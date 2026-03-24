[English](../../README.md) | [한국어](./README.ko.md) | [日本語](./README.ja.md) | [中文](./README.zh.md) | [Deutsch](./README.de.md) | [Français](./README.fr.md)

> [![Codex CLI](https://img.shields.io/badge/Codex_CLI-my--codex-10b981?style=flat-square&logo=openai&logoColor=white)](https://github.com/sehoon787/my-codex) Codex CLI をお探しですか？ → **my-codex** — OpenAI Codex CLI 用のネイティブ TOML 形式の同じエージェント

> **LLM エージェントの場合**、インストールガイドを取得して実行してください:
> ```bash
> curl -s https://raw.githubusercontent.com/sehoon787/my-claude/main/AI-INSTALL.md
> ```
> 完全な出力を読み、各ステップを順に実行してください。`WebFetch` ではなく `curl` を使用してください（概要では重要な設定値が失われます）。

---

# my-claude

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Agents](https://img.shields.io/badge/agents-201-blue)
![Skills](https://img.shields.io/badge/skills-148-purple)
![Rules](https://img.shields.io/badge/rules-65-orange)
![MCP](https://img.shields.io/badge/MCP-3-green)
![Hooks](https://img.shields.io/badge/hooks-6-red)
![Auto Sync](https://img.shields.io/badge/upstream_sync-weekly-brightgreen)

Claude Code 用の完全な複数エージェント オーケストレーション プラグイン — 1 回インストールするだけで、すべてが揃います。

3 つの MIT アップストリーム ソースから **201 エージェント**、**148 スキル**、**65 ルール**、**6 つのフック**、**3 つの MCP サーバー** をバンドルして、1 つのプラグインにまとめています。**Boss** 動的メタ オーケストレータは、実行時にインストール済みのすべてのコンポーネントを自動検出し、最適な専門家にタスクをルーティングします。GitHub Actions CI は、アップストリームの変更を毎週同期します。

<p align="center">
  <img src="./assets/demo.svg" alt="my-claude demo" width="700">
</p>

---

## コア原則

| 原則 | 説明 |
|-----------|-------------|
| **リーダーシップ** | Boss がオーケストレーションを行い、実装は行いません。ピアツーピア通信、動的構成、ファイル所有権プロトコルでチームをリードします |
| **ディスカバリー** | ランタイム機能マッチング — ハードコードされたルーティング テーブルはありません。すべてのエージェント、スキル、MCP サーバーはセッション開始時に自動検出されます |
| **検証** | 信用しつつ検証を行う。すべてのサブエージェント結果は、受け入れ前に独立して確認されます |

## クイックスタート

### 人間ユーザーの場合

**オプション 1: Claude Code プラグイン経由でインストール**

```bash
# Claude Code セッション内:
/plugin marketplace add sehoon787/my-claude
/plugin install my-claude@my-claude
```

その後、コンパニオン ツール（npm パッケージ + Anthropic スキル）をインストールします:

```bash
git clone --depth 1 https://github.com/sehoon787/my-claude.git /tmp/my-claude
bash /tmp/my-claude/install.sh
rm -rf /tmp/my-claude
```

**オプション 2: 自動スクリプト**

```bash
git clone --depth 1 https://github.com/sehoon787/my-claude.git /tmp/my-claude && bash /tmp/my-claude/install.sh && rm -rf /tmp/my-claude
```

> **注**: `install.sh` は Boss を自動的にデフォルト エージェントとして設定します。プラグイン インストール（オプション 1）の場合は、[AI-INSTALL.md](AI-INSTALL.md) のセットアップ コマンドを実行してください。
>
> **エージェント パック**: ドメイン専門家エージェント（マーケティング、セールス、ゲーム開発など）は `~/.claude/agent-packs/` にインストールされ、必要に応じて `~/.claude/agents/` にシンボリック リンクすることで有効化できます。

**オプション 3: 手動インストール**

```bash
git clone https://github.com/sehoon787/my-claude.git
```

次に、`SETUP.md` の指示に従ってファイルをコピーします。

### LLM エージェントの場合

AI インストール ガイドを取得して、各ステップを実行します:

```bash
curl -s https://raw.githubusercontent.com/sehoon787/my-claude/main/AI-INSTALL.md
```

完全な出力を読み、各ステップを順に実行します。`WebFetch` ではなく `curl` を使用してください。人間向けのステップバイステップ セットアップについては、`SETUP.md` を参照してください。

---

## 主な機能

### 複数エージェント オーケストレーション
- **Boss 動的メタ オーケストレータ**: 実行時にインストール済みのすべてのエージェント、スキル、MCP サーバーを自動検出し、3D 競合解決（スコープ/深さ×2/相互作用性）を通じてタスクをルーティングします。中規模タスク（P3a）をサブ オーケストレータ オーバーヘッドなしで直接処理します
- **エージェント チーム ダイレクト リーダーシップ**: Boss はエージェント チームを直接リード（優先度 3c-DIRECT）でき、ピアツーピア チームメート通信、ファイル所有権プロトコル、品質保証のためのレビュー チェーン パターンが可能です
- **サブ オーケストレータ（P3b）**: タスクが直接処理には複雑すぎる場合、Boss は Sisyphus（計画+検証）、Atlas（タスク調整）、Hephaestus（自律実行）に委譲します — 複雑なマルチステップ ワークフロー用のみで、すべてのリクエスト用ではありません
- **スキル vs エージェント 競合解決**: 加重 3 次元スコアリング（スコープ、深さ×2、相互作用性）により、各タスクでスキルを使用するかエージェントを使用するかを決定します — ハードコードされたルーティング テーブルはありません
- **モデル最適化ルーティング**: タスクの複雑さに基づいて、Opus（高複雑度）/ Sonnet（実装）/ Haiku（探索）を自動選択します

### ランタイム動作修正
- **委譲ガード**（PreToolUse）: オーケストレータがファイルを直接変更しようとするときにサブ エージェント委譲を強制します
- **サブエージェント ベリファイア**（SubagentStop）: サブ エージェントが完了した後、独立した検証を強制します
- **完了チェック**（Stop）: セッション終了を許可する前に、すべてのタスクが完了および検証されたことを確認します

### 外部知識統合（MCP）
- **Context7**: リアルタイムでオフィシャル ライブラリ ドキュメンテーションを取得
- **Exa**: セマンティック Web 検索（月額 1,000 リクエストまで無料）
- **grep.app**: GitHub オープンソース コード検索

### ワンパッケージ バンドル
- プラグイン インストールは **201 エージェント、148 スキル、65 ルール** を即座に提供
- 3 つの MIT アップストリーム ソース（agency-agents、everything-claude-code、oh-my-claudecode）をバンドル
- 毎週 CI オート同期によるアップストリーム コンテンツ最新化
- コンパニオン `install.sh` は npm ツールと独自 Anthropic スキルを追加

---

## コア + OMO エージェント

**Boss** は my-claude の唯一のオリジナル エージェントです。残りの 9 つは [OMO エージェント](https://github.com/code-yeongyu/oh-my-openagent)で、Boss がサブ オーケストレータおよび専門家として使用します。プラグインは **52 のコア エージェント**（Core 1 + OMO 9 + Engineering 23 + OMC 19 + OMO 専門家）を `~/.claude/agents/` に常時ロードし、さらに **150 のドメイン エージェント パック**を `~/.claude/agent-packs/` に置いており、必要に応じて有効化できます。Boss は、すべてのアクティブなエージェントから優先度 2 の機能マッチングを通じて最適マッチ専門家を選択します。以下の[インストール済みコンポーネント](#installed-components)を参照してください。

| エージェント | ソース | モデル | 役割 |
|---------|--------|------|------|
| **Boss** | my-claude | Opus | 動的メタ オーケストレータ。インストール済みのすべてのエージェント/スキル/MCP を自動検出し、最適な専門家にルーティング |
| **Sisyphus** | OMO | Opus | サブ オーケストレータ。複雑なマルチステップ ワークフローを意図分類と検証で管理 |
| **Hephaestus** | OMO | Opus | 自律型ディープ ワーカー。探索 → 計画 → 実行 → 検証サイクルを自律的に実行 |
| **Metis** | OMO | Opus | 前実行意図分析。実行前にリクエストを構造化し AI スロップ を防止 |
| **Atlas** | OMO | Opus | マスター タスク オーケストレータ。複雑なタスクを分解し、4 段階 QA サイクルで調整 |
| **Oracle** | OMO | Opus | 戦略的技術顧問。読み取り専用モードでコードを分析・改変せず方向を提示 |
| **Momus** | OMO | Opus | タスク計画レビューアー。承認バイアスで計画をレビュー。読み取り専用 |
| **Prometheus** | OMO | Opus | インタビューベース計画コンサルタント。対話を通じて要件を明確化 |
| **Librarian** | OMO | Sonnet | オープンソース ドキュメンテーション リサーチ エージェント（MCP 使用） |
| **Multimodal-Looker** | OMO | Sonnet | ビジュアル分析エージェント。画像/スクリーンショットを分析。読み取り専用 |

---

## エージェント パック（ドメイン専門家）

ドメイン専門家エージェントは `~/.claude/agent-packs/` にインストールされ、デフォルトではロードされません。パックを有効化するには、`~/.claude/agents/` にシンボリック リンクします:

```bash
# 単一パックを有効化
ln -s ~/.claude/agent-packs/marketing/*.md ~/.claude/agents/

# 無効化
rm ~/.claude/agents/<agent-name>.md
```

| パック | 数 | 例 |
|------|-------|---------|
| marketing | 27 | Douyin、Xiaohongshu、WeChat OA、TikTok |
| gamedev | 19 | Unity、Unreal、Godot、Roblox |
| engineering-domain | 8 | Mobile、Solidity、Embedded、Feishu |
| sales | 9 | SDR、Account Executive、Revenue Ops |
| specialized | 10+ | Legal、Finance、Healthcare、Education |
| design | 8 | Brand、UI、UX、Visual Storytelling |
| testing | 8 | API、Accessibility、Performance、E2E |
| product | 5 | Sprint、Feedback、Trend Research |
| paid-media | 7 | Google Ads、Meta Ads、Programmatic |
| project-mgmt | 5 | Scrum、Kanban、Risk Management |
| academic | 5 | Research、Literature Review、Citation |
| support | 6 | Customer Success、Escalation、Triage |
| spatial-computing | 3 | ARKit、visionOS、Spatial Audio |

---

## インストール済みコンポーネント

SETUP.md に従うと、以下が設定されます:

| カテゴリ | 数 | ソース | バンドル |
|------|------|------|------|
| コア エージェント | 53 | Core 1 + OMO 9 + Engineering 23 + OMC 19 | プラグイン |
| エージェント パック | 133 | 12 ドメイン カテゴリ（マーケティング、ゲーム開発、セールスなど） | プラグイン |
| スキル | 148 | ECC 119 + OMC 29 | プラグイン |
| ルール | 65 | ECC（共通 9 + 8 言語 × 5） | プラグイン |
| MCP サーバー | 3 | Context7、Exa、grep.app | プラグイン |
| フック | 6 | my-claude（Boss プロトコル + SessionStart） | プラグイン |
| Anthropic スキル | 14+ | Anthropic オフィシャル | install.sh |
| CLI ツール | 3 | omc、omo、ast-grep | install.sh |

<details>
<summary>コア + OMO エージェント（10） — Boss メタ オーケストレータ + omo エージェント</summary>

| エージェント | モデル | タイプ | 役割 | 読み取り専用 |
|---------|------|------|------|-----------|
| Boss | Opus | メタ オーケストレータ | すべてのエージェント/スキル/MCP のランタイム検出 → 機能マッチング → 最適ルーティング | はい |
| Sisyphus | Opus | サブ オーケストレータ | 意図分類 → 専門家エージェント委譲 → 独立検証。コード直接記述なし | いいえ |
| Hephaestus | Opus | 自律実行 | 探索 → 計画 → 実行 → 検証を自律的に実行。許可を求めずタスク完了 | いいえ |
| Metis | Opus | 分析 | ユーザー意図分析、曖昧性検出、AI スロップ 防止 | はい |
| Atlas | Opus | オーケストレータ | タスク委譲 + 4 段階 QA 検証。コード直接記述なし | いいえ |
| Oracle | Opus | 顧問 | 戦略的技術コンサルティング。アーキテクチャおよびデバッグ コンサルティング | はい |
| Momus | Opus | レビュー | タスク計画の実現可能性をレビュー。承認バイアス | はい |
| Prometheus | Opus | 計画 | インタビューベース詳細計画。.md ファイル記述のみ | 部分的 |
| Librarian | Sonnet | リサーチ | MCP 使用オープンソース ドキュメンテーション検索 | はい |
| Multimodal-Looker | Sonnet | ビジュアル分析 | 画像/スクリーンショット/図表分析 | はい |

</details>

<details>
<summary>OMC エージェント（19） — Oh My Claude Code 専門家エージェント</summary>

| エージェント | 役割 |
|---------|------|
| analyst | 前分析 — 計画前の状況理解 |
| architect | システム設計とアーキテクチャ判断 |
| code-reviewer | 重点的なコード レビュー |
| code-simplifier | コード簡略化とクリーンアップ |
| critic | 批判的分析、代替案提示 |
| debugger | 重点的なデバッグ |
| designer | UI/UX デザイン ガイダンス |
| document-specialist | ドキュメンテーション記述・管理 |
| executor | タスク実行 |
| explore | コードベース探索 |
| git-master | Git ワークフロー管理 |
| planner | 迅速な計画 |
| qa-tester | 品質保証テスト |
| scientist | リサーチおよび実験 |
| security-reviewer | セキュリティ レビュー |
| test-engineer | テスト記述・保守 |
| tracer | 実行トレース・分析 |
| verifier | 最終検証 |
| writer | コンテンツおよびドキュメンテーション記述 |

</details>

<details>
<summary>Agency エージェント（172） — 14 カテゴリにわたるビジネス専門家ペルソナ（すべてモデル: claude-sonnet-4-6）</summary>

**Engineering（22）**

| エージェント | 役割 |
|---------|------|
| ai-engineer | AI/ML エンジニアリング |
| autonomous-optimization-architect | 自律最適化アーキテクチャ |
| backend-architect | バックエンド アーキテクチャ |
| code-reviewer | コード レビュー |
| data-engineer | データ エンジニアリング |
| database-optimizer | データベース最適化 |
| devops-automator | DevOps オートメーション |
| embedded-firmware-engineer | 組み込みファームウェア |
| feishu-integration-developer | Feishu 統合開発 |
| frontend-developer | フロントエンド開発 |
| git-workflow-master | Git ワークフロー |
| incident-response-commander | インシデント対応 |
| mobile-app-builder | モバイル アプリ構築 |
| rapid-prototyper | 高速プロトタイピング |
| security-engineer | セキュリティ エンジニアリング |
| senior-developer | シニア開発 |
| software-architect | ソフトウェア アーキテクチャ |
| solidity-smart-contract-engineer | Solidity スマート コントラクト |
| sre | サイト リライアビリティ エンジニアリング |
| technical-writer | 技術ドキュメンテーション記述 |
| threat-detection-engineer | 脅威検出エンジニアリング |
| wechat-mini-program-developer | WeChat ミニ プログラム開発 |

**Testing（8）**

| エージェント | 役割 |
|---------|------|
| accessibility-auditor | アクセシビリティ 監査 |
| api-tester | API テスト |
| evidence-collector | テスト エビデンス収集 |
| performance-benchmarker | パフォーマンス ベンチマーク |
| reality-checker | 現実性検証 |
| test-results-analyzer | テスト結果分析 |
| tool-evaluator | ツール評価 |
| workflow-optimizer | ワークフロー最適化 |

**Design（8）**

| エージェント | 役割 |
|---------|------|
| brand-guardian | ブランド ガイドライン強制 |
| image-prompt-engineer | 画像プロンプト エンジニアリング |
| inclusive-visuals-specialist | インクルーシブ ビジュアル デザイン |
| ui-designer | UI デザイン |
| ux-architect | UX アーキテクチャ |
| ux-researcher | UX リサーチ |
| visual-storyteller | ビジュアル ストーリーテリング |
| whimsy-injector | 楽しさと遊び心の注入 |

**Product（4）**

| エージェント | 役割 |
|---------|------|
| behavioral-nudge-engine | 行動ナッジ デザイン |
| feedback-synthesizer | フィードバック 統合 |
| sprint-prioritizer | スプリント優先順位付け |
| trend-researcher | トレンド リサーチ |

</details>

<details>
<summary>スキル（33） — Anthropic オフィシャル + ECC</summary>

| スキル | ソース | 説明 |
|------|------|------|
| algorithmic-art | Anthropic | p5.js ベースのジェネレーティブ アート |
| backend-patterns | ECC | バックエンド アーキテクチャ パターン |
| brand-guidelines | Anthropic | Anthropic ブランド スタイル適用 |
| canvas-design | Anthropic | PNG/PDF ビジュアル デザイン |
| claude-api | Anthropic | Claude API/SDK でアプリケーション構築 |
| clickhouse-io | ECC | ClickHouse クエリ最適化 |
| coding-standards | ECC | TypeScript/React コーディング標準 |
| continuous-learning | ECC | セッションからの自動パターン抽出 |
| continuous-learning-v2 | ECC | インスティンクト ベース学習システム |
| doc-coauthoring | Anthropic | ドキュメント 共同執筆 ワークフロー |
| docx | Anthropic | Word ドキュメント作成/編集 |
| eval-harness | ECC | 評価駆動開発（EDD） |
| frontend-design | Anthropic | フロントエンド UI デザイン |
| frontend-patterns | ECC | React/Next.js パターン |
| internal-comms | Anthropic | 内部通信記述 |
| iterative-retrieval | ECC | インクリメンタル コンテキスト 取得 |
| karpathy-guidelines | Anthropic | Karpathy AI コーディング ガイドライン |
| learned | ECC | 学習パターン リポジトリ |
| mcp-builder | Anthropic | MCP サーバー開発 ガイド |
| pdf | Anthropic | PDF 読み取り/マージ/分割/OCR |
| postgres-patterns | ECC | PostgreSQL 最適化 |
| pptx | Anthropic | PowerPoint 作成/編集 |
| project-guidelines-example | Anthropic | プロジェクト ガイドライン例 |
| security-review | ECC | セキュリティ チェックリスト |
| skill-creator | Anthropic | カスタム スキル作成メタ スキル |
| slack-gif-creator | Anthropic | Slack 用 GIF 作成 |
| strategic-compact | ECC | 戦略的 コンテキスト 圧縮 |
| tdd-workflow | ECC | TDD ワークフロー強制 |
| theme-factory | Anthropic | アーティファクトへのテーマ 適用 |
| verification-loop | Anthropic | 検証ループ |
| web-artifacts-builder | Anthropic | 複合 Web アーティファクト 構築 |
| webapp-testing | Anthropic | Playwright Web アプリ テスト |
| xlsx | Anthropic | Excel ファイル 作成/編集 |

</details>

<details>
<summary>ルール（65） — ECC コーディング ルール</summary>

**共通（9）** — すべてのプロジェクトに適用

| ルール | 説明 |
|----|------|
| agents.md | エージェント動作ルール |
| coding-style.md | コーディング スタイル |
| development-workflow.md | 開発ワークフロー |
| git-workflow.md | Git ワークフロー |
| hooks.md | フック使用ルール |
| patterns.md | デザイン パターン |
| performance.md | パフォーマンス最適化 |
| security.md | セキュリティ ルール |
| testing.md | テスト ルール |

**TypeScript（5）** — TypeScript プロジェクトのみ

| ルール | 説明 |
|----|------|
| coding-style.md | TS コーディング スタイル |
| hooks.md | TS フック パターン |
| patterns.md | TS デザイン パターン |
| security.md | TS セキュリティ ルール |
| testing.md | TS テスト ルール |

**その他の言語（各 5 ルール）** — C++、Go、Kotlin、Perl、PHP、Python、Swift

各言語ディレクトリには以下が含まれます: coding-style.md、hooks.md、patterns.md、security.md、testing.md

</details>

<details>
<summary>MCP サーバー（3） + 動作修正フック（6）</summary>

**MCP サーバー**

| サーバー | URL | 目的 | コスト |
|------|-----|------|------|
| Context7 | mcp.context7.com | リアルタイム ライブラリ ドキュメンテーション ルックアップ | 無料（キー登録で上限アップ） |
| Exa | mcp.exa.ai | セマンティック Web 検索 | 無料 月 1k リクエスト |
| grep.app | mcp.grep.app | オープンソース GitHub コード検索 | 無料 |

**動作修正フック**

| フック | イベント | 動作 |
|----|--------|------|
| Session Setup | SessionStart | コンパニオン ツール（omc、omo、ast-grep、Anthropic スキル）の不足を自動検出しインストール |
| Delegation Guard | PreToolUse（Edit/Write） | Boss がファイルを直接変更しようとするときにサブ エージェントに委譲することを促します |
| Subagent Verifier | SubagentStop | サブ エージェント完了後、独立した検証を強制 |
| Completion Check | Stop | セッション終了を許可する前に、すべてのタスクが完了および検証されたことを確認 |
| Teammate Idle Guide | TeammateIdle | リーダーが TeamList をチェックし、チームメートがアイドル状態の場合にシャットダウンまたは次の指示を送信することを促します |
| Task Quality Gate | TaskCompleted | リーダーに成果物の存在を検証し、完了したタスクを受け入れる前に品質をチェックすることを促します |

</details>

---

## 完全なアーキテクチャ

```
┌─────────────────────────────────────────────────────────┐
│                    User Request                          │
└─────────────────────┬───────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────────┐
│  [Boss] Dynamic Meta-Orchestrator                       │
│  Runtime Discovery → Capability Matching → Routing      │
│  (agents, skills, MCP servers, hooks — all discovered)  │
└──┬──────────┬──────────┬──────────┬──────────┬──────────┘
   ↓          ↓          ↓          ↓          ↓
┌──────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐
│  P1  │ │   P2   │ │  P3a   │ │  P3b   │ │  P3c   │
│Skill │ │Special-│ │ Direct │ │Sub-orc-│ │ Agent  │
│Match │ │ist     │ │Parallel│ │hestrat-│ │ Teams  │
│      │ │Agent   │ │ (2-4)  │ │ors     │ │  P2P   │
│      │ │ (191)  │ │        │ │Sisyphus│ │        │
└──────┘ └────────┘ └────────┘ │ Atlas  │ └────────┘
                                │Hephaes-│
                                │ tus    │
                                └────────┘
┌─────────────────────────────────────────────────────────┐
│  Karpathy Guidelines (behavioral guidelines, always on) │
│  ECC Rules (language-specific coding rules, always on)  │
│  Hooks: PreToolUse / SubagentStop / Stop                │
└─────────────────────┬───────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────────┐
│  Specialist Agent Layer                                 │
│    ├── OMC Agents (executor, debugger, test-engineer)   │
│    ├── Agency Agents (UX architect, security auditor)   │
│    ├── ECC Commands (/tdd, /code-review, /build-fix)    │
│    └── Anthropic Skills (pdf, docx, mcp-builder)        │
└─────────────────────┬───────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────────┐
│  MCP Server Layer                                       │
│    ├── Context7 (real-time library documentation)       │
│    ├── Exa (semantic web search)                        │
│    └── grep.app (open-source code search)               │
└─────────────────────────────────────────────────────────┘

    ┌─────────────────────────────────────────────────────┐
    │ omo Bridge (when using OpenCode)                    │
    │  claude-code-agent-loader: loads ~/.claude/agents/*.md│
    │  claude-code-plugin-loader: loads CC plugins        │
    │  → Both OMC + omo agents available in OpenCode      │
    └─────────────────────────────────────────────────────┘
```

---

## 使用されているオープン ソース ツール

### 1. [Oh My Claude Code（OMC）](https://github.com/Yeachan-Heo/oh-my-claudecode)

Claude Code 専用マルチエージェント オーケストレーション プラグイン。18 の専門家エージェント（アーキテクト、デバッガー、コード レビューアー、セキュリティ レビューアーなど）が役割で仕事を分け、`autopilot:` などのマジック キーワードが自動並列実行を有効化します。

### 2. [Oh My OpenAgent（omo）](https://github.com/code-yeongyu/oh-my-openagent)

マルチプラットフォーム エージェント ハーネス。`claude-code-agent-loader` および `claude-code-plugin-loader` を通じて Claude Code エコシステムへブリッジ。カテゴリ別に 8 つのプロバイダー（Claude、GPT、Gemini など）にルーティング。このリポジトリの 9 つのエージェントは、omo エージェント を Claude Code スタンドアロン `.md` 形式に改変したものです。

### 3. [Andrej Karpathy スキル](https://github.com/forrestchang/andrej-karpathy-skills)

Andrej Karpathy が提唱した 4 つの AI コーディング動作ガイドライン（思考から実装を始める、シンプルさ優先、外科的変更、目標駆動実行）。CLAUDE.md に含まれ、すべてのセッションで常時アクティブ。

### 4. [Everything Claude Code（ECC）](https://github.com/affaan-m/everything-claude-code)

67 個のスキル + 17 個のエージェント + 45 個のコマンド + 言語固有ルールを提供する包括的フレームワーク。反復的な開発パターンを `/tdd`、`/plan`、`/code-review`、`/build-fix` などのスラッシュ コマンドでオートメーション化します。

### 5. [Anthropic オフィシャル スキル](https://github.com/anthropics/skills)

Anthropic が直接提供するオフィシャル エージェント スキル リポジトリ。PDF 解析、Word/Excel/PowerPoint ドキュメント操作、MCP サーバー作成などの専門家タスクを有効化します。

### 6. [Agency Agents](https://github.com/msitarzewski/agency-agents)

164 個のビジネス専門家エージェント ペルソナ ライブラリ。技術的役割を超えたビジネス コンテキストの専門家視点を提供 — UX アーキテクト、データ エンジニア、セキュリティ 監査人、QA マネージャーなど。

---

## Boss の動作

### ハーネス vs オーケストレータ vs エージェント

| 概念 | 役割 | 比喩 | 例 |
|---------|------|---------|---------|
| **ハーネス** | エージェント実行ランタイム プラットフォーム — ライフサイクル、ツール、権限を管理 | オペレーティング システム | Claude Code、omo |
| **オーケストレータ** | 他のエージェント調整特別エージェント — 意図分類、委譲、検証。直接実装なし | 指揮者 | Boss、Sisyphus、Atlas |
| **エージェント** | 特定ドメインで実際の作業実行ユニット — コード記述、分析、レビュー | ミュージシャン | debugger、executor、security-reviewer |

```
Harness (Claude Code)
 └─ Boss (Meta-Orchestrator)         — すべて検出、最適ルーティング
     ├─ Skill invocation              — pdf、docx、tdd-workflow など
     ├─ Direct agent delegation       — debugger、security-reviewer など
     ├─ Sisyphus (Sub-Orchestrator)   — 複雑ワークフロー管理
     │   ├─ Metis → intent analysis
     │   ├─ Prometheus → planning
     │   └─ Hephaestus → autonomous execution
     └─ Atlas (Sub-Orchestrator)      — タスク分解 + QA サイクル
```

### 委譲メカニズム（4 優先度ルーティング）

Boss はすべてのリクエストを 4 レベル優先度チェーンを通じてルーティングします:

| 優先度 | マッチ タイプ | いつ | 例 |
|----------|-----------|------|---------|
| **1** | 完全スキル マッチ | タスクが自己完結スキルに対応 | "PDF マージ" → `Skill("pdf")` |
| **2** | 専門家エージェント マッチ | ドメイン固有エージェント存在 | "セキュリティ監査" → `Agent("Security Engineer")` |
| **3a** | 直接オーケストレーション | 2-4 個の独立エージェント | "3 個のバグ修正" → Boss 並列 |
| **3b** | サブ オーケストレータ委譲 | 複雑マルチステップ ワークフロー | "リファクタ+テスト" → Sisyphus |
| **3c** | エージェント チーム（直接リーダーシップ） | ピアツーピア通信必要 | "実装+レビュー" → レビュー チェーン |
| **4** | 汎用フォールバック | 専門家マッチなし | "これを説明して" → `Agent(model="sonnet")` |

すべての委譲に **6 セクション構造化プロンプト**が含まれます: TASK、EXPECTED OUTCOME、REQUIRED TOOLS、MUST DO、MUST NOT DO、CONTEXT。

### 委譲例

#### サブエージェント vs エージェント チーム

| | サブエージェント（P2/P3a/P3b） | エージェント チーム（P3c） |
|---|---|---|
| **コマンド** | `Agent(prompt="...")` | `SendMessage(to: "agent", ...)` |
| **通信** | Boss → エージェント → Boss | Boss ↔ エージェント ↔ エージェント |
| **寿命** | 完了で終了 | TeamDelete までの永続 |
| **表示** | Boss ログのみ | tmux ペイン または Shift+↓ |
| **コスト** | 低 | 高（チームメートごと別 Claude セッション） |

**P2 — 単一専門家エージェント:**
```
$ claude "セキュリティ脆弱性について認証モジュール分析"

[Boss] Phase 0: スキャン中... 201 エージェント、148 スキル準備完了.
[Boss] Phase 1: 意図 → セキュリティ分析 | 優先度: P2
[Boss] Phase 2: マッチ → security-reviewer (sonnet)
[Boss] Agent(description="security review", model="sonnet", prompt="
  TASK: src/auth/ を OWASP Top 10 脆弱性について分析.
  MUST DO: SQL インジェクション、XSS、CSRF チェック.
  MUST NOT: ファイル変更.
")
       ↓ 結果返却
[Boss] Phase 4: レポート読み込み中... 2 クリティカル、1 中程度確認. ✓
```

**P3a — Boss ダイレクト 並列:**
```
$ claude "認証をリファクタしてテスト記述"

[Boss] Phase 1: マルチステップ → P3a ダイレクト オーケストレーション
[Boss] 2 エージェント並列スポーン:
  Agent(description="executor refactoring", model="sonnet", run_in_background=true)
  Agent(description="test-engineer tests", model="sonnet", run_in_background=true)
       ↓ 両結果返却
[Boss] Phase 4: リファクタファイル検証中... ✓
[Boss] Phase 4: テスト実行中... 12/12 成功. ✓
```

**P3c — エージェント チーム:**
```
$ claude "支払いモジュール実装とレビュー"

[Boss] Phase 1: エージェント間通信必要 → P3c エージェント チーム
[Boss] TeamCreate → 2 チームメート生成（tmux 分割ペイン）
[Boss] TaskCreate("支払い実装", assignee="executor")
[Boss] TaskCreate("支払いレビュー", assignee="code-reviewer")
[Boss] SendMessage(to: "executor", "Stripe SDK を使用して src/payment/ 実装")

  ┌─ executor (tmux ペイン 1) ──────────────────┐
  │ src/payment/... で作業中                      │
  │ SendMessage(to: "code-reviewer",            │
  │   "実装完了、src/payment/ レビュー")        │
  └─────────────────────────────────────────────┘
  ┌─ code-reviewer (tmux ペイン 2) ─────────────┐
  │ src/payment/checkout.ts レビュー中...        │
  │ SendMessage(to: "executor",                 │
  │   "42 行: エラー ハンドリング欠落")         │
  └─────────────────────────────────────────────┘
  ┌─ executor ──────────────────────────────────┐
  │ 修正完了. TaskUpdate(status: "completed")   │
  └─────────────────────────────────────────────┘

[Boss] すべてのタスク完了 → TeamDelete
```

詳細なエージェント互換性マトリックスおよびチーム通信パターンは、[エージェント チーム リファレンス](agents/core/agent-teams-reference.md)を参照してください。

### スコープ ディスカバリー（グローバル + プロジェクト）

Boss は **2 つのスコープ**からコンポーネントを検出し、ランタイムでマージします:

| スコープ | エージェント | スキル | MCP サーバー |
|-------|--------|--------|-------------|
| **グローバル** | `~/.claude/agents/*.md` | `~/.claude/skills/` | `~/.claude/settings.json` |
| **プロジェクト** | `.claude/agents/*.md` | `.claude/skills/` | `.mcp.json` |

プロジェクト ディレクトリで `claude` を実行するとき、Boss はグローバルとプロジェクト レベルの両コンポーネントを認識します。プロジェクト レベルのエージェントでグローバル同名のものは優先（プロジェクト固有のカスタマイズ）。

---

## エージェント オーバーラップ ガイド

OMC と omo には、重複機能を持つエージェント ペアがあります。両方を保持し、状況に応じて選択してください。

| 機能 | OMC | omo | 選択基準 |
|------|-----|-----|-----------|
| 計画 | planner | Prometheus | クイック タスク → OMC planner、複雑プロジェクト → omo Triad（Metis → Prometheus → Momus） |
| コード レビュー | code-reviewer | Momus | OMC: 重点的レビュー、omo: AI スロップ 検出含む |
| 探索 | explore | Explore | 現在のプラットフォームに属する方を使用 |

**omo 専用エージェント（6）:** Sisyphus、Sisyphus-Junior、Hephaestus、Oracle、Multimodal-Looker、Librarian

**OMC 専用エージェント（14）:** analyst、architect、code-simplifier、critic、debugger、designer、document-specialist、executor、git-master、qa-tester、scientist、test-engineer、verifier、writer

詳細分析は、[SETUP.md の エージェント オーバーラップ 分析](./SETUP.md#11-agent-overlap-analysis-omc-vs-omo)を参照してください。

---

## 貢献

Issues と PR を歓迎します。新しいエージェントを追加するときは、`agents/` ディレクトリに `.md` ファイルを追加し、`SETUP.md` のエージェント リストを更新してください。

---

## バンドル アップストリーム バージョン

[CI オート同期](.github/workflows/sync-upstream.yml)で毎週更新。正確な SHA は `upstream/SOURCES.json` を参照してください。

| ソース | 同期 SHA | タグ | 日付 | Diff |
|--------|-----------|-----|------|------|
| [agency-agents](https://github.com/msitarzewski/agency-agents) | `6254154` | — | 2026-03-18 | [compare](https://github.com/msitarzewski/agency-agents/compare/6254154...HEAD) |
| [everything-claude-code](https://github.com/affaan-m/everything-claude-code) | `fce4513` | — | 2026-03-18 | [compare](https://github.com/affaan-m/everything-claude-code/compare/fce4513...HEAD) |
| [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) | `7d07356` | v4.8.2 | 2026-03-18 | [compare](https://github.com/Yeachan-Heo/oh-my-claudecode/compare/7d07356...HEAD) |

---

## クレジット

このリポジトリは、以下のオープン ソース プロジェクトの成果に基づいています:

- [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) — Yeachan Heo
- [oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent) — code-yeongyu
- [andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills) — forrestchang
- [everything-claude-code](https://github.com/affaan-m/everything-claude-code) — affaan-m
- [anthropic/skills](https://github.com/anthropics/skills) — Anthropic
- [agency-agents](https://github.com/msitarzewski/agency-agents) — msitarzewski

---

## ライセンス

MIT ライセンス。詳細は [LICENSE](./LICENSE) ファイルを参照してください。
