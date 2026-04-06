#!/usr/bin/env bash
# Validate submodule integrity and/or installation state
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

MODE="repo"
[ "${1:-}" = "--installed" ] && MODE="installed"

ERRORS=0

if [ "$MODE" = "repo" ]; then
  echo "=== Repo Validation (submodule-based) ==="

  # 1. Self-owned files exist
  for f in agents/core/boss.md agents/core/agent-teams-reference.md; do
    test -f "$f" && echo "OK: $f" || { echo "FAIL: $f missing"; ERRORS=$((ERRORS + 1)); }
  done

  OMO_COUNT=$(find agents/omo -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
  [ "$OMO_COUNT" -ge 9 ] && echo "OK: agents/omo — $OMO_COUNT agents" || { echo "FAIL: agents/omo has $OMO_COUNT (expected >= 9)"; ERRORS=$((ERRORS + 1)); }

  CORE_SKILL_COUNT=$(find skills/core -name 'SKILL.md' 2>/dev/null | wc -l | tr -d ' ')
  [ "$CORE_SKILL_COUNT" -ge 2 ] && echo "OK: skills/core — $CORE_SKILL_COUNT skills" || { echo "FAIL: skills/core has $CORE_SKILL_COUNT (expected >= 2)"; ERRORS=$((ERRORS + 1)); }

  # 2. Submodules initialized — check each
  echo ""
  echo "=== Submodule Validation ==="
  for sub in agency-agents ecc omc gstack superpowers; do
    subdir="upstream/$sub"
    if [ ! -d "$subdir" ] || [ -z "$(ls -A "$subdir" 2>/dev/null)" ]; then
      echo "SKIP: $subdir not initialized (run: git submodule update --init)"
      continue
    fi
    case "$sub" in
      agency-agents)
        COUNT=$(find "$subdir" -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
        [ "$COUNT" -ge 100 ] && echo "OK: $sub — $COUNT agents" || { echo "FAIL: $sub has $COUNT agents (expected >= 100)"; ERRORS=$((ERRORS + 1)); }
        ;;
      ecc)
        SKILL_COUNT=$(find "$subdir/skills" -name 'SKILL.md' 2>/dev/null | wc -l | tr -d ' ')
        [ "$SKILL_COUNT" -ge 30 ] && echo "OK: $sub — $SKILL_COUNT skills" || { echo "FAIL: $sub has $SKILL_COUNT skills (expected >= 30)"; ERRORS=$((ERRORS + 1)); }
        ;;
      omc)
        AGENT_COUNT=$(find "$subdir/agents" -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
        SKILL_COUNT=$(find "$subdir/skills" -name 'SKILL.md' 2>/dev/null | wc -l | tr -d ' ')
        [ "$AGENT_COUNT" -ge 15 ] && echo "OK: $sub — $AGENT_COUNT agents" || { echo "FAIL: $sub has $AGENT_COUNT agents (expected >= 15)"; ERRORS=$((ERRORS + 1)); }
        [ "$SKILL_COUNT" -ge 20 ] && echo "OK: $sub — $SKILL_COUNT skills" || { echo "FAIL: $sub has $SKILL_COUNT skills (expected >= 20)"; ERRORS=$((ERRORS + 1)); }
        ;;
      gstack)
        SKILL_COUNT=$(find "$subdir" -name 'SKILL.md' 2>/dev/null | wc -l | tr -d ' ')
        [ "$SKILL_COUNT" -ge 20 ] && echo "OK: $sub — $SKILL_COUNT skills" || { echo "FAIL: $sub has $SKILL_COUNT skills (expected >= 20)"; ERRORS=$((ERRORS + 1)); }
        ;;
      superpowers)
        AGENT_COUNT=$(find "$subdir/agents" -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
        SKILL_COUNT=$(find "$subdir/skills" -name 'SKILL.md' 2>/dev/null | wc -l | tr -d ' ')
        [ "$AGENT_COUNT" -ge 1 ] && echo "OK: $sub — $AGENT_COUNT agents" || { echo "FAIL: $sub has $AGENT_COUNT agents (expected >= 1)"; ERRORS=$((ERRORS + 1)); }
        [ "$SKILL_COUNT" -ge 10 ] && echo "OK: $sub — $SKILL_COUNT skills" || { echo "FAIL: $sub has $SKILL_COUNT skills (expected >= 10)"; ERRORS=$((ERRORS + 1)); }
        ;;
    esac
  done

  # 3. SOURCES.json valid
  echo ""
  if [ -f upstream/SOURCES.json ]; then
    node -e "JSON.parse(require('fs').readFileSync('upstream/SOURCES.json','utf8'))" 2>/dev/null \
      && echo "OK: upstream/SOURCES.json is valid JSON" \
      || { echo "FAIL: upstream/SOURCES.json is not valid JSON"; ERRORS=$((ERRORS + 1)); }
  else
    echo "FAIL: upstream/SOURCES.json not found"; ERRORS=$((ERRORS + 1))
  fi

  # 4. No duplicate agent filenames (informational)
  echo ""
  echo "=== Duplicate Check ==="
  ALL_AGENTS=$(mktemp)
  find agents -name '*.md' -exec basename {} \; 2>/dev/null >> "$ALL_AGENTS"
  for sub in agency-agents omc superpowers; do
    [ -d "upstream/$sub" ] && find "upstream/$sub" -path '*/agents/*.md' -exec basename {} \; 2>/dev/null >> "$ALL_AGENTS"
  done
  DUPES=$(sort "$ALL_AGENTS" | uniq -d | wc -l | tr -d ' ')
  [ "$DUPES" -eq 0 ] && echo "OK: No duplicate agent names" || echo "INFO: $DUPES duplicate agent name(s) found"
  rm -f "$ALL_AGENTS"

elif [ "$MODE" = "installed" ]; then
  echo "=== Install Validation (~/.claude/) ==="

  AGENT_COUNT=$(find "$HOME/.claude/agents" -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
  [ "$AGENT_COUNT" -ge 10 ] && echo "OK: agents — $AGENT_COUNT installed" || { echo "FAIL: agents has $AGENT_COUNT (expected >= 10)"; ERRORS=$((ERRORS + 1)); }

  SKILL_COUNT=$(find "$HOME/.claude/skills" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
  [ "$SKILL_COUNT" -ge 5 ] && echo "OK: skills — $SKILL_COUNT installed" || { echo "FAIL: skills has $SKILL_COUNT (expected >= 5)"; ERRORS=$((ERRORS + 1)); }

  [ -f "$HOME/.claude/hooks/hooks.json" ] && echo "OK: hooks.json present" || { echo "FAIL: hooks.json missing"; ERRORS=$((ERRORS + 1)); }
  [ -f "$HOME/.claude/settings.json" ] && echo "OK: settings.json present" || { echo "FAIL: settings.json missing"; ERRORS=$((ERRORS + 1)); }
  [ -f "$HOME/.claude/.my-claude-manifest" ] && echo "OK: manifest present" || { echo "FAIL: manifest missing"; ERRORS=$((ERRORS + 1)); }

  # Supersession check
  echo ""
  echo "=== Supersession Check ==="
  SUPERSEDE_ERRORS=0
  for skill in benchmark canary-watch safety-guard browser-qa verification-loop security-review design-system; do
    if [ -d "$HOME/.claude/skills/$skill" ]; then
      echo "FAIL: ~/.claude/skills/$skill should have been removed (superseded by gstack)"
      SUPERSEDE_ERRORS=$((SUPERSEDE_ERRORS + 1))
    fi
  done
  [ "$SUPERSEDE_ERRORS" -eq 0 ] && echo "OK: All 7 ECC skills correctly superseded" || ERRORS=$((ERRORS + SUPERSEDE_ERRORS))

  # Companion tools
  echo ""
  echo "=== Companion Tools ==="
  command -v omc >/dev/null 2>&1 && echo "OK: omc" || echo "WARN: omc not found"
  command -v oh-my-opencode >/dev/null 2>&1 && echo "OK: omo" || echo "WARN: omo not found"
  command -v ast-grep >/dev/null 2>&1 && echo "OK: ast-grep" || echo "WARN: ast-grep not found"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "Errors: $ERRORS"
[ "$ERRORS" -gt 0 ] && { echo "VALIDATION FAILED"; exit 1; } || echo "VALIDATION PASSED"
