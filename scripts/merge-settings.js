// Usage: node scripts/merge-settings.js [--tmux]
// Merges settings: agent teams env, boss default agent, MCP servers, optional tmux mode
const fs = require('fs');
const path = require('path');
const home = process.env.HOME || process.env.USERPROFILE;
const settingsPath = path.join(home, '.claude', 'settings.json');
const tmuxAvailable = process.argv.includes('--tmux');

const settings = fs.existsSync(settingsPath)
  ? JSON.parse(fs.readFileSync(settingsPath, 'utf8'))
  : {};

settings.env = Object.assign({}, settings.env, {
  CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS: '1'
});
settings.agent = settings.agent || 'boss';
if (tmuxAvailable && !settings.teammateMode) {
  settings.teammateMode = 'tmux';
}
settings.mcpServers = Object.assign({}, settings.mcpServers, {
  context7: { type: 'url', url: 'https://mcp.context7.com/mcp' },
  exa: { type: 'url', url: 'https://mcp.exa.ai/mcp?tools=web_search_exa' },
  grep_app: { type: 'url', url: 'https://mcp.grep.app' }
});

fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2) + '\n');
console.log('  settings.json merged');
