# I. Network-wide ad blocking and internal DNS

Labels as in the [README](README.md): **[V]** read in the projects' READMEs, **[S]**, **[K]**, **[U]**.

## What DNS blocking is, and is not

A DNS blocker answers "no such host" for domains on a blocklist, so every device on the network skips them without installing anything. It cannot block ads served from the same domain as content, and it is bypassed by anything that does not use your resolver (encrypted DNS built into a browser or phone, apps with hard-coded resolvers). It is a convenience and privacy layer, not a security perimeter.

## Options

| Option | Strengths | Weaknesses | Verdict |
|--------|-----------|-----------|---------|
| **AdGuard Home** | Single binary or container; built-in DHCP server, encrypted upstreams (DoH/DoT/DNSCrypt), can act as a DoH/DoT server, per-client settings, safe search, malware/phishing filtering, easy DNS rewrites **[V, vendor-written comparison]** | Most differences versus Pi-hole come from its own README, so read them as claims | **Recommended** if you want rewrites and encrypted upstream built in |
| **Pi-hole** | Mature "DNS sinkhole" with a web dashboard, optional DHCP server, IPv4 and IPv6 blocking, large community **[V]** | Encrypted upstream usually needs extra software **[V, vendor comparison]**; installs by script or the official Docker image **[V]** | Equally valid if you already know it |
| Technitium DNS | Full DNS server with split-horizon "views" and blocking **[K]** | Different model; smaller community | Consider when you need per-source answers |
| Router-level filtering (OpenWrt add-ons, vendor features) | No extra server | Depends on router firmware | Good if your router already does it well |
| Hosted DNS filters | No hardware, no outage when your server is down | Your queries go to a third party; free tiers have limits **[K]** | A reasonable secondary or travelling option |

Pick one primary and give it an **identical** secondary. Do not run both AdGuard Home and Pi-hole on one network.

## AdGuard Home / Pi-hole profile (shared)

| | |
|---|---|
| **Problem it solves** | Household-wide ad/tracker blocking and a place to define internal names (`*.home.example.com`) |
| **Class / when** | **Recommended**. Internal DNS and rewrites in Stage 2 (Phase 8b, trial on one device); household switch-over in Stage 3 only after a second resolver exists |
| **Why this, not simpler** | Browser blockers only cover one browser; internal names need an authoritative-for-your-zone resolver anyway, so you get blocking almost free |
| **Hardware / storage** | ~50-150 MB RAM **[E]**; logs and statistics grow slowly |
| **Dependencies** | Port 53; a stable address for the server (DHCP reservation); optionally the router's DHCP DNS option |
| **Install / Compose** | Official project image or package (current docs at Phase 8). On Ubuntu-style hosts a local stub resolver may already hold 127.0.0.53:53, so bind the blocker to specific addresses rather than all addresses **[K]** |
| **Exposure** | **Class 2**: LAN and tailnet only. **Never publish port 53**, never forward it, keep UPnP off. Bind explicitly to the LAN and Tailscale addresses. If the host has a global IPv6 address and the router does not firewall inbound IPv6, a resolver listening on all addresses could be an open resolver: confirm with an external scan including IPv6 |
| **Authentication / security** | Strong admin password; the admin UI is admin-only (class 4); regularly review the blocklists you subscribe to |
| **Backup / recovery** | Export the configuration to Git (the private repo); include its data directory in restic if you want statistics |
| **Maintenance / cost** | Update monthly; free |
| **Limits** | See failure modes below |
| **Continuous?** | Yes, and **a reboot of this host takes household DNS with it unless a second resolver exists** |

## Router and DHCP integration

| Method | How | Notes |
|--------|-----|-------|
| **A. Router hands out both resolvers (best)** | Set the router's DHCP DNS servers to the primary and the secondary | Many ISP routers hide this setting; check yours before buying anything |
| B. Blocker also runs DHCP | Disable the router's DHCP; the blocker hands out leases | One more single point of failure; a mistake takes the whole LAN down; avoid unless the router cannot do A |
| C. Per-device DNS | Configure DNS manually on each device | Fine for a trial; does not scale |
| D. Replace/add a router or AP that exposes DNS settings | Use your own access point or OpenWrt-class router | A common fix for locked ISP routers |

**Clients do not reliably try the primary resolver first. Whatever you hand out, every resolver must filter identically and carry the same local records**, otherwise ads leak and internal names fail on whichever clients pick the odd one out. A router resolver or a public resolver as the "backup" breaks both.

## Local DNS records and Tailscale

You want `photos.home.example.com` to resolve to something reachable from home *and* from away. Choose deliberately:

| Option | Answer given | Works for | Trade-off |
|--------|--------------|-----------|-----------|
| **A. LAN address + subnet router** | The server's LAN IP | LAN devices directly; away devices through a Tailscale subnet route to the LAN | One answer for everyone. Choose an **uncommon LAN range** (not `192.168.0.0/24` or `192.168.1.0/24`) so a hotel or friend's network does not overlap **[K]** |
| B. Tailscale address everywhere | The server's `100.x.y.z` | Any device running Tailscale | LAN devices that cannot run Tailscale (TVs) cannot use it |
| C. Different answers by source | LAN IP for LAN clients, tailnet IP for tailnet clients | Everyone | Needs a resolver with views or client rules (Technitium, CoreDNS views, possibly AdGuard client-specific rules **[U]**) |

Tailscale side: point **split DNS** for your internal zone at the server's Tailscale address so only those queries go home. An optional global override sends all queries through the home blocker (ad blocking away from home) but then depends on your home uplink for everything **[K]**.

Keep three DNS roles separate: **home DNS** (ad blocking and internal names on your resolvers), **Tailscale DNS** (how remote devices find them), and **public DNS** (Cloudflare, for the few public hostnames).

## Mobile devices, encrypted DNS and other bypasses

- Android "Private DNS" and browser "Secure DNS" (DoH) send queries straight to a provider, bypassing your resolver. Turn them off or point them at your own encrypted endpoint **[K]**.
- iOS can install a DNS profile that overrides the network's DNS **[K]**.
- Some TVs and streaming sticks hard-code a public resolver; redirecting port 53 at the router is the only fix and not all routers can **[K]**.
- When Tailscale is connected with a DNS configuration, the phone uses the tailnet's DNS settings, not the Wi-Fi's **[K]**.

## Failure modes and recovery

| Failure | Effect | Prevention | Recovery |
|---------|--------|-----------|----------|
| Host reboot or crash | Clients lose DNS (internet "down") | Second identical resolver on another device | Router admin: temporarily set a public resolver; restore after |
| Primary and secondary drift apart | Ads leak or internal names fail intermittently | Keep configs in Git and sync them | Re-sync, check both |
| Resolver bound to the wrong interface | Open resolver, or unreachable | Bind explicitly; external scan after changes | Fix binding |
| Bad blocklist update | Sites break | Review lists; per-client allow rules | Disable the list |
| Router admin password lost | Cannot change DHCP DNS in an outage | Keep it in the recovery kit | Router factory reset (last resort) |

A DNS monitor (Uptime Kuma supports DNS record checks **[V]**) running on a different device tells you when the resolver is broken.

## Recommended approach

AdGuard Home (or Pi-hole) as primary on the server, an identical instance on a cheap always-on device as secondary, both handed out by router DHCP (method A), blocking and rewrites kept in sync from Git, Tailscale split DNS for the internal zone, ports bound to LAN and tailnet only, and a documented break-glass step for DNS failure. Trial on one device for a week before switching the household.
