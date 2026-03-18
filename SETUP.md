# Claude Code Multi-Agent Orchestration — Full Setup Guide

Give this document to an AI coding agent to reproduce the exact same environment.

> **Version Note (2025-03):** This guide was last verified in March 2025. External tools evolve rapidly. If a step fails, check the tool's official repository for updated instructions. Key dependencies: oh-my-claudecode (npm), oh-my-opencode (npm), everything-claude-code (GitHub), Context7/Exa MCP endpoints.

> **Section dependencies:** Sections must be followed in order. Section 5 requires Section 3. Section 6 requires Section 4. Section 7 can be done independently. Sections 9-12 are independent of each other but require git.
>
> **Idempotency:** This guide can be re-run safely. `mkdir -p` and `cp` are idempotent. Plugin installs skip if already installed. MCP `add` updates existing entries.
>
> **Cleanup after install:** Sections 9-12 clone repos to `/tmp`. Clean up with: `rm -rf /tmp/andrej-karpathy-skills /tmp/everything-claude-code /tmp/skills /tmp/agency-agents`

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Subscription Assessment](#2-subscription-assessment)
3. [Install OMC (Oh My Claude Code)](#3-install-omc-oh-my-claude-code)
4. [Install omo (Oh My OpenAgent)](#4-install-omo-oh-my-openagent)
5. [Fix OMC HUD Error](#5-fix-omc-hud-error)
6. [Install omo Additional Dependencies](#6-install-omo-additional-dependencies)
7. [Install my-claude Plugin (Sisyphus Orchestration)](#7-install-my-claude-plugin-sisyphus-orchestration)
8. [Model Understanding](#8-model-understanding)
9. [Install Andrej Karpathy Skills](#9-install-andrej-karpathy-skills)
10. [Install Everything Claude Code (ECC)](#10-install-everything-claude-code-ecc)
11. [Install Anthropic Official Skills](#11-install-anthropic-official-skills)
12. [Install Agency Agents](#12-install-agency-agents)
13. [Agent Overlap Analysis (OMC vs omo)](#13-agent-overlap-analysis-omc-vs-omo)
14. [Verification](#14-verification)
15. [Tool Reference](#15-tool-reference)

---

## 1. Prerequisites

### All Platforms

```bash
# Node.js (v20+)
node --version

# npm
npm --version

# Git (required for Sections 9-12)
git --version

# Claude Code CLI (v2.1+, required for plugin and MCP support)
claude --version

# Create required directories (if they don't exist)
mkdir -p ~/.claude/agents ~/.claude/skills ~/.claude/rules
```

### tmux (required by OMC team orchestration)

<details>
<summary>macOS</summary>

```bash
brew install tmux
```
</details>

<details>
<summary>Linux (Ubuntu/Debian)</summary>

```bash
sudo apt install tmux
```
</details>

<details>
<summary>Windows</summary>

tmux does not run natively on Windows. Choose one of these options:

```bash
# Option A: psmux (recommended — native Windows, Claude Code Agent Teams compatible)
winget install marlocarlo.psmux

# Option B: tmux-windows (native ConPTY port of real tmux)
winget install arndawg.tmux-windows

# Option C: Use WSL2 (run everything inside Linux)
wsl --install   # if not already installed
# Then install tmux inside WSL: sudo apt install tmux
```

> **Note:** Without tmux/psmux, OMC's `omc team` command will not work. However, Claude Code's built-in Agent Teams still works in "in-process" mode (all agents in a single terminal, navigate with Shift+Up/Down).

**Windows symlink fix (required for Git Bash):**

By default, `ln -s` in Git Bash creates a **copy** instead of a real symlink. Fix this:

```bash
# Add to ~/.bashrc or ~/.bash_profile
export MSYS=winsymlinks:nativestrict
```

> Requires either: running Git Bash as Administrator, OR enabling Windows Developer Mode (Settings > Update & Security > For developers).

</details>

### OpenCode (optional)

```bash
# Only required if running omo natively in OpenCode
opencode --version
# If not installed: npm i -g @anthropic-ai/opencode
```

> **Note:** OpenCode is only needed if you want to run omo's full agent suite natively in OpenCode. If you only use the standalone Metis/Atlas `.md` files in Claude Code, OpenCode is not required.

---

## 1b. Claude Code Authentication

Claude Code authenticates via browser-based OAuth — no API key needed for Pro/Max subscribers.

```bash
# First run — browser opens automatically for OAuth login
claude

# If browser doesn't open, press 'c' to copy the login URL

# Re-authenticate (from terminal)
claude login

# Check auth status (inside Claude Code session)
/status

# Switch auth method (inside Claude Code session)
/login
```

> **Important:** If the `ANTHROPIC_API_KEY` environment variable is set, Claude Code will use **API pay-as-you-go billing** instead of your subscription. To use your Pro/Max subscription:
> ```bash
> # Ensure this is NOT set
> unset ANTHROPIC_API_KEY
> ```

**Alternative: API key authentication** (for users without a subscription):
```bash
export ANTHROPIC_API_KEY='sk-ant-...'
claude
```

---

## 2. Subscription Assessment

Before installing tools, determine which AI subscriptions are available. This affects installation flags and agent-to-model routing.

### Required

| Subscription | Check | Impact |
|-------------|-------|--------|
| **Claude Pro or Max** | [claude.ai/settings](https://claude.ai/settings) | Core requirement. Determines `--claude=yes` (Pro) or `--claude=max20` (Max with 20x usage). Without Claude access, the Sisyphus orchestrator and most agents will not perform optimally. |

### Optional (for omo multi-model routing via OpenCode)

| Subscription | Flag | Impact |
|-------------|------|--------|
| **OpenAI / ChatGPT Plus** | `--openai=yes` | Enables GPT-5.4 for Oracle agent (deep consulting) |
| **Google Gemini** | `--gemini=yes` | Adds Gemini models for vision/multimodal tasks |
| **GitHub Copilot** | `--copilot=yes` | Acts as fallback provider |

> **For Claude Code-only users:** You only need a Claude Pro or Max subscription. The optional providers are only relevant if you also use OpenCode with omo's native multi-model routing.

### Determine your omo install flags

```bash
# Claude Pro subscriber:
--claude=yes --openai=no --gemini=no --copilot=no

# Claude Max subscriber:
--claude=max20 --openai=no --gemini=no --copilot=no

# Full multi-model (OpenCode + omo):
--claude=max20 --openai=yes --gemini=yes --copilot=yes
```

---

## 3. Install OMC (Oh My Claude Code)

Native multi-agent orchestration plugin for Claude Code.

### Option A: Claude Code plugin (recommended)

```bash
# Inside a Claude Code session:
/plugin marketplace add https://github.com/Yeachan-Heo/oh-my-claudecode
/plugin install oh-my-claudecode
```

### Option B: npm CLI

```bash
# Install CLI
# Tested with v1.x — check https://www.npmjs.com/package/oh-my-claudecode for latest
npm i -g oh-my-claude-sisyphus@latest

# Run setup (installs 18 agents + HUD + CLAUDE.md configuration)
omc setup

# Verify
omc --version
omc doctor conflicts
```

> **Troubleshooting:** If `npm i -g` fails with EACCES, try `npm i -g --prefix ~/.local oh-my-claude-sisyphus@latest` or use Option A instead. If `omc` is not found after install, check `npm root -g` and ensure the global bin directory is in your PATH.

**What gets installed:**
- `~/.claude/agents/` — 18 agent definition files (.md)
- `~/.claude/CLAUDE.md` — OMC orchestration directives injected (existing content preserved)
- `~/.claude/hud/omc-hud.mjs` — HUD statusline script
- `~/.claude/.omc-config.json` — Node binary path
- `~/.claude/.omc-version.json` — Version metadata

---

## 4. Install omo (Oh My OpenAgent)

Multi-platform agent harness with Claude Code ecosystem bridge.

> **Naming:** The project was renamed to **oh-my-openagent** (GitHub: [code-yeongyu/oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent)). The npm package name remains `oh-my-opencode` for backward compatibility.

```bash
# Global install (npm package is still oh-my-opencode)
# Tested with v0.x — check https://www.npmjs.com/package/oh-my-opencode for latest
npm i -g oh-my-opencode@latest

# Non-interactive install (use flags from Section 2)
oh-my-opencode install --no-tui --claude=yes --openai=no --gemini=no --copilot=no

# Update plugin in OpenCode cache (ONLY if OpenCode was previously installed and run)
# Skip this if ~/.cache/opencode/ does not exist
[ -d ~/.cache/opencode ] && cd ~/.cache/opencode && npm add oh-my-opencode@latest && cd ~

# Verify
oh-my-opencode --version
oh-my-opencode doctor
```

**What gets installed:**
- `~/.config/opencode/opencode.json` — Plugin registration
- `~/.config/opencode/oh-my-opencode.json` — Agent-to-model mapping

**Claude Code bridge:** omo includes a `claude-code-agent-loader` that reads `~/.claude/agents/*.md` files and a `claude-code-plugin-loader` that loads Claude Code plugins. This means when running in OpenCode with omo, you get access to both omo's native agents AND Claude Code ecosystem agents/plugins. The bridge direction is **omo consuming Claude Code ecosystem**, not the reverse.

**11 built-in agents:** Sisyphus (orchestrator), Sisyphus-Junior (lightweight orchestrator), Prometheus (planning), Metis (intent analysis), Momus (review), Oracle (consulting), Atlas (task management), Hephaestus (autonomous execution), Librarian (doc search), Explore (navigation), Multimodal-Looker (visual analysis)

### 4a. Fix OpenCode TUI crash

oh-my-opencode hides OpenCode's default `build` agent when Sisyphus is enabled, causing the TUI to crash with `TypeError: agents()[0].name`. To fix this, enable the fallback builder agent:

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

---

## 5. Fix OMC HUD Error

`omc setup` installs the npm package as `oh-my-claude-sisyphus`, but the HUD script tries to import `oh-my-claudecode`. Under nvm, global module resolution fails.

**Prerequisite:** Section 3 (OMC install) must be completed first. The file `~/.claude/hud/omc-hud.mjs` is created by `omc setup`.

**Fix:** Add an absolute-path fallback to `~/.claude/hud/omc-hud.mjs`.

Ensure these imports exist at the top of the file (add if missing):
```javascript
import { existsSync } from "node:fs";
import { join } from "node:path";
import { pathToFileURL } from "node:url";
```

Find this block (search for `oh-my-claudecode/dist/hud`):

```javascript
  // 4. npm package (global or local install)
  try {
    await import("oh-my-claudecode/dist/hud/index.js");
    return;
  } catch { /* continue */ }
```

Add the following immediately after:

```javascript
  // 4b. npm package under oh-my-claude-sisyphus (absolute path for nvm/Windows compatibility)
  const sisyphusPaths = [
    // Unix: /usr/local/lib/node_modules or nvm path
    join(process.execPath, "..", "..", "lib", "node_modules",
      "oh-my-claude-sisyphus", "dist", "hud", "index.js"),
    // Windows: %APPDATA%\npm\node_modules
    join(process.env.APPDATA || "", "npm", "node_modules",
      "oh-my-claude-sisyphus", "dist", "hud", "index.js"),
  ];
  for (const sp of sisyphusPaths) {
    if (existsSync(sp)) {
      try {
        await import(pathToFileURL(sp).href);
        return;
      } catch { /* continue */ }
    }
  }
```

**Verify:**

```bash
node ~/.claude/hud/omc-hud.mjs
# Expected: "[OMC] run /omc-setup to install properly" (this is normal)
# Error:    "[OMC HUD] Plugin not installed..." (this means the fix didn't work)
```

---

## 6. Install omo Additional Dependencies

Resolve all warnings from `oh-my-opencode doctor`.

```bash
# AST-Grep (structural code search/replace)
npm i -g @ast-grep/cli

# Comment Checker (comment quality hook)
npm i -g @code-yeongyu/comment-checker

# Symlink comment-checker binary (npm may not create the bin link)
# NOTE (Windows): Ensure MSYS=winsymlinks:nativestrict is set (see Section 1)
NODE_BIN=$(dirname $(which node))
NODE_LIB=$(dirname $NODE_BIN)/lib
if [ ! -f "$NODE_BIN/comment-checker" ] && [ -f "$NODE_LIB/node_modules/@code-yeongyu/comment-checker/bin/comment-checker" ]; then
  ln -s "$NODE_LIB/node_modules/@code-yeongyu/comment-checker/bin/comment-checker" "$NODE_BIN/comment-checker"
fi

# Windows: If comment-checker binary is missing after install, run postinstall manually:
# cd "$(npm root -g)/@code-yeongyu/comment-checker" && node postinstall.js
# If postinstall still fails, download manually from:
# https://github.com/code-yeongyu/go-claude-code-comment-checker/releases
# and copy comment-checker.exe to your npm global bin directory (npm prefix -g)

# Verify
oh-my-opencode doctor
# Expected: "✓ System OK"
```

---

## 6b. Install MCP Servers (Required for Librarian Agent)

Three MCP servers replicate the tool integrations that omo agents use internally. These are required for the Librarian agent and useful for all agents.

### Overview

| MCP Server | Purpose | Cost | API Key |
|-----------|---------|------|---------|
| **Context7** | Library documentation lookup | Free (key for higher rate limits) | Optional |
| **Exa** | Semantic web search | Free 1k req/mo, then $7/1k | Optional (recommended) |
| **grep.app** | Search across public GitHub repos | Free | Not needed |

### Install via CLI (recommended)

**Pre-check (optional):** Verify MCP endpoints are reachable from your network:

```bash
# All should return HTTP 405 (expected — MCP uses SSE, not GET)
curl -s -o /dev/null -w "%{http_code}" https://mcp.context7.com/mcp
curl -s -o /dev/null -w "%{http_code}" https://mcp.exa.ai/mcp
curl -s -o /dev/null -w "%{http_code}" https://mcp.grep.app
# If you get "connection refused" or timeout, check your network/proxy settings
```

```bash
# Note: MCP endpoints are remote services. If connection fails, check the provider's documentation.
claude mcp add --transport http --scope user context7 "https://mcp.context7.com/mcp"
claude mcp add --transport http --scope user exa "https://mcp.exa.ai/mcp?tools=web_search_exa"
claude mcp add --transport http --scope user grep_app "https://mcp.grep.app"
```

### Or add to `~/.claude/mcp.json` manually

```json
{
  "mcpServers": {
    "context7": {
      "type": "url",
      "url": "https://mcp.context7.com/mcp"
    },
    "exa": {
      "type": "url",
      "url": "https://mcp.exa.ai/mcp?tools=web_search_exa"
    },
    "grep_app": {
      "type": "url",
      "url": "https://mcp.grep.app"
    }
  }
}
```

### Optional: API Keys for Higher Limits

<details>
<summary>Context7 API Key</summary>

Get a free key from [context7.com/dashboard](https://context7.com/dashboard) for higher rate limits.

```json
"context7": {
  "type": "url",
  "url": "https://mcp.context7.com/mcp",
  "headers": {
    "Authorization": "Bearer YOUR_CONTEXT7_API_KEY"
  }
}
```
</details>

<details>
<summary>Exa API Key</summary>

Get a free key (1k requests/month) from [dashboard.exa.ai](https://dashboard.exa.ai). No credit card required.

```json
"exa": {
  "type": "url",
  "url": "https://mcp.exa.ai/mcp?tools=web_search_exa",
  "headers": {
    "x-api-key": "YOUR_EXA_API_KEY"
  }
}
```
</details>

### Verify

```bash
# Inside a Claude Code session, check MCP status
/mcp
# All three servers should show as connected
```

---

## 7. Install my-claude Plugin (Sisyphus Orchestration)

This repo is a **Claude Code plugin** that provides 9 omo agents, behavioral correction hooks, and MCP server configuration.

### Option A: Plugin install from GitHub (recommended)

> **Note:** This requires the repository to be **public**. If the repo is private, use Option B or Option C.

```bash
# Inside a Claude Code session:
/plugin marketplace add sehoon787/my-claude
/plugin install my-claude-orchestration@my-claude
```

**Verify:**
```bash
# Inside a Claude Code session:
/plugin list
# Expected: my-claude-orchestration@my-claude — Status: ✔ enabled
```

**What gets installed:**
- 9 agents (Sisyphus, Hephaestus, Metis, Atlas, Oracle, Momus, Prometheus, Librarian, Multimodal-Looker)
- 3 behavioral correction hooks (delegation guard, subagent verification, completion check)
- 3 MCP servers (Context7, Exa, grep.app)
- Default agent: Sisyphus (main orchestrator)

### Option B: Local plugin install (for private repos or local clones)

```bash
# Clone the repo (if not already cloned)
git clone https://github.com/sehoon787/my-claude.git ~/my-claude

# Inside a Claude Code session, register as local marketplace:
/plugin marketplace add ~/my-claude
/plugin install my-claude-orchestration@my-claude
```

**Verify:**
```bash
# Inside a Claude Code session:
/plugin list
# Expected: my-claude-orchestration@my-claude — Status: ✔ enabled
```

### Option C: Manual install (copy files individually)

```bash
# Ensure directories exist
mkdir -p ~/.claude/agents

# Agents
cp agents/*.md ~/.claude/agents/

# MCP servers (if not already installed via Section 6b)
claude mcp add --transport http --scope user context7 "https://mcp.context7.com/mcp"
claude mcp add --transport http --scope user exa "https://mcp.exa.ai/mcp?tools=web_search_exa"
claude mcp add --transport http --scope user grep_app "https://mcp.grep.app"
```

> **Note:** Options A and B (plugin install) automatically configure hooks and default agent. If using Option C (manual copy), add hooks and default agent manually with Option D below.

### Option D: Manual hooks and default agent setup

If you used Option C (manual copy), apply the behavioral correction hooks and set Sisyphus as default agent by merging into `~/.claude/settings.json`:

```bash
# Read current settings and merge hooks + default agent
node -e "
const fs = require('fs');
const path = require('path');
const settingsPath = path.join(process.env.HOME || process.env.USERPROFILE, '.claude', 'settings.json');
const settings = JSON.parse(fs.readFileSync(settingsPath, 'utf8'));
settings.agent = 'sisyphus';
settings.hooks = {
  PreToolUse: [{
    matcher: 'Edit|Write',
    hooks: [{
      type: 'command',
      command: 'node -e \"const j=JSON.parse(require(\\\"fs\\\").readFileSync(0,\\\"utf8\\\"));if(!j.agent_id){console.log(JSON.stringify({hookSpecificOutput:{hookEventName:\\\"PreToolUse\\\",additionalContext:\\\"SISYPHUS PROTOCOL: You are the orchestrator. Delegate file modifications to specialist subagents (model=sonnet for implementation, model=haiku for trivial fixes). Direct edits are acceptable ONLY for 1-line trivial changes or plan/draft markdown files.\\\"}}))}\"',
      timeout: 5000
    }]
  }],
  SubagentStop: [{
    hooks: [{
      type: 'command',
      command: 'node -e \"console.log(JSON.stringify({hookSpecificOutput:{additionalContext:\\\"VERIFICATION REQUIRED: Subagent finished. Before proceeding: (1) Read the changed files yourself, (2) Run lsp_diagnostics or tests to verify, (3) Only then mark the task complete. Do NOT trust subagent claims without independent verification.\\\"}}))}\"'
    }]
  }],
  Stop: [{
    hooks: [{
      type: 'prompt',
      prompt: 'Review the assistant last message. Check: (1) Are there incomplete tasks in the current plan? (2) Were all subagent results independently verified? (3) Did the assistant skip any verification steps? If work remains incomplete or unverified, return {\"ok\": false, \"reason\": \"Incomplete work detected. Continue with remaining tasks or verify pending results.\"}. If all tasks are complete and verified, return {\"ok\": true}.'
    }]
  }]
};
fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2));
console.log('Hooks and default agent configured.');
"
```

**Verify:**
```bash
node -e "const s=JSON.parse(require('fs').readFileSync((process.env.HOME||process.env.USERPROFILE)+'/.claude/settings.json','utf8')); console.log('agent:', s.agent, '| hooks:', Object.keys(s.hooks||{}).join(', '))"
# Expected: agent: sisyphus | hooks: PreToolUse, SubagentStop, Stop
```

> **What the hooks do:**
> - **PreToolUse (Edit|Write):** Reminds Sisyphus to delegate file modifications to subagents
> - **SubagentStop:** Injects verification reminder after subagent completion
> - **Stop:** Checks all tasks are complete and verified before ending session
>
> **To disable hooks later:** Remove the `hooks` key from `~/.claude/settings.json`.
> **To change default agent:** Change `"agent": "sisyphus"` to any other agent name, or remove the key to use no default.

### Option C: Native omo agents (via OpenCode)

If you use OpenCode with omo, all 11 agents are built-in — no porting needed. omo also loads any `.md` agents from `~/.claude/agents/` via its Claude Code bridge.

### Using Sisyphus (Main Orchestrator)

After plugin install, Sisyphus is the default agent. Usage:

```bash
# Inside a Claude Code session, invoke agents directly:
# - Type your request and Sisyphus orchestrates automatically (if set as default agent)
# - Or invoke specific agents via the /agents menu

# To use Hephaestus for autonomous deep work:
# Inside a Claude Code session, select Hephaestus from /agents or mention it in your prompt
```

> **Note:** After plugin install (Options A/B) or manual setup (Option D), Sisyphus is the default agent. You can invoke any agent explicitly from the `/agents` list inside a Claude Code session, or change the default in `~/.claude/settings.json`.

### Plugin Auto-Update

When the my-claude repository is updated, the plugin version is automatically bumped via GitHub Actions (`auto-tag.yml`). To receive updates:

```bash
# Inside a Claude Code session:
/plugin marketplace update my-claude        # Fetch latest from GitHub
/plugin update my-claude-orchestration      # Update the plugin

# If update doesn't apply (known cache issue):
# Delete plugin cache and reinstall
rm -rf ~/.claude/plugins/cache/my-claude
/plugin install my-claude-orchestration@my-claude
```

> **How versioning works:** Commits with `feat:` prefix trigger minor version bumps, `fix:`/`perf:`/`refactor:` trigger patch bumps. The `plugin.json` version is automatically synced with git tags by GitHub Actions.

### Agent Catalog (9 Ported Agents)

| Agent | Model | Role | Type |
|-------|-------|------|------|
| **Sisyphus** | Opus | Master orchestrator — intent classification, delegation, verification | Main agent |
| **Hephaestus** | Opus | Autonomous deep worker — explores, implements, verifies without asking | Main agent |
| **Metis** | Opus | Intent analysis + ambiguity detection + AI-slop prevention | Subagent |
| **Atlas** | Opus | Task orchestration + delegation + 4-phase QA verification | Subagent |
| **Oracle** | Opus | Strategic advisor — architecture, hard debugging, deep consulting | Subagent |
| **Momus** | Opus | Plan reviewer — blocker-finding, executability verification | Subagent |
| **Prometheus** | Opus | Planning consultant — interview-driven plan generation | Subagent |
| **Librarian** | Sonnet | Open-source codebase understanding + documentation lookup | Subagent |
| **Multimodal-Looker** | Sonnet | Visual analysis — images, PDFs, diagrams, screenshots | Subagent |

### Behavioral Correction Hooks

The plugin includes 3 hooks that replicate omo's runtime behavioral correction:

| Hook | Event | What It Does |
|------|-------|-------------|
| **Delegation Guard** | `PreToolUse` on Edit/Write | Reminds Sisyphus to delegate file modifications to subagents instead of editing directly |
| **Subagent Verifier** | `SubagentStop` | Injects verification reminder after subagent completion — read files, run tests |
| **Completion Check** | `Stop` | Evaluates whether all tasks are complete and verified before allowing the session to end |

### Sisyphus (Master Orchestrator)

**Role:** Conducts the entire workflow — classifies intent, delegates to specialist agents with model-optimized routing (Opus/Sonnet/Haiku), verifies all results independently. Never writes application code.

**Key capabilities:**
- Phase 0: Intent Gate (verbalize → classify → validate) — mandatory before any action
- Phase 1: Parallel research (Explore + Librarian in background), then planning (Metis → Prometheus → Momus)
- Phase 2: Wave-based execution with Agent tool model routing and parallel background agents
- Phase 2B: 4-step verification after every delegation (read files, run tests, cross-reference plan, check side effects)
- Anti-duplication enforcement, AI-slop detection, 3-attempt failure recovery
- Behavioral correction hooks prevent direct file editing and enforce verification

### Hephaestus (Autonomous Deep Worker)

**Role:** Senior staff engineer that takes a task and completes it fully without asking permission. Explores, plans, executes, and verifies autonomously.

**Key capabilities:**
- "Do NOT Ask — Just Do" principle — acts on intent, not literal instructions
- EXPLORE → PLAN → DECIDE → EXECUTE → VERIFY loop
- Surgical changes with existing style matching
- 3-tier failure recovery (retry → alternative approach → deep analysis)
- Completion guarantee with self-check before reporting done

### Metis (Intent Analyst)

**Role:** Classifies user intent before planning, detects ambiguity, and prevents AI-slop (over-engineering, scope creep). Outputs MUST/MUST NOT directives for the planner agent.

**Key capabilities:**
- Phase 0: Intent classification (Refactoring / Build / Mid-sized / Collaborative / Architecture / Research)
- Phase 1: Intent-specific analysis with required questions and planner directives
- AI-slop detection (scope inflation, premature abstraction, over-validation, doc bloat)
- Agent-executable acceptance criteria (no manual testing)

### Atlas (Task Orchestrator)

**Role:** Delegates all tasks in a work plan to specialist agents, verifies each result with 4-phase QA, and tracks everything to completion. Never writes code directly.

**Key capabilities:**
- 6-section delegation prompts (TASK, EXPECTED OUTCOME, REQUIRED TOOLS, MUST DO, MUST NOT DO, CONTEXT)
- 4-Phase QA (automated checks → manual code review → hands-on testing → state check)
- Parallel execution for independent tasks, sequential for dependent ones
- Session resume on failure (max 3 retries)
- Final Verification Wave (code-reviewer + verifier)

### Oracle (Strategic Advisor)

**Role:** On-demand specialist for architecture decisions, hard debugging (after 2+ failed attempts), and strategic technical questions. Read-only — advises but never implements.

**Key capabilities:**
- Pragmatic minimalism framework (bias toward simplicity, leverage what exists)
- Structured output: Bottom line → Action plan → Effort estimate
- Effort tagging: Quick(<1h), Short(1-4h), Medium(1-2d), Large(3d+)
- Scope discipline — recommends ONLY what was asked, no unsolicited improvements

### Momus (Plan Reviewer)

**Role:** Practical reviewer that verifies work plans are executable. Approves by default — rejects only for true blocking issues. Read-only.

**Key capabilities:**
- Reference verification (do cited files/lines actually exist?)
- Executability check (can a developer START each task?)
- QA scenario validation (are scenarios agent-executable?)
- Approval bias — max 3 blocking issues per rejection, no perfectionism

### Prometheus (Planning Consultant)

**Role:** Strategic planner that creates detailed, executable work plans through structured interviews. Writes ONLY markdown plan files. Works with Metis (pre-analysis) and Momus (plan review).

**Key capabilities:**
- 3-phase workflow: Interview → Plan Generation → Optional Review
- Intent classification into 7 types (Trivial through Research)
- Autonomous research before asking questions (reads codebase, git history)
- Self-clearance checklist to decide when enough context is gathered
- Plan template with parallel execution waves and QA scenarios
- Optional Momus review loop for high accuracy

### Librarian (Documentation Researcher)

**Role:** Specialized researcher for open-source libraries. Finds documentation and source code with GitHub permalink evidence. Read-only.

**Key capabilities:**
- 4 request types: Conceptual, Implementation, Context, Comprehensive
- Documentation Discovery via Context7 MCP + web search
- GitHub code search via grep.app MCP
- Mandatory permalink citations for every claim
- Parallel tool execution for speed

**Requires:** Context7, Exa, grep.app MCP servers ([Section 6b](#6b-install-mcp-servers-required-for-librarian-agent))

### Multimodal-Looker (Visual Analyst)

**Role:** Interprets media files that cannot be read as plain text — images, PDFs, diagrams, screenshots. Read-only.

**Key capabilities:**
- PDF text/table/structure extraction
- Image layout, UI element, and text description
- Diagram relationship and flow explanation
- Context-efficient — main agent never processes raw media files

---

## 8. Model Understanding

Different model families respond optimally to different prompt styles. This affects how agents are designed and which model they should target.

### Claude Family (Opus, Sonnet, Haiku)

| Trait | Description |
|-------|-------------|
| **Prompt style** | Detailed, mechanical instructions with explicit structure |
| **Strengths** | Long-context reasoning, following complex multi-step instructions, code generation with nuance |
| **Best for** | Orchestration (Sisyphus), intent analysis (Metis), planning (Prometheus), code review (Momus) |
| **Key behavior** | Responds well to XML-structured prompts, MUST/MUST NOT constraints, and explicit phase-based workflows |

### GPT Family (GPT-5.4, GPT-5.3-Codex)

| Trait | Description |
|-------|-------------|
| **Prompt style** | Principle-driven, concise instructions |
| **Strengths** | Fast iteration, code execution (Codex), broad knowledge |
| **Best for** | Consulting (Oracle with GPT-5.4), autonomous execution (Hephaestus with GPT-5.3-Codex) |
| **Key behavior** | Performs better with shorter, goal-oriented prompts rather than exhaustive rule lists |

### Default Agent-to-Model Assignments

| Agent | Recommended Model | Reason |
|-------|------------------|--------|
| Metis | Claude Opus | Complex intent classification requires deep reasoning |
| Atlas | Claude Opus | Orchestration demands precise instruction following |
| Planner (OMC) | Claude Sonnet | Fast planning with good code understanding |
| Oracle | Claude Opus / GPT-5.4 | Deep consulting benefits from strongest available model |
| Hephaestus | GPT-5.3-Codex | Autonomous code execution (omo/OpenCode only) |
| Explore | Claude Haiku / Sonnet | Speed-critical; simple search tasks |
| Other OMC agents | Claude Sonnet | Good balance of speed and capability |

> **Important:** Do not override default model assignments without explicit need. The system is optimized for these defaults. In Claude Code, the `model` field in agent `.md` frontmatter controls which model runs the agent.

---

## 9. Install Andrej Karpathy Skills

Four behavioral principles that reduce common LLM coding mistakes.

```bash
# Option A: Claude Code plugin (recommended)
# Inside a Claude Code session:
#   /plugin marketplace add forrestchang/andrej-karpathy-skills
#   /plugin install andrej-karpathy-skills@karpathy-skills

# Option B: Manual (append to CLAUDE.md)
cd /tmp && git clone --depth 1 https://github.com/forrestchang/andrej-karpathy-skills.git  # Clones latest; for reproducibility, pin to a specific commit if needed
cat /tmp/andrej-karpathy-skills/CLAUDE.md >> ~/.claude/CLAUDE.md
```

> **Note:** `omc setup` may overwrite CLAUDE.md. Always add custom content below the OMC marker (`<!-- OMC:END -->`).

---

## 10. Install Everything Claude Code (ECC)

Comprehensive framework with 67+ skills, 17 agents, 45 commands, and language-specific rules.

```bash
# Option A: Claude Code plugin (recommended)
# Inside a Claude Code session:
#   /plugin marketplace add affaan-m/everything-claude-code
#   /plugin install everything-claude-code@everything-claude-code

# Option B: Manual (rules only)
cd /tmp && git clone --depth 1 https://github.com/affaan-m/everything-claude-code.git  # Clones latest; for reproducibility, pin to a specific commit if needed
cd /tmp/everything-claude-code

# For TypeScript projects:
bash install.sh typescript

# For Python projects:
# bash install.sh python

# For Go projects:
# bash install.sh golang

# Return to home directory after install
cd ~
```

**What gets installed:**
- `~/.claude/rules/common/` — 9 common rules (coding style, security, testing, etc.)
- `~/.claude/rules/<language>/` — 5 language-specific rules

---

## 11. Install Anthropic Official Skills

Anthropic's official agent skills repository. 17 skills including document manipulation, design, and dev tools.

```bash
# Option A: Claude Code plugin (recommended)
# Inside a Claude Code session:
#   /plugin marketplace add anthropics/skills
#   /plugin install document-skills@anthropic-agent-skills
#   /plugin install example-skills@anthropic-agent-skills

# Option B: Manual (copy skill folders)
cd /tmp && git clone --depth 1 https://github.com/anthropics/skills.git  # Clones latest; for reproducibility, pin to a specific commit if needed
mkdir -p ~/.claude/skills
cp -r /tmp/skills/skills/* ~/.claude/skills/
```

**Skills installed (17):**
algorithmic-art, brand-guidelines, canvas-design, claude-api, doc-coauthoring, docx, frontend-design, internal-comms, mcp-builder, pdf, pptx, skill-creator, slack-gif-creator, theme-factory, web-artifacts-builder, webapp-testing, xlsx

---

## 12. Install Agency Agents

164 business-specialist agent personas across departments.

```bash
cd /tmp && git clone --depth 1 https://github.com/msitarzewski/agency-agents.git  # Clones latest; for reproducibility, pin to a specific commit if needed

# Ensure directory exists
mkdir -p ~/.claude/agents

# Core departments only (recommended — avoids agent overload)
cp /tmp/agency-agents/engineering/*.md ~/.claude/agents/
cp /tmp/agency-agents/testing/*.md ~/.claude/agents/
cp /tmp/agency-agents/design/*.md ~/.claude/agents/
cp /tmp/agency-agents/product/*.md ~/.claude/agents/

# Add model field to all Agency agents (required for Boss routing)
for f in ~/.claude/agents/{engineering,design,testing,product}-*.md; do
  if ! grep -q "^model:" "$f"; then
    sed -i '/^description:/a model: claude-sonnet-4-6' "$f"
  fi
done

# Full install (all 164 agents)
# cp -r /tmp/agency-agents/{engineering,testing,design,product,marketing,sales,project-management,spatial-computing,game-development,specialized,support,strategy,paid-media}/*.md ~/.claude/agents/
```

> **Warning:** Too many agents can cause Claude Code to struggle with selection. Install only the departments you actually need.

---

## 13. Agent Overlap Analysis (OMC vs omo)

OMC has 18 agents and omo has 11 agents. 7 pairs overlap in function — **both are kept** for situational selection.

### Overlapping Agent Pairs

| Function | OMC Agent | omo Agent | When to use which |
|----------|-----------|-----------|-------------------|
| Orchestration | — (CLAUDE.md rules) | Sisyphus | OMC: via magic keywords in Claude Code. omo: full orchestrator in OpenCode |
| Planning | planner | Prometheus | Quick tasks: OMC planner. Complex projects: omo Planning Triad (Metis→Prometheus→Momus) |
| Intent Analysis | — | Metis | Standalone .md in Claude Code OR native in OpenCode |
| Code Review | code-reviewer | Momus | OMC: focused code review. omo Momus: broader review with anti-slop detection |
| Task Management | — | Atlas | Standalone .md in Claude Code OR native in OpenCode |
| Exploration | explore | Explore | Both serve similar roles; use whichever platform you're in |
| Security | security-reviewer | — (via Momus) | OMC: dedicated security review. omo: security is part of Momus review |

### omo-Unique Agents (not in OMC)

| Agent | Role |
|-------|------|
| **Sisyphus** | Master orchestrator — coordinates all omo agents, manages state |
| **Sisyphus-Junior** | Lightweight orchestrator for simpler tasks |
| **Hephaestus** | Autonomous execution — runs code independently with tmux |
| **Oracle** | Consulting — deep reasoning for complex technical questions |
| **Multimodal-Looker** | Visual analysis — screenshots, diagrams, UI inspection |
| **Librarian** | Documentation search and knowledge retrieval |

### OMC-Unique Agents (not in omo)

| Agent | Role |
|-------|------|
| **analyst** | Pre-analysis before planning |
| **architect** | System design and architecture decisions |
| **code-simplifier** | Code simplification and cleanup |
| **critic** | Critical analysis and alternative perspectives |
| **debugger** | Focused debugging agent |
| **designer** | UI/UX design guidance |
| **document-specialist** | Documentation creation and management |
| **executor** | Task execution agent |
| **git-master** | Git workflow management |
| **qa-tester** | Quality assurance testing |
| **scientist** | Research and experimentation |
| **test-engineer** | Test writing and maintenance |
| **verifier** | Final verification of completed work |
| **writer** | Content and documentation writing |

### Complementary Pairs (use together)

| OMC Agent | omo Agent | How they complement |
|-----------|-----------|-------------------|
| analyst | Metis | analyst does broad pre-analysis; Metis does intent classification with AI-slop detection |
| document-specialist | Librarian | document-specialist creates docs; Librarian searches and retrieves existing docs |

### Planning Strategy

- **Quick tasks:** Use OMC `planner` directly
- **Complex projects:** Use omo Planning Triad: `Metis` (intent analysis) → `Prometheus` (detailed planning) → `Momus` (plan review)
- **In Claude Code:** Use standalone `Metis` → `Prometheus` → `Momus` (review) → `Atlas` (orchestration). All 7 agents are available as standalone `.md` files.

---

## 14. Verification

### All Platforms

```bash
# OMC
omc --version                    # 4.8.0+
omc doctor conflicts             # "No conflicts detected"

# omo
oh-my-opencode --version         # 3.11.0+
oh-my-opencode doctor            # "✓ System OK"

# HUD
node ~/.claude/hud/omc-hud.mjs   # "[OMC] run /omc-setup..." (not an error)

# Agents
ls ~/.claude/agents/ | wc -l     # 70+ (OMC 19 + omo 9 + Agency 42+)

# Skills
ls ~/.claude/skills/             # 30+ directories

# Rules
ls ~/.claude/rules/              # common/ + language directories

# Hooks (if plugin installed)
cat ~/.claude/settings.json | grep -c "hooks"  # Should show hook entries

# OpenCode (optional)
opencode --version               # 1.2.17+ (only if using omo natively)
```

### Plugin Status

```bash
# Check all plugins are loaded
claude plugin list
# Expected: my-claude-orchestration@my-claude — Status: ✔ enabled
```

### Platform-Specific Checks

<details>
<summary>macOS / Linux</summary>

```bash
tmux -V                          # 3.x+
```
</details>

<details>
<summary>Windows</summary>

```bash
# tmux alternative (one of these)
psmux --version                  # psmux installed via winget
tmux -V                          # tmux-windows installed via winget

# Symlink support
echo $MSYS                       # Should include "winsymlinks:nativestrict"

# If using WSL2
wsl --status                     # Verify WSL is running
```
</details>

---

## 15. Tool Reference

### OMC (Oh My Claude Code)

| | |
|---|---|
| **Purpose** | Native multi-agent orchestration for Claude Code |
| **Core** | 18 specialized agents + HUD statusline + magic keywords |
| **How it works** | Injects orchestration rules into CLAUDE.md, defines agents in `~/.claude/agents/` |
| **Key features** | `autopilot:` (auto-execution), `ulw` (max parallelization), `/team N:executor "task"` (team orchestration), real-time HUD monitoring |
| **Agents (18)** | analyst, architect, code-reviewer, code-simplifier, critic, debugger, designer, document-specialist, executor, explore, git-master, planner, qa-tester, scientist, security-reviewer, test-engineer, verifier, writer |
| **When to use** | Complex multi-step tasks in Claude Code sessions |

### omo (Oh My OpenAgent)

| | |
|---|---|
| **Purpose** | Multi-platform agent harness with Claude Code ecosystem bridge |
| **GitHub** | [code-yeongyu/oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent) |
| **npm** | `oh-my-opencode` (legacy name retained for compatibility) |
| **Core** | Sisyphus orchestrator + multi-model routing across 8 providers |
| **How it works** | Runs as an OpenCode plugin. Includes `claude-code-agent-loader` (reads `~/.claude/agents/*.md`) and `claude-code-plugin-loader` (loads CC plugins) — bridging the Claude Code ecosystem into OpenCode |
| **Key features** | `ultrawork` (activate all agents), `/start-work` (interview mode), `/init-deep` (generate AGENTS.md) |
| **Agents (11)** | Sisyphus (orchestrator), Sisyphus-Junior (lite orchestrator), Prometheus (planning), Metis (intent analysis), Momus (review), Oracle (consulting), Atlas (task mgmt), Hephaestus (autonomous execution), Librarian (doc search), Explore (navigation), Multimodal-Looker (visual analysis) |
| **When to use** | Multi-model orchestration via OpenCode; also when you need omo-unique agents (Sisyphus, Hephaestus, Oracle, Multimodal-Looker) |

### omo Standalone Agents (9 ported to Claude Code)

| Agent | Purpose | Model | Key Capability |
|-------|---------|-------|----------------|
| **Sisyphus** | Master orchestration | Opus | Intent gate + model-routed delegation + verification hooks |
| **Hephaestus** | Autonomous deep work | Opus | "Don't ask, just do" + EXPLORE→PLAN→EXECUTE→VERIFY loop |
| **Metis** | Pre-planning intent analysis | Opus | Intent classification + AI-slop prevention |
| **Atlas** | Task orchestration | Opus | 6-section delegation + 4-phase QA |
| **Oracle** | Strategic consulting | Opus | Architecture decisions + hard debugging |
| **Momus** | Plan review | Opus | Blocker-finding + executability verification |
| **Prometheus** | Planning | Opus | Interview-driven plan generation |
| **Librarian** | Documentation research | Sonnet | Library docs + GitHub permalink evidence |
| **Multimodal-Looker** | Visual analysis | Sonnet | Image/PDF/diagram interpretation |

**Availability:** All 9 available as standalone `.md` in Claude Code (`~/.claude/agents/`) AND natively in omo (OpenCode). Plugin install includes behavioral correction hooks for Sisyphus.

**Not ported (require omo runtime):** Sisyphus-Junior (lightweight variant — use Sisyphus with `model: "sonnet"` instead), Explore (redundant — Claude Code built-in).

### MCP Servers (required for Librarian, useful for all agents)

| Server | Purpose | URL | Cost |
|--------|---------|-----|------|
| **Context7** | Library documentation | `https://mcp.context7.com/mcp` | Free |
| **Exa** | Semantic web search | `https://mcp.exa.ai/mcp?tools=web_search_exa` | Free 1k/mo |
| **grep.app** | GitHub code search | `https://mcp.grep.app` | Free |

### Andrej Karpathy Skills

| | |
|---|---|
| **Purpose** | Behavioral guidelines for AI coding |
| **Core** | 4 principles to reduce LLM coding mistakes |
| **Principles** | (1) Think Before Coding — state assumptions, ask when uncertain (2) Simplicity First — minimum code, nothing speculative (3) Surgical Changes — touch only what you must (4) Goal-Driven Execution — define verifiable goals, loop until verified |
| **When to use** | Always active (included in CLAUDE.md) |

### Everything Claude Code (ECC)

| | |
|---|---|
| **Purpose** | Comprehensive Claude Code optimization framework |
| **Core** | 17 agents + 67 skills + 45 commands + language-specific rules |
| **Key commands** | `/tdd` (TDD workflow), `/plan` (implementation planning), `/e2e` (E2E tests), `/code-review` (code review), `/build-fix` (fix build errors), `/learn` (pattern extraction) |
| **Skill categories** | Coding standards, framework patterns (Spring Boot, Django, React, SwiftUI), security, databases, deployment, TDD |
| **Rule structure** | `common/` (all languages) + `typescript/`, `python/`, `golang/`, `swift/`, `kotlin/`, `perl/`, `php/` |
| **When to use** | When you need per-project language rules and workflow commands |

### Anthropic Official Skills

| | |
|---|---|
| **Purpose** | Official agent skills reference from Anthropic |
| **Core** | Document manipulation (PDF, DOCX, PPTX, XLSX) + design + dev tools |
| **Key skills** | `pdf` (parsing/form extraction), `docx` (Word), `pptx` (PowerPoint), `xlsx` (Excel), `claude-api` (API integration examples), `mcp-builder` (MCP server generation), `skill-creator` (meta-skill for creating custom skills) |
| **Skill format** | Folder + `SKILL.md` (YAML frontmatter + markdown instructions) |
| **When to use** | Document automation, design generation, MCP server building |

### Agency Agents

| | |
|---|---|
| **Purpose** | Business-specialist agent persona library |
| **Core** | 164 agents organized by department (engineering, design, QA, marketing, etc.) |
| **Agent format** | Markdown + YAML frontmatter (name, description, model, color, emoji, vibe) + personality/workflow/deliverable definitions |
| **Departments** | Engineering (21), Design (8), Testing (8), Product (4), Marketing (19), Sales (8), PM (6), Game Dev (5), Specialized (16) |
| **When to use** | When you need a specialized business-role persona (e.g., UX architect, QA engineer, security auditor) |

---

## Full Agent Catalog

### OMC Agents (18)

| Agent | Role |
|-------|------|
| analyst | Pre-analysis |
| architect | Architecture |
| code-reviewer | Code review |
| code-simplifier | Code simplification |
| critic | Critical analysis |
| debugger | Debugging |
| designer | UI/UX design |
| document-specialist | Documentation |
| executor | Task execution |
| explore | Codebase navigation |
| git-master | Git workflows |
| planner | Planning |
| qa-tester | QA testing |
| scientist | Research |
| security-reviewer | Security review |
| test-engineer | Test writing |
| verifier | Final verification |
| writer | Content writing |

### omo Agents (11)

| Agent | Role | Overlap with OMC? |
|-------|------|--------------------|
| Sisyphus | Master orchestrator | Unique (standalone .md + plugin hooks available) |
| Sisyphus-Junior | Lite orchestrator | Unique (use Sisyphus with model="sonnet" as lightweight alternative) |
| Prometheus | Detailed planning | Overlaps: planner (standalone .md available) |
| Metis | Intent analysis | Unique (standalone .md available) |
| Momus | Review + anti-slop | Overlaps: code-reviewer (standalone .md available) |
| Oracle | Deep consulting | Unique (standalone .md available) |
| Atlas | Task management | Unique (standalone .md available) |
| Hephaestus | Autonomous execution | Unique (standalone .md available — adapted for Opus) |
| Librarian | Doc search | Complementary: document-specialist (standalone .md available) |
| Explore | Navigation | Overlaps: explore (Claude Code built-in) |
| Multimodal-Looker | Visual analysis | Unique (standalone .md available) |

---

## Recommended Workflow

```
User Request
    ↓
[Metis] Intent analysis + ambiguity detection
    ↓
[Prometheus] Interview-driven plan generation
    ├── [Librarian] Library docs research (if needed)
    └── [Oracle] Architecture consulting (if needed)
    ↓
[Momus] Plan review (optional — high accuracy mode)
    ↓
[Atlas] Task orchestration
    ├── [executor] Implementation
    ├── [test-engineer] Write tests
    ├── [security-reviewer] Security audit
    ├── [code-reviewer] Code review
    └── [Multimodal-Looker] Visual verification (if UI changes)
    ↓
[Verifier] Final verification
    ↓
Done
```

**Magic keyword cheat sheet:**
- `autopilot:` — OMC auto-execution mode
- `ulw` — Max parallelization (OMC)
- `ultrawork` — Activate all agents (omo/OpenCode)
- `/team N:executor "task"` — N-agent team orchestration (OMC)
- `/tdd` — TDD workflow (ECC)
- `/plan` — Implementation planning (ECC)

---

## Directory Structure

```
~/.claude/
├── CLAUDE.md              # OMC markers + Karpathy Guidelines
├── agents/                # Agent definitions (OMC 18 + omo 9 + Agency 40+)
│   ├── analyst.md         # (OMC) Pre-analysis
│   ├── architect.md       # (OMC) Architecture
│   ├── sisyphus.md        # (omo standalone) Master orchestrator
│   ├── hephaestus.md      # (omo standalone) Autonomous deep worker
│   ├── atlas.md           # (omo standalone) Task orchestrator
│   ├── metis.md           # (omo standalone) Intent analyst
│   ├── oracle.md          # (omo standalone) Strategic advisor
│   ├── momus.md           # (omo standalone) Plan reviewer
│   ├── prometheus.md      # (omo standalone) Planning consultant
│   ├── librarian.md       # (omo standalone) Documentation researcher
│   ├── multimodal-looker.md # (omo standalone) Visual analyst
│   ├── eng-*.md           # (Agency) Engineering agents
│   ├── design-*.md        # (Agency) Design agents
│   └── ...
├── skills/                # Anthropic official skills
│   ├── pdf/
│   ├── docx/
│   ├── claude-api/
│   └── ...
├── rules/                 # ECC rules
│   ├── common/            # Common rules (coding style, security, testing, etc.)
│   └── typescript/        # Language-specific rules
├── hud/
│   └── omc-hud.mjs        # OMC HUD statusline
├── plugins/               # Claude Code plugins
└── .omc-config.json       # OMC config

~/.config/opencode/
├── opencode.json          # omo plugin registration
└── oh-my-opencode.json    # omo agent-to-model mapping
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `~/.claude/agents/` doesn't exist | `mkdir -p ~/.claude/agents ~/.claude/skills ~/.claude/rules` |
| `npm i -g` fails with EACCES | `npm i -g --prefix ~/.local <package>` and add `~/.local/bin` to PATH. Or use plugin install method instead. |
| `omc` or `oh-my-opencode` not found after install | Check `npm root -g` and ensure the global bin dir is in PATH. For nvm users: `nvm use default` then reinstall. |
| `[OMC HUD] Plugin not installed` | See [Section 5](#5-fix-omc-hud-error) — add sisyphus path to `omc-hud.mjs` |
| `omo doctor: Comment checker unavailable` | `npm i -g @code-yeongyu/comment-checker` + create bin symlink |
| `omo doctor: Loaded plugin is outdated` | `cd ~/.cache/opencode && npm add oh-my-opencode@latest` (only if `~/.cache/opencode/` exists) |
| `omo doctor: AST-Grep unavailable` | `npm i -g @ast-grep/cli` |
| `omc setup` overwrites CLAUDE.md | OMC only modifies content between markers (`<!-- OMC:START/END -->`), user content is preserved. Auto-backup created. |
| Agent name conflicts | OMC and Agency agents may share names. Install only departments you need. Known conflicts: `architect.md`, `designer.md` |
| `claude mcp add` fails: unknown transport | Requires Claude Code v2.1+. Run `claude --version` to check. Update: `npm update -g @anthropic-ai/claude-code` |
| Plugin marketplace 404 / auth error | Repository must be public. For private repos, use local plugin install (Option B in Section 7). |
| MCP server shows "disconnected" | Check network connectivity. MCP servers are remote HTTP endpoints. Try: `curl -s -o /dev/null -w "%{http_code}" https://mcp.context7.com/mcp` (405 = server is up, connection refused = network issue) |
| Corporate proxy blocks npm/git | Set proxy: `npm config set proxy http://proxy:port` and `git config --global http.proxy http://proxy:port` |
| (Windows) `ln -s` creates copy, not symlink | Run `export MSYS=winsymlinks:nativestrict` in current terminal AND add to `~/.bashrc`. Requires Admin or Developer Mode. |
| (Windows) `omc team` fails: tmux not found | Install psmux (`winget install marlocarlo.psmux`) or tmux-windows (`winget install arndawg.tmux-windows`) |
| (Windows) Split-pane display not working | Split panes require running inside a tmux/psmux session. Windows Terminal and VS Code terminal do not support split panes natively. Use in-process mode instead. |
| (Windows) `brew` command not found | Use `winget` instead of `brew` for package installation on Windows. |
| (Windows) `/tmp` path resolution differs | Git Bash maps `/tmp` to `C:\Users\<user>\AppData\Local\Temp`. This works for all commands in this guide. |
| Plugin not updating after `/plugin update` | Known cache issue ([#17361](https://github.com/anthropics/claude-code/issues/17361)). Delete cache and reinstall: `rm -rf ~/.claude/plugins/cache/my-claude` then `/plugin install my-claude-orchestration@my-claude` |
