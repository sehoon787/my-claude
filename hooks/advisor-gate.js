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
const cp = require('child_process');
const crypto = require('crypto');
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
// -> {found, human, id, startMs, startIndex, advisorCalled, lastText}
function inspectTurn(lines) {
  const turn = { found: false, human: true, id: '', startMs: NaN, startIndex: -1, advisorCalled: false, lastText: '' };
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
    turn.startIndex = i;
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

// -> {decision: 'block', reason} or null. Unchanged from before the Stuck
// trigger was added: still returns null on stop_hook_active and on a
// machine-started turn (Architecture/Ambiguity/PlanReview only fire for a
// live human prompt).
function evaluateAdvisorGate(input, home, turn) {
  if (input.stop_hook_active) return null;
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

// ---------------------------------------------------------------- Stuck trigger
//
// A second, independent reason to block: the turn looks stuck, and Boss
// should get oracle to reframe it and fact-check its assumptions rather than
// keep pushing the same approach. Three signals, any one of which fires:
//   (a) repeated failure   — last-tool-error-state.json retry_count >= 3
//                             inside this turn, or >=5 failed tool_results
//                             in the transcript when that file is absent.
//   (b) loop without progress (ralph only) — ralph-state.json iteration >= 5
//                             AND the working-tree diff hash is unchanged
//                             across the last 3 Stops.
//   (c) impossibility claim — the final assistant message matches an
//                             EN/KO "this can't be done" pattern, outside
//                             code fences and not a question to the user.
//
// Unlike the Architecture/Ambiguity/PlanReview gate above, this branch does
// NOT return early on stop_hook_active (ralph's loop depends on exactly
// that flag being set) and does not require a human-started turn (ralph
// continuations count). It still never fires for a subagent or when an
// advisor was already called this turn, and it fails open on any error.
const IMPOSSIBLE_CLAIM_RE = /(impossible|not possible|cannot be done|can't be done|blocked by|no way to|불가능|할 수 없|막혔|방법이 없)/i;
const QUESTION_TO_USER_RE = /\byou\b|사용자|직접/i;
const BLOCKED_ON_USER_LINE = /^[\s>*_-]*Blocked on user:\s*(.+)$/im;
const USER_ONLY_ACTION_RE = /login|trust|approve|permission|credential|2FA|권한|승인|로그인|신뢰/i;
const FAILURE_TS_SKEW_MS = 2000;
const RALPH_LOOP_MIN_ITERATION = 5;
const RALPH_LOOP_WINDOW = 3;
const RALPH_BLOCK_COOLDOWN_ITERATIONS = 10;
const STUCK_SESSION_CAP = 2;
const TRANSCRIPT_ERROR_THRESHOLD = 5;

function sha1(text) {
  return crypto.createHash('sha1').update(String(text)).digest('hex');
}

function stuckMarkerPath(home, session) {
  return path.join(store.storePaths(home).scratch, `advisor-stuck-${store.sessionKey(session)}.json`);
}

function omcSessionStatePath(cwd, session, filename) {
  return path.join(cwd, '.omc', 'state', 'sessions', String(session || ''), filename);
}

function countTranscriptToolErrors(lines, fromIndex) {
  let count = 0;
  for (let i = fromIndex; i < lines.length; i++) {
    if (!lines[i]) continue;
    let r;
    try { r = JSON.parse(lines[i]); } catch { continue; }
    if (r.isSidechain || r.type !== 'user') continue;
    const content = r.message && r.message.content;
    if (!Array.isArray(content)) continue;
    for (const item of content) {
      if (item && item.type === 'tool_result' && item.is_error === true) count++;
    }
  }
  return count;
}

// {key} when the turn shows repeated tool failure, else null.
function detectRepeatedFailure(cwd, session, turn, lines) {
  const errState = store.readJson(omcSessionStatePath(cwd, session, 'last-tool-error-state.json'), null);
  if (errState && typeof errState.retry_count === 'number' && errState.retry_count >= 3) {
    const ts = Date.parse(errState.timestamp);
    if (Number.isFinite(ts) && Number.isFinite(turn.startMs) && ts >= turn.startMs - FAILURE_TS_SKEW_MS) {
      return { key: 'err:' + sha1(`${errState.tool_name}|${errState.error}|${errState.timestamp}`) };
    }
  }
  const count = countTranscriptToolErrors(lines, turn.startIndex >= 0 ? turn.startIndex : 0);
  if (count >= TRANSCRIPT_ERROR_THRESHOLD) return { key: 'err:transcript:' + turn.id };
  return null;
}

// {iteration} when ralph is active for this session, else null.
function readRalphState(cwd, session) {
  const j = store.readJson(omcSessionStatePath(cwd, session, 'ralph-state.json'), null);
  if (!j || j.active !== true || typeof j.iteration !== 'number') return null;
  return { iteration: j.iteration };
}

// Working-tree diff hash: `git diff HEAD`, falling back to `git status
// --porcelain` + `git diff` (e.g. no commit yet). Null when git is
// unavailable — the caller must not treat that as "no change".
function computeDiffHash(cwd) {
  const opts = { cwd, encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] };
  try {
    return sha1(cp.execSync('git diff HEAD', opts));
  } catch {
    try {
      const status = cp.execSync('git status --porcelain', opts);
      let diff = '';
      try { diff = cp.execSync('git diff', opts); } catch { /* no diff to show */ }
      return sha1(status + diff);
    } catch {
      return null;
    }
  }
}

// Rolls the diff hash into the marker's rolling history and reports whether
// the loop-without-progress condition fires. `priorHistory` and the
// returned `history` are the last RALPH_LOOP_WINDOW hashes seen.
function updateLoopState(cwd, ralph, priorHistory) {
  const history = Array.isArray(priorHistory) ? priorHistory.slice() : [];
  if (!ralph) return { history, fires: false, hash: null };
  const hash = computeDiffHash(cwd);
  const nextHistory = hash ? history.concat([hash]).slice(-RALPH_LOOP_WINDOW) : history;
  const unchanged = nextHistory.length >= RALPH_LOOP_WINDOW && nextHistory.every((h) => h === nextHistory[0]);
  const fires = hash !== null && ralph.iteration >= RALPH_LOOP_MIN_ITERATION && unchanged;
  return { history: nextHistory, fires, hash };
}

function stripCodeFences(text) {
  return text.replace(/```[\s\S]*?```/g, '');
}

// The claim text (fences stripped) when the final message asserts
// impossibility, else null.
function detectImpossibilityClaim(lam) {
  const stripped = stripCodeFences(lam || '').trim();
  if (!IMPOSSIBLE_CLAIM_RE.test(stripped)) return null;
  if (stripped.endsWith('?') && QUESTION_TO_USER_RE.test(stripped)) return null;
  return stripped;
}

function isEscaped(lam) {
  const text = lam || '';
  if (SKIP_LINE.test(text)) return true;
  const m = text.match(BLOCKED_ON_USER_LINE);
  return !!(m && USER_ONLY_ACTION_RE.test(m[1]));
}

const STUCK_SIGNAL_LABEL = {
  'repeated-failure': 'repeated tool failures',
  'loop-without-progress': 'a ralph loop making no progress across several Stops',
  'impossibility-claim': 'a claim that this cannot be done',
};

function stuckBlockReason(signal) {
  return `[AdvisorGate:Stuck] This turn looks stuck (${STUCK_SIGNAL_LABEL[signal]}). ` +
    'Call `oracle` now with the Agent tool (subagent_type "oracle") in Stuck mode, giving it: ' +
    '(1) the claim or failure in one line; ' +
    '(2) at most 5 assumptions behind it, each marked VERIFIED or REFUTED with the command or source that settles it; ' +
    '(3) at least 1 alternative approach that does not rely on a refuted assumption, plus the next concrete step; ' +
    '(4) a verdict: truly-blocked (naming the user-only action) or unblocked. ' +
    'Then repeat your full final answer with a short "Advisor (oracle)" section covering its verdict. ' +
    'If oracle verdict is truly-blocked on a user-only action, end with one line: `Blocked on user: <action>` ' +
    '(only for login/trust/approve/permission/credential/2FA/권한/승인/로그인/신뢰). ' +
    'Otherwise, if consulting truly does not apply, end with: `Advisor skipped: <reason>`.';
}

// -> {decision: 'block', reason} or null. See the block comment above.
function evaluateStuckInner(input, home, turn, lines) {
  if (!turn.found || turn.advisorCalled) return null;
  const cwd = input.cwd || process.cwd();
  const session = input.session_id;
  const markerFile = stuckMarkerPath(home, session);
  const state = store.readJson(markerFile, { sessionBlocks: 0, episodes: {}, loopHistory: [], lastRalphBlockIteration: null });

  const ralph = readRalphState(cwd, session);
  const loop = updateLoopState(cwd, ralph, state.loopHistory);
  const persisted = Object.assign({}, state, { loopHistory: loop.history });

  const lam = typeof input.last_assistant_message === 'string' ? input.last_assistant_message : turn.lastText;
  const failure = detectRepeatedFailure(cwd, session, turn, lines);
  const claimText = failure ? null : detectImpossibilityClaim(lam);

  let signal = null;
  let episodeKey = null;
  if (failure) {
    signal = 'repeated-failure';
    episodeKey = failure.key;
  } else if (loop.fires) {
    signal = 'loop-without-progress';
    episodeKey = 'loop:' + loop.hash;
  } else if (claimText) {
    signal = 'impossibility-claim';
    episodeKey = 'claim:' + sha1(claimText);
  }

  if (!signal || isEscaped(lam)) {
    store.writeJson(markerFile, persisted);
    return null;
  }
  if ((persisted.sessionBlocks || 0) >= STUCK_SESSION_CAP) {
    store.writeJson(markerFile, persisted);
    return null;
  }
  if (persisted.episodes && persisted.episodes[episodeKey]) {
    store.writeJson(markerFile, persisted);
    return null;
  }
  if (ralph && persisted.lastRalphBlockIteration != null &&
      (ralph.iteration - persisted.lastRalphBlockIteration) < RALPH_BLOCK_COOLDOWN_ITERATIONS) {
    store.writeJson(markerFile, persisted);
    return null;
  }

  const final = Object.assign({}, persisted, {
    sessionBlocks: (persisted.sessionBlocks || 0) + 1,
    episodes: Object.assign({}, persisted.episodes, { [episodeKey]: true }),
  });
  if (ralph) final.lastRalphBlockIteration = ralph.iteration;
  store.writeJson(markerFile, final);
  return { decision: 'block', reason: stuckBlockReason(signal) };
}

function evaluateStuck(input, home, turn, lines) {
  try { return evaluateStuckInner(input, home, turn, lines); } catch { return null; }
}

// -> {decision: 'block', reason} or null
function evaluate(input, home) {
  if (!input || input.agent_id || input.hook_event_name === 'SubagentStop') return null;
  const lines = readTranscript(input.transcript_path);
  const turn = inspectTurn(lines);
  return evaluateAdvisorGate(input, home, turn) || evaluateStuck(input, home, turn, lines);
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
