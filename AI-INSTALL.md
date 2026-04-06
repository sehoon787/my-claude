# my-claude AI Installation Guide

You are an AI agent setting up a Claude Code multi-agent orchestration environment.
The plugin bundles 200+ agents (50+ core + 136 domain agent-packs), 200+ skills, 64 rules, 7 hooks, and 3 MCP servers.
Only 2-3 steps are needed.

---

## Step 1: Install the plugin

```bash
# Inside a Claude Code session:
/plugin marketplace add sehoon787/my-claude
/plugin install my-claude@my-claude
```

After plugin install, configure Boss and MCP servers globally:

```bash
# Set Boss as default agent + register MCP servers globally (one-time setup)
node -e "const fs=require('fs'),p=require('path'),f=p.join(require('os').homedir(),'.claude','settings.json');const s=fs.existsSync(f)?JSON.parse(fs.readFileSync(f,'utf8')):{};s.env={...s.env,CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS:'1'};s.agent=s.agent||'boss';s.mcpServers={...s.mcpServers,context7:{type:'url',url:'https://mcp.context7.com/mcp'},exa:{type:'url',url:'https://mcp.exa.ai/mcp?tools=web_search_exa'},grep_app:{type:'url',url:'https://mcp.grep.app'}};fs.writeFileSync(f,JSON.stringify(s,null,2))"
```

The plugin records its version automatically. To check: `cat ~/.claude/.my-claude-version`

This installs:
- 50+ core agents in ~/.claude/agents/ (always loaded): Boss, 9 OMO, 19 OMC, 23 engineering
- 136 domain agent-packs in ~/.claude/agent-packs/ (on-demand via symlink)
- 200+ skills (135 ECC + 31 OMC + 2 Core + 31 gstack)
  Note: gstack skills (27) are installed separately in Step 2.
- 64 rules
- 7 behavioral hooks (SessionStart, PreToolUse, PostToolUse, SubagentStop, TeammateIdle, TaskCompleted, Stop)
- 3 MCP servers globally (Context7, Exa, grep.app) — available in all projects
- Boss meta-orchestrator as default agent

## Step 1b: Manual install (if plugin unavailable)

```bash
# If plugin install is not available:
git clone --depth 1 https://github.com/sehoon787/my-claude.git /tmp/my-claude
mkdir -p ~/.claude/agents ~/.claude/agent-packs ~/.claude/skills ~/.claude/rules ~/.claude/hooks ~/.claude/docs/nexus

# ── Manifest-based cleanup (safe upgrade: only removes my-claude's own files) ──
if [ -f "$HOME/.claude/.my-claude-manifest" ]; then
  echo "Cleaning previous my-claude install via manifest..."
  while IFS= read -r rel_path; do
    [ -f "$HOME/.claude/$rel_path" ] && rm -f "$HOME/.claude/$rel_path"
  done < "$HOME/.claude/.my-claude-manifest"
  find "$HOME/.claude/agent-packs" -type d -empty -delete 2>/dev/null || true
fi

# ── Legacy cleanup (zsh-safe, for installs before manifest was introduced) ──
for prefix in marketing- sales- paid- academic- design- support- testing- specialized- product- project-management- game- godot- unity- unreal- roblox- xr- phase- scenario-; do
  find "$HOME/.claude/agents" -maxdepth 1 -name "${prefix}*.md" -delete 2>/dev/null || true
done

# Remove stale agent-pack directories not in current version
EXPECTED_PACKS="academic design game-development marketing paid-media product project-management sales spatial-computing specialized support testing"
for dir in "$HOME/.claude/agent-packs"/*/; do
  [ ! -d "$dir" ] && continue
  dirname=$(basename "$dir")
  echo " $EXPECTED_PACKS " | grep -q " $dirname " || rm -rf "$dir"
done

# ── Core agents (always loaded) ──
find /tmp/my-claude/agents/core -maxdepth 1 -name '*.md' ! -name 'agent-teams-reference.md' -exec cp {} ~/.claude/agents/ \;
cp /tmp/my-claude/agents/omo/*.md ~/.claude/agents/
cp /tmp/my-claude/agents/omc/*.md ~/.claude/agents/
cp /tmp/my-claude/agents/agency/engineering/*.md ~/.claude/agents/

# ── Domain agent-packs (on-demand) ──
for dir in academic design game-development marketing paid-media product project-management sales spatial-computing specialized support testing; do
  mkdir -p ~/.claude/agent-packs/$dir
  find /tmp/my-claude/agents/agency/$dir -name '*.md' -exec cp {} ~/.claude/agent-packs/$dir/ \;
done

# ── Dedup: remove pack entries that duplicate core agents ──
for f in ~/.claude/agents/*.md; do
  [ ! -f "$f" ] && continue
  find ~/.claude/agent-packs -name "$(basename "$f")" -delete 2>/dev/null || true
done

# ── Strategy docs ──
mkdir -p ~/.claude/docs/nexus
cp /tmp/my-claude/agents/core/agent-teams-reference.md ~/.claude/docs/nexus/
find /tmp/my-claude/agents/agency/strategy -name '*.md' -exec cp {} ~/.claude/docs/nexus/ \;

# ── Skills (pre-clean file/symlink conflicts, then copy) ──
for src in /tmp/my-claude/skills/ecc/*/; do
  [ ! -d "$src" ] && continue
  target="$HOME/.claude/skills/$(basename "$src")"
  { [ -L "$target" ] || { [ -e "$target" ] && [ ! -d "$target" ]; }; } && rm -f "$target"
done
for src in /tmp/my-claude/skills/omc/*/; do
  [ ! -d "$src" ] && continue
  target="$HOME/.claude/skills/$(basename "$src")"
  { [ -L "$target" ] || { [ -e "$target" ] && [ ! -d "$target" ]; }; } && rm -f "$target"
done
cp -r /tmp/my-claude/skills/ecc/* ~/.claude/skills/
cp -r /tmp/my-claude/skills/omc/* ~/.claude/skills/

# ── gstack (sprint-process harness with 27 skills) ──
GSTACK_DIR="$HOME/.claude/skills/gstack"
if [ -d "$GSTACK_DIR/.git" ]; then
  (cd "$GSTACK_DIR" && git pull --ff-only 2>/dev/null || true)
else
  git clone --depth 1 https://github.com/garrytan/gstack.git "$GSTACK_DIR" 2>/dev/null || true
fi
# Remove ECC skills superseded by gstack
for skill in benchmark canary-watch safety-guard browser-qa verification-loop security-review design-system; do
  target="$HOME/.claude/skills/$skill"
  if [ -L "$target" ]; then
    link_dest=$(readlink "$target")
    case "$link_dest" in *gstack*) continue ;; esac
    rm -f "$target"
  elif [ -d "$target" ]; then
    rm -rf "$target"
  fi
done
# Run gstack setup if bun is available
if [ -d "$GSTACK_DIR" ] && command -v bun >/dev/null 2>&1 && [ -f "$GSTACK_DIR/setup" ]; then
  (cd "$GSTACK_DIR" && bun install 2>/dev/null && ./setup --host claude 2>/dev/null || true)
  git -C "$GSTACK_DIR" checkout -- '*/SKILL.md' 'SKILL.md' 2>/dev/null || true
fi
# Auto-upgrade config
mkdir -p "$HOME/.gstack"
echo '{"auto_upgrade":true}' > "$HOME/.gstack/config.json"

# Rules, hooks
cp -r /tmp/my-claude/rules/* ~/.claude/rules/
cp /tmp/my-claude/hooks/hooks.json ~/.claude/hooks/
cp /tmp/my-claude/hooks/session-start.sh ~/.claude/hooks/

# MCP servers
claude mcp add --transport http --scope user context7 "https://mcp.context7.com/mcp"
claude mcp add --transport http --scope user exa "https://mcp.exa.ai/mcp?tools=web_search_exa"
claude mcp add --transport http --scope user grep_app "https://mcp.grep.app"

# Merge hooks + settings
node /tmp/my-claude/scripts/merge-hooks.js ~/.claude/hooks/hooks.json
node /tmp/my-claude/scripts/merge-settings.js

# ── Generate manifest from SOURCE (only tracks my-claude's own files, not user content) ──
{
  find /tmp/my-claude/agents/core -maxdepth 1 -name '*.md' ! -name 'agent-teams-reference.md' -exec sh -c 'echo "agents/$(basename "$1")"' _ {} \;
  find /tmp/my-claude/agents/omo -name '*.md' -exec sh -c 'echo "agents/$(basename "$1")"' _ {} \;
  find /tmp/my-claude/agents/omc -name '*.md' -exec sh -c 'echo "agents/$(basename "$1")"' _ {} \;
  find /tmp/my-claude/agents/agency/engineering -name '*.md' -exec sh -c 'echo "agents/$(basename "$1")"' _ {} \;
  for pack in academic design game-development marketing paid-media product project-management sales spatial-computing specialized support testing; do
    find /tmp/my-claude/agents/agency/$pack -name '*.md' -exec sh -c 'echo "agent-packs/'"$pack"'/$(basename "$1")"' _ {} \; 2>/dev/null || true
  done
  find /tmp/my-claude/skills/ecc -maxdepth 2 -name 'SKILL.md' -exec sh -c 'echo "skills/$(basename "$(dirname "$1")")/SKILL.md"' _ {} \;
  find /tmp/my-claude/skills/omc -maxdepth 2 -name 'SKILL.md' -exec sh -c 'echo "skills/$(basename "$(dirname "$1")")/SKILL.md"' _ {} \;
  find /tmp/my-claude/rules -name '*.md' | while read -r f; do echo "rules/${f#/tmp/my-claude/rules/}"; done
  echo "hooks/hooks.json"
  echo "hooks/session-start.sh"
  echo "docs/nexus/agent-teams-reference.md"
  find /tmp/my-claude/agents/agency/strategy -name '*.md' -exec sh -c 'echo "docs/nexus/$(basename "$1")"' _ {} \;
} | sort -u > ~/.claude/.my-claude-manifest

# Record installed version
node /tmp/my-claude/scripts/get-version.js /tmp/my-claude/.claude-plugin/plugin.json > ~/.claude/.my-claude-version
rm -rf /tmp/my-claude
```

Note: Manual install now includes hooks configuration. The `scripts/merge-hooks.js` resolves paths for both macOS and Windows.

## Step 2: Install companion tools

```bash
# Clone and run the companion installer
git clone --depth 1 https://github.com/sehoon787/my-claude.git /tmp/my-claude
bash /tmp/my-claude/install.sh
rm -rf /tmp/my-claude
```

This installs:
- Anthropic Official Skills (proprietary — cannot be bundled)
- OMC CLI (`oh-my-claude-sisyphus`)
- omo CLI (`oh-my-opencode`)
- ast-grep + comment-checker
- Karpathy coding guidelines (appended to CLAUDE.md)
- gstack sprint-process harness (27 skills — code review, QA, debugging, security, deployment)

### Activating Agent Packs

After installation, activate domain-specific agent packs:

```bash
# Activate specific packs (symlinks agents to ~/.claude/agents/)
bash install.sh --with-packs marketing,testing,sales

# Available packs: academic, design, game-development, marketing,
# paid-media, product, project-management, sales, spatial-computing,
# specialized, support, testing
```

Plugin users don't need this — all 150 domain agents are already accessible via the `my-claude:agency:*` namespace.

## Step 3 (Optional): Fix OpenCode TUI crash

If using OpenCode, enable the fallback builder agent:

```bash
node -e "
const fs = require('fs');
const os = require('os');
const path = require('path');
const cfgPath = path.join(os.homedir(), '.config', 'opencode', 'oh-my-opencode.json');
try {
  const cfg = JSON.parse(fs.readFileSync(cfgPath, 'utf8'));
  cfg.sisyphus_agent = { ...(cfg.sisyphus_agent || {}), default_builder_enabled: true };
  fs.writeFileSync(cfgPath, JSON.stringify(cfg, null, 2));
  console.log('OpenCode TUI fix applied');
} catch (e) {
  console.log('Skipped (oh-my-opencode.json not found yet)');
}
"
```

## Alternative: Skills only (via skills.sh)

If you only need the skills (not agents, rules, hooks, or MCP configs), use:

```bash
npx skills add sehoon787/my-claude -y -g
```

This installs skills to `~/.agents/skills/` and auto-symlinks to `~/.claude/skills/`. Cross-platform: works with Claude Code, Codex, Cursor, and other tools that support the skills.sh standard. For the full experience (agents, hooks, rules, MCP), complete Steps 1–2 above instead.

Note: `npx skills add` does NOT install gstack. gstack requires Step 2 (`install.sh`) for full installation, including the superseded-skill cleanup and auto-upgrade config.

## Verify

```bash
echo "Core agents:      $(find ~/.claude/agents -name '*.md' 2>/dev/null | wc -l) (no domain agents in core)"
echo "Agent packs:      $(find ~/.claude/agent-packs -name '*.md' 2>/dev/null | wc -l)"
echo "Plugin skills:    $(find ~/.claude/skills -name 'SKILL.md' 2>/dev/null | wc -l)"
echo "Rules:            $(find ~/.claude/rules -name '*.md' 2>/dev/null | wc -l)"
echo "Anthropic skills: $(ls -d ~/.claude/skills/pdf ~/.claude/skills/docx 2>/dev/null | wc -l) key skills"
echo "Manifest:         $(wc -l < ~/.claude/.my-claude-manifest 2>/dev/null || echo 'MISSING') entries"
echo "Duplicates:       $(find ~/.claude/agents ~/.claude/agent-packs -name '*.md' -exec basename {} \; | sort | uniq -d | wc -l | tr -d ' ') (should be 0)"
echo "gstack:           $(test -d ~/.claude/skills/gstack/.git && echo 'OK' || echo 'MISSING')"
echo "omc:              $(command -v omc >/dev/null 2>&1 && echo 'OK' || echo 'MISSING')"
echo "omo:              $(command -v oh-my-opencode >/dev/null 2>&1 && echo 'OK' || echo 'MISSING')"
echo "Version:          $(cat ~/.claude/.my-claude-version 2>/dev/null || echo 'unknown')"
```

Expected:
- Core agents: 55+ (no domain agents in core)
- Agent packs: 136+
- Plugin skills: 200+
- Rules: 77
- Anthropic skills: 2 key skills (pdf, docx)
- Manifest: 300+ entries
- Duplicates: 0 (should be 0)
- gstack: OK
- omc: OK
- omo: OK
- Version: matches latest release

Setup complete. Boss orchestrator is ready.
