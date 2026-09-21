[English](./README.md) | [한국어](./docs/i18n/README.ko.md) | [日本語](./docs/i18n/README.ja.md) | [中文](./docs/i18n/README.zh.md) | [Deutsch](./docs/i18n/README.de.md) | [Français](./docs/i18n/README.fr.md)

> [![Codex CLI](https://img.shields.io/badge/Codex_CLI-my--codex-10b981?style=flat-square&logo=openai&logoColor=white)](https://github.com/sehoon787/my-codex) Looking for Codex CLI? → **my-codex** — same orchestration in native TOML format

---

<div align="center">

# my-claude

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Agents](https://img.shields.io/badge/agents-32-blue)
![Skills](https://img.shields.io/badge/skills-106-purple)
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
```

If you use both routes, `install.sh` also refreshes the `my-claude` plugin (marketplace update + plugin update) so its hooks stay in sync with this script's install. The installer also ensures one shared codeburn dashboard and one shared Headroom proxy for both my-claude and my-codex. A later installer reuses healthy services instead of starting duplicates. State and startup logs live under `${XDG_STATE_HOME:-$HOME/.local/state}/agent-harness-services`; neither installer changes `ANTHROPIC_BASE_URL` or `OPENAI_BASE_URL`.

### For AI Agents

```
Read https://raw.githubusercontent.com/sehoon787/my-claude/main/AI-INSTALL.md and follow every step.
```

---

## Open-Source Tools Used

Every project this stack builds on is described once, here. Five MIT-licensed
upstreams are linked as git submodules pinned to an explicit SHA; the rest arrive
as version-pinned CLIs, hosted MCP servers, or files vendored with attribution.

| # | Project | What my-claude takes from it | How it arrives |
|---|---------|------------------------------|----------------|
| 1 | <img src="https://github.com/Yeachan-Heo.png?size=32" width="20" height="20" align="center"/> **[oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode)** (OMC) — Yeachan Heo | 19 specialist agents (architect, debugger, code reviewer, security reviewer, …) that divide work by role, plus 16 orchestration skills — autopilot, ralph, team. Magic keywords like `autopilot:` activate automatic parallel execution. | Submodule `upstream/omc`, SHA-pinned (see [Bundled Upstream Versions](#bundled-upstream-versions)); `install.sh` runs `npm i -g oh-my-claude-sisyphus@latest` and enables the `oh-my-claudecode@omc` plugin. |
| 2 | <img src="https://github.com/code-yeongyu.png?size=32" width="20" height="20" align="center"/> **[oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent)** (omo) — code-yeongyu | A multi-platform harness that routes across 8 providers (Claude, GPT, Gemini, …) by category and bridges to Claude Code via `claude-code-agent-loader` and `claude-code-plugin-loader`. Its 9 agents (Sisyphus, Atlas, Oracle, …) are adapted here as standalone `.md` files. | Not a submodule: the 9 agents live in `agents/omo/`; `install.sh` runs `npm i -g oh-my-opencode@latest` for the `omo` CLI. |
| 3 | <img src="https://github.com/forrestchang.png?size=32" width="20" height="20" align="center"/> **[andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills)** — forrestchang | The 4 AI-coding behavioral guidelines — Think Before Coding, Simplicity First, Surgical Changes, Goal-Driven Execution — always active. | `install.sh` curls `CLAUDE.md` at the pinned SHA `aa4467f`, checksum-verifies it, and appends it to `~/.claude/CLAUDE.md`. No code vendored. |
| 4 | <img src="https://github.com/affaan-m.png?size=32" width="20" height="20" align="center"/> **[everything-claude-code](https://github.com/affaan-m/everything-claude-code)** (ECC) — affaan-m | 278 skills + 67 agents + 94 commands + language rules upstream. my-claude installs a curated 61-skill subset (79 with the opt-in `web` lane) — stack patterns, AI/agent engineering, codebase tooling — plus 9 rule sets and slash commands like `/tdd`, `/plan`, `/code-review`, `/build-fix`. | Submodule `upstream/ecc`, SHA-pinned; `install.sh` tries `claude plugin add affaan-m/everything-claude-code` first and falls back to the submodule. |
| 5 | <img src="https://www.anthropic.com/favicon.ico" width="20" height="20" align="center"/> **[anthropic/skills](https://github.com/anthropics/skills)** — Anthropic | Anthropic's own skill repository: PDF parsing, Word/Excel/PowerPoint manipulation, MCP server creation. | `claude plugin add anthropics/skills`, run by `install.sh`. Deliberately not manifest-tracked. |
| 6 | <img src="https://github.com/garrytan.png?size=32" width="20" height="20" align="center"/> **[gstack](https://github.com/garrytan/gstack)** — garrytan | Garry Tan's sprint-process harness: 26 skills plus the `gstack` root router (27 total) — browser QA (`/qa`), scope-drift code review (`/review`), security audit (`/cso`), and the full Plan→Review→QA→Ship workflow (Boss P0 lane). Ships a compiled Playwright browser daemon for real-browser testing. | Submodule `upstream/gstack`, SHA-pinned. |
| 7 | <img src="https://github.com/obra.png?size=32" width="20" height="20" align="center"/> **[superpowers](https://github.com/obra/superpowers)** — Jesse Vincent | Jesse Vincent's dev-process library: 14 of its 15 skills — brainstorming, systematic debugging, TDD, plan writing and execution, code-review etiquette. `dispatching-parallel-agents` is excluded because Boss and Agent Teams already own that path. | Submodule `upstream/superpowers`, SHA-pinned. |
| 8 | <img src="https://github.com/getagentseal.png?size=32" width="20" height="20" align="center"/> **[codeburn](https://github.com/getagentseal/codeburn)** — getagentseal | Local-first token and cost tracking over the session files Claude Code and Codex already write — no proxy, no API key, nothing leaves the machine. The budget-guard hooks stay opt-in via `bash install.sh --with-codeburn-guard` because their hard cap ($15/session by default) blocks every tool call in the session, including `codeburn guard allow` (run that from an external terminal). | `npm i -g codeburn@0.9.23`; `install.sh` also starts or reuses one shared cross-harness dashboard — see [Where to See Results](#where-to-see-results). MIT. |
| 9 | <img src="https://github.com/oraios.png?size=32" width="20" height="20" align="center"/> **[serena](https://github.com/oraios/serena)** — oraios | A language server's symbol graph over MCP: `find_symbol`, `get_symbols_overview`, `find_referencing_symbols`, `replace_symbol_body`, `insert_after_symbol` — the tokens spent scale with the symbol, not the file. | `uv tool install -p 3.13 serena-agent==1.7.0`, registered as a user-scope stdio MCP server (`serena start-mcp-server --context claude-code --project-from-cwd`). The distributed package is GPL-3.0-or-later as a whole (PyPI's MIT classifier is inaccurate); used as an external server, never vendored. |
| 10 | <img src="https://github.com/headroomlabs-ai.png?size=32" width="20" height="20" align="center"/> **[headroom](https://github.com/headroomlabs-ai/headroom)** — Headroom Labs | Tool-output compression: `headroom mcp serve` exposes `headroom_compress`, `headroom_retrieve`, and `headroom_stats`, so an oversized tool result never lands in the transcript whole. | `uv tool install --python 3.13 "headroom-ai[all]==0.37.0"`, registered as the `headroom` stdio MCP server; `install.sh` also starts or reuses the mutation-free persistent profile `agent-harness-shared`. Apache-2.0. |
| 11 | <img src="https://github.com/tt-a1i.png?size=32" width="20" height="20" align="center"/> **[archify](https://github.com/tt-a1i/archify)** — tt-a1i | One agent skill that draws architecture, workflow, sequence, data-flow, and lifecycle diagrams as self-contained HTML — inline SVG, a dark/light theme toggle, a PNG/JPEG/WebP/SVG export menu, no runtime dependencies in the generated file. It also accepts pasted Mermaid as an input dialect. | Submodule `upstream/archify`, pinned at tag `v2.9.0`; `install.sh` copies the upstream `archify/` skill directory to `~/.claude/skills/archify`, so no `npx skills add` runs at install time. |
| 12 | <img src="https://github.com/msitarzewski.png?size=32" width="20" height="20" align="center"/> **[agency-agents](https://github.com/msitarzewski/agency-agents)** — msitarzewski | 3 engineering agents with no equivalent elsewhere in the stack: AI Engineer, DevOps Automator, Multi-Agent Systems Architect. | Submodule removed 2026-07-27; the 3 agents were snapshotted into `agents/vendored/` on that date, each file carrying its upstream attribution header. MIT. |
| 13 | <img src="https://github.com/ast-grep.png?size=32" width="20" height="20" align="center"/> **[ast-grep](https://github.com/ast-grep/ast-grep)** — ast-grep | Structural, AST-aware code search and rewrite, so agents match code shapes instead of regex. | `npm i -g @ast-grep/cli@0.42.0`. MIT. |
| 14 | <img src="https://github.com/upstash.png?size=32" width="20" height="20" align="center"/> **[context7](https://github.com/upstash/context7)** — Upstash | Up-to-date, version-accurate library documentation, so an agent reads the real API instead of recalling one. | Hosted MCP server at `https://mcp.context7.com/mcp`, registered by `install.sh`. |
| 15 | <img src="https://github.com/exa-labs.png?size=32" width="20" height="20" align="center"/> **[exa](https://github.com/exa-labs/exa-mcp-server)** — Exa Labs | Neural (semantic) web search for research that keyword search misses. | Hosted MCP server at `https://mcp.exa.ai/mcp`, registered by `install.sh`. |
| 16 | <img src="https://github.com/grep-app.png?size=32" width="20" height="20" align="center"/> **[grep.app](https://github.com/grep-app)** — grep.app | Code search across public GitHub repositories, for finding how a pattern is used in the wild. | Hosted MCP server at `https://mcp.grep.app`, registered by `install.sh`. |

---

## How Boss Works

Boss is the meta-orchestrator at the core of my-claude. It never writes code — it discovers, classifies, matches, delegates, and verifies.

| Phase | What Happens |
|-------|--------------|
| **0 · Discovery** | Scans agents, skills, MCP tools, and hooks at runtime into a live capability registry |
| **1 · Intent gate** | Classifies the request (trivial, build, refactor, mid-sized, architecture, research, …) and counter-proposes a skill when one fits better |
| **2 · Capability matching** | Cascades the priority chain below (P0 gstack skill → P1 exact skill → P2 specialist agent → P3 multi-agent orchestration → P4 general-purpose fallback) |
| **3 · Delegation** | Sends a 6-section structured prompt to the specialist: TASK / OUTCOME / TOOLS / DO / DON'T / CTX |
| **4 · Verification** | Reads the changed files independently, runs tests, lint, and build, cross-references the original intent, retries up to 3× on failure |

### Priority Routing

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

Model choice sets *which* brain runs a task; the `effort:` frontmatter field sets *how hard* it thinks. Every self-owned agent declares one:

| Effort | Agents |
|--------|--------|
| `xhigh` | Boss, Oracle, Prometheus, Multi-Agent Systems Architect |
| `high` | Sisyphus, Hephaestus, Atlas, Metis, Momus |
| `medium` | Librarian, Multimodal-Looker, AI Engineer, DevOps Automator |

Skills declare effort too — `boss-briefing` runs at `medium`, `briefing-vault` at `low`. `boss-advanced` and `gstack-sprint` deliberately declare none: a skill's effort overrides the session level while it runs, which would quietly downgrade Boss mid-flow.

Precedence is `CLAUDE_CODE_EFFORT_LEVEL` (env) > frontmatter > session effort level. `xhigh` is Fable's supported ceiling; `max` is Opus-class only and silently falls back elsewhere.

### 3-Phase Sprint Workflow

For end-to-end feature implementation, Boss orchestrates a structured sprint:

| Phase | Mode | What Happens |
|-------|------|--------------|
| **1 · Design** | interactive | User decides scope · engineering review · confirm "design done" |
| **2 · Execute** | autonomous | ralph runs execution · auto code review · architect verification |
| **3 · Review** | interactive | Compare against the design doc · present comparison table · user approves or asks for improvement |

### Structured Final Report

Boss closes every working turn — one that edited files, made commits/PRs, changed configuration, or ran verification — with a structured report the reader can scan without opening a diff. Each table is emitted only when its situation actually occurred (never an empty table):

| Situation | Table | Columns |
|-----------|-------|---------|
| Files/settings changed | Changes | Target / Before / After / Rationale |
| Multiple tasks completed | Work summary | Item / Result / Evidence |
| Verification was run | Verification | Item / Expected / Actual / Verdict |
| Commits/PRs produced | Deliverables | PR / Repo / Content / Status |
| Anything unresolved | Remaining | Item / Status / Next step |

It fires only at the very end of the request — never on a turn that launches or relays background work, never as a mid-task progress update — and pure Q&A turns end normally without it. The spec lives in `boss.md § FINAL REPORT`; the `stop-final-report.js` Stop hook enforces it, judging from the harness-provided `last_assistant_message` plus the turn's origin in the transcript, blocking at most once per turn and failing open on any error.

### Named Workflows

Deterministic multi-agent workflows. `install.sh` copies them to `~/.claude/workflows/`, so they run from any project through the Workflow tool — not just from this repo.

| Workflow | What It Does | Invocation |
|----------|--------------|------------|
| **code-review-fanout** | Four dimension reviewers (correctness, security, performance, tests) fan out in parallel, then every finding is adversarially verified before it is reported | `Workflow({name: "code-review-fanout"})` — args: the review target (branch, commit range, paths). Defaults to the working-tree diff |
| **upstream-audit** | One analyst per upstream — pin delta vs origin, allowlist fit, new overlaps, security signals, health — followed by a synthesized action list | `Workflow({name: "upstream-audit"})` — for quarterly or pre-sync audits |

---

## What's Inside

| Category | Count | Source |
|----------|------:|--------|
| **Agents** (always loaded) | 32 | Boss 1 + OMO 9 + OMC 19 + Vendored 3 |
| **Skills** | 106 | ECC 61 · gstack 27 · Superpowers 14 · Core 4. ECC's 18-skill `web` lane is opt-in (`--skills=web`); OMC's 16 come from the OMC plugin and are never copied |
| **Rules** | 48 files / 9 sets | ECC 46 (3 common files + 8 language dirs) + Core 2 |
| **MCP Servers** | 3 | Context7, Exa, grep.app |
| **Hooks** | 10 files / 6 events | Delegation guard, telemetry, verification, vault, context budget |
| **LSP Servers** | 2 | typescript (`typescript-language-server`), python (`pyright-langserver`) |
| **Named Workflows** | 2 | code-review-fanout, upstream-audit |
| **Upstream submodules** | 5 | ecc, omc, gstack, superpowers, archify |
| **CLI Tools** | 7 | omc, omo, ast-grep, comment-checker, codeburn, serena, headroom |

Every agent, skill, and rule above is allowlisted in [`scripts/skill-allowlists.sh`](./scripts/skill-allowlists.sh) and tracked in the install manifest. Anthropic's official document skills (pdf, docx, …) are added separately via `claude plugin add anthropics/skills` and are deliberately not manifest-tracked.

<details>
<summary><strong>Specialist Agents — 32 across 4 tiers</strong></summary>

Per-agent models are in [Model Routing](#model-routing); where each source comes from is in [Open-Source Tools Used](#open-source-tools-used).

| Agent | Tier | Role | Source |
|-------|------|------|--------|
| Boss | core | Dynamic runtime discovery → capability matching → optimal routing. Never writes code. | my-claude |
| Sisyphus | omo | Intent classification → specialist delegation → verification | [oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent) |
| Hephaestus | omo | Autonomous explore → plan → execute → verify | oh-my-openagent |
| Atlas | omo | Task decomposition + 4-stage QA verification | oh-my-openagent |
| Oracle | omo | Strategic technical consulting (read-only) | oh-my-openagent |
| Metis | omo | Intent analysis, ambiguity detection | oh-my-openagent |
| Momus | omo | Plan feasibility review | oh-my-openagent |
| Prometheus | omo | Interview-based detailed planning | oh-my-openagent |
| Librarian | omo | Open-source documentation search via MCP | oh-my-openagent |
| Multimodal-Looker | omo | Image/screenshot/diagram analysis | oh-my-openagent |
| analyst | omc | Pre-analysis before planning | [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) |
| architect | omc | System design and architecture | oh-my-claudecode |
| code-reviewer | omc | Focused code review | oh-my-claudecode |
| code-simplifier | omc | Code simplification and cleanup | oh-my-claudecode |
| critic | omc | Critical analysis, alternative proposals | oh-my-claudecode |
| debugger | omc | Focused debugging | oh-my-claudecode |
| designer | omc | UI/UX design guidance | oh-my-claudecode |
| document-specialist | omc | Documentation writing | oh-my-claudecode |
| executor | omc | Task execution | oh-my-claudecode |
| explore | omc | Codebase exploration | oh-my-claudecode |
| git-master | omc | Git workflow management | oh-my-claudecode |
| planner | omc | Rapid planning | oh-my-claudecode |
| qa-tester | omc | Quality assurance testing | oh-my-claudecode |
| scientist | omc | Research and experimentation | oh-my-claudecode |
| security-reviewer | omc | Security review | oh-my-claudecode |
| test-engineer | omc | Test writing and maintenance | oh-my-claudecode |
| tracer | omc | Execution tracing and analysis | oh-my-claudecode |
| verifier | omc | Final verification | oh-my-claudecode |
| writer | omc | Content and documentation | oh-my-claudecode |
| AI Engineer | vendored | AI/ML engineering, model integration, data pipelines | agency-agents (vendored) |
| DevOps Automator | vendored | Infrastructure automation, CI/CD, cloud operations | agency-agents (vendored) |
| Multi-Agent Systems Architect | vendored | Agent topology, context management, failure recovery | agency-agents (vendored) |

</details>

<details>
<summary><strong>Skills — 106 from 4 sources</strong></summary>

| Source | Count | Key Skills |
|--------|------:|------------|
| [everything-claude-code](https://github.com/affaan-m/everything-claude-code) | 61 | coding-standards, fastapi-patterns, agent-architecture-audit, springboot-patterns, kubernetes-patterns |
| [gstack](https://github.com/garrytan/gstack) | 27 | /qa, /review, /ship, /cso, /investigate, /office-hours |
| [superpowers](https://github.com/obra/superpowers) | 14 | brainstorming, systematic-debugging, test-driven-development, writing-plans |
| [my-claude Core](https://github.com/sehoon787/my-claude) | 4 | boss-advanced, boss-briefing, briefing-vault, gstack-sprint |

**Opt-in `web` lane (+18)** — `accessibility`, `bun-runtime`, `e2e-testing`, `frontend-a11y`, `frontend-patterns`, `motion-*` (3), `nestjs-patterns`, `nextjs-turbopack`, `nuxt4-patterns`, `react-patterns`, `react-performance`, `react-testing`, `ui-to-vue`, `vite-patterns`, `vue-patterns`, `windows-desktop-e2e`. Browser-UI work only; see [Installation](#installation) for the flags.

**OMC skills are not copied.** `install.sh` enables the `oh-my-claudecode@omc` plugin, which already exposes all 16 (`autopilot`, `ralph`, `team`, `ultrawork`, `ralplan`, `omc-reference`, …) as `oh-my-claudecode:<name>`. A local copy would put a second description of the same skill in every session. Routing surfaces use the prefixed name; a bare `ralph` does not resolve.

</details>

<details>
<summary><strong>MCP Servers (3) + Hooks (10)</strong></summary>

**MCP Servers** — what each one does and how it is registered is in [Open-Source Tools Used](#open-source-tools-used).

| Server | Cost |
|--------|------|
| <img src="https://context7.com/favicon.ico" width="16" height="16" align="center"/> [Context7](https://context7.com) | Free |
| <img src="https://exa.ai/images/favicon-32x32.png" width="16" height="16" align="center"/> [Exa](https://exa.ai) | Free 1k req/month |
| <img src="https://www.google.com/s2/favicons?domain=grep.app&sz=32" width="16" height="16" align="center"/> [grep.app](https://github.com/grep-app) | Free |

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

The plugin declares two language servers in `.lsp.json`. Claude Code starts them on demand, so agents get diagnostics and code navigation instantly instead of paying for a build round-trip. `install.sh` installs both binaries non-fatally — if one is unavailable, only that server is disabled and the rest of the install continues.

| Server | Command | Extensions |
|--------|---------|------------|
| typescript | `typescript-language-server --stdio` | `.ts` `.tsx` `.js` `.jsx` `.mjs` `.cjs` |
| python | `pyright-langserver --stdio` | `.py` |

</details>

---

## <img src="https://obsidian.md/images/obsidian-logo-gradient.svg" width="24" height="24" align="center"/> Briefing Vault

Obsidian-compatible persistent memory. Every project maintains a `.briefing/` directory that auto-populates across sessions. Every path below is created and maintained by hooks:

| Path | Description |
|------|-------------|
| `INDEX.md` | Project overview with links to recent decisions and learnings. Auto-created on first session, refreshed by /boss-briefing or Stop hook fallback. |
| `state.json` | Session metadata: counters (workCounter, messageCount), lastVaultSync timestamp, sessionStartHead. Auto-managed by hooks. |
| `sessions/` | **Session summaries**, named `YYYY-MM-DD-<topic>.md`. `YYYY-MM-DD-auto.md` — scaffold with git diff stats and agent counts. `<topic>.md` — AI-written summary enforced by Stop hook guard. |
| `decisions/` | **Architecture and design decisions** with rationale, as `YYYY-MM-DD-<decision>.md`. AI-written, enforced during active work. |
| `learnings/` | **Patterns, gotchas, non-obvious solutions**, as `YYYY-MM-DD-<pattern>.md`. `*-auto-session.md` — scaffold with file lists. `<topic>.md` — AI-written. |
| `references/` | **Web research URLs.** `auto-links.md` — auto-collected from WebSearch/WebFetch calls. |
| `agents/` | **Agent telemetry.** `agent-log.jsonl` — per-call log with enriched fields `{ts, agent_type, phase, seq, task_hint}`. `YYYY-MM-DD-summary.md` — daily usage breakdown. |
| `persona/` | **User work style profile.** `profile.md` — tool affinity stats. `suggestions.jsonl` — routing recommendations. Workflow sequence patterns in `rules/workflow-*.md`. Run /boss-briefing to analyze. |
| `archives/` | PARA Archives (flat) — completed sessions (30+ days), superseded decisions, inactive learnings |
| `wiki/` | LLM-wiki concept pages (`_schema.md` holds the page schema) — distilled knowledge from multiple sessions |

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

The Stop hook checks whether `/boss-briefing` has run today. If not, it blocks session end with a reminder. The existing `stop-profile-update.js` continues to run as a fallback. A second Stop hook, `stop-final-report.js`, enforces the [Structured Final Report](#structured-final-report).

---

## Where to See Results

Every tool in this stack writes its output somewhere. This is where. What each
tool is, is in [Open-Source Tools Used](#open-source-tools-used).

| Tool | How to Run | Where to Look |
|------|-----------|---------------|
| **codeburn** | `install.sh` starts or reuses `codeburn web --provider all --port 4747 --no-open` · `codeburn` opens the TUI · `codeburn report --format json --period week` emits a non-interactive dump (also `--day`, `--from`/`--to`, `--provider claude`) | Shared dashboard at <http://127.0.0.1:4747/>; startup log `${XDG_STATE_HOME:-$HOME/.local/state}/agent-harness-services/logs/codeburn.log`. Session files are read-only and dollar figures are **estimates** at API list rates — on a subscription plan a usage proxy, not a bill. |
| **Serena** | Starts automatically as an MCP server; call `get_symbols_overview` / `find_symbol` from any session | Dashboard at <http://localhost:24282/dashboard/index.html> while a server is running (logs + per-tool call counts). Per-project memories land in `.serena/` inside the repository you are working on; the global config is `~/.serena/serena_config.yml`. |
| **Headroom** | MCP tools `headroom_compress` / `headroom_retrieve` / `headroom_stats`; `install.sh` starts or reuses the shared `agent-harness-shared` proxy profile | Stats at <http://127.0.0.1:8787/stats> (empty until a client explicitly routes through the proxy); startup log `${XDG_STATE_HOME:-$HOME/.local/state}/agent-harness-services/logs/headroom.log`. |
| **Archify** | Ask for a diagram and Boss routes to the `archify` skill. Manually, from `~/.claude/skills/archify`: `node bin/archify.mjs render workflow examples/agent-tool-call.workflow.json out.html` | The generated `out.html` — open it in any browser. Validate one with `node bin/archify.mjs check out.html`. |
| **OMC HUD** | Installed as the statusline by `install.sh`; `/oh-my-claudecode:hud` reconfigures it | The Claude Code statusline at the bottom of the session, with a live context, quota, and mode readout. Complements codeburn: the HUD is this session, codeburn is every session. |

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
| **Curated Allowlists** | `scripts/skill-allowlists.sh` is the single source of truth — 106 skills, 3 always-on common rules and 8 path-scoped language rule sets survive from thousands upstream, so nothing unlisted ever reaches a session's context |
| **Briefing Vault** | Obsidian-compatible `.briefing/` directory with sessions, decisions, learnings, references |
| **Agent Telemetry** | PostToolUse hook logs agent usage to `agent-usage.jsonl` |
| **No-op Sync Skip** | Upstream sync stages the submodule bumps and `SOURCES.json` pins, then opens a PR only when that staged diff is non-empty |
| **Agent Dedup Detection** | `tests/validate-sync.sh` compares agent filenames across `agents/` and the omc/superpowers submodules and reports collisions |

---

## Bundled Upstream Versions

Linked via git submodules. Pinned commits are tracked natively by `.gitmodules` and mirrored as an AI-BOM in [`upstream/SOURCES.json`](./upstream/SOURCES.json); `install.sh` checks out these exact SHAs rather than tracking `main`.

| Source | SHA | Date | Diff |
|--------|-----|------|------|
| [everything-claude-code](https://github.com/affaan-m/everything-claude-code) | `07756ce` | 2026-09-19 | [compare](https://github.com/affaan-m/everything-claude-code/compare/07756ce...HEAD) |
| [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) | `5281b19` | 2026-09-13 | [compare](https://github.com/Yeachan-Heo/oh-my-claudecode/compare/5281b19...HEAD) |
| [gstack](https://github.com/garrytan/gstack) | `a6b3a57` | 2026-09-16 | [compare](https://github.com/garrytan/gstack/compare/a6b3a57...HEAD) |
| [superpowers](https://github.com/obra/superpowers) | `5bf4e78` | 2026-09-19 | [compare](https://github.com/obra/superpowers/compare/5bf4e78...HEAD) |
| [archify](https://github.com/tt-a1i/archify) | `62904f3` (`v2.9.0`) | 2026-09-19 | [compare](https://github.com/tt-a1i/archify/compare/62904f3...HEAD) |

---

## Contributing

Issues and PRs are welcome. When adding a new agent, add a `.md` file to `agents/core/` or `agents/omo/` and update `SETUP.md`.

## Credits

Built on the projects listed in [Open-Source Tools Used](#open-source-tools-used); thank you to every author.

## License

MIT License. See the [LICENSE](./LICENSE) file for details.
