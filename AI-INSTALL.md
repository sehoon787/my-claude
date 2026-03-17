# my-claude AI Installation Guide

You are an AI agent setting up a Claude Code multi-agent orchestration environment.
Execute each bash code block below in order. If a step fails, diagnose and fix before continuing.

---

## 1. Prerequisites

```bash
node --version    # v20+ required
npm --version
git --version
claude --version  # v2.1+ required
mkdir -p ~/.claude/agents ~/.claude/skills ~/.claude/rules
```

## 2. Install OMC (Oh My Claude Code)

```bash
npm i -g oh-my-claude-sisyphus@latest
omc setup
```

## 3. Install omo (Oh My OpenAgent)

```bash
npm i -g oh-my-opencode@latest
oh-my-opencode install --no-tui --claude=yes --openai=no --gemini=no --copilot=no
```

## 3a. Fix OpenCode TUI crash

The oh-my-opencode plugin hides OpenCode's default `build` agent, causing a TUI crash (`TypeError: agents()[0].name`). Enable the fallback builder agent:

```bash
node -e "
const fs = require('fs');
const os = require('os');
const path = require('path');
const cfgPath = path.join(os.homedir(), '.config', 'opencode', 'oh-my-opencode.json');
const cfg = JSON.parse(fs.readFileSync(cfgPath, 'utf8'));
cfg.sisyphus_agent = { ...(cfg.sisyphus_agent || {}), default_builder_enabled: true };
fs.writeFileSync(cfgPath, JSON.stringify(cfg, null, 2));
console.log('OpenCode TUI fix applied: default_builder_enabled = true');
"
```

## 4. Install omo dependencies

```bash
npm i -g @ast-grep/cli
npm i -g @code-yeongyu/comment-checker
```

## 5. Install MCP servers

```bash
claude mcp add --transport http --scope user context7 "https://mcp.context7.com/mcp"
claude mcp add --transport http --scope user exa "https://mcp.exa.ai/mcp?tools=web_search_exa"
claude mcp add --transport http --scope user grep_app "https://mcp.grep.app"
```

## 6. Install my-claude agents

Download each agent file from GitHub raw and save to `~/.claude/agents/`:

```bash
BASE="https://raw.githubusercontent.com/sehoon787/my-claude/main/agents"
for agent in boss sisyphus hephaestus metis atlas oracle momus prometheus librarian multimodal-looker; do
  curl -sL "${BASE}/${agent}.md" -o ~/.claude/agents/${agent}.md
done
```

## 7. Configure hooks and default agent

Fetch hooks.json and merge into settings.json:

```bash
curl -sL "https://raw.githubusercontent.com/sehoon787/my-claude/main/hooks/hooks.json" -o /tmp/my-claude-hooks.json

node -e "
const fs = require('fs');
const path = require('path');
const home = process.env.HOME || process.env.USERPROFILE;
const settingsPath = path.join(home, '.claude', 'settings.json');
let settings = {};
try { settings = JSON.parse(fs.readFileSync(settingsPath, 'utf8')); } catch {}
settings.agent = 'boss';
const hooksData = JSON.parse(fs.readFileSync('/tmp/my-claude-hooks.json', 'utf8'));
settings.hooks = hooksData.hooks;
fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2));
console.log('Default agent: boss | Hooks: ' + Object.keys(settings.hooks).join(', '));
"

rm -f /tmp/my-claude-hooks.json
```

## 8. Install Karpathy coding guidelines

```bash
curl -sL "https://raw.githubusercontent.com/forrestchang/andrej-karpathy-skills/main/CLAUDE.md" >> ~/.claude/CLAUDE.md
```

## 9. Install Everything Claude Code (ECC) rules

```bash
cd /tmp && git clone --depth 1 https://github.com/affaan-m/everything-claude-code.git
cd /tmp/everything-claude-code && bash install.sh typescript
cd ~ && rm -rf /tmp/everything-claude-code
```

## 10. Install Anthropic Official Skills

```bash
cd /tmp && git clone --depth 1 https://github.com/anthropics/skills.git
mkdir -p ~/.claude/skills
cp -r /tmp/skills/skills/* ~/.claude/skills/
rm -rf /tmp/skills
```

## 11. Install Agency Agents

```bash
cd /tmp && git clone --depth 1 https://github.com/msitarzewski/agency-agents.git
cp /tmp/agency-agents/engineering/*.md ~/.claude/agents/
cp /tmp/agency-agents/testing/*.md ~/.claude/agents/
cp /tmp/agency-agents/design/*.md ~/.claude/agents/
cp /tmp/agency-agents/product/*.md ~/.claude/agents/

# Add model field for Boss routing
for f in ~/.claude/agents/{engineering,design,testing,product}-*.md; do
  if [ -f "$f" ] && ! grep -q "^model:" "$f"; then
    sed -i '/^description:/a model: claude-sonnet-4-6' "$f"
  fi
done

rm -rf /tmp/agency-agents
```

## 12. Fix OMC HUD Error

The HUD script imports `oh-my-claudecode` but the npm package is `oh-my-claude-sisyphus`. Add a fallback path to `~/.claude/hud/omc-hud.mjs`:

1. Add these imports at the top of the file (if not already present):
```javascript
import { existsSync } from "node:fs";
import { join } from "node:path";
import { pathToFileURL } from "node:url";
```

2. Find the block containing `oh-my-claudecode/dist/hud/index.js` and add the following immediately after its `catch` block:
```javascript
  // 4b. npm package under oh-my-claude-sisyphus (absolute path)
  const sisyphusPaths = [
    join(process.execPath, "..", "..", "lib", "node_modules",
      "oh-my-claude-sisyphus", "dist", "hud", "index.js"),
    join(process.env.APPDATA || "", "npm", "node_modules",
      "oh-my-claude-sisyphus", "dist", "hud", "index.js"),
  ];
  for (const sp of sisyphusPaths) {
    if (existsSync(sp)) {
      try { await import(pathToFileURL(sp).href); return; } catch { /* continue */ }
    }
  }
```

## 13. Verify

```bash
echo "Agents:  $(ls ~/.claude/agents/*.md | wc -l)"
echo "Skills:  $(ls -d ~/.claude/skills/*/ | wc -l)"
echo "Rules:   $(find ~/.claude/rules -name '*.md' | wc -l)"
node -e "const s=JSON.parse(require('fs').readFileSync((process.env.HOME||process.env.USERPROFILE)+'/.claude/settings.json','utf8')); console.log('Agent:', s.agent, '| Hooks:', Object.keys(s.hooks||{}).join(', '))"
timeout 5 opencode 2>/dev/null; [ $? -ne 134 ] && echo "OpenCode TUI: OK" || echo "OpenCode TUI: CRASH"
```

Expected output:
- Agents: 70+
- Skills: 30+
- Rules: 14
- Agent: boss | Hooks: PreToolUse, SubagentStop, Stop
- OpenCode TUI: OK

Setup complete. Boss orchestrator is ready.
