#!/usr/bin/env bash
#
# install-omc-agents.test.sh — OMC agents stay installed for users whose OMC
# Claude plugin is not enabled. `bash tests/install-omc-agents.test.sh`
#
# Step [1d] skipped the OMC agent copy, and the dedup step deleted OMC agents,
# whenever ~/.claude/plugins/cache/omc/oh-my-claudecode held a version. Step
# [5b] creates that directory itself (it syncs the OMC npm package there for
# the HUD), so on every install after the first the manifest cleanup removed
# the agents and nothing put them back. Only a plugin that is enabled
# (enabledPlugins["oh-my-claudecode@omc"] in ~/.claude/settings.json) provides
# them. Guards:
#   1. No plugin: the agents survive a second install.
#   2. Plugin enabled: the copy is skipped and old copies are deduplicated.
#   3. Plugin installed but disabled: the agents are copied.
#
# Runs install.sh in the shared sandbox (tests/lib/install-sandbox.sh): a
# throwaway HOME, TMPDIR and npm prefix, shimmed installers, local git only.
set -uo pipefail
. "$(dirname "$0")/lib/install-sandbox.sh"

OMC_PIN="1.2.3"
CACHE_REL=".claude/plugins/cache/omc/oh-my-claudecode"
# One agent the dedup step names (executor.md) and one it does not.
C="$SANDBOX/repo"
make_repo "$C"
make_module "$C/upstream/omc" omc
mkdir -p "$C/upstream/omc/agents"
printf '{ "name": "oh-my-claude-sisyphus", "version": "%s" }\n' "$OMC_PIN" > "$C/upstream/omc/package.json"
printf -- '---\nname: executor\n---\nfrom omc\n' > "$C/upstream/omc/agents/executor.md"
printf -- '---\nname: omc-only-agent\n---\nfrom omc\n' > "$C/upstream/omc/agents/omc-only-agent.md"
record "$C" "$(commit_all "$C/upstream/omc" "omc at the pin")" upstream/omc

# npm publishes the pinned OMC CLI, so step [5b] installs it and syncs it into
# the plugin cache, as it does on a real machine.
NPM_SHIM_OMC_VERSIONS="$OMC_PIN"
FLAGS=(--skip-ecc --skip-gstack --skip-superpowers --skip-archify --skip-tools)
agents_installed() { [ -f "$1/.claude/agents/executor.md" ] && [ -f "$1/.claude/agents/omc-only-agent.md" ]; }
no_agents() { [ ! -e "$1/.claude/agents/executor.md" ] && [ ! -e "$1/.claude/agents/omc-only-agent.md" ]; }
manifest_lists_agents() {
  grep -qx 'agents/executor.md' "$1/.claude/.my-claude-manifest" && grep -qx 'agents/omc-only-agent.md' "$1/.claude/.my-claude-manifest"
}
# A plugin install as Claude Code leaves it: a cached version, and the plugin
# enabled (true) or disabled (false) in the user's settings.
seed_plugin() {  # seed_plugin <home> <true|false>
  mkdir -p "$1/$CACHE_REL/$OMC_PIN/.claude-plugin"
  echo '{ "name": "oh-my-claudecode" }' > "$1/$CACHE_REL/$OMC_PIN/.claude-plugin/plugin.json"
  printf '{ "enabledPlugins": { "oh-my-claudecode@omc": %s } }\n' "$2" > "$1/.claude/settings.json"
}

echo "[1/3] no OMC plugin: two installs"
H="$SANDBOX/home-noplugin"; mkdir -p "$H"
run_install "$H" "$C" "${FLAGS[@]}"
check "first install copies the OMC agents"               "$(yes_if agents_installed "$H")"
check "fixture: step [5b] synced a version into the plugin cache" "$(yes_if [ -d "$H/$CACHE_REL/$OMC_PIN" ])"
run_install "$H" "$C" "${FLAGS[@]}"
check "second install keeps the OMC agents"               "$(yes_if agents_installed "$H")"
check "the manifest still owns them"                      "$(yes_if manifest_lists_agents "$H")"
check "no 'Plugin detected' line"                         "$(yes_if not in_log "$H" "Plugin detected")"

echo "[2/3] OMC plugin installed and enabled"
H="$SANDBOX/home-enabled"; mkdir -p "$H/.claude/agents"
seed_plugin "$H" true
# A copy an older install left behind: the plugin provides this agent now.
printf -- '---\nname: executor\n---\nold copy\n' > "$H/.claude/agents/executor.md"
run_install "$H" "$C" "${FLAGS[@]}"
check "'Plugin detected' and the agent copy skipped"      "$(yes_if in_log "$H" "Plugin detected — skipping agent file copy")"
check "no OMC agent copies left (dedup removed the old one)" "$(yes_if no_agents "$H")"

echo "[3/3] OMC plugin installed but disabled"
H="$SANDBOX/home-disabled"; mkdir -p "$H/.claude"
seed_plugin "$H" false
run_install "$H" "$C" "${FLAGS[@]}"
check "the OMC agents are copied"                         "$(yes_if agents_installed "$H")"
check "no 'Plugin detected' line"                         "$(yes_if not in_log "$H" "Plugin detected")"

finish
