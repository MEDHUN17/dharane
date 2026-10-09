#!/usr/bin/env bash
# test-backup.sh - exercises scripts/backup.sh against a STUB restic in a temp directory.
# Needs no root, no real repository and no network; touches nothing outside the temp dir.
# Run:  bash examples/tests/test-backup.sh
set -Eeuo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
BACKUP="$HERE/../scripts/backup.sh"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT

PASS=0
FAIL=0
ok() { PASS=$((PASS + 1)); printf 'ok   - %s\n' "$1"; }
bad() { FAIL=$((FAIL + 1)); printf 'FAIL - %s\n' "$1"; }
check() { # description, command...
  local d="$1"
  shift
  if "$@"; then ok "$d"; else bad "$d"; fi
}
calls_has() { grep -q -- "$1" "$T/calls.log"; }
calls_lacks() { ! grep -q -- "$1" "$T/calls.log" 2>/dev/null; }

mkdir -p "$T/bin" "$T/state" "$T/data" "$T/backup" "$T/hooks" "$T/run"
touch "$T/data/.disk-ok" "$T/backup/.disk-ok"
echo "pw-local-test" >"$T/pw-local"
echo "pw-off-test" >"$T/pw-off"
printf '%s\n' "# comment" "$T/data" >"$T/paths.txt"

cat >"$T/bin/restic" <<'EOF'
#!/usr/bin/env bash
repo="" verb=""
args=("$@")
for ((i = 0; i < ${#args[@]}; i++)); do
  case "${args[i]}" in
    -r) repo="${args[i + 1]}" ;;
    cat | backup | forget | check) [ -z "$verb" ] && verb="${args[i]}" ;;
  esac
done
echo "$(basename "$repo") $*" >>"$STUB_DIR/calls.log"
rcf="$STUB_DIR/rc.$verb.$(basename "$repo")"
if [ -f "$rcf" ]; then exit "$(cat "$rcf")"; fi
exit 0
EOF
cat >"$T/bin/curl" <<'EOF'
#!/usr/bin/env bash
echo "$*" >>"$STUB_DIR/curl.log"
exit 0
EOF
chmod +x "$T/bin/restic" "$T/bin/curl"
export STUB_DIR="$T"
export PATH="$T/bin:$PATH"

write_conf() { # extra config lines on stdin
  cat >"$T/backup.conf" <<EOF
RESTIC_BIN=restic
LOCAL_REPO=$T/repo-local
LOCAL_PASSWORD_FILE=$T/pw-local
OFFSITE_REPO=$T/repo-offsite
OFFSITE_PASSWORD_FILE=$T/pw-off
PATHS_FILE=$T/paths.txt
SENTINELS=($T/data/.disk-ok $T/backup/.disk-ok)
HOOKS_DIR=$T/hooks
STATE_DIR=$T/state
LOCK_FILE=$T/run/lock
HEARTBEAT_OK_URL=http://127.0.0.1:9/ok
HEARTBEAT_FAIL_URL=http://127.0.0.1:9/fail
PRUNE_ENABLED=0
CHECK_WEEKDAY=0
EOF
  cat >>"$T/backup.conf"
}

reset() {
  rm -f "$T"/calls.log "$T"/curl.log "$T"/rc.* "$T"/state/* "$T"/hooks/* "$T"/hook-ran
  : >"$T/calls.log"
  : >"$T/curl.log"
  write_conf </dev/null
}

run() { # args...  -> sets RC and OUT
  RC=0
  OUT="$(BACKUP_CONF="$T/backup.conf" bash "$BACKUP" "$@" 2>&1)" || RC=$?
}

# 1. clean run
reset
run
check "clean run exits 0" test "$RC" -eq 0
check "backs up local and off-site" bash -c "grep -c ' backup ' '$T/calls.log' | grep -qx 2"
check "stamps written" test -f "$T/state/last-backup-local.ok" -a -f "$T/state/last-backup-offsite.ok"
check "OK heartbeat sent" grep -q '/ok' "$T/curl.log"
check "no FAIL heartbeat" bash -c "! grep -q '/fail' '$T/curl.log'"
check "never runs init" calls_lacks ' init'

# 2. restic exit 3 on the local backup -> warning exit 3, still a stamp, fail heartbeat
reset
echo 3 >"$T/rc.backup.repo-local"
run
check "partial backup (restic 3) exits 3" test "$RC" -eq 3
check "partial backup still records a stamp" test -f "$T/state/last-backup-local.ok"
check "partial backup sends the fail heartbeat" grep -q '/fail' "$T/curl.log"
check "partial backup skips maintenance" calls_lacks ' forget'

# 3. off-site failure
reset
echo 1 >"$T/rc.backup.repo-offsite"
run
check "off-site failure exits 1" test "$RC" -eq 1
check "no off-site stamp after failure" test ! -f "$T/state/last-backup-offsite.ok"
check "local stamp still written" test -f "$T/state/last-backup-local.ok"

# 4. unknown restic exit code is a failure
reset
echo 99 >"$T/rc.backup.repo-local"
run
check "unknown restic exit code is treated as failure" test "$RC" -eq 1

# 5. missing sentinel aborts before any backup
reset
rm -f "$T/data/.disk-ok"
run
check "missing sentinel exits 1" test "$RC" -eq 1
check "missing sentinel: no backup attempted" calls_lacks ' backup'
touch "$T/data/.disk-ok"

# 6. repository does not exist (restic 10): never auto-initialise
reset
echo 10 >"$T/rc.cat.repo-local"
run
check "missing repo exits 1" test "$RC" -eq 1
check "missing repo: no backup and no init" bash -c "! grep -q -e ' backup' -e ' init' '$T/calls.log'"

# 7. hook failure aborts before backup
reset
printf '#!/usr/bin/env bash\nexit 1\n' >"$T/hooks/10-dump.sh"
chmod +x "$T/hooks/10-dump.sh"
run
check "failing hook exits 1" test "$RC" -eq 1
check "failing hook: no backup attempted" calls_lacks ' backup'

# 8. successful hook runs
reset
printf '#!/usr/bin/env bash\ntouch "%s"\n' "$T/hook-ran" >"$T/hooks/10-dump.sh"
chmod +x "$T/hooks/10-dump.sh"
run
check "hook ran on a real run" test -f "$T/hook-ran"

# 9. dry run changes nothing
reset
printf '#!/usr/bin/env bash\ntouch "%s"\n' "$T/hook-ran" >"$T/hooks/10-dump.sh"
chmod +x "$T/hooks/10-dump.sh"
run --dry-run
check "dry run exits 0" test "$RC" -eq 0
check "dry run passes --dry-run to restic backup" calls_has 'backup .*--dry-run'
check "dry run runs no hooks" test ! -f "$T/hook-ran"
check "dry run writes no stamps" bash -c "[ -z \"\$(ls -A '$T/state')\" ]"
check "dry run sends no heartbeat" test ! -s "$T/curl.log"
check "dry run never prunes" calls_lacks '--prune'

# 10. local-only / off-site-only selection
reset
run --local-only
check "--local-only touches only the local repo" bash -c "! grep -q 'repo-offsite' '$T/calls.log'"
reset
run --offsite-only
check "--offsite-only touches only the off-site repo" bash -c "! grep -q 'repo-local' '$T/calls.log'"

# 11. prune only when enabled, on the right weekday, after a clean backup
TODAY="$(date +%u)"
reset
write_conf <<EOF
PRUNE_ENABLED=1
PRUNE_WEEKDAY=$TODAY
EOF
run
check "prune runs when enabled on the prune day" calls_has 'repo-local .*forget .*--prune'
check "off-site is not pruned unless explicitly enabled" bash -c "! grep -q 'repo-offsite .*forget' '$T/calls.log'"
reset
write_conf <<EOF
PRUNE_ENABLED=1
PRUNE_WEEKDAY=$TODAY
EOF
echo 1 >"$T/rc.backup.repo-offsite"
run
check "no prune after a failed backup" calls_lacks '--prune'
reset
write_conf <<EOF
PRUNE_ENABLED=1
PRUNE_WEEKDAY=$(((TODAY % 7) + 1))
EOF
run
check "no prune on other weekdays" calls_lacks 'forget'

# 12. integrity check on its weekday
reset
write_conf <<EOF
CHECK_WEEKDAY=$TODAY
EOF
run
check "restic check runs on its weekday" calls_has 'repo-local .* check'
DOM="$((10#$(date +%d)))"
if [ "$DOM" -le 7 ]; then
  check "data subset check runs in the first week" calls_has 'read-data-subset=5%'
else
  check "no data subset check after the first week" calls_lacks 'read-data-subset'
fi

# 13. lock prevents overlapping runs
reset
(
  exec 9>"$T/run/lock"
  flock -n 9
  sleep 4
) &
LOCKER=$!
sleep 1
run
check "second run exits 75 while the lock is held" test "$RC" -eq 75
wait "$LOCKER" || true

# 14. secrets never appear in output
reset
run
check "password text is never printed" bash -c "! printf '%s' \"$OUT\" | grep -q -e pw-local-test -e pw-off-test"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
