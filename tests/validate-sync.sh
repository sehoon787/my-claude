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

# 4. ECC skills exist
ECC_SKILL_COUNT=$(find skills/ecc -name 'SKILL.md' 2>/dev/null | wc -l)
if [ "$ECC_SKILL_COUNT" -lt 40 ]; then
  echo "FAIL: skills/ecc has $ECC_SKILL_COUNT skills (expected >= 40)"
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

# 8. No duplicate agent filenames across scopes (warning only)
echo ""
echo "=== Duplicate Check (informational) ==="
for name in $(find agents -name '*.md' -exec basename {} \; | sort | uniq -d); do
  echo "INFO: duplicate agent name '$name' found in:"
  find agents -name "$name" -exec echo "  {}" \;
done

# Summary
echo ""
TOTAL_AGENTS=$((CORE_COUNT + OMO_COUNT + AGENCY_COUNT + OMC_AGENT_COUNT))
TOTAL_SKILLS=$((ECC_SKILL_COUNT + OMC_SKILL_COUNT + CORE_SKILL_COUNT))
echo "=== Summary ==="
echo "Total agents: $TOTAL_AGENTS"
echo "Total skills: $TOTAL_SKILLS"
echo "Total rules:  $RULE_COUNT"
echo "Errors:       $ERRORS"

if [ "$ERRORS" -gt 0 ]; then
  echo "VALIDATION FAILED"
  exit 1
else
  echo "VALIDATION PASSED"
fi
