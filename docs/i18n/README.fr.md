[English](../../README.md) | [한국어](./README.ko.md) | [日本語](./README.ja.md) | [中文](./README.zh.md) | [Deutsch](./README.de.md) | [Français](./README.fr.md)

> [![Codex CLI](https://img.shields.io/badge/Codex_CLI-my--codex-10b981?style=flat-square&logo=openai&logoColor=white)](https://github.com/sehoon787/my-codex) Vous cherchez Codex CLI ? → **my-codex** — la même orchestration au format TOML natif

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

| Phase | Ce qui se passe |
|-------|-----------------|
| **0 · DISCOVERY** | Analyse les agents, skills, MCP et hooks à l'exécution pour construire un registre des capacités en direct |
| **1 · INTENT GATE** | Classe la requête (trivial, build, refactor, mid-sized, architecture, research, …) et contre-propose un skill lorsqu'un skill convient mieux |
| **2 · CAPABILITY MATCHING** | Fait cascader la chaîne de priorités ci-dessous (P0 skill gstack → P1 correspondance exacte de skill → P2 agent spécialiste → P3 orchestration multi-agents → P4 repli généraliste) |
| **3 · DELEGATION** | Envoie au spécialiste un prompt structuré en 6 sections : TASK / OUTCOME / TOOLS / DO / DON'T / CTX |
| **4 · VERIFICATION** | Relit indépendamment les fichiers modifiés, exécute les tests, le lint et le build, recoupe avec l'intention d'origine, et réessaie jusqu'à 3× en cas d'échec |

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
| Orchestration de haut niveau | `claude-fable-5-1` | Boss |
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

| Phase | Mode | Ce qui se passe |
|-------|------|-----------------|
| **1 · DESIGN** | interactif | l'utilisateur définit la portée · révision technique · confirmer « conception terminée » |
| **2 · EXECUTE** | autonome | ralph exécute · révision de code automatique · vérification architect |
| **3 · REVIEW** | interactif | comparer avec le doc de conception · présenter le tableau comparatif · l'utilisateur approuve ou demande une amélioration |

### Rapport final structuré

Boss clôt chaque tour de travail — tout tour ayant édité ou créé des fichiers, produit des commits/PR/merges, modifié la configuration ou exécuté une vérification — par un rapport final structuré lisible sans ouvrir de diff. Le rapport est assemblé à partir de cinq tableaux fixes, chacun n'étant émis que si sa situation s'est réellement produite (jamais de tableau vide) :

| Situation | Tableau | Colonnes |
|-----------|-------|---------|
| Fichiers/paramètres modifiés | 변경 대조 (Changes) | 대상 / Before / After / 근거 |
| Plusieurs tâches terminées | 작업 요약 (Work summary) | 항목 / 결과 / 근거 |
| Vérification exécutée | 검증 결과 (Verification) | 항목 / 기대 / 실제 / 판정 |
| Commits/PR produits | 산출물 (Deliverables) | PR / 저장소 / 내용 / 상태 |
| Éléments non résolus | 남은 것 (Remaining) | 항목 / 상태 / 다음 조치 |

Il ne se déclenche qu'à la toute fin de la requête — jamais dans un tour qui lance ou relaie du travail en arrière-plan, jamais comme point d'étape en cours de tâche — et les tours de simple Q&R se terminent normalement sans lui. La spécification vit dans `boss.md § FINAL REPORT` ; le hook Stop `stop-final-report.js` la fait respecter.

### Workflows nommés

Des workflows multi-agents déterministes. `install.sh` les copie dans `~/.claude/workflows/`, ce qui les rend appelables depuis n'importe quel projet via l'outil Workflow, et pas seulement depuis ce dépôt.

| Workflow | Ce qu'il fait | Invocation |
|----------|---------------|------------|
| **code-review-fanout** | Quatre relecteurs thématiques (exactitude, sécurité, performance, tests) se déploient en parallèle, puis chaque constat est vérifié de manière contradictoire avant d'être signalé | `Workflow({name: "code-review-fanout"})` — argument : la cible de la revue (branche, plage de commits, chemins). Par défaut, le diff de la copie de travail |
| **upstream-audit** | Un analyste par upstream — écart de pin vis-à-vis d'origin, adéquation de la liste blanche, nouveaux recoupements, signaux de sécurité, santé — suivi d'une liste d'actions synthétisée | `Workflow({name: "upstream-audit"})` — pour les audits trimestriels ou avant une synchronisation |

---

## Ce qui est inclus

| Catégorie | Nombre | Source |
|----------|------:|--------|
| **Agents** (toujours chargés) | 32 | Boss 1 + OMO 9 + OMC 19 + Vendored 3 |
| **Skills** | 105 | ECC 61 · gstack 27 · Superpowers 13 · Core 4 |
| **Règles** | 48 fichiers / 9 jeux | ECC 46 (common + 8 répertoires de langages) + Core 2 |
| **Serveurs MCP** | 3 | Context7, Exa, grep.app |
| **Hooks** | 10 fichiers / 6 événements | Garde de délégation, télémétrie, vérification, vault |
| **Serveurs LSP** | 2 | typescript (`typescript-language-server`), python (`pyright-langserver`) |
| **Workflows nommés** | 2 | code-review-fanout, upstream-audit |
| **Sous-modules upstream** | 4 | ecc, omc, gstack, superpowers |
| **Outils CLI** | 7 | omc, omo, ast-grep, comment-checker, codeburn, serena, headroom |

Chaque agent, skill et règle ci-dessus figure dans la liste d'autorisation de [`scripts/skill-allowlists.sh`](../../scripts/skill-allowlists.sh) et est suivi par le manifeste d'installation. Les skills documentaires officiels d'Anthropic (pdf, docx, etc.) sont installés séparément via `claude plugin add anthropics/skills` et volontairement exclus du manifeste.

<details>
<summary><strong>Agents spécialistes — 32 répartis sur 4 niveaux</strong></summary>

Les modèles utilisés par agent sont listés dans le tableau de routage par modèle ci-dessus.

Les agents vendorisés ont été capturés depuis [agency-agents](https://github.com/msitarzewski/agency-agents) (MIT) le 2026-07-27, lors de la suppression de ce sous-module. Seuls les agents d'ingénierie sans équivalent ailleurs dans la stack ont été conservés ; chaque fichier porte son attribution d'origine.

| Agent | Niveau | Rôle | Source |
|-------|--------|------|--------|
| Boss | core | Découverte dynamique à l'exécution → correspondance de capacités → routage optimal. N'écrit jamais de code. | my-claude |
| Sisyphus | omo | Classification d'intention → délégation aux spécialistes → vérification | [oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent) |
| Hephaestus | omo | Exploration autonome → planification → exécution → vérification | oh-my-openagent |
| Atlas | omo | Décomposition de tâches + vérification QA en 4 étapes | oh-my-openagent |
| Oracle | omo | Conseil technique stratégique (lecture seule) | oh-my-openagent |
| Metis | omo | Analyse d'intention, détection d'ambiguïté | oh-my-openagent |
| Momus | omo | Révision de faisabilité des plans | oh-my-openagent |
| Prometheus | omo | Planification détaillée par entretien | oh-my-openagent |
| Librarian | omo | Recherche de documentation open source via MCP | oh-my-openagent |
| Multimodal-Looker | omo | Analyse d'images, captures d'écran et diagrammes | oh-my-openagent |
| analyst | omc | Pré-analyse avant planification | [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) |
| architect | omc | Conception et architecture système | oh-my-claudecode |
| code-reviewer | omc | Révision de code ciblée | oh-my-claudecode |
| code-simplifier | omc | Simplification et nettoyage du code | oh-my-claudecode |
| critic | omc | Analyse critique, propositions alternatives | oh-my-claudecode |
| debugger | omc | Débogage ciblé | oh-my-claudecode |
| designer | omc | Conseils de conception UI/UX | oh-my-claudecode |
| document-specialist | omc | Rédaction de documentation | oh-my-claudecode |
| executor | omc | Exécution de tâches | oh-my-claudecode |
| explore | omc | Exploration de code source | oh-my-claudecode |
| git-master | omc | Gestion du workflow Git | oh-my-claudecode |
| planner | omc | Planification rapide | oh-my-claudecode |
| qa-tester | omc | Tests d'assurance qualité | oh-my-claudecode |
| scientist | omc | Recherche et expérimentation | oh-my-claudecode |
| security-reviewer | omc | Révision de sécurité | oh-my-claudecode |
| test-engineer | omc | Écriture et maintenance des tests | oh-my-claudecode |
| tracer | omc | Traçage et analyse d'exécution | oh-my-claudecode |
| verifier | omc | Vérification finale | oh-my-claudecode |
| writer | omc | Contenu et documentation | oh-my-claudecode |
| AI Engineer | vendored | Ingénierie IA/ML, intégration de modèles, pipelines de données | agency-agents (vendorisé) |
| DevOps Automator | vendored | Automatisation d'infrastructure, CI/CD, opérations cloud | agency-agents (vendorisé) |
| Multi-Agent Systems Architect | vendored | Topologie d'agents, gestion du contexte, reprise sur incident | agency-agents (vendorisé) |

</details>

<details>
<summary><strong>Skills — 105 issus de 4 sources</strong></summary>

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
<summary><strong>Serveurs MCP (3) + Hooks (10)</strong></summary>

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
| Subagent Logger | SubagentStop | Enregistre l'exécution des agents dans Briefing Vault |
| Completion Check | Stop | Confirme que les tâches sont vérifiées + invite au résumé de session |

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

### Sous-Vaults

| Chemin | Description |
|--------|-------------|
| `INDEX.md` | Vue d'ensemble du projet avec liens vers les décisions et apprentissages récents. Créé automatiquement à la première session, rafraîchi périodiquement. |
| `sessions/` | **Résumés de session.** `*-auto.md` — scaffold avec stats diff git et comptage d'agents. `<topic>.md` — résumé écrit par l'IA, imposé par les hooks. |
| `decisions/` | **Décisions d'architecture et de conception** avec justification. `YYYY-MM-DD-<decision>.md` — écrite par l'IA, imposée pendant le travail. |
| `learnings/` | **Patterns, pièges, solutions non évidentes.** `YYYY-MM-DD-auto-session.md` — scaffold avec listes de fichiers. `YYYY-MM-DD-<pattern>.md` — écrit par l'IA. |
| `references/` | **URLs de recherche web.** `auto-links.md` — collectées automatiquement lors des appels WebSearch/WebFetch. |
| `agents/` | **Télémétrie des agents.** `agent-log.jsonl` — log par appel. `YYYY-MM-DD-summary.md` — récapitulatif quotidien d'utilisation. |
| `persona/` | **Profil de style de travail.** `profile.md` — statistiques d'affinité d'outils. `suggestions.jsonl` — recommandations de routage. `rules/`, `skills/` — préférences acceptées. |
| `archives/` | **Notes terminées/inactives.** Sous-répertoires `sessions/`, `decisions/`, `learnings/`. Les notes de plus de 30 jours sont candidates à l'archivage. Concept Archives de PARA. Structure plate — le champ `type:` du frontmatter identifie la catégorie d'origine. |
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

## Où voir les résultats

Chaque outil de la stack écrit ses résultats quelque part — voici où les trouver.

| Outil | Ce qu'il fait | Comment l'exécuter | Où regarder |
|------|--------------|-----------|---------------|
| **codeburn** | Comptabilité des tokens et des coûts sur l'ensemble des sessions passées | `codeburn` (TUI interactif) · `codeburn web` pour un tableau de bord dans le navigateur (`--no-open` pour afficher l'URL au lieu de lancer un navigateur) · `codeburn report --format json --period week` pour un export non interactif (également `--day`, `--from`/`--to`, `--provider claude`) | Lit `~/.claude/projects/**/*.jsonl` en lecture seule. Tableau de bord navigateur sur <http://127.0.0.1:4747> (`codeburn web` ; bascule sur un port libre si celui-ci est pris). Les montants en dollars sont des **estimations** : nombre de tokens valorisé au tarif API public, donc sur un abonnement c'est un indicateur d'usage, pas une facture. |
| **Serena** | Navigation et édition de code au niveau des symboles | Démarre automatiquement comme serveur MCP ; appelez `get_symbols_overview` / `find_symbol` depuis n'importe quelle session | Tableau de bord sur <http://localhost:24282/dashboard/index.html> tant qu'un serveur tourne (logs + nombre d'appels par outil). Les mémoires par projet atterrissent dans `.serena/` à l'intérieur du dépôt sur lequel vous travaillez ; la configuration globale est `~/.serena/serena_config.yml`. |
| **Headroom** | Compresse les résultats d'outils surdimensionnés avant leur entrée dans la transcription | Outils MCP `headroom_compress` / `headroom_retrieve` / `headroom_stats` · proxy optionnel : `headroom proxy --port 8787`, puis `ANTHROPIC_BASE_URL=http://127.0.0.1:8787 claude` | `headroom_stats` rapporte le nombre de compressions du serveur en cours d'exécution. Avec le proxy activé, <http://127.0.0.1:8787/stats> et `headroom dashboard`. Sans lui, `headroom doctor` et `headroom perf` rapportent « not reachable » / « no performance data » — attendu, puisqu'ils décrivent le proxy. |
| **Archify** | Diagrammes d'architecture, de workflow, de séquence, de flux de données et de cycle de vie | Demandez un diagramme et Boss route vers le skill `archify`. Manuellement, depuis `~/.claude/skills/archify` : `node bin/archify.mjs render workflow examples/agent-tool-call.workflow.json out.html` | Le fichier `out.html` généré — ouvrez-le dans n'importe quel navigateur. Il est autonome (SVG inline, bascule de thème, menu d'export) et n'a aucune dépendance à l'exécution. Validez-en un avec `node bin/archify.mjs check out.html`. |
| **OMC HUD** | Lecture en direct du contexte, du quota et du mode | Installé comme statusline par `install.sh` ; `/oh-my-claudecode:hud` le reconfigure | La statusline de Claude Code en bas de la session. Complète codeburn : le HUD, c'est cette session ; codeburn, c'est toutes les sessions. |

---

## Sources open source en amont

my-claude relie 5 dépôts upstream sous licence MIT via des sous-modules git, chacun épinglé à un SHA explicite :

| # | Source | Ce qu'elle fournit |
|---|--------|-----------------|
| 1 | <img src="https://github.com/affaan-m.png?size=32" width="20" height="20" align="center"/> **[everything-claude-code](https://github.com/affaan-m/everything-claude-code)** — affaan-m | 79 skills installés + 9 jeux de règles. Voie connaissance langages et stack : TDD, sécurité, standards de codage, patterns de frameworks. |
| 2 | <img src="https://github.com/Yeachan-Heo.png?size=32" width="20" height="20" align="center"/> **[oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode)** — Yeachan Heo | 19 agents spécialistes + 16 skills installés. Voie orchestration : autopilot, ralph, team. |
| 3 | <img src="https://github.com/garrytan.png?size=32" width="20" height="20" align="center"/> **[gstack](https://github.com/garrytan/gstack)** — garrytan | 27 skills installés pour la livraison, la QA, le déploiement et la revue de sécurité (voie Boss P0). Inclut un daemon navigateur Playwright. |
| 4 | <img src="https://github.com/obra.png?size=32" width="20" height="20" align="center"/> **[superpowers](https://github.com/obra/superpowers)** — Jesse Vincent | 13 skills installés pour la voie processus de dev : brainstorming, TDD, débogage systématique, rédaction de plans. |
| 5 | <img src="https://github.com/tt-a1i.png?size=32" width="20" height="20" align="center"/> **[archify](https://github.com/tt-a1i/archify)** — tt-a1i | 1 skill installé, épinglé au tag `v2.9.0`. Diagrammes d'architecture, de workflow, de séquence, de flux de données et de cycle de vie en HTML autonome. |

Pas des sous-modules, mais partie intégrante de la stack :

| Source | Mode d'intégration |
|--------|--------------------|
| <img src="https://github.com/code-yeongyu.png?size=32" width="20" height="20" align="center"/> **[oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent)** — code-yeongyu | 9 agents OMO (Sisyphus, Atlas, Oracle, etc.), portés dans ce dépôt en agents `.md` autonomes sous `agents/omo/`. |
| <img src="https://github.com/msitarzewski.png?size=32" width="20" height="20" align="center"/> **[agency-agents](https://github.com/msitarzewski/agency-agents)** — msitarzewski | Sous-module supprimé le 2026-07-27. 3 agents d'ingénierie vendorisés dans `agents/vendored/` avec attribution. |
| <img src="https://www.anthropic.com/favicon.ico" width="20" height="20" align="center"/> **[anthropic/skills](https://github.com/anthropics/skills)** — Anthropic | Installés par `install.sh` via `claude plugin add anthropics/skills` (pdf, docx, etc.). Non suivis par le manifeste. |
| <img src="https://github.com/forrestchang.png?size=32" width="20" height="20" align="center"/> **[andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills)** — forrestchang | 4 principes de comportement de codage IA ajoutés à `~/.claude/CLAUDE.md`. |

CLIs compagnons et serveurs MCP apportés par `install.sh`, chacun épinglé à une version exacte :

| Source | Mode d'intégration |
|--------|--------------------|
| <img src="https://github.com/oraios.png?size=32" width="20" height="20" align="center"/> **[serena](https://github.com/oraios/serena)** — oraios | `uv tool install -p 3.13 serena-agent==1.7.0`, enregistré comme serveur MCP stdio `serena`. Navigation et édition de code au niveau des symboles. Le paquet `serena-agent` distribué est sous GPL-3.0-or-later dans son ensemble (SolidLSP MIT combiné à une application GPL-3.0-or-later) ; le classifieur MIT de PyPI est erroné. Utilisé comme serveur externe, jamais vendorisé. |
| <img src="https://github.com/headroomlabs-ai.png?size=32" width="20" height="20" align="center"/> **[headroom](https://github.com/headroomlabs-ai/headroom)** — Headroom Labs | `uv tool install --python 3.13 "headroom-ai[all]==0.37.0"`, enregistré comme serveur MCP stdio `headroom` (`headroom mcp serve`). Compression des sorties d'outils. Apache-2.0. Le mode proxy/wrap n'est volontairement pas utilisé. |
| <img src="https://github.com/getagentseal.png?size=32" width="20" height="20" align="center"/> **[codeburn](https://github.com/getagentseal/codeburn)** — getagentseal | CLI npm (MIT). Suivi local-first des tokens et des coûts — lit en lecture seule les fichiers de session que Claude Code écrit déjà et ventile les dépenses par modèle, projet et tâche. Pas de proxy, pas de clé API, rien ne quitte la machine. Installé par `install.sh` épinglé en `codeburn@0.9.23` et enregistré dans `upstream/SOURCES.json` en `method: npm-cli`. Les hooks de garde budgétaire sont opt-in via `--with-codeburn-guard`. Les montants en dollars sont des estimations — nombre de tokens au tarif API public ; codeburn est gratuit et ne facture rien (sur abonnement, c'est un indicateur d'usage). Le hard cap du garde ($15/session par défaut) bloque tous les appels d'outils de la session, y compris `codeburn guard allow` qui le lève (à lancer depuis un terminal externe), d'où son maintien en opt-in. Complète le HUD OMC (contexte et quota de la session courante) en montrant où va l'argent entre les sessions. |
| <img src="https://github.com/ast-grep.png?size=32" width="20" height="20" align="center"/> **[ast-grep](https://github.com/ast-grep/ast-grep)** — ast-grep | `npm i -g @ast-grep/cli@0.42.0`. Recherche et réécriture de code structurelles (compréhension de l'AST). |
| <img src="https://github.com/upstash.png?size=32" width="20" height="20" align="center"/> **[context7](https://github.com/upstash/context7)** — Upstash | Serveur MCP hébergé sur `https://mcp.context7.com/mcp`. Documentation de bibliothèques à jour. |
| <img src="https://github.com/exa-labs.png?size=32" width="20" height="20" align="center"/> **[exa](https://github.com/exa-labs/exa-mcp-server)** — Exa Labs | Serveur MCP hébergé sur `https://mcp.exa.ai/mcp`. Recherche web neuronale. |
| <img src="https://github.com/grep-app.png?size=32" width="20" height="20" align="center"/> **[grep.app](https://grep.app/)** — grep.app | Serveur MCP hébergé sur `https://mcp.grep.app`. Recherche de code dans les dépôts GitHub publics. |

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
| **Listes d'autorisation curées** | `scripts/skill-allowlists.sh` fait autorité — sur des milliers d'entrées upstream, 105 skills et 9 jeux de règles survivent ; rien de non listé n'atteint le contexte de session |
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
