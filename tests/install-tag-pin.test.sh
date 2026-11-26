#!/usr/bin/env bash
#
# install-tag-pin.test.sh — the clone fallback for a tag-pinned upstream
# (archify) installs only the commit this checkout records.
# `bash tests/install-tag-pin.test.sh`
#
# When the submodule init fails, init_upstream clones a tag-pinned upstream at
# its tag. A tag can be moved upstream, so the clone could hold another release
# than the recorded, scanned commit. Guards:
#   1. Tag moved off the recorded commit: a warning names the tag and both
#      commits, archify is reported as failed, and nothing is installed.
#   2. Tag at the recorded commit: archify is installed from it.
#
# Runs install.sh in the shared sandbox (tests/lib/install-sandbox.sh): a
# throwaway HOME, TMPDIR and npm prefix, shimmed installers, local git only.
set -uo pipefail
. "$(dirname "$0")/lib/install-sandbox.sh"
# shellcheck source=../scripts/skill-allowlists.sh
. "$REPO/scripts/skill-allowlists.sh"
ARCHIFY_URL="https://github.com/tt-a1i/archify"
SKILL_FILE=".claude/skills/$ARCHIFY_SKILL_NAME/SKILL.md"

# archify's remote: the recorded commit, then a later one the tag can move to.
ARCHIFY_REMOTE="$SANDBOX/archify-remote"
mkdir -p "$ARCHIFY_REMOTE/$ARCHIFY_SKILL_SRC_DIR"
printf -- '---\nname: archify\n---\npinned\n' > "$ARCHIFY_REMOTE/$ARCHIFY_SKILL_SRC_DIR/SKILL.md"
tgit init -q "$ARCHIFY_REMOTE"
PIN_SHA="$(commit_all "$ARCHIFY_REMOTE" "archify at the pin")"
printf -- '---\nname: archify\n---\nmoved\n' > "$ARCHIFY_REMOTE/$ARCHIFY_SKILL_SRC_DIR/SKILL.md"
MOVED_SHA="$(commit_all "$ARCHIFY_REMOTE" "a later release")"
tag_at() { tgit -C "$ARCHIFY_REMOTE" tag -f "$ARCHIFY_PINNED_TAG" "$1" > /dev/null; }
redirect "$ARCHIFY_URL" "$ARCHIFY_REMOTE"

# A checkout that records PIN_SHA for upstream/archify but never initialized it
# and has no .gitmodules, so init_upstream takes its clone fallback.
new_checkout() {  # new_checkout <dir>
  make_repo "$1"
  rm -f "$1/.gitmodules"
  mkdir -p "$1/upstream/archify"
  record "$1" "$PIN_SHA" upstream/archify
  tgit -C "$1" commit -qm "record the pins"
}
FLAGS=(--skip-ecc --skip-omc --skip-gstack --skip-superpowers --skip-tools)

if [ -z "$PIN_SHA" ] || [ -z "$MOVED_SHA" ] || [ "$PIN_SHA" = "$MOVED_SHA" ] || [ -z "$ARCHIFY_PINNED_TAG" ]; then
  echo "FAIL  fixture setup"
  exit 1
fi

echo "[1/2] $ARCHIFY_PINNED_TAG moved off the recorded commit"
tag_at "$MOVED_SHA"
C="$SANDBOX/repo-moved"; new_checkout "$C"
H="$SANDBOX/home-moved"; mkdir -p "$H"
run_install "$H" "$C" "${FLAGS[@]}"
check "a warning names the tag and both commits"          "$(yes_if in_log "$H" "WARNING: archify tag $ARCHIFY_PINNED_TAG is at ${MOVED_SHA:0:12}, not the recorded commit ${PIN_SHA:0:12}")"
check "archify reported as failed"                        "$(yes_if in_log "$H" "WARNING: archify install failed")"
check "nothing from the moved tag installed"              "$(yes_if [ ! -e "$H/$SKILL_FILE" ])"

echo "[2/2] $ARCHIFY_PINNED_TAG at the recorded commit"
tag_at "$PIN_SHA"
C="$SANDBOX/repo-pinned"; new_checkout "$C"
H="$SANDBOX/home-pinned"; mkdir -p "$H"
run_install "$H" "$C" "${FLAGS[@]}"
check "archify installed from the recorded commit"        "$(yes_if holds "$H/$SKILL_FILE" pinned)"
check "no tag warning"                                    "$(yes_if not in_log "$H" "not the recorded commit")"
check "archify not reported as failed"                    "$(yes_if not in_log "$H" "archify install failed")"

finish
