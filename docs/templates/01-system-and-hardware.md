# System, hardware and operating system (TEMPLATE)

> Copy into the PRIVATE config repo and fill in there. Never commit real serial numbers or addresses to a public repo.

Last reviewed: `YYYY-MM-DD`   Owner: `<name>`

## System inventory

| Field | Value |
|-------|-------|
| Hostname | |
| Role | primary server / backup / DNS / other |
| Location (room) | |
| Date installed | |
| Tier (Part D) | A / B / C / D |
| Purpose summary | |
| Stage reached (Part J) | 1 / 2 / 3 / 4 / 5 / 6 |

## Hardware inventory

| Item | Make / model | Serial (last 4) | Size / spec | Purchased | Warranty ends | Notes (CMR/SMR, slot, health baseline) |
|------|--------------|-----------------|-------------|-----------|---------------|----------------------------------------|
| CPU | | | | | | iGPU / AVX2 / SSE4.1 support |
| RAM | | | | | | free slots |
| System SSD | | | | | | |
| Data disk | | | | | | |
| Backup disk | | | | | | |
| Surveillance disk | | | | | | |
| NIC(s) | | | | | | speed |
| UPS | | | VA / W | | | battery date, runtime test result |
| Switch / router | | | | | | |

Measured idle power: `__ W` on `YYYY-MM-DD` (plug-in meter).

## Operating system details

| Field | Value |
|-------|-------|
| Distribution and release | e.g. Debian 13 |
| Kernel | |
| Install date / method | |
| Disk layout summary | EFI / root / swap |
| Filesystems and mount points | `/srv/storage` ... (UUIDs live in `/etc/fstab`, not here) |
| Auto-updates | unattended security: on / off; reboot policy |
| Time sync | |
| SSH | keys only: yes / no; allowed users |
| Firewall | ufw: rules summary |
| Docker / Compose versions | |
| Tailscale version | |
| Numeric UID/GID table | see `04-identity-and-secrets.md` |
| Known quirks | |
