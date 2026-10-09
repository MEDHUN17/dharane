# STATE - progress, decisions, assumptions

Last updated: 2026-10-09

## Status
- [x] Repo reachable; branch `claude/home-server-architecture-a081p8` pushed (read + write verified).
- [x] Part A executive summary
- [x] Part B architecture (11 Mermaid diagrams, render-validated)
- [x] Part C design decisions + storage layout
- [x] Part D hardware tiers and capacity
- [x] Part J roadmap + staged growth plan
- [x] Part L information request
- [x] Verification log (sources and dates)
- [x] Part E application catalogue + exposure matrix (docs/apps/)
- [x] Part G security + backup, Part H automation + monitoring, tested example scripts (examples/)
- [x] Part F device integration
- [x] Part I cost comparison (dated, sourced; hardware prices low confidence; refine after Part L)
- [x] Part K documentation templates + repo/secrets policy
- [x] Troubleshooting handbook
- [ ] Implementation phases (start after Part L is answered)

## Open decisions (owner)
1. **Repo visibility is PUBLIC.** Fine for this generic blueprint. Make it private, or use a separate private
   repo, before storing any real inventory (IPs, hostnames, tailnet, ACLs, device lists).
2. **Doc-site access.** This build session blocks most documentation hosts (tailscale.com, debian.org,
   docs.docker.com, docs.immich.app, developers.cloudflare.com, caddyserver.com, jellyfin.org, docs.frigate.video).
   Allowing them under the environment's Network access settings would let me verify directly instead of via
   GitHub-hosted doc sources and search summaries.

## Facts to re-check before relying on them
- Tailscale free-plan limits: reported 6 users / unlimited devices since 2026-04-08 (S9); confirm on the pricing page.
- Cloudflare CDN video/large-file terms for Free/Pro: second-hand only (U2).

## Provisional assumptions (replace when Part L is answered)
- Hardware unknown; plan is tier-based (A-D), single machine first.
- CGNAT / no inbound ports possible: design needs no port forwarding by default.
- Location: India (INR costs, local tariffs); state/DISCOM and ISP not yet known.

## Decisions made (see docs/02-design-decisions.md)
Debian 13 bare metal; ext4; Docker CE + Compose plugin (rootful, hardened); Tailscale on host; Caddy;
restic (local + off-site); AdGuard Home or Pi-hole with a secondary resolver; systemd timers + shell;
no Proxmox/Kubernetes/SSO/n8n at Stage 1. Directory layout under /srv (config, secrets, appdata, dumps,
storage, backup-local).

## Rules in force
- No invented image names, ports, env vars or Compose keys; verify against official docs at the phase that needs them.
- No secrets in the repo; placeholders only.
- No public exposure before backups are restore-tested and alerts exist.

## Next
Waiting on Part L answers (docs/11-information-needed.md). Then: tier the hardware, refine Part I, start Phase 0/1 interactively.
