#!/usr/bin/env bash
# my-claude companion installer — installs tools that can't be bundled in the plugin
# Usage: bash install.sh (after plugin install)
set -euo pipefail

echo "=== my-claude companion installer ==="
echo "This script installs additional tools not included in the plugin bundle."
echo ""

# ── 0. Prerequisites ──
echo "[0/4] Checking prerequisites..."
command -v node >/dev/null 2>&1 || { echo "ERROR: node not found. Install Node.js v20+"; exit 1; }
command -v npm >/dev/null 2>&1 || { echo "ERROR: npm not found"; exit 1; }
command -v git >/dev/null 2>&1 || { echo "ERROR: git not found"; exit 1; }
echo "  Prerequisites OK"

# ── 1. Anthropic Official Skills (proprietary — cannot be bundled) ──
echo "[1/4] Installing Anthropic skills..."
if [ -d "$HOME/.claude/skills/pdf" ] && [ -d "$HOME/.claude/skills/docx" ]; then
  echo "  Anthropic skills already installed"
else
  claude plugin add anthropics/skills 2>/dev/null || {
    echo "  Plugin install failed, falling back to git clone..."
    cd /tmp && git clone --depth 1 https://github.com/anthropics/skills.git 2>/dev/null || true
    if [ -d /tmp/skills/skills ]; then
      mkdir -p "$HOME/.claude/skills"
      cp -r /tmp/skills/skills/* "$HOME/.claude/skills/"
      rm -rf /tmp/skills
      echo "  Anthropic skills installed via git clone"
    else
      echo "  WARNING: Could not install Anthropic skills"
    fi
  }
fi

# ── 2. OMC CLI (npm package) ──
echo "[2/4] Installing OMC CLI..."
if command -v omc >/dev/null 2>&1; then
  echo "  OMC already installed ($(omc --version 2>/dev/null || echo 'unknown'))"
else
  npm i -g oh-my-claude-sisyphus@latest
  omc setup 2>/dev/null || true
  echo "  OMC installed"
fi

# ── 3. omo CLI + dependencies (npm packages) ──
echo "[3/4] Installing omo CLI..."
if command -v oh-my-opencode >/dev/null 2>&1; then
  echo "  omo already installed"
else
  npm i -g oh-my-opencode@latest
  oh-my-opencode install --no-tui --claude=yes --openai=no --gemini=no --copilot=no 2>/dev/null || true
  echo "  omo installed"
fi
npm i -g @ast-grep/cli @code-yeongyu/comment-checker 2>/dev/null || true

# ── 4. Karpathy guidelines (append to CLAUDE.md) ──
echo "[4/4] Appending Karpathy guidelines..."
if grep -q 'karpathy' "$HOME/.claude/CLAUDE.md" 2>/dev/null; then
  echo "  Karpathy guidelines already present"
else
  curl -sL "https://raw.githubusercontent.com/forrestchang/andrej-karpathy-skills/main/CLAUDE.md" \
    >> "$HOME/.claude/CLAUDE.md" 2>/dev/null || true
  echo "  Karpathy guidelines appended"
fi

# ── Verification ──
echo ""
echo "=== Verification ==="
echo "  Anthropic skills: $(ls -d "$HOME/.claude/skills"/*/ 2>/dev/null | wc -l) installed"
echo "  omc:              $(command -v omc >/dev/null 2>&1 && echo 'OK' || echo 'MISSING')"
echo "  omo:              $(command -v oh-my-opencode >/dev/null 2>&1 && echo 'OK' || echo 'MISSING')"
echo "  ast-grep:         $(command -v ast-grep >/dev/null 2>&1 && echo 'OK' || echo 'MISSING')"
echo ""
echo "=== Companion install complete ==="
echo "The plugin provides: 199+ agents, 136 skills, 14 rules, 4 hooks, 3 MCP servers"
echo "This script added: Anthropic skills, OMC CLI, omo CLI, ast-grep"
