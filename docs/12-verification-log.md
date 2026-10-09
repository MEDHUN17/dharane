# Verification log

Everything stated as fact in this blueprint that depends on a version, limit, or vendor policy is recorded here with how it was checked.
Checked on **2026-10-09**. Re-verify before acting, especially anything marked [S] or [U].

## Environment constraint

This build session's network policy blocked most documentation sites (for example tailscale.com, debian.org, docs.docker.com, docs.immich.app, developers.cloudflare.com, caddyserver.com, jellyfin.org). Where possible I read the **documentation source files hosted on GitHub** (raw.githubusercontent.com), which is the same text the sites render. Other facts came from web-search summaries and are labelled [S].

## [V] Verified from the project's own documentation source

| ID | Fact | Source |
|----|------|--------|
| V1 | Immich: minimum 6 GB RAM / 2 cores, recommended 8 GB / 4 cores; 4 GB possible only with machine learning disabled; Postgres data on local SSD, never a network share, typically 1-3 GB; thumbnails/transcodes add 10-20%; `docker compose` plugin required, legacy `docker-compose` unsupported; ML container on amd64 needs x86-64-v2 since v3; Docker-in-LXC not recommended | immich-app/immich `docs/docs/install/requirements.md` |
| V2 | Docker: published ports are diverted before ufw/INPUT chains, so ufw is effectively bypassed; Docker is only compatible with `iptables-nft`/`iptables-legacy` rules (raw `nft` rules unsupported); nftables backend exists (experimental); publish to `127.0.0.1` to limit exposure; `DOCKER-USER` chain for custom filtering | docker/docs `content/manuals/engine/network/packet-filtering-firewalls.md`, `firewall-iptables.md`, `port-publishing.md`, `install/debian.md` |
| V3 | Docker Engine supports Debian 13 (stable) and Debian 12 (oldstable); architectures amd64, armhf, arm64, ppc64le | docker/docs `content/manuals/engine/install/debian.md` |
| V4 | Nextcloud: Ubuntu 26.04 LTS and RHEL 10 recommended; Debian 13 supported; PostgreSQL 14-18 (18 recommended), MariaDB 11.8 recommended; PHP 8.5 recommended; 128 MB minimum / 512 MB recommended RAM per process | nextcloud/documentation `admin_manual/installation/system_requirements.rst` |
| V5 | Jellyfin: 100 GB SSD for OS/Jellyfin/transcode cache; gigabit Ethernet; 20 Mbps upload for remote; 8 GB RAM recommended (4 GB may suffice headless Linux); iGPU recommendations (e.g. Intel N100, i5-11400, Pentium Gold G7400); Intel J/M/N/Y up to 11th gen and AMD graphics not recommended; Raspberry Pi/most SBCs too slow; software HDR tone-mapping extremely demanding; 10.11 needs SSE4.1; cap bandwidth near 70% of upstream if under 100 Mbps | jellyfin/jellyfin.org `docs/general/administration/hardware-selection.md` |
| V6 | Frigate: Coral no longer recommended for new installs; detectors include OpenVINO (Intel iGPU/Arc/NPU), Hailo, NVIDIA, ROCm and others; Wi-Fi cameras not recommended; dual-NIC mini PC suggested to isolate a camera network; Intel N100 about 15 ms OpenVINO inference and single detector instance | blakeblackshear/frigate `docs/docs/frigate/hardware.md` |
| V7 | Paperless-ngx: Docker Compose recommended; PostgreSQL recommended for new installs; Redis-compatible broker required; optional Tika/Gotenberg compose variants; install script available | paperless-ngx/paperless-ngx `docs/setup.md` |
| V8 | Caddy: automatic HTTPS; HTTP challenge needs port 80, TLS-ALPN needs 443, DNS challenge needs no open ports and is required for wildcards; DNS provider support is by community plugins; wildcard certificates avoid leaking subdomain names to CT logs; local trust-store install "not guaranteed", especially in containers | caddyserver/website `src/docs/markdown/automatic-https.md` |
| V9 | Compose spec: `compose.yaml` is the preferred filename; bind-mount `create_host_path` (default true, can be set false); `depends_on` conditions incl. `service_healthy`; keys `read_only`, `cap_drop`, `security_opt`, `mem_limit`, `cpus`, `pids_limit`, `healthcheck`, `tmpfs` exist | compose-spec/compose-spec `03-compose-file.md`, `05-services.md` |
| V10 | Ubuntu: 26.04 LTS released April 2026, standard maintenance to May 2031; 24.04 to May 2029; 22.04 to May 2027 | ubuntu.com/about/release-cycle (fetched directly) |

## [S] Reported by web-search summaries of official pages (could not open directly)

| ID | Fact | Pointer |
|----|------|---------|
| S1 | Cloudflare request body limit: Free 100 MB, Pro 100 MB, Business 200 MB, Enterprise 500 MB; larger returns 413 | developers.cloudflare.com (Workers platform limits, error 413) |
| S2 | Cloudflare replaced "section 2.8" with a CDN-specific service term; video and large files via the CDN are tied to Cloudflare's own paid services; current wording seen only second-hand | blog.cloudflare.com/updated-tos |
| S3 | Tunnel public-hostname service types: HTTP, HTTPS, UNIX sockets, TCP (TCP needs `cloudflared` on the client); no documented anonymous public UDP; private TCP/UDP via WARP | developers.cloudflare.com (tunnel routing) |
| S4 | Spectrum: not on Free; Pro = Minecraft and SSH (one app each); Business adds RDP; generic TCP/UDP = Enterprise | developers.cloudflare.com/spectrum/protocols-per-plan |
| S5 | Debian 13 "trixie": released 2025-08-09; full support to 2028-08-09; LTS to 2030-06-30 | debian.org/releases/trixie |
| S6 | Tailscale: certificate (HTTPS) names for devices appear in Certificate Transparency logs; Funnel limited to ports 443/8443/10000, TLS only, undisclosed bandwidth limits | tailscale.com docs |
| S7 | restic 0.19.1 (2026-07); Borg 1.4.4 stable (2026-03), Borg 2.0 still beta; Kopia v0.23.x | project release pages |
| S8 | Immich users report Cloudflare Tunnel's 100 MB cap breaks large uploads; common workaround is a LAN/other endpoint in the mobile app | immich-app/immich discussions |

## [U] Unverified or conflicting - do not rely on yet

| ID | Item | State |
|----|------|-------|
| U1 | Tailscale free "Personal" plan limits | Sources conflict: older reports say 3 users / 100 devices; newer reports say 6 users / unlimited user-owned devices after an April 2026 pricing change. tailscale.com was unreachable from this session. **Check the pricing page before relying on either.** |
| U2 | Current text of Cloudflare's CDN service term for video/large files on Free/Pro/Business | Second-hand only |
| U3 | All Indian prices (domain, storage, drives, UPS, electricity tariffs) | Not yet researched; Part I will cite dated sources |

## Not yet verified (will be checked at the phase that needs them)

Tailscale policy file syntax, subnet-router steps and exit-node flags (Phase 5); restic flags and backend settings (Phase 6); Caddy DNS plugin build and Cloudflare token scope (Phases 8-9); Cloudflare Access/WAF features on the free plan (Phase 9); every application's current Compose file and environment variables (Phase 8).
