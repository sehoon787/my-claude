#!/usr/bin/env node
// Regression test: scripts/merge-hooks.js must drop hooks that were removed
// from hooks/hooks.json (e.g. the SubagentStop/TeammateIdle/TaskCompleted
// additionalContext hooks removed in fix/subagent-stop-context-loop) from an
// existing ~/.claude/settings.json on the next merge, while leaving
// unrelated third-party hooks untouched. Also covers the codeburn usage
// guard (#193): its `codeburn guard hook <event>` commands sit on
// PreToolUse/SessionStart/Stop — the same three events my-claude ships its
// own hooks on — so a harness reinstall (a fresh `merge-hooks.js` run) must
// not drop them.
// `node tests/merge-hooks-removal.test.js`
'use strict';
const fs = require('fs'), os = require('os'), path = require('path'), cp = require('child_process');
const SCRIPT = path.resolve(__dirname, '..', 'scripts', 'merge-hooks.js');
const HOOKS_JSON = path.resolve(__dirname, '..', 'hooks', 'hooks.json');

const OLD_SETTINGS = {
  hooks: {
    // codeburn guard install --global writes exactly these three groups.
    PreToolUse: [
      { hooks: [{ type: 'command', command: 'codeburn guard hook pretooluse' }] },
    ],
    SessionStart: [
      { matcher: 'startup', hooks: [{ type: 'command', command: 'codeburn guard hook sessionstart' }] },
    ],
    Stop: [
      { hooks: [{ type: 'command', command: 'codeburn guard hook stop' }] },
    ],
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
  run('codeburn guard PreToolUse hook survives a reinstall', (s) =>
    (s.hooks.PreToolUse || []).some((g) => (g.hooks || []).some((h) => h.command === 'codeburn guard hook pretooluse'))),
  run('codeburn guard SessionStart hook survives a reinstall', (s) =>
    (s.hooks.SessionStart || []).some((g) => (g.hooks || []).some((h) => h.command === 'codeburn guard hook sessionstart'))),
  run('codeburn guard Stop hook survives a reinstall', (s) =>
    (s.hooks.Stop || []).some((g) => (g.hooks || []).some((h) => h.command === 'codeburn guard hook stop'))),
  run('my-claude\'s own PreToolUse hook is still installed alongside the guard', (s) =>
    (s.hooks.PreToolUse || []).some((g) => (g.hooks || []).some((h) => h.command.includes('BOSS PROTOCOL')))),
];
const failed = results.filter((r) => !r).length;
console.log(failed ? `${failed} FAILED` : 'ALL PASSED');
process.exit(failed ? 1 : 0);
