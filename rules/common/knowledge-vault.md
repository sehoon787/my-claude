# Knowledge Vault

Every project maintains a `.briefing/` directory as a persistent, Obsidian-compatible knowledge base.

## Session Start
- If `.briefing/INDEX.md` exists, read it for project context, recent decisions, and open questions
- Use past decisions and learnings to inform current work

## During Work
- Architecture/design decisions → `.briefing/decisions/<descriptive-name>.md`
- Non-obvious solutions, gotchas, patterns → `.briefing/learnings/<descriptive-name>.md`
- Important agent execution results → `.briefing/agents/<date>-<agent-name>.md`
- Reference materials, web findings, factual data → `.briefing/references/<descriptive-name>.md`

## Session End
- Write session summary to `.briefing/sessions/<YYYY-MM-DD>-<topic>.md`
- Update `.briefing/INDEX.md` if significant decisions or learnings were added
- Link related notes with `[[wiki-links]]` for Obsidian graph view

## Note Format
Use YAML frontmatter:
```
---
date: YYYY-MM-DD
type: session | decision | learning | agent-log
tags: [relevant, tags]
related: [[other-note]]
---
```

## Search
Use Grep to search `.briefing/` by keyword, tag, or type.

## First Session in a New Project
If `.briefing/` does not exist, create it with INDEX.md on the first meaningful interaction.
Add `.briefing/` to the project's `.gitignore`.
