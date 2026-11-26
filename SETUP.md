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

**Note:** `npx skills add` does NOT install gstack, agents, rules, or hooks. Use Method A or B for the full experience. gstack in particular requires `install.sh` for the browser runtime.

---

## 3. What Gets Installed

| Category | Count | Details |
|----------|------:|---------|
| **Agents** (always loaded) | 33 | Core (2) + OMO sub-orchestrators (9) + OMC specialists (19) + vendored engineering agents (3) |
| **Skills** | 107 | ECC (61) + gstack (26) + Superpowers (14) + Core (5) + Archify (1). ECC's `web` lane (18) is opt-in; OMC's 13 come from the OMC plugin and are not copied |
| **Rules** | 48 files / 9 sets | ECC (46) + Core (2) |
| **Hooks** | 13 scripts / 7 events | SessionStart, PreToolUse, PostToolUse, SubagentStop, Stop, SessionEnd, UserPromptSubmit |
| **MCP Servers** | 3 | Context7, Exa, grep.app (registered globally) |
| **LSP Servers** | 2 | typescript (`typescript-language-server`), python (`pyright-langserver`) — declared in `.lsp.json`, started on demand for diagnostics and code navigation |
| **Named Workflows** | 2 | code-review-fanout, upstream-audit — copied to `~/.claude/workflows/`, invocable from any project via the Workflow tool |

Skills and rules are installed from an explicit allowlist (`scripts/skill-allowlists.sh`). Upstream ships far more — 278 ECC skills, 59 gstack skills, 41 OMC skills — and everything unlisted is deliberately left out to keep session context lean. Anthropic's official document skills are installed separately (see [Section 4](#4-companion-tools)) and add to the skill count.

Two lanes are deliberately not in the default install:

- **ECC `web` (18 skills)** — React/Vue/Nuxt/Nest, motion, a11y and browser e2e. Add them with `bash install.sh --skills=web` (or `--full-skills`, or `MY_CLAUDE_SKILLS=web`). The choice is saved to `~/.claude/.my-claude-skills`, so later plain installs keep it; `--skills=` clears it.
- **OMC (13 skills)** — the OMC plugin already exposes all of them as `oh-my-claudecode:<name>`, so copying them would put a second description of the same skill in every session. Routing surfaces use the prefixed name.

Every rule file under `rules/common` is injected into every session, so that directory is allowlisted per file (`coding-style.md`, `git-workflow.md`, `security.md` plus this repo's own two). The language rule dirs are `paths:`-scoped and cost nothing until a matching file is opened, so they stay whole.

### File layout after install

```
~/.claude/
├── agents/          ← 33 agents (always loaded by Claude Code)
├── skills/          ← 107 skill directories
├── rules/           ← 48 rule files in 9 rule sets
├── hooks/           ← hooks.json + routing-map.json + 13 hook scripts + 7 helper modules
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
| **Anthropic Official Skills** | Official document and design skills (pdf, docx, pptx, xlsx, canvas-design, mcp-builder) | Cannot be bundled in the plugin; `install.sh` clones github.com/anthropics/skills into `~/.claude/skills`. Deliberately not manifest-tracked, so upgrades never delete them |
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

All 33 agents load on every session — there are no on-demand packs to activate.

| Group | Count | Path | Models | Effort |
|-------|------:|------|--------|--------|
| Core agents (boss, academic-english-editor) | 2 | `~/.claude/agents/` | `claude-opus-5-5`, `claude-fable-5-1` | 2× `xhigh` |
| OMO sub-orchestrators and specialists | 9 | `~/.claude/agents/` | 4× `claude-opus-5-5`, 3× `claude-fable-5-1`, 2× `claude-sonnet-5` | 2× `xhigh`, 5× `high`, 2× `medium` |
| OMC specialists | 19 | `~/.claude/agents/` | opus / sonnet / haiku per agent | not set (upstream defaults) |
| Vendored engineering agents | 3 | `~/.claude/agents/` | inherited from the caller | 1× `xhigh`, 2× `medium` |

`effort` sets how much reasoning budget an agent spends, independent of its model. See [CONTRIBUTING.md](./CONTRIBUTING.md) for the field's values and the model-gating rules.

The vendored three — ai-engineer, devops-automator, multi-agent-systems-architect — are MIT-licensed snapshots taken from [agency-agents](https://github.com/msitarzewski/agency-agents) on 2026-07-27, when that submodule was dropped. The rest of that repo's domain agents are no longer part of my-claude; the `--with-packs` flag and the `my-claude:agency:*` namespace no longer exist.

---

## 6. gstack Sprint Process

gstack is a sprint-process harness from [garrytan/gstack](https://github.com/garrytan/gstack). my-claude installs 25 of its skills plus the `gstack` root router — 26 in total — for structured engineering workflows.

Key gstack skills: `/review`, `/qa`, `/ship`, `/cso`, `/office-hours`, `/plan-ceo-review`, `/plan-eng-review`, `/plan-design-review`, `/plan-devex-review`, `/land-and-deploy`, `/canary`, `/benchmark`, `/retro`. gstack supersedes several ECC skills of the same name — `install.sh` removes stale copies automatically.

### How Boss uses gstack

Boss gives gstack skills highest priority (P0) when routing:

```
Phase 1: DESIGN        (interactive)
  Plan in .briefing/plans/, momus review, one approval gate

Phase 2: EXECUTE       (autonomous)
  ralph agent runs the implementation
  Auto code review via gstack /review

Phase 3: REVIEW        (interactive)
  Output compared against the plan
  User approves or requests iteration
```

### gstack runtime (browser skills)

`/browse` and `/qa` require a Playwright browser daemon. `install.sh` builds this automatically if `bun` is installed. Text-based skills (`/review`, `/ship`, `/plan-*`, etc.) work without it.

```bash
# Install bun if missing, then re-run install.sh
curl -fsSL https://bun.sh/install | bash && bash install.sh
```

`install.sh` checks the runtime in `~/.gstack/runtime` out at the commit this checkout records for the `upstream/gstack` submodule, fetched from that local submodule, and never pulls it from upstream, so it only moves when the recorded commit does. If the submodule does not hold that commit, the runtime is left as it is and gstack's `./setup` is skipped. `install.sh` never turns on gstack auto-upgrade, and it turns off the `auto_upgrade: true` that earlier versions wrote to `~/.gstack/config.json`.

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
echo "Anthropic skills: $(ls ~/.claude/skills/pdf/SKILL.md ~/.claude/skills/docx/SKILL.md 2>/dev/null | wc -l) key skills"
echo "Manifest:         $(wc -l < ~/.claude/.my-claude-manifest 2>/dev/null || echo 'MISSING') entries"
echo "Duplicates:       $(find ~/.claude/agents -name '*.md' -exec basename {} \; | sort | uniq -d | wc -l | tr -d ' ') (should be 0)"
echo "gstack:           $(test -f ~/.claude/skills/gstack/SKILL.md && echo 'OK' || echo 'MISSING')"
echo "omc:              $(command -v omc >/dev/null 2>&1 && echo 'OK' || echo 'MISSING')"
echo "omo:              $(command -v oh-my-opencode >/dev/null 2>&1 && echo 'OK' || echo 'MISSING')"
echo "Workflows:        $(ls ~/.claude/workflows 2>/dev/null | wc -l)"
echo "LSP (typescript): $(command -v typescript-language-server >/dev/null 2>&1 && echo 'OK' || echo 'MISSING')"
echo "LSP (python):     $(command -v pyright-langserver >/dev/null 2>&1 && echo 'OK' || echo 'MISSING')"
echo "Version:          $(cat ~/.claude/.my-claude-version 2>/dev/null || echo 'unknown')"
```

### Expected output

```
Agents:           33
Skills (total):   209 (107 + Anthropic's 19 document/design skills + OMC's 84, less the gstack router)
Skills (my-claude): 107
Rules:            48
Anthropic skills: 2 key skills (pdf, docx)
Manifest:         605 entries
Duplicates:       0 (should be 0)
gstack:           OK
omc:              OK
omo:              OK
Workflows:        2
LSP (typescript): OK
LSP (python):     OK
Version:          <latest release tag>
```

Note: the 84 OMC skills in `Skills (total)` are written by `omc setup`, which `install.sh` runs on a clean machine, so they count there but not in `Skills (my-claude)`. If the OMC plugin is already installed, `install.sh` skips copying the 19 OMC agent files ("Plugin detected — skipping agent file copy"), so `Agents` reads 13 and `Manifest` 586 (605 − 19); the plugin serves the OMC skills instead (a machine with the plugin showed only 2 OMC-named directories under `~/.claude/skills`), so `Skills (total)` reads lower. Any personal skills or rules already in `~/.claude` raise the totals above. All of these are expected. `Skills (total)` does not count the gstack router: `~/.claude/skills/gstack` is a link to the gstack runtime, which `find` does not follow.

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

This moves every submodule to its upstream HEAD, including the gstack skills and the OMC version `install.sh` installs. It skips the upstream-diff scan and review that the sync PRs get. gstack's browser runtime stays at the commit this checkout records, and `install.sh` warns that the gstack and OMC submodule checkouts differ from the recorded commits.

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

If submodule init fails for an upstream (slow network, a timeout), `install.sh` prints `WARNING: submodule init failed for <name>, falling back to git clone...`. It then fetches the commit this checkout records for that submodule, the same one the upstream scan covered. archify is cloned at its pinned tag instead. If that fetch fails too, the upstream is skipped with a warning. gstack's browser runtime is built only from the recorded commit inside `upstream/gstack`, so while that submodule does not hold it, the runtime is left as it is and its setup is skipped. Re-run `git submodule update --init --depth 1` once the network is back, then run `install.sh` again.

A directory that is not a git checkout, such as an extracted zip download, records no commits. `install.sh` does not fall back to an upstream's default branch there: it skips that upstream with a warning, because the copy would be neither pinned nor covered by the upstream scan (archify still uses its pinned tag). Install from a `git clone` of this repository.

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
# OMC: the version upstream/omc pins (run from the my-claude checkout)
v=$(node -p "require('./upstream/omc/package.json').version") && npm i -g "oh-my-claude-sisyphus@$v" && omc setup
npm i -g oh-my-opencode@3.17.3 && oh-my-opencode install --no-tui --claude=yes --openai=no --gemini=no --copilot=no
```

If `npm i -g` fails with a permissions error, set a user-local npm prefix: `npm config set prefix ~/.npm-global` and add `~/.npm-global/bin` to your `PATH`.

If npm reports `No matching version found` for `oh-my-claude-sisyphus`, upstream has not published the pinned version to npm yet. `install.sh` handles that case by installing the newest published version below the pin, so re-running it is the simplest fix. It switches to the pinned version on the first run after npm has it.

The pin bounds the OMC version only. The npm package (its compiled `dist/`, its `postinstall` script, and the `omc setup` that `install.sh` runs after a fresh install) is not the git source the upstream scan reviewed: its contents are trusted as the npm registry serves them.

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

Text-based gstack skills (`/review`, `/ship`, `/plan-*`) work without the browser runtime.

### Duplicates: N > 0 in verify output

```bash
bash install.sh   # deduplicates automatically on re-run
```

---

For the AI-agent-friendly version of these instructions (compact, no explanations), see [AI-INSTALL.md](./AI-INSTALL.md).
