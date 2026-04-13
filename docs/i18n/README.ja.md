[English](../../README.md) | [한국어](./README.ko.md) | [日本語](./README.ja.md) | [中文](./README.zh.md) | [Deutsch](./README.de.md) | [Français](./README.fr.md)

> [![Codex CLI](https://img.shields.io/badge/Codex_CLI-my--codex-10b981?style=flat-square&logo=openai&logoColor=white)](https://github.com/sehoon787/my-codex) Codex CLI をお探しの方は → **my-codex** — 同じオーケストレーションをネイティブ TOML フォーマットで提供

---

<div align="center">

# my-claude

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Agents](https://img.shields.io/badge/agents-200%2B-blue)
![Skills](https://img.shields.io/badge/skills-200%2B-purple)
![Rules](https://img.shields.io/badge/rules-87-orange)
![MCP Servers](https://img.shields.io/badge/MCP-3-green)
![Hooks](https://img.shields.io/badge/hooks-7-red)

**Claude Code 向けオールインワン・エージェントハーネス。**
**プラグイン一つで、200 以上のエージェントがすぐに使えます。**

Boss はランタイムですべてのエージェント、スキル、MCP ツールを自動検出し、<br>
適切なスペシャリストにタスクをルーティングします。設定ファイルも、ボイラープレートも不要です。

<img src="./assets/owl-claude-social.svg" alt="The Maestro Owl — my-claude" width="700">

</div>

---

## インストール

### 人間向け

```bash
git clone --depth 1 https://github.com/sehoon787/my-claude.git /tmp/my-claude
bash /tmp/my-claude/install.sh
rm -rf /tmp/my-claude
```

または、まず Claude Code プラグインとしてインストールし、次にコンパニオンインストーラーを実行します:

```bash
# Inside a Claude Code session:
/plugin marketplace add sehoon787/my-claude
/plugin install my-claude@my-claude

# Then install companion tools:
git clone --depth 1 https://github.com/sehoon787/my-claude.git /tmp/my-claude
bash /tmp/my-claude/install.sh
rm -rf /tmp/my-claude
```

### AI エージェント向け

```bash
curl -s https://raw.githubusercontent.com/sehoon787/my-claude/main/AI-INSTALL.md
```

出力全文を読んでから、各ステップを順番に実行してください。`WebFetch` ではなく `curl` を使用してください。

---

## Boss の仕組み

Boss は my-claude の中核にあるメタオーケストレーターです。コードを書くことはなく、検出・分類・マッチング・委任・検証を行います。

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

### 優先ルーティング

Boss はすべてのリクエストを優先チェーンにカスケードし、最適なマッチを見つけます:

| 優先度 | マッチタイプ | 条件 | 例 |
|:--------:|-----------|------|---------|
| **P1** | スキルマッチ | タスクが自己完結型スキルに対応する場合 | `"merge PDFs"` → pdf スキル |
| **P2** | スペシャリストエージェント | ドメイン固有のエージェントが存在する場合 | `"security audit"` → Security Engineer |
| **P3a** | Boss ダイレクト | 2〜4 個の独立エージェント | `"fix 3 bugs"` → 並列スポーン |
| **P3b** | サブオーケストレーター | 複雑なマルチステップワークフロー | `"refactor + test"` → Sisyphus |
| **P3c** | エージェントチーム | ピアツーピア通信が必要な場合 | `"implement + review"` → Review Chain |
| **P4** | フォールバック | スペシャリストが一致しない場合 | `"explain this"` → 汎用エージェント |

### モデルルーティング

| 複雑度 | モデル | 使用場面 |
|-----------|-------|----------|
| 深い分析、アーキテクチャ | Opus | Boss、Oracle、Sisyphus |
| 標準的な実装 | Sonnet | executor、debugger、security-reviewer |
| 簡単な検索、調査 | Haiku | explore、簡易アドバイザリー |

### 3 フェーズスプリントワークフロー

エンドツーエンドの機能実装において、Boss は構造化されたスプリントをオーケストレートします:

```
Phase 1: DESIGN         Phase 2: EXECUTE        Phase 3: REVIEW
(interactive)            (autonomous)             (interactive)
─────────────────────   ─────────────────────   ─────────────────────
User decides scope      ralph runs execution    Compare vs design doc
Engineering review      Auto code review        Present comparison table
Confirm "design done"   Architect verification  User: approve / improve
```

---

## アーキテクチャ

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

## 含まれるもの

| カテゴリ | 数 | ソース |
|----------|------:|--------|
| **コアエージェント**（常時ロード） | 56 | Boss 1 + OMO 9 + OMC 19 + Agency Engineering 26 + Superpowers 1 |
| **エージェントパック**（オンデマンド） | 136 | agency-agents の 12 ドメインカテゴリ |
| **スキル** | 200+ | ECC 180+ · OMC 36 · gstack 40 · Superpowers 14 · Core 3 |
| **Anthropic スキル** | 14+ | PDF、DOCX、PPTX、XLSX、MCP ビルダー |
| **ルール** | 87 | ECC common + 14 言語ディレクトリ |
| **MCP サーバー** | 3 | Context7、Exa、grep.app |
| **フック** | 7 | 委任ガード、テレメトリー、検証 |
| **CLI ツール** | 3 | omc、omo、ast-grep |

<details>
<summary><strong>コアエージェント — Boss メタオーケストレーター (1)</strong></summary>

| エージェント | モデル | 役割 | ソース |
|-------|-------|------|--------|
| Boss | Opus | ダイナミックランタイム検出 → ケイパビリティマッチング → 最適ルーティング。コードは書かない。 | my-claude |

</details>

<details>
<summary><strong>OMO エージェント — サブオーケストレーターとスペシャリスト (9)</strong></summary>

| エージェント | モデル | 役割 | ソース |
|-------|-------|------|--------|
| Sisyphus | Opus | インテント分類 → スペシャリスト委任 → 検証 | [oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent) |
| Hephaestus | Opus | 自律的な調査 → 計画 → 実行 → 検証 | oh-my-openagent |
| Atlas | Opus | タスク分解 + 4 ステージ QA 検証 | oh-my-openagent |
| Oracle | Opus | 戦略的技術コンサルティング（読み取り専用） | oh-my-openagent |
| Metis | Opus | インテント分析、曖昧さ検出 | oh-my-openagent |
| Momus | Opus | 計画実現可能性レビュー | oh-my-openagent |
| Prometheus | Opus | インタビューベースの詳細計画立案 | oh-my-openagent |
| Librarian | Sonnet | MCP 経由のオープンソースドキュメント検索 | oh-my-openagent |
| Multimodal-Looker | Sonnet | 画像・スクリーンショット・図の分析 | oh-my-openagent |

</details>

<details>
<summary><strong>OMC エージェント — スペシャリストワーカー (19)</strong></summary>

| エージェント | 役割 | ソース |
|-------|------|--------|
| analyst | 計画前の事前分析 | [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) |
| architect | システム設計とアーキテクチャ | oh-my-claudecode |
| code-reviewer | 集中的なコードレビュー | oh-my-claudecode |
| code-simplifier | コードの簡略化とクリーンアップ | oh-my-claudecode |
| critic | 批判的分析、代替案の提案 | oh-my-claudecode |
| debugger | 集中的なデバッグ | oh-my-claudecode |
| designer | UI/UX デザインガイダンス | oh-my-claudecode |
| document-specialist | ドキュメント作成 | oh-my-claudecode |
| executor | タスク実行 | oh-my-claudecode |
| explore | コードベースの調査 | oh-my-claudecode |
| git-master | Git ワークフロー管理 | oh-my-claudecode |
| planner | 迅速な計画立案 | oh-my-claudecode |
| qa-tester | 品質保証テスト | oh-my-claudecode |
| scientist | リサーチと実験 | oh-my-claudecode |
| security-reviewer | セキュリティレビュー | oh-my-claudecode |
| test-engineer | テスト作成と保守 | oh-my-claudecode |
| tracer | 実行トレースと分析 | oh-my-claudecode |
| verifier | 最終検証 | oh-my-claudecode |
| writer | コンテンツとドキュメント | oh-my-claudecode |

</details>

<details>
<summary><strong>Agency Engineering — 常時ロードのスペシャリスト (26)</strong></summary>

| エージェント | 役割 | ソース |
|-------|------|--------|
| AI Engineer | AI/ML エンジニアリング | [agency-agents](https://github.com/msitarzewski/agency-agents) |
| Backend Architect | バックエンドアーキテクチャ | agency-agents |
| CMS Developer | CMS 開発 | agency-agents |
| Code Reviewer | コードレビュー | agency-agents |
| Data Engineer | データエンジニアリング | agency-agents |
| Database Optimizer | データベース最適化 | agency-agents |
| DevOps Automator | DevOps 自動化 | agency-agents |
| Embedded Firmware Engineer | 組み込みファームウェア | agency-agents |
| Frontend Developer | フロントエンド開発 | agency-agents |
| Git Workflow Master | Git ワークフロー | agency-agents |
| Incident Response Commander | インシデント対応 | agency-agents |
| Mobile App Builder | モバイルアプリ | agency-agents |
| Rapid Prototyper | 迅速なプロトタイピング | agency-agents |
| Security Engineer | セキュリティエンジニアリング | agency-agents |
| Senior Developer | シニア開発 | agency-agents |
| Software Architect | ソフトウェアアーキテクチャ | agency-agents |
| SRE | サイト信頼性 | agency-agents |
| Technical Writer | 技術文書 | agency-agents |
| AI Data Remediation Engineer | 自己修復データパイプライン | agency-agents |
| Autonomous Optimization Architect | API パフォーマンスガバナンス | agency-agents |
| Email Intelligence Engineer | メールデータ抽出 | agency-agents |
| Feishu Integration Developer | Feishu/Lark プラットフォーム | agency-agents |
| Filament Optimization Specialist | Filament PHP 最適化 | agency-agents |
| Solidity Smart Contract Engineer | EVM スマートコントラクト | agency-agents |
| Threat Detection Engineer | SIEM & 脅威ハンティング | agency-agents |
| WeChat Mini Program Developer | WeChat 小程序 | agency-agents |

</details>

<details>
<summary><strong>エージェントパック — オンデマンドドメインスペシャリスト (136)</strong></summary>

`~/.claude/agent-packs/` にインストールされます。シンボリックリンクで有効化:

```bash
ln -s ~/.claude/agent-packs/marketing/*.md ~/.claude/agents/
```

| パック | 数 | 例 | ソース |
|------|------:|---------|--------|
| marketing | 29 | Douyin、Xiaohongshu、TikTok、SEO | [agency-agents](https://github.com/msitarzewski/agency-agents) |
| specialized | 28 | 法律、金融、医療、MCP ビルダー | agency-agents |
| game-development | 20 | Unity、Unreal、Godot、Roblox | agency-agents |
| design | 8 | ブランド、UI、UX、ビジュアルストーリーテリング | agency-agents |
| testing | 8 | API、アクセシビリティ、パフォーマンス | agency-agents |
| sales | 8 | ディール戦略、パイプライン分析 | agency-agents |
| paid-media | 7 | Google Ads、Meta Ads、プログラマティック | agency-agents |
| project-management | 6 | Scrum、Kanban、リスク管理 | agency-agents |
| spatial-computing | 6 | visionOS、WebXR、Metal | agency-agents |
| support | 6 | アナリティクス、インフラ、法律 | agency-agents |
| academic | 5 | 人類学者、歴史家、心理学者 | agency-agents |
| product | 5 | プロダクトマネージャー、スプリント、フィードバック | agency-agents |

</details>

<details>
<summary><strong>スキル — 6 つのソースから 200 以上</strong></summary>

| ソース | 数 | 主要スキル |
|--------|------:|------------|
| [everything-claude-code](https://github.com/affaan-m/everything-claude-code) | 180+ | tdd-workflow、autopilot、ralph、security-review、coding-standards |
| [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) | 36 | plan、team、trace、deep-dive、blueprint、ultrawork |
| [gstack](https://github.com/garrytan/gstack) | 40 | /qa、/review、/ship、/cso、/investigate、/office-hours |
| [superpowers](https://github.com/obra/superpowers) | 14 | brainstorming、systematic-debugging、TDD、parallel-agents |
| [my-claude Core](https://github.com/sehoon787/my-claude) | 3 | boss-advanced、gstack-sprint、briefing-vault |
| [Anthropic Official](https://github.com/anthropics/skills) | 14+ | pdf、docx、pptx、xlsx、canvas-design、mcp-builder |

</details>

<details>
<summary><strong>MCP サーバー (3) + フック (7)</strong></summary>

**MCP サーバー**

| サーバー | 目的 | コスト |
|--------|---------|------|
| <img src="https://context7.com/favicon.ico" width="16" height="16" align="center"/> [Context7](https://mcp.context7.com) | リアルタイムライブラリドキュメント | 無料 |
| <img src="https://exa.ai/images/favicon-32x32.png" width="16" height="16" align="center"/> [Exa](https://mcp.exa.ai) | セマンティックウェブ検索 | 月 1,000 リクエスト無料 |
| <img src="https://www.google.com/s2/favicons?domain=grep.app&sz=32" width="16" height="16" align="center"/> [grep.app](https://mcp.grep.app) | GitHub コード検索 | 無料 |

**行動フック**

| フック | イベント | 動作 |
|------|-------|----------|
| Session Setup | SessionStart | 不足ツールの自動検出 + Briefing Vault コンテキストの注入 |
| Delegation Guard | PreToolUse | Boss がファイルを直接変更するのをブロック |
| Agent Telemetry | PostToolUse | エージェント使用状況を `agent-usage.jsonl` に記録 |
| Subagent Verifier | SubagentStop | 独立した検証を強制 + Briefing Vault に記録 |
| Completion Check | Stop | タスク検証の確認 + セッションサマリーのプロンプト |
| Teammate Idle Guide | TeammateIdle | アイドル状態のチームメートについてリーダーにプロンプト |
| Task Quality Gate | TaskCompleted | 成果物の品質を検証 |

</details>

---

## <img src="https://obsidian.md/images/obsidian-logo-gradient.svg" width="24" height="24" align="center"/> Briefing Vault

Obsidian 互換の永続メモリ。各プロジェクトはセッション間で自動入力される `.briefing/` ディレクトリを維持します。

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
└── persona/
    ├── profile.md                   ← Agent affinity stats (auto-updated)
    ├── suggestions.jsonl            ← Routing suggestions (auto-generated)
    ├── rules/                       ← Accepted routing preferences
    └── skills/                      ← Accepted persona skills
```

### サブ Vault

| パス | 説明 |
|------|------|
| `INDEX.md` | プロジェクト概要と最近の意思決定・学習へのリンク。初回セッションで自動作成、定期的に更新。 |
| `sessions/` | **セッションサマリー。** `*-auto.md` — git diff 統計とエージェント数のスキャフォールド。`<topic>.md` — フックで強制される AI 記述サマリー。 |
| `decisions/` | **アーキテクチャと設計の意思決定**記録と根拠。AI 記述、作業中に強制。 |
| `learnings/` | **パターン、注意事項、非自明な解決策。** `*-auto-session.md` — ファイルリストのスキャフォールド。`<topic>.md` — AI 記述。 |
| `references/` | **ウェブ調査 URL。** `auto-links.md` — WebSearch/WebFetch 呼び出し時に自動収集。 |
| `agents/` | **エージェントテレメトリー。** `agent-log.jsonl` — 呼び出しごとのログ。`YYYY-MM-DD-summary.md` — 日次使用状況。 |
| `persona/` | **ユーザー作業スタイルプロファイル。** `profile.md` — ツール親和性統計。`suggestions.jsonl` — ルーティング提案。`rules/`、`skills/` — 承認済みの設定。 |

### セッション固有の差分

セッション開始時、現在の git HEAD が `.briefing/.session-start-head` に保存されます。セッション終了時、差分はこの保存されたポイントを基準に計算されます — 以前のセッションから蓄積された未コミットの変更ではなく、現在のセッションの変更のみを表示します。

### Obsidian との使い方

1. Obsidian を開く → **フォルダをボルトとして開く** → `.briefing/` を選択
2. ノートはグラフビューに表示され、`[[wiki-links]]` でリンクされます
3. YAML フロントマター（`date`、`type`、`tags`）で構造化検索が可能
4. 意思決定と学習のタイムラインがセッションを重ねるごとに自動的に構築されます

---

## アップストリームのオープンソースソース

my-claude は git サブモジュール経由で 5 つの MIT ライセンスのアップストリームリポジトリのコンテンツをバンドルしています:

| # | ソース | 提供内容 |
|---|--------|-----------------|
| 1 | <img src="https://github.com/Yeachan-Heo.png?size=32" width="20" height="20" align="center"/> **[oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode)** — Yeachan Heo | 19 のスペシャリストエージェント + 36 スキル。autopilot、ralph、チームオーケストレーションを備えた Claude Code マルチエージェントハーネス。 |
| 2 | <img src="https://github.com/code-yeongyu.png?size=32" width="20" height="20" align="center"/> **[oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent)** — code-yeongyu | 9 つの OMO エージェント（Sisyphus、Atlas、Oracle など）。Claude、GPT、Gemini をブリッジするマルチプラットフォームエージェントハーネス。 |
| 3 | <img src="https://github.com/affaan-m.png?size=32" width="20" height="20" align="center"/> **[everything-claude-code](https://github.com/affaan-m/everything-claude-code)** — affaan-m | 14 言語にわたる 180 以上のスキル + 87 ルール。TDD、セキュリティ、コーディング標準を備えた包括的な開発フレームワーク。 |
| 4 | <img src="https://github.com/msitarzewski.png?size=32" width="20" height="20" align="center"/> **[agency-agents](https://github.com/msitarzewski/agency-agents)** — msitarzewski | 26 のエンジニアリングエージェント（常時ロード） + 12 カテゴリにわたる 136 のドメインエージェントパック。 |
| 5 | <img src="https://github.com/garrytan.png?size=32" width="20" height="20" align="center"/> **[gstack](https://github.com/garrytan/gstack)** — garrytan | コードレビュー、QA、セキュリティ監査、デプロイメント向けの 40 スキル。Playwright ブラウザデーモンを含む。 |
| 6 | <img src="https://github.com/obra.png?size=32" width="20" height="20" align="center"/> **[superpowers](https://github.com/obra/superpowers)** — Jesse Vincent | ブレインストーミング、TDD、並列エージェント、コードレビューをカバーする 14 スキル + 1 エージェント。 |
| 7 | <img src="https://www.anthropic.com/favicon.ico" width="20" height="20" align="center"/> **[anthropic/skills](https://github.com/anthropics/skills)** — Anthropic | PDF、DOCX、PPTX、XLSX、MCP ビルダー向けの 14 以上の公式スキル。 |
| 8 | <img src="https://github.com/forrestchang.png?size=32" width="20" height="20" align="center"/> **[andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills)** — forrestchang | 4 つの AI コーディング行動ガイドライン（コーディング前に考える、シンプルさ優先、外科的変更、目標駆動実行）。 |

---

## GitHub Actions

| ワークフロー | トリガー | 目的 |
|----------|---------|---------|
| **CI** | push、PR | JSON 設定、エージェントフロントマター、スキルの存在、アップストリームファイル数を検証 |
| **Update Upstream** | 週次 / 手動 | `git submodule update --remote` を実行し、自動マージ PR を作成 |
| **Auto Tag** | main へのプッシュ | `plugin.json` のバージョンを読み取り、新しい場合は git タグを作成 |
| **Pages** | main へのプッシュ | `docs/index.html` を GitHub Pages にデプロイ |
| **CLA** | PR | コントリビューターライセンス契約チェック |
| **Lint Workflows** | push、PR | GitHub Actions ワークフロー YAML 構文を検証 |

---

## my-claude オリジナル

アップストリームソースが提供するものを超えて、このプロジェクト専用に構築された機能:

| 機能 | 説明 |
|---------|-------------|
| **Boss メタオーケストレーター** | ダイナミックケイパビリティ検出 → インテント分類 → 5 優先ルーティング → 委任 → 検証 |
| **3 フェーズスプリント** | 設計（インタラクティブ）→ 実行（ralph による自律）→ レビュー（設計書との比較インタラクティブ） |
| **エージェント層優先度** | core > omo > omc > agency 重複排除。最も特化したエージェントが優先。 |
| **Agency コスト最適化** | アドバイザリーには Haiku、実装には Sonnet — 172 のドメインエージェントへの自動モデルルーティング |
| **Briefing Vault** | セッション、決定、学習、参照を含む Obsidian 互換の `.briefing/` ディレクトリ |
| **エージェントテレメトリー** | PostToolUse フックがエージェント使用状況を `agent-usage.jsonl` に記録 |
| **スマートパック** | プロジェクトタイプ検出がセッション開始時に関連エージェントパックを推奨 |
| **CI SHA 事前チェック** | `git ls-remote` SHA 比較により変更のないソースのアップストリーム同期をスキップ |
| **エージェント重複検出** | 正規化された名前比較でアップストリームソース間の重複を検出 |

---

## バンドルされたアップストリームバージョン

git サブモジュール経由でリンク。ピン留めされたコミットは `.gitmodules` でネイティブに追跡。

| ソース | SHA | 日付 | 差分 |
|--------|-----|------|------|
| [agency-agents](https://github.com/msitarzewski/agency-agents) | `4feb0cd` | 2026-04-07 | [compare](https://github.com/msitarzewski/agency-agents/compare/4feb0cd...HEAD) |
| [everything-claude-code](https://github.com/affaan-m/everything-claude-code) | `7dfdbe0` | 2026-04-07 | [compare](https://github.com/affaan-m/everything-claude-code/compare/7dfdbe0...HEAD) |
| [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) | `2487d38` | 2026-04-07 | [compare](https://github.com/Yeachan-Heo/oh-my-claudecode/compare/2487d38...HEAD) |
| [gstack](https://github.com/garrytan/gstack) | `03973c2` | 2026-04-07 | [compare](https://github.com/garrytan/gstack/compare/03973c2...HEAD) |
| [superpowers](https://github.com/obra/superpowers) | `b7a8f76` | 2026-04-06 | [compare](https://github.com/obra/superpowers/compare/b7a8f76...HEAD) |

---

## コントリビューション

Issues と PR を歓迎します。新しいエージェントを追加する際は、`agents/core/` または `agents/omo/` に `.md` ファイルを追加し、`SETUP.md` を更新してください。

## クレジット

以下の成果物の上に構築されています: [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) (Yeachan Heo)、[oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent) (code-yeongyu)、[everything-claude-code](https://github.com/affaan-m/everything-claude-code) (affaan-m)、[agency-agents](https://github.com/msitarzewski/agency-agents) (msitarzewski)、[gstack](https://github.com/garrytan/gstack) (garrytan)、[superpowers](https://github.com/obra/superpowers) (Jesse Vincent)、[anthropic/skills](https://github.com/anthropics/skills) (Anthropic)、[andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills) (forrestchang)。

## ライセンス

MIT ライセンス。詳細は [LICENSE](./LICENSE) ファイルをご参照ください。
