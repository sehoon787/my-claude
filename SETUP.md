# my-claude — Full Setup Guide

> **Version Note (2026-07):** Last verified July 2026, after the agency-agents submodule was removed and the skill allowlists were introduced. The architecture is plugin + `install.sh` based. Do not follow the old per-upstream manual clone steps. See [AI-INSTALL.md](./AI-INSTALL.md) for the AI-agent-friendly version of these instructions.

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Install (choose one method)](#2-install-choose-one-method)
3. [What Gets Installed](#3-what-gets-installed)
4. [Companion Tools](#4-companion-tools)
5. [Agents](#5-agents)
6. [gstack Sprint Process](#6-gstack-sprint-process)
7. [Briefing Vault](#7-briefing-vault)
8. [Verify Installation](#8-verify-installation)
9. [Updating](#9-updating)
10. [Troubleshooting](#10-troubleshooting)

---

## 1. Prerequisites

### Required on all platforms

```bash
# Node.js v20+
node --version

# npm
npm --version

# Git
git --version

# Claude Code CLI v2.1+
claude --version

# Create directories (idempotent — safe to re-run)
mkdir -p ~/.claude/agents ~/.claude/skills ~/.claude/rules
```

### tmux (required for Agent Teams split-pane mode)

`install.sh` will attempt to install tmux automatically. If you prefer to install it manually:

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
<summary>Linux (Fedora/RHEL)</summary>

```bash
sudo dnf install tmux
```
</details>

<details>
<summary>Windows</summary>

tmux does not run natively on Windows. Choose one of:

```bash
# Option A: psmux (recommended — native Windows, Agent Teams compatible)
winget install marlocarlo.psmux

# Option B: tmux-windows (native ConPTY port of real tmux)
winget install arndawg.tmux-windows

# Option C: Use WSL2 (run everything inside Linux)
wsl --install
# Then inside WSL: sudo apt install tmux
```

> Without tmux/psmux, `omc team` will not work. Claude Code's built-in Agent Teams still works in in-process mode (single terminal, Shift+Up/Down to navigate agents).

**Windows symlink fix (required for Git Bash):**

By default `ln -s` in Git Bash creates a copy instead of a real symlink. Fix this before running `install.sh`:

```bash
# Add to ~/.bashrc or ~/.bash_profile
export MSYS=winsymlinks:nativestrict
```

> Requires either running Git Bash as Administrator, or enabling Windows Developer Mode (Settings > Update & Security > For Developers).

</details>

---

## 2. Install (choose one method)

### Method A: Plugin Install (Recommended)

Install the plugin from inside a Claude Code session, then run the companion installer:

```bash
# Step 1: Inside a Claude Code session
/plugin marketplace add sehoon787/my-claude
/plugin install my-claude@my-claude
```

After the plugin installs, configure Boss as the default agent and register MCP servers globally (one-time setup, run in your terminal):

```bash
node -e "const fs=require('fs'),p=require('path'),f=p.join(require('os').homedir(),'.claude','settings.json');const s=fs.existsSync(f)?JSON.parse(fs.readFileSync(f,'utf8')):{};s.env={...s.env,CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS:'1'};s.agent=s.agent||'boss';s.mcpServers={...s.mcpServers,context7:{type:'url',url:'https://mcp.context7.com/mcp'},exa:{type:'url',url:'https://mcp.exa.ai/mcp?tools=web_search_exa'},grep_app:{type:'url',url:'https://mcp.grep.app'}};fs.writeFileSync(f,JSON.stringify(s,null,2))"
```

```bash
# Step 2: Install companion tools (terminal, outside Claude Code session)
git clone --depth 1 https://github.com/sehoon787/my-claude.git /tmp/my-claude
bash /tmp/my-claude/install.sh
rm -rf /tmp/my-claude
```

The plugin handles agents, skills, rules, hooks, and MCP servers. Step 2 adds companion CLIs, Anthropic official skills, and gstack runtime (see [Section 4](#4-companion-tools)).

---

### Method B: install.sh Only

If the plugin marketplace is unavailable or you prefer a fully scripted install:

```bash
git clone --depth 1 https://github.com/sehoon787/my-claude.git /tmp/my-claude
git -C /tmp/my-claude submodule update --init --depth 1
bash /tmp/my-claude/install.sh
rm -rf /tmp/my-claude
```

`install.sh` initializes git submodules from the `upstream/` directory, copies all agents/skills/rules/hooks, registers MCP servers, and installs companion tools in a single pass. For the full manual script (useful when running inside an AI agent session), see [AI-INSTALL.md Step 1b](./AI-INSTALL.md).

---

### Method C: Skills Only (npx skills add)

If you only need the skills library (not agents, rules, hooks, or MCP configs):

```bash
npx skills add sehoon787/my-claude -y -g
```

This installs skills to `~/.agents/skills/` and auto-symlinks them to `~/.claude/skills/`. Works with Claude Code, Codex, Cursor, and other tools that support the skills.sh standard.

**Note:** `npx skills add` does NOT install gstack, agents, rules, or hooks. Use Method A or B for the full experience. gstack in particular requires `install.sh` for the browser runtime and auto-upgrade config.

---

## 3. What Gets Installed

| Category | Count | Details |
|----------|------:|---------|
| **Agents** (always loaded) | 32 | Boss (1) + OMO sub-orchestrators (9) + OMC specialists (19) + vendored engineering agents (3) |
| **Skills** | 139 | ECC (79) + gstack (27) + OMC (16) + Superpowers (13) + Core (4) |
| **Rules** | 54 files / 9 sets | ECC (53) + Core (1) |
| **Hooks** | 8 files / 8 events | SessionStart, PreToolUse, PostToolUse, SubagentStop, TeammateIdle, TaskCompleted, Stop, UserPromptSubmit |
| **MCP Servers** | 3 | Context7, Exa, grep.app (registered globally) |
| **LSP Servers** | 2 | typescript (`typescript-language-server`), python (`pyright-langserver`) — declared in `.lsp.json`, started on demand for diagnostics and code navigation |
| **Named Workflows** | 2 | code-review-fanout, upstream-audit — copied to `~/.claude/workflows/`, invocable from any project via the Workflow tool |

Skills and rules are installed from an explicit allowlist (`scripts/skill-allowlists.sh`). Upstream ships far more — 278 ECC skills, 59 gstack skills, 41 OMC skills — and everything unlisted is deliberately left out to keep session context lean. Anthropic's official document skills are installed separately (see [Section 4](#4-companion-tools)) and add to the skill count.

### File layout after install

```
~/.claude/
├── agents/          ← 32 agents (always loaded by Claude Code)
├── skills/          ← 139 skill directories
├── rules/           ← 54 rule files in 9 rule sets
├── hooks/           ← hooks.json + 7 hook scripts
├── workflows/       ← 2 named workflows (code-review-fanout.js, upstream-audit.js)
├── docs/nexus/      ← Agent Teams reference (not parsed as an agent)
├── .my-claude-manifest   ← Tracks installed files for safe upgrades
└── .my-claude-version    ← Installed version string
```

---

## 4. Companion Tools

`install.sh` installs these tools in addition to the plugin files:

| Tool | What It Is | Why |
|------|-----------|-----|
| **Anthropic Official Skills** | Official document and design skills (pdf, docx, pptx, xlsx, canvas-design, mcp-builder) | Cannot be bundled in the plugin; installed via `claude plugin add anthropics/skills`. Deliberately not manifest-tracked, so upgrades never delete them |
| **omc** (`oh-my-claude-sisyphus`) | npm CLI for OMC team orchestration | Enables `omc team` multi-agent split-pane sessions |
| **omo** (`oh-my-opencode`) | npm CLI bridging Claude Code and OpenCode | Optional — only needed for OpenCode TUI workflows |
| **ast-grep** | Structural code search and rewrite tool | Used by several skills for code analysis |
| **LSP servers** | `typescript-language-server` + `pyright-langserver` | Back the plugin's `.lsp.json` declaration. Installed non-fatally — a missing binary disables only that server |
| **comment-checker** | Static analysis for code comment quality | Used by code-review skills |
| **Karpathy guidelines** | Andrej Karpathy's 4 AI coding principles | Appended to `~/.claude/CLAUDE.md` (checksum-verified before writing) |
| **gstack runtime** | Browser daemon for `/browse` and `/qa` skills | Requires `bun`; installed automatically if `bun` is present |

`install.sh` is idempotent — re-running it skips already-installed tools and upgrades the manifest.

---

## 5. Agents

All 32 agents load on every session — there are no on-demand packs to activate.

| Group | Count | Path | Models | Effort |
|-------|------:|------|--------|--------|
| Boss meta-orchestrator | 1 | `~/.claude/agents/boss.md` | `claude-fable-5-1` | `xhigh` |
| OMO sub-orchestrators and specialists | 9 | `~/.claude/agents/` | 7× `claude-opus-5`, 2× `claude-sonnet-5` | 2× `xhigh`, 5× `high`, 2× `medium` |
| OMC specialists | 19 | `~/.claude/agents/` | opus / sonnet / haiku per agent | not set (upstream defaults) |
| Vendored engineering agents | 3 | `~/.claude/agents/` | inherited from the caller | 1× `xhigh`, 2× `medium` |

`effort` sets how much reasoning budget an agent spends, independent of its model. See [CONTRIBUTING.md](./CONTRIBUTING.md) for the field's values and the model-gating rules.

The vendored three — ai-engineer, devops-automator, multi-agent-systems-architect — are MIT-licensed snapshots taken from [agency-agents](https://github.com/msitarzewski/agency-agents) on 2026-07-27, when that submodule was dropped. The rest of that repo's domain agents are no longer part of my-claude; the `--with-packs` flag and the `my-claude:agency:*` namespace no longer exist.

---

## 6. gstack Sprint Process

gstack is a sprint-process harness from [garrytan/gstack](https://github.com/garrytan/gstack). my-claude installs 26 of its skills plus the `gstack` root router — 27 in total — for structured engineering workflows.

Key gstack skills: `/review`, `/qa`, `/ship`, `/cso`, `/investigate`, `/office-hours`, `/plan-ceo-review`, `/plan-eng-review`, `/plan-design-review`, `/plan-devex-review`, `/land-and-deploy`, `/canary`, `/benchmark`, `/retro`. gstack supersedes several ECC skills of the same name — `install.sh` removes stale copies automatically.

### How Boss uses gstack

Boss gives gstack skills highest priority (P0) when routing:

```
Phase 1: DESIGN        (interactive)
  User confirms scope and design doc

Phase 2: EXECUTE       (autonomous)
  ralph agent runs the implementation
  Auto code review via gstack /review

Phase 3: REVIEW        (interactive)
  Output compared against design doc
  User approves or requests iteration
```

### gstack runtime (browser skills)

`/browse` and `/qa` require a Playwright browser daemon. `install.sh` builds this automatically if `bun` is installed. Text-based skills (`/review`, `/ship`, `/plan-*`, etc.) work without it.

```bash
# Install bun if missing, then re-run install.sh
curl -fsSL https://bun.sh/install | bash && bash install.sh
```

`install.sh` also writes `~/.gstack/config.json` with `auto_upgrade: true` so gstack self-updates on each use.

---

## 7. Briefing Vault

my-claude includes an Obsidian-compatible knowledge management system. Every project maintains a `.briefing/` directory as persistent memory across sessions.

```
.briefing/
├── INDEX.md              ← Project context and open questions
├── sessions/             ← Per-session summaries (YYYY-MM-DD-topic.md)
├── decisions/            ← Architecture and design decisions
├── learnings/            ← Non-obvious solutions and gotchas
├── references/           ← Web findings and factual data
└── agents/               ← Important agent execution logs
```

Boss reads `INDEX.md` at session start, writes notes during work, and updates the index at session end. All notes use YAML frontmatter (`date`, `type`, `tags`, `related`). Open `.briefing/` as an Obsidian vault for graph view. Add it to `.gitignore` to keep it local.

---

## 8. Verify Installation

Run this block in your terminal after installation:

```bash
echo "Agents:           $(find ~/.claude/agents -name '*.md' 2>/dev/null | wc -l)"
echo "Skills (total):   $(find ~/.claude/skills -maxdepth 2 -name 'SKILL.md' 2>/dev/null | wc -l)"
echo "Skills (my-claude): $(grep '^skills/' ~/.claude/.my-claude-manifest 2>/dev/null | cut -d/ -f2 | sort -u | wc -l)"
echo "Rules:            $(find ~/.claude/rules -name '*.md' 2>/dev/null | wc -l)"
echo "Anthropic skills: $(ls -d ~/.claude/skills/pdf ~/.claude/skills/docx 2>/dev/null | wc -l) key skills"
echo "Manifest:         $(wc -l < ~/.claude/.my-claude-manifest 2>/dev/null || echo 'MISSING') entries"
echo "Duplicates:       $(find ~/.claude/agents -name '*.md' -exec basename {} \; | sort | uniq -d | wc -l | tr -d ' ') (should be 0)"
echo "gstack:           $(find ~/.claude/skills -path '*/gstack/SKILL.md' 2>/dev/null | head -1 | grep -q . && echo 'OK' || echo 'MISSING')"
echo "omc:              $(command -v omc >/dev/null 2>&1 && echo 'OK' || echo 'MISSING')"
echo "omo:              $(command -v oh-my-opencode >/dev/null 2>&1 && echo 'OK' || echo 'MISSING')"
echo "Workflows:        $(ls ~/.claude/workflows 2>/dev/null | wc -l)"
echo "LSP (typescript): $(command -v typescript-language-server >/dev/null 2>&1 && echo 'OK' || echo 'MISSING')"
echo "LSP (python):     $(command -v pyright-langserver >/dev/null 2>&1 && echo 'OK' || echo 'MISSING')"
echo "Version:          $(cat ~/.claude/.my-claude-version 2>/dev/null || echo 'unknown')"
```

### Expected output

```
Agents:           32
Skills (total):   139 or more (Anthropic document skills add to this)
Skills (my-claude): 139
Rules:            54
Anthropic skills: 2 key skills (pdf, docx)
Manifest:         315 entries
Duplicates:       0 (should be 0)
gstack:           OK
omc:              OK
omo:              OK
Workflows:        2
LSP (typescript): OK
LSP (python):     OK
Version:          <latest release tag>
```

Non-zero duplicates: re-run `install.sh` (deduplicates automatically). gstack MISSING: install `bun` and re-run `install.sh`. LSP MISSING: install the binary yourself (`npm i -g typescript-language-server typescript` or `npm i -g pyright`) — the rest of the stack is unaffected.

---

## 9. Updating

**Plugin (Method A):** Inside a Claude Code session run `/plugin update my-claude`, then re-run `install.sh` to pick up new companion tools.

**Manual (Method B):**

```bash
cd /path/to/my-claude && git pull && git submodule update --init --depth 1 && bash install.sh
```

**Upstream submodules only:**

```bash
cd /path/to/my-claude && git submodule update --remote && bash install.sh
```

The manifest system removes stale files on upgrade without touching user-added content.

---

## 10. Troubleshooting

### Plugin install fails

If `/plugin marketplace add` or `/plugin install` fails inside Claude Code:

```bash
# Fallback: install via install.sh directly (Method B)
git clone --depth 1 https://github.com/sehoon787/my-claude.git /tmp/my-claude
git -C /tmp/my-claude submodule update --init --depth 1
bash /tmp/my-claude/install.sh
rm -rf /tmp/my-claude
```

### install.sh fails on submodule init

If submodule init is slow or times out, `install.sh` automatically falls back to `git clone --depth 1` for each upstream. You will see a `WARNING: submodule init failed, falling back to git clone` message — this is expected and safe.

If both fail (no network), download the repo with submodules as a zip from GitHub and run install from the extracted directory.

### MCP servers not showing up

```bash
# Check what Claude Code has registered
claude mcp list

# Re-register manually if missing
claude mcp add context7  --transport http --scope user "https://mcp.context7.com/mcp"
claude mcp add exa       --transport http --scope user "https://mcp.exa.ai/mcp?tools=web_search_exa"
claude mcp add grep_app  --transport http --scope user "https://mcp.grep.app"
```

MCP servers are registered at user scope (`--scope user`) so they are available in all projects.

### omc / omo not found after install

```bash
npm i -g oh-my-claude-sisyphus@4.8.2 && omc setup
npm i -g oh-my-opencode@3.12.3 && oh-my-opencode install --no-tui --claude=yes --openai=no --gemini=no --copilot=no
```

If `npm i -g` fails with a permissions error, set a user-local npm prefix: `npm config set prefix ~/.npm-global` and add `~/.npm-global/bin` to your `PATH`.

### Agent not recognized by Boss

Boss discovers agents at runtime by scanning `~/.claude/agents/`. Check that the `.md` file is there and that its frontmatter parses, then start a new session.

### Windows: symlinks not working in install.sh

```bash
# Run Git Bash as Administrator, then:
export MSYS=winsymlinks:nativestrict
bash install.sh
```

Or enable Windows Developer Mode (Settings > Update & Security > For Developers).

### gstack /browse or /qa not working

```bash
# Install bun, then rebuild the runtime
curl -fsSL https://bun.sh/install | bash && source ~/.bashrc && bash install.sh
```

Text-based gstack skills (`/review`, `/ship`, `/plan-*`, `/investigate`) work without the browser runtime.

### Duplicates: N > 0 in verify output

```bash
bash install.sh   # deduplicates automatically on re-run
```

---

For the AI-agent-friendly version of these instructions (compact, no explanations), see [AI-INSTALL.md](./AI-INSTALL.md).
