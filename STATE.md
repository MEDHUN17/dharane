# STATE - progress, decisions, assumptions

Last updated: 2026-10-09

## Status
- [x] Repo reachable; branch `claude/home-server-architecture-a081p8` created and pushed.
- [ ] Parts A-D, J, L (first deliverable)
- [ ] Parts E-I, K
- [ ] Implementation phases (start only after hardware details are provided)

## Open decisions
1. **Repo visibility: currently PUBLIC.** Fine for this generic blueprint. Make it private
   before adding any real inventory (IPs, hostnames, tailnet, ACLs). Owner decision.

## Provisional assumptions (replace when real details arrive)
- Hardware unknown; plan is tier-based (A-D), single machine first.
- CGNAT / no inbound ports possible: design needs no port forwarding by default.
- Location: India (INR costs, local tariffs); state/DISCOM and ISP not yet known.

## Rules in force
- No invented image names, ports, env vars or Compose keys; verify against official docs.
- No secrets in the repo; placeholders only.
- No public exposure before backups and auth are in place.
