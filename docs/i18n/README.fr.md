[English](../../README.md) | [한국어](./README.ko.md) | [日本語](./README.ja.md) | [中文](./README.zh.md) | [Deutsch](./README.de.md) | [Français](./README.fr.md)

> [![Codex CLI](https://img.shields.io/badge/Codex_CLI-my--codex-10b981?style=flat-square&logo=openai&logoColor=white)](https://github.com/sehoon787/my-codex) Vous cherchez Codex CLI ? → **my-codex** — la même orchestration au format TOML natif

---

<div align="center">

# my-claude

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Agents](https://img.shields.io/badge/agents-200%2B-blue)
![Skills](https://img.shields.io/badge/skills-200%2B-purple)
![Rules](https://img.shields.io/badge/rules-87-orange)
![MCP Servers](https://img.shields.io/badge/MCP-3-green)
![Hooks](https://img.shields.io/badge/hooks-7-red)

**Harnais d'agents tout-en-un pour Claude Code.**
**Un seul plugin, 200+ agents prêts à l'emploi.**

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
│  P2: Agent spécialiste (200+)              │
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
| **P1** | Correspondance de skill | La tâche correspond à un skill autonome | `"fusionner des PDFs"` → skill pdf |
| **P2** | Agent spécialiste | Un agent spécifique au domaine existe | `"audit de sécurité"` → Security Engineer |
| **P3a** | Boss direct | 2-4 agents indépendants | `"corriger 3 bugs"` → lancement parallèle |
| **P3b** | Sous-orchestrateur | Workflow complexe multi-étapes | `"refactor + test"` → Sisyphus |
| **P3c** | Équipes d'agents | Communication pair-à-pair nécessaire | `"implémenter + réviser"` → Review Chain |
| **P4** | Repli | Aucun spécialiste trouvé | `"expliquer ceci"` → agent généraliste |

### Routage par modèle

| Complexité | Modèle | Utilisé pour |
|-----------|-------|----------|
| Analyse approfondie, architecture | Opus | Boss, Oracle, Sisyphus |
| Implémentation standard | Sonnet | executor, debugger, security-reviewer |
| Recherche rapide, exploration | Haiku | explore, conseil simple |

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

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                    Requête utilisateur                │
└───────────────────────┬─────────────────────────────┘
                        ▼
┌─────────────────────────────────────────────────────┐
│  Boss · Méta-Orchestrateur (Opus)                     │
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
│  Principes Karpathy · Règles ECC (87) · Hooks (7)    │
├─────────────────────────────────────────────────────┤
│  Agents spécialistes (200+)                           │
│  OMO 9 · OMC 19 · Agency Eng. 26 · Superpowers 1    │
│  + 136 packs de domaine (à la demande)                │
├─────────────────────────────────────────────────────┤
│  Skills (200+)                                        │
│  ECC 180+ · OMC 36 · gstack 40 · Superpowers 14     │
│  + Core 3 · Anthropic 14+                             │
├─────────────────────────────────────────────────────┤
│  Couche MCP                                           │
│  Context7 · Exa · grep.app                            │
└─────────────────────────────────────────────────────┘
```

---

## Ce qui est inclus

| Catégorie | Nombre | Source |
|----------|------:|--------|
| **Agents principaux** (toujours chargés) | 56 | Boss 1 + OMO 9 + OMC 19 + Agency Engineering 26 + Superpowers 1 |
| **Packs d'agents** (à la demande) | 136 | 12 catégories de domaines issus de agency-agents |
| **Skills** | 200+ | ECC 180+ · OMC 36 · gstack 40 · Superpowers 14 · Core 3 |
| **Skills Anthropic** | 14+ | PDF, DOCX, PPTX, XLSX, MCP builder |
| **Règles** | 87 | ECC common + 14 répertoires de langages |
| **Serveurs MCP** | 3 | Context7, Exa, grep.app |
| **Hooks** | 7 | Garde de délégation, télémétrie, vérification |
| **Outils CLI** | 3 | omc, omo, ast-grep |

<details>
<summary><strong>Agent principal — Méta-orchestrateur Boss (1)</strong></summary>

| Agent | Modèle | Rôle | Source |
|-------|-------|------|--------|
| Boss | Opus | Découverte dynamique à l'exécution → correspondance de capacités → routage optimal. N'écrit jamais de code. | my-claude |

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
<summary><strong>Agency Engineering — Spécialistes toujours chargés (26)</strong></summary>

| Agent | Rôle | Source |
|-------|------|--------|
| AI Engineer | Ingénierie IA/ML | [agency-agents](https://github.com/msitarzewski/agency-agents) |
| Backend Architect | Architecture backend | agency-agents |
| CMS Developer | Développement CMS | agency-agents |
| Code Reviewer | Révision de code | agency-agents |
| Data Engineer | Ingénierie des données | agency-agents |
| Database Optimizer | Optimisation de base de données | agency-agents |
| DevOps Automator | Automatisation DevOps | agency-agents |
| Embedded Firmware Engineer | Firmware embarqué | agency-agents |
| Frontend Developer | Développement frontend | agency-agents |
| Git Workflow Master | Workflow Git | agency-agents |
| Incident Response Commander | Gestion d'incidents | agency-agents |
| Mobile App Builder | Applications mobiles | agency-agents |
| Rapid Prototyper | Prototypage rapide | agency-agents |
| Security Engineer | Ingénierie sécurité | agency-agents |
| Senior Developer | Développement senior | agency-agents |
| Software Architect | Architecture logicielle | agency-agents |
| SRE | Fiabilité du site | agency-agents |
| Technical Writer | Documentation technique | agency-agents |
| AI Data Remediation Engineer | Pipelines de données auto-correctifs | agency-agents |
| Autonomous Optimization Architect | Gouvernance des performances API | agency-agents |
| Email Intelligence Engineer | Extraction de données e-mail | agency-agents |
| Feishu Integration Developer | Plateforme Feishu/Lark | agency-agents |
| Filament Optimization Specialist | Optimisation Filament PHP | agency-agents |
| Solidity Smart Contract Engineer | Contrats intelligents EVM | agency-agents |
| Threat Detection Engineer | SIEM & chasse aux menaces | agency-agents |
| WeChat Mini Program Developer | WeChat 小程序 | agency-agents |

</details>

<details>
<summary><strong>Packs d'agents — Spécialistes de domaine à la demande (136)</strong></summary>

Installés dans `~/.claude/agent-packs/`. Activation par lien symbolique :

```bash
ln -s ~/.claude/agent-packs/marketing/*.md ~/.claude/agents/
```

| Pack | Nombre | Exemples | Source |
|------|------:|---------|--------|
| marketing | 29 | Douyin, Xiaohongshu, TikTok, SEO | [agency-agents](https://github.com/msitarzewski/agency-agents) |
| specialized | 28 | Juridique, Finance, Santé, MCP Builder | agency-agents |
| game-development | 20 | Unity, Unreal, Godot, Roblox | agency-agents |
| design | 8 | Marque, UI, UX, Visual Storytelling | agency-agents |
| testing | 8 | API, Accessibilité, Performance | agency-agents |
| sales | 8 | Stratégie de deal, Analyse de pipeline | agency-agents |
| paid-media | 7 | Google Ads, Meta Ads, Programmatique | agency-agents |
| project-management | 6 | Scrum, Kanban, Gestion des risques | agency-agents |
| spatial-computing | 6 | visionOS, WebXR, Metal | agency-agents |
| support | 6 | Analytique, Infrastructure, Juridique | agency-agents |
| academic | 5 | Anthropologue, Historien, Psychologue | agency-agents |
| product | 5 | Product Manager, Sprint, Retours | agency-agents |

</details>

<details>
<summary><strong>Skills — 200+ issus de 6 sources</strong></summary>

| Source | Nombre | Skills clés |
|--------|------:|------------|
| [everything-claude-code](https://github.com/affaan-m/everything-claude-code) | 180+ | tdd-workflow, autopilot, ralph, security-review, coding-standards |
| [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) | 36 | plan, team, trace, deep-dive, blueprint, ultrawork |
| [gstack](https://github.com/garrytan/gstack) | 40 | /qa, /review, /ship, /cso, /investigate, /office-hours |
| [superpowers](https://github.com/obra/superpowers) | 14 | brainstorming, systematic-debugging, TDD, parallel-agents |
| [my-claude Core](https://github.com/sehoon787/my-claude) | 3 | boss-advanced, gstack-sprint, briefing-vault |
| [Anthropic Official](https://github.com/anthropics/skills) | 14+ | pdf, docx, pptx, xlsx, canvas-design, mcp-builder |

</details>

<details>
<summary><strong>Serveurs MCP (3) + Hooks (7)</strong></summary>

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
└── persona/
    ├── profile.md                   ← Statistiques d'affinité d'agents (mis à jour auto)
    ├── suggestions.jsonl            ← Suggestions de routage (auto-générées)
    ├── rules/                       ← Préférences de routage acceptées
    └── skills/                      ← Skills persona acceptés
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

### Diffs spécifiques à la session

Au début de la session, le git HEAD courant est enregistré dans `.briefing/.session-start-head`. En fin de session, les diffs sont calculés par rapport à ce point enregistré — montrant uniquement les modifications de la session courante, pas les modifications non commitées accumulées des sessions précédentes.

### Utilisation avec Obsidian

1. Ouvrez Obsidian → **Ouvrir le dossier comme coffre** → sélectionnez `.briefing/`
2. Les notes apparaissent dans la vue graphique, liées par `[[wiki-links]]`
3. Le frontmatter YAML (`date`, `type`, `tags`) permet une recherche structurée
4. La chronologie des décisions et apprentissages se construit automatiquement entre les sessions

---

## Sources open source en amont

my-claude regroupe du contenu provenant de 5 dépôts upstream sous licence MIT via des sous-modules git :

| # | Source | Ce qu'elle fournit |
|---|--------|-----------------|
| 1 | <img src="https://github.com/Yeachan-Heo.png?size=32" width="20" height="20" align="center"/> **[oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode)** — Yeachan Heo | 19 agents spécialistes + 36 skills. Harnais multi-agents Claude Code avec autopilot, ralph, orchestration d'équipe. |
| 2 | <img src="https://github.com/code-yeongyu.png?size=32" width="20" height="20" align="center"/> **[oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent)** — code-yeongyu | 9 agents OMO (Sisyphus, Atlas, Oracle, etc.). Harnais d'agents multi-plateforme reliant Claude, GPT, Gemini. |
| 3 | <img src="https://github.com/affaan-m.png?size=32" width="20" height="20" align="center"/> **[everything-claude-code](https://github.com/affaan-m/everything-claude-code)** — affaan-m | 180+ skills + 87 règles dans 14 langages. Framework de développement complet avec TDD, sécurité et standards de codage. |
| 4 | <img src="https://github.com/msitarzewski.png?size=32" width="20" height="20" align="center"/> **[agency-agents](https://github.com/msitarzewski/agency-agents)** — msitarzewski | 26 agents d'ingénierie (toujours chargés) + 136 packs d'agents de domaine dans 12 catégories. |
| 5 | <img src="https://github.com/garrytan.png?size=32" width="20" height="20" align="center"/> **[gstack](https://github.com/garrytan/gstack)** — garrytan | 40 skills pour la révision de code, QA, audit de sécurité, déploiement. Inclut un daemon navigateur Playwright. |
| 6 | <img src="https://github.com/obra.png?size=32" width="20" height="20" align="center"/> **[superpowers](https://github.com/obra/superpowers)** — Jesse Vincent | 14 skills + 1 agent couvrant brainstorming, TDD, agents parallèles et révision de code. |
| 7 | <img src="https://www.anthropic.com/favicon.ico" width="20" height="20" align="center"/> **[anthropic/skills](https://github.com/anthropics/skills)** — Anthropic | 14+ skills officiels pour PDF, DOCX, PPTX, XLSX et le MCP builder. |
| 8 | <img src="https://github.com/forrestchang.png?size=32" width="20" height="20" align="center"/> **[andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills)** — forrestchang | 4 principes comportementaux de codage IA (Réfléchir avant de coder, La simplicité d'abord, Modifications chirurgicales, Exécution orientée objectifs). |

---

## GitHub Actions

| Workflow | Déclencheur | Objectif |
|----------|---------|---------|
| **CI** | push, PR | Valide les configs JSON, le frontmatter des agents, l'existence des skills, les nombres de fichiers upstream |
| **Update Upstream** | hebdomadaire / manuel | Exécute `git submodule update --remote` et crée une PR de fusion automatique |
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
| **Priorité par niveau d'agent** | core > omo > omc > déduplication agency. L'agent le plus spécialisé l'emporte. |
| **Optimisation des coûts Agency** | Haiku pour le conseil, Sonnet pour l'implémentation — routage de modèle automatique pour 172 agents de domaine |
| **Briefing Vault** | Répertoire `.briefing/` compatible Obsidian avec sessions, décisions, apprentissages, références |
| **Télémétrie des agents** | Le hook PostToolUse enregistre l'utilisation des agents dans `agent-usage.jsonl` |
| **Smart Packs** | La détection du type de projet recommande les packs d'agents pertinents au démarrage de session |
| **Pré-vérification CI SHA** | La synchronisation upstream ignore les sources inchangées via comparaison SHA `git ls-remote` |
| **Détection de doublon d'agents** | La comparaison normalisée des noms détecte les doublons entre les sources upstream |

---

## Versions upstream groupées

Liées via des sous-modules git. Les commits épinglés sont suivis nativement par `.gitmodules`.

| Source | SHA | Date | Diff |
|--------|-----|------|------|
| [agency-agents](https://github.com/msitarzewski/agency-agents) | `4feb0cd` | 2026-04-07 | [comparer](https://github.com/msitarzewski/agency-agents/compare/4feb0cd...HEAD) |
| [everything-claude-code](https://github.com/affaan-m/everything-claude-code) | `7dfdbe0` | 2026-04-07 | [comparer](https://github.com/affaan-m/everything-claude-code/compare/7dfdbe0...HEAD) |
| [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) | `2487d38` | 2026-04-07 | [comparer](https://github.com/Yeachan-Heo/oh-my-claudecode/compare/2487d38...HEAD) |
| [gstack](https://github.com/garrytan/gstack) | `03973c2` | 2026-04-07 | [comparer](https://github.com/garrytan/gstack/compare/03973c2...HEAD) |
| [superpowers](https://github.com/obra/superpowers) | `b7a8f76` | 2026-04-06 | [comparer](https://github.com/obra/superpowers/compare/b7a8f76...HEAD) |

---

## Contribuer

Les issues et PR sont les bienvenus. Lors de l'ajout d'un nouvel agent, ajoutez un fichier `.md` dans `agents/core/` ou `agents/omo/` et mettez à jour `SETUP.md`.

## Remerciements

Construit sur le travail de : [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) (Yeachan Heo), [oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent) (code-yeongyu), [everything-claude-code](https://github.com/affaan-m/everything-claude-code) (affaan-m), [agency-agents](https://github.com/msitarzewski/agency-agents) (msitarzewski), [gstack](https://github.com/garrytan/gstack) (garrytan), [superpowers](https://github.com/obra/superpowers) (Jesse Vincent), [anthropic/skills](https://github.com/anthropics/skills) (Anthropic), [andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills) (forrestchang).

## Licence

Licence MIT. Voir le fichier [LICENSE](./LICENSE) pour plus de détails.
