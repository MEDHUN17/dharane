# Part C - Core design decisions

Labels: **[V]** verified in docs, **[S]** search summary, **[K]** stable knowledge, **[E]** estimate, **[U]** unverified (see `00-executive-summary.md`).
Prices are intentionally not quoted here; they are researched with dates and sources in Part I.

## 1. Summary

| # | Decision | Recommended | Main alternative | Change the recommendation when... |
|---|----------|-------------|------------------|-----------------------------------|
| C1 | Host OS | **Debian 13 stable** | Ubuntu Server 26.04 LTS | Very new hardware needs a newer kernel/driver stack than Debian ships, or you want Canonical's Pro/Livepatch |
| C2 | Server role | **General-purpose Linux + Docker** | NAS OS (TrueNAS/OMV/Unraid) or Proxmox | Primary job becomes a many-disk NAS with ZFS; or you need several isolated VMs |
| C3 | Filesystem | **ext4** everywhere at Stage 1 | XFS, Btrfs, ZFS | Multi-disk pool with snapshots/checksums needed, and you accept the extra learning/RAM |
| C4 | Redundancy | **Backup disk + off-site first; RAID1 later if uptime matters** | RAID1/5/6, ZFS mirror | Family depends on the data daily and downtime from a disk swap + restore is unacceptable |
| C5 | Runtime | **Docker Engine (official repo) + Compose plugin**, rootful with hardening | Podman/Quadlet, rootless Docker | You specifically want daemonless/systemd-native units and accept non-standard app guides |
| C6 | Private access | **Tailscale on the host** | Plain WireGuard, ZeroTier, Headscale | You have a public VPS and want full control of the control plane (Headscale), or you must avoid a third-party coordination service |
| C7 | Public access | **None by default; Cloudflare Tunnel + Access for chosen web apps** | Port-forward + Caddy, VPS reverse proxy, Tailscale Funnel | You need non-HTTP public protocols (games) or large uploads/video |
| C8 | Names / TLS | **Own domain on Cloudflare DNS, wildcard cert via DNS challenge, split DNS** | MagicDNS + `tailscale serve`; internal CA | Stage 1: start with MagicDNS; move to own domain at Stage 2 |
| C9 | Reverse proxy | **Caddy** | Traefik, Nginx Proxy Manager | Dozens of fast-changing containers (Traefik); you insist on a GUI (NPM) |
| C10 | Backup tool | **restic** | Borg 1.4, Kopia | You want a built-in UI + policies (Kopia), or a Borg-native target such as a Borg-only host |
| C11 | Off-site target | **S3-compatible object storage, plus a rotated external drive** | Friend's machine over Tailscale, SFTP storage box | Data volume or privacy needs differ (Part I) |
| C12 | Ad-blocking DNS | **AdGuard Home (or Pi-hole) + a secondary resolver** | Router-level blocking, browser blockers | Router firmware already offers reliable filtering |
| C13 | Monitoring | **smartd + shell checks + Uptime Kuma + ntfy-style push + external heartbeat** | Prometheus + Grafana + Alertmanager | More than ~10 services or you want trend graphs |
| C14 | Automation | **systemd timers + shell scripts** | cron, n8n | Cross-application workflows with webhooks |
| C15 | Identity | **Per-app accounts + MFA; no SSO yet** | Authelia, Authentik, Pocket ID | Three or more apps and several family users make per-app accounts a chore |
| C16 | Secrets | **Root-owned 0600 files outside Git; recovery kit offline** | SOPS+age in a private repo, Docker secrets | You want encrypted secrets versioned alongside configs |

---

## C1. Host operating system

| Attribute | Debian 13 "trixie" (recommended) | Ubuntu Server 26.04 LTS (second choice) |
|-----------|----------------------------------|------------------------------------------|
| Support window | Full support to 2028-08-09, LTS to 2030-06-30 **[S]** | Standard security maintenance to May 2031 **[V]** (released Apr 2026) |
| Docker | Officially supported platform (Trixie 13 stable, Bookworm 12 oldstable) **[V]** | Officially supported by Docker **[K]** |
| App guidance | Immich: "Ubuntu, Debian, etc." **[V]** | Nextcloud lists Ubuntu 26.04 LTS as recommended and Debian 13 as supported **[V]** |
| Footprint | Very small headless install | Small, but ships snap/Canonical defaults |
| Hardware enablement | Older kernel by default; newer via backports **[K]** | Newer kernels/firmware sooner **[K]** |
| Advantages | Stability, predictability, minimal surprises, no snaps, tiny attack surface | Hardware support, huge community answers, optional Pro/Livepatch |
| Disadvantages | Newest GPUs/NICs/Wi-Fi may need backports | Faster-moving defaults; snap-first packaging for some tools |
| Security | Security team + `unattended-upgrades` **[K]** | Same mechanism; Livepatch is an Ubuntu Pro feature (Pro is free for personal use on a limited number of machines **[K]**, confirm terms) |
| Resources | ~0.2-0.4 GB RAM idle headless **[E]** | Similar **[E]** |
| Cost | Free | Free (Pro optional) |
| Complexity | Low | Low |
| Choose the other when | - | New iGPU/NIC not supported by Debian's kernel, or you want Livepatch |

Other genuinely relevant options and why they are not primary: **Fedora/RHEL clones** (faster cadence or a different packaging world; fine but fewer home-server guides), **NixOS** (excellent reproducibility, steep learning curve, not recommended for a first server), **Raspberry Pi OS** (only if the host is a Pi).

### Install and recovery plan (details in Phase 1 of the roadmap)

Checklist covers: installer media and checksum verification; partitioning (one SSD, ext4 root, optional separate `/var/lib/docker` only if the SSD is large); hostname and an admin user (no direct root login); SSH install with keys only; host firewall; updates; time sync; unattended security updates; power behaviour (auto-boot after power loss in firmware, lid/suspend disabled on laptops); log rotation limits; headless operation; and a **rebuild path**: reinstall Debian, install Docker and Tailscale, clone the config repo, restore appdata from restic.

## C2. General-purpose Linux vs NAS OS vs virtualisation

| Option | Fits when | Costs |
|--------|-----------|-------|
| **General-purpose Linux + Docker** (recommended) | Apps matter more than disk-pool features | You assemble storage, shares and backups yourself (this plan does) |
| OpenMediaVault (Debian-based UI) | Mostly a NAS, you like a web UI for shares/SMART | Two management layers; plugin model; still need Docker discipline |
| TrueNAS / Unraid | Many disks, ZFS or parity pool is the main job | App model is platform-shaped; Unraid is paid **[K]** |
| Proxmox VE | Several isolated VMs, snapshots of whole VMs, PCIe passthrough | RAM/disk overhead, extra layer to back up and patch; Immich documents Docker-in-LXC as not recommended while full VMs are fine **[V]** |

Start on bare metal. Proxmox is a Stage 6 candidate only if you need VM isolation or multi-OS testing.

## C3. Filesystem

| FS | Strengths | Weaknesses | Verdict |
|----|-----------|------------|---------|
| **ext4** | Mature, simple, excellent recovery tools, works with everything incl. Immich DB guidance (Unix permissions required) **[V]** | No checksums, no snapshots | **Recommended default** |
| XFS | Great with big files and parallel IO; cannot shrink **[K]** | Same lack of checksums/snapshots | Fine for large media disks |
| Btrfs | Checksums, snapshots, send/receive **[K]** | More moving parts; RAID5/6 profiles have long-standing caveats **[K, verify before use]** | Reasonable for a single-disk with snapshots if you learn it |
| ZFS | Checksums, snapshots, scrubs, mirrors/RAIDZ **[K]** | Out-of-tree kernel module, RAM appetite, expansion/layout planning, learning | Justified for a multi-disk pool, not for Stage 1 |

Snapshots are *not* backups (same disk, same failure domain). Use them only as a fast "undo" layer on top of real backups.

## C4. Redundancy model

| Mechanism | Protects against | Does NOT protect against |
|-----------|------------------|--------------------------|
| RAID / mirror | One disk failing (availability) | Deletion, ransomware, corruption written to both disks, fire/theft |
| Snapshot | Fast undo of recent mistakes | Disk death (same disk), site loss |
| Replication/sync (Syncthing, rsync) | Another live copy | Propagates deletions and corruption |
| **Backup** (versioned, separate, ideally off-site) | All of the above, if tested | Only as good as your last successful, restorable run |

Recommended Stage 1: single data disk + separate local backup disk + off-site repository. A second disk as a backup target is usually better value than a mirror. Add RAID1 (mdadm or Btrfs/ZFS mirror) when downtime matters more than disk cost.

## C5. Container runtime and deployment

| Attribute | Docker CE + Compose plugin (recommended) |
|-----------|------------------------------------------|
| Why | Every app in the catalogue documents it; Immich requires `docker compose` (the old `docker-compose` is unsupported) **[V]** |
| Install source | Docker's official apt repository for Debian **[V]** (steps verified at Phase 4) |
| Firewall facts | Published ports are diverted before ufw sees them **[V]**; Docker works with `iptables-nft`/`iptables-legacy`, not hand-written `nft` rules **[V]**; the nftables backend exists but is experimental **[V]** |
| Alternatives | Podman + Quadlet (daemonless, systemd-native; fewer copy-paste app guides); rootless Docker (stronger isolation, constraints on networking/devices) **[K]** |
| Security | Membership of the `docker` group is effectively root **[K]**; never mount `/var/run/docker.sock` into a container without a strong reason |
| Cost / complexity | Free / low |

### Compose convention (applies to every project)

1. One directory per project: `/srv/config/stacks/<project>/compose.yaml` (the preferred filename **[V]**) plus a committed `.env.example` and an uncommitted `.env`.
2. Pin image tags to a specific version (or digest); avoid `latest`. Keep upgrade notes per app (database major versions need care).
3. Data via **bind mounts**; for data paths use the long syntax with `create_host_path: false` so Docker refuses to start rather than silently creating an empty directory when a disk is missing **[V]**.
4. Networks: `proxy` (Caddy plus private apps), `public` (cloudflared plus public apps), and a private per-stack network for databases (consider `internal: true` **[K]**). Do not put every container on one network.
5. `restart: unless-stopped`; define `healthcheck`; use `depends_on` with `condition: service_healthy` because plain `depends_on` only orders start, it does not wait for readiness **[V]**.
6. Hardening where the app tolerates it: non-root `user:`, `read_only: true` plus `tmpfs`, `cap_drop`, `security_opt`, `mem_limit`, `cpus`, `pids_limit` (these keys exist in the spec **[V]**); `no-new-privileges` is passed via `security_opt` **[K]**. Apply gradually; some images need exceptions.
7. Log rotation configured in the daemon (the default json-file driver does not rotate **[K]**; verify in Phase 4).
8. Secrets in `.env`/secret files with mode 0600, outside Git.
9. No privileged containers and no host networking unless the app documents a need (e.g. Jellyfin DLNA discovery, some mDNS cases).

## C6. Private remote access

| Option | Advantages | Disadvantages | Notes |
|--------|------------|---------------|-------|
| **Tailscale (host install)** | Works behind CGNAT/double NAT; per-device auth; ACLs/tags; MagicDNS; subnet router; exit node; SSH integration **[K]** | Third-party coordination service; Personal (free, non-commercial) is reported as up to 6 users with unlimited user-owned devices since Tailscale's 2026-04-08 "Pricing v4" change **[S]**; older pages still show 3 users/100 devices. Confirm on the pricing page | Host install beats container: it sees the host network, SSH and subnet routing are simpler **[K]** |
| Plain WireGuard | No third party | Needs a reachable endpoint; fails behind CGNAT without a VPS | Good only with a public IP or VPS |
| Headscale (self-hosted control plane) | Removes the vendor dependency | Needs a public server; you operate it | Advanced |
| ZeroTier | Similar overlay | Different ecosystem; less common in home-server guides | Not recommended to mix with Tailscale |
| Cloudflare WARP + Tunnel private networks | Same vendor as the public door | Needs WARP client on devices; UDP needs QUIC tunnel and Gateway proxy **[S]** | Overlaps Tailscale; do not run both for the same job |

Key concepts to be taught in Phase 5: device authorisation, key expiry (disable for the server, keep for personal devices) **[K]**, tags and policy, MagicDNS and split DNS, subnet routers (need IP forwarding on the router host, route advertisement, **and** approval in the admin console; overlapping subnets break them) **[K]**, exit nodes (only for routing *all* traffic through home; unnecessary for server access) **[K]**, direct vs relayed (DERP) paths, and device revocation.

## C7. Public exposure

| Option | Verdict |
|--------|---------|
| **Do not publish** (default) | Most services need no public access if family devices run Tailscale |
| **Cloudflare Tunnel + Access** | Good for small web apps; no inbound port; Access can require identity + MFA before traffic reaches the app. Limits: 100 MB request bodies on Free/Pro **[S]**, HTTP/HTTPS/TCP only, CDN video restrictions **[S]/[U]**, and Cloudflare terminates TLS (it can see plaintext) |
| Port-forward + Caddy | Needs a public IPv4 (often unavailable on CGNAT), exposes your home IP, needs hardening and patching discipline. Avoid unless no alternative |
| VPS reverse proxy (WireGuard back to home) | Solves CGNAT and gives protocol freedom; costs a VPS and another server to secure. Consider for game servers |
| Tailscale Funnel | Public via your node; allowed ports 443/8443/10000, TLS only, undisclosed bandwidth limits, and the hostname appears in Certificate Transparency logs **[S]**. Use sparingly |
| Tailscale node sharing / family installs | Best for photos, media, files: nothing is public, access is per-user and revocable |

Never place SSH, SMB, NFS, databases, Docker APIs, admin dashboards, metrics endpoints or camera interfaces on a public hostname. Service-by-service classification is in Part E.

## C8. Names, DNS and certificates

| Approach | Pros | Cons |
|----------|------|------|
| MagicDNS + `tailscale serve` | No domain needed; free | One hostname per node (services by port/path); machine name appears in public CT logs if you request a certificate **[S]** |
| **Own domain, wildcard cert (DNS challenge), split DNS** (recommended from Stage 2) | Clean names (`photos.home.example.com`), valid certs on LAN and tailnet, no open ports; wildcard keeps individual service names out of CT logs **[V]** | Needs a domain; DNS API token to protect; local DNS must answer the internal names |
| Own domain, public A records pointing at private addresses | Works without split DNS | Publishes internal addressing; DNS-rebinding protection in many routers/resolvers drops such answers **[K]** |
| Internal CA | No public CA | Root must be installed on every device; Caddy's auto-install into trust stores is "not guaranteed", especially in containers **[V]** |

Challenge types: HTTP challenge needs port 80 reachable, TLS-ALPN needs 443, **DNS challenge needs no open port** and is required for wildcards; DNS provider support is a community plugin, so Caddy needs a build that includes your provider module **[V]**. Create a narrowly scoped DNS API token for that one zone.

Rule: **internal names are answered by your own DNS** (AdGuard/Pi-hole rewrites for LAN; Tailscale split DNS pointing the zone at the server for remote devices), so a Cloudflare DNS outage does not break private access.

## C9. Reverse proxy

| Attribute | Caddy (recommended) | Traefik | Nginx Proxy Manager |
|-----------|---------------------|---------|---------------------|
| Config style | Short Caddyfile, easy to read and diff | Labels/dynamic config, powerful | Web GUI, state in a database |
| HTTPS | Automatic, built in **[V]** | Automatic via ACME | Automatic via GUI |
| Docker discovery | Not required (static, explicit routes) | Core feature (needs Docker socket access or a socket proxy) | Manual |
| Security posture | No Docker socket needed; explicit allow-list of routes | Socket exposure must be mitigated **[K]** | GUI is another admin surface to protect |
| Version control | Excellent (one file) | Good | Poor (GUI state) |
| Resources | Low | Low-medium | Medium |
| Cost / complexity | Free / low | Free / medium | Free / low |
| Choose when | Almost always | Many dynamic containers, you want labels | You insist on a GUI |

Caddy is not required for every service: LAN-only services such as an SMB share, and admin-only ports reached over an SSH tunnel, do not need it. Proxy details to learn in Phase 8: forwarded headers (`X-Forwarded-*`), WebSocket support, upload size limits, and which networks Caddy joins.

## C10. Backup tool

| Attribute | restic (recommended) | Borg 1.4 | Kopia |
|-----------|----------------------|----------|-------|
| Version seen | 0.19.1 (2026-07) **[S]** | 1.4.4 stable (2026-03); 2.0 still beta, not for production **[S]** | v0.23.x (2026) **[S]**, pre-1.0 numbering |
| Encryption + dedup | Yes | Yes | Yes |
| Backends | Local, SFTP, S3-compatible, Backblaze, rclone, REST server **[K]** | Local and SSH/Borg servers (cloud via helpers) **[K]** | Local, S3, SFTP, rclone and more **[K]** |
| UI | None (CLI; optional wrappers) | None | Built-in web UI |
| Append-only protection | Via REST server or provider features **[K]** | Via SSH forced command **[K]** | Via provider/repo settings **[K]** |
| Why/why not | Simple, widely used, easy to script and restore | Excellent, but cloud backends are awkward | Friendly but younger; a recent release fixed a rare race that could cause data loss **[S]** |
| Choose when | Default | Backing up to a Borg-native host | You want policies + UI |

Restic repository passwords are the single point of loss: if they are lost the backups are unreadable. Store them off the server (password manager emergency kit and a printed copy). Integrity: schedule `restic check` regularly and a rotating partial data read, plus real restore tests (Part G).

## C11. Off-site destination (summary; numbers in Part I)

| Option | Privacy | Restore speed | Effort | Risk |
|--------|---------|---------------|--------|------|
| Rotated external drive (swap monthly, keep one elsewhere) | Total | Fast (drive in hand) | Manual | Recency gap between swaps |
| Trusted machine at a relative's home over Tailscale/SFTP | Good (encrypted by restic) | Depends on their uplink | Low once set | Their hardware and power |
| S3-compatible object storage (e.g. B2, R2, Wasabi) | Good (client-side encryption) | Good | Low | Recurring cost; egress/minimum-storage rules differ **[U until Part I]** |
| SFTP storage box (e.g. Hetzner) | Good | Good | Low | Foreign currency billing; latency from India |
| Consumer cloud via rclone | Good with restic encryption | Variable, API throttling | Medium | Terms of service, quotas |

Initial upload is bounded by your uplink: terabytes over a slow Indian residential upstream can take weeks. Seed the off-site copy first with the most irreplaceable data (documents, original photos).

## C12. Network-wide ad blocking

AdGuard Home and Pi-hole are both suitable **[K]**. Pick AdGuard Home for built-in encrypted upstream support and straightforward DNS rewrites (which you need for split DNS); pick Pi-hole if you already know it. Both bind only to the LAN and Tailscale interfaces; never publish port 53 to the internet (open resolvers get abused). Hand out **two** DNS servers via DHCP so a reboot of the server does not break the household. Clients do not reliably try the primary first, so **both resolvers must filter identically** (same blocklists, same local rewrites): a second server that is just the router or a public resolver will leak ads and fail to resolve your internal names for whichever clients pick it. Use a spare Pi or a second instance kept in sync. Phones/browsers using private/encrypted DNS bypass you; document that limitation. Tailscale can use your resolver as its tailnet DNS for blocking away from home.

## C13. Monitoring

Minimal stack: `smartd` for disk health, a small script for disk-space/mount/backup-age checks, Uptime Kuma for service reachability and certificate expiry, push notifications (self-hostable ntfy-style, or Telegram/e-mail), and one **external** heartbeat (a free hosted dead-man's-switch such as healthchecks.io **[K]**) so you hear about a dead server. Add Prometheus + node_exporter + cAdvisor + Grafana only when you want trends or have many services; they add RAM, storage, and maintenance. Details in Part H.

## C14. Automation mechanism

systemd timers (logging in the journal, `OnFailure=` hooks, catch-up after downtime via `Persistent=true`) **[K]** are preferred over cron for new work. Application-native schedulers handle in-app jobs (Immich jobs, Paperless consumer). n8n/webhooks only for cross-app workflows later.

## C15. Identity

Per-app accounts with unique strong passwords plus MFA, held in a password manager. An authentication gateway (Authelia, Authentik, Pocket ID) adds single sign-on and forward-auth but also a critical component that can lock you out; do not put the password manager or the gateway's own recovery behind itself. SSO never removes app-specific authorisation, API tokens or mobile-app login quirks.

## C16. Secrets

Rules: no secrets in Git; files with mode 0600 owned by root or the service account; one DNS API token with minimal scope; separate backup credentials with append-only/limited rights where the backend allows; the recovery kit (restic password, Tailscale/Cloudflare account recovery, domain registrar login, password-manager emergency sheet) stored **off the server** and in a second physical location. Optional later: SOPS+age to keep encrypted secrets beside configs in a private repo.

---

## Pending for later phases

- Exact Tailscale policy syntax and commands: verified at Phase 5 from current docs (the docs site is blocked in this environment; see `STATE.md`).
- Exact Caddy plugin/build steps and Cloudflare token scope: verified at Phase 8/9.
- Exact restic repository flags and backend settings: verified at Phase 6.
