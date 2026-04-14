# my-claude AI Installation Guide

You are an AI agent setting up a Claude Code multi-agent orchestration environment.
The plugin bundles 200+ agents (56 core + 136 domain agent-packs), 200+ skills, 89 rules, 7 hooks, and 3 MCP servers.
Only 2-3 steps are needed.

---

## Step 1: Install the plugin

```bash
# Inside a Claude Code session:
/plugin marketplace add sehoon787/my-claude
/plugin install my-claude@my-claude
```

After plugin install, configure Boss, MCP servers, and HUD globally:

```bash
# Set Boss as default agent + register MCP servers + configure HUD statusline (one-time setup)
node -e "const fs=require('fs'),p=require('path'),os=require('os'),f=p.join(os.homedir(),'.claude','settings.json');const s=fs.existsSync(f)?JSON.parse(fs.readFileSync(f,'utf8')):{};s.env={...s.env,CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS:'1'};s.agent=s.agent||'boss';s.mcpServers={...s.mcpServers,context7:{type:'url',url:'https://mcp.context7.com/mcp'},exa:{type:'url',url:'https://mcp.exa.ai/mcp?tools=web_search_exa'},grep_app:{type:'url',url:'https://mcp.grep.app'}};if(!s.statusLine){const h=p.join(os.homedir(),'.claude','hud','omc-hud.mjs');if(fs.existsSync(h)){s.statusLine={type:'command',command:'node '+h.split(p.sep).join('/')}}}fs.writeFileSync(f,JSON.stringify(s,null,2))"
```

The plugin records its version automatically. To check: `cat ~/.claude/.my-claude-version`

This installs:
- 56 core agents in ~/.claude/agents/ (always loaded): Boss, 9 OMO, 19 OMC, 26 engineering
- 136 domain agent-packs in ~/.claude/agent-packs/ (on-demand via symlink)
- 200+ skills (180+ ECC + 36 OMC + 3 Core + 40 gstack)
  Note: gstack skills are installed separately in Step 2.
- 89 rules
- 7 behavioral hooks (SessionStart, PreToolUse, PostToolUse, SubagentStop, TeammateIdle, TaskCompleted, Stop)
  - The SessionStart hook auto-creates a `.briefing/` vault per-project (with `INDEX.md`) on first session. This provides persistent project context, decision logs, and session summaries.
- 3 MCP servers globally (Context7, Exa, grep.app) — available in all projects
- Boss meta-orchestrator as default agent
- HUD statusline (via OMC wrapper — shows context usage, active agents, task progress)

## Step 1b: Manual install (if plugin unavailable)

`install.sh` is the single source of truth for installation. It handles everything:
agents, skills, rules, hooks, MCP servers, companion tools (omc, omo, ast-grep),
gstack, Anthropic skills, Karpathy guidelines, and manifest generation.

```bash
# Resolve the latest release tag so manual installs match published releases.
# Falls back to 'main' when the API is unreachable or rate-limited.
LATEST=$(curl -s https://api.github.com/repos/sehoon787/my-claude/releases/latest | grep '"tag_name"' | head -1 | cut -d'"' -f4)
git clone --depth 1 --branch "${LATEST:-main}" https://github.com/sehoon787/my-claude.git /tmp/my-claude
git -C /tmp/my-claude submodule update --init --depth 1
bash /tmp/my-claude/install.sh
rm -rf /tmp/my-claude
```

This installs everything in one step:
- 56 core agents + 136 domain agent-packs
- 200+ skills (ECC + OMC + Core + gstack + Superpowers)
- 89 rules, 7 hooks
- 3 MCP servers (Context7, Exa, grep.app)
- Companion tools: OMC CLI, omo CLI, ast-grep
- Anthropic Official Skills (pdf, docx)
- Karpathy coding guidelines
- gstack sprint-process harness (40 skills)
- Boss meta-orchestrator as default agent
- HUD statusline (context usage, active agents, task progress)

### Activating Agent Packs

After installation, activate domain-specific agent packs:

```bash
# Re-run install.sh with --with-packs flag
LATEST=$(curl -s https://api.github.com/repos/sehoon787/my-claude/releases/latest | grep '"tag_name"' | head -1 | cut -d'"' -f4)
git clone --depth 1 --branch "${LATEST:-main}" https://github.com/sehoon787/my-claude.git /tmp/my-claude
git -C /tmp/my-claude submodule update --init --depth 1
bash /tmp/my-claude/install.sh --with-packs=marketing,testing,sales
rm -rf /tmp/my-claude

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
echo "gstack:           $(find ~/.claude/skills -path '*/gstack/SKILL.md' 2>/dev/null | head -1 | grep -q . && echo 'OK' || echo 'MISSING')"
echo "omc:              $(command -v omc >/dev/null 2>&1 && echo 'OK' || echo 'MISSING')"
echo "omo:              $(command -v oh-my-opencode >/dev/null 2>&1 && echo 'OK' || echo 'MISSING')"
echo "Version:          $(cat ~/.claude/.my-claude-version 2>/dev/null || echo 'unknown')"
```

Expected:
- Core agents: 55+ (no domain agents in core)
- Agent packs: 136+
- Plugin skills: 200+
- Rules: 90
- Anthropic skills: 2 key skills (pdf, docx)
- Manifest: 300+ entries
- Duplicates: 0 (should be 0)
- gstack: OK
- omc: OK
- omo: OK
- Version: matches latest release

Setup complete. Boss orchestrator is ready.
