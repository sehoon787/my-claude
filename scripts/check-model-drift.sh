#!/usr/bin/env bash
#
# check-model-drift.sh — fail if any stale (previous-generation) model ID
# is still referenced in repo-owned files.
#
# Current generation (do NOT flag): claude-opus-4-8, claude-sonnet-5,
# claude-haiku-4-5.
#
# To roll forward on the next model generation, update OLD_MODEL_PATTERN and
# (if a doc/migration file legitimately references an old ID) EXCLUDE_PATHS.
#
# Excluded by design:
#   - upstream/  : vendored third-party submodules, not ours to police.
#   - .git/      : object store.
#   - AI-INSTALL.md : deliberately shows an old model ID in a troubleshooting
#                     example ("Boss still shows an old model, e.g. ...").

set -uo pipefail

# Previous-generation Claude model IDs. Extend this alternation as the
# current generation moves forward. Overridable via env (the CI workflow sets
# it at the top of smoke.yml so the list lives in one obvious place).
OLD_MODEL_PATTERN="${OLD_MODEL_PATTERN:-claude-opus-4-[0-7]|claude-sonnet-4-[0-9]|claude-haiku-4-[0-4]|claude-(2|3)([.-]|$)}"

# Path fragments to exclude from the scan (grep -E, matched against file path).
EXCLUDE_PATHS="${EXCLUDE_PATHS:-(^|/)upstream/|(^|/)\.git/|(^|/)AI-INSTALL\.md$}"

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

# Enumerate tracked files, drop excluded paths, grep the rest.
mapfile -t candidates < <(git ls-files 2>/dev/null | grep -vE "$EXCLUDE_PATHS" || true)

if [ "${#candidates[@]}" -eq 0 ]; then
  echo "No candidate files to scan."
  exit 0
fi

hits=$(printf '%s\n' "${candidates[@]}" | tr '\n' '\0' \
  | xargs -0 grep -nEI "$OLD_MODEL_PATTERN" 2>/dev/null || true)

if [ -n "$hits" ]; then
  echo "FAIL: stale (previous-generation) model IDs found:"
  echo "$hits" | sed 's/^/  /'
  echo ""
  echo "Update these to the current generation (claude-opus-4-8 / claude-sonnet-5 / claude-haiku-4-5),"
  echo "or add a deliberate exception to EXCLUDE_PATHS in scripts/check-model-drift.sh."
  exit 1
fi

echo "OK: no stale model IDs in ${#candidates[@]} scanned files."
