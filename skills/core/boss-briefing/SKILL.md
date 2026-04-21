---
name: boss-briefing
description: Vault health check — workflow pattern analysis, profile sync, session gap recovery, persona rule proposals
---

# boss-briefing

Vault health check skill. Analyzes workflow patterns, syncs profile, recovers from session gaps, and proposes persona rules based on temporal agent call sequences.

> **Relationship with other skills:**
> - `briefing-vault` handles vault templates and initialization
> - `boss-briefing` handles sync, analysis, and pattern detection
> - `stop-profile-update.js` still runs as a fallback if this skill was not invoked during the session

## Steps

Execute all 9 steps in order. If any step fails due to missing data, log the issue and continue to the next step.

### Step 1: Read state.json

Read `.briefing/state.json` to get session metadata:
- `date` — last session date
- `workCounter` — file edit count this session
- `sessionMessageCount` — user message count this session
- `lastVaultSync` — ISO timestamp of last /boss-briefing run
- `sessionStartHead` — git HEAD or `YYYY-MM-DD:cwd` identifier

If state.json does not exist or is empty, use defaults: `{ date: "", workCounter: 0, sessionMessageCount: 0, lastVaultSync: "", sessionStartHead: "" }`.

### Step 2: Previous session gap detection

Compare the `date` field from state.json with today's date.

If the gap is >= 1 day:
1. Scan `.briefing/sessions/` for the most recent session file (by filename date prefix)
2. Report the gap: "Last session was on YYYY-MM-DD (N days ago). Topic: <extracted from filename>"
3. Read the most recent session file and provide a brief recovery summary of what was last worked on

If gap is 0 (same day), skip this step.

### Step 3: Analyze agent-log.jsonl sequences

Read `.briefing/agents/agent-log.jsonl`. Parse all entries from the last 30 days.

Group entries by date. For each day, extract the ordered sequence of `agent_type` values.

**Frequency patterns:** Identify any `agent_type` that appears >= 3 times in the last 7 days.

**Sequence patterns:** Look for recurring ordered sub-sequences (length >= 2) that appear in >= 2 different sessions/days. Examples:
- "explore → executor" (seen 4 times)
- "explore → executor → code-reviewer" (seen 3 times)
- "planner → executor → code-reviewer" (seen 2 times)

Report both frequency and sequence patterns.

### Step 4: Update profile.md

Rewrite `.briefing/persona/profile.md` with:

```yaml
---
date: YYYY-MM-DD
type: persona
version: 2
session_count: <incremented count>
---
```

Sections to include:

**## Philosophy** — Infer work style from data. Only populate if >= 10 agent calls exist in the last 30 days. Examples: "Prefers thorough exploration before implementation", "Review-heavy workflow with security focus".

**## Workflow Patterns** — Total agent calls (30d), most active agent type, average calls per session.

**## Workflow Sequences** — Detected temporal patterns from Step 3. Format: "Explore → executor → code-reviewer (seen 3 times)". This section is new and distinguishes boss-briefing from the old profile update.

**## Agent Affinity** — Percentage breakdown by `agent_type` over the 30-day rolling window.

**## Active Persona Rules** — List all `.md` files from `.briefing/persona/rules/` directory. Format: `- rule-name: <first line of description>`.

**## History** — Append a one-line entry every 5th session (based on `session_count % 5 === 0`). Format: "Session N (YYYY-MM-DD): <brief summary>".

**Session count idempotency:** If `sessionStartHead` is empty (no git repo), use `YYYY-MM-DD:cwd` as the session identifier to avoid double-counting.

### Step 5: Propose persona rules

For each detected SEQUENCE pattern from Step 3 that appears >= 2 times:
1. Draft a rule proposal explaining the pattern and suggesting it be formalized
2. Present the proposal to the user using conversation (ask for confirmation)
3. If confirmed, write the rule to `.briefing/persona/rules/workflow-<slug>.md`:

```yaml
---
date: YYYY-MM-DD
type: persona-rule
source: boss-briefing
pattern: "<sequence description>"
occurrences: <count>
---
```

Followed by a description of the workflow pattern and when it should be applied.

If no new sequence patterns are detected, or all existing patterns already have rules, skip this step.

### Step 6: Validate session summary

Check `.briefing/sessions/` for files matching `YYYY-MM-DD-*.md` (today's date, excluding files containing `-auto`).

If no matching file exists AND either:
- `workCounter > 0`, or
- `sessionMessageCount >= 3`

Then warn the user: "No session summary found for today. Consider writing .briefing/sessions/YYYY-MM-DD-<topic>.md before ending the session."

### Step 7: Sync INDEX.md

Read all files from these directories:
- `.briefing/sessions/`
- `.briefing/decisions/`
- `.briefing/learnings/`

Rebuild these sections in `.briefing/INDEX.md`:
- `## Recent Sessions` — newest 5 files with `[[wiki-links]]`
- `## Recent Decisions` — newest 5 files with `[[wiki-links]]`
- `## Recent Learnings` — newest 5 files with `[[wiki-links]]`

Update the `date` field in INDEX.md frontmatter to today.

Preserve any other existing sections (Overview, Open Questions, Key Links).

### Step 8: Record lastVaultSync

Read `.briefing/state.json`, merge in `{ lastVaultSync: "<current ISO timestamp>" }`, and write back.

This timestamp is checked by hooks to determine whether /boss-briefing has been run today.

### Step 9: No-git-repo graceful handling

This is not a separate step but a cross-cutting concern for all steps above:
- If `sessionStartHead` is empty, use `YYYY-MM-DD:cwd` format for session identification
- Do NOT fail or error on missing `.git` directory
- All git-dependent features should degrade gracefully
