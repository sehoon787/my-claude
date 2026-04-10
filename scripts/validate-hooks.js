// Usage: node scripts/validate-hooks.js
// Validates hooks in ~/.claude/settings.json on session start.
// Removes command-type hooks that reference non-existent script files.
// Skips inline commands (node -e "...") and prompt-type hooks.
const fs = require('fs');
const path = require('path');
const home = process.env.HOME || process.env.USERPROFILE;
const settingsPath = path.join(home, '.claude', 'settings.json');

if (!fs.existsSync(settingsPath)) process.exit(0);

const settings = JSON.parse(fs.readFileSync(settingsPath, 'utf8'));
if (!settings.hooks) process.exit(0);

let removed = 0;

for (const [event, groups] of Object.entries(settings.hooks)) {
  for (const group of groups) {
    if (!group.hooks || !Array.isArray(group.hooks)) continue;
    group.hooks = group.hooks.filter(hook => {
      // Prompt hooks are always valid
      if (hook.type === 'prompt') return true;
      if (hook.type !== 'command' || !hook.command) return true;

      // Inline commands (node -e, bash -c, echo, etc.) are always valid
      const cmd = hook.command.trim();
      if (/\bnode\s+-e\b/.test(cmd)) return true;
      if (/\bbash\s+-c\b/.test(cmd)) return true;
      if (/^(echo|mkdir|cp|rm|cat|printf)\b/.test(cmd)) return true;

      // Extract file path from "node <path>" or "bash <path>" patterns
      const nodeMatch = cmd.match(/^node\s+["']?([^"'\s]+)["']?/);
      const bashMatch = cmd.match(/^bash\s+["']?([^"'\s]+)["']?/);
      const match = nodeMatch || bashMatch;
      if (!match) return true; // Can't parse — keep it

      let filePath = match[1];
      // Resolve ~ to home directory
      if (filePath.startsWith('~')) {
        filePath = path.join(home, filePath.slice(1));
      }
      // Skip unresolved variables — plugin runtime handles these
      if (/\$\{/.test(filePath) || /\$[A-Z]/.test(filePath)) return true;

      if (fs.existsSync(filePath)) return true;

      // File doesn't exist — remove this hook
      removed++;
      console.log(`  [validate-hooks] Removed ghost hook (${event}): ${filePath}`);
      return false;
    });
  }

  // Remove empty groups
  settings.hooks[event] = settings.hooks[event].filter(
    g => g.hooks && g.hooks.length > 0
  );
  // Remove empty events
  if (settings.hooks[event].length === 0) {
    delete settings.hooks[event];
  }
}

if (removed > 0) {
  fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2) + '\n');
  console.log(`  [validate-hooks] Cleaned ${removed} ghost hook(s) from settings.json`);
} else {
  console.log('  [validate-hooks] All hooks valid');
}
