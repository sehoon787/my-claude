[English](../../README.md) | [한국어](./README.ko.md) | [日本語](./README.ja.md) | [中文](./README.zh.md) | [Deutsch](./README.de.md) | [Français](./README.fr.md)

> [![Codex CLI](https://img.shields.io/badge/Codex_CLI-my--codex-10b981?style=flat-square&logo=openai&logoColor=white)](https://github.com/sehoon787/my-codex) Codex CLI をお探しの方は → **my-codex** — 同じオーケストレーションをネイティブ TOML フォーマットで提供

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

**Claude Code 向けオールインワン・エージェントハーネス。**
**プラグイン一つで、厳選された 32 のエージェントがすぐに使えます。**

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

### 優先ルーティング

Boss はすべてのリクエストを優先チェーンにカスケードし、最適なマッチを見つけます:

| 優先度 | マッチタイプ | 条件 | 例 |
|:--------:|-----------|------|---------|
| **P0** | gstack スキル | リリース / QA / デプロイ / セキュリティのワークフロー | `"ship this"` → gstack `/ship` |
| **P1** | スキルマッチ | タスクが自己完結型スキルに対応する場合 | `"merge PDFs"` → pdf スキル |
| **P2** | スペシャリストエージェント | ドメイン固有のエージェントが存在する場合 | `"security audit"` → security-reviewer |
| **P3a** | Boss ダイレクト | 2〜4 個の独立エージェント | `"fix 3 bugs"` → 並列スポーン |
| **P3b** | サブオーケストレーター | 複雑なマルチステップワークフロー | `"refactor + test"` → Sisyphus |
| **P3c** | エージェントチーム | ピアツーピア通信が必要な場合 | `"implement + review"` → Review Chain |
| **P4** | フォールバック | スペシャリストが一致しない場合 | `"explain this"` → 汎用エージェント |

### モデルルーティング

| 複雑度 | モデル | 使用場面 |
|-----------|-------|----------|
| トップレベルのオーケストレーション | `claude-fable-5` | Boss |
| 深い分析、アーキテクチャ | `claude-opus-5` | Sisyphus、Atlas、Hephaestus、Oracle、Metis、Momus、Prometheus |
| 標準的な実装 | `claude-sonnet-5` | Librarian、Multimodal-Looker、OMC スペシャリスト |
| 簡単な検索、調査 | `claude-haiku-4-5` | 軽量な OMC エージェント、簡易アドバイザリー |

### Effort ティア

モデルは*どの頭脳*がタスクを担当するかを決め、`effort:` フロントマターフィールドは*どこまで深く*考えるかを決めます。自前で管理するエージェントはすべてこの値を宣言しています。

| Effort | エージェント |
|--------|--------|
| `xhigh` | Boss、Oracle、Prometheus、Multi-Agent Systems Architect |
| `high` | Sisyphus、Hephaestus、Atlas、Metis、Momus |
| `medium` | Librarian、Multimodal-Looker、AI Engineer、DevOps Automator |

スキルも effort を宣言できます — `boss-briefing` は `medium`、`briefing-vault` は `low` です。`boss-advanced` と `gstack-sprint` は意図的に宣言していません。スキルの effort は呼び出し中セッションレベルを上書きするため、宣言するとタスクの途中で Boss の effort が静かに下がってしまいます。

優先順位は `CLAUDE_CODE_EFFORT_LEVEL`（環境変数）> フロントマター > セッションの effort レベルです。`xhigh` は Fable がサポートする上限で、`max` は opus クラス専用のため、それ以外のモデルでは静かにフォールバックします。

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

### 名前付きワークフロー

決定論的に動くマルチエージェントワークフローです。`install.sh` が `~/.claude/workflows/` にコピーするため、このリポジトリに限らずどのプロジェクトからでも Workflow ツールで呼び出せます。

| ワークフロー | 動作 | 呼び出し |
|--------------|------|----------|
| **code-review-fanout** | 4 つの観点のレビュアー（正確性、セキュリティ、パフォーマンス、テスト）が並列に展開し、すべての指摘は報告前に敵対的に検証されます | `Workflow({name: "code-review-fanout"})` — 引数: レビュー対象（ブランチ、コミット範囲、パス）。既定は作業ツリーの diff |
| **upstream-audit** | アップストリームごとのアナリスト（ピンとの差分、許可リストの適合性、新たな重複、セキュリティシグナル、健全性）と、統合されたアクションリスト | `Workflow({name: "upstream-audit"})` — 四半期ごと、または同期前の監査用 |

---

## アーキテクチャ

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
├─────────────────────────────────────────────────────┤
│  Tooling Layer                                        │
│  LSP (2) · Named Workflows (2)                        │
└─────────────────────────────────────────────────────┘
```

---

## 含まれるもの

| カテゴリ | 数 | ソース |
|----------|------:|--------|
| **エージェント**（常時ロード） | 32 | Boss 1 + OMO 9 + OMC 19 + Vendored 3 |
| **スキル** | 139 | ECC 79 · gstack 27 · OMC 16 · Superpowers 13 · Core 4 |
| **ルール** | 54 ファイル / 9 ルールセット | ECC 53（common + 8 言語ディレクトリ）+ Core 1 |
| **MCP サーバー** | 3 | Context7、Exa、grep.app |
| **フック** | 8 ファイル / 8 イベント | 委任ガード、テレメトリー、検証、ナレッジ Vault |
| **LSP サーバー** | 2 | typescript（`typescript-language-server`）、python（`pyright-langserver`） |
| **名前付きワークフロー** | 2 | code-review-fanout、upstream-audit |
| **アップストリームサブモジュール** | 4 | ecc、omc、gstack、superpowers |
| **CLI ツール** | 3 | omc、omo、ast-grep |

上記のエージェント・スキル・ルールはすべて [`scripts/skill-allowlists.sh`](../../scripts/skill-allowlists.sh) の許可リストに登録され、インストールマニフェストで追跡されます。Anthropic 公式のドキュメントスキル（pdf、docx など）は `claude plugin add anthropics/skills` で別途インストールされ、意図的にマニフェスト追跡の対象外です。

<details>
<summary><strong>コアエージェント — Boss メタオーケストレーター (1)</strong></summary>

| エージェント | モデル | 役割 | ソース |
|-------|-------|------|--------|
| Boss | Fable | ダイナミックランタイム検出 → ケイパビリティマッチング → 最適ルーティング。コードは書かない。 | my-claude |

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
<summary><strong>Vendored エージェント — AI・インフラのスペシャリスト (3)</strong></summary>

`agency-agents` サブモジュールを削除した 2026-07-27 に [agency-agents](https://github.com/msitarzewski/agency-agents)（MIT）からスナップショットしました。スタック内に代替のないエンジニアリングエージェントのみを残し、各ファイルに上流の帰属表示があります。

| エージェント | 役割 | 出典 |
|-------|------|--------|
| AI Engineer | AI/ML エンジニアリング、モデル統合、データパイプライン | agency-agents (vendored) |
| DevOps Automator | インフラ自動化、CI/CD、クラウド運用 | agency-agents (vendored) |
| Multi-Agent Systems Architect | エージェントトポロジー、コンテキスト管理、障害復旧 | agency-agents (vendored) |

</details>

<details>
<summary><strong>スキル — 5 つのソースから 139</strong></summary>

各ソースは [`scripts/skill-allowlists.sh`](../../scripts/skill-allowlists.sh) の許可リストで管理され、リストにないスキルはインストールされません。

| ソース | 数 | 主要スキル |
|--------|------:|------------|
| [everything-claude-code](https://github.com/affaan-m/everything-claude-code) | 79 | coding-standards、react-patterns、fastapi-patterns、agent-architecture-audit、e2e-testing |
| [gstack](https://github.com/garrytan/gstack) | 27 | /qa、/review、/ship、/cso、/investigate、/office-hours |
| [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) | 16 | autopilot、ralph、team、ultrawork、ralplan、omc-reference |
| [superpowers](https://github.com/obra/superpowers) | 13 | brainstorming、systematic-debugging、test-driven-development、writing-plans |
| [my-claude Core](https://github.com/sehoon787/my-claude) | 4 | boss-advanced、boss-briefing、briefing-vault、gstack-sprint |

</details>

<details>
<summary><strong>MCP サーバー (3) + フック (8)</strong></summary>

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

<details>
<summary><strong>LSP サーバー (2)</strong></summary>

プラグインは `.lsp.json` で 2 つの言語サーバーを宣言します。Claude Code が必要に応じて起動するため、エージェントはビルドを一巡させることなく診断とコードナビゲーションをすぐに利用できます。

| サーバー | コマンド | 拡張子 |
|----------|----------|--------|
| typescript | `typescript-language-server --stdio` | `.ts` `.tsx` `.js` `.jsx` `.mjs` `.cjs` |
| python | `pyright-langserver --stdio` | `.py` |

`install.sh` は両方のバイナリを非致命的にインストールします — どちらかが利用できなくても、そのサーバーだけが無効になり、残りのインストールは続行されます。

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
├── persona/
│   ├── profile.md                   ← Agent affinity stats (auto-updated)
│   ├── suggestions.jsonl            ← Routing suggestions (auto-generated)
│   ├── rules/                       ← Accepted routing preferences
│   └── skills/                      ← Accepted persona skills
├── archives/                        ← 完了/非アクティブノート (30日以上)
│   ├── sessions/
│   ├── decisions/
│   └── learnings/
└── wiki/                            ← コンセプトページ (自動提案)
    └── _schema.md
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
| `archives/` | **完了・非アクティブなノート。** 30 日以上経過したノートはアーカイブ候補。PARA の Archives に対応。フラット構造で、frontmatter の `type:` フィールドで元のカテゴリを識別。 |
| `wiki/` | **コンセプト Wiki ページ。** 3 回以上繰り返し登場したキーワードは自動提案。LLM-wiki コンセプトを採用。`_schema.md` でフォーマットを定義。 |

### ナレッジマネジメント (v2)

BriefingVault v2 は 3 つの知識管理手法を統合しています：

| 手法 | コンセプト | BriefingVault での適用 |
|------|-----------|----------------------|
| **PARA** (Tiago Forte) | 実行可能性による分類：Projects、Areas、Resources、Archives | sessions/ = Projects、decisions/ = Areas、references/ = Resources、archives/ = Archives |
| **Zettelkasten** (Luhmann) | 一意の ID と明示的なリンクを持つアトミックノート | learnings/ ファイル：`YYYYMMDDHHMMSS` ID、`related:` リンクは 2 つ以上必須 |
| **LLM-wiki** (Karpathy) | ソースノートから AI が管理するコンセプトページ | wiki/ ページ：3 回以上繰り返されたキーワードに自動提案 |

### セッション固有の差分

セッション開始時、現在の git HEAD が `.briefing/.session-start-head` に保存されます。セッション終了時、差分はこの保存されたポイントを基準に計算されます — 以前のセッションから蓄積された未コミットの変更ではなく、現在のセッションの変更のみを表示します。

### Obsidian との使い方

1. Obsidian を開く → **フォルダをボルトとして開く** → `.briefing/` を選択
2. ノートはグラフビューに表示され、`[[wiki-links]]` でリンクされます
3. YAML フロントマター（`date`、`type`、`tags`）で構造化検索が可能
4. 意思決定と学習のタイムラインがセッションを重ねるごとに自動的に構築されます

---

## アップストリームのオープンソースソース

my-claude は 4 つの MIT ライセンスのアップストリームリポジトリを git サブモジュールとしてリンクし、それぞれ明示的な SHA に固定しています:

| # | ソース | 提供内容 |
|---|--------|-----------------|
| 1 | <img src="https://github.com/affaan-m.png?size=32" width="20" height="20" align="center"/> **[everything-claude-code](https://github.com/affaan-m/everything-claude-code)** — affaan-m | インストールされる 79 スキル + 9 ルールセット。言語・スタック知識のレーン: TDD、セキュリティ、コーディング標準、フレームワークパターン。 |
| 2 | <img src="https://github.com/Yeachan-Heo.png?size=32" width="20" height="20" align="center"/> **[oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode)** — Yeachan Heo | 19 のスペシャリストエージェント + インストールされる 16 スキル。オーケストレーションのレーン: autopilot、ralph、team。 |
| 3 | <img src="https://github.com/garrytan.png?size=32" width="20" height="20" align="center"/> **[gstack](https://github.com/garrytan/gstack)** — garrytan | リリース・QA・デプロイ・セキュリティレビュー（Boss P0 レーン）向けにインストールされる 27 スキル。Playwright ブラウザデーモンを含む。 |
| 4 | <img src="https://github.com/obra.png?size=32" width="20" height="20" align="center"/> **[superpowers](https://github.com/obra/superpowers)** — Jesse Vincent | 開発プロセスのレーン向けにインストールされる 13 スキル: ブレインストーミング、TDD、体系的デバッグ、計画作成。 |

サブモジュールではないが、スタックの一部:

| ソース | 取り込み方法 |
|--------|----------------|
| <img src="https://github.com/code-yeongyu.png?size=32" width="20" height="20" align="center"/> **[oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent)** — code-yeongyu | 9 つの OMO エージェント（Sisyphus、Atlas、Oracle など）を、本リポジトリの `agents/omo/` に独立した `.md` エージェントとして移植。 |
| <img src="https://github.com/msitarzewski.png?size=32" width="20" height="20" align="center"/> **[agency-agents](https://github.com/msitarzewski/agency-agents)** — msitarzewski | 2026-07-27 にサブモジュールを削除。エンジニアリングエージェント 3 個を帰属表示付きで `agents/vendored/` に vendored。 |
| <img src="https://www.anthropic.com/favicon.ico" width="20" height="20" align="center"/> **[anthropic/skills](https://github.com/anthropics/skills)** — Anthropic | `install.sh` が `claude plugin add anthropics/skills` でインストール（pdf、docx など）。マニフェスト追跡の対象外。 |
| <img src="https://github.com/forrestchang.png?size=32" width="20" height="20" align="center"/> **[andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills)** — forrestchang | 4 つの AI コーディング行動ガイドラインを `~/.claude/CLAUDE.md` に追記。 |

---

## GitHub Actions

| ワークフロー | トリガー | 目的 |
|----------|---------|---------|
| **CI** | push、PR | JSON 設定、エージェントフロントマター、スキルの存在、アップストリームファイル数を検証 |
| **Smoke** | push、PR | 4 ジョブ — `hooks`（フック実行）、`shell`（インストールスクリプトの形）、`drift`（モデルドリフト）、`routing-refs`（切れたエージェント/スキル参照） |
| **Update Upstream** | 3 日ごと / 手動 | `git submodule update --remote` → `SOURCES.json` の SHA ピン更新 → アップストリーム差分のセキュリティスキャン → スキャンが通った場合のみ自動マージ、そうでなければ人手のレビュー用に PR を残す |
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
| **エージェント層優先度** | core > omo > omc > vendored 重複排除。最も特化したエージェントが優先。 |
| **レーン所有権** | オーケストレーション → OMC、開発プロセス → superpowers、リリース/QA/デプロイ/セキュリティ → gstack（Boss P0）、言語・スタック知識 → ECC、AI・ドメイン → vendored エージェント |
| **厳選された許可リスト** | `scripts/skill-allowlists.sh` が唯一の正 — アップストリームの数千から 139 スキルと 9 ルールセットだけが残り、リストにないものはセッションのコンテキストに入りません |
| **Briefing Vault** | セッション、決定、学習、参照を含む Obsidian 互換の `.briefing/` ディレクトリ |
| **エージェントテレメトリー** | PostToolUse フックがエージェント使用状況を `agent-usage.jsonl` に記録 |
| **スマートパック** | プロジェクトタイプ検出がセッション開始時に関連エージェントパックを推奨 |
| **変更なし時の同期スキップ** | アップストリーム同期はサブモジュール更新と `SOURCES.json` のピンをステージし、その差分が空でない場合のみ PR を作成 |
| **エージェント重複検出** | `tests/validate-sync.sh` が `agents/` と omc・superpowers サブモジュールのエージェントファイル名を比較し、衝突を報告 |

---

## バンドルされたアップストリームバージョン

git サブモジュール経由でリンク。ピン留めされたコミットは `.gitmodules` がネイティブに追跡し、[`upstream/SOURCES.json`](../../upstream/SOURCES.json) に AI-BOM としてミラーされます。`install.sh` は `main` を追わず、以下の SHA をそのままチェックアウトします。

| ソース | SHA | 日付 | 差分 |
|--------|-----|------|------|
| [everything-claude-code](https://github.com/affaan-m/everything-claude-code) | `4092795` | 2026-07-27 | [compare](https://github.com/affaan-m/everything-claude-code/compare/4092795...HEAD) |
| [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) | `590fb98` | 2026-07-27 | [compare](https://github.com/Yeachan-Heo/oh-my-claudecode/compare/590fb98...HEAD) |
| [gstack](https://github.com/garrytan/gstack) | `7c9df1c` | 2026-07-27 | [compare](https://github.com/garrytan/gstack/compare/7c9df1c...HEAD) |
| [superpowers](https://github.com/obra/superpowers) | `3dcbd5c` | 2026-07-27 | [compare](https://github.com/obra/superpowers/compare/3dcbd5c...HEAD) |

---

## コントリビューション

Issues と PR を歓迎します。新しいエージェントを追加する際は、`agents/core/` または `agents/omo/` に `.md` ファイルを追加し、`SETUP.md` を更新してください。

## クレジット

以下の成果物の上に構築されています: [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) (Yeachan Heo)、[oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent) (code-yeongyu)、[everything-claude-code](https://github.com/affaan-m/everything-claude-code) (affaan-m)、[gstack](https://github.com/garrytan/gstack) (garrytan)、[superpowers](https://github.com/obra/superpowers) (Jesse Vincent)、[agency-agents](https://github.com/msitarzewski/agency-agents) (msitarzewski — vendored エージェント 3 個)、[anthropic/skills](https://github.com/anthropics/skills) (Anthropic)、[andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills) (forrestchang)。

## ライセンス

MIT ライセンス。詳細は [LICENSE](./LICENSE) ファイルをご参照ください。
