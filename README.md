# dharane - home server blueprint

A hardware-agnostic, single-machine-first blueprint for a self-hosted home-server
ecosystem (Docker Compose, Tailscale, Cloudflare, tested backups), plus an
implementation handbook that is filled in one validated phase at a time.

> **This repository is public.** Everything here is generic. Real values - subnets,
> tailnet name, domain, public hostnames, ACLs, device lists, IPs, keys, recovery
> material - must NOT be committed. Use placeholders (`example.com`,
> `192.168.X.0/24`, `<tailnet>.ts.net`). Make the repo private before storing any
> filled-in inventory. See `STATE.md` -> "Open decisions".

## Where things are

| Part | Topic | File | Status |
|------|-------|------|--------|
| - | Progress, decisions, assumptions | [`STATE.md`](STATE.md) | live |
| A | Executive summary | `docs/00-executive-summary.md` | planned |
| B | Architecture diagrams, request flows, failure scenarios | `docs/01-architecture.md` | planned |
| C | Core design decisions | `docs/02-design-decisions.md` | planned |
| D | Hardware tiers and capacity matrix | `docs/03-hardware-capacity.md` | planned |
| E | Application catalogue (one file per category) | `docs/apps/` | planned |
| F | Device integration matrix | `docs/05-device-integration.md` | planned |
| G | Security and backup architecture | `docs/06-security-backup.md` | planned |
| H | Automation and monitoring | `docs/07-automation-monitoring.md` | planned |
| I | Cost comparison | `docs/08-cost.md` | planned |
| J | Phased implementation roadmap | `docs/09-roadmap.md` | planned |
| K | Documentation templates | `docs/templates/` | planned |
| L | Information needed from the owner | `docs/11-information-needed.md` | planned |
