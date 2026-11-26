#!/usr/bin/env bash
#
# install-half-clone.test.sh — a submodule clone that stopped before its
# checkout must not be skipped without a word.
# `bash tests/install-half-clone.test.sh`
#
# A `git submodule update` that cannot fetch the recorded commit (the remote no
# longer has it), or that is interrupted before its checkout, leaves
# upstream/<name> holding a .git and nothing else. init_upstream took any .git
# as a usable checkout, so every copy step found nothing to copy: ECC's skills
# and rules were skipped with no message at all. Guards:
#   1. Recorded commit not on the remote: a warning names the incomplete clone,
#      the submodule init and the clone fallback are retried and fail, ECC is
#      reported as failed, and nothing from the remote's tip is installed.
#   2. Clone stopped with HEAD already at the recorded commit, no remote
#      reachable: the same warning, then the submodule is checked out in place
#      (a plain `git submodule update` sees HEAD at the recorded commit and
#      checks nothing out) and ECC installs from it, offline.
#
# Runs install.sh in the shared sandbox (tests/lib/install-sandbox.sh): a
# throwaway HOME, TMPDIR and npm prefix, shimmed installers, local git only.
set -uo pipefail
. "$(dirname "$0")/lib/install-sandbox.sh"
# shellcheck source=../scripts/skill-allowlists.sh
. "$REPO/scripts/skill-allowlists.sh"
for ECC_SKILL in $ECC_SKILL_ALLOWLIST; do break; done
for ECC_RULE in $ECC_RULES_ALLOWLIST; do break; done
ECC_URL="https://github.com/affaan-m/everything-claude-code"

# ECC at the recorded commit: one allowlisted skill and one allowlisted rule set.
ECC_REMOTE="$SANDBOX/ecc-remote"
mkdir -p "$ECC_REMOTE/skills/$ECC_SKILL" "$ECC_REMOTE/rules/$ECC_RULE"
printf -- '---\nname: %s\n---\npinned\n' "$ECC_SKILL" > "$ECC_REMOTE/skills/$ECC_SKILL/SKILL.md"
echo pinned > "$ECC_REMOTE/rules/$ECC_RULE/rule.md"
tgit init -q "$ECC_REMOTE"
ECC_PIN="$(commit_all "$ECC_REMOTE" "ecc at the pin")"

# A remote whose history no longer holds that commit, only a rewritten tip.
ECC_TIP_ONLY="$SANDBOX/ecc-tip-only"
mkdir -p "$ECC_TIP_ONLY/skills/$ECC_SKILL"
printf -- '---\nname: %s\n---\nupstream-tip\n' "$ECC_SKILL" > "$ECC_TIP_ONLY/skills/$ECC_SKILL/SKILL.md"
tgit init -q "$ECC_TIP_ONLY"
commit_all "$ECC_TIP_ONLY" "rewritten upstream tip" > /dev/null

# A checkout that records ECC_PIN for upstream/ecc (with the real .gitmodules)
# and whose upstream/ecc is a clone of <remote> that never checked anything out.
half_clone_checkout() {  # half_clone_checkout <dir> <remote>
  make_repo "$1"
  record "$1" "$ECC_PIN" upstream/ecc
  tgit -C "$1" commit -qm "record the pins"
  mkdir -p "$SANDBOX/modules"
  tgit clone -q --no-checkout --separate-git-dir "$SANDBOX/modules/$(basename "$1")" "$2" "$1/upstream/ecc"
}
only_git() { [ "$(ls -A "$1")" = .git ]; }
FLAGS=(--skip-omc --skip-gstack --skip-superpowers --skip-archify --skip-tools)

echo "[1/2] incomplete clone whose recorded commit is not on the remote"
C="$SANDBOX/repo-tip"; half_clone_checkout "$C" "$ECC_TIP_ONLY"
check "fixture: upstream/ecc holds only .git"             "$(yes_if only_git "$C/upstream/ecc")"
H="$SANDBOX/home-tip"; mkdir -p "$H"
REDIRECTS=(); redirect "$ECC_URL" "$ECC_TIP_ONLY"
run_install "$H" "$C" "${FLAGS[@]}"
check "a warning names upstream/ecc as an incomplete clone" "$(yes_if in_log "$H" "WARNING: upstream/ecc has a .git but no checked-out files")"
check "ECC reported as failed"                            "$(yes_if in_log "$H" "WARNING: ECC install failed")"
check "nothing from the remote's tip installed"           "$(yes_if [ ! -e "$H/.claude/skills/$ECC_SKILL" ])"

echo "[2/2] incomplete clone with HEAD at the recorded commit, no remote reachable"
C="$SANDBOX/repo-pin"; half_clone_checkout "$C" "$ECC_REMOTE"
# Neither the clone's own remote nor the ECC URL (no redirect: https is not an
# allowed protocol here) can be fetched from: only an in-place checkout works.
tgit -C "$C/upstream/ecc" remote set-url origin "$SANDBOX/no-such-remote"
head_at_pin() { [ "$(tgit -C "$1" rev-parse HEAD 2>/dev/null)" = "$ECC_PIN" ]; }
check "fixture: upstream/ecc holds only .git"             "$(yes_if only_git "$C/upstream/ecc")"
check "fixture: its HEAD is the recorded commit"          "$(yes_if head_at_pin "$C/upstream/ecc")"
H="$SANDBOX/home-pin"; mkdir -p "$H"
REDIRECTS=()
run_install "$H" "$C" "${FLAGS[@]}"
check "a warning names upstream/ecc as an incomplete clone" "$(yes_if in_log "$H" "WARNING: upstream/ecc has a .git but no checked-out files")"
check "upstream/ecc checked out in place at the recorded commit" \
  "$(yes_if holds "$C/upstream/ecc/skills/$ECC_SKILL/SKILL.md" pinned)"
check "no clone fallback needed"                          "$(yes_if not in_log "$H" "falling back to git clone")"
check "ECC skill installed from the recorded commit"      "$(yes_if holds "$H/.claude/skills/$ECC_SKILL/SKILL.md" pinned)"
check "ECC rule set installed from the recorded commit"   "$(yes_if holds "$H/.claude/rules/$ECC_RULE/rule.md" pinned)"
check "ECC not reported as failed"                        "$(yes_if not in_log "$H" "ECC install failed")"

finish
