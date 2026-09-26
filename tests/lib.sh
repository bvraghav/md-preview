# tests/lib.sh — assertion helpers, sourced by every test-*.sh script.
#
# A suite calls ok/bad (or the check/eq helpers) for each assertion and ends
# with `finish`, which prints a summary and sets the exit status. `skip`
# skips the whole suite, e.g. when a tool it needs is missing.

set -u

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
MDP=$ROOT/bin/md-preview
WORK=${WORK:-$ROOT/tests/_work}
export MD_PREVIEW_DATA=${MD_PREVIEW_DATA:-$WORK/data}
SUITE=$(basename "$0" .sh)
SUITE=${SUITE#test-}
PASS=0
FAIL=0
mkdir -p "$WORK"

ok()   { PASS=$((PASS + 1)); printf '  ok    %s\n' "$*"; }
bad()  { FAIL=$((FAIL + 1)); printf '  FAIL  %s\n' "$*"; }
note() { printf '  ..    %s\n' "$*"; }
skip() { printf '%s: skipped (%s)\n' "$SUITE" "$*"; exit 0; }

# check DESC CMD...   passes when CMD succeeds
check() {
  local desc=$1; shift
  if "$@" >/dev/null 2>&1; then ok "$desc"; else bad "$desc"; fi
}
# refute DESC CMD...  passes when CMD fails
refute() {
  local desc=$1; shift
  if "$@" >/dev/null 2>&1; then bad "$desc"; else ok "$desc"; fi
}
# eq DESC WANT GOT
eq() {
  if [[ $3 == "$2" ]]; then ok "$1"; else bad "$1 (want '$2', got '$3')"; fi
}
# ge DESC MIN GOT
ge() {
  if (( $3 >= $2 )); then ok "$1"; else bad "$1 (want >= $2, got $3)"; fi
}

# count PATTERN FILE — occurrences (not lines) of a fixed string
count() { grep -oF -- "$1" "$2" | wc -l | tr -d ' '; }

need() {
  local c
  for c; do command -v "$c" >/dev/null 2>&1 || skip "needs $c"; done
}

free_port() {
  python3 -c 'import socket; s = socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1])'
}

# wait_for SECONDS CMD...  poll every 0.25 s until CMD succeeds
wait_for() {
  local tries=$(( $1 * 4 )); shift
  while (( tries-- > 0 )); do
    "$@" >/dev/null 2>&1 && return 0
    sleep 0.25
  done
  return 1
}

finish() {
  printf '%s: %d passed, %d failed\n' "$SUITE" "$PASS" "$FAIL"
  (( FAIL == 0 ))
}
