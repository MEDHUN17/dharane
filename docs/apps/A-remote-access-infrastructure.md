# A. Remote access and infrastructure

Rule: one tool per role. Do not run Tailscale, WARP and WireGuard for the same job, or Caddy, Traefik and Nginx Proxy Manager together.
Labels: **[V]** verified, **[S]** search summary, **[K]** stable knowledge, **[U]** unverified (see [README](README.md)).

## Tailscale (full profile)

| | |
|---|---|
| **Problem it solves** | Reaching the server (SSH, photos, files, media) from anywhere, encrypted, without open router ports, even behind CGNAT or double NAT |
| **Class / when** | **Essential** / Now (Phase 5) |
| **Why this, not simpler** | The alternative to a managed overlay is WireGuard + dynamic DNS + a forwarded port, which fails behind CGNAT. Alternatives: plain WireGuard (needs a reachable endpoint), ZeroTier, Headscale (self-hosted control plane; needs a public server), Cloudflare WARP + Tunnel private networks (overlaps; WARP needed on clients) **[S]** |
| **Hardware / storage** | Negligible (tens of MB RAM); any tier |
| **Dependencies** | A tailnet identity account (the identity provider you log in with); TUN support on the host; Tailscale's coordination service for logins, key rotation and policy changes **[K]** |
| **Install / Compose** | **Host package** from Tailscale's official repository (steps verified at Phase 5; their docs site is blocked in this build environment). Host install is preferred over a container: it sees the host network, simplifies SSH and subnet routing, and survives Docker problems. Containerised Tailscale is for isolating one app's network identity, not for the host itself |
| **Exposure / access** | It *is* the private door: services reachable at `100.x.y.z` or `server.<tailnet>.ts.net`. Services stay bound to localhost/LAN/Tailscale addresses |
| **Authentication / security** | Login via your identity provider with **MFA**; device approval; key expiry (disable on the server, keep on personal devices); tags for servers; an explicit access policy replacing allow-all; Tailscale SSH optional; revocation by removing the device. The identity account is now a crown jewel: passkey or hardware key |
| **Backup / recovery** | Keep the policy file in the private repo. Nothing else to back up: if the server is lost, enrol a new node and revoke the old one. Recovery depends on being able to log into the identity provider (recovery codes in the kit) |
| **Maintenance / cost** | Keep the client updated through apt in the monthly window. Free "Personal" plan reported as up to 6 users with unlimited user-owned devices since 2026-04-08 **[S]**, for non-commercial use; confirm on the pricing page |
| **Limits / device compatibility** | Phones allow one active VPN at a time, so it conflicts with a commercial VPN **[K]**. Clients exist for Android, iOS, Windows, macOS, Linux; Android TV and Apple TV have apps **[K]**; LG/Samsung smart TVs, printers, cameras and consoles cannot run it (use a subnet router, section below, or a streaming stick that can) |
| **Continuous?** | Yes |
| **Avoid when** | You must avoid any third-party coordination service (consider Headscale on a VPS), or the use is commercial and the free plan terms do not fit |

### Concepts to learn in Phase 5

| Topic | What to know **[K]** |
|-------|----------------------|
| Direct vs relayed | Peers first try a direct UDP path using NAT traversal; if CGNAT/strict firewalls block it, traffic falls back to Tailscale's DERP relays. Still end-to-end encrypted, but slower with higher latency. `tailscale ping` shows which path is used; `tailscale netcheck` shows relay reachability |
| Subnet router | A device on the LAN advertises the LAN's address range to the tailnet. Needs: IP forwarding enabled on that host, the route advertised, **and approved in the admin console**, plus forwarding allowed by the firewall. Then tailnet devices can reach LAN devices that cannot run Tailscale. **Overlapping ranges** (home and a remote site both `192.168.1.0/24`) are ambiguous: renumber one side or use Tailscale's 4via6 feature (verify). On a Docker host, remember Docker sets the forward policy to drop when it enables forwarding **[V]**, so forwarding rules must allow the subnet-router traffic |
| Exit node | Sends *all* of a client's internet traffic through the home server. Useful on untrusted Wi-Fi or for a home IP address abroad. **Not needed** for reaching the server; costs your home upload bandwidth |
| MagicDNS and split DNS | MagicDNS gives `device.<tailnet>.ts.net` names; split DNS lets you send queries for `home.example.com` to your own resolver so internal names work from anywhere |
| Tags and policy | Tag the server (`tag:server`), group users, allow admins to SSH, allow family only the ports they need, and default-deny the rest. Test with the policy tester |
| Certificates | Tailscale can issue HTTPS certificates for device names, but the names land in public Certificate Transparency logs **[S]**; a wildcard certificate on your own domain avoids exposing individual service names **[V: Caddy docs]** |
| Funnel | Publishes a service publicly through Tailscale (ports 443/8443/10000, TLS only, undisclosed bandwidth limits) **[S]**. Treat as public exposure; avoid for personal data |
| Lost device | Remove it in the admin console, revoke app sessions, rotate anything stored on it |

## Cloudflare DNS and domain (full profile)

| | |
|---|---|
| **Problem it solves** | A real domain gives clean names (`photos.home.example.com`), publicly trusted certificates via the DNS challenge (no open ports), and the hostnames Cloudflare Tunnel publishes |
| **Class / when** | **Recommended** / Stage 2 (buy early, use later) |
| **Why this, not simpler** | MagicDNS + `tailscale serve` works with no domain but gives one hostname per machine. Free dynamic-DNS names are fragile and rate-limited. A domain costs roughly the price of a coffee a month |
| **Hardware / storage** | None |
| **Dependencies** | A registrar account; DNS hosted at Cloudflare (free) so Caddy can use a DNS plugin and the Tunnel can create records |
| **Install / config** | Dashboard-based. Create a **narrowly scoped API token** (edit DNS for that one zone) for the certificate automation, stored in `/srv/secrets` |
| **Exposure / access** | Public DNS holds only what must be public. **Do not** create public A records for internal services: it leaks addressing and many resolvers drop private answers (DNS-rebinding protection) **[K]**; answer internal names from your own DNS |
| **Authentication / security** | MFA/passkey on the Cloudflare and registrar accounts; registrar lock; auto-renew; calendar the expiry. Domain loss means losing certificates, tunnels and names |
| **Backup / recovery** | Export the zone file into the private repo; registrar and Cloudflare recovery codes in the kit |
| **Maintenance / cost** | Domain fee is the only cost: a `.com` at Cloudflare Registrar was listed at about US$10.11/yr (at-cost renewals), dated February 2026 **[S]**; the Indian rupee figure is in Part I. `.in` domains are cheap in year one but renewals vary widely between registrars **[S]** |
| **Limits** | A domain registered at Cloudflare cannot use another DNS provider without transferring (verify at purchase); `.in` registration may have local requirements **[U]** |
| **Continuous?** | n/a (a service, not a process) |
| **Avoid when** | You only ever use Tailscale names and never need HTTPS names or public hostnames |

## Caddy (full profile)

| | |
|---|---|
| **Problem it solves** | One front door for private web apps: automatic HTTPS, host-based routing, WebSockets, upload limits, in a short readable file |
| **Class / when** | **Recommended** / Stage 2 (Phase 8) |
| **Why this, not simpler** | You do not need it for LAN-only services such as SMB, or for admin ports reached by an SSH tunnel. You do need it when apps require HTTPS (Vaultwarden, PWAs, mobile clients) or you want names instead of ports |
| **Alternatives** | Traefik (label-based discovery; needs the Docker socket or a socket proxy), Nginx Proxy Manager (GUI; state in a database, harder to version-control), plain nginx |
| **Hardware / storage** | Tens of MB RAM; tiny data directory (certificates, ACME account) |
| **Dependencies** | A DNS provider plugin for the DNS challenge; the HTTP challenge needs port 80 externally reachable and TLS-ALPN needs 443, whereas the **DNS challenge needs no open ports and is required for wildcards** **[V]**. DNS provider support is by community plugins, so the Caddy build must include yours **[V]** |
| **Install / Compose** | Official or custom-built image including the DNS module (build steps verified at Phase 8). One Caddyfile in `/srv/config/stacks/caddy/`. Joins the `proxy` network only; never the `public` network |
| **Exposure / access** | Listens on LAN/tailnet addresses; the admin API stays on localhost. `cloudflared` is separate and never routes to Caddy |
| **Authentication / security** | Caddy does not authenticate users; the apps do (or an auth portal later). Pass forwarded headers correctly and tell the app which proxies to trust (Jellyfin requires its known-proxies setting **[V]**; Frigate needs `trusted_proxies` for correct rate limiting **[V]**). Use a **wildcard certificate** so individual service names do not appear in Certificate Transparency logs **[V]**. Caddy's automatic local-trust installation is not guaranteed to work, especially in containers **[V]** |
| **Backup / recovery** | Caddyfile in Git; the data directory is regenerable but backing it up avoids ACME rate-limit pain |
| **Maintenance / cost** | Update with the stack; pin the plugin version; free |
| **Limits** | Plugin rebuilds on Caddy upgrades; rate limits at public CAs; certificate lifetimes are shortening over time, so renewal automation must be monitored (Part H cert check) |
| **Continuous?** | Yes |
| **Avoid when** | Only Tailscale hostnames plus ports are enough for you |

## Cloudflare Tunnel (medium profile)

| | |
|---|---|
| Problem | Publishes selected web apps with no inbound port, no exposed home IP, and CGNAT-proof |
| Class / when | **Optional** / Stage 3, only for services that pass the exposure checklist |
| Needs | Cloudflare account, domain on Cloudflare DNS, a `cloudflared` container on the `public` network. Public hostnames can target HTTP, HTTPS, UNIX sockets and TCP (TCP clients need `cloudflared`); no documented anonymous public UDP **[S]** |
| Limits | 100 MB request-body cap on Free/Pro (Business 200, Enterprise up to 5 GB self-serve) **[V]**; on Free, Pro and Business, public-hostname traffic is subject to terms that require a paid service to serve video and large files, and private network routes (which need Cloudflare's client on every viewer) are exempt **[V]**; Cloudflare terminates TLS and can see plaintext **[K]** |
| Security | The tunnel token is a credential (store in `/srv/secrets`, rotate on suspicion); only specific hostnames routed; route to app containers, not to Caddy; kill switch documented |
| Backup | Record hostnames and Access policies in the private repo; the tunnel config may live in Cloudflare's dashboard, so export notes |
| Cost | Reported free within the Zero Trust free plan (up to 50 users) **[S]** |
| Avoid for | Immich, Jellyfin, game servers, SMB, SSH for friends, anything with large uploads or non-HTTP protocols |

## Cloudflare Access (medium profile)

| | |
|---|---|
| Problem | An identity gate (email one-time code, identity provider, MFA) in front of a public hostname, before traffic reaches your app |
| Class / when | **Optional** / with Tunnel in Stage 3 |
| Limits | Browser-based login does not work for mobile or desktop *apps* that talk to an API (Vaultwarden clients, Immich app, Nextcloud clients) unless you use service tokens or bypass paths, which weakens it **[K]**; a misconfigured policy (especially a bypass) can expose the app to everyone; it does not replace the app's login |
| Cost | Free for up to 50 users **[S]** (verify the plan page) |
| Use for | A shared web page, a status page, a small internal tool for relatives |

## Short profiles

| App | Class / when | Purpose | Key caution | Verdict |
|-----|--------------|---------|-------------|---------|
| Traefik | Optional / Later | Reverse proxy with automatic discovery from Docker labels | Its Docker provider needs access to the Docker socket (use a read-only socket proxy) **[K]** | Choose only if you run many fast-changing containers |
| Nginx Proxy Manager | Optional / Later | GUI front end over nginx with Let's Encrypt | Configuration lives in a database, hard to review and version-control; another admin UI to protect **[K]** | Only if you insist on a GUI |
| Local DNS services (CoreDNS, dnsmasq, Unbound, Technitium, or AdGuard/Pi-hole rewrites) | Recommended / Stage 2-3 | Answer internal names (`*.home.example.com`) with the LAN or tailnet address | One resolver is a single point of failure; keep a second that answers identically; bind to LAN/tailnet only | Use the ad-blocking DNS you already run for rewrites; see [`I-adblocking-dns.md`](I-adblocking-dns.md) |
