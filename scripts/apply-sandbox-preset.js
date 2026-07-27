// Usage: node scripts/apply-sandbox-preset.js [--dry-run]
//
// Opt-in hardening preset for Claude Code's sandbox. NOT run by install.sh —
// invoke it by hand when you want it. It merges (never replaces) these keys
// into ~/.claude/settings.json:
//
//   sandbox.network.strictAllowlist  -> true
//     Sandboxed commands hitting a host outside allowedDomains are denied
//     outright instead of prompting. (Claude Code 2.1.219+)
//
//   sandbox.credentials.files[]      -> { path, mode: "deny" }
//   sandbox.credentials.envVars[]    -> { name, mode: "deny" }
//     Sandboxed commands cannot read these credential files or see these
//     secret environment variables. (Claude Code 2.1.187+)
//
// Key names and value shapes were read off the installed CLI's settings schema,
// not guessed: files/envVars are arrays of objects, mode "deny" (envVars also
// accept "mask", unused here).
//
// Existing entries are preserved; the preset only adds what is missing and
// leaves allowedDomains, filesystem rules, and every other setting untouched.

const fs = require('fs');
const path = require('path');

const home = process.env.HOME || process.env.USERPROFILE;
const settingsPath = path.join(home, '.claude', 'settings.json');
const dryRun = process.argv.includes('--dry-run');

const CREDENTIAL_FILES = [
  '~/.ssh',
  '~/.aws',
  '~/.gnupg',
  '~/.netrc',
  '~/.npmrc',
  '~/.docker/config.json',
  '~/.config/gcloud',
  '~/.claude/.credentials.json',
];

const CREDENTIAL_ENV_VARS = [
  'ANTHROPIC_API_KEY',
  'AWS_ACCESS_KEY_ID',
  'AWS_SECRET_ACCESS_KEY',
  'AWS_SESSION_TOKEN',
  'GITHUB_TOKEN',
  'GH_TOKEN',
  'NPM_TOKEN',
  'OPENAI_API_KEY',
  'GEMINI_API_KEY',
];

if (!fs.existsSync(settingsPath)) {
  console.error(`No settings file at ${settingsPath} — start Claude Code once, then re-run.`);
  process.exit(1);
}

const raw = fs.readFileSync(settingsPath, 'utf8');
const settings = JSON.parse(raw);
const changes = [];

const sandbox = settings.sandbox || {};
const network = sandbox.network || {};
const credentials = sandbox.credentials || {};
const files = Array.isArray(credentials.files) ? credentials.files.slice() : [];
const envVars = Array.isArray(credentials.envVars) ? credentials.envVars.slice() : [];

if (network.strictAllowlist !== true) {
  changes.push(`sandbox.network.strictAllowlist: ${JSON.stringify(network.strictAllowlist)} -> true`);
  network.strictAllowlist = true;
}

for (const p of CREDENTIAL_FILES) {
  if (files.some((f) => f && f.path === p)) continue;
  files.push({ path: p, mode: 'deny' });
  changes.push(`sandbox.credentials.files += ${p} (deny)`);
}

for (const name of CREDENTIAL_ENV_VARS) {
  if (envVars.some((v) => v && v.name === name)) continue;
  envVars.push({ name, mode: 'deny' });
  changes.push(`sandbox.credentials.envVars += ${name} (deny)`);
}

if (!changes.length) {
  console.log('Sandbox preset already applied — nothing to change.');
  process.exit(0);
}

credentials.files = files;
credentials.envVars = envVars;
sandbox.network = network;
sandbox.credentials = credentials;
settings.sandbox = sandbox;

console.log(dryRun ? 'Would change:' : 'Changed:');
for (const line of changes) console.log(`  ${line}`);

if (dryRun) {
  console.log('\n[DRY RUN] settings.json not written.');
  process.exit(0);
}

fs.writeFileSync(`${settingsPath}.bak`, raw);
fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2) + '\n');
console.log(`\nWrote ${settingsPath} (backup: ${settingsPath}.bak)`);
console.log('Sandbox rules apply to sandboxed commands only; unsandboxed Bash is unaffected.');
