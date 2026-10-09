# Part G - Security, identity and backup architecture

Labels: **[V]** verified in docs (see `12-verification-log.md`), **[S]** search summary, **[K]** stable knowledge, **[E]** estimate. Public repo: no real values.

Design the controls before exposing anything. The baseline below is sized for a personal home server, not an enterprise.

## 1. Security baseline: ten controls that carry most of the value

1. **No inbound ports.** Private access is Tailscale; public access (rare) is Cloudflare Tunnel + Access.
2. **MFA on every account that can control the server**: the Tailscale identity provider, Cloudflare, the domain registrar, GitHub, the password manager, and the backup provider. Prefer passkeys or hardware keys on these.
3. **SSH with keys only**, reachable from the LAN and the tailnet, never forwarded.
4. **Patch**: automatic OS security updates; monthly reviewed application updates (see `07-automation-monitoring.md`).
5. **Tested backups** with an off-site copy and credentials that a compromised server cannot use to destroy it.
6. **Least-privilege containers**: own network, own non-root user, minimal read-only mounts, no Docker socket.
7. **Do not expose** admin dashboards, Docker, databases, metrics, SMB/NFS, cameras.
8. **Segment**: guests, IoT and cameras away from the server and family devices where the router allows.
9. **Alerts and logs** that a human reads (Part H).
10. **A recovery kit** stored off the server, tested.

## 2. Threat model

Likelihood and impact are for a typical Indian home deployment and are judgements, not measurements.

| # | Threat | L | I | Preventive controls | Detection | Recovery |
|---|--------|---|---|---------------------|-----------|----------|
| 1 | **Compromised credentials** (reuse, phishing of the account that logs you into Tailscale/Cloudflare) | H | H | Unique passwords in a manager; passkeys/hardware keys on identity accounts; device approval + key expiry; tailnet policy limits what a compromised user can reach | New-device alerts in the Tailscale and Cloudflare consoles; IdP login alerts; `last`/auth logs | Revoke devices and sessions; rotate secrets; review audit logs; restore if data touched |
| 2 | **Lost or stolen phone/laptop** | H | M | Screen lock + device encryption; device approval; per-app sessions revocable; no long-lived SSH keys without passphrases | You notice | Remove the device from the tailnet; revoke app sessions; rotate anything saved on it |
| 3 | **Vulnerable container / app CVE** | M | H | Private by default; minimal published ports; per-app networks; update cadence; subscribe to release notes of each app | Security advisories; unexpected outbound traffic or CPU | Update or roll back; restore from a pre-incident backup; rotate secrets that app held |
| 4 | **Malicious or tampered image** | L | H | Official or well-known publishers only; pin version (or digest); never `latest`; read the compose file; no privileged mode | Unexpected connections/processes | Remove container and image; rotate secrets it saw; restore data from before |
| 5 | **Exposed admin interface** (Docker API, dashboards, metrics) | L | Crit | Bind to localhost/Tailscale IP; firewall; no socket mounts; external scan after every change | Periodic external port scan; `ss -tlnp` audit | Close it; assume compromise if Docker's API was open; rebuild host |
| 6 | **Unintended port forwarding** (router UPnP, forgotten rule) | M | H | Disable UPnP on the router; review the forward table; Docker publishes to localhost | External scan of the home IP | Remove rule; check what was exposed |
| 7 | **DNS misconfiguration** (open resolver, leaked internal names, dangling records) | M | M | Resolver bound to LAN/tailnet only; wildcard cert; clean up unused Cloudflare records | External open-resolver test; review DNS records quarterly | Fix binding/records |
| 8 | **One compromised application** | M | H | Separate networks and users; read-only mounts; no `docker.sock`; capabilities dropped | File integrity surprises; logs | Stop it; restore app data from a clean backup; rotate secrets |
| 9 | **Ransomware** (usually on a client PC with a mapped SMB drive) | M | H | Shares restricted per user; client protection; **versioned off-site backup that the server cannot delete**; a rotated offline disk | Backup size/change anomalies; many changed files | Isolate, then restore from a known-good snapshot |
| 10 | **Malicious family member or guest** | L | M | Individual accounts; minimal roles; no shell/Docker access; guests on guest Wi-Fi only | App audit logs | Disable account; rotate shared secrets |
| 11 | **Camera compromise** (default passwords, vendor cloud/P2P features, old firmware) | M | H | Camera network with **no internet**; unique passwords; firmware updates; disable P2P/UPnP/cloud; only the NVR may reach cameras | Firewall/DNS logs for camera outbound attempts | Factory-reset or replace; change credentials; review who viewed footage |
| 12 | **Backup credential theft** | M | H | Dedicated, scoped keys; provider immutability/object lock or append-only access; prune credentials kept off the server **[V: restic's append-only guidance]** | Provider access logs; unexpected snapshot deletions | Rotate keys; verify older snapshots; start a new repo if the password leaked |
| 13 | **Physical theft** (disks or the whole machine) | M | M | Out-of-sight placement; encrypted backup drives; LUKS on internal disks only if you accept manual unlock (`02a`) | n/a | Revoke every secret stored on the machine (Tailscale node, tunnel token, DNS token, backup keys); restore to new hardware |
| 14 | **Unpatched OS/kernel** | H | M | Unattended security upgrades; planned reboots for kernel updates | Update-check alert; `needrestart`-style check | Patch and reboot |
| 15 | **Misconfigured Docker permissions** (docker group, privileged, mounting `/`) | M | H | Hardening checklist (Part C); audit script for privileged/host-network/socket mounts | Read-only audit via `docker inspect` | Fix compose; recreate containers |
| 16 | **Human error** (`rm -rf`, `down -v`, `volume prune`, wrong disk) | H | H | Bind mounts; backups; confirm targets; no blanket prune habits | You notice | Restore from backup |
| 17 | **Power surge / unclean shutdown** | H | M | UPS + graceful shutdown; surge protection | Unclean-shutdown log entries | `fsck` after backup; restore if needed |

## 3. Controls in detail

**SSH hardening** **[K]** (apply in a drop-in file under `sshd_config.d`, test in a second session before closing the first, `sshd -t` before reload): public-key authentication only; password and keyboard-interactive authentication off; root login off; `AllowUsers` limited to your admin account; X11 forwarding off; modest `MaxAuthTries`. Keep a break-glass path (console, or LAN SSH if tailnet breaks). Do not rely on a changed port as protection.

**Host firewall** **[V for Docker interplay]**: default-deny inbound with ufw; allow SSH from the LAN subnet and `tailscale0`. Docker's published ports are diverted before ufw's rules **[V]**, so the real rules for containers are: publish to `127.0.0.1` or the Tailscale IP, and use the `DOCKER-USER` chain for anything that must be LAN-visible **[V]**. Use iptables-based tooling (ufw), not hand-written `nft` rulesets, while Docker's iptables backend is in use **[V]**.

**Tailscale policy** **[K]**: replace the default allow-all with explicit rules; give the server a tag and put people in groups; admins reach SSH; family reaches only the proxy ports of the services they use (not SSH, not SMB unless intended); test rules with the policy tester before saving; keep the policy file in the private repo; disable key expiry for the server only; require device approval; review the device list quarterly.

**Public access restrictions**: services must pass the checklist in `docs/apps/00-exposure-matrix.md`: the app's own authentication, Access in front where clients allow it, request-size/protocol limits understood, a kill switch tested, no admin paths reachable.

**Docker socket and privileges** **[K]**: anything with `docker.sock` is root on the host. Avoid Portainer-style tools and auto-update tools that need it; if unavoidable, use a read-only socket proxy and keep it on an internal network. No `privileged: true`, no `network_mode: host` and no added capabilities without a documented reason.

**Images and updates**: pinned tags, official/maintained images, published release notes read before upgrading, rollback = previous tag + restored backup. Optional image vulnerability scanning on your admin machine.

**Network segmentation where justified**: guest Wi-Fi isolated from LAN; cameras on their own network with no internet (`03-hardware-capacity.md` §6); IoT separated if the router can. If the router cannot do VLANs, a second NIC plus a dedicated switch for cameras is a cheap equivalent.

**Audit logs**: systemd journal (limit size, keep 30+ days if disk allows), Tailscale admin console audit log, Cloudflare Access logs, application logs. Alert on SSH logins from unknown sources and on new devices.

**Credential rotation**: DNS API token and tunnel token yearly or after any suspected exposure; backup keys yearly; admin SSH keys when a device is retired; app passwords when a family member leaves; recovery codes re-generated after use. Put rotation dates in the maintenance calendar.

**Recovery codes and device revocation**: print recovery codes for the Tailscale IdP, Cloudflare, registrar, GitHub, and password manager, and keep them off the server (recovery kit, section 8.9). Device revocation: remove it from the tailnet console first, then revoke app sessions, then rotate anything that device stored.

**Never publicly exposed without exceptional, written justification**: SSH, SMB/NFS, databases, Docker/containerd APIs, Portainer-like dashboards, Prometheus/metrics endpoints, Caddy's admin API, DNS resolvers (port 53), camera RTSP/ONVIF/web interfaces, Frigate's unauthenticated port, code-server, Ollama, router admin pages. Obscurity, odd ports, or a reverse proxy are not substitutes for authentication.

**Incident response, minimum**: (1) disconnect the machine from the network or run `tailscale down`; (2) do not wipe yet: preserve logs; (3) rotate secrets from a clean device (Tailscale/IdP, Cloudflare, registrar, DNS/tunnel tokens, backup keys, app admin passwords); (4) identify the entry point; (5) rebuild the host from Git and restore data from a pre-incident snapshot; (6) record what happened in the maintenance log.

## 4. Identity model

| Identity | Examples | Authoritative system | Privileges | Notes |
|----------|----------|----------------------|------------|-------|
| Linux administrator | `admin` | `/etc/passwd`, SSH `authorized_keys`, sudo | Full, via sudo | One human; two keys (daily + break-glass). Treat `docker` group membership as root |
| Ordinary Linux users | `fam-<name>` | `/etc/passwd` (`nologin` shell) + Samba password database | File shares only | Only if SMB is used; no shell |
| Docker service identities | numeric UIDs 10000+ per app | Host numeric IDs recorded in the inventory | Own `appdata` only | Rebuilds reproduce the same IDs |
| Application users | Immich, Jellyfin, Paperless users | Each app's own database (or OIDC later) | Per-app roles | Admin account separate from daily account |
| Family members | | Tailnet user (identity provider) + app accounts | Their apps only | MFA support varies per app (`apps/O-family-access.md`) |
| Guests | | Guest Wi-Fi only | Internet only | No tailnet, no accounts |
| Remote administrators | you | Tailnet identity (+ MFA) and SSH key | Admin | Another admin only with an explicit tag/policy |
| Backup credentials | restic repo passwords; provider keys | Recovery kit + provider IAM | Write/append to the repo | Distinct from admin credentials |
| Monitoring credentials | push-notification token, heartbeat URLs | `/srv/secrets` | Send-only | Treat heartbeat URLs as secrets |

Authority rule: **the tailnet identity decides who may reach a service; the application decides what they can do inside it; Linux decides what files a process can touch.** None replaces the others. Do not use one universal login or one shared Linux account.

### Data permission matrix

| Data | Owner : group (examples) | Who can read | Who can write | Mount into containers |
|------|--------------------------|--------------|---------------|-----------------------|
| Personal files | `<name>` : `family` | owner (+ chosen readers) | owner | Samba/Syncthing only |
| Shared folders | `root` : `family` | family | family | Samba/Syncthing |
| Media library | per-app users : `media` | players, arr apps | arr apps | Jellyfin `:ro` |
| Photo library | photo-app UID | the app; backup job | the app | one container, rw |
| Documents | document-app UID | the app; backup job | the app | one container, rw |
| Downloads | per-app users : `media` | arr apps | download client | download/arr stack only |
| Game saves | game UID | that game; backup job | that game | that game only |
| Camera recordings | NVR UID | NVR; export job | NVR | NVR only |
| App configuration | app UID | admin | app | that app only |
| Backup repositories | `root` | backup job | backup job | **none** |

Read-only where possible; never mount a parent directory (such as all of `/srv/storage`) when a subdirectory is enough (`02a` §2a).

## 5. Backup architecture

### 5.1 The 3-2-1 target mapped to this design

| Copy | Where | Failure it covers | Practical limits |
|------|-------|-------------------|------------------|
| 1. Live data | Data disk + SSD | none (it's the working copy) | - |
| 2. Local backup | Separate physical disk in/next to the server (different media) | Disk failure, deletion, corruption | Same room: fire/theft/surge can take copies 1 and 2 |
| 3. Off-site | Object storage, a relative's machine, or a rotated drive kept elsewhere | Site loss, theft, flood, ransomware (if immutable) | Upload time, recurring cost, trust (mitigated by client-side encryption) |

3-2-1 is impractical for some data: a large re-acquirable media library may be local-only by design, and continuous camera footage is not worth off-site cost. The policy below decides per dataset.

**RAID, snapshots, replication and sync are not backups.** RAID/mirrors do not protect against accidental deletion, ransomware, filesystem corruption written to both disks, or a site disaster. Snapshots share the disk's fate. Sync tools propagate deletions and encryption by ransomware.

### 5.2 Tool and repository layout

- **restic** (Part C, C10): two repositories with **separate passwords**: `local` on `/srv/backup-local` and `offsite` on object storage or SFTP. Verified features **[V]**: `backup` (with `--dry-run`, `--one-file-system`, `--exclude-caches`, `--tag`), `forget` (`--keep-*`, `--prune`, `--dry-run`), `check` (`--read-data-subset`), `restore --target/--include`, `copy --from-repo` (replicate snapshots between repos), `RESTIC_PASSWORD_FILE`, global `--limit-upload`, and S3/B2/SFTP backends with their documented credential environment variables.
- One script, one systemd timer, tags per dataset (`photos`, `documents`, `appdata`, `config`, `secrets`). Back up the same paths to both repos independently (simple, and each repo is independently restorable) or back up locally then `restic copy` to off-site (fewer source reads; both are valid).
- **Credentials that cannot destroy the off-site copy.** The server needs to *write* backups, so a compromised server can use whatever credential it holds. Choose one: (a) provider-side immutability/object lock with a retention window; (b) an append-only endpoint (restic's rest-server has an append-only mode **[V]**; few other backends do) with pruning done from a separate trusted machine; (c) a rotated offline drive. Whichever you choose, with append-only repositories **use `forget --keep-within`** so an attacker cannot bury good snapshots under fake ones **[V]**.

### 5.3 Policy per data class

| Class | Included | Method | Frequency | Retention (starting point) | Off-site | Notes |
|-------|----------|--------|-----------|----------------------------|----------|-------|
| Personal documents | `/srv/storage/documents`, `/srv/storage/files` | restic file backup | Nightly | 14 daily, 8 weekly, 12 monthly, 5 yearly | Yes (first to seed) | Highest value per GB |
| Original photos/videos | Immich `library/`, `upload/`, `profile/` | restic file backup | Nightly | same as documents | Yes | Thumbnails and encoded video may be excluded; they are regenerable **[V]** |
| Application configuration | `/srv/appdata/*` (without caches), `/srv/config` | restic | Nightly | 7 daily, 4 weekly, 6 monthly | Yes (small) | Apps with SQLite: stop container or use the app's backup tool, not a live copy |
| Databases | Dumps in `/srv/dumps` and Immich's `backups/` | Engine/app dump, then restic | Dump nightly before restic | 14 daily dumps (Immich keeps 14 **[V]**) + restic history | Yes | Dumps are the restore source, not the live DB directory |
| Re-acquirable media | `media-root` | Optional local restic or none | Weekly | 4 weekly | No | Metadata/watch history is in app config, which is backed up |
| Game saves | `/srv/games/*` worlds | Pre-hook save/flush then restic | Daily (more often if active) | 7 daily, 4 weekly | Yes if small | Stop or flush the server for consistency |
| NVR footage | `/srv/surveillance` | None | - | Recording retention only | **No by default** | Export chosen clips to documents; cost, privacy |
| System configuration | `/etc` selections, package list, `crontab`/timers | Config repo (Git) + restic | On change + weekly | 12 weekly | Yes | Rebuild path |
| Secrets and recovery material | `/srv/secrets`, recovery kit | Encrypted copy in a **separate** repo and an offline kit | On change | Keep all versions | Yes (encrypted) | Never in the public repo |

Retention numbers are starting points; adjust after seeing real change rates and costs.

### 5.4 Application-consistent backups

A copy of a live database directory, or a filesystem snapshot taken while the engine is writing, is at best *crash-consistent*: the engine may recover, but the guarantee is its recovery process, not yours; with caches, WAL files and multi-file state it may not recover at all **[K]**. Use:

| App type | Consistent method |
|----------|--------------------|
| PostgreSQL apps (Immich, Paperless, etc.) | Engine dump (`pg_dump`) or the app's built-in dump. Immich writes its own daily dump at 02:00 and keeps 14 **[V]**; schedule restic afterwards. Restoring needs a compatible Immich version and, for the CLI path, a fresh instance **[V]** |
| SQLite apps (Vaultwarden, Uptime Kuma, many small apps) | The tool's online backup/`.backup`, or stop the container briefly, then copy **[K]** |
| File-only apps | Pause writers or accept file-level consistency for static data |
| Paperless-ngx | Its exporter plus a DB dump; keep originals **[K]** |
| Nextcloud | Maintenance mode around DB dump and file copy **[K]** |
| Game servers | Server "save and flush" command, then copy **[K]** |

Verify dumps: size sanity check, and restore into a scratch instance monthly.

### 5.5 Schedule

| Time (server local) | Job |
|---------------------|-----|
| 02:00 | Immich's own built-in database dump (app-native, default schedule **[V]**) |
| 03:00 | `backup.sh` (example): runs the dump hooks for any *other* databases first, then the local restic backup, then the off-site backup, in that order. Split into two timers with `--local-only` and `--offsite-only` if you want different times. Bandwidth-limit the off-site leg with `--limit-upload` if needed **[V]** |
| Weekly (Sun 05:00) | `forget` per policy (local); `check` (structure) |
| Monthly | `check --read-data-subset` rotating slice **[V]**; off-site restore of a sample |
| Quarterly | Full-app restore rehearsal |
| Annually | Disaster-recovery drill; credential rotation |

Do not run `--read-data` on cloud repositories without checking egress cost rules **[V that it reads every pack]**.

### 5.6 Failure semantics (restic exit codes)

Exit codes **[V]**: 0 success; 1 failure; 2 Go runtime error; **3 `backup` could not read some source data** (a snapshot is still created) or `forget` could not remove snapshots; 10 repo does not exist; 11 lock failure; 12 wrong password; 130 cancelled. Unknown codes must be treated as failure. Policy: **0 = OK; 3 = WARNING that still alerts** (unreadable files may be exactly what you care about; investigate, do not report green); everything else = FAILURE. The example script in `examples/` implements this.

### 5.7 Initial upload and bandwidth

```
days = data_GB * 8000 / (upload_Mbps * 0.8 * 86400)
```

| Data | At 10 Mbps up | At 20 Mbps up | At 50 Mbps up |
|------|---------------|---------------|---------------|
| 500 GB | about 5.8 days | about 2.9 days | about 1.2 days |
| 2 TB | about 23 days | about 11.6 days | about 4.6 days |

(`0.8` = realistic efficiency.) Seed documents first, then original photos, then the rest; use `--limit-upload` so it does not starve the household **[V]**; run it overnight; resumability is handled by restic's repeated backup runs.

### 5.8 Restore tests

| Test | Frequency | Pass criteria |
|------|-----------|---------------|
| Restore a single file from the local repo to a scratch directory | Monthly | Checksum matches the source |
| Restore a directory from the **off-site** repo | Quarterly | Same, and time is recorded |
| Restore one app (DB dump + files) into a scratch instance and open it | Quarterly per app | App starts, sample data visible |
| Full DR drill: rebuild host from Git + recovery kit and restore | Annually | Documented RTO/RPO met |

Record date, snapshot ID, duration and result in the maintenance log. A monitoring check that a service is up is **not** evidence that its data can be restored.

### 5.9 Key management and the recovery kit

The kit lives **off the server and outside the house** (second location) and in a place you and a trusted person can find it. Contents: restic repository passwords (both repos); provider account recovery and API key IDs; Tailscale/IdP, Cloudflare, registrar, GitHub and password-manager recovery codes; the admin SSH private key backup (encrypted); the location of the config repo; this recovery runbook (printed). Test: with only the kit and an empty laptop, can you reach the off-site repo and restore one file? Do that once, annually.

### 5.10 Ransomware and compromised-account scenarios

| Scenario | What protects you | Check |
|----------|-------------------|-------|
| Client PC encrypts files on a mapped share | Versioned history (restic) is not reachable from the PC; short-lived shares; `valid users` restrictions | Restore from the pre-infection snapshot |
| Server compromised, attacker deletes backups | Immutable/append-only off-site (section 5.2); rotated offline drive; prune credentials elsewhere | Off-site snapshots still list and restore |
| Provider account taken over | MFA + scoped keys; a second independent copy for crown-jewel data | Provider logs |
| Attacker adds fake snapshots to trigger bad `forget` | `forget --keep-within` on append-only repos **[V]** | Snapshot-count alert (more than expected) |

### 5.11 Restoration runbooks (outline)

1. **Deleted file**: find the file (`restic find`/`ls` **[V]**), restore to a scratch path with `--include`, verify, copy back.
2. **Corrupted application**: stop the stack; restore `appdata` and the matching DB dump into a scratch location; start with the previous pinned image version; compare; swap; keep the broken copy until verified.
3. **Failed database**: restore the dump into a fresh DB container (for Immich, a fresh install, per docs **[V]**), start the app on the same version, run the app's integrity checks.
4. **Lost photo library**: restore `library/`, `upload/`, `profile/` and the DB dump onto a fresh instance **[V]**; thumbnails and encoded video regenerate (this takes time).
5. **Failed system disk**: install Debian, install Docker and Tailscale, clone the config repo, restore `/srv/appdata`, `/srv/secrets` (from the kit's repo), bring stacks up one at a time.
6. **Destroyed server**: as (5) on new hardware; reattach or restore the data disk contents from local or off-site backup; re-enrol Tailscale (new node, revoke the old); verify DNS and tunnel tokens; rotate every secret that lived on the old machine.

## 6. Off-site comparison (qualitative; prices in Part I)

| Destination | Cost model | Privacy | Restore speed | Complexity | Main risk |
|-------------|-----------|---------|---------------|-----------|-----------|
| Rotated external drive (kept at another location) | One-time hardware | Total (encrypt the drive too) | Fast | Manual routine | Gaps between swaps; drive failure |
| Relative's machine over Tailscale/SFTP | Their hardware + electricity | Good (encrypted by restic) | Limited by their uplink | Low-medium | Their reliability and consent |
| S3-compatible object storage | Per-TB per-month; egress/minimum rules vary | Good (client-side encryption) | Good | Low | Recurring cost; credentials; billing in foreign currency |
| SFTP storage box | Flat per month by size | Good | Good | Low | Foreign billing; no native immutability unless offered |
| Consumer cloud via rclone | Existing subscription | Good with restic encryption | Variable | Medium | Terms of service, API limits |
