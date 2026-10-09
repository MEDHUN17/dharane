# Network (TEMPLATE)

> Fill in the private copy only. Use real addresses there; this public template keeps placeholders.

## Topology

Describe or paste a diagram (Mermaid is fine): ISP -> router -> switch -> server, Wi-Fi, camera network, UPS.

| Field | Value |
|-------|-------|
| ISP / plan / speeds (down/up) | |
| CGNAT? Public IPv4? IPv6? | |
| Router make/model, firmware, admin access owner | |
| Router config export location (offline) | |
| UPnP disabled? | yes / no |
| Port forwards (should be none) | |

## IP addresses and subnets

| Network | Range | Gateway | DHCP range | Notes |
|---------|-------|---------|------------|-------|
| Home LAN | `192.168.X.0/24` (prefer an uncommon range) | | | |
| Guest Wi-Fi | | | | isolated? |
| Camera network | | | | no internet? |
| Docker networks | proxy / public / per stack | | | |
| Tailscale | `100.x.y.z` addresses are assigned by Tailscale | | | |

| Host / device | LAN address | Reservation or static? | Tailscale name | Notes |
|---------------|-------------|------------------------|----------------|-------|
| server | | | | |

## Tailscale devices and policy

| Device | Owner | Tags | Key expiry | Last reviewed |
|--------|-------|------|------------|---------------|
| server | admin | tag:server | disabled | |

Policy summary (who can reach what): `...`   Policy file location in the repo: `...`   Lost-device procedure: `06-recovery.md`.

## DNS records

| Name | Type | Value | Public or internal | Why it exists | Reviewed |
|------|------|-------|--------------------|---------------|----------|
| `*.home.example.com` | (internal rewrite) | LAN / tailnet IP | internal | private apps | |

Resolvers: primary `...`, secondary `...`; configs synchronised how: `...`. DNS provider API token: stored at `...` (name only).

## Public hostnames (should be few)

| Hostname | Backend service | Access policy | Auth in app | Kill-switch step | Reviewed |
|----------|-----------------|---------------|-------------|------------------|----------|

## Ports and protocols

| Service | Container port | Host publish (address:port) | Protocol | Reachable from | Class (exposure matrix) |
|---------|----------------|-----------------------------|----------|----------------|--------------------------|
