#!/usr/bin/env node
// Regression test: scripts/merge-hooks.js must drop hooks that were removed
// from hooks/hooks.json (e.g. the SubagentStop/TeammateIdle/TaskCompleted
// additionalContext hooks removed in fix/subagent-stop-context-loop) from an
// existing ~/.claude/settings.json on the next merge, while leaving
// unrelated third-party hooks untouched.
// `node tests/merge-hooks-removal.test.js`
'use strict';
const fs = require('fs'), os = require('os'), path = require('path'), cp = require('child_process');
const SCRIPT = path.resolve(__dirname, '..', 'scripts', 'merge-hooks.js');
const HOOKS_JSON = path.resolve(__dirname, '..', 'hooks', 'hooks.json');

const OLD_SETTINGS = {
  hooks: {
    TeammateIdle: [
      {
        hooks: [
          {
            type: 'command',
            command: "node -e \"console.log(JSON.stringify({hookSpecificOutput:{hookEventName:'TeammateIdle',additionalContext:'Teammate idle.'}}))\"",
            timeout: 5000,
          },
        ],
      },
    ],
    TaskCompleted: [
      {
        hooks: [
          {
            type: 'command',
            command: "node -e \"console.log(JSON.stringify({hookSpecificOutput:{hookEventName:'TaskCompleted',additionalContext:'Task completed.'}}))\"",
            timeout: 5000,
          },
        ],
      },
    ],
    SubagentStop: [
      {
        hooks: [
          {
            type: 'command',
            command: "node -e \"console.log(JSON.stringify({hookSpecificOutput:{hookEventName:'SubagentStop',additionalContext:'VERIFICATION REQUIRED.'}}))\"",
            timeout: 5000,
          },
          { type: 'command', command: 'some-unrelated-user-hook --do-thing', timeout: 5000 },
        ],
      },
    ],
  },
};

function run(name, fn) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'mhr-'));
  const home = path.join(dir, 'home');
  fs.mkdirSync(path.join(home, '.claude'), { recursive: true });
  fs.writeFileSync(path.join(home, '.claude', 'settings.json'), JSON.stringify(OLD_SETTINGS, null, 2));
  cp.spawnSync('node', [SCRIPT, HOOKS_JSON], { env: { ...process.env, HOME: home }, encoding: 'utf8' });
  const settings = JSON.parse(fs.readFileSync(path.join(home, '.claude', 'settings.json'), 'utf8'));
  const ok = fn(settings);
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}`);
  fs.rmSync(dir, { recursive: true, force: true });
  return ok;
}

const results = [
  run('removed hook events are dropped', (s) => !s.hooks.TeammateIdle && !s.hooks.TaskCompleted),
  run('stale SubagentStop additionalContext hook is dropped', (s) =>
    (s.hooks.SubagentStop || []).every((g) => (g.hooks || []).every((h) => !h.command.includes('additionalContext')))),
  run('unrelated third-party hook is preserved', (s) =>
    (s.hooks.SubagentStop || []).some((g) => (g.hooks || []).some((h) => h.command === 'some-unrelated-user-hook --do-thing'))),
];
const failed = results.filter((r) => !r).length;
console.log(failed ? `${failed} FAILED` : 'ALL PASSED');
process.exit(failed ? 1 : 0);
