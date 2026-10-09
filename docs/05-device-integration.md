# Part F - Device integration matrix

Labels: **[V]** verified in project docs, **[S]**, **[K]** stable knowledge, **[U]** unverified. Command tags: **[R]** read-only, **[W]** changes something on the client.
**Do not assume compatibility.** Check the actual device model, OS version and app version before planning around it; client availability and codec support vary.

## Four ways a device connects: do not mix them up

| Way | What it is | Examples |
|-----|-----------|----------|
| Native app | A purpose-built client talking to one service | Immich app, Jellyfin app, Bitwarden clients |
| Browser | The service's web UI | Immich web, Jellyfin web, Paperless web |
| Network share | A filesystem protocol | SMB drive, SFTP |
| VPN-based access | Makes the private network reachable from anywhere | Tailscale |

A VPN does not replace the app or the share: it only makes them reachable.

## Master matrix

| Client | Tailscale needed? | Browser enough? | LAN access | Remote access | Files | Photo/video upload | Media | Sync | Key limits |
|--------|-------------------|-----------------|------------|---------------|-------|--------------------|-------|------|-----------|
| **Android phone** | Yes for remote | For most web UIs | Apps with the server's LAN name | Tailscale app, then same names | SMB-capable file manager | Immich app (background limits) | Jellyfin app | Folder-sync tools; the official Syncthing app is discontinued **[V]** | Battery optimisation kills background jobs **[V]**; one VPN at a time |
| **iPhone** | Yes for remote | For most web UIs | Same | Same | Files app "Connect to Server" (SMB) | Immich app; **iOS decides when background uploads run; Background App Refresh must be on [V]** | Jellyfin for iOS or Swiftfin **[V]** | No official Syncthing; third-party apps limited by iOS **[K]** | Background execution limits |
| **Android tablet / iPad** | Yes for remote | Yes | Same | Same | As phone | Not used for upload usually | Jellyfin apps | As phone | Same |
| **Windows PC** | Yes for remote | Yes | Mapped SMB drive | Tailscale, then the same drive | SMB, SFTP clients | Immich web / CLI uploads | Jellyfin Media Player, browser | Syncthing, Nextcloud client | Windows may refuse guest SMB logons **[K]** |
| **Linux PC** | Yes for remote | Yes | SMB mount, SFTP/SSHFS | Tailscale | `mount.cifs`, GVFS, `sshfs` | Web / CLI | Jellyfin web, Kodi, MPV Shim **[V]** | Syncthing | Package/repo choices vary by distro |
| **macOS** | Yes for remote | Yes | Finder "Connect to Server" (`smb://`) | Tailscale | SMB, SFTP | Web / app | Jellyfin web, Swiftfin (Mac variants vary: check) | Syncthing, Nextcloud client | Finder SMB can be slow on large folders **[K]** |
| **Smart TV / streaming stick** | **Usually cannot run it** (Android TV and Apple TV devices can **[K]**) | No | Jellyfin app by LAN name | Use a stick that runs Tailscale, or only watch at home | n/a | n/a | Clients exist for webOS, Tizen, Roku, Android TV/Fire OS, tvOS (Swiftfin), Xbox **[V]** | n/a | Model and OS-version dependent; codec limits cause transcoding |
| **Other household devices** (printer/scanner, set-top boxes, consoles) | Cannot | n/a | Scan-to-SMB, DLNA, NFS | Not via Tailscale directly; use a subnet router **[K]** | SMB (scanner), NFS (some players) | n/a | DLNA or none | n/a | Weak or no authentication: keep on the LAN only |
| **Devices that cannot run Tailscale** | No | n/a | LAN | Subnet router | Same as above | n/a | n/a | n/a | Routes and firewall must allow it (Part C, C6) |
| **Remote friends and family** | Yes (invited user or shared node) | Sometimes | n/a | See `apps/O-family-access.md` | Rarely | Immich if they are users | Jellyfin app | n/a | Counts toward the plan's user limit **[S]** |

## Setting things up

### SMB mapped drives (client side)

| OS | Steps |
|----|-------|
| Windows **[W]** | Explorer > This PC > Map network drive > `\\server\share`, tick reconnect, enter the server account. Command form: `net use Z: \\server\share /user:USERNAME *` (prompts for the password) |
| macOS **[W]** | Finder > Go > Connect to Server > `smb://server/share` |
| Linux **[W]** | File manager "Connect to server" with `smb://server/share`, or `sudo mount -t cifs //server/share /mnt/share -o credentials=/path/to/credfile,uid=$(id -u)` (needs `cifs-utils`; the credentials file holds `username=` and `password=` lines and must be mode 0600; never put the password on the command line) |
| Android | A file-manager app with SMB support: add a network location with host, share, user, password |
| iOS | Files app > ... menu > Connect to Server > `smb://server/share` |

Use the server's tailnet name from outside the home and its LAN name at home. Never expose SMB to the internet.

### SFTP and remote administration

- SFTP uses your SSH key: `sftp user@server`, or mount with `sshfs user@server:/path /mnt/point` (needs `sshfs`) **[W]**; GUI clients: WinSCP, Cyberduck, Files apps with SFTP.
- Remote admin: `ssh admin@server` over the tailnet. Phones can use Termux (Android) or Blink Shell / Termius (iOS) **[K]**. Protect keys with passphrases; keep the break-glass console/LAN path.

### Photo backups

Install the Immich app, sign in with your own account, choose albums, enable backup. Details and the platform-specific caveats are in [`apps/C-personal-cloud-photos.md`](apps/C-personal-cloud-photos.md). Remember: Wi-Fi only by default; iOS controls background timing and needs Background App Refresh; Android needs battery exemptions; the first upload is slow **[V]**. For plain folders instead, use PhotoSync or FolderSync **[K]**.

### File synchronisation

Syncthing between PCs and the server (folder types, versioning, device ID verification); on Android only a community fork (the official wrapper is discontinued **[V]**); on iOS limited third-party options. Sync is not backup.

### Media streaming

Jellyfin on browsers and the clients listed above **[V]**. Prefer direct-play-friendly formats; check subtitles; at home use the LAN name; away use a Tailscale-capable device. Exact TV support depends on the model and OS version: verify before purchase.

### Family accounts

See [`apps/O-family-access.md`](apps/O-family-access.md): individual accounts, tailnet group with only the needed ports, MFA reality per app, onboarding and offboarding.

### Reaching devices that cannot run Tailscale (subnet router)

A tailnet device on the home LAN (typically the server) advertises the LAN's address range; you approve the route in the admin console; IP forwarding must be enabled on that host and the firewall must permit forwarding; Docker's forwarding policy can interfere **[V]**. Then remote tailnet devices can reach the printer, the NVR's camera network (if you choose), or a TV. Pitfalls: overlapping subnets (choose an uncommon LAN range), exposing more of the LAN than intended (limit with policy), and treating it as a substitute for installing Tailscale where possible.

## Limitations to state plainly

- **iOS background uploads** are managed by the OS; the app cannot force them. Open the app periodically **[V]**.
- **Smart-TV clients** are tied to the TV's OS and age; many models cannot run Tailscale; codec/audio support (HEVC, AV1, DTS, TrueHD, image subtitles) decides whether the server must transcode **[V for client list; K for codecs]**.
- **Android battery managers** differ by vendor and can silently stop background workers **[V]**.
- **One VPN at a time** on phones: Tailscale conflicts with other VPN apps **[K]**.

## Troubleshooting by symptom (first checks)

| Symptom | First checks |
|---------|--------------|
| App cannot connect away from home | Is Tailscale on and connected? `tailscale status` on the device; can you open the server's tailnet name in a browser? |
| Works at home, not away (or the reverse) | Which address does the app use? Set the LAN address for home Wi-Fi and the tailnet address for away |
| SMB drive will not map | Correct share path, user, password; port 445 permitted by tailnet policy; time and name resolution |
| Photos not uploading | Wi-Fi-only setting, battery optimisation (Android), Background App Refresh (iOS), server reachable, free space on the server **[V]** |
| TV plays but stutters or buffers | Is the server transcoding? Check the playback info; direct play vs transcode; bandwidth |
| Sync conflicts | Resolve the `sync-conflict` copies manually; check clocks; check which side is authoritative |

Full diagnostic procedures: [`10-troubleshooting.md`](10-troubleshooting.md).
