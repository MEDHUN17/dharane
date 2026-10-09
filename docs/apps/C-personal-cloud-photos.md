# C. Personal cloud and mobile backups

Labels as in the [README](README.md): **[V]** verified in Immich's own documentation (see `../12-verification-log.md` V1, V11), **[S]**, **[K]**, **[U]**.

## Immich (full profile)

| | |
|---|---|
| **Problem it solves** | Replaces a cloud photo service: automatic phone backup, timeline, albums, search, face/object recognition, sharing, for a household |
| **Class / when** | **Recommended** / Stage 2 (Phase 8e) |
| **Why this, not simpler** | A shared folder cannot do phone-driven uploads, previews, search or albums. Nextcloud can store photos but is not built around them |
| **Alternatives** | Nextcloud with a photos app, PhotoPrism, other self-hosted galleries **[K]** |
| **Hardware / storage** | **Minimum 6 GB RAM and 2 cores; recommended 8 GB and 4 cores [V].** With only 4 GB RAM, run with machine learning disabled **[V]**. Thumbnails and transcodes add roughly 10-20% to library size **[V]**. On x86 the ML container needs the x86-64-v2 level since v3 **[V]** |
| **Dependencies** | PostgreSQL (data **on local SSD, never a network share**; typically 1-3 GB) **[V]**; a cache; a machine-learning container. Needs `docker compose` (the legacy `docker-compose` is unsupported) **[V]**. Immich states Docker inside LXC is not recommended while full VMs are fine **[V]** |
| **Install / Compose** | The project's current `docker-compose.yml` and `.env` from its release page, pinned to a version, with `DB_DATA_LOCATION` on SSD and `UPLOAD_LOCATION` on the bulk disk **[V]**. Optional overrides move thumbnails, encoded video, profile pictures and backups elsewhere; do not bind-mount `upload/` and `library/` separately on one device **[V]**. Specific file contents are taken from the docs when we install (Phase 8) |
| **Exposure / access** | **Class 2.** Immich's docs: never forward port 2283 to the internet; Tailscale is the documented option when you cannot open a router port; a reverse-proxy setup may expose the web UI and API, and Cloudflare Access can shield only the web interface **[V]**. Cloudflare's 100 MB request-body cap on Free/Pro breaks big video uploads **[S]**. Practical pattern: phones run Tailscale; inside the app set the LAN address for home Wi-Fi |
| **Authentication / security** | Local accounts and OAuth/OIDC login **[V]**. Native app-level MFA is not described in the OAuth page I read **[U]**: treat the Tailscale identity (MFA) as the compensating control and, if you add an OIDC provider, its MFA. Immich is under very active development and severe vulnerabilities cannot be ruled out **[V]**: stay private, read release notes before every upgrade |
| **Backup / recovery** | **Two parts, both needed [V].** (1) The database: Immich writes its own dumps to `UPLOAD_LOCATION/backups`, by default daily at 02:00, keeping the last 14; they contain metadata only. (2) The originals: `library/`, `upload/`, `profile/`; thumbnails and encoded video are regenerable. Restore needs a compatible Immich version; the CLI restore requires a fresh install where Immich has never run. Schedule restic after 02:00 (Part G). Rehearse a restore |
| **Maintenance / cost** | Read release notes monthly; update the pinned tag one step at a time; free software; storage cost only |
| **Limits / device compatibility** | Mobile apps for Android and iOS, plus a web UI. First import is CPU and IO heavy. See upload behaviour below |
| **Continuous?** | Yes. Heavy jobs (ML, transcoding) can be paused or limited |
| **Avoid when** | You have less than ~4 GB RAM, or you only want a file share |

### Automatic uploads: what really happens **[V]** (Immich mobile docs)

| Topic | Behaviour |
|-------|-----------|
| When it runs | On app open/resume and periodically in the background, for the albums you select |
| Networking | Wi-Fi only by default (configurable) |
| First-time upload | Immich checksums each file to recognise ones already on the server, then uploads the rest. Expect hours to days for large libraries; keep the phone charging on Wi-Fi with the app opened now and then |
| Incremental | New assets from the selected albums are uploaded as they appear |
| Duplicates | Checksum matching skips files already on the server (uploaded by CLI, web or another device) |
| Album structure | Optional **one-way** album sync from device to server |
| Deletions | Nothing is deleted from the phone automatically. "Free Up Space" can remove local copies that are safely backed up, with a review screen. With **iCloud Photos two-way sync**, deleting or freeing space on the iPhone also deletes it from iCloud and other devices; use "Optimize iPhone Storage" if iCloud is part of your 3-2-1. Backing up and freeing WhatsApp media makes chats show blank images |
| Android | Aggressive battery optimisation can kill the background worker (the docs point to "Don't kill my app"); you can restrict background uploads to charging time and set a delay after capture |
| iOS | **Background App Refresh must be enabled; iOS decides when background tasks run; the app cannot force them.** The more often you open the app, the more often they run. iCloud-held originals are pulled into a temporary cache before upload, using data and space |
| Metadata and recovery | Original files and their metadata go to the server; recovery is a restore of originals + database (above) |

## Other upload tools (optional)

| Tool | Platform | Role | Notes **[K]** (verify features and price at install) |
|------|----------|------|------------------------------------------------------|
| Immich app | Android, iOS | Primary photo/video uploader | See above |
| PhotoSync | Android, iOS | Paid uploader to SMB/SFTP/WebDAV/cloud targets, can be triggered by events | Useful if you want originals in plain folders rather than an app |
| FolderSync | Android | Folder sync to SMB/SFTP/WebDAV/cloud | Good for non-photo folders on Android |
| Syncthing | Android (community forks), desktop | Folder sync | Official Android app discontinued **[V]** |
| iOS Shortcuts automations | iOS | Limited, user-triggered or scheduled | iOS limits unattended background work **[K]** |

## Do I need both Immich and Nextcloud?

**No.** Photos and videos: Immich. Plain files: Samba and/or Syncthing. Add Nextcloud only when you specifically want calendar/contacts, collaborative office, or one web UI for files and sharing, and accept its PHP/database stack and upgrade rules (see [`B-file-sharing-sync.md`](B-file-sharing-sync.md)).

## Sharing and uploading without exposing unrelated services

- Put family on the tailnet with a policy that allows only the proxy port (443 on the `server` tag), not SSH or SMB.
- Use Immich's own sharing (albums, links, partner sharing) **[K]**; remember recipients must be able to reach the server, which means they are on the tailnet. For anyone else, send exports through a normal channel rather than opening a public path.
- Phones upload only to Immich; they never need the file share.

## Application backup vs backup of originals

Immich's database dump is **not** a photo backup: it holds paths and metadata only **[V]**. The originals on disk (`library/`, `upload/`, `profile/`) are the irreplaceable part. Your restic policy must include both, plus the off-site copy.
