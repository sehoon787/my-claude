// Usage: node scripts/merge-settings.js
// Merges settings: agent teams env, boss default agent, MCP servers, HUD statusline.
// Agent Teams run in-process (Claude Code's default). tmux teammateMode is no longer
// written: it spawns every teammate as a separate `claude` process that stalls on the
// workspace-trust dialog when nobody can answer it and registers its own Remote Control
// session ("<host>-<adjective>-<noun>"), which shows up as unknown sessions.
const fs = require('fs');
const path = require('path');
const home = process.env.HOME || process.env.USERPROFILE;
const settingsPath = path.join(home, '.claude', 'settings.json');

const settings = fs.existsSync(settingsPath)
  ? JSON.parse(fs.readFileSync(settingsPath, 'utf8'))
  : {};

settings.env = Object.assign({}, settings.env, {
  CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS: '1'
});

// OMC's pre-tool-enforcer/post-tool-verifier plugin hooks append an advisory line
// ("Use parallel execution...", "Background operation detected...") to almost every
// Bash/Edit/Read call. Those lines are re-sent as context on every subsequent
// request, so they are a recurring per-call cost for advice Boss already has in its
// prompt. Level 2 suppresses them and the "Completed: N" agent summaries while
// still reporting real failures (detectBashFailure / detectWriteFailure and the
// team-routing error are not gated on the quiet level). An explicit user setting
// always wins.
if (!settings.env.OMC_QUIET) {
  settings.env.OMC_QUIET = '2';
}

// Auto-compact earlier than the default. Every request re-sends the whole
// transcript, so the tail of a long session is where cached-token cost
// concentrates; compacting sooner cuts that and loses less than the /clear people
// reach for instead. The variable only lowers the trigger — values above the
// default are ignored — and a value the user set already wins.
// Documented at https://code.claude.com/docs/en/env-vars
// (CLAUDE_AUTOCOMPACT_PCT_OVERRIDE: percentage 1-100 of the auto-compact window
// at which auto-compaction triggers).
if (!settings.env.CLAUDE_AUTOCOMPACT_PCT_OVERRIDE) {
  settings.env.CLAUDE_AUTOCOMPACT_PCT_OVERRIDE = '75';
}
settings.agent = settings.agent || 'boss';
// Earlier installs wrote teammateMode 'tmux'; normalise it back to in-process unless the
// user explicitly opts in with MY_CLAUDE_TEAMMATE_MODE=tmux.
if (settings.teammateMode === 'tmux' && process.env.MY_CLAUDE_TEAMMATE_MODE !== 'tmux') {
  settings.teammateMode = 'in-process';
  console.log('  teammateMode: tmux -> in-process (set MY_CLAUDE_TEAMMATE_MODE=tmux to keep tmux)');
}
// Kept byte-for-byte in step with .mcp.json — install.sh registers from that
// file first and only falls back to `claude mcp add`, so a server that exists
// in one place and not the other silently disappears on one of the two paths.
// serena and headroom are stdio servers whose CLIs step [5e] of install.sh
// installs with uv. headroom is wired up in MCP mode only; its proxy mode is a
// documented manual opt-in, because Claude Code cannot connect while the proxy
// is down.
settings.mcpServers = Object.assign({}, settings.mcpServers, {
  context7: { type: 'url', url: 'https://mcp.context7.com/mcp' },
  exa: { type: 'url', url: 'https://mcp.exa.ai/mcp?tools=web_search_exa' },
  grep_app: { type: 'url', url: 'https://mcp.grep.app' },
  serena: {
    type: 'stdio',
    command: 'serena',
    args: ['start-mcp-server', '--context', 'claude-code', '--project-from-cwd']
  },
  headroom: { type: 'stdio', command: 'headroom', args: ['mcp', 'serve'] }
});

// HUD statusLine (only add if not already configured)
if (!settings.statusLine) {
  const hudPath = path.join(home, '.claude', 'hud', 'omc-hud.mjs');
  if (fs.existsSync(hudPath)) {
    // Use forward slashes for all platforms (bash executes the command)
    const cmdPath = hudPath.split(path.sep).join('/');
    settings.statusLine = {
      type: 'command',
      command: 'node ' + cmdPath
    };
  }
}

fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2) + '\n');
console.log('  settings.json merged');
