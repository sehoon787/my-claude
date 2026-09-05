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
settings.agent = settings.agent || 'boss';
// Earlier installs wrote teammateMode 'tmux'; normalise it back to in-process unless the
// user explicitly opts in with MY_CLAUDE_TEAMMATE_MODE=tmux.
if (settings.teammateMode === 'tmux' && process.env.MY_CLAUDE_TEAMMATE_MODE !== 'tmux') {
  settings.teammateMode = 'in-process';
  console.log('  teammateMode: tmux -> in-process (set MY_CLAUDE_TEAMMATE_MODE=tmux to keep tmux)');
}
settings.mcpServers = Object.assign({}, settings.mcpServers, {
  context7: { type: 'url', url: 'https://mcp.context7.com/mcp' },
  exa: { type: 'url', url: 'https://mcp.exa.ai/mcp?tools=web_search_exa' },
  grep_app: { type: 'url', url: 'https://mcp.grep.app' }
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
