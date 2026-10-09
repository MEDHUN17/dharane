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
- [x] Power, UPS, inverter and physical-setup guide (docs/04-power-physical.md)
- [x] Generic schema-validated Compose template (examples/compose/)
- [x] Constrained single-laptop profile (docs/13-low-end-profile.md), written generically for that class of machine
- [x] Owner profile recorded, sanitised and provisional (profile/owner.md): an input, never a constraint
- [x] Decision guide (docs/14): the broader chart for choosing by the variables that change; reviewed by four independent lenses, fixes applied
- [ ] Implementation phases: Phase 0 (inventory) in progress; waiting on the follow-up answers in docs/11-information-needed.md

## Open decisions (owner)
1. **Repo visibility is PUBLIC.** Fine for this generic blueprint. Make it private, or use a separate private
   repo, before storing any real inventory (IPs, hostnames, tailnet, ACLs, device lists). `profile/owner.md` holds counts,
   ranges and classes only; the ISP name, the domain and the password-manager brand were left out on purpose. If the repo
   becomes private, those can be added to the profile.
2. **Doc-site access.** This build session blocks most documentation hosts (tailscale.com, debian.org,
   docs.docker.com, docs.immich.app, developers.cloudflare.com, caddyserver.com, jellyfin.org, docs.frigate.video).
   Allowing them under the environment's Network access settings would let me verify directly instead of via
   GitHub-hosted doc sources and search summaries.

## Facts to re-check before relying on them
- Tailscale free-plan limits: reported 6 users / unlimited devices since 2026-04-08 (S9); confirm on the pricing page.
- Cloudflare video/large-file terms: Cloudflare's docs state the effect (V29); the binding text on cloudflare.com was not read (U2).
- Memory, SSD and hard-drive prices rose sharply in 2026 and may keep rising into 2027 (S27-S33, S41-S43); every price in `docs/08-cost.md` and the ladder in `docs/14-decision-guide.md` must be re-checked on live listings before buying.
- Static IP, CGNAT and relay-server facts come from forum reports and aggregator sites (S36-S38); get any provider's offer in writing.

## Provisional assumptions (superseded by `profile/owner.md` wherever it has a value)

The profile is an input to planning, not a constraint on the blueprint: Parts A-K stay valid for any hardware, and anything specific to the owner lives in `profile/` and in the clearly marked example sections of the decision guide.

- Hardware class known (an old laptop; model, RAM and disk type per machine unmeasured, see profile/owner.md); the plan stays tier-based (A-D), single machine first.
- CGNAT / no inbound ports possible: design needs no port forwarding by default.
- Location: India (INR costs, local tariffs); state/DISCOM not yet known. The ISP is known to the owner but deliberately not recorded in this public repo.

## Decisions made (see docs/02-design-decisions.md)
Debian 13 bare metal; ext4; Docker CE + Compose plugin (rootful, hardened); Tailscale on host; Caddy;
restic (local + off-site); AdGuard Home or Pi-hole with a secondary resolver; systemd timers + shell;
no Proxmox/Kubernetes/SSO/n8n at Stage 1. Directory layout under /srv (config, secrets, appdata, dumps,
storage, backup-local).

## Rules in force
- The owner profile is an input, never a constraint: do not bend Parts A-K to it, and do not write "you have X" in them.
- No invented image names, ports, env vars or Compose keys; verify against official docs at the phase that needs them.
- No secrets in the repo; placeholders only.
- No public exposure before backups are restore-tested and alerts exist.

## Next
Waiting on the follow-up answers (docs/11-information-needed.md): laptops and CPU model, upload speed and unit, router DNS setting, camera type, data sizes, who "public" means, whether the monthly budget includes electricity, state and tariff, comfort and time. Meanwhile the decision guide (docs/14) lets any measured value be read against every option. Then: finalise purchases, refine Part I, start Phase 1 interactively.
