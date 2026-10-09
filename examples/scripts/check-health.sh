#!/usr/bin/env bash
# check-health.sh - local health checks with de-duplicated push notifications (EXAMPLE).
#
# Read-only: it never changes the system. It checks
#   disk usage, required mounts and sentinel files, backup freshness, memory pressure,
#   load, temperature, failed systemd units, restarting/unhealthy containers, certificate expiry.
# Each problem becomes a finding (WARN or CRIT). A finding is notified when it first appears,
# when its level changes, and again every REMIND_HOURS while it persists; a "resolved"
# message is sent once when it clears. State lives in STATE_DIR.
#
# A server cannot reliably report its own complete failure: pair this with an EXTERNAL
# heartbeat/uptime check (Part H).
#
# Usage: check-health.sh [--dry-run] [-h]     (--dry-run prints findings, notifies nothing, keeps no state)
# Config: $HEALTH_CONF or /etc/home-server/health.conf (shell syntax). See examples/config/health.conf.example.
# Exit status: 0 completed (findings do not change the exit status) | 1 internal error | 64 usage
set -Eeuo pipefail
umask 077

DRY_RUN=0
HOST="$(hostname -s)"
NOW="$(date +%s)"
SEP=$'\x1f'
FINDINGS=()

usage() { echo "Usage: check-health.sh [--dry-run] [-h]"; }
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    -h | --help) usage; exit 0 ;;
    *) usage >&2; exit 64 ;;
  esac
  shift
done

CONF="${HEALTH_CONF:-/etc/home-server/health.conf}"
[ -r "$CONF" ] || { echo "config not readable: $CONF" >&2; exit 1; }
# shellcheck source=/dev/null
. "$CONF"
: "${DISK_WARN_PCT:=80}" "${DISK_CRIT_PCT:=90}" "${BACKUP_MAX_AGE_HOURS:=30}"
: "${MEM_AVAILABLE_WARN_PCT:=10}" "${LOAD_WARN_PER_CORE:=2}" "${TEMP_WARN_C:=80}" "${TEMP_CRIT_C:=90}"
: "${CERT_WARN_DAYS:=14}" "${CERT_CRIT_DAYS:=5}" "${REMIND_HOURS:=24}" "${CHECK_DOCKER:=1}"
: "${STATE_DIR:=/var/lib/home-server/health}" "${NOTIFY_CMD:=/usr/local/bin/notify.sh}"
: "${THERMAL_GLOB:=/sys/class/thermal/thermal_zone*/temp}"
: "${MEMINFO_FILE:=/proc/meminfo}" "${LOADAVG_FILE:=/proc/loadavg}"

emit() { FINDINGS+=("$1${SEP}$2${SEP}$3"); } # level key message

check_disks() {
  local mp pct
  for mp in "${DISK_MOUNTS[@]:-}"; do
    [ -n "$mp" ] || continue
    if [ ! -d "$mp" ]; then emit CRIT "disk:$mp" "path $mp does not exist"; continue; fi
    pct="$(df -P "$mp" | awk 'NR==2 {gsub("%","",$5); print $5}')"
    if ! [[ "$pct" =~ ^[0-9]+$ ]]; then emit WARN "disk:$mp" "could not read usage of $mp"; continue; fi
    if [ "$pct" -ge "$DISK_CRIT_PCT" ]; then emit CRIT "disk:$mp" "$mp is ${pct}% full (critical at ${DISK_CRIT_PCT}%)"
    elif [ "$pct" -ge "$DISK_WARN_PCT" ]; then emit WARN "disk:$mp" "$mp is ${pct}% full (warning at ${DISK_WARN_PCT}%)"; fi
  done
}

check_mounts() {
  local m s
  for m in "${MOUNTS_REQUIRED[@]:-}"; do
    [ -n "$m" ] || continue
    mountpoint -q "$m" || emit CRIT "mount:$m" "$m is not a mounted filesystem"
  done
  for s in "${SENTINELS[@]:-}"; do
    [ -n "$s" ] || continue
    [ -e "$s" ] || emit CRIT "sentinel:$s" "sentinel file missing: $s (disk absent or wrong?)"
  done
}

check_backups() {
  local f ts age
  for f in "${BACKUP_STAMPS[@]:-}"; do
    [ -n "$f" ] || continue
    if [ ! -r "$f" ]; then emit CRIT "backup:$f" "no successful backup recorded ($f)"; continue; fi
    ts="$(cat "$f")"
    if ! [[ "$ts" =~ ^[0-9]+$ ]]; then emit WARN "backup:$f" "unreadable backup stamp $f"; continue; fi
    age=$(((NOW - ts) / 3600))
    if [ "$age" -ge "$BACKUP_MAX_AGE_HOURS" ]; then
      emit CRIT "backup:$f" "last backup recorded in $f is ${age}h old (limit ${BACKUP_MAX_AGE_HOURS}h)"
    fi
  done
}

check_memory() {
  local total avail pct
  total="$(awk '/^MemTotal:/ {print $2}' "$MEMINFO_FILE")"
  avail="$(awk '/^MemAvailable:/ {print $2}' "$MEMINFO_FILE")"
  [ -n "$total" ] && [ -n "$avail" ] || { emit WARN "memory" "could not read memory information"; return 0; }
  pct=$((avail * 100 / total))
  if [ "$pct" -lt "$MEM_AVAILABLE_WARN_PCT" ]; then
    emit WARN "memory" "only ${pct}% of memory is available (warning below ${MEM_AVAILABLE_WARN_PCT}%)"
  fi
}

check_load() {
  local l15 cores per
  l15="$(awk '{print $3}' "$LOADAVG_FILE")"
  cores="$(nproc)"
  per="$(awk -v l="$l15" -v c="$cores" 'BEGIN {printf "%.2f", l / c}')"
  if awk -v p="$per" -v t="$LOAD_WARN_PER_CORE" 'BEGIN {exit !(p > t)}'; then
    emit WARN "load" "15-minute load is ${per} per core (warning above ${LOAD_WARN_PER_CORE})"
  fi
}

check_temperature() {
  local f raw max=0 c
  # shellcheck disable=SC2231  # the glob is intentionally expanded from the configured pattern
  for f in $THERMAL_GLOB; do
    [ -r "$f" ] || continue
    raw="$(cat "$f")"
    [[ "$raw" =~ ^-?[0-9]+$ ]] || continue
    c=$((raw / 1000))
    [ "$c" -gt "$max" ] && max="$c"
  done
  if [ "$max" -ge "$TEMP_CRIT_C" ]; then emit CRIT "temperature" "hottest sensor is ${max} C (critical at ${TEMP_CRIT_C} C)"
  elif [ "$max" -ge "$TEMP_WARN_C" ]; then emit WARN "temperature" "hottest sensor is ${max} C (warning at ${TEMP_WARN_C} C)"; fi
}

check_systemd() {
  command -v systemctl >/dev/null 2>&1 || return 0
  local failed
  failed="$(systemctl --failed --no-legend --plain 2>/dev/null | awk '{print $1}' | head -n 5 | paste -sd, -)"
  if [ -n "$failed" ]; then emit WARN "systemd-failed" "failed units: $failed"; fi
}

check_docker() {
  [ "$CHECK_DOCKER" = 1 ] || return 0
  command -v docker >/dev/null 2>&1 || return 0
  local restarting unhealthy
  restarting="$(docker ps --filter status=restarting --format '{{.Names}}' 2>/dev/null | paste -sd, -)" || restarting=""
  unhealthy="$(docker ps --filter health=unhealthy --format '{{.Names}}' 2>/dev/null | paste -sd, -)" || unhealthy=""
  if [ -n "$restarting" ]; then emit CRIT "docker-restarting" "containers stuck restarting: $restarting"; fi
  if [ -n "$unhealthy" ]; then emit WARN "docker-unhealthy" "unhealthy containers: $unhealthy"; fi
}

check_certs() {
  local ep host end end_ts days
  command -v openssl >/dev/null 2>&1 || return 0
  for ep in "${CERT_ENDPOINTS[@]:-}"; do
    [ -n "$ep" ] || continue
    host="${ep%%:*}"
    end="$(echo | timeout 10 openssl s_client -connect "$ep" -servername "$host" 2>/dev/null |
      openssl x509 -noout -enddate 2>/dev/null | sed 's/^notAfter=//')" || end=""
    if [ -z "$end" ]; then emit WARN "cert:$ep" "could not read the certificate from $ep"; continue; fi
    end_ts="$(date -d "$end" +%s 2>/dev/null)" || { emit WARN "cert:$ep" "unparseable expiry for $ep"; continue; }
    days=$(((end_ts - NOW) / 86400))
    if [ "$days" -le "$CERT_CRIT_DAYS" ]; then emit CRIT "cert:$ep" "certificate for $ep expires in ${days} day(s)"
    elif [ "$days" -le "$CERT_WARN_DAYS" ]; then emit WARN "cert:$ep" "certificate for $ep expires in ${days} day(s)"; fi
  done
}

safe_key() { printf '%s' "$1" | tr -c 'A-Za-z0-9_.-' '_'; }

notify() { # level key message
  local prio=default
  [ "$1" = CRIT ] && prio=high
  [ "$1" = OK ] && prio=low
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "WOULD NOTIFY [$prio] $1 $2: $3"
    return 0
  fi
  "$NOTIFY_CMD" -p "$prio" -t "$HOST: $1 $2" "$3" || echo "warning: notification command failed" >&2
}

process() {
  local entry level key msg sf last_level last_ts age_h
  declare -A CURRENT=()
  [ "$DRY_RUN" -eq 1 ] || install -d -m 0700 "$STATE_DIR"
  for entry in "${FINDINGS[@]:-}"; do
    [ -n "$entry" ] || continue
    IFS="$SEP" read -r level key msg <<<"$entry"
    CURRENT["$key"]="$level"
    echo "$level $key: $msg"
    sf="$STATE_DIR/$(safe_key "$key")"
    last_level=""
    last_ts=0
    if [ "$DRY_RUN" -eq 0 ] && [ -r "$sf" ]; then read -r last_level last_ts <"$sf" || true; fi
    age_h=$(((NOW - last_ts) / 3600))
    if [ "$DRY_RUN" -eq 1 ] || [ "$last_level" != "$level" ] || [ "$age_h" -ge "$REMIND_HOURS" ]; then
      notify "$level" "$key" "$msg"
      [ "$DRY_RUN" -eq 1 ] || printf '%s %s\n' "$level" "$NOW" >"$sf"
    fi
  done
  # clear findings that have disappeared
  if [ "$DRY_RUN" -eq 0 ]; then
    local f k
    for f in "$STATE_DIR"/*; do
      [ -f "$f" ] || continue
      k="$(basename "$f")"
      # compare using the sanitised key of every current finding
      local still=0 ck
      for ck in "${!CURRENT[@]}"; do
        [ "$(safe_key "$ck")" = "$k" ] && still=1
      done
      if [ "$still" -eq 0 ]; then
        notify OK "$k" "resolved: $k is back to normal"
        rm -f "$f"
      fi
    done
  fi
}

check_disks
check_mounts
check_backups
check_memory
check_load
check_temperature
check_systemd
check_docker
check_certs
process
[ "${#FINDINGS[@]}" -gt 0 ] || echo "all checks passed"
