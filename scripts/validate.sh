#!/usr/bin/env bash
set -euo pipefail

SKIP_SUBMODULES=false
for arg in "$@"; do
  if [ "$arg" = "--skip-submodules" ]; then
    SKIP_SUBMODULES=true
  fi
done

if [ "$SKIP_SUBMODULES" = false ]; then
  git submodule update --init --depth 1
fi

# Validate JSON files
python3 -c "import json; json.load(open('.claude-plugin/plugin.json'))"
python3 -c "import json; json.load(open('hooks/hooks.json'))"
python3 -c "import json; json.load(open('.mcp.json'))"
python3 -c "import json; json.load(open('settings.json'))"

# Check required agent files exist
test -f "agents/core/boss.md" || (echo "Missing agent: boss" && exit 1)
test -f "agents/core/agent-teams-reference.md" || (echo "Missing: agent-teams-reference.md" && exit 1)
for agent in sisyphus hephaestus metis atlas oracle momus prometheus librarian multimodal-looker; do
  test -f "agents/omo/${agent}.md" || (echo "Missing agent: ${agent}" && exit 1)
done

# Validate agent frontmatter
for f in agents/core/boss.md agents/omo/*.md; do
  head -1 "$f" | grep -q '^---' || (echo "Missing frontmatter in $f" && exit 1)
done

# Check skills/core SKILL.md count
COUNT=$(find skills/core -name 'SKILL.md' 2>/dev/null | wc -l)
[ "$COUNT" -ge 2 ] || (echo "FAIL: skills/core has $COUNT SKILL.md files (expected >= 2)" && exit 1)
echo "OK: skills/core — $COUNT skills"

# Validate upstream submodule file counts
for sub in agency-agents ecc omc gstack superpowers; do
  subdir="upstream/$sub"
  [ -d "$subdir" ] && [ -n "$(ls -A "$subdir" 2>/dev/null)" ] || { echo "SKIP: $subdir not initialized"; continue; }
  case "$sub" in
    agency-agents)
      COUNT=$(find "$subdir" -name '*.md' | wc -l)
      [ "$COUNT" -ge 100 ] || (echo "FAIL: $sub has $COUNT agents" && exit 1)
      echo "OK: $sub — $COUNT agents" ;;
    ecc)
      COUNT=$(find "$subdir/skills" -name 'SKILL.md' | wc -l)
      [ "$COUNT" -ge 30 ] || (echo "FAIL: $sub has $COUNT skills" && exit 1)
      echo "OK: $sub — $COUNT skills" ;;
    omc)
      COUNT=$(find "$subdir/agents" -name '*.md' | wc -l)
      [ "$COUNT" -ge 15 ] || (echo "FAIL: $sub has $COUNT agents" && exit 1)
      echo "OK: $sub — $COUNT agents" ;;
    gstack)
      COUNT=$(find "$subdir" -name 'SKILL.md' | wc -l)
      [ "$COUNT" -ge 20 ] || (echo "FAIL: $sub has $COUNT skills" && exit 1)
      echo "OK: $sub — $COUNT skills" ;;
    superpowers)
      COUNT=$(find "$subdir/agents" -name '*.md' | wc -l)
      [ "$COUNT" -ge 1 ] || (echo "FAIL: $sub has $COUNT agents" && exit 1)
      echo "OK: $sub — $COUNT agents" ;;
  esac
done

echo "All validations passed"
