#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO/scripts/version-compare.sh"

fail=0
expect() {  # expect <lt|ge> <a> <b>
  local want="$1" a="$2" b="$3" got=ge
  version_lt "$a" "$b" && got=lt
  if [ "$got" = "$want" ]; then
    echo "ok   $a vs $b ($want)"
  else
    echo "FAIL $a vs $b: want $want, got $got"; fail=1
  fi
}

expect lt 4.13.7 5.6.2
expect ge 5.6.2 5.6.2
expect ge 5.10.0 5.6.2
expect lt 5.6.2 5.10.0
expect ge 5.6.2-beta 5.6.2
expect ge garbage 5.6.2

[ "$fail" = 0 ] && echo "version-compare: all passed"
exit "$fail"
