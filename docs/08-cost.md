# Part I - Cost model (INR)

Prepared **2026-10-09**. Prices come from web-search summaries of vendor and retailer pages, not from the vendors' own pages (those hosts were blocked in this session). **None is a confirmed price.** A second pass on 2026-10-09 re-checked memory, SSDs, hard drives, mini PCs, enclosures and small items (rows marked **[S27]-[S35]**) and found that memory and storage cost far more in 2026 than earlier rows in this file assumed. Rupee figures are conversions: the base price, the exchange rate and its date are shown so you can recompute. Taxes (GST), card foreign-exchange markups and shipping are **not** included.

Exchange rates used (search-reported): **USD/INR 95.95** (2026-09-16), **EUR/INR 110.43** (2026-08-28). Both move; recompute with a live rate before paying.

Confidence: **A** several consistent sources; **B** one decent source; **C** conflicting, undated or retailer-blog only (use as a rough range); **N** not priced (not researched or sources unusable). Labels **[S]** (search summary) and **[E]** (estimate) as elsewhere.

## 1. Price book

### Recurring services

| Item | Base price | Source and date | INR (at rate above) | Conf. |
|------|-----------|------------------|---------------------|-------|
| Domain `.com` at Cloudflare Registrar | US$10.11/yr (another record: $10.46), at-cost renewals | PriceWorld record 2026-02-19 **[S]** | about Rs 970-1,004/yr | B |
| Domain `.in` | Cheapest first year US$1.99; cheapest renewal US$5.50; some registrars renew at US$17.99 | Domain-comparison site, mid-2026 **[S]** | Rs 190 first year; renewals Rs 530-1,720 | C |
| Backblaze B2 storage | US$6.95/TB/month; egress free up to 3x average stored; then US$0.01/GB | Guide confirmed with the vendor 2026-10-01 **[S]** | Rs 667/TB/month = **Rs 8,002/TB/yr** | B |
| Cloudflare R2 storage | US$0.015/GB-month (US$15/TB); free egress; Class A ops US$4.50 per million, Class B US$0.36 per million; free allowance disputed | Third-party pricing pages 2026 **[S]** | Rs 1,439/TB/month = **Rs 17,271/TB/yr** + operations | B |
| Wasabi | US$6.99/TB/month, 1 TB minimum; minimum-retention terms unclear (30 or 90 days) | Review pages 2026 **[S]** | Rs 671/TB/month = **Rs 8,048/yr** (1 TB min) | C |
| Hetzner Storage Box BX11 (1 TB) | EUR 3.20/month plus VAT where applicable | Reseller comparison 2026-02 **[S]** | Rs 353/month = **Rs 4,241/yr**; with 19% VAT about Rs 5,046/yr | B |
| Google One 2 TB (India) | Rs 650/month; family sharing up to five; annual saves about two months | July 2026 buyer's guide **[S]** | **Rs 7,800/yr** (about Rs 6,500 on annual billing) | B |
| iCloud+ 2 TB (India) | Rs 749/month incl. GST | July 2026 buyer's guide **[S]** | **Rs 8,988/yr** | B |
| Tailscale Personal | US$0 (reported up to 6 users, unlimited user devices since 2026-04-08; non-commercial) | Pricing-change trackers **[S]** | Rs 0 | B |
| Cloudflare Zero Trust (Access, Tunnel) | US$0 for up to 50 users; paid US$7/user/month | Third-party pages 2026 **[S]** | Rs 0 | B |
| Plex Pass | Lifetime US$749.99 since 2026-07-01; five-year US$249.99 | Press coverage **[S]** | Rs 71,962 lifetime (not recommended; Jellyfin is free) | B |
| Hosted heartbeat, push notifications | Free tiers typical | Not researched | N | N |
| Google One tiers (India) | Rs 59 (30 GB), Rs 130 (100 GB), Rs 210 (200 GB), Rs 650 (2 TB) per month | July 2026 buyer's guide **[S]** | 100 GB = **Rs 1,560/yr**; 200 GB = **Rs 2,520/yr** | B |
| playit.gg premium | US$3/month or US$30/year (free tier exists; limits disputed) | Reviews and guides 2026 **[S]** | Rs 288/month or Rs 2,879/yr | C |
| Minecraft hosting, India | Rs 150 per GB (4 GB = Rs 399/month, vendor claim); Hostinger Game Panel Rs 649/month renewing at Rs 999 | Vendor pages and a 2026-10-05 news article **[S]** | as listed | C |
| Aternos, Oracle Cloud Always Free | Free (Aternos ad-supported; Oracle reportedly cut to 2 OCPU/12 GB in 2026, with idle accounts reclaimable after 30 days) | Guides and trackers **[S19]**, Oracle's terms page **[V34]** | Rs 0 | C |
| Small VPS with a public IPv4 (a relay) | US$3.50-5 a month (Vultr US$3.50 **[C]**; DigitalOcean US$4, probably not offered in Bangalore, where US$6 is the cheapest; Akamai/Linode and Vultr 1 GB US$5); plus 18% GST | Aggregator sites, June-August 2026 **[S38]** | about Rs 336-576 a month before GST (Rs 480 for a 1 GB plan) | C |
| Paid static IPv4 from the internet provider | About Rs 100-350 a month plus 18% GST; BSNL Rs 1,800-3,000 a year by circle; Jio reportedly not sold to homes | Forum reports and circle tariff summaries, undated **[S36]** | Rs 118-413 a month with GST | C |

### Hardware (one-time)

| Item | Price found | Source | Conf. |
|------|-------------|--------|-------|
| Intel N100 mini PC, 16 GB + 512 GB (Amazon.in) | Rs 16,999-19,999 in tracker snapshots (newest Rs 18,999, 2026-07-25). The earlier "Rs 17,999 for 16 GB + 256 GB" is not confirmed by any dated source; barebone 4x2.5G LAN units Rs 15,499 (N100) / Rs 16,399 (N150); an imported-brand N150 16 GB/512 GB Rs 35,399 | Price-tracker snapshots December 2025 - July 2026 **[S30]** | **B** (Rs 17,000-19,000) |
| Refurbished office mini PC, Core i5 6th-8th gen, 8 GB + 256-512 GB SSD (HP EliteDesk Mini, Dell OptiPlex Micro, Lenovo ThinkCentre Tiny) | Rs 10,000-13,000 (newest HP EliteDesk 800 G4 Mini 8/256 Rs 12,799, 2026-09-14); dealers Rs 7,500-15,000; Flipkart listings Rs 16,700-19,990 (conflict); seller warranty about one month to one year | Amazon.in tracker snapshots June-September 2026, IndiaMART, OLX **[S29]** | **B** (Amazon.in range), **C** (others) |
| 4 TB NAS-class 3.5" HDD | **Rs 23,700-26,500** (Seagate IronWolf ST4000VN006 about Rs 24,750-25,500; WD Red Plus WD40EFPX about Rs 26,499). The earlier Rs 7,000-10,500 figures came from stale or out-of-stock pages | Amazon.in, Smartprix, PrimeABGB and MD Computers listings, September-October 2026 **[S32]** | **A** |
| 2 TB NAS-class 3.5" HDD | Rs 17,700-20,000 (WD Red Plus WD20EFPX about Rs 17,700; IronWolf ST2000VN003 Rs 19,999) | Amazon.in, Smartprix, September-October 2026 **[S32]** | **B** |
| 2 TB / 4 TB surveillance-rated 3.5" HDD | 2 TB Rs 13,000-16,000 (WD Purple, SkyHawk, Toshiba S300); 4 TB Rs 12,000-21,500 (very wide spread: WD Purple 4 TB Rs 11,999-13,499, SkyHawk Rs 12,799-21,499, S300 Rs 18,299) | Amazon.in, trackers, a July 2026 roundup **[S32]** | **C** |
| Desktop-class 3.5" HDD (Seagate BarraCuda) | 4 TB Rs 18,500-19,500; 2 TB Rs 14,799-15,999 | Retailer listings, undated, seen 2026-10-09 **[S32]** | **B** |
| 2 TB portable USB drive | Rs 12,049-12,949 (June 2026 listings); another undated guide says about Rs 6,000-6,500 | Listing roundup | **C** |
| 4 TB portable USB drive | Rs 10,903 (sale, undated) to Rs 16,700-17,000 | Retailer pages, undated | **C** |
| 1 TB SATA SSD | About Rs 4,500-6,000 (2025 guide); one 2026 listing showed Rs 13,999 (conflict) | Mixed | **C** |
| 1 TB NVMe SSD | Rs 4,849 (sale, undated) to about Rs 10,000 (Gen 3-4) | Retailer pages, undated | **C** |
| UPS, APC Back-UPS 600 VA (router + mini PC) | About Rs 3,490-4,800 | Reseller pages and a July 2026 roundup | B |
| UPS, APC Back-UPS 1100 VA | About Rs 6,700-8,430 | Same | B |
| Raspberry Pi 5 4 GB | Sources range Rs 5,500 to Rs 12,000 | Retailer blogs | **N** (too inconsistent to use) |
| 1 TB portable USB drive | Toshiba Canvio about Rs 3,599; WD Elements Rs 8,899-9,981; Seagate Expansion about Rs 9,799; older deal pages Rs 3,700-4,000 | June 2026 roundup and deal pages | **C** (large spread) |
| 256 GB 2.5" SATA SSD | Rs 2,200-3,800 mainstream brands (no-name Rs 1,250-1,750; premium Rs 5,100-7,700) | Amazon.in tracker points, June-October 2026 **[S33]** | **B** |
| 512 GB 2.5" SATA SSD | Rs 3,500-6,600 mainstream brands (cheapest Rs 2,600-3,500; name brands Rs 7,000 and up) | Amazon.in tracker points, June-October 2026 **[S33]** | **B** |
| Laptop memory, 8 GB DDR3L SO-DIMM (new) | Rs 600-2,000, typically Rs 1,000-1,600; 4 GB Rs 789-1,029; used 8 GB asked Rs 800-1,500 (OLX) | Trackers and listings, June-October 2026 **[S27]** | **A** (new), **C** (used) |
| Laptop memory, 8 GB DDR4 SO-DIMM (new) | Rs 5,200-7,600 (about 2-2.5x its 2025 price); 16 GB about Rs 13,500-14,000; used 8 GB asked Rs 2,000-4,500 | Listings, July-October 2026 **[S27][S28]** | **A** (8 GB new), **B** (16 GB), **C** (used) |
| USB-SATA enclosure or dock | 2.5" USB 3.0 enclosure Rs 260-470; 3.5" single-bay with a 12 V adapter Rs 800-1,200; 2-bay dock Rs 1,900-2,700 | Amazon.in and Flipkart listings, undated **[S31]** | **B** |
| USB 3.0 gigabit Ethernet adapter; Cat6 patch cable (1-2 m); USB flash drive | Adapter Rs 800-2,000 (TP-Link UE300 Rs 1,000-1,100); cable Rs 145-355; flash drive 16 GB Rs 400-600, 32 GB Rs 590-690 | Amazon.in and Flipkart listings, undated **[S34]** | **B** |
| 16-channel analog DVR | CP Plus Rs 5,700-6,800 (5 MP Rs 10,800); Hikvision Rs 9,500-14,500; full 16-camera kit with 4 TB disk Rs 30,000-45,000 | B2B listings and a price tracker, 2026 | **C** (hard disk not priced) |
| Managed or PoE switch, cameras, UPS replacement batteries | Not researched | - | **N**: tell me if you plan to buy and I will price them |

## 2. Electricity

```
kWh per month = watts x 24 x 30 / 1000
cost per month = kWh per month x tariff (Rs per kWh)
```

Measure real watts with a plug-in meter. As rough starting points **[E]**: Tier A 5-10 W, Tier B 10-20 W, plus about 5 W per spinning disk (3.6 kWh a month each), Tier C 30-60 W, Tier D 60-100+ W.

| Average load | kWh/month | at Rs 4 | at Rs 6 | at Rs 8 | at Rs 10 |
|--------------|-----------|---------|---------|---------|----------|
| 10 W | 7.2 | Rs 29/mo | Rs 43/mo | Rs 58/mo | Rs 72/mo |
| 20 W | 14.4 | Rs 58 | Rs 86 | Rs 115 | Rs 144 |
| 30 W | 21.6 | Rs 86 | Rs 130 | Rs 173 | Rs 216 |
| 40 W | 28.8 | Rs 115 | Rs 173 | Rs 230 | Rs 288 |
| 60 W | 43.2 | Rs 173 | Rs 259 | Rs 346 | Rs 432 |
| 100 W | 72.0 | Rs 288 | Rs 432 | Rs 576 | Rs 720 |

Tariffs differ by state, slab, fixed charges and surcharges. Search results disagree and are mostly blogs, so treat these as **indicative only [S]**: Delhi about Rs 3.00/unit for the first 200 units rising to about Rs 8.00 above 800; Maharashtra's MSEDCL listed from about Rs 5.56 (first 100 units) up to over Rs 12 for 101-300 units; Karnataka reported anywhere from about Rs 3.20 to Rs 7.45; Tamil Nadu about Rs 2.50-4.95 in lower slabs; Kerala about Rs 1.50-5.90. **Use your own DISCOM's current tariff order and your marginal slab** (the slab your extra consumption falls in), which is what matters when a server adds 10-40 kWh a month. Tell me your state and slab.

## 3. Scenarios

"Existing hardware" means you already own it and spend nothing. Recurring items are split into mandatory and optional.

### Scenario A: Minimal (reuse a spare PC or laptop; Stage 1)

| Category | Cost |
|----------|------|
| Existing hardware assumed | The machine itself: Rs 0 |
| Additional purchases | A backup disk (a 2 TB portable drive, Rs 12,049-12,949 **C**; or a 4 TB 3.5" NAS-class drive Rs 23,700-26,500 **A** plus an enclosure Rs 800-1,200 **B**) plus a 600 VA UPS (Rs 3,490-4,800). **About Rs 15,500-17,700 one-time** using the portable drive (portable prices were not re-checked in October 2026 and may be low), or **about Rs 28,000-32,500** with the 4 TB drive |
| Mandatory recurring | Electricity at 10-20 W: about Rs 350-1,730/yr depending on tariff. Off-site backup of up to ~0.5 TB: a rotated second drive (extra one-time cost, no subscription) or a Hetzner-style 1 TB box at about Rs 4,200-5,000/yr, or B2 0.5 TB at about Rs 4,000/yr. **About Rs 4,400-6,800/yr** with a paid off-site copy |
| Optional recurring | Domain about Rs 970-1,000/yr (only if you want HTTPS names) |

### Scenario B: Balanced recommended (Stages 1-3)

| Category | Cost |
|----------|------|
| Existing hardware assumed | Router, switch, phones, PCs |
| Additional purchases | N100-class mini PC with 16 GB + 512 GB (Rs 17,000-19,000 **B**) + two 4 TB NAS-class drives, one data and one backup (Rs 47,400-53,000 **A**) + two single-bay enclosures (Rs 1,600-2,400 **B**) + a 1100 VA UPS (Rs 6,700-8,430). **About Rs 72,700-82,800**; with two 2 TB surveillance-rated drives instead (Rs 26,000-32,000 **C**) it is **about Rs 51,300-61,800**. A 1 TB SSD for more fast storage is not re-priced here: the earlier Rs 4,800-10,000 figure is likely stale |
| Mandatory recurring | Electricity at about 30 W (mini PC plus two disks): about Rs 1,040-2,590/yr. Off-site backup: 1 TB on a flat-rate box about Rs 4,200-5,000/yr; 2 TB on B2 or Wasabi about Rs 16,000/yr. **About Rs 5,300-18,600/yr** depending on how much you must send off-site |
| Optional recurring | Domain Rs 970-1,000/yr; a hosted password manager if you do not self-host (not priced); heartbeat/push (free tiers, limits unverified) |
| Replacement reserve | Spinning drives last years, not decades; budget a drive replacement every ~5 years **[E]** (Rs 13,000-26,500 each depending on size and class, **A**-**C**) and a UPS battery replacement every few years (not priced) |

### Scenario C: Expanded (Stages 4-6)

| Category | Cost |
|----------|------|
| Additional purchases | Higher-tier machine or a second box, a secondary DNS/monitor device (Raspberry Pi class: **not priced**), a managed/PoE switch (**not priced**), more drives |
| Mandatory recurring | Electricity at 60-100 W: about Rs 2,100-8,600/yr; off-site for ~5 TB: about Rs 40,000/yr on B2 or Wasabi, about Rs 86,000/yr on R2 (plus operations) |
| Optional recurring | VPS relay for game servers (**not priced**), additional storage-box tiers (**not priced**) |

### Scenario D: Constrained single laptop (about Rs 12,000-15,000 once and about Rs 200/month)

| Category | Cost |
|----------|------|
| Existing hardware assumed | The laptop(s), a UPS, the router, the phones |
| Additional purchases (choose by what you own) | **If the laptop has a hard drive:** a 256 GB SATA SSD, Rs 2,200-3,800 **B**. **If it has 4 GB of memory:** 8 GB of laptop memory, Rs 600-2,000 if the laptop uses DDR3/DDR3L **A**, Rs 5,200-7,600 if it uses DDR4 **A**. **Data storage, one of:** a 512 GB SATA SSD in a 2.5" enclosure, Rs 3,500-6,600 + Rs 260-470 **B**; a portable hard drive (1 TB Rs 3,600-10,000 **C**, 2 TB Rs 12,049-12,949 **C**; **not re-checked in October 2026 and possibly low**); a 3.5" drive, which now costs far more (2 TB surveillance-rated Rs 13,000-16,000 **C**, 4 TB NAS-class Rs 23,700-26,500 **A**) plus an enclosure Rs 800-1,200 **B**. **Small items:** an Ethernet cable and a USB installer stick, about Rs 550-950 **B**. Examples: SSD + 8 GB DDR3L memory + a 512 GB SSD in an enclosure, about **Rs 6,600-12,900**; the same with DDR4 memory, about **Rs 11,200-18,500**; a 2 TB portable alone, about **Rs 12,000-12,900** (portable prices unverified) |
| Mandatory recurring | Off-site copy: Backblaze B2 at about Rs 667/TB/month gives roughly **300 GB for Rs 200** (150 GB for Rs 100); or Google One 100 GB Rs 130 or 200 GB Rs 210. Domain renewal about Rs 970-1,000/yr, roughly Rs 80/month. Electricity for a laptop plus drive (about 25-35 W): about 18-25 kWh/month, **Rs 72-250/month** across Rs 4-10 tariffs. *Whether the Rs 200 includes electricity decides which of these fit* |
| Optional | A second local drive (another Rs 3,800-7,100 for a 512 GB SSD in an enclosure, more for a hard drive) to reach three copies; a recorder for cameras (separate budget); a paid game host (Rs 400+/month) |
| What money at this scale cannot fix | Public hosting of media or games from a home line with no inbound ports; 16-camera AI recording on an old laptop; a new 4 TB NAS-class drive (Rs 23,700-26,500) |

Seeding time for the off-site copy depends on the measured upload speed (section 5 of [`13-low-end-profile.md`](13-low-end-profile.md)).

### Additions

| Addition | One-time | Recurring |
|----------|----------|-----------|
| **CCTV / NVR** | Cameras, PoE switch, perhaps an accelerator: **not priced**. A surveillance-rated disk: 2 TB Rs 13,000-16,000, 4 TB Rs 12,000-21,500 **C** | +15-25 W (about Rs 43-180/month across Rs 4-10 tariffs **[E]**); no off-site storage by default |
| **Game servers** | Possibly more RAM or a second machine: not priced | +10-40 W; a VPS relay about Rs 336-576 a month before GST **C**, or a rented host from about Rs 400 a month, if you do not use Tailscale |

## 4. Is self-hosting cheaper than subscriptions?

Not on storage cost alone. A shared Google One 2 TB plan is about **Rs 7,800/yr** (or iCloud+ 2 TB about **Rs 8,988/yr**) **[S]**. Scenario B costs about Rs 73-83k up front (Rs 51-62k with two 2 TB drives) plus Rs 5-19k/yr, and you maintain it. Self-hosting becomes worthwhile for reasons other than price: more capacity than 2 TB, privacy and control, media streaming, ad blocking, learning, and not depending on a subscriber account. Decide on those grounds, not savings.

## 5. Which paid services are worth it

| Item | Verdict |
|------|---------|
| Off-site backup | **Worth it.** Without it you do not have a backup of your house. Pick the cheapest option that fits your data: a flat-rate box for ≤1 TB, per-TB object storage for more, a rotated drive for the most privacy |
| Domain | Worth it from Stage 2 for HTTPS names; about the price of one meal a year |
| UPS | Worth it: it protects the disks and gives a graceful shutdown |
| Tailscale paid tiers | Not needed for a household on the free plan, subject to its personal/non-commercial terms |
| Cloudflare paid tiers | Not needed |
| Plex Pass | Not worth it; Jellyfin includes hardware transcoding free |
| Hosted password manager | Worth considering instead of self-hosting if you cannot commit to the recovery plan |

## 6. Free-tier limits and avoiding surprise charges

| Service | Watch for |
|---------|-----------|
| Off-site repo growth | With `OFFSITE_PRUNE_ENABLED=0` and no prune run from a trusted machine, the off-site repository only ever grows, and so does a per-TB bill. Schedule a periodic prune elsewhere (use `forget --keep-within` for append-only repositories) before relying on it |
| Backblaze B2 | Free egress only up to about 3x your stored volume per month; beyond that US$0.01/GB; a full `restic check --read-data` or a mass restore counts as egress **[S]** |
| Cloudflare R2 | Per-operation charges and a free allowance whose existence sources dispute; chatty backups make many operations **[S]**; verify on the pricing page |
| Wasabi | 1 TB minimum billing; minimum retention for deleted objects, whose length sources disagree on **[U]** |
| Flat-rate storage boxes | VAT; EU-based billing in euros, so card markups; no native immutability unless offered |
| Domains | `.in` renewals can be several times the first-year price **[S]**; set auto-renew and calendar the date |
| Tailscale | Free plan is for personal, non-commercial use; limits changed in April 2026 **[S]** |
| Cloudflare Zero Trust | Free for up to 50 users; Access users beyond that are paid **[S]** |
| Any foreign-currency service | Card forex markup and GST treatment vary; confirm with your bank; use a card with a spending limit |

Habits: set budget alerts where offered; test restores on small slices; record every subscription in the inventory (Part K) with the renewal date and payment method; review all recurring costs each year.

## 7. What I still need to finish this part

Your state/DISCOM and tariff slab; whether you already own a server, disks and a UPS; how much data must be backed up off-site; whether you plan cameras or game servers (then I will price those items properly).

## 8. Source links

Rows in the price book come from these pages; open them to confirm before buying. The same links, by ID, are in [`12-verification-log.md`](12-verification-log.md).

- Exchange rates: https://dollarrupee.in/ , https://30rates.com/eur-to-inr
- Backblaze B2: https://egresscost.com/backblaze-b2 ; Cloudflare R2: https://filebase.com/blog/cloudflare-r2-pricing-costs-savings-and-alternatives-in-2026/ ; Wasabi: https://toolradar.com/tools/wasabi/pricing ; Hetzner BX11: https://www.hetzner.com/de/storage/storage-box/bx11/
- Google One and iCloud+ (India): https://www.itforsme.in/best/cloud-storage-personal-use-india
- Domains: https://priceworld.com/domains/cloudflare/ , https://domainoffer.net/tld/in
- Tailscale plan change: https://tailscale.com/blog/pricing-v4 ; Cloudflare Zero Trust: https://zerotrustcost.com/cloudflare-zero-trust-pricing ; Plex: https://9to5mac.com/2026/05/19/plex-increasing-lifetime-plex-pass-cost-to-whopping-750/
- India hardware: https://techenclave.com/t/intel-n100-n150-mini-pcs-itx-motherboards-for-nas-home-servers-firewalls-opnsense-pfsense/397179 , https://getpc.co.in/parts/storage/seagate-ironwolf-4tb , https://magicdrop.in/drops/2tb-hard-disk , https://magicdrop.in/drops/1tb-ssd , https://magicdrop.in/drops/best-ups-for-home , https://estorewale.com/product/apc-back-ups-1100va-bx1100c-in
- Electricity tariffs (indicative): https://www.voltflow.net/blog/electricity-rates-india-by-state-2026 , https://desiutility.com/electricity/tariffs , https://www.mymotor.in/blog/ev-charging-cost-india-state-wise-tariff
- Added for the constrained scenario: https://magicdrop.in/drops/1tb-external-hard-drive , https://magicdrop.in/drops/256gb-ssd , https://www.aajjo.com/product/cp-plus-16-ch-dvr-in-ghaziabad-ms-sv-india-infotech-solutions , https://price-history.in/product/cp-plus-16-channel-dvr-2-ea7eWzIm , https://gbnodes.host/blogs/cheap-minecraft-server-hosting-india-2026/ , https://zoutons.com/news/hostinger-minecraft-server-hosting-price-india-2026 , https://terminalbytes.com/oracle-cloud-free-tier-changes-2026 , https://www.teklynk.dev/blog/how-to-host-a-game-server-from-your-home-using-playItgg
- Added in the October 2026 pass (memory, SSDs, hard drives, mini PCs, enclosures, small items, relay servers, static IPs): see S27-S39 and their links in [`12-verification-log.md`](12-verification-log.md).
