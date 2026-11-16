---
name: gstack-sprint
description: 3-Phase Sprint workflow — design (writing-plans plan in .briefing/plans/, momus review, one approval gate) → execute (ralph) → review against the plan
level: 4
user-invocable: true
---

<Purpose>
gstack-sprint wraps the 3-Phase Sprint workflow (design→execute→review) as a structured skill to guarantee deterministic execution. Without this skill, the 3-Phase workflow exists only as prompt instructions in boss.md and may be forgotten during long sessions. This skill is the single entry point for end-to-end feature implementation — it coordinates design, execution, and review with user confirmation at each phase boundary.
</Purpose>

<Use_When>
- End-to-end feature implementation ("build this feature for me", "design and implement this")
- Build or Mid-sized intent type with implementation phase included
- User says "sprint", "end-to-end", "e2e implementation"
</Use_When>

<Do_Not_Use_When>
- Pure design/planning/idea review without implementation → use /office-hours or /plan-ceo-review directly
- Architecture intent type (design only, no build)
- "just design it", "just plan it", "review this idea" — these route to /office-hours or /plan-ceo-review
- Single-purpose requests: code review → /review, QA → /qa, deploy → /ship
- Trivial fixes, research, documentation
</Do_Not_Use_When>

<Why_This_Exists>
End-to-end feature work fails silently in three predictable ways:
1. Implementation starts before design is aligned — wrong thing built
2. Execution proceeds without structured iteration — partial implementations declared done
3. Review skips comparison against the design doc — drift goes unnoticed

gstack-sprint enforces the three-phase contract: user-confirmed design → automated execution via ralph → user-confirmed review against the design doc. Each phase boundary requires explicit user confirmation before the next phase begins.
</Why_This_Exists>

<Steps>

## Phase 1: Design (interactive — one approval gate)

1. **Recall** (always): search `.briefing/decisions/`, `.briefing/learnings/` and `.briefing/plans/` for two or three keywords from the request. Read at most the three most relevant notes, and note any earlier decision that the request conflicts with. If `.briefing/` does not exist, skip this step.

2. **Clarify** (only when the request is ambiguous): if the goal or the scope has several plausible readings, call the `metis` advisor once, then ask the user at most two clarifying questions in ONE AskUserQuestion call. If the request is clear, skip this step and ask nothing.

3. **Spec and slice** (always): invoke the `writing-plans` skill with two things already decided:
   - Save path: `.briefing/plans/YYYY-MM-DD-<topic>.md`. Create the directory if it is missing.
   - Execution method: Phase 2 of this skill. `writing-plans` must save the plan and return its path. It must not ask which execution approach to use, and it must not ask the user to review the plan: the approval gate in step 5 replaces both questions.

   The plan lists small tasks with exact file paths, test-first steps, a verification command for each task, and the dependencies between tasks. `/plan-ceo-review`, `/plan-eng-review` and `/autoplan` are optional extra reviews: run one only when the user asks for it.

4. **Plan review** (always): call the `momus` advisor on the plan file. Fix its blocking issues in the plan, for at most two rounds, then append the final momus verdict to the plan file.

5. **APPROVAL GATE** (always): ask exactly one AskUserQuestion. It shows the plan path, the momus verdict and every decision that is still open, and it offers three options: approve, revise, stop.
   - approve → start Phase 2.
   - revise → change the plan, repeat step 4, then ask this gate again.
   - stop → end the sprint and keep the plan file.

   Phase 2 never starts without an approve answer at this gate (except under step 6). Do not ask for approval anywhere else in Phase 1.

6. **Skip condition**: if the user's original message already says the design is done ("design is done, just build it"), skip steps 2 and 5 and ask nothing. Steps 3 and 4 still run on the design the user gave, so that Phase 2 and Phase 3 have a reviewed plan file. If the user gave a finished task plan file, use it as the plan and skip step 3 as well. If `momus` still reports a blocking issue after its two rounds, do not skip step 5.

7. **Fallback** (`writing-plans` is not installed): delegate the plan to the `prometheus` agent, which writes it to the same path. Steps 4 and 5 still apply. If `momus` is not available, say so at the approval gate in place of its verdict.

---

## Phase 2: Execute (autonomous/automated — ralph)

Phase 2 runs as an independent skill invocation, not nested within gstack-sprint's prompt context. Boss invokes `Skill(skill: "oh-my-claudecode:ralph")` for this phase.

1. **Invoke the ralph skill** — ralph internally selects its execution strategy based on scale:
   - Parallel multi-agent (team) for large, multi-story work
   - Single executor for simple, well-scoped implementation

   ralph receives the Phase 1 plan file path as the source for its PRD stories. ralph is the executor of this sprint, so the plan header line that names another execution skill is ignored.

2. **ralph Step 7a** (inside ralph): attempts gstack /review for code review — non-blocking, skips silently if gstack is not installed or /review fails

3. **ralph Step 7b** (inside ralph): architect/critic verification — always runs regardless of Step 7a result

4. **Agent teams** for complex work (ralph delegates to executor + code-reviewer + test-engineer in parallel as needed)

5. **Fallback** (gstack not installed): ralph's existing verification flow runs unchanged — no behavior difference from ralph's perspective

6. **Phase 2 completion**: ralph signals completion via its standard cancel/completion flow. After ralph completes, gstack-sprint resumes Phase 3.

---

## Phase 3: Review (conversation/improvement — user confirms)

1. **Reload the plan from disk** in this order:
   1. the Phase 1 plan file; if its path is not known, the newest matching file in `.briefing/plans/`
   2. the gstack design doc `~/.gstack/projects/<org>-<repo>/*-design-*.md`
   3. the original request

   The gstack design doc lookup:
   ```bash
   REPO=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)")
   ORG=$(git remote get-url origin 2>/dev/null | sed 's|.*[:/]\([^/]*\)/.*|\1|' || echo "unknown")
   DESIGN_DOC=$(ls -t ~/.gstack/projects/${ORG}-${REPO}/*-design-*.md 2>/dev/null | head -1)
   ```

2. **Read what step 1 loaded** in full (the plan file, or the gstack design doc when there is no plan file), then read all files implemented during Phase 2

3. **Compare implementation against design**: For each item in what step 1 loaded, determine whether it was implemented, partially implemented, or skipped. Note any implementation that was added beyond the design scope.

4. **Present a comparison table** to the user:

   | Design Item | Status | Notes |
   |---|---|---|
   | Feature A | Implemented | |
   | Feature B | Partial | Missing edge case X |
   | Feature C | Not implemented | Descoped during Phase 2 |
   | Bonus: Feature D | Added (not in design) | Confirm or revert |

5. **AskUserQuestion** with the following options:
   - "approve" — implementation matches design intent, proceed to next step
   - "needs improvement" — significant gaps exist, re-enter Phase 2 with corrections
   - "partial fix" — minor gaps, specify what to fix before approving

6. **If "needs improvement" or "partial fix"**: Re-enter Phase 2 with a targeted correction delta. Pass the specific gaps to ralph rather than re-running the full implementation. After correction, return to Phase 3 Step 1.

7. **If "approve"**: Suggest next steps — /ship or manual commit. Do not proceed autonomously.

8. **Optional follow-up chain** (present as options, do not auto-invoke):
   - /land-and-deploy → /canary → /document-release → /retro

9. **Fallback** (gstack not installed): Read the implemented files directly, compare them against what step 1 loaded (the plan file, or the original request when there is no plan file), and present the comparison to the user for their review.

</Steps>

<Escalation_And_Stop_Conditions>
- Stop and report when a fundamental blocker requires user input (missing credentials, unclear requirements, external service down)
- Stop when the user says "stop", "cancel", or "abort"
- Never auto-advance phase boundaries — Phase 2 starts only on an approve answer at the Phase 1 approval gate (except under the Phase 1 skip condition), and Phase 3 waits for the user's decision
- If `momus` still reports a blocking issue after its two review rounds, do not start a third round on your own: append its verdict to the plan file and name the issue at the approval gate
- If Phase 2 (ralph) fails after the maximum retry attempts, surface the blocker to the user rather than silently retrying or declaring completion
- If Phase 3 comparison reveals that more than 50% of design items are unimplemented, flag this as a significant implementation gap before asking for user decision
</Escalation_And_Stop_Conditions>

<Examples>
<Good>
Phase 1 — one approval gate after the momus review:
```
AskUserQuestion: "Plan saved: .briefing/plans/2026-03-26-user-auth.md (6 tasks)
momus verdict: OKAY (round 1 asked for a token-expiry test; Task 4 now has it)
Still open: JWT tokens or session cookies? The plan assumes JWT.
Options: approve (start Phase 2) / revise (change the plan) / stop (end the sprint, keep the plan)"
```
Why good: One question shows the plan path, the momus verdict and the open decision; implementation cannot start without an approve answer.
</Good>

<Good>
Phase 3 — comparison table against design doc:
```
Design doc: ~/.gstack/projects/sehoon787-my-claude/sehunkim-main-design-20260326-142559.md

| Design Item | Status | Notes |
|---|---|---|
| User auth via JWT | Implemented | |
| Refresh token rotation | Implemented | |
| Rate limiting (100 req/min) | Partial | Middleware added, limit not configurable |
| Audit log for auth events | Not implemented | Descoped during execution |
| OpenAPI schema update | Implemented | |

3 items fully implemented, 1 partially implemented, 1 not implemented.
How would you like to proceed? (approve / needs improvement / partial fix)
```
Why good: Reads the actual design doc, presents concrete status per item, asks before proceeding.
</Good>

<Bad>
Skipping Phase 1 and jumping straight to implementation:
```
"Understood, I'll start implementing right away."
[immediately starts writing code without design confirmation]
```
Why bad: Phase 1 exists to align on design before implementation. Skipping it risks building the wrong thing.
</Bad>

<Bad>
Claiming Phase 3 complete without reading the design doc:
```
"Implementation is complete. All features are working correctly."
```
Why bad: Did not read the design doc, did not produce a comparison table, did not ask the user for confirmation. This is completion theater.
</Bad>
</Examples>

<Final_Checklist>
- [ ] Phase 1: Plan file saved under `.briefing/plans/`, momus verdict appended to it, and an approve answer given at the approval gate (or the gate skipped under the Phase 1 skip condition)
- [ ] Phase 2: ralph invoked and completed with its own verification (7a + 7b)
- [ ] Phase 3: Plan reloaded from disk (Phase 1 plan file, else the gstack design doc, else the original request)
- [ ] Phase 3: Comparison table presented to user
- [ ] Phase 3: User selected "approve", "needs improvement", or "partial fix"
- [ ] If "needs improvement": correction delta passed to ralph, Phase 3 re-run after correction
- [ ] If "approve": next steps suggested (/ship or manual commit), no autonomous action taken
</Final_Checklist>
