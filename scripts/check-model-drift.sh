#!/usr/bin/env bash
#
# check-model-drift.sh — guard the model IDs this repo ships.
#
# Two complementary checks, because a wrong model ID fails in two directions:
#
#   1. Stale (blacklist, repo-wide)  — an ID that was real but is now previous
#      generation. Scanned across all tracked files.
#   2. Unknown (allowlist, agents/)  — an ID that is neither current nor
#      known-old: a typo, or a slug that was never served. Scoped to the
#      structured `model:` field so prose can never trip it.
#
# Check 2 exists because check 1 cannot catch a nonexistent ID — it only knows
# what to reject, not what to accept.
#
# Current generation (do NOT flag): claude-fable-5, claude-opus-5,
# claude-sonnet-5, claude-haiku-4-5.
#
# To roll forward on the next model generation, update OLD_MODEL_PATTERN,
# VALID_MODELS, and (if a doc/migration file legitimately references an old
# ID) EXCLUDE_PATHS. Keep the two lists consistent: anything OLD_MODEL_PATTERN
# rejects must not appear in VALID_MODELS.
#
# Excluded by design:
#   - upstream/  : vendored third-party submodules, not ours to police.
#   - .git/      : object store.
#   - AI-INSTALL.md : deliberately shows an old model ID in a troubleshooting
#                     example ("Boss still shows an old model, e.g. ...").

set -uo pipefail

# Previous-generation Claude model IDs. Extend this alternation as the
# current generation moves forward. Overridable via env for local testing;
# CI (smoke.yml) calls this script with no override, so this default is the
# single source of truth — do not duplicate it elsewhere.
OLD_MODEL_PATTERN="${OLD_MODEL_PATTERN:-claude-opus-4-[0-9]|claude-sonnet-4-[0-9]|claude-haiku-4-[0-4]|claude-(2|3)([.-]|$)}"

# Path fragments to exclude from the scan (grep -E, matched against file path).
#   - this script : VALID_MODELS below spells out real IDs, so the stale-ID
#                   scan would otherwise flag the allowlist itself.
EXCLUDE_PATHS="${EXCLUDE_PATHS:-(^|/)upstream/|(^|/)\.git/|(^|/)AI-INSTALL\.md$|(^|/)scripts/check-model-drift\.sh$}"

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

# Enumerate tracked files, drop excluded paths, grep the rest.
# `while read` rather than `mapfile`: mapfile is bash 4+, and macOS ships
# bash 3.2, so mapfile made this script impossible to run locally.
candidates=""
while IFS= read -r f; do
  candidates="$candidates$f
"
done < <(git ls-files 2>/dev/null | grep -vE "$EXCLUDE_PATHS" || true)

candidate_count=$(printf '%s' "$candidates" | grep -c . || true)
if [ "$candidate_count" -eq 0 ]; then
  echo "No candidate files to scan."
  exit 0
fi

status=0

# ── Check 1: stale IDs (blacklist) ──────────────────────────────────────
hits=$(printf '%s' "$candidates" | tr '\n' '\0' \
  | xargs -0 grep -nEI "$OLD_MODEL_PATTERN" 2>/dev/null || true)

if [ -n "$hits" ]; then
  echo "FAIL: stale (previous-generation) model IDs found:"
  echo "$hits" | sed 's/^/  /'
  echo ""
  echo "Update these to the current generation (claude-fable-5 / claude-opus-5 / claude-sonnet-5 / claude-haiku-4-5),"
  echo "or add a deliberate exception to EXCLUDE_PATHS in scripts/check-model-drift.sh."
  status=1
fi

# ── Check 2: unknown IDs (allowlist) ────────────────────────────────────
#
# Check 1 only catches IDs we already know are old. It cannot catch the
# opposite failure: a value that is neither old nor real — a typo, or a slug
# the API never served. That gap is not hypothetical; the sibling my-codex
# repo shipped a bare `gpt-5.6` for weeks (the 5.6 generation only has
# suffixed slugs), and every stale-pattern check passed the whole time
# because the value was not *old*, just nonexistent.
#
# Scoped to the structured `model:` field under agents/ — never prose. A model
# ID mentioned in a doc, comment, or migration note cannot trip this, which is
# what keeps the check trustworthy enough to stay wired into CI.
# Deliberately narrower than "every model the API serves". Opus 4.6-4.8 and
# Sonnet 4.6 are still served, but this repo treats them as previous
# generation — OLD_MODEL_PATTERN above already rejects them. Listing them as
# valid here would put the two checks in direct contradiction. Bare aliases
# are included because Claude Code resolves them and upstream agents use them.
VALID_MODELS="${VALID_MODELS:-claude-fable-5 claude-mythos-5 claude-opus-5 claude-sonnet-5 claude-haiku-4-5 opus sonnet haiku}"

unknown=""
while IFS= read -r line; do
  [ -n "$line" ] || continue
  file="${line%%:*}"
  rest="${line#*:}"
  lineno="${rest%%:*}"
  value=$(printf '%s' "${rest#*:}" | sed 's/^model:[[:space:]]*//; s/[[:space:]]*$//')
  [ -n "$value" ] || continue
  case " $VALID_MODELS " in
    *" $value "*) ;;
    *) unknown="$unknown  $file:$lineno: $value
" ;;
  esac
done < <(grep -rn '^model:' agents/ 2>/dev/null || true)

if [ -n "$unknown" ]; then
  echo "FAIL: unrecognised model IDs in agent frontmatter:"
  printf '%s' "$unknown"
  echo ""
  echo "These are neither current nor known-old — most likely a typo or a slug that is not served."
  echo "Fix the value, or add it to VALID_MODELS in scripts/check-model-drift.sh if it is genuinely new."
  status=1
fi

[ "$status" -eq 0 ] || exit 1

agent_models=$(grep -rc '^model:' agents/ 2>/dev/null | awk -F: '{s+=$2} END {print s+0}')
echo "OK: no stale model IDs in $candidate_count scanned files; $agent_models agent model values all recognised."
