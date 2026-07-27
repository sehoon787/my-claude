[English](../../README.md) | [한국어](./README.ko.md) | [日本語](./README.ja.md) | [中文](./README.zh.md) | [Deutsch](./README.de.md) | [Français](./README.fr.md)

> [![Codex CLI](https://img.shields.io/badge/Codex_CLI-my--codex-10b981?style=flat-square&logo=openai&logoColor=white)](https://github.com/sehoon787/my-codex) Suchen Sie nach Codex CLI? → **my-codex** — dieselbe Orchestrierung im nativen TOML-Format

---

<div align="center">

# my-claude

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Agents](https://img.shields.io/badge/agents-32-blue)
![Skills](https://img.shields.io/badge/skills-139-purple)
![Rules](https://img.shields.io/badge/rules-54-orange)
![MCP Servers](https://img.shields.io/badge/MCP-3-green)
![Hooks](https://img.shields.io/badge/hooks-8-red)

**All-in-one Agent-Harness für Claude Code.**
**Ein Plugin, 32 kuratierte Agenten bereit.**

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

### Prioritäts-Routing

Boss leitet jede Anfrage durch eine Prioritätskette, bis die beste Übereinstimmung gefunden wird:

| Priorität | Übereinstimmungstyp | Wann | Beispiel |
|:---------:|---------------------|------|----------|
| **P0** | gstack-Skill | Release-, QA-, Deployment- oder Sicherheits-Workflow | `"ship this"` → gstack `/ship` |
| **P1** | Skill-Treffer | Aufgabe entspricht einer eigenständigen Skill | `"merge PDFs"` → pdf skill |
| **P2** | Spezialist-Agent | Domänenspezifischer Agent vorhanden | `"security audit"` → security-reviewer |
| **P3a** | Boss direkt | 2–4 unabhängige Agenten | `"fix 3 bugs"` → parallel spawn |
| **P3b** | Sub-Orchestrator | Komplexer mehrstufiger Workflow | `"refactor + test"` → Sisyphus |
| **P3c** | Agent Teams | Peer-to-Peer-Kommunikation erforderlich | `"implement + review"` → Review Chain |
| **P4** | Fallback | Kein Spezialist gefunden | `"explain this"` → general agent |

### Modell-Routing

| Komplexität | Modell | Verwendet für |
|-------------|--------|---------------|
| Orchestrierung auf oberster Ebene | `claude-fable-5` | Boss |
| Tiefgehende Analyse, Architektur | `claude-opus-5` | Sisyphus, Atlas, Hephaestus, Oracle, Metis, Momus, Prometheus |
| Standardimplementierung | `claude-sonnet-5` | Librarian, Multimodal-Looker, OMC-Spezialisten |
| Schnelle Suche, Erkundung | `claude-haiku-4-5` | Leichtgewichtige OMC-Agenten, einfache Beratung |

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
│  Karpathy Guidelines · Rules (54) · Hooks (8)        │
├─────────────────────────────────────────────────────┤
│  Specialist Agents (32)                               │
│  Boss 1 · OMO 9 · OMC 19 · Vendored 3                │
├─────────────────────────────────────────────────────┤
│  Skills (139)                                         │
│  ECC 79 · gstack 27 · OMC 16 · Superpowers 13       │
│  + Core 4                                             │
├─────────────────────────────────────────────────────┤
│  MCP Layer                                            │
│  Context7 · Exa · grep.app                            │
└─────────────────────────────────────────────────────┘
```

---

## Was enthalten ist

| Kategorie | Anzahl | Quelle |
|-----------|-------:|--------|
| **Agenten** (immer geladen) | 32 | Boss 1 + OMO 9 + OMC 19 + Vendored 3 |
| **Skills** | 139 | ECC 79 · gstack 27 · OMC 16 · Superpowers 13 · Core 4 |
| **Regeln** | 54 Dateien / 9 Regelsätze | ECC 53 (common + 8 Sprachverzeichnisse) + Core 1 |
| **MCP-Server** | 3 | Context7, Exa, grep.app |
| **Hooks** | 8 Dateien / 8 Events | Delegationswächter, Telemetrie, Verifikation, Vault |
| **Upstream-Submodule** | 4 | ecc, omc, gstack, superpowers |
| **CLI-Tools** | 3 | omc, omo, ast-grep |

Alle oben genannten Agenten, Skills und Regeln stehen auf der Allowlist in [`scripts/skill-allowlists.sh`](../../scripts/skill-allowlists.sh) und werden im Installationsmanifest verfolgt. Anthropics offizielle Dokument-Skills (pdf, docx usw.) werden separat über `claude plugin add anthropics/skills` installiert und bewusst nicht im Manifest verfolgt.

<details>
<summary><strong>Kern-Agent — Boss Meta-Orchestrator (1)</strong></summary>

| Agent | Modell | Rolle | Quelle |
|-------|--------|-------|--------|
| Boss | Fable | Dynamische Laufzeitentdeckung → Fähigkeitsabgleich → optimales Routing. Schreibt niemals Code. | my-claude |

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
<summary><strong>Vendored Agenten — KI- und Infrastruktur-Spezialisten (3)</strong></summary>

Am 2026-07-27 aus [agency-agents](https://github.com/msitarzewski/agency-agents) (MIT) übernommen, als dieses Submodul entfernt wurde. Behalten wurden nur die Engineering-Agenten ohne Entsprechung im übrigen Stack; jede Datei trägt ihren Herkunftsnachweis.

| Agent | Rolle | Quelle |
|-------|------|--------|
| AI Engineer | KI/ML-Engineering, Modellintegration, Datenpipelines | agency-agents (vendored) |
| DevOps Automator | Infrastrukturautomatisierung, CI/CD, Cloud-Betrieb | agency-agents (vendored) |
| Multi-Agent Systems Architect | Agenten-Topologie, Kontextverwaltung, Fehlerbehebung | agency-agents (vendored) |

</details>

<details>
<summary><strong>Skills — 139 aus 5 Quellen</strong></summary>

Jede Quelle wird über die Allowlist in [`scripts/skill-allowlists.sh`](../../scripts/skill-allowlists.sh) gesteuert — was dort nicht steht, wird nie installiert.

| Quelle | Anzahl | Wichtige Skills |
|--------|-------:|-----------------|
| [everything-claude-code](https://github.com/affaan-m/everything-claude-code) | 79 | coding-standards, react-patterns, fastapi-patterns, agent-architecture-audit, e2e-testing |
| [gstack](https://github.com/garrytan/gstack) | 27 | /qa, /review, /ship, /cso, /investigate, /office-hours |
| [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) | 16 | autopilot, ralph, team, ultrawork, ralplan, omc-reference |
| [superpowers](https://github.com/obra/superpowers) | 13 | brainstorming, systematic-debugging, test-driven-development, writing-plans |
| [my-claude Core](https://github.com/sehoon787/my-claude) | 4 | boss-advanced, boss-briefing, briefing-vault, gstack-sprint |

</details>

<details>
<summary><strong>MCP-Server (3) + Hooks (8)</strong></summary>

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
│   └── YYYY-MM-DD-<decision>.md     ← AI-written decision record (enforced)
├── learnings/
│   ├── YYYY-MM-DD-<pattern>.md      ← AI-written learning note
│   └── YYYY-MM-DD-auto-session.md   ← Auto-generated scaffold (agents, files)
├── references/
│   └── auto-links.md                ← Auto-collected URLs from web searches
├── agents/
│   ├── agent-log.jsonl              ← Subagent execution telemetry
│   └── YYYY-MM-DD-summary.md        ← Daily agent usage breakdown
├── persona/
│   ├── profile.md                   ← Agent affinity stats (auto-updated)
│   ├── suggestions.jsonl            ← Routing suggestions (auto-generated)
│   ├── rules/                       ← Accepted routing preferences
│   └── skills/                      ← Accepted persona skills
├── archives/                        ← Abgeschlossene/inaktive Notizen (30+ Tage)
│   ├── sessions/
│   ├── decisions/
│   └── learnings/
└── wiki/                            ← Konzeptseiten (automatisch vorgeschlagen)
    └── _schema.md
```

### Sub-Vaults

| Pfad | Beschreibung |
|------|-------------|
| `INDEX.md` | Projektübersicht mit Links zu aktuellen Entscheidungen und Lernnotizen. Wird bei der ersten Sitzung automatisch erstellt, periodisch aktualisiert. |
| `sessions/` | **Sitzungszusammenfassungen.** `*-auto.md` — Gerüst mit Git-Diff-Statistiken und Agentenzahlen. `<topic>.md` — KI-erstellte Zusammenfassung, durch Hooks erzwungen. |
| `decisions/` | **Architektur- und Designentscheidungen** mit Begründung. KI-erstellt, während der Arbeit erzwungen. |
| `learnings/` | **Muster, Stolperfallen, nicht offensichtliche Lösungen.** `*-auto-session.md` — Gerüst mit Dateilisten. `<topic>.md` — KI-erstellt. |
| `references/` | **Web-Recherche-URLs.** `auto-links.md` — automatisch gesammelt bei WebSearch/WebFetch-Aufrufen. |
| `agents/` | **Agenten-Telemetrie.** `agent-log.jsonl` — Protokoll pro Aufruf. `YYYY-MM-DD-summary.md` — tägliche Nutzungsübersicht. |
| `persona/` | **Arbeitsstil-Profil.** `profile.md` — Tool-Affinitätsstatistiken. `suggestions.jsonl` — Routing-Vorschläge. `rules/`, `skills/` — akzeptierte Präferenzen. |
| `archives/` | **Abgeschlossene/inaktive Notizen.** Notizen älter als 30 Tage sind Archivierungskandidaten. PARA-Archives-Konzept. Flache Struktur — das `type:`-Feld im Frontmatter identifiziert die ursprüngliche Kategorie. |
| `wiki/` | **Konzept-Wiki-Seiten.** Schlüsselwörter, die 3+ Mal vorkommen, werden automatisch vorgeschlagen. LLM-wiki-Konzept. Format wird über `_schema.md` definiert. |

### Wissensmanagement (v2)

BriefingVault v2 integriert drei Wissensmanagement-Methoden:

| Methode | Konzept | Anwendung in BriefingVault |
|---------|---------|---------------------------|
| **PARA** (Tiago Forte) | Ordnen nach Umsetzbarkeit: Projects, Areas, Resources, Archives | sessions/ = Projects, decisions/ = Areas, references/ = Resources, archives/ = Archives |
| **Zettelkasten** (Luhmann) | Atomare Notizen mit eindeutigen IDs und expliziten Verknüpfungen | learnings/-Dateien: `YYYYMMDDHHMMSS`-IDs, `related:` mindestens 2 Links erforderlich |
| **LLM-wiki** (Karpathy) | KI-gepflegte Konzeptseiten aus Quellnotizen | wiki/-Seiten: automatisch vorgeschlagen bei 3+ wiederholten Schlüsselwörtern |

### Sitzungsspezifische Diffs

Beim Sitzungsstart wird der aktuelle git-HEAD in `.briefing/.session-start-head` gespeichert. Am Sitzungsende werden Diffs relativ zu diesem gespeicherten Punkt berechnet — es werden nur Änderungen aus der aktuellen Sitzung angezeigt, keine angesammelten nicht committeten Änderungen aus vorherigen Sitzungen.

### Verwendung mit Obsidian

1. Öffnen Sie Obsidian → **Ordner als Vault öffnen** → `.briefing/` auswählen
2. Notizen erscheinen in der Graphansicht, verknüpft durch `[[wiki-links]]`
3. YAML-Frontmatter (`date`, `type`, `tags`) ermöglicht strukturierte Suche
4. Eine Zeitleiste von Entscheidungen und Lernnotizen entsteht automatisch über Sitzungen hinweg

---

## Upstream Open-Source-Quellen

my-claude verknüpft 4 MIT-lizenzierte Upstream-Repositories als git-Submodule, jedes auf einen expliziten SHA festgelegt:

| # | Quelle | Was bereitgestellt wird |
|---|--------|------------------------|
| 1 | <img src="https://github.com/affaan-m.png?size=32" width="20" height="20" align="center"/> **[everything-claude-code](https://github.com/affaan-m/everything-claude-code)** — affaan-m | 79 installierte Skills + 9 Regelsätze. Lane für Sprach- und Stack-Wissen: TDD, Sicherheit, Coding-Standards, Framework-Patterns. |
| 2 | <img src="https://github.com/Yeachan-Heo.png?size=32" width="20" height="20" align="center"/> **[oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode)** — Yeachan Heo | 19 Spezialisten-Agenten + 16 installierte Skills. Orchestrierungs-Lane: autopilot, ralph, team. |
| 3 | <img src="https://github.com/garrytan.png?size=32" width="20" height="20" align="center"/> **[gstack](https://github.com/garrytan/gstack)** — garrytan | 27 installierte Skills für Release, QA, Deployment und Sicherheitsreview (Boss-P0-Lane). Enthält Playwright-Browser-Daemon. |
| 4 | <img src="https://github.com/obra.png?size=32" width="20" height="20" align="center"/> **[superpowers](https://github.com/obra/superpowers)** — Jesse Vincent | 13 installierte Skills für die Entwicklungsprozess-Lane: Brainstorming, TDD, systematisches Debuggen, Planerstellung. |

Keine Submodule, aber Teil des Stacks:

| Quelle | Wie sie eingebunden ist |
|--------|-------------------------|
| <img src="https://github.com/code-yeongyu.png?size=32" width="20" height="20" align="center"/> **[oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent)** — code-yeongyu | 9 OMO-Agenten (Sisyphus, Atlas, Oracle usw.), in diesem Repository als eigenständige `.md`-Agenten unter `agents/omo/` übernommen. |
| <img src="https://github.com/msitarzewski.png?size=32" width="20" height="20" align="center"/> **[agency-agents](https://github.com/msitarzewski/agency-agents)** — msitarzewski | Submodul am 2026-07-27 entfernt. 3 Engineering-Agenten mit Herkunftsnachweis nach `agents/vendored/` übernommen. |
| <img src="https://www.anthropic.com/favicon.ico" width="20" height="20" align="center"/> **[anthropic/skills](https://github.com/anthropics/skills)** — Anthropic | Von `install.sh` über `claude plugin add anthropics/skills` installiert (pdf, docx und weitere). Nicht im Manifest verfolgt. |
| <img src="https://github.com/forrestchang.png?size=32" width="20" height="20" align="center"/> **[andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills)** — forrestchang | 4 KI-Coding-Verhaltensrichtlinien, angehängt an `~/.claude/CLAUDE.md`. |

---

## GitHub Actions

| Workflow | Auslöser | Zweck |
|----------|----------|-------|
| **CI** | push, PR | Validiert JSON-Konfigurationen, Agent-Frontmatter, Skill-Existenz, Upstream-Dateianzahlen |
| **Smoke** | push, PR | 4 Jobs — `hooks` (Hook-Ausführung), `shell` (Form des Installationsskripts), `drift` (Modell-Drift), `routing-refs` (tote Agenten-/Skill-Verweise) |
| **Update Upstream** | alle 3 Tage / manuell | `git submodule update --remote` → SHA-Pins in `SOURCES.json` auffrischen → Sicherheitsscan des Upstream-Diffs → Auto-Merge nur bei sauberem Scan, sonst bleibt der PR zur manuellen Prüfung offen |
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
| **Agenten-Tier-Priorität** | core > omo > omc > vendored-Deduplizierung. Der speziellste Agent gewinnt. |
| **Lane-Zuständigkeit** | Orchestrierung → OMC, Entwicklungsprozess → superpowers, Release/QA/Deployment/Sicherheit → gstack (Boss P0), Sprach- und Stack-Wissen → ECC, KI und Domäne → vendored Agenten |
| **Kuratierte Allowlists** | `scripts/skill-allowlists.sh` ist die einzige Quelle der Wahrheit — von Tausenden Upstream-Einträgen bleiben 139 Skills und 9 Regelsätze übrig; nichts Ungelistetes erreicht je den Sitzungskontext |
| **Briefing Vault** | Obsidian-kompatibles `.briefing/`-Verzeichnis mit Sitzungen, Entscheidungen, Lernnotizen und Referenzen |
| **Agenten-Telemetrie** | PostToolUse-Hook protokolliert Agentennutzung in `agent-usage.jsonl` |
| **Smart Packs** | Projekttypenerkennung empfiehlt relevante Agenten-Packs beim Sitzungsstart |
| **Sync-Skip ohne Änderungen** | Der Upstream-Sync staged Submodul-Bumps und `SOURCES.json`-Pins und öffnet nur dann einen PR, wenn dieser Diff nicht leer ist |
| **Agenten-Duplikatserkennung** | `tests/validate-sync.sh` vergleicht Agent-Dateinamen aus `agents/` und den omc-/superpowers-Submodulen und meldet Kollisionen |

---

## Gebündelte Upstream-Versionen

Über git-Submodule verknüpft. Festgelegte Commits werden nativ von `.gitmodules` verfolgt und als AI-BOM in [`upstream/SOURCES.json`](../../upstream/SOURCES.json) gespiegelt. `install.sh` checkt genau diese SHAs aus, statt `main` zu folgen.

| Quelle | SHA | Datum | Diff |
|--------|-----|-------|------|
| [everything-claude-code](https://github.com/affaan-m/everything-claude-code) | `4092795` | 2026-07-27 | [compare](https://github.com/affaan-m/everything-claude-code/compare/4092795...HEAD) |
| [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) | `590fb98` | 2026-07-27 | [compare](https://github.com/Yeachan-Heo/oh-my-claudecode/compare/590fb98...HEAD) |
| [gstack](https://github.com/garrytan/gstack) | `7c9df1c` | 2026-07-27 | [compare](https://github.com/garrytan/gstack/compare/7c9df1c...HEAD) |
| [superpowers](https://github.com/obra/superpowers) | `3dcbd5c` | 2026-07-27 | [compare](https://github.com/obra/superpowers/compare/3dcbd5c...HEAD) |

---

## Mitwirken

Issues und PRs sind willkommen. Wenn Sie einen neuen Agenten hinzufügen, fügen Sie eine `.md`-Datei zu `agents/core/` oder `agents/omo/` hinzu und aktualisieren Sie `SETUP.md`.

## Danksagungen

Aufgebaut auf der Arbeit von: [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) (Yeachan Heo), [oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent) (code-yeongyu), [everything-claude-code](https://github.com/affaan-m/everything-claude-code) (affaan-m), [gstack](https://github.com/garrytan/gstack) (garrytan), [superpowers](https://github.com/obra/superpowers) (Jesse Vincent), [agency-agents](https://github.com/msitarzewski/agency-agents) (msitarzewski — 3 vendored Agenten), [anthropic/skills](https://github.com/anthropics/skills) (Anthropic), [andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills) (forrestchang).

## Lizenz

MIT-Lizenz. Weitere Informationen finden Sie in der Datei [LICENSE](./LICENSE).
