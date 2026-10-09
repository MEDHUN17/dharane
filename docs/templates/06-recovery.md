# Recovery, troubleshooting notes and disaster-recovery checklist (TEMPLATE)

## Recovery procedures (fill in with your real paths and commands)

| Situation | Steps (link to runbook sections) | Last rehearsed |
|-----------|----------------------------------|----------------|
| Restore a deleted file | | |
| Corrupted application | | |
| Failed database | | |
| Lost photo library | | |
| Failed system disk | | |
| Destroyed server | | |
| Lost or stolen device | remove from tailnet, revoke app sessions, rotate saved secrets | |
| Locked out of SSH | console or LAN break-glass | |
| DNS resolver down | temporary public DNS in router, then restore | |

## Troubleshooting notes (things that bit you; keep short)

| Date | Symptom | Cause | Fix | Prevention |
|------|---------|-------|-----|------------|

## Disaster-recovery checklist

Before: [ ] latest backups verified [ ] recovery kit accessible [ ] this repo reachable from a clean laptop.

Rebuild:
1. [ ] Install the OS on the new hardware; set hostname; create the admin user; SSH keys only.
2. [ ] Install Docker and Tailscale; re-enrol as a **new** node; revoke the old node.
3. [ ] Restore `/srv/secrets` from the recovery kit repo.
4. [ ] Clone the config repo to `/srv/config`.
5. [ ] Mount or restore data disks; create sentinel files; re-apply the immutable mountpoint flag.
6. [ ] Restore `appdata` and database dumps from backup.
7. [ ] Start stacks one at a time; verify each.
8. [ ] Re-point DNS, tunnel and certificates; test public hostnames and the kill switch.
9. [ ] Rotate every secret that lived on the old machine.
10. [ ] Run a backup and a monitoring check; update the inventory; record RTO/RPO achieved: `__`.
