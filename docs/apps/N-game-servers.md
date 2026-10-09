# N. Optional game servers

**Advanced / Stage 4**, resource-isolated, with no access to personal data. Labels as in the [README](README.md): **[V]**, **[S]**, **[K]**, **[E]**, **[U]**. Figures for specific games are starting expectations: read each game's own dedicated-server documentation before sizing.

## The networking truth first

| Option | Works behind CGNAT? | Hides your home IP? | Notes |
|--------|---------------------|---------------------|-------|
| **Cloudflare Tunnel public hostname** | n/a | yes | **Not suitable** for arbitrary game traffic: public hostnames carry HTTP/HTTPS/TCP-over-WebSocket and no documented anonymous UDP **[S]** |
| Cloudflare Spectrum | yes | yes | Not on Free; Pro covers only Minecraft and SSH (one app each); generic TCP/UDP is Enterprise **[S]**; check prices and exactly which Minecraft edition is covered **[U]** |
| **Tailscale** (friends install it or you share the node) | **yes** | yes (private) | Simple, private, DDoS-proof. Friction for non-technical friends and consoles cannot join |
| Port-forward from the router | **no** (needs a public IPv4) | no | Exposes your home IP and a home-network DDoS target. Add a whitelist and keep the server in its own network |
| Small VPS relay forwarding to home over WireGuard/Tailscale | yes | yes | Costs a VPS and its upstream limits; adds latency; verify the provider's DDoS terms |
| Third-party game tunnelling services | yes | yes | You trust a third party with traffic |
| Rent a game-server host | n/a | n/a | No home exposure at all |

Default recommendation: **Tailscale for a small, known group**; a rented host or VPS relay for a public community.

## Representative servers

| Game / image | CPU | RAM **[E]** | Storage **[E]** | Notes |
|--------------|-----|-------------|-----------------|-------|
| **Minecraft Java** (well-known maintained container image supporting many versions, server types and mod loaders **[V]**) | Single-thread speed matters most | 2-4 GB for a few vanilla players; much more for modded | World 0.5-5 GB | Accept the EULA as the image requires; whitelist on; pre-generate the world; optional auto-pause when empty |
| Valheim-class survival servers | Moderate | ~4-8 GB | A few GB | Save integrity matters; stop cleanly before backup |
| Factorio-class factory servers | Single-thread bound as the factory grows | Modest to moderate | Small saves | Updates must match client versions |

The same pattern applies to others: a CPU and RAM budget, a world directory, a documented way to flush a save, and an update path.

## Operating them safely

| Topic | Practice |
|-------|----------|
| Container images | Use the well-known maintained image for that game; pin versions; read the image's docs for settings |
| Isolation | Own Docker network; no `docker.sock`; no mounts of personal data; `cpus` and `mem_limit` set so a runaway server cannot starve Immich or the database |
| Persistent worlds | Bind mount the world directory on SSD |
| Save backups | Flush/save-all (or stop the server briefly), then copy with restic; daily is a good start, more often if active; keep a week of dailies |
| Mods and updates | Test on a copy; mods lag game versions; keep the previous server version and a world backup before updating |
| Access control | Whitelist/allow-list; ops by name; RCON/admin ports never published |
| On-demand start/stop | A systemd unit or Compose profile started by you, or an authenticated trigger on the tailnet; flush before stop; never expose the trigger publicly |
| Public servers | Expect scanning and abuse; DDoS and bandwidth: your upstream is small and shared with the household; prefer a VPS relay or rented host |
| Resource conflicts | A busy server competes with everything else on a small box: budget it separately (Part D) or give it its own machine |

## Verdict

Install later, one server at a time, after Phase 7 monitoring shows spare headroom. If friends are outside your tailnet and you want a public IP-free setup, rent a host rather than expose your home.

## Offering a server to people you do not know (no inbound ports, tiny budget)

You cannot host publicly from a home line with no port forwarding or behind CGNAT, and a small uplink would not carry it anyway. Realistic options, cheapest first. All figures are search-reported **[S]** and change; confirm on the provider's page.

| Option | Cost | What to know |
|--------|------|--------------|
| Players you invite, on **Tailscale** (PC and Android; consoles cannot) | Rs 0 | Private; works behind CGNAT. The free plan is reported at 6 users, with node sharing for more |
| **Aternos** | Rs 0 | Ad-supported, start-up queue, sleeps when empty, limited RAM, may delete inactive servers; Java and Bedrock, Paper/Spigot, Forge/Fabric; Bedrock players can join Java via Geyser |
| **playit.gg** tunnel to your home server | Free tier; premium US$30/year or US$3/month | Outbound tunnel; conflicting reports on Java/TCP on the free tier after a late-2025 abuse crackdown **[U]**; some ISPs block its domain |
| **Oracle Cloud Always Free** (Arm VM) | Rs 0 | Reportedly cut to 2 OCPU/12 GB in June 2026; "out of host capacity" is common; verify on Oracle's page; treat as an experiment **[U]** |
| Paid Minecraft host (India) | about Rs 400 for 4 GB (vendor claim); another vendor Rs 649 rising to Rs 999 | Over a Rs 200/month budget; a 4 GB plan is the realistic size for 8 players |

An old dual-core laptop may struggle with 8 players because Minecraft is bound by single-thread speed: test with the real group and watch the server's tick rate **[E]**, and keep the game server off a box that also runs Immich or Paperless.
