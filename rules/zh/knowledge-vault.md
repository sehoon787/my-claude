# 知识库

每个项目在 `.knowledge/` 目录中维护一个持久化的、与 Obsidian 兼容的知识库。

## 会话开始
- 如果 `.knowledge/INDEX.md` 存在，读取它以获取项目背景、近期决策和待解问题
- 利用过去的决策和经验指导当前工作

## 工作过程中
- 架构/设计决策 → `.knowledge/decisions/<描述性名称>.md`
- 非显而易见的解决方案、注意事项、模式 → `.knowledge/learnings/<描述性名称>.md`
- 重要的代理执行结果 → `.knowledge/agents/<日期>-<代理名称>.md`

## 会话结束
- 将会话摘要写入 `.knowledge/sessions/<YYYY-MM-DD>-<主题>.md`
- 如果添加了重要决策或经验，更新 `.knowledge/INDEX.md`
- 使用 `[[wiki-links]]` 链接相关笔记，以便在 Obsidian 图谱视图中查看

## 笔记格式
使用 YAML frontmatter：
```
---
date: YYYY-MM-DD
type: session | decision | learning | agent-log
tags: [相关, 标签]
related: [[其他笔记]]
---
```

## 搜索
使用 Grep 按关键字、标签或类型搜索 `.knowledge/`。

## 新项目的第一次会话
如果 `.knowledge/` 不存在，在第一次有意义的交互时创建它并附带 INDEX.md。
将 `.knowledge/` 添加到项目的 `.gitignore` 中。
