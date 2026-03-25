// Usage: node scripts/get-version.js <plugin-json-path>
// Prints the version from plugin.json, or "unknown" on failure
const fs = require('fs');
const pluginPath = process.argv[2];
try {
  const plugin = JSON.parse(fs.readFileSync(pluginPath, 'utf8'));
  console.log(plugin.version);
} catch (e) {
  console.log('unknown');
}
