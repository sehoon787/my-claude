[English](../../README.md) | [한국어](./README.ko.md) | [日本語](./README.ja.md) | [中文](./README.zh.md) | [Deutsch](./README.de.md) | [Français](./README.fr.md)

> [![Codex CLI](https://img.shields.io/badge/Codex_CLI-my--codex-10b981?style=flat-square&logo=openai&logoColor=white)](https://github.com/sehoon787/my-codex) Vous cherchez Codex CLI ? → **my-codex** — la même orchestration au format TOML natif

---

<div align="center">

# my-claude

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Agents](https://img.shields.io/badge/agents-32-blue)
![Skills](https://img.shields.io/badge/skills-139-purple)
![Rules](https://img.shields.io/badge/rules-54-orange)
![MCP Servers](https://img.shields.io/badge/MCP-3-green)
![Hooks](https://img.shields.io/badge/hooks-8-red)
![LSP Servers](https://img.shields.io/badge/LSP-2-008b8b)
![Workflows](https://img.shields.io/badge/workflows-2-blueviolet)

**Harnais d'agents tout-en-un pour Claude Code.**
**Un seul plugin, 32 agents sélectionnés prêts à l'emploi.**

Boss détecte automatiquement chaque agent, skill et outil MCP au démarrage,<br>
puis route votre tâche vers le bon spécialiste. Aucun fichier de configuration. Aucun code superflu.

<img src="./assets/owl-claude-social.svg" alt="The Maestro Owl — my-claude" width="700">

</div>

---

## Installation

### Pour les humains

```bash
git clone --depth 1 https://github.com/sehoon787/my-claude.git /tmp/my-claude
bash /tmp/my-claude/install.sh
rm -rf /tmp/my-claude
```

Ou installez d'abord en tant que plugin Claude Code, puis exécutez l'installateur complémentaire :

```bash
# Dans une session Claude Code :
/plugin marketplace add sehoon787/my-claude
/plugin install my-claude@my-claude

# Puis installez les outils complémentaires :
git clone --depth 1 https://github.com/sehoon787/my-claude.git /tmp/my-claude
bash /tmp/my-claude/install.sh
rm -rf /tmp/my-claude
```

### Pour les agents IA

```bash
curl -s https://raw.githubusercontent.com/sehoon787/my-claude/main/AI-INSTALL.md
```

Lisez la TOTALITÉ de la sortie, puis exécutez chaque étape dans l'ordre. Utilisez `curl`, PAS `WebFetch`.

---

## Fonctionnement de Boss

Boss est le méta-orchestrateur au cœur de my-claude. Il n'écrit jamais de code — il découvre, classe, associe, délègue et vérifie.

```
Requête utilisateur
     │
     ▼
┌─────────────────────────────────────────────┐
│  Phase 0 · DÉCOUVERTE                       │
│  Analyse agents, skills, MCP, hooks au      │
│  démarrage → Construit le registre des      │
│  capacités en direct                        │
└──────────────────────┬──────────────────────┘
                       ▼
┌─────────────────────────────────────────────┐
│  Phase 1 · FILTRE D'INTENTION               │
│  Classer : trivial | build | refactor |     │
│  moyen | architecture | recherche | ...     │
│  → Proposer un skill alternatif si plus     │
│  adapté                                     │
└──────────────────────┬──────────────────────┘
                       ▼
┌─────────────────────────────────────────────┐
│  Phase 2 · CORRESPONDANCE DE CAPACITÉS      │
│  P0: skill gstack (si installé)             │
│  P1: Correspondance exacte de skill         │
│  P2: Agent spécialiste (32)                 │
│  P3: Orchestration multi-agents             │
│  P4: Repli généraliste                      │
└──────────────────────┬──────────────────────┘
                       ▼
┌─────────────────────────────────────────────┐
│  Phase 3 · DÉLÉGATION                       │
│  Prompt structuré en 6 sections au          │
│  spécialiste                                │
│  TÂCHE / RÉSULTAT / OUTILS / FAIRE /       │
│  NE PAS FAIRE / CTX                         │
└──────────────────────┬──────────────────────┘
                       ▼
┌─────────────────────────────────────────────┐
│  Phase 4 · VÉRIFICATION                     │
│  Lecture indépendante des fichiers modifiés │
│  Exécution des tests, lint, build           │
│  Recoupement avec l'intention d'origine     │
│  → Jusqu'à 3 nouvelles tentatives en cas   │
│  d'échec                                    │
└─────────────────────────────────────────────┘
```

### Routage par priorité

Boss cascade chaque requête dans une chaîne de priorités jusqu'à trouver la meilleure correspondance :

| Priorité | Type de correspondance | Quand | Exemple |
|:--------:|-----------|------|---------|
| **P0** | Skill gstack | Workflow livraison / QA / déploiement / sécurité | `"ship this"` → gstack `/ship` |
| **P1** | Correspondance de skill | La tâche correspond à un skill autonome | `"fusionner des PDFs"` → skill pdf |
| **P2** | Agent spécialiste | Un agent spécifique au domaine existe | `"audit de sécurité"` → security-reviewer |
| **P3a** | Boss direct | 2-4 agents indépendants | `"corriger 3 bugs"` → lancement parallèle |
| **P3b** | Sous-orchestrateur | Workflow complexe multi-étapes | `"refactor + test"` → Sisyphus |
| **P3c** | Équipes d'agents | Communication pair-à-pair nécessaire | `"implémenter + réviser"` → Review Chain |
| **P4** | Repli | Aucun spécialiste trouvé | `"expliquer ceci"` → agent généraliste |

### Routage par modèle

| Complexité | Modèle | Utilisé pour |
|-----------|-------|----------|
| Orchestration de haut niveau | `claude-fable-5` | Boss |
| Analyse approfondie, architecture | `claude-opus-5` | Sisyphus, Atlas, Hephaestus, Oracle, Metis, Momus, Prometheus |
| Implémentation standard | `claude-sonnet-5` | Librarian, Multimodal-Looker, spécialistes OMC |
| Recherche rapide, exploration | `claude-haiku-4-5` | Agents OMC légers, conseil simple |

### Niveaux d'effort

Le choix du modèle détermine *quel* cerveau traite la tâche ; le champ de frontmatter `effort:` détermine *à quelle profondeur* il réfléchit. Chaque agent maintenu en interne en déclare un.

| Effort | Agents |
|--------|--------|
| `xhigh` | Boss, Oracle, Prometheus, Multi-Agent Systems Architect |
| `high` | Sisyphus, Hephaestus, Atlas, Metis, Momus |
| `medium` | Librarian, Multimodal-Looker, AI Engineer, DevOps Automator |

Les skills déclarent aussi un effort — `boss-briefing` en `medium`, `briefing-vault` en `low`. `boss-advanced` et `gstack-sprint` n'en déclarent volontairement aucun : l'effort d'un skill remplace le niveau de session pendant son invocation et rétrograderait Boss silencieusement en pleine tâche.

Ordre de priorité : `CLAUDE_CODE_EFFORT_LEVEL` (variable d'environnement) > frontmatter > niveau d'effort de la session. `xhigh` est le plafond pris en charge par Fable ; `max` est réservé aux modèles de classe Opus et retombe silencieusement ailleurs.

### Workflow en sprint 3 phases

Pour l'implémentation de fonctionnalités de bout en bout, Boss orchestre un sprint structuré :

```
Phase 1 : CONCEPTION    Phase 2 : EXÉCUTION     Phase 3 : RÉVISION
(interactive)            (autonome)               (interactive)
─────────────────────   ─────────────────────   ─────────────────────
L'utilisateur définit   ralph exécute           Comparer avec le doc
la portée               Révision de code auto   de conception
Révision technique      Vérification architect  Présenter le tableau
Confirmer "conception   comparatif              comparatif
terminée"               User : approuver /      User : approuver /
                        améliorer               améliorer
```

### Workflows nommés

Des workflows multi-agents déterministes. `install.sh` les copie dans `~/.claude/workflows/`, ce qui les rend appelables depuis n'importe quel projet via l'outil Workflow, et pas seulement depuis ce dépôt.

| Workflow | Ce qu'il fait | Invocation |
|----------|---------------|------------|
| **code-review-fanout** | Quatre relecteurs thématiques (exactitude, sécurité, performance, tests) se déploient en parallèle, puis chaque constat est vérifié de manière contradictoire avant d'être signalé | `Workflow({name: "code-review-fanout"})` — argument : la cible de la revue (branche, plage de commits, chemins). Par défaut, le diff de la copie de travail |
| **upstream-audit** | Un analyste par upstream — écart de pin vis-à-vis d'origin, adéquation de la liste blanche, nouveaux recoupements, signaux de sécurité, santé — suivi d'une liste d'actions synthétisée | `Workflow({name: "upstream-audit"})` — pour les audits trimestriels ou avant une synchronisation |

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                    Requête utilisateur                │
└───────────────────────┬─────────────────────────────┘
                        ▼
┌─────────────────────────────────────────────────────┐
│  Boss · Méta-Orchestrateur (Fable)                    │
│  Découverte → Classification → Correspondance →       │
│  Délégation                                           │
└──┬──────────┬──────────┬──────────┬─────────────────┘
   │          │          │          │
   ▼          ▼          ▼          ▼
┌──────┐ ┌────────┐ ┌────────┐ ┌────────┐
│ P3a  │ │  P3b   │ │  P3c   │ │  P1/P2 │
│Direct│ │Sous-   │ │Équipes │ │ Skill/ │
│2-4   │ │orch    │ │d'agents│ │ Agent  │
│agents│ │Sisyphus│ │  P2P   │ │ Direct │
└──────┘ │Atlas   │ └────────┘ └────────┘
         │Hephaes│
         └────────┘
┌─────────────────────────────────────────────────────┐
│  Couche comportementale                               │
│  Principes Karpathy · Règles (54) · Hooks (8)        │
├─────────────────────────────────────────────────────┤
│  Agents spécialistes (32)                             │
│  Boss 1 · OMO 9 · OMC 19 · Vendored 3                │
├─────────────────────────────────────────────────────┤
│  Skills (139)                                         │
│  ECC 79 · gstack 27 · OMC 16 · Superpowers 13       │
│  + Core 4                                             │
├─────────────────────────────────────────────────────┤
│  Couche MCP                                           │
│  Context7 · Exa · grep.app                            │
├─────────────────────────────────────────────────────┤
│  Couche outillage                                     │
│  LSP (2) · Workflows nommés (2)                       │
└─────────────────────────────────────────────────────┘
```

---

## Ce qui est inclus

| Catégorie | Nombre | Source |
|----------|------:|--------|
| **Agents** (toujours chargés) | 32 | Boss 1 + OMO 9 + OMC 19 + Vendored 3 |
| **Skills** | 139 | ECC 79 · gstack 27 · OMC 16 · Superpowers 13 · Core 4 |
| **Règles** | 54 fichiers / 9 jeux | ECC 53 (common + 8 répertoires de langages) + Core 1 |
| **Serveurs MCP** | 3 | Context7, Exa, grep.app |
| **Hooks** | 8 fichiers / 8 événements | Garde de délégation, télémétrie, vérification, vault |
| **Serveurs LSP** | 2 | typescript (`typescript-language-server`), python (`pyright-langserver`) |
| **Workflows nommés** | 2 | code-review-fanout, upstream-audit |
| **Sous-modules upstream** | 4 | ecc, omc, gstack, superpowers |
| **Outils CLI** | 3 | omc, omo, ast-grep |

Chaque agent, skill et règle ci-dessus figure dans la liste d'autorisation de [`scripts/skill-allowlists.sh`](../../scripts/skill-allowlists.sh) et est suivi par le manifeste d'installation. Les skills documentaires officiels d'Anthropic (pdf, docx, etc.) sont installés séparément via `claude plugin add anthropics/skills` et volontairement exclus du manifeste.

<details>
<summary><strong>Agent principal — Méta-orchestrateur Boss (1)</strong></summary>

| Agent | Modèle | Rôle | Source |
|-------|-------|------|--------|
| Boss | Fable | Découverte dynamique à l'exécution → correspondance de capacités → routage optimal. N'écrit jamais de code. | my-claude |

</details>

<details>
<summary><strong>Agents OMO — Sous-orchestrateurs et spécialistes (9)</strong></summary>

| Agent | Modèle | Rôle | Source |
|-------|-------|------|--------|
| Sisyphus | Opus | Classification d'intention → délégation aux spécialistes → vérification | [oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent) |
| Hephaestus | Opus | Exploration autonome → planification → exécution → vérification | oh-my-openagent |
| Atlas | Opus | Décomposition de tâches + vérification QA en 4 étapes | oh-my-openagent |
| Oracle | Opus | Conseil technique stratégique (lecture seule) | oh-my-openagent |
| Metis | Opus | Analyse d'intention, détection d'ambiguïté | oh-my-openagent |
| Momus | Opus | Révision de faisabilité des plans | oh-my-openagent |
| Prometheus | Opus | Planification détaillée par entretien | oh-my-openagent |
| Librarian | Sonnet | Recherche de documentation open source via MCP | oh-my-openagent |
| Multimodal-Looker | Sonnet | Analyse d'images, captures d'écran et diagrammes | oh-my-openagent |

</details>

<details>
<summary><strong>Agents OMC — Agents spécialistes (19)</strong></summary>

| Agent | Rôle | Source |
|-------|------|--------|
| analyst | Pré-analyse avant planification | [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) |
| architect | Conception et architecture système | oh-my-claudecode |
| code-reviewer | Révision de code ciblée | oh-my-claudecode |
| code-simplifier | Simplification et nettoyage du code | oh-my-claudecode |
| critic | Analyse critique, propositions alternatives | oh-my-claudecode |
| debugger | Débogage ciblé | oh-my-claudecode |
| designer | Conseils de conception UI/UX | oh-my-claudecode |
| document-specialist | Rédaction de documentation | oh-my-claudecode |
| executor | Exécution de tâches | oh-my-claudecode |
| explore | Exploration de code source | oh-my-claudecode |
| git-master | Gestion du workflow Git | oh-my-claudecode |
| planner | Planification rapide | oh-my-claudecode |
| qa-tester | Tests d'assurance qualité | oh-my-claudecode |
| scientist | Recherche et expérimentation | oh-my-claudecode |
| security-reviewer | Révision de sécurité | oh-my-claudecode |
| test-engineer | Écriture et maintenance des tests | oh-my-claudecode |
| tracer | Traçage et analyse d'exécution | oh-my-claudecode |
| verifier | Vérification finale | oh-my-claudecode |
| writer | Contenu et documentation | oh-my-claudecode |

</details>

<details>
<summary><strong>Agents vendorisés — Spécialistes IA et infrastructure (3)</strong></summary>

Capturés depuis [agency-agents](https://github.com/msitarzewski/agency-agents) (MIT) le 2026-07-27, lors de la suppression de ce sous-module. Seuls les agents d'ingénierie sans équivalent ailleurs dans la stack ont été conservés ; chaque fichier porte son attribution d'origine.

| Agent | Rôle | Source |
|-------|------|--------|
| AI Engineer | Ingénierie IA/ML, intégration de modèles, pipelines de données | agency-agents (vendorisé) |
| DevOps Automator | Automatisation d'infrastructure, CI/CD, opérations cloud | agency-agents (vendorisé) |
| Multi-Agent Systems Architect | Topologie d'agents, gestion du contexte, reprise sur incident | agency-agents (vendorisé) |

</details>

<details>
<summary><strong>Skills — 139 issus de 5 sources</strong></summary>

Chaque source est pilotée par la liste d'autorisation de [`scripts/skill-allowlists.sh`](../../scripts/skill-allowlists.sh) : ce qui n'y figure pas n'est jamais installé.

| Source | Nombre | Skills clés |
|--------|------:|------------|
| [everything-claude-code](https://github.com/affaan-m/everything-claude-code) | 79 | coding-standards, react-patterns, fastapi-patterns, agent-architecture-audit, e2e-testing |
| [gstack](https://github.com/garrytan/gstack) | 27 | /qa, /review, /ship, /cso, /investigate, /office-hours |
| [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) | 16 | autopilot, ralph, team, ultrawork, ralplan, omc-reference |
| [superpowers](https://github.com/obra/superpowers) | 13 | brainstorming, systematic-debugging, test-driven-development, writing-plans |
| [my-claude Core](https://github.com/sehoon787/my-claude) | 4 | boss-advanced, boss-briefing, briefing-vault, gstack-sprint |

</details>

<details>
<summary><strong>Serveurs MCP (3) + Hooks (8)</strong></summary>

**Serveurs MCP**

| Serveur | Objectif | Coût |
|--------|---------|------|
| <img src="https://context7.com/favicon.ico" width="16" height="16" align="center"/> [Context7](https://mcp.context7.com) | Documentation de bibliothèques en temps réel | Gratuit |
| <img src="https://exa.ai/images/favicon-32x32.png" width="16" height="16" align="center"/> [Exa](https://mcp.exa.ai) | Recherche web sémantique | Gratuit 1k req/mois |
| <img src="https://www.google.com/s2/favicons?domain=grep.app&sz=32" width="16" height="16" align="center"/> [grep.app](https://mcp.grep.app) | Recherche de code GitHub | Gratuit |

**Hooks comportementaux**

| Hook | Événement | Comportement |
|------|-------|----------|
| Session Setup | SessionStart | Détecte les outils manquants + injecte le contexte Briefing Vault |
| Delegation Guard | PreToolUse | Empêche Boss de modifier directement des fichiers |
| Agent Telemetry | PostToolUse | Enregistre l'utilisation des agents dans `agent-usage.jsonl` |
| Subagent Verifier | SubagentStop | Force la vérification indépendante + enregistre dans Briefing Vault |
| Completion Check | Stop | Confirme que les tâches sont vérifiées + invite au résumé de session |
| Teammate Idle Guide | TeammateIdle | Invite le responsable sur les coéquipiers inactifs |
| Task Quality Gate | TaskCompleted | Vérifie la qualité du livrable |

</details>

<details>
<summary><strong>Serveurs LSP (2)</strong></summary>

Le plugin déclare deux serveurs de langage dans `.lsp.json`. Claude Code les démarre à la demande : les agents obtiennent diagnostics et navigation dans le code immédiatement, sans passer par un cycle de build.

| Serveur | Commande | Extensions |
|---------|----------|------------|
| typescript | `typescript-language-server --stdio` | `.ts` `.tsx` `.js` `.jsx` `.mjs` `.cjs` |
| python | `pyright-langserver --stdio` | `.py` |

`install.sh` installe les deux binaires de façon non bloquante — si l'un manque, seul ce serveur est désactivé et le reste de l'installation continue.

</details>

---

## <img src="https://obsidian.md/images/obsidian-logo-gradient.svg" width="24" height="24" align="center"/> Briefing Vault

Mémoire persistante compatible Obsidian. Chaque projet maintient un répertoire `.briefing/` qui se remplit automatiquement entre les sessions.

```
.briefing/
├── INDEX.md                          ← Contexte du projet (créé une seule fois)
├── sessions/
│   ├── YYYY-MM-DD-<topic>.md        ← Résumé de session écrit par l'IA (obligatoire)
│   └── YYYY-MM-DD-auto.md           ← Scaffold auto-généré (diff git, stats d'agents)
├── decisions/
│   └── YYYY-MM-DD-<decision>.md     ← Décision écrite par l'IA (obligatoire)
├── learnings/
│   ├── YYYY-MM-DD-<pattern>.md      ← Note d'apprentissage écrite par l'IA
│   └── YYYY-MM-DD-auto-session.md   ← Scaffold auto-généré (agents, fichiers)
├── references/
│   └── auto-links.md                ← URLs collectées automatiquement depuis les recherches web
├── agents/
│   ├── agent-log.jsonl              ← Télémétrie d'exécution des sous-agents
│   └── YYYY-MM-DD-summary.md        ← Récapitulatif quotidien d'utilisation des agents
├── persona/
│   ├── profile.md                   ← Statistiques d'affinité d'agents (mis à jour auto)
│   ├── suggestions.jsonl            ← Suggestions de routage (auto-générées)
│   ├── rules/                       ← Préférences de routage acceptées
│   └── skills/                      ← Skills persona acceptés
├── archives/                        ← Notes terminées/inactives (30+ jours)
│   ├── sessions/
│   ├── decisions/
│   └── learnings/
└── wiki/                            ← Pages de concepts (suggestion automatique)
    └── _schema.md
```

### Sous-Vaults

| Chemin | Description |
|--------|-------------|
| `INDEX.md` | Vue d'ensemble du projet avec liens vers les décisions et apprentissages récents. Créé automatiquement à la première session, rafraîchi périodiquement. |
| `sessions/` | **Résumés de session.** `*-auto.md` — scaffold avec stats diff git et comptage d'agents. `<topic>.md` — résumé écrit par l'IA, imposé par les hooks. |
| `decisions/` | **Décisions d'architecture et de conception** avec justification. Écrites par l'IA, imposées pendant le travail. |
| `learnings/` | **Patterns, pièges, solutions non évidentes.** `*-auto-session.md` — scaffold avec listes de fichiers. `<topic>.md` — écrit par l'IA. |
| `references/` | **URLs de recherche web.** `auto-links.md` — collectées automatiquement lors des appels WebSearch/WebFetch. |
| `agents/` | **Télémétrie des agents.** `agent-log.jsonl` — log par appel. `YYYY-MM-DD-summary.md` — récapitulatif quotidien d'utilisation. |
| `persona/` | **Profil de style de travail.** `profile.md` — statistiques d'affinité d'outils. `suggestions.jsonl` — recommandations de routage. `rules/`, `skills/` — préférences acceptées. |
| `archives/` | **Notes terminées/inactives.** Les notes de plus de 30 jours sont candidates à l'archivage. Concept Archives de PARA. Structure plate — le champ `type:` du frontmatter identifie la catégorie d'origine. |
| `wiki/` | **Pages wiki de concepts.** Les mots-clés apparaissant 3 fois ou plus déclenchent une suggestion automatique. Concept LLM-wiki. Format défini via `_schema.md`. |

### Gestion des connaissances (v2)

BriefingVault v2 intègre trois méthodologies de gestion des connaissances :

| Méthodologie | Concept | Application dans BriefingVault |
|--------------|---------|-------------------------------|
| **PARA** (Tiago Forte) | Organiser par capacité d'action : Projects, Areas, Resources, Archives | sessions/ = Projects, decisions/ = Areas, references/ = Resources, archives/ = Archives |
| **Zettelkasten** (Luhmann) | Notes atomiques avec identifiants uniques et liens explicites | fichiers learnings/ : IDs `YYYYMMDDHHMMSS`, champ `related:` avec 2+ liens obligatoires |
| **LLM-wiki** (Karpathy) | Pages de concepts maintenues par l'IA à partir des notes sources | pages wiki/ : suggestion automatique pour les mots-clés répétés 3+ fois |

### Diffs spécifiques à la session

Au début de la session, le git HEAD courant est enregistré dans `.briefing/.session-start-head`. En fin de session, les diffs sont calculés par rapport à ce point enregistré — montrant uniquement les modifications de la session courante, pas les modifications non commitées accumulées des sessions précédentes.

### Utilisation avec Obsidian

1. Ouvrez Obsidian → **Ouvrir le dossier comme coffre** → sélectionnez `.briefing/`
2. Les notes apparaissent dans la vue graphique, liées par `[[wiki-links]]`
3. Le frontmatter YAML (`date`, `type`, `tags`) permet une recherche structurée
4. La chronologie des décisions et apprentissages se construit automatiquement entre les sessions

---

## Sources open source en amont

my-claude relie 4 dépôts upstream sous licence MIT via des sous-modules git, chacun épinglé à un SHA explicite :

| # | Source | Ce qu'elle fournit |
|---|--------|-----------------|
| 1 | <img src="https://github.com/affaan-m.png?size=32" width="20" height="20" align="center"/> **[everything-claude-code](https://github.com/affaan-m/everything-claude-code)** — affaan-m | 79 skills installés + 9 jeux de règles. Voie connaissance langages et stack : TDD, sécurité, standards de codage, patterns de frameworks. |
| 2 | <img src="https://github.com/Yeachan-Heo.png?size=32" width="20" height="20" align="center"/> **[oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode)** — Yeachan Heo | 19 agents spécialistes + 16 skills installés. Voie orchestration : autopilot, ralph, team. |
| 3 | <img src="https://github.com/garrytan.png?size=32" width="20" height="20" align="center"/> **[gstack](https://github.com/garrytan/gstack)** — garrytan | 27 skills installés pour la livraison, la QA, le déploiement et la revue de sécurité (voie Boss P0). Inclut un daemon navigateur Playwright. |
| 4 | <img src="https://github.com/obra.png?size=32" width="20" height="20" align="center"/> **[superpowers](https://github.com/obra/superpowers)** — Jesse Vincent | 13 skills installés pour la voie processus de dev : brainstorming, TDD, débogage systématique, rédaction de plans. |

Pas des sous-modules, mais partie intégrante de la stack :

| Source | Mode d'intégration |
|--------|--------------------|
| <img src="https://github.com/code-yeongyu.png?size=32" width="20" height="20" align="center"/> **[oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent)** — code-yeongyu | 9 agents OMO (Sisyphus, Atlas, Oracle, etc.), portés dans ce dépôt en agents `.md` autonomes sous `agents/omo/`. |
| <img src="https://github.com/msitarzewski.png?size=32" width="20" height="20" align="center"/> **[agency-agents](https://github.com/msitarzewski/agency-agents)** — msitarzewski | Sous-module supprimé le 2026-07-27. 3 agents d'ingénierie vendorisés dans `agents/vendored/` avec attribution. |
| <img src="https://www.anthropic.com/favicon.ico" width="20" height="20" align="center"/> **[anthropic/skills](https://github.com/anthropics/skills)** — Anthropic | Installés par `install.sh` via `claude plugin add anthropics/skills` (pdf, docx, etc.). Non suivis par le manifeste. |
| <img src="https://github.com/forrestchang.png?size=32" width="20" height="20" align="center"/> **[andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills)** — forrestchang | 4 principes de comportement de codage IA ajoutés à `~/.claude/CLAUDE.md`. |

---

## GitHub Actions

| Workflow | Déclencheur | Objectif |
|----------|---------|---------|
| **CI** | push, PR | Valide les configs JSON, le frontmatter des agents, l'existence des skills, les nombres de fichiers upstream |
| **Smoke** | push, PR | 4 jobs — `hooks` (exécution des hooks), `shell` (forme du script d'installation), `drift` (dérive de modèle), `routing-refs` (références d'agents/skills mortes) |
| **Update Upstream** | tous les 3 jours / manuel | `git submodule update --remote` → rafraîchit les SHA épinglés dans `SOURCES.json` → scan de sécurité du diff upstream → fusion automatique uniquement si le scan est propre, sinon la PR reste ouverte pour revue humaine |
| **Auto Tag** | push sur main | Lit la version de `plugin.json` et crée un tag git si nouvelle |
| **Pages** | push sur main | Déploie `docs/index.html` sur GitHub Pages |
| **CLA** | PR | Vérification du Contrat de Licence de Contributeur |
| **Lint Workflows** | push, PR | Valide la syntaxe YAML des workflows GitHub Actions |

---

## Originaux my-claude

Fonctionnalités construites spécifiquement pour ce projet, au-delà de ce que fournissent les sources upstream :

| Fonctionnalité | Description |
|---------|-------------|
| **Boss Méta-Orchestrateur** | Découverte dynamique des capacités → classification d'intention → routage à 5 priorités → délégation → vérification |
| **Sprint 3 phases** | Conception (interactive) → Exécution (autonome via ralph) → Révision (interactive vs doc de conception) |
| **Priorité par niveau d'agent** | core > omo > omc > déduplication vendored. L'agent le plus spécialisé l'emporte. |
| **Répartition des voies** | Orchestration → OMC, processus de dev → superpowers, livraison/QA/déploiement/sécurité → gstack (Boss P0), connaissance langages et stack → ECC, IA et domaine → agents vendorisés |
| **Listes d'autorisation curées** | `scripts/skill-allowlists.sh` fait autorité — sur des milliers d'entrées upstream, 139 skills et 9 jeux de règles survivent ; rien de non listé n'atteint le contexte de session |
| **Briefing Vault** | Répertoire `.briefing/` compatible Obsidian avec sessions, décisions, apprentissages, références |
| **Télémétrie des agents** | Le hook PostToolUse enregistre l'utilisation des agents dans `agent-usage.jsonl` |
| **Smart Packs** | La détection du type de projet recommande les packs d'agents pertinents au démarrage de session |
| **Sync ignorée si rien ne change** | La synchronisation upstream indexe les bumps de sous-modules et les SHA de `SOURCES.json`, puis n'ouvre une PR que si ce diff est non vide |
| **Détection de doublon d'agents** | `tests/validate-sync.sh` compare les noms de fichiers d'agents entre `agents/` et les sous-modules omc et superpowers, et signale les collisions |

---

## Versions upstream groupées

Liées via des sous-modules git. Les commits épinglés sont suivis nativement par `.gitmodules` et reflétés en AI-BOM dans [`upstream/SOURCES.json`](../../upstream/SOURCES.json). `install.sh` extrait exactement ces SHA au lieu de suivre `main`.

| Source | SHA | Date | Diff |
|--------|-----|------|------|
| [everything-claude-code](https://github.com/affaan-m/everything-claude-code) | `4092795` | 2026-07-27 | [comparer](https://github.com/affaan-m/everything-claude-code/compare/4092795...HEAD) |
| [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) | `590fb98` | 2026-07-27 | [comparer](https://github.com/Yeachan-Heo/oh-my-claudecode/compare/590fb98...HEAD) |
| [gstack](https://github.com/garrytan/gstack) | `7c9df1c` | 2026-07-27 | [comparer](https://github.com/garrytan/gstack/compare/7c9df1c...HEAD) |
| [superpowers](https://github.com/obra/superpowers) | `3dcbd5c` | 2026-07-27 | [comparer](https://github.com/obra/superpowers/compare/3dcbd5c...HEAD) |

---

## Contribuer

Les issues et PR sont les bienvenus. Lors de l'ajout d'un nouvel agent, ajoutez un fichier `.md` dans `agents/core/` ou `agents/omo/` et mettez à jour `SETUP.md`.

## Remerciements

Construit sur le travail de : [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) (Yeachan Heo), [oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent) (code-yeongyu), [everything-claude-code](https://github.com/affaan-m/everything-claude-code) (affaan-m), [gstack](https://github.com/garrytan/gstack) (garrytan), [superpowers](https://github.com/obra/superpowers) (Jesse Vincent), [agency-agents](https://github.com/msitarzewski/agency-agents) (msitarzewski — 3 agents vendorisés), [anthropic/skills](https://github.com/anthropics/skills) (Anthropic), [andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills) (forrestchang).

## Licence

Licence MIT. Voir le fichier [LICENSE](./LICENSE) pour plus de détails.
