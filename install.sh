#!/usr/bin/env bash
# my-claude full installer — copies plugin files + registers MCP + installs companion tools
# Usage: bash install.sh
set -euo pipefail

# Cross-platform SHA-256 checksum
sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    echo "no-sha256-tool"
  fi
}

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== my-claude installer ==="
echo ""

# ── 0. Prerequisites ──
echo "[0/6] Checking prerequisites..."
command -v node >/dev/null 2>&1 || { echo "ERROR: node not found. Install Node.js v20+"; exit 1; }
command -v npm  >/dev/null 2>&1 || { echo "ERROR: npm not found"; exit 1; }
command -v git  >/dev/null 2>&1 || { echo "ERROR: git not found"; exit 1; }
echo "  Prerequisites OK"

# ── Version info ──
INSTALLING_VERSION=$(node "$SCRIPT_DIR/scripts/get-version.js" "$SCRIPT_DIR/.claude-plugin/plugin.json" 2>/dev/null)
INSTALLED_VERSION="none"
if [ -f "$HOME/.claude/.my-claude-version" ]; then
  INSTALLED_VERSION=$(cat "$HOME/.claude/.my-claude-version")
fi
if [ "$INSTALLED_VERSION" = "none" ]; then
  echo "  Fresh install: v${INSTALLING_VERSION}"
elif [ "$INSTALLED_VERSION" = "$INSTALLING_VERSION" ]; then
  echo "  Reinstalling: v${INSTALLING_VERSION} (same version)"
else
  echo "  Updating: v${INSTALLED_VERSION} → v${INSTALLING_VERSION}"
fi

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

# Manifest-based cleanup: remove only files from previous my-claude install
if [ -f "$HOME/.claude/.my-claude-manifest" ]; then
  while IFS= read -r rel_path; do
    target="$HOME/.claude/$rel_path"
    [ -f "$target" ] && rm -f "$target"
  done < "$HOME/.claude/.my-claude-manifest"
  # Remove empty agent-pack directories (only if empty after cleanup)
  find "$HOME/.claude/agent-packs" -type d -empty -delete 2>/dev/null || true
fi

mkdir -p "$HOME/.claude/agent-packs/academic" "$HOME/.claude/agent-packs/design" \
         "$HOME/.claude/agent-packs/game-development" "$HOME/.claude/agent-packs/marketing" \
         "$HOME/.claude/agent-packs/paid-media" "$HOME/.claude/agent-packs/product" \
         "$HOME/.claude/agent-packs/project-management" "$HOME/.claude/agent-packs/sales" \
         "$HOME/.claude/agent-packs/spatial-computing" "$HOME/.claude/agent-packs/specialized" \
         "$HOME/.claude/agent-packs/support" "$HOME/.claude/agent-packs/testing"
mkdir -p "$HOME/.claude/docs/nexus"

# Clean up old flattened agents from previous installs
echo "  Cleaning up old flattened agents..."
for prefix in marketing- sales- paid- academic- design- support- testing- specialized- product- project-management- game- godot- unity- unreal- roblox- xr- phase- scenario-; do
  find "$HOME/.claude/agents" -maxdepth 1 -name "${prefix}*.md" -delete 2>/dev/null || true
done
# Also remove known non-agent files that may have leaked into agents/
for name in nexus-strategy EXECUTIVE-BRIEF QUICKSTART handoff-templates agent-activation-prompts; do
  find "$HOME/.claude/agents" -maxdepth 1 -name "${name}*.md" -delete 2>/dev/null || true
done

# Clean up old-named agent-pack directories from previous installs
echo "  Cleaning up old naming variants..."
EXPECTED_PACKS=(academic design game-development marketing paid-media product project-management sales spatial-computing specialized support testing)
if [ -d "$HOME/.claude/agent-packs" ]; then
  for dir in "$HOME/.claude/agent-packs"/*/; do
    [ ! -d "$dir" ] && continue
    dirname=$(basename "$dir")
    is_expected=0
    for ep in "${EXPECTED_PACKS[@]}"; do
      [ "$dirname" = "$ep" ] && is_expected=1 && break
    done
    if [ "$is_expected" = "0" ]; then
      echo "  Removing stale agent-pack: $dirname"
      rm -rf "$dir"
    fi
  done
fi

# agents — core tier (always loaded)
find "$SCRIPT_DIR/agents/core" -maxdepth 1 -name '*.md' ! -name 'agent-teams-reference.md' -exec cp {} "$HOME/.claude/agents/" \;
cp "$SCRIPT_DIR"/agents/omo/*.md  "$HOME/.claude/agents/"
cp "$SCRIPT_DIR"/agents/omc/*.md  "$HOME/.claude/agents/"
cp -r "$SCRIPT_DIR"/agents/agency/engineering/*.md "$HOME/.claude/agents/"

# agent-packs — domain agents (not auto-loaded)
cp -r "$SCRIPT_DIR"/agents/agency/academic/*.md            "$HOME/.claude/agent-packs/academic/"
cp -r "$SCRIPT_DIR"/agents/agency/design/*.md              "$HOME/.claude/agent-packs/design/"
find "$SCRIPT_DIR/agents/agency/game-development" -name '*.md' -exec cp {} "$HOME/.claude/agent-packs/game-development/" \;
cp -r "$SCRIPT_DIR"/agents/agency/marketing/*.md           "$HOME/.claude/agent-packs/marketing/"
cp -r "$SCRIPT_DIR"/agents/agency/paid-media/*.md          "$HOME/.claude/agent-packs/paid-media/"
cp -r "$SCRIPT_DIR"/agents/agency/product/*.md             "$HOME/.claude/agent-packs/product/"
cp -r "$SCRIPT_DIR"/agents/agency/project-management/*.md  "$HOME/.claude/agent-packs/project-management/"
cp -r "$SCRIPT_DIR"/agents/agency/sales/*.md               "$HOME/.claude/agent-packs/sales/"
cp -r "$SCRIPT_DIR"/agents/agency/spatial-computing/*.md   "$HOME/.claude/agent-packs/spatial-computing/"
cp -r "$SCRIPT_DIR"/agents/agency/specialized/*.md         "$HOME/.claude/agent-packs/specialized/"
cp -r "$SCRIPT_DIR"/agents/agency/support/*.md             "$HOME/.claude/agent-packs/support/"
cp -r "$SCRIPT_DIR"/agents/agency/testing/*.md             "$HOME/.claude/agent-packs/testing/"

# Dedup: remove agent-pack entries that duplicate core agents
for f in "$HOME/.claude/agents"/*.md; do
  [ ! -f "$f" ] && continue
  name=$(basename "$f")
  find "$HOME/.claude/agent-packs" -name "$name" -delete 2>/dev/null || true
done

# docs/nexus — strategy docs + reference material (never parsed as agents)
cp "$SCRIPT_DIR/agents/core/agent-teams-reference.md"      "$HOME/.claude/docs/nexus/"
find "$SCRIPT_DIR/agents/agency/strategy" -name '*.md' -exec cp {} "$HOME/.claude/docs/nexus/" \;

# Pre-clean: resolve file/symlink vs directory conflicts for skills
for src in "$SCRIPT_DIR"/skills/ecc/*/; do
  [ ! -d "$src" ] && continue
  name=$(basename "$src")
  target="$HOME/.claude/skills/$name"
  if [ -L "$target" ] || { [ -e "$target" ] && [ ! -d "$target" ]; }; then
    rm -f "$target"
  fi
done
for src in "$SCRIPT_DIR"/skills/omc/*/; do
  [ ! -d "$src" ] && continue
  name=$(basename "$src")
  target="$HOME/.claude/skills/$name"
  if [ -L "$target" ] || { [ -e "$target" ] && [ ! -d "$target" ]; }; then
    rm -f "$target"
  fi
done
for src in "$SCRIPT_DIR"/skills/core/*/; do
  [ ! -d "$src" ] && continue
  name=$(basename "$src")
  target="$HOME/.claude/skills/$name"
  if [ -L "$target" ] || { [ -e "$target" ] && [ ! -d "$target" ]; }; then
    rm -f "$target"
  fi
done
if [ -d "$HOME/.claude/skills/gstack" ]; then
  for src in "$HOME/.claude/skills/gstack"/*/; do
    [ ! -d "$src" ] && continue
    name=$(basename "$src")
    target="$HOME/.claude/skills/$name"
    if [ -L "$target" ] || { [ -e "$target" ] && [ ! -d "$target" ]; }; then
      rm -f "$target"
    fi
  done
fi

# skills
cp -r "$SCRIPT_DIR"/skills/ecc/* "$HOME/.claude/skills/"
cp -r "$SCRIPT_DIR"/skills/omc/* "$HOME/.claude/skills/"
if [ -d "$SCRIPT_DIR/skills/core" ]; then
  cp -r "$SCRIPT_DIR"/skills/core/* "$HOME/.claude/skills/"
fi

# ── gstack (runtime install — not bundled in repo) ──
echo "  [gstack] Installing/updating..."
GSTACK_DIR="$HOME/.claude/skills/gstack"
if [ -d "$GSTACK_DIR/.git" ]; then
  git -C "$GSTACK_DIR" pull --ff-only 2>/dev/null || true
else
  rm -rf "$GSTACK_DIR"
  git clone --depth 1 https://github.com/garrytan/gstack.git "$GSTACK_DIR" 2>/dev/null || true
fi

# Install bun if missing (required for gstack browser)
if ! command -v bun >/dev/null 2>&1; then
  echo "  [gstack] Installing bun..."
  curl -fsSL https://bun.sh/install | bash 2>/dev/null || true
  export BUN_INSTALL="$HOME/.bun"
  export PATH="$BUN_INSTALL/bin:$PATH"
fi

# Run gstack setup (builds browse binary + creates symlinks)
if [ -d "$GSTACK_DIR" ] && command -v bun >/dev/null 2>&1 && [ -f "$GSTACK_DIR/setup" ]; then
  (cd "$GSTACK_DIR" && ./setup --host claude 2>/dev/null || true)
fi

# Fallback: ensure individual gstack skills are accessible at depth 1
if [ -d "$GSTACK_DIR" ]; then
  for skill_dir in "$GSTACK_DIR"/*/; do
    [ -f "$skill_dir/SKILL.md" ] || continue
    skill_name=$(basename "$skill_dir")
    case "$skill_name" in .git|bin|node_modules|agents) continue ;; esac
    target="$HOME/.claude/skills/$skill_name"
    # Only create if not already present (don't overwrite ECC/OMC skills)
    if [ ! -e "$target" ] && [ ! -L "$target" ]; then
      ln -s "$(cd "$skill_dir" && pwd)" "$target" 2>/dev/null || cp -r "$skill_dir" "$target"
    fi
  done
fi

# gstack auto_upgrade config
mkdir -p "$HOME/.gstack"
GSTACK_CONFIG="$HOME/.gstack/config.json"
if [ -f "$GSTACK_CONFIG" ]; then
  node -e "
    const fs = require('fs');
    const cfg = JSON.parse(fs.readFileSync('$GSTACK_CONFIG', 'utf8'));
    cfg.auto_upgrade = true;
    fs.writeFileSync('$GSTACK_CONFIG', JSON.stringify(cfg, null, 2));
  " 2>/dev/null || true
else
  echo '{"auto_upgrade":true}' > "$GSTACK_CONFIG"
fi

# Remove superseded ECC skills replaced by gstack
for skill in benchmark canary-watch safety-guard browser-qa verification-loop security-review design-system; do
  target="$HOME/.claude/skills/$skill"
  if [ -L "$target" ] || [ -d "$target" ]; then
    rm -rf "$target"
  fi
done

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
if [ "$TMUX_AVAILABLE" = "1" ]; then
  node "$SCRIPT_DIR/scripts/merge-settings.js" --tmux
else
  node "$SCRIPT_DIR/scripts/merge-settings.js"
fi

# ── 4b. Merge hooks from hooks.json into settings.json ──
echo "[4b] Merging hooks into settings.json..."
node "$SCRIPT_DIR/scripts/merge-hooks.js" "$SCRIPT_DIR/hooks/hooks.json"

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
    ACTUAL_CHECKSUM=$(sha256 "$_tmp_karpathy")
    if [ "$ACTUAL_CHECKSUM" = "$KARPATHY_EXPECTED_CHECKSUM" ]; then
      cat "$_tmp_karpathy" >> "$HOME/.claude/CLAUDE.md"
      echo "    Karpathy guidelines appended"
    else
      echo "    WARNING: Checksum mismatch, skipping Karpathy guidelines"
    fi
  fi
fi

# Generate manifest from SOURCE files (only tracks what my-claude installs, not user content)
{
  # Core agents — from source directories
  find "$SCRIPT_DIR/agents/core" -maxdepth 1 -name '*.md' ! -name 'agent-teams-reference.md' -exec sh -c 'echo "agents/$(basename "$1")"' _ {} \;
  find "$SCRIPT_DIR/agents/omo" -name '*.md' -exec sh -c 'echo "agents/$(basename "$1")"' _ {} \;
  find "$SCRIPT_DIR/agents/omc" -name '*.md' -exec sh -c 'echo "agents/$(basename "$1")"' _ {} \;
  find "$SCRIPT_DIR/agents/agency/engineering" -name '*.md' -exec sh -c 'echo "agents/$(basename "$1")"' _ {} \;
  # Agent packs — from source directories
  for pack in academic design game-development marketing paid-media product project-management sales spatial-computing specialized support testing; do
    find "$SCRIPT_DIR/agents/agency/$pack" -name '*.md' -exec sh -c 'echo "agent-packs/'"$pack"'/$(basename "$1")"' _ {} \; 2>/dev/null || true
  done
  # Skills — from source directories
  find "$SCRIPT_DIR/skills/ecc" -maxdepth 2 -name 'SKILL.md' -exec sh -c 'echo "skills/$(basename "$(dirname "$1")")/SKILL.md"' _ {} \;
  find "$SCRIPT_DIR/skills/omc" -maxdepth 2 -name 'SKILL.md' -exec sh -c 'echo "skills/$(basename "$(dirname "$1")")/SKILL.md"' _ {} \;
  find "$SCRIPT_DIR/skills/core" -maxdepth 2 -name 'SKILL.md' -exec sh -c 'echo "skills/$(basename "$(dirname "$1")")/SKILL.md"' _ {} \; 2>/dev/null
  find "$HOME/.claude/skills/gstack" -maxdepth 2 -name 'SKILL.md' -exec sh -c 'echo "skills/$(basename "$(dirname "$1")")/SKILL.md"' _ {} \; 2>/dev/null || true
  # Rules — from source
  find "$SCRIPT_DIR/rules" -name '*.md' | while read -r f; do echo "rules/${f#$SCRIPT_DIR/rules/}"; done
  # Hooks
  echo "hooks/hooks.json"
  echo "hooks/session-start.sh"
  # Docs
  echo "docs/nexus/agent-teams-reference.md"
  find "$SCRIPT_DIR/agents/agency/strategy" -name '*.md' -exec sh -c 'echo "docs/nexus/$(basename "$1")"' _ {} \;
} | sort -u > "$HOME/.claude/.my-claude-manifest"
echo "  Manifest saved ($(wc -l < "$HOME/.claude/.my-claude-manifest") entries)"

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
TEAMMATE_MODE=$(node -e "try{const h=process.env.HOME||process.env.USERPROFILE;console.log(JSON.parse(require('fs').readFileSync(h+'/.claude/settings.json','utf8')).teammateMode||'auto')}catch(e){console.log('auto')}")
echo "  version:          v${INSTALLING_VERSION}"
echo "  teammateMode:     $TEAMMATE_MODE"
echo ""
# Record installed version
echo "$INSTALLING_VERSION" > "$HOME/.claude/.my-claude-version"

echo "=== Install complete ==="
