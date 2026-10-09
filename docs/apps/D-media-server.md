# D. Media server

Labels as in the [README](README.md): **[V]** verified in Jellyfin's docs source (see `../12-verification-log.md` V5, V14), **[S]** search summary, **[K]**, **[U]**.
Media storage and streaming (this page) is separate from media acquisition ([`E-downloads-media-management.md`](E-downloads-media-management.md)).

## Jellyfin (full profile)

| | |
|---|---|
| **Problem it solves** | Streams your own movies, shows and music to TVs, phones and browsers, with accounts, resume and metadata |
| **Class / when** | **Recommended** if you have a media library / Stage 2 (Phase 8f) |
| **Why this, not simpler** | A shared folder plays on a PC but gives TVs no library, artwork, subtitles or per-person history |
| **Alternatives** | Plex (see below), Emby, Kodi **[K]** |
| **Hardware / storage** | 8 GB RAM recommended (4 GB may do on headless Linux); 100 GB SSD for the OS, Jellyfin files and transcode cache; Gigabit Ethernet; at least 20 Mbps upload for remote use **[V]**. Library size is your media size |
| **Hardware acceleration** | Strongly advised: software transcoding is very demanding and HDR-to-SDR tone-mapping in software can overwhelm even a Ryzen 9 5950X **[V]**. Intel iGPUs (for example N100, i5-11400, Pentium Gold G7400) are the easy path on Linux; avoid Intel J/M/N/Y parts up to 11th gen, AMD graphics, and SBCs such as the Raspberry Pi 5 **[V]**. Jellyfin 10.11 needs a CPU with SSE4.1 **[V]**. Older Intel graphics: Linux Quick Sync (QSV) works from Broadwell (5th gen) onward; earlier parts use VA-API (the `i965` driver); H.264 is supported on any QSV-capable GPU, HEVC 8-bit from Skylake, HEVC 10-bit from Kaby Lake **[V]**. On an old dual-core laptop plan for **direct play**, not transcoding. Details in Part D section 5 |
| **Dependencies** | A filesystem path for media (mounted **read-only**), a config directory and a cache/transcode directory on SSD. No external database |
| **Install / Compose** | Official image. For Intel acceleration the docs say the image already contains the Intel media drivers and OpenCL runtime; you pass the host's `render` group ID (`group_add`) and the `/dev/dri/renderD128` device. On some releases the group is `video` or `input` **[V]**. Their example uses host networking for discovery; avoid it unless you need LAN auto-discovery (Jellyfin's discovery uses UDP 7359 and must stay on the LAN) **[V]** |
| **Exposure / access** | **Class 2.** Ports: 8096/TCP HTTP, 8920/TCP HTTPS, 7359/UDP discovery **[V]**. Terminate HTTPS at Caddy rather than in Jellyfin (the docs strongly recommend a reverse proxy) and configure **known proxies** or forwarded addresses will be wrong **[V]**. Avoid a Base URL unless required: it breaks some integrations **[V]**. Do not publish through Cloudflare: its terms restrict serving video via the CDN without its paid services **[S]/[U]** |
| **Authentication / security** | Separate admin account from daily accounts; per-user library access; no native MFA described in the pages I read **[U]**, so the Tailscale identity (MFA) is the compensating control; disable remote access for users who do not need it |
| **Backup / recovery** | Back up the config directory (users, watch history, metadata) with restic; media is local-only or not at all (re-acquirable). Cache and transcode directories are disposable |
| **Maintenance / cost** | Monthly updates (pinned tag); read release notes; free |
| **Limits / devices** | See the client table; client codec support decides direct play vs transcode |
| **Continuous?** | Yes |
| **Avoid when** | Your TVs cannot run a Jellyfin client and you do not want to buy a streaming stick; or no media library exists |

### Media organisation **[V]**

```
Movies/Movie Name (2019) [imdbid-tt1234567]/Movie Name (2019).mkv   one folder per movie
Shows/Series Name (2010)/Season 01/Series Name S01E01.mkv           series, then season folders
```

Subtitles beside the file (`.srt`), optional `.nfo` metadata, extras in the folder. Library scans run on a schedule and optionally on file-change monitoring; metadata comes from online providers; a wrong folder name is the usual cause of "wrong movie matched".

### Direct play vs transcoding (summary; full table in Part D)

Direct play costs almost no CPU. Transcoding is triggered by an unsupported codec/container, a bandwidth cap lower than the file bitrate, burned-in image subtitles, or HDR-to-SDR conversion **[K]**. Prefer text subtitles (SRT) over image subtitles **[K]**, cap remote bitrate near 70% of your upload when it is under 100 Mbps **[V]**, and give the server a hardware encoder. Multiple concurrent remote streams multiply both upstream bandwidth and transcode load.

### Client support **[V]** (Jellyfin's client list, 2026-10-09)

| Platform | Clients listed |
|----------|----------------|
| Browsers | Jellyfin Web; supported browsers: Firefox, Chrome, Safari (macOS and iOS), Edge |
| Android / Android TV / Fire OS | Jellyfin for Android; Jellyfin for Android TV (also Fire OS); third-party Findroid, Streamyfin |
| iOS / Apple TV (tvOS) | Jellyfin for iOS; Swiftfin (iOS and tvOS); third-party Streamyfin |
| Smart TVs | Jellyfin for LG webOS; Jellyfin for Samsung Tizen; Roku; Xbox |
| Desktop / media centres | Jellyfin Media Player and MPV Shim; Kodi add-ons (Jellyfin for Kodi, JellyCon); music clients (Supersonic, Feishin, Finamp and others) |

Do not promise a client works on **your** device: TV clients depend on the TV's OS version and codec support, so check the specific model before buying or planning. Smart TVs generally cannot run Tailscale; for remote viewing use a streaming stick or Android TV/Apple TV device that can **[K]**.

## Plex (short profile)

| | |
|---|---|
| Class / when | **Optional** / only if a client you need works better with it |
| Facts **[S]** | Hardware-accelerated transcoding requires a paid Plex Pass; since April 2025 viewers without a Pass need a paid Remote Watch Pass for remote streaming unless the server owner has a Pass; the lifetime Plex Pass rose to US$749.99 in July 2026 and a five-year plan was added at US$249.99. Confirm on plex.tv |
| Other points **[K]** | Closed-source, depends on a Plex account for sign-in features |
| Verdict | Jellyfin gives hardware transcoding and remote access without a subscription; choose Plex only for a specific client or feature |

## Optional media-management tools

Subtitle automation, request portals and statistics add moving parts. If you adopt a request portal, note that **Overseerr is being superseded by Seerr, a merged Overseerr/Jellyseerr project [V]**: start with Seerr and check its current docs. Install none of these until the basic library works.
