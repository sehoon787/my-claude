# Contributing to my-claude

Thank you for contributing. This guide covers how to author agents and skills, meet quality standards, and submit pull requests.

---

## Repository Structure

```
agents/
  core/                   # Self-owned (boss.md, agent-teams-reference.md)
  omo/                    # Self-owned OMO agents — always loaded
  vendored/               # Snapshotted third-party agents (attribution in-file)
upstream/                 # Git submodules (4 upstream sources)
  ecc/                    # everything-claude-code (skills + rules)
  omc/                    # oh-my-claudecode (agents + skills)
  gstack/                 # gstack (sprint-process skills)
  superpowers/            # superpowers (dev-process skills)
skills/
  core/                   # Self-owned skills
workflows/                # Named workflows (code-review-fanout, upstream-audit)
.lsp.json                 # LSP servers: typescript-language-server, pyright-langserver
scripts/
  skill-allowlists.sh     # Single source of truth for what actually installs
```

**Load Model**

Every agent is always loaded — there are no on-demand packs. 32 agents install in total.

| Source | Paths | Count |
|--------|-------|------:|
| Self-owned | `agents/core/boss.md`, `agents/omo/` | 10 |
| Upstream | `upstream/omc/agents/` | 19 |
| Vendored | `agents/vendored/` | 3 |

Skills and rules are not loaded wholesale from upstream: only names listed in `scripts/skill-allowlists.sh` are copied (139 skills, 9 rule sets). Adding a skill to the stack means adding its name there.

---

## Authoring Agents

### File Format

Agents are Markdown files with YAML frontmatter.

**Required frontmatter fields:**

```yaml
---
name: my-agent-name
description: Use when a task needs X in order to Y.
model: claude-sonnet-5
---
```

**Optional frontmatter fields:**

| Field | Values | Notes |
|-------|--------|-------|
| `effort` | `low`, `medium`, `high`, `xhigh`, `max` | Reasoning budget — see [Effort](#effort) below |
| `disallowedTools` | array of tool names | Restrict tool access |
| `color` | hex or named color | UI display only |
| `emoji` | single character | UI display only |

**Model options:**

| Model | Use For |
|-------|---------|
| `claude-fable-5` | Top-level orchestration (Boss) — highest-capability meta-routing |
| `claude-opus-5` | Deep reasoning, architecture, complex analysis |
| `claude-sonnet-5` | Standard development work, orchestration |
| `claude-haiku-4-5` | Fast lookups, lightweight agents, frequent invocation |

### Effort

`effort` sets how much reasoning budget an agent spends, independent of its model.

| Effort | Use For |
|--------|---------|
| `xhigh` | Meta-orchestration and deep advisory work (Boss, Oracle, Prometheus) |
| `high` | Sub-orchestrators and planning agents (Sisyphus, Hephaestus, Atlas, Metis, Momus) |
| `medium` | Focused workers (Librarian, Multimodal-Looker, vendored engineering agents) |
| `low` | Mechanical, well-specified tasks |

The top two tiers are model-gated: `xhigh` and `max` require an opus-class model. `xhigh` is Fable's supported ceiling, and `max` silently falls back on anything that is not opus-class — so do not set `max` on a Fable agent expecting it to take effect.

Precedence at runtime: `CLAUDE_CODE_EFFORT_LEVEL` (env) > frontmatter > session effort level.

Skills may declare `effort` too, but with a caveat: a skill's effort overrides the session level for the duration of the invocation. Omit `effort` on any skill that runs inside Boss's flow (as `boss-advanced` and `gstack-sprint` do) — otherwise invoking it downgrades Boss mid-task.

### File Location

- Core/infrastructure agents: `agents/core/` or `agents/omo/`
- Third-party agents kept without a submodule: `agents/vendored/{name}.md`, with an attribution comment naming the upstream repo, its license, and the snapshot date
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

Where `{source}` is the upstream origin (e.g., `core`) or installed from submodules at `upstream/`.

---

## Naming Conventions

- Agent names: kebab-case (`security-reviewer`, `backend-architect`)
- File names: `{name}.md` matching the `name` frontmatter field exactly
- Directories: lowercase with hyphens (`agents/vendored/`, `skills/core/`)

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
