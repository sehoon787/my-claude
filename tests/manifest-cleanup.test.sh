#!/usr/bin/env bash
#
# manifest-cleanup.test.sh — the install manifest must delete what it owns and
# nothing else. `bash tests/manifest-cleanup.test.sh`
#
# Guards two properties that the lean-skill default depends on:
#   1. A skill directory that drops out of the allowlist (an OMC copy, a `web`
#      lane skill) and a rules/common file that drops out of the per-file
#      allowlist are removed on the next install, because the previous manifest
#      owned them.
#   2. A skill directory the manifest never listed — anything the user dropped
#      into ~/.claude/skills/ by hand — survives every install untouched.
#
# Runs install.sh --self-only against a throwaway HOME with npm/claude/curl
# shimmed out, so nothing outside the temp dir is read or written.
set -uo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

SHIM="$TMP/shim"
mkdir -p "$SHIM"
# npm: answer `npm root -g` from the real npm, never install anything globally.
printf '#!/usr/bin/env bash\ncase "$1" in root) exec %s "$@" ;; *) exit 0 ;; esac\n' \
  "$(command -v npm || echo /bin/true)" > "$SHIM/npm"
# claude / curl: fail, so install.sh takes its offline fallback paths.
printf '#!/usr/bin/env bash\nexit 1\n' > "$SHIM/claude"
printf '#!/usr/bin/env bash\nexit 1\n' > "$SHIM/curl"
chmod +x "$SHIM/npm" "$SHIM/claude" "$SHIM/curl"

FAKE_HOME="$TMP/home"
mkdir -p "$FAKE_HOME"
run_install() {
  ( cd "$REPO" && PATH="$SHIM:$PATH" HOME="$FAKE_HOME" bash install.sh --self-only ) \
    > "$TMP/install.log" 2>&1
}

fail=0
check() {
  if [ "$2" = "1" ]; then
    echo "PASS  $1"
  else
    echo "FAIL  $1"
    fail=1
  fi
}
present() { [ -e "$FAKE_HOME/.claude/$1" ] && echo 1 || echo 0; }

echo "[1/3] first install"
if ! run_install; then
  echo "FAIL  install.sh --self-only exited non-zero"
  tail -20 "$TMP/install.log"
  exit 1
fi
MANIFEST="$FAKE_HOME/.claude/.my-claude-manifest"
[ -f "$MANIFEST" ] || { echo "FAIL  no manifest written"; exit 1; }

echo "[2/3] seeding a legacy install: manifest-owned leftovers + one user-owned skill"
# Manifest-owned leftovers: names an older install DID copy and this one does not
# (an OMC plugin duplicate, a `web` lane skill, a dropped rules/common file).
for leftover in skills/ralph skills/react-patterns; do
  mkdir -p "$FAKE_HOME/.claude/$leftover"
  echo "# leftover" > "$FAKE_HOME/.claude/$leftover/SKILL.md"
  echo "$leftover/SKILL.md" >> "$MANIFEST"
done
mkdir -p "$FAKE_HOME/.claude/rules/common"
echo "# leftover" > "$FAKE_HOME/.claude/rules/common/testing.md"
echo "rules/common/testing.md" >> "$MANIFEST"
# User-owned: never in the manifest, must never be touched.
mkdir -p "$FAKE_HOME/.claude/skills/user-custom/references"
echo "# mine" > "$FAKE_HOME/.claude/skills/user-custom/SKILL.md"
echo "# mine" > "$FAKE_HOME/.claude/skills/user-custom/references/notes.md"

echo "[3/3] second install"
run_install || { echo "FAIL  second install exited non-zero"; tail -20 "$TMP/install.log"; exit 1; }

check "manifest-owned OMC copy removed (skills/ralph)"          "$([ "$(present skills/ralph)" = 0 ] && echo 1 || echo 0)"
check "manifest-owned web-lane skill removed (react-patterns)"  "$([ "$(present skills/react-patterns)" = 0 ] && echo 1 || echo 0)"
check "manifest-owned rules/common/testing.md removed"          "$([ "$(present rules/common/testing.md)" = 0 ] && echo 1 || echo 0)"
check "user-owned skill dir survives"                           "$(present skills/user-custom/SKILL.md)"
check "user-owned nested file survives"                         "$(present skills/user-custom/references/notes.md)"
check "self-owned skill still installed (boss-advanced)"        "$(present skills/boss-advanced/SKILL.md)"
check "self-owned rule still installed (calibrated-response)"   "$(present rules/common/calibrated-response.md)"
check "boss agent still installed"                              "$(present agents/boss.md)"
check "context-budget hook installed"                           "$(present hooks/context-budget.js)"

if [ "$fail" -eq 0 ]; then
  echo "ALL PASSED"
else
  echo "FAILED"
fi
exit "$fail"
