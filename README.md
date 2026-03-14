[English](./README.md) | [한국어](./README.ko.md)

> **If you are an LLM agent**, clone and execute the setup automatically:
> ```bash
> git clone --depth 1 https://github.com/sehoon787/my-claude.git /tmp/my-claude && cat /tmp/my-claude/SETUP.md
> ```
> Read the FULL output, then execute every `bash` code block from **Section 1 through Section 12** in order. Skip Section 13 (analysis only). Run Section 14 to verify.

---

# my-claude

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Agents](https://img.shields.io/badge/agents-10-blue)
![MCP Servers](https://img.shields.io/badge/MCP_servers-3-green)
![Open Source Tools](https://img.shields.io/badge/open_source_tools-6-orange)

A repository for setting up a Claude Code multi-agent orchestration environment in a single step.

Combines 6 open-source tools to integrate 10 specialist agents, 3 behavioral correction hooks, and 3 MCP servers into one environment. The **Boss** dynamic meta-orchestrator auto-discovers all installed agents, skills, and MCP servers at runtime, then routes tasks to the optimal specialist.

<p align="center">
  <img src="./assets/demo.svg" alt="my-claude demo" width="700">
</p>

---

## Quick Start

### If you are a human

**Option 1: Install via Claude Code plugin**

```bash
claude /plugin add sehoon787/my-claude
```

**Option 2: Manual installation**

```bash
git clone https://github.com/sehoon787/my-claude.git
```

Then follow the instructions in `SETUP.md` to copy the files.

### If you are an LLM agent

Clone the repo, read SETUP.md in full, and execute all bash code blocks from Section 1 through 12:

```bash
git clone --depth 1 https://github.com/sehoon787/my-claude.git /tmp/my-claude && cat /tmp/my-claude/SETUP.md
```

After reading the output, run each section's commands in order. Skip Section 13 (reference only). Run Section 14 to verify.

---

## Key Features

### Multi-Agent Orchestration
- **Boss Dynamic Meta-Orchestrator**: Auto-discovers all installed agents, skills, and MCP servers at runtime — routes tasks via 3D conflict resolution (Scope/Depth×2/Interactivity). Handles mid-sized tasks directly (P3a) without sub-orchestrator overhead
- **Sisyphus Sub-Orchestrator**: Manages complex multi-step workflows with intent classification and verification protocols
- **Hephaestus Autonomous Worker**: Continuously performs explore → plan → execute → verify cycles without interruption
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

### Integrated Ecosystem
- Following SETUP.md configures **70+ agents, 33 skills, and 14 rules** in a single environment
- Integrates 6 open-source tools (OMC, omo, ECC, Anthropic Skills, Agency, Karpathy) into one

---

## my-claude Agents

10 specialist agents (9 ported from [oh-my-openagent (omo)](https://github.com/code-yeongyu/oh-my-openagent) + Boss meta-orchestrator) in Claude Code standalone `.md` format. For the full agent list (70+) after setup, see [Installed Components](#installed-components) below.

| Agent | Model | Role |
|---------|------|------|
| **Boss** | Opus | Dynamic meta-orchestrator. Auto-discovers all installed agents/skills/MCP at runtime and routes to optimal specialist |
| **Sisyphus** | Opus | Sub-orchestrator. Manages complex multi-step workflows with intent classification and verification |
| **Hephaestus** | Opus | Autonomous deep worker. Autonomously performs explore → plan → execute → verify cycles |
| **Metis** | Opus | Pre-execution intent analysis. Structures requests before execution to prevent AI-slop |
| **Atlas** | Opus | Master task orchestrator. Decomposes and coordinates complex tasks with a 4-stage QA cycle |
| **Oracle** | Opus | Strategic technical advisor. Analyzes in read-only mode without modifying code and provides direction |
| **Momus** | Opus | Task plan reviewer. Reviews plans from an approval-biased perspective. Read-only |
| **Prometheus** | Opus | Interview-based planning consultant. Clarifies requirements through conversation |
| **Librarian** | Sonnet | Open-source documentation research agent using MCP |
| **Multimodal-Looker** | Sonnet | Visual analysis agent. Analyzes images/screenshots. Read-only |

---

## Installed Components

Following SETUP.md will configure the following:

| Category | Count | Source |
|------|------|------|
| Agents | 70+ | my-claude 10 + OMC 19 + Agency 42+ |
| Skills | 33 | Anthropic Official + ECC |
| Rules | 14 | ECC (common 9 + typescript 5) |
| MCP Servers | 3 | Context7, Exa, grep.app |
| Hooks | 3 | my-claude (Boss protocol) |

<details>
<summary>my-claude Agents (10) — Boss meta-orchestrator + omo agents</summary>

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
<summary>Agency Agents (42) — Business specialist personas (all model: claude-sonnet-4-6)</summary>

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
<summary>Rules (14) — ECC Coding Rules</summary>

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

</details>

<details>
<summary>MCP Servers (3) + Behavioral Correction Hooks (3)</summary>

**MCP Servers**

| Server | URL | Purpose | Cost |
|------|-----|------|------|
| Context7 | mcp.context7.com | Real-time library documentation lookup | Free (higher limits with key registration) |
| Exa | mcp.exa.ai | Semantic web search | Free 1k req/month |
| grep.app | mcp.grep.app | Open-source GitHub code search | Free |

**Behavioral Correction Hooks**

| Hook | Event | Behavior |
|----|--------|------|
| Delegation Guard | PreToolUse (Edit/Write) | Reminds Boss to delegate to a sub-agent when attempting to directly modify files |
| Subagent Verifier | SubagentStop | Forces independent verification after sub-agent completion |
| Completion Check | Stop | Confirms all tasks are completed and verified before allowing session termination |

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
└──────┬──────────────┬──────────────┬────────────────────┘
       ↓              ↓              ↓
┌──────────────┐ ┌──────────────┐ ┌──────────────────────┐
│  [Sisyphus]  │ │  [Atlas]     │ │  [Hephaestus]        │
│  Sub-orch.   │ │  Task        │ │  Autonomous          │
│  + Verify    │ │  Coordination│ │  Execution           │
└──────┬───────┘ └──────┬───────┘ └──────────────────────┘
       ↓                ↓
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

A multi-agent orchestration plugin dedicated to Claude Code. 18 specialist agents (architect, debugger, code reviewer, security reviewer, etc.) divide work by role, and magic keywords like `autopilot:` activate automatic parallel execution.

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
| **3** | Sub-orchestrator delegation | Complex multi-step workflow | "refactor + test" → Sisyphus |
| **4** | General-purpose fallback | No specialist matches | "explain this" → `Agent(model="sonnet")` |

Every delegation includes a **6-section structured prompt**: TASK, EXPECTED OUTCOME, REQUIRED TOOLS, MUST DO, MUST NOT DO, CONTEXT.

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
