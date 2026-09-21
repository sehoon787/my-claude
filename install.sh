#!/usr/bin/env bash
# my-claude full installer — copies plugin files + registers MCP + installs companion tools
# Usage: bash install.sh
set -euo pipefail

# Cross-platform SHA-256 checksum
sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    echo "no-sha256-tool"
  fi
}

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Which upstream skills/rules this installer copies — see scripts/skill-allowlists.sh
# shellcheck source=scripts/skill-allowlists.sh
. "$SCRIPT_DIR/scripts/skill-allowlists.sh"

echo "=== my-claude installer ==="
echo ""

# ── 0. Prerequisites ──
echo "[0/6] Checking prerequisites..."
command -v node >/dev/null 2>&1 || { echo "ERROR: node not found. Install Node.js v20+"; exit 1; }
command -v npm  >/dev/null 2>&1 || { echo "ERROR: npm not found"; exit 1; }
command -v git  >/dev/null 2>&1 || { echo "ERROR: git not found"; exit 1; }
echo "  Prerequisites OK"

# ── Argument parsing ──
SKIP_ECC=0
SKIP_OMC=0
SKIP_GSTACK=0
SKIP_SUPERPOWERS=0
SKIP_ARCHIFY=0
# Companion CLI tools. Each is selected on its own; the prompt below asks which
# ones, and --skip-tools / --yes / --tools= answer that question up front.
# Default (including every unattended run) stays what it has always been: all.
INSTALL_SERENA=1
INSTALL_HEADROOM=1
INSTALL_CODEBURN=1
SKIP_TOOLS=0
TOOLS_SELECTION=""
TOOLS_ANSWERED=0
# Optional skill lanes (see scripts/skill-allowlists.sh). Empty = default install.
# Precedence: CLI flag > MY_CLAUDE_SKILLS env > ~/.claude/.my-claude-skills.
SKILL_LANES=""
SKILL_LANES_SET=0
for arg in "$@"; do
  case "$arg" in
    --skip-ecc)        SKIP_ECC=1 ;;
    --skip-omc)        SKIP_OMC=1 ;;
    --skip-gstack)     SKIP_GSTACK=1 ;;
    --skip-superpowers) SKIP_SUPERPOWERS=1 ;;
    --skip-archify)    SKIP_ARCHIFY=1 ;;
    --skip-tools)      SKIP_TOOLS=1; TOOLS_ANSWERED=1 ;;
    --yes)             TOOLS_ANSWERED=1 ;;
    --tools=*)         TOOLS_SELECTION="${arg#--tools=}"; TOOLS_ANSWERED=1 ;;
    --self-only)       SKIP_ECC=1; SKIP_OMC=1; SKIP_GSTACK=1; SKIP_SUPERPOWERS=1; SKIP_ARCHIFY=1 ;;
    --skills=*)        SKILL_LANES="${arg#--skills=}"; SKILL_LANES_SET=1 ;;
    --full-skills)     SKILL_LANES="$ECC_SKILL_OPTIONAL_LANES"; SKILL_LANES_SET=1 ;;
    --with-codeburn-guard) WITH_CODEBURN_GUARD=1 ;;
    -h|--help)
      cat <<'EOF'
Usage:
  bash install.sh

Options:
  --skip-ecc              Skip everything-claude-code upstream install
  --skip-omc              Skip oh-my-claudecode upstream install
  --skip-gstack           Skip gstack upstream install
  --skip-superpowers      Skip superpowers upstream install
  --skip-archify          Skip the archify diagram skill install
  --skip-tools            Skip every companion tool (same as --tools=none)
  --yes                   Install every companion tool without asking (same as --tools=all)
  --tools=<list>          Choose companion tools without asking: all | none |
                          any mix of serena, headroom, codeburn (e.g.
                          --tools=serena,codeburn)
  --self-only             Install only self-owned files (implies all upstream --skip-* flags)
  --skills=<lane[,lane]>  Also install optional skill lanes (available: web)
  --full-skills           Install every optional skill lane
  --with-codeburn-guard   Install the opt-in codeburn budget-guard hooks

Environment:
  MY_CLAUDE_SKILLS=web    Same as --skills=web

The chosen lanes are saved to ~/.claude/.my-claude-skills, so a later plain
`bash install.sh` keeps them. Pass --skills= (empty) to go back to the default.
EOF
      exit 0
      ;;
  esac
done

# ── Optional skill lanes ──
# A choice made on any earlier run is remembered; an explicit flag or env var on
# this run replaces it (including `--skills=` to clear it back to the default).
SKILL_LANES_FILE="$HOME/.claude/.my-claude-skills"
if [ "$SKILL_LANES_SET" = "0" ]; then
  if [ -n "${MY_CLAUDE_SKILLS:-}" ]; then
    SKILL_LANES="$MY_CLAUDE_SKILLS"
    SKILL_LANES_SET=1
  elif [ -f "$SKILL_LANES_FILE" ]; then
    SKILL_LANES=$(head -1 "$SKILL_LANES_FILE" 2>/dev/null || echo "")
  fi
fi
# Expand the comma list into the concrete extra skill names.
ECC_EXTRA_SKILLS=""
for _lane in $(printf '%s' "$SKILL_LANES" | tr ',' ' '); do
  case "$_lane" in
    web) ECC_EXTRA_SKILLS="$ECC_EXTRA_SKILLS $ECC_SKILL_OPTIONAL_WEB" ;;
    "")  ;;
    *)   echo "  WARNING: unknown skill lane '$_lane' (available: $ECC_SKILL_OPTIONAL_LANES)" ;;
  esac
done
if [ -n "$(printf '%s' "$ECC_EXTRA_SKILLS" | tr -d '[:space:]')" ]; then
  echo "  Optional skill lanes: $SKILL_LANES"
else
  echo "  Optional skill lanes: none (default install; add with --skills=web)"
fi

# ── Version info ──
INSTALLING_VERSION=$(node "$SCRIPT_DIR/scripts/get-version.js" "$SCRIPT_DIR/.claude-plugin/plugin.json" 2>/dev/null)
INSTALLED_VERSION="none"
if [ -f "$HOME/.claude/.my-claude-version" ]; then
  INSTALLED_VERSION=$(cat "$HOME/.claude/.my-claude-version")
fi
if [ "$INSTALLED_VERSION" = "none" ]; then
  echo "  Fresh install: v${INSTALLING_VERSION}"
elif [ "$INSTALLED_VERSION" = "$INSTALLING_VERSION" ]; then
  echo "  Reinstalling: v${INSTALLING_VERSION} (same version)"
else
  echo "  Updating: v${INSTALLED_VERSION} → v${INSTALLING_VERSION}"
fi

# ── Companion tools ──
# Asked once, before any installation work, so that a "no" costs nothing.

# Read one selection — "all", "none", or any comma/space separated mix of the
# numbers 1/2/3 and the names serena/headroom/codeburn — into the three
# INSTALL_* variables. Returns 1 on an unrecognised token, leaving them as they
# were, so a bad answer can simply be asked again.
parse_tool_selection() {
  local _raw _token _serena=0 _headroom=0 _codeburn=0
  _raw=$(printf '%s' "$1" | tr 'A-Z' 'a-z' | tr ',' ' ')
  case "$(printf '%s' "$_raw" | tr -d '[:space:]')" in
    ""|all|a)  INSTALL_SERENA=1; INSTALL_HEADROOM=1; INSTALL_CODEBURN=1; return 0 ;;
    none|n|0)  INSTALL_SERENA=0; INSTALL_HEADROOM=0; INSTALL_CODEBURN=0; return 0 ;;
  esac
  for _token in $_raw; do
    case "$_token" in
      1|serena)   _serena=1 ;;
      2|headroom) _headroom=1 ;;
      3|codeburn) _codeburn=1 ;;
      *)          return 1 ;;
    esac
  done
  INSTALL_SERENA=$_serena
  INSTALL_HEADROOM=$_headroom
  INSTALL_CODEBURN=$_codeburn
}

# Names of the tools whose INSTALL_* flag equals $1 (1 = selected, 0 = skipped),
# as a comma-separated list. Empty when none match.
tool_names_with() {
  _want="$1"; _names=""
  if [ "$INSTALL_SERENA"   = "$_want" ]; then _names="$_names, serena"; fi
  if [ "$INSTALL_HEADROOM" = "$_want" ]; then _names="$_names, headroom"; fi
  if [ "$INSTALL_CODEBURN" = "$_want" ]; then _names="$_names, codeburn"; fi
  printf '%s' "${_names#, }"
}

# --tools= is the explicit answer; --skip-tools still means "none" and wins over
# it, and --yes leaves the install-everything default alone.
if [ -n "$TOOLS_SELECTION" ]; then
  parse_tool_selection "$TOOLS_SELECTION" || {
    echo "ERROR: unrecognised --tools=$TOOLS_SELECTION" >&2
    echo "       expected: all | none | any mix of serena, headroom, codeburn" >&2
    exit 1
  }
fi
if [ "$SKIP_TOOLS" = "1" ]; then
  INSTALL_SERENA=0; INSTALL_HEADROOM=0; INSTALL_CODEBURN=0
fi

# The prompt is skipped whenever an answer cannot be read back (no TTY, CI) or
# has already been given (--skip-tools / --yes / --tools=); the unattended
# default stays what it has always been: install everything.
if [ "$TOOLS_ANSWERED" = "0" ] && [ -t 0 ] && [ -z "${CI:-}" ]; then
  echo ""
  echo "Optional companion tools — the harness works without them:"
  echo "  1) serena    — symbol-level code navigation over MCP (uv tool)"
  echo "  2) headroom  — tool-output compression over MCP (uv tool)"
  echo "  3) codeburn  — token/cost tracking with a local dashboard (npm)"
  _tools_tries=0
  while :; do
    printf 'Select: all / none / numbers like "1,3"  [all]: '
    # EOF (closed stdin mid-run) is not an answer: take the unattended default
    # rather than re-asking a question nobody can answer.
    if ! read -r _tools_answer; then
      echo ""
      INSTALL_SERENA=1; INSTALL_HEADROOM=1; INSTALL_CODEBURN=1
      break
    fi
    if parse_tool_selection "$_tools_answer"; then
      break
    fi
    _tools_tries=$((_tools_tries + 1))
    if [ "$_tools_tries" -ge 3 ]; then
      echo "  Still unrecognised after 3 tries — installing all three."
      INSTALL_SERENA=1; INSTALL_HEADROOM=1; INSTALL_CODEBURN=1
      break
    fi
    echo "  Unrecognised: '$_tools_answer'. Enter all, none, or numbers/names like 1,3."
  done
  echo ""
fi

TOOLS_SELECTED="$(tool_names_with 1)"
TOOLS_SKIPPED="$(tool_names_with 0)"
if [ -z "$TOOLS_SELECTED" ]; then
  echo "  Companion tools: skipped ($TOOLS_SKIPPED)"
elif [ -n "$TOOLS_SKIPPED" ]; then
  echo "  Companion tools: installing $TOOLS_SELECTED; skipping $TOOLS_SKIPPED"
fi

# ── 0b. tmux (optional — used by omc qa-tester; Agent Teams run in-process) ──
echo "[0b] Checking tmux..."
if command -v tmux >/dev/null 2>&1; then
  echo "  tmux found: $(tmux -V)"
  TMUX_AVAILABLE=1
else
  echo "  tmux not found. Attempting install..."
  TMUX_AVAILABLE=0

  if [[ "$OSTYPE" == "darwin"* ]]; then
    if command -v brew >/dev/null 2>&1; then
      brew install tmux 2>/dev/null && TMUX_AVAILABLE=1 || true
    fi
  elif [[ -f /etc/os-release ]]; then
    if command -v apt-get >/dev/null 2>&1; then
      sudo apt-get install -y tmux 2>/dev/null && TMUX_AVAILABLE=1 || true
    elif command -v dnf >/dev/null 2>&1; then
      sudo dnf install -y tmux 2>/dev/null && TMUX_AVAILABLE=1 || true
    elif command -v pacman >/dev/null 2>&1; then
      sudo pacman -S --noconfirm tmux 2>/dev/null && TMUX_AVAILABLE=1 || true
    fi
  fi

  if [ "$TMUX_AVAILABLE" = "1" ]; then
    echo "  tmux installed: $(tmux -V)"
  else
    echo "  tmux install failed — optional, no action needed"
  fi
fi

# ── Upstream helper ──
CLONE_TMPDIR=$(mktemp -d)
trap 'rm -rf "$CLONE_TMPDIR"' EXIT

# Provenance-tracked manifest: every path this script actually copies gets
# appended here (relative to $HOME/.claude). The manifest is NEVER built by
# scanning destination directories — that would also capture user-owned files
# that happen to live alongside managed ones (e.g. a custom agent dropped
# directly into ~/.claude/agents/), which would then be deleted on a later
# update. See MANIFEST_TMP write-outs throughout this script.
MANIFEST_TMP="$CLONE_TMPDIR/new-manifest.txt"
: > "$MANIFEST_TMP"

# Record every file a directory copy actually placed under $HOME/.claude.
# `cp -r <dir>` installs the whole subtree, so recording just the top-level
# SKILL.md left every other file (references/, scripts/, nested dirs)
# unmanaged: the manifest-diff cleanup below deleted the SKILL.md and left the
# rest behind as husk directories on every update. Paths are emitted relative
# to $HOME/.claude with forward slashes — the exact format the cleanup reads.
# It enumerates the destination subtree immediately after the copy, which only
# stays equivalent to the source while nothing else writes into that directory.
# A skill the agent runs `npm install` inside (archify) manifests from its
# source tree instead, so runtime files there stay user-owned.
manifest_dir() {
  local rel="$1"
  [ -d "$HOME/.claude/$rel" ] || return 0
  ( cd "$HOME/.claude" && find "$rel" -type f ) >> "$MANIFEST_TMP" || true
}

UPSTREAM_DIR=""
init_upstream() {
  local name="$1" url="$2" pinned_ref="${3:-}"
  local submod_path="$SCRIPT_DIR/upstream/$name"
  if [ -d "$submod_path/.git" ] || [ -f "$submod_path/.git" ]; then
    # Use the checked-out (pinned) submodule SHA as-is. Upstream updates land
    # deliberately via update-upstream.yml (PR + security review), never
    # silently at install time.
    UPSTREAM_DIR="$submod_path"
    return 0
  fi
  if git -C "$SCRIPT_DIR" submodule update --init --depth 1 "upstream/$name" 2>/dev/null; then
    UPSTREAM_DIR="$submod_path"
    return 0
  fi
  echo "  WARNING: submodule init failed for $name, falling back to git clone..."
  UPSTREAM_DIR="$CLONE_TMPDIR/$name"
  # A tag-pinned upstream keeps its pin on this path too: cloning the default
  # branch here would quietly install a different release than the submodule.
  if [ -n "$pinned_ref" ]; then
    git clone --depth 1 --branch "$pinned_ref" "$url" "$UPSTREAM_DIR" 2>/dev/null || return 1
  else
    git clone --depth 1 "$url" "$UPSTREAM_DIR" 2>/dev/null || return 1
  fi
}

# ── 1. Plugin files (agents, skills, rules) ──
echo "[1/6] Installing plugin files..."
# Tiered agent structure:
#   ~/.claude/agents/      → core only (always loaded): core + omc + omo + vendored
#   ~/.claude/docs/nexus/  → reference material (never parsed as agents)
mkdir -p "$HOME/.claude/agents" "$HOME/.claude/skills" "$HOME/.claude/rules"

# Manifest-based cleanup: remove only files from previous my-claude install.
# Diff behavior: every file recorded in the OLD manifest is deleted here; the
# copy steps below then recreate whichever of those paths are still part of
# the current install. Anything the old manifest listed but this run does not
# recreate stays deleted (stale). Files never listed in the manifest (i.e.
# user-owned) are never touched, because we never delete-by-directory-scan.
if [ -f "$HOME/.claude/.my-claude-manifest" ]; then
  while IFS= read -r rel_path; do
    target="$HOME/.claude/$rel_path"
    [ -f "$target" ] && rm -f "$target"
  done < "$HOME/.claude/.my-claude-manifest"
  # Prune directories the deletions above emptied. Scoped strictly to
  # directories that appear in the manifest — never a blanket prune of
  # ~/.claude — and deepest-first (longest path first), so nested husks
  # collapse before their parents. Top-level roots (agents/, skills/, rules/,
  # ...) are deliberately excluded: later copy steps write into them. rmdir
  # only succeeds on an already-empty directory, so user-owned files sitting
  # alongside managed ones keep their directory alive.
  awk -F/ 'NF>1 { p=$1; for (i=2;i<NF;i++) { p=p"/"$i; print p } }' "$HOME/.claude/.my-claude-manifest" \
    | sort -u \
    | awk '{ print length($0) "\t" $0 }' | sort -rn -k1,1 | cut -f2- \
    | while IFS= read -r rel_dir; do
        rmdir "$HOME/.claude/$rel_dir" 2>/dev/null || true
      done
  # Remove empty agent-pack directories (only if empty after cleanup)
  find "$HOME/.claude/agent-packs" -type d -empty -delete 2>/dev/null || true
else
  echo "  No previous manifest found — skipping stale-file cleanup (safe default for first-time or legacy installs)"
fi

mkdir -p "$HOME/.claude/docs/nexus"

# ── 1a. Self-owned files (always installed) ──
echo "  [core] Installing self-owned files..."

# agents — core tier (always loaded)
find "$SCRIPT_DIR/agents/core" -maxdepth 1 -name '*.md' ! -name 'agent-teams-reference.md' -exec cp {} "$HOME/.claude/agents/" \;
find "$SCRIPT_DIR/agents/core" -maxdepth 1 -name '*.md' ! -name 'agent-teams-reference.md' -exec sh -c 'echo "agents/$(basename "$1")"' _ {} \; >> "$MANIFEST_TMP"
cp "$SCRIPT_DIR"/agents/omo/*.md "$HOME/.claude/agents/"
for f in "$SCRIPT_DIR"/agents/omo/*.md; do [ -f "$f" ] && echo "agents/$(basename "$f")" >> "$MANIFEST_TMP"; done

# skills/core
if [ -d "$SCRIPT_DIR/skills/core" ]; then
  for src in "$SCRIPT_DIR"/skills/core/*/; do
    [ ! -d "$src" ] && continue
    name=$(basename "$src")
    target="$HOME/.claude/skills/$name"
    if [ -L "$target" ] || { [ -e "$target" ] && [ ! -d "$target" ]; }; then
      rm -f "$target"
    fi
  done
  cp -r "$SCRIPT_DIR"/skills/core/* "$HOME/.claude/skills/"
  for src in "$SCRIPT_DIR"/skills/core/*/; do
    [ ! -d "$src" ] && continue
    manifest_dir "skills/$(basename "$src")"
  done
fi

# workflows — named deterministic workflows, user-scope (~/.claude/workflows/).
# Invoke via Workflow({name: "code-review-fanout"}) etc. from any project.
if [ -d "$SCRIPT_DIR/workflows" ]; then
  mkdir -p "$HOME/.claude/workflows"
  for wf in "$SCRIPT_DIR"/workflows/*.js; do
    [ -f "$wf" ] || continue
    cp "$wf" "$HOME/.claude/workflows/"
    echo "workflows/$(basename "$wf")" >> "$MANIFEST_TMP"
  done
fi

# docs/nexus — reference material (never parsed as agents)
cp "$SCRIPT_DIR/agents/core/agent-teams-reference.md" "$HOME/.claude/docs/nexus/"
echo "docs/nexus/agent-teams-reference.md" >> "$MANIFEST_TMP"

# ── 1b. Vendored third-party agents (kept in-tree, always loaded) ──
cp "$SCRIPT_DIR"/agents/vendored/*.md "$HOME/.claude/agents/"
for f in "$SCRIPT_DIR"/agents/vendored/*.md; do [ -f "$f" ] && echo "agents/$(basename "$f")" >> "$MANIFEST_TMP"; done

# ── 1c. ECC upstream ──
if [ "$SKIP_ECC" = "0" ]; then
  echo "  [ecc] Installing everything-claude-code..."
  if ! claude plugin add affaan-m/everything-claude-code 2>/dev/null; then
    if init_upstream "ecc" "https://github.com/affaan-m/everything-claude-code"; then
      # Allowlisted skills only — $ECC_SKILL_ALLOWLIST (scripts/skill-allowlists.sh)
      for name in $ECC_SKILL_ALLOWLIST $ECC_EXTRA_SKILLS; do
        src="$UPSTREAM_DIR/skills/$name"
        [ -d "$src" ] || continue
        target="$HOME/.claude/skills/$name"
        # Pre-clean: resolve file/symlink vs directory conflicts
        if [ -L "$target" ] || { [ -e "$target" ] && [ ! -d "$target" ]; }; then
          rm -f "$target"
        fi
        cp -r "$src" "$HOME/.claude/skills/"
        manifest_dir "skills/$name"
      done
      # continuous-learning v1 is self-declared deprecated in favor of v2; never
      # allowlisted — this also clears copies left by pre-allowlist installs.
      rm -rf "$HOME/.claude/skills/continuous-learning"
      # Allowlisted language rule dirs only — $ECC_RULES_ALLOWLIST
      for name in $ECC_RULES_ALLOWLIST; do
        src="$UPSTREAM_DIR/rules/$name"
        [ -d "$src" ] || continue
        cp -r "$src" "$HOME/.claude/rules/"
        manifest_dir "rules/$name"
      done
      # rules/common is injected into every session, so it is allowlisted per
      # file — $ECC_RULES_COMMON_ALLOWLIST — not copied wholesale. Files dropped
      # from that list are manifest-owned and disappear on the next install.
      if [ -d "$UPSTREAM_DIR/rules/common" ]; then
        mkdir -p "$HOME/.claude/rules/common"
        for rule_file in $ECC_RULES_COMMON_ALLOWLIST; do
          [ -f "$UPSTREAM_DIR/rules/common/$rule_file" ] || continue
          cp "$UPSTREAM_DIR/rules/common/$rule_file" "$HOME/.claude/rules/common/"
          echo "rules/common/$rule_file" >> "$MANIFEST_TMP"
        done
      fi
    else
      echo "  WARNING: ECC install failed"
    fi
  fi
fi

# ── 1c-post. Self-owned rules (override ECC rules if same name) ──
if [ -d "$SCRIPT_DIR/rules" ]; then
  cp -r "$SCRIPT_DIR"/rules/* "$HOME/.claude/rules/" 2>/dev/null || true
  for src in "$SCRIPT_DIR"/rules/*; do
    [ -e "$src" ] || continue
    name=$(basename "$src")
    if [ -d "$src" ]; then
      manifest_dir "rules/$name"
    else
      echo "rules/$name" >> "$MANIFEST_TMP"
    fi
  done
fi

# ── 1d. OMC upstream ──
if [ "$SKIP_OMC" = "0" ]; then
  echo "  [omc] Installing oh-my-claudecode..."
  if init_upstream "omc" "https://github.com/Yeachan-Heo/oh-my-claudecode"; then
    # Check if OMC plugin is installed (provides agents/skills natively)
    _omc_plugin_active=0
    if [ -d "$HOME/.claude/plugins/cache/omc/oh-my-claudecode" ]; then
      for _pv in "$HOME/.claude/plugins/cache/omc/oh-my-claudecode"/*/; do
        [ -d "$_pv" ] && _omc_plugin_active=1 && break
      done
    fi
    if [ "$_omc_plugin_active" = "1" ]; then
      echo "  [omc] Plugin detected — skipping agent file copy (plugin provides agents)"
    else
      find "$UPSTREAM_DIR/agents" -maxdepth 1 -name '*.md' -exec cp {} "$HOME/.claude/agents/" \;
      find "$UPSTREAM_DIR/agents" -maxdepth 1 -name '*.md' -exec sh -c 'echo "agents/$(basename "$1")"' _ {} \; >> "$MANIFEST_TMP"
    fi
    # OMC skills are never copied into ~/.claude/skills/. The OMC plugin exposes
    # all of them as `oh-my-claudecode:<name>`; a bare local copy would add a
    # second description of the same skill to every session's context. See
    # $OMC_PLUGIN_SKILL_NAMES in scripts/skill-allowlists.sh for the routing
    # names. Copies left by older installs are manifest-owned and are removed by
    # the cleanup at the top of step 1.
  else
    echo "  WARNING: OMC install failed"
  fi
fi

# ── 1e. gstack upstream ──
if [ "$SKIP_GSTACK" = "0" ]; then
  echo "  [gstack] Installing gstack skills..."

  # 1) Remove ECC skills superseded by gstack (before gstack copy)
  for skill in benchmark canary-watch safety-guard browser-qa verification-loop security-review design-system; do
    target="$HOME/.claude/skills/$skill"
    if [ -L "$target" ]; then
      rm -f "$target"
    elif [ -d "$target" ]; then
      rm -rf "$target"
    fi
  done

  if init_upstream "gstack" "https://github.com/garrytan/gstack"; then
    # Pre-clean: resolve file/symlink vs directory conflicts
    for name in gstack $GSTACK_SKILL_ALLOWLIST; do
      target="$HOME/.claude/skills/$name"
      if [ -L "$target" ] || { [ -e "$target" ] && [ ! -d "$target" ]; }; then
        rm -f "$target"
      fi
    done

    # Root gstack meta-skill
    mkdir -p "$HOME/.claude/skills/gstack"
    cp "$UPSTREAM_DIR/SKILL.md" "$HOME/.claude/skills/gstack/" 2>/dev/null || true
    echo "skills/gstack/SKILL.md" >> "$MANIFEST_TMP"

    # Allowlisted skill subdirectories — $GSTACK_SKILL_ALLOWLIST (scripts/skill-allowlists.sh)
    for skill_name in $GSTACK_SKILL_ALLOWLIST; do
      skill_dir="$UPSTREAM_DIR/$skill_name"
      [ -f "$skill_dir/SKILL.md" ] || continue
      mkdir -p "$HOME/.claude/skills/$skill_name"
      cp "$skill_dir/SKILL.md" "$HOME/.claude/skills/$skill_name/"
      echo "skills/$skill_name/SKILL.md" >> "$MANIFEST_TMP"
    done
  else
    echo "  WARNING: gstack skills install failed"
  fi

  # 2) Runtime binary build (optional — needed for /browse and /qa)
  echo "  [gstack] Setting up runtime (browser binary)..."
  GSTACK_RUNTIME="$HOME/.gstack/runtime"

  # Install bun if missing (required for gstack browser)
  if ! command -v bun >/dev/null 2>&1; then
    echo "  [gstack] Installing bun..."
    curl -fsSL https://bun.sh/install | bash 2>/dev/null || true
    export BUN_INSTALL="$HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"
  fi

  # Clone gstack for binary build (separate from vendored skills)
  if [ -d "$GSTACK_RUNTIME/.git" ]; then
    git -C "$GSTACK_RUNTIME" pull --ff-only 2>/dev/null || true
  else
    rm -rf "$GSTACK_RUNTIME"
    git clone --depth 1 https://github.com/garrytan/gstack.git "$GSTACK_RUNTIME" 2>/dev/null || true
  fi

  # Run gstack setup for binary compilation
  GSTACK_BROWSER_OK=0
  if [ -d "$GSTACK_RUNTIME" ] && command -v bun >/dev/null 2>&1 && [ -f "$GSTACK_RUNTIME/setup" ]; then
    if (cd "$GSTACK_RUNTIME" && ./setup --host claude 2>/dev/null); then
      GSTACK_BROWSER_OK=1
    fi
  fi
  if [ "$GSTACK_BROWSER_OK" = "0" ]; then
    echo "  [gstack] WARNING: Browser runtime not available. /browse and /qa skills will not work."
    echo "           Text-based gstack skills (review, ship, plan-*, etc.) are installed and functional."
  fi

  # gstack auto_upgrade config
  mkdir -p "$HOME/.gstack"
  GSTACK_CONFIG="$HOME/.gstack/config.json"
  if [ -f "$GSTACK_CONFIG" ]; then
    node -e "
      const fs = require('fs');
      const cfg = JSON.parse(fs.readFileSync('$GSTACK_CONFIG', 'utf8'));
      cfg.auto_upgrade = true;
      fs.writeFileSync('$GSTACK_CONFIG', JSON.stringify(cfg, null, 2));
    " 2>/dev/null || true
  else
    echo '{"auto_upgrade":true}' > "$GSTACK_CONFIG"
  fi
fi

# ── 1f. superpowers upstream ──
if [ "$SKIP_SUPERPOWERS" = "0" ]; then
  echo "  [superpowers] Installing superpowers..."
  if init_upstream "superpowers" "https://github.com/obra/superpowers"; then
    # Pre-clean: resolve file/symlink vs directory conflicts
    for src in "$UPSTREAM_DIR"/skills/*/; do
      [ ! -d "$src" ] && continue
      name=$(basename "$src")
      target="$HOME/.claude/skills/$name"
      if [ -L "$target" ] || { [ -e "$target" ] && [ ! -d "$target" ]; }; then
        rm -f "$target"
      fi
    done
    if [ -d "$UPSTREAM_DIR/agents" ]; then
      find "$UPSTREAM_DIR/agents" -maxdepth 1 -name '*.md' | while read -r agent_src; do
        agent_base=$(basename "$agent_src")
        if [ -f "$HOME/.claude/agents/$agent_base" ]; then
          echo "  [superpowers] Skipping $agent_base (higher-tier version already installed)"
        else
          cp "$agent_src" "$HOME/.claude/agents/"
          echo "agents/$agent_base" >> "$MANIFEST_TMP"
        fi
      done
    fi
    if [ -d "$UPSTREAM_DIR/skills" ]; then
      # All skills except $SUPERPOWERS_SKILL_EXCLUDE (scripts/skill-allowlists.sh)
      # shellcheck disable=SC2086  # deliberate re-split: newline list -> " a b " for case matching
      _sp_exclude=" $(echo $SUPERPOWERS_SKILL_EXCLUDE) "
      for src in "$UPSTREAM_DIR"/skills/*/; do
        [ -d "$src" ] || continue
        name=$(basename "$src")
        case "$_sp_exclude" in *" $name "*) continue ;; esac
        cp -r "${src%/}" "$HOME/.claude/skills/" 2>/dev/null || true
        manifest_dir "skills/$name"
      done
    fi
  else
    echo "  WARNING: superpowers install failed"
  fi
fi

# ── 1g. archify upstream (one skill directory) ──
if [ "$SKIP_ARCHIFY" = "0" ]; then
  echo "  [archify] Installing archify skill..."
  if init_upstream "archify" "https://github.com/tt-a1i/archify" "$ARCHIFY_PINNED_TAG"; then
    src="$UPSTREAM_DIR/$ARCHIFY_SKILL_SRC_DIR"
    target="$HOME/.claude/skills/$ARCHIFY_SKILL_NAME"
    if [ -d "$src" ]; then
      # Pre-clean: resolve file/symlink vs directory conflicts
      if [ -L "$target" ] || { [ -e "$target" ] && [ ! -d "$target" ]; }; then
        rm -f "$target"
      fi
      mkdir -p "$target"
      cp -r "$src/." "$target/" 2>/dev/null || true
      # Manifest from the SOURCE tree, not manifest_dir on the destination:
      # archify's SKILL.md tells the agent to run `npm install` inside the
      # installed skill, so the destination also holds node_modules/ and
      # rendered diagrams. Those runtime files are user-owned — never
      # manifest-owned, so the cleanup above never deletes them.
      # `|| true` for the same reason manifest_dir carries one: a find that
      # trips on an unreadable path must not abort the install under `set -e`.
      ( cd "$src" && find . -type f ) \
        | sed "s|^\./|skills/$ARCHIFY_SKILL_NAME/|" >> "$MANIFEST_TMP" || true
    else
      echo "  WARNING: archify skill directory not found at $src"
    fi
  else
    echo "  WARNING: archify install failed"
  fi
fi

# Dedup: remove agents/skills that duplicate OMC plugin-provided content
if [ -d "$HOME/.claude/plugins/cache/omc/oh-my-claudecode" ]; then
  _omc_has_version=0
  for _v in "$HOME/.claude/plugins/cache/omc/oh-my-claudecode"/*/; do
    [ -d "$_v" ] && _omc_has_version=1 && break
  done
  if [ "$_omc_has_version" = "1" ]; then
    echo "  Deduplicating OMC plugin-provided files..."
    _omc_dedup_count=0
    for _agent in architect.md document-specialist.md explore.md executor.md debugger.md planner.md analyst.md critic.md verifier.md test-engineer.md designer.md writer.md qa-tester.md scientist.md security-reviewer.md code-reviewer.md git-master.md code-simplifier.md; do
      if [ -f "$HOME/.claude/agents/$_agent" ]; then
        rm -f "$HOME/.claude/agents/$_agent"
        _omc_dedup_count=$((_omc_dedup_count + 1))
      fi
    done
    for _skill in ai-slop-cleaner ask autopilot cancel ccg configure-notifications deep-interview deepinit external-context hud learner mcp-setup omc-doctor omc-setup omc-teams plan project-session-manager ralph ralplan release sciomc setup skill team ultraqa ultrawork visual-verdict writer-memory; do
      if [ -d "$HOME/.claude/skills/$_skill" ]; then
        rm -rf "$HOME/.claude/skills/$_skill"
        _omc_dedup_count=$((_omc_dedup_count + 1))
      fi
    done
    [ "$_omc_dedup_count" -gt 0 ] && echo "  Removed $_omc_dedup_count plugin duplicates"
  fi
fi

echo "  Plugin files installed"

# ── 2. Hooks ──
echo "[2/6] Installing hooks..."
mkdir -p "$HOME/.claude/hooks"
cp "$SCRIPT_DIR/hooks/hooks.json"                "$HOME/.claude/hooks/"
cp "$SCRIPT_DIR/hooks/session-start.sh"           "$HOME/.claude/hooks/"
cp "$SCRIPT_DIR/hooks/stop-profile-update.js"     "$HOME/.claude/hooks/"
cp "$SCRIPT_DIR/hooks/stop-session-enforcement.js" "$HOME/.claude/hooks/"
cp "$SCRIPT_DIR/hooks/stop-final-report.js"        "$HOME/.claude/hooks/"
cp "$SCRIPT_DIR/hooks/persona-rule.js"             "$HOME/.claude/hooks/"
cp "$SCRIPT_DIR/hooks/briefing-runtime.js"         "$HOME/.claude/hooks/"
cp "$SCRIPT_DIR/hooks/session-sync.js"             "$HOME/.claude/hooks/"
cp "$SCRIPT_DIR/hooks/session-end.js"              "$HOME/.claude/hooks/"
cp "$SCRIPT_DIR/hooks/context-budget.js"           "$HOME/.claude/hooks/"
cp "$SCRIPT_DIR/hooks/vault-enforcer.js"           "$HOME/.claude/hooks/"
for f in hooks.json session-start.sh stop-profile-update.js stop-session-enforcement.js stop-final-report.js persona-rule.js briefing-runtime.js session-sync.js session-end.js context-budget.js vault-enforcer.js; do
  echo "hooks/$f" >> "$MANIFEST_TMP"
done
mkdir -p "$HOME/.claude/scripts"
cp "$SCRIPT_DIR/scripts/validate-hooks.js" "$HOME/.claude/scripts/"
echo "  Hooks installed"

# ── 3. MCP servers ──
echo "[3/6] Registering MCP servers..."
# One `claude mcp add` per server. There is no bulk "import this .mcp.json"
# subcommand in Claude Code, so these calls are the registration, not a
# fallback. .mcp.json stays as the project-scope declaration of the same set;
# scripts/merge-settings.js writes the user-scope copy into settings.json.
claude mcp add context7  --transport http --scope user "https://mcp.context7.com/mcp" 2>/dev/null || true
claude mcp add exa       --transport http --scope user "https://mcp.exa.ai/mcp?tools=web_search_exa" 2>/dev/null || true
claude mcp add grep_app  --transport http --scope user "https://mcp.grep.app" 2>/dev/null || true
# stdio servers — the CLIs are installed by step [5e] below.
# --open-web-dashboard False: Claude Code spawns this server, so a browser tab
# popping open on every session start is noise; the dashboard still runs.
# `claude mcp add` is not an upsert: if the name already exists it errors and
# the 2>/dev/null||true below swallows that, so a changed argument list never
# reaches an already-installed machine. This harness owns these two
# registrations, so remove any existing one first and re-add with current args.
if [ "$INSTALL_SERENA" = "1" ]; then
  claude mcp remove serena -s user 2>/dev/null || true
  claude mcp add --scope user serena   -- serena start-mcp-server --context claude-code --project-from-cwd --open-web-dashboard False 2>/dev/null || true
fi
if [ "$INSTALL_HEADROOM" = "1" ]; then
  claude mcp remove headroom -s user 2>/dev/null || true
  claude mcp add --scope user headroom -- headroom mcp serve 2>/dev/null || true
fi
echo "  MCP servers registered"

# ── 4. Merge settings.json ──
echo "[4/6] Merging settings.json..."
node "$SCRIPT_DIR/scripts/merge-settings.js"

# ── 4b. Merge hooks from hooks.json into settings.json ──
echo "[4b] Merging hooks into settings.json..."
node "$SCRIPT_DIR/scripts/merge-hooks.js" "$SCRIPT_DIR/hooks/hooks.json"

# ── 4c. HUD (statusline) ──
echo "[4c] Installing HUD statusline..."
HUD_DIR="$HOME/.claude/hud"
mkdir -p "$HUD_DIR/lib"
if [ -f "$SCRIPT_DIR/upstream/omc/scripts/lib/hud-wrapper-template.txt" ]; then
  cp "$SCRIPT_DIR/upstream/omc/scripts/lib/hud-wrapper-template.txt" "$HUD_DIR/omc-hud.mjs"
  cp "$SCRIPT_DIR/upstream/omc/scripts/lib/config-dir.mjs" "$HUD_DIR/lib/config-dir.mjs"
  # Remove legacy .js version if present
  rm -f "$HUD_DIR/omc-hud.js" 2>/dev/null || true
  # Make executable on Unix
  chmod +x "$HUD_DIR/omc-hud.mjs" 2>/dev/null || true
  echo "  HUD wrapper installed"
else
  echo "  WARNING: OMC upstream not found, skipping HUD (run with submodules initialized)"
fi

# ── 5. Companion tools ──

# 5a. Anthropic Official Skills (proprietary — cannot be bundled)
echo "[5/6] Installing companion tools..."
echo "  [5a] Anthropic skills..."
if [ -d "$HOME/.claude/skills/pdf" ] && [ -d "$HOME/.claude/skills/docx" ]; then
  echo "    Anthropic skills already installed"
else
  claude plugin add anthropics/skills 2>/dev/null || {
    echo "    Plugin install failed, falling back to git clone..."
    _tmp_skills=$(mktemp -d)
    trap 'rm -rf "$_tmp_skills"' EXIT
    git clone --depth 1 https://github.com/anthropics/skills.git "$_tmp_skills/skills" 2>/dev/null || true
    if [ -d "$_tmp_skills/skills/skills" ]; then
      mkdir -p "$HOME/.claude/skills"
      # Deliberately manifest-exempt: this fallback only runs once (the
      # `[ -d pdf ] && [ -d docx ]` guard above skips it afterwards). Tracking
      # it would make every update delete these skills at cleanup time and
      # re-clone the whole anthropics/skills repo. Left fully untracked rather
      # than half-tracked.
      cp -r "$_tmp_skills/skills/skills/"* "$HOME/.claude/skills/"
      echo "    Anthropic skills installed via git clone"
    else
      echo "    WARNING: Could not install Anthropic skills"
    fi
  }
fi

# 5b. OMC CLI (npm package)
echo "  [5b] OMC CLI..."
_OMC_HUD_OK=false
_OMC_PKG_HUD="$(npm root -g 2>/dev/null)/oh-my-claude-sisyphus/dist/hud/index.js"
[ -f "$_OMC_PKG_HUD" ] && _OMC_HUD_OK=true
if command -v omc >/dev/null 2>&1 && [ "$_OMC_HUD_OK" = "true" ]; then
  echo "    OMC already installed ($(omc --version 2>/dev/null || echo 'unknown'))"
else
  if command -v omc >/dev/null 2>&1 && [ "$_OMC_HUD_OK" = "false" ]; then
    echo "    OMC found but HUD missing (broken install), reinstalling..."
  fi
  npm i -g oh-my-claude-sisyphus@latest
  omc setup 2>/dev/null || true
  echo "    OMC installed"
fi

# Sync OMC npm package to plugin cache (HUD reads from cache first)
_OMC_NPM_DIR="$(npm root -g 2>/dev/null)/oh-my-claude-sisyphus"
_OMC_CACHE_BASE="$HOME/.claude/plugins/cache/omc/oh-my-claudecode"
if [ -d "$_OMC_NPM_DIR/dist" ]; then
  _OMC_VER="$(node -e "console.log(require('$_OMC_NPM_DIR/package.json').version)" 2>/dev/null || echo "")"
  if [ -n "$_OMC_VER" ] && [ ! -d "$_OMC_CACHE_BASE/$_OMC_VER/dist" ]; then
    echo "    Syncing OMC v$_OMC_VER to plugin cache..."
    mkdir -p "$_OMC_CACHE_BASE/$_OMC_VER"
    cp -r "$_OMC_NPM_DIR/"* "$_OMC_CACHE_BASE/$_OMC_VER/" 2>/dev/null || true
  fi
fi

# 5c. omo CLI + dependencies (npm packages)
echo "  [5c] omo CLI..."
if command -v oh-my-opencode >/dev/null 2>&1; then
  echo "    omo already installed"
else
  npm i -g oh-my-opencode@latest
  oh-my-opencode install --no-tui --claude=yes --openai=no --gemini=no --copilot=no 2>/dev/null || true
  echo "    omo installed"
fi
# codeburn is a companion tool; the other two are always installed.
if [ "$INSTALL_CODEBURN" = "1" ]; then
  npm i -g @ast-grep/cli@0.42.0 @code-yeongyu/comment-checker@0.7.0 codeburn@0.9.23 2>/dev/null || true
else
  npm i -g @ast-grep/cli@0.42.0 @code-yeongyu/comment-checker@0.7.0 2>/dev/null || true
fi
# codeburn budget guard is opt-in: it adds a PreToolUse hook on every tool call.
if [ "${WITH_CODEBURN_GUARD:-0}" = "1" ] && command -v codeburn >/dev/null 2>&1; then
  codeburn guard install 2>/dev/null && echo "  codeburn guard hooks installed" || echo "  WARNING: codeburn guard install failed"
fi

# 5c-lsp. Language servers for the plugin's .lsp.json declaration (typescript + python).
# Binaries must be on PATH (docs: plugins-reference → LSP servers); a missing binary
# only disables that one server, so this stays non-fatal.
echo "  [5c-lsp] Language servers (typescript-language-server, pyright)..."
command -v typescript-language-server >/dev/null 2>&1 || npm i -g typescript-language-server typescript 2>/dev/null || true
command -v pyright-langserver >/dev/null 2>&1 || npm i -g pyright 2>/dev/null || true

# 5d. Karpathy guidelines (a marked block in CLAUDE.md)
echo "  [5d] Karpathy guidelines..."
# The block is found by a marker WE write, not by the fetched text: the
# upstream guidelines never contain the word "karpathy", so the old content
# sniff never matched and every install re-appended the whole block (10 copies
# accumulated in the wild).
# Sweep up the copies those pre-marker installs already appended (13 of them on
# one real machine). Runs from $SCRIPT_DIR like the other install-time node
# helpers; it never needs to exist in ~/.claude. Non-fatal under `set -e`.
node "$SCRIPT_DIR/scripts/dedupe-karpathy.js" "$HOME/.claude/CLAUDE.md" || true
# Pinned to a specific commit SHA + checksum to prevent supply chain attacks.
# To upgrade: update SHA and EXPECTED_CHECKSUM together. The fetch runs on
# every install rather than only when the marker is missing, so a bumped pin
# reaches a machine that already carries the block; only checksum-verified
# content is ever written, and a failed download leaves the installed block
# exactly where it is.
KARPATHY_SHA="aa4467f0b33e1e80d11c7c043d4b27e7c79a73a3"
KARPATHY_URL="https://raw.githubusercontent.com/forrestchang/andrej-karpathy-skills/${KARPATHY_SHA}/CLAUDE.md"
KARPATHY_EXPECTED_CHECKSUM="694a2d721e41c385f3db492838c23299826df5ba9809e3b0721aac70021e196a"
_tmp_karpathy=$(mktemp)
trap 'rm -f "$_tmp_karpathy"' EXIT
if curl -sL "$KARPATHY_URL" -o "$_tmp_karpathy" 2>/dev/null; then
  ACTUAL_CHECKSUM=$(sha256 "$_tmp_karpathy")
  if [ "$ACTUAL_CHECKSUM" = "$KARPATHY_EXPECTED_CHECKSUM" ]; then
    # Replaces the marked block in place, or appends it when it is absent, and
    # writes nothing when the file already holds this exact content.
    node "$SCRIPT_DIR/scripts/dedupe-karpathy.js" --install \
      "$HOME/.claude/CLAUDE.md" "$_tmp_karpathy" \
      || echo "    WARNING: could not write the Karpathy guidelines"
  else
    echo "    WARNING: Checksum mismatch, skipping Karpathy guidelines"
  fi
else
  echo "    WARNING: download failed, keeping the installed Karpathy guidelines"
fi

# 5e. uv + MCP tool CLIs (serena, headroom)
# Both MCP servers registered in step [3] are stdio servers that run a local
# Python CLI, so the harness has to bring its own uv and install them itself —
# a clone of this repo plus `bash install.sh` is the whole prerequisite list.
# Every command here is non-fatal: a missing CLI disables one MCP server, it
# does not break the install.
# uv itself is only worth installing when at least one of the two tools it
# carries was selected.
_UV_TOOL_NAMES=""
if [ "$INSTALL_SERENA"   = "1" ]; then _UV_TOOL_NAMES="$_UV_TOOL_NAMES, serena"; fi
if [ "$INSTALL_HEADROOM" = "1" ]; then _UV_TOOL_NAMES="$_UV_TOOL_NAMES, headroom"; fi
_UV_TOOL_NAMES="${_UV_TOOL_NAMES#, }"
if [ -z "$_UV_TOOL_NAMES" ]; then
  echo "  [5e] uv + MCP tool CLIs: SKIPPED (not selected)"
else
  echo "  [5e] uv + MCP tool CLIs ($_UV_TOOL_NAMES)..."
  if ! command -v uv >/dev/null 2>&1; then
    echo "    uv not found, installing via the official installer..."
    curl -LsSf https://astral.sh/uv/install.sh | sh >/dev/null 2>&1 || echo "    WARNING: uv install failed"
  fi
  # The uv installer drops uv and every `uv tool` shim in ~/.local/bin, which is
  # not on PATH in a non-login shell. Prepend it for the rest of this script.
  case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) PATH="$HOME/.local/bin:$PATH"; export PATH ;;
  esac

  if command -v uv >/dev/null 2>&1; then
    _UV_TOOLS="$(uv tool list 2>/dev/null || echo "")"
    # serena-agent — symbol-level code navigation and editing (LSP-backed).
    if [ "$INSTALL_SERENA" = "1" ]; then
      case "$_UV_TOOLS" in
        *"serena-agent v1.7.0"*) echo "    serena-agent 1.7.0 already installed" ;;
        *) uv tool install -p 3.13 serena-agent==1.7.0 >/dev/null 2>&1 \
             && echo "    serena-agent 1.7.0 installed" \
             || echo "    WARNING: serena-agent install failed" ;;
      esac
    fi
    # headroom-ai — tool-output compression exposed over MCP. The proxy mode
    # (`headroom proxy` + ANTHROPIC_BASE_URL) works on a subscription login too,
    # but it is left to the user: Claude Code cannot connect while the proxy is
    # down, so starting one automatically would be a new way to break a session.
    # MCP mode has no such failure mode and is what this installer wires up.
    if [ "$INSTALL_HEADROOM" = "1" ]; then
      case "$_UV_TOOLS" in
        *"headroom-ai v0.37.0"*) echo "    headroom-ai 0.37.0 already installed" ;;
        *) uv tool install --python 3.13 "headroom-ai[all]==0.37.0" >/dev/null 2>&1 \
             && echo "    headroom-ai 0.37.0 installed" \
             || echo "    WARNING: headroom-ai install failed" ;;
      esac
    fi

    # Serena keeps a global config; create it once and turn off the launch-time
    # browser pop-up there too. The registered server passes
    # `--open-web-dashboard False`, which overrides this setting, so the config
    # write is belt-and-braces for servers started by hand. Only written when
    # this run creates the file, so a config the user has tuned is never
    # rewritten.
    SERENA_CONFIG="$HOME/.serena/serena_config.yml"
    if [ "$INSTALL_SERENA" = "1" ] && command -v serena >/dev/null 2>&1 && [ ! -f "$SERENA_CONFIG" ]; then
      serena init >/dev/null 2>&1 || true
      if [ -f "$SERENA_CONFIG" ]; then
        # `serena config` only offers an interactive `edit`, so patch the key.
        sed -i.bak 's/^web_dashboard_open_on_launch: true$/web_dashboard_open_on_launch: false/' "$SERENA_CONFIG" \
          && rm -f "$SERENA_CONFIG.bak"
        # Report what actually landed: a future serena release that renames or
        # drops the key would leave the sed a no-op, and claiming success then
        # hides it.
        if grep -q '^web_dashboard_open_on_launch: false$' "$SERENA_CONFIG"; then
          echo "    serena config created (dashboard auto-open off)"
        else
          echo "    serena config created, but web_dashboard_open_on_launch not found — the MCP server still passes --open-web-dashboard False"
        fi
      fi
    fi

    # `uv tool` shims live in ~/.local/bin. Claude Code launches the stdio MCP
    # servers by bare command name, so that directory has to be on the PATH the
    # editor inherits. This script prepended it for itself above; tell the user
    # how to make it permanent rather than editing their shell profile for them.
    for _cli in $(printf '%s' "$_UV_TOOL_NAMES" | tr -d ','); do
      command -v "$_cli" >/dev/null 2>&1 \
        || echo "    WARNING: $_cli not on PATH — run 'uv tool update-shell' so its MCP server can start"
    done
  else
    echo "    WARNING: uv unavailable — the $_UV_TOOL_NAMES MCP server(s) will not start"
  fi
fi

# 5f. Shared local dashboards (my-claude + my-codex)
# The helper locks a cross-harness state directory, identifies an existing
# service before reusing it, and never kills an unknown port owner. Failures are
# diagnostic only: the CLI/MCP installation remains usable without dashboards.
# The helper takes the services to ensure as positional arguments; with none it
# still ensures both, which is what the my-codex copy relies on.
_SHARED_SERVICES=""
if [ "$INSTALL_CODEBURN" = "1" ]; then _SHARED_SERVICES="$_SHARED_SERVICES codeburn"; fi
if [ "$INSTALL_HEADROOM" = "1" ]; then _SHARED_SERVICES="$_SHARED_SERVICES headroom"; fi
if [ -z "$_SHARED_SERVICES" ]; then
  echo "  [5f] shared local dashboards: SKIPPED (not selected)"
else
  echo "  [5f] shared local dashboards ($(printf '%s' "${_SHARED_SERVICES# }" | tr ' ' ','))..."
  # shellcheck disable=SC2086 # deliberate word splitting: one argument per service
  bash "$SCRIPT_DIR/scripts/ensure-shared-local-services.sh" $_SHARED_SERVICES || \
    echo "    WARNING: shared local dashboard setup failed"
fi

# 5g. my-claude plugin refresh (keep the two install routes in sync)
# my-claude can be installed via this script (copies files into ~/.claude and
# merges hooks into settings.json) or via the Claude Code plugin system
# (`/plugin marketplace add` + `/plugin install`, which registers
# hooks/hooks.json on its own). If both routes were used and the plugin clone
# is stale, it keeps re-registering hooks this repo has already removed — so
# refresh it here too, best-effort, whenever it is present.
echo "  [5g] my-claude plugin (marketplace route, if installed)..."
PLUGIN_REFRESH_STATUS="not installed (skipped)"
if command -v claude >/dev/null 2>&1; then
  _PLUGIN_LIST="$(claude plugin list 2>/dev/null || true)"
  case "$_PLUGIN_LIST" in
    *my-claude@my-claude*)
      claude plugin marketplace update my-claude 2>/dev/null || true
      claude plugin update my-claude@my-claude 2>/dev/null || true
      _PLUGIN_LIST_AFTER="$(claude plugin list 2>/dev/null || true)"
      _PLUGIN_VERSION="$(printf '%s\n' "$_PLUGIN_LIST_AFTER" | awk '/my-claude@my-claude/{found=1; next} found && /Version:/{print $2; exit}')"
      if [ -n "$_PLUGIN_VERSION" ]; then
        PLUGIN_REFRESH_STATUS="refreshed to $_PLUGIN_VERSION"
      else
        PLUGIN_REFRESH_STATUS="refreshed"
      fi
      ;;
  esac
fi
echo "  my-claude plugin: $PLUGIN_REFRESH_STATUS"

# Write the manifest from provenance-tracked entries (MANIFEST_TMP), not from
# scanning $HOME/.claude directories. A directory scan would also pick up
# user-owned files that happen to sit in the same folders (a custom agent
# dropped into ~/.claude/agents/, a hand-written skill, etc.), and those would
# then be deleted on a future update by the manifest-diff cleanup above.
# The final "still exists on disk" filter drops any entry that dedup steps
# removed after it was recorded (e.g. OMC-plugin-duplicate agents/skills).
sort -u "$MANIFEST_TMP" | while IFS= read -r rel_path; do
  [ -e "$HOME/.claude/$rel_path" ] && printf '%s\n' "$rel_path"
done > "$HOME/.claude/.my-claude-manifest"
echo "  Manifest saved ($(wc -l < "$HOME/.claude/.my-claude-manifest") entries)"
echo "$SCRIPT_DIR" > "$HOME/.claude/.my-claude-repo-path" 2>/dev/null || true
# Remember the optional skill lanes so a later plain `bash install.sh` keeps them.
printf '%s\n' "$SKILL_LANES" > "$SKILL_LANES_FILE" 2>/dev/null || true

# ── 6. Verification ──
# `command -v` only proves a file sits on PATH. Each probe below actually runs
# the tool: a cheap local call — no network, no server, no browser, well under
# a second. Every probe is non-fatal under `set -euo pipefail`; a FAIL is
# reported and the install still completes.
probe() {  # probe <binary> <command...>
  _probe_bin="$1"; shift
  command -v "$_probe_bin" >/dev/null 2>&1 || { echo "MISSING (not on PATH)"; return 0; }
  _probe_cmd="$*"
  if _probe_out=$("$@" 2>/dev/null); then
    # A one-line banner (`serena --version`) is the most useful thing to show;
    # anything longer (a JSON report) is summarised by the command that ran.
    _probe_lines=$(printf '%s\n' "$_probe_out" | wc -l | tr -d ' ')
    if [ "$_probe_lines" = "1" ] && [ -n "$_probe_out" ] && [ ${#_probe_out} -le 40 ]; then
      echo "OK ($_probe_out)"
    else
      echo "OK (ran \`$_probe_cmd\`)"
    fi
  else
    echo "FAIL (\`$_probe_cmd\` exited non-zero)"
  fi
}

# archify ships as a skill, not a binary: render its own bundled example into a
# temp file and require a non-empty result, then drop the file.
probe_archify() {
  _ar_dir="$HOME/.claude/skills/archify"
  [ -f "$_ar_dir/SKILL.md" ] || { echo "MISSING (skill not installed)"; return 0; }
  if [ ! -f "$_ar_dir/bin/archify.mjs" ] || [ ! -f "$_ar_dir/examples/agent-run.lifecycle.json" ]; then
    echo "SKIPPED (SKILL.md present, renderer or example missing)"
    return 0
  fi
  _ar_out="${TMPDIR:-/tmp}/my-claude-archify-probe.$$.html"
  if ( cd "$_ar_dir" && node bin/archify.mjs render lifecycle examples/agent-run.lifecycle.json "$_ar_out" ) >/dev/null 2>&1 && [ -s "$_ar_out" ]; then
    echo "OK (rendered examples/agent-run.lifecycle.json, $(wc -c < "$_ar_out" | tr -d ' ') bytes)"
  else
    echo "FAIL (bin/archify.mjs render produced no output)"
  fi
  rm -f "$_ar_out"
}

echo ""
echo "[6/6] Verification"
echo "  agents (core):    $(find "$HOME/.claude/agents" -name '*.md' 2>/dev/null | wc -l | tr -d ' ') files"
echo "  skills:           $(find "$HOME/.claude/skills" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ') installed"
echo "  rules:            $(find "$HOME/.claude/rules"  -name '*.md' 2>/dev/null | wc -l | tr -d ' ') files"
echo "  skill lanes:      ${SKILL_LANES:-default}"
echo "  hooks:            $(find "$HOME/.claude/hooks"  -type f      2>/dev/null | wc -l | tr -d ' ') files"
echo "  omc:              $(command -v omc            >/dev/null 2>&1 && echo 'OK' || echo 'MISSING')"
echo "  omo:              $(command -v oh-my-opencode >/dev/null 2>&1 && echo 'OK' || echo 'MISSING')"
echo "  ast-grep:         $(command -v ast-grep       >/dev/null 2>&1 && echo 'OK' || echo 'MISSING')"
if [ "$INSTALL_CODEBURN" = "1" ]; then
  echo "  codeburn:         $(probe codeburn codeburn report --format json --period today)"
else
  echo "  codeburn:         SKIPPED (not selected)"
fi
if [ -n "$_UV_TOOL_NAMES" ]; then
  echo "  uv:               $(command -v uv >/dev/null 2>&1 && echo "OK ($(uv --version 2>/dev/null))" || echo 'MISSING')"
else
  echo "  uv:               SKIPPED (not selected)"
fi
if [ "$INSTALL_SERENA" = "1" ]; then
  echo "  serena (MCP):     $(probe serena serena --version)"
else
  echo "  serena (MCP):     SKIPPED (not selected)"
fi
if [ "$INSTALL_HEADROOM" = "1" ]; then
  echo "  headroom (MCP):   $(probe headroom headroom --version)"
else
  echo "  headroom (MCP):   SKIPPED (not selected)"
fi
echo "  archify (skill):  $(probe_archify)"
echo "  tmux:             $(command -v tmux >/dev/null 2>&1 && echo "OK ($(tmux -V))" || echo 'NOT INSTALLED (optional)')"
echo "  hud:              $(test -f "$HOME/.claude/hud/omc-hud.mjs" && echo 'OK' || echo 'MISSING')"
echo "  my-claude plugin: $PLUGIN_REFRESH_STATUS"
TEAMMATE_MODE=$(node -e "try{const h=process.env.HOME||process.env.USERPROFILE;console.log(JSON.parse(require('fs').readFileSync(h+'/.claude/settings.json','utf8')).teammateMode||'in-process (default)')}catch(e){console.log('auto')}")
echo "  version:          v${INSTALLING_VERSION}"
echo "  teammateMode:     $TEAMMATE_MODE"
echo ""
if [ -z "$TOOLS_SELECTED" ]; then
  echo "  Companion tools were skipped; re-run with --yes to install them."
  echo ""
else
  echo "Open these"
  if [ "$INSTALL_SERENA" = "1" ]; then
    echo "  Serena dashboard:   http://localhost:24282/dashboard/index.html"
    echo "                      (live whenever a Claude session has the serena MCP server up)"
  fi
  if [ "$INSTALL_CODEBURN" = "1" ]; then
    echo "  codeburn dashboard: http://127.0.0.1:4747 (shared service started or reused above)"
  fi
  if [ "$INSTALL_HEADROOM" = "1" ]; then
    echo "  Headroom stats:      http://127.0.0.1:8787/stats"
    echo "                       (may be empty until a client explicitly routes through the proxy)"
  fi
  echo ""
  if [ -n "$_UV_TOOL_NAMES" ]; then
    echo "  The $_UV_TOOL_NAMES MCP server(s) start automatically with each Claude Code session."
  fi
  echo ""
fi
# Record installed version
echo "$INSTALLING_VERSION" > "$HOME/.claude/.my-claude-version"
git -C "$SCRIPT_DIR" rev-parse --short=12 HEAD 2>/dev/null > "$HOME/.claude/.my-claude-installed-sha" || true

echo "=== Install complete ==="
