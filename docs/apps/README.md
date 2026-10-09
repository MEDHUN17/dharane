# Part E - Application catalogue

Read [`00-exposure-matrix.md`](00-exposure-matrix.md) first: it decides what may be reachable how. Then use the category files:

| File | Category |
|------|----------|
| [`A-remote-access-infrastructure.md`](A-remote-access-infrastructure.md) | Tailscale, Cloudflare (DNS, Tunnel, Access), Caddy, Traefik, Nginx Proxy Manager, local DNS |
| [`B-file-sharing-sync.md`](B-file-sharing-sync.md) | Samba, NFS, Syncthing, SFTP, web file managers, Nextcloud |
| [`C-personal-cloud-photos.md`](C-personal-cloud-photos.md) | Immich, phone upload clients, Immich vs Nextcloud |
| [`D-media-server.md`](D-media-server.md) | Jellyfin, Plex, media layout, client support |
| [`E-downloads-media-management.md`](E-downloads-media-management.md) | qBittorrent, Prowlarr, Sonarr/Radarr/Lidarr, Usenet clients (optional, legal content only) |
| [`F-secrets-and-identity.md`](F-secrets-and-identity.md) | Vaultwarden, Bitwarden self-host, Authelia, Authentik |
| [`G-documents-productivity.md`](G-documents-productivity.md) | Paperless-ngx, OCR, office suites |
| [`H-monitoring.md`](H-monitoring.md) | Uptime Kuma, Prometheus stack, smartd (details in Part H) |
| [`I-adblocking-dns.md`](I-adblocking-dns.md) | AdGuard Home, Pi-hole, alternatives, failure modes |
| [`J-automation.md`](J-automation.md) | cron, systemd timers, n8n, webhooks |
| [`K-development-personal-infra.md`](K-development-personal-infra.md) | Git hosting, code-server, dev containers, small web apps |
| [`L-local-ai.md`](L-local-ai.md) | Ollama and local inference |
| [`M-cctv-nvr.md`](M-cctv-nvr.md) | Frigate and alternatives, camera networking |
| [`N-game-servers.md`](N-game-servers.md) | Minecraft, Valheim-class, Factorio-class servers |
| [`O-family-access.md`](O-family-access.md) | Accounts, permissions, onboarding/offboarding, MFA reality per app |

## Conventions

- **Class**: *Essential* (built first), *Recommended* (add when you have the need), *Optional*, *Advanced* (experiments, measured headroom required).
- **When**: *Now* (Stage 1), *Stage 2/3/4*, *Later*, *Not at all*.
- **Evidence labels** as everywhere: **[V]** verified in the project's docs on 2026-10-09 (see [`../12-verification-log.md`](../12-verification-log.md)), **[S]** search summary, **[K]** stable knowledge, **[E]** estimate, **[U]** unverified. Unlabelled statements are **[K]**.
- **No invented specifics.** Image names, ports, environment variables and Compose files are deliberately not given here: they change between versions. They are taken from the project's current install documentation at the phase where the app is installed (Phase 8).
- **Full profiles** (14 rows) for Essential and Recommended items; **short profiles** (table rows) for Optional and Advanced.
- Every profile answers: what problem it solves, why not something simpler, what it needs, how it is secured/maintained/backed up/recovered, and when to avoid it.

## Install timing at a glance

| When | Applications |
|------|--------------|
| **Now (Stage 1)** | Tailscale, restic backups, smartd, push channel + external heartbeat |
| **Stage 2** | Domain + Cloudflare DNS, Caddy, Uptime Kuma, Samba and/or Syncthing, Immich, Jellyfin (if media), Paperless-ngx (if paper), AdGuard Home (internal DNS first) |
| **Stage 3** | Household DNS switch-over with a second resolver, Vaultwarden (after proven backups), Cloudflare Tunnel + Access for chosen web apps, optional SSO |
| **Stage 4** | Frigate/NVR, game servers |
| **Later / optional** | Nextcloud, download stack, Forgejo, code-server, n8n, Prometheus stack |
| **Experiments** | Ollama / local AI, Headscale, Proxmox, Kubernetes |
| **Not at all** | File Browser (archived, no security fixes **[V]**), Overseerr (superseded **[V]**), Watchtower-style auto-updaters, anything needing the Docker socket without a socket proxy, any app that must be published straight to the internet |
