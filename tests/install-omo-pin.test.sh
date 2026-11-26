#!/usr/bin/env bash
#
# install-omo-pin.test.sh — step [5c] installs the omo CLI (npm oh-my-opencode)
# at the version upstream/SOURCES.json pins, never npm @latest.
# `bash tests/install-omo-pin.test.sh`
#
# The other global npm installs (ast-grep, comment-checker, codeburn) name
# exact versions; omo was `npm i -g oh-my-opencode@latest`, so every fresh
# install took whatever npm served that day. Guards:
#   1. SOURCES.json pins an exact version, and install.sh installs that one.
#   2. omo missing: npm is asked for oh-my-opencode@<pin> only, and
#      `oh-my-opencode install` then runs with the flags it always had.
#   3. omo already on PATH: npm is not asked for it again.
#
# Runs install.sh in the shared sandbox (tests/lib/install-sandbox.sh): a
# throwaway HOME, TMPDIR and npm prefix, shimmed installers, local git only.
set -uo pipefail
. "$(dirname "$0")/lib/install-sandbox.sh"

PIN="$(node -p 'require(process.argv[1])["oh-my-opencode"].pinned_version' "$REPO/upstream/SOURCES.json" 2>/dev/null)"
case "$PIN" in ""|undefined) PIN="(none in SOURCES.json)" ;; esac
omo_requests() { { grep -E '^npm (i|install) .*oh-my-opencode' "$1/shim.log" 2>/dev/null || true; } | wc -l | tr -d ' '; }

echo "[1/3] the pin"
check "SOURCES.json pins an exact oh-my-opencode version: $PIN" "$(yes_if grep -Eqx '[0-9]+\.[0-9]+\.[0-9]+' <<< "$PIN")"
check "install.sh installs exactly that version"         "$(yes_if grep -qwF "npm i -g oh-my-opencode@$PIN" "$REPO/install.sh")"

C="$SANDBOX/repo"; make_repo "$C"
H="$SANDBOX/home"; mkdir -p "$H"

echo "[2/3] omo missing"
run_install "$H" "$C" --self-only --skip-tools
check "npm asked for oh-my-opencode@$PIN"                 "$(yes_if grep -qxF "npm i -g oh-my-opencode@$PIN" "$H/shim.log")"
check "npm never asked for oh-my-opencode@latest"         "$(yes_if not logged "$H" "oh-my-opencode@latest")"
check "npm asked for oh-my-opencode once"                 "$(yes_if [ "$(omo_requests "$H")" = 1 ])"
check "oh-my-opencode install ran with its flags"         "$(yes_if logged "$H" "oh-my-opencode install --no-tui --claude=yes --openai=no --gemini=no --copilot=no")"

echo "[3/3] omo already on PATH"
: > "$H/shim.log"
run_install "$H" "$C" --self-only --skip-tools
check "reported as already installed"                     "$(yes_if in_log "$H" "omo already installed")"
check "npm not asked for oh-my-opencode"                  "$(yes_if [ "$(omo_requests "$H")" = 0 ])"

finish
