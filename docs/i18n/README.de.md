[English](../../README.md) | [한국어](./README.ko.md) | [日本語](./README.ja.md) | [中文](./README.zh.md) | [Deutsch](./README.de.md) | [Français](./README.fr.md)

> [![Codex CLI](https://img.shields.io/badge/Codex_CLI-my--codex-10b981?style=flat-square&logo=openai&logoColor=white)](https://github.com/sehoon787/my-codex) Suchen Sie nach Codex CLI? → **my-codex** — dieselbe Orchestrierung im nativen TOML-Format

---

<div align="center">

# my-claude

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Agents](https://img.shields.io/badge/agents-200%2B-blue)
![Skills](https://img.shields.io/badge/skills-200%2B-purple)
![Rules](https://img.shields.io/badge/rules-87-orange)
![MCP Servers](https://img.shields.io/badge/MCP-3-green)
![Hooks](https://img.shields.io/badge/hooks-7-red)

**All-in-one Agent-Harness für Claude Code.**
**Ein Plugin, 200+ Agenten bereit.**

Boss entdeckt automatisch zur Laufzeit jeden Agenten, jede Skill und jedes MCP-Tool,<br>
und leitet Ihre Aufgabe an den richtigen Spezialisten weiter. Keine Konfigurationsdateien. Kein Boilerplate.

<img src="./assets/owl-claude-social.svg" alt="The Maestro Owl — my-claude" width="700">

</div>

---

## Installation

### Für Menschen

```bash
git clone --depth 1 https://github.com/sehoon787/my-claude.git /tmp/my-claude
bash /tmp/my-claude/install.sh
rm -rf /tmp/my-claude
```

Oder installieren Sie es zunächst als Claude Code-Plugin und führen Sie dann das begleitende Installationsprogramm aus:

```bash
# Inside a Claude Code session:
/plugin marketplace add sehoon787/my-claude
/plugin install my-claude@my-claude

# Then install companion tools:
git clone --depth 1 https://github.com/sehoon787/my-claude.git /tmp/my-claude
bash /tmp/my-claude/install.sh
rm -rf /tmp/my-claude
```

### Für KI-Agenten

```bash
curl -s https://raw.githubusercontent.com/sehoon787/my-claude/main/AI-INSTALL.md
```

Lesen Sie die VOLLSTÄNDIGE Ausgabe, und führen Sie dann jeden Schritt der Reihe nach aus. Verwenden Sie `curl`, NICHT `WebFetch`.

---

## Wie Boss funktioniert

Boss ist der Meta-Orchestrator im Kern von my-claude. Er schreibt niemals Code — er entdeckt, klassifiziert, ordnet zu, delegiert und verifiziert.

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

### Prioritäts-Routing

Boss leitet jede Anfrage durch eine Prioritätskette, bis die beste Übereinstimmung gefunden wird:

| Priorität | Übereinstimmungstyp | Wann | Beispiel |
|:---------:|---------------------|------|----------|
| **P1** | Skill-Treffer | Aufgabe entspricht einer eigenständigen Skill | `"merge PDFs"` → pdf skill |
| **P2** | Spezialist-Agent | Domänenspezifischer Agent vorhanden | `"security audit"` → Security Engineer |
| **P3a** | Boss direkt | 2–4 unabhängige Agenten | `"fix 3 bugs"` → parallel spawn |
| **P3b** | Sub-Orchestrator | Komplexer mehrstufiger Workflow | `"refactor + test"` → Sisyphus |
| **P3c** | Agent Teams | Peer-to-Peer-Kommunikation erforderlich | `"implement + review"` → Review Chain |
| **P4** | Fallback | Kein Spezialist gefunden | `"explain this"` → general agent |

### Modell-Routing

| Komplexität | Modell | Verwendet für |
|-------------|--------|---------------|
| Tiefgehende Analyse, Architektur | Opus | Boss, Oracle, Sisyphus |
| Standardimplementierung | Sonnet | executor, debugger, security-reviewer |
| Schnelle Suche, Erkundung | Haiku | explore, einfache Beratung |

### 3-Phasen-Sprint-Workflow

Für die Ende-zu-Ende-Funktionsimplementierung orchestriert Boss einen strukturierten Sprint:

```
Phase 1: DESIGN         Phase 2: EXECUTE        Phase 3: REVIEW
(interactive)            (autonomous)             (interactive)
─────────────────────   ─────────────────────   ─────────────────────
User decides scope      ralph runs execution    Compare vs design doc
Engineering review      Auto code review        Present comparison table
Confirm "design done"   Architect verification  User: approve / improve
```

---

## Architektur

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

## Was enthalten ist

| Kategorie | Anzahl | Quelle |
|-----------|-------:|--------|
| **Kern-Agenten** (immer geladen) | 56 | Boss 1 + OMO 9 + OMC 19 + Agency Engineering 26 + Superpowers 1 |
| **Agenten-Packs** (on-demand) | 136 | 12 Domänenkategorien aus agency-agents |
| **Skills** | 200+ | ECC 180+ · OMC 36 · gstack 40 · Superpowers 14 · Core 3 |
| **Anthropic Skills** | 14+ | PDF, DOCX, PPTX, XLSX, MCP builder |
| **Regeln** | 87 | ECC common + 14 Sprachverzeichnisse |
| **MCP-Server** | 3 | Context7, Exa, grep.app |
| **Hooks** | 7 | Delegationswächter, Telemetrie, Verifikation |
| **CLI-Tools** | 3 | omc, omo, ast-grep |

<details>
<summary><strong>Kern-Agent — Boss Meta-Orchestrator (1)</strong></summary>

| Agent | Modell | Rolle | Quelle |
|-------|--------|-------|--------|
| Boss | Opus | Dynamische Laufzeitentdeckung → Fähigkeitsabgleich → optimales Routing. Schreibt niemals Code. | my-claude |

</details>

<details>
<summary><strong>OMO-Agenten — Sub-Orchestratoren und Spezialisten (9)</strong></summary>

| Agent | Modell | Rolle | Quelle |
|-------|--------|-------|--------|
| Sisyphus | Opus | Absichtsklassifizierung → Spezialistendelegation → Verifikation | [oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent) |
| Hephaestus | Opus | Autonom erkunden → planen → ausführen → verifizieren | oh-my-openagent |
| Atlas | Opus | Aufgabenzerlegung + 4-stufige QA-Verifikation | oh-my-openagent |
| Oracle | Opus | Strategische technische Beratung (nur lesend) | oh-my-openagent |
| Metis | Opus | Absichtsanalyse, Mehrdeutigkeitserkennung | oh-my-openagent |
| Momus | Opus | Überprüfung der Planumsetzbarkeit | oh-my-openagent |
| Prometheus | Opus | Interviewbasierte detaillierte Planung | oh-my-openagent |
| Librarian | Sonnet | Open-Source-Dokumentationssuche über MCP | oh-my-openagent |
| Multimodal-Looker | Sonnet | Bild-/Screenshot-/Diagrammanalyse | oh-my-openagent |

</details>

<details>
<summary><strong>OMC-Agenten — Spezialistenmitarbeiter (19)</strong></summary>

| Agent | Rolle | Quelle |
|-------|-------|--------|
| analyst | Voranalyse vor der Planung | [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) |
| architect | Systemdesign und Architektur | oh-my-claudecode |
| code-reviewer | Fokussierter Code-Review | oh-my-claudecode |
| code-simplifier | Code-Vereinfachung und -Bereinigung | oh-my-claudecode |
| critic | Kritische Analyse, alternative Vorschläge | oh-my-claudecode |
| debugger | Fokussiertes Debugging | oh-my-claudecode |
| designer | UI/UX-Design-Anleitung | oh-my-claudecode |
| document-specialist | Dokumentationserstellung | oh-my-claudecode |
| executor | Aufgabenausführung | oh-my-claudecode |
| explore | Codebasis-Erkundung | oh-my-claudecode |
| git-master | Git-Workflow-Verwaltung | oh-my-claudecode |
| planner | Schnelle Planung | oh-my-claudecode |
| qa-tester | Qualitätssicherungstests | oh-my-claudecode |
| scientist | Forschung und Experimente | oh-my-claudecode |
| security-reviewer | Sicherheitsüberprüfung | oh-my-claudecode |
| test-engineer | Test-Erstellung und -Pflege | oh-my-claudecode |
| tracer | Ausführungs-Tracing und Analyse | oh-my-claudecode |
| verifier | Abschließende Verifikation | oh-my-claudecode |
| writer | Inhalte und Dokumentation | oh-my-claudecode |

</details>

<details>
<summary><strong>Agency Engineering — Immer geladene Spezialisten (26)</strong></summary>

| Agent | Rolle | Quelle |
|-------|-------|--------|
| AI Engineer | KI/ML-Engineering | [agency-agents](https://github.com/msitarzewski/agency-agents) |
| Backend Architect | Backend-Architektur | agency-agents |
| CMS Developer | CMS-Entwicklung | agency-agents |
| Code Reviewer | Code-Review | agency-agents |
| Data Engineer | Datentechnik | agency-agents |
| Database Optimizer | Datenbankoptimierung | agency-agents |
| DevOps Automator | DevOps-Automatisierung | agency-agents |
| Embedded Firmware Engineer | Eingebettete Firmware | agency-agents |
| Frontend Developer | Frontend-Entwicklung | agency-agents |
| Git Workflow Master | Git-Workflow | agency-agents |
| Incident Response Commander | Incident Response | agency-agents |
| Mobile App Builder | Mobile Apps | agency-agents |
| Rapid Prototyper | Schnelles Prototyping | agency-agents |
| Security Engineer | Sicherheitstechnik | agency-agents |
| Senior Developer | Senior-Entwicklung | agency-agents |
| Software Architect | Software-Architektur | agency-agents |
| SRE | Site Reliability | agency-agents |
| Technical Writer | Technische Dokumentation | agency-agents |
| AI Data Remediation Engineer | Selbstheilende Datenpipelines | agency-agents |
| Autonomous Optimization Architect | API-Performance-Governance | agency-agents |
| Email Intelligence Engineer | E-Mail-Datenextraktion | agency-agents |
| Feishu Integration Developer | Feishu/Lark-Plattform | agency-agents |
| Filament Optimization Specialist | Filament PHP-Optimierung | agency-agents |
| Solidity Smart Contract Engineer | EVM Smart Contracts | agency-agents |
| Threat Detection Engineer | SIEM & Bedrohungsjagd | agency-agents |
| WeChat Mini Program Developer | WeChat 小程序 | agency-agents |

</details>

<details>
<summary><strong>Agenten-Packs — On-demand-Domänenspezialisten (136)</strong></summary>

Installiert in `~/.claude/agent-packs/`. Durch Symlink aktivieren:

```bash
ln -s ~/.claude/agent-packs/marketing/*.md ~/.claude/agents/
```

| Pack | Anzahl | Beispiele | Quelle |
|------|-------:|-----------|--------|
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
<summary><strong>Skills — 200+ aus 6 Quellen</strong></summary>

| Quelle | Anzahl | Wichtige Skills |
|--------|-------:|-----------------|
| [everything-claude-code](https://github.com/affaan-m/everything-claude-code) | 180+ | tdd-workflow, autopilot, ralph, security-review, coding-standards |
| [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) | 36 | plan, team, trace, deep-dive, blueprint, ultrawork |
| [gstack](https://github.com/garrytan/gstack) | 40 | /qa, /review, /ship, /cso, /investigate, /office-hours |
| [superpowers](https://github.com/obra/superpowers) | 14 | brainstorming, systematic-debugging, TDD, parallel-agents |
| [my-claude Core](https://github.com/sehoon787/my-claude) | 3 | boss-advanced, gstack-sprint, briefing-vault |
| [Anthropic Official](https://github.com/anthropics/skills) | 14+ | pdf, docx, pptx, xlsx, canvas-design, mcp-builder |

</details>

<details>
<summary><strong>MCP-Server (3) + Hooks (7)</strong></summary>

**MCP-Server**

| Server | Zweck | Kosten |
|--------|-------|--------|
| <img src="https://context7.com/favicon.ico" width="16" height="16" align="center"/> [Context7](https://mcp.context7.com) | Echtzeit-Bibliotheksdokumentation | Kostenlos |
| <img src="https://exa.ai/images/favicon-32x32.png" width="16" height="16" align="center"/> [Exa](https://mcp.exa.ai) | Semantische Websuche | Kostenlos 1k Anfragen/Monat |
| <img src="https://www.google.com/s2/favicons?domain=grep.app&sz=32" width="16" height="16" align="center"/> [grep.app](https://mcp.grep.app) | GitHub-Code-Suche | Kostenlos |

**Verhaltens-Hooks**

| Hook | Ereignis | Verhalten |
|------|----------|-----------|
| Session Setup | SessionStart | Erkennt automatisch fehlende Tools + injiziert Briefing Vault-Kontext |
| Delegation Guard | PreToolUse | Verhindert, dass Boss Dateien direkt ändert |
| Agent Telemetry | PostToolUse | Protokolliert Agentennutzung in `agent-usage.jsonl` |
| Subagent Verifier | SubagentStop | Erzwingt unabhängige Verifikation + Protokollierung in Briefing Vault |
| Completion Check | Stop | Bestätigt verifizierte Aufgaben + fordert Sitzungszusammenfassung an |
| Teammate Idle Guide | TeammateIdle | Benachrichtigt Teamleiter über inaktive Teammitglieder |
| Task Quality Gate | TaskCompleted | Prüft die Qualität des Lieferergebnisses |

</details>

---

## <img src="https://obsidian.md/images/obsidian-logo-gradient.svg" width="24" height="24" align="center"/> Briefing Vault

Obsidian-kompatibler persistenter Speicher. Jedes Projekt pflegt ein `.briefing/`-Verzeichnis, das sich über Sitzungen hinweg automatisch befüllt.

```
.briefing/
├── INDEX.md                          ← Project context (auto-created once)
├── sessions/
│   ├── YYYY-MM-DD-<topic>.md        ← AI-written session summary (enforced)
│   └── YYYY-MM-DD-auto.md           ← Auto-generated scaffold (git diff, agent stats)
├── decisions/
│   ├── YYYY-MM-DD-<decision>.md     ← AI-written decision record
│   └── YYYY-MM-DD-auto.md           ← Auto-generated scaffold (commits, files)
├── learnings/
│   ├── YYYY-MM-DD-<pattern>.md      ← AI-written learning note
│   └── YYYY-MM-DD-auto-session.md   ← Auto-generated scaffold (agents, files)
├── references/
│   └── auto-links.md                ← Auto-collected URLs from web searches
├── agents/
│   ├── agent-log.jsonl              ← Subagent execution telemetry
│   └── YYYY-MM-DD-summary.md        ← Daily agent usage breakdown
└── persona/
    ├── profile.md                   ← Agent affinity stats (auto-updated)
    ├── suggestions.jsonl            ← Routing suggestions (auto-generated)
    ├── rules/                       ← Accepted routing preferences
    └── skills/                      ← Accepted persona skills
```

### Automatisierungs-Lebenszyklus

| Phase | Hook-Ereignis | Was passiert |
|-------|--------------|--------------|
| **Sitzungsstart** | `SessionStart` | Erstellt `.briefing/`-Struktur, speichert git-HEAD-Hash für sitzungsspezifische Diffs |
| **Während der Arbeit** | `PostToolUse` Edit/Write | Verfolgt die Anzahl der Dateibearbeitungen; warnt bei 5, sperrt bei 15, wenn keine Entscheidungen/Lernnotizen geschrieben wurden |
| **Während der Arbeit** | `PostToolUse` WebSearch/WebFetch | Sammelt URLs automatisch in `references/auto-links.md` |
| **Während der Arbeit** | `SubagentStop` | Protokolliert Agentenausführung in `agents/agent-log.jsonl` |
| **Während der Arbeit** | `UserPromptSubmit` (every 5th) | Gedrosseltes Persona-Profil-Update |
| **Sitzungsende** | `Stop` (1. Hook) | Generiert automatisch Gerüste: `sessions/auto.md`, `learnings/auto-session.md`, `decisions/auto.md`, `persona/profile.md` |
| **Sitzungsende** | `Stop` (2. Hook) | **Erzwingt** KI-erstellte Sitzungszusammenfassung bei ≥ 3 Dateibearbeitungen — blockiert Sitzungsende mit Vorlage |

### Automatisch generiert vs. KI-erstellt

| Typ | Dateimuster | Erstellt von | Inhalt |
|-----|-------------|-------------|--------|
| **Auto-Gerüst** | `*-auto.md`, `*-auto-session.md` | Stop hook (Node.js) | Git-Diff-Statistiken, Agentennutzung, Commit-Liste — nur Daten |
| **KI-Zusammenfassung** | `YYYY-MM-DD-<topic>.md` | KI während der Sitzung | Aussagekräftige Analyse mit Kontext, Code-Referenzen, Begründung |
| **Telemetrie** | `agent-log.jsonl`, `auto-links.md` | Hook-Skripte | Nur-Anhänge-strukturierte Protokolle |
| **Persona** | `profile.md`, `suggestions.jsonl` | Stop hook | Nutzungsbasierte Agenten-Affinität und Routing-Vorschläge |

Auto-Gerüste dienen als **Referenzdaten** für die KI zum Verfassen angemessener Zusammenfassungen. Der Durchsetzungs-Hook stellt den Gerüstinhalt + eine strukturierte Vorlage bereit, wenn das Sitzungsende blockiert wird.

### Sitzungsspezifische Diffs

Beim Sitzungsstart wird der aktuelle git-HEAD in `.briefing/.session-start-head` gespeichert. Am Sitzungsende werden Diffs relativ zu diesem gespeicherten Punkt berechnet — es werden nur Änderungen aus der aktuellen Sitzung angezeigt, keine angesammelten nicht committeten Änderungen aus vorherigen Sitzungen.

### Verwendung mit Obsidian

1. Öffnen Sie Obsidian → **Ordner als Vault öffnen** → `.briefing/` auswählen
2. Notizen erscheinen in der Graphansicht, verknüpft durch `[[wiki-links]]`
3. YAML-Frontmatter (`date`, `type`, `tags`) ermöglicht strukturierte Suche
4. Eine Zeitleiste von Entscheidungen und Lernnotizen entsteht automatisch über Sitzungen hinweg

---

## Upstream Open-Source-Quellen

my-claude bündelt Inhalte aus 5 MIT-lizenzierten Upstream-Repositories über git-Submodule:

| # | Quelle | Was bereitgestellt wird |
|---|--------|------------------------|
| 1 | <img src="https://github.com/Yeachan-Heo.png?size=32" width="20" height="20" align="center"/> **[oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode)** — Yeachan Heo | 19 Spezialisten-Agenten + 36 Skills. Claude Code Multi-Agent-Harness mit autopilot, ralph und Team-Orchestrierung. |
| 2 | <img src="https://github.com/code-yeongyu.png?size=32" width="20" height="20" align="center"/> **[oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent)** — code-yeongyu | 9 OMO-Agenten (Sisyphus, Atlas, Oracle usw.). Multi-Plattform-Agent-Harness, der Claude, GPT und Gemini verbindet. |
| 3 | <img src="https://github.com/affaan-m.png?size=32" width="20" height="20" align="center"/> **[everything-claude-code](https://github.com/affaan-m/everything-claude-code)** — affaan-m | 180+ Skills + 87 Regeln in 14 Sprachen. Umfassendes Entwicklungsframework mit TDD, Sicherheit und Coding-Standards. |
| 4 | <img src="https://github.com/msitarzewski.png?size=32" width="20" height="20" align="center"/> **[agency-agents](https://github.com/msitarzewski/agency-agents)** — msitarzewski | 26 Engineering-Agenten (immer geladen) + 136 Domänen-Agenten-Packs in 12 Kategorien. |
| 5 | <img src="https://github.com/garrytan.png?size=32" width="20" height="20" align="center"/> **[gstack](https://github.com/garrytan/gstack)** — garrytan | 40 Skills für Code-Review, QA, Sicherheits-Audit und Deployment. Enthält Playwright-Browser-Daemon. |
| 6 | <img src="https://github.com/obra.png?size=32" width="20" height="20" align="center"/> **[superpowers](https://github.com/obra/superpowers)** — Jesse Vincent | 14 Skills + 1 Agent zu Brainstorming, TDD, parallelen Agenten und Code-Review. |
| 7 | <img src="https://www.anthropic.com/favicon.ico" width="20" height="20" align="center"/> **[anthropic/skills](https://github.com/anthropics/skills)** — Anthropic | 14+ offizielle Skills für PDF, DOCX, PPTX, XLSX und MCP builder. |
| 8 | <img src="https://github.com/forrestchang.png?size=32" width="20" height="20" align="center"/> **[andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills)** — forrestchang | 4 KI-Coding-Verhaltensrichtlinien (Think Before Coding, Simplicity First, Surgical Changes, Goal-Driven Execution). |

---

## GitHub Actions

| Workflow | Auslöser | Zweck |
|----------|----------|-------|
| **CI** | push, PR | Validiert JSON-Konfigurationen, Agent-Frontmatter, Skill-Existenz, Upstream-Dateianzahlen |
| **Update Upstream** | wöchentlich / manuell | Führt `git submodule update --remote` aus und erstellt einen Auto-Merge-PR |
| **Auto Tag** | push to main | Liest die `plugin.json`-Version und erstellt ein git-Tag, wenn neu |
| **Pages** | push to main | Deployt `docs/index.html` auf GitHub Pages |
| **CLA** | PR | Prüfung des Contributor License Agreement |
| **Lint Workflows** | push, PR | Validiert die YAML-Syntax der GitHub Actions-Workflows |

---

## my-claude Originals

Funktionen, die speziell für dieses Projekt entwickelt wurden und über das hinausgehen, was Upstream-Quellen bieten:

| Funktion | Beschreibung |
|----------|-------------|
| **Boss Meta-Orchestrator** | Dynamische Fähigkeitsentdeckung → Absichtsklassifizierung → 5-Prioritäten-Routing → Delegation → Verifikation |
| **3-Phasen-Sprint** | Design (interaktiv) → Ausführung (autonom über ralph) → Review (interaktiv vs. Design-Dokument) |
| **Agenten-Tier-Priorität** | core > omo > omc > agency-Deduplizierung. Der speziellste Agent gewinnt. |
| **Agency-Kostenoptimierung** | Haiku für Beratung, Sonnet für Implementierung — automatisches Modell-Routing für 172 Domänen-Agenten |
| **Briefing Vault** | Obsidian-kompatibles `.briefing/`-Verzeichnis mit Sitzungen, Entscheidungen, Lernnotizen und Referenzen |
| **Agenten-Telemetrie** | PostToolUse-Hook protokolliert Agentennutzung in `agent-usage.jsonl` |
| **Smart Packs** | Projekttypenerkennung empfiehlt relevante Agenten-Packs beim Sitzungsstart |
| **CI SHA-Vorprüfung** | Upstream-Sync überspringt unveränderte Quellen per `git ls-remote`-SHA-Vergleich |
| **Agenten-Duplikatserkennung** | Normalisierter Namensvergleich erkennt Duplikate über Upstream-Quellen hinweg |

---

## Gebündelte Upstream-Versionen

Über git-Submodule verknüpft. Festgelegte Commits werden nativ von `.gitmodules` verfolgt.

| Quelle | SHA | Datum | Diff |
|--------|-----|-------|------|
| [agency-agents](https://github.com/msitarzewski/agency-agents) | `4feb0cd` | 2026-04-07 | [compare](https://github.com/msitarzewski/agency-agents/compare/4feb0cd...HEAD) |
| [everything-claude-code](https://github.com/affaan-m/everything-claude-code) | `7dfdbe0` | 2026-04-07 | [compare](https://github.com/affaan-m/everything-claude-code/compare/7dfdbe0...HEAD) |
| [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) | `2487d38` | 2026-04-07 | [compare](https://github.com/Yeachan-Heo/oh-my-claudecode/compare/2487d38...HEAD) |
| [gstack](https://github.com/garrytan/gstack) | `03973c2` | 2026-04-07 | [compare](https://github.com/garrytan/gstack/compare/03973c2...HEAD) |
| [superpowers](https://github.com/obra/superpowers) | `b7a8f76` | 2026-04-06 | [compare](https://github.com/obra/superpowers/compare/b7a8f76...HEAD) |

---

## Mitwirken

Issues und PRs sind willkommen. Wenn Sie einen neuen Agenten hinzufügen, fügen Sie eine `.md`-Datei zu `agents/core/` oder `agents/omo/` hinzu und aktualisieren Sie `SETUP.md`.

## Danksagungen

Aufgebaut auf der Arbeit von: [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) (Yeachan Heo), [oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent) (code-yeongyu), [everything-claude-code](https://github.com/affaan-m/everything-claude-code) (affaan-m), [agency-agents](https://github.com/msitarzewski/agency-agents) (msitarzewski), [gstack](https://github.com/garrytan/gstack) (garrytan), [superpowers](https://github.com/obra/superpowers) (Jesse Vincent), [anthropic/skills](https://github.com/anthropics/skills) (Anthropic), [andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills) (forrestchang).

## Lizenz

MIT-Lizenz. Weitere Informationen finden Sie in der Datei [LICENSE](./LICENSE).
