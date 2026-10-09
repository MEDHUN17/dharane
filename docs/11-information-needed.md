# Part L - Information needed from you

The plan does **not** block on these answers: provisional assumptions are in `00-executive-summary.md` section 3 and will be replaced as you answer. Partial answers are fine. Answer in chat (not in this public repo).

**Never send:** passwords, auth keys, API tokens, private keys, recovery codes, your exact home address, or your public IP. Disk serial numbers: last 4 characters are enough.

> **Status:** first answers received in chat and deliberately **not stored in this public repository**. The profile they point to is described generically in [`13-low-end-profile.md`](13-low-end-profile.md). Remaining follow-ups are listed in section "Follow-up questions" at the end.

## Questions (and why each matters)

| # | Question | Why I ask / what it changes |
|---|----------|------------------------------|
| 1 | **Machines.** What will be the server (make/model, CPU model, RAM size and free slots, laptop or desktop)? Any spare devices (Raspberry Pi, old PC, old router)? | Tier (Part D), iGPU and codec support, whether a laptop's lid/battery behaviour needs configuring, whether a secondary DNS/monitor device already exists |
| 2 | **Drives.** Each disk: SSD or HDD, size, model if known; free bays/ports; how much data (photos, videos, documents) must move onto the server | Storage layout, capacity plan, whether a backup disk is possible now |
| 3 | **Router and LAN.** Router make/model (ISP-supplied?), do you have admin access, can it do DHCP reservations, custom DNS in DHCP, port-forward, VLANs? Ethernet near the server? | DNS design, camera isolation, whether Wi-Fi-only is a blocker |
| 4 | **Internet.** ISP name, plan type (fibre/cable/wireless), download and **upload** speed, data cap, public IPv4 or CGNAT (how to check: Phase 0), IPv6? | Exposure design, game servers, off-site backup seeding time, remote streaming limits |
| 5 | **Location and power.** State/DISCOM and your electricity tariff slab (Rs/kWh), power-cut frequency/duration, existing inverter/UPS, where the server will sit and ventilation | Electricity cost model (Part I), UPS sizing (Part J phase 2), cooling |
| 6 | **Devices and users.** Phones/tablets (OS versions), PCs (Windows/macOS/Linux), smart TV make/model/OS, number of family members and how technical each is | Client matrix (Part F), Tailscale vs browser vs share per person |
| 7 | **Priorities.** Rank: photo backup, file sync/sharing, media streaming, ad blocking, password manager, documents, CCTV, game servers, development, local AI | What goes in Stage 2 vs later |
| 8 | **Budget.** One-time ceiling, monthly ceiling, willingness to buy a UPS/disks/second device | Part I scenarios |
| 9 | **Domain.** Do you own a domain? Which registrar? Existing Cloudflare account? OK to buy one? | HTTPS design and Cloudflare options |
| 10 | **Public access.** Does anything need to be usable by people who will not install Tailscale? Who, and what for? | Whether Stage 3's public door is needed at all |
| 11 | **Backups today.** Existing backups? Who could host an off-site copy (a relative)? Cloud storage budget? How much data is irreplaceable? | Off-site design and seeding plan |
| 12 | **Security habits.** Authenticator app or hardware key? Which password manager do you use now? | MFA and recovery design |
| 13 | **Optional workloads.** Cameras (count, brand, wired/Wi-Fi)? Which games and how many players? Media library size and formats? | NVR sizing, game-server plan, transcoding needs |

## How to collect hardware facts safely (none of these change anything)

**Linux** (if the machine already runs Linux or a live USB):
```
lscpu
free -h
lsblk -o NAME,SIZE,TYPE,ROTA,MODEL
ip -br a
lspci | grep -i -E 'vga|3d|ethernet|network'
sudo smartctl -H /dev/<disk>
```
`ROTA=1` means a spinning disk, `0` means SSD. The SMART health line is read-only.

**Windows:** Settings > System > About for CPU/RAM; Task Manager > Performance for disks and network; or PowerShell `Get-PhysicalDisk | Select FriendlyName,MediaType,Size` (read-only).

**macOS:** Apple menu > About This Mac > More Info.

## Copy-and-fill template

```
Server machine:
Drives (type/size/free bays):
Data to migrate (GB photos/videos/docs):
Router + admin access + features (DHCP reservation, DNS in DHCP, VLAN):
ISP, plan type, down/up Mbps, CGNAT? IPv6?:
State/DISCOM, tariff Rs/kWh, power cuts, UPS/inverter:
Devices (phones, PCs, TVs) + family members:
Priorities (ranked):
Budget (one-time / monthly):
Domain / Cloudflare account:
Anything that must be public (who/what):
Existing backups / off-site host option:
MFA + password manager in use:
Cameras / games / media size:
```

## What happens after you reply

1. I classify the machine into a tier and say which Stage 2-4 workloads are realistic (Part D section 11).
2. I fill Part I with prices (dated, sourced, estimates marked) for your scenario.
3. We start **Phase 0 -> Phase 1** interactively, one small verified batch at a time (`09-roadmap.md`).

## Follow-up questions (what blocks a purchase or an install)

1. **Laptops:** how many; for each the exact CPU model (Windows: Settings > System > About), RAM, whether the drive is an HDD or SSD (Task Manager > Performance > Disk), and whether it can be wiped and dedicated to the server.
2. **Speed test:** download **and upload** in Mbps (fast.com or speedtest.net); whether the advertised plan speed is in megabits per second (Mbps) or megabytes per second (MB/s); any data cap; whether the router's WAN address looks like CGNAT (100.64.x.x to 100.127.x.x or a private range).
3. **Router:** make and model; whether the DHCP/LAN settings let you change the DNS servers; whether you have the admin password.
4. **Cameras:** coax/BNC cables to a DVR (analog) or network cables (IP)? Is there already a recorder with a hard disk?
5. **Data size:** roughly how many GB of photos and videos across the phones (Settings > Storage), and whether Google Photos/Google One is already in use; how much documents; rough media library size.
6. **"Public":** people you know who can install an app, or anyone? Minecraft Java or Bedrock; other games; do any players use consoles?
7. **Budget:** does the monthly figure include electricity?
