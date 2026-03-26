# Reddit Promotion — r/ClaudeAI

**Post link**: https://www.reddit.com/r/ClaudeAI/submit

**Flair**: Built with Claude

---

## Title Options (pick one)

```
A: I got tired of being the middleman between my Claude Code agents. Now they talk to each other directly.
```

```
B: Your Claude Code agents don't know each other exist. I fixed that.
```

```
C: I made my Claude Code subagents actually collaborate in real-time — open sourced everything
```

---

## Body

```
Every time I asked Claude to "review this and fix the issues," it picked
one agent and did everything alone. Meanwhile I had agents from 3 repos
sitting in ~/.claude/agents/ that could've helped — but they had no idea
the others existed.

I was the human middleware. Copy output from the reviewer, paste it to
the executor, copy back, re-check. Over and over.

So I built a plugin that fixes this. The short version:

You say "review and fix this." Boss (the orchestrator) spawns a
code-reviewer and an executor as a Team. The reviewer finds issues,
sends them directly to the executor via SendMessage. Executor fixes,
reviewer re-checks. You watch in tmux split-pane. No copy-pasting.

One command to install:
`claude plugin add sehoon787/my-claude`

What's inside: 52 core subagents always loaded + 133 domain packs
you can activate when needed (gamedev, marketing, sales, etc).
Auto-syncs weekly from 3 MIT upstream repos — I haven't manually
copied an agent file in months.

Also built the same thing for Codex CLI (444 subagents in native TOML)
if you use both: https://github.com/sehoon787/my-codex

Claude Code: https://github.com/sehoon787/my-claude

Caveat: ~5s scan at session start. Domain packs eat disk but don't
load until called.

How do you coordinate agents right now? Or is everyone still
solo-agent-ing everything?
```

---

## Posting Checklist

- [ ] 화~목, 오전 10시-12시 ET (한국시간 밤 11시-새벽 1시)
- [ ] 포스팅 후 최소 2-3시간 댓글 응대
- [ ] 첫 댓글 질문에 5분 내 답변 (알고리즘 부스트)
