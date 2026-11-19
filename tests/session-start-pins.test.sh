#!/usr/bin/env bash
#
# session-start-pins.test.sh — hooks/session-start.sh installs the omo CLI and
# ast-grep at the exact versions install.sh pins.
# `bash tests/session-start-pins.test.sh`
#
# The hook installs either CLI when it is missing at session start. With
# `@latest` or no version there, a machine without it got whatever npm served
# that day, which undid install.sh's pin. Reads the two files only; no network.
set -uo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"

fail=0
check() {
  if [ "$2" = "1" ]; then
    echo "PASS  $1"
  else
    echo "FAIL  $1"
    fail=1
  fi
}

# Every version <file> passes to `npm i -g` for <package>, one per line:
# 3.17.3 for oh-my-opencode@3.17.3, "latest" for @latest, "(none)" for a bare
# package name.
npm_versions() {  # npm_versions <file> <package>
  awk -v pkg="$2" '
    /npm i(nstall)? -g / {
      for (i = 1; i <= NF; i++) {
        if ($i == pkg) print "(none)"
        else if (index($i, pkg "@") == 1) print substr($i, length(pkg) + 2)
      }
    }' "$1"
}

for pkg in oh-my-opencode @ast-grep/cli; do
  want="$(npm_versions "$REPO/install.sh" "$pkg" | sort -u)"
  got="$(npm_versions "$REPO/hooks/session-start.sh" "$pkg" | sort -u)"
  check "install.sh pins one exact $pkg version: ${want:-none}" \
    "$([[ "$want" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] && echo 1 || echo 0)"
  check "hooks/session-start.sh installs $pkg at that version: ${got:-none}" \
    "$([ -n "$got" ] && [ "$got" = "$want" ] && echo 1 || echo 0)"
done

if [ "$fail" -eq 0 ]; then
  echo "ALL PASSED"
else
  echo "FAILED"
fi
exit "$fail"
