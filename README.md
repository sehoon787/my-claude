[English](./README.md) | [한국어](./docs/i18n/README.ko.md) | [日本語](./docs/i18n/README.ja.md) | [中文](./docs/i18n/README.zh.md) | [Deutsch](./docs/i18n/README.de.md) | [Français](./docs/i18n/README.fr.md)

> [![Codex CLI](https://img.shields.io/badge/Codex_CLI-my--codex-10b981?style=flat-square&logo=openai&logoColor=white)](https://github.com/sehoon787/my-codex) Looking for Codex CLI? → **my-codex** — same orchestration in native TOML format

---

<div align="center">

# my-claude

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Agents](https://img.shields.io/badge/agents-200%2B-blue)
![Skills](https://img.shields.io/badge/skills-200%2B-purple)
![Rules](https://img.shields.io/badge/rules-87-orange)
![MCP Servers](https://img.shields.io/badge/MCP-3-green)
![Hooks](https://img.shields.io/badge/hooks-7-red)

**All-in-one agent harness for Claude Code.**
**One plugin, 200+ agents ready.**

Boss auto-discovers every agent, skill, and MCP tool at runtime,<br>
then routes your task to the right specialist. No config files. No boilerplate.

<img src="./logo/owl-claude.svg" alt="The Maestro Owl — my-claude" width="500">

</div>

---

## Installation

### For Humans

```bash
git clone --depth 1 https://github.com/sehoon787/my-claude.git /tmp/my-claude
bash /tmp/my-claude/install.sh
rm -rf /tmp/my-claude
```

Or install as a Claude Code plugin first, then run the companion installer:

```bash
# Inside a Claude Code session:
/plugin marketplace add sehoon787/my-claude
/plugin install my-claude@my-claude

# Then install companion tools:
git clone --depth 1 https://github.com/sehoon787/my-claude.git /tmp/my-claude
bash /tmp/my-claude/install.sh
rm -rf /tmp/my-claude
```

### For AI Agents

```bash
curl -s https://raw.githubusercontent.com/sehoon787/my-claude/main/AI-INSTALL.md
```

Read the FULL output, then execute each step in order. Use `curl`, NOT `WebFetch`.

---

## How Boss Works

Boss is the meta-orchestrator at the core of my-claude. It never writes code — it discovers, classifies, matches, delegates, and verifies.

```
User Request
     │
     ▼
┌─────────────────────────────────────────────┐
│  Phase 0 · DISCOVERY                        │
│  Scan agents, skills, MCP, hooks at runtime │
│  → Build live capability registry           │
└──────────────────────┬──────────────────────┘
                       ▼
┌─────────────────────────────────────────────┐
│  Phase 1 · INTENT GATE                      │
│  Classify: trivial | build | refactor |     │
│  mid-sized | architecture | research | ...  │
│  → Counter-propose skill if better fit      │
└──────────────────────┬──────────────────────┘
                       ▼
┌─────────────────────────────────────────────┐
│  Phase 2 · CAPABILITY MATCHING              │
│  P0: gstack skill (if installed)            │
│  P1: Exact skill match                      │
│  P2: Specialist agent (200+)               │
│  P3: Multi-agent orchestration              │
│  P4: General-purpose fallback               │
└──────────────────────┬──────────────────────┘
                       ▼
┌─────────────────────────────────────────────┐
│  Phase 3 · DELEGATION                       │
│  6-section structured prompt to specialist  │
│  TASK / OUTCOME / TOOLS / DO / DON'T / CTX  │
└──────────────────────┬──────────────────────┘
                       ▼
┌─────────────────────────────────────────────┐
│  Phase 4 · VERIFICATION                     │
│  Read changed files independently           │
│  Run tests, lint, build                     │
│  Cross-reference with original intent       │
│  → Retry up to 3× on failure               │
└─────────────────────────────────────────────┘
```

### Priority Routing

Boss cascades every request through a priority chain until the best match is found:

| Priority | Match Type | When | Example |
|:--------:|-----------|------|---------|
| **P1** | Skill match | Task maps to a self-contained skill | `"merge PDFs"` → pdf skill |
| **P2** | Specialist agent | Domain-specific agent exists | `"security audit"` → Security Engineer |
| **P3a** | Boss direct | 2-4 independent agents | `"fix 3 bugs"` → parallel spawn |
| **P3b** | Sub-orchestrator | Complex multi-step workflow | `"refactor + test"` → Sisyphus |
| **P3c** | Agent Teams | Peer-to-peer communication needed | `"implement + review"` → Review Chain |
| **P4** | Fallback | No specialist matches | `"explain this"` → general agent |

### Model Routing

| Complexity | Model | Used For |
|-----------|-------|----------|
| Deep analysis, architecture | Opus | Boss, Oracle, Sisyphus |
| Standard implementation | Sonnet | executor, debugger, security-reviewer |
| Quick lookup, exploration | Haiku | explore, simple advisory |

### 3-Phase Sprint Workflow

For end-to-end feature implementation, Boss orchestrates a structured sprint:

```
Phase 1: DESIGN         Phase 2: EXECUTE        Phase 3: REVIEW
(interactive)            (autonomous)             (interactive)
─────────────────────   ─────────────────────   ─────────────────────
User decides scope      ralph runs execution    Compare vs design doc
Engineering review      Auto code review        Present comparison table
Confirm "design done"   Architect verification  User: approve / improve
```

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                    User Request                       │
└───────────────────────┬─────────────────────────────┘
                        ▼
┌─────────────────────────────────────────────────────┐
│  Boss · Meta-Orchestrator (Opus)                      │
│  Discovery → Classification → Matching → Delegation  │
└──┬──────────┬──────────┬──────────┬─────────────────┘
   │          │          │          │
   ▼          ▼          ▼          ▼
┌──────┐ ┌────────┐ ┌────────┐ ┌────────┐
│ P3a  │ │  P3b   │ │  P3c   │ │  P1/P2 │
│Direct│ │Sub-orch│ │ Agent  │ │ Skill/ │
│2-4   │ │Sisyphus│ │ Teams  │ │ Agent  │
│agents│ │Atlas   │ │  P2P   │ │ Direct │
└──────┘ │Hephaes│ └────────┘ └────────┘
         └────────┘
┌─────────────────────────────────────────────────────┐
│  Behavioral Layer                                     │
│  Karpathy Guidelines · ECC Rules (87) · Hooks (7)    │
├─────────────────────────────────────────────────────┤
│  Specialist Agents (200+)                             │
│  OMO 9 · OMC 19 · Agency Eng. 26 · Superpowers 1    │
│  + 136 domain packs (on-demand)                       │
├─────────────────────────────────────────────────────┤
│  Skills (200+)                                        │
│  ECC 180+ · OMC 36 · gstack 40 · Superpowers 14     │
│  + Core 3 · Anthropic 14+                             │
├─────────────────────────────────────────────────────┤
│  MCP Layer                                            │
│  Context7 · Exa · grep.app                            │
└─────────────────────────────────────────────────────┘
```

---

## What's Inside

| Category | Count | Source |
|----------|------:|--------|
| **Core agents** (always loaded) | 56 | Boss 1 + OMO 9 + OMC 19 + Agency Engineering 26 + Superpowers 1 |
| **Agent packs** (on-demand) | 136 | 12 domain categories from agency-agents |
| **Skills** | 200+ | ECC 180+ · OMC 36 · gstack 40 · Superpowers 14 · Core 3 |
| **Anthropic Skills** | 14+ | PDF, DOCX, PPTX, XLSX, MCP builder |
| **Rules** | 87 | ECC common + 14 language directories |
| **MCP Servers** | 3 | Context7, Exa, grep.app |
| **Hooks** | 7 | Delegation guard, telemetry, verification |
| **CLI Tools** | 3 | omc, omo, ast-grep |

<details>
<summary><strong>Core Agent — Boss meta-orchestrator (1)</strong></summary>

| Agent | Model | Role | Source |
|-------|-------|------|--------|
| Boss | Opus | Dynamic runtime discovery → capability matching → optimal routing. Never writes code. | my-claude |

</details>

<details>
<summary><strong>OMO Agents — Sub-orchestrators and specialists (9)</strong></summary>

| Agent | Model | Role | Source |
|-------|-------|------|--------|
| Sisyphus | Opus | Intent classification → specialist delegation → verification | [oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent) |
| Hephaestus | Opus | Autonomous explore → plan → execute → verify | oh-my-openagent |
| Atlas | Opus | Task decomposition + 4-stage QA verification | oh-my-openagent |
| Oracle | Opus | Strategic technical consulting (read-only) | oh-my-openagent |
| Metis | Opus | Intent analysis, ambiguity detection | oh-my-openagent |
| Momus | Opus | Plan feasibility review | oh-my-openagent |
| Prometheus | Opus | Interview-based detailed planning | oh-my-openagent |
| Librarian | Sonnet | Open-source documentation search via MCP | oh-my-openagent |
| Multimodal-Looker | Sonnet | Image/screenshot/diagram analysis | oh-my-openagent |

</details>

<details>
<summary><strong>OMC Agents — Specialist workers (19)</strong></summary>

| Agent | Role | Source |
|-------|------|--------|
| analyst | Pre-analysis before planning | [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) |
| architect | System design and architecture | oh-my-claudecode |
| code-reviewer | Focused code review | oh-my-claudecode |
| code-simplifier | Code simplification and cleanup | oh-my-claudecode |
| critic | Critical analysis, alternative proposals | oh-my-claudecode |
| debugger | Focused debugging | oh-my-claudecode |
| designer | UI/UX design guidance | oh-my-claudecode |
| document-specialist | Documentation writing | oh-my-claudecode |
| executor | Task execution | oh-my-claudecode |
| explore | Codebase exploration | oh-my-claudecode |
| git-master | Git workflow management | oh-my-claudecode |
| planner | Rapid planning | oh-my-claudecode |
| qa-tester | Quality assurance testing | oh-my-claudecode |
| scientist | Research and experimentation | oh-my-claudecode |
| security-reviewer | Security review | oh-my-claudecode |
| test-engineer | Test writing and maintenance | oh-my-claudecode |
| tracer | Execution tracing and analysis | oh-my-claudecode |
| verifier | Final verification | oh-my-claudecode |
| writer | Content and documentation | oh-my-claudecode |

</details>

<details>
<summary><strong>Agency Engineering — Always-loaded specialists (26)</strong></summary>

| Agent | Role | Source |
|-------|------|--------|
| AI Engineer | AI/ML engineering | [agency-agents](https://github.com/msitarzewski/agency-agents) |
| Backend Architect | Backend architecture | agency-agents |
| CMS Developer | CMS development | agency-agents |
| Code Reviewer | Code review | agency-agents |
| Data Engineer | Data engineering | agency-agents |
| Database Optimizer | Database optimization | agency-agents |
| DevOps Automator | DevOps automation | agency-agents |
| Embedded Firmware Engineer | Embedded firmware | agency-agents |
| Frontend Developer | Frontend development | agency-agents |
| Git Workflow Master | Git workflow | agency-agents |
| Incident Response Commander | Incident response | agency-agents |
| Mobile App Builder | Mobile apps | agency-agents |
| Rapid Prototyper | Rapid prototyping | agency-agents |
| Security Engineer | Security engineering | agency-agents |
| Senior Developer | Senior development | agency-agents |
| Software Architect | Software architecture | agency-agents |
| SRE | Site reliability | agency-agents |
| Technical Writer | Technical docs | agency-agents |
| AI Data Remediation Engineer | Self-healing data pipelines | agency-agents |
| Autonomous Optimization Architect | API performance governance | agency-agents |
| Email Intelligence Engineer | Email data extraction | agency-agents |
| Feishu Integration Developer | Feishu/Lark platform | agency-agents |
| Filament Optimization Specialist | Filament PHP optimization | agency-agents |
| Solidity Smart Contract Engineer | EVM smart contracts | agency-agents |
| Threat Detection Engineer | SIEM & threat hunting | agency-agents |
| WeChat Mini Program Developer | WeChat 小程序 | agency-agents |

</details>

<details>
<summary><strong>Agent Packs — On-demand domain specialists (136)</strong></summary>

Installed to `~/.claude/agent-packs/`. Activate by symlinking:

```bash
ln -s ~/.claude/agent-packs/marketing/*.md ~/.claude/agents/
```

| Pack | Count | Examples | Source |
|------|------:|---------|--------|
| marketing | 29 | Douyin, Xiaohongshu, TikTok, SEO | [agency-agents](https://github.com/msitarzewski/agency-agents) |
| specialized | 28 | Legal, Finance, Healthcare, MCP Builder | agency-agents |
| game-development | 20 | Unity, Unreal, Godot, Roblox | agency-agents |
| design | 8 | Brand, UI, UX, Visual Storytelling | agency-agents |
| testing | 8 | API, Accessibility, Performance | agency-agents |
| sales | 8 | Deal Strategy, Pipeline Analysis | agency-agents |
| paid-media | 7 | Google Ads, Meta Ads, Programmatic | agency-agents |
| project-management | 6 | Scrum, Kanban, Risk Management | agency-agents |
| spatial-computing | 6 | visionOS, WebXR, Metal | agency-agents |
| support | 6 | Analytics, Infrastructure, Legal | agency-agents |
| academic | 5 | Anthropologist, Historian, Psychologist | agency-agents |
| product | 5 | Product Manager, Sprint, Feedback | agency-agents |

</details>

<details>
<summary><strong>Skills — 200+ from 6 sources</strong></summary>

| Source | Count | Key Skills |
|--------|------:|------------|
| [everything-claude-code](https://github.com/affaan-m/everything-claude-code) | 180+ | tdd-workflow, autopilot, ralph, security-review, coding-standards |
| [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) | 36 | plan, team, trace, deep-dive, blueprint, ultrawork |
| [gstack](https://github.com/garrytan/gstack) | 40 | /qa, /review, /ship, /cso, /investigate, /office-hours |
| [superpowers](https://github.com/obra/superpowers) | 14 | brainstorming, systematic-debugging, TDD, parallel-agents |
| [my-claude Core](https://github.com/sehoon787/my-claude) | 3 | boss-advanced, gstack-sprint, knowledge-vault |
| [Anthropic Official](https://github.com/anthropics/skills) | 14+ | pdf, docx, pptx, xlsx, canvas-design, mcp-builder |

</details>

<details>
<summary><strong>MCP Servers (3) + Hooks (7)</strong></summary>

**MCP Servers**

| Server | Purpose | Cost |
|--------|---------|------|
| <img src="https://context7.com/favicon.ico" width="16" height="16" align="center"/> [Context7](https://mcp.context7.com) | Real-time library documentation | Free |
| <img src="https://exa.ai/images/favicon-32x32.png" width="16" height="16" align="center"/> [Exa](https://mcp.exa.ai) | Semantic web search | Free 1k req/month |
| <img src="https://www.google.com/s2/favicons?domain=grep.app&sz=32" width="16" height="16" align="center"/> [grep.app](https://mcp.grep.app) | GitHub code search | Free |

**Behavioral Hooks**

| Hook | Event | Behavior |
|------|-------|----------|
| Session Setup | SessionStart | Auto-detects missing tools + injects Knowledge Vault context |
| Delegation Guard | PreToolUse | Blocks Boss from directly modifying files |
| Agent Telemetry | PostToolUse | Logs agent usage to `agent-usage.jsonl` |
| Subagent Verifier | SubagentStop | Forces independent verification + logs to Knowledge Vault |
| Completion Check | Stop | Confirms tasks verified + prompts session summary |
| Teammate Idle Guide | TeammateIdle | Prompts leader on idle teammates |
| Task Quality Gate | TaskCompleted | Verifies deliverable quality |

</details>

---

## <img src="https://obsidian.md/images/obsidian-logo-gradient.svg" width="24" height="24" align="center"/> Knowledge Vault

my-claude includes an Obsidian-compatible knowledge management system. Every project maintains a `.knowledge/` directory as a persistent memory base.

```
.knowledge/
├── INDEX.md              ← Project context, recent decisions
├── sessions/             ← Session summaries (YYYY-MM-DD-topic.md)
├── decisions/            ← Architecture & design decisions
├── learnings/            ← Non-obvious solutions, gotchas
├── references/           ← Web findings, factual data
└── agents/               ← Important agent execution logs
```

### How It Works

1. **Session start** — Boss reads `INDEX.md` to load project context
2. **During work** — Decisions, learnings, and references are captured as notes
3. **Session end** — Summary written, `INDEX.md` updated, notes linked with `[[wiki-links]]`

### Using with Obsidian

Open your project's `.knowledge/` folder as an [Obsidian](https://obsidian.md) vault:

1. Open Obsidian → **Open folder as vault** → select `.knowledge/`
2. Notes appear in the graph view, linked by `[[wiki-links]]`
3. YAML frontmatter provides searchable tags and metadata
4. Timeline of decisions and learnings builds automatically over sessions

All notes use YAML frontmatter with `date`, `type`, `tags`, and `related` fields for structured search.

---

## Upstream Open-Source Sources

my-claude bundles content from 5 MIT-licensed upstream repositories via git submodules:

| # | Source | What It Provides |
|---|--------|-----------------|
| 1 | <img src="https://github.com/Yeachan-Heo.png?size=32" width="20" height="20" align="center"/> **[oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode)** — Yeachan Heo | 19 specialist agents + 36 skills. Claude Code multi-agent harness with autopilot, ralph, team orchestration. |
| 2 | <img src="https://github.com/code-yeongyu.png?size=32" width="20" height="20" align="center"/> **[oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent)** — code-yeongyu | 9 OMO agents (Sisyphus, Atlas, Oracle, etc.). Multi-platform agent harness bridging Claude, GPT, Gemini. |
| 3 | <img src="https://github.com/affaan-m.png?size=32" width="20" height="20" align="center"/> **[everything-claude-code](https://github.com/affaan-m/everything-claude-code)** — affaan-m | 180+ skills + 87 rules across 14 languages. Comprehensive dev framework with TDD, security, and coding standards. |
| 4 | <img src="https://github.com/msitarzewski.png?size=32" width="20" height="20" align="center"/> **[agency-agents](https://github.com/msitarzewski/agency-agents)** — msitarzewski | 26 engineering agents (always loaded) + 136 domain agent-packs across 12 categories. |
| 5 | <img src="https://github.com/garrytan.png?size=32" width="20" height="20" align="center"/> **[gstack](https://github.com/garrytan/gstack)** — garrytan | 40 skills for code review, QA, security audit, deployment. Includes Playwright browser daemon. |
| 6 | <img src="https://github.com/obra.png?size=32" width="20" height="20" align="center"/> **[superpowers](https://github.com/obra/superpowers)** — Jesse Vincent | 14 skills + 1 agent covering brainstorming, TDD, parallel agents, and code review. |
| 7 | <img src="https://www.anthropic.com/favicon.ico" width="20" height="20" align="center"/> **[anthropic/skills](https://github.com/anthropics/skills)** — Anthropic | 14+ official skills for PDF, DOCX, PPTX, XLSX, and MCP builder. |
| 8 | <img src="https://github.com/forrestchang.png?size=32" width="20" height="20" align="center"/> **[andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills)** — forrestchang | 4 AI coding behavioral guidelines (Think Before Coding, Simplicity First, Surgical Changes, Goal-Driven Execution). |

---

## GitHub Actions

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| **CI** | push, PR | Validates JSON configs, agent frontmatter, skill existence, upstream file counts |
| **Update Upstream** | weekly / manual | Runs `git submodule update --remote` and creates auto-merge PR |
| **Auto Tag** | push to main | Reads `plugin.json` version and creates git tag if new |
| **Pages** | push to main | Deploys `docs/index.html` to GitHub Pages |
| **CLA** | PR | Contributor License Agreement check |
| **Lint Workflows** | push, PR | Validates GitHub Actions workflow YAML syntax |

---

## my-claude Originals

Features built specifically for this project, beyond what upstream sources provide:

| Feature | Description |
|---------|-------------|
| **Boss Meta-Orchestrator** | Dynamic capability discovery → intent classification → 5-priority routing → delegation → verification |
| **3-Phase Sprint** | Design (interactive) → Execute (autonomous via ralph) → Review (interactive vs design doc) |
| **Agent Tier Priority** | core > omo > omc > agency deduplication. Most specialized agent wins. |
| **Agency Cost Optimization** | Haiku for advisory, Sonnet for implementation — automatic model routing for 172 domain agents |
| **Knowledge Vault** | Obsidian-compatible `.knowledge/` directory with sessions, decisions, learnings, references |
| **Agent Telemetry** | PostToolUse hook logs agent usage to `agent-usage.jsonl` |
| **Smart Packs** | Project-type detection recommends relevant agent packs at session start |
| **CI SHA Pre-check** | Upstream sync skips unchanged sources via `git ls-remote` SHA comparison |
| **Agent Dedup Detection** | Normalized name comparison catches duplicates across upstream sources |

---

## Bundled Upstream Versions

Linked via git submodules. Pinned commits tracked natively by `.gitmodules`.

| Source | SHA | Date | Diff |
|--------|-----|------|------|
| [agency-agents](https://github.com/msitarzewski/agency-agents) | `4feb0cd` | 2026-04-07 | [compare](https://github.com/msitarzewski/agency-agents/compare/4feb0cd...HEAD) |
| [everything-claude-code](https://github.com/affaan-m/everything-claude-code) | `7dfdbe0` | 2026-04-07 | [compare](https://github.com/affaan-m/everything-claude-code/compare/7dfdbe0...HEAD) |
| [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) | `2487d38` | 2026-04-07 | [compare](https://github.com/Yeachan-Heo/oh-my-claudecode/compare/2487d38...HEAD) |
| [gstack](https://github.com/garrytan/gstack) | `03973c2` | 2026-04-07 | [compare](https://github.com/garrytan/gstack/compare/03973c2...HEAD) |
| [superpowers](https://github.com/obra/superpowers) | `b7a8f76` | 2026-04-06 | [compare](https://github.com/obra/superpowers/compare/b7a8f76...HEAD) |

---

## Contributing

Issues and PRs are welcome. When adding a new agent, add a `.md` file to `agents/core/` or `agents/omo/` and update `SETUP.md`.

## Credits

Built on the work of: [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) (Yeachan Heo), [oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent) (code-yeongyu), [everything-claude-code](https://github.com/affaan-m/everything-claude-code) (affaan-m), [agency-agents](https://github.com/msitarzewski/agency-agents) (msitarzewski), [gstack](https://github.com/garrytan/gstack) (garrytan), [superpowers](https://github.com/obra/superpowers) (Jesse Vincent), [anthropic/skills](https://github.com/anthropics/skills) (Anthropic), [andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills) (forrestchang).

## License

MIT License. See the [LICENSE](./LICENSE) file for details.
