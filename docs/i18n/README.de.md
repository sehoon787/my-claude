[English](../../README.md) | [한국어](./README.ko.md) | [日本語](./README.ja.md) | [中文](./README.zh.md) | [Deutsch](./README.de.md) | [Français](./README.fr.md)

> [![Codex CLI](https://img.shields.io/badge/Codex_CLI-my--codex-10b981?style=flat-square&logo=openai&logoColor=white)](https://github.com/sehoon787/my-codex) Suchen Sie nach Codex CLI? → **my-codex** — dieselbe Orchestrierung im nativen TOML-Format

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

**All-in-one Agent-Harness für Claude Code.**
**Ein Plugin, 32 kuratierte Agenten bereit.**

Boss entdeckt automatisch zur Laufzeit jeden Agenten, jede Skill und jedes MCP-Tool,<br>
und leitet Ihre Aufgabe an den richtigen Spezialisten weiter. Keine Konfigurationsdateien. Kein Boilerplate.

<img src="../../assets/owl-claude-social.svg" alt="The Maestro Owl — my-claude" width="700">

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

Der Installer stellt ein gemeinsames codeburn-Dashboard und einen gemeinsamen Headroom-Proxy für my-claude und my-codex bereit. Eine spätere Installation übernimmt gesunde Dienste, statt Duplikate zu starten. Status und Startprotokolle liegen unter `${XDG_STATE_HOME:-$HOME/.local/state}/agent-harness-services`; weder `ANTHROPIC_BASE_URL` noch `OPENAI_BASE_URL` werden geändert.

### Für KI-Agenten

```bash
curl -s https://raw.githubusercontent.com/sehoon787/my-claude/main/AI-INSTALL.md
```

Lesen Sie die VOLLSTÄNDIGE Ausgabe, und führen Sie dann jeden Schritt der Reihe nach aus. Verwenden Sie `curl`, NICHT `WebFetch`.

---

<a id="open-source-tools-used"></a>

## Verwendete Open-Source-Tools

Jedes Projekt, auf dem dieser Stack aufbaut, wird genau einmal beschrieben — hier.
Fünf MIT-lizenzierte Upstreams sind als git-Submodule mit explizitem SHA eingebunden;
der Rest kommt als versionsfixierte CLIs, gehostete MCP-Server oder als Dateien mit Herkunftsnachweis.

| # | Projekt | Was my-claude davon übernimmt | Wie es eingebunden wird |
|---|---------|-------------------------------|-------------------------|
| 1 | <img src="https://github.com/Yeachan-Heo.png?size=32" width="20" height="20" align="center"/> **[oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode)** (OMC) — Yeachan Heo | 19 Spezialisten-Agenten (architect, debugger, code reviewer, security reviewer, …), die die Arbeit nach Rolle aufteilen, plus 16 Orchestrierungs-Skills — autopilot, ralph, team. Magische Schlüsselwörter wie `autopilot:` starten automatische Parallelausführung. | Submodul `upstream/omc`, SHA-fixiert (siehe **Gebündelte Upstream-Versionen**); `install.sh` führt `npm i -g oh-my-claude-sisyphus@latest` aus und aktiviert das Plugin `oh-my-claudecode@omc`. |
| 2 | <img src="https://github.com/code-yeongyu.png?size=32" width="20" height="20" align="center"/> **[oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent)** (omo) — code-yeongyu | Ein Multi-Plattform-Harness, das über 8 Anbieter (Claude, GPT, Gemini, …) nach Kategorie routet und über `claude-code-agent-loader` und `claude-code-plugin-loader` zu Claude Code brückt. Seine 9 Agenten (Sisyphus, Atlas, Oracle, …) sind hier als eigenständige `.md`-Dateien übernommen. | Kein Submodul: Die 9 Agenten liegen unter `agents/omo/`; `install.sh` führt `npm i -g oh-my-opencode@latest` für die `omo`-CLI aus. |
| 3 | <img src="https://github.com/forrestchang.png?size=32" width="20" height="20" align="center"/> **[andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills)** — forrestchang | Die 4 Verhaltensrichtlinien für KI-Coding — Think Before Coding, Simplicity First, Surgical Changes, Goal-Driven Execution — dauerhaft aktiv. | `install.sh` lädt `CLAUDE.md` beim fixierten SHA `aa4467f` per curl, prüft die Checksumme und hängt es an `~/.claude/CLAUDE.md` an. Kein Code vendored. |
| 4 | <img src="https://github.com/affaan-m.png?size=32" width="20" height="20" align="center"/> **[everything-claude-code](https://github.com/affaan-m/everything-claude-code)** (ECC) — affaan-m | 278 Skills + 67 Agenten + 94 Commands + Sprachregeln upstream. my-claude installiert eine kuratierte Auswahl von 61 Skills (79 mit der optionalen `web`-Lane) — Stack-Patterns, KI- und Agenten-Engineering, Codebasis-Tooling — plus 9 Regelsätze und Slash-Commands wie `/tdd`, `/plan`, `/code-review`, `/build-fix`. | Submodul `upstream/ecc`, SHA-fixiert; `install.sh` versucht zuerst `claude plugin add affaan-m/everything-claude-code` und fällt auf das Submodul zurück. |
| 5 | <img src="https://www.anthropic.com/favicon.ico" width="20" height="20" align="center"/> **[anthropic/skills](https://github.com/anthropics/skills)** — Anthropic | Anthropics eigenes Skill-Repository: PDF-Parsing, Word-/Excel-/PowerPoint-Bearbeitung, Erstellung von MCP-Servern. | `claude plugin add anthropics/skills`, ausgeführt von `install.sh`. Bewusst nicht im Manifest verfolgt. |
| 6 | <img src="https://github.com/garrytan.png?size=32" width="20" height="20" align="center"/> **[gstack](https://github.com/garrytan/gstack)** — garrytan | Garry Tans Sprint-Prozess-Harness: 26 Skills plus der `gstack`-Root-Router (27 insgesamt) — Browser-QA (`/qa`), Code-Review auf Scope-Drift (`/review`), Sicherheitsaudit (`/cso`) und der vollständige Plan→Review→QA→Ship-Workflow (Boss-P0-Lane). Bringt einen kompilierten Playwright-Browser-Daemon für echte Browsertests mit. | Submodul `upstream/gstack`, SHA-fixiert. |
| 7 | <img src="https://github.com/obra.png?size=32" width="20" height="20" align="center"/> **[superpowers](https://github.com/obra/superpowers)** — Jesse Vincent | Jesse Vincents Bibliothek für den Entwicklungsprozess: 14 seiner 15 Skills — Brainstorming, systematisches Debuggen, TDD, Planerstellung und -ausführung, Code-Review-Etikette. `dispatching-parallel-agents` bleibt ausgeschlossen, weil Boss und Agent Teams diesen Pfad bereits abdecken. | Submodul `upstream/superpowers`, SHA-fixiert. |
| 8 | <img src="https://github.com/getagentseal.png?size=32" width="20" height="20" align="center"/> **[codeburn](https://github.com/getagentseal/codeburn)** — getagentseal | Local-first Token- und Kosten-Tracking über die Sitzungsdateien, die Claude Code und Codex ohnehin schreiben — kein Proxy, kein API-Key, nichts verlässt den Rechner. Die Budget-Guard-Hooks bleiben per `bash install.sh --with-codeburn-guard` opt-in, denn ihr Hard Cap (Standard $15/Sitzung) blockiert jeden Tool-Aufruf dieser Sitzung, auch `codeburn guard allow` (in einem externen Terminal ausführen). | `npm i -g codeburn@0.9.23`; `install.sh` startet oder übernimmt außerdem ein gemeinsames Dashboard für beide Harnesses — siehe **Wo die Ergebnisse landen**. MIT. |
| 9 | <img src="https://github.com/oraios.png?size=32" width="20" height="20" align="center"/> **[serena](https://github.com/oraios/serena)** — oraios | Der Symbolgraph eines Language Servers über MCP: `find_symbol`, `get_symbols_overview`, `find_referencing_symbols`, `replace_symbol_body`, `insert_after_symbol` — die Token-Kosten skalieren mit dem Symbol, nicht mit der Datei. | `uv tool install -p 3.13 serena-agent==1.7.0`, registriert als stdio-MCP-Server im User-Scope (`serena start-mcp-server --context claude-code --project-from-cwd`). Das ausgelieferte Paket steht als Ganzes unter GPL-3.0-or-later (der MIT-Classifier auf PyPI ist falsch); es wird als externer Server genutzt, nie vendored. |
| 10 | <img src="https://github.com/headroomlabs-ai.png?size=32" width="20" height="20" align="center"/> **[headroom](https://github.com/headroomlabs-ai/headroom)** — Headroom Labs | Komprimierung von Tool-Ausgaben: `headroom mcp serve` stellt `headroom_compress`, `headroom_retrieve` und `headroom_stats` bereit, damit ein übergroßes Tool-Ergebnis nie vollständig im Transkript landet. | `uv tool install --python 3.13 "headroom-ai[all]==0.37.0"`, registriert als stdio-MCP-Server `headroom`; `install.sh` startet oder übernimmt außerdem das mutationsfreie persistente Profil `agent-harness-shared`. Apache-2.0. |
| 11 | <img src="https://github.com/tt-a1i.png?size=32" width="20" height="20" align="center"/> **[archify](https://github.com/tt-a1i/archify)** — tt-a1i | Ein Agent-Skill, der Architektur-, Workflow-, Sequenz-, Datenfluss- und Lebenszyklusdiagramme als eigenständiges HTML zeichnet — Inline-SVG, Hell-/Dunkel-Umschalter, Exportmenü für PNG/JPEG/WebP/SVG, keine Laufzeitabhängigkeiten in der erzeugten Datei. Eingefügtes Mermaid wird ebenfalls als Eingabedialekt akzeptiert. | Submodul `upstream/archify`, auf Tag `v2.9.0` festgelegt; `install.sh` kopiert das Upstream-Verzeichnis `archify/` nach `~/.claude/skills/archify`, sodass zur Installationszeit kein `npx skills add` läuft. |
| 12 | <img src="https://github.com/msitarzewski.png?size=32" width="20" height="20" align="center"/> **[agency-agents](https://github.com/msitarzewski/agency-agents)** — msitarzewski | 3 Engineering-Agenten ohne Entsprechung im übrigen Stack: AI Engineer, DevOps Automator, Multi-Agent Systems Architect. | Submodul am 2026-07-27 entfernt; die 3 Agenten wurden an diesem Tag nach `agents/vendored/` übernommen, jede Datei mit ihrem Herkunftsnachweis. MIT. |
| 13 | <img src="https://github.com/ast-grep.png?size=32" width="20" height="20" align="center"/> **[ast-grep](https://github.com/ast-grep/ast-grep)** — ast-grep | Strukturelle, AST-bewusste Codesuche und -umschreibung, damit Agenten Codeformen statt Regex treffen. | `npm i -g @ast-grep/cli@0.42.0`. MIT. |
| 14 | <img src="https://github.com/upstash.png?size=32" width="20" height="20" align="center"/> **[context7](https://github.com/upstash/context7)** — Upstash | Aktuelle, versionsgenaue Bibliotheksdokumentation, damit ein Agent die echte API liest, statt sie zu erinnern. | Gehosteter MCP-Server unter `https://mcp.context7.com/mcp`, registriert von `install.sh`. |
| 15 | <img src="https://github.com/exa-labs.png?size=32" width="20" height="20" align="center"/> **[exa](https://github.com/exa-labs/exa-mcp-server)** — Exa Labs | Neuronale (semantische) Websuche für Recherchen, die eine Stichwortsuche verfehlt. | Gehosteter MCP-Server unter `https://mcp.exa.ai/mcp`, registriert von `install.sh`. |
| 16 | <img src="https://github.com/grep-app.png?size=32" width="20" height="20" align="center"/> **[grep.app](https://github.com/grep-app)** — grep.app | Codesuche über öffentliche GitHub-Repositories, um zu finden, wie ein Muster in freier Wildbahn verwendet wird. | Gehosteter MCP-Server unter `https://mcp.grep.app`, registriert von `install.sh`. |


---

## Wie Boss funktioniert

Boss ist der Meta-Orchestrator im Kern von my-claude. Er schreibt niemals Code — er entdeckt, klassifiziert, ordnet zu, delegiert und verifiziert.

| Phase | Was passiert |
|-------|--------------|
| **0 · DISCOVERY** | Scannt Agenten, Skills, MCP und Hooks zur Laufzeit und baut daraus eine Live-Registry der Fähigkeiten auf |
| **1 · INTENT GATE** | Klassifiziert die Anfrage (trivial, build, refactor, mid-sized, architecture, research, …) und schlägt als Gegenvorschlag eine Skill vor, wenn diese besser passt |
| **2 · CAPABILITY MATCHING** | Durchläuft kaskadierend die Prioritätskette unten (P0 gstack-Skill → P1 exakter Skill-Treffer → P2 Spezialist-Agent → P3 Multi-Agenten-Orchestrierung → P4 General-Purpose-Fallback) |
| **3 · DELEGATION** | Sendet einen strukturierten 6-Abschnitts-Prompt an den Spezialisten: TASK / OUTCOME / TOOLS / DO / DON'T / CTX |
| **4 · VERIFICATION** | Liest die geänderten Dateien unabhängig, führt Tests, Lint und Build aus, gleicht mit der ursprünglichen Absicht ab und wiederholt bei Fehlschlag bis zu 3× |

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
| Orchestrierung auf oberster Ebene | `claude-fable-5-1` | Boss |
| Tiefgehende Analyse, Architektur | `claude-opus-5` | Sisyphus, Atlas, Hephaestus, Oracle, Metis, Momus, Prometheus |
| Standardimplementierung | `claude-sonnet-5` | Librarian, Multimodal-Looker, OMC-Spezialisten |
| Schnelle Suche, Erkundung | `claude-haiku-4-5` | Leichtgewichtige OMC-Agenten, einfache Beratung |

### Effort-Stufen

Die Modellwahl bestimmt, *welches* Gehirn eine Aufgabe übernimmt; das Frontmatter-Feld `effort:` bestimmt, *wie tief* es denkt. Jeder selbst gepflegte Agent deklariert einen Wert.

| Effort | Agenten |
|--------|---------|
| `xhigh` | Boss, Oracle, Prometheus, Multi-Agent Systems Architect |
| `high` | Sisyphus, Hephaestus, Atlas, Metis, Momus |
| `medium` | Librarian, Multimodal-Looker, AI Engineer, DevOps Automator |

Auch Skills deklarieren Effort — `boss-briefing` läuft auf `medium`, `briefing-vault` auf `low`. `boss-advanced` und `gstack-sprint` deklarieren bewusst keinen: Der Effort eines Skills überschreibt während des Aufrufs die Sitzungsstufe und würde Boss mitten in der Arbeit unbemerkt herabstufen.

Vorrang gilt in dieser Reihenfolge: `CLAUDE_CODE_EFFORT_LEVEL` (Umgebungsvariable) > Frontmatter > Effort-Stufe der Sitzung. `xhigh` ist die von Fable unterstützte Obergrenze; `max` ist ausschließlich Opus-Klasse und fällt anderswo stillschweigend zurück.

### 3-Phasen-Sprint-Workflow

Für die Ende-zu-Ende-Funktionsimplementierung orchestriert Boss einen strukturierten Sprint:

| Phase | Modus | Was passiert |
|-------|-------|--------------|
| **1 · DESIGN** | interaktiv | Nutzer legt den Umfang fest · Engineering-Review · „design done“ bestätigen |
| **2 · EXECUTE** | autonom | ralph führt die Umsetzung aus · automatischer Code-Review · Architekt-Verifikation |
| **3 · REVIEW** | interaktiv | Abgleich mit dem Design-Dokument · Vergleichstabelle präsentieren · Nutzer genehmigt oder fordert Verbesserung |

### Strukturierter Abschlussbericht

Boss schließt jeden Arbeits-Turn — jeden Turn, in dem Dateien bearbeitet oder erstellt, Commits/PRs/Merges gemacht, Konfiguration geändert oder Verifikation ausgeführt wurde — mit einem strukturierten Abschlussbericht ab, den man ohne Öffnen eines Diffs überfliegen kann. Der Bericht besteht aus fünf festen Tabellen, die jeweils nur ausgegeben werden, wenn ihre Situation tatsächlich eingetreten ist (niemals eine leere Tabelle):

| Situation | Tabelle | Spalten |
|-----------|-------|---------|
| Dateien/Einstellungen geändert | Änderungen (Changes) | Ziel / Before / After / Begründung |
| Mehrere Aufgaben abgeschlossen | Arbeitsübersicht (Work summary) | Punkt / Ergebnis / Nachweis |
| Verifikation ausgeführt | Verifikation (Verification) | Punkt / Erwartet / Tatsächlich / Urteil |
| Commits/PRs erzeugt | Ergebnisse (Deliverables) | PR / Repository / Inhalt / Status |
| Etwas ungelöst | Offen (Remaining) | Punkt / Status / Nächster Schritt |

Er wird nur ganz am Ende der Anfrage ausgelöst — niemals in einem Turn, der Hintergrundarbeit startet oder weiterreicht, und niemals als Fortschrittsmeldung mitten in der Aufgabe — und reine Q&A-Turns enden normal ohne ihn. Die Spezifikation steht in `boss.md § FINAL REPORT`; der Stop-Hook `stop-final-report.js` setzt sie durch.

### Benannte Workflows

Deterministische Multi-Agenten-Workflows. `install.sh` kopiert sie nach `~/.claude/workflows/`, sodass sie sich nicht nur aus diesem Repository, sondern aus jedem Projekt über das Workflow-Tool aufrufen lassen.

| Workflow | Was er tut | Aufruf |
|----------|------------|--------|
| **code-review-fanout** | Vier Dimensions-Reviewer (Korrektheit, Sicherheit, Performance, Tests) laufen parallel; jeder Befund wird vor der Meldung adversarial verifiziert | `Workflow({name: "code-review-fanout"})` — Argument: das Review-Ziel (Branch, Commit-Bereich, Pfade). Standard ist das Diff des Arbeitsverzeichnisses |
| **upstream-audit** | Ein Analyst je Upstream — Pin-Delta gegenüber Origin, Passung der Allowlist, neue Überschneidungen, Sicherheitssignale, Gesundheit — plus eine zusammengeführte Maßnahmenliste | `Workflow({name: "upstream-audit"})` — für vierteljährliche Audits oder vor einem Sync |

---

## Was enthalten ist

| Kategorie | Anzahl | Quelle |
|-----------|-------:|--------|
| **Agenten** (immer geladen) | 32 | Boss 1 + OMO 9 + OMC 19 + Vendored 3 |
| **Skills** | 106 | ECC 61 · gstack 27 · Superpowers 14 · Core 4 |
| **Regeln** | 48 Dateien / 9 Regelsätze | ECC 46 (common + 8 Sprachverzeichnisse) + Core 2 |
| **MCP-Server** | 3 | Context7, Exa, grep.app |
| **Hooks** | 10 Dateien / 6 Events | Delegationswächter, Telemetrie, Verifikation, Vault |
| **LSP-Server** | 2 | typescript (`typescript-language-server`), python (`pyright-langserver`) |
| **Benannte Workflows** | 2 | code-review-fanout, upstream-audit |
| **Upstream-Submodule** | 5 | ecc, omc, gstack, superpowers, archify |
| **CLI-Tools** | 7 | omc, omo, ast-grep, comment-checker, codeburn, serena, headroom |

Alle oben genannten Agenten, Skills und Regeln stehen auf der Allowlist in [`scripts/skill-allowlists.sh`](../../scripts/skill-allowlists.sh) und werden im Installationsmanifest verfolgt. Anthropics offizielle Dokument-Skills (pdf, docx usw.) werden separat über `claude plugin add anthropics/skills` installiert und bewusst nicht im Manifest verfolgt.

<details>
<summary><strong>Spezialisten-Agenten — 32 in 4 Tiers</strong></summary>

Das Modell je Agent steht in der Tabelle **Modell-Routing** weiter oben; woher die jeweilige Quelle stammt, steht unter [Verwendete Open-Source-Tools](#open-source-tools-used).

| Agent | Tier | Rolle | Quelle |
|-------|------|-------|--------|
| Boss | `core` | Dynamische Laufzeitentdeckung → Fähigkeitsabgleich → optimales Routing. Schreibt niemals Code. | my-claude |
| Sisyphus | `omo` | Absichtsklassifizierung → Spezialistendelegation → Verifikation | [oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent) |
| Hephaestus | `omo` | Autonom erkunden → planen → ausführen → verifizieren | oh-my-openagent |
| Atlas | `omo` | Aufgabenzerlegung + 4-stufige QA-Verifikation | oh-my-openagent |
| Oracle | `omo` | Strategische technische Beratung (nur lesend) | oh-my-openagent |
| Metis | `omo` | Absichtsanalyse, Mehrdeutigkeitserkennung | oh-my-openagent |
| Momus | `omo` | Überprüfung der Planumsetzbarkeit | oh-my-openagent |
| Prometheus | `omo` | Interviewbasierte detaillierte Planung | oh-my-openagent |
| Librarian | `omo` | Open-Source-Dokumentationssuche über MCP | oh-my-openagent |
| Multimodal-Looker | `omo` | Bild-/Screenshot-/Diagrammanalyse | oh-my-openagent |
| analyst | `omc` | Voranalyse vor der Planung | [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) |
| architect | `omc` | Systemdesign und Architektur | oh-my-claudecode |
| code-reviewer | `omc` | Fokussierter Code-Review | oh-my-claudecode |
| code-simplifier | `omc` | Code-Vereinfachung und -Bereinigung | oh-my-claudecode |
| critic | `omc` | Kritische Analyse, alternative Vorschläge | oh-my-claudecode |
| debugger | `omc` | Fokussiertes Debugging | oh-my-claudecode |
| designer | `omc` | UI/UX-Design-Anleitung | oh-my-claudecode |
| document-specialist | `omc` | Dokumentationserstellung | oh-my-claudecode |
| executor | `omc` | Aufgabenausführung | oh-my-claudecode |
| explore | `omc` | Codebasis-Erkundung | oh-my-claudecode |
| git-master | `omc` | Git-Workflow-Verwaltung | oh-my-claudecode |
| planner | `omc` | Schnelle Planung | oh-my-claudecode |
| qa-tester | `omc` | Qualitätssicherungstests | oh-my-claudecode |
| scientist | `omc` | Forschung und Experimente | oh-my-claudecode |
| security-reviewer | `omc` | Sicherheitsüberprüfung | oh-my-claudecode |
| test-engineer | `omc` | Test-Erstellung und -Pflege | oh-my-claudecode |
| tracer | `omc` | Ausführungs-Tracing und Analyse | oh-my-claudecode |
| verifier | `omc` | Abschließende Verifikation | oh-my-claudecode |
| writer | `omc` | Inhalte und Dokumentation | oh-my-claudecode |
| AI Engineer | `vendored` | KI/ML-Engineering, Modellintegration, Datenpipelines | agency-agents (vendored) |
| DevOps Automator | `vendored` | Infrastrukturautomatisierung, CI/CD, Cloud-Betrieb | agency-agents (vendored) |
| Multi-Agent Systems Architect | `vendored` | Agenten-Topologie, Kontextverwaltung, Fehlerbehebung | agency-agents (vendored) |

</details>

<details>
<summary><strong>Skills — 106 aus 4 Quellen</strong></summary>

Jede Quelle wird über die Allowlist in [`scripts/skill-allowlists.sh`](../../scripts/skill-allowlists.sh) gesteuert — was dort nicht steht, wird nie installiert.

| Quelle | Anzahl | Wichtige Skills |
|--------|-------:|-----------------|
| [everything-claude-code](https://github.com/affaan-m/everything-claude-code) | 61 | coding-standards, fastapi-patterns, agent-architecture-audit, springboot-patterns, kubernetes-patterns |
| [gstack](https://github.com/garrytan/gstack) | 27 | /qa, /review, /ship, /cso, /investigate, /office-hours |
| [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) | 16 (Plugin) | autopilot, ralph, team, ultrawork, ralplan, omc-reference |
| [superpowers](https://github.com/obra/superpowers) | 14 | brainstorming, systematic-debugging, test-driven-development, writing-plans |
| [my-claude Core](https://github.com/sehoon787/my-claude) | 4 | boss-advanced, boss-briefing, briefing-vault, gstack-sprint |

</details>

<details>
<summary><strong>MCP-Server (3) + Hooks (10)</strong></summary>

**MCP-Server** — was jeder davon tut und wie er registriert wird, steht unter [Verwendete Open-Source-Tools](#open-source-tools-used).

| Server | Kosten |
|--------|--------|
| <img src="https://context7.com/favicon.ico" width="16" height="16" align="center"/> [Context7](https://context7.com) | Kostenlos |
| <img src="https://exa.ai/images/favicon-32x32.png" width="16" height="16" align="center"/> [Exa](https://exa.ai) | Kostenlos 1k Anfragen/Monat |
| <img src="https://www.google.com/s2/favicons?domain=grep.app&sz=32" width="16" height="16" align="center"/> [grep.app](https://github.com/grep-app) | Kostenlos |

**Verhaltens-Hooks**

| Hook | Ereignis | Verhalten |
|------|----------|-----------|
| Session Setup | SessionStart | Erkennt automatisch fehlende Tools + injiziert Briefing Vault-Kontext |
| Delegation Guard | PreToolUse | Verhindert, dass Boss Dateien direkt ändert |
| Agent Telemetry | PostToolUse | Protokolliert Agentennutzung in `agent-usage.jsonl` |
| Subagent Logger | SubagentStop | Protokolliert die Agentenausführung in Briefing Vault |
| Completion Check | Stop | Bestätigt verifizierte Aufgaben + fordert Sitzungszusammenfassung an |

</details>

<details>
<summary><strong>LSP-Server (2)</strong></summary>

Das Plugin deklariert in `.lsp.json` zwei Language Server. Claude Code startet sie bei Bedarf, sodass Agenten Diagnosen und Codenavigation sofort erhalten, ohne einen Build-Umweg zu gehen.

| Server | Befehl | Dateiendungen |
|--------|--------|---------------|
| typescript | `typescript-language-server --stdio` | `.ts` `.tsx` `.js` `.jsx` `.mjs` `.cjs` |
| python | `pyright-langserver --stdio` | `.py` |

`install.sh` installiert beide Binaries nicht-fatal — fehlt eines, wird nur dieser Server deaktiviert, der Rest der Installation läuft weiter.

</details>

---

## <img src="https://obsidian.md/images/obsidian-logo-gradient.svg" width="24" height="24" align="center"/> Briefing Vault

Obsidian-kompatibler persistenter Speicher. Jedes Projekt pflegt ein `.briefing/`-Verzeichnis, das sich über Sitzungen hinweg automatisch befüllt.

### Sub-Vaults

| Pfad | Beschreibung |
|------|-------------|
| `INDEX.md` | Projektübersicht mit Links zu aktuellen Entscheidungen und Lernnotizen. Wird bei der ersten Sitzung automatisch erstellt, periodisch aktualisiert. |
| `sessions/` | **Sitzungszusammenfassungen.** `YYYY-MM-DD-auto.md` — Gerüst mit Git-Diff-Statistiken und Agentenzahlen. `YYYY-MM-DD-<topic>.md` — KI-erstellte Zusammenfassung, durch Hooks erzwungen. |
| `decisions/` | **Architektur- und Designentscheidungen** mit Begründung. `YYYY-MM-DD-<decision>.md` — KI-erstellt, während der Arbeit erzwungen. |
| `learnings/` | **Muster, Stolperfallen, nicht offensichtliche Lösungen.** `YYYY-MM-DD-auto-session.md` — Gerüst mit Dateilisten. `YYYY-MM-DD-<pattern>.md` — KI-erstellt. |
| `references/` | **Web-Recherche-URLs.** `auto-links.md` — automatisch gesammelt bei WebSearch/WebFetch-Aufrufen. |
| `agents/` | **Agenten-Telemetrie.** `agent-log.jsonl` — Protokoll pro Aufruf. `YYYY-MM-DD-summary.md` — tägliche Nutzungsübersicht. |
| `persona/` | **Arbeitsstil-Profil.** `profile.md` — Tool-Affinitätsstatistiken. `suggestions.jsonl` — Routing-Vorschläge. `rules/`, `skills/` — akzeptierte Präferenzen. |
| `archives/` | **Abgeschlossene/inaktive Notizen** (30+ Tage) in `sessions/`, `decisions/`, `learnings/`. Notizen älter als 30 Tage sind Archivierungskandidaten. PARA-Archives-Konzept. Flache Struktur — das `type:`-Feld im Frontmatter identifiziert die ursprüngliche Kategorie. |
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

## Wo die Ergebnisse landen

Wo die Arbeit der einzelnen Begleit-Tools tatsächlich sichtbar wird. Was das jeweilige Tool ist, steht unter [Verwendete Open-Source-Tools](#open-source-tools-used):

| Tool | Aufruf | Wo es zu sehen ist |
|------|--------|--------------------|
| **codeburn** | `install.sh` startet oder übernimmt `codeburn web --provider all --port 4747 --no-open` · `codeburn` öffnet die TUI · `codeburn report --format json --period week` erzeugt eine nicht interaktive Ausgabe | Gemeinsames Dashboard: <http://127.0.0.1:4747/>, Startprotokoll: `${XDG_STATE_HOME:-$HOME/.local/state}/agent-harness-services/logs/codeburn.log`. Sitzungsdateien werden nur gelesen; Dollarbeträge sind Schätzungen zu API-Listenpreisen. |
| **Serena** | Startet automatisch als MCP-Server; `get_symbols_overview` / `find_symbol` aus jeder Sitzung aufrufen | Dashboard unter <http://localhost:24282/dashboard/index.html>, solange ein Server läuft (Logs + Aufrufzahlen pro Tool). Projektbezogene Memories landen in `.serena/` innerhalb des bearbeiteten Repositories; die globale Konfiguration ist `~/.serena/serena_config.yml`. |
| **Headroom** | MCP-Tools `headroom_compress` / `headroom_retrieve` / `headroom_stats`; `install.sh` startet oder übernimmt das gemeinsame Proxy-Profil `agent-harness-shared` | Statistiken: <http://127.0.0.1:8787/stats> (leer, bis ein Client ausdrücklich über den Proxy geleitet wird), Startprotokoll: `${XDG_STATE_HOME:-$HOME/.local/state}/agent-harness-services/logs/headroom.log`. |
| **Archify** | Nach einem Diagramm fragen — Boss leitet an die `archify`-Skill weiter. Manuell aus `~/.claude/skills/archify`: `node bin/archify.mjs render workflow examples/agent-tool-call.workflow.json out.html` | Die erzeugte `out.html` — in einem beliebigen Browser öffnen. Prüfen lässt sie sich mit `node bin/archify.mjs check out.html`. |
| **OMC HUD** | Wird von `install.sh` als Statusline installiert; `/oh-my-claudecode:hud` konfiguriert sie neu | Die Claude Code-Statusline am unteren Rand der Sitzung mit Live-Anzeige von Kontext, Kontingent und Modus. Ergänzt codeburn: Das HUD zeigt diese Sitzung, codeburn zeigt alle Sitzungen. |

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
| **Kuratierte Allowlists** | `scripts/skill-allowlists.sh` ist die einzige Quelle der Wahrheit — von Tausenden Upstream-Einträgen bleiben 106 Skills und 9 Regelsätze übrig; nichts Ungelistetes erreicht je den Sitzungskontext |
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
| [everything-claude-code](https://github.com/affaan-m/everything-claude-code) | `07756ce` | 2026-09-19 | [compare](https://github.com/affaan-m/everything-claude-code/compare/07756ce...HEAD) |
| [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) | `5281b19` | 2026-09-13 | [compare](https://github.com/Yeachan-Heo/oh-my-claudecode/compare/5281b19...HEAD) |
| [gstack](https://github.com/garrytan/gstack) | `a6b3a57` | 2026-09-16 | [compare](https://github.com/garrytan/gstack/compare/a6b3a57...HEAD) |
| [superpowers](https://github.com/obra/superpowers) | `5bf4e78` | 2026-09-19 | [compare](https://github.com/obra/superpowers/compare/5bf4e78...HEAD) |
| [archify](https://github.com/tt-a1i/archify) | `62904f3` (`v2.9.0`) | 2026-09-19 | [compare](https://github.com/tt-a1i/archify/compare/62904f3...HEAD) |

---

## Mitwirken

Issues und PRs sind willkommen. Wenn Sie einen neuen Agenten hinzufügen, fügen Sie eine `.md`-Datei zu `agents/core/` oder `agents/omo/` hinzu und aktualisieren Sie `SETUP.md`.

## Danksagungen

Aufgebaut auf den unter [Verwendete Open-Source-Tools](#open-source-tools-used) aufgeführten Projekten; Dank an jede Autorin und jeden Autor.

## Lizenz

MIT-Lizenz. Weitere Informationen finden Sie in der Datei [LICENSE](../../LICENSE).
