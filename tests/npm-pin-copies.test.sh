#!/usr/bin/env bash
#
# npm-pin-copies.test.sh — every copy of the omo CLI and ast-grep npm pins
# names the exact version install.sh installs. `bash tests/npm-pin-copies.test.sh`
#
# hooks/session-start.sh installs either CLI when it is missing at session
# start; with `@latest` or no version there, a machine without it got whatever
# npm served that day, which undid install.sh's pin. The README tool tables
# (all six languages) and SETUP.md repeat the same `npm i -g` commands. Reads
# the files only; no network.
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
# 3.17.3 for oh-my-opencode@3.17.3 (also inside a Markdown code span),
# "latest" for @latest, "(none)" for a bare package name. Only the arguments
# of `npm i -g` count: they end at a shell operator or at the end of a code
# span, so `... && oh-my-opencode install` is not read as a bare package.
npm_versions() {  # npm_versions <file> <package>
  awk -v pkg="$2" '
    /npm i(nstall)? -g / {
      on = 0
      for (i = 1; i <= NF; i++) {
        if (!on) {
          if ($i == "-g" && i > 2 && ($(i - 1) == "i" || $(i - 1) == "install") && $(i - 2) ~ /npm$/) on = 1
          continue
        }
        if ($i ~ /^(&&|\|\||\||;)$/) { on = 0; continue }
        bare = $i
        sub(/[`.,;)]+$/, "", bare)
        if (bare == pkg) print "(none)"
        else if (index($i, pkg "@") == 1) {
          v = substr($i, length(pkg) + 2)
          sub(/[^0-9A-Za-z.+-].*$/, "", v)
          print v
        }
        if ($i ~ /`/) on = 0
      }
    }' "$1"
}

READMES=("$REPO/README.md" "$REPO"/docs/i18n/README.*.md)
check "six READMEs to compare (${#READMES[@]})"           "$([ "${#READMES[@]}" = 6 ] && echo 1 || echo 0)"

for pkg in oh-my-opencode @ast-grep/cli; do
  want="$(npm_versions "$REPO/install.sh" "$pkg" | sort -u)"
  check "install.sh pins one exact $pkg version: ${want:-none}" \
    "$([[ "$want" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] && echo 1 || echo 0)"
  copies=("$REPO/hooks/session-start.sh" "${READMES[@]}")
  if [ "$pkg" = oh-my-opencode ]; then copies+=("$REPO/SETUP.md"); fi
  for file in "${copies[@]}"; do
    got="$(npm_versions "$file" "$pkg" | sort -u)"
    check "${file#"$REPO"/} names $pkg at that version: ${got:-none}" \
      "$([ -n "$got" ] && [ "$got" = "$want" ] && echo 1 || echo 0)"
  done
done

if [ "$fail" -eq 0 ]; then
  echo "ALL PASSED"
else
  echo "FAILED"
fi
exit "$fail"
