#!/usr/bin/env node
// Unit tests for hooks/advisor-gate.js — runs the hook against a fake HOME
// (intent file + marker) and fake transcripts. `node tests/advisor-gate.test.js`
'use strict';
const fs = require('fs'), os = require('os'), path = require('path'), cp = require('child_process');
const HOOK = path.resolve(__dirname, '..', 'hooks', 'advisor-gate.js');
const SESSION = 's1';
const T0 = '2026-09-29T12:00:00.000Z';
const T1 = '2026-09-29T12:00:00.300Z';   // intent written just after the prompt
const T_OLD = '2026-09-29T11:00:00.000Z'; // intent from an earlier prompt
const ANSWER = 'Keep the settings.json merge; here is why.';
const SKIPPED = 'Line 3 of README.md.\n\nAdvisor skipped: trivial one-line lookup, the hint misclassified it.';

const human = (t, extra) => Object.assign({ type: 'user', promptId: 'p1', timestamp: T0, message: { role: 'user', content: t } }, extra);
const notif = (t) => ({ type: 'user', origin: { kind: 'task-notification' }, promptId: 'p1', timestamp: T0, message: { role: 'user', content: '<task-notification>' + t + '</task-notification>' } });
const teammate = (t) => ({ type: 'user', promptId: 'p1', timestamp: T0, message: { role: 'user', content: '<teammate-message teammate_id="lead">' + t + '</teammate-message>' } });
const meta = (t) => ({ type: 'user', isMeta: true, promptId: 'p1', message: { role: 'user', content: t } });
const tool = (t) => ({ type: 'user', promptId: 'p1', message: { role: 'user', content: [{ type: 'tool_result', content: t }] } });
const agentCall = (sub, name = 'Agent') => ({ type: 'assistant', message: { role: 'assistant', content: [{ type: 'tool_use', name, input: { subagent_type: sub, prompt: 'q' } }] } });
const asst = (t = ANSWER) => ({ type: 'assistant', message: { role: 'assistant', content: [{ type: 'text', text: t }] } });

function run(name, { entries, intent = 'Architecture', intentTs = T1, lam = ANSWER, input = {}, marker }, expectBlocked) {
  const home = fs.mkdtempSync(path.join(os.tmpdir(), 'agate-'));
  const scratch = path.join(home, '.claude', '.adoption');
  fs.mkdirSync(scratch, { recursive: true });
  if (intent) fs.writeFileSync(path.join(scratch, `intent-${SESSION}.json`), JSON.stringify({ intent, ts: intentTs }));
  if (marker) fs.writeFileSync(path.join(scratch, `advisor-gate-${SESSION}.json`), JSON.stringify({ turn: marker }));
  const tp = path.join(home, 't.jsonl');
  fs.writeFileSync(tp, entries.map((e) => JSON.stringify(e)).join('\n') + '\n');
  const payload = Object.assign({ hook_event_name: 'Stop', session_id: SESSION, transcript_path: tp, last_assistant_message: lam, stop_hook_active: false }, input);
  const out = cp.spawnSync('node', [HOOK], { cwd: home, env: Object.assign({}, process.env, { HOME: home }), input: JSON.stringify(payload), encoding: 'utf8' });
  let doc = null;
  try { doc = out.stdout.trim() ? JSON.parse(out.stdout) : null; } catch { /* malformed */ }
  const blocked = !!doc && doc.decision === 'block';
  const oneDoc = out.stdout.trim() === '' || (!!doc && out.stdout.trim().split('\n').length === 1);
  const ok = blocked === expectBlocked && oneDoc && out.status === 0;
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}  (blocked=${blocked}${blocked ? `, reason names ${(doc.reason.match(/`(oracle|metis|momus)`/) || [])[1]}` : ''})`);
  fs.rmSync(home, { recursive: true, force: true });
  return { ok, doc };
}

const results = [];
const check = (name, ok) => { console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}`); results.push(ok); };

const arch = run('Architecture, no advisor call, no skip line → block', { entries: [human('should we merge hooks?'), tool('read'), asst()] }, true);
results.push(arch.ok);
check('block reason names oracle and asks to repeat the final answer', !!arch.doc && /`oracle`/.test(arch.doc.reason) && /repeat your full final answer/.test(arch.doc.reason) && /Advisor skipped:/.test(arch.doc.reason));
const amb = run('Ambiguity, no advisor call → block naming metis', { entries: [human('make it better'), asst()], intent: 'Ambiguity' }, true);
results.push(amb.ok && /`metis`/.test(amb.doc.reason));
const plan = run('PlanReview, no advisor call → block naming momus', { entries: [human('is this plan safe?'), asst()], intent: 'PlanReview' }, true);
results.push(plan.ok && /`momus`/.test(plan.doc.reason));

for (const [n, o, e] of [
  ['oracle called via Agent → pass', { entries: [human('q'), agentCall('oracle'), tool('advice'), asst()] }, false],
  ['plugin-namespaced advisor (my-claude:oracle) → pass', { entries: [human('q'), agentCall('my-claude:oracle'), tool('advice'), asst()] }, false],
  ['advisor called via Task tool → pass', { entries: [human('q'), agentCall('metis', 'Task'), tool('advice'), asst()], intent: 'Ambiguity' }, false],
  ['a different advisor than the intent’s still counts → pass', { entries: [human('q'), agentCall('momus'), tool('advice'), asst()] }, false],
  ['non-advisor agent (architect) only → block', { entries: [human('q'), agentCall('oh-my-claudecode:architect'), tool('r'), asst()] }, true],
  ['advisor call made after an earlier Stop-feedback (isMeta) entry → pass', { entries: [human('q'), asst(), meta('Stop hook feedback:\n[FinalReport] ...'), agentCall('oracle'), tool('advice'), asst()] }, false],
  ['advisor called in a PREVIOUS turn only → block', { entries: [human('q0', { promptId: 'p0' }), agentCall('oracle'), tool('advice'), asst(), human('q1'), asst()] }, true],
  ['"Advisor skipped:" line → pass', { entries: [human('fix typo'), asst(SKIPPED)], lam: SKIPPED }, false],
  ['"Advisor skipped:" as a bold bullet → pass', { entries: [human('q'), asst()], lam: ANSWER + '\n\n- **Advisor skipped:** user asked not to consult' }, false],
  ['skip line only in transcript (no last_assistant_message) → pass', { entries: [human('q'), asst(SKIPPED)], lam: null }, false],
  ['"Advisor skipped:" with nothing after it → block', { entries: [human('q'), asst()], lam: ANSWER + '\n\nAdvisor skipped:' }, true],
  ['"Advisor skipped: n/a" → block', { entries: [human('q'), asst()], lam: ANSWER + '\n\nAdvisor skipped: n/a' }, true],
  ['"Advisor skipped: <reason>" placeholder → block', { entries: [human('q'), asst()], lam: ANSWER + '\n\nAdvisor skipped: <reason>' }, true],
  ['"Advisor skipped: simple lookup; no trade-off to weigh" real reason → pass', { entries: [human('q'), asst()], lam: ANSWER + '\n\nAdvisor skipped: simple lookup; no trade-off to weigh' }, false],
  ['intent Trivial → pass', { entries: [human('fix the typo'), asst()], intent: 'Trivial' }, false],
  ['intent unknown → pass', { entries: [human('hello'), asst()], intent: 'unknown' }, false],
  ['no intent file → pass', { entries: [human('q'), asst()], intent: null }, false],
  ['stale intent from an earlier prompt (e.g. this turn was a slash command) → pass', { entries: [human('/compact')], intentTs: T_OLD }, false],
  ['stop_hook_active (continuation after a block) → pass', { entries: [human('q'), asst()], input: { stop_hook_active: true } }, false],
  ['already blocked this turn (marker = promptId) → pass', { entries: [human('q'), asst()], marker: 'p1' }, false],
  ['marker from an earlier turn → block', { entries: [human('q'), asst()], marker: 'p0' }, true],
  ['task-notification turn → pass', { entries: [human('q', { promptId: 'p0' }), asst(), notif('agent done'), asst()] }, false],
  ['teammate-message turn (no origin) → pass', { entries: [teammate('do x'), asst()] }, false],
  ['origin.kind=human → block', { entries: [human('q', { origin: { kind: 'human' } }), asst()] }, true],
  ['subagent (agent_id present) → pass', { entries: [human('q'), asst()], input: { agent_id: 'a1' } }, false],
  ['SubagentStop event → pass', { entries: [human('q'), asst()], input: { hook_event_name: 'SubagentStop' } }, false],
  ['sidechain advisor call does not count → block', { entries: [human('q'), Object.assign(agentCall('oracle'), { isSidechain: true }), asst()] }, true],
  ['missing transcript → pass (fail open)', { entries: [], input: { transcript_path: '/nonexistent/t.jsonl' } }, false],
]) results.push(run(n, o, e).ok);

// Second Stop of the same turn after a block, if the harness omitted
// stop_hook_active: the marker written by the first block must stop a loop.
{
  const home = fs.mkdtempSync(path.join(os.tmpdir(), 'agate-'));
  const scratch = path.join(home, '.claude', '.adoption');
  fs.mkdirSync(scratch, { recursive: true });
  fs.writeFileSync(path.join(scratch, `intent-${SESSION}.json`), JSON.stringify({ intent: 'Architecture', ts: T1 }));
  const tp = path.join(home, 't.jsonl');
  fs.writeFileSync(tp, [human('q'), asst()].map((e) => JSON.stringify(e)).join('\n') + '\n');
  const once = () => cp.spawnSync('node', [HOOK], { env: Object.assign({}, process.env, { HOME: home }), input: JSON.stringify({ hook_event_name: 'Stop', session_id: SESSION, transcript_path: tp, last_assistant_message: ANSWER }), encoding: 'utf8' }).stdout;
  const first = once(), second = once();
  check('same turn twice without stop_hook_active → blocks only the first time', /"decision":"block"/.test(first) && second.trim() === '');
  fs.rmSync(home, { recursive: true, force: true });
}

// Malformed stdin must fail open with no output.
{
  const out = cp.spawnSync('node', [HOOK], { input: 'not json', encoding: 'utf8' });
  check('malformed stdin → no output, exit 0', out.status === 0 && out.stdout === '');
}

const failed = results.filter((r) => !r).length;
console.log(failed ? `${failed} FAILED` : 'ALL PASSED');
process.exit(failed ? 1 : 0);
