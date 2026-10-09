# J. Automation (catalogue profiles)

The mechanism choice, the automation catalogue with benefit/complexity/risk, the safety table and the safe-update policy live in [`../07-automation-monitoring.md`](../07-automation-monitoring.md); tested scripts are in [`../../examples/`](../../examples/README.md). Labels as in the [README](README.md).

## Choosing the mechanism

| Need | Use | Not |
|------|-----|-----|
| Run a script nightly/weekly, survive reboots, log, alert on failure | **systemd timer + service** (with `OnFailure=` and `Persistent=true`) **[K]** | n8n |
| Trivial legacy job | cron is acceptable | |
| In-app jobs (photo ML, DB dumps, document consumption) | The app's own scheduler **[V for Immich dumps]** | Re-implementing it externally |
| An event in one system should trigger actions in another | A webhook receiver or n8n | A polling shell loop |
| Notify yourself | A push channel | E-mail-only (easily missed) |

## n8n (short profile)

| | |
|---|---|
| Purpose | Visual workflow automation that connects services and reacts to webhooks |
| Class / when | **Optional / Later**, only for cross-application workflows |
| Resources | ~300-800 MB RAM **[E]**; SQLite by default, PostgreSQL for heavier use **[K]** |
| Security | The editor is class 4 (admin only): it stores credentials and can run code. If you need inbound webhooks, only the webhook paths are class 3, protected by secret tokens and rate limits. Back up the encryption key that protects stored credentials separately **[K]** |
| Backup | Workflows exported to Git; database and key in restic |
| Verdict | Do not introduce it to schedule a shell script. Alternatives for event glue: Node-RED, small webhook receivers, or app-native integrations **[K]** |

## Webhooks (short)

A webhook is an authenticated HTTP request that triggers an action. Rules: one secret per hook, HTTPS, rate limit, allow-list the caller where possible, perform one narrow action, log every call, never expose a general "run command" endpoint. Public webhook endpoints must pass the exposure checklist.

## Application-native automation worth using

Immich (jobs, database dumps), Paperless-ngx (consumption rules, matching), Jellyfin (library scans, scheduled tasks), Uptime Kuma (notifications, maintenance windows), Compose (`restart` policies, healthchecks). Prefer these to external glue.
