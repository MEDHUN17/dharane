# Identity, permissions and secrets inventory (TEMPLATE)

> The secrets inventory records NAMES, PURPOSES, LOCATIONS, OWNERS and ROTATION DATES. It never contains secret values.

## Users and permissions

| Identity | Type (admin / family / guest / service) | Where it exists (Linux, tailnet, apps) | Privileges | MFA? | Created | Offboarding steps |
|----------|------------------------------------------|----------------------------------------|-----------|------|---------|-------------------|

## Numeric ID table (keep stable across rebuilds)

| Name | UID | GID | Used by |
|------|-----|-----|---------|
| admin | 1000 | 1000 | human admin |
| media (group) | | | arr apps, Jellyfin read |

## Data permission policy

| Data | Owner : group | Mode | Mounted into | Read-only? |
|------|---------------|------|--------------|-----------|

## Secrets inventory (no values)

| Name | Purpose | Stored at (path/system) | Who can read | Rotation interval | Last rotated | Recovery path if lost |
|------|---------|--------------------------|--------------|-------------------|--------------|-----------------------|
| restic local repo password | Decrypts local backups | `/srv/secrets/...` + recovery kit | root | on suspicion | | kit |
| restic off-site repo password | Decrypts off-site backups | `/srv/secrets/...` + recovery kit | root | on suspicion | | kit |
| provider API key (off-site) | Writes backups | `/srv/secrets/...` | root | yearly | | provider console |
| DNS API token (one zone) | Certificate renewals | `/srv/secrets/...` | root | yearly | | Cloudflare dashboard |
| Tunnel token | Public hostnames | `/srv/secrets/...` | root | yearly / on suspicion | | Cloudflare dashboard |
| Notification URL/token | Alerts | `/srv/secrets/...` | root | yearly | | notification service |
| Heartbeat URLs | Dead-man's switch | `/srv/secrets/...` | root | on suspicion | | provider |
| Tailscale / IdP recovery codes | Account recovery | printed in kit | admin | when used | | kit |
| Registrar / Cloudflare / GitHub / password-manager recovery codes | Account recovery | printed in kit | admin | when used | | kit |

## Recovery kit contents (checklist)

- [ ] Repository passwords (both)
- [ ] Provider account recovery and key IDs
- [ ] Identity-provider, Cloudflare, registrar, GitHub, password-manager recovery codes
- [ ] Encrypted backup of the admin SSH key
- [ ] Location of the config repo and its mirror
- [ ] Printed copy of `06-recovery.md`
- [ ] Verified by a rebuild test on `YYYY-MM-DD`
