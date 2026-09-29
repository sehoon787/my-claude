#!/usr/bin/env node
// SessionEnd hook: look back over the session and queue learning suggestions
// for the user to approve (hooks/learning-cli.js). Deterministic, no LLM
// call, prints nothing, never throws.
//
//   rule   A user message, after the assistant has replied at least once,
//          that states a standing preference or correction ("don't ...",
//          "always ...", "from now on ...", "하지 마", "앞으로 ... 해줘").
//          See isCorrection() for the exact rule.
//   skill  An ordered chain of 2-4 agents/skills the user accepted back to
//          back (adoption ledger) in >= 3 distinct sessions within 30 days.
//
// At most two rule candidates per session, standing phrasing first.
// Suggestions are deduped by key; keys already approved or dismissed are
// never re-queued. At most 5 are pending: new ones beyond that are refused
// and the refusal is audited. It also records when an approved learned item
// was used (a Skill call of learned-*, or the same correction repeated), which
// is what the curator ages items by.
//
//   node learning-review.js   (stdin: SessionEnd payload with transcript_path)
'use strict';
const fs = require('fs');
const store = require('./learning-store.js');
const adoption = require('./adoption-store.js');
const { isRoutable } = require('./route-hint.js');

const RULE_TEXT_MAX = 200;
// Longer messages are task briefs or pasted text, not a one-line correction.
const MESSAGE_MAX = 1500;
const TRANSCRIPT_TAIL_BYTES = 32 * 1024 * 1024;
const WORKFLOW_WINDOW_DAYS = 30;
const WORKFLOW_MIN_SESSIONS = 3;
const CHAIN_MIN = 2;
const CHAIN_MAX = 4;
// A session's corrections are mostly about that session's task; queue only
// the two most rule-like, so one busy session cannot fill the pending queue.
const RULES_PER_SESSION = 2;
const STANDING = /(^|[^a-z])(always|never|from now on|going forward)([^a-z]|$)|항상|앞으로|다음부터|매번/i;

// ---------------------------------------------------------------- corrections

// English: phrases that state a rule anywhere in a sentence, and words that
// only do so when they open the sentence ("Always run tests" vs "it always
// fails", "Don't add tables" vs "I don't know").
const EN_ANYWHERE = /(^|[^a-z])(stop (doing|using|adding|writing|making|putting)|from now on|going forward|instead of)([^a-z]|$)/;
const EN_LEAD_IN = /^(?:(?:please|and|but|also|so|ok|okay|no)[,\s]+)*/;
const EN_LEADING = /^(?:you (?:should|must) )?(?:don't|do not|never|always)(?![a-z])/;
const EN_EXCLUDE = /^(?:never ?mind|don't worry|do not worry|don't know|do not know)/;
// Korean: a negative imperative ("~지 마", "~지 말고") or "다음부터" is a rule
// on its own; 항상 / 앞으로 / 대신 / 말고 only with an imperative ending
// ("앞으로 영어로 써줘" yes, "항상 그랬잖아" no).
const KO_STRONG = /지\s?마(?:$|[\s,.!~]|세요|십시오|라|요)|지\s?말고|지\s?말\s?것|다음부터/;
const KO_WEAK = /항상|앞으로|대신|말고/;
const KO_IMPERATIVE = /(해\s?줘|주세요|줘|하세요|해라|하자|해요|해|써|쓰세요|할\s?것|하도록|마|마세요|말\s?것)[.!~\s]*$/;
const QUESTION = /[?？]\s*$/;

function isCorrection(sentence) {
  const s = String(sentence || '').trim();
  if (!s || QUESTION.test(s)) return false;
  const lower = s.toLowerCase().replace(/[‘’]/g, "'");
  const opening = lower.replace(EN_LEAD_IN, '');
  if (EN_EXCLUDE.test(opening)) return false;
  if (EN_ANYWHERE.test(lower) || EN_LEADING.test(opening)) return true;
  if (KO_STRONG.test(s)) return true;
  return KO_WEAK.test(s) && KO_IMPERATIVE.test(s);
}

// Code, quoted lines, and tagged blocks (system reminders, pasted content) are
// never the user's own instruction.
function stripNonProse(text) {
  return String(text)
    .replace(/```[\s\S]*?(```|$)/g, ' ')
    .replace(/`[^`\n]*`/g, ' ')
    .replace(/<([a-z][\w-]*)[^>]*>[\s\S]*?<\/\1>/gi, ' ')
    .split('\n').filter((l) => !/^\s*>/.test(l)).join('\n');
}

function splitSentences(text) {
  return text.split(/\n+|(?<=[.!?。？])\s+/).map((s) => s.trim()).filter(Boolean);
}

// The correcting sentences of one user message, joined, or null.
function correctionText(message) {
  const text = String(message || '');
  if (text.length > MESSAGE_MAX || !isRoutable(text)) return null;
  const t = text.trim();
  if (t.startsWith('<') || t.startsWith('[Request interrupted')) return null;
  const hits = splitSentences(stripNonProse(t)).filter(isCorrection);
  if (!hits.length) return null;
  return hits.join(' ').replace(/\s+/g, ' ').slice(0, RULE_TEXT_MAX);
}

// ---------------------------------------------------------------- transcript

function readTail(file) {
  const fd = fs.openSync(file, 'r');
  try {
    const size = fs.fstatSync(fd).size;
    const len = Math.min(size, TRANSCRIPT_TAIL_BYTES);
    const buf = Buffer.alloc(len);
    fs.readSync(fd, buf, 0, len, size - len);
    return buf.toString('utf8');
  } finally {
    fs.closeSync(fd);
  }
}

function userText(content) {
  if (typeof content === 'string') return content;
  if (!Array.isArray(content)) return '';
  if (content.some((c) => c && c.type === 'tool_result')) return '';
  return content.filter((c) => c && c.type === 'text').map((c) => c.text || '').join('\n');
}

function toolsOf(entry) {
  const content = (entry.message && entry.message.content) || [];
  const tools = [];
  for (const c of Array.isArray(content) ? content : []) {
    if (!c || c.type !== 'tool_use') continue;
    const input = c.input || {};
    if (c.name === 'Agent' || c.name === 'Task') tools.push({ kind: 'agent', id: String(input.subagent_type || 'general-purpose') });
    else if (c.name === 'Skill' && input.skill) tools.push({ kind: 'skill', id: String(input.skill).replace(/^\//, '') });
  }
  return tools;
}

function parse(line) {
  try { return JSON.parse(line); } catch { return null; }
}

// Main-thread timeline: {type: 'user', text} | {type: 'assistant', tools}.
// Only lines that can matter are JSON-parsed, which keeps a long session fast.
function readTimeline(file) {
  let text = '';
  try { text = readTail(file); } catch { return []; }
  const timeline = [];
  for (const line of text.split('\n')) {
    if (line.includes('"type":"assistant"')) {
      const useful = line.includes('"tool_use"') && /"name":"(Agent|Task|Skill)"/.test(line);
      const e = useful ? parse(line) : null;
      if (e && e.isSidechain) continue;
      timeline.push({ type: 'assistant', tools: e ? toolsOf(e) : [] });
    } else if (line.includes('"type":"user"') && !line.includes('"tool_use_id"')) {
      const e = parse(line);
      if (!e || e.type !== 'user' || e.isMeta || e.isSidechain || e.isCompactSummary) continue;
      const t = userText(e.message && e.message.content);
      if (t) timeline.push({ type: 'user', text: t });
    }
  }
  return timeline;
}

// -> {rules: [{text, context}], skillUses: [slug]}
function scanTimeline(timeline) {
  const rules = [];
  const skillUses = new Set();
  let replied = false;
  let lastTool = null;
  for (const ev of timeline) {
    if (ev.type === 'assistant') {
      replied = true;
      for (const t of ev.tools) {
        lastTool = t;
        if (t.kind === 'skill' && t.id.startsWith(store.LEARNED_PREFIX)) skillUses.add(t.id);
      }
      continue;
    }
    if (!replied) continue; // the opening prompt is a task, not a correction
    const text = correctionText(ev.text);
    if (text) rules.push({ text, context: lastTool });
  }
  return { rules, skillUses: [...skillUses] };
}

// Standing phrasing ("always", "앞으로") first, then the latest; one per key.
function pickRules(rules) {
  const seen = new Set();
  return rules
    .map((r, i) => ({ r, i, standing: STANDING.test(r.text) ? 1 : 0 }))
    .sort((a, b) => b.standing - a.standing || b.i - a.i)
    .filter(({ r }) => {
      const key = store.normalizeText(r.text);
      if (seen.has(key)) return false;
      seen.add(key);
      return true;
    })
    .slice(0, RULES_PER_SESSION)
    .map(({ r }) => r);
}

// ---------------------------------------------------------------- workflows

// Per session, runs of back-to-back accepted items (a reject breaks a run),
// then every 2-4 long contiguous chain counted once per session.
function workflowCandidates(events, now) {
  const since = now - WORKFLOW_WINDOW_DAYS * store.DAY_MS;
  const bySession = new Map();
  events.forEach((e, i) => {
    const t = Date.parse(e.ts);
    if (!Number.isFinite(t) || t < since || t > now) return;
    if ((e.harness || store.HARNESS) !== store.HARNESS || !e.session || e.session === 'unknown') return;
    if (!bySession.has(e.session)) bySession.set(e.session, []);
    bySession.get(e.session).push({ e, t, i });
  });
  const chains = new Map();
  for (const [session, rows] of bySession) {
    rows.sort((a, b) => a.t - b.t || a.i - b.i);
    const runs = [[]];
    for (const { e } of rows) {
      const run = runs[runs.length - 1];
      if (e.verdict !== 'accept' || e.id.startsWith(store.LEARNED_PREFIX)) { runs.push([]); continue; }
      if (!run.length || run[run.length - 1].id !== e.id) run.push(e);
    }
    const seen = new Set();
    for (const run of runs) {
      for (let n = CHAIN_MIN; n <= CHAIN_MAX; n++) {
        for (let s = 0; s + n <= run.length; s++) {
          const steps = run.slice(s, s + n);
          const key = steps.map((x) => x.id).join('>');
          if (seen.has(key)) continue;
          seen.add(key);
          const c = chains.get(key) || { steps: steps.map((x) => ({ id: x.id, kind: x.kind || 'agent' })), sessions: [], intents: {} };
          c.sessions.push(session);
          for (const x of steps) if (x.intent && x.intent !== 'unknown') c.intents[x.intent] = (c.intents[x.intent] || 0) + 1;
          chains.set(key, c);
        }
      }
    }
  }
  const qualifying = [...chains.entries()].filter(([, c]) => c.sessions.length >= WORKFLOW_MIN_SESSIONS);
  // A chain inside a longer qualifying chain is the same habit: keep the longer.
  const within = (inner, outer) => inner !== outer && `>${outer}>`.includes(`>${inner}>`);
  return qualifying
    .filter(([key]) => !qualifying.some(([other]) => within(key, other)))
    .map(([, c]) => ({
      kind: 'skill',
      name: `${store.LEARNED_PREFIX}${c.steps.map((st) => store.slugify(st.id, 24)).join('-then-')}`.slice(0, 64),
      steps: c.steps,
      intents: Object.keys(c.intents).sort((a, b) => c.intents[b] - c.intents[a]),
      evidence: c.sessions,
    }));
}

// ---------------------------------------------------------------- queue

function markUsed(state, slug, now) {
  const item = state.items[slug];
  if (!item || item.status === 'archived') return false;
  state.items[slug] = Object.assign({}, item, { last_used_at: store.iso(now) });
  return true;
}

// Queue candidates: dedupe by key, refuse beyond MAX_PENDING (audited once
// per key), and count a re-detected approved rule as a use of that rule.
function queueSuggestions(home, candidates, now, session) {
  const rows = store.readSuggestions(home);
  const state = store.readState(home);
  let rowsChanged = false;
  let stateChanged = false;
  const refusedKeys = new Set(store.readAudit(home).filter((r) => r.action === 'cap_refused').map((r) => r.key));
  const added = [];
  for (const cand of candidates) {
    const key = store.suggestionKey(cand);
    const existing = rows.find((r) => r.key === key && store.isOurs(r));
    if (existing) {
      if (existing.status === 'approved' && existing.slug) stateChanged = markUsed(state, existing.slug, now) || stateChanged;
      continue;
    }
    if (rows.filter((r) => r.status === 'pending' && store.isOurs(r)).length >= store.MAX_PENDING) {
      if (!refusedKeys.has(key)) {
        store.audit(home, now, 'cap_refused', { key, kind: cand.kind, reason: `${store.MAX_PENDING} suggestions already pending` });
        refusedKeys.add(key);
      }
      continue;
    }
    const row = Object.assign({ id: store.nextSuggestionId(rows), kind: cand.kind, status: 'pending', key, created_at: store.iso(now), harness: store.HARNESS, session: session || 'unknown' }, cand);
    rows.push(row);
    added.push(row);
    rowsChanged = true;
    store.audit(home, now, 'suggest', { suggestion: row.id, key, before: null, after: { status: 'pending' } });
  }
  if (rowsChanged) store.writeSuggestions(home, rows);
  if (stateChanged) store.writeState(home, state);
  return added;
}

function review(opts) {
  const o = opts || {};
  const now = o.now || Date.now();
  const scan = o.transcriptPath ? scanTimeline(readTimeline(o.transcriptPath)) : { rules: [], skillUses: [] };
  const state = store.readState(o.home);
  const used = scan.skillUses.filter((slug) => markUsed(state, slug, now));
  if (used.length) store.writeState(o.home, state);
  const rules = pickRules(scan.rules).map((r) => ({ kind: 'rule', text: r.text, context: r.context, scope: 'global', evidence: [o.session || 'unknown'] }));
  const skills = workflowCandidates(adoption.readLedger(o.home), now);
  return queueSuggestions(o.home, [...rules, ...skills], now, o.session);
}

function main() {
  let input = {};
  try { input = JSON.parse(fs.readFileSync(0, 'utf8') || '{}'); } catch { return; }
  review({ transcriptPath: input.transcript_path, session: input.session_id ? String(input.session_id) : 'unknown' });
}

module.exports = { correctionText, isCorrection, pickRules, queueSuggestions, readTimeline, review, scanTimeline, workflowCandidates };

if (require.main === module) {
  try { main(); } catch { /* fail open: session end must never error */ }
}
