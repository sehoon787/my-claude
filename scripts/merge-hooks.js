// Usage: node scripts/merge-hooks.js <hooks-json-path>
// Merges hooks from hooks.json into ~/.claude/settings.json
// Resolves ${CLAUDE_PLUGIN_ROOT}/{hooks,scripts} to ~/.claude/{hooks,scripts}
//
// Ownership rule: this script replaces ONLY the entries my-claude ships and
// keeps everything else. Previously it assigned each event's array wholesale,
// which silently deleted any third-party hook registered on an event we also
// use (PreToolUse / SessionStart / Stop) — e.g. `codeburn guard install` was
// wiped on every re-run of install.sh. An entry counts as ours when its
// command references our hooks/ or scripts/ dir, or is one of the inline
// `node -e` hooks we ship (all of which touch .briefing/ or emit
// hookSpecificOutput). Anything else is foreign and is preserved verbatim.
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
const existing = (settings.hooks && typeof settings.hooks === 'object') ? settings.hooks : {};

// Resolve ${CLAUDE_PLUGIN_ROOT}/<subdir> → ~/.claude/<subdir> (forward slashes)
const hooksDir = path.join(home, '.claude', 'hooks').replace(/\\/g, '/');
const scriptsDir = path.join(home, '.claude', 'scripts').replace(/\\/g, '/');
let rawHooks = JSON.stringify(srcHooks);
rawHooks = rawHooks.replace(/\$\{CLAUDE_PLUGIN_ROOT\}\/hooks/g, hooksDir);
rawHooks = rawHooks.replace(/\$\{CLAUDE_PLUGIN_ROOT\}\/scripts/g, scriptsDir);
rawHooks = rawHooks.replace(/\$HOME\/\.claude\/hooks/g, hooksDir);
rawHooks = rawHooks.replace(/\$HOME\/\.claude\/scripts/g, scriptsDir);
const resolvedHooks = JSON.parse(rawHooks);

const OWNERSHIP_MARKERS = [hooksDir, scriptsDir, '.briefing', 'BOSS PROTOCOL', '.gstack/analytics', 'hookSpecificOutput'];
const isOurs = (cmd) => typeof cmd === 'string' && OWNERSHIP_MARKERS.some((m) => cmd.includes(m));

const merged = {};
const events = new Set([...Object.keys(existing), ...Object.keys(resolvedHooks)]);
let preserved = 0;
for (const event of events) {
  const foreignGroups = (Array.isArray(existing[event]) ? existing[event] : [])
    .map((g) => ({ ...g, hooks: (Array.isArray(g.hooks) ? g.hooks : []).filter((h) => !isOurs(h && h.command)) }))
    .filter((g) => g.hooks.length > 0);
  preserved += foreignGroups.reduce((n, g) => n + g.hooks.length, 0);
  const ours = Array.isArray(resolvedHooks[event]) ? resolvedHooks[event] : [];
  const groups = [...ours, ...foreignGroups];
  if (groups.length > 0) merged[event] = groups;
}
settings.hooks = merged;

fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2) + '\n');
console.log(`  hooks merged into settings.json (${preserved} third-party hook${preserved === 1 ? '' : 's'} preserved)`);
