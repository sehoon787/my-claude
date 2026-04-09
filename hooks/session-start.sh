#!/usr/bin/env bash
# SessionStart hook: detect missing companion tools and auto-install
# Failures are non-blocking (set +e)
set +e

MISSING=()
INSTALLED=()

# 1. Anthropic Skills
if [ ! -d "$HOME/.claude/skills/pdf" ] && [ ! -d "$HOME/.claude/skills/docx" ]; then
  _tmp_dir=$(mktemp -d)
  git clone --depth 1 https://github.com/anthropics/skills.git "$_tmp_dir/skills" 2>/dev/null
  if [ -d "$_tmp_dir/skills/skills" ]; then
    mkdir -p "$HOME/.claude/skills"
    cp -r "$_tmp_dir/skills/skills/"* "$HOME/.claude/skills/" 2>/dev/null
    rm -rf "$_tmp_dir"
    INSTALLED+=("anthropic-skills")
  else
    rm -rf "$_tmp_dir"
    MISSING+=("anthropic-skills")
  fi
fi

# 2. OMC CLI
if ! command -v omc >/dev/null 2>&1; then
  npm i -g oh-my-claude-sisyphus@latest 2>/dev/null && INSTALLED+=("omc") || MISSING+=("omc")
fi

# 3. omo CLI
if ! command -v oh-my-opencode >/dev/null 2>&1; then
  npm i -g oh-my-opencode@latest 2>/dev/null && INSTALLED+=("omo") || MISSING+=("omo")
fi

# 4. ast-grep
if ! command -v ast-grep >/dev/null 2>&1; then
  npm i -g @ast-grep/cli 2>/dev/null && INSTALLED+=("ast-grep") || MISSING+=("ast-grep")
fi

# 5. Capability Registry Cache
REGISTRY_DIR="$HOME/.omc/state"
REGISTRY_FILE="$REGISTRY_DIR/capability-registry.json"
REGISTRY_STATUS="up-to-date"
mkdir -p "$REGISTRY_DIR"
_needs_regen=0
if [ ! -f "$REGISTRY_FILE" ]; then
  _needs_regen=1
else
  if find "$HOME/.claude/agents" "$HOME/.claude/skills" -name "*.md" -newer "$REGISTRY_FILE" 2>/dev/null | grep -q .; then
    _needs_regen=1
  elif [ -d ".claude/agents" ] && find ".claude/agents" ".claude/skills" -name "*.md" -newer "$REGISTRY_FILE" 2>/dev/null | grep -q .; then
    _needs_regen=1
  fi
fi
if [ "$_needs_regen" -eq 1 ]; then
  _ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%SZ")

  # Detect project type from current directory
  _recommended_packs="[]"
  if [ -f "package.json" ] || [ -f "tsconfig.json" ] || [ -f "Cargo.toml" ] || \
     [ -f "requirements.txt" ] || [ -f "pyproject.toml" ] || [ -f "go.mod" ] || [ -f "Gemfile" ]; then
    _recommended_packs='["engineering"]'
  elif ls *.unity 2>/dev/null | grep -q . || [ -d "Assets" ]; then
    _recommended_packs='["game-development"]'
  fi

  _agents_json="["
  _first_agent=1
  for _f in "$HOME/.claude/agents/"*.md .claude/agents/*.md; do
    [ -f "$_f" ] || continue
    case "$_f" in "$HOME/.claude/agents/"*) _scope="global" ;; *) _scope="project" ;; esac
    _name=$(sed -n '/^---/,/^---/p' "$_f" 2>/dev/null | grep '^name:' | head -1 | sed 's/^name:[[:space:]]*//' | tr -d '"'"'"'')
    _desc=$(sed -n '/^---/,/^---/p' "$_f" 2>/dev/null | grep '^description:' | head -1 | sed 's/^description:[[:space:]]*//' | tr -d '"'"'"'')
    _model=$(sed -n '/^---/,/^---/p' "$_f" 2>/dev/null | grep '^model:' | head -1 | sed 's/^model:[[:space:]]*//' | tr -d '"'"'"'')
    [ -z "$_name" ] && _name=$(basename "$_f" .md)
    [ -z "$_model" ] && _model=""
    if [ "$_first_agent" -eq 1 ]; then _first_agent=0; else _agents_json="${_agents_json},"; fi
    _agents_json="${_agents_json}{\"name\":\"${_name}\",\"description\":\"${_desc}\",\"model\":\"${_model}\",\"scope\":\"${_scope}\"}"
  done
  _agents_json="${_agents_json}]"
  _skills_json="["
  _first_skill=1
  for _f in "$HOME/.claude/skills/"*/SKILL.md .claude/skills/*/SKILL.md; do
    [ -f "$_f" ] || continue
    _sname=$(basename "$(dirname "$_f")")
    if [ "$_first_skill" -eq 1 ]; then _first_skill=0; else _skills_json="${_skills_json},"; fi
    _skills_json="${_skills_json}\"${_sname}\""
  done
  _skills_json="${_skills_json}]"
  _mcp_json="["
  _first_mcp=1
  for _sf in "$HOME/.claude/settings.json" ".mcp.json"; do
    [ -f "$_sf" ] || continue
    while IFS= read -r _key; do
      [ -z "$_key" ] && continue
      if [ "$_first_mcp" -eq 1 ]; then _first_mcp=0; else _mcp_json="${_mcp_json},"; fi
      _mcp_json="${_mcp_json}\"${_key}\""
    done <<EOF
$(grep -o '"[^"]*"[[:space:]]*:' "$_sf" 2>/dev/null | sed -n '/mcpServers/,/}/p' | grep -v 'mcpServers' | sed 's/[[:space:]]*"//;s/"[[:space:]]*://' | grep -v '^$' | grep -v '^{' | grep -v '^}' | head -50)
EOF
  done
  _mcp_json="${_mcp_json}]"
  printf '{"generated_at":"%s","agents":%s,"skills":%s,"mcp_servers":%s,"recommended_packs":%s}\n' \
    "$_ts" "$_agents_json" "$_skills_json" "$_mcp_json" "$_recommended_packs" > "$REGISTRY_FILE" 2>/dev/null \
    && REGISTRY_STATUS="regenerated" || REGISTRY_STATUS="failed"
fi

# 6. Briefing Vault Auto-Create + Context
_kv_msg=""
_kv_dir=".briefing"
if [ ! -f "$_kv_dir/INDEX.md" ]; then
  mkdir -p "$_kv_dir/sessions" "$_kv_dir/decisions" "$_kv_dir/learnings" "$_kv_dir/agents" "$_kv_dir/references" "$_kv_dir/persona/rules" "$_kv_dir/persona/skills"
  _proj_name=$(basename "$(pwd)")
  cat > "$_kv_dir/INDEX.md" <<KVEOF
---
date: $(date +%Y-%m-%d)
type: index
tags: [project, index]
language: en
---

# ${_proj_name} Knowledge Base

## Overview
Project knowledge base. Auto-created by SessionStart hook.

## Recent Decisions

## Recent Sessions

## Open Questions

## Key Links
- [[sessions/]] — Session logs
- [[decisions/]] — Architecture decisions
- [[learnings/]] — Patterns and solutions
- [[agents/]] — Agent execution logs
- [[references/]] — Reference materials
KVEOF
  if [ -f ".gitignore" ] && ! grep -q '\.briefing/' ".gitignore" 2>/dev/null; then
    echo '.briefing/' >> ".gitignore"
  elif [ ! -f ".gitignore" ]; then
    echo '.briefing/' > ".gitignore"
  fi
  _kv_msg="[BriefingVault] Auto-created .briefing/ structure. Log decisions, learnings, sessions per rules/common/briefing-vault.md."
else
  _kv_recent=$(grep -E '^\- \[\[' "$_kv_dir/INDEX.md" 2>/dev/null | head -5 | tr '\n' '; ')
  if [ -n "$_kv_recent" ]; then
    _kv_msg="[BriefingVault] .briefing/INDEX.md loaded. Recent: ${_kv_recent}Log decisions→.briefing/decisions/, learnings→.briefing/learnings/, sessions→.briefing/sessions/, agent logs→.briefing/agents/."
  else
    _kv_msg="[BriefingVault] .briefing/INDEX.md exists. Log decisions/learnings/sessions per rules/common/briefing-vault.md."
  fi
fi

# Return results as additionalContext
MSG=""
if [ ${#INSTALLED[@]} -gt 0 ]; then
  MSG="[SessionStart] Auto-installed: ${INSTALLED[*]}. "
fi
if [ ${#MISSING[@]} -gt 0 ]; then
  MSG="${MSG}[SessionStart] Missing (run install.sh): ${MISSING[*]}."
fi

MSG="${MSG}[SessionStart] Registry cache: ${REGISTRY_STATUS}."
[ -n "$_kv_msg" ] && MSG="${MSG} ${_kv_msg}"
if [ -n "$MSG" ]; then
  echo "{\"hookSpecificOutput\":{\"additionalContext\":\"$MSG\"}}"
fi
