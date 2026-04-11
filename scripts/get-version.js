// Usage: node scripts/get-version.js <plugin-json-path>
// Prints the version from plugin.json, falling back to `git describe` if the
// plugin.json version field is stale (common when a tag is published before
// the version field is bumped).
//
// Resolution order:
//   1. git describe --tags --exact-match  (strip leading "v")
//   2. plugin.json "version" field
//   3. "unknown"
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const pluginPath = process.argv[2];

function tryGitTag(pluginJsonPath) {
  try {
    const repoDir = path.resolve(path.dirname(pluginJsonPath), '..');
    const tag = execSync('git describe --tags --exact-match', {
      cwd: repoDir,
      stdio: ['ignore', 'pipe', 'ignore'],
    })
      .toString()
      .trim();
    if (tag) return tag.replace(/^v/, '');
  } catch (_) {
    // Not on an exact tag, or not a git repo, or git missing — fall through.
  }
  return null;
}

function tryPluginJson(pluginJsonPath) {
  try {
    const plugin = JSON.parse(fs.readFileSync(pluginJsonPath, 'utf8'));
    return plugin.version || null;
  } catch (_) {
    return null;
  }
}

const gitVersion = pluginPath ? tryGitTag(pluginPath) : null;
const jsonVersion = pluginPath ? tryPluginJson(pluginPath) : null;

// Prefer git tag when available — it's the source of truth for releases.
// Fall back to plugin.json (dev checkout, no exact tag) and finally "unknown".
console.log(gitVersion || jsonVersion || 'unknown');
