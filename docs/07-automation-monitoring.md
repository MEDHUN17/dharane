# Part H - Automation and monitoring

Labels: **[V]** verified in docs, **[K]** stable knowledge (re-check at the phase that uses it), **[E]** estimate. Working, tested reference scripts are in [`../examples/`](../examples/README.md).

Principles: prefer the simplest mechanism that works; alert only on things a human can act on; watch from outside the box as well as inside it; **a green dashboard is not proof that data is intact or restorable**.

## 1. Monitoring tools: what each measures and what it cannot tell you

| Tool | Measures | Cannot tell you | Cost | Verdict |
|------|----------|-----------------|------|---------|
| `smartd` / smartmontools **[K]** | Disk SMART health, scheduled self-tests, early warning (reallocated/pending sectors, CRC errors) | A disk can pass SMART and still fail soon; says nothing about data corruption | RAM ~nil | **Essential** |
| Shell checks (`examples/scripts/check-health.sh`) | Disk %, mounts and sentinels, backup age, memory, load, temperature, failed units, restarting containers, cert expiry | Anything your checks do not look at; trends | nil | **Essential** (tested example) |
| Uptime Kuma **[K]** | Is each service reachable (HTTP/TCP/ping/DNS, keyword), certificate expiry, status pages, many notification channels | Whether the data behind a reachable page is correct or restorable; cannot report its own host dying | ~100-250 MB **[E]** | **Recommended** (Stage 2) |
| External heartbeat / dead-man's-switch (hosted, e.g. healthchecks.io-style) **[K]** | "Did the expected ping arrive on schedule?", independent of your server | Why it stopped | free tier typical (verify) | **Essential**: the only way to hear about total failure |
| Push channel (ntfy-style, Telegram, e-mail) **[K]** | Delivers the alert to your phone | n/a | self-host or hosted | **Essential** |
| `node_exporter` **[K]** | Host CPU, RAM, disk, network counters for Prometheus | Anything about application correctness | tens of MB | Advanced stack |
| cAdvisor **[K]** | Per-container CPU/RAM/network | App-level health | ~100+ MB; wants broad host access | Advanced stack; weigh the access it needs |
| Prometheus + Alertmanager **[K]** | Time series, rules, trends, capacity planning | Black-box reachability unless you add a prober | 0.5-1.5 GB total with Grafana **[E]** | Advanced stack; only with a reason |
| Grafana **[K]** | Dashboards over Prometheus | Raw data quality | ~100-300 MB **[E]** | Advanced stack |
| `vnstat` or router counters **[K]** | Network volume per interface/day | Which application used it | tiny | Optional (answers "excessive network usage") |
| UPS monitoring (NUT) **[K]** | Mains/battery state, runtime, graceful shutdown trigger | Whether the load is healthy | tiny | Essential once a UPS exists (Part J phase 2) |
| Log aggregation (Loki etc.) **[K]** | Searchable logs across containers | n/a | heavy | Skip for a home server |

**Minimal stack (Stage 1-2):** smartd, `check-health.sh` on a 15-minute timer, a push channel, one external heartbeat, and Uptime Kuma once there are services to probe.
**Optional advanced stack (Stage 3+, only with a stated need):** Prometheus, node_exporter, cAdvisor, Grafana, Alertmanager, a blackbox prober, vnstat.

### Local vs external checks

A server cannot reliably report its own complete failure. So:

| Must run **outside** the server | May run on the server |
|---------------------------------|-----------------------|
| Heartbeat from the backup job and from the health timer (the *absence* of a ping is the alert) | smartd, disk/mount/sentinel checks |
| Reachability of public hostnames and of the tailnet address (from a cheap second device or a hosted prober) | Container health, restart loops |
| Power/internet loss visibility (a second device on mains, or the hosted heartbeat going silent) | Memory/CPU/temperature, cert expiry (also check externally) |

## 2. Alert matrix

Thresholds are starting points; tune after a month of real data. "Where" says whether the check can run on the box or must be external.

| Condition | Signal / tool | Where | Warning | Critical | Action | How to test |
|-----------|---------------|-------|---------|----------|--------|-------------|
| Host unreachable | External heartbeat from `check-health.sh`; external ping/TCP probe | **External** | 1 missed beat | 3 missed beats (45 min) | Check power, router, then console | Stop the timer for 50 min once |
| Application unavailable | Uptime Kuma HTTP/keyword checks (via tailnet or LAN) | External-ish (run on a *different* device if possible) | 2 failed checks | 5 min down | Check container logs/health | Stop the container once |
| Container restarting repeatedly | `docker ps --filter status=restarting` in `check-health.sh` | Local | n/a | any restarting | `docker compose logs`; roll back last change | Start a container with a bad command |
| Disk failure indicators | smartd + `smartctl -H` | Local | reallocated/pending sectors > 0 | SMART FAILING status | Replace disk after verifying backup | `smartctl` self-test log; smartd test mail option |
| Low storage | `df` per mount | Local | 80% | 90% | Free or add capacity; check growth | Fill a small test mount |
| Excessive temperature | `/sys/class/thermal` | Local | 80 C | 90 C | Clean/cooling; check fan | Lower threshold temporarily |
| Backup failure | restic exit codes (0 / 3 / other), backup stamps | Local + **external** heartbeat | exit 3 (partial) or stamp > 26 h | failure or stamp > 30 h | Read journal for the unit | Break credentials once |
| Certificate expiration | Uptime Kuma + `check-health.sh` TLS probe | Both | 14 days | 5 days | Check ACME/DNS token, Caddy logs | Point the probe at a short-lived test cert |
| Memory pressure | MemAvailable % | Local | < 10% available | OOM kill seen in journal | Find the hungry container; add limits | Run a memory stress test in a scratch container |
| Unexpected CPU usage | 15-min load per core | Local | > 2 per core | sustained > 4 per core | Identify with `docker stats`/`top` | Run a CPU burner briefly |
| Excessive network usage | `vnstat`/router counters | Local/router | > 2x your normal daily volume | > 5x | Identify talker | Move a large file |
| Power interruption | NUT `ups.status` OB (on battery); unclean-shutdown log | Local + external heartbeat gap | on battery | battery low (shutdown starts) | Check mains; confirm graceful shutdown | Pull the UPS input once, with a verified backup, in a quiet hour |

### Severity, escalation, and avoiding alert fatigue

| Level | Meaning | Delivery | Repeats |
|-------|---------|----------|---------|
| Critical | Act today (data at risk or service down) | Push, high priority | Daily until resolved |
| Warning | Act this week | Push, default priority | Daily at most |
| Info | Good to know | Weekly digest only | n/a |

Escalation: if a critical alert is unacknowledged for 24 hours, use a second channel (e-mail or a message to a trusted person with the runbook). De-duplicate (the example sends once on change, repeats only every `REMIND_HOURS`, and sends "resolved"). **Test the channel monthly** with a deliberate test message; a silent channel looks identical to a healthy system.

## 3. Maintenance schedule

| Cadence | Tasks |
|---------|-------|
| **Daily** (30 seconds) | Glance at the push digest/Uptime Kuma; no news is good news only if the heartbeat is alive |
| **Weekly** | Read warnings; confirm last backup stamps; look at free space trend; `docker compose ps` across stacks; review pending updates list (notify-only) |
| **Monthly** | Patch window: OS packages, review app release notes and update one stack at a time (section 6); notification test; rotate/check log sizes; restore one file from backup; check SMART summary |
| **Quarterly** | Full restore rehearsal for one app; review Tailscale devices/users and Cloudflare Access users; review firewall/exposure inventory with an external scan; test UPS runtime/shutdown; review DNS records |
| **Annually** | Disaster-recovery drill from the recovery kit; credential rotation; domain/registrar renewals and 2FA review; hardware health review (fans, dust, battery date); revisit capacity plan and costs |

## 4. Automation catalogue

Scale: Benefit/Risk **H**igh, **M**edium, **L**ow. "Needs approval" = a human must approve before it changes anything.

### Routine

| Automation | Benefit | Complexity | Risk | Tools | Setup | Frequency | Failure handling |
|------------|---------|-----------|------|-------|-------|-----------|------------------|
| Start services after boot | H | L | L | Compose `restart: unless-stopped`; `RequiresMountsFor=` ordering | 30 min | on boot | Health alert if a stack is down |
| Scheduled local + off-site backups | H | M | M (prune is destructive; opt-in) | `backup.sh` + systemd timer | 1-2 h (+ restore test) | nightly | Exit codes 3/other -> OnFailure alert + heartbeat |
| Photo/video upload from phones | H | L | L | Immich mobile app (background limits on iOS) **[V]** | 15 min per phone | continuous | Check "last backup" in the app monthly |
| Disk space monitor | H | L | L | `check-health.sh` | 15 min | 15 min | Deduped alert |
| Disk health monitor | H | L | L | smartd + monthly `smartctl -H` | 30 min | continuous | Alert, plan replacement |
| Notify on service failure | H | L | L | Uptime Kuma + push | 30 min | 1 min | Second channel |
| Notify on backup failure | H | L | L | `OnFailure=` + heartbeat | 20 min | per run | Dead-man's-switch catches silence |
| Storage-approaching-capacity alerts | H | L | L | thresholds in `check-health.sh` | included | 15 min | Deduped |
| Log rotation and limits | M | L | L | journald size limits; Docker log options | 20 min | n/a | Disk alert |
| Safe temp cleanup | L | L | M (deletion) | A dry-run-first script | 30 min | weekly | **Dry-run first; human reviews the list** |
| Certificate expiry monitor | H | L | L | Uptime Kuma + TLS probe | 15 min | hourly | Warning at 14 d |
| Update availability check | M | L | L | `apt list --upgradable`; notify-only image-tag watcher | 30 min | weekly | Digest |

### Optional workflow automation

| Automation | Benefit | Complexity | Risk | Tools | Notes |
|------------|---------|-----------|------|-------|-------|
| Push/e-mail/chat notifications | H | L | L | ntfy-style, Telegram, SMTP | Test monthly |
| Webhook-triggered actions | M | M | M-H | small webhook receiver or n8n | Authenticate every endpoint; never expose the editor UI |
| Weekly health report | M | L | L | script + notification | Summarise warnings, free space, backup ages |
| Organise incoming files | M | M | M | systemd path unit or Paperless consume folder | Move, never delete; log actions |
| Process/index documents | H | L | L | Paperless-ngx native consumer **[V]** | Prefer app-native |
| Tell family a shared file/album is ready | M | L | L | App-native share notifications | Avoid custom glue |
| Start/stop game servers on demand | M | M | M | systemd unit or Compose profile; authenticated trigger | Save-flush before stop; never expose the trigger publicly |
| Run heavy jobs at quiet hours | M | L | L | timers with `Persistent=true` | Stagger so backups do not overlap |

### Where does each task belong?

| Mechanism | Use for |
|-----------|---------|
| **systemd timers / services** | Backups, health checks, cleanups, anything that must survive reboot and log to the journal; `OnFailure=` hooks; `Persistent=true` to catch up after downtime **[K]** |
| **cron** | Acceptable for trivial jobs; systemd timers are preferred for new work (logs, dependencies, failure hooks) |
| **Shell scripts** | The logic behind timers; keep them small, idempotent, and tested |
| **Application-native schedulers** | In-app jobs: Immich background jobs and DB dumps **[V]**, Paperless consumption, Nextcloud cron |
| **n8n / webhooks** | Cross-application workflows only (an event in one system triggers actions in another); not for scheduling a shell script |

## 5. Safety requirements for every automation

Record this table (template in Part K) for each automation before enabling it. Destructive operations, broad permission changes, risky firewall changes and changes that expose a service publicly **require human approval**; no automation does them unattended.

| Field | Backup timer | Health timer | Update checker (notify-only) |
|-------|--------------|--------------|------------------------------|
| Trigger | systemd timer 03:00 | systemd timer every 15 min | systemd timer weekly |
| Action | restic backup (local + off-site); optional prune | read-only checks; push on change | list upgradable packages / newer image tags; push digest |
| Permissions | root (reads all data); network egress | root (reads /proc, docker) | read-only; no package changes |
| Logs | journal + exit status | journal + state files | journal |
| Failure detection | exit code, `OnFailure=`, missing heartbeat | missing heartbeat from the external watcher | missing digest |
| Retries | restic `--retry-lock`; next night; `Persistent=true` | next run | next run |
| Data-loss potential | prune deletes old snapshots (**opt-in, local only**); never touches live data | none | none |
| Disable | `systemctl disable --now home-backup.timer` | same for `home-health.timer` | same |
| Safe test | `backup.sh --dry-run`; run the test suites | `check-health.sh --dry-run` | run once manually |

## 6. Update policy

Do **not** automatically pull and recreate every container on a schedule. Reasons: a new image can include breaking changes or one-way database migrations; mutable tags (`latest`) change under you; an update at 03:00 coinciding with a backup or a failed dependency breaks several apps at once with nobody watching; a compromised upstream would reach your server unattended.

| Layer | Policy |
|-------|--------|
| OS security patches | Unattended **security** upgrades on **[K]**; reboot for kernel updates in a chosen window (optionally an automatic reboot at a quiet hour when a reboot is pending) |
| Docker Engine and Compose | Update from Docker's repository inside the monthly window, not unattended: restarting the daemon restarts containers |
| Application images | Pinned tags. A notify-only checker tells you when a new version exists. You read the release notes, then update **one stack at a time** |
| Database migrations | Never skip major versions; take a fresh dump; for a major database engine upgrade, test the restore on a copy first. Immich restores need a compatible version and, for the CLI path, a fresh install **[V]** |
| Configuration changes | Edit in Git, `docker compose config` to validate, commit, then apply |
| Maintenance windows | Monthly patch slot (about 2 hours), outside 02:00-05:00 when dumps and backups run; announce to family if downtime is likely |
| Post-update checks | Container healthy, HTTP check green, one real action (open a photo, search a document), logs free of errors, free space sane |
| Backup verification before risky upgrades | Trigger an on-demand backup, confirm the snapshot and the fresh DB dump exist, optionally restore the dump into a scratch instance |
| Rollback | Revert the tag; start the previous version; if a migration ran, restore the pre-upgrade dump and files; keep the old tag and dump until the new version has run clean for a week |

### Per-stack update runbook (summary)

1. Check last backup: stamp fresh, no alerts. 2. Read release notes for breaking changes. 3. Take a fresh dump/backup. 4. Change the image tag in Git. 5. `docker compose config` (validate). 6. `docker compose pull` then `up -d` for that stack only. 7. Watch logs and health. 8. Functional test. 9. Commit. 10. If it fails: revert tag and restore (rollback row above).

## 7. UPS and power events

Automatic restart after power returns does not protect against an interrupted write or filesystem corruption; a UPS gives time for a **graceful shutdown**. With NUT or `apcupsd` **[K]**, the server reads UPS state and shuts down cleanly when battery is low; alert on "on battery" and on "low battery". Test the shutdown path once with a verified backup in a quiet hour. Without a UPS you can still detect interruptions afterwards (unexpected boot in the journal, a heartbeat gap) but you cannot prevent corruption.
