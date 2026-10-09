# Examples: tested reference scripts

These are **examples to read, adapt and test**, not a drop-in installer. They implement the designs in
[`docs/06-security-backup.md`](../docs/06-security-backup.md) and [`docs/07-automation-monitoring.md`](../docs/07-automation-monitoring.md).
They contain placeholders only; real configuration and secrets live outside this public repo.

| File | Purpose |
|------|---------|
| `scripts/backup.sh` | Nightly restic wrapper: lock, pre-flight (sentinels, paths, repositories), dump hooks, local + off-site backup, opt-in forget/prune, integrity checks, heartbeat, `--dry-run` |
| `scripts/check-health.sh` | Read-only local checks (disk, mounts, sentinels, backup age, memory, load, temperature, systemd, containers, certificates) with de-duplicated alerts and "resolved" messages |
| `scripts/notify.sh` | One push notification to an ntfy-style HTTP endpoint; token passed via a private header file, never on the command line |
| `config/*.example` | Configuration templates (shell syntax, root-owned, mode 0600 when real) |
| `systemd/*` | Service/timer pairs and an `OnFailure=` notifier |
| `tests/*.sh` | Test suites using stub `restic`, `df`, `docker`, `curl` etc. in a temp directory |

## Run the tests (safe: no root, no network, no real repositories)

```
bash examples/tests/test-backup.sh
bash examples/tests/test-health.sh
bash examples/tests/test-notify.sh
```

They were run with `shellcheck` (clean) and `bash -n`; the unit files pass `systemd-analyze verify`.
Last verified 2026-10-09 against the restic documentation sources listed in `docs/12-verification-log.md` (V12).

## Behaviour you should know

- **restic exit codes** (documented): `0` ok, `3` snapshot created but some source data unreadable, anything else (including unknown codes) is a failure. `backup.sh` exits `3` for the warning case so systemd's `OnFailure=` fires; it never reports a partial backup as green.
- **No `init`, no `unlock`, no `rebuild-index`.** A missing repository is an error you resolve by hand.
- **Prune is opt-in** (`PRUNE_ENABLED=1`), weekly, local repo only by default, and only after a fully clean backup. Do **not** enable off-site pruning for an append-only/immutable repository; prune from a separate trusted machine and use `forget --keep-within` there (restic's append-only guidance).
- **`--one-file-system`**: list each mount point explicitly in the paths file (see the example) because restic will not cross into other filesystems from a parent directory.
- **Heartbeat URLs are secrets** and are never logged.

## How these get installed (done interactively, phase by phase)

Phase 6 (backups) and Phase 7 (monitoring) in [`docs/09-roadmap.md`](../docs/09-roadmap.md): copy scripts to `/usr/local/bin` (root, 0755), real configs to `/etc/home-server` (root, 0600), secrets to `/srv/secrets` (root, 0700), unit files to `/etc/systemd/system`, then `--dry-run`, then one manual run, then enable the timers. Every step is verified against the then-current restic and systemd documentation before you run it. Nothing here should be copied onto the server before that.

## Known limits

- `check-health.sh` reports local conditions. A server cannot reliably report its own complete failure: pair it with an external heartbeat/uptime check.
- Certificate checks need `openssl` and network reachability to the endpoint.
- Network-usage and trend alerts are out of scope here (they need a metrics stack or `vnstat`; see Part H).
