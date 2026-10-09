#!/usr/bin/env bash
# backup.sh - nightly restic backup wrapper (EXAMPLE: read it fully before using it).
#
# What it does
#   1. takes a lock so two runs never overlap
#   2. pre-flight: config files, mount sentinels, listed paths, repositories reachable
#   3. runs dump hooks (every executable in HOOKS_DIR); any failure aborts the run, so an
#      inconsistent dump is never stored
#   4. restic backup to the local repository and, if configured, the off-site repository
#   5. optional weekly forget/prune (only when PRUNE_ENABLED=1) and integrity checks
#   6. heartbeat ping (ok/fail) so an EXTERNAL service notices if this stops running
#
# Exit status
#   0 ok | 1 failure | 3 warning (restic exit 3: snapshot created, some source data unreadable)
#   64 usage error | 75 another run holds the lock
#   restic exit codes follow the restic scripting docs: 0 ok, 3 partial, anything else
#   (including unknown codes) is treated as a failure.
#
# Safety
#   * --dry-run: runs the pre-flight checks and 'restic backup --dry-run' / 'forget --dry-run';
#     it runs no hooks, writes no stamps, prunes nothing and sends no heartbeat.
#   * This script never runs 'restic init', 'restic unlock' or 'restic rebuild-index'.
#   * Secrets are read from files named in the config; they are never printed.
#
# Usage: backup.sh [--dry-run] [--local-only | --offsite-only] [--no-maintenance] [-h]
# Config: $BACKUP_CONF or /etc/home-server/backup.conf (shell syntax, root-owned, mode 0600).
#         See examples/config/backup.conf.example.
set -Eeuo pipefail
umask 077

DRY_RUN=0
ONLY=""
MAINTENANCE=1
FAILS=0
WARNS=0

log() { printf '%s [%s] %s\n' "$(date -Is)" "$1" "${*:2}" >&2; }

usage() {
  cat <<'EOF'
Usage: backup.sh [--dry-run] [--local-only | --offsite-only] [--no-maintenance] [-h]
  --dry-run         pre-flight + 'restic backup --dry-run'; no hooks, no stamps, no prune
  --local-only      only the local repository
  --offsite-only    only the off-site repository
  --no-maintenance  skip forget/prune and integrity checks
Config file: $BACKUP_CONF (default /etc/home-server/backup.conf)
EOF
}

parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --dry-run) DRY_RUN=1 ;;
      --local-only) ONLY=local ;;
      --offsite-only) ONLY=offsite ;;
      --no-maintenance) MAINTENANCE=0 ;;
      -h | --help) usage; exit 0 ;;
      *) echo "unknown option: $1" >&2; usage >&2; exit 64 ;;
    esac
    shift
  done
}

load_conf() {
  local conf="${BACKUP_CONF:-/etc/home-server/backup.conf}"
  [ -r "$conf" ] || { log ERROR "config not readable: $conf"; exit 1; }
  # shellcheck source=/dev/null
  . "$conf"
  : "${RESTIC_BIN:=restic}"
  : "${LOCAL_REPO:?LOCAL_REPO is required}"
  : "${LOCAL_PASSWORD_FILE:?LOCAL_PASSWORD_FILE is required}"
  : "${PATHS_FILE:?PATHS_FILE is required}"
  : "${STATE_DIR:=/var/lib/home-server}"
  : "${LOCK_FILE:=/run/lock/home-backup.lock}"
  : "${RETRY_LOCK:=5m}"
  : "${TAG:=nightly}"
  : "${KEEP_DAILY:=14}" "${KEEP_WEEKLY:=8}" "${KEEP_MONTHLY:=12}" "${KEEP_YEARLY:=5}"
  : "${PRUNE_ENABLED:=0}" "${PRUNE_WEEKDAY:=7}" "${CHECK_WEEKDAY:=7}" "${READ_DATA_SUBSET:=5%}"
  : "${OFFSITE_REPO:=}" "${OFFSITE_PRUNE_ENABLED:=0}"
}

heartbeat() { # ok|fail
  local url=""
  case "$1" in
    ok) url="${HEARTBEAT_OK_URL:-}" ;;
    fail) url="${HEARTBEAT_FAIL_URL:-}" ;;
  esac
  [ -n "$url" ] || return 0
  if [ "$DRY_RUN" -eq 1 ]; then log INFO "dry-run: skipping heartbeat ($1)"; return 0; fi
  curl -fsS -m 10 --retry 3 -o /dev/null "$url" || log WARN "heartbeat ping failed ($1)"
}

finish() {
  local code=0
  if [ "$FAILS" -gt 0 ]; then code=1; elif [ "$WARNS" -gt 0 ]; then code=3; fi
  case "$code" in
    0) heartbeat ok; log INFO "finished OK" ;;
    3) heartbeat fail; log WARN "finished with $WARNS warning(s)" ;;
    *) heartbeat fail; log ERROR "finished with $FAILS failure(s) and $WARNS warning(s)" ;;
  esac
  exit "$code"
}

# restic_for LABEL RESTIC-ARGS...  -> restic's own exit status
restic_for() {
  local label="$1"
  shift
  case "$label" in
    local)
      ( exec "$RESTIC_BIN" -r "$LOCAL_REPO" --password-file "$LOCAL_PASSWORD_FILE" \
          --retry-lock "$RETRY_LOCK" "$@" )
      ;;
    offsite)
      (
        if [ -n "${OFFSITE_ENV_FILE:-}" ]; then
          set -a
          # shellcheck source=/dev/null
          . "$OFFSITE_ENV_FILE"
          set +a
        fi
        extra=()
        if [ -n "${OFFSITE_LIMIT_UPLOAD_KIB:-}" ]; then extra=(--limit-upload "$OFFSITE_LIMIT_UPLOAD_KIB"); fi
        exec "$RESTIC_BIN" -r "$OFFSITE_REPO" --password-file "$OFFSITE_PASSWORD_FILE" \
          --retry-lock "$RETRY_LOCK" "${extra[@]}" "$@"
      )
      ;;
    *) log ERROR "internal error: unknown repository label $label"; return 1 ;;
  esac
}

wants() { # label -> true if this run should handle that repository
  [ -z "$ONLY" ] || [ "$ONLY" = "$1" ]
}

repo_configured() { # label
  case "$1" in
    local) return 0 ;;
    offsite) [ -n "$OFFSITE_REPO" ] ;;
  esac
}

active() { # label -> true if the repository is configured and selected for this run
  wants "$1" && repo_configured "$1"
}

acquire_lock() {
  mkdir -p "$(dirname "$LOCK_FILE")"
  exec 9>"$LOCK_FILE"
  if ! flock -n 9; then
    log ERROR "another backup run holds the lock ($LOCK_FILE)"
    exit 75
  fi
}

preflight() {
  local ok=1 s line
  [ -r "$PATHS_FILE" ] || { log ERROR "paths file not readable: $PATHS_FILE"; ok=0; }
  [ -s "$LOCAL_PASSWORD_FILE" ] || { log ERROR "local password file missing or empty"; ok=0; }
  if [ -n "$OFFSITE_REPO" ]; then
    [ -s "${OFFSITE_PASSWORD_FILE:-/nonexistent}" ] || { log ERROR "off-site password file missing or empty"; ok=0; }
    if [ -n "${OFFSITE_ENV_FILE:-}" ] && [ ! -r "$OFFSITE_ENV_FILE" ]; then
      log ERROR "off-site env file not readable"
      ok=0
    fi
  fi
  command -v "$RESTIC_BIN" >/dev/null 2>&1 || { log ERROR "restic not found: $RESTIC_BIN"; ok=0; }
  for s in "${SENTINELS[@]:-}"; do
    [ -z "$s" ] && continue
    [ -e "$s" ] || { log ERROR "sentinel missing (is the disk mounted?): $s"; ok=0; }
  done
  if [ -r "$PATHS_FILE" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
      line="${line#"${line%%[![:space:]]*}"}"
      line="${line%"${line##*[![:space:]]}"}"
      case "$line" in '' | '#'*) continue ;; esac
      # only plain paths are checked; patterns containing glob characters are skipped
      case "$line" in *[\*\?\[]*) continue ;; esac
      [ -e "$line" ] || { log ERROR "listed path does not exist: $line"; ok=0; }
    done <"$PATHS_FILE"
  fi
  [ "$ok" -eq 1 ]
}

check_repo() { # label
  local rc=0
  restic_for "$1" cat config >/dev/null || rc=$?
  case "$rc" in
    0) return 0 ;;
    10) log ERROR "$1: repository does not exist. Initialise it manually first; this script never runs 'restic init'." ;;
    11) log ERROR "$1: could not lock the repository (another restic process or a stale lock)." ;;
    12) log ERROR "$1: wrong repository password." ;;
    *) log ERROR "$1: repository not reachable (restic exit $rc)." ;;
  esac
  return 1
}

run_hooks() {
  local h name
  if [ -z "${HOOKS_DIR:-}" ] || [ ! -d "$HOOKS_DIR" ]; then
    log INFO "no hooks directory; skipping dump hooks"
    return 0
  fi
  for h in "$HOOKS_DIR"/*; do
    [ -f "$h" ] && [ -x "$h" ] || continue
    name="$(basename "$h")"
    if [ "$DRY_RUN" -eq 1 ]; then log INFO "dry-run: would run hook $name"; continue; fi
    log INFO "running hook $name"
    if ! "$h"; then
      log ERROR "hook $name failed; aborting before backup so no inconsistent dump is stored"
      return 1
    fi
  done
}

do_backup() { # label
  local label="$1" rc=0
  local -a args=(backup --files-from "$PATHS_FILE" --one-file-system --exclude-caches --tag "$TAG")
  [ -n "${EXCLUDE_FILE:-}" ] && args+=(--exclude-file "$EXCLUDE_FILE")
  [ "$DRY_RUN" -eq 1 ] && args+=(--dry-run)
  log INFO "$label: starting backup"
  restic_for "$label" "${args[@]}" || rc=$?
  case "$rc" in
    0) log INFO "$label: backup OK" ;;
    3) WARNS=$((WARNS + 1)); log WARN "$label: snapshot created but some source data could not be read (restic exit 3). Investigate." ;;
    *) FAILS=$((FAILS + 1)); log ERROR "$label: backup FAILED (restic exit $rc)"; return 1 ;;
  esac
  if [ "$DRY_RUN" -eq 0 ]; then
    install -d -m 0700 "$STATE_DIR"
    date +%s >"$STATE_DIR/last-backup-$label.ok"
  fi
  return 0
}

maintenance() { # runs after backups; label of repos that backed up OK is in OK_LABELS
  local dow dom label rc
  dow="$(date +%u)"
  dom="$((10#$(date +%d)))"
  # shellcheck disable=SC2086  # OK_LABELS is a list of plain words we built ourselves
  for label in $OK_LABELS; do
    # forget/prune: weekly, opt-in, never right after a failed or partial backup
    if [ "$PRUNE_ENABLED" = 1 ] && [ "$dow" = "$PRUNE_WEEKDAY" ] && { [ "$label" = local ] || [ "$OFFSITE_PRUNE_ENABLED" = 1 ]; }; then
      rc=0
      if [ "$DRY_RUN" -eq 1 ]; then
        restic_for "$label" forget --dry-run --keep-daily "$KEEP_DAILY" --keep-weekly "$KEEP_WEEKLY" \
          --keep-monthly "$KEEP_MONTHLY" --keep-yearly "$KEEP_YEARLY" || rc=$?
      else
        restic_for "$label" forget --keep-daily "$KEEP_DAILY" --keep-weekly "$KEEP_WEEKLY" \
          --keep-monthly "$KEEP_MONTHLY" --keep-yearly "$KEEP_YEARLY" --prune || rc=$?
      fi
      [ "$rc" -eq 0 ] || { FAILS=$((FAILS + 1)); log ERROR "$label: forget/prune failed (restic exit $rc)"; }
    fi
    # integrity: structure weekly, rotating data sample in the first week of each month
    if [ "$DRY_RUN" -eq 0 ] && [ "$dow" = "$CHECK_WEEKDAY" ]; then
      rc=0
      restic_for "$label" check || rc=$?
      [ "$rc" -eq 0 ] || { FAILS=$((FAILS + 1)); log ERROR "$label: 'restic check' failed (exit $rc)"; }
      if [ "$dom" -le 7 ]; then
        rc=0
        restic_for "$label" check --read-data-subset="$READ_DATA_SUBSET" || rc=$?
        [ "$rc" -eq 0 ] || { FAILS=$((FAILS + 1)); log ERROR "$label: data subset check failed (exit $rc)"; }
      fi
    fi
  done
}

main() {
  parse_args "$@"
  load_conf
  acquire_lock
  trap 'log ERROR "aborted unexpectedly near line $LINENO"; heartbeat fail; exit 1' ERR

  preflight || { FAILS=$((FAILS + 1)); finish; }

  local label
  for label in local offsite; do
    active "$label" || continue
    check_repo "$label" || { FAILS=$((FAILS + 1)); finish; }
  done

  run_hooks || { FAILS=$((FAILS + 1)); finish; }

  OK_LABELS=""
  for label in local offsite; do
    active "$label" || continue
    if do_backup "$label"; then OK_LABELS="$OK_LABELS $label"; fi
  done

  # only maintain repositories whose backup was completely clean
  if [ "$MAINTENANCE" -eq 1 ] && [ "$FAILS" -eq 0 ] && [ "$WARNS" -eq 0 ]; then
    maintenance
  elif [ "$MAINTENANCE" -eq 1 ]; then
    log INFO "skipping maintenance because this run had warnings or failures"
  fi
  finish
}

main "$@"
