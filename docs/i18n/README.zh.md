[English](../../README.md) | [한국어](./README.ko.md) | [日本語](./README.ja.md) | [中文](./README.zh.md) | [Deutsch](./README.de.md) | [Français](./README.fr.md)

> [![Codex CLI](https://img.shields.io/badge/Codex_CLI-my--codex-10b981?style=flat-square&logo=openai&logoColor=white)](https://github.com/sehoon787/my-codex) 在找 Codex CLI？→ **my-codex** — 同样的编排架构，原生 TOML 格式

---

<div align="center">

# my-claude

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Agents](https://img.shields.io/badge/agents-32-blue)
![Skills](https://img.shields.io/badge/skills-139-purple)
![Rules](https://img.shields.io/badge/rules-54-orange)
![MCP Servers](https://img.shields.io/badge/MCP-3-green)
![Hooks](https://img.shields.io/badge/hooks-9-red)
![LSP Servers](https://img.shields.io/badge/LSP-2-008b8b)
![Workflows](https://img.shields.io/badge/workflows-2-blueviolet)

**Claude Code 的一体化 Agent 框架。**
**一个插件，32 个精选 Agent 随时待命。**

Boss 在运行时自动发现所有 Agent、Skill 和 MCP 工具，<br>
并将任务路由到最合适的专家。无需配置文件，无需样板代码。

<img src="./assets/owl-claude-social.svg" alt="The Maestro Owl — my-claude" width="700">

</div>

---

## 安装

### 面向用户

```bash
git clone --depth 1 https://github.com/sehoon787/my-claude.git /tmp/my-claude
bash /tmp/my-claude/install.sh
rm -rf /tmp/my-claude
```

或者先作为 Claude Code 插件安装，再运行配套安装器：

```bash
# Inside a Claude Code session:
/plugin marketplace add sehoon787/my-claude
/plugin install my-claude@my-claude

# Then install companion tools:
git clone --depth 1 https://github.com/sehoon787/my-claude.git /tmp/my-claude
bash /tmp/my-claude/install.sh
rm -rf /tmp/my-claude
```

### 面向 AI Agent

```bash
curl -s https://raw.githubusercontent.com/sehoon787/my-claude/main/AI-INSTALL.md
```

阅读完整输出，然后按顺序执行每个步骤。请使用 `curl`，而非 `WebFetch`。

---

## Boss 的工作原理

Boss 是 my-claude 的核心元编排器。它从不编写代码——它负责发现、分类、匹配、委派和验证。

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

### 优先级路由

Boss 对每个请求按优先级链逐级匹配，直到找到最佳方案：

| 优先级 | 匹配类型 | 触发时机 | 示例 |
|:--------:|-----------|------|---------|
| **P0** | gstack Skill | 发布 / QA / 部署 / 安全流程 | `"ship this"` → gstack `/ship` |
| **P1** | Skill 匹配 | 任务对应某个独立 skill | `"merge PDFs"` → pdf skill |
| **P2** | 专家 Agent | 存在领域专属 Agent | `"security audit"` → security-reviewer |
| **P3a** | Boss 直接 | 2-4 个独立 Agent | `"fix 3 bugs"` → parallel spawn |
| **P3b** | 子编排器 | 复杂多步骤工作流 | `"refactor + test"` → Sisyphus |
| **P3c** | Agent 团队 | 需要点对点通信 | `"implement + review"` → Review Chain |
| **P4** | 回退 | 无专家匹配 | `"explain this"` → general agent |

### 模型路由

| 复杂度 | 模型 | 用途 |
|-----------|-------|----------|
| 顶层编排 | `claude-fable-5-1` | Boss |
| 深度分析、架构 | `claude-opus-5` | Sisyphus、Atlas、Hephaestus、Oracle、Metis、Momus、Prometheus |
| 标准实现 | `claude-sonnet-5` | Librarian、Multimodal-Looker、OMC 专家 Agent |
| 快速查询、探索 | `claude-haiku-4-5` | 轻量 OMC Agent、简单咨询 |

### Effort 分级

模型决定*由哪个大脑*执行任务，`effort:` frontmatter 字段则决定*思考多深*。所有自有 Agent 都声明该字段。

| Effort | Agent |
|--------|--------|
| `xhigh` | Boss、Oracle、Prometheus、Multi-Agent Systems Architect |
| `high` | Sisyphus、Hephaestus、Atlas、Metis、Momus |
| `medium` | Librarian、Multimodal-Looker、AI Engineer、DevOps Automator |

Skills 同样可以声明 effort —— `boss-briefing` 为 `medium`，`briefing-vault` 为 `low`。`boss-advanced` 与 `gstack-sprint` 刻意不声明：Skill 的 effort 会在调用期间覆盖会话级别，一旦声明就会在任务中途悄悄降低 Boss 的 effort。

优先级：`CLAUDE_CODE_EFFORT_LEVEL`（环境变量）> frontmatter > 会话 effort 级别。`xhigh` 是 Fable 支持的上限；`max` 仅限 opus 级模型，在其他模型上会静默回退。

### 三阶段冲刺工作流

对于端到端功能实现，Boss 编排结构化冲刺：

```
Phase 1: DESIGN         Phase 2: EXECUTE        Phase 3: REVIEW
(interactive)            (autonomous)             (interactive)
─────────────────────   ─────────────────────   ─────────────────────
User decides scope      ralph runs execution    Compare vs design doc
Engineering review      Auto code review        Present comparison table
Confirm "design done"   Architect verification  User: approve / improve
```

### 结构化最终报告

Boss 会以一份无需打开 diff 即可浏览的结构化最终报告来结束每个有实际工作的回合 — 即编辑/创建了文件、进行了提交/PR/合并、更改了配置或执行了验证的回合。报告由 5 个固定表格组成，每个表格仅在对应情况确实发生时才输出（绝不输出空表）:

| 情况 | 表格 | 列 |
|-----------|-------|---------|
| 文件/设置变更 | 변경 대조 (Changes) | 대상 / Before / After / 근거 |
| 完成多项任务 | 작업 요약 (Work summary) | 항목 / 결과 / 근거 |
| 执行了验证 | 검증 결과 (Verification) | 항목 / 기대 / 실제 / 판정 |
| 产出提交/PR | 산출물 (Deliverables) | PR / 저장소 / 내용 / 상태 |
| 存在未解决项 | 남은 것 (Remaining) | 항목 / 상태 / 다음 조치 |

该报告仅在推理的最末尾触发 — 绝不会作为任务中途的进度更新输出 — 纯问答回合则正常结束、不生成报告。规范位于 `boss.md § FINAL REPORT`，由 `stop-final-report.js` Stop 钩子强制执行。

### 具名工作流

确定性的多 Agent 工作流。`install.sh` 会把它们复制到 `~/.claude/workflows/`，因此不限于本仓库，在任意项目中都能通过 Workflow 工具调用。

| 工作流 | 作用 | 调用方式 |
|--------|------|----------|
| **code-review-fanout** | 4 个维度的审查者（正确性、安全性、性能、测试）并行展开，每条发现在上报前都经过对抗性验证 | `Workflow({name: "code-review-fanout"})` —— 参数：审查目标（分支、提交范围、路径），默认为工作区 diff |
| **upstream-audit** | 每个上游一名分析者（Pin 差异、允许列表契合度、新增重叠、安全信号、健康度），最后汇总成行动清单 | `Workflow({name: "upstream-audit"})` —— 用于季度审计或同步前审计 |

---

## 架构

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

## 内容一览

| 类别 | 数量 | 来源 |
|----------|------:|--------|
| **Agent**（始终加载） | 32 | Boss 1 + OMO 9 + OMC 19 + Vendored 3 |
| **Skills** | 139 | ECC 79 · gstack 27 · OMC 16 · Superpowers 13 · Core 4 |
| **规则** | 54 个文件 / 9 个规则集 | ECC 53（common + 8 个语言目录）+ Core 1 |
| **MCP 服务器** | 3 | Context7、Exa、grep.app |
| **Hooks** | 8 个文件 / 8 个事件 | 委派守卫、遥测、验证、知识库 |
| **LSP 服务器** | 2 | typescript（`typescript-language-server`）、python（`pyright-langserver`） |
| **具名工作流** | 2 | code-review-fanout、upstream-audit |
| **上游子模块** | 4 | ecc、omc、gstack、superpowers |
| **CLI 工具** | 5 | omc、omo、ast-grep、comment-checker、codeburn |

以上 Agent、Skills、规则全部登记在 [`scripts/skill-allowlists.sh`](../../scripts/skill-allowlists.sh) 的白名单中，并由安装清单跟踪。Anthropic 官方文档 Skills（pdf、docx 等）通过 `claude plugin add anthropics/skills` 单独安装，有意不纳入清单跟踪。

<details>
<summary><strong>核心 Agent — Boss 元编排器（1）</strong></summary>

| Agent | 模型 | 角色 | 来源 |
|-------|-------|------|--------|
| Boss | Fable | 动态运行时发现 → 能力匹配 → 最优路由。从不编写代码。 | my-claude |

</details>

<details>
<summary><strong>OMO Agents — 子编排器与专家（9）</strong></summary>

| Agent | 模型 | 角色 | 来源 |
|-------|-------|------|--------|
| Sisyphus | Opus | 意图分类 → 专家委派 → 验证 | [oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent) |
| Hephaestus | Opus | 自主探索 → 规划 → 执行 → 验证 | oh-my-openagent |
| Atlas | Opus | 任务分解 + 四阶段 QA 验证 | oh-my-openagent |
| Oracle | Opus | 战略技术咨询（只读） | oh-my-openagent |
| Metis | Opus | 意图分析、歧义检测 | oh-my-openagent |
| Momus | Opus | 计划可行性评审 | oh-my-openagent |
| Prometheus | Opus | 基于访谈的详细规划 | oh-my-openagent |
| Librarian | Sonnet | 通过 MCP 搜索开源文档 | oh-my-openagent |
| Multimodal-Looker | Sonnet | 图像 / 截图 / 图表分析 | oh-my-openagent |

</details>

<details>
<summary><strong>OMC Agents — 专家工作者（19）</strong></summary>

| Agent | 角色 | 来源 |
|-------|------|--------|
| analyst | 规划前预分析 | [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) |
| architect | 系统设计与架构 | oh-my-claudecode |
| code-reviewer | 专注代码审查 | oh-my-claudecode |
| code-simplifier | 代码简化与清理 | oh-my-claudecode |
| critic | 批判性分析、替代方案提议 | oh-my-claudecode |
| debugger | 专注调试 | oh-my-claudecode |
| designer | UI/UX 设计指导 | oh-my-claudecode |
| document-specialist | 文档撰写 | oh-my-claudecode |
| executor | 任务执行 | oh-my-claudecode |
| explore | 代码库探索 | oh-my-claudecode |
| git-master | Git 工作流管理 | oh-my-claudecode |
| planner | 快速规划 | oh-my-claudecode |
| qa-tester | 质量保证测试 | oh-my-claudecode |
| scientist | 研究与实验 | oh-my-claudecode |
| security-reviewer | 安全审查 | oh-my-claudecode |
| test-engineer | 测试编写与维护 | oh-my-claudecode |
| tracer | 执行追踪与分析 | oh-my-claudecode |
| verifier | 最终验证 | oh-my-claudecode |
| writer | 内容与文档 | oh-my-claudecode |

</details>

<details>
<summary><strong>Vendored Agent — AI 与基础设施专家（3）</strong></summary>

在 2026-07-27 移除 `agency-agents` 子模块时，从 [agency-agents](https://github.com/msitarzewski/agency-agents)（MIT）快照而来。仅保留栈内没有替代者的工程 Agent，每个文件都保留了上游署名。

| Agent | 角色 | 来源 |
|-------|------|--------|
| AI Engineer | AI/ML 工程、模型集成、数据管道 | agency-agents（vendored） |
| DevOps Automator | 基础设施自动化、CI/CD、云运维 | agency-agents（vendored） |
| Multi-Agent Systems Architect | Agent 拓扑、上下文管理、故障恢复 | agency-agents（vendored） |

</details>

<details>
<summary><strong>Skills — 139 个，来自 5 个来源</strong></summary>

每个来源都由 [`scripts/skill-allowlists.sh`](../../scripts/skill-allowlists.sh) 白名单管理，未列入的 Skills 一律不安装。

| 来源 | 数量 | 核心 Skills |
|--------|------:|------------|
| [everything-claude-code](https://github.com/affaan-m/everything-claude-code) | 79 | coding-standards、react-patterns、fastapi-patterns、agent-architecture-audit、e2e-testing |
| [gstack](https://github.com/garrytan/gstack) | 27 | /qa、/review、/ship、/cso、/investigate、/office-hours |
| [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) | 16 | autopilot、ralph、team、ultrawork、ralplan、omc-reference |
| [superpowers](https://github.com/obra/superpowers) | 13 | brainstorming、systematic-debugging、test-driven-development、writing-plans |
| [my-claude Core](https://github.com/sehoon787/my-claude) | 4 | boss-advanced、boss-briefing、briefing-vault、gstack-sprint |

</details>

<details>
<summary><strong>MCP 服务器（3）+ Hooks（8）</strong></summary>

**MCP 服务器**

| 服务器 | 用途 | 费用 |
|--------|---------|------|
| <img src="https://context7.com/favicon.ico" width="16" height="16" align="center"/> [Context7](https://mcp.context7.com) | 实时库文档 | 免费 |
| <img src="https://exa.ai/images/favicon-32x32.png" width="16" height="16" align="center"/> [Exa](https://mcp.exa.ai) | 语义网页搜索 | 每月免费 1k 次请求 |
| <img src="https://www.google.com/s2/favicons?domain=grep.app&sz=32" width="16" height="16" align="center"/> [grep.app](https://mcp.grep.app) | GitHub 代码搜索 | 免费 |

**行为 Hooks**

| Hook | 事件 | 行为 |
|------|-------|----------|
| Session Setup | SessionStart | 自动检测缺失工具 + 注入 Briefing Vault 上下文 |
| Delegation Guard | PreToolUse | 阻止 Boss 直接修改文件 |
| Agent Telemetry | PostToolUse | 将 Agent 使用情况记录到 `agent-usage.jsonl` |
| Subagent Verifier | SubagentStop | 强制独立验证 + 记录到 Briefing Vault |
| Completion Check | Stop | 确认任务已验证 + 提示会话摘要 |
| Teammate Idle Guide | TeammateIdle | 提示领导者关注空闲队友 |
| Task Quality Gate | TaskCompleted | 验证交付物质量 |
| Vault Reminder | UserPromptSubmit | 超过 5 条消息后提示运行 /boss-briefing |

</details>

<details>
<summary><strong>LSP 服务器（2）</strong></summary>

插件在 `.lsp.json` 中声明了两个语言服务器。Claude Code 按需启动它们，Agent 无需跑一遍构建即可获得诊断与代码导航。

| 服务器 | 命令 | 扩展名 |
|--------|------|--------|
| typescript | `typescript-language-server --stdio` | `.ts` `.tsx` `.js` `.jsx` `.mjs` `.cjs` |
| python | `pyright-langserver --stdio` | `.py` |

`install.sh` 以非致命方式安装这两个二进制文件 —— 若其中一个不可用，仅禁用对应的服务器，其余安装照常进行。

</details>

---

## <img src="https://obsidian.md/images/obsidian-logo-gradient.svg" width="24" height="24" align="center"/> Briefing Vault

兼容 Obsidian 的持久化记忆。每个项目维护一个 `.briefing/` 目录，跨会话自动填充。

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
├── archives/                        ← 已完成/不活跃的笔记 (30天+)
│   ├── sessions/
│   ├── decisions/
│   └── learnings/
└── wiki/                            ← 概念页面 (自动建议)
    └── _schema.md
```

### 子 Vault

| 路径 | 说明 |
|------|------|
| `INDEX.md` | 项目概览，含最近决策和学习的链接。首次会话自动创建，定期刷新。 |
| `sessions/` | **会话摘要。** `*-auto.md` — 含 git diff 统计和 Agent 计数的脚手架。`<topic>.md` — 由 hook 强制的 AI 撰写摘要。 |
| `decisions/` | **架构和设计决策**，含理由。AI 撰写，工作期间强制。 |
| `learnings/` | **模式、注意事项、非显而易见的解决方案。** `*-auto-session.md` — 文件列表脚手架。`<topic>.md` — AI 撰写。 |
| `references/` | **网络调研 URL。** `auto-links.md` — 从 WebSearch/WebFetch 调用自动收集。 |
| `agents/` | **Agent 遥测。** `agent-log.jsonl` — 每次调用日志。`YYYY-MM-DD-summary.md` — 每日使用汇总。 |
| `persona/` | **用户工作风格档案。** `profile.md` — 工具偏好统计。`suggestions.jsonl` — 路由建议。`rules/`、`skills/` — 已接受的偏好。 |
| `archives/` | **已完成/不活跃的笔记。** 超过 30 天的笔记为存档候选。PARA 方法中的 Archives 概念。扁平结构，通过 frontmatter 中的 `type:` 字段识别原始分类。 |
| `wiki/` | **概念 Wiki 页面。** 出现 3 次以上的关键词会触发自动建议。采用 LLM-wiki 概念，`_schema.md` 定义格式规范。 |

### 知识管理 (v2)

BriefingVault v2 融合了三种知识管理方法论：

| 方法论 | 概念 | 在 BriefingVault 中的应用 |
|--------|------|--------------------------|
| **PARA** (Tiago Forte) | 按可执行性分类：Projects、Areas、Resources、Archives | sessions/ = Projects，decisions/ = Areas，references/ = Resources，archives/ = Archives |
| **Zettelkasten** (Luhmann) | 具有唯一 ID 和显式链接的原子笔记 | learnings/ 文件：`YYYYMMDDHHMMSS` ID，`related:` 至少需要 2 个链接 |
| **LLM-wiki** (Karpathy) | 由 AI 从源笔记维护的概念页面 | wiki/ 页面：关键词出现 3 次以上时自动建议 |

### 会话专属差异

在会话开始时，当前 git HEAD 保存到 `.briefing/.session-start-head`。会话结束时，差异相对于此保存点计算——仅显示当前会话的变更，而非之前会话积累的未提交变更。

### 与 Obsidian 配合使用

1. Open Obsidian → **Open folder as vault** → 选择 `.briefing/`
2. 笔记显示在图谱视图中，通过 `[[wiki-links]]` 关联
3. YAML frontmatter（`date`、`type`、`tags`）支持结构化搜索
4. 决策与学习的时间线跨会话自动积累

---

## 上游开源来源

my-claude 以 git 子模块方式关联 4 个 MIT 授权的上游仓库，每个都固定在明确的 SHA 上：

| # | 来源 | 提供的内容 |
|---|--------|-----------------|
| 1 | <img src="https://github.com/affaan-m.png?size=32" width="20" height="20" align="center"/> **[everything-claude-code](https://github.com/affaan-m/everything-claude-code)** — affaan-m | 安装 79 个 skills + 9 个规则集。语言与技术栈知识通道：TDD、安全、编码标准、框架模式。 |
| 2 | <img src="https://github.com/Yeachan-Heo.png?size=32" width="20" height="20" align="center"/> **[oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode)** — Yeachan Heo | 19 个专家 Agent + 安装 16 个 skills。编排通道：autopilot、ralph、team。 |
| 3 | <img src="https://github.com/garrytan.png?size=32" width="20" height="20" align="center"/> **[gstack](https://github.com/garrytan/gstack)** — garrytan | 安装 27 个 skills，用于发布、QA、部署与安全审查（Boss P0 通道）。含 Playwright 浏览器守护进程。 |
| 4 | <img src="https://github.com/obra.png?size=32" width="20" height="20" align="center"/> **[superpowers](https://github.com/obra/superpowers)** — Jesse Vincent | 安装 13 个 skills，覆盖开发流程通道：头脑风暴、TDD、系统化调试、计划撰写。 |

并非子模块，但同属这套技术栈：

| 来源 | 接入方式 |
|--------|----------------|
| <img src="https://github.com/code-yeongyu.png?size=32" width="20" height="20" align="center"/> **[oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent)** — code-yeongyu | 9 个 OMO Agent（Sisyphus、Atlas、Oracle 等），已移植为本仓库 `agents/omo/` 下的独立 `.md` Agent。 |
| <img src="https://github.com/msitarzewski.png?size=32" width="20" height="20" align="center"/> **[agency-agents](https://github.com/msitarzewski/agency-agents)** — msitarzewski | 2026-07-27 移除子模块。3 个工程 Agent 连同署名一并 vendored 到 `agents/vendored/`。 |
| <img src="https://www.anthropic.com/favicon.ico" width="20" height="20" align="center"/> **[anthropic/skills](https://github.com/anthropics/skills)** — Anthropic | 由 `install.sh` 通过 `claude plugin add anthropics/skills` 安装（pdf、docx 等）。不纳入清单跟踪。 |
| <img src="https://github.com/forrestchang.png?size=32" width="20" height="20" align="center"/> **[andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills)** — forrestchang | 4 条 AI 编码行为准则，追加到 `~/.claude/CLAUDE.md`。 |
| <img src="https://github.com/getagentseal.png?size=32" width="20" height="20" align="center"/> **[codeburn](https://github.com/getagentseal/codeburn)** — getagentseal | npm CLI (MIT)。本地优先的 token/成本追踪器 — 只读解析 Claude Code 已写出的会话文件，按模型、项目、任务汇总花费。无代理、无 API 密钥、不上传。由 `install.sh` 以 `codeburn@0.9.23` 固定版本安装，并在 `upstream/SOURCES.json` 中以 `method: npm-cli` 登记。预算守卫钩子通过 `--with-codeburn-guard` 选择启用。与 OMC HUD（当前会话的上下文与配额）互补，展示跨会话的花费去向。 |

---

## GitHub Actions

| 工作流 | 触发条件 | 用途 |
|----------|---------|---------|
| **CI** | push、PR | 验证 JSON 配置、Agent frontmatter、skill 存在性、上游文件数量 |
| **Smoke** | push、PR | 4 个 job — `hooks`（钩子执行）、`shell`（安装脚本形态）、`drift`（模型漂移）、`routing-refs`（失效的 Agent/Skill 引用） |
| **Update Upstream** | 每 3 天 / 手动 | `git submodule update --remote` → 刷新 `SOURCES.json` 的 SHA 固定 → 上游 diff 安全扫描 → 扫描通过才自动合并，否则保留 PR 供人工复核 |
| **Auto Tag** | push 到 main | 读取 `plugin.json` 版本并在有新版本时创建 git tag |
| **Pages** | push 到 main | 将 `docs/index.html` 部署到 GitHub Pages |
| **CLA** | PR | 贡献者许可协议检查 |
| **Lint Workflows** | push、PR | 验证 GitHub Actions 工作流 YAML 语法 |

---

## my-claude 原创功能

专为本项目构建、超出上游来源的功能：

| 功能 | 描述 |
|---------|-------------|
| **Boss 元编排器** | 动态能力发现 → 意图分类 → 5 级优先路由 → 委派 → 验证 |
| **三阶段冲刺** | 设计（交互式）→ 执行（通过 ralph 自主进行）→ 审查（交互式对比设计文档） |
| **Agent 层级优先级** | core > omo > omc > vendored 去重。最专业的 Agent 优先。 |
| **通道归属** | 编排 → OMC，开发流程 → superpowers，发布/QA/部署/安全 → gstack（Boss P0），语言与技术栈知识 → ECC，AI 与领域 → vendored Agent |
| **精选白名单** | `scripts/skill-allowlists.sh` 是唯一事实来源——上游数千项中只留下 139 个 Skills 和 9 个规则集，未列入的绝不进入会话上下文 |
| **Briefing Vault** | 兼容 Obsidian 的 `.briefing/` 目录，含会话、决策、学习、参考资料 |
| **Agent 遥测** | PostToolUse hook 将 Agent 使用情况记录到 `agent-usage.jsonl` |
| **智能包** | 项目类型检测在会话开始时推荐相关 Agent 包 |
| **无变更同步跳过** | 上游同步先暂存子模块升级与 `SOURCES.json` 固定，只有该 diff 非空时才创建 PR |
| **Agent 重复检测** | `tests/validate-sync.sh` 比对 `agents/` 与 omc、superpowers 子模块中的 Agent 文件名并报告冲突 |

---

## 捆绑的上游版本

通过 git 子模块链接。固定提交由 `.gitmodules` 原生追踪，并以 AI-BOM 形式镜像在 [`upstream/SOURCES.json`](../../upstream/SOURCES.json) 中。`install.sh` 直接检出下列 SHA，而不是跟踪 `main`。

| 来源 | SHA | 日期 | 差异 |
|--------|-----|------|------|
| [everything-claude-code](https://github.com/affaan-m/everything-claude-code) | `4092795` | 2026-07-27 | [compare](https://github.com/affaan-m/everything-claude-code/compare/4092795...HEAD) |
| [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) | `590fb98` | 2026-07-27 | [compare](https://github.com/Yeachan-Heo/oh-my-claudecode/compare/590fb98...HEAD) |
| [gstack](https://github.com/garrytan/gstack) | `7c9df1c` | 2026-07-27 | [compare](https://github.com/garrytan/gstack/compare/7c9df1c...HEAD) |
| [superpowers](https://github.com/obra/superpowers) | `3dcbd5c` | 2026-07-27 | [compare](https://github.com/obra/superpowers/compare/3dcbd5c...HEAD) |

---

## 贡献

欢迎提交 Issue 和 PR。添加新 Agent 时，请在 `agents/core/` 或 `agents/omo/` 中添加 `.md` 文件并更新 `SETUP.md`。

## 致谢

本项目基于以下工作构建：[oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode)（Yeachan Heo）、[oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent)（code-yeongyu）、[everything-claude-code](https://github.com/affaan-m/everything-claude-code)（affaan-m）、[gstack](https://github.com/garrytan/gstack)（garrytan）、[superpowers](https://github.com/obra/superpowers)（Jesse Vincent）、[agency-agents](https://github.com/msitarzewski/agency-agents)（msitarzewski — 3 个 vendored Agent）、[anthropic/skills](https://github.com/anthropics/skills)（Anthropic）、[andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills)（forrestchang）。

## 许可证

MIT 许可证。详情请参阅 [LICENSE](./LICENSE) 文件。
