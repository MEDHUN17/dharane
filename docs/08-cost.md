# Part I - Cost model (INR)

Prepared **2026-10-09**. Prices come from web-search summaries of vendor and retailer pages, not from the vendors' own pages (those hosts were blocked in this session). **None is a confirmed price.** Rupee figures are conversions: the base price, the exchange rate and its date are shown so you can recompute. Taxes (GST), card foreign-exchange markups and shipping are **not** included.

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

### Hardware (one-time)

| Item | Price found | Source | Conf. |
|------|-------------|--------|-------|
| Intel N100 mini PC, DDR4, 16 GB + 256 GB | Rs 17,999 (N150: Rs 18,599); barebone Rs 14,399 / Rs 14,999 | Seller list on an enthusiast forum, **undated** | **C** |
| 4 TB NAS-class 3.5" HDD | About Rs 7,000-10,500 (IronWolf ~Rs 8,250; WD Red Plus ~Rs 9,000) | One retailer guide that contradicted itself | **C** |
| 2 TB portable USB drive | Rs 12,049-12,949 (June 2026 listings); another undated guide says about Rs 6,000-6,500 | Listing roundup | **C** |
| 4 TB portable USB drive | Rs 10,903 (sale, undated) to Rs 16,700-17,000 | Retailer pages, undated | **C** |
| 1 TB SATA SSD | About Rs 4,500-6,000 (2025 guide); one 2026 listing showed Rs 13,999 (conflict) | Mixed | **C** |
| 1 TB NVMe SSD | Rs 4,849 (sale, undated) to about Rs 10,000 (Gen 3-4) | Retailer pages, undated | **C** |
| UPS, APC Back-UPS 600 VA (router + mini PC) | About Rs 3,490-4,800 | Reseller pages and a July 2026 roundup | B |
| UPS, APC Back-UPS 1100 VA | About Rs 6,700-8,430 | Same | B |
| Raspberry Pi 5 4 GB | Sources range Rs 5,500 to Rs 12,000 | Retailer blogs | **N** (too inconsistent to use) |
| Managed or PoE switch, cameras, surveillance HDD, VPS, UPS replacement batteries | Not researched | - | **N**: tell me if you plan to buy and I will price them |

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
| Additional purchases | A backup disk (a 2 TB portable drive, Rs 12,049-12,949 **C**; or a 4 TB 3.5" drive Rs 7,000-10,500 **C**, which also needs a way to attach it: not priced) plus a 600 VA UPS (Rs 3,490-4,800). **About Rs 15,500-17,700 one-time** using the portable drive |
| Mandatory recurring | Electricity at 10-20 W: about Rs 350-1,730/yr depending on tariff. Off-site backup of up to ~0.5 TB: a rotated second drive (extra one-time cost, no subscription) or a Hetzner-style 1 TB box at about Rs 4,200-5,000/yr, or B2 0.5 TB at about Rs 4,000/yr. **About Rs 4,400-6,800/yr** with a paid off-site copy |
| Optional recurring | Domain about Rs 970-1,000/yr (only if you want HTTPS names) |

### Scenario B: Balanced recommended (Stages 1-3)

| Category | Cost |
|----------|------|
| Existing hardware assumed | Router, switch, phones, PCs |
| Additional purchases | N100-class mini PC with 16 GB + 256 GB (Rs 17,999-18,599 **C**) + two 4 TB drives, one data and one backup (Rs 14,000-21,000 **C**; attaching two disks to a mini PC may need enclosures: not priced) + a 1100 VA UPS (Rs 6,700-8,430). **About Rs 38,700-48,000**; add a 1 TB SSD (about Rs 4,800-10,000 **C**) if you want more fast storage: **about Rs 43,500-58,000** |
| Mandatory recurring | Electricity at about 30 W (mini PC plus two disks): about Rs 1,040-2,590/yr. Off-site backup: 1 TB on a flat-rate box about Rs 4,200-5,000/yr; 2 TB on B2 or Wasabi about Rs 16,000/yr. **About Rs 5,300-18,600/yr** depending on how much you must send off-site |
| Optional recurring | Domain Rs 970-1,000/yr; a hosted password manager if you do not self-host (not priced); heartbeat/push (free tiers, limits unverified) |
| Replacement reserve | Spinning drives last years, not decades; budget a drive replacement every ~5 years **[E]** (Rs 7,000-10,500 each **C**) and a UPS battery replacement every few years (not priced) |

### Scenario C: Expanded (Stages 4-6)

| Category | Cost |
|----------|------|
| Additional purchases | Higher-tier machine or a second box, a secondary DNS/monitor device (Raspberry Pi class: **not priced**), a managed/PoE switch (**not priced**), more drives |
| Mandatory recurring | Electricity at 60-100 W: about Rs 2,100-8,600/yr; off-site for ~5 TB: about Rs 40,000/yr on B2 or Wasabi, about Rs 86,000/yr on R2 (plus operations) |
| Optional recurring | VPS relay for game servers (**not priced**), additional storage-box tiers (**not priced**) |

### Additions

| Addition | One-time | Recurring |
|----------|----------|-----------|
| **CCTV / NVR** | Cameras, PoE switch, surveillance HDD, perhaps an accelerator: **not priced** | +15-25 W (about Rs 43-180/month across Rs 4-10 tariffs **[E]**); no off-site storage by default |
| **Game servers** | Possibly more RAM or a second machine: not priced | +10-40 W; a VPS relay or rented host if you do not use Tailscale: not priced |

## 4. Is self-hosting cheaper than subscriptions?

Not on storage cost alone. A shared Google One 2 TB plan is about **Rs 7,800/yr** (or iCloud+ 2 TB about **Rs 8,988/yr**) **[S]**. Scenario B costs about Rs 39-58k up front plus Rs 5-19k/yr, and you maintain it. Self-hosting becomes worthwhile for reasons other than price: more capacity than 2 TB, privacy and control, media streaming, ad blocking, learning, and not depending on a subscriber account. Decide on those grounds, not savings.

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
