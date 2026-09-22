[English](../../README.md) | [한국어](./README.ko.md) | [日本語](./README.ja.md) | [中文](./README.zh.md) | [Deutsch](./README.de.md) | [Français](./README.fr.md)

> [![Codex CLI](https://img.shields.io/badge/Codex_CLI-my--codex-10b981?style=flat-square&logo=openai&logoColor=white)](https://github.com/sehoon787/my-codex) Codex CLI をお探しの方は → **my-codex** — 同じオーケストレーションをネイティブ TOML フォーマットで提供

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

**Claude Code 向けオールインワン・エージェントハーネス。**
**プラグイン一つで、厳選された 32 のエージェントがすぐに使えます。**

Boss はランタイムですべてのエージェント、スキル、MCP ツールを自動検出し、<br>
適切なスペシャリストにタスクをルーティングします。設定ファイルも、ボイラープレートも不要です。

<img src="../../assets/owl-claude-social.svg" alt="The Maestro Owl — my-claude" width="700">

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

インストーラーは my-claude と my-codex で共有する codeburn ダッシュボードと Headroom プロキシを 1 つずつ用意します。後から実行したインストーラーは正常なサービスを再利用し、重複起動しません。状態と起動ログは `${XDG_STATE_HOME:-$HOME/.local/state}/agent-harness-services` に保存され、`ANTHROPIC_BASE_URL` と `OPENAI_BASE_URL` は変更しません。

### AI エージェント向け

```bash
curl -s https://raw.githubusercontent.com/sehoon787/my-claude/main/AI-INSTALL.md
```

出力全文を読んでから、各ステップを順番に実行してください。`WebFetch` ではなく `curl` を使用してください。

インストーラーを実行する前に、エージェントはどのコンパニオンツール（Serena、Headroom、codeburn）をインストールするか尋ねます。対話型のチェックボックスメニューは対話型端末でのみ表示されるためです。

---

<a id="open-source-tools-used"></a>

## 使用しているオープンソースツール

このスタックが土台にしているプロジェクトは、すべてここで一度だけ説明します。
MIT ライセンスのアップストリーム 5 件は明示的な SHA に固定した git サブモジュールとしてリンクされ、
残りはバージョン固定の CLI、ホスト型 MCP サーバー、または帰属表示付きで取り込んだファイルとして届きます。

| # | プロジェクト | my-claude が取り入れているもの | 取り込み方法 |
|---|--------------|--------------------------------|--------------|
| 1 | <img src="https://github.com/Yeachan-Heo.png?size=32" width="20" height="20" align="center"/> **[oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode)** (OMC) — Yeachan Heo | 役割ごとに作業を分担する 19 のスペシャリストエージェント（architect、debugger、code reviewer、security reviewer、…）と、autopilot・ralph・team を含む 16 のオーケストレーションスキル。`autopilot:` のようなマジックキーワードが自動並列実行を起動します。 | サブモジュール `upstream/omc`、SHA 固定（「バンドルされたアップストリームバージョン」を参照）。`install.sh` が `npm i -g oh-my-claude-sisyphus@latest` を実行し、`oh-my-claudecode@omc` プラグインを有効化します。 |
| 2 | <img src="https://github.com/code-yeongyu.png?size=32" width="20" height="20" align="center"/> **[oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent)** (omo) — code-yeongyu | 8 プロバイダー（Claude、GPT、Gemini、…）へカテゴリ別にルーティングし、`claude-code-agent-loader` と `claude-code-plugin-loader` で Claude Code に橋渡しするマルチプラットフォームハーネス。その 9 エージェント（Sisyphus、Atlas、Oracle、…）を単体の `.md` ファイルとして取り込んでいます。 | サブモジュールではありません。9 エージェントは `agents/omo/` にあり、`install.sh` が `omo` CLI のために `npm i -g oh-my-opencode@latest` を実行します。 |
| 3 | <img src="https://github.com/forrestchang.png?size=32" width="20" height="20" align="center"/> **[andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills)** — forrestchang | AI コーディングの 4 つの行動指針 — Think Before Coding、Simplicity First、Surgical Changes、Goal-Driven Execution — が常時有効になります。 | `install.sh` が固定 SHA `aa4467f` の `CLAUDE.md` を curl で取得し、チェックサムを検証して `~/.claude/CLAUDE.md` に追記します。コードは取り込みません。 |
| 4 | <img src="https://github.com/affaan-m.png?size=32" width="20" height="20" align="center"/> **[everything-claude-code](https://github.com/affaan-m/everything-claude-code)** (ECC) — affaan-m | アップストリームには 278 スキル + 67 エージェント + 94 コマンド + 言語ルール。my-claude は厳選した 61 スキル（オプトインの `web` レーンを足すと 79）— スタックパターン、AI/エージェントエンジニアリング、コードベースツール — に加えて 9 ルールセットと `/tdd`、`/plan`、`/code-review`、`/build-fix` などのスラッシュコマンドを導入します。 | サブモジュール `upstream/ecc`、SHA 固定。`install.sh` はまず `claude plugin add affaan-m/everything-claude-code` を試し、失敗した場合はサブモジュールにフォールバックします。 |
| 5 | <img src="https://www.anthropic.com/favicon.ico" width="20" height="20" align="center"/> **[anthropic/skills](https://github.com/anthropics/skills)** — Anthropic | Anthropic 公式のスキルリポジトリ: PDF 解析、Word/Excel/PowerPoint 操作、MCP サーバー作成。 | `install.sh` が `claude plugin add anthropics/skills` を実行します。意図的にマニフェスト追跡の対象外です。 |
| 6 | <img src="https://github.com/garrytan.png?size=32" width="20" height="20" align="center"/> **[gstack](https://github.com/garrytan/gstack)** — garrytan | Garry Tan のスプリントプロセスハーネス: 26 スキルとルートルーター `gstack`（合計 27）— ブラウザ QA（`/qa`）、スコープドリフトのコードレビュー（`/review`）、セキュリティ監査（`/cso`）、および Plan→Review→QA→Ship の全工程（Boss P0 レーン）。実ブラウザテスト用にコンパイル済みの Playwright ブラウザデーモンを同梱します。 | サブモジュール `upstream/gstack`、SHA 固定。 |
| 7 | <img src="https://github.com/obra.png?size=32" width="20" height="20" align="center"/> **[superpowers](https://github.com/obra/superpowers)** — Jesse Vincent | Jesse Vincent の開発プロセスライブラリ: 15 スキル中 14 — ブレインストーミング、体系的デバッグ、TDD、計画の作成と実行、コードレビューの作法。`dispatching-parallel-agents` は Boss と Agent Teams が既にその経路を担うため除外しています。 | サブモジュール `upstream/superpowers`、SHA 固定。 |
| 8 | <img src="https://github.com/getagentseal.png?size=32" width="20" height="20" align="center"/> **[codeburn](https://github.com/getagentseal/codeburn)** — getagentseal | Claude Code と Codex が既に書き出しているセッションファイルを読むローカルファーストのトークン・コスト追跡 — プロキシなし、API キーなし、マシンの外に何も出ません。予算ガードフックは `bash install.sh --with-codeburn-guard` によるオプトインのままです。ハードキャップ（既定で $15/セッション）が解除コマンド `codeburn guard allow` を含むそのセッションのすべてのツール呼び出しを止めるためです（解除は外部ターミナルから実行）。 | `npm i -g codeburn@0.9.23`。`install.sh` は両ハーネス共有のダッシュボードも起動または再利用します — 「結果を確認する場所」を参照。MIT。 |
| 9 | <img src="https://github.com/oraios.png?size=32" width="20" height="20" align="center"/> **[serena](https://github.com/oraios/serena)** — oraios | MCP 経由で使う言語サーバーのシンボルグラフ: `find_symbol`、`get_symbols_overview`、`find_referencing_symbols`、`replace_symbol_body`、`insert_after_symbol` — 消費トークンはファイルではなくシンボルの大きさに比例します。 | `uv tool install -p 3.13 serena-agent==1.7.0` でインストールし、ユーザースコープの stdio MCP サーバー（`serena start-mcp-server --context claude-code --project-from-cwd`）として登録します。配布パッケージは全体として GPL-3.0-or-later です（PyPI の MIT classifier は不正確）。外部サーバーとして利用し、コードは取り込みません。 |
| 10 | <img src="https://github.com/headroomlabs-ai.png?size=32" width="20" height="20" align="center"/> **[headroom](https://github.com/headroomlabs-ai/headroom)** — Headroom Labs | ツール出力の圧縮: `headroom mcp serve` が `headroom_compress`、`headroom_retrieve`、`headroom_stats` を公開し、肥大化したツール実行結果がそのままトランスクリプトに入らないようにします。 | `uv tool install --python 3.13 "headroom-ai[all]==0.37.0"` でインストールし、stdio MCP サーバー `headroom` として登録します。`install.sh` は変更を加えない永続プロファイル `agent-harness-shared` も起動または再利用します。Apache-2.0。 |
| 11 | <img src="https://github.com/tt-a1i.png?size=32" width="20" height="20" align="center"/> **[archify](https://github.com/tt-a1i/archify)** — tt-a1i | アーキテクチャ、ワークフロー、シーケンス、データフロー、ライフサイクルの図を自己完結型 HTML として描くエージェントスキル — インライン SVG、ライト/ダークのテーマ切り替え、PNG/JPEG/WebP/SVG のエクスポートメニュー、生成ファイルにランタイム依存なし。貼り付けた Mermaid も入力方言として受け付けます。 | サブモジュール `upstream/archify`、タグ `v2.9.0` に固定。`install.sh` がアップストリームの `archify/` スキルディレクトリを `~/.claude/skills/archify` にコピーするため、インストール時に `npx skills add` は実行されません。 |
| 12 | <img src="https://github.com/msitarzewski.png?size=32" width="20" height="20" align="center"/> **[agency-agents](https://github.com/msitarzewski/agency-agents)** — msitarzewski | スタック内に代替のないエンジニアリングエージェント 3 個: AI Engineer、DevOps Automator、Multi-Agent Systems Architect。 | サブモジュールは 2026-07-27 に削除。同日に 3 エージェントを `agents/vendored/` へスナップショットし、各ファイルに上流の帰属表示を付けています。MIT。 |
| 13 | <img src="https://github.com/ast-grep.png?size=32" width="20" height="20" align="center"/> **[ast-grep](https://github.com/ast-grep/ast-grep)** — ast-grep | 構文木を理解する構造的なコード検索・書き換え。エージェントは正規表現ではなくコードの形にマッチできます。 | `npm i -g @ast-grep/cli@0.42.0`。MIT。 |
| 14 | <img src="https://github.com/upstash.png?size=32" width="20" height="20" align="center"/> **[context7](https://github.com/upstash/context7)** — Upstash | バージョンに忠実な最新のライブラリドキュメント。エージェントが記憶に頼らず実際の API を読めます。 | `https://mcp.context7.com/mcp` のホスト型 MCP サーバー。`install.sh` が登録します。 |
| 15 | <img src="https://github.com/exa-labs.png?size=32" width="20" height="20" align="center"/> **[exa](https://github.com/exa-labs/exa-mcp-server)** — Exa Labs | キーワード検索では取りこぼす調査のためのニューラル（意味ベース）ウェブ検索。 | `https://mcp.exa.ai/mcp` のホスト型 MCP サーバー。`install.sh` が登録します。 |
| 16 | <img src="https://github.com/grep-app.png?size=32" width="20" height="20" align="center"/> **[grep.app](https://github.com/grep-app)** — grep.app | 公開 GitHub リポジトリ横断のコード検索。あるパターンが実際にどう使われているかを探せます。 | `https://mcp.grep.app` のホスト型 MCP サーバー。`install.sh` が登録します。 |


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
| ファイル/設定の変更 | 変更対照 (Changes) | 対象 / Before / After / 根拠 |
| 複数タスクの完了 | 作業サマリ (Work summary) | 項目 / 結果 / 根拠 |
| 検証を実行 | 検証結果 (Verification) | 項目 / 期待 / 実際 / 判定 |
| コミット/PR を作成 | 成果物 (Deliverables) | PR / リポジトリ / 内容 / 状態 |
| 未解決事項あり | 残項目 (Remaining) | 項目 / 状態 / 次のアクション |

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
| **スキル** | 107 | ECC 61 · gstack 27 · Superpowers 14 · Core 4 · Archify 1 |
| **ルール** | 48 ファイル / 9 ルールセット | ECC 46（common + 8 言語ディレクトリ）+ Core 2 |
| **MCP サーバー** | 3 | Context7、Exa、grep.app |
| **フック** | 10 ファイル / 6 イベント | 委任ガード、テレメトリー、検証、ナレッジ Vault |
| **LSP サーバー** | 2 | typescript（`typescript-language-server`）、python（`pyright-langserver`） |
| **名前付きワークフロー** | 2 | code-review-fanout、upstream-audit |
| **アップストリームサブモジュール** | 5 | ecc、omc、gstack、superpowers、archify |
| **CLI ツール** | 7 | omc、omo、ast-grep、comment-checker、codeburn、serena、headroom |

上記のエージェント・スキル・ルールはすべて [`scripts/skill-allowlists.sh`](../../scripts/skill-allowlists.sh) の許可リストに登録され、インストールマニフェストで追跡されます。Anthropic 公式のドキュメントスキル（pdf、docx など）は `claude plugin add anthropics/skills` で別途インストールされ、意図的にマニフェスト追跡の対象外です。

<details>
<summary><strong>スペシャリストエージェント — 4 ティアで 32</strong></summary>

エージェントごとのモデルは上の「モデルルーティング」テーブルに記載されています。各ソースの出どころは [使用しているオープンソースツール](#open-source-tools-used) にあります。

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
<summary><strong>スキル — 5 つのソースから 107</strong></summary>

各ソースは [`scripts/skill-allowlists.sh`](../../scripts/skill-allowlists.sh) の許可リストで管理され、リストにないスキルはインストールされません。

| ソース | 数 | 主要スキル |
|--------|------:|------------|
| [everything-claude-code](https://github.com/affaan-m/everything-claude-code) | 61 | coding-standards、fastapi-patterns、agent-architecture-audit、springboot-patterns、kubernetes-patterns |
| [gstack](https://github.com/garrytan/gstack) | 27 | /qa、/review、/ship、/cso、/investigate、/office-hours |
| [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) | 16（プラグイン） | autopilot、ralph、team、ultrawork、ralplan、omc-reference |
| [superpowers](https://github.com/obra/superpowers) | 14 | brainstorming、systematic-debugging、test-driven-development、writing-plans |
| [my-claude Core](https://github.com/sehoon787/my-claude) | 4 | boss-advanced、boss-briefing、briefing-vault、gstack-sprint |
| [archify](https://github.com/tt-a1i/archify) | 1 | archify |

</details>

<details>
<summary><strong>MCP サーバー (3) + フック (8)</strong></summary>

**MCP サーバー** — それぞれの機能と登録方法は [使用しているオープンソースツール](#open-source-tools-used) にあります。

| サーバー | コスト |
|--------|------|
| <img src="https://context7.com/favicon.ico" width="16" height="16" align="center"/> [Context7](https://context7.com) | 無料 |
| <img src="https://exa.ai/images/favicon-32x32.png" width="16" height="16" align="center"/> [Exa](https://exa.ai) | 月 1,000 リクエスト無料 |
| <img src="https://www.google.com/s2/favicons?domain=grep.app&sz=32" width="16" height="16" align="center"/> [grep.app](https://github.com/grep-app) | 無料 |

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

スタックが生成した出力を実際に確認できる場所です。各ツールが何であるかは [使用しているオープンソースツール](#open-source-tools-used) にあります:

| ツール | 開く | 実行方法 | 確認場所 |
|--------|------|----------|----------|
| **codeburn** | <http://127.0.0.1:4747/> | `install.sh` が `codeburn web --provider all --port 4747 --no-open` を起動または再利用 · `codeburn` は TUI を表示 · `codeburn report --format json --period week` は非対話形式で出力 | 共有ダッシュボード。起動ログは `${XDG_STATE_HOME:-$HOME/.local/state}/agent-harness-services/logs/codeburn.log`。セッションファイルは読み取り専用で、ドル金額は API 定価に基づく推定値です。 |
| **Serena** | <http://localhost:24282/dashboard/index.html> | MCP サーバーとして自動的に起動します。任意のセッションから `get_symbols_overview` / `find_symbol` を呼び出せます | サーバー稼働中に使えるダッシュボード（ログ + ツールごとの呼び出し回数）。プロジェクトごとのメモリは作業中のリポジトリ内の `.serena/` に保存され、グローバル設定は `~/.serena/serena_config.yml` です。 |
| **Headroom** | <http://127.0.0.1:8787/stats> | MCP ツール `headroom_compress` / `headroom_retrieve` / `headroom_stats`。`install.sh` が共有プロキシプロファイル `agent-harness-shared` を起動または再利用 | 圧縮統計。プロキシ経由になるまで空の場合があります。起動ログは `${XDG_STATE_HOME:-$HOME/.local/state}/agent-harness-services/logs/headroom.log`。 |
| **Archify** | `out.html` | 図を依頼すると Boss が `archify` スキルにルーティングします。手動で実行する場合は `~/.claude/skills/archify` から: `node bin/archify.mjs render workflow examples/agent-tool-call.workflow.json out.html` | 生成されたファイル — 任意のブラウザで開けます。`node bin/archify.mjs check out.html` で検証できます。 |
| **OMC HUD** | Claude Code ステータスライン | `install.sh` がステータスラインとしてインストールします。`/oh-my-claudecode:hud` で再設定できます | セッション下部に、コンテキスト・クォータ・モードがライブ表示されます。codeburn を補完します: HUD は現在のセッション、codeburn は全セッションを対象とします。 |

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
| **厳選された許可リスト** | `scripts/skill-allowlists.sh` が唯一の正 — アップストリームの数千から 107 スキルと 9 ルールセットだけが残り、リストにないものはセッションのコンテキストに入りません |
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
| [everything-claude-code](https://github.com/affaan-m/everything-claude-code) | `07756ce` | 2026-09-19 | [compare](https://github.com/affaan-m/everything-claude-code/compare/07756ce...HEAD) |
| [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) | `5281b19` | 2026-09-13 | [compare](https://github.com/Yeachan-Heo/oh-my-claudecode/compare/5281b19...HEAD) |
| [gstack](https://github.com/garrytan/gstack) | `a6b3a57` | 2026-09-16 | [compare](https://github.com/garrytan/gstack/compare/a6b3a57...HEAD) |
| [superpowers](https://github.com/obra/superpowers) | `5bf4e78` | 2026-09-19 | [compare](https://github.com/obra/superpowers/compare/5bf4e78...HEAD) |
| [archify](https://github.com/tt-a1i/archify) | `62904f3` (`v2.9.0`) | 2026-09-19 | [compare](https://github.com/tt-a1i/archify/compare/62904f3...HEAD) |

---

## コントリビューション

Issues と PR を歓迎します。新しいエージェントを追加する際は、`agents/core/` または `agents/omo/` に `.md` ファイルを追加し、`SETUP.md` を更新してください。

## クレジット

[使用しているオープンソースツール](#open-source-tools-used) に挙げたプロジェクトの上に構築されています。すべての作者に感謝します。

## ライセンス

MIT ライセンス。詳細は [LICENSE](../../LICENSE) ファイルをご参照ください。
