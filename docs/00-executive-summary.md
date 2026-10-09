# Part A - Executive summary

Status: draft v0.1, 2026-10-09. Hardware is **unknown**; everything is tier-based (see Part D).
Repo is public: all names, subnets and domains below are placeholders.

## Evidence labels used in every document

| Label | Meaning |
|-------|---------|
| **[V]** | Verified on 2026-10-09 by reading the project's own documentation source. Logged in [`12-verification-log.md`](12-verification-log.md). |
| **[S]** | Reported by a web-search summary of an official page I could not open directly (network policy blocked the site). Treat as probably right; confirm before spending money. |
| **[K]** | General engineering knowledge, stable for years. Re-check the exact command or option when we reach that phase. |
| **[E]** | Estimate or rule of thumb. Must be measured on your hardware. |
| **[U]** | Unverified or sources conflict. Do not rely on it. |

## 1. The recommendation in one paragraph

Build **one boring Linux server** (Debian 13 stable on bare metal, ext4, Docker Engine with the
Compose plugin, one Compose project per application) and give it **three doors**: the home LAN,
**Tailscale** for everything private (including SSH and all family access to photos and media), and
**Cloudflare Tunnel plus Cloudflare Access** only for the few web services that are genuinely
suitable to be public. Nothing needs an open inbound router port by default, so the design works
behind CGNAT. **Backups come before data**: no irreplaceable file lands on the server until a
restore has been tested. Monitoring and automation use plain tools (smartd, systemd timers, shell
scripts, Uptime Kuma, a push-notification channel, and one external dead-man's-switch check).
Virtualisation, Kubernetes, SSO platforms and workflow engines are deliberately deferred.

## 2. Design principles

1. **Private by default.** Reachable only via LAN or Tailscale unless a written reason says otherwise.
2. **No inbound ports.** Outbound-only connectivity (Tailscale, cloudflared) works behind CGNAT and removes the most common mistake (accidentally forwarded ports). Game servers are the main exception (Part D, Part E-N).
3. **Backups before data; restores before trust.** A backup that was never restored is a hope, not a backup.
4. **One failure domain per concern.** Fast disk (OS, databases, app state) is separate from bulk disk (photos, media) and from the backup disk.
5. **Everything reproducible from Git plus backups.** Compose files and docs live in Git (no secrets); data lives in backups; the host OS is disposable.
6. **Smallest tool that does the job.** systemd timer before n8n; Caddy before Traefik; ext4 before ZFS; one VPN before three.
7. **Separate identities.** Admin account, service identities, app users and family accounts are different things (identity model in `06-security-backup.md`).
8. **Alert on things a human can act on**, and monitor from outside the box as well as inside it.
9. **Prefer reversible steps** and write the rollback before the change.
10. **Do not trust a green dashboard for data integrity.** Service up is not the same as data restorable.

## 3. Provisional assumptions (replace as you answer Part L)

| # | Assumption | Why I made it | If wrong |
|---|-----------|---------------|----------|
| 1 | One machine, headless, always on | Stated requirement | Tier choice changes (Part D) |
| 2 | Hardware could be anything from an old PC to a mini PC | Not provided | Workload placement changes |
| 3 | **CGNAT or no port-forwarding may apply** (common on Indian ISP plans) | Safest design assumption | If you have a public IPv4, game servers and direct hosting get easier, but the default design is unchanged |
| 4 | Costs in INR; electricity tariff varies by state/DISCOM | You are in India | Need your state and tariff slab for Part I |
| 5 | A handful of family users; mixed Android/iPhone/Windows | Typical | Client section (Part F) adjusts |
| 6 | You own no domain yet | Not provided | Domain purchase becomes a Stage 2/3 task |
| 7 | No UPS yet | Not provided | UPS moves up the priority list (Part J, phase 2) |
| 8 | Budget moderate; reuse existing hardware first | Cost-aware requirement | Scenarios in Part I |

## 4. Where I challenge the brief (simpler or safer alternatives)

| Idea | My position | Reason |
|------|-------------|--------|
| Expose Immich / Jellyfin through Cloudflare | **No.** Use Tailscale | Cloudflare caps proxied request bodies at 100 MB on Free/Pro **[S]**, which breaks large video uploads; serving video through its CDN is restricted by its terms unless you use its paid services **[S]**. Immich's own docs name Tailscale as the route when you cannot open a router port and warn that a reverse-proxy setup may expose both the web interface and the API **[V]**; Immich users also report the 100 MB cap breaking large uploads **[S]**. |
| Both Immich and Nextcloud | **Immich first; Nextcloud only if you need its extras** | Different jobs. Photos and videos: Immich. Plain files: SMB + Syncthing. Nextcloud adds calendar/contacts/office collaboration at the cost of a PHP/database stack to maintain. |
| Pi-hole/AdGuard on the same box as everything else | **Yes, but with a second resolver** | If it is the only DNS server, a reboot of the server takes down household internet. |
| Vaultwarden on day one | **Stage 3, after tested backups and HTTPS** | A password manager that depends on your home internet is high-impact. Clients keep an offline cache **[K]**, but recovery planning must exist first. |
| Auto-updating every container (e.g. Watchtower-style) | **No.** Notify, then update by hand in a maintenance window | A silent major-version database migration is how people lose data. |
| Proxmox or Kubernetes at the start | **No** | Adds RAM, learning, and a second system to back up with no Stage 1 benefit. Immich documents LXC+Docker as not recommended **[V]**. |
| n8n for automation | **Later, only for cross-app workflows** | Backups, disk checks and updates are one-file shell scripts on systemd timers. |
| RAID for safety | **Not first.** A second disk as a *backup* beats a mirror | RAID protects against one failure type (disk death), not deletion, ransomware or corruption. |
| Rootless Docker | **Not initially** | Real hardening, but it complicates networking, device access and many app guides. Use rootful Docker with a hardening checklist instead (Part C). |

## 5. Essential / recommended / optional / advanced

| Class | Items | Rule |
|-------|-------|------|
| **Essential infrastructure** | Debian host, SSH hardening, host firewall, unattended security updates, time sync, Docker + Compose, Tailscale (host), storage layout + SMART monitoring, restic backups (local + off-site), minimal monitoring + notifications, documentation repo | Build and validate first (phases 0-7) |
| **Recommended applications** | Caddy (when HTTPS names are needed), Immich (photos), Syncthing and/or SMB (files), Uptime Kuma, AdGuard Home or Pi-hole (ad blocking, with fallback DNS), Jellyfin (if you have media), Paperless-ngx (if you have paper to digitise) | Add one at a time, each with backup and restore notes |
| **Optional** | Vaultwarden, Nextcloud, Forgejo/Gitea, code-server, Sonarr/Radarr/Prowlarr + qBittorrent (legal content only), Authelia/Authentik, Prometheus + Grafana, n8n | Only with a stated need |
| **Advanced experiments** | Frigate/NVR, game servers, Ollama / local AI, Headscale, Proxmox, multi-host, Kubernetes | Only when hardware headroom is measured |

## 6. Minimum viable vs expanded architecture

| Layer | Minimum viable (Stage 1) | Expanded (Stages 2-5) |
|-------|--------------------------|-----------------------|
| Hardware | One machine, 1 SSD + 1 data disk + 1 backup disk | Add UPS, separate backup or NAS box, optional second compute host |
| OS | Debian 13, headless | Same; second host same OS |
| Remote access | Tailscale on host, SSH keys only | Tailnet ACLs/tags, subnet router for non-Tailscale devices, family sharing |
| HTTPS / names | Tailscale MagicDNS name + published ports bound to localhost or the Tailscale IP | Own domain, Caddy, wildcard cert via DNS challenge, split DNS |
| Public access | None | Cloudflare Tunnel + Access for selected web apps |
| Apps | None yet, or one low-risk app to prove the pipeline | Immich, Jellyfin, Paperless, Vaultwarden, ad blocking |
| Backups | restic to local disk + one off-site repo, tested restore | Retention tuning, per-dataset policies, quarterly full restore drill |
| Monitoring | smartd + disk/mount/backup checks + push notifications + external heartbeat | Uptime Kuma, optional Prometheus/Grafana |
| Automation | systemd timers + shell | Selected n8n workflows if justified |

## 7. What is deliberately not in the first build

Public hosting, SSO, NVR, game servers, local AI, download automation, virtualisation, orchestration, GPU work.
Each has a gate in the staged growth plan (Part J, stages) and is revisited when its precondition is met.

## 8. Next documents

- Architecture, flows and failure behaviour: [`01-architecture.md`](01-architecture.md)
- Decision table: [`02-design-decisions.md`](02-design-decisions.md), storage layout: [`02a-storage-layout.md`](02a-storage-layout.md)
- Hardware tiers and capacity: [`03-hardware-capacity.md`](03-hardware-capacity.md)
- Application catalogue and exposure matrix: [`apps/README.md`](apps/README.md)
- Devices: [`05-device-integration.md`](05-device-integration.md); security and backup: [`06-security-backup.md`](06-security-backup.md); automation and monitoring: [`07-automation-monitoring.md`](07-automation-monitoring.md); costs: [`08-cost.md`](08-cost.md)
- Roadmap: [`09-roadmap.md`](09-roadmap.md) and growth stages [`09a-growth-stages.md`](09a-growth-stages.md); troubleshooting: [`10-troubleshooting.md`](10-troubleshooting.md); templates: [`templates/README.md`](templates/README.md)
- Questions for you: [`11-information-needed.md`](11-information-needed.md)
