#!/usr/bin/env bash
# notify.sh - send one push notification to an ntfy-style HTTP endpoint (EXAMPLE).
#
# Usage: notify.sh [--dry-run] [-p PRIORITY] [-t TITLE] [-T TAGS] MESSAGE...
#   PRIORITY: min | low | default | high | urgent   (default: default)
#   --dry-run prints what would be sent (never the URL or the token) and sends nothing.
#
# Config (shell syntax, root-owned, mode 0600): $NOTIFY_CONF or /etc/home-server/notify.conf
#   NTFY_URL=https://ntfy.example.com/<topic>   # full topic URL; treat it as a secret
#   NTFY_TOKEN_FILE=/srv/secrets/ntfy.token     # optional: file holding an access token
#
# Exit status: 0 sent (or dry-run) | 1 delivery failed | 2 usage or configuration error
# Verify the header names and token format against your notification server's documentation
# before relying on this (written for the ntfy publish API).
set -Eeuo pipefail
umask 077

DRY_RUN=0
PRIORITY=default
TITLE="home-server"
TAGS=""

usage() {
  cat <<'EOF'
Usage: notify.sh [--dry-run] [-p PRIORITY] [-t TITLE] [-T TAGS] MESSAGE...
  PRIORITY: min | low | default | high | urgent
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    -p) PRIORITY="${2:?missing priority}"; shift 2 ;;
    -t) TITLE="${2:?missing title}"; shift 2 ;;
    -T) TAGS="${2:?missing tags}"; shift 2 ;;
    -h | --help) usage; exit 0 ;;
    --) shift; break ;;
    -*) echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
    *) break ;;
  esac
done
[ $# -ge 1 ] || { echo "message required" >&2; usage >&2; exit 2; }
MESSAGE="$*"

case "$PRIORITY" in
  min | low | default | high | urgent | max | 1 | 2 | 3 | 4 | 5) ;;
  *) echo "invalid priority: $PRIORITY" >&2; exit 2 ;;
esac

if [ "$DRY_RUN" -eq 1 ]; then
  printf 'notify (dry-run): priority=%s title=%q tags=%q message=%q\n' "$PRIORITY" "$TITLE" "$TAGS" "$MESSAGE"
  exit 0
fi

CONF="${NOTIFY_CONF:-/etc/home-server/notify.conf}"
[ -r "$CONF" ] || { echo "config not readable: $CONF" >&2; exit 2; }
# shellcheck source=/dev/null
. "$CONF"
: "${NTFY_URL:?NTFY_URL is not set in the config}"
case "$NTFY_URL" in http://* | https://*) ;; *) echo "NTFY_URL must start with http:// or https://" >&2; exit 2 ;; esac

# Headers go through a private temp file so the token never appears in the process list.
HDR="$(mktemp)"
trap 'rm -f "$HDR"' EXIT
{
  printf 'Title: %s\n' "$TITLE"
  printf 'Priority: %s\n' "$PRIORITY"
  if [ -n "$TAGS" ]; then printf 'Tags: %s\n' "$TAGS"; fi
  if [ -n "${NTFY_TOKEN_FILE:-}" ]; then
    [ -r "$NTFY_TOKEN_FILE" ] || { echo "token file not readable" >&2; exit 2; }
    printf 'Authorization: Bearer %s\n' "$(tr -d '\r\n' <"$NTFY_TOKEN_FILE")"
  fi
} >"$HDR"

if ! curl --fail --silent --show-error --max-time 15 --retry 2 --retry-delay 2 \
  -H "@$HDR" --data-binary "$MESSAGE" "$NTFY_URL" >/dev/null; then
  echo "notification delivery failed" >&2
  exit 1
fi
