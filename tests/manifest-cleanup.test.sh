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
#   3. Runtime files the agent creates inside the installed archify skill
#      (node_modules/ from the `npm install` its SKILL.md asks for, rendered
#      diagrams) are user-owned: the archify manifest entries come from the
#      upstream source tree, so a reinstall never deletes them — while a file
#      that dropped out of upstream still is deleted.
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
# claude / curl / uv: fail, so install.sh takes its offline fallback paths and
# no CLI is downloaded into the throwaway HOME.
printf '#!/usr/bin/env bash\nexit 1\n' > "$SHIM/claude"
printf '#!/usr/bin/env bash\nexit 1\n' > "$SHIM/curl"
printf '#!/usr/bin/env bash\nexit 1\n' > "$SHIM/uv"
chmod +x "$SHIM/npm" "$SHIM/claude" "$SHIM/curl" "$SHIM/uv"

FAKE_HOME="$TMP/home"
mkdir -p "$FAKE_HOME"
run_install() {
  ( cd "$REPO" && PATH="$SHIM:$PATH" HOME="$FAKE_HOME" \
      AGENT_HARNESS_SERVICES_SKIP=1 bash install.sh --self-only ) \
    > "$TMP/install.log" 2>&1
}

# Second throwaway HOME, for the archify phases: everything self-owned plus the
# one upstream that installs a skill directory the agent then writes into.
ARCHIFY_HOME="$TMP/archify-home"
mkdir -p "$ARCHIFY_HOME"
run_archify_install() {
  ( cd "$REPO" && PATH="$SHIM:$PATH" HOME="$ARCHIFY_HOME" \
      AGENT_HARNESS_SERVICES_SKIP=1 bash install.sh \
      --skip-ecc --skip-omc --skip-gstack --skip-superpowers ) \
    > "$TMP/archify-install.log" 2>&1
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
present_archify() { [ -e "$ARCHIFY_HOME/.claude/$1" ] && echo 1 || echo 0; }

echo "[1/5] first install"
if ! run_install; then
  echo "FAIL  install.sh --self-only exited non-zero"
  tail -20 "$TMP/install.log"
  exit 1
fi
MANIFEST="$FAKE_HOME/.claude/.my-claude-manifest"
[ -f "$MANIFEST" ] || { echo "FAIL  no manifest written"; exit 1; }

echo "[2/5] seeding a legacy install: manifest-owned leftovers + one user-owned skill"
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

echo "[3/5] second install"
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

echo "[4/5] first install with archify"
if ! run_archify_install; then
  echo "FAIL  install.sh (archify) exited non-zero"
  tail -20 "$TMP/archify-install.log"
  exit 1
fi
ARCHIFY_MANIFEST="$ARCHIFY_HOME/.claude/.my-claude-manifest"
ARCHIFY_SKILL="$ARCHIFY_HOME/.claude/skills/archify"
if [ ! -f "$ARCHIFY_SKILL/SKILL.md" ]; then
  echo "SKIP  archify skill not installed (submodule not checked out?)"
  tail -5 "$TMP/archify-install.log"
else
  # Runtime files the agent creates after install: `npm install` inside the
  # skill, and a rendered diagram written next to it.
  mkdir -p "$ARCHIFY_SKILL/node_modules"
  echo "module.exports = {};" > "$ARCHIFY_SKILL/node_modules/x.js"
  echo "<html></html>" > "$ARCHIFY_SKILL/out.html"
  # A file an older archify release shipped and this one does not: manifest-owned,
  # so the reinstall must delete it.
  echo "# gone upstream" > "$ARCHIFY_SKILL/stale-upstream.md"
  echo "skills/archify/stale-upstream.md" >> "$ARCHIFY_MANIFEST"

  # Two more installs: the cleanup deletes what the PREVIOUS manifest owned, so
  # a runtime file wrongly adopted by install two is only deleted by install
  # three. Both are needed to show it is never adopted at all.
  echo "[5/5] two more installs with archify"
  run_archify_install || { echo "FAIL  second archify install exited non-zero"; tail -20 "$TMP/archify-install.log"; exit 1; }
  run_archify_install || { echo "FAIL  third archify install exited non-zero"; tail -20 "$TMP/archify-install.log"; exit 1; }

  check "archify node_modules never manifest-owned" \
    "$(grep -q '^skills/archify/node_modules/' "$ARCHIFY_MANIFEST" && echo 0 || echo 1)"
  check "archify generated output never manifest-owned" \
    "$(grep -q '^skills/archify/out\.html$' "$ARCHIFY_MANIFEST" && echo 0 || echo 1)"
  check "agent-installed node_modules survives reinstall" \
    "$(present_archify skills/archify/node_modules/x.js)"
  check "generated diagram survives reinstall" \
    "$(present_archify skills/archify/out.html)"
  check "file dropped from upstream is cleaned" \
    "$([ "$(present_archify skills/archify/stale-upstream.md)" = 0 ] && echo 1 || echo 0)"
  check "archify SKILL.md reinstalled" "$(present_archify skills/archify/SKILL.md)"
fi

if [ "$fail" -eq 0 ]; then
  echo "ALL PASSED"
else
  echo "FAILED"
fi
exit "$fail"
