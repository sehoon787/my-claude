# Agent Teams Reference

Reference document covering the Agent Capability Matrix, Orchestration Tool Comparison,
teammate communication patterns, and Known Limitations & Workarounds referenced from the Boss prompt.

---

## 1. Agent Capability Matrix

### CORE (10)

| Agent | Model | Write/Edit | teammate | Recommended Role | Notes |
|----------|------|:----------:|:--------:|-----------|----------|
| boss | Opus | ✅ | — | Leader | Team leader only |
| sisyphus | Opus | ✅ | ❌ | Sub-agent delegation only | Cannot spawn when teammate |
| hephaestus | Opus | ✅ | ⚠️ | Autonomous execution | Low cost-efficiency as teammate |
| prometheus | Opus | MD only | ⚠️ | Planning | NotebookEdit blocked only |
| atlas | Opus | ❌ | ❌ | Sub-agent delegation only | Write/Edit blocked + cannot spawn |
| metis | Opus | ❌ | ⚠️ | Analysis only | Read-only |
| momus | Opus | ❌ | ⚠️ | Review only | Read-only |
| oracle | Opus | ❌ | ⚠️ | Advisory only | Read-only |
| librarian | Sonnet | ❌ | ⚠️ | Doc search only | Read-only |
| multimodal-looker | Sonnet | ❌ | ❌ | — | Bash also blocked, unsuitable as teammate |

### OMC (19)

| Agent | Model | Write/Edit | teammate | Recommended Role | Notes |
|----------|------|:----------:|:--------:|-----------|----------|
| executor | Sonnet | ✅ | ✅ | **Core implementation** | No restrictions, optimal teammate |
| debugger | Sonnet | ✅ | ✅ | Debugging | No restrictions |
| designer | Sonnet | ✅ | ✅ | UI implementation | No restrictions |
| test-engineer | Sonnet | ✅ | ✅ | Test writing | No restrictions |
| qa-tester | Sonnet | ✅ | ✅ | QA/verification | tmux-based testing |
| tracer | Sonnet | ✅ | ✅ | Root cause tracing | No restrictions |
| git-master | Sonnet | ✅ | ⚠️ | Git operations | "Work ALONE" — agent spawning blocked |
| writer | Haiku | ✅ | ✅ | Documentation | Low cost |
| code-simplifier | Opus | ✅ | ✅ | Code cleanup | High cost |
| planner | Opus | MD only | ⚠️ | Planning | Writes to `.omc/plans/*.md` only |
| code-reviewer | Opus | ❌ | ⚠️ | Review only | SendMessage OK, cannot modify files |
| security-reviewer | Opus | ❌ | ⚠️ | Security review | SendMessage OK, cannot modify files |
| architect | Opus | ❌ | ⚠️ | Architecture advisory | Read-only |
| analyst | Opus | ❌ | ⚠️ | Analysis only | Read-only |
| critic | Opus | ❌ | ⚠️ | Critical review | Read-only |
| scientist | Sonnet | ❌ | ⚠️ | Data analysis | python_repl only, Write/Edit blocked |
| verifier | Sonnet | ❌ | ⚠️ | Verification only | Read-only |
| explore | Haiku | ❌ | ⚠️ | Exploration only | Low cost, read-only |
| document-specialist | Sonnet | ❌ | ⚠️ | External doc lookup | Read-only |

### Built-in (never use as teammate)

| Agent | teammate | Reason |
|----------|:--------:|------|
| Explore (built-in) | ❌ | No SendMessage/TaskUpdate, blocks shutdown |
| Plan (built-in) | ❌ | No SendMessage/TaskUpdate, blocks shutdown |

---

## 2. Orchestration Tool Comparison and Hierarchy

| Tool | Purpose | Team? | Cost | Best For |
|------|------|:--------:|------|------------|
| Subagent (Agent tool) | Single task delegation | No | Low | 1–4 independent tasks (Priority 3a) |
| sisyphus/atlas (sub-agents) | Complex workflow delegation | No | Medium–High | 5+ agents, complex dependencies (Priority 3b) |
| Agent Teams (Boss as direct leader) | Requires mutual communication | Yes | High | peer-to-peer communication, mutual checks needed (Priority 3c-DIRECT) |
| /team skill | Pipeline orchestration | Yes | High | Structured plan→exec→verify (Priority 3c) |
| /ralph | Completion-guarantee loop | No | Medium | Iterative tasks requiring verification |
| /autopilot | Full automation | Internal use | High | Idea→code fully automated |
| /ultrawork | Parallel execution engine | No | Medium | Large-scale parallel execution of independent tasks |

**Containment**: `autopilot ⊃ ralph ⊃ ultrawork` — each wraps the one below. /team is a separate path (native team infrastructure).

---

## 3. Inter-Teammate Communication Patterns

### Pipeline (Sequential dependency)
```
A → B → C
```
- Set dependencies with blockedBy
- A completes → B starts → C starts
- Use case: implementation → testing → review

### Parallel (Independent parallel)
```
A ──┐
B ──┼── Boss aggregates
C ──┘
```
- Each runs independently, Boss aggregates results
- Use case: simultaneous multi-module analysis, multi-perspective review

### Adversarial (Adversarial)
```
A ←→ B (direct debate via SendMessage)
```
- Each forms hypotheses and rebuts the other
- Boss acts as mediator
- Use case: debugging, architecture trade-off analysis

### Review Chain (Implementation-review cycle)
```
Implementer → Reviewer → Implementer → Reviewer
```
- Implementer completes → SendMessage to Reviewer
- Reviewer gives feedback → SendMessage to Implementer
- After iterations, Reviewer approves → TaskUpdate complete
- Use case: feature development where quality is critical

---

## 4. Known Limitations & Workarounds

| Limitation | Cause | Workaround |
|------|------|-----------|
| Explore/Plan built-in cannot be teammates | SendMessage/TaskUpdate not supported | Replace with general-purpose agent |
| Orchestrators are inefficient as teammates | "Subagents cannot spawn other subagents" | Replace with executor; orchestrators handle sub-agent delegation only (Priority 3b) |
| In-process teammate session cannot be restored | Claude Code limitation | Replace by spawning a new teammate |
| Two teammates editing the same file simultaneously | Overwrites occur | File scope separation required; shared files must be sequenced with blockedBy |
| Only one team per session | Claude Code limitation | Clean up existing team (TeamDelete) before creating a new one |
| Nested teams not supported | Teammates cannot create sub-teams | Single-level team + Boss direct coordination |
| Leader is fixed | Leader cannot change during team lifetime | Boss starts as leader; no change needed |
