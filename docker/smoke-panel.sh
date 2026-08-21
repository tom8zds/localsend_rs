#!/usr/bin/env bash
# Panel-issued config end-to-end verification, standalone.
#
# Kept out of smoke.sh deliberately: inside the long smoke process
# (after scenarios A-D) coturn in this stack intermittently stops
# answering TURN dials — restarts of coturn/rx1 don't clear it, yet
# the identical commands succeed from a fresh shell. Root cause is
# upstream/environment and still under investigation; this script
# runs the panel flow in a clean stack, which is deterministic.
set -euo pipefail
cd "$(dirname "$0")"

FAILURES=0
note()  { printf '\n\033[1;36m== %s ==\033[0m\n' "$*"; }
pass()  { printf '  \033[32mPASS\033[0m %s\n' "$*"; }
fail()  { printf '  \033[31mFAIL\033[0m %s\n' "$*"; FAILURES=$((FAILURES+1)); }

cleanup() {
  docker compose -f compose.relay.yaml down -v >/dev/null 2>&1 || true
  ( cd turn && docker compose down ) >/dev/null 2>&1 || true
}
trap cleanup EXIT

note "start coturn + panel (host network)"
( cd turn && docker compose up -d --build ) >/dev/null 2>&1
for i in $(seq 1 60); do
  curl -s -o /dev/null http://127.0.0.1:8787/login && break
  sleep 1
done

note "issue a config from the panel"
PB=http://127.0.0.1:8787
PANEL_COOKIE=$(curl -s -i -X POST -d "password=localtest-admin" $PB/login \
  | grep -i set-cookie | sed 's/.*panel_session=\([^;]*\).*/\1/')
ISSUE_HTML=$(curl -s -H "Cookie: panel_session=$PANEL_COOKIE" \
  -X POST -d "ttl=3600&suffix=smoke" $PB/issue)
PANEL_ADDR=$(printf '%s' "$ISSUE_HTML" | grep -oE 'addr=[^&"]*' | head -1 | sed 's/addr=//;s/%3A/:/')
PANEL_SECRET=$(printf '%s' "$ISSUE_HTML" | grep -oE 'secret=[^&"<]*' | head -1 | sed 's/secret=//')
if [[ -n "$PANEL_ADDR" && -n "$PANEL_SECRET" ]]; then
  pass "panel issued a config ($PANEL_ADDR)"
else
  fail "panel issue failed"; exit 1
fi
if printf '%s' "$ISSUE_HTML" | grep -q 'localsend-relay://configure'; then
  pass "deep link + QR present"
else
  fail "deep link missing"
fi

note "transfer with the panel-issued config"
printf '[relay]\naddr = "host.docker.internal:3478"\nsecret = "%s"\n' "$PANEL_SECRET" \
  > relay-test-config/localsend-cli/config.toml
docker compose -f compose.relay.yaml up -d rx1 >/dev/null 2>&1
for i in $(seq 1 60); do
  docker compose -f compose.relay.yaml logs rx1 2>/dev/null | grep -q 'Receiving as' && break
  sleep 1
done
DATA=$(mktemp -d)
head -c 524288 /dev/urandom > "$DATA/panel-e2e.bin"
WANT=$(sha256sum "$DATA/panel-e2e.bin" | cut -d' ' -f1)
if timeout 120 docker compose -f compose.relay.yaml run --rm --build \
    -v "$DATA:/data:ro" tx send --to 172.31.201.10:53317 --via-relay \
    -f /data/panel-e2e.bin >/dev/null 2>&1 \
  && [[ "$(docker compose -f compose.relay.yaml exec -T rx1 \
      sha256sum /inbox/panel-e2e.bin 2>/dev/null | cut -d' ' -f1)" == "$WANT" ]]; then
  pass "transfer + sha256 via panel-issued config"
else
  fail "transfer via panel-issued config"
fi
printf '[relay]\naddr = "host.docker.internal:3478"\nsecret = "localsend-relay-test-secret"\n' \
  > relay-test-config/localsend-cli/config.toml

note "result"
if [[ $FAILURES -eq 0 ]]; then
  echo "  PANEL FLOW PASSED ✅"
else
  echo "  $FAILURES check(s) failed ❌"
  exit 1
fi
