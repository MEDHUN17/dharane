# Storage architecture and directory layout

Labels: **[V]** verified in docs, **[K]** stable knowledge (re-check at Phase 3), **[E]** estimate to measure.
Placeholders only: UUIDs, names and sizes below are examples.

## 1. Disk roles

| Role | Typical media | Mount | Holds | Why |
|------|---------------|-------|-------|-----|
| System + app state | SSD | `/` and `/srv/appdata`, `/srv/config` | OS, Docker images, Compose files, app config, **all databases**, caches | Random IO and latency. Immich says its Postgres data should use local SSD and never a network share **[V]**; Jellyfin recommends an SSD for its files and transcode cache **[V]** |
| Bulk data | HDD (or large SSD) | `/srv/storage` | Original photos/videos, documents, shared files, media, downloads | Capacity and sequential reads |
| Backup (local) | Separate physical HDD | `/srv/backup-local` | restic repository | Different failure domain from the data disk |
| Surveillance (Stage 4) | Surveillance-rated HDD | `/srv/surveillance` | Camera recordings | Continuous 24/7 sequential writes shouldn't compete with everything else |
| Off-site | Cloud or remote machine | n/a | Encrypted restic repo | Survives site loss |

A single disk is possible at Stage 1 (one SSD with everything) but then you have **no** local backup domain. Minimum sensible: SSD + one more disk used for backups.

## 2. Directory layout

```
/srv
├── config/                    # SSD. Git working tree of the PRIVATE "server-config" repo (no secrets)
│   ├── stacks/<project>/      #   compose.yaml, .env.example, README.md (ports, networks, data paths, restore notes)
│   ├── scripts/               #   backup, health checks, maintenance (versioned)
│   ├── systemd/               #   .service/.timer files that get installed into /etc/systemd/system
│   └── docs/                  #   inventory + runbooks (templates in Part K)
├── secrets/                   # SSD. root:root 0700. NOT in Git. env files, tokens, key files
├── appdata/<app>/             # SSD. App config, state, databases, caches. Backed up (DBs via dumps)
│   └── e.g. immich/postgres, jellyfin/config, paperless/db, caddy/data
├── dumps/                     # SSD. Database dumps staged before each backup
├── storage/                   # MOUNT: bulk data disk
│   ├── photos/                #   Immich UPLOAD_LOCATION: library/, upload/, profile/, thumbs/, encoded-video/, backups/
│   ├── documents/             #   Paperless media/consume, personal documents
│   ├── files/{shared,users/<name>}/   # SMB/Syncthing content
│   └── media-root/            #   ONE parent for the whole media/download stack (see section 2a)
│       ├── media/{movies,tv,music}/
│       └── downloads/{torrents,usenet}/   # same parent as media so hardlinks and instant moves work
├── games/<server>/            # SSD preferred for worlds; excluded from "bulk" if disk is slow
├── surveillance/              # MOUNT (Stage 4): NVR disk
├── backup-local/              # MOUNT: local restic repo
└── logs/                      # only for apps that cannot log to the journal/Docker
```

Why `/srv`: it is the Filesystem Hierarchy Standard location for "data served by this system" **[K]**, it keeps everything you must back up or restore in one tree, and it survives an OS reinstall if `/srv` mounts are separate.

### 2a. Why `media-root/` exists (hardlinks without exposing personal data)

Hardlinks and instant moves only work inside **one filesystem**: you cannot hardlink directories, and you cannot hardlink across separate file systems, partitions, volumes **or mounts** **[V]** (TRaSH Guides). Inside a container, two separate bind mounts count as two mounts even when they come from the same host disk. So:

- Mount `/srv/storage/media-root` into the download/arr containers as **one** path (for example `/data`) and let them use `media/` and `downloads/` beneath it. Do not bind-mount `media/` and `downloads/` separately.
- Do **not** mount all of `/srv/storage` for this: that would let a download client or indexer app read personal photos and documents.
- Jellyfin gets `media-root/media` read-only; it never needs `downloads/`.
- Run the apps as a per-app user plus a shared group with `UMASK 002` (folders 775, files 664) so they can read each other's files **[V]**.

Immich note **[V]**: Immich stores everything under one `UPLOAD_LOCATION` by default and documents optional overrides for thumbnails, encoded video, profile and backups; it advises against mounting `upload/` and `library/` as separate bind mounts on the same device. Mount the photo directory once as a whole.

## 3. Mounting without foot-guns

**Use UUIDs** in `/etc/fstab`, never `/dev/sdX` names (they change). Example shape (do not copy blindly; Phase 3 verifies your disks first):

```
UUID=<uuid-of-data-disk>  /srv/storage  ext4  defaults,nofail,x-systemd.device-timeout=30s  0 2
```

`nofail` stops a missing disk from blocking boot, but that creates the dangerous case: **the server boots, the mount is absent, and a container writes into an empty directory on the SSD** (then fills the system disk, or "starts fresh" and later gets backed up as empty). Defend in layers:

| Layer | What it does | Evidence |
|-------|--------------|----------|
| 1. Immutable mountpoint | With the disk **unmounted**, run `chattr +i /srv/storage`. Writes into the bare directory fail; the mounted filesystem overlays it normally | **[K]** |
| 2. Compose bind mounts with `create_host_path: false` | Docker errors instead of silently creating a missing source directory | **[V]** (default is `true`) |
| 3. Sentinel file | A file such as `/srv/storage/.disk-ok` on the data disk; health checks and the backup script refuse to run if it is absent | **[K]** |
| 4. systemd ordering | A drop-in with `RequiresMountsFor=/srv/storage` (on `docker.service`, or on per-stack units) so containers do not start before the mount. Trade-off: on `docker.service` it fails *closed* for every stack, including ones that do not need that disk | **[K]** |
| 5. Alert | A monitor that pages you when a mount or sentinel is missing | Part H |

## 4. Bind mounts vs Docker volumes

| | Bind mount (recommended) | Named volume |
|---|--------------------------|--------------|
| Where data lives | A path you choose (`/srv/appdata/...`) | Under `/var/lib/docker/volumes` |
| Backup | Trivial: it's a normal directory | Needs to go through Docker or the volume path |
| Visibility/permissions | You control owner/mode; easy to inspect | Docker-managed; ownership set by the image |
| Portability | Copy the tree to a new host | Export/import steps |
| Risk | Wrong path or missing mount (mitigated above); host permission mismatches | `docker compose down -v` or `docker volume prune` deletes data **[K]** |
| Best for | Everything you care about | Disposable caches, or where a guide requires it (e.g. Immich's Windows-only note) **[V]** |

Container deletion does not delete bind-mounted data. `docker compose down` removes containers and networks; adding `-v` removes named volumes **[K]**. Never use `docker system prune --volumes` or `docker volume prune` as a "cleanup" habit.

## 5. Ownership, permissions and IDs

Principles: each app writes only where it must; shared datasets use a **group**, not world-writable modes; no blanket recursive `chmod 777` or `chown -R` as a fix.

| Data | Owner (user:group) | Mode | Mounted into | Access |
|------|--------------------|------|--------------|--------|
| `/srv/config`, `/srv/secrets` | `admin` / `root` | 0750 / 0700 | host only | admin; secrets root-only |
| `/srv/appdata/<app>` | that app's service UID, or the image's documented UID | 0750 | only that app | rw, private to the app |
| Databases | the DB image's UID | 0700 | only the DB container | rw |
| `/srv/storage/photos` | the photo app's UID | 0750 | photo app rw; backup reads | rw by app |
| `/srv/storage/media-root` | per-app users : `media` | 2775 (setgid), `UMASK 002` | arr/download apps rw as one mount; Jellyfin `media/` `:ro` | read-only for Jellyfin |
| `/srv/storage/files/shared` | `root` : `family` | 2770 | SMB / Syncthing | family group rw |
| `/srv/storage/files/users/<name>` | `<name>` : `family` | 2750 or 0700 | SMB / Syncthing | owner rw, optional group read |
| `/srv/backup-local` | `root` | 0700 | backup script only | not mounted into apps |

Practices:
- Prefer the image's documented `user:` or `PUID/PGID` settings **[K]**; do not run containers as root without a stated reason.
- Mount read-only (`:ro`, or `read_only: true` in the long syntax) wherever the app only reads (media for Jellyfin, external photo libraries) **[K]**.
- Check effective permissions as the container user (`docker compose exec`), not as `admin`.
- Choose numeric UIDs/GIDs once (Phase 3) and record them in the inventory so a rebuilt host reproduces them. SMB users map to Linux users with `/usr/sbin/nologin` and their own Samba password **[K]**.

## 6. Databases and application-consistent backups

- Databases live on SSD under `/srv/appdata/<app>/...` (or a Docker volume for Postgres-on-Windows only **[V]**).
- Back them up with the engine's own tool (for example a Postgres dump written to `/srv/dumps`), not by copying live files. A filesystem copy or snapshot of a running database can be crash-consistent but is not guaranteed application-consistent **[K]**.
- Keep the dump files in the restic run (or the app's built-in backup, where it has one, alongside the originals).
- **Immich** writes its own database dumps to `UPLOAD_LOCATION/backups`, by default daily at 02:00 keeping the last 14 (changed in v2.5.0, so check the docs for your version) **[V]**. Dumps contain metadata only; they are useless without the originals. Prefer these built-in dumps; schedule restic **after** them (for example 03:00). If you add your own independent `pg_dump`, run it away from 02:00 so the two never race. Restores need a compatible Immich version, and the command-line restore requires a fresh install where Immich has never run **[V]**.
- Never run a database on NFS/SMB **[V for Immich]**.

## 7. Encryption at rest (decision)

| Option | Protects against | Cost |
|--------|------------------|------|
| restic repository encryption (always on) | Theft/compromise of backup media or cloud account | None extra |
| LUKS on data/backup disks | Someone reading a stolen or discarded disk | **Headless unlock problem**: after a power cut the disk stays locked until you unlock it or a keyfile/TPM/network unlock is used, which weakens the protection **[K]** |
| LUKS on the root disk | Theft of the whole machine | Same, plus initramfs unlock setup |

Recommendation: Stage 1 encrypts **portable/rotated backup drives** (they leave the house) and relies on restic for off-site. Add LUKS for internal disks only if physical theft is a realistic threat for you *and* you accept manual or network-assisted unlock after outages. If you use LUKS, back up the LUKS header and keep the passphrase in your recovery kit.

## 8. Health, alerts and replacement

- SMART: `smartd` with scheduled short and long self-tests; `smartctl -a /dev/<disk>` is read-only **[K]**. Treat reallocated/pending sectors and rising CRC errors as "plan replacement". SMART can pass while a disk fails soon; it is a warning system, not a guarantee.
- Alerts: warn at 80% used, critical at 90% (leave headroom; ext4 reserves blocks by default **[K]**), and alert on a missing mount/sentinel.
- Filesystem checks: `fsck` only on unmounted filesystems, after a backup, and never as a first reflex on a failing disk (image it first) **[K]**.
- **Safe replacement of a data disk** (outline; exact commands at Phase 3/14): confirm the latest backup restores; stop dependent stacks; identify the failing disk by serial, not device name; attach and format the new disk; mount it temporarily; copy with `rsync -aHAX` (or restore from backup); verify counts and checksums; update `/etc/fstab` UUID; re-apply `chattr +i` to the empty mountpoint; start stacks; keep the old disk untouched until the new one has run clean for a while.
- Expansion: with plain ext4 you add a new disk and a new mount (for example `/srv/storage2`) or migrate to a larger disk; LVM/mdadm/ZFS offer pooling at the cost of complexity (Part C, C3/C4).

## 9. Capacity planning

| Source | Rule of thumb | Notes |
|--------|---------------|-------|
| Phone photos | 2-6 MB each **[E]** | Depends on resolution and format |
| Phone video | 1080p about 100-150 MB/min; 4K 30fps about 300-400 MB/min **[E]** | Largest driver of photo-library growth |
| Immich overhead | add 10-20% for thumbnails and transcoded video **[V]** | Plus a ~1-3 GB Postgres database **[V]** |
| Documents | scanned page 0.1-2 MB; Paperless keeps the original and an archived copy **[V/K]**, so budget up to about 2x | OCR index in the DB |
| Movies/TV | 1080p encode 2-8 GB per movie; remux 20-40 GB; episodes 1-3 GB **[E]** | Re-acquirable, so lowest backup priority |
| Game worlds | 0.5-5 GB per world **[E]**, times backup retention | Mods and maps can be larger |
| Camera footage | GB/day = bitrate_Mbps x 86400 / 8 / 1000 per camera | 4 Mbps -> about 43 GB/day per camera continuous; motion-only recording is often several times smaller **[E]** |
| Backup repo | Roughly 1.0-1.5x unique data for dedup plus retention churn **[E]** | Photos dedup poorly across edits but well across runs |

Method: record current usage monthly (Part H), compute growth per category, and plan to replace or add capacity when projected usage reaches 70-75% within 12 months.

## 10. What gets backed up (preview; policies in Part G)

| Path | Backup? |
|------|---------|
| `/srv/config` | Yes (also in Git) |
| `/srv/secrets` | Yes, encrypted, to a repo with separate credentials; never to a public location |
| `/srv/appdata` | Yes, except pure caches (thumbnail/model caches are re-creatable) |
| `/srv/dumps` | Yes |
| `/srv/storage/photos` (Immich) | Yes, local + off-site: `library/`, `upload/`, `profile/` (originals) and `backups/` (DB dumps). `thumbs/` and `encoded-video/` are regenerable, so they may be excluded at the cost of regeneration time after a restore **[V]** |
| `/srv/storage/documents`, `files` | Yes, local + off-site |
| `/srv/storage/media-root` | Local only, or not at all (re-acquirable) |
| `/srv/surveillance` | No by default; export selected clips |
| `/srv/backup-local` | Never back up a repo into itself |
