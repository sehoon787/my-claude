#!/usr/bin/env bash
#
# install-ecc-submodule.test.sh — step [1c] installs ECC from the pinned
# upstream/ecc submodule only, never through a Claude Code plugin command.
# `bash tests/install-ecc-submodule.test.sh`
#
# [1c] first ran `claude plugin add affaan-m/everything-claude-code` and used
# the submodule only when that failed. Claude Code has no `plugin add`
# subcommand (2.1.328: `claude plugin --help` lists install, marketplace, ...),
# so it always failed and the submodule was the real install path. A plugin
# command that did succeed would install all of ECC from its marketplace at
# upstream HEAD — past the SHA pin and the skill allowlist — and skip the
# allowlisted rules, which only the submodule path copies. The claude shim here
# accepts every plugin command, the case in which that bypass would happen:
#   1. No `claude plugin add`, `install` or `marketplace add` call.
#   2. The allowlisted skill, rule set and rules/common file come from the
#      recorded commit.
#
# Runs install.sh in the shared sandbox (tests/lib/install-sandbox.sh): a
# throwaway HOME, TMPDIR and npm prefix, shimmed installers, local git only.
set -uo pipefail
. "$(dirname "$0")/lib/install-sandbox.sh"
# shellcheck source=../scripts/skill-allowlists.sh
. "$REPO/scripts/skill-allowlists.sh"
for ECC_SKILL in $ECC_SKILL_ALLOWLIST; do break; done
for ECC_RULE in $ECC_RULES_ALLOWLIST; do break; done
for ECC_COMMON_RULE in $ECC_RULES_COMMON_ALLOWLIST; do break; done

# upstream/ecc checked out at the recorded commit, like an initialized submodule.
C="$SANDBOX/repo"
make_repo "$C"
make_module "$C/upstream/ecc" ecc
mkdir -p "$C/upstream/ecc/skills/$ECC_SKILL" "$C/upstream/ecc/rules/$ECC_RULE" "$C/upstream/ecc/rules/common"
printf -- '---\nname: %s\n---\npinned\n' "$ECC_SKILL" > "$C/upstream/ecc/skills/$ECC_SKILL/SKILL.md"
echo pinned > "$C/upstream/ecc/rules/$ECC_RULE/rule.md"
echo pinned > "$C/upstream/ecc/rules/common/$ECC_COMMON_RULE"
record "$C" "$(commit_all "$C/upstream/ecc" "ecc at the pin")" upstream/ecc

echo "[1/1] a claude CLI that accepts every plugin command"
H="$SANDBOX/home"; mkdir -p "$H"
CLAUDE_SHIM_ACCEPT_ALL=1
run_install "$H" "$C" --skip-omc --skip-gstack --skip-superpowers --skip-archify --skip-tools
check "no claude plugin add/install/marketplace add call" "$(yes_if not grep -Eq '^claude plugin (add|install|i|marketplace add) ' "$H/shim.log")"
check "ECC skill installed from the recorded commit"      "$(yes_if holds "$H/.claude/skills/$ECC_SKILL/SKILL.md" pinned)"
check "ECC rule set installed from the recorded commit"   "$(yes_if holds "$H/.claude/rules/$ECC_RULE/rule.md" pinned)"
check "ECC rules/common file installed from the recorded commit" "$(yes_if holds "$H/.claude/rules/common/$ECC_COMMON_RULE" pinned)"

finish
