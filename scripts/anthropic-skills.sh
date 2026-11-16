#!/usr/bin/env bash
# Anthropic official skills presence check, sourced by install.sh (step 5a).

# anthropic_skills_installed: success when the Anthropic skills are installed where
# step 5a puts them, i.e. pdf and docx each have a SKILL.md under ~/.claude/skills.
#
# A bare pdf/ or docx/ directory does not count. A skill without SKILL.md is never
# loaded, and installs from before 6bc7841 left exactly such "husks": the manifest
# cleanup deleted a skill's SKILL.md but not the rest of its directory.
#
# Only ~/.claude/skills is checked, on purpose. `claude plugin add` is not a Claude
# Code command (2.1.325: "unknown command 'add'"), so step 5a always ends up on its
# git clone fallback, whose only product is ~/.claude/skills/<skill>/.
anthropic_skills_installed() {
  [ -f "$HOME/.claude/skills/pdf/SKILL.md" ] && [ -f "$HOME/.claude/skills/docx/SKILL.md" ]
}
