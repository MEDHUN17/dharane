# Power, hardware reliability and physical setup

Labels: **[K]** stable knowledge, **[E]** estimate to measure, **[S]** search-reported, **[V]** verified in docs. Prices and the electricity-cost method are in [`08-cost.md`](08-cost.md); monitoring of power events in [`07-automation-monitoring.md`](07-automation-monitoring.md) section 7.

## 1. UPS or just "restart after power returns"?

Setting the firmware to power on automatically after an outage gets the server back up; it does **not** prevent an interrupted write from corrupting a filesystem or a database. A UPS gives time to shut down cleanly. For a server with data you care about, the UPS is the single most valuable reliability purchase. **[K]**

| | Auto-restart only | UPS with graceful shutdown |
|---|-------------------|-----------------------------|
| Server returns after an outage | Yes | Yes |
| Protects against mid-write corruption | **No** | Yes, if the shutdown completes |
| Covers brief dips and surges | No | Yes (line-interactive models) |
| Cost | none | see Part I |

## 2. UPS sizing

1. **List the loads** on the UPS: server, router, ONT/modem, switch (and a PoE switch plus cameras if you run an NVR). Measure watts with a plug-in meter rather than trusting nameplates.
2. **VA is not watts.** Real power capacity is `watts = VA x power factor`; small consumer units often have a power factor around 0.6, so a nominal 600 VA unit may be rated for about 360 W (a retailer page for one model lists 360 W **[S]**). Size on **watts**.
3. Keep the connected load to about **60-70% of the watt rating** for headroom **[E]**.
4. **Runtime estimate:** `minutes = battery_Wh x inverter_efficiency x derating / load_W x 60`. Typical derating for ageing batteries and the discharge curve is 0.5-0.7 **[E]**. Worked example: an 84 Wh battery, efficiency 0.8, derating 0.6, load 40 W gives about 60 minutes. Verify by timing a real test.
5. The goal of the battery is **graceful shutdown plus bridging short outages**, not hours of runtime. Runtime beyond that is the job of a home inverter (below).
6. Batteries age: plan replacement every few years **[K]** and record the date in the inventory.

## 3. Put the network on the UPS too

If only the server is protected, it can outlive the router and ONT, and then you cannot reach it, and Tailscale and your alerts cannot leave the house. Power the **ONT/modem, router and the switch** from the same protected circuit. A server that shuts down gracefully when the *UPS* reaches low battery is better than one that keeps running with no network.

## 4. Home inverters (common in India) **[K]**

Many homes have an inverter and battery bank. Things to know:

- **Changeover time.** The switch from mains to inverter takes a moment; some modes are slower than others. A server on that circuit can reboot during the changeover. Check the specification.
- **Waveform.** Inexpensive inverters may output a square or modified sine wave. Switch-mode PC power supplies often tolerate it poorly (heat, noise, early failure). A pure-sine-wave inverter is the safer choice.
- **No signalling.** Most home inverters cannot tell a server that power is failing, so there is no graceful shutdown; the server simply loses power when the inverter battery is exhausted.
- **Usual answer:** keep a small **UPS that the server can monitor** between the inverter-backed circuit and the server/network gear. The UPS bridges the changeover, signals the server to shut down cleanly before the *inverter's* battery dies, and filters the supply.
- Do not daisy-chain surge strips or cheap extension boards on the inverter circuit.

## 5. Power-on behaviour and flicker

- Set the firmware option to restore power after AC loss so the server comes back when you are away.
- **Repeated brownouts or flicker can cause boot loops** and stress the disks. A UPS prevents this; without one, consider whether you want automatic restart after a long outage during unstable supply **[K]**.
- After an unclean shutdown, check logs and monitoring before assuming everything is fine; let filesystems recover, then run a backup and a restore check.
- Staggered spin-up on multi-disk systems reduces the start-up current spike on the power supply **[K]**.

## 6. Disk behaviour

- **Spin-down** saves a few watts per disk but every start/stop cycle adds wear, and spin-up delays can time out applications. For a server accessed daily, leaving disks spinning is simpler **[K]**.
- Use drives rated for the duty: NAS-class (CMR) for the data and backup disks, surveillance-rated for recording **[V for Frigate's guidance]**; avoid SMR for write-heavy or rebuild-heavy use **[K]**.
- Disk power: roughly 5 W per spinning disk idle **[E]**, which feeds the electricity estimate in Part I.
- Monitor health with SMART (Part H) and replace on warnings, not after failure.

## 7. Heat, dust and airflow

- Indian summer rooms can reach 35-45 C. Keep drives below the sustained temperatures their datasheets recommend (commonly well under 50 C) and alert on sensor temperature (80/90 C thresholds in the example script).
- Do not put the server in a closed cupboard without ventilation; give mini PCs free space around vents.
- **Dust:** fit a filter where intake is exposed; clean quarterly with compressed air; schedule it with the maintenance log.
- Keep it **off the floor** (dust, damp, monsoon flooding) on a stable shelf.

## 8. Placement and physical security

- **Vibration:** several drives in a shared chassis transmit vibration; use rubber mounts and avoid placing the server on a surface shared with a washing machine or speakers.
- **Water and pests:** away from kitchens, bathrooms, window sills and leaks; sealed-but-ventilated enclosures help keep insects out **[K]**.
- **Theft:** out of sight from the door; do not label it; encrypted backup drives; understand that full-disk encryption on internal disks has availability trade-offs (see `02a-storage-layout.md` section 7).
- **Access:** reachable for service, with cables labelled and a spare cable and router on hand.

## 9. Surge protection and earthing

- Use a UPS or surge protector with surge suppression; unplug equipment from the mains and the network cable during severe thunderstorms if you can **[K]**.
- **Earthing:** many homes have poor or missing earth. Test sockets with a simple socket tester before installing a UPS or a server; a bad earth makes shocks and equipment damage more likely **[K]**. Have an electrician fix it.
- Lightning can enter through the ONT/fibre equipment and Ethernet runs; keep network gear on the same protected supply.

## 10. Network reliability

- Wired Ethernet for the server; Wi-Fi servers are unreliable **[K]**. Jellyfin's docs also recommend Gigabit Ethernet and say Wi-Fi/Powerline are not recommended **[V]**.
- Router and switch wall adapters draw only a few watts each but need protected power; a PoE switch for cameras may add tens of watts **[E]**.
- Keep a saved router configuration export and a spare cable.

## 11. Reliability checklist, ranked by practical benefit

| Rank | Upgrade or practice | Why |
|------|---------------------|-----|
| 1 | UPS with graceful shutdown, also covering router/ONT/switch | Prevents corruption and keeps the network up for alerts |
| 2 | Tested backups with an off-site copy | Covers everything else |
| 3 | SSD for the OS, databases and application state | Faster, fewer failures than a spinning boot disk |
| 4 | Wired Ethernet | Removes the flakiest link |
| 5 | NAS-class (CMR) data disks plus SMART monitoring | Early warning and suitable duty cycle |
| 6 | A separate backup disk | Different failure domain |
| 7 | Good power supply, surge protection and verified earthing | Hardware survival |
| 8 | Cooling, dust control and sensible placement | Longevity |
| 9 | Spare cables, a spare router/AP, a saved router config | Fast recovery |
| 10 | Up-to-date inventory and recovery kit | Makes everything above recoverable by someone else |
