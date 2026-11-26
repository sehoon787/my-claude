#!/usr/bin/env bash
#
# gstack-skill-link.test.sh — install.sh links ~/.claude/skills/gstack to the
# pinned gstack runtime (~/.gstack/runtime), so the gstack skills find the bin/
# helpers they run through that path, and it never deletes, moves or writes
# into a directory it did not create. `bash tests/gstack-skill-link.test.sh`
#
# Guards:
#   1. gstack's ./setup runs while ~/.claude/skills/gstack is the real directory
#      install.sh made: setup leaves such a directory alone, but through a link
#      to itself it would link every gstack skill and register its hooks. The
#      link is made after setup, on a fresh install, over the link an earlier
#      run left and over the real directory older installs left.
#   2. The router copy stays manifest-owned while skills/gstack is a link, and
#      the manifest cleanup and its prune never act through the link: a
#      manifest that lists skills/gstack/... leaves the runtime's files and
#      directories alone. A run that stopped before linking (also a first one,
#      before any manifest: gstack's generated banner), or Finder's .DS_Store
#      file, does not make the installer's directory look like the user's.
#   3. A real ~/.claude/skills/gstack the installer did not create (a gstack
#      clone, files no manifest listed, a .DS_Store that is a directory) is left
#      byte-identical, with a notice naming the path and the manual fix, even
#      when an older manifest lists skills/gstack/SKILL.md.
#   4. The root SKILL.md copy never writes through a link: a link to another
#      directory is removed, never followed, before the copy, and a link to the
#      user's own gstack checkout is named in a notice.
#   5. Without bun, setup is skipped and the link is still made (the helpers are
#      files in the checkout). Without a runtime at the pin, the root SKILL.md
#      is a real, manifest-owned copy as before and nothing is linked.
#   6. Once linked, gstack's update_check is turned off through the runtime's
#      own bin/gstack-config, with one line, unless config.yaml already sets
#      it (that value is the user's and stays byte-identical).
#   7. When ln makes no symlink (Git Bash without native symlinks copies the
#      target), the copy is removed and the router copy installs as before,
#      with a notice. When something else appears in the router directory
#      before the link is made, it is left alone, the router copy stays, a
#      notice says so, and the install runs to the end.
#
# install.sh runs from a symlink copy of this checkout whose upstream/gstack is
# a small local git repo (a .git file, like a submodule), with its commit
# recorded in the copy's index. Every run gets `env -i` with a throwaway HOME,
# TMPDIR and NPM_CONFIG_PREFIX inside this test's temp dir; git may only use
# local paths, and npm, claude, bun, curl and the other installers are shims,
# so the real HOME is never read or written.
set -uo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP:?}"' EXIT

# git for building fixtures and reading results: no system or user config.
tgit() {
  GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null \
  GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.invalid \
  GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@example.invalid \
    git -c init.defaultBranch=main -c commit.gpgsign=false "$@"
}
# Record <sha> as the commit <repo> pins for submodule <path>.
record() { tgit -C "$1" update-index --add --cacheinfo "160000,$2,$3"; }

# ── Fixtures ──
# A symlink copy of this checkout with an upstream/ of its own.
FAKE_REPO="$TMP/repo"
mkdir -p "$FAKE_REPO/upstream" "$TMP/modules"
for entry in "$REPO"/* "$REPO"/.[!.]*; do
  [ -e "$entry" ] || continue
  case "$(basename "$entry")" in .git|upstream) continue ;; esac
  ln -s "$entry" "$FAKE_REPO/$(basename "$entry")"
done

# upstream/gstack: the root router, one allowlisted skill, a bin/ helper, and a
# ./setup that records what ~/.claude/skills/gstack was while it ran. With
# ~/setup-writes-a-file present it also leaves a file of its own in there.
GSTACK_PIN_REPO="$FAKE_REPO/upstream/gstack"
mkdir -p "$GSTACK_PIN_REPO/bin" "$GSTACK_PIN_REPO/review"
cat > "$GSTACK_PIN_REPO/setup" <<'EOF'
#!/usr/bin/env bash
d="$HOME/.claude/skills/gstack"
if [ -L "$d" ]; then echo "link" >> "$HOME/gstack-setup.log"
elif [ -d "$d" ]; then echo "dir: $(ls -A "$d" | tr '\n' ' ')" >> "$HOME/gstack-setup.log"
else echo "absent" >> "$HOME/gstack-setup.log"
fi
if [ -e "$HOME/setup-writes-a-file" ] && [ -d "$d" ] && [ ! -L "$d" ]; then echo "not the installer's" > "$d/extra.md"; fi
EOF
printf '#!/usr/bin/env bash\necho "SKILL_START_PROTO: 1"\n' > "$GSTACK_PIN_REPO/bin/gstack-skill-start"
# bin/gstack-config answers `has` and `set` the way the real one does (has: the
# key is literally in ~/.gstack/config.yaml) and logs every call.
cat > "$GSTACK_PIN_REPO/bin/gstack-config" <<'EOF'
#!/usr/bin/env bash
cfg="$HOME/.gstack/config.yaml"
echo "$*" >> "$HOME/gstack-config.log"
case "${1:-}" in
  has) grep -qE "^$2:" "$cfg" 2>/dev/null ;;
  set) mkdir -p "${cfg%/*}"
       { grep -vE "^$2:" "$cfg" 2>/dev/null; echo "$2: $3"; } > "$cfg.tmp" && mv "$cfg.tmp" "$cfg" ;;
  *) exit 1 ;;
esac
EOF
chmod +x "$GSTACK_PIN_REPO/setup" "$GSTACK_PIN_REPO/bin/gstack-skill-start" "$GSTACK_PIN_REPO/bin/gstack-config"
printf -- '---\nname: gstack\n---\npinned router\n' > "$GSTACK_PIN_REPO/SKILL.md"
printf -- '---\nname: review\n---\npinned review\n' > "$GSTACK_PIN_REPO/review/SKILL.md"
tgit init -q --separate-git-dir "$TMP/modules/gstack" "$GSTACK_PIN_REPO"
tgit -C "$GSTACK_PIN_REPO" add -A
tgit -C "$GSTACK_PIN_REPO" commit -qm "gstack at the pin"
GSTACK_PIN_SHA="$(tgit -C "$GSTACK_PIN_REPO" rev-parse HEAD)"
# A commit the submodule does not hold, for a runtime that cannot reach the pin.
tgit clone -q "$GSTACK_PIN_REPO" "$TMP/gstack-ahead"
echo ahead >> "$TMP/gstack-ahead/SKILL.md"
tgit -C "$TMP/gstack-ahead" commit -qam "a commit upstream/gstack does not hold"
GSTACK_MISSING_SHA="$(tgit -C "$TMP/gstack-ahead" rev-parse HEAD)"

tgit init -q "$FAKE_REPO"
record "$FAKE_REPO" "$GSTACK_PIN_SHA" upstream/gstack

if [ -z "$GSTACK_PIN_SHA" ] || [ -z "$GSTACK_MISSING_SHA" ] || [ "$GSTACK_PIN_SHA" = "$GSTACK_MISSING_SHA" ] \
   || [ ! -f "$GSTACK_PIN_REPO/.git" ] \
   || [ "$(tgit -C "$FAKE_REPO" rev-parse -q --verify :upstream/gstack)" != "$GSTACK_PIN_SHA" ]; then
  echo "FAIL  fixture setup"
  exit 1
fi

# ── Shims ──
SHIM="$TMP/shim"
BUN_SHIM="$TMP/shim-bun"
TOOLS="$TMP/tools"
mkdir -p "$SHIM" "$BUN_SHIM" "$TOOLS"
ln -s "$(node -p process.execPath)" "$TOOLS/node"
ln -s "$(command -v git)" "$TOOLS/git"
# mktemp: install.sh calls it bare, and macOS mktemp then ignores TMPDIR; a
# template inside TMPDIR keeps its directories under this test's temp dir.
cat > "$SHIM/mktemp" <<EOF
#!/usr/bin/env bash
for arg in "\$@"; do
  case "\$arg" in -*) ;; *) exec "$(command -v mktemp)" "\$@" ;; esac
done
exec "$(command -v mktemp)" "\$@" "\${TMPDIR:-/tmp}/tmp.XXXXXXXXXX"
EOF
# npm and claude do nothing; npm's global root is inside NPM_CONFIG_PREFIX.
cat > "$SHIM/npm" <<'EOF'
#!/usr/bin/env bash
[ "${1:-}" = root ] && echo "$NPM_CONFIG_PREFIX/lib/node_modules"
exit 0
EOF
printf '#!/usr/bin/env bash\nexit 0\n' > "$SHIM/claude"
printf '#!/usr/bin/env bash\necho "tmux 3.4"\n' > "$SHIM/tmux"
# Anything that would download or install for real fails.
for tool in curl uv brew sudo; do printf '#!/usr/bin/env bash\nexit 1\n' > "$SHIM/$tool"; done
# bun only has to exist for install.sh to run the runtime's ./setup.
printf '#!/usr/bin/env bash\nexit 0\n' > "$BUN_SHIM/bun"
# ln as Git Bash runs it without native symlinks: -s copies the target.
NOLINK_SHIM="$TMP/shim-nolink"
mkdir -p "$NOLINK_SHIM"
cat > "$NOLINK_SHIM/ln" <<'EOF'
#!/usr/bin/env bash
args=()
for a in "$@"; do case "$a" in -*) ;; *) args+=("$a") ;; esac; done
exec cp -R "${args[0]}" "${args[1]}"
EOF
chmod +x "$SHIM"/* "$BUN_SHIM/bun" "$NOLINK_SHIM/ln"

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

# run_install <home> <bun|no-bun|no-symlinks> [install.sh flags...]
run_install() {
  local home="$1" mode="$2" path="$SHIM:$TOOLS:/usr/bin:/bin:/usr/sbin:/sbin" rc=0
  shift 2
  case "$mode" in
    bun) path="$BUN_SHIM:$path" ;;
    no-symlinks) path="$NOLINK_SHIM:$BUN_SHIM:$path" ;;
  esac
  mkdir -p "$home/tmp" "$home/npm-prefix"
  ( cd "$FAKE_REPO" && env -i HOME="$home" TMPDIR="$home/tmp" NPM_CONFIG_PREFIX="$home/npm-prefix" \
      PATH="$path" AGENT_HARNESS_SERVICES_SKIP=1 GIT_CONFIG_NOSYSTEM=1 GIT_ALLOW_PROTOCOL=file \
      "$BASH" install.sh --skip-ecc --skip-omc --skip-superpowers --skip-archify --skip-tools "$@" ) \
    > "$home/install.log" 2>&1 < /dev/null || rc=$?
  if [ "$rc" -ne 0 ]; then
    echo "FAIL  install.sh exited $rc ($home)"
    tail -20 "$home/install.log"
    fail=1
  fi
}

skill_dir() { echo "$1/.claude/skills/gstack"; }
linked_to_runtime() { [ -L "$(skill_dir "$1")" ] && [ "$(readlink "$(skill_dir "$1")")" = "$1/.gstack/runtime" ]; }
real_dir() { [ -d "$(skill_dir "$1")" ] && [ ! -L "$(skill_dir "$1")" ]; }
helper_resolves() { [ "$("$(skill_dir "$1")/bin/gstack-skill-start" 2>/dev/null)" = "SKILL_START_PROTO: 1" ]; }
setup_saw() { cat "$1/gstack-setup.log" 2>/dev/null; }
manifest_has_gstack_root() { grep -q '^skills/gstack/' "$1/.claude/.my-claude-manifest"; }
# The router copy is manifest-owned even while skills/gstack is a link: the
# cleanup never deletes through the link, and a run that stops before linking
# still owns its copy.
manifest_lists_router_only() { [ "$(grep '^skills/gstack/' "$1/.claude/.my-claude-manifest")" = skills/gstack/SKILL.md ]; }
review_owned() { grep -qx 'pinned review' "$1/.claude/skills/review/SKILL.md" && grep -qx 'skills/review/SKILL.md' "$1/.claude/.my-claude-manifest"; }
router_copy_owned() { real_dir "$1" && grep -qx 'pinned router' "$(skill_dir "$1")/SKILL.md" && grep -qx 'skills/gstack/SKILL.md' "$1/.claude/.my-claude-manifest"; }
router_copy_only() { router_copy_owned "$1" && [ "$(ls -A "$(skill_dir "$1")")" = SKILL.md ]; }
runtime_intact() { [ -f "$1/.gstack/runtime/SKILL.md" ] && [ -x "$1/.gstack/runtime/bin/gstack-skill-start" ]; }
not() { ! "$@"; }
in_log() { grep -qF -- "$2" "$1/install.log"; }
# update_check: how often install.sh set it through the runtime's gstack-config,
# and how many lines of the last install log mention it.
config_sets() { cat "$1/gstack-config.log" 2>/dev/null | grep -c '^set update_check false$'; }
update_check_lines() { grep -c 'update_check' "$1/install.log"; }
update_check_off_once() {
  [ "$(config_sets "$1")" = 1 ] && grep -qx 'update_check: false' "$1/.gstack/config.yaml" \
    && [ "$(grep -c "update_check turned off: gstack updates arrive through my-claude's upstream/gstack pin" "$1/install.log")" = 1 ]
}
# update_check_left <home> <sets so far>: this run set nothing and printed nothing.
update_check_left() { [ "$(config_sets "$1")" = "$2" ] && [ "$(update_check_lines "$1")" = 0 ]; }
notice_logged() { in_log "$1" "NOTICE: $(skill_dir "$1") was not created by this installer" && in_log "$1" "mv \"$(skill_dir "$1")\""; }
# Every path under <dir> with a checksum for each regular file, so two
# snapshots compare equal only when nothing was added, removed or changed.
snapshot() {
  ( cd "$1" && find . | LC_ALL=C sort | while IFS= read -r p; do
      if [ -L "$p" ]; then echo "$p -> $(readlink "$p")"
      elif [ -f "$p" ]; then echo "$p $(cksum < "$p")"
      else echo "$p"
      fi
    done )
}
# A user-owned gstack directory: a clone (.git) or plain files of the user's.
seed_foreign() {  # seed_foreign <home> <git|plain>
  local d
  d="$(skill_dir "$1")"
  mkdir -p "$d/bin"
  printf -- '---\nname: gstack\n---\nthe user'"'"'s own router\n' > "$d/SKILL.md"
  echo "mine" > "$d/notes.md"
  printf '#!/usr/bin/env bash\necho mine\n' > "$d/bin/gstack-skill-start"
  if [ "$2" = git ]; then mkdir -p "$d/.git"; echo "ref: refs/heads/main" > "$d/.git/HEAD"; echo user-owned > "$d/VERSION"; fi
  # The manifest an install before this change wrote: it copied the router in.
  echo "skills/gstack/SKILL.md" > "$1/.claude/.my-claude-manifest"
}

echo "[1/14] fresh install"
H="$TMP/home-fresh"; mkdir -p "$H"
run_install "$H" bun
check "setup ran once, while skills/gstack was the real directory holding only the router copy" "$(yes_if [ "$(setup_saw "$H")" = "dir: SKILL.md " ])"
check "then skills/gstack was linked to the runtime"     "$(yes_if linked_to_runtime "$H")"
check "a gstack bin/ helper resolves through the link"   "$(yes_if helper_resolves "$H")"
check "the root router is the pinned runtime's"          "$(yes_if grep -qx 'pinned router' "$(skill_dir "$H")/SKILL.md")"
check "manifest lists the router and nothing else under the link" "$(yes_if manifest_lists_router_only "$H")"
check "allowlisted gstack skill still copied and manifest-owned" "$(yes_if review_owned "$H")"
check "install log names the link"                       "$(yes_if in_log "$H" "$(skill_dir "$H") -> $H/.gstack/runtime")"
check "update_check turned off once, through the runtime's gstack-config, with one line" "$(yes_if update_check_off_once "$H")"
check "the undo hint names the runtime's gstack-config"  "$(yes_if in_log "$H" "(undo: $H/.gstack/runtime/bin/gstack-config set update_check true)")"

echo "[2/14] reinstall over the link, with a manifest that lists files under it"
mkdir -p "$H/.gstack/runtime/browse/dist"
echo built > "$H/.gstack/runtime/browse/dist/browse"
printf 'skills/gstack/SKILL.md\nskills/gstack/browse/dist/browse\n' >> "$H/.claude/.my-claude-manifest"
run_install "$H" bun
check "setup ran again while skills/gstack was a real directory, not the link" "$(yes_if [ "$(setup_saw "$H")" = "$(printf 'dir: SKILL.md \ndir: SKILL.md ')" ])"
check "untracked runtime file listed in the manifest is not deleted through the link" "$(yes_if [ -f "$H/.gstack/runtime/browse/dist/browse" ])"
check "skills/gstack is linked to the runtime again"     "$(yes_if linked_to_runtime "$H")"
check "manifest lists the router and nothing else under the link" "$(yes_if manifest_lists_router_only "$H")"
check "update_check already set: not set again, no line" "$(yes_if update_check_left "$H" 1)"

echo "[3/14] cleanup and prune with a manifest over the link, gstack step skipped"
cp "$H/.gstack/runtime/SKILL.md" "$TMP/runtime-router.before"
mkdir -p "$H/.gstack/runtime/empty-dir"
echo "skills/gstack/empty-dir/gone.md" >> "$H/.claude/.my-claude-manifest"
run_install "$H" bun --skip-gstack
check "the runtime's SKILL.md is not deleted through the link" "$(yes_if cmp -s "$H/.gstack/runtime/SKILL.md" "$TMP/runtime-router.before")"
check "an empty runtime directory above a manifest entry is not pruned through the link" "$(yes_if [ -d "$H/.gstack/runtime/empty-dir" ])"
check "the link is left in place"                        "$(yes_if linked_to_runtime "$H")"

echo "[4/14] upgrade from the real directory older installs made, update_check set by the user"
H="$TMP/home-upgrade"; mkdir -p "$(skill_dir "$H")" "$H/.gstack"
printf -- '---\nname: gstack\n---\nan older copy\n' > "$(skill_dir "$H")/SKILL.md"
echo "skills/gstack/SKILL.md" > "$H/.claude/.my-claude-manifest"
printf 'update_check: true\n' > "$H/.gstack/config.yaml"
cp "$H/.gstack/config.yaml" "$TMP/user-config.yaml"
run_install "$H" bun
check "setup saw the real directory with only the router copy" "$(yes_if [ "$(setup_saw "$H")" = "dir: SKILL.md " ])"
check "the installer-owned directory became the link"    "$(yes_if linked_to_runtime "$H")"
check "manifest lists the router and nothing else under the link" "$(yes_if manifest_lists_router_only "$H")"
check "update_check the user set is byte-identical"      "$(yes_if cmp -s "$H/.gstack/config.yaml" "$TMP/user-config.yaml")"
check "update_check the user set: not set, no line"      "$(yes_if update_check_left "$H" 0)"

echo "[5/14] a gstack clone the user put at skills/gstack"
H="$TMP/home-clone"; mkdir -p "$H"
seed_foreign "$H" git
snapshot "$(skill_dir "$H")" > "$TMP/clone.before"
run_install "$H" bun
check "the clone is byte-identical (not cleaned, copied into, moved or linked over)" "$(yes_if cmp -s "$TMP/clone.before" <(snapshot "$(skill_dir "$H")"))"
check "it is still a real directory"                     "$(yes_if real_dir "$H")"
check "a notice names the path and the manual fix"       "$(yes_if notice_logged "$H")"
check "manifest lists nothing under it"                  "$(yes_if not manifest_has_gstack_root "$H")"
check "allowlisted gstack skill still copied"            "$(yes_if review_owned "$H")"
check "update_check untouched for a gstack install the user owns" "$(yes_if [ ! -e "$H/.gstack/config.yaml" ])"

echo "[6/14] files of the user's at skills/gstack (no .git), one of them in an old manifest"
H="$TMP/home-plain"; mkdir -p "$H"
seed_foreign "$H" plain
snapshot "$(skill_dir "$H")" > "$TMP/plain.before"
run_install "$H" bun
check "the directory is byte-identical"                  "$(yes_if cmp -s "$TMP/plain.before" <(snapshot "$(skill_dir "$H")"))"
check "a notice names the path and the manual fix"       "$(yes_if notice_logged "$H")"
check "manifest lists nothing under it"                  "$(yes_if not manifest_has_gstack_root "$H")"

echo "[7/14] skills/gstack links to the user's own gstack checkout: removed, never written through"
H="$TMP/home-otherlink"; mkdir -p "$H/elsewhere" "$H/.claude/skills"
printf -- '---\nname: gstack\n---\nelsewhere\n' > "$H/elsewhere/SKILL.md"
printf '#!/usr/bin/env bash\n' > "$H/elsewhere/setup"
echo 9.9.9.9 > "$H/elsewhere/VERSION"
ln -s "$H/elsewhere" "$(skill_dir "$H")"
echo "skills/gstack/SKILL.md" > "$H/.claude/.my-claude-manifest"
snapshot "$H/elsewhere" > "$TMP/elsewhere.before"
run_install "$H" bun
check "the checkout is untouched"                        "$(yes_if cmp -s "$TMP/elsewhere.before" <(snapshot "$H/elsewhere"))"
check "a notice names the checkout the link pointed to"  "$(yes_if in_log "$H" "NOTICE: $(skill_dir "$H") linked to $H/elsewhere, a gstack checkout")"
check "setup saw a real directory, not the old link"     "$(yes_if [ "$(setup_saw "$H")" = "dir: SKILL.md " ])"
check "skills/gstack now links to the runtime"           "$(yes_if linked_to_runtime "$H")"

echo "[8/14] fallbacks: no bun, and no runtime at the pin"
H="$TMP/home-nobun"; mkdir -p "$H"
run_install "$H" no-bun
check "no bun: setup skipped"                            "$(yes_if [ ! -e "$H/gstack-setup.log" ])"
check "no bun: the browser-runtime warning is printed"   "$(yes_if in_log "$H" "Browser runtime not available")"
check "no bun: skills/gstack still linked to the pinned runtime" "$(yes_if linked_to_runtime "$H")"
check "no bun: a gstack bin/ helper resolves"            "$(yes_if helper_resolves "$H")"
check "no bun: allowlisted gstack skill still copied"    "$(yes_if review_owned "$H")"
check "no bun: update_check turned off (the helpers run without setup)" "$(yes_if update_check_off_once "$H")"
# The same HOME, now with a recorded commit the submodule does not hold.
record "$FAKE_REPO" "$GSTACK_MISSING_SHA" upstream/gstack
run_install "$H" bun
record "$FAKE_REPO" "$GSTACK_PIN_SHA" upstream/gstack
check "no pin: setup skipped"                            "$(yes_if [ ! -e "$H/gstack-setup.log" ])"
check "no pin: the link gives way to a real, manifest-owned router copy" "$(yes_if router_copy_owned "$H")"
check "no pin: the runtime left at the old pin keeps its files" "$(yes_if runtime_intact "$H")"
check "no pin: allowlisted gstack skill still copied"    "$(yes_if review_owned "$H")"
check "no pin: update_check not set again, no line"      "$(yes_if update_check_left "$H" 1)"

echo "[9/14] no symlinks (Git Bash without native symlinks): ln copies the runtime"
H="$TMP/home-nosymlink"; mkdir -p "$H"
run_install "$H" no-symlinks
check "no symlinks: setup ran while skills/gstack was the real directory" "$(yes_if [ "$(setup_saw "$H")" = "dir: SKILL.md " ])"
check "no symlinks: the copy ln made is removed, the router copy is back and manifest-owned" "$(yes_if router_copy_only "$H")"
check "no symlinks: a notice says no symlink was made"   "$(yes_if in_log "$H" "NOTICE: ln made no symlink at $(skill_dir "$H")")"
check "no symlinks: the runtime keeps its files"         "$(yes_if runtime_intact "$H")"
check "no symlinks: update_check left alone (no helpers to run)" "$(yes_if [ ! -e "$H/.gstack/config.yaml" ])"

echo "[10/14] a run that stopped after step 1e: the router copy it left is still the installer's"
H="$TMP/home-stopped"; mkdir -p "$H"
run_install "$H" bun
rm -f "${H:?}/.claude/skills/gstack"
mkdir -p "$(skill_dir "$H")"
cp "$GSTACK_PIN_REPO/SKILL.md" "$(skill_dir "$H")/SKILL.md"
run_install "$H" bun
check "stopped run: the copy it left is not taken for the user's" "$(yes_if not in_log "$H" "was not created by this installer")"
check "stopped run: skills/gstack is linked again"       "$(yes_if linked_to_runtime "$H")"

echo "[11/14] Finder's .DS_Store in the installer's router directory"
H="$TMP/home-dsstore"; mkdir -p "$(skill_dir "$H")"
cp "$GSTACK_PIN_REPO/SKILL.md" "$(skill_dir "$H")/SKILL.md"
echo finder > "$(skill_dir "$H")/.DS_Store"
echo "skills/gstack/SKILL.md" > "$H/.claude/.my-claude-manifest"
run_install "$H" bun
check ".DS_Store: the directory is not taken for the user's" "$(yes_if not in_log "$H" "was not created by this installer")"
check ".DS_Store: skills/gstack is linked"               "$(yes_if linked_to_runtime "$H")"
check ".DS_Store: it does not end up in the runtime"     "$(yes_if [ ! -e "$H/.gstack/runtime/.DS_Store" ])"

echo "[12/14] a file appears in the router directory while setup runs"
H="$TMP/home-extra"; mkdir -p "$H"
: > "$H/setup-writes-a-file"
run_install "$H" bun
check "extra file: install.sh runs to the end"           "$(yes_if in_log "$H" "Install complete")"
check "extra file: the file is left as it is"            "$(yes_if grep -qx "not the installer's" "$(skill_dir "$H")/extra.md")"
check "extra file: the router copy is back and manifest-owned" "$(yes_if router_copy_owned "$H")"
check "extra file: a notice says the directory was not linked" "$(yes_if in_log "$H" "NOTICE: $(skill_dir "$H") holds files this installer did not put there")"
check "extra file: update_check left alone (nothing linked)" "$(yes_if [ ! -e "$H/.gstack/config.yaml" ])"

echo "[13/14] a .DS_Store directory, not Finder's file, in the router directory"
H="$TMP/home-dsstore-dir"; mkdir -p "$(skill_dir "$H")/.DS_Store"
cp "$GSTACK_PIN_REPO/SKILL.md" "$(skill_dir "$H")/SKILL.md"
echo "skills/gstack/SKILL.md" > "$H/.claude/.my-claude-manifest"
snapshot "$(skill_dir "$H")" > "$TMP/dsstore-dir.before"
run_install "$H" bun
check ".DS_Store directory: install.sh runs to the end"  "$(yes_if in_log "$H" "Install complete")"
check ".DS_Store directory: taken for the user's, with a notice" "$(yes_if notice_logged "$H")"
check ".DS_Store directory: left byte-identical"         "$(yes_if cmp -s "$TMP/dsstore-dir.before" <(snapshot "$(skill_dir "$H")"))"

echo "[14/14] a first install that stopped before it wrote a manifest"
H="$TMP/home-first-stopped"; mkdir -p "$(skill_dir "$H")"
printf -- '---\nname: gstack\n---\n<!-- AUTO-GENERATED from SKILL.md.tmpl — do not edit directly -->\n' > "$(skill_dir "$H")/SKILL.md"
run_install "$H" bun
check "first run stopped: gstack's generated router copy is not taken for the user's" "$(yes_if not in_log "$H" "was not created by this installer")"
check "first run stopped: skills/gstack is linked"       "$(yes_if linked_to_runtime "$H")"

if [ "$fail" -eq 0 ]; then
  echo "ALL PASSED"
else
  echo "FAILED"
fi
exit "$fail"
