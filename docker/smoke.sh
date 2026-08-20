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
  if timeout 120 docker compose run --rm -v "$DATA:/data:ro" tx "${args[@]}" \
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

note "result"
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
