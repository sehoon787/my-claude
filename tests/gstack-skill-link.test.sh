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
#   2. Nothing under a linked skills/gstack is written to the manifest, and the
#      manifest cleanup never deletes through the link: a manifest that lists
#      skills/gstack/... leaves the runtime's files alone.
#   3. A real ~/.claude/skills/gstack the installer did not create (a gstack
#      clone, or files no manifest listed) is left byte-identical, with a
#      notice naming the path and the manual fix, even when an older manifest
#      lists skills/gstack/SKILL.md.
#   4. The root SKILL.md copy never writes through a link: a link to another
#      directory is removed, never followed, before the copy.
#   5. Without bun, setup is skipped and the link is still made (the helpers are
#      files in the checkout). Without a runtime at the pin, the root SKILL.md
#      is a real, manifest-owned copy as before and nothing is linked.
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
trap 'rm -rf "$TMP"' EXIT

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
# ./setup that records what ~/.claude/skills/gstack was while it ran.
GSTACK_PIN_REPO="$FAKE_REPO/upstream/gstack"
mkdir -p "$GSTACK_PIN_REPO/bin" "$GSTACK_PIN_REPO/review"
cat > "$GSTACK_PIN_REPO/setup" <<'EOF'
#!/usr/bin/env bash
d="$HOME/.claude/skills/gstack"
if [ -L "$d" ]; then echo "link" >> "$HOME/gstack-setup.log"
elif [ -d "$d" ]; then echo "dir: $(ls -A "$d" | tr '\n' ' ')" >> "$HOME/gstack-setup.log"
else echo "absent" >> "$HOME/gstack-setup.log"
fi
EOF
printf '#!/usr/bin/env bash\necho "SKILL_START_PROTO: 1"\n' > "$GSTACK_PIN_REPO/bin/gstack-skill-start"
chmod +x "$GSTACK_PIN_REPO/setup" "$GSTACK_PIN_REPO/bin/gstack-skill-start"
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
chmod +x "$SHIM"/* "$BUN_SHIM/bun"

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

# run_install <home> <bun|no-bun> [install.sh flags...]
run_install() {
  local home="$1" bun="$2" path="$SHIM:$TOOLS:/usr/bin:/bin:/usr/sbin:/sbin" rc=0
  shift 2
  [ "$bun" = bun ] && path="$BUN_SHIM:$path"
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
review_owned() { grep -qx 'pinned review' "$1/.claude/skills/review/SKILL.md" && grep -qx 'skills/review/SKILL.md' "$1/.claude/.my-claude-manifest"; }
router_copy_owned() { real_dir "$1" && grep -qx 'pinned router' "$(skill_dir "$1")/SKILL.md" && grep -qx 'skills/gstack/SKILL.md' "$1/.claude/.my-claude-manifest"; }
runtime_intact() { [ -f "$1/.gstack/runtime/SKILL.md" ] && [ -x "$1/.gstack/runtime/bin/gstack-skill-start" ]; }
not() { ! "$@"; }
in_log() { grep -qF -- "$2" "$1/install.log"; }
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

echo "[1/8] fresh install"
H="$TMP/home-fresh"; mkdir -p "$H"
run_install "$H" bun
check "setup ran once, while skills/gstack was the real directory holding only the router copy" "$(yes_if [ "$(setup_saw "$H")" = "dir: SKILL.md " ])"
check "then skills/gstack was linked to the runtime"     "$(yes_if linked_to_runtime "$H")"
check "a gstack bin/ helper resolves through the link"   "$(yes_if helper_resolves "$H")"
check "the root router is the pinned runtime's"          "$(yes_if grep -qx 'pinned router' "$(skill_dir "$H")/SKILL.md")"
check "manifest lists nothing under the link"            "$(yes_if not manifest_has_gstack_root "$H")"
check "allowlisted gstack skill still copied and manifest-owned" "$(yes_if review_owned "$H")"
check "install log names the link"                       "$(yes_if in_log "$H" "$(skill_dir "$H") -> $H/.gstack/runtime")"

echo "[2/8] reinstall over the link, with a manifest that lists files under it"
mkdir -p "$H/.gstack/runtime/browse/dist"
echo built > "$H/.gstack/runtime/browse/dist/browse"
printf 'skills/gstack/SKILL.md\nskills/gstack/browse/dist/browse\n' >> "$H/.claude/.my-claude-manifest"
run_install "$H" bun
check "setup ran again while skills/gstack was a real directory, not the link" "$(yes_if [ "$(setup_saw "$H")" = "$(printf 'dir: SKILL.md \ndir: SKILL.md ')" ])"
check "untracked runtime file listed in the manifest is not deleted through the link" "$(yes_if [ -f "$H/.gstack/runtime/browse/dist/browse" ])"
check "skills/gstack is linked to the runtime again"     "$(yes_if linked_to_runtime "$H")"
check "manifest lists nothing under the link"            "$(yes_if not manifest_has_gstack_root "$H")"

echo "[3/8] cleanup with an old manifest over the link, gstack step skipped"
cp "$H/.gstack/runtime/SKILL.md" "$TMP/runtime-router.before"
echo "skills/gstack/SKILL.md" >> "$H/.claude/.my-claude-manifest"
run_install "$H" bun --skip-gstack
check "the runtime's SKILL.md is not deleted through the link" "$(yes_if cmp -s "$H/.gstack/runtime/SKILL.md" "$TMP/runtime-router.before")"
check "the link is left in place"                        "$(yes_if linked_to_runtime "$H")"

echo "[4/8] upgrade from the real directory older installs made"
H="$TMP/home-upgrade"; mkdir -p "$(skill_dir "$H")"
printf -- '---\nname: gstack\n---\nan older copy\n' > "$(skill_dir "$H")/SKILL.md"
echo "skills/gstack/SKILL.md" > "$H/.claude/.my-claude-manifest"
run_install "$H" bun
check "setup saw the real directory with only the router copy" "$(yes_if [ "$(setup_saw "$H")" = "dir: SKILL.md " ])"
check "the installer-owned directory became the link"    "$(yes_if linked_to_runtime "$H")"
check "manifest lists nothing under the link"            "$(yes_if not manifest_has_gstack_root "$H")"

echo "[5/8] a gstack clone the user put at skills/gstack"
H="$TMP/home-clone"; mkdir -p "$H"
seed_foreign "$H" git
snapshot "$(skill_dir "$H")" > "$TMP/clone.before"
run_install "$H" bun
check "the clone is byte-identical (not cleaned, copied into, moved or linked over)" "$(yes_if cmp -s "$TMP/clone.before" <(snapshot "$(skill_dir "$H")"))"
check "it is still a real directory"                     "$(yes_if real_dir "$H")"
check "a notice names the path and the manual fix"       "$(yes_if notice_logged "$H")"
check "manifest lists nothing under it"                  "$(yes_if not manifest_has_gstack_root "$H")"
check "allowlisted gstack skill still copied"            "$(yes_if review_owned "$H")"

echo "[6/8] files of the user's at skills/gstack (no .git), one of them in an old manifest"
H="$TMP/home-plain"; mkdir -p "$H"
seed_foreign "$H" plain
snapshot "$(skill_dir "$H")" > "$TMP/plain.before"
run_install "$H" bun
check "the directory is byte-identical"                  "$(yes_if cmp -s "$TMP/plain.before" <(snapshot "$(skill_dir "$H")"))"
check "a notice names the path and the manual fix"       "$(yes_if notice_logged "$H")"
check "manifest lists nothing under it"                  "$(yes_if not manifest_has_gstack_root "$H")"

echo "[7/8] skills/gstack links to another directory: removed, never written through"
H="$TMP/home-otherlink"; mkdir -p "$H/elsewhere" "$H/.claude/skills"
printf -- '---\nname: gstack\n---\nelsewhere\n' > "$H/elsewhere/SKILL.md"
ln -s "$H/elsewhere" "$(skill_dir "$H")"
echo "skills/gstack/SKILL.md" > "$H/.claude/.my-claude-manifest"
snapshot "$H/elsewhere" > "$TMP/elsewhere.before"
run_install "$H" bun
check "the other directory is untouched"                 "$(yes_if cmp -s "$TMP/elsewhere.before" <(snapshot "$H/elsewhere"))"
check "setup saw a real directory, not the old link"     "$(yes_if [ "$(setup_saw "$H")" = "dir: SKILL.md " ])"
check "skills/gstack now links to the runtime"           "$(yes_if linked_to_runtime "$H")"

echo "[8/8] fallbacks: no bun, and no runtime at the pin"
H="$TMP/home-nobun"; mkdir -p "$H"
run_install "$H" no-bun
check "no bun: setup skipped"                            "$(yes_if [ ! -e "$H/gstack-setup.log" ])"
check "no bun: the browser-runtime warning is printed"   "$(yes_if in_log "$H" "Browser runtime not available")"
check "no bun: skills/gstack still linked to the pinned runtime" "$(yes_if linked_to_runtime "$H")"
check "no bun: a gstack bin/ helper resolves"            "$(yes_if helper_resolves "$H")"
check "no bun: allowlisted gstack skill still copied"    "$(yes_if review_owned "$H")"
# The same HOME, now with a recorded commit the submodule does not hold.
record "$FAKE_REPO" "$GSTACK_MISSING_SHA" upstream/gstack
run_install "$H" bun
record "$FAKE_REPO" "$GSTACK_PIN_SHA" upstream/gstack
check "no pin: setup skipped"                            "$(yes_if [ ! -e "$H/gstack-setup.log" ])"
check "no pin: the link gives way to a real, manifest-owned router copy" "$(yes_if router_copy_owned "$H")"
check "no pin: the runtime left at the old pin keeps its files" "$(yes_if runtime_intact "$H")"
check "no pin: allowlisted gstack skill still copied"    "$(yes_if review_owned "$H")"

if [ "$fail" -eq 0 ]; then
  echo "ALL PASSED"
else
  echo "FAILED"
fi
exit "$fail"
