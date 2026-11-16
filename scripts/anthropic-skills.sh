#!/usr/bin/env bash
# Anthropic official skills presence check, sourced by install.sh (step 5a).

# anthropic_skills_installed: success when the Anthropic skills are installed where
# step 5a puts them, i.e. pdf and docx each have a SKILL.md under ~/.claude/skills.
#
# A bare pdf/ or docx/ directory does not count. A skill without SKILL.md is never
# loaded, and installs from before 6bc7841 left exactly such "husks": the manifest
# cleanup deleted a skill's SKILL.md but not the rest of its directory.
#
# Only ~/.claude/skills is checked, on purpose: step 5a clones
# github.com/anthropics/skills straight into it. There is no plugin install to look
# for, since `claude plugin add` is not a Claude Code command (2.1.325: "unknown
# command 'add'").
#
# hooks/session-start.sh repeats this condition inline, because an installed hook
# cannot source this file; tests/anthropic-skills.test.sh keeps the two in step.
anthropic_skills_installed() {
  [ -f "$HOME/.claude/skills/pdf/SKILL.md" ] && [ -f "$HOME/.claude/skills/docx/SKILL.md" ]
}
