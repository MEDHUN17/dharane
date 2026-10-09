# Owner profile (provisional input, not a constraint)

**How to read this file.** It records what the owner has said so far, so that decisions start from real numbers instead of guesses. It is an *input*: nothing in the blueprint (`docs/00` to `docs/12`) depends on it, and nothing here narrows what the repository describes. When a value is measured or changes, edit it here and re-read the [revisit triggers](../docs/14-decision-guide.md#7-revisit-triggers) in the [decision guide](../docs/14-decision-guide.md). Values marked *unknown* are genuinely unknown: a blank is not a "no".

**This repository is public**, so only counts, ranges and classes are recorded. Left out on purpose: the ISP name, the domain name, IP addresses, account and tailnet names, serial numbers, router make and credentials, and the password-manager brand (recorded only as "hosted"). Keep those in a private place: a private repository, or a local file named `profile/<name>.local.<ext>` (git ignores that pattern).

Status: **provisional**. First recorded 2026-10-09 from the owner's chat answers to [Part L](../docs/11-information-needed.md); the follow-up questions there are still open.

**Source column.** *said* = stated by the owner; *range* = the owner gave alternatives; *inferred* = my reading of what was said; *unknown* = not answered yet.

## 1. Machine

| Item | Recorded | Source | What it decides | How to check (read-only) |
|------|----------|--------|-----------------|--------------------------|
| Server candidate | Old laptop(s) with a "pretty old" Core i3; how many laptops is not stated | said + unknown | Tier A ([`03`](../docs/03-hardware-capacity.md)); a second laptop can become the second DNS resolver, watcher or subnet router ([`13`](../docs/13-low-end-profile.md) section 2) | Count the machines |
| CPU generation and flags | Core i3 class, probably dual-core (older mobile i3 parts are) | inferred **[K]** | AVX2 for Frigate, Quick Sync for Jellyfin, x86-64-v2 for Immich machine learning ([`03`](../docs/03-hardware-capacity.md) section 1) | Linux: `lscpu`. Windows: Settings > System > About, then look the model number up |
| RAM | 4 GB or 8 GB (which machine has which is not stated) | range | Which single heavy workload fits ([`13`](../docs/13-low-end-profile.md) section 2) | `free -h`; Windows: Task Manager > Performance > Memory |
| Internal disk | One 256 GB disk, hard drive or SSD (type not stated) | range | Immich needs its database on an SSD **[V1]**; Docker on a spinning laptop disk is slow ([`13`](../docs/13-low-end-profile.md) section 3) | `lsblk -o NAME,SIZE,ROTA,MODEL` (ROTA 1 means spinning) |
| Extra disks | None stated | unknown | Where photos, files and the backup copy live ([`02a`](../docs/02a-storage-layout.md)) | List the drives you own |
| Ethernet vs Wi-Fi only | Not stated | unknown | Wi-Fi servers are unreliable ([`03`](../docs/03-hardware-capacity.md) section 2) | `ip -br a` |
| Battery, lid, heat | Not stated | unknown | A healthy battery is a tiny UPS; a swollen one must come out ([`13`](../docs/13-low-end-profile.md) section 3) | Look at the battery; check temperatures under load |
| Can it be wiped and dedicated? | Not stated | unknown | The install replaces the existing OS | Ask who else uses it |

## 2. Network and router

| Item | Recorded | Source | What it decides | How to check |
|------|----------|--------|-----------------|--------------|
| Router | Does not support port forwarding | said | Nothing may rely on inbound connections: the design already assumes this ([`00`](../docs/00-executive-summary.md) section 3, row 3) | Router settings page |
| Router DNS setting | Not stated | unknown | Whether ad blocking can be rolled out household-wide or per device ([`13`](../docs/13-low-end-profile.md) section 6) | Router LAN/DHCP page: can the DNS servers be changed? |
| Router admin access | Not stated | unknown | Same as above | Ask whoever installed it |
| Internet plan | Advertised as "4 megabyte": either 4 Mbps or 4 MB/s (= 32 Mbps). Unit not confirmed | range | An 8x difference for off-site seeding time and remote streaming ([`13`](../docs/13-low-end-profile.md) sections 5 and 6) | Speed test (fast.com or speedtest.net) |
| Upload speed | Not stated | unknown | Off-site seed time; remote streaming (Jellyfin recommends at least 20 Mbps upload **[V5]**) | Same speed test: read the *upload* figure |
| Data cap | Not stated | unknown | Whether big off-site seeding and remote streaming are allowed | ISP bill or plan page |
| CGNAT or public IPv4 | Not stated. A router without port forwarding does not by itself prove CGNAT | unknown | Whether any inbound hosting is possible even with a better router | Compare the router's WAN address with an external "what is my IP" page; 100.64.0.0 to 100.127.255.255 means CGNAT |
| IPv6 | Not stated | unknown | Whether a second reachability path exists | Router status page |

## 3. Power and place

| Item | Recorded | Source | What it decides |
|------|----------|--------|-----------------|
| UPS | Available, capacity not stated | said | Graceful shutdown, outage survival ([`04`](../docs/04-power-physical.md)) |
| Router and modem on the UPS | Not stated | unknown | The server stays reachable only if the network gear stays up too |
| State, tariff slab, power cuts | Not stated | unknown | Electricity cost ([`08`](../docs/08-cost.md) section 2) and UPS runtime |

## 4. People, devices and access

| Item | Recorded | Source | What it decides |
|------|----------|--------|-----------------|
| Household | 4 members | said | Accounts and permissions ([`apps/O`](../docs/apps/O-family-access.md)) |
| Phones | Android | said | Photo upload client and Tailscale on phones ([`05`](../docs/05-device-integration.md)) |
| TVs | Yes; make, model and OS not stated | said + unknown | Which media apps and Tailscale options exist per TV ([`05`](../docs/05-device-integration.md)) |
| PCs and consoles | Not stated | unknown | Game clients, sync clients |
| Invited remote people | Not stated | unknown | Whether Tailscale is enough |
| "Public" audience | Wants the media server and a game server to "work for public"; whether that means strangers or friends who can install an app is not stated | said + unknown | Whether a public door is needed at all ([`apps/00`](../docs/apps/00-exposure-matrix.md), [`apps/N`](../docs/apps/N-game-servers.md)) |

## 5. Money, domain and accounts

| Item | Recorded | Source | What it decides |
|------|----------|--------|-----------------|
| One-time budget | Rs 12,000-15,000 | said | Which rungs of the upgrade ladder are reachable ([`08`](../docs/08-cost.md) Scenario D) |
| Monthly budget | Rs 200 | said | Off-site backup size and provider |
| Does the monthly figure include electricity? | Not stated | unknown | Which off-site option fits ([`08`](../docs/08-cost.md) Scenario D) |
| Domain | Owned (name not recorded) | said | HTTPS names, Cloudflare options ([`apps/A`](../docs/apps/A-remote-access-infrastructure.md)) |
| Cloudflare account | Can be created | said | Same |

## 6. Priorities, ranked by the owner

1. Photo backup
2. File sync
3. Ad blocking
4. Password management
5. Documents
6. CCTV
7. Game servers
8. Local AI
9. Media server
10. Development

The ranking orders the *effort*, not the wish list: the owner also wants the media server and a game server to be reachable by "public" users, even though the media server is ranked ninth.

## 7. Data, cameras and games

| Item | Recorded | Source | What it decides |
|------|----------|--------|-----------------|
| Photos and videos | Size not stated | unknown | Disk size, off-site seeding time |
| Documents | Size not stated | unknown | Same |
| Media library | "All my childhood shows and movies"; size not stated | said + unknown | Disk size; whether transcoding matters |
| Existing backups | None | said | Backups come first ([`09`](../docs/09-roadmap.md) Phase 6, [`13`](../docs/13-low-end-profile.md) section 5) |
| Cameras | 16, wired. Analog (coax to a DVR) or IP, whether a recorder with a disk exists, brand: not stated | said + unknown | Which CCTV path applies ([`apps/M`](../docs/apps/M-cctv-nvr.md)) |
| Games | Minecraft and "other similar titles"; 4 to 8 players. Java or Bedrock, consoles: not stated | said + unknown | Game-server plan ([`apps/N`](../docs/apps/N-game-servers.md)) |
| Local AI, development | Ranked low; no specifics | said | Whether they matter on this hardware |

## 8. Security habits

| Item | Recorded | Source | What it decides |
|------|----------|--------|-----------------|
| Authenticator | An authenticator app (TOTP) | said | Recovery design ([`06`](../docs/06-security-backup.md)) |
| Password manager | A hosted service (brand not recorded) | said | Whether to self-host later ([`apps/F`](../docs/apps/F-secrets-and-identity.md)) |
| Account recovery codes printed | Not stated | unknown | Whether a lost phone is recoverable |

## 9. Measurements that settle the most (all read-only)

In order of how many open questions each one closes:

1. CPU model (Linux: `lscpu`; Windows: Settings > System > About) - tells which of AVX2, Quick Sync and x86-64-v2 exist.
2. RAM and disk type for each laptop (`free -h`, `lsblk -o NAME,SIZE,ROTA,MODEL`).
3. A speed test: download **and upload**, in megabits per second.
4. The router's WAN address against an external "what is my IP" page (CGNAT check).
5. Whether the cameras use coax/BNC cables to a recorder (analog) or network cables (IP), and whether a recorder with a disk already exists.
6. Rough sizes: photos and videos on the phones, documents, the media library.
7. The router's DHCP/LAN page: can the DNS servers be changed?

The full follow-up list is at the end of [`11-information-needed.md`](../docs/11-information-needed.md).

## 10. Decisions this profile does not make

Which machine to keep or buy; which applications to run; whether anything is made public; which off-site provider to use; whether to buy a DVR or NVR; whether to self-host passwords. Those stay open until measured, and each has its [decision path](../docs/14-decision-guide.md#5-decision-paths) in the guide. Nothing in the blueprint should be bent to fit this file.

## Change log

| Date | Change |
|------|--------|
| 2026-10-09 | First recording of the owner's Part L answers (sanitised) |
