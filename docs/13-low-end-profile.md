# Constrained single-laptop profile

For: an old dual-core Core i3-class laptop, **4-8 GB RAM**, a single **~256 GB** internal disk, an uplink of a few Mbps, a router with **no port forwarding** (or CGNAT), and a small budget (this profile uses about Rs 12,000-15,000 once and Rs 200 a month as a worked example; scale the figures to yours). It adapts the blueprint to those limits and overrides the tier defaults where it says so. It is one profile among several: the [decision guide](14-decision-guide.md) shows the same workloads for other machine classes and says what to re-read when a value changes.
Labels: **[V]** verified in docs, **[S]** search summary (see [`12-verification-log.md`](12-verification-log.md)), **[K]** stable knowledge, **[E]** estimate, **[U]** unverified, **[C]** low-confidence price. No identifying details (ISP, domain, addresses, accounts) live in this public repo; the owner's sanitised answers are in [`../profile/owner.md`](../profile/owner.md).

## 1. Verdict by workload

| Workload | Verdict | Condition and notes |
|----------|---------|---------------------|
| Backups (local + off-site) | **Do first** | Nothing else matters if the photos exist only on phones. Section 5 |
| Photo backup | **Do now** | Immich if the box has 8 GB **and** an SSD, otherwise Syncthing-Fork plus plain folders (section 4) |
| File sync | **Do now** | Syncthing; very light |
| Ad blocking | **Do now** | AdGuard Home is tiny; DNS plan in section 6 |
| Documents | **Do now as folders + backup**; Paperless-ngx later | Paperless wants roughly 1.5-2.5 GB RAM **[E]** and OCR bursts; only on the 8 GB box and not together with Immich |
| Passwords | **Do not self-host yet** | Harden the current manager or move to a hosted one (section 9) |
| Private remote access | **Do now** | Tailscale: needs no inbound ports |
| Media server | **Home TVs: yes. Remote: very limited. Public: no** | Direct play on the LAN is cheap; the uplink and the law limit the rest (section 7) |
| Game server | **Possible for players you invite; not public from home** | One heavy workload per 8 GB box (section 2); public options in section 7 |
| CCTV, 16 cameras | **Not on this laptop** | Needs a recorder with its own disk; the laptop can provide secure remote access only (section 8) |
| Local AI | **Not on this hardware** | Use an external API or a phone app |
| Development | **Yes, light** | SSH, Git, an editor; skip code-server |

## 2. RAM budget (all figures **[E]**; measure with `docker stats` and `free -h`)

| Service | Idle |
|---------|------|
| Debian headless + Docker | 0.6 GB |
| Tailscale, Caddy, AdGuard Home, Syncthing, Samba | about 0.5 GB together |
| restic backup run | up to ~1 GB while running |
| Jellyfin, direct play | 0.5-0.8 GB |
| **Immich with machine learning off** | about 2-3 GB (the docs allow 4 GB machines only with ML disabled **[V]**; 6 GB minimum otherwise **[V]**) |
| **Minecraft Java, small group** | about 3 GB with a 2 GB heap |
| **Paperless-ngx** | about 2 GB |

- **4 GB laptop:** the light stack plus, at most, Jellyfin. No Immich, no game server, no Paperless. Enable zram compressed swap **[K]**.
- **8 GB laptop:** the light stack plus Jellyfin plus **one** of Immich (ML off), a Minecraft server, or Paperless. Two of them together will swap and stall.
- **Two laptops:** the 8 GB one is the main server; the 4 GB one becomes the second DNS resolver, the Tailscale subnet router (for the DVR) and the outside watcher, at no cost.

## 3. Preparing a laptop to be a server

| Item | What to do **[K]** |
|------|--------------------|
| Battery | Check for swelling before running 24/7; a swollen battery must be removed. A healthy battery works as a tiny built-in UPS and lets the OS shut down when low. Many laptops will **not** power back on by themselves after the battery runs flat, so rely on the heartbeat alert to tell you |
| Lid | Configure the lid switch to do nothing, and disable suspend |
| Network | Wired Ethernet, not Wi-Fi. Old Wi-Fi chips often need non-free firmware |
| Heat | Clean the fan and vents; hard, ventilated surface; consider fresh thermal paste on a very old machine |
| Disk | **An SSD is the single best upgrade** for a 256 GB internal disk if it is a hard drive: databases and Docker on a spinning laptop disk are slow and fragile (Immich requires its database on local SSD **[V]**). A 256 GB 2.5" SATA SSD was listed at Rs 2,200-3,800 in June-October 2026 **[S]** |
| Power | Plug into the UPS; put the router and ONT on it too (`04-power-physical.md`) |
| CPU features | Check `lscpu`/`/proc/cpuinfo` flags: Frigate needs AVX and AVX2 **[V]**; Immich's ML container needs x86-64-v2 **[V]**; Jellyfin needs SSE4.1 **[V]** |
| Old iGPU | Linux Quick Sync works from Broadwell (5th gen) onward; older Intel graphics use VA-API; H.264 is supported on any QSV-capable part, HEVC 8-bit from Skylake **[V]**. Plan on direct play, not transcoding |

## 4. Storage plan and the photo tool

- **Internal 256 GB (SSD preferred):** OS, Docker, app state, databases, and a *small local backup of the critical set* (documents, configuration, database dumps).
- **External drive(s):** photos, files, documents, media. A bus-powered 2.5" portable drive is simplest; a 3.5" drive gives more terabytes per rupee but needs its own power adapter and enclosure.
- **Power trap:** a 3.5" dock on a wall socket loses power in an outage while the laptop keeps running on its battery. Put the dock on the UPS, and mount the data directories so apps refuse to start if the drive vanishes (`02a-storage-layout.md`: `nofail`, immutable mountpoint, sentinel file). A bus-powered drive survives as long as the laptop's battery does.
- **USB drives and sleep:** disable USB autosuspend and disk spin-down for the data drive, or it can disconnect under load **[K]**.

**Choosing the photo tool by rule**

| Situation | Use |
|-----------|-----|
| 8 GB RAM **and** SSD, no game server on the same box | **Immich with machine learning off**: the phone app is easy for non-technical family members; originals on the external drive, database on the SSD **[V]** |
| 4 GB RAM, or only a hard drive | **Syncthing-Fork** on each phone writing to plain folders on the laptop, plus restic |

Syncthing safety **[V]**: file versioning defaults to *none*, so turn on **Trash Can** versioning (deleted files go to `.stversions`); do not enable `ignoreDelete` (the docs reserve it for power users). Make the server side of each phone folder *receive-only* so a mistake on the server cannot spread back **[K]**. The official Syncthing Android app is discontinued; a community fork, Syncthing-Fork (repository `researchxxl/syncthing-android`, F-Droid package `com.github.catfriend1.syncthingfork`), is documented in its README, but check its latest release date yourself **[V][U]**.

## 5. Backups on a tiny budget

**This week, at no cost:** turn on Google Photos backup on each phone, or copy each phone's DCIM folder to the laptop over USB. Google Photos' free space is shared with Gmail and Drive **[K]**. This is the stopgap until the server exists.

| Off-site option (about Rs 200/month) | Cost | Notes |
|--------------------------------------|------|-------|
| **Backblaze B2 + restic** | US$6.95/TB/month **[S]**: about Rs 667/TB, so **~300 GB for ~Rs 200/month** | Client-side encryption; needs the setup in `06-security-backup.md`; free egress up to 3x stored **[S]** |
| **Google One 100 GB** | Rs 130/month; 200 GB Rs 210/month; family sharing **[S]** | Simplest for photos and already on the phones; Google can read the data; not for restic |
| A relative's drive, swapped monthly | One extra drive | Free monthly; gaps between swaps |
| Wasabi / flat-rate boxes / R2 | Over budget **[S]** | Wasabi has a 1 TB minimum; a 1 TB storage box is about Rs 350/month before VAT |

Domain renewal (about Rs 80/month equivalent) is a recurring cost too, so Rs 200 covers roughly 180 GB on B2 plus the domain.

**Seeding time** `days = GB x 8000 / (uplink_Mbps x 0.8 x 86400)`; measure the *upload* speed first:

| Data | 1 Mbps up | 2 Mbps up | 4 Mbps up |
|------|-----------|-----------|-----------|
| 100 GB | 11.6 days | 5.8 days | 2.9 days |
| 300 GB | 34.7 days | 17.4 days | 8.7 days |

Use restic's `--limit-upload` so the household can still use the line **[V]**, and seed documents first, then photos by recency.

**What is backed up:** documents, photos, configuration, database dumps. Media and camera footage are *not* (too large; re-acquirable or expendable). The honest gap: one external drive plus one off-site copy is two copies, not 3-2-1. Add a second local drive when the budget allows.

## 6. Network and DNS on this connection

- **Design for no inbound connections.** Tailscale and Cloudflare Tunnel are outbound only. Check CGNAT: if the router's WAN address is in 100.64.0.0/10 or a private range, or differs from the address a "what is my IP" site shows, inbound is blocked at the ISP **[K]**.
- **Uplink math:** a remote video stream needs roughly the file's bitrate. Jellyfin recommends at least 20 Mbps of upload for remote access **[V]**; a few Mbps supports at most one low-bitrate stream **[E]**. Home TVs on the LAN are unaffected.
- **DNS exception to the blueprint's rule.** Normally both resolvers must filter identically. With one machine and possibly no DNS setting in the router, a pragmatic design is: AdGuard Home on the laptop as primary, and a *hosted filtering resolver* as the secondary (AdGuard DNS default servers 94.140.14.14 and 94.140.15.15 **[S]**). It still filters ads, but it cannot resolve your internal names; accept that and use IP addresses or the Tailscale names for the server. If the router cannot hand out DNS, set static DNS per device (Android Wi-Fi settings, Android TV network settings) **[K]**. Verify any Private DNS hostname on the vendor's page before using it.
- **Subnet router for a DVR or other LAN-only device:** the laptop advertises the LAN to Tailscale; Docker's forwarding policy defaults to drop and must be allowed for this to work **[V]**.

## 7. "Public" media and game servers

**Media.** Do not publish it:
1. There are no inbound ports (and probably CGNAT), so a public server cannot be reached.
2. The uplink cannot carry several viewers.
3. Cloudflare's terms restrict serving video through its CDN unless you use its paid services **[S][U]**.
4. Making copyrighted films and shows available to the public is distribution and a legal risk; this is not legal advice.

What works: TVs in the house over the LAN (Jellyfin has Android TV/Fire OS, LG webOS, Samsung Tizen, Roku and tvOS clients; check each TV model **[V]**); family and invited people over Tailscale with Android TV and Apple TV devices able to run it **[S]**, within the upload limit.

**Game server.** Options in order of fit:

| Option | Cost | Notes |
|--------|------|-------|
| **Tailscale for invited players** (PC and Android; consoles cannot) | Rs 0 | Works behind CGNAT, private, no DDoS exposure; the free plan reportedly allows 6 users **[S]**, node sharing for more. Test whether the old CPU copes with 4-8 players **[E]** |
| Aternos (free hosting) | Rs 0 | Ad-supported, start queues, sleeps when empty, limited RAM and mods; Java and Bedrock **[S]** |
| playit.gg tunnel from the home server | Free tier, premium US$30/year **[S]** | Outbound tunnel, works behind CGNAT; reports conflict about Java/TCP on the free tier **[U]** |
| Oracle Cloud Always Free | Rs 0 | Reported cut to 2 OCPU/12 GB in June 2026, frequent "out of capacity", card verification **[S][U]**; an experiment, not a plan |
| Paid Minecraft host in India | about Rs 400 and up for 4 GB, vendor claims **[S]** | Over the stated budget |

## 8. CCTV with many cameras

Sixteen cameras need a **recorder with its own disk**: at 1 Mbps each that is about 173 GB per day, at 2 Mbps about 346 GB per day; a 256 GB disk holds under two days, and a 4 TB disk about 12-23 days **[E]**. AI detection needs decoding and a capable CPU; Frigate also needs AVX2 and 4-16 GB RAM **[V]**. Therefore:

- **Existing DVR/NVR:** keep it. Change its passwords, turn off cloud/P2P features, update firmware, and reach it through the laptop as a Tailscale subnet router. Do not forward ports.
- **Analog cameras and no recorder:** a 16-channel analog DVR was listed around Rs 5,700-14,500 before the hard disk (a surveillance-rated 2 TB disk was Rs 13,000-16,000 and a 4 TB one Rs 12,000-21,500 in 2026 **[S][C]**); a full kit with cameras and disk was listed at Rs 30,000-45,000, a price that predates the 2026 disk rise, so treat it as a floor **[S][C]**. That is a separate budget; defer it.
- Remote viewing over a slow uplink: view one sub-stream at a time.

## 9. Passwords and account recovery

- **Do not self-host a password manager on this setup yet:** old hardware, no HA, no tested backups.
- **If your hosted manager has had a breach (LastPass in 2022 is the best-known case):** that breach copied encrypted vaults; the risk is highest for a short or old master password and a low iteration count. UC Berkeley's guidance: iterations of at least 600,000, MFA on, and changed passwords for sensitive accounts; researchers link later crypto thefts to cracked vaults **[S]**. Steps: long unique master password, check the iteration setting in Account Settings, rotate banking/email/crypto passwords, move any seed phrases out of the vault, and consider moving to a hosted manager such as Bitwarden **[S]** (affiliate-style reviews exist, so weigh them).
- **Google Authenticator:** turn on its Google-account backup so a lost phone is recoverable; this sync is reported as not end-to-end encrypted, so protect the Google account itself **[S]**. Generate and print the Google account's backup codes **[S]**.

## 10. Staged plan

| Stage | What | Gate to continue | Rough cost |
|-------|------|------------------|-----------|
| **S0 (this week)** | Phones to Google Photos or USB; Authenticator backup and Google backup codes; password-manager hygiene; speed test; read the CPU model and drive type | Photos exist in two places | Rs 0 |
| **S1** | Buy storage (section 11); install Debian headless; SSH keys; firewall; Tailscale; restic local + one off-site; **restore test** | A file restored from off-site | storage + about Rs 200/month |
| **S2** | Syncthing-Fork for photos/files (or Immich with ML off); AdGuard Home with the DNS exception; documents as folders | Family phones syncing; alerts working | Rs 0 |
| **S3** | Jellyfin on the LAN for TVs; DVR secured behind the subnet router; Minecraft for invited players on Tailscale | Headroom measured: free RAM, CPU, disk | Rs 0 |
| **S4** | Second local drive; Paperless-ngx (8 GB box, no Immich); hosted/paid game host if truly public | Budget and measured need | by need |

## 11. What to buy, and in what order **(prices are provisional [S][C])**

Memory and storage became much more expensive in 2026, so the cheap, high-impact steps come first. The ladder in [`14-decision-guide.md`](14-decision-guide.md) section 6 has the price bands and what each step unlocks.

1. **Nothing until you know:** RAM and its type (DDR3L or DDR4), CPU model, HDD or SSD, how many laptops, upload speed, data size.
2. **SSD swap** if the drive is a hard drive: Rs 2,200-3,800 **[S]**.
3. **RAM to 8 GB** if the laptop has 4 GB and a free or replaceable SO-DIMM slot: Rs 600-2,000 for DDR3L, Rs 5,200-7,600 for DDR4 **[S]**. Read the memory type first, with `sudo dmidecode -t memory` on Linux or `Get-CimInstance Win32_PhysicalMemory` in Windows PowerShell **[V]**.
4. **Data drive:** the cheapest reliable capacity that fits your data. A 512 GB SATA SSD in an enclosure is about Rs 3,800-7,100 **[S]**. Hard drives now cost far more than older lists say: a portable 1 TB is Rs 8,999-11,200 and a 2 TB Rs 11,250-13,150 (only about Rs 2,250 more), a 2 TB surveillance-rated 3.5" drive Rs 13,000-16,000, a 4 TB NAS-class drive Rs 23,700-26,500 **[S]**. Used drives are asked at one-third to two-thirds of new (1 TB Rs 1,500-5,000, 2 TB external Rs 4,200-7,500) but need a SMART check **[C]**. Drives of 2 TB and more, especially 2.5" portables, are often SMR (shingled): fine for photos and backup copies, poor for databases; the model codes known to be SMR are in `08` **[S41][V35]**. Prices conflicted between sources and are at a high: check live listings, compare with the six-month history before a festive-sale purchase, and prefer a known brand with a proper invoice.
5. **Small items:** an Ethernet cable (Rs 145-355) and a USB stick for the Debian installer (Rs 400-600): about Rs 550-950 together **[S]**.
6. **Later:** a second drive for a local backup copy, then a recorder if you need one.

Cost tables for this scenario are in [`08-cost.md`](08-cost.md) (Scenario D).
