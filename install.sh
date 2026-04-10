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

# ── Argument parsing ──
WITH_PACKS=""
SKIP_AGENCY=0
SKIP_ECC=0
SKIP_OMC=0
SKIP_GSTACK=0
SKIP_SUPERPOWERS=0
for arg in "$@"; do
  case "$arg" in
    --with-packs=*) WITH_PACKS="${arg#*=}" ;;
    --skip-agency)     SKIP_AGENCY=1 ;;
    --skip-ecc)        SKIP_ECC=1 ;;
    --skip-omc)        SKIP_OMC=1 ;;
    --skip-gstack)     SKIP_GSTACK=1 ;;
    --skip-superpowers) SKIP_SUPERPOWERS=1 ;;
    --self-only)       SKIP_AGENCY=1; SKIP_ECC=1; SKIP_OMC=1; SKIP_GSTACK=1; SKIP_SUPERPOWERS=1 ;;
    -h|--help)
      cat <<'EOF'
Usage:
  bash install.sh
  bash install.sh --with-packs=<pack1,pack2,...>

Options:
  --with-packs=<packs>    Comma-separated list of agent packs to symlink into ~/.claude/agents/
                          Available: academic, design, game-development, marketing, paid-media,
                                     product, project-management, sales, spatial-computing,
                                     specialized, support, testing
  --skip-agency           Skip agency-agents upstream install
  --skip-ecc              Skip everything-claude-code upstream install
  --skip-omc              Skip oh-my-claudecode upstream install
  --skip-gstack           Skip gstack upstream install
  --skip-superpowers      Skip superpowers upstream install
  --self-only             Install only self-owned files (implies all --skip-* flags)
EOF
      exit 0
      ;;
  esac
done

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

# ── Upstream helper ──
CLONE_TMPDIR=$(mktemp -d)
trap 'rm -rf "$CLONE_TMPDIR"' EXIT

UPSTREAM_DIR=""
init_upstream() {
  local name="$1" url="$2"
  local submod_path="$SCRIPT_DIR/upstream/$name"
  if [ -d "$submod_path/.git" ] || [ -f "$submod_path/.git" ]; then
    UPSTREAM_DIR="$submod_path"
    return 0
  fi
  if git -C "$SCRIPT_DIR" submodule update --init --depth 1 "upstream/$name" 2>/dev/null; then
    UPSTREAM_DIR="$submod_path"
    return 0
  fi
  echo "  WARNING: submodule init failed for $name, falling back to git clone..."
  UPSTREAM_DIR="$CLONE_TMPDIR/$name"
  git clone --depth 1 "$url" "$UPSTREAM_DIR" 2>/dev/null || return 1
}

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

# ── 1a. Self-owned files (always installed) ──
echo "  [core] Installing self-owned files..."

# agents — core tier (always loaded)
find "$SCRIPT_DIR/agents/core" -maxdepth 1 -name '*.md' ! -name 'agent-teams-reference.md' -exec cp {} "$HOME/.claude/agents/" \;
cp "$SCRIPT_DIR"/agents/omo/*.md "$HOME/.claude/agents/"

# skills/core
if [ -d "$SCRIPT_DIR/skills/core" ]; then
  for src in "$SCRIPT_DIR"/skills/core/*/; do
    [ ! -d "$src" ] && continue
    name=$(basename "$src")
    target="$HOME/.claude/skills/$name"
    if [ -L "$target" ] || { [ -e "$target" ] && [ ! -d "$target" ]; }; then
      rm -f "$target"
    fi
  done
  cp -r "$SCRIPT_DIR"/skills/core/* "$HOME/.claude/skills/"
fi

# docs/nexus — reference material (never parsed as agents)
cp "$SCRIPT_DIR/agents/core/agent-teams-reference.md" "$HOME/.claude/docs/nexus/"

# ── 1b. agency-agents upstream ──
if [ "$SKIP_AGENCY" = "0" ]; then
  echo "  [agency] Installing agency-agents..."
  if init_upstream "agency-agents" "https://github.com/msitarzewski/agency-agents"; then
    # engineering/*.md → core agents (always loaded)
    find "$UPSTREAM_DIR/engineering" -maxdepth 1 -name '*.md' -exec cp {} "$HOME/.claude/agents/" \;

    # domain agent-packs
    for pack in academic design marketing paid-media product project-management sales spatial-computing specialized support testing; do
      [ -d "$UPSTREAM_DIR/$pack" ] && cp -r "$UPSTREAM_DIR/$pack/"*.md "$HOME/.claude/agent-packs/$pack/" 2>/dev/null || true
    done
    # game-development may contain subdirectories; use find to flatten
    if [ -d "$UPSTREAM_DIR/game-development" ]; then
      find "$UPSTREAM_DIR/game-development" -name '*.md' -exec cp {} "$HOME/.claude/agent-packs/game-development/" \;
    fi

    # strategy/*.md → docs/nexus (never parsed as agents)
    if [ -d "$UPSTREAM_DIR/strategy" ]; then
      find "$UPSTREAM_DIR/strategy" -name '*.md' -exec cp {} "$HOME/.claude/docs/nexus/" \;
    fi
  else
    echo "  WARNING: agency-agents install failed"
  fi
fi

# ── 1c. ECC upstream ──
if [ "$SKIP_ECC" = "0" ]; then
  echo "  [ecc] Installing everything-claude-code..."
  if ! claude plugin add affaan-m/everything-claude-code 2>/dev/null; then
    if init_upstream "ecc" "https://github.com/affaan-m/everything-claude-code"; then
      # Pre-clean: resolve file/symlink vs directory conflicts
      for src in "$UPSTREAM_DIR"/skills/*/; do
        [ ! -d "$src" ] && continue
        name=$(basename "$src")
        target="$HOME/.claude/skills/$name"
        if [ -L "$target" ] || { [ -e "$target" ] && [ ! -d "$target" ]; }; then
          rm -f "$target"
        fi
      done
      cp -r "$UPSTREAM_DIR"/skills/* "$HOME/.claude/skills/"
      if [ -d "$UPSTREAM_DIR/rules" ]; then
        cp -r "$UPSTREAM_DIR"/rules/* "$HOME/.claude/rules/"
      fi
    else
      echo "  WARNING: ECC install failed"
    fi
  fi
fi

# ── 1c-post. Self-owned rules (override ECC rules if same name) ──
if [ -d "$SCRIPT_DIR/rules" ]; then
  cp -r "$SCRIPT_DIR"/rules/* "$HOME/.claude/rules/" 2>/dev/null || true
fi

# ── 1d. OMC upstream ──
if [ "$SKIP_OMC" = "0" ]; then
  echo "  [omc] Installing oh-my-claudecode..."
  if init_upstream "omc" "https://github.com/Yeachan-Heo/oh-my-claudecode"; then
    # Pre-clean: resolve file/symlink vs directory conflicts for skills
    for src in "$UPSTREAM_DIR"/skills/*/; do
      [ ! -d "$src" ] && continue
      name=$(basename "$src")
      target="$HOME/.claude/skills/$name"
      if [ -L "$target" ] || { [ -e "$target" ] && [ ! -d "$target" ]; }; then
        rm -f "$target"
      fi
    done
    find "$UPSTREAM_DIR/agents" -maxdepth 1 -name '*.md' -exec cp {} "$HOME/.claude/agents/" \;
    cp -r "$UPSTREAM_DIR"/skills/* "$HOME/.claude/skills/"
  else
    echo "  WARNING: OMC install failed"
  fi
fi

# ── 1e. gstack upstream ──
if [ "$SKIP_GSTACK" = "0" ]; then
  echo "  [gstack] Installing gstack skills..."

  # 1) Remove ECC skills superseded by gstack (before gstack copy)
  for skill in benchmark canary-watch safety-guard browser-qa verification-loop security-review design-system; do
    target="$HOME/.claude/skills/$skill"
    if [ -L "$target" ]; then
      rm -f "$target"
    elif [ -d "$target" ]; then
      rm -rf "$target"
    fi
  done

  if init_upstream "gstack" "https://github.com/garrytan/gstack"; then
    # Pre-clean: resolve file/symlink vs directory conflicts
    for src in "$UPSTREAM_DIR"/*/; do
      [ ! -d "$src" ] && continue
      name=$(basename "$src")
      target="$HOME/.claude/skills/$name"
      if [ -L "$target" ] || { [ -e "$target" ] && [ ! -d "$target" ]; }; then
        rm -f "$target"
      fi
    done

    # Root gstack meta-skill
    mkdir -p "$HOME/.claude/skills/gstack"
    cp "$UPSTREAM_DIR/SKILL.md" "$HOME/.claude/skills/gstack/" 2>/dev/null || true

    # Individual skill subdirectories
    for skill_dir in "$UPSTREAM_DIR"/*/; do
      [ -f "$skill_dir/SKILL.md" ] || continue
      skill_name=$(basename "$skill_dir")
      mkdir -p "$HOME/.claude/skills/$skill_name"
      cp "$skill_dir/SKILL.md" "$HOME/.claude/skills/$skill_name/"
    done
  else
    echo "  WARNING: gstack skills install failed"
  fi

  # 2) Runtime binary build (optional — needed for /browse and /qa)
  echo "  [gstack] Setting up runtime (browser binary)..."
  GSTACK_RUNTIME="$HOME/.gstack/runtime"

  # Install bun if missing (required for gstack browser)
  if ! command -v bun >/dev/null 2>&1; then
    echo "  [gstack] Installing bun..."
    curl -fsSL https://bun.sh/install | bash 2>/dev/null || true
    export BUN_INSTALL="$HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"
  fi

  # Clone gstack for binary build (separate from vendored skills)
  if [ -d "$GSTACK_RUNTIME/.git" ]; then
    git -C "$GSTACK_RUNTIME" pull --ff-only 2>/dev/null || true
  else
    rm -rf "$GSTACK_RUNTIME"
    git clone --depth 1 https://github.com/garrytan/gstack.git "$GSTACK_RUNTIME" 2>/dev/null || true
  fi

  # Run gstack setup for binary compilation
  GSTACK_BROWSER_OK=0
  if [ -d "$GSTACK_RUNTIME" ] && command -v bun >/dev/null 2>&1 && [ -f "$GSTACK_RUNTIME/setup" ]; then
    if (cd "$GSTACK_RUNTIME" && ./setup --host claude 2>/dev/null); then
      GSTACK_BROWSER_OK=1
    fi
  fi
  if [ "$GSTACK_BROWSER_OK" = "0" ]; then
    echo "  [gstack] WARNING: Browser runtime not available. /browse and /qa skills will not work."
    echo "           Text-based gstack skills (review, ship, plan-*, etc.) are installed and functional."
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
fi

# ── 1f. superpowers upstream ──
if [ "$SKIP_SUPERPOWERS" = "0" ]; then
  echo "  [superpowers] Installing superpowers..."
  if init_upstream "superpowers" "https://github.com/obra/superpowers"; then
    # Pre-clean: resolve file/symlink vs directory conflicts
    for src in "$UPSTREAM_DIR"/skills/*/; do
      [ ! -d "$src" ] && continue
      name=$(basename "$src")
      target="$HOME/.claude/skills/$name"
      if [ -L "$target" ] || { [ -e "$target" ] && [ ! -d "$target" ]; }; then
        rm -f "$target"
      fi
    done
    find "$UPSTREAM_DIR/agents" -maxdepth 1 -name '*.md' | while read -r agent_src; do
      agent_base=$(basename "$agent_src")
      if [ -f "$HOME/.claude/agents/$agent_base" ]; then
        echo "  [superpowers] Skipping $agent_base (higher-tier version already installed)"
      else
        cp "$agent_src" "$HOME/.claude/agents/"
      fi
    done
    cp -r "$UPSTREAM_DIR"/skills/* "$HOME/.claude/skills/"
  else
    echo "  WARNING: superpowers install failed"
  fi
fi

# ── --with-packs: symlink requested pack agents into ~/.claude/agents/ ──
if [ -n "$WITH_PACKS" ]; then
  IFS=',' read -ra PACKS <<< "$WITH_PACKS"
  for pack in "${PACKS[@]}"; do
    pack_dir="$HOME/.claude/agent-packs/$pack"
    if [ -d "$pack_dir" ]; then
      for agent in "$pack_dir"/*.md; do
        [ -f "$agent" ] || continue
        basename=$(basename "$agent")
        # Skip if file already exists (dedup)
        [ -f "$HOME/.claude/agents/$basename" ] && continue
        ln -sf "$agent" "$HOME/.claude/agents/$basename"
        echo "  Symlinked: $basename (from $pack)"
      done
    else
      echo "  WARNING: Pack '$pack' not found in $HOME/.claude/agent-packs/"
    fi
  done
fi

# Dedup: remove agent-pack entries that duplicate core agents
for f in "$HOME/.claude/agents"/*.md; do
  [ ! -f "$f" ] && continue
  name=$(basename "$f")
  find "$HOME/.claude/agent-packs" -name "$name" -delete 2>/dev/null || true
done

echo "  Plugin files installed"

# ── 2. Hooks ──
echo "[2/6] Installing hooks..."
mkdir -p "$HOME/.claude/hooks"
cp "$SCRIPT_DIR/hooks/hooks.json"      "$HOME/.claude/hooks/"
cp "$SCRIPT_DIR/hooks/session-start.sh" "$HOME/.claude/hooks/"
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

# ── Generate manifest from installed files in $HOME/.claude/ ──
{
  find "$HOME/.claude/agents" -maxdepth 1 -name '*.md' -exec sh -c 'echo "agents/$(basename "$1")"' _ {} \;
  for pack in academic design game-development marketing paid-media product project-management sales spatial-computing specialized support testing; do
    find "$HOME/.claude/agent-packs/$pack" -name '*.md' -exec sh -c 'echo "agent-packs/'"$pack"'/$(basename "$1")"' _ {} \; 2>/dev/null || true
  done
  find "$HOME/.claude/skills" -maxdepth 2 -name 'SKILL.md' -exec sh -c 'echo "skills/$(basename "$(dirname "$1")")/SKILL.md"' _ {} \;
  find "$HOME/.claude/rules" -name '*.md' | while read -r f; do echo "rules/${f#$HOME/.claude/rules/}"; done 2>/dev/null || true
  echo "hooks/hooks.json"
  echo "hooks/session-start.sh"
  echo "docs/nexus/agent-teams-reference.md"
  find "$HOME/.claude/docs/nexus" -name '*.md' -exec sh -c 'echo "docs/nexus/$(basename "$1")"' _ {} \; 2>/dev/null || true
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
git -C "$SCRIPT_DIR" rev-parse --short=12 HEAD 2>/dev/null > "$HOME/.claude/.my-claude-installed-sha" || true

echo "=== Install complete ==="
