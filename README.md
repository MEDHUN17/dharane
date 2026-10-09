# dharane - home server blueprint

A hardware-agnostic, single-machine-first blueprint for a self-hosted home-server
ecosystem (Docker Compose, Tailscale, Cloudflare, tested backups), plus an
implementation handbook that is filled in one validated phase at a time.

> **This repository is public.** Everything here is generic. Real values - subnets,
> tailnet name, domain, public hostnames, ACLs, device lists, IPs, keys, recovery
> material - must NOT be committed. Use placeholders (`example.com`,
> `192.168.X.0/24`, `<tailnet>.ts.net`). Keep real inventory in a **private** repo
> (see `STATE.md` -> "Open decisions").

Evidence labels used throughout: **[V]** verified in the project's own docs, **[S]** from a
search summary, **[K]** stable knowledge, **[E]** estimate to measure, **[U]** unverified.
Every verified fact and its source is in [`docs/12-verification-log.md`](docs/12-verification-log.md).

## Where things are

| Part | Topic | File | Status |
|------|-------|------|--------|
| - | Progress, decisions, assumptions | [`STATE.md`](STATE.md) | live |
| A | Executive summary | [`docs/00-executive-summary.md`](docs/00-executive-summary.md) | draft v0.1 |
| B | Architecture, diagrams, request flows, failure behaviour | [`docs/01-architecture.md`](docs/01-architecture.md) | draft v0.1 |
| C | Core design decisions | [`docs/02-design-decisions.md`](docs/02-design-decisions.md) | draft v0.1 |
| C | Storage architecture and directory layout | [`docs/02a-storage-layout.md`](docs/02a-storage-layout.md) | draft v0.1 |
| D | Hardware tiers and capacity matrix | [`docs/03-hardware-capacity.md`](docs/03-hardware-capacity.md) | draft v0.1 |
| E | Application catalogue + service-exposure matrix (one file per category) | [`docs/apps/`](docs/apps/README.md) | draft v0.1 |
| F | Device integration matrix | [`docs/05-device-integration.md`](docs/05-device-integration.md) | draft v0.1 |
| G | Security, identity and backup architecture | [`docs/06-security-backup.md`](docs/06-security-backup.md) | draft v0.1 |
| H | Automation and monitoring | [`docs/07-automation-monitoring.md`](docs/07-automation-monitoring.md) | draft v0.1 |
| I | Cost comparison (INR, dated sources) | [`docs/08-cost.md`](docs/08-cost.md) | draft v0.1 (prices low-to-medium confidence) |
| - | Power, UPS, inverters and physical setup | [`docs/04-power-physical.md`](docs/04-power-physical.md) | draft v0.1 |
| J | Phased implementation roadmap | [`docs/09-roadmap.md`](docs/09-roadmap.md) | draft v0.1 |
| J | Staged growth plan | [`docs/09a-growth-stages.md`](docs/09a-growth-stages.md) | draft v0.1 |
| K | Documentation templates and repo/secrets policy | [`docs/templates/`](docs/templates/README.md) | draft v0.1 |
| L | Information needed from the owner | [`docs/11-information-needed.md`](docs/11-information-needed.md) | **awaiting answers** |
| - | Troubleshooting handbook (25 topics) | [`docs/10-troubleshooting.md`](docs/10-troubleshooting.md) | draft v0.1 |
| - | Tested example scripts, systemd units and test suites | [`examples/`](examples/README.md) | tested |
| - | Verification log | [`docs/12-verification-log.md`](docs/12-verification-log.md) | live |

## How to use this

1. Read Part A, then B.
2. Answer Part L in chat (not in this repo).
3. Implementation proceeds phase by phase from `docs/09-roadmap.md`, each step verified before the next.
