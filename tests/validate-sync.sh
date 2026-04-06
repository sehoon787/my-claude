#!/usr/bin/env bash
# Validate sync integrity — run after sync-upstream workflow
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

ERRORS=0

echo "=== Sync Integrity Validation ==="

# 1. Core agents exist
CORE_COUNT=$(find agents/core -name '*.md' 2>/dev/null | wc -l)
if [ "$CORE_COUNT" -lt 2 ]; then
  echo "FAIL: agents/core has $CORE_COUNT files (expected >= 2)"
  ERRORS=$((ERRORS + 1))
else
  echo "OK: agents/core — $CORE_COUNT files"
fi

# 1b. OMO agents exist
OMO_COUNT=$(find agents/omo -name '*.md' 2>/dev/null | wc -l)
if [ "$OMO_COUNT" -lt 9 ]; then
  echo "FAIL: agents/omo has $OMO_COUNT files (expected >= 9)"
  ERRORS=$((ERRORS + 1))
else
  echo "OK: agents/omo — $OMO_COUNT agents"
fi

# 2. Agency agents exist
AGENCY_COUNT=$(find agents/agency -name '*.md' 2>/dev/null | wc -l)
if [ "$AGENCY_COUNT" -lt 100 ]; then
  echo "FAIL: agents/agency has $AGENCY_COUNT files (expected >= 100)"
  ERRORS=$((ERRORS + 1))
else
  echo "OK: agents/agency — $AGENCY_COUNT agents"
fi

# 3. OMC agents exist
OMC_AGENT_COUNT=$(find agents/omc -name '*.md' 2>/dev/null | wc -l)
if [ "$OMC_AGENT_COUNT" -lt 15 ]; then
  echo "FAIL: agents/omc has $OMC_AGENT_COUNT files (expected >= 15)"
  ERRORS=$((ERRORS + 1))
else
  echo "OK: agents/omc — $OMC_AGENT_COUNT agents"
fi

# 3b. Superpowers agents exist
SUPERPOWERS_AGENT_COUNT=$(find agents/superpowers -name '*.md' 2>/dev/null | wc -l)
if [ "$SUPERPOWERS_AGENT_COUNT" -lt 1 ]; then
  echo "FAIL: agents/superpowers has $SUPERPOWERS_AGENT_COUNT files (expected >= 1)"
  ERRORS=$((ERRORS + 1))
else
  echo "OK: agents/superpowers — $SUPERPOWERS_AGENT_COUNT agents"
fi

# 4. ECC skills exist
ECC_SKILL_COUNT=$(find skills/ecc -name 'SKILL.md' 2>/dev/null | wc -l)
if [ "$ECC_SKILL_COUNT" -lt 33 ]; then
  echo "FAIL: skills/ecc has $ECC_SKILL_COUNT skills (expected >= 33)"
  ERRORS=$((ERRORS + 1))
else
  echo "OK: skills/ecc — $ECC_SKILL_COUNT skills"
fi

# 5. OMC skills exist
OMC_SKILL_COUNT=$(find skills/omc -name 'SKILL.md' 2>/dev/null | wc -l)
if [ "$OMC_SKILL_COUNT" -lt 20 ]; then
  echo "FAIL: skills/omc has $OMC_SKILL_COUNT skills (expected >= 20)"
  ERRORS=$((ERRORS + 1))
else
  echo "OK: skills/omc — $OMC_SKILL_COUNT skills"
fi

# 5b. Core skills exist
CORE_SKILL_COUNT=$(find skills/core -name 'SKILL.md' 2>/dev/null | wc -l)
if [ "$CORE_SKILL_COUNT" -lt 1 ]; then
  echo "FAIL: skills/core has $CORE_SKILL_COUNT skills (expected >= 1)"
  ERRORS=$((ERRORS + 1))
else
  echo "OK: skills/core — $CORE_SKILL_COUNT skills"
fi

# 5c. gstack skills exist (vendored)
GSTACK_SKILL_COUNT=$(find skills/gstack -name 'SKILL.md' 2>/dev/null | wc -l)
if [ "$GSTACK_SKILL_COUNT" -lt 20 ]; then
  echo "FAIL: skills/gstack has $GSTACK_SKILL_COUNT skills (expected >= 20)"
  ERRORS=$((ERRORS + 1))
else
  echo "OK: skills/gstack — $GSTACK_SKILL_COUNT skills"
fi

# 5d. Superpowers skills exist
SUPERPOWERS_SKILL_COUNT=$(find skills/superpowers -name 'SKILL.md' 2>/dev/null | wc -l)
if [ "$SUPERPOWERS_SKILL_COUNT" -lt 10 ]; then
  echo "FAIL: skills/superpowers has $SUPERPOWERS_SKILL_COUNT skills (expected >= 10)"
  ERRORS=$((ERRORS + 1))
else
  echo "OK: skills/superpowers — $SUPERPOWERS_SKILL_COUNT skills"
fi

# 6. Rules exist
RULE_COUNT=$(find rules -name '*.md' ! -name 'README.md' 2>/dev/null | wc -l)
if [ "$RULE_COUNT" -lt 10 ]; then
  echo "FAIL: rules has $RULE_COUNT files (expected >= 10)"
  ERRORS=$((ERRORS + 1))
else
  echo "OK: rules — $RULE_COUNT rule files"
fi

# 7. SOURCES.json exists and is valid JSON
if [ -f upstream/SOURCES.json ]; then
  node -e "JSON.parse(require('fs').readFileSync('upstream/SOURCES.json','utf8'))" 2>/dev/null
  if [ $? -eq 0 ]; then
    echo "OK: upstream/SOURCES.json is valid JSON"
  else
    echo "FAIL: upstream/SOURCES.json is not valid JSON"
    ERRORS=$((ERRORS + 1))
  fi
else
  echo "FAIL: upstream/SOURCES.json not found"
  ERRORS=$((ERRORS + 1))
fi

# 7b. SOURCES.json schema completeness
if [ -f upstream/SOURCES.json ]; then
  SCHEMA_ERRORS=0
  for src in agency-agents everything-claude-code oh-my-claudecode gstack superpowers; do
    SHA=$(node -e "const d=JSON.parse(require('fs').readFileSync('upstream/SOURCES.json','utf8')); console.log(d['$src']?.syncedSha || '')" 2>/dev/null)
    if [ -z "$SHA" ] || [ "$SHA" = "undefined" ]; then
      echo "FAIL: SOURCES.json missing syncedSha for $src"
      SCHEMA_ERRORS=$((SCHEMA_ERRORS + 1))
    fi
  done
  if [ "$SCHEMA_ERRORS" -gt 0 ]; then
    ERRORS=$((ERRORS + SCHEMA_ERRORS))
  else
    echo "OK: SOURCES.json has syncedSha for all 5 upstream sources"
  fi
fi

# 8. No duplicate agent filenames across scopes (warning only)
echo ""
echo "=== Duplicate Check (informational) ==="
for name in $(find agents -name '*.md' -exec basename {} \; | sort | uniq -d); do
  echo "INFO: duplicate agent name '$name' found in:"
  find agents -name "$name" -exec echo "  {}" \;
done

# 8b. Skill name collisions across sources
echo ""
echo "=== Skill Collision Check ==="
SKILL_COLLISIONS=0
for ecc_skill in skills/ecc/*/; do
  [ ! -d "$ecc_skill" ] && continue
  name=$(basename "$ecc_skill")
  for other_src in skills/omc skills/gstack skills/superpowers skills/core; do
    if [ -d "$other_src/$name" ]; then
      echo "WARN: skill '$name' exists in both skills/ecc/ and $other_src/"
      SKILL_COLLISIONS=$((SKILL_COLLISIONS + 1))
    fi
  done
done
if [ "$SKILL_COLLISIONS" -gt 0 ]; then
  echo "INFO: $SKILL_COLLISIONS skill name collisions found (check for intentional supersession)"
else
  echo "OK: No skill name collisions across sources"
fi

# 8c. ECC superseded skills removed
echo ""
echo "=== ECC Supersession Check ==="
SUPERSEDE_ERRORS=0
for skill in benchmark canary-watch safety-guard browser-qa verification-loop security-review design-system; do
  if [ -d "skills/ecc/$skill" ]; then
    echo "FAIL: skills/ecc/$skill should have been removed (superseded by gstack)"
    SUPERSEDE_ERRORS=$((SUPERSEDE_ERRORS + 1))
  fi
done
if [ "$SUPERSEDE_ERRORS" -gt 0 ]; then
  ERRORS=$((ERRORS + SUPERSEDE_ERRORS))
else
  echo "OK: All 7 ECC skills correctly superseded by gstack"
fi

# Summary
echo ""
TOTAL_AGENTS=$((CORE_COUNT + OMO_COUNT + AGENCY_COUNT + OMC_AGENT_COUNT + SUPERPOWERS_AGENT_COUNT))
TOTAL_SKILLS=$((ECC_SKILL_COUNT + OMC_SKILL_COUNT + CORE_SKILL_COUNT + GSTACK_SKILL_COUNT + SUPERPOWERS_SKILL_COUNT))
echo "=== Summary ==="
echo "Total agents: $TOTAL_AGENTS"
echo "Total skills: $TOTAL_SKILLS"
echo "Total rules:  $RULE_COUNT"
echo "Errors:       $ERRORS"

# 9. Validate docs/index.html counts match computed values
if [ -f docs/index.html ]; then
  HTML_AGENTS=$(perl -ne 'print "$1\n" while /data-count="(\d+)">0<\/em>\s*<span[^>]*data-en="agents"/g' docs/index.html | head -1)
  HTML_SKILLS=$(perl -ne 'print "$1\n" while /data-count="(\d+)">0<\/em>\s*<span[^>]*data-en="skills"/g' docs/index.html | head -1)
  if [ -z "$HTML_AGENTS" ] || [ -z "$HTML_SKILLS" ]; then
    echo "WARN: docs/index.html data-count attributes not found — skipping count check"
  else
    # agents: warn if stale (CI workflow updates these counts)
    if [ "$HTML_AGENTS" != "$TOTAL_AGENTS" ]; then
      echo "WARN: docs/index.html agents=$HTML_AGENTS expected=$TOTAL_AGENTS (CI will fix)"
    else
      echo "OK: docs/index.html agents count — $HTML_AGENTS"
    fi
    # skills: warn if stale (CI workflow updates these counts)
    if [ "$HTML_SKILLS" != "$TOTAL_SKILLS" ]; then
      echo "WARN: docs/index.html skills=$HTML_SKILLS expected=$TOTAL_SKILLS (CI will fix)"
    else
      echo "OK: docs/index.html skills count — $HTML_SKILLS"
    fi
  fi
fi

if [ "$ERRORS" -gt 0 ]; then
  echo "VALIDATION FAILED"
  exit 1
else
  echo "VALIDATION PASSED"
fi
