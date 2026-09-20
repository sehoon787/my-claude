[English](../../README.md) | [한국어](./README.ko.md) | [日本語](./README.ja.md) | [中文](./README.zh.md) | [Deutsch](./README.de.md) | [Français](./README.fr.md)

> [![Codex CLI](https://img.shields.io/badge/Codex_CLI-my--codex-10b981?style=flat-square&logo=openai&logoColor=white)](https://github.com/sehoon787/my-codex) Codex CLI をお探しの方は → **my-codex** — 同じオーケストレーションをネイティブ TOML フォーマットで提供

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

| フェーズ | 動作 |
|---------|------|
| **0 · DISCOVERY** | エージェント、スキル、MCP、フックをランタイムでスキャンし、ライブのケイパビリティレジストリを構築します |
| **1 · INTENT GATE** | リクエストを分類し（trivial、build、refactor、mid-sized、architecture、research、…）、より適したスキルがあればそちらを逆提案します |
| **2 · CAPABILITY MATCHING** | 下記の優先チェーンをカスケードします（P0 gstack スキル → P1 スキル完全一致 → P2 スペシャリストエージェント → P3 マルチエージェントオーケストレーション → P4 汎用フォールバック） |
| **3 · DELEGATION** | 6 セクション構成の構造化プロンプトをスペシャリストに送ります: TASK / OUTCOME / TOOLS / DO / DON'T / CTX |
| **4 · VERIFICATION** | 変更されたファイルを独立して読み取り、テスト・lint・ビルドを実行し、元のインテントと突き合わせ、失敗時は最大 3 回まで再試行します |

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
| トップレベルのオーケストレーション | `claude-fable-5-1` | Boss |
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

| フェーズ | モード | 動作 |
|---------|--------|------|
| **1 · DESIGN** | interactive | ユーザーがスコープを決定 · エンジニアリングレビュー · 「design done」を確認 |
| **2 · EXECUTE** | autonomous | ralph が実行を担当 · 自動コードレビュー · architect による検証 |
| **3 · REVIEW** | interactive | 設計書と比較 · 比較テーブルを提示 · ユーザーが承認または改善を要求 |

### 構造化された最終レポート

Boss は作業が発生したすべてのターン — ファイルの編集・作成、コミット/PR/マージ、設定変更、検証の実行があったターン — を、diff を開かなくても読み取れる構造化された最終レポートで締めくくります。レポートは固定された 5 つのテーブルから組み立てられ、各テーブルはその状況が実際に発生した場合にのみ出力されます（空のテーブルは決して出力しません）:

| 状況 | テーブル | 列 |
|-----------|-------|---------|
| ファイル/設定の変更 | 변경 대조 (Changes) | 대상 / Before / After / 근거 |
| 複数タスクの完了 | 작업 요약 (Work summary) | 항목 / 결과 / 근거 |
| 検証を実行 | 검증 결과 (Verification) | 항목 / 기대 / 실제 / 판정 |
| コミット/PR を作成 | 산출물 (Deliverables) | PR / 저장소 / 내용 / 상태 |
| 未解決事項あり | 남은 것 (Remaining) | 항목 / 상태 / 다음 조치 |

このレポートはリクエストの最後にのみ発動し — バックグラウンド作業を起動・中継するターンやタスク途中の進捗報告としては決して出力されず — 純粋な Q&A のターンはレポートなしで通常どおり終了します。仕様は `boss.md § FINAL REPORT` にあり、`stop-final-report.js` Stop フックがこれを強制します。

### 名前付きワークフロー

決定論的に動くマルチエージェントワークフローです。`install.sh` が `~/.claude/workflows/` にコピーするため、このリポジトリに限らずどのプロジェクトからでも Workflow ツールで呼び出せます。

| ワークフロー | 動作 | 呼び出し |
|--------------|------|----------|
| **code-review-fanout** | 4 つの観点のレビュアー（正確性、セキュリティ、パフォーマンス、テスト）が並列に展開し、すべての指摘は報告前に敵対的に検証されます | `Workflow({name: "code-review-fanout"})` — 引数: レビュー対象（ブランチ、コミット範囲、パス）。既定は作業ツリーの diff |
| **upstream-audit** | アップストリームごとのアナリスト（ピンとの差分、許可リストの適合性、新たな重複、セキュリティシグナル、健全性）と、統合されたアクションリスト | `Workflow({name: "upstream-audit"})` — 四半期ごと、または同期前の監査用 |

---

## 含まれるもの

| カテゴリ | 数 | ソース |
|----------|------:|--------|
| **エージェント**（常時ロード） | 32 | Boss 1 + OMO 9 + OMC 19 + Vendored 3 |
| **スキル** | 105 | ECC 61 · gstack 27 · Superpowers 13 · Core 4 |
| **ルール** | 48 ファイル / 9 ルールセット | ECC 46（common + 8 言語ディレクトリ）+ Core 2 |
| **MCP サーバー** | 3 | Context7、Exa、grep.app |
| **フック** | 10 ファイル / 6 イベント | 委任ガード、テレメトリー、検証、ナレッジ Vault |
| **LSP サーバー** | 2 | typescript（`typescript-language-server`）、python（`pyright-langserver`） |
| **名前付きワークフロー** | 2 | code-review-fanout、upstream-audit |
| **アップストリームサブモジュール** | 4 | ecc、omc、gstack、superpowers |
| **CLI ツール** | 7 | omc、omo、ast-grep、comment-checker、codeburn、serena、headroom |

上記のエージェント・スキル・ルールはすべて [`scripts/skill-allowlists.sh`](../../scripts/skill-allowlists.sh) の許可リストに登録され、インストールマニフェストで追跡されます。Anthropic 公式のドキュメントスキル（pdf、docx など）は `claude plugin add anthropics/skills` で別途インストールされ、意図的にマニフェスト追跡の対象外です。

<details>
<summary><strong>スペシャリストエージェント — 4 ティアで 32</strong></summary>

エージェントごとのモデルは上の「モデルルーティング」テーブルに記載されています。

Vendored エージェントは `agency-agents` サブモジュールを削除した 2026-07-27 に [agency-agents](https://github.com/msitarzewski/agency-agents)（MIT）からスナップショットしました。スタック内に代替のないエンジニアリングエージェントのみを残し、各ファイルに上流の帰属表示があります。

| エージェント | ティア | 役割 | ソース |
|-------|------|------|--------|
| Boss | core | ダイナミックランタイム検出 → ケイパビリティマッチング → 最適ルーティング。コードは書かない。 | my-claude |
| Sisyphus | omo | インテント分類 → スペシャリスト委任 → 検証 | [oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent) |
| Hephaestus | omo | 自律的な調査 → 計画 → 実行 → 検証 | oh-my-openagent |
| Atlas | omo | タスク分解 + 4 ステージ QA 検証 | oh-my-openagent |
| Oracle | omo | 戦略的技術コンサルティング（読み取り専用） | oh-my-openagent |
| Metis | omo | インテント分析、曖昧さ検出 | oh-my-openagent |
| Momus | omo | 計画実現可能性レビュー | oh-my-openagent |
| Prometheus | omo | インタビューベースの詳細計画立案 | oh-my-openagent |
| Librarian | omo | MCP 経由のオープンソースドキュメント検索 | oh-my-openagent |
| Multimodal-Looker | omo | 画像・スクリーンショット・図の分析 | oh-my-openagent |
| analyst | omc | 計画前の事前分析 | [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) |
| architect | omc | システム設計とアーキテクチャ | oh-my-claudecode |
| code-reviewer | omc | 集中的なコードレビュー | oh-my-claudecode |
| code-simplifier | omc | コードの簡略化とクリーンアップ | oh-my-claudecode |
| critic | omc | 批判的分析、代替案の提案 | oh-my-claudecode |
| debugger | omc | 集中的なデバッグ | oh-my-claudecode |
| designer | omc | UI/UX デザインガイダンス | oh-my-claudecode |
| document-specialist | omc | ドキュメント作成 | oh-my-claudecode |
| executor | omc | タスク実行 | oh-my-claudecode |
| explore | omc | コードベースの調査 | oh-my-claudecode |
| git-master | omc | Git ワークフロー管理 | oh-my-claudecode |
| planner | omc | 迅速な計画立案 | oh-my-claudecode |
| qa-tester | omc | 品質保証テスト | oh-my-claudecode |
| scientist | omc | リサーチと実験 | oh-my-claudecode |
| security-reviewer | omc | セキュリティレビュー | oh-my-claudecode |
| test-engineer | omc | テスト作成と保守 | oh-my-claudecode |
| tracer | omc | 実行トレースと分析 | oh-my-claudecode |
| verifier | omc | 最終検証 | oh-my-claudecode |
| writer | omc | コンテンツとドキュメント | oh-my-claudecode |
| AI Engineer | vendored | AI/ML エンジニアリング、モデル統合、データパイプライン | agency-agents (vendored) |
| DevOps Automator | vendored | インフラ自動化、CI/CD、クラウド運用 | agency-agents (vendored) |
| Multi-Agent Systems Architect | vendored | エージェントトポロジー、コンテキスト管理、障害復旧 | agency-agents (vendored) |

</details>

<details>
<summary><strong>スキル — 5 つのソースから 105</strong></summary>

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
| Subagent Logger | SubagentStop | エージェントの実行を Briefing Vault に記録 |
| Completion Check | Stop | タスク検証の確認 + セッションサマリーのプロンプト |

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

### サブ Vault

| パス | 説明 |
|------|------|
| `INDEX.md` | プロジェクト概要と最近の意思決定・学習へのリンク。初回セッションで自動作成、定期的に更新。 |
| `sessions/` | **セッションサマリー。** `YYYY-MM-DD-auto.md` — git diff 統計とエージェント数のスキャフォールド。`YYYY-MM-DD-<topic>.md` — フックで強制される AI 記述サマリー。 |
| `decisions/` | **アーキテクチャと設計の意思決定**記録と根拠。`YYYY-MM-DD-<decision>.md` — AI 記述、作業中に強制。 |
| `learnings/` | **パターン、注意事項、非自明な解決策。** `YYYY-MM-DD-auto-session.md` — ファイルリストのスキャフォールド。`YYYY-MM-DD-<pattern>.md` — AI 記述。 |
| `references/` | **ウェブ調査 URL。** `auto-links.md` — WebSearch/WebFetch 呼び出し時に自動収集。 |
| `agents/` | **エージェントテレメトリー。** `agent-log.jsonl` — 呼び出しごとのログ。`YYYY-MM-DD-summary.md` — 日次使用状況。 |
| `persona/` | **ユーザー作業スタイルプロファイル。** `profile.md` — ツール親和性統計。`suggestions.jsonl` — ルーティング提案。`rules/`、`skills/` — 承認済みの設定。 |
| `archives/` | **完了・非アクティブなノート。** 30 日以上経過したノートはアーカイブ候補。PARA の Archives に対応。`sessions/`、`decisions/`、`learnings/` のサブディレクトリに分かれ、frontmatter の `type:` フィールドで元のカテゴリを識別。 |
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

## 結果を確認する場所

スタックが生成した出力を実際に確認できる場所です:

| ツール | 機能 | 実行方法 | 確認場所 |
|------|--------------|-----------|---------------|
| **codeburn** | 過去の全セッションにわたるトークンとコストの集計 | `codeburn`（インタラクティブ TUI）· ブラウザダッシュボードは `codeburn web`（`--no-open` でブラウザを起動せず URL を出力）· 非インタラクティブなダンプは `codeburn report --format json --period week`（`--day`、`--from`/`--to`、`--provider claude` も利用可） | `~/.claude/projects/**/*.jsonl` を読み取り専用で参照します。ブラウザダッシュボードは <http://127.0.0.1:4747>（`codeburn web`。ポートが使用中の場合は空きポートにフォールバック）。ドル金額は**推定値**です: トークン数を API 定価で換算しているため、サブスクリプションプランでは請求額ではなく使用量の目安になります。 |
| **Serena** | シンボル単位のコードナビゲーションと編集 | MCP サーバーとして自動的に起動します。任意のセッションから `get_symbols_overview` / `find_symbol` を呼び出せます | サーバー稼働中はダッシュボードが <http://localhost:24282/dashboard/index.html> で利用できます（ログ + ツールごとの呼び出し回数）。プロジェクトごとのメモリは作業中のリポジトリ内の `.serena/` に保存され、グローバル設定は `~/.serena/serena_config.yml` です。 |
| **Headroom** | 肥大化したツール実行結果を、トランスクリプトに入る前に圧縮します | MCP ツール `headroom_compress` / `headroom_retrieve` / `headroom_stats` · オプションのプロキシ: `headroom proxy --port 8787` を実行してから `ANTHROPIC_BASE_URL=http://127.0.0.1:8787 claude` | `headroom_stats` が稼働中サーバーの圧縮回数を報告します。プロキシをオプトインした場合は <http://127.0.0.1:8787/stats> と `headroom dashboard`。オプトインしていない場合、`headroom doctor` と `headroom perf` は "not reachable" / "no performance data" を報告します — これらはプロキシについての情報なので想定どおりの動作です。 |
| **Archify** | アーキテクチャ、ワークフロー、シーケンス、データフロー、ライフサイクルの図 | 図を依頼すると Boss が `archify` スキルにルーティングします。手動で実行する場合は `~/.claude/skills/archify` から: `node bin/archify.mjs render workflow examples/agent-tool-call.workflow.json out.html` | 生成された `out.html` — 任意のブラウザで開けます。自己完結型（インライン SVG、テーマトグル、エクスポートメニュー）で、ランタイム依存はありません。`node bin/archify.mjs check out.html` で検証できます。 |
| **OMC HUD** | コンテキスト、クォータ、モードのライブ表示 | `install.sh` がステータスラインとしてインストールします。`/oh-my-claudecode:hud` で再設定できます | セッション下部の Claude Code ステータスライン。codeburn を補完します: HUD は現在のセッション、codeburn は全セッションを対象とします。 |

---

## アップストリームのオープンソースソース

my-claude は 5 つの MIT ライセンスのアップストリームリポジトリを git サブモジュールとしてリンクし、それぞれ明示的な SHA に固定しています:

| # | ソース | 提供内容 |
|---|--------|-----------------|
| 1 | <img src="https://github.com/affaan-m.png?size=32" width="20" height="20" align="center"/> **[everything-claude-code](https://github.com/affaan-m/everything-claude-code)** — affaan-m | インストールされる 79 スキル + 9 ルールセット。言語・スタック知識のレーン: TDD、セキュリティ、コーディング標準、フレームワークパターン。 |
| 2 | <img src="https://github.com/Yeachan-Heo.png?size=32" width="20" height="20" align="center"/> **[oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode)** — Yeachan Heo | 19 のスペシャリストエージェント + インストールされる 16 スキル。オーケストレーションのレーン: autopilot、ralph、team。 |
| 3 | <img src="https://github.com/garrytan.png?size=32" width="20" height="20" align="center"/> **[gstack](https://github.com/garrytan/gstack)** — garrytan | リリース・QA・デプロイ・セキュリティレビュー（Boss P0 レーン）向けにインストールされる 27 スキル。Playwright ブラウザデーモンを含む。 |
| 4 | <img src="https://github.com/obra.png?size=32" width="20" height="20" align="center"/> **[superpowers](https://github.com/obra/superpowers)** — Jesse Vincent | 開発プロセスのレーン向けにインストールされる 13 スキル: ブレインストーミング、TDD、体系的デバッグ、計画作成。 |
| 5 | <img src="https://github.com/tt-a1i.png?size=32" width="20" height="20" align="center"/> **[archify](https://github.com/tt-a1i/archify)** — tt-a1i | インストールされる 1 スキル、タグ `v2.9.0` に固定。アーキテクチャ・ワークフロー・シーケンス・データフロー・ライフサイクルの図を自己完結型 HTML として生成。 |

サブモジュールではないが、スタックの一部:

| ソース | 取り込み方法 |
|--------|----------------|
| <img src="https://github.com/code-yeongyu.png?size=32" width="20" height="20" align="center"/> **[oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent)** — code-yeongyu | 9 つの OMO エージェント（Sisyphus、Atlas、Oracle など）を、本リポジトリの `agents/omo/` に独立した `.md` エージェントとして移植。 |
| <img src="https://github.com/msitarzewski.png?size=32" width="20" height="20" align="center"/> **[agency-agents](https://github.com/msitarzewski/agency-agents)** — msitarzewski | 2026-07-27 にサブモジュールを削除。エンジニアリングエージェント 3 個を帰属表示付きで `agents/vendored/` に vendored。 |
| <img src="https://www.anthropic.com/favicon.ico" width="20" height="20" align="center"/> **[anthropic/skills](https://github.com/anthropics/skills)** — Anthropic | `install.sh` が `claude plugin add anthropics/skills` でインストール（pdf、docx など）。マニフェスト追跡の対象外。 |
| <img src="https://github.com/forrestchang.png?size=32" width="20" height="20" align="center"/> **[andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills)** — forrestchang | 4 つの AI コーディング行動ガイドラインを `~/.claude/CLAUDE.md` に追記。 |

`install.sh` が一緒に導入するコンパニオン CLI と MCP サーバー。それぞれ正確なバージョンに固定されています:

| ソース | 取り込み方法 |
|--------|----------------|
| <img src="https://github.com/oraios.png?size=32" width="20" height="20" align="center"/> **[serena](https://github.com/oraios/serena)** — oraios | `uv tool install -p 3.13 serena-agent==1.7.0` でインストールし、`serena` stdio MCP サーバーとして登録。シンボル単位のコードナビゲーションと編集。配布される `serena-agent` パッケージは全体として GPL-3.0-or-later です（MIT の SolidLSP と GPL-3.0-or-later のアプリケーションの結合）。PyPI の MIT classifier は誤りです。外部サーバーとして利用し、vendored はしません。 |
| <img src="https://github.com/headroomlabs-ai.png?size=32" width="20" height="20" align="center"/> **[headroom](https://github.com/headroomlabs-ai/headroom)** — Headroom Labs | `uv tool install --python 3.13 "headroom-ai[all]==0.37.0"` でインストールし、`headroom` stdio MCP サーバー（`headroom mcp serve`）として登録。ツール出力の圧縮。Apache-2.0。プロキシ/wrap モードは意図的に未使用。 |
| <img src="https://github.com/getagentseal.png?size=32" width="20" height="20" align="center"/> **[codeburn](https://github.com/getagentseal/codeburn)** — getagentseal | npm CLI (MIT)。ローカルファーストのトークン/コストトラッカー — Claude Code が既に書き出すセッションファイルを読み取り専用で解析し、モデル・プロジェクト・タスク別にコストを集計します。プロキシ・API キー・アップロード不要。`install.sh` が `codeburn@0.9.23` に固定してインストールし、`upstream/SOURCES.json` に `method: npm-cli` として登録。予算ガードフックは `--with-codeburn-guard` でオプトイン。表示されるドル金額はトークン数を API 定価で換算した推定値で、codeburn 自体は無料で何も課金しません（サブスクリプションでは使用量の目安）。ガードの hard cap（既定 $15/セッション）は解除コマンド `codeburn guard allow` を含むそのセッションの全ツール呼び出しをブロックするため（外部ターミナルから実行）、オプトインのままにしています。OMC HUD（現在のセッションのコンテキストとクォータ）を補完し、セッション横断のコストの行き先を示します。 |
| <img src="https://github.com/ast-grep.png?size=32" width="20" height="20" align="center"/> **[ast-grep](https://github.com/ast-grep/ast-grep)** — ast-grep | `npm i -g @ast-grep/cli@0.42.0`。構造的（AST を理解する）コード検索と書き換え。 |
| <img src="https://github.com/upstash.png?size=32" width="20" height="20" align="center"/> **[context7](https://github.com/upstash/context7)** — Upstash | `https://mcp.context7.com/mcp` のホスト型 MCP サーバー。最新のライブラリドキュメント。 |
| <img src="https://github.com/exa-labs.png?size=32" width="20" height="20" align="center"/> **[exa](https://github.com/exa-labs/exa-mcp-server)** — Exa Labs | `https://mcp.exa.ai/mcp` のホスト型 MCP サーバー。ニューラルウェブ検索。 |
| <img src="https://github.com/grep-app.png?size=32" width="20" height="20" align="center"/> **[grep.app](https://grep.app/)** — grep.app | `https://mcp.grep.app` のホスト型 MCP サーバー。パブリック GitHub リポジトリ横断のコード検索。 |

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
| **厳選された許可リスト** | `scripts/skill-allowlists.sh` が唯一の正 — アップストリームの数千から 105 スキルと 9 ルールセットだけが残り、リストにないものはセッションのコンテキストに入りません |
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
