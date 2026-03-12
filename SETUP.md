# Claude Code Multi-Agent Orchestration — Full Setup Guide

Give this document to an AI coding agent to reproduce the exact same environment.

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Install OMC (Oh My Claude Code)](#2-install-omc-oh-my-claude-code)
3. [Install omo (Oh My OpenAgent)](#3-install-omo-oh-my-openagent)
4. [Fix OMC HUD Error](#4-fix-omc-hud-error)
5. [Install omo Additional Dependencies](#5-install-omo-additional-dependencies)
6. [Use omo Agents in Claude Code (Metis, Atlas)](#6-use-omo-agents-in-claude-code-metis-atlas)
7. [Install Andrej Karpathy Skills](#7-install-andrej-karpathy-skills)
8. [Install Everything Claude Code (ECC)](#8-install-everything-claude-code-ecc)
9. [Install Anthropic Official Skills](#9-install-anthropic-official-skills)
10. [Install Agency Agents](#10-install-agency-agents)
11. [Agent Overlap Analysis (OMC vs omo)](#11-agent-overlap-analysis-omc-vs-omo)
12. [Verification](#12-verification)
13. [Tool Reference](#13-tool-reference)

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

# OpenCode (optional — required only if running omo natively in OpenCode)
opencode --version
# If not installed: npm i -g @anthropic-ai/opencode
```

> **Note:** OpenCode is only needed if you want to run omo's full agent suite natively in OpenCode. If you only use the standalone Metis/Atlas `.md` files in Claude Code, OpenCode is not required.

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

## 3. Install omo (Oh My OpenAgent)

Multi-platform agent harness with Claude Code ecosystem bridge.

> **Naming:** The project was renamed to **oh-my-openagent** (GitHub: [code-yeongyu/oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent)). The npm package name remains `oh-my-opencode` for backward compatibility.

```bash
# Global install (npm package is still oh-my-opencode)
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

**Claude Code bridge:** omo includes a `claude-code-agent-loader` that reads `~/.claude/agents/*.md` files and a `claude-code-plugin-loader` that loads Claude Code plugins. This means when running in OpenCode with omo, you get access to both omo's native agents AND Claude Code ecosystem agents/plugins. The bridge direction is **omo consuming Claude Code ecosystem**, not the reverse.

**11 built-in agents:** Sisyphus (orchestrator), Sisyphus-Junior (lightweight orchestrator), Prometheus (planning), Metis (intent analysis), Momus (review), Oracle (consulting), Atlas (task management), Hephaestus (autonomous execution), Librarian (doc search), Explore (navigation), Multimodal-Looker (visual analysis)

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

## 6. Use omo Agents in Claude Code (Metis, Atlas)

Two key omo agents (Metis, Atlas) can be used in Claude Code. Choose your approach:

### Option A: Standalone .md files (for Claude Code users)

Copy adapted agent definitions to `~/.claude/agents/`. These are standalone adaptations of the original omo agents, rewritten for Claude Code's agent format. They work without OpenCode or omo installed.

```bash
# Install from this repo
cp agents/metis.md ~/.claude/agents/
cp agents/atlas.md ~/.claude/agents/
```

### Option B: Native omo agents (via OpenCode)

If you use OpenCode with omo, Metis and Atlas are built-in — no porting needed. omo also loads any `.md` agents from `~/.claude/agents/` via its Claude Code bridge, so you get both omo-native and Claude Code agents in one session.

```bash
# Just run OpenCode — omo agents are available automatically
opencode
```

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

## 11. Agent Overlap Analysis (OMC vs omo)

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
- **In Claude Code:** Use standalone Metis .md → OMC planner → standalone Atlas .md for orchestration

---

## 12. Verification

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
ls ~/.claude/agents/ | wc -l     # 60+ (OMC 18 + Metis + Atlas + Agency 40+)

# Skills
ls ~/.claude/skills/             # 17 directories

# Rules
ls ~/.claude/rules/              # common/ + language directories

# tmux
tmux -V                          # 3.x+

# OpenCode (optional)
opencode --version               # 1.2.17+ (only if using omo natively)
```

---

## 13. Tool Reference

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

### Metis (standalone adaptation from omo)

| | |
|---|---|
| **Purpose** | Pre-planning intent analysis agent |
| **Core** | Intent classification + ambiguity detection + AI-slop prevention |
| **How it works** | Classifies into 6 intent types (Refactoring, Build, Mid-sized, Collaborative, Architecture, Research), then runs intent-specific analysis |
| **Availability** | Native in omo (OpenCode) / Standalone .md in Claude Code (`~/.claude/agents/metis.md`) |
| **When to use** | Before handing complex requirements to the planner agent |

### Atlas (standalone adaptation from omo)

| | |
|---|---|
| **Purpose** | Master task orchestrator |
| **Core** | Task-list delegation + 4-phase QA verification + completion tracking |
| **How it works** | Never writes code; delegates to specialist agents via 6-section prompts; runs independent tasks in parallel |
| **Availability** | Native in omo (OpenCode) / Standalone .md in Claude Code (`~/.claude/agents/atlas.md`) |
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
| Sisyphus | Master orchestrator | Unique |
| Sisyphus-Junior | Lite orchestrator | Unique |
| Prometheus | Detailed planning | Overlaps: planner |
| Metis | Intent analysis | Unique (standalone .md available) |
| Momus | Review + anti-slop | Overlaps: code-reviewer |
| Oracle | Deep consulting | Unique |
| Atlas | Task management | Unique (standalone .md available) |
| Hephaestus | Autonomous execution | Unique |
| Librarian | Doc search | Complementary: document-specialist |
| Explore | Navigation | Overlaps: explore |
| Multimodal-Looker | Visual analysis | Unique |

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
│   ├── atlas.md           # (omo standalone) Task orchestrator
│   ├── metis.md           # (omo standalone) Intent analyst
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
