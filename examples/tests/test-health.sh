#!/usr/bin/env bash
# test-health.sh - exercises scripts/check-health.sh with stubbed df/mountpoint/docker/systemctl
# and a stub notifier, entirely inside a temp directory. No root needed.
# Run:  bash examples/tests/test-health.sh
set -Eeuo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
HEALTH="$HERE/../scripts/check-health.sh"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT

PASS=0
FAIL=0
ok() { PASS=$((PASS + 1)); printf 'ok   - %s\n' "$1"; }
bad() { FAIL=$((FAIL + 1)); printf 'FAIL - %s\n' "$1"; }
check() { local d="$1"; shift; if "$@"; then ok "$d"; else bad "$d"; fi; }
notified() { grep -q -- "$1" "$T/notify.log"; }
notify_count() { wc -l <"$T/notify.log" | tr -d ' '; }

mkdir -p "$T/bin" "$T/state" "$T/data"
touch "$T/data/.disk-ok"

# --- stubs ---
cat >"$T/bin/df" <<'EOS'
#!/usr/bin/env bash
pct="$(cat "$STUB_DIR/df.pct" 2>/dev/null || echo 10)"
echo "Filesystem 1024-blocks Used Available Capacity Mounted on"
echo "/dev/stub 1000 500 500 ${pct}% $2"
EOS
cat >"$T/bin/mountpoint" <<'EOS'
#!/usr/bin/env bash
[ "$1" = "-q" ] && shift
grep -qx -- "$1" "$STUB_DIR/mounted.list" 2>/dev/null
EOS
cat >"$T/bin/docker" <<'EOS'
#!/usr/bin/env bash
case "$*" in
  *status=restarting*) cat "$STUB_DIR/docker.restarting" 2>/dev/null || true ;;
  *health=unhealthy*) cat "$STUB_DIR/docker.unhealthy" 2>/dev/null || true ;;
esac
EOS
cat >"$T/bin/systemctl" <<'EOS'
#!/usr/bin/env bash
cat "$STUB_DIR/systemd.failed" 2>/dev/null || true
EOS
cat >"$T/notifier" <<'EOS'
#!/usr/bin/env bash
echo "$*" >>"$STUB_DIR/notify.log"
EOS
chmod +x "$T"/bin/* "$T/notifier"
export STUB_DIR="$T"
export PATH="$T/bin:$PATH"

write_conf() {
  cat >"$T/health.conf" <<CONF
DISK_MOUNTS=($T/data)
MOUNTS_REQUIRED=($T/data)
SENTINELS=($T/data/.disk-ok)
BACKUP_STAMPS=($T/stamp)
BACKUP_MAX_AGE_HOURS=30
STATE_DIR=$T/state
NOTIFY_CMD=$T/notifier
MEMINFO_FILE=$T/meminfo
LOADAVG_FILE=$T/loadavg
THERMAL_GLOB='$T/thermal/zone*/temp'
CHECK_DOCKER=1
REMIND_HOURS=24
CONF
  cat >>"$T/health.conf"
}

reset() {
  rm -rf "$T/state" "$T/thermal" "$T"/docker.* "$T"/systemd.failed "$T/df.pct"
  mkdir -p "$T/state" "$T/thermal/zone0"
  : >"$T/notify.log"
  echo "$T/data" >"$T/mounted.list"
  date +%s >"$T/stamp"
  printf 'MemTotal: 1000000 kB\nMemAvailable: 600000 kB\n' >"$T/meminfo"
  echo "0.10 0.10 0.10 1/100 1" >"$T/loadavg"
  echo 40000 >"$T/thermal/zone0/temp"
  touch "$T/data/.disk-ok"
  write_conf </dev/null
}

run() { RC=0; OUT="$(HEALTH_CONF="$T/health.conf" bash "$HEALTH" "$@" 2>&1)" || RC=$?; }

# 1. healthy
reset
run
check "healthy system exits 0" test "$RC" -eq 0
check "healthy system says all checks passed" bash -c "printf '%s' \"$OUT\" | grep -q 'all checks passed'"
check "healthy system sends nothing" test "$(notify_count)" -eq 0

# 2. disk usage levels and de-duplication
reset; echo 85 >"$T/df.pct"; run
check "85% full -> WARN notification" notified 'WARN'
check "WARN uses default priority" notified '-p default'
run
check "same WARN is not re-sent immediately" test "$(notify_count)" -eq 1
echo 95 >"$T/df.pct"; run
check "WARN -> CRIT is notified again" test "$(notify_count)" -eq 2
check "CRIT uses high priority" notified '-p high'
echo 10 >"$T/df.pct"; run
check "recovery sends a resolved message" notified 'resolved'
check "state cleared after recovery" bash -c "[ -z \"\$(ls -A '$T/state')\" ]"
run
check "no repeat resolved message" test "$(notify_count)" -eq 3

# 3. reminders
reset; echo 85 >"$T/df.pct"; write_conf <<<"REMIND_HOURS=0"; run; run
check "REMIND_HOURS=0 re-notifies each run" test "$(notify_count)" -eq 2

# 4. mounts, sentinels
reset; : >"$T/mounted.list"; run
check "unmounted required path -> CRIT" notified 'is not a mounted filesystem'
reset; rm -f "$T/data/.disk-ok"; run
check "missing sentinel -> CRIT" notified 'sentinel file missing'

# 5. backup freshness
reset; echo $(($(date +%s) - 40 * 3600)) >"$T/stamp"; run
check "stale backup stamp -> CRIT" notified 'hours\?\|h old'
reset; rm -f "$T/stamp"; run
check "missing backup stamp -> CRIT" notified 'no successful backup'

# 6. memory, load, temperature
reset; printf 'MemTotal: 1000000 kB\nMemAvailable: 50000 kB\n' >"$T/meminfo"; run
check "low available memory -> WARN" notified 'of memory is available'
reset; echo "50.00 50.00 50.00 1/100 1" >"$T/loadavg"; write_conf <<<"LOAD_WARN_PER_CORE=0"; run
check "high load -> WARN" notified 'load is'
reset; echo 85000 >"$T/thermal/zone0/temp"; run
check "85 C -> WARN" notified '85 C'
reset; echo 95000 >"$T/thermal/zone0/temp"; run
check "95 C -> CRIT" notified 'critical at'

# 7. containers and systemd
reset; echo "web,db" >"$T/docker.restarting"; run
check "restarting container -> CRIT" notified 'stuck restarting: web,db'
reset; echo "app" >"$T/docker.unhealthy"; run
check "unhealthy container -> WARN" notified 'unhealthy containers: app'
reset; printf 'foo.service loaded failed failed Foo\n' >"$T/systemd.failed"; run
check "failed systemd unit -> WARN" notified 'failed units: foo.service'

# 8. dry run
reset; echo 95 >"$T/df.pct"; run --dry-run
check "dry run prints WOULD NOTIFY" bash -c "printf '%s' \"$OUT\" | grep -q 'WOULD NOTIFY'"
check "dry run sends nothing" test "$(notify_count)" -eq 0
check "dry run keeps no state" bash -c "[ -z \"\$(ls -A '$T/state')\" ]"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
