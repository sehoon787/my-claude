#!/usr/bin/env bash
#
# check-dangling-refs.sh — fail CI when a routing surface (boss.md,
# boss-advanced, gstack-sprint) names a skill/agent the install would not
# actually provide.
#
# Builds the INSTALLABLE set from repo sources only (no network, no
# installed-machine access — CI runs from a clean checkout where upstream/*
# submodules may be uninitialized) and compares it against every
# backtick-quoted or slash-command name referenced in the routing surfaces.
# A referenced name is DANGLING when it is in DENYLIST (known-cut) or
# otherwise absent from INSTALLABLE.
#
# Ordinary prose words (`model`, `resume`, "boss", ...) are never flagged —
# a candidate is only checked when it also appears in KNOWN_EVER
# (INSTALLABLE ∪ DENYLIST). That keeps the check deterministic without a
# curated word-exclusion list.

set -uo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

# shellcheck source=scripts/skill-allowlists.sh
. scripts/skill-allowlists.sh

in_list() { case " $2 " in *" $1 "*) return 0 ;; *) return 1 ;; esac; }

# ── superpowers: derive from the submodule when initialized, else fall back.
# Fallback mirrors `ls upstream/superpowers/skills` as pinned by this repo;
# SUPERPOWERS_SKILL_EXCLUDE is applied the same way regardless of source. ──
FALLBACK_SUPERPOWERS="
brainstorming dispatching-parallel-agents executing-plans
finishing-a-development-branch receiving-code-review requesting-code-review
subagent-driven-development systematic-debugging test-driven-development
using-git-worktrees using-superpowers verification-before-completion
writing-plans writing-skills
"
if [ -d upstream/superpowers/skills ] && [ -n "$(ls -A upstream/superpowers/skills 2>/dev/null)" ]; then
  sp_names="$(ls upstream/superpowers/skills)"
else
  sp_names="$FALLBACK_SUPERPOWERS"
fi
superpowers=""
for n in $sp_names; do
  in_list "$n" "$SUPERPOWERS_SKILL_EXCLUDE" && continue
  superpowers="$superpowers $n"
done

# ── OMC agents: derive from the submodule when initialized, else fall back.
# Fallback mirrors `ls upstream/omc/agents` as pinned by this repo (the 19
# agents installed flat into ~/.claude/agents/). ──
FALLBACK_OMC_AGENTS="
analyst architect code-reviewer code-simplifier critic debugger designer
document-specialist executor explore git-master planner qa-tester scientist
security-reviewer test-engineer tracer verifier writer
"
if [ -d upstream/omc/agents ] && [ -n "$(ls -A upstream/omc/agents 2>/dev/null)" ]; then
  omc_agents="$(ls upstream/omc/agents)"
else
  omc_agents="$FALLBACK_OMC_AGENTS"
fi

skills_core="$(ls skills/core)"
agents_core="$(ls agents/core | grep -v '^agent-teams-reference\.md$')"
agents_omo="$(ls agents/omo)"
agents_vendored="$(ls agents/vendored)"

# echo with unquoted expansion re-splits every newline- or space-separated
# source list into one clean space-joined string (same idiom install.sh uses
# for SUPERPOWERS_SKILL_EXCLUDE matching). Strip .md so basenames compare
# clean against routing-file references.
INSTALLABLE="$(echo $ECC_SKILL_ALLOWLIST $GSTACK_SKILL_ALLOWLIST $OMC_SKILL_ALLOWLIST \
  $skills_core gstack $superpowers pdf docx pptx xlsx doc-coauthoring \
  $agents_core $agents_omo $agents_vendored $omc_agents | sed 's/\.md//g')"

# ── known-cut names: skills/agents removed in earlier dependency-graph
# reconciliation passes. Referencing one of these is always dangling. ──
DENYLIST="trace deep-dive tdd-workflow blueprint sciomc market-research plan-orchestrate make-pdf skillify plan-canvas git-workflow team-builder autoresearch research-ops dispatching-parallel-agents benchmark-models context-save context-restore devex-review"

FILES="agents/core/boss.md skills/core/boss-advanced/SKILL.md skills/core/gstack-sprint/SKILL.md"

fail=0
checked=0
for f in $FILES; do
  [ -f "$f" ] || continue
  while IFS=: read -r lineno match; do
    [ -n "${lineno:-}" ] || continue
    name="${match#\`}"; name="${name%\`}"; name="${name#/}"
    [ -n "$name" ] || continue
    checked=$((checked + 1))
    in_list "$name" "$INSTALLABLE" && continue
    if in_list "$name" "$DENYLIST"; then
      echo "DANGLING $f:$lineno: '$name' is referenced but not installable"
      fail=1
    fi
  done < <(grep -noE '`[a-z0-9][a-z0-9-]+`|/[a-z0-9][a-z0-9-]+' "$f")
done

if [ "$fail" -eq 1 ]; then
  echo "check-dangling-refs: at least one routing surface references an uninstallable name."
  exit 1
fi
echo "check-dangling-refs: OK — $checked candidate reference(s) checked, none dangling."
