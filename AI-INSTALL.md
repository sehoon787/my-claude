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

### Updating or reinstalling the plugin

`/plugin marketplace add` clones and caches the marketplace repo locally. Re-running
`/plugin install my-claude@my-claude` alone reinstalls from that **cached** copy — it
does not by itself fetch new commits. If you update or reinstall later (new PC, newer
release, or just picking up recent changes), refresh the cache first:

```bash
# 1. Refresh the cached marketplace repo to the latest commit
/plugin marketplace update my-claude

# 2. Reinstall so the refreshed cache is actually applied
/plugin uninstall my-claude@my-claude
/plugin install my-claude@my-claude
```

If `/plugin marketplace update my-claude` isn't available in your Claude Code version,
remove and re-add the marketplace instead: `/plugin marketplace remove my-claude` then
`/plugin marketplace add sehoon787/my-claude`.

### Two agent sources — why marketplace update alone may not fix a stale model

Agents can reach Claude Code through **two independent paths**, and they update
differently:

1. **Plugin cache** (`~/.claude/plugins/...`) — populated by `/plugin install`, refreshed
   by `/plugin marketplace update`. These agents are namespaced (`my-claude:boss`).
2. **User-level agents** (`~/.claude/agents/*.md`, bare names like `boss`) — written
   **only by `install.sh`** (Step 1b), and mirrored on the daily SessionStart
   auto-update for repo-based installs. `/plugin marketplace update` and
   `/plugin install` **never touch these files.**

The configure step sets the default agent to the bare name `boss`
(`settings.agent = 'boss'`), so when a user-level `~/.claude/agents/boss.md` exists it
**takes precedence over** the plugin's `my-claude:boss`. That means a stale
`~/.claude/agents/boss.md` left over from an earlier `install.sh` run keeps serving the
old model no matter how many times you update the marketplace and reinstall the plugin.

**Troubleshooting: "I just reinstalled but Boss still shows an old model"** (e.g.
`claude-opus-4-6`):

```bash
# 1. Diagnose — check which model the user-level file serves
grep '^model:' ~/.claude/agents/boss.md   # if this shows the OLD model, it is shadowing the plugin

# 2a. Repo-based install (Step 1b / you have the repo cloned): re-run install.sh.
#     It overwrites every user-level agent it owns, including boss.md.
cd <your my-claude repo> && git pull && bash install.sh
#     (Or just start a new Claude Code session — the SessionStart auto-update now
#      refreshes core user-level agents from your local repo once per day.)

# 2b. Pure plugin install (never ran install.sh, no local repo): the stale file is a
#     leftover. Remove it so the plugin's namespaced my-claude:boss takes over, then
#     refresh the marketplace cache.
rm ~/.claude/agents/boss.md
#     followed by:  /plugin marketplace update my-claude
#                   /plugin uninstall my-claude@my-claude
#                   /plugin install my-claude@my-claude

# 3. Re-verify
grep '^model:' ~/.claude/agents/boss.md   # should now show the current model, or be absent (plugin-only)
cat ~/.claude/.my-claude-version
```

A stale marketplace cache (path 1) is only the cause when you have **no** user-level
`~/.claude/agents/boss.md`; if that file exists, path 2 above is the real fix.

This installs:
- 56 core agents in ~/.claude/agents/ (always loaded): Boss, 9 OMO, 19 OMC, 26 engineering
- 136 domain agent-packs in ~/.claude/agent-packs/ (on-demand via symlink)
- 200+ skills (180+ ECC + 36 OMC + 3 Core + 40 gstack)
  Note: gstack skills are installed separately — run Step 1b (`install.sh`) for those.
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

Prerequisites: `bash` (Git Bash or WSL on Windows — this is a bash script, not
PowerShell), `node`/`npm` (v20+), and `git`. `install.sh` checks for these and
exits with an error naming whichever is missing before doing anything else.

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

This installs skills to `~/.agents/skills/` and auto-symlinks to `~/.claude/skills/`. Cross-platform: works with Claude Code, Codex, Cursor, and other tools that support the skills.sh standard. For the full experience (agents, hooks, rules, MCP), complete Step 1 (or 1b) above instead.

Note: `npx skills add` does NOT install gstack. gstack requires Step 1b (`install.sh`) for full installation, including the superseded-skill cleanup and auto-upgrade config.

## Update behavior

Re-running `install.sh` (Step 1b) later, e.g. on a new PC or to pick up a newer release, is safe:
- Only files that `install.sh` itself previously installed are removed and replaced. This is tracked in `~/.claude/.my-claude-manifest`, which records the exact set of paths this script wrote — never a scan of `~/.claude/agents`, `~/.claude/skills`, `~/.claude/rules`, or `~/.claude/hooks`.
- Any file you added yourself directly in those directories (a custom agent, a hand-written skill, a personal rule) is never listed in the manifest and is therefore never touched, on this run or any future one.
- Files that were part of a previous my-claude install but are no longer part of the current one (e.g. an upstream agent was renamed or removed) are deleted as stale.
- If `~/.claude/.my-claude-manifest` does not exist (very first install, or a pre-manifest legacy install), stale-file cleanup is skipped entirely and a warning is printed — nothing is deleted in that case.

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
echo "Boss model:       $(grep '^model:' ~/.claude/agents/boss.md 2>/dev/null || echo 'MISSING')"
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
- Version: matches latest release (compare against the latest GitHub release tag — if it
  doesn't match after a reinstall, see "Updating or reinstalling the plugin" above)
- Boss model: matches the current model in the published `agents/core/boss.md` on GitHub

Setup complete. Boss orchestrator is ready.
