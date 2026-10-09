# Part K - Documentation templates and repository policy

These are **blank templates**. Copy them into your **private** `server-config` repository (`/srv/config/docs/`) and fill them in there. **Never fill them in inside this public repository.**

The public repository keeps only a sanitised profile of the owner's answers ([`../../profile/owner.md`](../../profile/owner.md): counts, ranges and classes, no names or addresses). Real inventory belongs in the private copy of these templates.

| Template | Covers |
|----------|--------|
| [`01-system-and-hardware.md`](01-system-and-hardware.md) | System inventory, hardware inventory, operating-system details |
| [`02-network.md`](02-network.md) | Topology, IP addresses and subnets, Tailscale devices and policy, DNS records, public hostnames, ports and protocols |
| [`03-services.md`](03-services.md) | Service inventory, dependencies, Compose project locations, persistent-data locations |
| [`04-identity-and-secrets.md`](04-identity-and-secrets.md) | Users and permissions, secrets inventory (names and locations only) |
| [`05-operations.md`](05-operations.md) | Backup policy, update schedule, maintenance log, subscriptions and renewals |
| [`06-recovery.md`](06-recovery.md) | Recovery procedures, troubleshooting notes, disaster-recovery checklist |

## Keeping configuration in Git without leaking secrets

1. **Private repository, MFA on the hosting account, minimal collaborators.** The public blueprint repo holds no real values.
2. **Split every file into committed and uncommitted parts:** commit `compose.yaml` and `.env.example`; keep `.env` and tokens in `/srv/secrets` (root-only, mode 0600); reference them by path. Use the `.gitignore` in this repo as a starting point; it is deliberately aggressive, so check with `git check-ignore -v <path>` if a legitimate file is skipped.
3. **Scan before every commit.** Add a local pre-commit secret scanner (for example gitleaks) **[K]**; do not rely on the hosting service's scanning: for private repositories it may not be included in your plan **[K]**, so verify before trusting it.
4. **Secrets inventory lists names, purposes, locations, owners and rotation dates, never values** (template 04).
5. **If a secret is committed:** treat it as compromised, rotate it first, then clean history if you must. Deleting a file in a later commit does not remove it from history.
6. **Optional encrypted secrets in Git:** a tool such as SOPS with age keys can store encrypted secrets beside the config **[K]**; the key itself lives only in the recovery kit and on the server.
7. **Documentation repo access:** read access only for people who need it; the recovery kit (printed and offline) is the break-glass copy if the repository host is unreachable.

## Portable vs machine-specific: what moves when the host changes

| Class | Examples | Where it lives | On a host change |
|-------|----------|----------------|------------------|
| **Portable configuration** | Compose files, Caddyfile, systemd units, scripts, docs | Git (`/srv/config`) | Clone and reuse |
| **Application data** | `/srv/appdata`, database dumps, photos, documents | Disks and backups | Restore or move the disks |
| **Machine-specific settings** | Hostname, `/etc/fstab` UUIDs, NIC names, static IP, SSH host keys, Tailscale node identity, numeric UIDs/GIDs table | Inventory + host | Recreate; record new values |
| **Secrets** | `.env`, API tokens, repo passwords | `/srv/secrets` + recovery kit | Restore from the kit, rotate if the old host is untrusted |
| **Hardware-dependent configuration** | GPU/render group IDs, `/dev/dri` paths, sensor paths, disk names | Compose + scripts | Re-detect and update |

## Rebuild, replace, migrate, add a machine

- **Replace the host / reinstall the OS / change distribution:** install the OS, install Docker and Tailscale, restore `/srv/secrets` from the kit, clone `/srv/config`, restore `appdata` and data from backup, start stacks one at a time. Re-enrol Tailscale as a new node and revoke the old one.
- **Migrate a stateful app safely:** take a fresh dump and file backup; restore into the new host on the **same app version first**; verify; only then upgrade. For Immich the restore requires a compatible version and, on the CLI path, a fresh instance **[V]**. Keep the old host untouched until the new one has run clean.
- **Add another machine:** give it its own Compose projects, the same directory conventions, its own backup job and monitoring check; move one service at a time (replicate data, test, switch names, retire the old copy after a clean period).
- **Move a service to another host:** stop writes, final backup, restore on the target, update the proxy upstream and DNS, verify, then remove the old container (never the old data until verified).
- **Lose the primary server:** follow `06-recovery.md` using only Git, backups and the recovery kit.
