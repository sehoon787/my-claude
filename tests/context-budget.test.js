#!/usr/bin/env node
// Unit tests for hooks/context-budget.js — runs the hook against a fake
// .briefing vault. `node tests/context-budget.test.js`
'use strict';
const fs = require('fs'), os = require('os'), path = require('path'), cp = require('child_process');
const HOOK = path.resolve(__dirname, '..', 'hooks', 'context-budget.js');

function vault(withIndex, state) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'ctxb-'));
  if (withIndex) {
    fs.mkdirSync(path.join(dir, '.briefing'));
    fs.writeFileSync(path.join(dir, '.briefing', 'INDEX.md'), '---\nlanguage: en\n---\n# x\n');
    if (state) fs.writeFileSync(path.join(dir, '.briefing', 'state.json'), JSON.stringify(state));
  }
  return dir;
}

function hook(dir, mode, env) {
  const out = cp.spawnSync('node', mode ? [HOOK, mode] : [HOOK], {
    cwd: dir,
    input: JSON.stringify({ hook_event_name: 'UserPromptSubmit', prompt: 'do x' }),
    encoding: 'utf8',
    env: Object.assign({}, process.env, env || {})
  });
  let counter = null;
  try {
    counter = JSON.parse(fs.readFileSync(path.join(dir, '.briefing', 'state.json'), 'utf8')).promptsSinceCompact;
  } catch {}
  return { stdout: out.stdout || '', status: out.status, counter };
}

function check(name, ok, detail) {
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? '  (' + detail + ')' : ''}`);
  return ok;
}

const results = [];

// 1. Below the threshold: counts silently.
{
  const dir = vault(true, { promptsSinceCompact: 5 });
  const r = hook(dir, null, { MY_CLAUDE_COMPACT_EVERY: '40' });
  results.push(check('below threshold → no output, counter incremented', r.stdout === '' && r.counter === 6, `stdout=${JSON.stringify(r.stdout)} counter=${r.counter}`));
  fs.rmSync(dir, { recursive: true, force: true });
}

// 2. At the threshold: exactly one additionalContext line.
{
  const dir = vault(true, { promptsSinceCompact: 39 });
  const r = hook(dir, null, { MY_CLAUDE_COMPACT_EVERY: '40' });
  let parsed = null;
  try { parsed = JSON.parse(r.stdout); } catch {}
  const ctx = parsed && parsed.hookSpecificOutput && parsed.hookSpecificOutput.additionalContext;
  const oneLine = r.stdout.trim().split('\n').length === 1;
  results.push(check('at threshold → one /compact line', oneLine && !!ctx && ctx.includes('[ContextBudget]') && ctx.includes('/compact') && r.counter === 40, `ctx=${ctx}`));
  fs.rmSync(dir, { recursive: true, force: true });
}

// 3. Compaction resets the counter, and the nudge does not fire again next prompt.
{
  const dir = vault(true, { promptsSinceCompact: 40 });
  const reset = hook(dir, 'reset', {});
  const next = hook(dir, null, { MY_CLAUDE_COMPACT_EVERY: '40' });
  results.push(check('reset on compact → counter 0, no output', reset.stdout === '' && reset.counter === 0 && next.stdout === '' && next.counter === 1, `reset=${reset.counter} next=${next.counter}`));
  fs.rmSync(dir, { recursive: true, force: true });
}

// 4. No vault: the hook does nothing at all, and creates nothing.
{
  const dir = vault(false);
  const r = hook(dir, null, { MY_CLAUDE_COMPACT_EVERY: '1' });
  results.push(check('missing vault → no-op', r.stdout === '' && r.status === 0 && !fs.existsSync(path.join(dir, '.briefing')), `stdout=${JSON.stringify(r.stdout)}`));
  fs.rmSync(dir, { recursive: true, force: true });
}

// 5. Threshold is configurable and keeps firing on every Nth prompt.
{
  const dir = vault(true, { promptsSinceCompact: 9 });
  const r = hook(dir, null, { MY_CLAUDE_COMPACT_EVERY: '5' });
  results.push(check('custom MY_CLAUDE_COMPACT_EVERY → fires on every Nth', r.stdout.includes('[ContextBudget]') && r.counter === 10, `counter=${r.counter}`));
  fs.rmSync(dir, { recursive: true, force: true });
}

// 6. A corrupt state.json must not block the prompt.
{
  const dir = vault(true);
  fs.writeFileSync(path.join(dir, '.briefing', 'state.json'), '{not json');
  const r = hook(dir, null, { MY_CLAUDE_COMPACT_EVERY: '40' });
  results.push(check('corrupt state.json → fails open', r.status === 0 && r.stdout === '' && r.counter === 1, `counter=${r.counter}`));
  fs.rmSync(dir, { recursive: true, force: true });
}

const failed = results.filter((r) => !r).length;
console.log(failed ? `${failed} FAILED` : 'ALL PASSED');
process.exit(failed ? 1 : 0);
