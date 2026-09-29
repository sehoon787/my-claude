#!/usr/bin/env node
// Unit tests for the Stuck trigger in hooks/advisor-gate.js — repeated
// failure, ralph loop-without-progress, and impossibility claims.
// `node tests/advisor-stuck.test.js`
'use strict';
const fs = require('fs'), os = require('os'), path = require('path'), cp = require('child_process');
const HOOK = path.resolve(__dirname, '..', 'hooks', 'advisor-gate.js');
const SESSION = 's1';
const T0 = '2026-09-29T12:00:00.000Z';
const T1 = '2026-09-29T12:00:01.000Z'; // inside the same turn as T0

const human = (t, extra) => Object.assign({ type: 'user', promptId: 'p1', timestamp: T0, message: { role: 'user', content: t } }, extra);
const agentCall = (sub) => ({ type: 'assistant', message: { role: 'assistant', content: [{ type: 'tool_use', name: 'Agent', input: { subagent_type: sub, prompt: 'q' } }] } });
const tool = (t) => ({ type: 'user', promptId: 'p1', message: { role: 'user', content: [{ type: 'tool_result', content: t }] } });
const asst = (t) => ({ type: 'assistant', message: { role: 'assistant', content: [{ type: 'text', text: t }] } });

function mkHome() {
  return fs.mkdtempSync(path.join(os.tmpdir(), 'astuck-home-'));
}

function mkRepo() {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'astuck-repo-'));
  const run = (cmd) => cp.execSync(cmd, { cwd: dir, stdio: 'ignore' });
  run('git init -q');
  run('git config user.email t@example.com');
  run('git config user.name Test');
  fs.writeFileSync(path.join(dir, 'f.txt'), 'base\n');
  run('git add -A');
  run('git commit -q -m base');
  return dir;
}

function writeOmcState(cwd, session, filename, data) {
  const dir = path.join(cwd, '.omc', 'state', 'sessions', session);
  fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(path.join(dir, filename), JSON.stringify(data));
}

function runHook({ home, cwd, entries, lam, extra }) {
  const tp = path.join(home, `t-${Math.random().toString(36).slice(2)}.jsonl`);
  fs.writeFileSync(tp, entries.map((e) => JSON.stringify(e)).join('\n') + '\n');
  const payload = Object.assign(
    { hook_event_name: 'Stop', session_id: SESSION, transcript_path: tp, last_assistant_message: lam, stop_hook_active: false, cwd },
    extra
  );
  const out = cp.spawnSync('node', [HOOK], {
    cwd,
    env: Object.assign({}, process.env, { HOME: home }),
    input: JSON.stringify(payload),
    encoding: 'utf8',
  });
  let doc = null;
  try { doc = out.stdout.trim() ? JSON.parse(out.stdout) : null; } catch { /* malformed */ }
  return { blocked: !!doc && doc.decision === 'block', doc, status: out.status };
}

const results = [];
const check = (name, ok) => { console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}`); results.push(ok); };

// --- (a) repeated failure: OMC state file, retry_count >= 3 -------------
{
  const home = mkHome(), cwd = mkRepo();
  const entries = [human('do the thing'), asst('Still working on it.')];
  writeOmcState(cwd, SESSION, 'last-tool-error-state.json', {
    tool_name: 'Bash', tool_input_preview: '...', error: 'boom', timestamp: T1, retry_count: 3,
  });
  const r1 = runHook({ home, cwd, entries, lam: 'Still working on it.' });
  check('3 repeated failures in a turn -> 1 block', r1.blocked && r1.status === 0 && /oracle/.test(r1.doc.reason));
  const r2 = runHook({ home, cwd, entries, lam: 'Still working on it.' });
  check('same failure episode again -> suppressed (1 block per episode)', !r2.blocked);
}

// --- (b) ralph loop without progress -------------------------------------
{
  const home = mkHome(), cwd = mkRepo();
  const entries = [human('keep going'), asst('Continuing.')];
  let blocks = 0;
  for (let i = 1; i <= 20; i++) {
    writeOmcState(cwd, SESSION, 'ralph-state.json', { active: true, iteration: i });
    const r = runHook({ home, cwd, entries, lam: 'Continuing.', extra: { stop_hook_active: true } });
    if (r.blocked) blocks++;
  }
  check('20 simulated ralph Stops, no diff change -> exactly 1 block', blocks === 1);
}
{
  const home = mkHome(), cwd = mkRepo();
  const entries = [human('keep going'), asst('Continuing.')];
  let blocks = 0;
  for (let i = 1; i <= 20; i++) {
    writeOmcState(cwd, SESSION, 'ralph-state.json', { active: true, iteration: i });
    fs.appendFileSync(path.join(cwd, 'f.txt'), `change-${i}\n`);
    const r = runHook({ home, cwd, entries, lam: 'Continuing.', extra: { stop_hook_active: true } });
    if (r.blocked) blocks++;
  }
  check('20 simulated ralph Stops, diff changes every Stop -> 0 blocks', blocks === 0);
}

// --- (c) impossibility claim ----------------------------------------------
{
  const home = mkHome(), cwd = mkRepo();
  const lam = 'This is impossible given the current constraints.';
  const r = runHook({ home, cwd, entries: [human('try again'), asst(lam)], lam });
  check('impossibility claim (EN) -> block', r.blocked && /oracle/.test(r.doc.reason));
}
{
  const home = mkHome(), cwd = mkRepo();
  const lam = '이 방법으로는 불가능합니다.';
  const r = runHook({ home, cwd, entries: [human('try again'), asst(lam)], lam });
  check('impossibility claim (KO) -> block', r.blocked);
}
{
  const home = mkHome(), cwd = mkRepo();
  const lam = '```\nThis is impossible.\n```\nHere is plan B instead.';
  const r = runHook({ home, cwd, entries: [human('try again'), asst(lam)], lam });
  check('claim inside a code fence -> no block', !r.blocked);
}
{
  const home = mkHome(), cwd = mkRepo();
  const lam = 'This is impossible without admin login.\n\nBlocked on user: approve hook trust';
  const r = runHook({ home, cwd, entries: [human('try again'), asst(lam)], lam });
  check('"Blocked on user: approve hook trust" -> no block', !r.blocked);
}
{
  const home = mkHome(), cwd = mkRepo();
  const lam = 'This is impossible right now.\n\nAdvisor skipped: known limitation, no advisor needed';
  const r = runHook({ home, cwd, entries: [human('try again'), asst(lam)], lam });
  check('"Advisor skipped: x" -> no block', !r.blocked);
}
{
  const home = mkHome(), cwd = mkRepo();
  const lam = 'This is impossible without more info.';
  const entries = [human('q'), agentCall('oracle'), tool('advice'), asst(lam)];
  const r = runHook({ home, cwd, entries, lam });
  check('oracle call made this turn -> no block', !r.blocked);
}

// --- session cap: at most 2 Stuck blocks per session ----------------------
{
  const home = mkHome(), cwd = mkRepo();
  const claims = [
    'This is impossible with the current API.',
    'There is no way to fix this without X.',
    'This cannot be done without Y.',
  ];
  const outcomes = claims.map((lam) => runHook({ home, cwd, entries: [human('q'), asst(lam)], lam }).blocked);
  check('session cap holds: 3 distinct episodes -> blocked, blocked, NOT blocked',
    outcomes[0] === true && outcomes[1] === true && outcomes[2] === false);
}

const failed = results.filter((r) => !r).length;
console.log(failed ? `${failed} FAILED` : 'ALL PASSED');
process.exit(failed ? 1 : 0);
