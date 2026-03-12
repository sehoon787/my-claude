# Claude Code Multi-Agent Orchestration — Full Setup Guide

Give this document to an AI coding agent to reproduce the exact same environment.

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Install OMC (Oh My Claude Code)](#2-install-omc-oh-my-claude-code)
3. [Install omo (Oh My OpenCode)](#3-install-omo-oh-my-opencode)
4. [Fix OMC HUD Error](#4-fix-omc-hud-error)
5. [Install omo Additional Dependencies](#5-install-omo-additional-dependencies)
6. [Port omo Agents to Claude Code (Metis, Atlas)](#6-port-omo-agents-to-claude-code-metis-atlas)
7. [Install Andrej Karpathy Skills](#7-install-andrej-karpathy-skills)
8. [Install Everything Claude Code (ECC)](#8-install-everything-claude-code-ecc)
9. [Install Anthropic Official Skills](#9-install-anthropic-official-skills)
10. [Install Agency Agents](#10-install-agency-agents)
11. [Verification](#11-verification)
12. [Tool Reference](#12-tool-reference)

---

## 1. Prerequisites

```bash
# Node.js (v20+)
node --version

# npm
npm --version

# tmux (required by OMC and omo)
brew install tmux   # macOS
# sudo apt install tmux   # Ubuntu/Debian

# Claude Code CLI
claude --version

# OpenCode (required by omo)
opencode --version
# If not installed: npm i -g @anthropic-ai/opencode
```

---

## 2. Install OMC (Oh My Claude Code)

Native multi-agent orchestration plugin for Claude Code.

```bash
# Install CLI
npm i -g oh-my-claude-sisyphus@latest

# Run setup (installs 18 agents + HUD + CLAUDE.md configuration)
omc setup

# Verify
omc --version
omc doctor conflicts
```

**What gets installed:**
- `~/.claude/agents/` — 18 agent definition files (.md)
- `~/.claude/CLAUDE.md` — OMC orchestration directives injected (existing content preserved)
- `~/.claude/hud/omc-hud.mjs` — HUD statusline script
- `~/.claude/.omc-config.json` — Node binary path
- `~/.claude/.omc-version.json` — Version metadata

---

## 3. Install omo (Oh My OpenCode)

Multi-model agent orchestration plugin for OpenCode.

```bash
# Global install
npm i -g oh-my-opencode@latest

# Non-interactive install (Claude only)
oh-my-opencode install --no-tui --claude=yes --openai=no --gemini=no --copilot=no

# Update plugin in OpenCode cache
cd ~/.cache/opencode && npm add oh-my-opencode@latest && cd ~

# Verify
oh-my-opencode --version
oh-my-opencode doctor
```

**What gets installed:**
- `~/.config/opencode/opencode.json` — Plugin registration
- `~/.config/opencode/oh-my-opencode.json` — Agent-to-model mapping

---

## 4. Fix OMC HUD Error

`omc setup` installs the npm package as `oh-my-claude-sisyphus`, but the HUD script tries to import `oh-my-claudecode`. Under nvm, global module resolution fails.

**Fix:** Add an absolute-path fallback to `~/.claude/hud/omc-hud.mjs`.

Find this block (around line 76–80):

```javascript
  // 4. npm package (global or local install)
  try {
    await import("oh-my-claudecode/dist/hud/index.js");
    return;
  } catch { /* continue */ }
```

Add the following immediately after:

```javascript
  // 4b. npm package under oh-my-claude-sisyphus (absolute path for nvm compatibility)
  const sisyphusHudPath = join(
    process.execPath, "..", "..", "lib", "node_modules",
    "oh-my-claude-sisyphus", "dist", "hud", "index.js"
  );
  if (existsSync(sisyphusHudPath)) {
    try {
      await import(pathToFileURL(sisyphusHudPath).href);
      return;
    } catch { /* continue */ }
  }
```

**Verify:**

```bash
node ~/.claude/hud/omc-hud.mjs
# Expected: "[OMC] run /omc-setup to install properly" (this is normal)
# Error:    "[OMC HUD] Plugin not installed..." (this means the fix didn't work)
```

---

## 5. Install omo Additional Dependencies

Resolve all warnings from `oh-my-opencode doctor`.

```bash
# AST-Grep (structural code search/replace)
npm i -g @ast-grep/cli

# Comment Checker (comment quality hook)
npm i -g @code-yeongyu/comment-checker

# Symlink comment-checker binary (npm may not create the bin link)
NODE_BIN=$(dirname $(which node))
NODE_LIB=$(dirname $NODE_BIN)/lib
if [ ! -f "$NODE_BIN/comment-checker" ] && [ -f "$NODE_LIB/node_modules/@code-yeongyu/comment-checker/bin/comment-checker" ]; then
  ln -s "$NODE_LIB/node_modules/@code-yeongyu/comment-checker/bin/comment-checker" "$NODE_BIN/comment-checker"
fi

# Verify
oh-my-opencode doctor
# Expected: "✓ System OK"
```

---

## 6. Port omo Agents to Claude Code (Metis, Atlas)

Two agents unique to omo (not present in OMC) are ported to Claude Code's agent format.

### Metis (Intent Analyst)

Copy `agents/metis.md` from this repo to `~/.claude/agents/metis.md`.

**Role:** Classifies user intent before planning, detects ambiguity, and prevents AI-slop (over-engineering, scope creep). Outputs MUST/MUST NOT directives for the planner agent.

**Key capabilities:**
- Phase 0: Intent classification (Refactoring / Build / Mid-sized / Collaborative / Architecture / Research)
- Phase 1: Intent-specific analysis with required questions and planner directives
- AI-slop detection (scope inflation, premature abstraction, over-validation, doc bloat)
- Agent-executable acceptance criteria (no manual testing)

### Atlas (Task Orchestrator)

Copy `agents/atlas.md` from this repo to `~/.claude/agents/atlas.md`.

**Role:** Delegates all tasks in a work plan to specialist agents, verifies each result with 4-phase QA, and tracks everything to completion. Never writes code directly.

**Key capabilities:**
- 6-section delegation prompts (TASK, EXPECTED OUTCOME, REQUIRED TOOLS, MUST DO, MUST NOT DO, CONTEXT)
- 4-Phase QA (automated checks → manual code review → hands-on testing → state check)
- Parallel execution for independent tasks, sequential for dependent ones
- Session resume on failure (max 3 retries)
- Final Verification Wave (code-reviewer + verifier)

```bash
# Install from this repo
cp agents/metis.md ~/.claude/agents/
cp agents/atlas.md ~/.claude/agents/
```

---

## 7. Install Andrej Karpathy Skills

Four behavioral principles that reduce common LLM coding mistakes.

```bash
# Option A: Claude Code plugin (recommended)
# Inside a Claude Code session:
#   /plugin marketplace add forrestchang/andrej-karpathy-skills
#   /plugin install andrej-karpathy-skills@karpathy-skills

# Option B: Manual (append to CLAUDE.md)
cd /tmp && git clone --depth 1 https://github.com/forrestchang/andrej-karpathy-skills.git
cat /tmp/andrej-karpathy-skills/CLAUDE.md >> ~/.claude/CLAUDE.md
```

> **Note:** `omc setup` may overwrite CLAUDE.md. Always add custom content below the OMC marker (`<!-- OMC:END -->`).

---

## 8. Install Everything Claude Code (ECC)

Comprehensive framework with 67+ skills, 17 agents, 45 commands, and language-specific rules.

```bash
# Option A: Claude Code plugin (recommended)
# Inside a Claude Code session:
#   /plugin marketplace add affaan-m/everything-claude-code
#   /plugin install everything-claude-code@everything-claude-code

# Option B: Manual (rules only)
cd /tmp && git clone --depth 1 https://github.com/affaan-m/everything-claude-code.git
cd /tmp/everything-claude-code

# For TypeScript projects:
bash install.sh claude typescript

# For Python projects:
# bash install.sh claude python

# For Go projects:
# bash install.sh claude golang
```

**What gets installed:**
- `~/.claude/rules/common/` — 9 common rules (coding style, security, testing, etc.)
- `~/.claude/rules/<language>/` — 5 language-specific rules

---

## 9. Install Anthropic Official Skills

Anthropic's official agent skills repository. 17 skills including document manipulation, design, and dev tools.

```bash
# Option A: Claude Code plugin (recommended)
# Inside a Claude Code session:
#   /plugin marketplace add anthropics/skills
#   /plugin install document-skills@anthropic-agent-skills
#   /plugin install example-skills@anthropic-agent-skills

# Option B: Manual (copy skill folders)
cd /tmp && git clone --depth 1 https://github.com/anthropics/skills.git
mkdir -p ~/.claude/skills
cp -r /tmp/skills/skills/* ~/.claude/skills/
```

**Skills installed (17):**
algorithmic-art, brand-guidelines, canvas-design, claude-api, doc-coauthoring, docx, frontend-design, internal-comms, mcp-builder, pdf, pptx, skill-creator, slack-gif-creator, theme-factory, web-artifacts-builder, webapp-testing, xlsx

---

## 10. Install Agency Agents

164 business-specialist agent personas across departments.

```bash
cd /tmp && git clone --depth 1 https://github.com/msitarzewski/agency-agents.git

# Core departments only (recommended — avoids agent overload)
cp /tmp/agency-agents/engineering/*.md ~/.claude/agents/
cp /tmp/agency-agents/testing/*.md ~/.claude/agents/
cp /tmp/agency-agents/design/*.md ~/.claude/agents/
cp /tmp/agency-agents/product/*.md ~/.claude/agents/

# Full install (all 164 agents)
# cp -r /tmp/agency-agents/{engineering,testing,design,product,marketing,sales,project-management,spatial-computing,game-development,specialized,support,strategy,paid-media}/*.md ~/.claude/agents/
```

> **Warning:** Too many agents can cause Claude Code to struggle with selection. Install only the departments you actually need.

---

## 11. Verification

```bash
# OMC
omc --version                    # 4.7.10+
omc doctor conflicts             # "No conflicts detected"

# omo
oh-my-opencode --version         # 3.11.2+
oh-my-opencode doctor            # "✓ System OK"

# HUD
node ~/.claude/hud/omc-hud.mjs   # "[OMC] run /omc-setup..." (not an error)

# Agents
ls ~/.claude/agents/ | wc -l     # 60+ (OMC 18 + Atlas/Metis 2 + Agency 40+)

# Skills
ls ~/.claude/skills/             # 17 directories

# Rules
ls ~/.claude/rules/              # common/ + language directories

# tmux
tmux -V                          # 3.x+
```

---

## 12. Tool Reference

### OMC (Oh My Claude Code)

| | |
|---|---|
| **Purpose** | Native multi-agent orchestration for Claude Code |
| **Core** | 18 specialized agents + HUD statusline + magic keywords |
| **How it works** | Injects orchestration rules into CLAUDE.md, defines agents in `~/.claude/agents/` |
| **Key features** | `autopilot:` (auto-execution), `ulw` (max parallelization), `/team N:executor "task"` (team orchestration), real-time HUD monitoring |
| **Agents** | analyst, architect, code-reviewer, code-simplifier, critic, debugger, designer, document-specialist, executor, explore, git-master, planner, qa-tester, scientist, security-reviewer, test-engineer, verifier, writer |
| **When to use** | Complex multi-step tasks in Claude Code sessions |

### omo (Oh My OpenCode)

| | |
|---|---|
| **Purpose** | Multi-model agent orchestration for OpenCode |
| **Core** | Sisyphus orchestrator + multi-model routing across 8 providers |
| **How it works** | Runs as an OpenCode plugin, auto-selects models by task category |
| **Key features** | `ultrawork` (activate all agents), `/start-work` (interview mode), `/init-deep` (generate AGENTS.md) |
| **Agents** | Sisyphus (orchestrator), Prometheus (planning), Metis (intent analysis), Momus (review), Oracle (consulting), Atlas (task mgmt), Hephaestus (autonomous execution), Librarian (doc search), Explore (navigation) |
| **When to use** | Multi-model orchestration (Claude, GPT, Gemini) via OpenCode |

### Metis (ported from omo)

| | |
|---|---|
| **Purpose** | Pre-planning intent analysis agent |
| **Core** | Intent classification + ambiguity detection + AI-slop prevention |
| **How it works** | Classifies into 6 intent types (Refactoring, Build, Mid-sized, Collaborative, Architecture, Research), then runs intent-specific analysis |
| **When to use** | Before handing complex requirements to the planner agent |

### Atlas (ported from omo)

| | |
|---|---|
| **Purpose** | Master task orchestrator |
| **Core** | Task-list delegation + 4-phase QA verification + completion tracking |
| **How it works** | Never writes code; delegates to specialist agents via 6-section prompts; runs independent tasks in parallel |
| **When to use** | When you need to execute and verify a multi-step work plan automatically |

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
| **Agent format** | Markdown + YAML frontmatter (name, description, color, emoji, vibe) + personality/workflow/deliverable definitions |
| **Departments** | Engineering (21), Design (8), Testing (8), Product (4), Marketing (19), Sales (8), PM (6), Game Dev (5), Specialized (16) |
| **When to use** | When you need a specialized business-role persona (e.g., UX architect, QA engineer, security auditor) |

---

## Recommended Workflow

```
User Request
    ↓
[Metis] Intent analysis + ambiguity detection
    ↓
[Planner] Build execution plan
    ↓
[Atlas] Task orchestration
    ├── [executor] Implementation
    ├── [test-engineer] Write tests
    ├── [security-reviewer] Security audit
    └── [code-reviewer] Code review
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
├── agents/                # Agent definitions (OMC 18 + Metis + Atlas + Agency 40+)
│   ├── analyst.md         # (OMC) Pre-analysis
│   ├── architect.md       # (OMC) Architecture
│   ├── atlas.md           # (omo port) Task orchestrator
│   ├── metis.md           # (omo port) Intent analyst
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
| `[OMC HUD] Plugin not installed` | See [Section 4](#4-fix-omc-hud-error) — add sisyphus path to `omc-hud.mjs` |
| `omo doctor: Comment checker unavailable` | `npm i -g @code-yeongyu/comment-checker` + create bin symlink |
| `omo doctor: Loaded plugin is outdated` | `cd ~/.cache/opencode && npm add oh-my-opencode@latest` |
| `omo doctor: AST-Grep unavailable` | `npm i -g @ast-grep/cli` |
| `omc setup` overwrites CLAUDE.md | OMC only modifies content between markers (`<!-- OMC:START/END -->`), user content is preserved. Auto-backup created. |
| Agent name conflicts | OMC and Agency agents may share names. Install only departments you need. |
