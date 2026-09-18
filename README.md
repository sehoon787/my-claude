[English](./README.md) | [한국어](./docs/i18n/README.ko.md) | [日本語](./docs/i18n/README.ja.md) | [中文](./docs/i18n/README.zh.md) | [Deutsch](./docs/i18n/README.de.md) | [Français](./docs/i18n/README.fr.md)

> [![Codex CLI](https://img.shields.io/badge/Codex_CLI-my--codex-10b981?style=flat-square&logo=openai&logoColor=white)](https://github.com/sehoon787/my-codex) Looking for Codex CLI? → **my-codex** — same orchestration in native TOML format

---

<div align="center">

# my-claude

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Agents](https://img.shields.io/badge/agents-32-blue)
![Skills](https://img.shields.io/badge/skills-105-purple)
![Rules](https://img.shields.io/badge/rules-48-orange)
![MCP Servers](https://img.shields.io/badge/MCP-3-green)
![Hooks](https://img.shields.io/badge/hooks-10-red)
![LSP Servers](https://img.shields.io/badge/LSP-2-008b8b)
![Workflows](https://img.shields.io/badge/workflows-2-blueviolet)

**All-in-one agent harness for Claude Code.**
**One plugin, 32 curated agents ready.**

Boss auto-discovers every agent, skill, and MCP tool at runtime,<br>
then routes your task to the right specialist. No config files. No boilerplate.

<img src="./assets/owl-claude-social.svg" alt="The Maestro Owl — my-claude" width="700">

</div>

---

## Installation

### For Humans

```bash
git clone --depth 1 https://github.com/sehoon787/my-claude.git /tmp/my-claude
bash /tmp/my-claude/install.sh
rm -rf /tmp/my-claude
```

The default install is lean on purpose: every installed skill's description is
re-sent as context on every request. Frontend work needs 18 more skills, so they
are a separate lane:

```bash
bash install.sh --skills=web    # add the React/Vue/Nuxt/Nest, motion, a11y and browser-e2e skills
bash install.sh --full-skills   # every optional lane
bash install.sh --skills=       # back to the default
```

The choice is saved to `~/.claude/.my-claude-skills`, so a later plain
`bash install.sh` keeps it. `MY_CLAUDE_SKILLS=web` does the same thing.

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

```
Read https://raw.githubusercontent.com/sehoon787/my-claude/main/AI-INSTALL.md and follow every step.
```

---

## Open-Source Tools Used

### 1. [Oh My Claude Code (OMC)](https://github.com/Yeachan-Heo/oh-my-claudecode)

An agent harness dedicated to Claude Code. 19 specialist agents (architect, debugger, code reviewer, security reviewer, etc.) divide work by role, and magic keywords like `autopilot:` activate automatic parallel execution.

### 2. [Oh My OpenAgent (omo)](https://github.com/code-yeongyu/oh-my-openagent)

A multi-platform agent harness. Bridges to the Claude Code ecosystem via `claude-code-agent-loader` and `claude-code-plugin-loader`. Automatically routes across 8 providers (Claude, GPT, Gemini, etc.) by category. The 9 agents in this repository are adaptations of omo agents in Claude Code standalone `.md` format.

### 3. [Andrej Karpathy Skills](https://github.com/forrestchang/andrej-karpathy-skills)

The 4 AI coding behavioral guidelines proposed by Andrej Karpathy (Think Before Coding, Simplicity First, Surgical Changes, Goal-Driven Execution). Included in CLAUDE.md and always active across all sessions.

### 4. [Everything Claude Code (ECC)](https://github.com/affaan-m/everything-claude-code)

A comprehensive framework of 278 skills + 67 agents + 94 commands + language-specific rules. my-claude installs a curated 79-skill subset (stack patterns, AI/agent engineering, codebase tooling) plus 9 rule sets. Automates repetitive development patterns with slash commands like `/tdd`, `/plan`, `/code-review`, and `/build-fix`.

### 5. [Anthropic Official Skills](https://github.com/anthropics/skills)

The official agent skills repository provided directly by Anthropic. Enables specialist tasks such as PDF parsing, Word/Excel/PowerPoint document manipulation, and MCP server creation.

### 6. [gstack](https://github.com/garrytan/gstack)

A sprint-process harness by Garry Tan. my-claude installs 26 of its skills plus the `gstack` root router (27 total). Provides browser-based QA testing (`/qa`), code review with scope-drift detection (`/review`), security auditing (`/cso`), and a full Plan→Review→QA→Ship deployment workflow. Includes a compiled Playwright browser daemon for real-browser testing.

### 7. [superpowers](https://github.com/obra/superpowers)

Jesse Vincent's development-process skill library. my-claude installs 13 of its 14 skills — brainstorming, systematic debugging, TDD, plan writing and execution, and code-review etiquette. (`dispatching-parallel-agents` is excluded because Boss and Agent Teams already own that path.)

### 8. [codeburn](https://github.com/getagentseal/codeburn)

Local-first AI token and cost tracker. Reads the session files Claude Code already writes (`~/.claude/projects/**/*.jsonl`) and breaks spend down by model, project, and task — no proxy, no API key, nothing leaves the machine. Installed as a companion CLI (`codeburn`, pinned in `install.sh`); the budget-guard hooks are opt-in via `bash install.sh --with-codeburn-guard` because they add a PreToolUse hook on every tool call. The dollar figures are estimates — token counts priced at API list rates; codeburn itself is free and bills nothing, so on a subscription plan they are a usage proxy. The guard's hard cap ($15/session by default) blocks every tool call in that session, including the `codeburn guard allow` that lifts it (run it from an external terminal), which is why it stays opt-in. Complements the OMC HUD: the HUD shows this session's context and quota, codeburn shows where money went across sessions.

### 9. [Serena](https://github.com/oraios/serena)

A coding-agent toolkit that exposes a language server's symbol graph over MCP. Instead of reading a whole file to change one function, agents call `find_symbol`, `get_symbols_overview`, `find_referencing_symbols`, `replace_symbol_body`, and `insert_after_symbol` — the tokens spent scale with the symbol, not the file. `install.sh` installs the pinned `serena-agent` CLI with uv and registers it as a user-scope stdio MCP server (`serena start-mcp-server --context claude-code --project-from-cwd`); no Serena code is vendored into this repository. A local dashboard at `http://localhost:24282/dashboard/index.html` shows logs and per-tool call counts, and per-project memories are written to `.serena/` in the repository being worked on. The installer turns off the dashboard's launch-time browser pop-up, so the tab only opens when you ask for it.

### 10. [Headroom](https://github.com/headroomlabs-ai/headroom)

A context-optimization layer for LLM applications. my-claude uses it in MCP mode only: `headroom mcp serve` exposes `headroom_compress`, `headroom_retrieve`, and `headroom_stats`, so a long tool result can be compressed before it enters the transcript and the original recovered on demand. Headroom's other mode — the `headroom wrap` / `headroom proxy` pair that routes all traffic through a local proxy — is deliberately **not** used: it authenticates with an Anthropic API key, which a subscription/OAuth login does not have. That is also why `headroom doctor` reports the proxy as unreachable on this stack; the MCP tools work without it.

### 11. [Archify](https://github.com/tt-a1i/archify)

An agent skill that draws architecture, workflow, sequence, data-flow, and lifecycle diagrams as self-contained HTML files — inline SVG, a dark/light theme toggle, and a built-in PNG/JPEG/WebP/SVG export menu, with no runtime dependencies in the generated file. It also accepts pasted Mermaid as an input dialect and lays the diagram out from scratch in archify style. Pinned as a submodule at tag `v2.9.0`; `install.sh` copies the upstream `archify/` skill directory to `~/.claude/skills/archify`, so no `npx skills add` runs at install time.

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
│  P2: Specialist agent (32)                  │
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
| **P0** | gstack skill | Ship / QA / deploy / security workflow | `"ship this"` → gstack `/ship` |
| **P1** | Skill match | Task maps to a self-contained skill | `"merge PDFs"` → pdf skill |
| **P2** | Specialist agent | Domain-specific agent exists | `"security audit"` → security-reviewer |
| **P3a** | Boss direct | 2-4 independent agents | `"fix 3 bugs"` → parallel spawn |
| **P3b** | Sub-orchestrator | Complex multi-step workflow | `"refactor + test"` → Sisyphus |
| **P3c** | Agent Teams | Peer-to-peer communication needed | `"implement + review"` → Review Chain |
| **P4** | Fallback | No specialist matches | `"explain this"` → general agent |

### Model Routing

| Complexity | Model | Used For |
|-----------|-------|----------|
| Top-level orchestration | `claude-fable-5-1` | Boss |
| Deep analysis, architecture | `claude-opus-5` | Sisyphus, Atlas, Hephaestus, Oracle, Metis, Momus, Prometheus |
| Standard implementation | `claude-sonnet-5` | Librarian, Multimodal-Looker, OMC specialists |
| Quick lookup, exploration | `claude-haiku-4-5` | Lightweight OMC agents, simple advisory |

### Effort Tiers

Model choice sets *which* brain runs a task; the `effort:` frontmatter field sets *how hard* it thinks. Every self-owned agent declares one.

| Effort | Agents |
|--------|--------|
| `xhigh` | Boss, Oracle, Prometheus, Multi-Agent Systems Architect |
| `high` | Sisyphus, Hephaestus, Atlas, Metis, Momus |
| `medium` | Librarian, Multimodal-Looker, AI Engineer, DevOps Automator |

Skills declare effort too — `boss-briefing` runs at `medium`, `briefing-vault` at `low`. `boss-advanced` and `gstack-sprint` deliberately declare none: a skill's effort overrides the session level while it runs, which would quietly downgrade Boss mid-flow.

Precedence is `CLAUDE_CODE_EFFORT_LEVEL` (env) > frontmatter > session effort level. `xhigh` is Fable's supported ceiling; `max` is Opus-class only and silently falls back elsewhere.

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

### Structured Final Report

Boss closes every working turn — any turn that edited files, made commits/PRs, changed configuration, or ran verification — with a structured final report the reader can scan without opening a diff. The report is assembled from five fixed tables, each emitted only when its situation actually occurred (never an empty table):

| Situation | Table | Columns |
|-----------|-------|---------|
| Files/settings changed | Changes | Target / Before / After / Rationale |
| Multiple tasks completed | Work summary | Item / Result / Evidence |
| Verification was run | Verification | Item / Expected / Actual / Verdict |
| Commits/PRs produced | Deliverables | PR / Repo / Content / Status |
| Anything unresolved | Remaining | Item / Status / Next step |

It fires only at the very end of the request — never on a turn that launches or relays background work, never as a mid-task progress update — and pure Q&A turns end normally without it. The spec lives in `boss.md § FINAL REPORT`; the `stop-final-report.js` Stop hook enforces it (see [Hooks](#-briefing-vault)).

### Named Workflows

Deterministic multi-agent workflows. `install.sh` copies them to `~/.claude/workflows/`, so they run from any project through the Workflow tool — not just from this repo.

| Workflow | What It Does | Invocation |
|----------|--------------|------------|
| **code-review-fanout** | Four dimension reviewers (correctness, security, performance, tests) fan out in parallel, then every finding is adversarially verified before it is reported | `Workflow({name: "code-review-fanout"})` — args: the review target (branch, commit range, paths). Defaults to the working-tree diff |
| **upstream-audit** | One analyst per upstream — pin delta vs origin, allowlist fit, new overlaps, security signals, health — followed by a synthesized action list | `Workflow({name: "upstream-audit"})` — for quarterly or pre-sync audits |

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                    User Request                       │
└───────────────────────┬─────────────────────────────┘
                        ▼
┌─────────────────────────────────────────────────────┐
│  Boss · Meta-Orchestrator (Fable)                     │
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
│  Karpathy Guidelines · Rules (48) · Hooks (10)       │
├─────────────────────────────────────────────────────┤
│  Specialist Agents (32)                               │
│  Boss 1 · OMO 9 · OMC 19 · Vendored 3                │
├─────────────────────────────────────────────────────┤
│  Skills (105)                                         │
│  ECC 61 · gstack 27 · Superpowers 13 · Core 4       │
│  + ECC web lane 18 (opt-in) · OMC 16 (plugin)        │
├─────────────────────────────────────────────────────┤
│  MCP Layer                                            │
│  Context7 · Exa · grep.app                            │
├─────────────────────────────────────────────────────┤
│  Tooling Layer                                        │
│  LSP (2) · Named Workflows (2)                        │
└─────────────────────────────────────────────────────┘
```

---

## What's Inside

| Category | Count | Source |
|----------|------:|--------|
| **Agents** (always loaded) | 32 | Boss 1 + OMO 9 + OMC 19 + Vendored 3 |
| **Skills** | 105 | ECC 61 · gstack 27 · Superpowers 13 · Core 4. ECC's 18-skill `web` lane is opt-in (`--skills=web`); OMC's 16 come from the OMC plugin and are never copied |
| **Rules** | 48 files / 9 sets | ECC 46 (3 common files + 8 language dirs) + Core 2 |
| **MCP Servers** | 3 | Context7, Exa, grep.app |
| **Hooks** | 10 files / 6 events | Delegation guard, telemetry, verification, vault, context budget |
| **LSP Servers** | 2 | typescript (`typescript-language-server`), python (`pyright-langserver`) |
| **Named Workflows** | 2 | code-review-fanout, upstream-audit |
| **Upstream submodules** | 4 | ecc, omc, gstack, superpowers |
| **CLI Tools** | 5 | omc, omo, ast-grep, comment-checker, codeburn |

Every agent, skill, and rule above is allowlisted in [`scripts/skill-allowlists.sh`](./scripts/skill-allowlists.sh) and tracked in the install manifest. Anthropic's official document skills (pdf, docx, …) are added separately via `claude plugin add anthropics/skills` and are deliberately not manifest-tracked.

<details>
<summary><strong>Core Agent — Boss meta-orchestrator (1)</strong></summary>

| Agent | Model | Role | Source |
|-------|-------|------|--------|
| Boss | Fable | Dynamic runtime discovery → capability matching → optimal routing. Never writes code. | my-claude |

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
<summary><strong>Vendored Agents — AI and infrastructure specialists (3)</strong></summary>

Snapshotted from [agency-agents](https://github.com/msitarzewski/agency-agents) (MIT) on 2026-07-27, when that submodule was removed. Only the engineering agents with no equivalent elsewhere in the stack were kept; each file carries its upstream attribution header.

| Agent | Role | Source |
|-------|------|--------|
| AI Engineer | AI/ML engineering, model integration, data pipelines | agency-agents (vendored) |
| DevOps Automator | Infrastructure automation, CI/CD, cloud operations | agency-agents (vendored) |
| Multi-Agent Systems Architect | Agent topology, context management, failure recovery | agency-agents (vendored) |

</details>

<details>
<summary><strong>Skills — 105 from 4 sources</strong></summary>

Each source is allowlisted in [`scripts/skill-allowlists.sh`](./scripts/skill-allowlists.sh) — anything not listed there is never installed.

| Source | Count | Key Skills |
|--------|------:|------------|
| [everything-claude-code](https://github.com/affaan-m/everything-claude-code) | 61 | coding-standards, fastapi-patterns, agent-architecture-audit, springboot-patterns, kubernetes-patterns |
| [gstack](https://github.com/garrytan/gstack) | 27 | /qa, /review, /ship, /cso, /investigate, /office-hours |
| [superpowers](https://github.com/obra/superpowers) | 13 | brainstorming, systematic-debugging, test-driven-development, writing-plans |
| [my-claude Core](https://github.com/sehoon787/my-claude) | 4 | boss-advanced, boss-briefing, briefing-vault, gstack-sprint |

**Opt-in `web` lane (+18)** — `accessibility`, `bun-runtime`, `e2e-testing`, `frontend-a11y`, `frontend-patterns`, `motion-*` (3), `nestjs-patterns`, `nextjs-turbopack`, `nuxt4-patterns`, `react-patterns`, `react-performance`, `react-testing`, `ui-to-vue`, `vite-patterns`, `vue-patterns`, `windows-desktop-e2e`. Browser-UI work only, so a backend or infra session would pay for 18 descriptions it never uses. Install them with `bash install.sh --skills=web` (or `--full-skills`, or `MY_CLAUDE_SKILLS=web`); the choice is saved to `~/.claude/.my-claude-skills` and later plain installs keep it.

**OMC skills are not copied.** `install.sh` enables the `oh-my-claudecode@omc` plugin, which already exposes all 16 (`autopilot`, `ralph`, `team`, `ultrawork`, `ralplan`, `omc-reference`, …) as `oh-my-claudecode:<name>`. A local copy would put a second description of the same skill in every session. Routing surfaces use the prefixed name; a bare `ralph` does not resolve.

</details>

<details>
<summary><strong>MCP Servers (3) + Hooks (10)</strong></summary>

**MCP Servers**

| Server | Purpose | Cost |
|--------|---------|------|
| <img src="https://context7.com/favicon.ico" width="16" height="16" align="center"/> [Context7](https://mcp.context7.com) | Real-time library documentation | Free |
| <img src="https://exa.ai/images/favicon-32x32.png" width="16" height="16" align="center"/> [Exa](https://mcp.exa.ai) | Semantic web search | Free 1k req/month |
| <img src="https://www.google.com/s2/favicons?domain=grep.app&sz=32" width="16" height="16" align="center"/> [grep.app](https://mcp.grep.app) | GitHub code search | Free |

**Behavioral Hooks**

| Hook | Event | Behavior |
|------|-------|----------|
| Session Setup | SessionStart | Auto-detects missing tools + injects Briefing Vault context |
| Delegation Guard | PreToolUse | Blocks Boss from directly modifying files |
| Agent Telemetry | PostToolUse | Logs agent usage to `agent-usage.jsonl` |
| Subagent Logger | SubagentStop | Logs agent execution to Briefing Vault |
| Completion Check | Stop | Runs profile fallback + guards /boss-briefing execution |
| Vault Reminder | UserPromptSubmit | Suggests /boss-briefing after 5+ messages |
| Calibrated Response | UserPromptSubmit | Re-injects `rules/common/calibrated-response.md` every turn |
| Context Budget | UserPromptSubmit | Every 40 prompts since the last compaction (`MY_CLAUDE_COMPACT_EVERY`), suggests `/compact` at the next task boundary |
| Context Budget reset | SessionStart (`compact`) | Zeroes that counter after a compaction |

**Quiet plugin hooks.** `merge-settings.js` sets `env.OMC_QUIET=2` unless you already set it. OMC's own plugin hooks otherwise append an advisory line ("Use parallel execution…", "Background operation detected…") to nearly every Bash, Edit, and Read call, and every one of those lines is re-sent as context on every later request. Level 2 drops the advisories and the "Completed: N" agent summaries; real failures are still reported.

**Earlier auto-compaction.** `merge-settings.js` also sets `env.CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=75` unless you already set it, so a long session compacts before the tail of its transcript gets expensive. The variable can only lower the trigger. See the [environment variable reference](https://code.claude.com/docs/en/env-vars).

</details>

<details>
<summary><strong>LSP Servers (2)</strong></summary>

The plugin declares two language servers in `.lsp.json`. Claude Code starts them on demand, so agents get diagnostics and code navigation instantly instead of paying for a build round-trip.

| Server | Command | Extensions |
|--------|---------|------------|
| typescript | `typescript-language-server --stdio` | `.ts` `.tsx` `.js` `.jsx` `.mjs` `.cjs` |
| python | `pyright-langserver --stdio` | `.py` |

`install.sh` installs both binaries non-fatally — if one is unavailable, only that server is disabled and the rest of the install continues.

</details>

---

## <img src="https://obsidian.md/images/obsidian-logo-gradient.svg" width="24" height="24" align="center"/> Briefing Vault

Obsidian-compatible persistent memory. Every project maintains a `.briefing/` directory that auto-populates across sessions.

```
.briefing/
├── INDEX.md                          ← Project context (auto-created once)
├── state.json                        ← Session metadata, counters, lastVaultSync (auto-managed)
├── sessions/
│   ├── YYYY-MM-DD-<topic>.md        ← AI-written session summary (enforced)
│   └── YYYY-MM-DD-auto.md           ← Auto-generated scaffold (git diff, agent stats)
├── decisions/
│   └── YYYY-MM-DD-<decision>.md     ← AI-written decision record (enforced)
├── learnings/
│   ├── YYYY-MM-DD-<pattern>.md      ← AI-written learning note
│   └── YYYY-MM-DD-auto-session.md   ← Auto-generated scaffold (agents, files)
├── references/
│   └── auto-links.md                ← Auto-collected URLs from web searches
├── archives/                         ← PARA: completed/inactive notes (flat)
├── wiki/                             ← LLM-wiki: concept pages
│   └── _schema.md
├── agents/
│   ├── agent-log.jsonl              ← Subagent execution telemetry
│   └── YYYY-MM-DD-summary.md        ← Daily agent usage breakdown
└── persona/
    ├── profile.md                   ← Agent affinity stats (auto-updated)
    ├── suggestions.jsonl            ← Routing suggestions (auto-generated)
    └── rules/                       ← Workflow pattern rules (workflow-*.md)
```

### Sub-Vaults

| Path | Description |
|------|-------------|
| `INDEX.md` | Project overview with links to recent decisions and learnings. Auto-created on first session, refreshed by /boss-briefing or Stop hook fallback. |
| `state.json` | Session metadata: counters (workCounter, messageCount), lastVaultSync timestamp, sessionStartHead. Auto-managed by hooks. |
| `sessions/` | **Session summaries.** `*-auto.md` — scaffold with git diff stats and agent counts. `<topic>.md` — AI-written summary enforced by Stop hook guard. |
| `decisions/` | **Architecture and design decisions** with rationale. AI-written, enforced during active work. |
| `learnings/` | **Patterns, gotchas, non-obvious solutions.** `*-auto-session.md` — scaffold with file lists. `<topic>.md` — AI-written. |
| `references/` | **Web research URLs.** `auto-links.md` — auto-collected from WebSearch/WebFetch calls. |
| `agents/` | **Agent telemetry.** `agent-log.jsonl` — per-call log with enriched fields `{ts, agent_type, phase, seq, task_hint}`. `YYYY-MM-DD-summary.md` — daily usage breakdown. |
| `persona/` | **User work style profile.** `profile.md` — tool affinity stats. `suggestions.jsonl` — routing recommendations. Workflow sequence patterns in `rules/workflow-*.md`. Run /boss-briefing to analyze. |
| `archives/` | PARA Archives — completed sessions (30+ days), superseded decisions, inactive learnings |
| `wiki/` | LLM-wiki concept pages — distilled knowledge from multiple sessions |

### Knowledge Management (v2)

BriefingVault v2 integrates three knowledge management methodologies:

| Methodology | Applied As |
|------------|-----------|
| **PARA** (Tiago Forte) | Directory structure: sessions=Projects, decisions=Areas, references=Resources, archives=Archives |
| **Zettelkasten** (Luhmann) | Atomic notes in `learnings/`, unique IDs (`YYYYMMDDHHMMSS`), enforced `[[wiki-links]]` |
| **LLM-wiki** (Karpathy) | Concept pages in `wiki/` — auto-suggested when keywords appear 3+ times |

Claude Code session-end hooks automatically:
- Suggest archiving notes older than 30 days
- Propose wiki pages for frequently mentioned concepts
- Generate unique Zettelkasten IDs for new notes

### Session-Specific Diffs

At session start, the current git HEAD is saved to `state.json` (`sessionStartHead` field). For non-git projects, a `YYYY-MM-DD:cwd` identifier is used instead. At session end, diffs are calculated relative to this saved point — showing only changes from the current session, not accumulated uncommitted changes from previous sessions.

### Using with Obsidian

1. Open Obsidian → **Open folder as vault** → select `.briefing/`
2. Notes appear in graph view, linked by `[[wiki-links]]`
3. YAML frontmatter (`date`, `type`, `tags`) enables structured search
4. Timeline of decisions and learnings builds automatically over sessions

### /boss-briefing

Run `/boss-briefing` during or at the end of a session to:
- **Sync vault**: Update profile.md, INDEX.md, and agent summaries
- **Detect workflow patterns**: Analyze temporal agent call sequences across sessions
- **Recover from gaps**: Generate recovery summaries if days have passed since the last session
- **Propose persona rules**: Suggest workflow-based routing preferences (not just frequency)
- **Validate session notes**: Check that today's session has a proper summary

The Stop hook checks whether `/boss-briefing` has run today. If not, it blocks session end with a reminder. The existing `stop-profile-update.js` continues to run as a fallback.

A second Stop hook, `stop-final-report.js`, enforces Boss's FINAL REPORT: when a turn changed state (files edited, commits made, verification run) but the final message lacks the structured report tables defined in `boss.md § FINAL REPORT`, it blocks once with the spec as the reminder. It judges from the harness-provided `last_assistant_message` plus the turn's origin in the transcript: it enforces only on human-initiated turns that launched no background agent or workflow (notification-triggered turns and turns with pending background work just record a report if one is present), blocks at most once per turn, and fails open on any error.

---

## Where to See Results

Every tool in this stack writes its output somewhere. This is where.

| Tool | What It Does | How to Run | Where to Look |
|------|--------------|-----------|---------------|
| **codeburn** | Token and cost accounting across every past session | `codeburn` (interactive TUI) · `codeburn report --period week --format json` for a non-interactive dump | Reads `~/.claude/projects/**/*.jsonl` read-only. Dollar figures are **estimates**: token counts priced at API list rates, so on a subscription plan they are a usage proxy, not a bill. |
| **Serena** | Symbol-level code navigation and editing | Starts automatically as an MCP server; call `get_symbols_overview` / `find_symbol` from any session | Dashboard at `http://localhost:24282/dashboard/index.html` while a server is running (logs + per-tool call counts). Per-project memories land in `.serena/` inside the repository you are working on; the global config is `~/.serena/serena_config.yml`. |
| **Headroom** | Compresses oversized tool results before they enter the transcript | MCP tools `headroom_compress` / `headroom_retrieve` / `headroom_stats` · `headroom --version` to confirm the CLI | `headroom_stats` reports compression counts for the running server. `headroom doctor` and `headroom perf` describe the **proxy**, which this stack does not run — both reporting "not reachable" / "no performance data" is the expected state here. |
| **Archify** | Architecture, workflow, sequence, data-flow, and lifecycle diagrams | Ask for a diagram and Boss routes to the `archify` skill. Manually, from `~/.claude/skills/archify`: `node bin/archify.mjs render workflow examples/agent-tool-call.workflow.json out.html` | The generated `out.html` — open it in any browser. It is self-contained (inline SVG, theme toggle, export menu) and has no runtime dependencies. Validate one with `node bin/archify.mjs check out.html`. |
| **OMC HUD** | Live context, quota, and mode readout | Installed as the statusline by `install.sh`; `/oh-my-claudecode:hud` reconfigures it | The Claude Code statusline at the bottom of the session. Complements codeburn: the HUD is this session, codeburn is every session. |

---

## Upstream Open-Source Sources

my-claude links 5 MIT-licensed upstream repositories as git submodules, each pinned to an explicit SHA:

| # | Source | What It Provides |
|---|--------|-----------------|
| 1 | <img src="https://github.com/affaan-m.png?size=32" width="20" height="20" align="center"/> **[everything-claude-code](https://github.com/affaan-m/everything-claude-code)** — affaan-m | 79 installed skills + 9 rule sets. Language and stack knowledge: TDD, security, coding standards, framework patterns. |
| 2 | <img src="https://github.com/Yeachan-Heo.png?size=32" width="20" height="20" align="center"/> **[oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode)** — Yeachan Heo | 19 specialist agents + 16 installed skills. Orchestration lane: autopilot, ralph, team. |
| 3 | <img src="https://github.com/garrytan.png?size=32" width="20" height="20" align="center"/> **[gstack](https://github.com/garrytan/gstack)** — garrytan | 27 installed skills for ship, QA, deploy, and security review (Boss P0 lane). Includes Playwright browser daemon. |
| 4 | <img src="https://github.com/obra.png?size=32" width="20" height="20" align="center"/> **[superpowers](https://github.com/obra/superpowers)** — Jesse Vincent | 13 installed skills covering the dev-process lane: brainstorming, TDD, systematic debugging, plan writing. |
| 5 | <img src="https://github.com/tt-a1i.png?size=32" width="20" height="20" align="center"/> **[archify](https://github.com/tt-a1i/archify)** — tt-a1i | 1 installed skill, pinned at tag `v2.9.0`. Architecture, workflow, sequence, data-flow, and lifecycle diagrams as self-contained HTML. |

Not submodules, but part of the stack:

| Source | How It Arrives |
|--------|----------------|
| <img src="https://github.com/code-yeongyu.png?size=32" width="20" height="20" align="center"/> **[oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent)** — code-yeongyu | 9 OMO agents (Sisyphus, Atlas, Oracle, etc.), adapted into this repo as standalone `.md` agents under `agents/omo/`. |
| <img src="https://github.com/msitarzewski.png?size=32" width="20" height="20" align="center"/> **[agency-agents](https://github.com/msitarzewski/agency-agents)** — msitarzewski | Submodule removed 2026-07-27. 3 engineering agents vendored into `agents/vendored/` with attribution. |
| <img src="https://www.anthropic.com/favicon.ico" width="20" height="20" align="center"/> **[anthropic/skills](https://github.com/anthropics/skills)** — Anthropic | Installed by `install.sh` via `claude plugin add anthropics/skills` (pdf, docx, and friends). Not manifest-tracked. |
| <img src="https://github.com/forrestchang.png?size=32" width="20" height="20" align="center"/> **[andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills)** — forrestchang | 4 AI coding behavioral guidelines appended to `~/.claude/CLAUDE.md`. |

Companion CLIs and MCP servers `install.sh` brings in, each pinned to an exact version:

| Source | How It Arrives |
|--------|----------------|
| <img src="https://github.com/oraios.png?size=32" width="20" height="20" align="center"/> **[serena](https://github.com/oraios/serena)** — oraios | `uv tool install -p 3.13 serena-agent==1.7.0`, registered as the `serena` stdio MCP server. Symbol-level code navigation and editing. GPL-3.0 application, MIT SolidLSP; used as an external server, never vendored. |
| <img src="https://github.com/headroomlabs-ai.png?size=32" width="20" height="20" align="center"/> **[headroom](https://github.com/headroomlabs-ai/headroom)** — Headroom Labs | `uv tool install --python 3.13 "headroom-ai[all]==0.37.0"`, registered as the `headroom` stdio MCP server (`headroom mcp serve`). Tool-output compression. Apache-2.0. Proxy/wrap mode is intentionally unused. |
| <img src="https://github.com/getagentseal.png?size=32" width="20" height="20" align="center"/> **[codeburn](https://github.com/getagentseal/codeburn)** — getagentseal | `npm i -g codeburn@0.9.23`. Local-first token and cost tracking over the session files Claude Code already writes. |
| <img src="https://github.com/ast-grep.png?size=32" width="20" height="20" align="center"/> **[ast-grep](https://github.com/ast-grep/ast-grep)** — ast-grep | `npm i -g @ast-grep/cli@0.42.0`. Structural (AST-aware) code search and rewrite. |
| <img src="https://github.com/upstash.png?size=32" width="20" height="20" align="center"/> **[context7](https://github.com/upstash/context7)** — Upstash | Hosted MCP server at `https://mcp.context7.com/mcp`. Up-to-date library documentation. |
| <img src="https://github.com/exa-labs.png?size=32" width="20" height="20" align="center"/> **[exa](https://github.com/exa-labs/exa-mcp-server)** — Exa Labs | Hosted MCP server at `https://mcp.exa.ai/mcp`. Neural web search. |
| <img src="https://github.com/grep-app.png?size=32" width="20" height="20" align="center"/> **[grep.app](https://grep.app/)** — grep.app | Hosted MCP server at `https://mcp.grep.app`. Code search across public GitHub repositories. |

---

## GitHub Actions

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| **CI** | push, PR | Validates JSON configs, agent frontmatter, skill existence, upstream file counts |
| **Smoke** | push, PR | 4 jobs — `hooks` (hook execution), `shell` (install script shape), `drift` (model drift), `routing-refs` (dangling agent/skill references) |
| **Update Upstream** | every 3 days / manual | `git submodule update --remote` → refresh SHA pins in `SOURCES.json` → security scan of the upstream diff → auto-merge only when the scan is clean, otherwise the PR is flagged for human review |
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
| **Agent Tier Priority** | core > omo > omc > vendored deduplication. Most specialized agent wins. |
| **Lane Ownership** | Orchestration → OMC, dev process → superpowers, ship/QA/deploy/security → gstack (Boss P0), language and stack knowledge → ECC, AI and domain work → vendored agents |
| **Curated Allowlists** | `scripts/skill-allowlists.sh` is the single source of truth — 105 skills, 3 always-on common rules and 8 path-scoped language rule sets survive from thousands upstream, so nothing unlisted ever reaches a session's context |
| **Briefing Vault** | Obsidian-compatible `.briefing/` directory with sessions, decisions, learnings, references |
| **Agent Telemetry** | PostToolUse hook logs agent usage to `agent-usage.jsonl` |
| **No-op Sync Skip** | Upstream sync stages the submodule bumps and `SOURCES.json` pins, then opens a PR only when that staged diff is non-empty |
| **Agent Dedup Detection** | `tests/validate-sync.sh` compares agent filenames across `agents/` and the omc/superpowers submodules and reports collisions |

---

## Bundled Upstream Versions

Linked via git submodules. Pinned commits are tracked natively by `.gitmodules` and mirrored as an AI-BOM in [`upstream/SOURCES.json`](./upstream/SOURCES.json); `install.sh` checks out these exact SHAs rather than tracking `main`.

| Source | SHA | Date | Diff |
|--------|-----|------|------|
| [everything-claude-code](https://github.com/affaan-m/everything-claude-code) | `4092795` | 2026-07-27 | [compare](https://github.com/affaan-m/everything-claude-code/compare/4092795...HEAD) |
| [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) | `590fb98` | 2026-07-27 | [compare](https://github.com/Yeachan-Heo/oh-my-claudecode/compare/590fb98...HEAD) |
| [gstack](https://github.com/garrytan/gstack) | `7c9df1c` | 2026-07-27 | [compare](https://github.com/garrytan/gstack/compare/7c9df1c...HEAD) |
| [superpowers](https://github.com/obra/superpowers) | `3dcbd5c` | 2026-07-27 | [compare](https://github.com/obra/superpowers/compare/3dcbd5c...HEAD) |
| [archify](https://github.com/tt-a1i/archify) | `62904f3` (`v2.9.0`) | 2026-09-19 | [compare](https://github.com/tt-a1i/archify/compare/62904f3...HEAD) |

---

## Contributing

Issues and PRs are welcome. When adding a new agent, add a `.md` file to `agents/core/` or `agents/omo/` and update `SETUP.md`.

## Credits

Built on the work of: [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) (Yeachan Heo), [oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent) (code-yeongyu), [everything-claude-code](https://github.com/affaan-m/everything-claude-code) (affaan-m), [gstack](https://github.com/garrytan/gstack) (garrytan), [superpowers](https://github.com/obra/superpowers) (Jesse Vincent), [agency-agents](https://github.com/msitarzewski/agency-agents) (msitarzewski — 3 vendored agents), [anthropic/skills](https://github.com/anthropics/skills) (Anthropic), [andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills) (forrestchang), [serena](https://github.com/oraios/serena) (oraios), [headroom](https://github.com/headroomlabs-ai/headroom) (Headroom Labs), [archify](https://github.com/tt-a1i/archify) (tt-a1i), [codeburn](https://github.com/getagentseal/codeburn) (getagentseal).

## License

MIT License. See the [LICENSE](./LICENSE) file for details.
