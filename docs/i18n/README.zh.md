[English](../../README.md) | [한국어](./README.ko.md) | [日本語](./README.ja.md) | [中文](./README.zh.md) | [Deutsch](./README.de.md) | [Français](./README.fr.md)

> [![Codex CLI](https://img.shields.io/badge/Codex_CLI-my--codex-10b981?style=flat-square&logo=openai&logoColor=white)](https://github.com/sehoon787/my-codex) 在找 Codex CLI？→ **my-codex** — 同样的编排架构，原生 TOML 格式

---

<div align="center">

# my-claude

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Agents](https://img.shields.io/badge/agents-200%2B-blue)
![Skills](https://img.shields.io/badge/skills-200%2B-purple)
![Rules](https://img.shields.io/badge/rules-87-orange)
![MCP Servers](https://img.shields.io/badge/MCP-3-green)
![Hooks](https://img.shields.io/badge/hooks-7-red)

**Claude Code 的一体化 Agent 框架。**
**一个插件，200+ Agent 随时待命。**

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

### 优先级路由

Boss 对每个请求按优先级链逐级匹配，直到找到最佳方案：

| 优先级 | 匹配类型 | 触发时机 | 示例 |
|:--------:|-----------|------|---------|
| **P1** | Skill 匹配 | 任务对应某个独立 skill | `"merge PDFs"` → pdf skill |
| **P2** | 专家 Agent | 存在领域专属 Agent | `"security audit"` → Security Engineer |
| **P3a** | Boss 直接 | 2-4 个独立 Agent | `"fix 3 bugs"` → parallel spawn |
| **P3b** | 子编排器 | 复杂多步骤工作流 | `"refactor + test"` → Sisyphus |
| **P3c** | Agent 团队 | 需要点对点通信 | `"implement + review"` → Review Chain |
| **P4** | 回退 | 无专家匹配 | `"explain this"` → general agent |

### 模型路由

| 复杂度 | 模型 | 用途 |
|-----------|-------|----------|
| 深度分析、架构 | Opus | Boss、Oracle、Sisyphus |
| 标准实现 | Sonnet | executor、debugger、security-reviewer |
| 快速查询、探索 | Haiku | explore、简单咨询 |

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

---

## 架构

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

## 内容一览

| 类别 | 数量 | 来源 |
|----------|------:|--------|
| **核心 Agent**（始终加载） | 56 | Boss 1 + OMO 9 + OMC 19 + Agency Engineering 26 + Superpowers 1 |
| **Agent 包**（按需加载） | 136 | 来自 agency-agents 的 12 个领域分类 |
| **Skills** | 200+ | ECC 180+ · OMC 36 · gstack 40 · Superpowers 14 · Core 3 |
| **Anthropic Skills** | 14+ | PDF、DOCX、PPTX、XLSX、MCP builder |
| **规则** | 87 | ECC common + 14 个语言目录 |
| **MCP 服务器** | 3 | Context7、Exa、grep.app |
| **Hooks** | 7 | 委派守卫、遥测、验证 |
| **CLI 工具** | 3 | omc、omo、ast-grep |

<details>
<summary><strong>核心 Agent — Boss 元编排器（1）</strong></summary>

| Agent | 模型 | 角色 | 来源 |
|-------|-------|------|--------|
| Boss | Opus | 动态运行时发现 → 能力匹配 → 最优路由。从不编写代码。 | my-claude |

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
<summary><strong>Agency Engineering — 始终加载的专家（26）</strong></summary>

| Agent | 角色 | 来源 |
|-------|------|--------|
| AI Engineer | AI/ML 工程 | [agency-agents](https://github.com/msitarzewski/agency-agents) |
| Backend Architect | 后端架构 | agency-agents |
| CMS Developer | CMS 开发 | agency-agents |
| Code Reviewer | 代码审查 | agency-agents |
| Data Engineer | 数据工程 | agency-agents |
| Database Optimizer | 数据库优化 | agency-agents |
| DevOps Automator | DevOps 自动化 | agency-agents |
| Embedded Firmware Engineer | 嵌入式固件 | agency-agents |
| Frontend Developer | 前端开发 | agency-agents |
| Git Workflow Master | Git 工作流 | agency-agents |
| Incident Response Commander | 事故响应 | agency-agents |
| Mobile App Builder | 移动应用 | agency-agents |
| Rapid Prototyper | 快速原型 | agency-agents |
| Security Engineer | 安全工程 | agency-agents |
| Senior Developer | 高级开发 | agency-agents |
| Software Architect | 软件架构 | agency-agents |
| SRE | 站点可靠性 | agency-agents |
| Technical Writer | 技术文档 | agency-agents |
| AI Data Remediation Engineer | 自愈数据管道 | agency-agents |
| Autonomous Optimization Architect | API 性能治理 | agency-agents |
| Email Intelligence Engineer | 邮件数据提取 | agency-agents |
| Feishu Integration Developer | 飞书 / Lark 平台 | agency-agents |
| Filament Optimization Specialist | Filament PHP 优化 | agency-agents |
| Solidity Smart Contract Engineer | EVM 智能合约 | agency-agents |
| Threat Detection Engineer | SIEM 与威胁狩猎 | agency-agents |
| WeChat Mini Program Developer | WeChat 小程序 | agency-agents |

</details>

<details>
<summary><strong>Agent 包 — 按需领域专家（136）</strong></summary>

安装至 `~/.claude/agent-packs/`。通过软链接激活：

```bash
ln -s ~/.claude/agent-packs/marketing/*.md ~/.claude/agents/
```

| 包 | 数量 | 示例 | 来源 |
|------|------:|---------|--------|
| marketing | 29 | Douyin、Xiaohongshu、TikTok、SEO | [agency-agents](https://github.com/msitarzewski/agency-agents) |
| specialized | 28 | 法律、金融、医疗、MCP Builder | agency-agents |
| game-development | 20 | Unity、Unreal、Godot、Roblox | agency-agents |
| design | 8 | 品牌、UI、UX、视觉叙事 | agency-agents |
| testing | 8 | API、无障碍、性能 | agency-agents |
| sales | 8 | 交易策略、管道分析 | agency-agents |
| paid-media | 7 | Google Ads、Meta Ads、程序化广告 | agency-agents |
| project-management | 6 | Scrum、看板、风险管理 | agency-agents |
| spatial-computing | 6 | visionOS、WebXR、Metal | agency-agents |
| support | 6 | 分析、基础设施、法律 | agency-agents |
| academic | 5 | 人类学家、历史学家、心理学家 | agency-agents |
| product | 5 | 产品经理、冲刺、反馈 | agency-agents |

</details>

<details>
<summary><strong>Skills — 200+ 来自 6 个来源</strong></summary>

| 来源 | 数量 | 核心 Skills |
|--------|------:|------------|
| [everything-claude-code](https://github.com/affaan-m/everything-claude-code) | 180+ | tdd-workflow、autopilot、ralph、security-review、coding-standards |
| [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) | 36 | plan、team、trace、deep-dive、blueprint、ultrawork |
| [gstack](https://github.com/garrytan/gstack) | 40 | /qa、/review、/ship、/cso、/investigate、/office-hours |
| [superpowers](https://github.com/obra/superpowers) | 14 | brainstorming、systematic-debugging、TDD、parallel-agents |
| [my-claude Core](https://github.com/sehoon787/my-claude) | 3 | boss-advanced、gstack-sprint、briefing-vault |
| [Anthropic Official](https://github.com/anthropics/skills) | 14+ | pdf、docx、pptx、xlsx、canvas-design、mcp-builder |

</details>

<details>
<summary><strong>MCP 服务器（3）+ Hooks（7）</strong></summary>

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
│   ├── YYYY-MM-DD-<decision>.md     ← AI-written decision record
│   └── YYYY-MM-DD-auto.md           ← Auto-generated scaffold (commits, files)
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

### 自动化生命周期

| 阶段 | Hook 事件 | 发生的事情 |
|-------|-----------|-------------|
| **会话开始** | `SessionStart` | 创建 `.briefing/` 结构，保存 git HEAD 哈希用于会话专属差异 |
| **工作期间** | `PostToolUse` Edit/Write | 追踪文件编辑次数；达到 5 次警告，达到 15 次且未写决策 / 学习时阻止 |
| **工作期间** | `PostToolUse` WebSearch/WebFetch | 自动将 URL 收集到 `references/auto-links.md` |
| **工作期间** | `SubagentStop` | 将 Agent 执行记录到 `agents/agent-log.jsonl` |
| **工作期间** | `UserPromptSubmit`（每 5 次） | 节流更新个性化档案 |
| **会话结束** | `Stop`（第 1 个 hook） | 自动生成脚手架：`sessions/auto.md`、`learnings/auto-session.md`、`decisions/auto.md`、`persona/profile.md` |
| **会话结束** | `Stop`（第 2 个 hook） | 若文件编辑 ≥ 3 次则**强制** AI 撰写会话摘要——以模板阻止会话结束 |

### 自动生成 vs AI 撰写

| 类型 | 文件模式 | 创建者 | 内容 |
|------|-------------|-----------|---------|
| **自动脚手架** | `*-auto.md`、`*-auto-session.md` | Stop hook（Node.js） | Git 差异统计、Agent 使用情况、提交列表——仅数据 |
| **AI 摘要** | `YYYY-MM-DD-<topic>.md` | 会话中的 AI | 有意义的分析，包含上下文、代码引用、理由 |
| **遥测** | `agent-log.jsonl`、`auto-links.md` | Hook 脚本 | 仅追加的结构化日志 |
| **个性化** | `profile.md`、`suggestions.jsonl` | Stop hook | 基于使用的 Agent 偏好和路由建议 |

自动脚手架作为 AI 撰写正式摘要的**参考数据**。强制 hook 在阻止会话结束时提供脚手架内容和结构化模板。

### 会话专属差异

在会话开始时，当前 git HEAD 保存到 `.briefing/.session-start-head`。会话结束时，差异相对于此保存点计算——仅显示当前会话的变更，而非之前会话积累的未提交变更。

### 与 Obsidian 配合使用

1. Open Obsidian → **Open folder as vault** → 选择 `.briefing/`
2. 笔记显示在图谱视图中，通过 `[[wiki-links]]` 关联
3. YAML frontmatter（`date`、`type`、`tags`）支持结构化搜索
4. 决策与学习的时间线跨会话自动积累

---

## 上游开源来源

my-claude 通过 git 子模块捆绑了 5 个 MIT 授权的上游仓库的内容：

| # | 来源 | 提供的内容 |
|---|--------|-----------------|
| 1 | <img src="https://github.com/Yeachan-Heo.png?size=32" width="20" height="20" align="center"/> **[oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode)** — Yeachan Heo | 19 个专家 Agent + 36 个 skills。Claude Code 多 Agent 框架，含 autopilot、ralph、团队编排。 |
| 2 | <img src="https://github.com/code-yeongyu.png?size=32" width="20" height="20" align="center"/> **[oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent)** — code-yeongyu | 9 个 OMO Agent（Sisyphus、Atlas、Oracle 等）。支持 Claude、GPT、Gemini 的多平台 Agent 框架。 |
| 3 | <img src="https://github.com/affaan-m.png?size=32" width="20" height="20" align="center"/> **[everything-claude-code](https://github.com/affaan-m/everything-claude-code)** — affaan-m | 180+ 个 skills + 87 条规则，覆盖 14 种语言。全面的开发框架，包含 TDD、安全和编码标准。 |
| 4 | <img src="https://github.com/msitarzewski.png?size=32" width="20" height="20" align="center"/> **[agency-agents](https://github.com/msitarzewski/agency-agents)** — msitarzewski | 26 个工程 Agent（始终加载）+ 12 个分类共 136 个领域 Agent 包。 |
| 5 | <img src="https://github.com/garrytan.png?size=32" width="20" height="20" align="center"/> **[gstack](https://github.com/garrytan/gstack)** — garrytan | 40 个用于代码审查、QA、安全审计、部署的 skills。包含 Playwright 浏览器守护进程。 |
| 6 | <img src="https://github.com/obra.png?size=32" width="20" height="20" align="center"/> **[superpowers](https://github.com/obra/superpowers)** — Jesse Vincent | 14 个 skills + 1 个 Agent，覆盖头脑风暴、TDD、并行 Agent 和代码审查。 |
| 7 | <img src="https://www.anthropic.com/favicon.ico" width="20" height="20" align="center"/> **[anthropic/skills](https://github.com/anthropics/skills)** — Anthropic | 14+ 个官方 skills，用于 PDF、DOCX、PPTX、XLSX 和 MCP builder。 |
| 8 | <img src="https://github.com/forrestchang.png?size=32" width="20" height="20" align="center"/> **[andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills)** — forrestchang | 4 条 AI 编码行为准则（先思考再编码、简洁优先、精准修改、目标驱动执行）。 |

---

## GitHub Actions

| 工作流 | 触发条件 | 用途 |
|----------|---------|---------|
| **CI** | push、PR | 验证 JSON 配置、Agent frontmatter、skill 存在性、上游文件数量 |
| **Update Upstream** | 每周 / 手动 | 运行 `git submodule update --remote` 并创建自动合并 PR |
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
| **Agent 层级优先级** | core > omo > omc > agency 去重。最专业的 Agent 优先。 |
| **Agency 成本优化** | 咨询用 Haiku，实现用 Sonnet——172 个领域 Agent 自动模型路由 |
| **Briefing Vault** | 兼容 Obsidian 的 `.briefing/` 目录，含会话、决策、学习、参考资料 |
| **Agent 遥测** | PostToolUse hook 将 Agent 使用情况记录到 `agent-usage.jsonl` |
| **智能包** | 项目类型检测在会话开始时推荐相关 Agent 包 |
| **CI SHA 预检** | 上游同步通过 `git ls-remote` SHA 对比跳过未变更来源 |
| **Agent 重复检测** | 规范化名称对比检测跨上游来源的重复项 |

---

## 捆绑的上游版本

通过 git 子模块链接。固定提交由 `.gitmodules` 原生追踪。

| 来源 | SHA | 日期 | 差异 |
|--------|-----|------|------|
| [agency-agents](https://github.com/msitarzewski/agency-agents) | `4feb0cd` | 2026-04-07 | [compare](https://github.com/msitarzewski/agency-agents/compare/4feb0cd...HEAD) |
| [everything-claude-code](https://github.com/affaan-m/everything-claude-code) | `7dfdbe0` | 2026-04-07 | [compare](https://github.com/affaan-m/everything-claude-code/compare/7dfdbe0...HEAD) |
| [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) | `2487d38` | 2026-04-07 | [compare](https://github.com/Yeachan-Heo/oh-my-claudecode/compare/2487d38...HEAD) |
| [gstack](https://github.com/garrytan/gstack) | `03973c2` | 2026-04-07 | [compare](https://github.com/garrytan/gstack/compare/03973c2...HEAD) |
| [superpowers](https://github.com/obra/superpowers) | `b7a8f76` | 2026-04-06 | [compare](https://github.com/obra/superpowers/compare/b7a8f76...HEAD) |

---

## 贡献

欢迎提交 Issue 和 PR。添加新 Agent 时，请在 `agents/core/` 或 `agents/omo/` 中添加 `.md` 文件并更新 `SETUP.md`。

## 致谢

本项目基于以下工作构建：[oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode)（Yeachan Heo）、[oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent)（code-yeongyu）、[everything-claude-code](https://github.com/affaan-m/everything-claude-code)（affaan-m）、[agency-agents](https://github.com/msitarzewski/agency-agents)（msitarzewski）、[gstack](https://github.com/garrytan/gstack)（garrytan）、[superpowers](https://github.com/obra/superpowers)（Jesse Vincent）、[anthropic/skills](https://github.com/anthropics/skills)（Anthropic）、[andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills)（forrestchang）。

## 许可证

MIT 许可证。详情请参阅 [LICENSE](./LICENSE) 文件。
