#!/usr/bin/env bash
#
# codeburn-guard-policy.test.sh — the codeburn usage guard installs by
# default with its hard cost cap disabled, and stays idempotent.
# `bash tests/codeburn-guard-policy.test.sh`
#
# Root cause this guards against: codeburn guard's hard cap denies every
# tool call once a session's list-price-estimated cost passes it ($15
# default), and on a subscription plan a normal session reaches that in
# minutes. install.sh now installs the guard by default but writes
# hardUSD: null right after, unless the user already set a non-default cap.
#
# Runs install.sh --self-only against a throwaway HOME with npm/claude/curl/uv
# shimmed out (same pattern as manifest-cleanup.test.sh) plus a fake codeburn
# binary that records every call and emulates `guard status` / `guard install
# --global`, so nothing outside the temp dir is read or written and no real
# network or npm install happens.
set -uo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

SHIM="$TMP/shim"
mkdir -p "$SHIM"
printf '#!/usr/bin/env bash\ncase "$1" in root) exec %s "$@" ;; *) exit 0 ;; esac\n' \
  "$(command -v npm || echo /bin/true)" > "$SHIM/npm"
printf '#!/usr/bin/env bash\nexit 1\n' > "$SHIM/claude"
printf '#!/usr/bin/env bash\nexit 1\n' > "$SHIM/curl"
printf '#!/usr/bin/env bash\nexit 1\n' > "$SHIM/uv"
chmod +x "$SHIM/npm" "$SHIM/claude" "$SHIM/curl" "$SHIM/uv"

# Fake codeburn: records every invocation, and emulates just enough of
# `guard status` / `guard install --global` / `report` for install.sh's
# codeburn-guard block and verification probe to run against.
cat > "$SHIM/codeburn" <<'EOF'
#!/usr/bin/env bash
set -uo pipefail
state="${SHIM_STATE:?}"
printf '%s\n' "$*" >> "$state/codeburn-calls"
if [ "${1:-}" = "guard" ] && [ "${2:-}" = "status" ]; then
  if [ -f "$state/codeburn-guard-installed" ]; then
    printf '\n  codeburn guard\n    installed:  global %s/.claude/settings.json [PreToolUse, SessionStart, Stop]\n' "$HOME"
  else
    printf '\n  codeburn guard\n    installed:  nowhere (run: codeburn guard install)\n'
  fi
  exit 0
fi
if [ "${1:-}" = "guard" ] && [ "${2:-}" = "install" ] && [ "${3:-}" = "--global" ]; then
  if [ -f "$state/codeburn-guard-installed" ]; then
    echo "  ! guard hooks already present; nothing to install"
    exit 0
  fi
  mkdir -p "$HOME/.claude" "$HOME/.config/codeburn"
  [ -f "$HOME/.claude/settings.json" ] || echo '{}' > "$HOME/.claude/settings.json"
  if [ ! -f "$HOME/.config/codeburn/guard.json" ]; then
    cat > "$HOME/.config/codeburn/guard.json" <<'JSON'
{
  "softUSD": 5,
  "hardUSD": 15,
  "checkpointUSD": 3,
  "openerEnabled": true,
  "updatedAt": "2026-01-01T00:00:00.000Z"
}
JSON
  fi
  touch "$state/codeburn-guard-installed"
  echo "  Installed fakehash  Install codeburn guard hooks"
  exit 0
fi
if [ "${1:-}" = "report" ]; then
  echo '{}'
  exit 0
fi
exit 0
EOF
chmod +x "$SHIM/codeburn"

run_install() {  # run_install <fake-home> <log-file> [extra install.sh args...]
  local home="$1" log="$2"
  shift 2
  mkdir -p "$home"
  ( cd "$REPO" && PATH="$SHIM:$PATH" HOME="$home" SHIM_STATE="$home" \
      AGENT_HARNESS_SERVICES_SKIP=1 bash install.sh --self-only "$@" ) \
    > "$log" 2>&1
}

fail=0
check() {
  if [ "$2" = "1" ]; then
    echo "PASS  $1"
  else
    echo "FAIL  $1"
    fail=1
  fi
}
hard_usd() {  # hard_usd <fake-home>
  node -e "try{const g=JSON.parse(require('fs').readFileSync(process.argv[1]+'/.config/codeburn/guard.json','utf8'));console.log(g.hardUSD)}catch(e){console.log('MISSING')}" "$1"
}

echo "[1/5] fresh install (no prior guard.json) -> hardUSD null"
H1="$TMP/home-fresh"
if ! run_install "$H1" "$TMP/fresh.log"; then
  echo "FAIL  install.sh --self-only exited non-zero (fresh)"; tail -30 "$TMP/fresh.log"; exit 1
fi
check "guard install --global was called" "$([ -f "$H1/codeburn-guard-installed" ] && echo 1 || echo 0)"
check "hardUSD is null after a fresh install" "$([ "$(hard_usd "$H1")" = "null" ] && echo 1 || echo 0)"
check "summary line reports hard cap off" "$(grep -q 'codeburn guard:   installed (hard cap off)' "$TMP/fresh.log" && echo 1 || echo 0)"

echo "[2/5] pre-existing default hardUSD (15, guard already installed) -> becomes null"
H2="$TMP/home-default15"
mkdir -p "$H2/.config/codeburn"
cat > "$H2/.config/codeburn/guard.json" <<'JSON'
{
  "softUSD": 5,
  "hardUSD": 15,
  "checkpointUSD": 3,
  "openerEnabled": true,
  "updatedAt": "2026-01-01T00:00:00.000Z"
}
JSON
touch "$H2/codeburn-guard-installed"
if ! run_install "$H2" "$TMP/default15.log"; then
  echo "FAIL  install.sh --self-only exited non-zero (default15)"; tail -30 "$TMP/default15.log"; exit 1
fi
check "hardUSD 15 becomes null" "$([ "$(hard_usd "$H2")" = "null" ] && echo 1 || echo 0)"
check "guard install --global was NOT called again (already installed)" \
  "$(grep -q 'guard install --global' "$H2/codeburn-calls" && echo 0 || echo 1)"

echo "[3/5] pre-existing custom hardUSD (40, guard already installed) -> kept"
H3="$TMP/home-custom40"
mkdir -p "$H3/.config/codeburn"
cat > "$H3/.config/codeburn/guard.json" <<'JSON'
{
  "softUSD": 5,
  "hardUSD": 40,
  "checkpointUSD": 3,
  "openerEnabled": true,
  "updatedAt": "2026-01-01T00:00:00.000Z"
}
JSON
touch "$H3/codeburn-guard-installed"
if ! run_install "$H3" "$TMP/custom40.log"; then
  echo "FAIL  install.sh --self-only exited non-zero (custom40)"; tail -30 "$TMP/custom40.log"; exit 1
fi
check "hardUSD 40 is kept" "$([ "$(hard_usd "$H3")" = "40" ] && echo 1 || echo 0)"
check "summary line reports the kept cap" "$(grep -q 'codeburn guard:   installed (hard cap \$40)' "$TMP/custom40.log" && echo 1 || echo 0)"

echo "[4/5] --no-codeburn-guard -> no guard install call, guard.json untouched"
H4="$TMP/home-optout"
if ! run_install "$H4" "$TMP/optout.log" --no-codeburn-guard; then
  echo "FAIL  install.sh --self-only exited non-zero (optout)"; tail -30 "$TMP/optout.log"; exit 1
fi
check "no guard subcommand was called" \
  "$([ ! -f "$H4/codeburn-calls" ] || ! grep -q '^guard ' "$H4/codeburn-calls" && echo 1 || echo 0)"
check "guard.json was never created" "$([ ! -f "$H4/.config/codeburn/guard.json" ] && echo 1 || echo 0)"
check "summary line reports skipped" "$(grep -q 'codeburn guard:   skipped (--no-codeburn-guard)' "$TMP/optout.log" && echo 1 || echo 0)"

echo "[5/5] second run -> no duplicate install"
H5="$TMP/home-second-run"
if ! run_install "$H5" "$TMP/second-run-1.log"; then
  echo "FAIL  install.sh --self-only exited non-zero (second-run 1st pass)"; tail -30 "$TMP/second-run-1.log"; exit 1
fi
FIRST_CALLS="$(grep -c 'guard install --global' "$H5/codeburn-calls" || true)"
if ! run_install "$H5" "$TMP/second-run-2.log"; then
  echo "FAIL  install.sh --self-only exited non-zero (second-run 2nd pass)"; tail -30 "$TMP/second-run-2.log"; exit 1
fi
TOTAL_CALLS="$(grep -c 'guard install --global' "$H5/codeburn-calls" || true)"
check "guard install --global called exactly once across both runs" \
  "$([ "$FIRST_CALLS" = "1" ] && [ "$TOTAL_CALLS" = "1" ] && echo 1 || echo 0)"
check "second run still reports hard cap off" \
  "$(grep -q 'codeburn guard:   installed (hard cap off)' "$TMP/second-run-2.log" && echo 1 || echo 0)"

echo ""
if [ "$fail" -eq 1 ]; then
  echo "FAILED"
  exit 1
fi
echo "ALL PASSED"
