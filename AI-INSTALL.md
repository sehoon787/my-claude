# my-claude AI Installation Guide

You are an AI agent setting up a Claude Code multi-agent orchestration environment.
The plugin bundles 186 agents (53 core + 133 domain agent-packs), 156 skills, 65 rules, 6 hooks, and 3 MCP servers.
Only 2-3 steps are needed.

---

## Step 1: Install the plugin

```bash
# Inside a Claude Code session:
/plugin marketplace add sehoon787/my-claude
/plugin install my-claude@my-claude
```

After plugin install, set Boss as default agent:

```bash
# Set Boss as default agent (one-time setup)
node -e "const fs=require('fs'),p=require('path'),f=p.join(require('os').homedir(),'.claude','settings.json');const s=fs.existsSync(f)?JSON.parse(fs.readFileSync(f,'utf8')):{};s.env={...s.env,CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS:'1'};s.agent=s.agent||'boss';fs.writeFileSync(f,JSON.stringify(s,null,2))"
```

This installs:
- 53 core agents in ~/.claude/agents/ (always loaded): Boss, 9 OMO, 19 OMC, 23 engineering
- 133 domain agent-packs in ~/.claude/agent-packs/ (on-demand via symlink)
- 156 skills (125 ECC + 31 OMC)
- 49 rules (9 common + 8 languages × 5)
- 6 behavioral hooks (SessionStart, PreToolUse, SubagentStop, TeammateIdle, TaskCompleted, Stop)
- 3 MCP servers (Context7, Exa, grep.app)
- Boss meta-orchestrator as default agent

## Step 1b: Manual install (if plugin unavailable)

```bash
# If plugin install is not available:
git clone --depth 1 https://github.com/sehoon787/my-claude.git /tmp/my-claude
mkdir -p ~/.claude/agents ~/.claude/agent-packs ~/.claude/skills ~/.claude/rules
# Clean up old flat installs
for prefix in marketing- sales- paid- academic- design- support- testing- specialized- product- project-management- game- godot- unity- unreal- roblox- xr- phase- scenario-; do
  rm -f ~/.claude/agents/${prefix}*.md
done
# Core agents (always loaded)
cp /tmp/my-claude/agents/core/boss.md /tmp/my-claude/agents/omo/*.md ~/.claude/agents/
cp /tmp/my-claude/agents/omc/*.md ~/.claude/agents/
cp /tmp/my-claude/agents/agency/engineering/*.md ~/.claude/agents/
# Domain agent-packs (on-demand)
for dir in academic design game-development marketing paid-media product project-management sales spatial-computing specialized support testing; do
  mkdir -p ~/.claude/agent-packs/$dir
  find /tmp/my-claude/agents/agency/$dir -name '*.md' -exec cp {} ~/.claude/agent-packs/$dir/ \;
done
# Strategy docs
mkdir -p ~/.claude/docs/nexus
cp /tmp/my-claude/agents/core/agent-teams-reference.md ~/.claude/docs/nexus/
find /tmp/my-claude/agents/agency/strategy -name '*.md' -exec cp {} ~/.claude/docs/nexus/ \;
cp -r /tmp/my-claude/skills/ecc/* ~/.claude/skills/
cp -r /tmp/my-claude/skills/omc/* ~/.claude/skills/
cp -r /tmp/my-claude/rules/* ~/.claude/rules/
claude mcp add --transport http --scope user context7 "https://mcp.context7.com/mcp"
claude mcp add --transport http --scope user exa "https://mcp.exa.ai/mcp?tools=web_search_exa"
claude mcp add --transport http --scope user grep_app "https://mcp.grep.app"
rm -rf /tmp/my-claude
```

After manual install, set Boss as default agent:

```bash
# Set Boss as default agent (one-time setup)
node -e "const fs=require('fs'),p=require('path'),f=p.join(require('os').homedir(),'.claude','settings.json');const s=fs.existsSync(f)?JSON.parse(fs.readFileSync(f,'utf8')):{};s.env={...s.env,CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS:'1'};s.agent=s.agent||'boss';fs.writeFileSync(f,JSON.stringify(s,null,2))"
```

Note: Manual install does not configure hooks. Run the node command above to set Boss as default agent. See SETUP.md Section 7 Option D for hooks setup.

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

## Verify

```bash
echo "Core agents:      $(find ~/.claude/agents -name '*.md' 2>/dev/null | wc -l)"
echo "Agent packs:      $(find ~/.claude/agent-packs -name '*.md' 2>/dev/null | wc -l)"
echo "Plugin skills:    $(find ~/.claude/skills -name 'SKILL.md' 2>/dev/null | wc -l)"
echo "Rules:            $(find ~/.claude/rules -name '*.md' 2>/dev/null | wc -l)"
echo "Anthropic skills: $(ls -d ~/.claude/skills/pdf ~/.claude/skills/docx 2>/dev/null | wc -l) key skills"
echo "omc:              $(command -v omc >/dev/null 2>&1 && echo 'OK' || echo 'MISSING')"
echo "omo:              $(command -v oh-my-opencode >/dev/null 2>&1 && echo 'OK' || echo 'MISSING')"
```

Expected:
- Core agents: 53+
- Agent packs: 133+
- Plugin skills: 156+
- Rules: 65
- Anthropic skills: 2 key skills (pdf, docx)
- omc: OK
- omo: OK

Setup complete. Boss orchestrator is ready.
