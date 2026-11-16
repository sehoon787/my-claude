#!/usr/bin/env node
// Regression test: scripts/merge-settings.js must leave Claude Code's auto-compact
// trigger alone. Earlier installs wrote env.CLAUDE_AUTOCOMPACT_PCT_OVERRIDE='75'.
// On a ~200k-window model that triggers at about the size the context already has
// right after a compaction (summary, re-attached skills, CLAUDE.md, rules), so the
// session refills within a few turns and Claude Code stops with "Autocompact is
// thrashing". The installer now sets no override, removes exactly the '75' it used
// to write, and keeps any other value the user set.
// `node tests/merge-settings-autocompact.test.js`
'use strict';
const fs = require('fs'), os = require('os'), path = require('path'), cp = require('child_process');
const SCRIPT = path.resolve(__dirname, '..', 'scripts', 'merge-settings.js');
const KEY = 'CLAUDE_AUTOCOMPACT_PCT_OVERRIDE';
const results = [];

function check(name, ok, detail) {
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${!ok && detail ? '  (' + detail + ')' : ''}`);
  results.push(ok);
}

// Runs `body` against a throwaway HOME whose ~/.claude/settings.json holds `initial`
// (no file when null). The child gets that HOME through its own env, so the real
// ~/.claude is never read or written. `merge()` runs the script once and returns what
// it printed plus the settings file it left behind.
function scenario(initial, body) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'msac-'));
  const home = path.join(dir, 'home');
  const file = path.join(home, '.claude', 'settings.json');
  fs.mkdirSync(path.dirname(file), { recursive: true });
  if (initial) fs.writeFileSync(file, JSON.stringify(initial, null, 2) + '\n');
  const merge = () => {
    const r = cp.spawnSync(process.execPath, [SCRIPT], { env: { ...process.env, HOME: home }, encoding: 'utf8' });
    if (r.status !== 0) throw new Error(`merge-settings.js exited ${r.status}: ${r.stderr}`);
    const raw = fs.readFileSync(file);
    return { stdout: r.stdout, raw, settings: JSON.parse(raw.toString('utf8')) };
  };
  try {
    body(merge);
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

const reported = (stdout) => stdout.split('\n').filter((line) => line.includes(KEY));
const show = (value) => JSON.stringify(value);

// (a) No settings.json yet: no override, the rest of the merge is intact, and Claude
// Code's own auto-compact window setting is left at its default.
scenario(null, (merge) => {
  const { settings: s } = merge();
  check('(a) fresh install: CLAUDE_AUTOCOMPACT_PCT_OVERRIDE is not written', !(KEY in s.env), `env.${KEY}=${show(s.env[KEY])}`);
  check('(a) fresh install: OMC_QUIET=2 and agent=boss are still set', s.env.OMC_QUIET === '2' && s.agent === 'boss',
    `OMC_QUIET=${show(s.env.OMC_QUIET)} agent=${show(s.agent)}`);
  check('(a) fresh install: no autoCompactWindow / CLAUDE_CODE_AUTO_COMPACT_WINDOW is set',
    s.autoCompactWindow === undefined && !('CLAUDE_CODE_AUTO_COMPACT_WINDOW' in s.env),
    `autoCompactWindow=${show(s.autoCompactWindow)} CLAUDE_CODE_AUTO_COMPACT_WINDOW=${show(s.env.CLAUDE_CODE_AUTO_COMPACT_WINDOW)}`);
});

// (b) The '75' an earlier install wrote is removed; everything else the user has stays.
scenario({
  env: { [KEY]: '75', MY_OWN_VAR: 'keep-me' },
  model: 'opus',
  permissions: { allow: ['Bash(ls:*)'] }
}, (merge) => {
  const { settings: s, stdout } = merge();
  check("(b) earlier install's '75': CLAUDE_AUTOCOMPACT_PCT_OVERRIDE is removed", !(KEY in s.env), `env.${KEY}=${show(s.env[KEY])}`);
  check("(b) earlier install's '75': other env keys and unrelated settings are preserved",
    s.env.MY_OWN_VAR === 'keep-me' && s.model === 'opus' && show(s.permissions) === show({ allow: ['Bash(ls:*)'] }),
    `MY_OWN_VAR=${show(s.env.MY_OWN_VAR)} model=${show(s.model)} permissions=${show(s.permissions)}`);
  const lines = reported(stdout);
  check("(b) earlier install's '75': one line reports the removal and names autoCompactWindow: auto",
    lines.length === 1 && lines[0].includes('removed') && lines[0].includes('autoCompactWindow: auto'), show(lines));
});

// (c) Any other value is the user's own and stays untouched.
scenario({ env: { [KEY]: '60' } }, (merge) => {
  const { settings: s, stdout } = merge();
  check("(c) user value '60' is kept as '60'", s.env[KEY] === '60', `env.${KEY}=${show(s.env[KEY])}`);
  check("(c) user value '60': nothing is reported as removed", reported(stdout).length === 0, show(reported(stdout)));
});

// (d) A second merge changes nothing, including after the migration has run.
scenario({ env: { [KEY]: '75' } }, (merge) => {
  const first = merge();
  const second = merge();
  check('(d) second run: settings.json is byte-identical', first.raw.equals(second.raw),
    `${first.raw.length} bytes -> ${second.raw.length} bytes`);
  check('(d) second run: CLAUDE_AUTOCOMPACT_PCT_OVERRIDE is still absent', !(KEY in second.settings.env),
    `env.${KEY}=${show(second.settings.env[KEY])}`);
  check('(d) second run: nothing is reported as removed again', reported(second.stdout).length === 0, show(reported(second.stdout)));
});

const failed = results.filter((ok) => !ok).length;
console.log(failed ? `${failed} FAILED` : 'ALL PASSED');
process.exit(failed ? 1 : 0);
