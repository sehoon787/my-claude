// Usage: node scripts/merge-hooks.js <hooks-json-path>
// Merges hooks from hooks.json into ~/.claude/settings.json
// Resolves ${CLAUDE_PLUGIN_ROOT}/{hooks,scripts} to ~/.claude/{hooks,scripts}
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

const srcHooks = JSON.parse(fs.readFileSync(hooksJsonPath, 'utf8')).hooks || {};
settings.hooks = settings.hooks || {};

// Resolve ${CLAUDE_PLUGIN_ROOT}/<subdir> → ~/.claude/<subdir> (forward slashes)
const hooksDir = path.join(home, '.claude', 'hooks').replace(/\\/g, '/');
const scriptsDir = path.join(home, '.claude', 'scripts').replace(/\\/g, '/');
let rawHooks = JSON.stringify(srcHooks);
rawHooks = rawHooks.replace(/\$\{CLAUDE_PLUGIN_ROOT\}\/hooks/g, hooksDir);
rawHooks = rawHooks.replace(/\$\{CLAUDE_PLUGIN_ROOT\}\/scripts/g, scriptsDir);
rawHooks = rawHooks.replace(/\$HOME\/\.claude\/hooks/g, hooksDir);
rawHooks = rawHooks.replace(/\$HOME\/\.claude\/scripts/g, scriptsDir);
const resolvedHooks = JSON.parse(rawHooks);

for (const [event, entries] of Object.entries(resolvedHooks)) {
  settings.hooks[event] = entries;
}

fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2) + '\n');
console.log('  hooks merged into settings.json');
