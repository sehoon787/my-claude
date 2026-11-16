#!/usr/bin/env bash
#
# upstream-pins.test.sh — install.sh installs gstack and OMC at the versions the
# upstream/gstack and upstream/omc submodules pin, never upstream HEAD or npm
# @latest. `bash tests/upstream-pins.test.sh`
#
# Upstream changes are meant to reach a machine only through the sync PRs that
# bump those pins (scripts/scan-upstream-diff.sh + review). Guards:
#   1. The gstack runtime (~/.gstack/runtime) is checked out at the pinned
#      commit and gstack's ./setup runs once, from it: on a fresh install, and
#      over a runtime an older install cloned from upstream main (ahead of the
#      pin).
#   2. gstack auto_upgrade is never turned on. A true that an older install
#      left in ~/.gstack/config.json is turned off with one line; a value the
#      user set, and gstack's own config.yaml, stay byte-identical.
#   3. The OMC CLI is installed as oh-my-claude-sisyphus@<upstream/omc
#      package.json version>, never @latest, replacing a newer install; nothing
#      is installed when that version is already there; a pinned version npm
#      does not have warns instead of aborting the install.
#   4. The OMC plugin is never refreshed: no `claude plugin update`, `install`
#      or `marketplace update|add|remove`.
#   5. With upstream/gstack and upstream/omc not checked out (submodule init
#      failed, upstream HEAD reachable), gstack's ./setup never runs, the runtime
#      is left alone and npm is never asked for OMC.
#   6. hooks/session-start.sh reports a missing omc instead of installing it
#      from npm @latest.
#
# install.sh runs from a symlink copy of this checkout whose upstream/gstack and
# upstream/omc are small local git repos (a .git file, like a submodule). A
# local repo one commit ahead of the gstack pin stands in for
# github.com/garrytan/gstack (git insteadOf), git may only use local paths
# (GIT_ALLOW_PROTOCOL=file), and npm, claude, bun, curl and the other installers
# are shims. Every run gets `env -i`, a throwaway HOME and a TMPDIR inside it,
# so the real HOME is never read or written. (install.sh replaces its own EXIT
# trap before it removes its mktemp dir, so where `mktemp -d` ignores TMPDIR,
# as on macOS, each run still leaves one small tmp.* dir behind.)
set -uo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

OMC_PIN="1.2.3"      # version in the fake upstream/omc/package.json
OMC_NEWER="9.9.9"    # what the npm shim resolves @latest to
GSTACK_URL="https://github.com/garrytan/gstack"   # init_upstream's clone fallback
GSTACK_GIT_URL="$GSTACK_URL.git"                   # older installs' runtime clone

# git for building fixtures and reading results: no system or user config.
tgit() {
  GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null \
  GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.invalid \
  GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@example.invalid \
    git -c init.defaultBranch=main -c commit.gpgsign=false "$@"
}

# A symlink copy of this checkout with an empty upstream/ of its own.
make_repo() {  # make_repo <dir>
  mkdir -p "$1/upstream"
  for entry in "$REPO"/* "$REPO"/.[!.]*; do
    [ -e "$entry" ] || continue
    case "$(basename "$entry")" in .git|upstream) continue ;; esac
    ln -s "$entry" "$1/$(basename "$entry")"
  done
}

# ── The repo under test, with fake pinned submodules ──
FAKE_REPO="$TMP/repo"
make_repo "$FAKE_REPO"

# upstream/gstack: its ./setup records which tree it ran from.
GSTACK_PIN_REPO="$FAKE_REPO/upstream/gstack"
mkdir -p "$GSTACK_PIN_REPO" "$TMP/modules"
cat > "$GSTACK_PIN_REPO/setup" <<'EOF'
#!/usr/bin/env bash
printf '%s %s\n' "$(cat MARKER)" "$*" >> "$HOME/gstack-setup.log"
EOF
chmod +x "$GSTACK_PIN_REPO/setup"
printf -- '---\nname: gstack\n---\n' > "$GSTACK_PIN_REPO/SKILL.md"
echo pinned > "$GSTACK_PIN_REPO/MARKER"
tgit init -q --separate-git-dir "$TMP/modules/gstack" "$GSTACK_PIN_REPO"
tgit -C "$GSTACK_PIN_REPO" add -A
tgit -C "$GSTACK_PIN_REPO" commit -qm "gstack at the pin"
GSTACK_PIN_SHA="$(tgit -C "$GSTACK_PIN_REPO" rev-parse HEAD)"

# "upstream" gstack: main has moved one commit past the pin.
GSTACK_UPSTREAM="$TMP/gstack-upstream"
tgit clone -q "$GSTACK_PIN_REPO" "$GSTACK_UPSTREAM"
echo upstream-head > "$GSTACK_UPSTREAM/MARKER"
tgit -C "$GSTACK_UPSTREAM" commit -qam "upstream main, past the pin"
GSTACK_HEAD_SHA="$(tgit -C "$GSTACK_UPSTREAM" rev-parse HEAD)"

# upstream/omc: the pinned package.json version, plus one agent for step 1d.
OMC_PIN_REPO="$FAKE_REPO/upstream/omc"
mkdir -p "$OMC_PIN_REPO/agents"
printf '{ "name": "oh-my-claude-sisyphus", "version": "%s" }\n' "$OMC_PIN" > "$OMC_PIN_REPO/package.json"
printf -- '---\nname: omc-test-agent\n---\n' > "$OMC_PIN_REPO/agents/omc-test-agent.md"
tgit init -q --separate-git-dir "$TMP/modules/omc" "$OMC_PIN_REPO"
tgit -C "$OMC_PIN_REPO" add -A
tgit -C "$OMC_PIN_REPO" commit -qm "omc at the pin"

# The same checkout with upstream/gstack and upstream/omc never initialized.
NOPIN_REPO="$TMP/repo-nopin"
make_repo "$NOPIN_REPO"
mkdir -p "$NOPIN_REPO/upstream/gstack" "$NOPIN_REPO/upstream/omc"

# Every check below compares against these, so a broken fixture must stop here
# rather than let two empty strings compare equal.
if [ -z "$GSTACK_PIN_SHA" ] || [ -z "$GSTACK_HEAD_SHA" ] || [ "$GSTACK_PIN_SHA" = "$GSTACK_HEAD_SHA" ] \
   || [ ! -f "$GSTACK_PIN_REPO/.git" ] || [ ! -f "$OMC_PIN_REPO/.git" ]; then
  echo "FAIL  fixture setup (pin '$GSTACK_PIN_SHA', upstream head '$GSTACK_HEAD_SHA')"
  exit 1
fi

# ── Shims ──
SHIM="$TMP/shim"
TOOLS="$TMP/tools"
mkdir -p "$SHIM" "$TOOLS"
# The only real tools install.sh gets beyond the system directories — linked one
# by one, because node's own bin directory usually holds a real omc as well.
ln -s "$(node -p process.execPath)" "$TOOLS/node"
ln -s "$(command -v git)" "$TOOLS/git"

# npm: the global prefix lives at $NPM_SHIM_ROOT. `npm i -g` of
# oh-my-claude-sisyphus installs a version only if $NPM_SHIM_PUBLISHED lists
# it (@latest is $NPM_SHIM_LATEST); every other package is a no-op.
cat > "$SHIM/npm" <<'EOF'
#!/usr/bin/env bash
echo "npm $*" >> "$SHIM_LOG"
case "${1:-}" in
  root) echo "$NPM_SHIM_ROOT/lib/node_modules"; exit 0 ;;
  view) [ "${2:-}" = oh-my-claude-sisyphus ] && [ "${3:-}" = version ] && echo "$NPM_SHIM_LATEST"; exit 0 ;;
  i|install) ;;
  *) exit 0 ;;
esac
for spec in "$@"; do
  case "$spec" in oh-my-claude-sisyphus@*) ;; *) continue ;; esac
  ver="${spec#oh-my-claude-sisyphus@}"
  [ "$ver" = latest ] && ver="$NPM_SHIM_LATEST"
  case " $NPM_SHIM_PUBLISHED " in
    *" $ver "*) ;;
    *) echo "npm error notarget No matching version found for $spec." >&2; exit 1 ;;
  esac
  pkg="$NPM_SHIM_ROOT/lib/node_modules/oh-my-claude-sisyphus"
  mkdir -p "$pkg/dist/hud" "$NPM_SHIM_ROOT/bin"
  printf '{ "name": "oh-my-claude-sisyphus", "version": "%s" }\n' "$ver" > "$pkg/package.json"
  echo "// hud" > "$pkg/dist/hud/index.js"
  printf '#!/usr/bin/env bash\n[ "${1:-}" = --version ] && echo "oh-my-claudecode v%s"\nexit 0\n' "$ver" > "$NPM_SHIM_ROOT/bin/omc"
  chmod +x "$NPM_SHIM_ROOT/bin/omc"
done
exit 0
EOF
# claude: lists the OMC plugin as installed; every call is logged.
cat > "$SHIM/claude" <<'EOF'
#!/usr/bin/env bash
echo "claude $*" >> "$SHIM_LOG"
if [ "${1:-}" = plugin ] && [ "${2:-}" = list ]; then
  printf 'Installed plugins:\n\n  > oh-my-claudecode@omc\n    Version: %s\n    Scope: user\n    Status: enabled\n' "$NPM_SHIM_LATEST"
fi
exit 0
EOF
# bun only has to exist for install.sh to run the runtime's ./setup.
printf '#!/usr/bin/env bash\nexit 0\n' > "$SHIM/bun"
printf '#!/usr/bin/env bash\necho "tmux 3.4"\n' > "$SHIM/tmux"
# Anything that would download or install for real fails.
for tool in curl uv brew sudo; do printf '#!/usr/bin/env bash\nexit 1\n' > "$SHIM/$tool"; done
chmod +x "$SHIM"/*

# Environment for a run against throwaway HOME $1, with npm offering the
# versions in $2. Both gstack URLs lead to the local "upstream" repo (git uses
# the longest matching insteadOf).
run_env() {
  local home="$1" published="$2"
  mkdir -p "$home/tmp"
  env -i HOME="$home" TMPDIR="$home/tmp" \
    PATH="$SHIM:$home/npm-global/bin:$TOOLS:/usr/bin:/bin:/usr/sbin:/sbin" \
    SHIM_LOG="$home/shim.log" NPM_SHIM_ROOT="$home/npm-global" \
    NPM_SHIM_PUBLISHED="$published" NPM_SHIM_LATEST="$OMC_NEWER" \
    AGENT_HARNESS_SERVICES_SKIP=1 \
    GIT_CONFIG_NOSYSTEM=1 GIT_ALLOW_PROTOCOL=file \
    GIT_CONFIG_COUNT=2 \
    GIT_CONFIG_KEY_0="url.$GSTACK_UPSTREAM.insteadOf" GIT_CONFIG_VALUE_0="$GSTACK_GIT_URL" \
    GIT_CONFIG_KEY_1="url.$GSTACK_UPSTREAM.insteadOf" GIT_CONFIG_VALUE_1="$GSTACK_URL" \
    "${@:3}"
}
run_install() {  # run_install <home> <published versions> [repo]
  ( cd "${3:-$FAKE_REPO}" && run_env "$1" "$2" "$BASH" install.sh \
      --skip-ecc --skip-superpowers --skip-archify --skip-tools ) \
    > "$1/install.log" 2>&1 < /dev/null
}
# Put OMC <version> into <home>'s npm prefix, as an earlier install left it.
seed_omc() {  # seed_omc <home> <version>
  run_env "$1" "$2" "$SHIM/npm" i -g "oh-my-claude-sisyphus@$2" > /dev/null 2>&1
  : > "$1/shim.log"
}
# A runtime as older installs left it: a clone of upstream main, ahead of the pin.
seed_runtime() {  # seed_runtime <home>
  tgit clone -q "$GSTACK_UPSTREAM" "$1/.gstack/runtime"
  tgit -C "$1/.gstack/runtime" remote set-url origin "$GSTACK_GIT_URL"
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
yes_if() { if "$@"; then echo 1; else echo 0; fi; }
not() { ! "$@"; }
runtime_head() { tgit -C "$1/.gstack/runtime" rev-parse HEAD 2>/dev/null; }
setup_runs() { cat "$1/gstack-setup.log" 2>/dev/null; }
omc_version() { node -p "require(process.argv[1]).version" "$1/npm-global/lib/node_modules/oh-my-claude-sisyphus/package.json" 2>/dev/null; }
auto_upgrade() { node -p "JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8')).auto_upgrade" "$1/.gstack/config.json" 2>/dev/null; }
logged() { grep -qF -- "$2" "$1/shim.log" 2>/dev/null; }
no_plugin_refresh() {
  not grep -Eq '^claude plugin (update|install|marketplace (update|add|remove))' "$1/shim.log"
}
user_gstack_intact() {
  [ "$(cat "$1/.claude/skills/gstack/VERSION" 2>/dev/null)" = user-owned ] && [ -d "$1/.claude/skills/gstack/.git" ]
}
install_ok() {
  if [ "$2" -ne 0 ]; then
    echo "FAIL  install.sh exited $2 ($3)"
    tail -20 "$1/install.log"
    fail=1
  fi
}

echo "[1/6] fresh install"
H="$TMP/home-fresh"; mkdir -p "$H"
run_install "$H" "$OMC_PIN $OMC_NEWER"; install_ok "$H" $? "fresh install"
check "gstack runtime checked out at the pin"             "$(yes_if [ "$(runtime_head "$H")" = "$GSTACK_PIN_SHA" ])"
check "gstack ./setup ran once, from the pinned tree"     "$(yes_if [ "$(setup_runs "$H")" = "pinned --host claude" ])"
check "no gstack config.json written (auto_upgrade off)"  "$(yes_if [ ! -e "$H/.gstack/config.json" ])"
check "npm installs oh-my-claude-sisyphus@$OMC_PIN"       "$(yes_if logged "$H" "npm i -g oh-my-claude-sisyphus@$OMC_PIN")"
check "npm never asked for oh-my-claude-sisyphus@latest"  "$(yes_if not logged "$H" "oh-my-claude-sisyphus@latest")"
check "OMC CLI installed at the pin"                      "$(yes_if [ "$(omc_version "$H")" = "$OMC_PIN" ])"
check "OMC plugin not refreshed or reinstalled"           "$(yes_if no_plugin_refresh "$H")"

echo "[2/6] update over an older install (runtime on upstream main, auto_upgrade on, newer OMC)"
H="$TMP/home-update"; mkdir -p "$H/.gstack"
seed_runtime "$H"
mkdir -p "$H/.gstack/runtime/browse/dist"
echo built > "$H/.gstack/runtime/browse/dist/browse"
printf '{\n  "auto_upgrade": true\n}' > "$H/.gstack/config.json"
seed_omc "$H" "$OMC_NEWER"
# A global gstack install the user owns.
mkdir -p "$H/.claude/skills/gstack/.git"
echo user-owned > "$H/.claude/skills/gstack/VERSION"
run_install "$H" "$OMC_PIN $OMC_NEWER"; install_ok "$H" $? "update"
check "gstack runtime moved back from upstream main to the pin" "$(yes_if [ "$(runtime_head "$H")" = "$GSTACK_PIN_SHA" ])"
check "gstack ./setup ran once, from the pinned tree"     "$(yes_if [ "$(setup_runs "$H")" = "pinned --host claude" ])"
check "runtime build output kept (browse/dist)"           "$(yes_if [ -f "$H/.gstack/runtime/browse/dist/browse" ])"
check "auto_upgrade=true from an older install turned off" "$(yes_if [ "$(auto_upgrade "$H")" = "false" ])"
check "exactly one line reports it"                       "$(yes_if [ "$(grep -c 'auto_upgrade' "$H/install.log")" = "1" ])"
check "newer OMC CLI replaced by oh-my-claude-sisyphus@$OMC_PIN" "$(yes_if logged "$H" "npm i -g oh-my-claude-sisyphus@$OMC_PIN")"
check "OMC CLI now at the pin"                            "$(yes_if [ "$(omc_version "$H")" = "$OMC_PIN" ])"
check "OMC plugin not refreshed or reinstalled"           "$(yes_if no_plugin_refresh "$H")"
check "user-owned global gstack install keeps its files"  "$(yes_if user_gstack_intact "$H")"

echo "[3/6] user-set auto_upgrade values and an install already at the pins"
H="$TMP/home-user"; mkdir -p "$H/.gstack"
seed_runtime "$H"
printf '{"auto_upgrade": false, "note": "mine"}\n' > "$H/.gstack/config.json"
printf 'auto_upgrade: true\n' > "$H/.gstack/config.yaml"
cp "$H/.gstack/config.json" "$TMP/user-config.json"
cp "$H/.gstack/config.yaml" "$TMP/user-config.yaml"
seed_omc "$H" "$OMC_PIN"
run_install "$H" "$OMC_PIN $OMC_NEWER"; install_ok "$H" $? "user values"
check "user's config.json left byte-identical"           "$(yes_if cmp -s "$H/.gstack/config.json" "$TMP/user-config.json")"
check "gstack's own config.yaml left byte-identical"      "$(yes_if cmp -s "$H/.gstack/config.yaml" "$TMP/user-config.yaml")"
check "no auto_upgrade line printed"                      "$(yes_if [ "$(grep -c 'auto_upgrade' "$H/install.log")" = "0" ])"
check "OMC already at the pin: npm installs nothing for it" "$(yes_if not logged "$H" "oh-my-claude-sisyphus@")"
check "gstack runtime at the pin"                         "$(yes_if [ "$(runtime_head "$H")" = "$GSTACK_PIN_SHA" ])"

echo "[4/6] pinned OMC version not on npm"
H="$TMP/home-unpublished"; mkdir -p "$H"
run_install "$H" "$OMC_NEWER"; install_ok "$H" $? "unpublished pin"
check "install.sh carries on past the npm failure"        "$(yes_if grep -q 'Install complete' "$H/install.log")"
check "warning names oh-my-claude-sisyphus@$OMC_PIN"      "$(yes_if grep -q "WARNING: npm could not install oh-my-claude-sisyphus@$OMC_PIN" "$H/install.log")"
check "no fallback to oh-my-claude-sisyphus@latest"       "$(yes_if not logged "$H" "oh-my-claude-sisyphus@latest")"
check "no OMC CLI past the pin installed"                 "$(yes_if [ -z "$(omc_version "$H")" ])"

echo "[5/6] upstream/gstack and upstream/omc not checked out (upstream HEAD reachable)"
H="$TMP/home-nopin"; mkdir -p "$H/.gstack"
seed_runtime "$H"
run_install "$H" "$OMC_PIN $OMC_NEWER" "$NOPIN_REPO"; install_ok "$H" $? "no pins"
check "gstack ./setup never ran"                          "$(yes_if [ ! -e "$H/gstack-setup.log" ])"
check "existing runtime left where it was"                "$(yes_if [ "$(runtime_head "$H")" = "$GSTACK_HEAD_SHA" ])"
check "warning says the runtime was not updated"          "$(yes_if grep -q 'upstream/gstack is not checked out' "$H/install.log")"
check "npm never asked for oh-my-claude-sisyphus"         "$(yes_if not logged "$H" "oh-my-claude-sisyphus@")"
check "warning says the OMC pin is unknown"               "$(yes_if grep -q 'pinned OMC version is unknown' "$H/install.log")"

echo "[6/6] session-start hook with omc missing"
H="$TMP/home-hook"; mkdir -p "$H" "$TMP/project"
( cd "$TMP/project" && run_env "$H" "$OMC_PIN $OMC_NEWER" "$BASH" "$REPO/hooks/session-start.sh" ) \
  > "$H/hook.out" 2>&1 < /dev/null
check "hook never installs oh-my-claude-sisyphus from npm" "$(yes_if not logged "$H" "oh-my-claude-sisyphus")"
check "hook reports omc missing (run install.sh)"         "$(yes_if grep -Eq 'Missing \(run install\.sh\):[^.]* omc[ .]' "$H/hook.out")"

if [ "$fail" -eq 0 ]; then
  echo "ALL PASSED"
else
  echo "FAILED"
fi
exit "$fail"
