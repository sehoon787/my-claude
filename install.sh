#!/usr/bin/env bash
# my-claude full installer — copies plugin files + registers MCP + installs companion tools
# Usage: bash install.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== my-claude installer ==="
echo ""

# ── 0. Prerequisites ──
echo "[0/6] Checking prerequisites..."
command -v node >/dev/null 2>&1 || { echo "ERROR: node not found. Install Node.js v20+"; exit 1; }
command -v npm  >/dev/null 2>&1 || { echo "ERROR: npm not found"; exit 1; }
command -v git  >/dev/null 2>&1 || { echo "ERROR: git not found"; exit 1; }
echo "  Prerequisites OK"

# ── 0b. tmux (optional — for Agent Teams split-pane mode) ──
echo "[0b] Checking tmux..."
if command -v tmux >/dev/null 2>&1; then
  echo "  tmux found: $(tmux -V)"
  TMUX_AVAILABLE=1
else
  echo "  tmux not found. Attempting install..."
  TMUX_AVAILABLE=0

  if [[ "$OSTYPE" == "darwin"* ]]; then
    if command -v brew >/dev/null 2>&1; then
      brew install tmux 2>/dev/null && TMUX_AVAILABLE=1 || true
    fi
  elif [[ -f /etc/os-release ]]; then
    if command -v apt-get >/dev/null 2>&1; then
      sudo apt-get install -y tmux 2>/dev/null && TMUX_AVAILABLE=1 || true
    elif command -v dnf >/dev/null 2>&1; then
      sudo dnf install -y tmux 2>/dev/null && TMUX_AVAILABLE=1 || true
    elif command -v pacman >/dev/null 2>&1; then
      sudo pacman -S --noconfirm tmux 2>/dev/null && TMUX_AVAILABLE=1 || true
    fi
  fi

  if [ "$TMUX_AVAILABLE" = "1" ]; then
    echo "  tmux installed: $(tmux -V)"
  else
    echo "  tmux install failed — will use in-process mode (no action needed)"
  fi
fi

# ── 1. Plugin files (agents, skills, rules) ──
echo "[1/6] Installing plugin files..."
# Tiered agent structure:
#   ~/.claude/agents/      → core only (always loaded): core + omc + omo + engineering
#   ~/.claude/agent-packs/ → domain agents (not auto-loaded, available on demand)
#   ~/.claude/docs/nexus/  → strategy docs (reference material, never parsed as agents)
mkdir -p "$HOME/.claude/agents" "$HOME/.claude/skills" "$HOME/.claude/rules"
mkdir -p "$HOME/.claude/agent-packs/academic" "$HOME/.claude/agent-packs/design" \
         "$HOME/.claude/agent-packs/gamedev" "$HOME/.claude/agent-packs/marketing" \
         "$HOME/.claude/agent-packs/paid-media" "$HOME/.claude/agent-packs/product" \
         "$HOME/.claude/agent-packs/project-mgmt" "$HOME/.claude/agent-packs/sales" \
         "$HOME/.claude/agent-packs/spatial-computing" "$HOME/.claude/agent-packs/specialized" \
         "$HOME/.claude/agent-packs/support" "$HOME/.claude/agent-packs/testing"
mkdir -p "$HOME/.claude/docs/nexus"

# Clean up old flattened agents from previous installs
echo "  Cleaning up old flattened agents..."
for prefix in marketing- sales- paid- academic- design- support- testing- specialized- product- project-management- game- godot- unity- unreal- roblox- xr- phase- scenario- nexus-strategy EXECUTIVE-BRIEF QUICKSTART handoff-templates agent-activation-prompts; do
  rm -f "$HOME/.claude/agents/${prefix}"*.md
done

# agents — core tier (always loaded)
find "$SCRIPT_DIR/agents/core" -maxdepth 1 -name '*.md' ! -name 'agent-teams-reference.md' -exec cp {} "$HOME/.claude/agents/" \;
cp "$SCRIPT_DIR"/agents/omo/*.md  "$HOME/.claude/agents/"
cp "$SCRIPT_DIR"/agents/omc/*.md  "$HOME/.claude/agents/"
cp -r "$SCRIPT_DIR"/agents/agency/engineering/*.md "$HOME/.claude/agents/"

# agent-packs — domain agents (not auto-loaded)
cp -r "$SCRIPT_DIR"/agents/agency/academic/*.md            "$HOME/.claude/agent-packs/academic/"
cp -r "$SCRIPT_DIR"/agents/agency/design/*.md              "$HOME/.claude/agent-packs/design/"
find "$SCRIPT_DIR/agents/agency/game-development" -name '*.md' -exec cp {} "$HOME/.claude/agent-packs/gamedev/" \;
cp -r "$SCRIPT_DIR"/agents/agency/marketing/*.md           "$HOME/.claude/agent-packs/marketing/"
cp -r "$SCRIPT_DIR"/agents/agency/paid-media/*.md          "$HOME/.claude/agent-packs/paid-media/"
cp -r "$SCRIPT_DIR"/agents/agency/product/*.md             "$HOME/.claude/agent-packs/product/"
cp -r "$SCRIPT_DIR"/agents/agency/project-management/*.md  "$HOME/.claude/agent-packs/project-mgmt/"
cp -r "$SCRIPT_DIR"/agents/agency/sales/*.md               "$HOME/.claude/agent-packs/sales/"
cp -r "$SCRIPT_DIR"/agents/agency/spatial-computing/*.md   "$HOME/.claude/agent-packs/spatial-computing/"
cp -r "$SCRIPT_DIR"/agents/agency/specialized/*.md         "$HOME/.claude/agent-packs/specialized/"
cp -r "$SCRIPT_DIR"/agents/agency/support/*.md             "$HOME/.claude/agent-packs/support/"
cp -r "$SCRIPT_DIR"/agents/agency/testing/*.md             "$HOME/.claude/agent-packs/testing/"

# docs/nexus — strategy docs + reference material (never parsed as agents)
cp "$SCRIPT_DIR/agents/core/agent-teams-reference.md"      "$HOME/.claude/docs/nexus/"
find "$SCRIPT_DIR/agents/agency/strategy" -name '*.md' -exec cp {} "$HOME/.claude/docs/nexus/" \;

# skills
cp -r "$SCRIPT_DIR"/skills/ecc/* "$HOME/.claude/skills/"
cp -r "$SCRIPT_DIR"/skills/omc/* "$HOME/.claude/skills/"

# rules
cp -r "$SCRIPT_DIR"/rules/* "$HOME/.claude/rules/"

echo "  Plugin files installed"

# ── 2. Hooks ──
echo "[2/6] Installing hooks..."
mkdir -p "$HOME/.claude/hooks"
cp "$SCRIPT_DIR/hooks/hooks.json"      "$HOME/.claude/hooks/"
cp "$SCRIPT_DIR/hooks/session-start.sh" "$HOME/.claude/hooks/"
echo "  NOTE: hooks.json uses \${CLAUDE_PLUGIN_ROOT}. If not using plugin, update script paths manually."
echo "  Hooks installed"

# ── 3. MCP servers ──
echo "[3/6] Registering MCP servers..."
claude mcp add-from-claude-json "$SCRIPT_DIR/.mcp.json" 2>/dev/null || {
  # Fallback: register individually if bulk add unavailable
  claude mcp add context7  --transport http --scope user "https://mcp.context7.com/mcp" 2>/dev/null || true
  claude mcp add exa       --transport http --scope user "https://mcp.exa.ai/mcp?tools=web_search_exa" 2>/dev/null || true
  claude mcp add grep_app  --transport http --scope user "https://mcp.grep.app" 2>/dev/null || true
}
echo "  MCP servers registered"

# ── 4. Merge settings.json ──
echo "[4/6] Merging settings.json..."
node -e "
const fs   = require('fs');
const path = require('path');
const dest = path.join(process.env.HOME, '.claude', 'settings.json');
const existing = fs.existsSync(dest) ? JSON.parse(fs.readFileSync(dest, 'utf8')) : {};
existing.env   = Object.assign({}, existing.env, { CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS: '1' });
existing.agent = existing.agent || 'boss';
if ('${TMUX_AVAILABLE}' === '1' && !existing.teammateMode) {
  existing.teammateMode = 'tmux';
}
fs.writeFileSync(dest, JSON.stringify(existing, null, 2) + '\n');
console.log('  settings.json merged');
"

# ── 4b. Merge hooks from hooks.json into settings.json ──
echo "[4b] Merging hooks into settings.json..."
node -e "
const fs   = require('fs');
const path = require('path');
const dest = path.join(process.env.HOME, '.claude', 'settings.json');
const src  = path.join('${SCRIPT_DIR}', 'hooks', 'hooks.json');
const existing  = fs.existsSync(dest) ? JSON.parse(fs.readFileSync(dest, 'utf8')) : {};
const srcHooks  = JSON.parse(fs.readFileSync(src, 'utf8')).hooks || {};
existing.hooks  = existing.hooks || {};
// Add/replace each hook event from hooks.json into settings.json
for (const [event, entries] of Object.entries(srcHooks)) {
  existing.hooks[event] = entries;
}
fs.writeFileSync(dest, JSON.stringify(existing, null, 2) + '\n');
console.log('  hooks merged into settings.json');
"

# ── 5. Companion tools ──

# 5a. Anthropic Official Skills (proprietary — cannot be bundled)
echo "[5/6] Installing companion tools..."
echo "  [5a] Anthropic skills..."
if [ -d "$HOME/.claude/skills/pdf" ] && [ -d "$HOME/.claude/skills/docx" ]; then
  echo "    Anthropic skills already installed"
else
  claude plugin add anthropics/skills 2>/dev/null || {
    echo "    Plugin install failed, falling back to git clone..."
    _tmp_skills=$(mktemp -d)
    trap 'rm -rf "$_tmp_skills"' EXIT
    git clone --depth 1 https://github.com/anthropics/skills.git "$_tmp_skills/skills" 2>/dev/null || true
    if [ -d "$_tmp_skills/skills/skills" ]; then
      mkdir -p "$HOME/.claude/skills"
      cp -r "$_tmp_skills/skills/skills/"* "$HOME/.claude/skills/"
      echo "    Anthropic skills installed via git clone"
    else
      echo "    WARNING: Could not install Anthropic skills"
    fi
  }
fi

# 5b. OMC CLI (npm package)
echo "  [5b] OMC CLI..."
if command -v omc >/dev/null 2>&1; then
  echo "    OMC already installed ($(omc --version 2>/dev/null || echo 'unknown'))"
else
  npm i -g oh-my-claude-sisyphus@4.8.2
  omc setup 2>/dev/null || true
  echo "    OMC installed"
fi

# 5c. omo CLI + dependencies (npm packages)
echo "  [5c] omo CLI..."
if command -v oh-my-opencode >/dev/null 2>&1; then
  echo "    omo already installed"
else
  npm i -g oh-my-opencode@3.12.3
  oh-my-opencode install --no-tui --claude=yes --openai=no --gemini=no --copilot=no 2>/dev/null || true
  echo "    omo installed"
fi
npm i -g @ast-grep/cli@0.42.0 @code-yeongyu/comment-checker@0.7.0 2>/dev/null || true

# 5d. Karpathy guidelines (append to CLAUDE.md)
echo "  [5d] Karpathy guidelines..."
if grep -q 'karpathy' "$HOME/.claude/CLAUDE.md" 2>/dev/null; then
  echo "    Karpathy guidelines already present"
else
  # Pinned to a specific commit SHA + checksum to prevent supply chain attacks.
  # To upgrade: update SHA and EXPECTED_CHECKSUM together.
  KARPATHY_SHA="aa4467f0b33e1e80d11c7c043d4b27e7c79a73a3"
  KARPATHY_URL="https://raw.githubusercontent.com/forrestchang/andrej-karpathy-skills/${KARPATHY_SHA}/CLAUDE.md"
  KARPATHY_EXPECTED_CHECKSUM="694a2d721e41c385f3db492838c23299826df5ba9809e3b0721aac70021e196a"
  _tmp_karpathy=$(mktemp)
  trap 'rm -f "$_tmp_karpathy"' EXIT
  if curl -sL "$KARPATHY_URL" -o "$_tmp_karpathy" 2>/dev/null; then
    ACTUAL_CHECKSUM=$(sha256sum "$_tmp_karpathy" | awk '{print $1}')
    if [ "$ACTUAL_CHECKSUM" = "$KARPATHY_EXPECTED_CHECKSUM" ]; then
      cat "$_tmp_karpathy" >> "$HOME/.claude/CLAUDE.md"
      echo "    Karpathy guidelines appended"
    else
      echo "    WARNING: Checksum mismatch, skipping Karpathy guidelines"
    fi
  fi
fi

# ── 6. Verification ──
echo ""
echo "[6/6] Verification"
echo "  agents (core):    $(find "$HOME/.claude/agents" -name '*.md' 2>/dev/null | wc -l | tr -d ' ') files"
echo "  agent-packs:      $(find "$HOME/.claude/agent-packs" -name '*.md' 2>/dev/null | wc -l | tr -d ' ') files"
echo "  skills:           $(find "$HOME/.claude/skills" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ') installed"
echo "  rules:            $(find "$HOME/.claude/rules"  -name '*.md' 2>/dev/null | wc -l | tr -d ' ') files"
echo "  hooks:            $(find "$HOME/.claude/hooks"  -type f      2>/dev/null | wc -l | tr -d ' ') files"
echo "  omc:              $(command -v omc            >/dev/null 2>&1 && echo 'OK' || echo 'MISSING')"
echo "  omo:              $(command -v oh-my-opencode >/dev/null 2>&1 && echo 'OK' || echo 'MISSING')"
echo "  ast-grep:         $(command -v ast-grep       >/dev/null 2>&1 && echo 'OK' || echo 'MISSING')"
echo "  tmux:             $(command -v tmux >/dev/null 2>&1 && echo "OK ($(tmux -V))" || echo 'NOT INSTALLED (in-process mode)')"
TEAMMATE_MODE=$(node -e 'try{console.log(JSON.parse(require("fs").readFileSync(process.env.HOME+"/.claude/settings.json","utf8")).teammateMode||"auto")}catch(e){console.log("auto")}')
echo "  teammateMode:     $TEAMMATE_MODE"
echo ""
echo "=== Install complete ==="
