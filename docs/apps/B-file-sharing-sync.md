# B. File sharing and synchronisation

Labels as in the [README](README.md): **[V]** verified, **[S]** search summary, **[K]** stable knowledge, **[U]** unverified.

## Four different things people call "files"

| Concept | What it is | Example | Protects against deletion/ransomware? |
|---------|------------|---------|----------------------------------------|
| Remote file access | You open the **master copy** over the network | SMB share on the server | No: it *is* the data |
| Synchronised copy | Several devices keep copies equal | Syncthing, Nextcloud client | **No**: deletions and ransomware encryption propagate (versioning helps a little) |
| Backup | Independent, versioned copy somewhere else | restic | Yes, if tested |
| Authoritative master | The one copy whose loss matters | `/srv/storage` on the server | Only via backups |

Design rule: the server holds the master; PCs and phones are clients or caches; **backups protect the master** (Part G).

## Which one do I need?

| Need | Use | Why |
|------|-----|-----|
| A network drive on Windows/macOS/Linux PCs | **Samba (SMB)** | Native everywhere, simple permissions |
| Keep a folder identical on laptop + server (notes, documents you edit offline) | **Syncthing** (or Nextcloud client) | Peer-to-peer, no server component required |
| Phone photos and videos | **Immich** ([C](C-personal-cloud-photos.md)) | Built for it; not a file sync tool |
| Share something with a relative | A Samba account over Tailscale, or an Immich album over Tailscale | Nothing public |
| Share with someone outside the family | A hosted service, or a short-lived public page behind Cloudflare Access (size limits apply) | Do not widen the private door for a one-off |
| Calendar, contacts, collaborative office | **Nextcloud** (or a lighter CalDAV/CardDAV server) | Only if you truly want these |
| Linux user editing files remotely | **SFTP/SSHFS** over Tailscale | It is SSH |
| Archive / disaster recovery | **restic**, not sync | Versioned and independent |

## Samba / SMB (full profile)

| | |
|---|---|
| **Problem it solves** | A normal network drive for Windows, macOS, Linux, Android file managers and iOS Files |
| **Class / when** | **Recommended** / Stage 2 |
| **Why this, not simpler** | A web file manager is a larger attack surface; NFS has weak per-user authentication. SMB is what every OS expects |
| **Hardware / storage** | Tens to a couple of hundred MB RAM; storage is the data itself |
| **Dependencies** | Linux users for ownership; a separate Samba password database; group-based permissions on `/srv/storage/files` |
| **Install** | Prefer a **host package**: user/group mapping is simpler than inside a container (specific settings verified from Samba's docs at Phase 8) |
| **Exposure / access** | Class 2: LAN and tailnet to specific devices only; **never published, never behind Cloudflare**. SMB over WAN-like links is slow and chatty |
| **Authentication / security** | Per-person accounts (no shared logins, no guest access), `nologin` shells, modern protocol versions only (SMB1 off), read-only shares for read-only data, no shares for `/srv/backup-local` or `/srv/secrets`. Ransomware on a PC with a mapped drive can encrypt what that user can write, which is why backups are versioned and out of reach |
| **Backup / recovery** | The data is backed up by restic; configuration in Git; user passwords are re-set on rebuild |
| **Maintenance / cost** | OS package updates; free |
| **Limits / devices** | Windows maps via Explorer ("Map network drive") or `net use`; macOS via Finder "Connect to Server" (`smb://`); Linux via the file manager or `mount.cifs`; Android through file-manager apps with SMB support; iOS via the Files app "Connect to Server". Smart TVs vary: test each model |
| **Continuous?** | Yes |
| **Avoid when** | Only phones and a web UI are needed, or nobody uses PCs |

## Syncthing (full profile)

| | |
|---|---|
| **Problem it solves** | Keeps chosen folders identical across devices without a central cloud |
| **Class / when** | **Recommended** / Stage 2 (optional per user) |
| **Why this, not simpler** | Copying by hand does not scale; Nextcloud is a bigger stack. Syncthing is a single peer-to-peer tool with device IDs and TLS |
| **Hardware / storage** | ~100-300 MB RAM depending on file count **[E]**; storage is the data |
| **Dependencies** | None. Optional relays/discovery servers (public by default) can be disabled for a fully private setup using Tailscale addresses **[K]** |
| **Install** | Container or host service on the server; clients on PCs/phones. Verify the current install method at Phase 8 |
| **Exposure / access** | Sync port class 2; the web GUI is admin-only (localhost / SSH tunnel) |
| **Authentication / security** | Devices authenticate by device ID; verify IDs when pairing; GUI password set; use folder types deliberately (send-only on the server for pure distribution, receive-only for pure ingest) **[K]** |
| **Backup / recovery** | Not a backup. File versioning is **off by default**: enable *Trash Can* versioning so deleted files are kept in `.stversions` **[V]**, and leave `ignoreDelete` alone (the docs reserve it for power users) **[V]**; the server's copy is backed up by restic |
| **Maintenance / cost** | Updates monthly; free |
| **Limits / devices** | **Android:** the official Syncthing-Android wrapper is **discontinued**: its README states the last GitHub/F-Droid release was the December 2024 Syncthing version and the repo is being archived **[V]**. A community fork, **Syncthing-Fork** (repository `researchxxl/syncthing-android`, F-Droid package `com.github.catfriend1.syncthingfork`), is documented in its own README **[V]**; check its latest release date and issue tracker before relying on it **[U]**. **iOS:** no official app; third-party apps are limited by iOS background execution **[K]**. Conflicts create `sync-conflict` copies that need human review |
| **Continuous?** | Yes (on at least the server and one other device) |
| **Avoid when** | Your devices are mainly phones (use Immich for photos), or you want a single web UI for everything (consider Nextcloud) |

## Nextcloud (medium profile)

| | |
|---|---|
| Purpose | Personal cloud: files, desktop/mobile sync, WebDAV, calendar/contacts, optional office integrations |
| Class / when | **Optional** / Stage 3 only if you need its extras. **Not needed for photos** when Immich is installed |
| Requirements **[V]** | Ubuntu 26.04 LTS recommended; Debian 13 supported; PostgreSQL 14-18 (18 recommended) or MariaDB (11.8 recommended); PHP 8.5 recommended; minimum 128 MB and recommended 512 MB RAM **per process** |
| Security | 2FA supported once an administrator enables a provider **[V]**; fast patching matters; if published, desktop and mobile clients and WebDAV do not pass a Cloudflare Access login cleanly **[K]**; keep it on Tailscale by default |
| Upgrades | Major versions cannot be skipped **[K]**; read the upgrade notes; test on a copy |
| Backup | Files + database dump + configuration, with maintenance mode around the dump **[K]** |
| Cost / burden | Free; highest maintenance of the file options |
| Avoid when | You only want a network drive (Samba) or sync (Syncthing) |

## Short profiles

| App | Class / when | Notes |
|-----|--------------|-------|
| NFS | Optional / Later | LAN-only. Trust is by IP and numeric UID (weak). Useful for Linux-to-Linux or media players that require it. Never public, not over the tailnet unless you must |
| SFTP | Essential (it is SSH) | Admin and power users. Restrict family accounts to SFTP only if ever used. Clients: OpenSSH `sftp`/`sshfs`, WinSCP, Cyberduck, Files apps with SFTP |
| Web file managers | Not recommended | **File Browser is archived (2026-09-01) with no further releases, bug fixes or security fixes [V]**: do not adopt it. Any browser over the filesystem is a high-value target; mount only one share |
| Other personal clouds (Seafile, ownCloud Infinite Scale, copyparty and similar) | Optional / Later | Check maintenance status and licence before adopting **[U]** |
