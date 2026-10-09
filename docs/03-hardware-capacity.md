# Part D - Hardware classification and capacity planning

Hardware is **unknown**. These are workload classes, not product recommendations. Labels: **[V]** read in the project's docs on 2026-10-09, **[K]** stable knowledge, **[E]** estimate that you must measure on your hardware, **[U]** unverified.

> A published "minimum" is a point where the software starts, not where it is pleasant. Plan for the **combined** load, not each container alone.

## 1. Tier definitions (indicative)

| Tier | Class of machine | CPU | RAM | Storage | Network | Idle power **[E]** | Typical role |
|------|------------------|-----|-----|---------|---------|--------------------|--------------|
| **A** | Low-power or old hardware: single-board computers, old laptops/desktops, very old low-end x86 | 2-4 slow cores | 2-8 GB | One SSD (avoid SD cards for databases) | 100 Mb-1 GbE | 3-15 W | Infrastructure and light services |
| **B** | General-purpose: modern Intel N-series/Core i3-i5 mini PC, small desktop, mid-range laptop | 4-8 threads, usable iGPU | 8-32 GB | SSD 256 GB-1 TB plus 1-2 HDDs | 1-2.5 GbE | 8-25 W | Several concurrent apps incl. photos + light media |
| **C** | Higher performance: workstation/desktop class | 8-16+ cores | 32-128 GB | NVMe plus several HDDs | 2.5-10 GbE | 25-60+ W | Heavy library, many containers, game servers, bigger NVR |
| **D** | Specialised: Tier B/C plus a GPU or accelerator | any, with PCIe lanes | 32 GB+ | NVMe plus HDDs | 1-10 GbE | 40-100+ W (150-400+ W under load) | GPU transcoding, local AI, large NVR |

Limits of this table: two machines in the same tier can behave very differently (memory channels, SSD quality, iGPU generation). The real classifier is *measured* headroom, which we collect in Phase 0 and again after Stage 2.

Constrained laptop-class hardware (old dual-core Core i3, 4-8 GB RAM, small disk, slow uplink): see [`13-low-end-profile.md`](13-low-end-profile.md) for what is realistic.

Hardware gotchas that matter regardless of tier:
- **Jellyfin on integrated graphics**: its docs recommend, for example, Intel N100, Core i5-11400 or Pentium Gold G7400 class parts, say **not** to expect good results from Intel J/M/N/Y-series up to 11th gen, advise against AMD graphics for this role, and list most single-board computers (including the Raspberry Pi 5) as too slow for a good experience **[V]**. Jellyfin 10.11 requires a CPU with SSE4.1 **[V]**.
- **Immich machine-learning** on x86 requires the x86-64-v2 level since v3; most CPUs from about 2012 qualify **[V]**.
- **Frigate** needs a CPU with **AVX and AVX2**; these are often absent in low-power or budget parts, notably Intel Celeron/Pentium models before the 2020 Tiger Lake generation and Atom-based chips, so many Tier A machines are ruled out **[V]**. RAM: 4 GB basic minimum with a dedicated detector, 8 GB if you use enrichments, 16 GB recommended for 8+ cameras **[V]**. It prefers wired cameras (Wi-Fi cameras lose streams), lists Intel iGPU/OpenVINO, Hailo and NVIDIA among recommended detectors, and no longer recommends the Google Coral for new installs **[V]**.
- HDDs: avoid SMR drives for busy write workloads and for any parity/rebuild scenario; prefer CMR NAS-class drives, and surveillance-rated drives for 24/7 recording **[K]**.

## 2. Overheads you must budget

| Item | Typical | Notes |
|------|---------|-------|
| Debian headless idle | 0.2-0.4 GB RAM **[E]** | Less than a desktop OS by an order of magnitude |
| Docker daemon + containerd | 0.1-0.3 GB **[E]** | Plus a few MB per idle container |
| Linux page cache | uses "free" RAM | Not wasted: it speeds disk access. Do not count it as used, but do not allocate it away |
| Headroom | 20-25% RAM free at peak **[E]** | Prevents the OOM killer choosing a database |
| Swap/zram | a few GB or compressed RAM **[K]** | A safety net, not extra capacity |

**RAM budgeting method.** For each service write down idle RSS and peak RSS (during import, OCR, transcoding, ML indexing). Sum *idle* for normal operation and *idle + the two largest simultaneous peaks* for the worst case. Add the OS/Docker baseline and the 20-25% headroom. Measure with `docker stats --no-stream` and `free -h` (both read-only) during a first import.

**CPU contention.** Heavy bursts: photo ML and thumbnail generation on first import, OCR, transcoding, video decode for cameras, restic (CPU + IO), library scans. Stagger them (backups at night, bulk imports before bedtime), cap batch containers with `cpus` and `mem_limit` **[V keys exist]**, and run backups under `nice`/`ionice` **[K]**.

**Disk IO.** One HDD cannot simultaneously serve a recording stream, a torrent, a media stream and a backup without stalling. SSD for databases/appdata/thumbnails; HDD for sequential bulk; a *dedicated* surveillance disk; a *separate* backup disk. An iowait that stays high (`iostat -x 5`, read-only) means you are IO-bound, and more CPU won't help.

**Network.** Gigabit Ethernet is the sane floor for anything beyond DNS and notes; Wi-Fi servers are unreliable **[K]**. Jellyfin suggests Gigabit Ethernet and at least 20 Mbps of upload for remote access, and a bandwidth cap near 70% of upstream if your uplink is under 100 Mbps **[V]**. Your *upload* speed is the limit for everything remote.

## 3. Workload profiles

`Peak` = import/ML/transcode burst. Everything marked [E] is a starting expectation; first measure on your box.

### 3a. Resource profile

| Workload | Minimum practical | Recommended | Idle RAM **[E]** | CPU | Storage and growth | Network | Accel |
|----------|-------------------|-------------|------------------|-----|--------------------|---------|-------|
| Tailscale | any | any | ~tens of MB | very low | negligible | low; relay use is slower | none |
| Caddy | any | any | ~tens of MB | very low | tiny (certs) | proxy overhead only | none |
| cloudflared | any | any | ~tens of MB | very low | negligible | upstream-bound | none |
| AdGuard Home / Pi-hole | Tier A | Tier A/B | ~50-150 MB | low | logs/stats grow slowly | low | none |
| Uptime Kuma | Tier A | Tier A/B | ~100-250 MB | low | small DB | low | none |
| Samba / Syncthing | Tier A | Tier B | ~50-300 MB | low (hash/scan bursts) | **the data itself** | LAN speed | none |
| **Immich** | 6 GB RAM, 2 cores **[V]** (4 GB only with ML disabled **[V]**) | 8 GB, 4 cores **[V]** | server + DB + ML: ~2-4 GB **[E]** | **High** during first import (ML, thumbnails, transcode) | library x1.1-1.2 **[V]**; DB 1-3 GB **[V]** on SSD | uploads: LAN/Tailscale | optional hardware transcode/ML |
| Nextcloud | 128 MB/process min, 512 MB recommended **[V]** | Tier B | stack ~1-2 GB **[E]** | medium | data + DB growth | web + sync clients | none |
| **Jellyfin** | 4 GB headless Linux, 8 GB recommended **[V]**; 100 GB SSD for OS/files/transcode cache **[V]** | iGPU-capable Tier B **[V]** | ~0.3-1 GB **[E]** | Direct play: low. Software transcode: very high; 4K HDR tone-mapping can exceed even a Ryzen 9 5950X **[V]** | media size; metadata/cache modest | per stream: roughly the file bitrate **[K]** | **Strongly advised** (Intel iGPU, NVIDIA; AMD not advised) **[V]** |
| Download stack (qBittorrent, Prowlarr, Sonarr, Radarr, Lidarr) | Tier A/B | Tier B | ~150-500 MB each (Sonarr/Radarr ~) **[E]** | low; IO high | downloads + library | upstream/downstream heavy | none |
| **Paperless-ngx** | Tier B | Tier B | ~1.5-2.5 GB with DB + broker **[E]** | OCR bursts are CPU-heavy | originals + archive copies, ~2x **[K]** | low | none |
| Vaultwarden | Tier A | Tier A | ~tens of MB | very low | tiny | low | none |
| Authelia / Authentik | Tier A / Tier B | Tier B | tens of MB / ~1-2 GB **[E]** | low | small | low | none |
| Forgejo/Gitea | Tier A/B | Tier B | ~100-300 MB | low | repos | low | none |
| code-server | Tier B | Tier B/C | ~0.5-2 GB per active user **[E]** | bursty | workspaces | low | none |
| n8n | Tier B | Tier B | ~300-800 MB **[E]** | low | small | low | none |
| Prometheus + Grafana + exporters | Tier B | Tier B | ~0.5-1.5 GB **[E]** | low-medium | grows with retention | low | none |
| **Frigate (NVR)** | 4 GB RAM + AVX/AVX2 CPU + a detector **[V]** | 16 GB for 8+ cameras; OpenVINO/Hailo/GPU **[V]** | ~1-4 GB **[E]** | decode + motion: medium-high | GB/day per camera, see section 6 | camera streams (Mbps each) | video decode + detector **[V]** |
| **Game servers** | game-dependent | Tier B/C | 2-8+ GB each **[E]** | often single-thread-bound | worlds 0.5-5 GB **[E]** | upstream, low per player | none |
| **Ollama / local LLM** | Tier B CPU-only, tiny models | Tier D | model size + context | CPU-only: low tokens/s; GPU: fast | model files 2-40+ GB **[E]** | local | GPU/VRAM strongly preferred |
| restic backup job | Tier A | Tier B | up to ~1 GB on big repos **[E]** | medium + IO | repo size | upstream-bound off-site | none |

### 3b. Operational profile

| Workload | Continuous? | Shares a machine? | Likely conflicts | Modest hardware? | Benefits from a separate machine? | Stop when idle? |
|----------|-------------|-------------------|------------------|------------------|-----------------------------------|-----------------|
| Tailscale, Caddy, cloudflared | Yes | Yes | none | Yes | No | No |
| AdGuard/Pi-hole | Yes | Yes (needs a secondary) | A reboot of this box kills DNS | Yes | **Yes** for resilience: a second small device | No |
| Uptime Kuma | Yes | Yes (needs an external check too) | Cannot report its own host dying | Yes | **Yes**: put the watcher elsewhere | No |
| Samba/Syncthing | Yes | Yes | IO with backups/imports | Yes | NAS later | No |
| Immich | Yes | Yes if >= 8 GB | RAM/CPU with Jellyfin transcodes, Paperless OCR | Borderline on 6 GB | Heavy libraries | ML jobs can be paused |
| Nextcloud | Yes | Yes | PHP/DB RAM | With care | Large multi-user | No |
| Jellyfin | Yes | Yes | CPU/GPU with Immich, Frigate | Only with hardware decode | Many users/streams | No |
| Download stack | Optional | Yes | IO with media + backups | Yes | Isolation from sensitive data | Yes |
| Paperless-ngx | Yes | Yes | CPU on OCR bursts | Yes | No | Consume jobs only on demand if needed |
| Vaultwarden | Yes | Yes | none | Yes | Optionally isolated for blast radius | No (high-availability need) |
| Auth gateways | Yes | Yes | Lockout risk | Yes | No | No |
| Git/dev | Optional | Yes, but isolate dev from public services | RAM spikes | Yes | **Yes** for untrusted code | Yes |
| n8n | Optional | Yes | none | Yes | No | Yes |
| Prometheus/Grafana | Optional | Yes | Disk + RAM | Tier B | Yes at scale | Yes |
| Frigate | Yes | Only with headroom | CPU/IO, disk wear | No for >2 cameras | **Yes**: dedicated NVR box and disk | No (recording gaps) |
| Game servers | When in use | Yes, resource-limited | Single-thread CPU spikes; upstream saturation | Small ones | **Yes**: keep away from personal data | **Yes**, on demand |
| Local AI | Optional | Not with other heavy work | VRAM/RAM | No | **Yes**: GPU box | **Yes** |
| Backups | Nightly | Yes | IO/CPU at night | Yes | Backup machine = better failure isolation | n/a (timer) |

## 4. Compatibility matrix

✅ comfortable ⚠️ possible with caveats or limits ❌ not realistic. Assumes the service runs *together with the Stage 1 base* and typical household use. Treat as a starting point, not a promise.

| Workload | Tier A | Tier B | Tier C | Tier D |
|----------|:------:|:------:|:------:|:------:|
| Tailscale + Caddy + backups + monitoring | ✅ | ✅ | ✅ | ✅ |
| AdGuard/Pi-hole, Vaultwarden, Syncthing/Samba | ✅ | ✅ | ✅ | ✅ |
| Immich (ML on) | ❌ | ✅ (8 GB+) | ✅ | ✅ |
| Immich (ML off, 4 GB) **[V]** | ⚠️ | ✅ | ✅ | ✅ |
| Jellyfin, direct play only | ⚠️ | ✅ | ✅ | ✅ |
| Jellyfin with transcoding | ❌ | ✅ (iGPU) **[V]** | ✅ | ✅ |
| Paperless-ngx | ❌ | ✅ | ✅ | ✅ |
| Nextcloud | ⚠️ (small) | ✅ | ✅ | ✅ |
| Download automation stack | ⚠️ | ✅ | ✅ | ✅ |
| Prometheus + Grafana | ❌ | ✅ | ✅ | ✅ |
| Authentik (full) | ❌ | ⚠️ | ✅ | ✅ |
| Git hosting + code-server | ⚠️ | ✅ | ✅ | ✅ |
| NVR, 1-4 cameras with a detector | ❌ | ✅ **[V]** | ✅ | ✅ |
| NVR, 8+ cameras with AI | ❌ | ⚠️ | ✅ | ✅ |
| Small game server (a few players) | ⚠️ | ✅ | ✅ | ✅ |
| Several / modded game servers | ❌ | ⚠️ | ✅ | ✅ |
| Local LLM, small (about 3-8B quantised) | ❌ | ⚠️ (slow, CPU-only) | ⚠️ | ✅ |
| Local LLM, large | ❌ | ❌ | ❌ | ⚠️ (VRAM-bound) |

### Combined-load examples (all numbers **[E]**: replace with measurements)

**Stage 2 bundle on a 16 GB Tier B host:** OS+Docker 0.6 GB; Immich 3 GB (peak 5 GB during import); Jellyfin 0.8 GB (peak 2 GB while transcoding); Paperless 2 GB (peak 3 GB OCR); Caddy/Tailscale/AdGuard/Uptime Kuma/Vaultwarden 0.6 GB; a restic run ~1 GB. Idle total about 7 GB, a plausible worst-case peak about 12-13 GB, leaving the 20-25% headroom rule satisfied on 16 GB but **not** on 8 GB. Result: on 8 GB, install Immich first, delay Paperless, and keep Jellyfin to direct play.

**Stage 4 bundle:** adding Frigate (1-4 GB plus a detector and a dedicated disk) and a game server (2-8 GB) pushes a 16 GB box over the line; plan 32 GB or a second machine for the NVR.

## 5. Transcoding vs direct play

| Concept | Meaning | Implication |
|---------|---------|-------------|
| Direct play | Client plays the file as stored | Almost no server CPU; only network bandwidth equal to the file bitrate **[K]** |
| Direct stream/remux | Container changed, video copied | Light **[K]** |
| Transcode | Server decodes and re-encodes | CPU or GPU heavy |
| Common triggers | Client lacks the codec (HEVC, AV1, 10-bit); bitrate capped by a slow link; **image-based subtitles burned in**; HDR to SDR tone-mapping | **[K]**; tone-mapping in software is extremely demanding **[V]** |

Mitigations: choose clients that direct-play your formats (Jellyfin's apps vary per platform; verify per device in Part F), prefer text subtitles (SRT) over image subtitles (PGS) **[K]**, use a hardware encoder (Intel iGPU on Linux is the easy path; NVIDIA works; AMD not advised) **[V]**, and cap remote bitrate to your upload (Jellyfin suggests at most about 70% of upstream below 100 Mbps) **[V]**. Rule: measure, then decide whether a GPU is needed.

## 6. NVR sizing (CCTV is optional)

```
storage_GB_per_day_per_camera = bitrate_Mbps * 86400 / 8 / 1000
```

| Example | Per camera per day | 8 cameras x 14 days |
|---------|--------------------|---------------------|
| 2 Mbps continuous | ~21.6 GB | ~2.4 TB |
| 4 Mbps continuous | ~43.2 GB | ~4.8 TB |
| 8 Mbps continuous | ~86.4 GB | ~9.7 TB |

Motion/event-only recording typically cuts this several-fold but adds the risk of missing pre-event footage **[E]**. Use a surveillance-rated HDD for long retention (Frigate notes modern SSDs are fine for endurance and HDDs are the cost-effective choice for large archives **[V]**), keep recordings off the system disk so that a full recording disk can never take down the OS, avoid network storage for recordings **[V]**, put cameras on a separate network or VLAN with no internet access (Frigate's own example hardware has dual NICs for exactly this **[V]**), and prefer wired cameras **[V]**. Detection: use a modern detector (Intel iGPU via OpenVINO, Hailo, NVIDIA) rather than buying a Coral for a new build **[V]**; the Frigate docs list e.g. ~15 ms inference on an Intel N100 and note that device can run only one detector instance **[V]**. Retention versus backup: do not back up continuous footage off-site by default; export selected clips (Part G).

## 7. AI inference (optional)

| Topic | Guidance |
|-------|----------|
| CPU-only | Works for small quantised models; throughput is limited mostly by **memory bandwidth** **[K]**; expect a few tokens per second on 7B-class models on a typical mini PC **[E]** |
| GPU | The model must fit in VRAM; otherwise layers spill to system RAM and speed collapses **[K]** |
| Quantisation | Lower precision shrinks memory roughly proportionally: a 7B model at 4-bit is about 4-5 GB, 13B about 8-9 GB, 70B about 40 GB or more **[E]** |
| Context length | Longer context adds KV-cache memory on top of the model **[K]** |
| Disk | Models are 2-40+ GB each, SSD preferred **[E]** |
| Concurrency | Each simultaneous request multiplies memory and slows everyone **[K]** |
| External API vs local | Use an API for quality, occasional use, or large models; self-host for privacy, offline use, learning or constant light use. For a home server, local AI is an *experiment*, not infrastructure |

## 8. Game servers

CPU: many are bound by single-thread speed (clock and cache matter more than core count) **[K]**. RAM: a vanilla Minecraft Java server for a few players is typically a few GB; modded or large-world servers need much more **[E]**. Network: low per-player bandwidth (tens to low hundreds of kbit/s) but latency-sensitive and exposed to abuse **[E]**; CGNAT blocks inbound connections and Cloudflare Tunnel does not carry arbitrary game UDP (Part B section 8). Keep game servers in their own Docker network with CPU/RAM limits, no access to personal data, and whitelists. Details per game in Part E-N.

## 9. One machine or several?

| Separate | Benefit | Cost | Trigger |
|----------|---------|------|---------|
| Storage (NAS) | Independent data lifecycle, disk expansion | Another box to patch, network dependence | Disk count outgrows the chassis, or you want clean separation |
| Compute | Isolate heavy/untrusted (game, dev, AI) | Cost, power, networking | Sustained CPU above ~70%, or noise/heat/power issues |
| NVR | Isolation, 24/7 write wear away from personal data | Another disk and box | More than a few cameras |
| Backup target | Different failure domain, ransomware resistance | Cost | After Stage 2; best at a second location |
| DNS/monitoring watcher | Survives main-server outages | A cheap always-on device | As soon as the household depends on DNS |

## 10. Measuring (read-only commands)

`lscpu`, `free -h`, `lsblk -o NAME,SIZE,TYPE,ROTA,MODEL`, `df -h`, `uptime`, `docker stats --no-stream`, `iostat -x 5` (from the `sysstat` package), `sensors` (lm-sensors), `smartctl -a /dev/<disk>` (smartmontools). None of these changes system state. Baseline for a week before judging whether you need more hardware.

## 11. Refinement checklist (when you send your hardware details)

CPU model and generation (for iGPU and SSE/AVX support), RAM size/speed and free slots, disk models and whether HDDs are CMR/SMR, number of SATA/NVMe slots, NIC speed, case/cooling, power draw at idle (a plug-in meter), UPS, and noise tolerance. With those I will place each workload on a tier, mark which Stage 2-4 applications are realistic, and produce a measured budget.
