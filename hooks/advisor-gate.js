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
const SKIP_LINE = /^[\s>*_-]*Advisor skipped:\s*(.*)$/im;
// An escape line (`Advisor skipped:` / `Blocked on user:`) only counts when
// its reason text is real: at least MIN_REASON_CHARS non-space characters,
// and not a placeholder someone typed to satisfy the regex without saying
// anything. An invalid reason is treated as if the line were absent.
const MIN_REASON_CHARS = 8;
const PLACEHOLDER_REASONS = new Set(['<reason>', '<action>', 'n/a', 'na', 'none', 'skip', 'skipped', '-', '...', 'tbd']);

function hasRealReason(text) {
  const trimmed = String(text || '').trim();
  if (trimmed.replace(/\s/g, '').length < MIN_REASON_CHARS) return false;
  return !PLACEHOLDER_REASONS.has(trimmed.toLowerCase());
}

function hasValidSkipLine(text) {
  const m = String(text || '').match(SKIP_LINE);
  return !!(m && hasRealReason(m[1]));
}
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
    'If consulting truly does not apply (trivial request, misclassified intent, the user said not to), instead repeat your full final answer ending with one line: `Advisor skipped: <reason>` — the reason must be concrete, not a placeholder.';
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
  if (hasValidSkipLine(lam)) return null;
  const marker = markerPath(home, input.session_id);
  const prior = store.readJson(marker, {});
  if (prior && prior.turn === turn.id) return null;
  store.writeJson(marker, { turn: turn.id, intent, ts: new Date().toISOString() });
  return { decision: 'block', reason: blockReason(intent, advisor) };
}

// ---------------------------------------------------------------- Stuck trigger
//
// A second, independent reason to block: the turn looks stuck, and Boss
// should get a second opinion (per routing-map.json's "Stuck" intent —
// tracer, oracle, metis, architect) rather than keep pushing the same
// approach. Three signals, any one of which fires:
//   (a) repeated failure    — last-tool-error-state.json retry_count >= 3
//                              inside this turn, or >=5 failed tool_results
//                              in the transcript when that file is absent.
//   (b) no-progress loop    — a per-session rolling window (last 5 Stops,
//                              human or machine, ralph or not) where the
//                              last 3 all did tool work, share the same
//                              working-tree diff hash, and either repeat the
//                              same failing tool+input signature or produce
//                              near-identical final messages. This part
//                              never fires on a ralph iteration count alone.
//                              Separately, with ralph active (iteration >=
//                              5) it also fires on a frozen diff hash alone
//                              across the last 3 Stops, no tool-work/error/
//                              text agreement required (ralph's own loop
//                              already guarantees tool activity); that path
//                              carries its own 10-iteration cooldown on top
//                              of the shared per-episode/per-session caps.
//   (c) impossibility claim — the final assistant message matches an
//                              EN/KO "this can't be done" pattern, outside
//                              code fences and not a question to the user.
//
// Unlike the Architecture/Ambiguity/PlanReview gate above, this branch does
// NOT return early on stop_hook_active (a Stop-forced loop, ralph or not,
// depends on exactly that flag being set) and does not require a
// human-started turn (machine-started continuations count). It still never
// fires when a Stuck Group member was already called this turn, and it
// fails open on any error.
// Assertive predicate forms only: a bare noun ("불가능 주장", "the impossible
// case") merely names a topic and must not count as a claim.
const IMPOSSIBLE_CLAIM_RE = /(\b(is|it's|it is|this is|that's) (impossible|not possible)\b|cannot be done|can't be done|there is no way to|불가능(합니다|해요|해|하다|하네요|함)|할 수 없(습니다|어요|어|다|음)|막혔(습니다|어요|어|다)|방법이 없(습니다|어요|어|다|음))/i;
const QUESTION_TO_USER_RE = /\byou\b|사용자|직접/i;
const BLOCKED_ON_USER_LINE = /^[\s>*_-]*Blocked on user:\s*(.+)$/im;
const USER_ONLY_ACTION_RE = /login|trust|approve|permission|credential|2FA|권한|승인|로그인|신뢰/i;
const FAILURE_TS_SKEW_MS = 2000;
const STUCK_SESSION_CAP = 2;
const TRANSCRIPT_ERROR_THRESHOLD = 5;
const NO_PROGRESS_WINDOW = 3; // consecutive Stops that must agree to fire
const NO_PROGRESS_HISTORY = 5; // Stops kept in the rolling window
const RALPH_LOOP_MIN_ITERATION = 5;
const RALPH_BLOCK_COOLDOWN_ITERATIONS = 10;
const ROUTING_MAP_PATH = process.env.ROUTING_MAP || path.join(__dirname, 'routing-map.json');

function sha1(text) {
  return crypto.createHash('sha1').update(String(text)).digest('hex');
}

function stuckMarkerPath(home, session) {
  return path.join(store.storePaths(home).scratch, `advisor-stuck-${store.sessionKey(session)}.json`);
}

function omcSessionStatePath(cwd, session, filename) {
  return path.join(cwd, '.omc', 'state', 'sessions', String(session || ''), filename);
}

// The routing-map's "Stuck" intent is the single source of truth for which
// agents satisfy this gate (data, not code — ROUTING_MAP env var overrides
// the path, same convention build-registry.js uses).
function stuckAdvisorNames() {
  const map = store.readJson(ROUTING_MAP_PATH, null);
  const intent = map && Array.isArray(map.intents) && map.intents.find((i) => i && i.name === 'Stuck');
  const members = (intent && intent.members) || [];
  return members.map((m) => (typeof m === 'string' ? m : m && m.name)).filter(Boolean);
}

// A bare or plugin-qualified subagent_type matches by its short (last ':')
// segment, same convention as ADVISOR_TYPE above.
function stuckAdvisorRegex(names) {
  if (!names.length) return null;
  const shorts = names.map((n) => String(n).split(':').pop().replace(/[.*+?^${}()|[\]\\]/g, '\\$&'));
  return new RegExp(`(^|:)(${shorts.join('|')})$`);
}

function turnHasStuckAdvisorCall(lines, fromIndex, re) {
  if (!re) return false;
  for (let i = fromIndex; i < lines.length; i++) {
    if (!lines[i]) continue;
    let r;
    try { r = JSON.parse(lines[i]); } catch { continue; }
    if (r.isSidechain || r.type !== 'assistant') continue;
    const content = r.message && r.message.content;
    if (!Array.isArray(content)) continue;
    for (const x of content) {
      const sub = x && x.type === 'tool_use' && (x.name === 'Agent' || x.name === 'Task') && x.input && x.input.subagent_type;
      if (sub && re.test(String(sub))) return true;
    }
  }
  return false;
}

function toolSignature(name, toolInput) {
  return `${name}:${JSON.stringify(toolInput || {}).slice(0, 80)}`;
}

// {toolCalls, errorSig} for the current turn: how many tools ran, and the
// most-frequent failing tool+input signature (via tool_use_id pairing), or
// null when nothing failed / nothing paired.
function computeTurnToolStats(lines, fromIndex) {
  const sigById = new Map();
  const failCounts = new Map();
  let toolCalls = 0;
  for (let i = fromIndex; i < lines.length; i++) {
    if (!lines[i]) continue;
    let r;
    try { r = JSON.parse(lines[i]); } catch { continue; }
    if (r.isSidechain) continue;
    const content = r.message && r.message.content;
    if (!Array.isArray(content)) continue;
    if (r.type === 'assistant') {
      for (const x of content) {
        if (x && x.type === 'tool_use') {
          toolCalls++;
          if (x.id) sigById.set(x.id, toolSignature(x.name, x.input));
        }
      }
    } else if (r.type === 'user') {
      for (const item of content) {
        if (item && item.type === 'tool_result' && item.is_error === true) {
          const sig = item.tool_use_id && sigById.get(item.tool_use_id);
          if (sig) failCounts.set(sig, (failCounts.get(sig) || 0) + 1);
        }
      }
    }
  }
  let errorSig = null, best = 0;
  for (const [sig, count] of failCounts) if (count > best) { best = count; errorSig = sig; }
  return { toolCalls, errorSig };
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

// Ralph's iteration count, when available — optional extra context for the
// block reason only; no signal requires it.
function readRalphIteration(cwd, session) {
  const j = store.readJson(omcSessionStatePath(cwd, session, 'ralph-state.json'), null);
  return (j && j.active === true && typeof j.iteration === 'number') ? j.iteration : null;
}

// Working-tree diff hash: `git diff HEAD` plus the untracked-file list,
// falling back to `git status --porcelain` + `git diff` when there is no
// commit yet. Null when git is unavailable — never treated as "no change".
function computeDiffHash(cwd) {
  // Bounded: the Stop hook's total budget is 5000ms, and a big repo's diff
  // can be slow or exceed the default 1 MB maxBuffer. --no-ext-diff avoids
  // shelling out to a configured external diff tool.
  const opts = {
    cwd, encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'],
    timeout: 2000, maxBuffer: 64 * 1024 * 1024,
  };
  let diff;
  try {
    diff = cp.execSync('git diff --no-ext-diff HEAD', opts);
  } catch {
    try { diff = cp.execSync('git diff --no-ext-diff', opts); } catch { return null; }
  }
  let untracked = '';
  try {
    untracked = cp.execSync('git status --porcelain', opts).split('\n').filter((l) => l.startsWith('??')).join('\n');
  } catch { /* best effort */ }
  return sha1(diff + '\n' + untracked);
}

function normalizeSnippet(text) {
  return String(text || '').trim().replace(/\s+/g, ' ').slice(0, 200);
}

// Appends this Stop's {diffHash, errorSig, toolCalls, textSig} to the
// rolling window (capped at NO_PROGRESS_HISTORY) and reports whether the
// last NO_PROGRESS_WINDOW entries show no progress: all did tool work,
// share one diff hash, and either repeat one failing signature or produce
// near-identical final messages.
function updateNoProgressWindow(cwd, lines, turn, lam, priorWindow) {
  const stats = computeTurnToolStats(lines, turn.startIndex >= 0 ? turn.startIndex : 0);
  const entry = {
    diffHash: computeDiffHash(cwd),
    errorSig: stats.errorSig,
    toolCalls: stats.toolCalls,
    textSig: normalizeSnippet(lam),
  };
  const window = (Array.isArray(priorWindow) ? priorWindow.slice() : []).concat([entry]).slice(-NO_PROGRESS_HISTORY);
  if (window.length < NO_PROGRESS_WINDOW) return { window, fires: false };
  const last3 = window.slice(-NO_PROGRESS_WINDOW);
  const busy = last3.every((e) => e.toolCalls > 0);
  const sameDiff = busy && last3.every((e) => e.diffHash && e.diffHash === last3[0].diffHash);
  if (!sameDiff) return { window, fires: false };
  const errCounts = new Map();
  for (const e of last3) if (e.errorSig) errCounts.set(e.errorSig, (errCounts.get(e.errorSig) || 0) + 1);
  let repeatedErrorSig = null;
  for (const [sig, c] of errCounts) if (c >= 2) { repeatedErrorSig = sig; break; }
  const sameText = last3.every((e) => e.textSig && e.textSig === last3[0].textSig);
  if (!repeatedErrorSig && !sameText) return { window, fires: false };
  return { window, fires: true, diffHash: last3[0].diffHash, errorSig: repeatedErrorSig };
}

// Ralph-specific addition to the no-progress check: with ralph active and
// iteration >= 5, also fire purely off a frozen diff across the last 3
// Stops (no toolCalls/errorSig/textSig requirement — ralph's own loop
// already guarantees tool activity). Reuses the same rolling window.
function detectRalphFrozenDiff(window, ralphIteration) {
  if (ralphIteration === null || ralphIteration < RALPH_LOOP_MIN_ITERATION) return null;
  if (!Array.isArray(window) || window.length < NO_PROGRESS_WINDOW) return null;
  const last3 = window.slice(-NO_PROGRESS_WINDOW);
  const sameDiff = last3.every((e) => e.diffHash && e.diffHash === last3[0].diffHash);
  return sameDiff ? { diffHash: last3[0].diffHash } : null;
}

// Drops fenced blocks, inline code and quoted spans: text that is quoted or
// named rather than asserted.
function stripCodeFences(text) {
  return text
    .replace(/```[\s\S]*?```/g, '')
    .replace(/`[^`\n]*`/g, '')
    .replace(/"[^"\n]*"/g, '')
    .replace(/\u201c[^\u201d\n]*\u201d/g, '');
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
  if (hasValidSkipLine(text)) return true;
  const m = text.match(BLOCKED_ON_USER_LINE);
  return !!(m && hasRealReason(m[1]) && USER_ONLY_ACTION_RE.test(m[1]));
}

const STUCK_SIGNAL_LABEL = {
  'repeated-failure': 'repeated tool failures',
  'no-progress-loop': 'a loop making no progress across several Stops',
  'impossibility-claim': 'a claim that this cannot be done',
};

// Names the member best suited to this signal; any Stuck Group member
// (tracer, oracle, metis, architect) still satisfies the gate.
const STUCK_RECOMMENDATION = {
  'repeated-failure': 'Call `tracer` now with the Agent tool (subagent_type "tracer", model "opus") for a competing-hypotheses trace of why this keeps failing — evidence for and against each hypothesis, and the next probe.',
  'no-progress-loop': 'Call `oracle` now with the Agent tool (subagent_type "oracle") to reframe the approach — or `metis` (subagent_type "metis") if the goal itself looks misread.',
  'impossibility-claim': 'Call `oracle` now with the Agent tool (subagent_type "oracle") for an assumption audit.',
};

function stuckBlockReason(signal, context) {
  return `[AdvisorGate:Stuck] This turn looks stuck (${STUCK_SIGNAL_LABEL[signal]}${context ? `; ${context}` : ''}). ` +
    `${STUCK_RECOMMENDATION[signal]} ` +
    'Any Stuck Group member (tracer, oracle, metis, architect — see routing-map.json\'s "Stuck" intent) satisfies this gate. Whichever you call, give it: ' +
    '(1) the claim or failure in one line; ' +
    '(2) at most 5 assumptions behind it, each marked VERIFIED or REFUTED with the command or source that settles it; ' +
    '(3) at least 1 alternative approach that does not rely on a refuted assumption, plus the next concrete step; ' +
    '(4) a verdict: truly-blocked (naming the user-only action) or unblocked. ' +
    'Then repeat your full final answer with a short "Advisor (<name>)" section covering its verdict. ' +
    'If the verdict is truly-blocked on a user-only action, end with one line: `Blocked on user: <action>` ' +
    '(only for login/trust/approve/permission/credential/2FA/권한/승인/로그인/신뢰), with a concrete action, not a placeholder. ' +
    'Otherwise, if consulting truly does not apply, end with: `Advisor skipped: <reason>` — the reason must be concrete, not a placeholder.';
}

// -> {decision: 'block', reason} or null. See the block comment above.
function evaluateStuckInner(input, home, turn, lines) {
  if (!turn.found) return null;
  const cwd = input.cwd || process.cwd();
  const session = input.session_id;
  if (turnHasStuckAdvisorCall(lines, turn.startIndex >= 0 ? turn.startIndex : 0, stuckAdvisorRegex(stuckAdvisorNames()))) return null;

  const markerFile = stuckMarkerPath(home, session);
  const state = store.readJson(markerFile, { sessionBlocks: 0, episodes: {}, window: [], lastRalphBlockIteration: null });

  const lam = typeof input.last_assistant_message === 'string' ? input.last_assistant_message : turn.lastText;
  const ralphIteration = readRalphIteration(cwd, session);
  const noProgress = updateNoProgressWindow(cwd, lines, turn, lam, state.window);
  const ralphFrozen = noProgress.fires ? null : detectRalphFrozenDiff(noProgress.window, ralphIteration);
  const persisted = Object.assign({}, state, { window: noProgress.window });

  const failure = detectRepeatedFailure(cwd, session, turn, lines);
  const claimText = failure ? null : detectImpossibilityClaim(lam);

  let signal = null;
  let episodeKey = null;
  let viaRalphCooldown = false;
  if (failure) {
    signal = 'repeated-failure';
    episodeKey = failure.key;
  } else if (noProgress.fires) {
    signal = 'no-progress-loop';
    episodeKey = `loop:${noProgress.diffHash}|${noProgress.errorSig || ''}`;
  } else if (ralphFrozen) {
    signal = 'no-progress-loop';
    episodeKey = `loop:${ralphFrozen.diffHash}`;
    viaRalphCooldown = true;
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
  if (viaRalphCooldown && persisted.lastRalphBlockIteration != null &&
      (ralphIteration - persisted.lastRalphBlockIteration) < RALPH_BLOCK_COOLDOWN_ITERATIONS) {
    store.writeJson(markerFile, persisted);
    return null;
  }

  const final = Object.assign({}, persisted, {
    sessionBlocks: (persisted.sessionBlocks || 0) + 1,
    episodes: Object.assign({}, persisted.episodes, { [episodeKey]: true }),
  });
  if (viaRalphCooldown) final.lastRalphBlockIteration = ralphIteration;
  store.writeJson(markerFile, final);
  const context = ralphIteration !== null ? `ralph iteration ${ralphIteration}` : '';
  return { decision: 'block', reason: stuckBlockReason(signal, context) };
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
