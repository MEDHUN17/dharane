# M. Optional CCTV and NVR

**Advanced / Stage 4**, only with measured headroom and a dedicated disk. Labels as in the [README](README.md): **[V]** verified in Frigate's docs (V6, V13), **[S]**, **[K]**, **[E]**, **[U]**. For legal and privacy rules about recording people (family, guests, neighbours, staff), check the rules that apply where you live; this document gives no legal advice.

**Which path applies** (existing recorder, analog DVR, IP NVR, software NVR): see the camera path in the [decision guide](../14-decision-guide.md#54-cameras-which-path).

## Frigate (profile)

| | |
|---|---|
| **Problem it solves** | Records IP-camera streams and runs local object detection (person, car, animal) to make events searchable and cut false alarms |
| **Class / when** | **Advanced / optional** / Stage 4 |
| **Why this, not simpler** | A camera's own app or SD card is cloud-tied and weak. A generic recorder stores video but does not detect objects |
| **Hardware / storage** | RAM: 4 GB basic minimum with a detector, 8 GB with enrichments (face/plate recognition), 16 GB recommended for 8+ cameras. **CPU must support AVX and AVX2**; this excludes many older or budget Celeron/Pentium/Atom parts **[V]**. Video decoding should be offloaded to an Intel/AMD iGPU or GPU **[V]** |
| **Object detection** | Use an accelerator: Intel iGPU/Arc/NPU via OpenVINO, Hailo, NVIDIA (TensorRT/ONNX), AMD ROCm, and others. **The Google Coral is no longer recommended for new installs [V].** Example: Intel N100 about 15 ms per inference with OpenVINO, and that device can run only one detector instance **[V]** |
| **Storage** | See the sizing formula in Part D section 6. SSDs are fine for recording (modern endurance is not a concern, per Frigate); HDDs are the cost-effective choice for long retention, and surveillance-rated drives (for example WD Purple, Seagate SkyHawk) are designed for 24/7 writes **[V]**. Network storage is possible but local storage is recommended **[V]**. Keep recordings on their own disk so a full recording disk can never fill the OS disk |
| **Cameras** | Wired, ideally PoE. Wi-Fi cameras are not recommended because of lost streams **[V]**. Use cameras that expose standard **RTSP** streams (many also support **ONVIF** for discovery and PTZ control); avoid models that only work through a vendor cloud. Configure **H.264** with AAC audio for best compatibility, a main stream for recording and a low-resolution sub-stream for detection **[V]** |
| **Recording policy** | *Continuous* uses the most space but never misses pre-event footage. *Motion/event-based* saves space but can miss the lead-up. A common balance: a few days of continuous, weeks of event clips **[K]**. Decide retention per camera (a door camera matters more than a backyard one) |
| **Dependencies** | A detector device or iGPU; the camera network; SQLite database for events on SSD **[K]** |
| **Install / Compose** | Official image per the current docs at Phase 13; needs device passthrough for the detector/GPU and a shared-memory size appropriate to the camera count (the docs give the numbers) **[K]** |
| **Exposure / access** | Authenticated UI/API on **port 8971** (use this one behind a reverse proxy); **port 5000 is internal and unauthenticated, so keep it on the Docker-internal network only [V]**. Class 2 over Tailscale; never publish. Camera interfaces, RTSP and ONVIF: class 1 |
| **Authentication / security** | On first start an admin user and password are generated and printed in the logs: change it immediately; minimum password length 12; JWT secret must be kept private; failed-login rate limiting exists and needs `trusted_proxies` set when behind a proxy, or limits apply to the proxy's address **[V]**. Frigate does not implement OIDC/SAML/LDAP; it can trust an upstream authentication proxy instead **[V]**. No native MFA is described **[U]**: Tailscale identity MFA is the compensating control |
| **Camera networking** | Put cameras on their own network (VLAN, or a dedicated NIC and switch) with **no internet access**; allow only the NVR to reach them on the stream ports. Frigate's own example hardware uses dual NICs for exactly this **[V]**. Disable P2P/UPnP/cloud features on the cameras and change default passwords; update firmware |
| **Remote viewing** | Over Tailscale only (web UI or an app/integration that supports it). Never port-forward RTSP |
| **Power-loss recovery and continuity** | UPS for the NVR, the PoE switch and the router; a missed hour of recording during a power failure is a fact of life. Journaling filesystems recover, but expect the last minutes of a file to be lost. Alert on "recordings stopped" (a stale newest recording is a better signal than a green container) |
| **Exporting important footage** | Export clips you care about (an incident, a delivery dispute) to `documents/` so they survive retention rollover, and back those up like documents |
| **Backup vs retention** | Recording retention is *not* a backup. Do not back up continuous footage off-site by default: it is large, costly and privacy-sensitive. Back up configuration (`/srv/appdata/frigate`) and exported clips |
| **Maintenance / cost** | Updates monthly after release notes (configuration formats change between versions); free software, hardware cost for cameras, disk, accelerator |
| **Limits** | Detection quality depends on camera placement and resolution; false positives need tuning |
| **Continuous?** | Yes (stopping means gaps) |
| **Avoid when** | You have one or two cameras and no spare headroom (use the camera's local recording), or no way to isolate the camera network |

## Alternatives (short)

| Option | Notes **[K]** (verify licence, price and maintenance before adopting) |
|--------|--------------------------------------------------------------------|
| Agent DVR | Closed-source freeware with paid tiers for some remote features; wide camera support; Windows-first heritage |
| Shinobi, ZoneMinder | Older open-source NVRs; heavier to administer; check current maintenance |
| Moonfire NVR | Lightweight recorder focused on efficient storage; no object detection |
| Scrypted, Viseron | Camera aggregation and detection projects; check integrations |
| Blue Iris | Windows-based commercial NVR |

## Why NVR storage needs its own policy

It is continuous, write-heavy, high-volume and expendable. Documents and photos are small, precious, and kept for years. Different disks, different retention (days to weeks, not years), different backup rules (export selectively), different privacy handling (who may view, how long it is kept).

## Many cameras, an old laptop, or an existing DVR/NVR

- **Do the numbers first:** at 1 Mbps per camera, 16 cameras write about 173 GB per day (about 346 GB at 2 Mbps); a 256 GB disk holds under two days and a 4 TB disk roughly 12-23 days **[E]**. AI detection additionally needs video decoding, a capable CPU or accelerator, AVX2 and 4-16 GB of RAM **[V]**. An old dual-core laptop is not an NVR for that many cameras.
- **If you already own a recorder (analog DVR or IP NVR):** keep it. Change its passwords, disable vendor cloud/P2P features, update its firmware, and leave it unreachable from the internet. Reach it remotely through a Tailscale **subnet router** on the LAN (Docker's default forward-drop policy must be allowed for that to work **[V]**), and view one sub-stream at a time over a slow uplink.
- **Analog cameras with no recorder:** a 16-channel analog DVR was listed at roughly Rs 5,700-14,500 before the hard disk, and a full 16-camera kit with disk at Rs 30,000-45,000 **[S][C]**. Budget it separately and defer it; check that a model supports analog inputs rather than being an IP-only NVR.
