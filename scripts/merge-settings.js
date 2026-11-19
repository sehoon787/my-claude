// Usage: node scripts/merge-settings.js
// Merges settings: agent teams env, boss default agent, MCP servers, HUD statusline.
// Agent Teams run in-process (Claude Code's default). tmux teammateMode is no longer
// written: it spawns every teammate as a separate `claude` process that stalls on the
// workspace-trust dialog when nobody can answer it and registers its own Remote Control
// session ("<host>-<adjective>-<noun>"), which shows up as unknown sessions.
const fs = require('fs');
const path = require('path');
const { backupSettings } = require('./settings-backup');
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

// No CLAUDE_AUTOCOMPACT_PCT_OVERRIDE default. Claude Code's `autoCompactWindow: auto`
// picks the window per model, and a fixed 75% of a ~200k window is about where the
// context already sits right after a compaction (summary, re-attached skills,
// CLAUDE.md, rules), so Claude Code stops with "Autocompact is thrashing". Earlier
// installs wrote '75'; that exact value is removed, any other value is the user's.
if (settings.env.CLAUDE_AUTOCOMPACT_PCT_OVERRIDE === '75') {
  delete settings.env.CLAUDE_AUTOCOMPACT_PCT_OVERRIDE;
  console.log("  CLAUDE_AUTOCOMPACT_PCT_OVERRIDE: 75 -> removed (Claude Code's autoCompactWindow: auto now decides)");
}
settings.agent = settings.agent || 'boss';
// Earlier installs wrote teammateMode 'tmux'; normalise it back to in-process unless the
// user explicitly opts in with MY_CLAUDE_TEAMMATE_MODE=tmux.
if (settings.teammateMode === 'tmux' && process.env.MY_CLAUDE_TEAMMATE_MODE !== 'tmux') {
  settings.teammateMode = 'in-process';
  console.log('  teammateMode: tmux -> in-process (set MY_CLAUDE_TEAMMATE_MODE=tmux to keep tmux)');
}
// Kept byte-for-byte in step with .mcp.json and with the `claude mcp add`
// calls in install.sh step [3]. Those three are independent registrations of
// the same set — there is no bulk import from .mcp.json — so a server that
// exists in one place and not the others silently disappears on that path.
// serena and headroom are stdio servers whose CLIs step [5e] of install.sh
// installs with uv. headroom is wired up in MCP mode only; its proxy mode is a
// documented manual opt-in, because Claude Code cannot connect while the proxy
// is down.
settings.mcpServers = Object.assign({}, settings.mcpServers, {
  context7: { type: 'http', url: 'https://mcp.context7.com/mcp' },
  exa: { type: 'http', url: 'https://mcp.exa.ai/mcp?tools=web_search_exa' },
  grep_app: { type: 'http', url: 'https://mcp.grep.app' },
  serena: {
    type: 'stdio',
    command: 'serena',
    args: [
      'start-mcp-server',
      '--context',
      'claude-code',
      '--project-from-cwd',
      // Claude Code spawns this server; a dashboard tab opening on every
      // session start is noise. The dashboard itself keeps running.
      '--open-web-dashboard',
      'False'
    ]
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

backupSettings(settingsPath);
fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2) + '\n');
console.log('  settings.json merged');
