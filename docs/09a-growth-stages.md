# Staged growth plan

Start on one machine. Move only when a **measured** limit or a clear benefit says so. Costs are in Part I; hardware tiers in Part D.

| | Stage 1 | Stage 2 | Stage 3 |
|---|---|---|---|
| **Name** | Essentials on one machine | Personal cloud, photos, media, monitoring | Public door, family, ad blocking |
| **Problem solved** | A safe, reachable, recoverable base | Replace cloud photo/file services and basic media | Let selected people use selected services; household-wide DNS |
| **Hardware** | Tier A-B, SSD + data disk + backup disk | Tier B with 8-16 GB RAM | Adds a small always-on device (secondary DNS, external monitor) |
| **Services** | Debian, Docker, Tailscale, restic, smartd, notifications | + Caddy, Immich, files, Uptime Kuma, optionally Jellyfin, Paperless, Vaultwarden | + Cloudflare Tunnel/Access for chosen apps, AdGuard rollout, optional SSO |
| **Networking** | LAN + tailnet | Domain, wildcard cert, split DNS | Public hostnames (few), DHCP DNS change, tailnet policy refined for family |
| **Backups** | Local + off-site, restore-tested | DB dumps, per-app restore rehearsals | Review scope of backup credentials; test restore of public-facing app |
| **Security** | Baseline hardening | App auth + MFA, exposure matrix enforced | Access policies, device/user audits, credential rotation |
| **Added maintenance** | Monthly patch review, alert triage | Monthly app updates, quarterly restore test | Review Access logs/users, resolver redundancy checks |
| **Migration steps** | n/a | Add apps one by one | Introduce resolver redundancy before switching DHCP |
| **Proceed when** | Phases 0-7 done | Stage 1 stable for about a month, restore tested | Phases 6-7 verified and a real need exists |

| | Stage 4 | Stage 5 | Stage 6 |
|---|---|---|---|
| **Name** | CCTV/NVR and game servers | Separate storage, backup or compute machines | Virtualisation, GPU, advanced networking, orchestration |
| **Problem solved** | Cameras and shared games | Isolation, capacity, resilience beyond one box | Needs that Compose on one or two hosts cannot meet |
| **Hardware** | Dedicated surveillance disk; camera network (VLAN or second NIC); more RAM/CPU | NAS, backup box at another location, dedicated media/NVR box | Hypervisor host, GPU, managed switch |
| **Services** | Frigate-class NVR, game containers | Move heavy or sensitive services; keep infra consistent | Proxmox/VMs, GPU workloads, maybe Kubernetes |
| **Networking** | Camera isolation with no internet; game exposure decision | Inter-host links over LAN/tailnet; DNS names stay stable | VLANs, firewall segmentation |
| **Backups** | Selective clip export; game save backups | Backup target on another machine/site (append-only if possible) | VM-level plus application-level backups |
| **Security** | Camera isolation, strong auth, no public viewing by default | Per-host least privilege; service accounts per host | Hypervisor hardening, secrets distribution |
| **Added maintenance** | Disk wear, retention tuning | Patching N hosts; monitoring N hosts | Cluster upgrades, certificate and storage lifecycle |
| **Migration steps** | New stacks with limits; watch resources | Replicate data, test on the new host, switch names, retire the old copy after a clean period | Rebuild-from-Git rehearsal on the new platform first |
| **Proceed when** | Measured headroom: sustained CPU and RAM comfortable, spare disk bays | Measured benefit: contention, noise/heat, blast-radius or capacity limits | Concrete requirement, not curiosity |

## When to consider each addition

| Addition | Consider when | Do not bother when |
|----------|---------------|--------------------|
| Separate NAS | Disk count/capacity outgrows the chassis; you want storage independent of compute | A couple of disks in the main box are enough |
| Secondary backup machine | You want a different failure domain, ideally in another home; ransomware resistance via append-only access | Off-site object storage already meets your recovery needs |
| Dedicated media server | Many concurrent streams or GPU transcoding contend with other apps | Direct play covers your household |
| Dedicated NVR | More than a few cameras or you want recording continuity independent of the main server | One or two cameras with motion recording |
| GPU machine | Measured transcoding or AI demand the iGPU cannot meet | Occasional light use |
| Proxmox / VMs | You need isolated OSes, VM snapshots, passthrough, or to test rebuilds safely | Everything fits in Docker on one host (Immich also documents Docker-in-LXC as not recommended **[V]**) |
| Kubernetes | Several hosts, a need for declarative rolling deployments/self-healing at scale, or a deliberate learning goal | A home server: it adds a control plane, ingress, storage drivers and upgrade burden for little gain. Compose + Git + backups is usually the right size |

## Kubernetes, honestly

Benefits: declarative state, rolling updates, scheduling across nodes, a large ecosystem. Costs: control-plane upkeep, networking and storage layers (CNI, CSI), certificate and version upgrades, a steeper failure-debugging path, higher idle RAM, and many home-server apps ship only Compose examples. It becomes justified when you have several machines, services that must move between them automatically, or you want the skill. It is not the inevitable destination of a home server.
