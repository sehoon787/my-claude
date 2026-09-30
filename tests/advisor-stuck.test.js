#!/usr/bin/env node
// Unit tests for the Stuck trigger in hooks/advisor-gate.js — repeated
// failure, a generic no-progress loop (ralph or a plain human loop), and
// impossibility claims. `node tests/advisor-stuck.test.js`
'use strict';
const fs = require('fs'), os = require('os'), path = require('path'), cp = require('child_process');
const HOOK = path.resolve(__dirname, '..', 'hooks', 'advisor-gate.js');
const SESSION = 's1';
const T0 = '2026-09-29T12:00:00.000Z';
const T1 = '2026-09-29T12:00:01.000Z'; // inside the same turn as T0

const human = (t, extra) => Object.assign({ type: 'user', promptId: 'p1', timestamp: T0, message: { role: 'user', content: t } }, extra);
const agentCall = (sub) => ({ type: 'assistant', message: { role: 'assistant', content: [{ type: 'tool_use', name: 'Agent', input: { subagent_type: sub, prompt: 'q' } }] } });
const toolUse = (id, name, input) => ({ type: 'assistant', message: { role: 'assistant', content: [{ type: 'tool_use', id, name, input: input || {} }] } });
const toolResult = (id, isError) => ({ type: 'user', promptId: 'p1', message: { role: 'user', content: [{ type: 'tool_result', tool_use_id: id, is_error: !!isError, content: 'r' }] } });
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

function runHook({ home, cwd, entries, lam, extra, env }) {
  const tp = path.join(home, `t-${Math.random().toString(36).slice(2)}.jsonl`);
  fs.writeFileSync(tp, entries.map((e) => JSON.stringify(e)).join('\n') + '\n');
  const payload = Object.assign(
    { hook_event_name: 'Stop', session_id: SESSION, transcript_path: tp, last_assistant_message: lam, stop_hook_active: false, cwd },
    extra
  );
  const out = cp.spawnSync('node', [HOOK], {
    cwd,
    env: Object.assign({}, process.env, { HOME: home }, env),
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
  check('3 repeated failures in a turn -> 1 block', r1.blocked && r1.status === 0 && /tracer/.test(r1.doc.reason));
  const r2 = runHook({ home, cwd, entries, lam: 'Still working on it.' });
  check('same failure episode again -> suppressed (1 block per episode)', !r2.blocked);
}

// --- (b) no-progress loop, generic (ralph-style: same turn, repeated Stops)
{
  const home = mkHome(), cwd = mkRepo();
  const entries = [human('keep going'), toolUse('t1', 'Bash', { command: 'run x' }), toolResult('t1', true), asst('Continuing.')];
  let blocks = 0;
  for (let i = 1; i <= 20; i++) {
    writeOmcState(cwd, SESSION, 'ralph-state.json', { active: true, iteration: i }); // optional context only
    const r = runHook({ home, cwd, entries, lam: 'Continuing.', extra: { stop_hook_active: true } });
    if (r.blocked) blocks++;
  }
  check('20 simulated ralph Stops, no diff change -> exactly 1 block', blocks === 1);
}
{
  const home = mkHome(), cwd = mkRepo();
  const entries = [human('keep going'), toolUse('t1', 'Bash', { command: 'run x' }), toolResult('t1', true), asst('Continuing.')];
  let blocks = 0;
  for (let i = 1; i <= 20; i++) {
    writeOmcState(cwd, SESSION, 'ralph-state.json', { active: true, iteration: i });
    fs.appendFileSync(path.join(cwd, 'f.txt'), `change-${i}\n`);
    const r = runHook({ home, cwd, entries, lam: 'Continuing.', extra: { stop_hook_active: true } });
    if (r.blocked) blocks++;
  }
  check('20 simulated ralph Stops, diff changes every Stop -> 0 blocks', blocks === 0);
}

// --- (b) no-progress loop, generic: plain human loop, no ralph at all ----
{
  const home = mkHome(), cwd = mkRepo();
  const texts = ['Trying again.', 'Still trying.', 'One more attempt.'];
  const outcomes = [1, 2, 3].map((n) => {
    const entries = [human(`retry ${n}`, { promptId: `p${n}` }), toolUse(`t${n}`, 'Bash', { command: 'run x' }), toolResult(`t${n}`, true), asst(texts[n - 1])];
    return runHook({ home, cwd, entries, lam: texts[n - 1] }).blocked;
  });
  check('3-turn human loop, no ralph, same diff + same errorSig -> 1 block (3rd Stop)',
    outcomes[0] === false && outcomes[1] === false && outcomes[2] === true);
}
{
  const home = mkHome(), cwd = mkRepo();
  const texts = ['Trying again.', 'Still trying.', 'One more attempt.'];
  const outcomes = [1, 2, 3].map((n) => {
    fs.appendFileSync(path.join(cwd, 'f.txt'), `change-${n}\n`);
    const entries = [human(`retry ${n}`, { promptId: `p${n}` }), toolUse(`t${n}`, 'Bash', { command: 'run x' }), toolResult(`t${n}`, true), asst(texts[n - 1])];
    return runHook({ home, cwd, entries, lam: texts[n - 1] }).blocked;
  });
  check('3-turn human loop, no ralph, changing diff -> 0 blocks', outcomes.every((b) => b === false));
}
{
  // Same diff, identical final text each turn, but no repeated errorSig
  // (tool_result succeeds) -- isolates the textSig-only firing path.
  const home = mkHome(), cwd = mkRepo();
  const lam = 'Still stuck on the same step.';
  const outcomes = [1, 2, 3].map((n) => {
    const entries = [human(`retry ${n}`, { promptId: `p${n}` }), toolUse(`t${n}`, 'Bash', { command: 'run x' }), toolResult(`t${n}`, false), asst(lam)];
    return runHook({ home, cwd, entries, lam }).blocked;
  });
  check('3-turn human loop, no ralph, identical text + same diff (no repeated error) -> 1 block (3rd Stop)',
    outcomes[0] === false && outcomes[1] === false && outcomes[2] === true);
}

// --- (b) no-progress loop, ralph-specific addition: frozen diff alone ----
{
  // No tool calls at all, so the generic toolCalls>0 rule never fires; the
  // ralph-only "iteration >= 5 + frozen diff" addition must fire instead.
  const home = mkHome(), cwd = mkRepo();
  const entries = [human('keep going'), asst('Continuing.')];
  let blocks = 0;
  for (let i = 1; i <= 20; i++) {
    writeOmcState(cwd, SESSION, 'ralph-state.json', { active: true, iteration: i });
    const r = runHook({ home, cwd, entries, lam: 'Continuing.', extra: { stop_hook_active: true } });
    if (r.blocked) blocks++;
  }
  check('ralph active, frozen diff, zero tool calls -> exactly 1 block (ralph-only rule)', blocks === 1);
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
  const lam = "- Claude S1~S5: 반복 실패 → tracer, 불가능 주장 → oracle, `Blocked on user` 통과, 루프, …";
  const r = runHook({ home, cwd, entries: [human('try again'), asst(lam)], lam });
  check("observed bullet naming a test scenario -> no block", !r.blocked);
}
{
  const home = mkHome(), cwd = mkRepo();
  const lam = "불가능 주장 → oracle";
  const r = runHook({ home, cwd, entries: [human('try again'), asst(lam)], lam });
  check("bare noun '불가능 주장 → oracle' -> no block", !r.blocked);
}
{
  const home = mkHome(), cwd = mkRepo();
  const lam = "이 작업은 불가능합니다.";
  const r = runHook({ home, cwd, entries: [human('try again'), asst(lam)], lam });
  check("KO predicate '이 작업은 불가능합니다.' -> block", r.blocked);
}
{
  const home = mkHome(), cwd = mkRepo();
  const lam = "권한이 없어 할 수 없습니다.";
  const r = runHook({ home, cwd, entries: [human('try again'), asst(lam)], lam });
  check("KO predicate '할 수 없습니다' -> block", r.blocked);
}
{
  const home = mkHome(), cwd = mkRepo();
  const lam = "This is impossible without admin rights.";
  const r = runHook({ home, cwd, entries: [human('try again'), asst(lam)], lam });
  check("EN 'This is impossible without admin rights.' -> block", r.blocked);
}
{
  const home = mkHome(), cwd = mkRepo();
  const lam = "`불가능합니다`";
  const r = runHook({ home, cwd, entries: [human('try again'), asst(lam)], lam });
  check("claim inside inline code -> no block", !r.blocked);
}
{
  const home = mkHome(), cwd = mkRepo();
  const lam = "The detector matches \"This is impossible\" phrasing.";
  const r = runHook({ home, cwd, entries: [human('try again'), asst(lam)], lam });
  check("claim inside double quotes -> no block", !r.blocked);
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
  const lam = 'This is impossible without admin login.\n\nBlocked on user:';
  const r = runHook({ home, cwd, entries: [human('try again'), asst(lam)], lam });
  check('"Blocked on user:" with nothing after it -> block', r.blocked);
}
{
  const home = mkHome(), cwd = mkRepo();
  const lam = 'This is impossible without admin login.\n\nBlocked on user: n/a';
  const r = runHook({ home, cwd, entries: [human('try again'), asst(lam)], lam });
  check('"Blocked on user: n/a" -> block', r.blocked);
}
{
  const home = mkHome(), cwd = mkRepo();
  const lam = 'This is impossible without admin login.\n\nBlocked on user: <action>';
  const r = runHook({ home, cwd, entries: [human('try again'), asst(lam)], lam });
  check('"Blocked on user: <action>" placeholder -> block', r.blocked);
}
{
  const home = mkHome(), cwd = mkRepo();
  const lam = 'This is impossible right now.\n\nAdvisor skipped:';
  const r = runHook({ home, cwd, entries: [human('try again'), asst(lam)], lam });
  check('"Advisor skipped:" with nothing after it -> block', r.blocked);
}
{
  const home = mkHome(), cwd = mkRepo();
  const lam = 'This is impossible right now.\n\nAdvisor skipped: n/a';
  const r = runHook({ home, cwd, entries: [human('try again'), asst(lam)], lam });
  check('"Advisor skipped: n/a" -> block', r.blocked);
}
{
  const home = mkHome(), cwd = mkRepo();
  const lam = 'This is impossible right now.\n\nAdvisor skipped: <reason>';
  const r = runHook({ home, cwd, entries: [human('try again'), asst(lam)], lam });
  check('"Advisor skipped: <reason>" placeholder -> block', r.blocked);
}
{
  const home = mkHome(), cwd = mkRepo();
  const lam = 'This is impossible without more info.';
  const entries = [human('q'), agentCall('oracle'), toolResult('x', false), asst(lam)];
  const r = runHook({ home, cwd, entries, lam });
  check('oracle call made this turn -> no block', !r.blocked);
}
{
  const home = mkHome(), cwd = mkRepo();
  const lam = 'There is no way to do this with the current permissions.';
  const entries = [human('q'), agentCall('tracer'), toolResult('x', false), asst(lam)];
  const r = runHook({ home, cwd, entries, lam });
  check('calling tracer satisfies the gate -> no block', !r.blocked);
}

// --- routing-map is read as data, not hardcoded ---------------------------
{
  const home = mkHome(), cwd = mkRepo();
  const fixtureMap = path.join(home, 'routing-map.fixture.json');
  fs.writeFileSync(fixtureMap, JSON.stringify({ intents: [{ name: 'Stuck', members: ['custom-advisor'] }] }));
  const lam = 'This cannot be done as specified.';
  const entries = [human('q'), agentCall('custom-advisor'), toolResult('x', false), asst(lam)];
  const r = runHook({ home, cwd, entries, lam, env: { ROUTING_MAP: fixtureMap } });
  check('routing-map Stuck entry is read: a fixture member satisfies the gate', !r.blocked);
}

// --- git unavailable: computeDiffHash must fail open, never block --------
{
  // cwd is not a git repo: every execSync attempt in computeDiffHash throws
  // ("not a git repository"), it returns null, and the no-progress window
  // must never treat that as "diff unchanged". Reuses the ralph scenario
  // that would otherwise fire the ralph-only frozen-diff rule.
  const home = mkHome();
  const cwd = fs.mkdtempSync(path.join(os.tmpdir(), 'astuck-nogit-'));
  const entries = [human('keep going'), asst('Continuing.')];
  let blocks = 0;
  let allExitZero = true;
  for (let i = 1; i <= 20; i++) {
    writeOmcState(cwd, SESSION, 'ralph-state.json', { active: true, iteration: i });
    const r = runHook({ home, cwd, entries, lam: 'Continuing.', extra: { stop_hook_active: true } });
    if (r.blocked) blocks++;
    if (r.status !== 0) allExitZero = false;
  }
  check('git unavailable (cwd not a repo) -> computeDiffHash fails open, never blocks', blocks === 0 && allExitZero);
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
