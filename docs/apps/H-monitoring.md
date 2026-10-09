# H. Monitoring and observability (catalogue profiles)

Design, alert matrix, thresholds and the tested scripts are in [`../07-automation-monitoring.md`](../07-automation-monitoring.md). This page profiles the tools. Labels as in the [README](README.md).

Monitoring tells you a service is *up*; it does not prove its data is intact or restorable. Only restore tests do (Part G).

## Uptime Kuma (full profile)

| | |
|---|---|
| **Problem it solves** | A friendly dashboard that probes your services and certificates and sends you alerts, plus status pages |
| **Class / when** | **Recommended** / Stage 2 (Phase 8c) |
| **Why this, not simpler** | `check-health.sh` covers host conditions; Kuma adds black-box checks of what users actually use (is the login page up, does the HTTPS certificate verify, does DNS answer) with a UI and 90+ notification integrations **[V]** |
| **What it checks** | HTTP(S), TCP, HTTP keyword and JSON query, WebSocket, ping, DNS record, push (heartbeat receiver), Steam game server, and Docker containers; 20-second intervals; certificate information; multiple status pages; 2FA support **[V]** |
| **Hardware / storage** | ~100-250 MB RAM **[E]**; small database |
| **Dependencies** | Local storage for its data directory: **NFS is not supported [V]**. No external database |
| **Install / Compose** | The README's quick start publishes the UI on **all network interfaces** by default **[V]**; in this design give it no host port at all (reach it through Caddy on the `proxy` network) or bind to `127.0.0.1`/the Tailscale IP. Avoid the Docker-container monitor type: it needs the Docker socket; use HTTP/health checks instead |
| **Exposure / access** | Class 2 (admin dashboard). An optional read-only status page can be class 3 if it reveals nothing sensitive |
| **Authentication / security** | Admin account with 2FA **[V]**; notification tokens in its database are secrets: back it up encrypted |
| **Backup / recovery** | Back up the data directory using a consistent method (stop briefly or use its backup facility); worst case, rebuild monitors from your service inventory (Part K) |
| **Maintenance / cost** | Monthly update after release notes; free |
| **Limits** | **It cannot report its own host dying.** Run a second probe on a different device or use a hosted external check, and use Kuma's push/heartbeat monitor with the backup and health timers as a dead-man's switch |
| **Continuous?** | Yes |
| **Avoid when** | You have no services yet, or prefer only scripts and an external heartbeat |

## Short profiles

| Tool | Class / when | Purpose | Cost / burden | Verdict |
|------|--------------|---------|---------------|---------|
| smartmontools (`smartd`) | **Essential** / Now | Disk SMART monitoring and scheduled self-tests with alerts | negligible | Always |
| Prometheus + node_exporter + cAdvisor + Grafana + Alertmanager | Optional / Stage 3+ | Metrics, trends, dashboards, rule-based alerts | ~0.5-1.5 GB RAM and a disk to keep; cAdvisor wants broad host access **[K]** | Only with a stated need such as capacity planning across many services |
| Exporters and metrics endpoints | n/a | Expose internals | They are **unauthenticated by default** **[K]** | Class 4: internal network only |
| Netdata, Beszel, Glances-style all-in-one monitors | Optional | Quick host dashboards | Vary; some include cloud features | Optional alternatives; read what they send out |
| Log tools (Dozzle, Loki) | Optional | Browse logs | Dozzle-style tools use the Docker socket; Loki is heavy | Prefer `docker compose logs` and `journalctl` |
| Hosted heartbeat (healthchecks-style) | **Essential** / Now | Notifies when an expected ping does *not* arrive | Free tiers are typical; confirm limits **[U]** | Treat ping URLs as secrets |
| Push notification service (ntfy-style, Telegram) | **Essential** / Now | Delivers alerts to your phone | Self-host or hosted | Test it monthly |
| NUT / apcupsd | **Essential** once a UPS exists | UPS state and graceful shutdown | tiny | Part H section 7 |

## Minimal vs advanced stack

**Minimal:** smartd + `check-health.sh` + push channel + external heartbeat + Uptime Kuma. **Advanced:** add Prometheus, node_exporter, cAdvisor, Grafana, Alertmanager and a blackbox prober, but only when the minimal stack no longer answers a question you actually have.
