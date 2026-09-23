[English](../../README.md) | [한국어](./README.ko.md) | [日本語](./README.ja.md) | [中文](./README.zh.md) | [Deutsch](./README.de.md) | [Français](./README.fr.md)

> [![Codex CLI](https://img.shields.io/badge/Codex_CLI-my--codex-10b981?style=flat-square&logo=openai&logoColor=white)](https://github.com/sehoon787/my-codex) 在找 Codex CLI？→ **my-codex** — 同样的编排架构，原生 TOML 格式

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

**Claude Code 的一体化 Agent 框架。**
**一个插件，32 个精选 Agent 随时待命。**

Boss 在运行时自动发现所有 Agent、Skill 和 MCP 工具，<br>
并将任务路由到最合适的专家。无需配置文件，无需样板代码。

<img src="../../assets/owl-claude-social.svg" alt="The Maestro Owl — my-claude" width="700">

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

安装程序为 my-claude 和 my-codex 提供一套共享的 codeburn 仪表盘与 Headroom 代理。后续安装会复用健康服务，不会重复启动。状态和启动日志位于 `${XDG_STATE_HOME:-$HOME/.local/state}/agent-harness-services`；安装程序不会修改 `ANTHROPIC_BASE_URL` 或 `OPENAI_BASE_URL`。

### 面向 AI Agent

```bash
curl -s https://raw.githubusercontent.com/sehoon787/my-claude/main/AI-INSTALL.md
```

阅读完整输出，然后按顺序执行每个步骤。请使用 `curl`，而非 `WebFetch`。

在运行安装程序之前，代理会询问要安装哪些配套工具（Serena、Headroom、codeburn），因为交互式复选框菜单仅在交互式终端中出现。

---

<a id="open-source-tools-used"></a>

## 使用的开源工具

这套栈所依赖的每个项目，都只在这里描述一次。
其中 5 个 MIT 许可的上游以 git 子模块方式链接并固定到明确的 SHA；
其余则以版本固定的 CLI、托管 MCP 服务器，或带署名收录的文件形式引入。

| # | 项目 | my-claude 从中获得什么 | 引入方式 |
|---|------|------------------------|----------|
| 1 | <img src="https://github.com/Yeachan-Heo.png?size=32" width="20" height="20" align="center"/> **[oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode)** (OMC) — Yeachan Heo | 19 个按角色分工的专家 Agent（architect、debugger、code reviewer、security reviewer 等），以及 autopilot、ralph、team 等 16 个编排 Skills。`autopilot:` 这类魔法关键词会触发自动并行执行。 | 子模块 `upstream/omc`，固定 SHA（见「捆绑的上游版本」）；`install.sh` 执行 `npm i -g oh-my-claude-sisyphus@latest` 并启用 `oh-my-claudecode@omc` 插件。 |
| 2 | <img src="https://github.com/code-yeongyu.png?size=32" width="20" height="20" align="center"/> **[oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent)** (omo) — code-yeongyu | 一套多平台 harness，按类别在 8 个提供方（Claude、GPT、Gemini 等）之间路由，并通过 `claude-code-agent-loader` 与 `claude-code-plugin-loader` 桥接到 Claude Code。其 9 个 Agent（Sisyphus、Atlas、Oracle 等）在此改写为独立的 `.md` 文件。 | 不是子模块：9 个 Agent 位于 `agents/omo/`；`install.sh` 执行 `npm i -g oh-my-opencode@latest` 安装 `omo` CLI。 |
| 3 | <img src="https://github.com/forrestchang.png?size=32" width="20" height="20" align="center"/> **[andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills)** — forrestchang | 4 条 AI 编码行为准则 —— Think Before Coding、Simplicity First、Surgical Changes、Goal-Driven Execution —— 始终生效。 | `install.sh` 以 curl 拉取固定 SHA `aa4467f` 的 `CLAUDE.md`，校验其校验和后追加到 `~/.claude/CLAUDE.md`。不收录任何代码。 |
| 4 | <img src="https://github.com/affaan-m.png?size=32" width="20" height="20" align="center"/> **[everything-claude-code](https://github.com/affaan-m/everything-claude-code)** (ECC) — affaan-m | 上游共 278 个 Skills + 67 个 Agent + 94 条命令 + 语言规则。my-claude 精选安装 61 个 Skills（加上可选的 `web` 通道为 79 个）—— 技术栈模式、AI/Agent 工程、代码库工具 —— 外加 9 个规则集，以及 `/tdd`、`/plan`、`/code-review`、`/build-fix` 等斜杠命令。 | 子模块 `upstream/ecc`，固定 SHA；`install.sh` 先尝试 `claude plugin add affaan-m/everything-claude-code`，失败则回退到子模块。 |
| 5 | <img src="https://www.anthropic.com/favicon.ico" width="20" height="20" align="center"/> **[anthropic/skills](https://github.com/anthropics/skills)** — Anthropic | Anthropic 官方 Skills 仓库：PDF 解析，Word/Excel/PowerPoint 处理，MCP 服务器创建。 | 由 `install.sh` 执行 `claude plugin add anthropics/skills`。有意不纳入清单跟踪。 |
| 6 | <img src="https://github.com/garrytan.png?size=32" width="20" height="20" align="center"/> **[gstack](https://github.com/garrytan/gstack)** — garrytan | Garry Tan 的冲刺流程 harness：26 个 Skills 加上 `gstack` 根路由器（共 27 个）—— 浏览器 QA（`/qa`）、范围漂移代码审查（`/review`）、安全审计（`/cso`），以及完整的 Plan→Review→QA→Ship 流程（Boss P0 通道）。随附编译好的 Playwright 浏览器守护进程用于真实浏览器测试。 | 子模块 `upstream/gstack`，固定 SHA。 |
| 7 | <img src="https://github.com/obra.png?size=32" width="20" height="20" align="center"/> **[superpowers](https://github.com/obra/superpowers)** — Jesse Vincent | Jesse Vincent 的开发流程库：15 个 Skills 中的 14 个 —— 头脑风暴、系统化调试、TDD、计划编写与执行、代码审查礼仪。`dispatching-parallel-agents` 被排除，因为 Boss 与 Agent Teams 已覆盖该路径。 | 子模块 `upstream/superpowers`，固定 SHA。 |
| 8 | <img src="https://github.com/getagentseal.png?size=32" width="20" height="20" align="center"/> **[codeburn](https://github.com/getagentseal/codeburn)** — getagentseal | 基于 Claude Code 与 Codex 本就写入的会话文件做本地优先的 token 与成本追踪 —— 无代理、无 API key，数据不离开本机。预算守卫 hooks 保持通过 `bash install.sh --with-codeburn-guard` 选择启用，因为其硬上限（默认每会话 $15）会阻断该会话的所有工具调用，包括解除命令 `codeburn guard allow`（需在外部终端运行）。 | `npm i -g codeburn@0.9.23`；`install.sh` 还会启动或复用一个跨 harness 共享的仪表盘 —— 见「在哪里查看结果」。MIT。 |
| 9 | <img src="https://github.com/oraios.png?size=32" width="20" height="20" align="center"/> **[serena](https://github.com/oraios/serena)** — oraios | 通过 MCP 使用语言服务器的符号图：`find_symbol`、`get_symbols_overview`、`find_referencing_symbols`、`replace_symbol_body`、`insert_after_symbol` —— 消耗的 token 随符号大小而非文件大小增长。 | `uv tool install -p 3.13 serena-agent==1.7.0`，注册为用户级 stdio MCP 服务器（`serena start-mcp-server --context claude-code --project-from-cwd`）。分发包整体遵循 GPL-3.0-or-later（PyPI 的 MIT classifier 并不准确）；作为外部服务器使用，从不收录进本仓库。 |
| 10 | <img src="https://github.com/headroomlabs-ai.png?size=32" width="20" height="20" align="center"/> **[headroom](https://github.com/headroomlabs-ai/headroom)** — Headroom Labs | 工具输出压缩：`headroom mcp serve` 暴露 `headroom_compress`、`headroom_retrieve`、`headroom_stats`，让超大的工具结果不会整段进入对话记录。 | `uv tool install --python 3.13 "headroom-ai[all]==0.37.0"`，注册为 `headroom` stdio MCP 服务器；`install.sh` 还会启动或复用无副作用的持久配置 `agent-harness-shared`。Apache-2.0。 |
| 11 | <img src="https://github.com/tt-a1i.png?size=32" width="20" height="20" align="center"/> **[archify](https://github.com/tt-a1i/archify)** — tt-a1i | 一个把架构、工作流、时序、数据流与生命周期图绘制为自包含 HTML 的 Agent skill —— 内联 SVG、明暗主题切换、PNG/JPEG/WebP/SVG 导出菜单，生成文件没有运行时依赖。它也接受粘贴的 Mermaid 作为输入方言。 | 子模块 `upstream/archify`，固定在标签 `v2.9.0`；`install.sh` 把上游的 `archify/` skill 目录复制到 `~/.claude/skills/archify`，因此安装时不会运行 `npx skills add`。 |
| 12 | <img src="https://github.com/msitarzewski.png?size=32" width="20" height="20" align="center"/> **[agency-agents](https://github.com/msitarzewski/agency-agents)** — msitarzewski | 栈内没有替代者的 3 个工程 Agent：AI Engineer、DevOps Automator、Multi-Agent Systems Architect。 | 子模块已于 2026-07-27 移除；当天把这 3 个 Agent 快照到 `agents/vendored/`，每个文件都保留上游署名。MIT。 |
| 13 | <img src="https://github.com/ast-grep.png?size=32" width="20" height="20" align="center"/> **[ast-grep](https://github.com/ast-grep/ast-grep)** — ast-grep | 理解语法树的结构化代码搜索与改写，让 Agent 匹配代码形状而非正则。 | `npm i -g @ast-grep/cli@0.42.0`。MIT。 |
| 14 | <img src="https://github.com/upstash.png?size=32" width="20" height="20" align="center"/> **[context7](https://github.com/upstash/context7)** — Upstash | 与版本对应的最新库文档，让 Agent 读真实 API 而不是凭记忆。 | 托管 MCP 服务器 `https://mcp.context7.com/mcp`，由 `install.sh` 注册。 |
| 15 | <img src="https://github.com/exa-labs.png?size=32" width="20" height="20" align="center"/> **[exa](https://github.com/exa-labs/exa-mcp-server)** — Exa Labs | 神经（语义）网页搜索，覆盖关键词检索会遗漏的资料。 | 托管 MCP 服务器 `https://mcp.exa.ai/mcp`，由 `install.sh` 注册。 |
| 16 | <img src="https://github.com/grep-app.png?size=32" width="20" height="20" align="center"/> **[grep.app](https://github.com/grep-app)** — grep.app | 跨公开 GitHub 仓库的代码搜索，用于查看某个写法在真实项目中的用法。 | 托管 MCP 服务器 `https://mcp.grep.app`，由 `install.sh` 注册。 |


---

## Boss 的工作原理

Boss 是 my-claude 的核心元编排器。它从不编写代码——它负责发现、分类、匹配、委派和验证。

| 阶段 | 执行内容 |
|------|----------|
| **0 · DISCOVERY** | 在运行时扫描 agents、skills、MCP、hooks，构建实时能力注册表 |
| **1 · INTENT GATE** | 对请求进行分类（trivial、build、refactor、mid-sized、architecture、research 等），若某个 skill 更契合则反向提议 |
| **2 · CAPABILITY MATCHING** | 按下方优先级链逐级匹配（P0 gstack skill → P1 精确 skill 匹配 → P2 专家 Agent → P3 多 Agent 编排 → P4 通用回退） |
| **3 · DELEGATION** | 向专家发送 6 段式结构化提示：TASK / OUTCOME / TOOLS / DO / DON'T / CTX |
| **4 · VERIFICATION** | 独立读取变更文件，运行测试、lint 与构建，与原始意图交叉比对，失败时最多重试 3 次 |

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
| 深度分析、架构 | `claude-opus-5-5` | Sisyphus、Atlas、Hephaestus、Oracle、Metis、Momus、Prometheus |
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

| 阶段 | 模式 | 执行内容 |
|------|------|----------|
| **1 · DESIGN** | interactive | 用户决定范围 · 工程评审 · 确认 "design done" |
| **2 · EXECUTE** | autonomous | ralph 执行实现 · 自动代码审查 · 架构师验证 |
| **3 · REVIEW** | interactive | 与设计文档对比 · 呈现对比表格 · 用户批准或要求改进 |

### 结构化最终报告

Boss 会以一份无需打开 diff 即可浏览的结构化最终报告来结束每个有实际工作的回合 — 即编辑/创建了文件、进行了提交/PR/合并、更改了配置或执行了验证的回合。报告由 5 个固定表格组成，每个表格仅在对应情况确实发生时才输出（绝不输出空表）:

| 情况 | 表格 | 列 |
|-----------|-------|---------|
| 文件/设置变更 | 变更对照 (Changes) | 对象 / Before / After / 依据 |
| 完成多项任务 | 工作摘要 (Work summary) | 项目 / 结果 / 依据 |
| 执行了验证 | 验证结果 (Verification) | 项目 / 预期 / 实际 / 判定 |
| 产出提交/PR | 交付物 (Deliverables) | PR / 仓库 / 内容 / 状态 |
| 存在未解决项 | 遗留项 (Remaining) | 项目 / 状态 / 后续操作 |

该报告仅在请求的最末尾触发 — 绝不会在启动或转达后台任务的回合、或作为任务中途的进度更新输出 — 纯问答回合则正常结束、不生成报告。规范位于 `boss.md § FINAL REPORT`，由 `stop-final-report.js` Stop 钩子强制执行。

### 具名工作流

确定性的多 Agent 工作流。`install.sh` 会把它们复制到 `~/.claude/workflows/`，因此不限于本仓库，在任意项目中都能通过 Workflow 工具调用。

| 工作流 | 作用 | 调用方式 |
|--------|------|----------|
| **code-review-fanout** | 4 个维度的审查者（正确性、安全性、性能、测试）并行展开，每条发现在上报前都经过对抗性验证 | `Workflow({name: "code-review-fanout"})` —— 参数：审查目标（分支、提交范围、路径），默认为工作区 diff |
| **upstream-audit** | 每个上游一名分析者（Pin 差异、允许列表契合度、新增重叠、安全信号、健康度），最后汇总成行动清单 | `Workflow({name: "upstream-audit"})` —— 用于季度审计或同步前审计 |

---

## 内容一览

| 类别 | 数量 | 来源 |
|----------|------:|--------|
| **Agent**（始终加载） | 32 | Boss 1 + OMO 9 + OMC 19 + Vendored 3 |
| **Skills** | 107 | ECC 61 · gstack 27 · Superpowers 14 · Core 4 · Archify 1 |
| **规则** | 48 个文件 / 9 个规则集 | ECC 46（common + 8 个语言目录）+ Core 2 |
| **MCP 服务器** | 3 | Context7、Exa、grep.app |
| **Hooks** | 10 个文件 / 6 个事件 | 委派守卫、遥测、验证、知识库 |
| **LSP 服务器** | 2 | typescript（`typescript-language-server`）、python（`pyright-langserver`） |
| **具名工作流** | 2 | code-review-fanout、upstream-audit |
| **上游子模块** | 5 | ecc、omc、gstack、superpowers、archify |
| **CLI 工具** | 7 | omc、omo、ast-grep、comment-checker、codeburn、serena、headroom |

以上 Agent、Skills、规则全部登记在 [`scripts/skill-allowlists.sh`](../../scripts/skill-allowlists.sh) 的白名单中，并由安装清单跟踪。Anthropic 官方文档 Skills（pdf、docx 等）通过 `claude plugin add anthropics/skills` 单独安装，有意不纳入清单跟踪。

<details>
<summary><strong>专家 Agent — 4 个层级共 32 个</strong></summary>

各 Agent 使用的模型见上方「模型路由」表；各来源的出处见 [使用的开源工具](#open-source-tools-used)。

| Agent | 层级 | 职责 | 来源 |
|-------|------|------|--------|
| Boss | core | 动态运行时发现 → 能力匹配 → 最优路由。从不编写代码。 | my-claude |
| Sisyphus | omo | 意图分类 → 专家委派 → 验证 | [oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent) |
| Hephaestus | omo | 自主探索 → 规划 → 执行 → 验证 | oh-my-openagent |
| Atlas | omo | 任务分解 + 四阶段 QA 验证 | oh-my-openagent |
| Oracle | omo | 战略技术咨询（只读） | oh-my-openagent |
| Metis | omo | 意图分析、歧义检测 | oh-my-openagent |
| Momus | omo | 计划可行性评审 | oh-my-openagent |
| Prometheus | omo | 基于访谈的详细规划 | oh-my-openagent |
| Librarian | omo | 通过 MCP 搜索开源文档 | oh-my-openagent |
| Multimodal-Looker | omo | 图像 / 截图 / 图表分析 | oh-my-openagent |
| analyst | omc | 规划前预分析 | [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) |
| architect | omc | 系统设计与架构 | oh-my-claudecode |
| code-reviewer | omc | 专注代码审查 | oh-my-claudecode |
| code-simplifier | omc | 代码简化与清理 | oh-my-claudecode |
| critic | omc | 批判性分析、替代方案提议 | oh-my-claudecode |
| debugger | omc | 专注调试 | oh-my-claudecode |
| designer | omc | UI/UX 设计指导 | oh-my-claudecode |
| document-specialist | omc | 文档撰写 | oh-my-claudecode |
| executor | omc | 任务执行 | oh-my-claudecode |
| explore | omc | 代码库探索 | oh-my-claudecode |
| git-master | omc | Git 工作流管理 | oh-my-claudecode |
| planner | omc | 快速规划 | oh-my-claudecode |
| qa-tester | omc | 质量保证测试 | oh-my-claudecode |
| scientist | omc | 研究与实验 | oh-my-claudecode |
| security-reviewer | omc | 安全审查 | oh-my-claudecode |
| test-engineer | omc | 测试编写与维护 | oh-my-claudecode |
| tracer | omc | 执行追踪与分析 | oh-my-claudecode |
| verifier | omc | 最终验证 | oh-my-claudecode |
| writer | omc | 内容与文档 | oh-my-claudecode |
| AI Engineer | vendored | AI/ML 工程、模型集成、数据管道 | agency-agents（vendored） |
| DevOps Automator | vendored | 基础设施自动化、CI/CD、云运维 | agency-agents（vendored） |
| Multi-Agent Systems Architect | vendored | Agent 拓扑、上下文管理、故障恢复 | agency-agents（vendored） |

</details>

<details>
<summary><strong>Skills — 107 个，来自 5 个来源</strong></summary>

每个来源都由 [`scripts/skill-allowlists.sh`](../../scripts/skill-allowlists.sh) 白名单管理，未列入的 Skills 一律不安装。

| 来源 | 数量 | 核心 Skills |
|--------|------:|------------|
| [everything-claude-code](https://github.com/affaan-m/everything-claude-code) | 61 | coding-standards、fastapi-patterns、agent-architecture-audit、springboot-patterns、kubernetes-patterns |
| [gstack](https://github.com/garrytan/gstack) | 27 | /qa、/review、/ship、/cso、/investigate、/office-hours |
| [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) | 16（插件） | autopilot、ralph、team、ultrawork、ralplan、omc-reference |
| [superpowers](https://github.com/obra/superpowers) | 14 | brainstorming、systematic-debugging、test-driven-development、writing-plans |
| [my-claude Core](https://github.com/sehoon787/my-claude) | 4 | boss-advanced、boss-briefing、briefing-vault、gstack-sprint |
| [archify](https://github.com/tt-a1i/archify) | 1 | archify |

</details>

<details>
<summary><strong>MCP 服务器（3）+ Hooks（8）</strong></summary>

**MCP 服务器** —— 各自的作用与注册方式见 [使用的开源工具](#open-source-tools-used)。

| 服务器 | 费用 |
|--------|------|
| <img src="https://context7.com/favicon.ico" width="16" height="16" align="center"/> [Context7](https://context7.com) | 免费 |
| <img src="https://exa.ai/images/favicon-32x32.png" width="16" height="16" align="center"/> [Exa](https://exa.ai) | 每月免费 1k 次请求 |
| <img src="https://www.google.com/s2/favicons?domain=grep.app&sz=32" width="16" height="16" align="center"/> [grep.app](https://github.com/grep-app) | 免费 |

**行为 Hooks**

| Hook | 事件 | 行为 |
|------|-------|----------|
| Session Setup | SessionStart | 自动检测缺失工具 + 注入 Briefing Vault 上下文 |
| Delegation Guard | PreToolUse | 阻止 Boss 直接修改文件 |
| Agent Telemetry | PostToolUse | 将 Agent 使用情况记录到 `agent-usage.jsonl` |
| Subagent Logger | SubagentStop | 将 Agent 执行记录到 Briefing Vault |
| Completion Check | Stop | 确认任务已验证 + 提示会话摘要 |
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

### 子 Vault

| 路径 | 说明 |
|------|------|
| `INDEX.md` | 项目概览，含最近决策和学习的链接。首次会话自动创建，定期刷新。 |
| `sessions/` | **会话摘要。** `YYYY-MM-DD-auto.md` — 含 git diff 统计和 Agent 计数的脚手架。`YYYY-MM-DD-<topic>.md` — 由 hook 强制的 AI 撰写摘要。 |
| `decisions/` | **架构和设计决策**，含理由。`YYYY-MM-DD-<decision>.md` — AI 撰写，工作期间强制。 |
| `learnings/` | **模式、注意事项、非显而易见的解决方案。** `YYYY-MM-DD-auto-session.md` — 文件列表脚手架。`YYYY-MM-DD-<pattern>.md` — AI 撰写。 |
| `references/` | **网络调研 URL。** `auto-links.md` — 从 WebSearch/WebFetch 调用自动收集。 |
| `agents/` | **Agent 遥测。** `agent-log.jsonl` — 每次调用日志。`YYYY-MM-DD-summary.md` — 每日使用汇总。 |
| `persona/` | **用户工作风格档案。** `profile.md` — 工具偏好统计。`suggestions.jsonl` — 路由建议。`rules/`、`skills/` — 已接受的偏好。 |
| `archives/` | **已完成/不活跃的笔记。** 含 `sessions/`、`decisions/`、`learnings/` 子目录。超过 30 天的笔记为存档候选。PARA 方法中的 Archives 概念。扁平结构，通过 frontmatter 中的 `type:` 字段识别原始分类。 |
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

## 在哪里查看结果

my-claude 捆绑的工具会把结果写到不同位置 —— 下表列出各自的查看方式。每个工具是什么，见 [使用的开源工具](#open-source-tools-used)。

| 工具 | 打开 | 运行方式 | 查看位置 |
|------|------|----------|----------|
| **codeburn** | <http://127.0.0.1:4747/> | `install.sh` 启动或复用 `codeburn web --provider all --port 4747 --no-open` · `codeburn` 打开 TUI · `codeburn report --format json --period week` 生成非交互式输出 | 共享仪表盘。启动日志 `${XDG_STATE_HOME:-$HOME/.local/state}/agent-harness-services/logs/codeburn.log`。会话文件只读，美元金额是按 API 标价计算的估算值。 |
| **Serena** | <http://localhost:24282/dashboard/index.html> | 作为 MCP 服务器自动启动；在任意会话中调用 `get_symbols_overview` / `find_symbol` | 服务器运行期间可用的仪表盘（日志 + 各工具调用计数）。按项目的记忆写入你正在工作的仓库内的 `.serena/`；全局配置为 `~/.serena/serena_config.yml`。 |
| **Headroom** | <http://127.0.0.1:8787/stats> | MCP 工具 `headroom_compress` / `headroom_retrieve` / `headroom_stats`；`install.sh` 启动或复用共享代理配置 `agent-harness-shared` | 压缩统计页面，客户端显式通过代理路由前可能为空。启动日志 `${XDG_STATE_HOME:-$HOME/.local/state}/agent-harness-services/logs/headroom.log`。 |
| **Archify** | `out.html` | 请求绘图时 Boss 会路由到 `archify` skill。手动方式，从 `~/.claude/skills/archify` 运行：`node bin/archify.mjs render workflow examples/agent-tool-call.workflow.json out.html` | 生成的文件 —— 用任意浏览器打开。可用 `node bin/archify.mjs check out.html` 校验。 |
| **OMC HUD** | Claude Code 状态栏 | 由 `install.sh` 安装为状态栏；`/oh-my-claudecode:hud` 可重新配置 | 会话底部，实时显示上下文、配额与模式。与 codeburn 互补：HUD 看当前会话，codeburn 看所有会话。 |

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
| **精选白名单** | `scripts/skill-allowlists.sh` 是唯一事实来源——上游数千项中只留下 107 个 Skills 和 9 个规则集，未列入的绝不进入会话上下文 |
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
| [everything-claude-code](https://github.com/affaan-m/everything-claude-code) | `07756ce` | 2026-09-19 | [compare](https://github.com/affaan-m/everything-claude-code/compare/07756ce...HEAD) |
| [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) | `5281b19` | 2026-09-13 | [compare](https://github.com/Yeachan-Heo/oh-my-claudecode/compare/5281b19...HEAD) |
| [gstack](https://github.com/garrytan/gstack) | `a6b3a57` | 2026-09-16 | [compare](https://github.com/garrytan/gstack/compare/a6b3a57...HEAD) |
| [superpowers](https://github.com/obra/superpowers) | `5bf4e78` | 2026-09-19 | [compare](https://github.com/obra/superpowers/compare/5bf4e78...HEAD) |
| [archify](https://github.com/tt-a1i/archify) | `62904f3` (`v2.9.0`) | 2026-09-19 | [compare](https://github.com/tt-a1i/archify/compare/62904f3...HEAD) |

---

## 贡献

欢迎提交 Issue 和 PR。添加新 Agent 时，请在 `agents/core/` 或 `agents/omo/` 中添加 `.md` 文件并更新 `SETUP.md`。

## 致谢

本项目构建在 [使用的开源工具](#open-source-tools-used) 所列的项目之上；感谢每一位作者。

## 许可证

MIT 许可证。详情请参阅 [LICENSE](../../LICENSE) 文件。
