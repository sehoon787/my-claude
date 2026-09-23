[English](../../README.md) | [한국어](./README.ko.md) | [日本語](./README.ja.md) | [中文](./README.zh.md) | [Deutsch](./README.de.md) | [Français](./README.fr.md)

> [![Codex CLI](https://img.shields.io/badge/Codex_CLI-my--codex-10b981?style=flat-square&logo=openai&logoColor=white)](https://github.com/sehoon787/my-codex) Vous cherchez Codex CLI ? → **my-codex** — la même orchestration au format TOML natif

---

<div align="center">

# my-claude

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Agents](https://img.shields.io/badge/agents-32-blue)
![Skills](https://img.shields.io/badge/skills-107-purple)
![Rules](https://img.shields.io/badge/rules-48-orange)
![MCP Servers](https://img.shields.io/badge/MCP-3-green)
![Hooks](https://img.shields.io/badge/hooks-10-red)
![LSP Servers](https://img.shields.io/badge/LSP-2-008b8b)
![Workflows](https://img.shields.io/badge/workflows-2-blueviolet)

**Harnais d'agents tout-en-un pour Claude Code.**
**Un seul plugin, 32 agents sélectionnés prêts à l'emploi.**

Boss détecte automatiquement chaque agent, skill et outil MCP au démarrage,<br>
puis route votre tâche vers le bon spécialiste. Aucun fichier de configuration. Aucun code superflu.

<img src="../../assets/owl-claude-social.svg" alt="The Maestro Owl — my-claude" width="700">

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

L'installeur met à disposition un tableau de bord codeburn et un proxy Headroom partagés par my-claude et my-codex. Une installation ultérieure réutilise les services sains au lieu de créer des doublons. L'état et les journaux de démarrage se trouvent sous `${XDG_STATE_HOME:-$HOME/.local/state}/agent-harness-services` ; ni `ANTHROPIC_BASE_URL` ni `OPENAI_BASE_URL` ne sont modifiés.

### Pour les agents IA

```bash
curl -s https://raw.githubusercontent.com/sehoon787/my-claude/main/AI-INSTALL.md
```

Lisez la TOTALITÉ de la sortie, puis exécutez chaque étape dans l'ordre. Utilisez `curl`, PAS `WebFetch`.

Avant d'exécuter l'installeur, l'agent demandera quels outils compagnons (Serena, Headroom, codeburn) installer, car le menu de sélection interactif n'apparaît que dans un terminal interactif.

---

<a id="open-source-tools-used"></a>

## Outils open source utilisés

Chaque projet sur lequel cette stack s'appuie est décrit une seule fois : ici.
Cinq upstreams sous licence MIT sont reliés comme sous-modules git épinglés à un SHA explicite ;
le reste arrive sous forme de CLI épinglées à une version, de serveurs MCP hébergés ou de fichiers vendorisés avec attribution.

| # | Projet | Ce que my-claude en retient | Mode d'intégration |
|---|--------|-----------------------------|--------------------|
| 1 | <img src="https://github.com/Yeachan-Heo.png?size=32" width="20" height="20" align="center"/> **[oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode)** (OMC) — Yeachan Heo | 19 agents spécialistes (architect, debugger, code reviewer, security reviewer, …) qui répartissent le travail par rôle, plus 16 skills d'orchestration — autopilot, ralph, team. Des mots-clés magiques comme `autopilot:` déclenchent l'exécution parallèle automatique. | Sous-module `upstream/omc`, épinglé à un SHA (voir **Versions upstream groupées**) ; `install.sh` exécute `npm i -g oh-my-claude-sisyphus@latest` et active le plugin `oh-my-claudecode@omc`. |
| 2 | <img src="https://github.com/code-yeongyu.png?size=32" width="20" height="20" align="center"/> **[oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent)** (omo) — code-yeongyu | Un harnais multi-plateforme qui route par catégorie vers 8 fournisseurs (Claude, GPT, Gemini, …) et fait le pont vers Claude Code via `claude-code-agent-loader` et `claude-code-plugin-loader`. Ses 9 agents (Sisyphus, Atlas, Oracle, …) sont adaptés ici en fichiers `.md` autonomes. | Pas un sous-module : les 9 agents vivent dans `agents/omo/` ; `install.sh` exécute `npm i -g oh-my-opencode@latest` pour la CLI `omo`. |
| 3 | <img src="https://github.com/forrestchang.png?size=32" width="20" height="20" align="center"/> **[andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills)** — forrestchang | Les 4 principes de comportement pour le codage assisté par IA — Think Before Coding, Simplicity First, Surgical Changes, Goal-Driven Execution — toujours actifs. | `install.sh` récupère `CLAUDE.md` au SHA épinglé `aa4467f` via curl, en vérifie la somme de contrôle et l'ajoute à `~/.claude/CLAUDE.md`. Aucun code vendorisé. |
| 4 | <img src="https://github.com/affaan-m.png?size=32" width="20" height="20" align="center"/> **[everything-claude-code](https://github.com/affaan-m/everything-claude-code)** (ECC) — affaan-m | 278 skills + 67 agents + 94 commandes + règles de langages en amont. my-claude installe une sélection de 61 skills (79 avec la voie `web` optionnelle) — patterns de stack, ingénierie IA et agents, outillage de codebase — plus 9 jeux de règles et des commandes comme `/tdd`, `/plan`, `/code-review`, `/build-fix`. | Sous-module `upstream/ecc`, épinglé à un SHA ; `install.sh` tente d'abord `claude plugin add affaan-m/everything-claude-code` et retombe sur le sous-module. |
| 5 | <img src="https://www.anthropic.com/favicon.ico" width="20" height="20" align="center"/> **[anthropic/skills](https://github.com/anthropics/skills)** — Anthropic | Le dépôt de skills d'Anthropic : analyse de PDF, manipulation Word/Excel/PowerPoint, création de serveurs MCP. | `claude plugin add anthropics/skills`, exécuté par `install.sh`. Volontairement exclu du manifeste. |
| 6 | <img src="https://github.com/garrytan.png?size=32" width="20" height="20" align="center"/> **[gstack](https://github.com/garrytan/gstack)** — garrytan | Le harnais de processus sprint de Garry Tan : 26 skills plus le routeur racine `gstack` (27 au total) — QA navigateur (`/qa`), revue de code sur la dérive de périmètre (`/review`), audit de sécurité (`/cso`) et tout le flux Plan→Review→QA→Ship (voie Boss P0). Fournit un daemon navigateur Playwright compilé pour des tests en navigateur réel. | Sous-module `upstream/gstack`, épinglé à un SHA. |
| 7 | <img src="https://github.com/obra.png?size=32" width="20" height="20" align="center"/> **[superpowers](https://github.com/obra/superpowers)** — Jesse Vincent | La bibliothèque de processus de développement de Jesse Vincent : 14 de ses 15 skills — brainstorming, débogage systématique, TDD, rédaction et exécution de plans, étiquette de revue de code. `dispatching-parallel-agents` est exclu car Boss et les Agent Teams couvrent déjà ce chemin. | Sous-module `upstream/superpowers`, épinglé à un SHA. |
| 8 | <img src="https://github.com/getagentseal.png?size=32" width="20" height="20" align="center"/> **[codeburn](https://github.com/getagentseal/codeburn)** — getagentseal | Suivi local des tokens et des coûts à partir des fichiers de session que Claude Code et Codex écrivent déjà — pas de proxy, pas de clé API, rien ne quitte la machine. Les hooks de garde budgétaire restent optionnels via `bash install.sh --with-codeburn-guard`, car leur plafond strict ($15/session par défaut) bloque tout appel d'outil de la session, y compris `codeburn guard allow` (à lancer depuis un terminal externe). | `npm i -g codeburn@0.9.23` ; `install.sh` démarre ou réutilise aussi un tableau de bord partagé entre harnais — voir **Où voir les résultats**. MIT. |
| 9 | <img src="https://github.com/oraios.png?size=32" width="20" height="20" align="center"/> **[serena](https://github.com/oraios/serena)** — oraios | Le graphe de symboles d'un serveur de langage via MCP : `find_symbol`, `get_symbols_overview`, `find_referencing_symbols`, `replace_symbol_body`, `insert_after_symbol` — les tokens dépensés varient avec le symbole, pas avec le fichier. | `uv tool install -p 3.13 serena-agent==1.7.0`, enregistré comme serveur MCP stdio au périmètre utilisateur (`serena start-mcp-server --context claude-code --project-from-cwd`). Le paquet distribué est dans son ensemble sous GPL-3.0-or-later (le classifieur MIT de PyPI est inexact) ; il est utilisé comme serveur externe, jamais vendorisé. |
| 10 | <img src="https://github.com/headroomlabs-ai.png?size=32" width="20" height="20" align="center"/> **[headroom](https://github.com/headroomlabs-ai/headroom)** — Headroom Labs | Compression des sorties d'outils : `headroom mcp serve` expose `headroom_compress`, `headroom_retrieve` et `headroom_stats`, pour qu'un résultat d'outil surdimensionné n'atterrisse jamais entier dans la transcription. | `uv tool install --python 3.13 "headroom-ai[all]==0.37.0"`, enregistré comme serveur MCP stdio `headroom` ; `install.sh` démarre ou réutilise aussi le profil persistant sans mutation `agent-harness-shared`. Apache-2.0. |
| 11 | <img src="https://github.com/tt-a1i.png?size=32" width="20" height="20" align="center"/> **[archify](https://github.com/tt-a1i/archify)** — tt-a1i | Un skill d'agent qui dessine des diagrammes d'architecture, de workflow, de séquence, de flux de données et de cycle de vie en HTML autonome — SVG inline, bascule de thème clair/sombre, menu d'export PNG/JPEG/WebP/SVG, aucune dépendance à l'exécution dans le fichier généré. Il accepte aussi du Mermaid collé comme dialecte d'entrée. | Sous-module `upstream/archify`, épinglé au tag `v2.9.0` ; `install.sh` copie le répertoire de skill `archify/` en amont vers `~/.claude/skills/archify`, donc aucun `npx skills add` ne s'exécute à l'installation. |
| 12 | <img src="https://github.com/msitarzewski.png?size=32" width="20" height="20" align="center"/> **[agency-agents](https://github.com/msitarzewski/agency-agents)** — msitarzewski | 3 agents d'ingénierie sans équivalent ailleurs dans la stack : AI Engineer, DevOps Automator, Multi-Agent Systems Architect. | Sous-module supprimé le 2026-07-27 ; les 3 agents ont été capturés ce jour-là dans `agents/vendored/`, chaque fichier portant son attribution d'origine. MIT. |
| 13 | <img src="https://github.com/ast-grep.png?size=32" width="20" height="20" align="center"/> **[ast-grep](https://github.com/ast-grep/ast-grep)** — ast-grep | Recherche et réécriture de code structurelles, conscientes de l'AST, pour que les agents ciblent des formes de code plutôt que des regex. | `npm i -g @ast-grep/cli@0.42.0`. MIT. |
| 14 | <img src="https://github.com/upstash.png?size=32" width="20" height="20" align="center"/> **[context7](https://github.com/upstash/context7)** — Upstash | Documentation de bibliothèques à jour et fidèle à la version, pour qu'un agent lise l'API réelle au lieu de la deviner. | Serveur MCP hébergé sur `https://mcp.context7.com/mcp`, enregistré par `install.sh`. |
| 15 | <img src="https://github.com/exa-labs.png?size=32" width="20" height="20" align="center"/> **[exa](https://github.com/exa-labs/exa-mcp-server)** — Exa Labs | Recherche web neuronale (sémantique) pour les recherches que la recherche par mots-clés manque. | Serveur MCP hébergé sur `https://mcp.exa.ai/mcp`, enregistré par `install.sh`. |
| 16 | <img src="https://github.com/grep-app.png?size=32" width="20" height="20" align="center"/> **[grep.app](https://github.com/grep-app)** — grep.app | Recherche de code dans les dépôts GitHub publics, pour voir comment un motif est utilisé en conditions réelles. | Serveur MCP hébergé sur `https://mcp.grep.app`, enregistré par `install.sh`. |


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
| Analyse approfondie, architecture | `claude-opus-5-5` | Sisyphus, Atlas, Hephaestus, Oracle, Metis, Momus, Prometheus |
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
| Fichiers/paramètres modifiés | Changements (Changes) | Cible / Before / After / Justification |
| Plusieurs tâches terminées | Résumé des travaux (Work summary) | Élément / Résultat / Preuve |
| Vérification exécutée | Vérification (Verification) | Élément / Attendu / Réel / Verdict |
| Commits/PR produits | Livrables (Deliverables) | PR / Dépôt / Contenu / Statut |
| Éléments non résolus | Restant (Remaining) | Élément / Statut / Prochaine étape |

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
| **Skills** | 107 | ECC 61 · gstack 27 · Superpowers 14 · Core 4 · Archify 1 |
| **Règles** | 48 fichiers / 9 jeux | ECC 46 (common + 8 répertoires de langages) + Core 2 |
| **Serveurs MCP** | 3 | Context7, Exa, grep.app |
| **Hooks** | 10 fichiers / 6 événements | Garde de délégation, télémétrie, vérification, vault |
| **Serveurs LSP** | 2 | typescript (`typescript-language-server`), python (`pyright-langserver`) |
| **Workflows nommés** | 2 | code-review-fanout, upstream-audit |
| **Sous-modules upstream** | 5 | ecc, omc, gstack, superpowers, archify |
| **Outils CLI** | 7 | omc, omo, ast-grep, comment-checker, codeburn, serena, headroom |

Chaque agent, skill et règle ci-dessus figure dans la liste d'autorisation de [`scripts/skill-allowlists.sh`](../../scripts/skill-allowlists.sh) et est suivi par le manifeste d'installation. Les skills documentaires officiels d'Anthropic (pdf, docx, etc.) sont installés séparément via `claude plugin add anthropics/skills` et volontairement exclus du manifeste.

<details>
<summary><strong>Agents spécialistes — 32 répartis sur 4 niveaux</strong></summary>

Les modèles utilisés par agent sont listés dans le tableau de routage par modèle ci-dessus ; la provenance de chaque source figure dans [Outils open source utilisés](#open-source-tools-used).

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
<summary><strong>Skills — 107 issus de 5 sources</strong></summary>

Chaque source est pilotée par la liste d'autorisation de [`scripts/skill-allowlists.sh`](../../scripts/skill-allowlists.sh) : ce qui n'y figure pas n'est jamais installé.

| Source | Nombre | Skills clés |
|--------|------:|------------|
| [everything-claude-code](https://github.com/affaan-m/everything-claude-code) | 61 | coding-standards, fastapi-patterns, agent-architecture-audit, springboot-patterns, kubernetes-patterns |
| [gstack](https://github.com/garrytan/gstack) | 27 | /qa, /review, /ship, /cso, /investigate, /office-hours |
| [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) | 16 (plugin) | autopilot, ralph, team, ultrawork, ralplan, omc-reference |
| [superpowers](https://github.com/obra/superpowers) | 14 | brainstorming, systematic-debugging, test-driven-development, writing-plans |
| [my-claude Core](https://github.com/sehoon787/my-claude) | 4 | boss-advanced, boss-briefing, briefing-vault, gstack-sprint |
| [archify](https://github.com/tt-a1i/archify) | 1 | archify |

</details>

<details>
<summary><strong>Serveurs MCP (3) + Hooks (10)</strong></summary>

**Serveurs MCP** — ce que chacun fait et comment il est enregistré figure dans [Outils open source utilisés](#open-source-tools-used).

| Serveur | Coût |
|--------|------|
| <img src="https://context7.com/favicon.ico" width="16" height="16" align="center"/> [Context7](https://context7.com) | Gratuit |
| <img src="https://exa.ai/images/favicon-32x32.png" width="16" height="16" align="center"/> [Exa](https://exa.ai) | Gratuit 1k req/mois |
| <img src="https://www.google.com/s2/favicons?domain=grep.app&sz=32" width="16" height="16" align="center"/> [grep.app](https://github.com/grep-app) | Gratuit |

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

Chaque outil de la stack écrit ses résultats quelque part — voici où les trouver. Ce que chaque outil est figure dans [Outils open source utilisés](#open-source-tools-used).

| Outil | Ouvrir | Comment l'exécuter | Où regarder |
|-------|--------|--------------------|-------------|
| **codeburn** | <http://127.0.0.1:4747/> | `install.sh` démarre ou réutilise `codeburn web --provider all --port 4747 --no-open` · `codeburn` ouvre la TUI · `codeburn report --format json --period week` produit un export non interactif | Le tableau de bord partagé ; journal de démarrage : `${XDG_STATE_HOME:-$HOME/.local/state}/agent-harness-services/logs/codeburn.log`. Les fichiers de session sont lus en lecture seule ; les montants sont des estimations aux tarifs API publics. |
| **Serena** | <http://localhost:24282/dashboard/index.html> | Démarre automatiquement comme serveur MCP ; appelez `get_symbols_overview` / `find_symbol` depuis n'importe quelle session | Le tableau de bord, tant qu'un serveur tourne (logs + nombre d'appels par outil). Les mémoires par projet atterrissent dans `.serena/` à l'intérieur du dépôt sur lequel vous travaillez ; la configuration globale est `~/.serena/serena_config.yml`. |
| **Headroom** | <http://127.0.0.1:8787/stats> | Outils MCP `headroom_compress` / `headroom_retrieve` / `headroom_stats` ; `install.sh` démarre ou réutilise le profil proxy partagé `agent-harness-shared` | Les statistiques de compression, vides tant qu'aucun client n'est routé via le proxy ; journal de démarrage : `${XDG_STATE_HOME:-$HOME/.local/state}/agent-harness-services/logs/headroom.log`. |
| **Archify** | `out.html` | Demandez un diagramme et Boss route vers le skill `archify`. Manuellement, depuis `~/.claude/skills/archify` : `node bin/archify.mjs render workflow examples/agent-tool-call.workflow.json out.html` | Le fichier généré — ouvrez-le dans n'importe quel navigateur. Validez-en un avec `node bin/archify.mjs check out.html`. |
| **OMC HUD** | Statusline de Claude Code | Installé comme statusline par `install.sh` ; `/oh-my-claudecode:hud` le reconfigure | En bas de la session, avec la lecture en direct du contexte, du quota et du mode. Complète codeburn : le HUD, c'est cette session ; codeburn, c'est toutes les sessions. |

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
| **Listes d'autorisation curées** | `scripts/skill-allowlists.sh` fait autorité — sur des milliers d'entrées upstream, 107 skills et 9 jeux de règles survivent ; rien de non listé n'atteint le contexte de session |
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
| [everything-claude-code](https://github.com/affaan-m/everything-claude-code) | `bf70150` | 2026-09-22 | [comparer](https://github.com/affaan-m/everything-claude-code/compare/bf70150...HEAD) |
| [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) | `9fd35ec` | 2026-09-22 | [comparer](https://github.com/Yeachan-Heo/oh-my-claudecode/compare/9fd35ec...HEAD) |
| [gstack](https://github.com/garrytan/gstack) | `35dd014` | 2026-09-22 | [comparer](https://github.com/garrytan/gstack/compare/35dd014...HEAD) |
| [superpowers](https://github.com/obra/superpowers) | `5bf4e78` | 2026-09-19 | [comparer](https://github.com/obra/superpowers/compare/5bf4e78...HEAD) |
| [archify](https://github.com/tt-a1i/archify) | `62904f3` (`v2.9.0`) | 2026-09-19 | [comparer](https://github.com/tt-a1i/archify/compare/62904f3...HEAD) |

---

## Contribuer

Les issues et PR sont les bienvenus. Lors de l'ajout d'un nouvel agent, ajoutez un fichier `.md` dans `agents/core/` ou `agents/omo/` et mettez à jour `SETUP.md`.

## Remerciements

Construit sur les projets listés dans [Outils open source utilisés](#open-source-tools-used) ; merci à chaque autrice et auteur.

## Licence

Licence MIT. Voir le fichier [LICENSE](../../LICENSE) pour plus de détails.
