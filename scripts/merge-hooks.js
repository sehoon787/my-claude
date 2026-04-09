// Usage: node scripts/merge-hooks.js <hooks-json-path>
// Merges hooks from hooks.json into ~/.claude/settings.json
// Resolves ${CLAUDE_PLUGIN_ROOT}/hooks to ~/.claude/hooks
const fs = require('fs');
const path = require('path');
const home = process.env.HOME || process.env.USERPROFILE;
const settingsPath = path.join(home, '.claude', 'settings.json');
const hooksJsonPath = process.argv[2];

if (!hooksJsonPath || !fs.existsSync(hooksJsonPath)) {
  console.error('  ERROR: hooks.json not found at', hooksJsonPath);
  process.exit(1);
}

const settings = fs.existsSync(settingsPath)
  ? JSON.parse(fs.readFileSync(settingsPath, 'utf8'))
  : {};

// Skip hook merging when plugin is active (plugin loads hooks directly)
const pluginKey = 'my-claude@my-claude';
if (settings.enabledPlugins && settings.enabledPlugins[pluginKey]) {
  // Remove stale hooks from settings.json to prevent duplicate execution
  if (settings.hooks) {
    delete settings.hooks;
    fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2) + '\n');
    console.log('  plugin active — removed stale hooks from settings.json');
  } else {
    console.log('  plugin active — hooks managed by plugin, skipping merge');
  }
  process.exit(0);
}

const srcHooks = JSON.parse(fs.readFileSync(hooksJsonPath, 'utf8')).hooks || {};
settings.hooks = settings.hooks || {};

// Resolve ${CLAUDE_PLUGIN_ROOT}/hooks → ~/.claude/hooks (forward slashes)
const hooksDir = path.join(home, '.claude', 'hooks').replace(/\\/g, '/');
let rawHooks = JSON.stringify(srcHooks);
rawHooks = rawHooks.replace(/\$\{CLAUDE_PLUGIN_ROOT\}\/hooks/g, hooksDir);
const resolvedHooks = JSON.parse(rawHooks);

for (const [event, entries] of Object.entries(resolvedHooks)) {
  settings.hooks[event] = entries;
}

fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2) + '\n');
console.log('  hooks merged into settings.json');
