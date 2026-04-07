# Knowledge Vault

Every project maintains a `.knowledge/` directory as a persistent, Obsidian-compatible knowledge base.

## Session Start
- If `.knowledge/INDEX.md` exists, read it for project context, recent decisions, and open questions
- Use past decisions and learnings to inform current work

## During Work
- Architecture/design decisions → `.knowledge/decisions/<descriptive-name>.md`
- Non-obvious solutions, gotchas, patterns → `.knowledge/learnings/<descriptive-name>.md`
- Important agent execution results → `.knowledge/agents/<date>-<agent-name>.md`

## Session End
- Write session summary to `.knowledge/sessions/<YYYY-MM-DD>-<topic>.md`
- Update `.knowledge/INDEX.md` if significant decisions or learnings were added
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
Use Grep to search `.knowledge/` by keyword, tag, or type.

## First Session in a New Project
If `.knowledge/` does not exist, create it with INDEX.md on the first meaningful interaction.
Add `.knowledge/` to the project's `.gitignore`.
