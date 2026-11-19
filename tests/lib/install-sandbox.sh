#!/usr/bin/env bash
#
# install-sandbox.sh — shared fixture for the tests/install-*.test.sh files that
# run install.sh end to end. Sourced, never run on its own.
#
# install.sh runs from a symlink copy of this checkout (make_repo) whose
# upstream/ holds small local git repos instead of the real submodules. Every
# run gets `env -i` with a throwaway HOME, TMPDIR and npm prefix inside
# $SANDBOX, so the real HOME is never read or written. npm, claude, curl, uv,
# brew, sudo, bun, tmux and mktemp are shims: nothing is downloaded or
# installed for real, and git may only use local paths (GIT_ALLOW_PROTOCOL=file).
#
# Provides:
#   tgit ...                      git with no system or user config
#   make_repo <dir>               symlink copy of this checkout, empty upstream/, a git repo
#   make_module <dir> <name>      git init <dir> with a .git file, like a submodule checkout
#   commit_all <dir> <message>    commit every file in <dir>, print the new commit
#   record <repo> <sha> <path>    record <sha> as the commit <repo> pins for submodule <path>
#   redirect <url> <local-repo>   make git fetch <url> from <local-repo> during runs
#   run_install <home> <repo> [install.sh flags...]
#                                 exit code in INSTALL_RC, output in <home>/install.log,
#                                 shim calls in <home>/shim.log; RUN_ENV (NAME=value
#                                 words) is added to the run's environment
#   check <label> <1|0>, yes_if <command...>, not <command...>, finish
#   holds <file> <line>, in_log <home> <text>, logged <home> <text>

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SANDBOX="$(mktemp -d)"
trap 'rm -rf "$SANDBOX"' EXIT

tgit() {
  GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null \
  GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.invalid \
  GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@example.invalid \
    git -c init.defaultBranch=main -c commit.gpgsign=false "$@"
}

make_repo() {  # make_repo <dir>
  mkdir -p "$1/upstream"
  for entry in "$REPO"/* "$REPO"/.[!.]*; do
    [ -e "$entry" ] || continue
    case "$(basename "$entry")" in .git|upstream) continue ;; esac
    ln -s "$entry" "$1/$(basename "$entry")"
  done
  tgit init -q "$1"
}

make_module() {  # make_module <dir> <name>: its .git dir lives in $SANDBOX/modules
  mkdir -p "$1" "$SANDBOX/modules"
  tgit init -q --separate-git-dir "$SANDBOX/modules/$2" "$1"
}

commit_all() {  # commit_all <dir> <message>
  tgit -C "$1" add -A
  tgit -C "$1" commit -qm "$2"
  tgit -C "$1" rev-parse HEAD
}

record() { tgit -C "$1" update-index --add --cacheinfo "160000,$2,$3"; }

REDIRECTS=()
redirect() { REDIRECTS+=("$1" "$2"); }

# ── Shims ──
SHIM="$SANDBOX/shim"
TOOLS="$SANDBOX/tools"
mkdir -p "$SHIM" "$TOOLS"
# The only real tools install.sh gets beyond the system directories, linked one
# by one: node's own bin directory usually holds real omc/codeburn CLIs too.
ln -s "$(node -p process.execPath)" "$TOOLS/node"
ln -s "$(command -v git)" "$TOOLS/git"

# mktemp: install.sh calls it bare, and macOS then ignores TMPDIR. A template
# inside TMPDIR keeps those directories in the sandbox.
cat > "$SHIM/mktemp" <<EOF
#!/usr/bin/env bash
for arg in "\$@"; do
  case "\$arg" in -*) ;; *) exec "$(command -v mktemp)" "\$@" ;; esac
done
exec "$(command -v mktemp)" "\$@" "\${TMPDIR:-/tmp}/tmp.XXXXXXXXXX"
EOF

# npm: every call is logged. The global prefix is $NPM_SHIM_ROOT. `npm view`
# lists $NPM_SHIM_OMC_VERSIONS; `npm i -g oh-my-claude-sisyphus@<v>` installs a
# listed <v> with its HUD and an omc bin; `npm i -g oh-my-opencode@<v>` installs
# an oh-my-opencode bin that logs its own calls. Everything else is a no-op.
cat > "$SHIM/npm" <<'EOF'
#!/usr/bin/env bash
echo "npm $*" >> "$SHIM_LOG"
case "${1:-}" in
  root) echo "$NPM_SHIM_ROOT/lib/node_modules"; exit 0 ;;
  view)
    out="["; sep=""
    for v in ${NPM_SHIM_OMC_VERSIONS:-}; do out="$out$sep\"$v\""; sep=","; done
    echo "$out]"
    exit 0 ;;
  i|install) ;;
  *) exit 0 ;;
esac
pkg_json() { mkdir -p "$1"; printf '{ "name": "%s", "version": "%s" }\n' "$2" "$3" > "$1/package.json"; }
mkdir -p "$NPM_SHIM_ROOT/bin"
for spec in "$@"; do
  case "$spec" in
    oh-my-claude-sisyphus@*)
      ver="${spec#*@}"
      case " ${NPM_SHIM_OMC_VERSIONS:-} " in
        *" $ver "*) ;;
        *) echo "npm error notarget No matching version found for $spec." >&2; exit 1 ;;
      esac
      dir="$NPM_SHIM_ROOT/lib/node_modules/oh-my-claude-sisyphus"
      pkg_json "$dir" oh-my-claude-sisyphus "$ver"
      mkdir -p "$dir/dist/hud"
      echo "// hud" > "$dir/dist/hud/index.js"
      printf '#!/usr/bin/env bash\necho "omc $*" >> "$SHIM_LOG"\n' > "$NPM_SHIM_ROOT/bin/omc"
      chmod +x "$NPM_SHIM_ROOT/bin/omc" ;;
    oh-my-opencode@*)
      pkg_json "$NPM_SHIM_ROOT/lib/node_modules/oh-my-opencode" oh-my-opencode "${spec#*@}"
      printf '#!/usr/bin/env bash\necho "oh-my-opencode $*" >> "$SHIM_LOG"\n' > "$NPM_SHIM_ROOT/bin/oh-my-opencode"
      chmod +x "$NPM_SHIM_ROOT/bin/oh-my-opencode" ;;
  esac
done
exit 0
EOF

# claude: every call is logged and prints nothing (`claude plugin list` lists
# no plugins). `claude plugin add` fails the way Claude Code 2.1.328 does (it
# has no such subcommand) unless CLAUDE_SHIM_ACCEPT_ALL is set; every other
# call succeeds.
cat > "$SHIM/claude" <<'EOF'
#!/usr/bin/env bash
echo "claude $*" >> "$SHIM_LOG"
if [ "${1:-}" = plugin ] && [ "${2:-}" = add ] && [ -z "${CLAUDE_SHIM_ACCEPT_ALL:-}" ]; then
  echo "error: unknown command 'add'" >&2
  exit 1
fi
exit 0
EOF
printf '#!/usr/bin/env bash\nexit 0\n' > "$SHIM/bun"
printf '#!/usr/bin/env bash\necho "tmux 3.4"\n' > "$SHIM/tmux"
# Anything that would download or install for real fails.
for tool in curl uv brew sudo; do printf '#!/usr/bin/env bash\nexit 1\n' > "$SHIM/$tool"; done
chmod +x "$SHIM"/*

INSTALL_RC=0
RUN_ENV=()
run_install() {  # run_install <home> <repo> [install.sh flags...]
  local home="$1" repo="$2" i=0 n=0
  local -a cfg=()
  shift 2
  while [ "$i" -lt "${#REDIRECTS[@]}" ]; do
    cfg+=("GIT_CONFIG_KEY_$n=url.${REDIRECTS[$((i + 1))]}.insteadOf" "GIT_CONFIG_VALUE_$n=${REDIRECTS[$i]}")
    i=$((i + 2)); n=$((n + 1))
  done
  mkdir -p "$home/tmp" "$home/npm-global"
  ( cd "$repo" && env -i HOME="$home" TMPDIR="$home/tmp" NPM_CONFIG_PREFIX="$home/npm-global" \
      PATH="$SHIM:$home/npm-global/bin:$TOOLS:/usr/bin:/bin:/usr/sbin:/sbin" \
      SHIM_LOG="$home/shim.log" NPM_SHIM_ROOT="$home/npm-global" \
      NPM_SHIM_OMC_VERSIONS="${NPM_SHIM_OMC_VERSIONS:-}" \
      CLAUDE_SHIM_ACCEPT_ALL="${CLAUDE_SHIM_ACCEPT_ALL:-}" \
      AGENT_HARNESS_SERVICES_SKIP=1 GIT_CONFIG_NOSYSTEM=1 GIT_ALLOW_PROTOCOL=file \
      GIT_CONFIG_COUNT="$n" ${cfg[@]+"${cfg[@]}"} ${RUN_ENV[@]+"${RUN_ENV[@]}"} \
      "$BASH" install.sh "$@" ) > "$home/install.log" 2>&1 < /dev/null
  INSTALL_RC=$?
  if [ "$INSTALL_RC" -ne 0 ]; then
    echo "FAIL  install.sh exited $INSTALL_RC ($home)"
    tail -20 "$home/install.log"
    fail=1
  fi
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
holds() { grep -qx -- "$2" "$1" 2>/dev/null; }  # holds <file> <line>: the file has that exact line
in_log() { grep -qF -- "$2" "$1/install.log"; }
logged() { grep -qF -- "$2" "$1/shim.log" 2>/dev/null; }
finish() {
  if [ "$fail" -eq 0 ]; then
    echo "ALL PASSED"
  else
    echo "FAILED"
  fi
  exit "$fail"
}
