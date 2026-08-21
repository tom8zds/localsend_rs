#!/usr/bin/env bash
# End-to-end CLI transfer smoke test across docker containers.
#
# Topology (all on one docker bridge network):
#   rx1, rx2  — `localsend-cli receive` (auto-accept, persistent)
#   tx        — one-shot `localsend-cli send` containers
#
# Scenarios:
#   C  discovery      — rx1/rx2 should see each other via UDP multicast
#   A  multi-receiver — parallel sends from tx to rx1 AND rx2
#   B  multi-session  — a second, independent session to the same rx1
#   ✓  integrity      — sha256 of every received file matches the sender
#
# Usage: docker/smoke.sh [--keep]     (--keep leaves containers running)
set -euo pipefail
cd "$(dirname "$0")"

KEEP=0
[[ "${1:-}" == "--keep" ]] && KEEP=1
FAILURES=0

note()  { printf '\n\033[1;36m== %s ==\033[0m\n' "$*"; }
pass()  { printf '  \033[32mPASS\033[0m %s\n' "$*"; }
fail()  { printf '  \033[31mFAIL\033[0m %s\n' "$*"; FAILURES=$((FAILURES+1)); }

cleanup() {
  if [[ $KEEP -eq 1 ]]; then
    echo "(--keep: containers left running; use 'docker compose down' when done)"
  else
    docker compose down -v --remove-orphans >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

note "build image & start receivers"
docker compose down -v --remove-orphans >/dev/null 2>&1 || true
docker compose up -d --build rx1 rx2

note "wait for receivers to be ready"
for i in $(seq 1 60); do
  if docker compose logs rx1 2>/dev/null | grep -q 'Receiving as' \
     && docker compose logs rx2 2>/dev/null | grep -q 'Receiving as'; then
    break
  fi
  sleep 1
  [[ $i -eq 60 ]] && { fail "receivers not ready within 60s"; exit 1; }
done
pass "rx1 and rx2 listening"
sleep 3   # let multicast announcements propagate

note "scenario C: multicast discovery between rx1 and rx2"
for rx in rx1 rx2; do
  if docker compose exec -T "$rx" cat /tmp/localsend-cli.log 2>/dev/null \
      | grep -q 'node discovered'; then
    peer=$(docker compose exec -T "$rx" cat /tmp/localsend-cli.log 2>/dev/null \
      | grep -o 'node discovered.*' | head -1 | cut -c1-120)
    pass "$rx discovered a peer: $peer"
  else
    fail "$rx saw no peers via multicast (discovery degraded or blocked)"
  fi
done

note "generate test payloads"
DATA=$(mktemp -d /tmp/localsend-smoke.XXXXXX)
trap 'rm -rf "$DATA"; cleanup' EXIT
echo "hello from the docker smoke test" > "$DATA/note.txt"
head -c 1048576 /dev/urandom > "$DATA/small.bin"    # 1 MiB
head -c 33554432 /dev/urandom > "$DATA/big.bin"     # 32 MiB
declare -A SUM
for f in note.txt small.bin big.bin; do
  SUM[$f]=$(sha256sum "$DATA/$f" | cut -d' ' -f1)
done
pass "payloads ready in $DATA"

run_tx() {  # run_tx <label> <target> <files...>
  local label=$1 target=$2; shift 2
  local args=(send --to "$target")
  for f in "$@"; do args+=(-f "/data/$f"); done
  if timeout 120 docker compose run --rm --build -v "$DATA:/data:ro" tx "${args[@]}" \
      >/dev/null 2>&1; then
    pass "$label -> $target"
  else
    fail "$label -> $target (exit $?)"
  fi
}

note "scenario A: parallel sends to two receivers"
run_tx "A1(note+big)"  rx1:53317 note.txt big.bin &
PID1=$!
run_tx "A2(small)"     rx2:53317 small.bin &
PID2=$!
wait $PID1; wait $PID2

note "scenario B: second independent session to rx1"
run_tx "B(small)" rx1:53317 small.bin

verify() {  # verify <rx> <files...>
  local rx=$1; shift
  for f in "$@"; do
    local got
    got=$(docker compose exec -T "$rx" sha256sum "/inbox/$f" 2>/dev/null \
      | cut -d' ' -f1 || true)
    if [[ -n "$got" && "$got" == "${SUM[$f]}" ]]; then
      pass "$rx/$f sha256 matches"
    else
      fail "$rx/$f sha256 mismatch (got '${got:-missing}', want '${SUM[$f]}')"
    fi
  done
}

note "verify integrity"
verify rx1 note.txt big.bin small.bin
verify rx2 small.bin

note "scenario D: cross-network relay fallback"
# Separate topology (docker/compose.relay.yaml): tx and rx1 sit on
# mutually-unreachable networks; the coturn relay runs on the host
# network (docker/turn) and is reached via host.docker.internal.
# Direct connections cannot route — the sender must fall back.
docker compose -f compose.relay.yaml down -v >/dev/null 2>&1 || true
( cd turn && docker compose up -d --build ) >/dev/null 2>&1
for i in $(seq 1 60); do
  if ss -tln 2>/dev/null | grep -q ':3478 ' \
     || docker logs localsend-turn-turn-1 2>&1 | tail -50 | grep -q 'Total auth threads'; then
    break
  fi
  sleep 1
done
docker compose -f compose.relay.yaml up -d --build rx1
for i in $(seq 1 60); do
  if docker compose -f compose.relay.yaml logs rx1 2>/dev/null | grep -q 'Receiving as'; then
    break
  fi
  sleep 1
  [[ $i -eq 60 ]] && { fail "relay rx1 not ready within 60s"; break; }
done
head -c 1048576 /dev/urandom > "$DATA/relay.bin"
SUM[relay.bin]=$(sha256sum "$DATA/relay.bin" | cut -d' ' -f1)
if timeout 120 docker compose -f compose.relay.yaml run --rm --build \
    -v "$DATA:/data:ro" tx send --to 172.31.201.10:53317 -f /data/relay.bin \
    >/dev/null 2>&1; then
  pass "D1 auto-fallback send via relay"
else
  fail "D1 auto-fallback send via relay"
fi
got=$(docker compose -f compose.relay.yaml exec -T rx1 \
  sha256sum /inbox/relay.bin 2>/dev/null | cut -d' ' -f1 || true)
if [[ -n "$got" && "$got" == "${SUM[relay.bin]}" ]]; then
  pass "D2 rx1/relay.bin sha256 matches"
else
  fail "D2 rx1/relay.bin sha256 mismatch"
fi
# --via-relay skips the doomed direct attempt entirely.
head -c 1024 /dev/urandom > "$DATA/forced.bin"
SUM[forced.bin]=$(sha256sum "$DATA/forced.bin" | cut -d' ' -f1)
if timeout 120 docker compose -f compose.relay.yaml run --rm --build \
    -v "$DATA:/data:ro" tx send --to 172.31.201.10:53317 --via-relay \
    -f /data/forced.bin >/dev/null 2>&1 \
  && [[ "$(docker compose -f compose.relay.yaml exec -T rx1 \
      sha256sum /inbox/forced.bin 2>/dev/null | cut -d' ' -f1)" == "${SUM[forced.bin]}" ]]; then
  pass "D3 --via-relay forced send + sha256"
else
  fail "D3 --via-relay forced send + sha256"
fi
docker compose -f compose.relay.yaml down -v >/dev/null 2>&1 || true

note "scenario E: panel-issued config (standalone script)"
# Runs in its own stack: inside the long-lived smoke process, coturn
# intermittently stops answering dials after scenario D (see the
# header of smoke-panel.sh). The panel flow is verified end-to-end by
# docker/smoke-panel.sh.
if [[ "${SMOKE_SKIP_PANEL:-0}" != "1" ]]; then
  if ./smoke-panel.sh > /tmp/smoke-panel.log 2>&1; then
    pass "E panel flow (details: docker/smoke-panel.sh)"
  else
    fail "E panel flow (rerun docker/smoke-panel.sh for details)"
    tail -20 /tmp/smoke-panel.log || true
  fi
else
  echo "  SKIP E (SMOKE_SKIP_PANEL=1)"
fi

if [[ $FAILURES -eq 0 ]]; then
  echo "  ALL SCENARIOS PASSED ✅"
else
  echo "  $FAILURES check(s) failed ❌ — dumping receiver logs:"
  for rx in rx1 rx2; do
    echo "--- $rx stdout ---"
    docker compose logs "$rx" 2>/dev/null | tail -20
    echo "--- $rx /tmp/localsend-cli.log (tail) ---"
    docker compose exec -T "$rx" cat /tmp/localsend-cli.log 2>/dev/null | tail -20
  done
  exit 1
fi
