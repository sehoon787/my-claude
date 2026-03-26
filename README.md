[English](./README.md) | [한국어](./docs/i18n/README.ko.md) | [日本語](./docs/i18n/README.ja.md) | [中文](./docs/i18n/README.zh.md) | [Deutsch](./docs/i18n/README.de.md) | [Français](./docs/i18n/README.fr.md)

> [![Codex CLI](https://img.shields.io/badge/Codex_CLI-my--codex-10b981?style=flat-square&logo=openai&logoColor=white)](https://github.com/sehoon787/my-codex) Looking for Codex CLI? → **my-codex** — same agents in native TOML format for OpenAI Codex CLI

> **If you are an LLM agent**, fetch and follow the installation guide:
> ```bash
> curl -s https://raw.githubusercontent.com/sehoon787/my-claude/main/AI-INSTALL.md
> ```
> Read the FULL output, then execute each step in order. Use `curl`, NOT `WebFetch` (summaries lose critical config values).

---

# my-claude

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Agents](https://img.shields.io/badge/agents-202-blue)
![Skills](https://img.shields.io/badge/skills-184-purple)
![Rules](https://img.shields.io/badge/rules-65-orange)
![MCP Servers](https://img.shields.io/badge/MCP-3-green)
![Hooks](https://img.shields.io/badge/hooks-6-red)
![Auto Sync](https://img.shields.io/badge/upstream_sync-weekly-brightgreen)

All-in-one agent harness for Claude Code — one plugin, 202 agents ready.

**Boss** auto-discovers every agent, skill, and MCP tool at runtime, then routes your task to the right specialist. Four MIT upstream repos bundled and synced weekly via CI.

<p align="center">
  <img src="./assets/demo.svg" alt="my-claude demo" width="700">
</p>

---

## Core Principles

| Principle | Description |
|-----------|-------------|
| **Leadership** | Boss orchestrates, never implements. Leads teams with peer-to-peer communication, dynamic composition, and file ownership protocols |
| **Discovery** | Runtime capability matching — no hardcoded routing tables. Every agent, skill, and MCP server is auto-discovered at session start |
| **Verification** | Trust but verify. Every subagent result is independently checked before acceptance |

## Quick Start

### If you are a human

**Option 1: Install via Claude Code plugin**

```bash
# Inside a Claude Code session:
/plugin marketplace add sehoon787/my-claude
/plugin install my-claude@my-claude
```

Then install companion tools (npm packages + Anthropic skills):

```bash
git clone --depth 1 https://github.com/sehoon787/my-claude.git /tmp/my-claude
bash /tmp/my-claude/install.sh
rm -rf /tmp/my-claude
```

**Option 2: Automated script**

```bash
git clone --depth 1 https://github.com/sehoon787/my-claude.git /tmp/my-claude && bash /tmp/my-claude/install.sh && rm -rf /tmp/my-claude
```

> **Note**: `install.sh` automatically sets Boss as the default agent. For plugin install (Option 1), run the setup command in [AI-INSTALL.md](AI-INSTALL.md).
>
> **Agent Packs**: Domain specialist agents (marketing, sales, gamedev, etc.) are installed to `~/.claude/agent-packs/` and can be activated by symlinking to `~/.claude/agents/` when needed.

**Option 3: Manual installation**

```bash
git clone https://github.com/sehoon787/my-claude.git
```

Then follow the instructions in `SETUP.md` to copy the files.

**Option 4: Skills only (via skills.sh)**

```bash
npx skills add sehoon787/my-claude -y -g
```

Installs skills to `~/.agents/skills/` and auto-symlinks to `~/.claude/skills/`. Works with Claude Code, Codex, Cursor, and other tools that support the skills.sh standard. Does **not** install agents, rules, hooks, or MCP configs — use Option 1 or 2 for the full experience.

### If you are an LLM agent

Fetch the AI installation guide and execute each step:

```bash
curl -s https://raw.githubusercontent.com/sehoon787/my-claude/main/AI-INSTALL.md
```

Read the full output and execute each step in order. Use `curl`, not `WebFetch`. For human-readable step-by-step setup, see `SETUP.md`.

---

## Key Features

### Multi-Agent Orchestration
- **Boss Dynamic Meta-Orchestrator**: Auto-discovers all installed agents, skills, and MCP servers at runtime — routes tasks via 3D conflict resolution (Scope/Depth×2/Interactivity). Handles mid-sized tasks directly (P3a) without sub-orchestrator overhead
- **Agent Teams Direct Leadership**: Boss can lead Agent Teams directly (Priority 3c-DIRECT) with peer-to-peer teammate communication, file ownership protocol, and Review Chain patterns for quality assurance
- **Sub-Orchestrators (P3b)**: When tasks are too complex for direct handling, Boss delegates to Sisyphus (planning+verification), Atlas (task coordination), or Hephaestus (autonomous execution) — only for complex multi-step workflows, not every request
- **Skill vs Agent Conflict Resolution**: Weighted 3-dimensional scoring (Scope, Depth×2, Interactivity) determines whether to use a Skill or Agent for each task — no hardcoded routing tables
- **Model-Optimized Routing**: Automatically selects Opus (high complexity) / Sonnet (implementation) / Haiku (exploration) based on task complexity

### Runtime Behavioral Correction
- **Delegation Guard** (PreToolUse): Forces sub-agent delegation when the orchestrator attempts to directly modify files
- **Subagent Verifier** (SubagentStop): Forces independent verification after a sub-agent completes its work
- **Completion Check** (Stop): Confirms all tasks are completed and verified before allowing the session to end

### External Knowledge Integration (MCP)
- **Context7**: Retrieves official library documentation in real time
- **Exa**: Semantic web search (1,000 free requests per month)
- **grep.app**: GitHub open-source code search

### All-in-One Bundle
- Plugin install provides **202 agents, 184 skills, and 65 rules** instantly
- Bundles 4 MIT upstream sources (agency-agents, everything-claude-code, oh-my-claudecode, gstack)
- Weekly CI auto-sync keeps bundled content up-to-date with upstream
- Companion `install.sh` adds npm tools and proprietary Anthropic skills

---

## Core + OMO Agents

**Boss** is the only my-claude original agent. The remaining 9 are [OMO agents](https://github.com/code-yeongyu/oh-my-openagent) that Boss uses as sub-orchestrators and specialists. The plugin bundles **52 core agents** (Core 1 + OMO 9 + Engineering 23 + OMC 19 + OMO specialists) always loaded into `~/.claude/agents/`, plus **133 domain agent-packs** in `~/.claude/agent-packs/` that can be activated on demand. Boss selects the best-matching specialist from all active agents via Priority 2 capability matching. See [Installed Components](#installed-components) below.

| Agent | Source | Model | Role |
|---------|--------|------|------|
| **Boss** | my-claude | Opus | Dynamic meta-orchestrator. Auto-discovers all installed agents/skills/MCP at runtime and routes to optimal specialist |
| **Sisyphus** | OMO | Opus | Sub-orchestrator. Manages complex multi-step workflows with intent classification and verification |
| **Hephaestus** | OMO | Opus | Autonomous deep worker. Autonomously performs explore → plan → execute → verify cycles |
| **Metis** | OMO | Opus | Pre-execution intent analysis. Structures requests before execution to prevent AI-slop |
| **Atlas** | OMO | Opus | Master task orchestrator. Decomposes and coordinates complex tasks with a 4-stage QA cycle |
| **Oracle** | OMO | Opus | Strategic technical advisor. Analyzes in read-only mode without modifying code and provides direction |
| **Momus** | OMO | Opus | Task plan reviewer. Reviews plans from an approval-biased perspective. Read-only |
| **Prometheus** | OMO | Opus | Interview-based planning consultant. Clarifies requirements through conversation |
| **Librarian** | OMO | Sonnet | Open-source documentation research agent using MCP |
| **Multimodal-Looker** | OMO | Sonnet | Visual analysis agent. Analyzes images/screenshots. Read-only |

---

## Agent Packs (Domain Specialists)

Domain specialist agents are installed to `~/.claude/agent-packs/` and are **not** loaded by default. Activate a pack by symlinking it into `~/.claude/agents/`:

```bash
# Activate a single pack
ln -s ~/.claude/agent-packs/marketing/*.md ~/.claude/agents/

# Deactivate
rm ~/.claude/agents/<agent-name>.md
```

| Pack | Count | Examples |
|------|-------|---------|
| marketing | 27 | Douyin, Xiaohongshu, WeChat OA, TikTok |
| gamedev | 19 | Unity, Unreal, Godot, Roblox |
| engineering-domain | 8 | Mobile, Solidity, Embedded, Feishu |
| sales | 9 | SDR, Account Executive, Revenue Ops |
| specialized | 10+ | Legal, Finance, Healthcare, Education |
| design | 8 | Brand, UI, UX, Visual Storytelling |
| testing | 8 | API, Accessibility, Performance, E2E |
| product | 5 | Sprint, Feedback, Trend Research |
| paid-media | 7 | Google Ads, Meta Ads, Programmatic |
| project-mgmt | 5 | Scrum, Kanban, Risk Management |
| academic | 5 | Research, Literature Review, Citation |
| support | 6 | Customer Success, Escalation, Triage |
| spatial-computing | 3 | ARKit, visionOS, Spatial Audio |

---

## Installed Components

Following SETUP.md will configure the following:

| Category | Count | Source | Bundled |
|------|------|------|------|
| Core Agents | 52 | Core 1 + OMO 9 + Engineering 23 + OMC 19 | Plugin |
| Agent Packs | 133 | 12 domain categories (marketing, gamedev, sales, etc.) | Plugin |
| Skills | 184 | ECC 118 + OMC 31 + Core 1 + gstack 27 (runtime) | Plugin + install.sh |
| Rules | 65 | ECC (common 9 + 8 languages × 5) | Plugin |
| MCP Servers | 3 | Context7, Exa, grep.app | Plugin |
| Hooks | 6 | my-claude (Boss protocol + SessionStart) | Plugin |
| Anthropic Skills | 14+ | Anthropic Official | install.sh |
| CLI Tools | 3 | omc, omo, ast-grep | install.sh |

<details>
<summary>Core + OMO Agents (10) — Boss meta-orchestrator + omo agents</summary>

| Agent | Model | Type | Role | Read-only |
|---------|------|------|------|-----------|
| Boss | Opus | Meta-orchestrator | Dynamic runtime discovery of all agents/skills/MCP → capability matching → optimal routing | Yes |
| Sisyphus | Opus | Sub-orchestrator | Intent classification → specialist agent delegation → independent verification. Does not write code directly | No |
| Hephaestus | Opus | Autonomous execution | Autonomously performs explore → plan → execute → verify. Completes tasks without asking for permission | No |
| Metis | Opus | Analysis | User intent analysis, ambiguity detection, AI-slop prevention | Yes |
| Atlas | Opus | Orchestrator | Task delegation + 4-stage QA verification. Does not write code directly | No |
| Oracle | Opus | Advisory | Strategic technical consulting. Architecture and debugging consulting | Yes |
| Momus | Opus | Review | Reviews task plan feasibility. Approval bias | Yes |
| Prometheus | Opus | Planning | Interview-based detailed planning. Only writes .md files | Partial |
| Librarian | Sonnet | Research | Open-source documentation search using MCP | Yes |
| Multimodal-Looker | Sonnet | Visual analysis | Analyzes images/screenshots/diagrams | Yes |

</details>

<details>
<summary>OMC Agents (19) — Oh My Claude Code specialist agents</summary>

| Agent | Role |
|---------|------|
| analyst | Pre-analysis — understand the situation before planning |
| architect | System design and architecture decisions |
| code-reviewer | Focused code review |
| code-simplifier | Code simplification and cleanup |
| critic | Critical analysis, alternative proposals |
| debugger | Focused debugging |
| designer | UI/UX design guidance |
| document-specialist | Documentation writing and management |
| executor | Task execution |
| explore | Codebase exploration |
| git-master | Git workflow management |
| planner | Rapid planning |
| qa-tester | Quality assurance testing |
| scientist | Research and experimentation |
| security-reviewer | Security review |
| test-engineer | Test writing and maintenance |
| tracer | Execution tracing and analysis |
| verifier | Final verification |
| writer | Content and documentation writing |

</details>

<details>
<summary>Agency Agents (172) — Business specialist personas across 14 categories (all model: claude-sonnet-4-6)</summary>

**Engineering (22)**

| Agent | Role |
|---------|------|
| ai-engineer | AI/ML engineering |
| autonomous-optimization-architect | Autonomous optimization architecture |
| backend-architect | Backend architecture |
| code-reviewer | Code review |
| data-engineer | Data engineering |
| database-optimizer | Database optimization |
| devops-automator | DevOps automation |
| embedded-firmware-engineer | Embedded firmware |
| feishu-integration-developer | Feishu integration development |
| frontend-developer | Frontend development |
| git-workflow-master | Git workflow |
| incident-response-commander | Incident response |
| mobile-app-builder | Mobile app building |
| rapid-prototyper | Rapid prototyping |
| security-engineer | Security engineering |
| senior-developer | Senior development |
| software-architect | Software architecture |
| solidity-smart-contract-engineer | Solidity smart contracts |
| sre | Site Reliability Engineering |
| technical-writer | Technical documentation writing |
| threat-detection-engineer | Threat detection engineering |
| wechat-mini-program-developer | WeChat mini program development |

**Testing (8)**

| Agent | Role |
|---------|------|
| accessibility-auditor | Accessibility auditing |
| api-tester | API testing |
| evidence-collector | Test evidence collection |
| performance-benchmarker | Performance benchmarking |
| reality-checker | Reality verification |
| test-results-analyzer | Test results analysis |
| tool-evaluator | Tool evaluation |
| workflow-optimizer | Workflow optimization |

**Design (8)**

| Agent | Role |
|---------|------|
| brand-guardian | Brand guideline enforcement |
| image-prompt-engineer | Image prompt engineering |
| inclusive-visuals-specialist | Inclusive visual design |
| ui-designer | UI design |
| ux-architect | UX architecture |
| ux-researcher | UX research |
| visual-storyteller | Visual storytelling |
| whimsy-injector | Injecting fun and whimsy |

**Product (4)**

| Agent | Role |
|---------|------|
| behavioral-nudge-engine | Behavioral nudge design |
| feedback-synthesizer | Feedback synthesis |
| sprint-prioritizer | Sprint prioritization |
| trend-researcher | Trend research |

</details>

<details>
<summary>Skills (33) — Anthropic Official + ECC</summary>

| Skill | Source | Description |
|------|------|------|
| algorithmic-art | Anthropic | Generative art based on p5.js |
| backend-patterns | ECC | Backend architecture patterns |
| brand-guidelines | Anthropic | Applying Anthropic brand style |
| canvas-design | Anthropic | PNG/PDF visual design |
| claude-api | Anthropic | Building apps with the Claude API/SDK |
| clickhouse-io | ECC | ClickHouse query optimization |
| coding-standards | ECC | TypeScript/React coding standards |
| continuous-learning | ECC | Automatic pattern extraction from sessions |
| continuous-learning-v2 | ECC | Instinct-based learning system |
| doc-coauthoring | Anthropic | Document co-authoring workflow |
| docx | Anthropic | Word document creation/editing |
| eval-harness | ECC | Evaluation-driven development (EDD) |
| frontend-design | Anthropic | Frontend UI design |
| frontend-patterns | ECC | React/Next.js patterns |
| internal-comms | Anthropic | Internal communication writing |
| iterative-retrieval | ECC | Incremental context retrieval |
| karpathy-guidelines | Anthropic | Karpathy AI coding guidelines |
| learned | ECC | Learned pattern repository |
| mcp-builder | Anthropic | MCP server development guide |
| pdf | Anthropic | PDF reading/merging/splitting/OCR |
| postgres-patterns | ECC | PostgreSQL optimization |
| pptx | Anthropic | PowerPoint creation/editing |
| project-guidelines-example | Anthropic | Project guidelines example |
| security-review | ECC | Security checklist |
| skill-creator | Anthropic | Meta-skill for creating custom skills |
| slack-gif-creator | Anthropic | GIF creation for Slack |
| strategic-compact | ECC | Strategic context compression |
| tdd-workflow | ECC | TDD workflow enforcement |
| theme-factory | Anthropic | Applying themes to artifacts |
| verification-loop | Anthropic | Verification loop |
| web-artifacts-builder | Anthropic | Building composite web artifacts |
| webapp-testing | Anthropic | Playwright web app testing |
| xlsx | Anthropic | Excel file creation/editing |

</details>

<details>
<summary>Rules (65) — ECC Coding Rules</summary>

**Common (9)** — Applied to all projects

| Rule | Description |
|----|------|
| agents.md | Agent behavioral rules |
| coding-style.md | Coding style |
| development-workflow.md | Development workflow |
| git-workflow.md | Git workflow |
| hooks.md | Hook usage rules |
| patterns.md | Design patterns |
| performance.md | Performance optimization |
| security.md | Security rules |
| testing.md | Testing rules |

**TypeScript (5)** — TypeScript projects only

| Rule | Description |
|----|------|
| coding-style.md | TS coding style |
| hooks.md | TS hook patterns |
| patterns.md | TS design patterns |
| security.md | TS security rules |
| testing.md | TS testing rules |

**Other Languages (5 rules each)** — C++, Go, Kotlin, Perl, PHP, Python, Swift

Each language directory contains: coding-style.md, hooks.md, patterns.md, security.md, testing.md

</details>

<details>
<summary>MCP Servers (3) + Behavioral Correction Hooks (6)</summary>

**MCP Servers**

| Server | URL | Purpose | Cost |
|------|-----|------|------|
| Context7 | mcp.context7.com | Real-time library documentation lookup | Free (higher limits with key registration) |
| Exa | mcp.exa.ai | Semantic web search | Free 1k req/month |
| grep.app | mcp.grep.app | Open-source GitHub code search | Free |

**Behavioral Correction Hooks**

| Hook | Event | Behavior |
|----|--------|------|
| Session Setup | SessionStart | Auto-detects and installs missing companion tools (omc, omo, ast-grep, Anthropic skills) |
| Delegation Guard | PreToolUse (Edit/Write) | Reminds Boss to delegate to a sub-agent when attempting to directly modify files |
| Subagent Verifier | SubagentStop | Forces independent verification after sub-agent completion |
| Completion Check | Stop | Confirms all tasks are completed and verified before allowing session termination |
| Teammate Idle Guide | TeammateIdle | Reminds leader to check TaskList and send shutdown or next instructions when a teammate goes idle |
| Task Quality Gate | TaskCompleted | Reminds leader to verify deliverable exists and check quality before accepting completed tasks |

</details>

---

## Full Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    User Request                          │
└─────────────────────┬───────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────────┐
│  [Boss] Dynamic Meta-Orchestrator                       │
│  Runtime Discovery → Capability Matching → Routing      │
│  (agents, skills, MCP servers, hooks — all discovered)  │
└──┬──────────┬──────────┬──────────┬──────────┬──────────┘
   ↓          ↓          ↓          ↓          ↓
┌──────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐
│  P1  │ │   P2   │ │  P3a   │ │  P3b   │ │  P3c   │
│Skill │ │Special-│ │ Direct │ │Sub-orc-│ │ Agent  │
│Match │ │ist     │ │Parallel│ │hestrat-│ │ Teams  │
│      │ │Agent   │ │ (2-4)  │ │ors     │ │  P2P   │
│      │ │ (191)  │ │        │ │Sisyphus│ │        │
└──────┘ └────────┘ └────────┘ │ Atlas  │ └────────┘
                                │Hephaes-│
                                │ tus    │
                                └────────┘
┌─────────────────────────────────────────────────────────┐
│  Karpathy Guidelines (behavioral guidelines, always on) │
│  ECC Rules (language-specific coding rules, always on)  │
│  Hooks: PreToolUse / SubagentStop / Stop                │
└─────────────────────┬───────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────────┐
│  Specialist Agent Layer                                 │
│    ├── OMC Agents (executor, debugger, test-engineer)   │
│    ├── Agency Agents (UX architect, security auditor)   │
│    ├── ECC Commands (/tdd, /code-review, /build-fix)    │
│    └── Anthropic Skills (pdf, docx, mcp-builder)        │
└─────────────────────┬───────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────────┐
│  MCP Server Layer                                       │
│    ├── Context7 (real-time library documentation)       │
│    ├── Exa (semantic web search)                        │
│    └── grep.app (open-source code search)               │
└─────────────────────────────────────────────────────────┘

    ┌─────────────────────────────────────────────────────┐
    │ omo Bridge (when using OpenCode)                    │
    │  claude-code-agent-loader: loads ~/.claude/agents/*.md│
    │  claude-code-plugin-loader: loads CC plugins        │
    │  → Both OMC + omo agents available in OpenCode      │
    └─────────────────────────────────────────────────────┘
```

---

## Open-Source Tools Used

### 1. [Oh My Claude Code (OMC)](https://github.com/Yeachan-Heo/oh-my-claudecode)

An agent harness dedicated to Claude Code. 18 specialist agents (architect, debugger, code reviewer, security reviewer, etc.) divide work by role, and magic keywords like `autopilot:` activate automatic parallel execution.

### 2. [Oh My OpenAgent (omo)](https://github.com/code-yeongyu/oh-my-openagent)

A multi-platform agent harness. Bridges to the Claude Code ecosystem via `claude-code-agent-loader` and `claude-code-plugin-loader`. Automatically routes across 8 providers (Claude, GPT, Gemini, etc.) by category. The 9 agents in this repository are adaptations of omo agents in Claude Code standalone `.md` format.

### 3. [Andrej Karpathy Skills](https://github.com/forrestchang/andrej-karpathy-skills)

The 4 AI coding behavioral guidelines proposed by Andrej Karpathy (Think Before Coding, Simplicity First, Surgical Changes, Goal-Driven Execution). Included in CLAUDE.md and always active across all sessions.

### 4. [Everything Claude Code (ECC)](https://github.com/affaan-m/everything-claude-code)

A comprehensive framework providing 67 skills + 17 agents + 45 commands + language-specific rules. Automates repetitive development patterns with slash commands like `/tdd`, `/plan`, `/code-review`, and `/build-fix`.

### 5. [Anthropic Official Skills](https://github.com/anthropics/skills)

The official agent skills repository provided directly by Anthropic. Enables specialist tasks such as PDF parsing, Word/Excel/PowerPoint document manipulation, and MCP server creation.

### 6. [Agency Agents](https://github.com/msitarzewski/agency-agents)

A library of 164 business specialist agent personas. Provides specialist perspectives in business contexts beyond technical roles — UX architects, data engineers, security auditors, QA managers, and more.

---

## How Boss Works

### Harness vs Orchestrator vs Agent

| Concept | Role | Analogy | Examples |
|---------|------|---------|---------|
| **Harness** | Runtime platform that executes agents — manages lifecycle, tools, permissions | Operating System | Claude Code, omo |
| **Orchestrator** | Special agent that coordinates other agents — classifies intent, delegates, verifies. Never implements directly | Conductor | Boss, Sisyphus, Atlas |
| **Agent** | Execution unit that performs actual work in a specific domain — writes code, analyzes, reviews | Musician | debugger, executor, security-reviewer |

```
Harness (Claude Code)
 └─ Boss (Meta-Orchestrator)         — discovers all, routes optimally
     ├─ Skill invocation              — pdf, docx, tdd-workflow, etc.
     ├─ Direct agent delegation       — debugger, security-reviewer, etc.
     ├─ Sisyphus (Sub-Orchestrator)   — complex workflow management
     │   ├─ Metis → intent analysis
     │   ├─ Prometheus → planning
     │   └─ Hephaestus → autonomous execution
     └─ Atlas (Sub-Orchestrator)      — task decomposition + QA cycles
```

### Delegation Mechanism (4-Priority Routing)

Boss routes every request through a 4-level priority chain:

| Priority | Match Type | When | Example |
|----------|-----------|------|---------|
| **1** | Exact Skill match | Task maps to a self-contained skill | "merge PDFs" → `Skill("pdf")` |
| **2** | Specialist Agent match | Domain-specific agent exists | "security audit" → `Agent("Security Engineer")` |
| **3a** | Direct orchestration | 2-4 independent agents | "fix 3 bugs" → Boss parallel |
| **3b** | Sub-orchestrator delegation | Complex multi-step workflow | "refactor + test" → Sisyphus |
| **3c** | Agent Teams (direct leadership) | Peer-to-peer communication needed | "implement + review" → Review Chain |
| **4** | General-purpose fallback | No specialist matches | "explain this" → `Agent(model="sonnet")` |

Every delegation includes a **6-section structured prompt**: TASK, EXPECTED OUTCOME, REQUIRED TOOLS, MUST DO, MUST NOT DO, CONTEXT.

### Delegation Examples

#### Subagent vs Agent Teams

| | Subagent (P2/P3a/P3b) | Agent Teams (P3c) |
|---|---|---|
| **Command** | `Agent(prompt="...")` | `SendMessage(to: "agent", ...)` |
| **Communication** | Boss → Agent → Boss | Boss ↔ Agent ↔ Agent |
| **Lifetime** | Ends on completion | Persists until TeamDelete |
| **Visibility** | Boss log only | tmux pane or Shift+↓ |
| **Cost** | Low | High (separate Claude session per teammate) |

**P2 — Single Specialist Agent:**
```
$ claude "analyze auth module for security vulnerabilities"

[Boss] Phase 0: Scanning... 202 agents, 184 skills ready.
[Boss] Phase 1: Intent → Security Analysis | Priority: P2
[Boss] Phase 2: Matched → security-reviewer (sonnet)
[Boss] Agent(description="security review", model="sonnet", prompt="
  TASK: Analyze src/auth/ for OWASP Top 10 vulnerabilities.
  MUST DO: Check SQL injection, XSS, CSRF.
  MUST NOT: Modify any files.
")
       ↓ result returned
[Boss] Phase 4: Reading report... 2 critical, 1 medium confirmed. ✓
```

**P3a — Boss Direct Parallel:**
```
$ claude "refactor auth and write tests"

[Boss] Phase 1: Multi-step → P3a Direct Orchestration
[Boss] Spawning 2 agents in parallel:
  Agent(description="executor refactoring", model="sonnet", run_in_background=true)
  Agent(description="test-engineer tests", model="sonnet", run_in_background=true)
       ↓ both results returned
[Boss] Phase 4: Verifying refactored files... ✓
[Boss] Phase 4: Running tests... 12/12 passed. ✓
```

**P3c — Agent Teams:**
```
$ claude "implement payment module with review"

[Boss] Phase 1: Needs inter-agent communication → P3c Agent Teams
[Boss] TeamCreate → 2 teammates spawned (tmux split-pane)
[Boss] TaskCreate("Implement payment", assignee="executor")
[Boss] TaskCreate("Review payment", assignee="code-reviewer")
[Boss] SendMessage(to: "executor", "Implement src/payment/ using Stripe SDK")

  ┌─ executor (tmux pane 1) ──────────────────┐
  │ Working on src/payment/...                  │
  │ SendMessage(to: "code-reviewer",            │
  │   "Implementation done, review src/payment/")│
  └─────────────────────────────────────────────┘
  ┌─ code-reviewer (tmux pane 2) ─────────────┐
  │ Reviewing src/payment/checkout.ts...        │
  │ SendMessage(to: "executor",                 │
  │   "Line 42: missing error handling")        │
  └─────────────────────────────────────────────┘
  ┌─ executor ──────────────────────────────────┐
  │ Fixed. TaskUpdate(status: "completed")      │
  └─────────────────────────────────────────────┘

[Boss] All tasks completed → TeamDelete
```

For detailed agent compatibility matrix and team communication patterns, see [Agent Teams Reference](agents/core/agent-teams-reference.md).

### Scope Discovery (Global + Project)

Boss discovers components from **two scopes** that merge at runtime:

| Scope | Agents | Skills | MCP Servers |
|-------|--------|--------|-------------|
| **Global** | `~/.claude/agents/*.md` | `~/.claude/skills/` | `~/.claude/settings.json` |
| **Project** | `.claude/agents/*.md` | `.claude/skills/` | `.mcp.json` |

When running `claude` in a project directory, Boss sees both global and project-level components. Project-level agents with the same name as global ones take priority (project-specific customization).

---

## Agent Overlap Guide

OMC and omo have agent pairs with overlapping functionality. Keep both and choose based on the situation.

| Function | OMC | omo | Selection Criteria |
|------|-----|-----|-----------|
| Planning | planner | Prometheus | Quick tasks → OMC planner, complex projects → omo Triad (Metis → Prometheus → Momus) |
| Code Review | code-reviewer | Momus | OMC: focused review, omo: includes AI-slop detection |
| Exploration | explore | Explore | Use whichever belongs to the current platform |

**omo-exclusive agents (6):** Sisyphus, Sisyphus-Junior, Hephaestus, Oracle, Multimodal-Looker, Librarian

**OMC-exclusive agents (14):** analyst, architect, code-simplifier, critic, debugger, designer, document-specialist, executor, git-master, qa-tester, scientist, test-engineer, verifier, writer

For a detailed analysis, see the [Agent Overlap Analysis in SETUP.md](./SETUP.md#11-agent-overlap-analysis-omc-vs-omo).

---

## Contributing

Issues and PRs are welcome. When adding a new agent, add a `.md` file to the `agents/` directory and update the agent list in `SETUP.md`.

---

## Bundled Upstream Versions

Updated weekly by [CI auto-sync](.github/workflows/sync-upstream.yml). See `upstream/SOURCES.json` for exact SHAs.

| Source | Synced SHA | Tag | Date | Diff |
|--------|-----------|-----|------|------|
| [agency-agents](https://github.com/msitarzewski/agency-agents) | `6254154` | — | 2026-03-18 | [compare](https://github.com/msitarzewski/agency-agents/compare/6254154...HEAD) |
| [everything-claude-code](https://github.com/affaan-m/everything-claude-code) | `fce4513` | — | 2026-03-18 | [compare](https://github.com/affaan-m/everything-claude-code/compare/fce4513...HEAD) |
| [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) | `7d07356` | v4.8.2 | 2026-03-18 | [compare](https://github.com/Yeachan-Heo/oh-my-claudecode/compare/7d07356...HEAD) |

---

## Credits

This repository builds on the work of the following open-source projects:

- [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) — Yeachan Heo
- [oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent) — code-yeongyu
- [andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills) — forrestchang
- [everything-claude-code](https://github.com/affaan-m/everything-claude-code) — affaan-m
- [anthropic/skills](https://github.com/anthropics/skills) — Anthropic
- [agency-agents](https://github.com/msitarzewski/agency-agents) — msitarzewski

---

## License

MIT License. See the [LICENSE](./LICENSE) file for details.
