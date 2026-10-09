# Service-exposure matrix

How far each service may be reachable. Reasoning for the default: nothing needs an inbound router port (Part B), family reaches private services through Tailscale, and the public Cloudflare door is for a few small web apps only.

## Classes

| Class | Meaning |
|-------|---------|
| **1. LAN-only** | Reachable only from the home network. Not exposed over the tailnet, not public |
| **2. Tailscale-only** | Reachable from the LAN and over the tailnet, restricted by tailnet policy to the people/devices that need it. Never public |
| **3. Public with safeguards** | May be published through Cloudflare Tunnel + Access (no inbound ports), with the app's own authentication and the limits in Part B section 8 respected |
| **4. Unsuitable for public exposure** | Admin-only or internal. Bound to localhost, a Docker-internal network, or reachable only by admin devices. Never published, and not offered to family |

Two notes: (a) a service can be class 2 for daily use yet have an admin interface in class 4; (b) classification is a ceiling, not a requirement.

## Matrix

### Infrastructure

| Service | Class | Justification | Safeguards |
|---------|-------|---------------|------------|
| SSH | 4 | Root-equivalent access; password-guessing target | Keys only; LAN + `tailscale0` only; never port-forwarded; tailnet policy limits who can reach it |
| Docker daemon / socket | 4 | Anyone who can talk to it is effectively root on the host **[K]** | Never listen on the network; never mount into containers (or use a read-only socket proxy on an internal network) |
| Caddy admin API | 4 | Reconfigures the proxy | Localhost only |
| Caddy HTTPS listener (private apps) | 2 | The front door for private apps | Binds LAN/tailnet addresses; separate from the public tunnel |
| `cloudflared` | n/a | Outbound-only connector | Separate Docker network with only public apps; tunnel token in `/srv/secrets` |
| Tailscale | n/a | The private door | MFA on the identity account; policy; device approval |
| DNS resolver (AdGuard Home / Pi-hole), port 53 | 2 | Needed by LAN and tailnet clients; an open resolver on the internet is abused | Bind to LAN and Tailscale addresses only; verify with an external scan, including IPv6 |
| DNS resolver admin UI | 4 | Controls everyone's DNS | Admin devices only |
| Uptime Kuma | 2 | Admin dashboard | Admin devices; an optional read-only status page is class 3 and must show nothing sensitive |
| Prometheus, Grafana, exporters, cAdvisor | 4 (Grafana UI: 2 for admins) | Metrics reveal topology and versions; exporters have no authentication by default | Internal Docker network; Grafana admin only |
| Databases, Redis-style brokers | 4 | Never need a published port | No `ports:`; internal network only (Immich and Paperless-ngx run Postgres/Redis-style companions as ordinary containers **[V]**) |
| Backup repositories / rest-server | 2 (admin) | Contains all data (encrypted) | Tailnet/LAN only; append-only mode where used **[V]** |
| Router admin page | 1 | Controls the network | LAN only; strong unique password; UPnP off |

### Files, photos, media, documents

| Service | Class | Justification | Safeguards |
|---------|-------|---------------|------------|
| Samba/SMB | 2 | Chatty, legacy protocol, ransomware path; remote use works over Tailscale but is slow | Per-user accounts; `valid users`; SMB1 off; tailnet policy restricts port to chosen devices; **never published**; never behind Cloudflare |
| NFS | 1 | Trust is by IP/UID, weak authentication | LAN only, read-only exports to specific clients; not over the tailnet |
| Syncthing sync port | 2 | Peer-to-peer TLS between known devices | Disable global discovery/relays if you want it private; device IDs verified |
| Syncthing GUI | 4 | Controls what syncs | Localhost, behind SSH tunnel or admin tailnet access |
| SFTP | 4/2 | It is SSH | As SSH; give family `internal-sftp`-only accounts only if you must |
| Web file manager | 4 | A whole-filesystem browser is a high-value target; **File Browser is archived with no further security fixes [V]** | Avoid; if used, mount only one share, class 2 at most |
| Nextcloud | 2 (3 possible) | Heavier attack surface and frequent patches; clients and WebDAV do not pass Cloudflare Access cleanly **[K]** | Tailscale by default; if published: Access policy for web paths, app MFA, trusted-domain and proxy settings, fast patching, upload sizes within Cloudflare's limits |
| Immich | 2 | Holds your private photos; actively developed; its docs name Tailscale for access without an open port and warn that a reverse proxy may expose web UI and API **[V]**; Cloudflare caps proxied request bodies at 100 MB (Free/Pro) which breaks large video uploads **[V]** | Tailscale on phones; LAN address inside the app at home; no public exposure |
| Jellyfin | 2 | Serving video through Cloudflare's CDN is restricted by its terms unless you use its paid services **[S]/[U]**; bandwidth heavy | Tailscale; separate admin and user accounts; discovery (UDP 7359) stays on the LAN **[V]** |
| Plex | 2 | Cloud-account dependent; remote streaming has its own paywall **[S]** | Same as Jellyfin |
| Paperless-ngx | 2 | Contains identity, tax, medical records | Tailscale only; never public; app MFA on **[V]** |
| Vaultwarden | 2 (public: exceptional) | Highest-value secrets; clients are non-browser apps so Cloudflare Access cannot sit in front cleanly **[K]** | HTTPS required; disable open signups and the admin page; MFA; tested backups; offline emergency kit |
| Authelia / Authentik portal | 2 (3 only to protect public apps) | Gatekeeper; a bug here is catastrophic | Keep SSH, Tailscale, Vaultwarden and the portal's own recovery **out** of its protection |

### Automation, development, AI, cameras, games

| Service | Class | Justification | Safeguards |
|---------|-------|---------------|------------|
| qBittorrent, Prowlarr, Sonarr, Radarr, Lidarr, Usenet clients | 4 | Admin UIs with API keys that can reach files; legal/privacy exposure | LAN/tailnet admin only; download client routed through a VPN container if you use torrents; mounts limited to `media-root` |
| n8n editor | 4 | Stores credentials, can run code | Admin only; webhook endpoints, if needed, are the only class 3 part, with secret tokens |
| Forgejo / Gitea | 2 | Source code, tokens | Tailscale; SSH git on a non-default port still not public |
| code-server | 4 | Remote code execution by design | Admin tailnet only; separate network; no `docker.sock`; no personal-data mounts |
| Ollama | 4 | Binds localhost by default **[V]**; no authentication layer of its own **[K]** | Keep on localhost or an authenticated proxy; never publish |
| Frigate authenticated port (8971) | 2 | The documented port for reverse proxies **[V]** | Tailscale; strong admin password (12+ characters **[V]**) |
| Frigate unauthenticated port (5000) | 4 | Documented as internal, unauthenticated **[V]** | Docker-internal only |
| Camera web UI / RTSP / ONVIF | 1 | Weak vendor firmware, default credentials | Camera network with no internet; only the NVR may talk to cameras |
| Game server | special | Public by nature; Cloudflare Tunnel does not carry arbitrary game UDP and Spectrum on Pro covers only specific protocols such as Minecraft/SSH **[S]** | Tailscale for friends, or a VPS relay, or direct port with a whitelist; isolate from personal data; see `N-game-servers.md` |
| Small public web app or form (example) | 3 | Small payloads, simple auth, deliberate sharing | Cloudflare Access + app login; rate limits; no admin paths; tested kill switch |

## Checklist before anything is made class 3

1. The app has its own authentication and I know how to rotate its admin credential.
2. Payload sizes and protocols fit Cloudflare's limits (100 MB request body on Free/Pro **[V]**; HTTP/HTTPS, and TCP/SSH/RDP/SMB only through a client program, no UDP **[V]**).
3. An Access policy exists (who, MFA, session length) and I tested it from a non-tailnet device.
4. Only the specific hostname is routed; no wildcard routes to internal services.
5. The app runs on the `public` Docker network only, with no access to databases of other stacks.
6. Backups are restore-tested (Phase 6) and alerts exist (Phase 7).
7. A kill switch (disable the public hostname) is documented and tested.
8. The exposure inventory (Part K) is updated and an external scan shows nothing else open.
