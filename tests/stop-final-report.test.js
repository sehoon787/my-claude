#!/usr/bin/env node
// Unit tests for hooks/stop-final-report.js — runs the hook against a fake
// .briefing vault and fake transcripts. `node tests/stop-final-report.test.js`
'use strict';
const fs = require('fs'), os = require('os'), path = require('path'), cp = require('child_process');
const HOOK = path.resolve(__dirname, '..', 'hooks', 'stop-final-report.js');
const NO_REPORT = '작업을 마쳤습니다. 결과가 오면 이어서 진행하겠습니다.';
const REPORT = '완료.\n\n## 변경 대조 (Changes)\n\n| 대상 | Before | After | 근거 |\n|---|---|---|---|\n| a | b | c | d |\n';
const human = (t) => ({ type: 'user', origin: { kind: 'human' }, message: { role: 'user', content: t } });
const notif = (t) => ({ type: 'user', origin: { kind: 'task-notification' }, message: { role: 'user', content: '<task-notification>' + t + '</task-notification>' } });
const notifNoOrigin = (t) => ({ type: 'user', message: { role: 'user', content: '<task-notification>' + t + '</task-notification>' } });
const tool = (t) => ({ type: 'user', message: { role: 'user', content: [{ type: 'tool_result', content: t }] } });
const asst = () => ({ type: 'assistant', message: { role: 'assistant', content: [{ type: 'text', text: 'ok' }] } });

function run(name, { entries, lam, workCounter = 5, acked = 0, blockedPromptId, promptId = 'p1' }, expect) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'sfr-'));
  fs.mkdirSync(path.join(dir, '.briefing'));
  fs.writeFileSync(path.join(dir, '.briefing', 'INDEX.md'), '---\nlanguage: ko\n---\n# x\n');
  fs.writeFileSync(path.join(dir, '.briefing', 'state.json'), JSON.stringify({ workCounter, finalReport: { ackWorkCounter: acked, blockedPromptId } }));
  const tp = path.join(dir, 't.jsonl');
  fs.writeFileSync(tp, entries.map((e) => JSON.stringify(e)).join('\n') + '\n');
  const out = cp.spawnSync('node', [HOOK], { cwd: dir, input: JSON.stringify({ hook_event_name: 'Stop', prompt_id: promptId, transcript_path: tp, last_assistant_message: lam }), encoding: 'utf8' });
  const blocked = /"decision":"block"/.test(out.stdout);
  const state = JSON.parse(fs.readFileSync(path.join(dir, '.briefing', 'state.json'), 'utf8'));
  const ack = (state.finalReport || {}).ackWorkCounter || 0;
  const ok = blocked === expect.blocked && (expect.ack === undefined || ack === expect.ack);
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}  (blocked=${blocked}, ack=${ack})`);
  fs.rmSync(dir, { recursive: true, force: true });
  return ok;
}

const results = [
  run('human turn, work, no report → block', { entries: [human('do x'), tool('edited'), asst()], lam: NO_REPORT }, { blocked: true, ack: 0 }),
  run('human turn, work, report → pass + ack', { entries: [human('do x'), tool('edited'), asst()], lam: REPORT }, { blocked: false, ack: 5 }),
  run('notification turn, work, no report → pass (mid-request)', { entries: [human('do x'), asst(), notif('done w1'), tool('edited'), asst()], lam: NO_REPORT }, { blocked: false, ack: 0 }),
  run('notification turn (no origin field), no report → pass', { entries: [human('do x'), notifNoOrigin('done w1'), asst()], lam: NO_REPORT }, { blocked: false, ack: 0 }),
  run('notification turn, report present → pass + ack', { entries: [human('do x'), notif('done w1'), asst()], lam: REPORT }, { blocked: false, ack: 5 }),
  run('human turn launched background work, no report → pass', { entries: [human('do x'), tool('edited'), tool('Workflow launched in background. Task ID: w1'), asst()], lam: NO_REPORT }, { blocked: false, ack: 0 }),
  run('human turn spawned agent, no report → pass', { entries: [human('do x'), tool('Spawned successfully. agent_id: a1'), asst()], lam: NO_REPORT }, { blocked: false, ack: 0 }),
  run('background launched in a PREVIOUS turn only → block', { entries: [human('do x'), tool('Workflow launched in background'), asst(), human('and now y'), tool('edited'), asst()], lam: NO_REPORT }, { blocked: true, ack: 0 }),
  run('no new work → pass', { entries: [human('hi'), asst()], lam: NO_REPORT, workCounter: 5, acked: 5 }, { blocked: false, ack: 5 }),
  run('second Stop after a block (loop guard) → pass + ack', { entries: [human('do x'), tool('edited'), asst()], lam: NO_REPORT, blockedPromptId: 'p1' }, { blocked: false, ack: 5 }),
  run('missing transcript → falls back to enforcing', { entries: [], lam: NO_REPORT }, { blocked: true }),
];
const failed = results.filter((r) => !r).length;
console.log(failed ? `${failed} FAILED` : 'ALL PASSED');
process.exit(failed ? 1 : 0);
