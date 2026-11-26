#!/usr/bin/env bash
#
# codeburn-identity-label.test.sh — when something already listens on port 4747
# and the shared-services helper cannot tell that it is CodeBurn, the failure
# line must say which of two different things happened.
# `bash tests/codeburn-identity-label.test.sh`
#
#   foreign   the listener answered with a page that is not CodeBurn's
#             dashboard  -> "port 4747 belongs to another service"
#   deadline  nothing identifying answered before the overall deadline (a slow
#             or stalled dashboard, a listener that does not speak HTTP)
#             -> "listener on port 4747 did not confirm CodeBurn identity
#                 before Ns deadline"
#
# Root cause this guards against: scripts/ensure-shared-local-services.sh
# printed "belongs to another service" for both. On 2026-11-16 a CodeBurn
# dashboard that was only slow under load hit the 12 s deadline (the identity
# probe exits 2) and was reported as a foreign service. my-codex's copy of the
# helper already tells the two apart.
#
# curl and lsof are shimmed, so no port is bound and nothing leaves the machine;
# the helper's own state goes to a throwaway AGENT_HARNESS_STATE_DIR. HOME is
# never read or written.
set -uo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

DEADLINE_SECONDS=2          # short, so the two deadline cases stay quick
# Long, so a busy machine cannot push a foreign answer past the deadline: the
# verdict is immediate whatever the budget, and the label shows that it was.
FOREIGN_DEADLINE_SECONDS=30
SHIM="$TMP/shim"
mkdir -p "$SHIM"

# curl: what answers on http://127.0.0.1:4747/ depends on which marker file the
# case created. A stalled listener holds the connection until curl's own
# --max-time runs out and then exits 28, which is what curl does for a listener
# that accepted the connection and never answered.
cat > "$SHIM/curl" <<'EOF'
#!/usr/bin/env bash
url="${*: -1}"
state="${SHIM_STATE:?}"
case "$url" in
  http://127.0.0.1:4747/)
    max_time=1
    previous=""
    for argument in "$@"; do
      [ "$previous" = "--max-time" ] && max_time="$argument"
      previous="$argument"
    done
    if [ -f "$state/stalled" ]; then
      python3 -c 'import sys,time; time.sleep(float(sys.argv[1]))' "$max_time"
      exit 28
    fi
    if [ -f "$state/foreign" ]; then
      printf '<html><title>Another service</title></html>'
      exit 0
    fi
    if [ -f "$state/not-http" ]; then
      exit 52
    fi
    ;;
esac
exit 7
EOF

# lsof: port 4747 has a listener whenever the case says so.
cat > "$SHIM/lsof" <<'EOF'
#!/usr/bin/env bash
case "$*" in
  *-iTCP:4747*) [ -f "${SHIM_STATE:?}/listener" ] ;;
  *) exit 1 ;;
esac
EOF

# codeburn: must never be started while a listener owns the port.
cat > "$SHIM/codeburn" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${SHIM_STATE:?}/codeburn-calls"
exit 1
EOF
chmod +x "$SHIM/curl" "$SHIM/lsof" "$SHIM/codeburn"

fail=0
check() {
  if [ "$2" = "1" ]; then
    echo "PASS  $1"
  else
    echo "FAIL  $1"
    fail=1
  fi
}
contains() { grep -Fq -- "$2" "$1" && echo 1 || echo 0; }
lacks()    { grep -Fq -- "$2" "$1" && echo 0 || echo 1; }

# run_case <name> <marker> <deadline-seconds>: a listener on 4747 that behaves as
# <marker> says, with the helper's overall deadline set to <deadline-seconds>.
# Leaves the helper's output in $CASE_OUT.
run_case() {
  local name="$1" marker="$2" deadline="$3" root="$TMP/$1" extra_path="${4:-}"
  mkdir -p "$root/state" "$root/shared"
  touch "$root/state/listener" "$root/state/$marker"
  env PATH="${extra_path:+$extra_path:}$SHIM:$PATH" SHIM_STATE="$root/state" \
    AGENT_HARNESS_STATE_DIR="$root/shared" \
    AGENT_HARNESS_SERVICE_TIMEOUT_SECONDS="$deadline" \
    bash "$REPO/scripts/ensure-shared-local-services.sh" codeburn \
    > "$root/output" 2>&1 < /dev/null
  CASE_OUT="$root/output"
  CASE_CALLS="$root/state/codeburn-calls"
}

DEADLINE_LINE="codeburn web: FAIL (listener on port 4747 did not confirm CodeBurn identity before ${DEADLINE_SECONDS}s deadline; left untouched"
FOREIGN_LINE="codeburn web: FAIL (port 4747 belongs to another service; left untouched"

echo "[1/4] a stalled listener never answers: the deadline passes"
run_case stalled stalled "$DEADLINE_SECONDS"
check "reported as unconfirmed at the ${DEADLINE_SECONDS}s deadline" "$(contains "$CASE_OUT" "$DEADLINE_LINE")"
check "not reported as another service"                        "$(lacks "$CASE_OUT" "belongs to another service")"
check "codeburn is not started over the listener"              "$([ ! -e "$CASE_CALLS" ] && echo 1 || echo 0)"

echo "[2/4] a listener that does not speak HTTP: the deadline passes"
run_case not-http not-http "$DEADLINE_SECONDS"
check "reported as unconfirmed at the ${DEADLINE_SECONDS}s deadline" "$(contains "$CASE_OUT" "$DEADLINE_LINE")"
check "not reported as another service"                        "$(lacks "$CASE_OUT" "belongs to another service")"
check "codeburn is not started over the listener"              "$([ ! -e "$CASE_CALLS" ] && echo 1 || echo 0)"

echo "[3/4] a listener that answers as a different service"
run_case foreign foreign "$FOREIGN_DEADLINE_SECONDS"
check "reported as another service"                            "$(contains "$CASE_OUT" "$FOREIGN_LINE")"
check "not reported as an unconfirmed listener"                "$(lacks "$CASE_OUT" "did not confirm CodeBurn identity")"
check "codeburn is not started over the listener"              "$([ ! -e "$CASE_CALLS" ] && echo 1 || echo 0)"

echo "[4/4] the identity probe itself crashes"
# A python3 whose subprocess.run raises makes the probe die with a traceback
# instead of answering. That says nothing about the listener, so it must not be
# reported as another service. (Only scripts read from stdin are touched, which
# is how the probe runs; the lock supervisor uses Popen and is unaffected.)
REAL_PYTHON3="$(command -v python3)"
mkdir -p "$TMP/crash-shim"
cat > "$TMP/crash-shim/python3" <<EOF2
#!/usr/bin/env bash
if [ "\${1:-}" = "-" ]; then
  { printf 'import subprocess\ndef _boom(*a, **k):\n    raise RuntimeError("probe crash")\nsubprocess.run = _boom\n'; cat; } | exec "$REAL_PYTHON3" - "\${@:2}"
  exit \$?
fi
exec "$REAL_PYTHON3" "\$@"
EOF2
chmod +x "$TMP/crash-shim/python3"
run_case probe-crash not-http "$DEADLINE_SECONDS" "$TMP/crash-shim"
check "a probe crash is reported as unconfirmed" "$(contains "$CASE_OUT" "did not confirm CodeBurn identity")"
check "a probe crash is not reported as another service" "$(lacks "$CASE_OUT" "belongs to another service")"
check "codeburn is not started over the listener" "$([ ! -e "$CASE_CALLS" ] && echo 1 || echo 0)"

echo ""
if [ "$fail" -eq 1 ]; then
  echo "FAILED"
  exit 1
fi
echo "ALL PASSED"
