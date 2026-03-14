#!/usr/bin/env bash
# my-claude automated installer — bash-only, no interactive commands
# Usage: git clone --depth 1 https://github.com/sehoon787/my-claude.git /tmp/my-claude && bash /tmp/my-claude/install.sh
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="${HOME}/.claude"
AGENTS_DIR="${CLAUDE_DIR}/agents"
SKILLS_DIR="${CLAUDE_DIR}/skills"
RULES_DIR="${CLAUDE_DIR}/rules"

# Convert Git Bash paths to Windows paths for Node.js compatibility
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "mingw"* || "$OSTYPE" == "cygwin" ]]; then
  REPO_DIR_NODE="$(cygpath -m "${REPO_DIR}")"
  CLAUDE_DIR_NODE="$(cygpath -m "${CLAUDE_DIR}")"
else
  REPO_DIR_NODE="${REPO_DIR}"
  CLAUDE_DIR_NODE="${CLAUDE_DIR}"
fi

echo "=== my-claude installer ==="
echo "Repo: ${REPO_DIR}"
echo ""

# ── 0. Prerequisites ──
echo "[0/10] Checking prerequisites..."
command -v node >/dev/null 2>&1 || { echo "ERROR: node not found. Install Node.js v20+"; exit 1; }
command -v npm >/dev/null 2>&1 || { echo "ERROR: npm not found"; exit 1; }
command -v git >/dev/null 2>&1 || { echo "ERROR: git not found"; exit 1; }
command -v claude >/dev/null 2>&1 || { echo "ERROR: claude CLI not found. Install Claude Code v2.1+"; exit 1; }
mkdir -p "${AGENTS_DIR}" "${SKILLS_DIR}" "${RULES_DIR}"
echo "  Prerequisites OK"

# ── 1. Install OMC (Oh My Claude Code) ──
echo "[1/10] Installing OMC..."
if command -v omc >/dev/null 2>&1; then
  echo "  OMC already installed ($(omc --version 2>/dev/null || echo 'unknown'))"
else
  npm i -g oh-my-claude-sisyphus@latest
  omc setup
  echo "  OMC installed"
fi

# ── 2. Install omo (Oh My OpenAgent) ──
echo "[2/10] Installing omo..."
if command -v oh-my-opencode >/dev/null 2>&1; then
  echo "  omo already installed ($(oh-my-opencode --version 2>/dev/null || echo 'unknown'))"
else
  npm i -g oh-my-opencode@latest
  oh-my-opencode install --no-tui --claude=yes --openai=no --gemini=no --copilot=no
  echo "  omo installed"
fi

# ── 3. Fix OMC HUD Error ──
echo "[3/10] Fixing OMC HUD..."
HUD_FILE="${CLAUDE_DIR}/hud/omc-hud.mjs"
if [ -f "${HUD_FILE}" ]; then
  # Add missing imports if not present
  if ! grep -q 'import { existsSync }' "${HUD_FILE}" 2>/dev/null; then
    sed -i '1i import { existsSync } from "node:fs";\nimport { join } from "node:path";\nimport { pathToFileURL } from "node:url";' "${HUD_FILE}"
  fi
  # Add sisyphus fallback path if not present
  if ! grep -q 'oh-my-claude-sisyphus' "${HUD_FILE}" 2>/dev/null; then
    sed -i '/oh-my-claudecode\/dist\/hud\/index.js/,/catch.*continue/{/catch.*continue/a\
  // 4b. npm package under oh-my-claude-sisyphus (absolute path)\
  const sisyphusPaths = [\
    join(process.execPath, "..", "..", "lib", "node_modules", "oh-my-claude-sisyphus", "dist", "hud", "index.js"),\
    join(process.env.APPDATA || "", "npm", "node_modules", "oh-my-claude-sisyphus", "dist", "hud", "index.js"),\
  ];\
  for (const sp of sisyphusPaths) {\
    if (existsSync(sp)) {\
      try { await import(pathToFileURL(sp).href); return; } catch { /* continue */ }\
    }\
  }
}' "${HUD_FILE}"
  fi
  echo "  HUD fix applied"
else
  echo "  HUD file not found (skipping — run 'omc setup' first if needed)"
fi

# ── 4. Install omo dependencies ──
echo "[4/10] Installing omo dependencies..."
npm i -g @ast-grep/cli 2>/dev/null || true
npm i -g @code-yeongyu/comment-checker 2>/dev/null || true
echo "  omo dependencies installed"

# ── 5. Install MCP servers ──
echo "[5/10] Installing MCP servers..."
claude mcp add --transport http --scope user context7 "https://mcp.context7.com/mcp" 2>/dev/null || true
claude mcp add --transport http --scope user exa "https://mcp.exa.ai/mcp?tools=web_search_exa" 2>/dev/null || true
claude mcp add --transport http --scope user grep_app "https://mcp.grep.app" 2>/dev/null || true
echo "  MCP servers configured"

# ── 6. Install my-claude agents + hooks ──
echo "[6/10] Installing my-claude agents and hooks..."
cp "${REPO_DIR}"/agents/*.md "${AGENTS_DIR}/"

# Merge hooks and set default agent to boss
node -e "
const fs = require('fs');
const path = require('path');
const settingsPath = path.join('${CLAUDE_DIR_NODE}', 'settings.json');
let settings = {};
try { settings = JSON.parse(fs.readFileSync(settingsPath, 'utf8')); } catch {}
settings.agent = 'boss';
const hooksData = JSON.parse(fs.readFileSync(path.join('${REPO_DIR_NODE}', 'hooks', 'hooks.json'), 'utf8'));
settings.hooks = hooksData.hooks;
fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2));
console.log('  Default agent: boss | Hooks: ' + Object.keys(settings.hooks).join(', '));
"

# ── 7. Install Andrej Karpathy Skills ──
echo "[7/10] Installing Karpathy skills..."
cd /tmp && git clone --depth 1 https://github.com/forrestchang/andrej-karpathy-skills.git 2>/dev/null || true
if [ -f /tmp/andrej-karpathy-skills/CLAUDE.md ]; then
  if ! grep -q 'karpathy' "${CLAUDE_DIR}/CLAUDE.md" 2>/dev/null; then
    cat /tmp/andrej-karpathy-skills/CLAUDE.md >> "${CLAUDE_DIR}/CLAUDE.md"
    echo "  Karpathy skills appended to CLAUDE.md"
  else
    echo "  Karpathy skills already in CLAUDE.md"
  fi
fi

# ── 8. Install Everything Claude Code (ECC) ──
echo "[8/10] Installing ECC rules..."
cd /tmp && git clone --depth 1 https://github.com/affaan-m/everything-claude-code.git 2>/dev/null || true
if [ -d /tmp/everything-claude-code ]; then
  cd /tmp/everything-claude-code
  bash install.sh typescript 2>/dev/null || true
  cd ~
  echo "  ECC rules installed"
fi

# ── 9. Install Anthropic Official Skills ──
echo "[9/10] Installing Anthropic skills..."
cd /tmp && git clone --depth 1 https://github.com/anthropics/skills.git 2>/dev/null || true
if [ -d /tmp/skills/skills ]; then
  mkdir -p "${SKILLS_DIR}"
  cp -r /tmp/skills/skills/* "${SKILLS_DIR}/"
  echo "  Anthropic skills installed"
fi

# ── 10. Install Agency Agents ──
echo "[10/10] Installing Agency agents..."
cd /tmp && git clone --depth 1 https://github.com/msitarzewski/agency-agents.git 2>/dev/null || true
if [ -d /tmp/agency-agents ]; then
  cp /tmp/agency-agents/engineering/*.md "${AGENTS_DIR}/" 2>/dev/null || true
  cp /tmp/agency-agents/testing/*.md "${AGENTS_DIR}/" 2>/dev/null || true
  cp /tmp/agency-agents/design/*.md "${AGENTS_DIR}/" 2>/dev/null || true
  cp /tmp/agency-agents/product/*.md "${AGENTS_DIR}/" 2>/dev/null || true

  # Add model field to Agency agents
  for f in "${AGENTS_DIR}"/{engineering,design,testing,product}-*.md; do
    if [ -f "$f" ] && ! grep -q "^model:" "$f"; then
      sed -i '/^description:/a model: claude-sonnet-4-6' "$f"
    fi
  done
  echo "  Agency agents installed with model fields"
fi

# ── Cleanup ──
rm -rf /tmp/andrej-karpathy-skills /tmp/everything-claude-code /tmp/skills /tmp/agency-agents

# ── Verification ──
echo ""
echo "=== Verification ==="
AGENT_COUNT=$(ls "${AGENTS_DIR}"/*.md 2>/dev/null | wc -l)
SKILL_COUNT=$(ls -d "${SKILLS_DIR}"/*/ 2>/dev/null | wc -l)
RULE_COUNT=$(find "${RULES_DIR}" -name "*.md" 2>/dev/null | wc -l)
DEFAULT_AGENT=$(node -e "try{console.log(JSON.parse(require('fs').readFileSync('${CLAUDE_DIR_NODE}/settings.json','utf8')).agent)}catch{console.log('none')}")
HOOKS=$(node -e "try{console.log(Object.keys(JSON.parse(require('fs').readFileSync('${CLAUDE_DIR_NODE}/settings.json','utf8')).hooks||{}).join(', '))}catch{console.log('none')}")

echo "  Agents:        ${AGENT_COUNT}"
echo "  Skills:        ${SKILL_COUNT}"
echo "  Rules:         ${RULE_COUNT}"
echo "  Default agent: ${DEFAULT_AGENT}"
echo "  Hooks:         ${HOOKS}"
echo ""

if [ "${AGENT_COUNT}" -ge 50 ] && [ "${DEFAULT_AGENT}" = "boss" ]; then
  echo "=== Setup complete. Boss orchestrator is ready. ==="
else
  echo "=== Setup finished with warnings. Check counts above. ==="
fi
