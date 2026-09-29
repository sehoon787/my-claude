#!/usr/bin/env node
// Stop hook: the deterministic half of boss.md's Advisor Gate.
//
// boss.md says: when the prompt's intent is Architecture, Ambiguity, or
// PlanReview, call that advisor (oracle / metis / momus) before answering, or
// write one `Advisor skipped: <reason>` line. A prompt rule alone lost to
// "answer it yourself" economy rules in live runs, so this hook checks the
// finished turn and blocks ONCE when:
//   - route-hint.js recorded one of those intents for THIS prompt
//     (~/.claude/.adoption/intent-<session>.json, written after the prompt
//     arrived — an older file belongs to an earlier prompt), and
//   - no Agent/Task tool_use in this turn has subagent_type oracle, metis, or
//     momus (plugin-namespaced names count), and
//   - the final assistant message has no `Advisor skipped:` line.
//
// Never blocks: a subagent (agent_id / SubagentStop), a turn started by a
// task-notification or teammate message, a continuation after any Stop block
// (stop_hook_active), or a turn it already blocked once (per-turn marker in
// ~/.claude/.adoption/advisor-gate-<session>.json). Fails open on any error.
'use strict';
const fs = require('fs');
const path = require('path');
const store = require('./adoption-store.js');

const ADVISOR_FOR_INTENT = { Architecture: 'oracle', Ambiguity: 'metis', PlanReview: 'momus' };
const ADVISOR_TYPE = /(^|:)(oracle|metis|momus)$/;
const SKIP_LINE = /^[\s>*_-]*Advisor skipped:/im;
const MACHINE_MESSAGE = /<task-notification>|\[SYSTEM NOTIFICATION|<cross-session-message|<teammate-message|^Another Claude session sent a message:/;
// The intent file is written a few hundred ms after the prompt's transcript
// timestamp; allow for clock rounding without accepting a previous prompt's.
const INTENT_SKEW_MS = 2000;

function readTranscript(transcriptPath) {
  try { return fs.readFileSync(transcriptPath, 'utf8').split('\n'); } catch { return []; }
}

function textOf(content) {
  if (typeof content === 'string') return content;
  if (!Array.isArray(content)) return '';
  return content.filter((x) => x && x.type === 'text').map((x) => x.text || '').join('\n');
}

// Walk back to the entry that started this turn. Tool results and isMeta
// entries (e.g. "Stop hook feedback") belong to the turn and are passed over.
// -> {found, human, id, startMs, advisorCalled, lastText}
function inspectTurn(lines) {
  const turn = { found: false, human: true, id: '', startMs: NaN, advisorCalled: false, lastText: '' };
  for (let i = lines.length - 1; i >= 0; i--) {
    if (!lines[i]) continue;
    let r;
    try { r = JSON.parse(lines[i]); } catch { continue; }
    if (r.isSidechain) continue;
    const content = r.message && r.message.content;
    if (r.type === 'assistant') {
      for (const x of Array.isArray(content) ? content : []) {
        const sub = x && x.type === 'tool_use' && (x.name === 'Agent' || x.name === 'Task') && x.input && x.input.subagent_type;
        if (sub && ADVISOR_TYPE.test(String(sub))) turn.advisorCalled = true;
      }
      if (!turn.lastText) turn.lastText = textOf(content);
      continue;
    }
    if (r.type !== 'user' || r.isMeta) continue;
    if (Array.isArray(content) && content.some((x) => x && x.type === 'tool_result')) continue;
    turn.found = true;
    const kind = r.origin && r.origin.kind;
    turn.human = kind ? kind === 'human' : !MACHINE_MESSAGE.test(textOf(content) || JSON.stringify(content || ''));
    turn.id = String(r.promptId || r.uuid || i);
    turn.startMs = Date.parse(r.timestamp);
    break;
  }
  return turn;
}

// The intent route-hint.js recorded for this turn's prompt, or null.
function currentIntent(home, session, turnStartMs) {
  const j = store.readJson(store.intentPath(home, session), null);
  if (!j || typeof j.intent !== 'string') return null;
  const ts = Date.parse(j.ts);
  if (Number.isFinite(ts) && Number.isFinite(turnStartMs) && ts < turnStartMs - INTENT_SKEW_MS) return null;
  return j.intent;
}

function markerPath(home, session) {
  return path.join(store.storePaths(home).scratch, `advisor-gate-${store.sessionKey(session)}.json`);
}

function blockReason(intent, advisor) {
  return `[AdvisorGate] This prompt's intent is ${intent}, but no advisor was consulted this turn. ` +
    `Per boss.md's Advisor Gate, call \`${advisor}\` now with the Agent tool (subagent_type "${advisor}"), passing it the question plus the files and findings you already have. ` +
    `Then repeat your full final answer with a short "Advisor (${advisor})" section: its view and where you agree or disagree. ` +
    'If consulting truly does not apply (trivial request, misclassified intent, the user said not to), instead repeat your full final answer ending with one line: `Advisor skipped: <reason>`.';
}

// -> {decision: 'block', reason} or null
function evaluate(input, home) {
  if (!input || input.agent_id || input.hook_event_name === 'SubagentStop') return null;
  if (input.stop_hook_active) return null;
  const turn = inspectTurn(readTranscript(input.transcript_path));
  if (!turn.found || !turn.human || turn.advisorCalled) return null;
  const intent = currentIntent(home, input.session_id, turn.startMs);
  const advisor = ADVISOR_FOR_INTENT[intent];
  if (!advisor) return null;
  const lam = typeof input.last_assistant_message === 'string' ? input.last_assistant_message : turn.lastText;
  if (SKIP_LINE.test(lam || '')) return null;
  const marker = markerPath(home, input.session_id);
  const prior = store.readJson(marker, {});
  if (prior && prior.turn === turn.id) return null;
  store.writeJson(marker, { turn: turn.id, intent, ts: new Date().toISOString() });
  return { decision: 'block', reason: blockReason(intent, advisor) };
}

function main() {
  let input = {};
  try { input = JSON.parse(fs.readFileSync(0, 'utf8') || '{}'); } catch { return; }
  const out = evaluate(input, null);
  if (out) process.stdout.write(JSON.stringify(out) + '\n');
}

module.exports = { evaluate, inspectTurn };

if (require.main === module) {
  try { main(); } catch { /* fail open: never trap the session */ }
}
