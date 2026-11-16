#!/usr/bin/env bash
#
# anthropic-skills.test.sh — install.sh step [5a] must not count a husk (a skill
# directory without SKILL.md) as an installed Anthropic skill.
# `bash tests/anthropic-skills.test.sh`
#
# Root cause this guards against: before 6bc7841 the install manifest recorded
# only a skill's top-level SKILL.md, so the manifest-diff cleanup deleted
# SKILL.md and left the rest of the directory behind. [5a] only asked
# `[ -d pdf ] && [ -d docx ]`, so it printed "already installed" forever and
# the skills were never loaded.
#
# Sources scripts/anthropic-skills.sh (the guard install.sh calls) and checks it
# against throwaway HOMEs. The fallback's own `cp -r` line is pulled out of
# install.sh and replayed against a fake anthropics/skills clone. Nothing outside
# the temp dir is written and nothing touches the network.
#
# hooks/session-start.sh installs the same skills but cannot source that script,
# so it repeats the condition inline. Its `if` is pulled out of the hook and held
# to the guard's verdict (running the hook would also run its OMC/npm steps).
set -uo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=scripts/anthropic-skills.sh
. "$REPO/scripts/anthropic-skills.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fail=0
check() {
  if [ "$2" = "1" ]; then
    echo "PASS  $1"
  else
    echo "FAIL  $1"
    fail=1
  fi
}

# The guard's verdict under a throwaway HOME, as the 1/0 that check() takes.
installed()     { ( HOME="$1"; anthropic_skills_installed ) && echo 1 || echo 0; }
not_installed() { ( HOME="$1"; anthropic_skills_installed ) && echo 0 || echo 1; }

# What the pre-6bc7841 cleanup left behind: everything in the skill but SKILL.md.
make_husk() {  # make_husk <home> <skill>
  local dir="$1/.claude/skills/$2"
  mkdir -p "$dir/scripts"
  echo "# forms"     > "$dir/forms.md"
  echo "# reference" > "$dir/reference.md"
  echo "# license"   > "$dir/LICENSE.txt"
  echo "# helper"    > "$dir/scripts/helper.py"
  echo "# mine"      > "$dir/notes.md"   # in the husk only, never shipped upstream
}

echo "[1/4] guard"
H="$TMP/fresh"
mkdir -p "$H"
check "no skills at all: not installed" "$(not_installed "$H")"

H="$TMP/husks"
make_husk "$H" pdf; make_husk "$H" docx
check "husk pdf/ and docx/ without SKILL.md: not installed" "$(not_installed "$H")"

H="$TMP/half-repaired"
make_husk "$H" pdf; make_husk "$H" docx
echo "# pdf" > "$H/.claude/skills/pdf/SKILL.md"
check "SKILL.md in pdf/ only: not installed" "$(not_installed "$H")"

H="$TMP/skillmd-is-a-directory"
make_husk "$H" pdf; make_husk "$H" docx
mkdir "$H/.claude/skills/pdf/SKILL.md" "$H/.claude/skills/docx/SKILL.md"
check "SKILL.md that is a directory, not a regular file: not installed" "$(not_installed "$H")"

H="$TMP/installed"
make_husk "$H" pdf; make_husk "$H" docx
echo "# pdf" > "$H/.claude/skills/pdf/SKILL.md"
echo "# docx" > "$H/.claude/skills/docx/SKILL.md"
check "SKILL.md in pdf/ and docx/: installed" "$(installed "$H")"

echo "[2/4] the fallback copy repairs a husk"
# install.sh clones into $_tmp_skills/skills, and the skills live in its skills/.
CLONE="$TMP/clone"
for skill in pdf docx; do
  mkdir -p "$CLONE/skills/skills/$skill/scripts"
  echo "# $skill"          > "$CLONE/skills/skills/$skill/SKILL.md"
  echo "# upstream forms"  > "$CLONE/skills/skills/$skill/forms.md"
  echo "# upstream helper" > "$CLONE/skills/skills/$skill/scripts/helper.py"
done
# Run the cp line from install.sh itself, not a re-typed copy, so it cannot drift.
COPY_CMD="$(grep -F 'cp -r "$_tmp_skills/skills/skills/"' "$REPO/install.sh")"
check "install.sh still copies the clone with one cp -r line" "$([ -n "$COPY_CMD" ] && echo 1 || echo 0)"

H="$TMP/repaired"
make_husk "$H" pdf; make_husk "$H" docx
_tmp_skills="$CLONE" HOME="$H" bash -c "$COPY_CMD"
S="$H/.claude/skills"
check "SKILL.md restored in both husks" \
  "$([ -f "$S/pdf/SKILL.md" ] && [ -f "$S/docx/SKILL.md" ] && echo 1 || echo 0)"
check "husk files kept (forms.md, reference.md, LICENSE.txt, scripts/)" \
  "$([ -f "$S/pdf/forms.md" ] && [ -f "$S/pdf/reference.md" ] && [ -f "$S/pdf/LICENSE.txt" ] && [ -f "$S/pdf/scripts/helper.py" ] && echo 1 || echo 0)"
check "file only the husk had is left alone" \
  "$([ "$(cat "$S/pdf/notes.md" 2>/dev/null)" = "# mine" ] && echo 1 || echo 0)"
check "copied into the husk, not nested inside it (no pdf/pdf)" \
  "$([ ! -e "$S/pdf/pdf" ] && [ ! -e "$S/docx/docx" ] && echo 1 || echo 0)"
check "guard reports installed after the repair" "$(installed "$H")"

echo "[3/4] install.sh wiring"
check "install.sh sources the guard from scripts/" \
  "$(grep -qF '. "$SCRIPT_DIR/scripts/anthropic-skills.sh"' "$REPO/install.sh" && echo 1 || echo 0)"
check "install.sh [5a] branches on the guard" \
  "$(grep -q '^if anthropic_skills_installed; then$' "$REPO/install.sh" && echo 1 || echo 0)"

echo "[4/4] hooks/session-start.sh"
# Evaluate the hook's own condition under every HOME built in [1/4].
HOOK_COND="$(sed -n 's/^if \(.*skills\/pdf.*\); then$/\1/p' "$REPO/hooks/session-start.sh")"
check "hook still has its Anthropic skills condition" "$([ -n "$HOOK_COND" ] && echo 1 || echo 0)"
hook_installs() { ( HOME="$1"; eval "$HOOK_COND" ) && echo 1 || echo 0; }
for scenario in fresh husks half-repaired skillmd-is-a-directory installed; do
  check "hook installs exactly when the guard says not installed ($scenario)" \
    "$([ "$(hook_installs "$TMP/$scenario")" = "$(not_installed "$TMP/$scenario")" ] && echo 1 || echo 0)"
done

if [ "$fail" -eq 0 ]; then
  echo "ALL PASSED"
else
  echo "FAILED"
fi
exit "$fail"
