#!/usr/bin/env bash
# test-notify.sh - exercises scripts/notify.sh with a stub curl. Sends nothing over the network.
# Run:  bash examples/tests/test-notify.sh
set -Eeuo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
NOTIFY="$HERE/../scripts/notify.sh"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT
PASS=0; FAIL=0
ok() { PASS=$((PASS + 1)); printf 'ok   - %s\n' "$1"; }
bad() { FAIL=$((FAIL + 1)); printf 'FAIL - %s\n' "$1"; }
check() { local d="$1"; shift; if "$@"; then ok "$d"; else bad "$d"; fi; }

mkdir -p "$T/bin"
cat >"$T/bin/curl" <<'EOS'
#!/usr/bin/env bash
echo "$*" >"$STUB_DIR/curl.args"
args=("$@")
for ((i = 0; i < ${#args[@]}; i++)); do
  if [ "${args[i]}" = "-H" ] && [[ "${args[i + 1]}" == @* ]]; then cp "${args[i + 1]#@}" "$STUB_DIR/curl.headers"; fi
done
exit "$(cat "$STUB_DIR/curl.rc" 2>/dev/null || echo 0)"
EOS
chmod +x "$T/bin/curl"
export STUB_DIR="$T" PATH="$T/bin:$PATH"
echo "tk_supersecret_test_token" >"$T/token"
cat >"$T/notify.conf" <<CONF
NTFY_URL=https://ntfy.example.invalid/private-topic-xyz
NTFY_TOKEN_FILE=$T/token
CONF
run() { RC=0; OUT="$(NOTIFY_CONF="$T/notify.conf" bash "$NOTIFY" "$@" 2>&1)" || RC=$?; }

run -p high -t "Test title" "hello world"
check "send succeeds" test "$RC" -eq 0
check "headers carry title and priority" bash -c "grep -q 'Title: Test title' '$T/curl.headers' && grep -q 'Priority: high' '$T/curl.headers'"
check "token is sent as a bearer header" grep -q 'Authorization: Bearer tk_supersecret_test_token' "$T/curl.headers"
check "token never appears on the command line" bash -c "! grep -q 'supersecret' '$T/curl.args'"
check "message is the request body" grep -q -- '--data-binary hello world' "$T/curl.args"

run --dry-run -p low "quiet message"
check "dry run exits 0 and prints the message" bash -c "[ $RC -eq 0 ] && printf '%s' \"$OUT\" | grep -q 'quiet'"
check "dry run never prints the URL or token" bash -c "! printf '%s' \"$OUT\" | grep -q -e private-topic -e supersecret"

run
check "missing message exits 2" test "$RC" -eq 2
run -p bogus "x"
check "invalid priority exits 2" test "$RC" -eq 2
RC=0; NOTIFY_CONF="$T/missing.conf" bash "$NOTIFY" "x" >/dev/null 2>&1 || RC=$?
check "missing config exits 2" test "$RC" -eq 2
echo 22 >"$T/curl.rc"; run "x"
check "delivery failure exits 1" test "$RC" -eq 1
check "failure output does not leak the URL or token" bash -c "! printf '%s' \"$OUT\" | grep -q -e private-topic -e supersecret"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
