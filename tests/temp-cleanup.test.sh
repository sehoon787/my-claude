#!/usr/bin/env bash
#
# temp-cleanup.test.sh — install.sh removes every temp path it creates, on every
# way out of the script. `bash tests/temp-cleanup.test.sh`
#
# Root cause this guards against: install.sh set `trap ... EXIT` three times
# (the clone directory, the anthropics/skills clone, the karpathy file), and a
# later EXIT trap replaces the earlier one, so each run left its clone and
# manifest directories behind in $TMPDIR; the tools menu also cleared every
# trap. Second cause: BSD/macOS mktemp ignores TMPDIR when it gets no template,
# so on macOS neither install.sh nor a check against a throwaway TMPDIR ever
# looked at the directory the temp paths really went to.
#
# What this proves:
#   [1/5] scripts/temp-cleanup.sh: every path make_temp registered is gone on
#         a normal exit, `exit N`, a `set -e` abort, SIGTERM, SIGINT and
#         SIGHUP, with the exit status unchanged; make_temp puts its path under
#         TMPDIR even when mktemp would ignore it; odd TMPDIR values work
#         (spaces, a trailing slash, a directory that does not exist).
#   [2/5] install.sh keeps to that: no EXIT trap without the cleanup, nothing
#         clears the EXIT trap, no mktemp outside make_temp.
#   [3/5] The tools menu (the real select_tools_menu, cut out of install.sh and
#         run under a pseudo-terminal) leaves the cleanup trap in place: a path
#         registered before the menu is removed after a confirmed menu, after a
#         path registered after it, and after Ctrl-C (exit 130).
#   [4/5] A whole `install.sh --self-only` with no terminal: every temp path it
#         made is under TMPDIR and gone afterwards, and TMPDIR is empty.
#   [5/5] The same under a pseudo-terminal, so the tools menu runs inside the
#         real install.
#
# Every child gets a throwaway HOME, TMPDIR, NPM_CONFIG_PREFIX and XDG_*
# directory, and shims for npm, claude, curl, uv, serena, headroom, codeburn,
# tmux and the one `git clone` install.sh makes (anthropics/skills), so nothing
# outside the test's temp dir is read or written and nothing is downloaded.
# The mktemp shim behaves like macOS mktemp (no template: TMPDIR ignored, the
# path goes to a decoy directory inside the test's temp dir) and logs every path
# it makes, so a run against a broken install.sh leaks into the test's own temp
# dir, never into the machine's.
set -uo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
HELPER="$REPO/scripts/temp-cleanup.sh"

SHIM="$TMP/shim"
mkdir -p "$SHIM"
REAL_MKTEMP="$(command -v mktemp)"
REAL_GIT="$(command -v git)"

cat > "$SHIM/mktemp" <<EOF
#!/usr/bin/env bash
template=""
for arg in "\$@"; do
  case "\$arg" in -*) ;; *) template=1 ;; esac
done
[ -n "\$template" ] || set -- "\$@" "\$MKTEMP_DEFAULT_DIR/tmp.XXXXXXXXXX"
made=\$("$REAL_MKTEMP" "\$@") || exit \$?
printf '%s\n' "\$made" >> "\$MKTEMP_LOG"
printf '%s\n' "\$made"
EOF

cat > "$SHIM/git" <<EOF
#!/usr/bin/env bash
if [ "\${1:-}" = clone ]; then
  dest="\${@: -1}"
  mkdir -p "\$dest/skills/pdf" "\$dest/skills/docx"
  echo "# pdf" > "\$dest/skills/pdf/SKILL.md"
  echo "# docx" > "\$dest/skills/docx/SKILL.md"
  exit 0
fi
exec "$REAL_GIT" "\$@"
EOF

cat > "$SHIM/npm" <<'EOF'
#!/usr/bin/env bash
[ "${1:-}" = root ] && echo "${NPM_CONFIG_PREFIX:-/nonexistent}/lib/node_modules"
exit 0
EOF
printf '#!/usr/bin/env bash\necho "tmux 3.4"\n' > "$SHIM/tmux"
for tool in claude curl uv serena headroom codeburn brew sudo; do
  printf '#!/usr/bin/env bash\nexit 1\n' > "$SHIM/$tool"
done
chmod +x "$SHIM"/*

fail=0
check() {
  if [ "$2" = "1" ]; then
    echo "PASS  $1"
  else
    echo "FAIL  $1"
    fail=1
  fi
}
yes_if() { if "$@"; then echo 1; else echo 0; fi; }
# under <path> <dir>: success when <path> is inside <dir> (a function, because
# bash 3.2 cannot parse a `case` inside $(...)).
under() { case "$1" in "${2%/}"/*) return 0 ;; esac; return 1; }

# new_case <name>: a throwaway HOME, an empty TMPDIR, and the decoy directory
# the shimmed mktemp uses when it is given no template.
new_case() {
  CASE="$TMP/$1"
  mkdir -p "$CASE/home" "$CASE/tmp" "$CASE/decoy" "$CASE/npm-prefix" \
    "$CASE/xdg-config" "$CASE/xdg-state" "$CASE/xdg-cache" "$CASE/xdg-data"
  : > "$CASE/mktemp.log"
}
# in_case <command...>: run a command in the current case's environment.
in_case() {
  env PATH="$SHIM:$PATH" HOME="$CASE/home" TMPDIR="$CASE/tmp" NPM_CONFIG_PREFIX="$CASE/npm-prefix" \
    XDG_CONFIG_HOME="$CASE/xdg-config" XDG_STATE_HOME="$CASE/xdg-state" \
    XDG_CACHE_HOME="$CASE/xdg-cache" XDG_DATA_HOME="$CASE/xdg-data" \
    MKTEMP_DEFAULT_DIR="$CASE/decoy" MKTEMP_LOG="$CASE/mktemp.log" \
    AGENT_HARNESS_SERVICES_SKIP=1 \
    "$@"
}

# ---------------------------------------------------------------------------
echo "[1/5] scripts/temp-cleanup.sh"
if [ ! -f "$HELPER" ]; then
  check "scripts/temp-cleanup.sh exists" 0
else
  # unit <name> <expected-status> <body...>: the body runs after make_temp has
  # registered a directory (with a file inside) and a file, under the EXIT trap
  # install.sh sets. Both must be gone afterwards, whatever the body does.
  unit() {
    local name="$1" expected="$2" body="$3" script rc dir_path file_path
    new_case "unit-$name"
    script="$CASE/snippet.sh"
    {
      printf 'set -euo pipefail\n. "%s"\ntrap cleanup_temp_paths EXIT\n' "$HELPER"
      printf 'make_temp DIR_PATH -d\nmake_temp FILE_PATH\n'
      printf 'mkdir "$DIR_PATH/nested dir"; : > "$DIR_PATH/nested dir/inner file"\n'
      printf 'printf "%%s\\n" "$DIR_PATH" "$FILE_PATH" > "%s/paths"\n' "$CASE"
      printf '%s\n' "$body"
    } > "$script"
    in_case bash "$script" > "$CASE/out" 2>&1 < /dev/null
    rc=$?
    dir_path="$(sed -n 1p "$CASE/paths" 2>/dev/null)"
    file_path="$(sed -n 2p "$CASE/paths" 2>/dev/null)"
    check "$name: exit status is $expected" "$([ "$rc" = "$expected" ] && echo 1 || echo 0)"
    check "$name: the registered directory (with contents) and file are gone" \
      "$([ -n "$dir_path" ] && [ -n "$file_path" ] && [ ! -e "$dir_path" ] && [ ! -e "$file_path" ] && echo 1 || echo 0)"
    check "$name: nothing is left in TMPDIR" "$([ -z "$(ls -A "$CASE/tmp")" ] && echo 1 || echo 0)"
  }
  unit "normal exit"            0   ':'
  unit "exit 3"                 3   'exit 3'
  unit "set -e abort"           1   'false'
  unit "SIGTERM"                143 'kill -TERM $$; sleep 5'
  unit "SIGINT"                 130 'kill -INT $$; sleep 5'
  unit "SIGHUP"                 129 'kill -HUP $$; sleep 5'
  unit "cleanup run twice"      0   'cleanup_temp_paths; cleanup_temp_paths'

  # Nothing registered: an empty list must not trip `set -u`, which bash before
  # 4.4 (the macOS system bash is 3.2) reports as an unbound variable. Run it
  # under the system bash as well as the one on PATH.
  for shell in bash /bin/bash; do
    [ -x "$(command -v "$shell")" ] || continue
    new_case unit-empty
    printf 'set -euo pipefail\n. "%s"\ntrap cleanup_temp_paths EXIT\n:\n' "$HELPER" > "$CASE/snippet.sh"
    in_case "$shell" "$CASE/snippet.sh" > "$CASE/out" 2>&1 < /dev/null
    check "nothing registered ($shell): exits 0 with no error under set -u" \
      "$([ "$?" = 0 ] && [ ! -s "$CASE/out" ] && echo 1 || echo 0)"
  done

  # TMPDIR is honored even though this mktemp, like macOS's, ignores it when it
  # is given no template. A trailing slash, a space, and a TMPDIR that does not
  # exist are all handled.
  for variant in plain slash space missing; do
    new_case "unit-tmpdir-$variant"
    case "$variant" in
      plain)   dir="$CASE/tmp" ;;
      slash)   dir="$CASE/tmp/" ;;
      space)   dir="$CASE/tmp dir"; mkdir -p "$dir" ;;
      missing) dir="$CASE/no such dir" ;;
    esac
    cat > "$CASE/snippet.sh" <<EOF
set -euo pipefail
. "$HELPER"
trap cleanup_temp_paths EXIT
make_temp D -d
make_temp F
printf '%s\n%s\n' "\$D" "\$F" > "$CASE/paths"
EOF
    env PATH="$SHIM:$PATH" TMPDIR="$dir" MKTEMP_DEFAULT_DIR="$CASE/decoy" MKTEMP_LOG="$CASE/mktemp.log" \
      bash "$CASE/snippet.sh" > "$CASE/out" 2>&1 < /dev/null
    rc=$?
    d="$(sed -n 1p "$CASE/paths" 2>/dev/null)"; f="$(sed -n 2p "$CASE/paths" 2>/dev/null)"
    check "TMPDIR $variant: make_temp succeeds and both paths are removed on exit" \
      "$([ "$rc" = 0 ] && [ -n "$d" ] && [ -n "$f" ] && [ ! -e "$d" ] && [ ! -e "$f" ] && echo 1 || echo 0)"
    if [ "$variant" = missing ]; then
      check "TMPDIR $variant: falls back to mktemp's own default" \
        "$(yes_if under "$d" "$CASE/decoy")"
    else
      check "TMPDIR $variant: the paths are created inside it, not in mktemp's own default" \
        "$(under "$d" "$dir" && under "$f" "$dir" && echo 1 || echo 0)"
    fi
  done
fi

# ---------------------------------------------------------------------------
echo "[2/5] install.sh wiring"
# Every `trap ... EXIT` runs the cleanup (a later one would otherwise replace it).
BAD_TRAPS="$(grep -nE '^[[:space:]]*trap[^#]*[[:space:]]EXIT\b' "$REPO/install.sh" | grep -v 'cleanup_temp_paths' || true)"
check "every EXIT trap in install.sh runs cleanup_temp_paths" "$([ -z "$BAD_TRAPS" ] && echo 1 || echo 0)"
[ -z "$BAD_TRAPS" ] || printf '      %s\n' "$BAD_TRAPS"
# Nothing clears the EXIT trap (`trap - EXIT INT TERM` is what the menu did).
CLEARED="$(grep -nE '^[[:space:]]*trap[[:space:]]+-[[:space:]][^#]*\bEXIT\b' "$REPO/install.sh" || true)"
check "nothing in install.sh clears the EXIT trap" "$([ -z "$CLEARED" ] && echo 1 || echo 0)"
[ -z "$CLEARED" ] || printf '      %s\n' "$CLEARED"
# Temp paths come from make_temp, which registers them.
DIRECT_MKTEMP="$(grep -nE '(^|[^[:alnum:]_.-])mktemp([^[:alnum:]_-]|$)' "$REPO/install.sh" | grep -vE '^[0-9]+:[[:space:]]*#' || true)"
check "install.sh makes no temp path except through make_temp" "$([ -z "$DIRECT_MKTEMP" ] && echo 1 || echo 0)"
[ -z "$DIRECT_MKTEMP" ] || printf '      %s\n' "$DIRECT_MKTEMP"
check "install.sh sources scripts/temp-cleanup.sh" \
  "$(yes_if grep -qF '. "$SCRIPT_DIR/scripts/temp-cleanup.sh"' "$REPO/install.sh")"
check "install.sh sets the cleanup trap before the first make_temp and before the tools menu is defined" \
  "$(awk '
    /^trap cleanup_temp_paths EXIT$/ { if (!t) t = NR }
    /^[[:space:]]*#/ { next }
    /make_temp / { if (!m) m = NR }
    /^select_tools_menu\(\) \{/ { if (!s) s = NR }
    END { exit !(t && m && s && t < m && t < s) }
  ' "$REPO/install.sh" && echo 1 || echo 0)"

# ---------------------------------------------------------------------------
# Python is only needed for the pseudo-terminal runs. A host that cannot give
# out a pty (exit 99) skips them, loudly.
cat > "$TMP/pty-run.py" <<'PY'
# usage: pty-run.py <transcript> <wait-for> <keys> -- <command...>
# Runs the command under a pseudo-terminal, sends <keys> (backslash escapes
# understood) once <wait-for> has appeared in its output and the output has then
# gone quiet, and exits with the command's status (128+signal for a signal, 124
# on timeout, 99 without a pty).
# Why wait for quiet, and keep reading meanwhile: the menu's `read -s` changes the
# terminal attributes when it starts, and that change waits for the output the
# program already wrote to be consumed and throws away input that has not been
# read yet. A key sent before then is lost, and a Ctrl-C that lands in the middle
# of it interrupts the attribute change itself and leaves bash stuck. A person
# types long after the menu is drawn; so does this.
import codecs, os, pty, select, signal, sys, time

transcript, wait_for, keys = sys.argv[1], sys.argv[2].encode(), codecs.decode(sys.argv[3], "unicode_escape").encode("latin-1")
command = sys.argv[5:]
timeout = float(os.environ.get("PTY_RUN_TIMEOUT", "600"))
quiet_for = float(os.environ.get("PTY_RUN_QUIET", "1.0"))
try:
    pid, fd = pty.fork()
except OSError as err:
    sys.stderr.write("no pty available: %s\n" % err)
    sys.exit(99)
if pid == 0:
    try:
        os.execvp(command[0], command)
    except OSError as err:
        sys.stderr.write("exec failed: %s\n" % err)
        os._exit(127)

out = bytearray()
sent = False
last_output = time.time()
deadline = time.time() + timeout
timed_out = False
while True:
    now = time.time()
    if now > deadline:
        timed_out = True
        os.kill(pid, signal.SIGKILL)
        break
    if not sent and wait_for in out and now - last_output >= quiet_for:
        os.write(fd, keys)
        sent = True
    ready, _, _ = select.select([fd], [], [], 0.05)
    if not ready:
        continue
    try:
        chunk = os.read(fd, 65536)
    except OSError:
        chunk = b""
    if not chunk:
        break
    out += chunk
    last_output = time.time()
_, status = os.waitpid(pid, 0)
with open(transcript, "wb") as handle:
    handle.write(bytes(out))
if timed_out:
    sys.exit(124)
sys.exit(os.WEXITSTATUS(status) if os.WIFEXITED(status) else 128 + os.WTERMSIG(status))
PY

HAVE_PTY=1
command -v python3 >/dev/null 2>&1 || HAVE_PTY=0

# pty_run <transcript> <wait-for> <keys> <command...> (in the current case's environment)
pty_run() {
  local transcript="$1" wait_for="$2" keys="$3"
  shift 3
  in_case env -u CI TERM=xterm PTY_RUN_TIMEOUT=600 python3 "$TMP/pty-run.py" "$transcript" "$wait_for" "$keys" -- "$@" < /dev/null
}

# ---------------------------------------------------------------------------
echo "[3/5] tools menu keeps the cleanup trap"
MENU_BLOCK="$TMP/menu-block.sh"
awk '
  /^_TOOLS_MENU_NAMES=\(/ { on = 1 }
  on { print }
  on && /^select_tools_menu\(\) \{/ { inside = 1 }
  inside && /^}$/ { exit }
' "$REPO/install.sh" > "$MENU_BLOCK"
check "select_tools_menu and its helpers can be cut out of install.sh" \
  "$(grep -q '^select_tools_menu() {' "$MENU_BLOCK" && grep -q '^_tools_menu_restore() {' "$MENU_BLOCK" && echo 1 || echo 0)"

if [ "$HAVE_PTY" = 0 ]; then
  echo "SKIP  python3 not found: the pseudo-terminal runs ([3/5], [5/5]) are skipped"
elif [ ! -f "$HELPER" ]; then
  check "tools menu: scripts/temp-cleanup.sh exists" 0
else
  # menu_run <name> <keys> <expected-status>: the menu, with one path registered
  # before it and one after it.
  menu_run() {
    local name="$1" keys="$2" expected="$3" rc early late
    new_case "menu-$name"
    cat > "$CASE/driver.sh" <<EOF
set -euo pipefail
. "$HELPER"
trap cleanup_temp_paths EXIT
make_temp EARLY -d
printf '%s\n' "\$EARLY" > "$CASE/early"
INSTALL_SERENA=1; INSTALL_HEADROOM=1; INSTALL_CODEBURN=1
. "$MENU_BLOCK"
select_tools_menu
make_temp LATE -d
printf '%s\n' "\$LATE" > "$CASE/late"
echo "menu returned: serena=\$INSTALL_SERENA headroom=\$INSTALL_HEADROOM codeburn=\$INSTALL_CODEBURN"
exit 0
EOF
    pty_run "$CASE/transcript" "Select companion tools" "$keys" bash "$CASE/driver.sh"
    rc=$?
    if [ "$rc" = 99 ]; then echo "SKIP  no pseudo-terminal on this host: tools menu runs skipped"; return 0; fi
    early="$(cat "$CASE/early" 2>/dev/null)"
    late="$(cat "$CASE/late" 2>/dev/null)"
    check "menu $name: the menu ran on a terminal" "$(yes_if grep -aq 'Select companion tools' "$CASE/transcript")"
    check "menu $name: exit status is $expected" "$([ "$rc" = "$expected" ] && echo 1 || echo 0)"
    check "menu $name: the path registered before the menu is removed" \
      "$([ -n "$early" ] && [ ! -e "$early" ] && echo 1 || echo 0)"
    if [ "$expected" = 0 ]; then
      check "menu $name: the answer was applied (n = no tools)" \
        "$(yes_if grep -aq 'menu returned: serena=0 headroom=0 codeburn=0' "$CASE/transcript")"
      check "menu $name: the path registered after the menu is removed" \
        "$([ -n "$late" ] && [ ! -e "$late" ] && echo 1 || echo 0)"
    fi
    check "menu $name: nothing is left in TMPDIR" "$([ -z "$(ls -A "$CASE/tmp")" ] && echo 1 || echo 0)"
  }
  menu_run confirmed 'n\r' 0
  menu_run "Ctrl-C" '\x03' 130
fi

# ---------------------------------------------------------------------------
# assert_clean <label>: what a finished install must look like.
assert_clean() {
  local label="$1" total=0 outside=0 leaked=0 path
  while IFS= read -r path; do
    [ -n "$path" ] || continue
    total=$((total + 1))
    case "$path" in "$CASE/tmp"/*) ;; *) outside=$((outside + 1)) ;; esac
    if [ -e "$path" ]; then leaked=$((leaked + 1)); echo "      leaked: $path"; fi
  done < "$CASE/mktemp.log"
  check "$label: install.sh made temp paths (the check is not vacuous; $total made)" "$([ "$total" -ge 3 ] && echo 1 || echo 0)"
  check "$label: every temp path was created under TMPDIR" "$([ "$outside" = 0 ] && echo 1 || echo 0)"
  check "$label: every temp path is gone after the install" "$([ "$leaked" = 0 ] && echo 1 || echo 0)"
  check "$label: TMPDIR is empty afterwards" "$([ -z "$(ls -A "$CASE/tmp")" ] && echo 1 || echo 0)"
  check "$label: the default directory of a template-less mktemp is empty too" "$([ -z "$(ls -A "$CASE/decoy")" ] && echo 1 || echo 0)"
  check "$label: the install ran in the throwaway HOME" "$([ -f "$CASE/home/.claude/.my-claude-manifest" ] && echo 1 || echo 0)"
}

echo "[4/5] install.sh --self-only, no terminal"
new_case install-plain
( cd "$REPO" && in_case bash install.sh --self-only ) > "$CASE/install.log" 2>&1 < /dev/null
rc=$?
check "install-plain: install.sh exits 0" "$([ "$rc" = 0 ] && echo 1 || echo 0)"
[ "$rc" = 0 ] || tail -15 "$CASE/install.log"
assert_clean "install-plain"

echo "[5/5] install.sh --self-only under a pseudo-terminal (the tools menu runs)"
if [ "$HAVE_PTY" = 0 ]; then
  echo "SKIP  python3 not found"
else
  new_case install-menu
  pty_run "$CASE/transcript" "Select companion tools" 'n\r' bash -c 'cd "$1" && exec bash install.sh --self-only' _ "$REPO"
  rc=$?
  if [ "$rc" = 99 ]; then
    echo "SKIP  no pseudo-terminal on this host"
  else
    check "install-menu: the tools menu ran inside the install" "$(yes_if grep -aq 'Select companion tools' "$CASE/transcript")"
    check "install-menu: install.sh exits 0" "$([ "$rc" = 0 ] && echo 1 || echo 0)"
    [ "$rc" = 0 ] || tail -c 1500 "$CASE/transcript"
    check "install-menu: no companion tool was installed (n = none)" "$(yes_if grep -aq 'Companion tools: skipped' "$CASE/transcript")"
    assert_clean "install-menu"
  fi
fi

echo ""
if [ "$fail" -eq 1 ]; then
  echo "FAILED"
  exit 1
fi
echo "ALL PASSED"
