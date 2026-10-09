# Operations (TEMPLATE)

## Backup policy

| Dataset | Source path | Method | Schedule | Local repo | Off-site repo | Retention | Last restore test | Result |
|---------|-------------|--------|----------|-----------|---------------|-----------|-------------------|--------|

Heartbeat / alert routes: `...`   Immich built-in DB dump time: `02:00` (verify)   restic run time: `03:00`.

## Update schedule

| Layer | Method | Cadence | Window | Approver | Rollback |
|-------|--------|---------|--------|----------|----------|
| OS security patches | unattended | daily | n/a | automatic | `apt` history |
| OS full upgrade | manual | monthly | first Saturday, 2 h | me | snapshot/backup |
| Docker Engine | manual | monthly | same | me | package pin |
| App images | manual, one stack at a time | monthly | same | me | previous tag + restore |

## Maintenance log

| Date | Who | What was done | Result | Follow-up |
|------|-----|---------------|--------|-----------|

## Restore-test log

| Date | Dataset | Snapshot ID | Duration | Pass/fail | Notes |
|------|---------|-------------|----------|-----------|-------|

## Subscriptions and renewals

| Item | Provider | Cost and currency | Renewal date | Payment method | Auto-renew | Owner |
|------|----------|-------------------|--------------|----------------|-----------|-------|
| Domain | | | | | | |
| Off-site storage | | | | | | |
