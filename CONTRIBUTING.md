# Contributing to my-claude

Thank you for contributing. This guide covers how to author agents and skills, meet quality standards, and submit pull requests.

---

## Repository Structure

```
agents/
  core/          # Reference material (boss.md, agent-teams-reference.md)
  omc/           # Core OMC agents — always loaded
  omo/           # OMO agents — always loaded
  agency/
    engineering/ # Core engineering agents — always loaded
    {category}/  # Domain agent packs — on-demand via symlink
skills/
  ecc/           # everything-claude-code skills
  omc/           # oh-my-claudecode skills
```

**3-Tier Architecture**

| Tier | Paths | Load Behavior |
|------|-------|---------------|
| Core | `agents/omc/`, `agents/omo/`, `agents/agency/engineering/` | Always loaded |
| Agent Packs | `agents/agency/{domain}/` | On-demand via symlink |
| Docs | `agents/agency/strategy/` | Reference only — never parsed as agents |

---

## Authoring Agents

### File Format

Agents are Markdown files with YAML frontmatter.

**Required frontmatter fields:**

```yaml
---
name: my-agent-name
description: Use when a task needs X in order to Y.
model: claude-sonnet-4-6
---
```

**Optional frontmatter fields:**

| Field | Values | Notes |
|-------|--------|-------|
| `disallowedTools` | array of tool names | Restrict tool access |
| `color` | hex or named color | UI display only |
| `emoji` | single character | UI display only |

**Model options:**

| Model | Use For |
|-------|---------|
| `claude-opus-4-6` | Deep reasoning, architecture, complex analysis |
| `claude-sonnet-4-6` | Standard development work, orchestration |
| `claude-haiku-4-5` | Fast lookups, lightweight agents, frequent invocation |

### File Location

- Core/infrastructure agents: `agents/omc/` or `agents/omo/`
- Domain agents: `agents/agency/{category}/{name}.md`
- File name must match the `name` field: `security-reviewer.md` for `name: security-reviewer`

### Body Structure

The body should follow a task-shaped structure, not generic roleplay. A well-structured agent body includes:

```markdown
[Brief role statement — what this agent owns and why it exists]

Working mode:
1. [First step]
2. [Second step]
3. ...

Focus on:
- [Key area]
- [Key area]

Quality checks:
- [ ] [Verifiable criterion]
- [ ] [Verifiable criterion]

Output: [What the agent produces and in what format]
```

### Quality Bar

**Descriptions must:**
- Start with "Use when..." followed by a concrete trigger condition
- Name the specific task, not the general domain
- Be one sentence

**Body instructions must:**
- Be task-shaped, not persona-shaped
- State what the agent does, not just what role it plays
- Include working mode steps, focus areas, and quality checks
- Avoid phrases like "You are a helpful assistant who..."
- Avoid assuming tools that are not standard Claude Code tools

**High signal-to-noise:** Remove any instruction that does not change behavior. If a line could be deleted without affecting output, delete it.

---

## Authoring Skills

Skills are invokable workflows stored as `SKILL.md` files.

### File Format

```yaml
---
name: skill-name
description: One-sentence description of when to invoke this skill.
---

[Skill body — instructions, templates, or structured workflow content]
```

### File Location

```
skills/{source}/{skill-name}/SKILL.md
```

Where `{source}` is the upstream origin (e.g., `omc`, `ecc`).

---

## Naming Conventions

- Agent names: kebab-case (`security-reviewer`, `backend-architect`)
- File names: `{name}.md` matching the `name` frontmatter field exactly
- Category directories: lowercase with hyphens (`game-development`, `paid-media`)

---

## Pull Request Process

1. **One agent per PR** is preferred. Multiple agents are acceptable when they form a cohesive domain pack.
2. **PR body must include:**
   - The use case that motivated the contribution
   - The agent name and target directory
   - Confirmation that the name is unique across the repository
3. **README updates:** Add the agent to the relevant category table in `README.md`.
4. **Verify frontmatter parses** by running the agent through Claude Code and confirming it loads without errors.

### Commit Message Format

Follow conventional commits:

```
feat: add security-reviewer agent for pre-commit analysis
fix: correct model field in backend-architect.md
docs: update README table for engineering agents
```

Types: `feat` for new agents/skills, `fix` for corrections, `docs` for documentation updates, `refactor` for restructuring without behavior change.

---

## Pre-submission Checklist

- [ ] Frontmatter parses correctly (valid YAML, all required fields present)
- [ ] `name` field is unique across all agents in the repository
- [ ] File name matches the `name` field
- [ ] Description starts with "Use when..." and names a concrete trigger
- [ ] Body follows task-shaped structure (working mode, focus areas, quality checks)
- [ ] No generic roleplay language ("You are a helpful...")
- [ ] No assumptions about tools not available in Claude Code
- [ ] Model choice is appropriate for the agent's workload
- [ ] File is in the correct directory for its tier
- [ ] README category table updated if applicable
- [ ] PR body describes the use case
