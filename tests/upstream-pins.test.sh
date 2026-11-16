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
#      over a runtime an older install cloned from upstream main.
#   2. gstack auto_upgrade is never turned on. A true that an older install
#      left in ~/.gstack/config.json is turned off with one line; a value the
#      user set, and gstack's own config.yaml, stay byte-identical.
#   3. The OMC CLI is the version upstream/omc's package.json pins when npm has
#      it, otherwise the newest published version below it (compared per
#      numeric field, prereleases ignored unless they are the pin). Never
#      @latest or anything above the pin; nothing is installed when npm cannot
#      be read or the resolved version is already there.
#   4. The OMC plugin is never refreshed: no `claude plugin update`, `install`
#      or `marketplace update|add|remove`.
#   5. When submodule init fails, the fallback fetches the commit this checkout
#      records, not the upstream default branch; with no recorded commit the
#      upstream is skipped. The gstack runtime is only ever built from the
#      recorded commit, taken from the local submodule: a clone that stopped at
#      upstream's tip, or a checkout behind the recorded commit, never reaches
#      ./setup. The warnings say what is left in ~/.gstack/runtime.
#   6. A submodule checkout that differs from the recorded commit is reported.
#   7. A broken ~/.gstack/runtime/.git never resolves to an enclosing repository
#      (here a HOME kept under git), and neither an exported GIT_WORK_TREE nor
#      a core.worktree left in the runtime's .git receives its checkout or a
#      fallback checkout.
#   8. hooks/session-start.sh reports a missing omc instead of installing it
#      from npm @latest.
#
# install.sh runs from a symlink copy of this checkout whose upstream/gstack and
# upstream/omc are small local git repos (a .git file, like a submodule), with
# the commits recorded in the copy's index. A local repo one commit ahead of the
# gstack pin stands in for github.com/garrytan/gstack (git insteadOf), git may
# only use local paths (GIT_ALLOW_PROTOCOL=file), and npm, claude, bun, curl,
# mktemp and the other installers are shims. Every run gets `env -i`, a
# throwaway HOME and a TMPDIR inside the test's temp dir, so nothing is left
# behind and the real HOME is never read or written.
set -uo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

OMC_PIN="1.2.3"      # version in the fake upstream/omc/package.json
OMC_NEWER="9.9.9"    # a release above the pin
GSTACK_URL="https://github.com/garrytan/gstack"   # init_upstream's clone fallback
GSTACK_GIT_URL="$GSTACK_URL.git"                   # older installs' runtime clone

# git for building fixtures and reading results: no system or user config.
tgit() {
  GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null \
  GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.invalid \
  GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@example.invalid \
    git -c init.defaultBranch=main -c commit.gpgsign=false "$@"
}
# Record <sha> as the commit <repo> pins for submodule <path>.
record() { tgit -C "$1" update-index --add --cacheinfo "160000,$2,$3"; }

# A symlink copy of this checkout with an empty upstream/ of its own.
make_repo() {  # make_repo <dir>
  mkdir -p "$1/upstream"
  for entry in "$REPO"/* "$REPO"/.[!.]*; do
    [ -e "$entry" ] || continue
    case "$(basename "$entry")" in .git|upstream) continue ;; esac
    ln -s "$entry" "$1/$(basename "$entry")"
  done
}

# ── Fixtures ──
mkdir -p "$TMP/modules"
FAKE_REPO="$TMP/repo"
make_repo "$FAKE_REPO"

# upstream/gstack: its ./setup records which tree it ran from.
GSTACK_PIN_REPO="$FAKE_REPO/upstream/gstack"
mkdir -p "$GSTACK_PIN_REPO"
cat > "$GSTACK_PIN_REPO/setup" <<'EOF'
#!/usr/bin/env bash
printf '%s %s\n' "$(cat MARKER)" "$*" >> "$HOME/gstack-setup.log"
EOF
chmod +x "$GSTACK_PIN_REPO/setup"
printf -- '---\nname: gstack\n---\npinned\n' > "$GSTACK_PIN_REPO/SKILL.md"
echo pinned > "$GSTACK_PIN_REPO/MARKER"
tgit init -q --separate-git-dir "$TMP/modules/gstack" "$GSTACK_PIN_REPO"
tgit -C "$GSTACK_PIN_REPO" add -A
tgit -C "$GSTACK_PIN_REPO" commit -qm "gstack at the pin"
GSTACK_PIN_SHA="$(tgit -C "$GSTACK_PIN_REPO" rev-parse HEAD)"

# "upstream" gstack: main has moved one commit past the pin.
GSTACK_UPSTREAM="$TMP/gstack-upstream"
tgit clone -q "$GSTACK_PIN_REPO" "$GSTACK_UPSTREAM"
echo upstream-head > "$GSTACK_UPSTREAM/MARKER"
printf -- '---\nname: gstack\n---\nupstream-head\n' > "$GSTACK_UPSTREAM/SKILL.md"
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
OMC_PIN_SHA="$(tgit -C "$OMC_PIN_REPO" rev-parse HEAD)"
# A later OMC commit, for a superproject that has moved past its checkout.
OMC_UPSTREAM="$TMP/omc-upstream"
tgit clone -q "$OMC_PIN_REPO" "$OMC_UPSTREAM"
echo "# later" >> "$OMC_UPSTREAM/agents/omc-test-agent.md"
tgit -C "$OMC_UPSTREAM" commit -qam "omc past the pin"
OMC_HEAD_SHA="$(tgit -C "$OMC_UPSTREAM" rev-parse HEAD)"

# The copy is a git checkout that records both pins, as this repo does.
tgit init -q "$FAKE_REPO"
record "$FAKE_REPO" "$GSTACK_PIN_SHA" upstream/gstack
record "$FAKE_REPO" "$OMC_PIN_SHA" upstream/omc

# Recorded pins, submodules never initialized and no .gitmodules: submodule
# init fails ("No url found"), so init_upstream takes its clone fallback.
UNINIT_REPO="$TMP/repo-uninit"
make_repo "$UNINIT_REPO"
rm -f "$UNINIT_REPO/.gitmodules"
mkdir -p "$UNINIT_REPO/upstream/gstack" "$UNINIT_REPO/upstream/omc"
tgit init -q "$UNINIT_REPO"
record "$UNINIT_REPO" "$GSTACK_PIN_SHA" upstream/gstack
record "$UNINIT_REPO" "$OMC_PIN_SHA" upstream/omc

# Not a git checkout at all (an extracted archive): no recorded commits.
NOPIN_REPO="$TMP/repo-nopin"
make_repo "$NOPIN_REPO"
mkdir -p "$NOPIN_REPO/upstream/gstack" "$NOPIN_REPO/upstream/omc"

# An upstream whose history no longer holds the recorded commit, only a newer
# tip (a rewritten branch). This copy keeps the real .gitmodules, and the run
# points github.com/garrytan/gstack at this repo: `git submodule update` clones
# the tip, cannot fetch the recorded commit and stops, leaving
# upstream/gstack/.git at the unscanned tip with no files checked out.
GSTACK_TIP_ONLY="$TMP/gstack-tip-only"
mkdir -p "$GSTACK_TIP_ONLY"
cp "$GSTACK_PIN_REPO/setup" "$GSTACK_TIP_ONLY/setup"
chmod +x "$GSTACK_TIP_ONLY/setup"
echo upstream-tip > "$GSTACK_TIP_ONLY/MARKER"
printf -- '---\nname: gstack\n---\nupstream-tip\n' > "$GSTACK_TIP_ONLY/SKILL.md"
tgit init -q "$GSTACK_TIP_ONLY"
tgit -C "$GSTACK_TIP_ONLY" add -A
tgit -C "$GSTACK_TIP_ONLY" commit -qm "rewritten upstream tip"
GSTACK_TIP_SHA="$(tgit -C "$GSTACK_TIP_ONLY" rev-parse HEAD)"
TIPCLONE_REPO="$TMP/repo-tip-clone"
make_repo "$TIPCLONE_REPO"
mkdir -p "$TIPCLONE_REPO/upstream/gstack"
tgit init -q "$TIPCLONE_REPO"
record "$TIPCLONE_REPO" "$GSTACK_PIN_SHA" upstream/gstack

# upstream/gstack moved past the recorded commit (`git submodule update
# --remote`): checked out at upstream main, with the recorded commit still in
# its history.
AHEAD_REPO="$TMP/repo-ahead"
make_repo "$AHEAD_REPO"
tgit clone -q "$GSTACK_UPSTREAM" "$AHEAD_REPO/upstream/gstack"
tgit init -q "$AHEAD_REPO"
record "$AHEAD_REPO" "$GSTACK_PIN_SHA" upstream/gstack

# Every check below compares against these, so a broken fixture must stop here
# rather than let two empty strings compare equal.
if [ -z "$GSTACK_PIN_SHA" ] || [ -z "$GSTACK_HEAD_SHA" ] || [ "$GSTACK_PIN_SHA" = "$GSTACK_HEAD_SHA" ] \
   || [ -z "$OMC_PIN_SHA" ] || [ -z "$OMC_HEAD_SHA" ] || [ -z "$GSTACK_TIP_SHA" ] \
   || [ "$(tgit -C "$AHEAD_REPO/upstream/gstack" rev-parse HEAD)" != "$GSTACK_HEAD_SHA" ] \
   || [ ! -f "$GSTACK_PIN_REPO/.git" ] || [ ! -f "$OMC_PIN_REPO/.git" ] \
   || [ "$(tgit -C "$FAKE_REPO" rev-parse -q --verify :upstream/gstack)" != "$GSTACK_PIN_SHA" ]; then
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

# mktemp: install.sh calls it bare; macOS then ignores TMPDIR, and install.sh's
# own cleanup trap is replaced before it runs. A template inside TMPDIR keeps
# those directories under this test's temp dir.
cat > "$SHIM/mktemp" <<EOF
#!/usr/bin/env bash
for arg in "\$@"; do
  case "\$arg" in -*) ;; *) exec "$(command -v mktemp)" "\$@" ;; esac
done
exec "$(command -v mktemp)" "\$@" "\${TMPDIR:-/tmp}/tmp.XXXXXXXXXX"
EOF

# npm: the global prefix lives at $NPM_SHIM_ROOT. `npm view … versions --json`
# lists $NPM_SHIM_PUBLISHED; `npm i -g oh-my-claude-sisyphus@<v>` installs <v>
# only if it is listed (@latest is the last one listed); every other package is
# a no-op. NPM_SHIM_REGISTRY_DOWN=1 makes every oh-my-claude-sisyphus view and
# install fail like an unreachable registry; other packages keep working, so
# only step [5b] sees the outage.
cat > "$SHIM/npm" <<'EOF'
#!/usr/bin/env bash
echo "npm $*" >> "$SHIM_LOG"
omc=""
for arg in "$@"; do
  case "$arg" in oh-my-claude-sisyphus|oh-my-claude-sisyphus@*) omc=1 ;; esac
done
case "${1:-}" in
  root) echo "$NPM_SHIM_ROOT/lib/node_modules"; exit 0 ;;
  view|i|install) [ -n "$omc" ] || exit 0 ;;
  *) exit 0 ;;
esac
if [ -n "${NPM_SHIM_REGISTRY_DOWN:-}" ]; then
  echo '{"error":{"code":"ENOTFOUND","summary":"request to https://registry.npmjs.org failed"}}'
  echo "npm error code ENOTFOUND" >&2
  exit 1
fi
if [ "$1" = view ]; then
  case "${3:-}" in
    versions)
      out="["; sep=""
      for v in $NPM_SHIM_PUBLISHED; do out="$out$sep\"$v\""; sep=","; done
      echo "$out]" ;;
  esac
  exit 0
fi
for spec in "$@"; do
  case "$spec" in oh-my-claude-sisyphus@*) ;; *) continue ;; esac
  ver="${spec#oh-my-claude-sisyphus@}"
  [ "$ver" = latest ] && ver="${NPM_SHIM_PUBLISHED##* }"
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
  printf 'Installed plugins:\n\n  > oh-my-claudecode@omc\n    Version: %s\n    Scope: user\n    Status: enabled\n' "${NPM_SHIM_PUBLISHED##* }"
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
# versions in $2 (NPM_DOWN=1 makes the registry unreachable). Both gstack URLs
# lead to $GSTACK_REMOTE, the local "upstream" repo unless a scenario swaps it
# (git uses the longest matching insteadOf). GIT_WORK_TREE_EXPORT, when set, is
# exported to the run as GIT_WORK_TREE.
NPM_DOWN=""
GSTACK_REMOTE="$GSTACK_UPSTREAM"
GIT_WORK_TREE_EXPORT=""
run_env() {
  local home="$1" published="$2"
  mkdir -p "$home/tmp"
  env -i HOME="$home" TMPDIR="$home/tmp" \
    PATH="$SHIM:$home/npm-global/bin:$TOOLS:/usr/bin:/bin:/usr/sbin:/sbin" \
    SHIM_LOG="$home/shim.log" NPM_SHIM_ROOT="$home/npm-global" \
    NPM_SHIM_PUBLISHED="$published" NPM_SHIM_REGISTRY_DOWN="$NPM_DOWN" \
    AGENT_HARNESS_SERVICES_SKIP=1 \
    GIT_CONFIG_NOSYSTEM=1 GIT_ALLOW_PROTOCOL=file \
    GIT_CONFIG_COUNT=2 \
    GIT_CONFIG_KEY_0="url.$GSTACK_REMOTE.insteadOf" GIT_CONFIG_VALUE_0="$GSTACK_GIT_URL" \
    GIT_CONFIG_KEY_1="url.$GSTACK_REMOTE.insteadOf" GIT_CONFIG_VALUE_1="$GSTACK_URL" \
    ${GIT_WORK_TREE_EXPORT:+"GIT_WORK_TREE=$GIT_WORK_TREE_EXPORT"} \
    "${@:3}"
}
INSTALL_RC=0
run_install() {  # run_install <home> <published versions> <repo> [install.sh flags...]
  local home="$1" published="$2" repo="$3"
  shift 3
  ( cd "$repo" && run_env "$home" "$published" "$BASH" install.sh \
      --skip-ecc --skip-superpowers --skip-archify --skip-tools "$@" ) \
    > "$home/install.log" 2>&1 < /dev/null
  INSTALL_RC=$?
  if [ "$INSTALL_RC" -ne 0 ]; then
    echo "FAIL  install.sh exited $INSTALL_RC ($home)"
    tail -20 "$home/install.log"
    fail=1
  fi
}
# Put OMC <version> into <home>'s npm prefix, as an earlier install left it.
seed_omc() {  # seed_omc <home> <version>
  NPM_DOWN="" run_env "$1" "$2" "$SHIM/npm" i -g "oh-my-claude-sisyphus@$2" > /dev/null 2>&1
  : > "$1/shim.log"
}
# A runtime as older installs left it: a clone of upstream main, ahead of the pin.
seed_runtime() {  # seed_runtime <home>
  tgit clone -q "$GSTACK_UPSTREAM" "$1/.gstack/runtime"
  tgit -C "$1/.gstack/runtime" remote set-url origin "$GSTACK_GIT_URL"
}
set_omc_pin() {  # set_omc_pin <version>
  printf '{ "name": "oh-my-claude-sisyphus", "version": "%s" }\n' "$1" > "$OMC_PIN_REPO/package.json"
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
in_log() { grep -qF -- "$2" "$1/install.log"; }
no_plugin_refresh() {
  not grep -Eq '^claude plugin (update|install|marketplace (update|add|remove))' "$1/shim.log"
}
user_gstack_intact() {
  [ "$(cat "$1/.claude/skills/gstack/VERSION" 2>/dev/null)" = user-owned ] && [ -d "$1/.claude/skills/gstack/.git" ]
}
# Step [5b] of install.log: from "[5b] OMC CLI" up to the next step.
omc_step() { awk '/\[5b\] OMC CLI/ { on = 1 } /\[5c\]/ { on = 0 } on' "$1/install.log"; }
omc_warnings() { omc_step "$1" | grep -c 'WARNING'; }
omc_installs() { { grep -E '^npm (i|install) .*oh-my-claude-sisyphus@' "$1/shim.log" 2>/dev/null || true; } | wc -l | tr -d ' '; }
installed_only() { [ "$(omc_installs "$1")" = 1 ] && logged "$1" "npm i -g oh-my-claude-sisyphus@$2" && [ "$(omc_version "$1")" = "$2" ]; }

echo "[1/11] fresh install"
H="$TMP/home-fresh"; mkdir -p "$H"
run_install "$H" "$OMC_PIN $OMC_NEWER" "$FAKE_REPO"
check "gstack runtime checked out at the pin"             "$(yes_if [ "$(runtime_head "$H")" = "$GSTACK_PIN_SHA" ])"
check "gstack ./setup ran once, from the pinned tree"     "$(yes_if [ "$(setup_runs "$H")" = "pinned --host claude" ])"
check "no gstack config.json written (auto_upgrade off)"  "$(yes_if [ ! -e "$H/.gstack/config.json" ])"
check "npm installs oh-my-claude-sisyphus@$OMC_PIN"       "$(yes_if logged "$H" "npm i -g oh-my-claude-sisyphus@$OMC_PIN")"
check "npm never asked for oh-my-claude-sisyphus@latest"  "$(yes_if not logged "$H" "oh-my-claude-sisyphus@latest")"
check "OMC CLI installed at the pin"                      "$(yes_if [ "$(omc_version "$H")" = "$OMC_PIN" ])"
check "OMC plugin not refreshed or reinstalled"           "$(yes_if no_plugin_refresh "$H")"
check "checkouts at the recorded commits: no sync warning" "$(yes_if not in_log "$H" "is checked out at")"

echo "[2/11] update over an older install (runtime on upstream main, auto_upgrade on, newer OMC)"
H="$TMP/home-update"; mkdir -p "$H/.gstack"
seed_runtime "$H"
mkdir -p "$H/.gstack/runtime/browse/dist"
echo built > "$H/.gstack/runtime/browse/dist/browse"
printf '{\n  "auto_upgrade": true\n}' > "$H/.gstack/config.json"
seed_omc "$H" "$OMC_NEWER"
# A global gstack install the user owns.
mkdir -p "$H/.claude/skills/gstack/.git"
echo user-owned > "$H/.claude/skills/gstack/VERSION"
run_install "$H" "$OMC_PIN $OMC_NEWER" "$FAKE_REPO"
check "gstack runtime moved back from upstream main to the pin" "$(yes_if [ "$(runtime_head "$H")" = "$GSTACK_PIN_SHA" ])"
check "gstack ./setup ran once, from the pinned tree"     "$(yes_if [ "$(setup_runs "$H")" = "pinned --host claude" ])"
check "runtime build output kept (browse/dist)"           "$(yes_if [ -f "$H/.gstack/runtime/browse/dist/browse" ])"
check "auto_upgrade=true from an older install turned off" "$(yes_if [ "$(auto_upgrade "$H")" = "false" ])"
check "exactly one line reports it"                       "$(yes_if [ "$(grep -c 'auto_upgrade' "$H/install.log")" = "1" ])"
check "newer OMC CLI replaced by oh-my-claude-sisyphus@$OMC_PIN" "$(yes_if logged "$H" "npm i -g oh-my-claude-sisyphus@$OMC_PIN")"
check "OMC CLI now at the pin"                            "$(yes_if [ "$(omc_version "$H")" = "$OMC_PIN" ])"
check "OMC plugin not refreshed or reinstalled"           "$(yes_if no_plugin_refresh "$H")"
check "user-owned global gstack install keeps its files"  "$(yes_if user_gstack_intact "$H")"

echo "[3/11] user-set auto_upgrade values and an install already at the pins"
H="$TMP/home-user"; mkdir -p "$H/.gstack"
seed_runtime "$H"
printf '{"auto_upgrade": false, "note": "mine"}\n' > "$H/.gstack/config.json"
printf 'auto_upgrade: true\n' > "$H/.gstack/config.yaml"
cp "$H/.gstack/config.json" "$TMP/user-config.json"
cp "$H/.gstack/config.yaml" "$TMP/user-config.yaml"
seed_omc "$H" "$OMC_PIN"
run_install "$H" "$OMC_PIN $OMC_NEWER" "$FAKE_REPO"
check "user's config.json left byte-identical"           "$(yes_if cmp -s "$H/.gstack/config.json" "$TMP/user-config.json")"
check "gstack's own config.yaml left byte-identical"      "$(yes_if cmp -s "$H/.gstack/config.yaml" "$TMP/user-config.yaml")"
check "no auto_upgrade line printed"                      "$(yes_if [ "$(grep -c 'auto_upgrade' "$H/install.log")" = "0" ])"
check "OMC already at the pin: npm installs nothing for it" "$(yes_if not logged "$H" "oh-my-claude-sisyphus@")"
check "gstack runtime at the pin"                         "$(yes_if [ "$(runtime_head "$H")" = "$GSTACK_PIN_SHA" ])"

echo "[4/11] OMC version: the pin, or the newest published version below it"
omc_case() {  # omc_case <name> <pin> <published versions> [installed version]
  H="$TMP/home-omc-$1"; mkdir -p "$H"
  set_omc_pin "$2"
  if [ -n "${4:-}" ]; then seed_omc "$H" "$4"; fi
  run_install "$H" "$3" "$FAKE_REPO" --skip-gstack
}
omc_case published 5.8.10 "5.8.2 5.8.9 5.8.10 5.9.0"
check "pin on npm: installs exactly 5.8.10"               "$(yes_if installed_only "$H" 5.8.10)"
check "pin on npm: no info or WARNING line"               "$(yes_if [ "$(omc_step "$H" | grep -cE 'WARNING|not on npm yet')" = 0 ])"
omc_case unpublished 5.8.10 "5.8.2 5.8.9 5.9.0"
check "pin not on npm: newest version below it (5.8.9, not 5.8.2)" "$(yes_if installed_only "$H" 5.8.9)"
check "never above the pin, even when it is latest (5.9.0)" "$(yes_if not logged "$H" "oh-my-claude-sisyphus@5.9.0")"
check "never @latest"                                     "$(yes_if not logged "$H" "oh-my-claude-sisyphus@latest")"
check "one info line names the pin and the version used"  "$(yes_if [ "$(omc_step "$H" | grep -c 'OMC 5.8.10 (pinned) is not on npm yet; using 5.8.9, the newest published version not above the pin')" = 1 ])"
check "no WARNING for a pin npm does not have yet"        "$(yes_if [ "$(omc_warnings "$H")" = 0 ])"
check "plugin cache synced for the version installed"    "$(yes_if [ -d "$H/.claude/plugins/cache/omc/oh-my-claudecode/5.8.9/dist" ])"
omc_case order 5.9.0 "5.8.9 5.8.10 5.8.11-beta.1 5.9.1 5.10.0"
check "numeric order: 5.8.10 over 5.8.9, 5.10.0 above 5.9.0, prerelease ignored" "$(yes_if installed_only "$H" 5.8.10)"
omc_case prerelease-pin 5.9.0-rc.1 "5.8.10 5.9.0-rc.1 5.9.0"
check "a prerelease that is the pin itself is used"       "$(yes_if installed_only "$H" 5.9.0-rc.1)"
omc_case installed 5.8.10 "5.8.2 5.8.9 5.9.0" 5.8.9
check "resolved version already installed: no npm i"      "$(yes_if [ "$(omc_installs "$H")" = 0 ])"
check "resolved version already installed: no WARNING"   "$(yes_if [ "$(omc_warnings "$H")" = 0 ])"
NPM_DOWN=1
omc_case registry-down 5.8.10 "5.8.2 5.8.9" 5.8.2
NPM_DOWN=""
check "registry unreadable: no npm i"                     "$(yes_if [ "$(omc_installs "$H")" = 0 ])"
check "registry unreadable: exactly one WARNING line"     "$(yes_if [ "$(omc_warnings "$H")" = 1 ])"
check "registry unreadable: exit code unchanged (0)"      "$(yes_if [ "$INSTALL_RC" = 0 ] && in_log "$H" "Install complete")"
check "registry unreadable: CLI left at 5.8.2"            "$(yes_if [ "$(omc_version "$H")" = 5.8.2 ])"
omc_case none-at-or-below 1.2.3 "9.9.9"
check "nothing published at or below the pin: no npm i"   "$(yes_if [ "$(omc_installs "$H")" = 0 ])"
check "nothing published at or below the pin: one WARNING" "$(yes_if [ "$(omc_warnings "$H")" = 1 ])"
set_omc_pin "$OMC_PIN"

echo "[5/11] submodule init fails; this checkout records the commits"
H="$TMP/home-fallback"; mkdir -p "$H"
run_install "$H" "$OMC_PIN $OMC_NEWER" "$UNINIT_REPO"
check "gstack skills fetched at the recorded commit, not upstream's default branch" "$(yes_if grep -qx pinned "$H/.claude/skills/gstack/SKILL.md")"
check "OMC fetch fails: OMC skipped with a warning"       "$(yes_if in_log "$H" "WARNING: OMC install failed")"
check "OMC fetch fails: no OMC agents copied"             "$(yes_if [ ! -e "$H/.claude/agents/omc-test-agent.md" ])"
check "gstack ./setup never ran"                          "$(yes_if [ ! -e "$H/gstack-setup.log" ])"
check "runtime warning says no runtime is left"           "$(yes_if in_log "$H" "no runtime checkout in")"

echo "[6/11] not a git checkout: no recorded commits (upstream HEAD reachable)"
H="$TMP/home-nopin"; mkdir -p "$H/.gstack"
seed_runtime "$H"
run_install "$H" "$OMC_PIN $OMC_NEWER" "$NOPIN_REPO"
check "gstack skipped with a warning, not cloned from its default branch" "$(yes_if in_log "$H" "WARNING: no commit is recorded for upstream/gstack here, so gstack is skipped")"
check "no default-branch gstack skills copied"            "$(yes_if [ ! -e "$H/.claude/skills/gstack/SKILL.md" ])"
check "gstack ./setup never ran"                          "$(yes_if [ ! -e "$H/gstack-setup.log" ])"
check "existing runtime left where it was"                "$(yes_if [ "$(runtime_head "$H")" = "$GSTACK_HEAD_SHA" ])"
check "warning says the runtime was not updated"          "$(yes_if in_log "$H" "upstream/gstack is not checked out")"
check "warning names the runtime commit left in place"    "$(yes_if in_log "$H" "left at ${GSTACK_HEAD_SHA:0:12}")"
check "npm never asked for oh-my-claude-sisyphus"         "$(yes_if not logged "$H" "oh-my-claude-sisyphus@")"
check "warning says the OMC pin is unknown"               "$(yes_if in_log "$H" "pinned OMC version is unknown")"

echo "[7/11] submodule clone stopped at upstream's tip (the recorded commit is gone upstream)"
H="$TMP/home-tipclone"; mkdir -p "$H"
GSTACK_REMOTE="$GSTACK_TIP_ONLY" run_install "$H" "$OMC_PIN $OMC_NEWER" "$TIPCLONE_REPO" --skip-omc
check "fixture: upstream/gstack/.git was left at upstream's tip" "$(yes_if [ "$(tgit -C "$TIPCLONE_REPO/upstream/gstack" rev-parse HEAD 2>/dev/null)" = "$GSTACK_TIP_SHA" ])"
check "gstack ./setup never ran"                          "$(yes_if [ ! -e "$H/gstack-setup.log" ])"
check "runtime not checked out at upstream's tip"         "$(yes_if [ "$(runtime_head "$H")" != "$GSTACK_TIP_SHA" ] && [ ! -e "$H/.gstack/runtime/MARKER" ])"
check "no gstack skills copied"                           "$(yes_if [ ! -e "$H/.claude/skills/gstack/SKILL.md" ])"
check "warning names the recorded commit and the runtime state" "$(yes_if in_log "$H" "could not check the runtime out at the pinned ${GSTACK_PIN_SHA:0:12} — setup skipped; no runtime checkout in")"

echo "[8/11] submodule checkouts that differ from the recorded commits"
# Behind: the superproject records newer commits than the checkouts hold (a
# git pull without the submodule update).
record "$FAKE_REPO" "$GSTACK_HEAD_SHA" upstream/gstack
record "$FAKE_REPO" "$OMC_HEAD_SHA" upstream/omc
H="$TMP/home-unsynced"; mkdir -p "$H"
run_install "$H" "$OMC_PIN $OMC_NEWER" "$FAKE_REPO"
record "$FAKE_REPO" "$GSTACK_PIN_SHA" upstream/gstack
record "$FAKE_REPO" "$OMC_PIN_SHA" upstream/omc
check "gstack: one warning with both commits and the sync command" "$(yes_if [ "$(grep -c "upstream/gstack is checked out at ${GSTACK_PIN_SHA:0:12}, not the recorded ${GSTACK_HEAD_SHA:0:12}.*git submodule update --init --depth 1" "$H/install.log")" = 1 ])"
check "omc: one warning with both commits and the sync command"    "$(yes_if [ "$(grep -c "upstream/omc is checked out at ${OMC_PIN_SHA:0:12}, not the recorded ${OMC_HEAD_SHA:0:12}.*git submodule update --init --depth 1" "$H/install.log")" = 1 ])"
check "behind: gstack skills still come from the checkout" "$(yes_if grep -qx pinned "$H/.claude/skills/gstack/SKILL.md")"
check "behind: runtime not built from the checkout, ./setup never ran" "$(yes_if [ ! -e "$H/gstack-setup.log" ])"
check "behind: warning names the recorded commit the checkout lacks" "$(yes_if in_log "$H" "could not check the runtime out at the pinned ${GSTACK_HEAD_SHA:0:12} — setup skipped")"
# Ahead: the checkout moved past the recorded commit and still holds it.
H="$TMP/home-ahead"; mkdir -p "$H"
run_install "$H" "$OMC_PIN $OMC_NEWER" "$AHEAD_REPO" --skip-omc
check "ahead: one warning with both commits"              "$(yes_if [ "$(grep -c "upstream/gstack is checked out at ${GSTACK_HEAD_SHA:0:12}, not the recorded ${GSTACK_PIN_SHA:0:12}" "$H/install.log")" = 1 ])"
check "ahead: runtime at the recorded commit, not the checkout" "$(yes_if [ "$(runtime_head "$H")" = "$GSTACK_PIN_SHA" ])"
check "ahead: ./setup ran once, from the recorded commit" "$(yes_if [ "$(setup_runs "$H")" = "pinned --host claude" ])"

echo "[9/11] broken runtime checkout inside a HOME kept under git"
H="$TMP/home-gitrepo"; mkdir -p "$H"
tgit init -q "$H"
echo "# mine" > "$H/.dotfile"
tgit -C "$H" add .dotfile
tgit -C "$H" commit -qm "a HOME under version control"
HOME_REPO_SHA="$(tgit -C "$H" rev-parse HEAD)"
mkdir -p "$H/.gstack/runtime/.git"
run_install "$H" "$OMC_PIN $OMC_NEWER" "$FAKE_REPO"
check "the HOME repository keeps its commit and files"    "$(yes_if [ "$(tgit -C "$H" rev-parse HEAD)" = "$HOME_REPO_SHA" ] && [ -f "$H/.dotfile" ] && [ ! -e "$H/MARKER" ])"
check "gstack ./setup never ran"                          "$(yes_if [ ! -e "$H/gstack-setup.log" ])"
check "warning says what is left in the runtime"          "$(yes_if in_log "$H" "could not check the runtime out at the pinned ${GSTACK_PIN_SHA:0:12} — setup skipped; no runtime checkout in")"

echo "[10/11] git pointed at another work tree (exported GIT_WORK_TREE, core.worktree)"
# A directory holding one file of the user's, and checks on it and the runtime.
other_tree() { mkdir -p "$1/other"; echo mine > "$1/other/mine"; }
other_tree_intact() { [ "$(ls -A "$1/other")" = mine ] && [ "$(cat "$1/other/mine")" = mine ]; }
runtime_at_pin() { [ "$(runtime_head "$1")" = "$GSTACK_PIN_SHA" ] && [ "$(cat "$1/.gstack/runtime/MARKER" 2>/dev/null)" = pinned ]; }
H="$TMP/home-worktree-env"; mkdir -p "$H/.gstack"; other_tree "$H"
seed_runtime "$H"
GIT_WORK_TREE_EXPORT="$H/other" run_install "$H" "$OMC_PIN $OMC_NEWER" "$FAKE_REPO"
check "GIT_WORK_TREE: that directory is untouched"        "$(yes_if other_tree_intact "$H")"
check "GIT_WORK_TREE: runtime files checked out at the pin" "$(yes_if runtime_at_pin "$H")"
check "GIT_WORK_TREE: ./setup ran once, from the pinned files" "$(yes_if [ "$(setup_runs "$H")" = "pinned --host claude" ])"
H="$TMP/home-worktree-config"; mkdir -p "$H/.gstack"; other_tree "$H"
seed_runtime "$H"
tgit -C "$H/.gstack/runtime" config core.worktree "$H/other"
run_install "$H" "$OMC_PIN $OMC_NEWER" "$FAKE_REPO"
check "core.worktree in the runtime: that directory is untouched" "$(yes_if other_tree_intact "$H")"
check "core.worktree in the runtime: runtime files checked out at the pin" "$(yes_if runtime_at_pin "$H")"
H="$TMP/home-worktree-fresh"; mkdir -p "$H"; other_tree "$H"
GIT_WORK_TREE_EXPORT="$H/other" run_install "$H" "$OMC_PIN $OMC_NEWER" "$FAKE_REPO"
check "GIT_WORK_TREE, no runtime yet: that directory is untouched" "$(yes_if other_tree_intact "$H")"
check "GIT_WORK_TREE, no runtime yet: runtime created at the pin" "$(yes_if runtime_at_pin "$H")"
H="$TMP/home-worktree-fallback"; mkdir -p "$H"; other_tree "$H"
GIT_WORK_TREE_EXPORT="$H/other" run_install "$H" "$OMC_PIN $OMC_NEWER" "$UNINIT_REPO"
check "GIT_WORK_TREE, clone fallback: that directory is untouched" "$(yes_if other_tree_intact "$H")"
check "GIT_WORK_TREE, clone fallback: gstack skills fetched at the recorded commit" "$(yes_if grep -qx pinned "$H/.claude/skills/gstack/SKILL.md")"

echo "[11/11] session-start hook with omc missing"
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
