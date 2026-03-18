#!/usr/bin/env bash
# Compare current bundle versions against upstream latest
set -euo pipefail
SOURCES="$(dirname "$0")/SOURCES.json"

if [ ! -f "$SOURCES" ]; then
  echo "ERROR: SOURCES.json not found at $SOURCES"
  exit 1
fi

echo "=== Upstream Version Check ==="
for repo in $(node -e "Object.keys(JSON.parse(require('fs').readFileSync('$SOURCES','utf8'))).forEach(k=>console.log(k))"); do
  URL=$(node -e "console.log(JSON.parse(require('fs').readFileSync('$SOURCES','utf8'))['$repo'].repo)")
  SYNCED=$(node -e "console.log(JSON.parse(require('fs').readFileSync('$SOURCES','utf8'))['$repo'].syncedSha)")
  TAG=$(node -e "console.log(JSON.parse(require('fs').readFileSync('$SOURCES','utf8'))['$repo'].syncedTag||'none')")

  LATEST=$(git ls-remote "$URL" HEAD | cut -f1)

  if [ "$SYNCED" = "$LATEST" ]; then
    echo "  ✅ $repo — up to date (${SYNCED:0:7}, tag: $TAG)"
  else
    echo "  ⚠️  $repo — outdated!"
    echo "     bundled: ${SYNCED:0:7} (tag: $TAG)"
    echo "     latest:  ${LATEST:0:7}"
    echo "     diff:    ${URL}/compare/${SYNCED:0:7}...${LATEST:0:7}"
  fi
done
