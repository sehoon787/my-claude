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

# 5b. .knowledge → .briefing migration (one-time, backward compat)
if [ -d ".knowledge" ]; then
  if [ ! -d ".briefing" ]; then
    # Simple rename
    mv ".knowledge" ".briefing"
    mkdir -p ".briefing/persona/rules"
    # Add language field to INDEX.md if missing
    if [ -f ".briefing/INDEX.md" ] && ! grep -q '^language:' ".briefing/INDEX.md"; then
      sed -i '/^type:/a language: en' ".briefing/INDEX.md" 2>/dev/null || true
    fi
    # Update .gitignore
    if [ -f ".gitignore" ]; then
      sed -i '/^\.knowledge\//d' ".gitignore" 2>/dev/null || true
      grep -q '\.briefing/' ".gitignore" 2>/dev/null || echo '.briefing/' >> ".gitignore"
    fi
  else
    # Both exist — merge unique files from .knowledge into .briefing, then remove
    for _subdir in sessions decisions learnings agents references; do
      if [ -d ".knowledge/$_subdir" ]; then
        mkdir -p ".briefing/$_subdir"
        for _file in ".knowledge/$_subdir"/*; do
          [ -f "$_file" ] || continue
          _bname=$(basename "$_file")
          [ ! -f ".briefing/$_subdir/$_bname" ] && cp "$_file" ".briefing/$_subdir/$_bname"
        done
      fi
    done
    rm -rf ".knowledge"
    mkdir -p ".briefing/persona/rules"
    if [ -f ".gitignore" ]; then
      sed -i '/^\.knowledge\//d' ".gitignore" 2>/dev/null || true
      grep -q '\.briefing/' ".gitignore" 2>/dev/null || echo '.briefing/' >> ".gitignore"
    fi
  fi
fi

# 6. Briefing Vault Auto-Create + Context
_kv_msg=""
_kv_dir=".briefing"
if [ ! -f "$_kv_dir/INDEX.md" ]; then
  mkdir -p "$_kv_dir/sessions" "$_kv_dir/decisions" "$_kv_dir/learnings" "$_kv_dir/agents" "$_kv_dir/references" "$_kv_dir/persona/rules"
  # Save git HEAD and reset session counters in state.json
  _head_sha=$(git rev-parse HEAD 2>/dev/null || echo "")
  _session_id="$_head_sha"
  if [ -z "$_session_id" ]; then
    _session_id="$(date +%Y-%m-%d):$(pwd)"
  fi
  node -e "var f='$_kv_dir/state.json',s={};try{s=JSON.parse(require('fs').readFileSync(f,'utf8'))}catch(e){}Object.assign(s,{date:'$(date +%Y-%m-%d)',sessionStartHead:'$_session_id',sessionMessageCount:0,workCounter:0,profileUpdateCounter:0,prevEntryCount:0,subagentSeq:0});require('fs').writeFileSync(f,JSON.stringify(s,null,2))" 2>/dev/null || true
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
  # Migrate old dot-files to state.json (one-time, backward compat)
  if [ ! -f "$_kv_dir/state.json" ] && [ -f "$_kv_dir/.session-start-head" ]; then
    node -e "
      var fs=require('fs'),f='$_kv_dir/state.json',s={};
      function r(p){try{return fs.readFileSync('$_kv_dir/'+p,'utf8').trim()}catch(e){return ''}}
      s.sessionStartHead=r('.session-start-head');
      s.lastCountedSession=r('.last-counted-session');
      s.sessionMessageCount=parseInt(r('.session-message-count'))||0;
      s.profileUpdateCounter=parseInt(r('.profile-update-counter'))||0;
      s.workCounter=parseInt(r('.work-counter'))||0;
      s.prevEntryCount=parseInt(r('.prev-entry-count'))||0;
      fs.writeFileSync(f,JSON.stringify(s,null,2));
      ['.session-start-head','.last-counted-session','.session-message-count','.profile-update-counter','.work-counter','.prev-entry-count'].forEach(function(p){try{fs.unlinkSync('$_kv_dir/'+p)}catch(e){}});
    " 2>/dev/null || true
  fi
  # Gap detection: check previous session date
  _prev_date=""
  if [ -f "$_kv_dir/state.json" ]; then
    _prev_date=$(node -e "try{var s=JSON.parse(require('fs').readFileSync('$_kv_dir/state.json','utf8'));console.log(s.date||'')}catch(e){}" 2>/dev/null)
  fi
  _today=$(date +%Y-%m-%d)
  if [ -n "$_prev_date" ] && [ "$_prev_date" != "$_today" ]; then
    _gap_msg="[BriefingVault] Previous session: ${_prev_date}. Run /boss-briefing for recovery."
    _kv_msg="${_kv_msg} ${_gap_msg}"
  fi
  # Save git HEAD and reset session counters in state.json
  _head_sha=$(git rev-parse HEAD 2>/dev/null || echo "")
  _session_id="$_head_sha"
  if [ -z "$_session_id" ]; then
    _session_id="$(date +%Y-%m-%d):$(pwd)"
  fi
  node -e "var f='$_kv_dir/state.json',s={};try{s=JSON.parse(require('fs').readFileSync(f,'utf8'))}catch(e){}Object.assign(s,{date:'$_today',sessionStartHead:'$_session_id',sessionMessageCount:0,workCounter:0,profileUpdateCounter:0,prevEntryCount:0,subagentSeq:0});require('fs').writeFileSync(f,JSON.stringify(s,null,2))" 2>/dev/null || true
  # Add language field to INDEX.md if missing
  if ! grep -q '^language:' "$_kv_dir/INDEX.md" 2>/dev/null; then
    sed -i '/^type:/a language: en' "$_kv_dir/INDEX.md" 2>/dev/null || true
  fi
  _kv_recent=$(grep -E '^\- \[\[' "$_kv_dir/INDEX.md" 2>/dev/null | head -5 | tr '\n' '; ')
  if [ -n "$_kv_recent" ]; then
    _kv_msg="[BriefingVault] .briefing/INDEX.md loaded. Recent: ${_kv_recent}Log decisions→.briefing/decisions/, learnings→.briefing/learnings/, sessions→.briefing/sessions/, agent logs→.briefing/agents/."
  else
    _kv_msg="[BriefingVault] .briefing/INDEX.md exists. Log decisions/learnings/sessions per rules/common/briefing-vault.md."
  fi
fi

# 7. Persona: Pending Suggestions Notification
_sug_file="$_kv_dir/persona/suggestions.jsonl"
if [ -f "$_sug_file" ]; then
  _pending_count=0
  while IFS= read -r _line; do
    case "$_line" in *'"type":"pending"'*|*'"type": "pending"'*) _pending_count=$((_pending_count + 1)) ;; esac
  done < "$_sug_file"
  if [ "$_pending_count" -gt 0 ]; then
    _kv_msg="${_kv_msg} [BriefingVault] ${_pending_count} pending persona suggestion(s). Run: node hooks/persona-rule.js list"
  fi
fi

# 8. Persona: Active Rules Summary
_rules_dir="$_kv_dir/persona/rules"
if [ -d "$_rules_dir" ]; then
  _rule_names=""
  for _rf in "$_rules_dir"/*.md; do
    [ -f "$_rf" ] || continue
    _rname=$(basename "$_rf" .md)
    if [ -z "$_rule_names" ]; then
      _rule_names="$_rname"
    else
      _rule_names="$_rule_names, $_rname"
    fi
  done
  if [ -n "$_rule_names" ]; then
    _kv_msg="${_kv_msg} [BriefingVault] Active persona rules: ${_rule_names}"
  fi
fi


# 10. Version Freshness Check (once per day, non-blocking)
_update_msg=""
_vc_stamp="$HOME/.claude/.my-claude-update-check"
_vc_today=$(date +%Y-%m-%d)
_vc_last=""
[ -f "$_vc_stamp" ] && _vc_last=$(head -1 "$_vc_stamp" 2>/dev/null)
if [ "$_vc_today" != "$_vc_last" ]; then
  _vc_installed_sha=""
  [ -f "$HOME/.claude/.my-claude-installed-sha" ] && _vc_installed_sha=$(cat "$HOME/.claude/.my-claude-installed-sha" 2>/dev/null)
  if [ -n "$_vc_installed_sha" ]; then
    _vc_remote_sha=$(git ls-remote https://github.com/sehoon787/my-claude.git HEAD 2>/dev/null | cut -f1 | head -c 12)
    if [ -n "$_vc_remote_sha" ] && [ "${_vc_installed_sha}" != "${_vc_remote_sha}" ]; then
      # Auto-update hooks/scripts only (lightweight, <5s)
      _repo_dir=""
      if [ -f "$HOME/.claude/.my-claude-manifest" ]; then
        _repo_dir=$(head -1 "$HOME/.claude/.my-claude-manifest" 2>/dev/null | grep -o '/.*my-claude' | head -1)
      fi
      # Fallback: check common locations
      if [ -z "$_repo_dir" ] || [ ! -d "$_repo_dir" ]; then
        for _candidate in "$HOME/Desktop/proj/my-claude" "$HOME/projects/my-claude" "$HOME/my-claude"; do
          if [ -d "$_candidate/.git" ] && [ -f "$_candidate/hooks/hooks.json" ]; then
            _repo_dir="$_candidate"
            break
          fi
        done
      fi

      if [ -n "$_repo_dir" ] && [ -d "$_repo_dir/.git" ]; then
        # Pull latest (fast-forward only, non-blocking)
        _pull_result=$(cd "$_repo_dir" && git pull --ff-only 2>&1) || true

        # Copy hooks and scripts
        if [ -d "$_repo_dir/hooks" ]; then
          cp "$_repo_dir/hooks/hooks.json" "$HOME/.claude/hooks/hooks.json" 2>/dev/null || true
          for _hf in "$_repo_dir/hooks/"*.js; do
            [ -f "$_hf" ] && cp "$_hf" "$HOME/.claude/hooks/" 2>/dev/null || true
          done
          for _hf in "$_repo_dir/hooks/"*.sh; do
            [ -f "$_hf" ] && cp "$_hf" "$HOME/.claude/hooks/" 2>/dev/null || true
          done
        fi

        # Update HUD wrapper from upstream (if available)
        _hud_src="$_repo_dir/upstream/omc/scripts/lib/hud-wrapper-template.txt"
        if [ -f "$_hud_src" ]; then
          mkdir -p "$HOME/.claude/hud/lib"
          cp "$_hud_src" "$HOME/.claude/hud/omc-hud.mjs" 2>/dev/null || true
          cp "$_repo_dir/upstream/omc/scripts/lib/config-dir.mjs" "$HOME/.claude/hud/lib/config-dir.mjs" 2>/dev/null || true
          chmod +x "$HOME/.claude/hud/omc-hud.mjs" 2>/dev/null || true
        fi

        # Sync OMC npm package to plugin cache (HUD reads from cache first)
        _omc_npm="$(npm root -g 2>/dev/null)/oh-my-claude-sisyphus"
        _omc_cache="$HOME/.claude/plugins/cache/omc/oh-my-claudecode"
        if [ -d "$_omc_npm/dist" ]; then
          _omc_v="$(node -e "console.log(require('$_omc_npm/package.json').version)" 2>/dev/null || echo "")"
          if [ -n "$_omc_v" ] && [ ! -d "$_omc_cache/$_omc_v/dist" ]; then
            mkdir -p "$_omc_cache/$_omc_v"
            cp -r "$_omc_npm/"* "$_omc_cache/$_omc_v/" 2>/dev/null || true
          fi
        fi

        # Merge hooks into settings.json
        if [ -f "$_repo_dir/scripts/merge-hooks.js" ]; then
          node "$_repo_dir/scripts/merge-hooks.js" "$HOME/.claude/hooks/hooks.json" 2>/dev/null || true
        fi

        # Refresh settings (boss default, statusLine, MCP)
        if [ -f "$_repo_dir/scripts/merge-settings.js" ]; then
          node "$_repo_dir/scripts/merge-settings.js" 2>/dev/null || true
        fi

        # Update installed SHA
        _new_sha=$(cd "$_repo_dir" && git rev-parse --short=12 HEAD 2>/dev/null)
        if [ -n "$_new_sha" ]; then
          echo "$_new_sha" > "$HOME/.claude/.my-claude-installed-sha"
        fi

        _update_msg="[UpdateCheck] my-claude hooks auto-updated (${_vc_installed_sha} → ${_new_sha:-unknown})"
      else
        _vc_current=$(cat "$HOME/.claude/.my-claude-version" 2>/dev/null || echo "unknown")
        _update_msg="[UpdateCheck] my-claude update available (installed: v${_vc_current}). Run: cd <my-claude-repo> && bash install.sh"
      fi
    fi
    echo "$_vc_today" > "$_vc_stamp" 2>/dev/null || true
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
[ -n "$_update_msg" ] && MSG="${MSG} ${_update_msg}"
if [ -n "$MSG" ]; then
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"SessionStart\",\"additionalContext\":\"$MSG\"}}"
fi
