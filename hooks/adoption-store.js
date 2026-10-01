// Adoption store: did the user adopt what an agent or skill produced?
//
// Shared across harnesses (my-claude writes harness "claude"; my-codex can
// write "codex" into the same files):
//   ~/.config/agent-harness/adoption-ledger.jsonl   append-only verdict events
//   ~/.config/agent-harness/adoption-pins.json      [{id, intent, ts}]
//   ~/.config/agent-harness/adoption-archive.jsonl  events moved out by reset/undo
//   ~/.config/agent-harness/adoption-audit.jsonl    one line per CLI mutation
// Per-session scratch for this harness lives in ~/.claude/.adoption/
// (pending-<session>.jsonl offers, intent-<session>.json current intent).
//
// Ledger event: {ts, harness, session, kind: "agent"|"skill", id, intent,
// verdict: "accept"|"reject", signal: "reply"|"choice"|"revert", evidence}.
'use strict';
const fs = require('fs');
const path = require('path');

const HARNESS = 'claude';
const WINDOW_DAYS = 180;
const HALF_LIFE_DAYS = 90;
const MIN_EFFECTIVE_N = 5;
const SCRATCH_TTL_DAYS = 7;
const DAY_MS = 24 * 60 * 60 * 1000;
// Intents whose routing order is fixed by the map: adoption and pins never
// reorder them.
const SAFETY_INTENTS = new Set(['Security', 'Ship']);

function storePaths(home) {
  const h = home || process.env.HOME || process.env.USERPROFILE || require('os').homedir();
  const shared = path.join(h, '.config', 'agent-harness');
  return {
    shared,
    scratch: path.join(h, '.claude', '.adoption'),
    ledger: path.join(shared, 'adoption-ledger.jsonl'),
    pins: path.join(shared, 'adoption-pins.json'),
    archive: path.join(shared, 'adoption-archive.jsonl'),
    audit: path.join(shared, 'adoption-audit.jsonl'),
  };
}

function sessionKey(session) {
  return String(session || 'unknown').replace(/[^A-Za-z0-9_-]/g, '_').slice(0, 128);
}

function pendingPath(home, session) {
  return path.join(storePaths(home).scratch, `pending-${sessionKey(session)}.jsonl`);
}

function intentPath(home, session) {
  return path.join(storePaths(home).scratch, `intent-${sessionKey(session)}.json`);
}

// ---------------------------------------------------------------- file io

function readJson(file, fallback) {
  try { return JSON.parse(fs.readFileSync(file, 'utf8')); } catch { return fallback; }
}

function writeAtomic(file, text) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  const tmp = `${file}.${process.pid}.tmp`;
  fs.writeFileSync(tmp, text);
  fs.renameSync(tmp, file);
}

function writeJson(file, value) {
  writeAtomic(file, JSON.stringify(value, null, 2) + '\n');
}

function readJsonl(file) {
  let text = '';
  try { text = fs.readFileSync(file, 'utf8'); } catch { return []; }
  const rows = [];
  for (const line of text.split('\n')) {
    if (!line.trim()) continue;
    try { rows.push(JSON.parse(line)); } catch { /* skip malformed line */ }
  }
  return rows;
}

function writeJsonl(file, rows) {
  writeAtomic(file, rows.map((r) => JSON.stringify(r) + '\n').join(''));
}

function appendJsonl(file, rows) {
  if (!rows.length) return;
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.appendFileSync(file, rows.map((r) => JSON.stringify(r) + '\n').join(''));
}

// ---------------------------------------------------------------- ledger + pins

// Other harnesses write here too: keep only well-formed rows.
function isIdIntent(r) {
  return !!r && typeof r.id === 'string' && r.id !== '' && typeof r.intent === 'string' && r.intent !== '';
}

function readLedger(home) {
  return readJsonl(storePaths(home).ledger).filter((e) => isIdIntent(e) && (e.verdict === 'accept' || e.verdict === 'reject'));
}

function readPins(home) {
  const pins = readJson(storePaths(home).pins, []);
  return Array.isArray(pins) ? pins.filter(isIdIntent) : [];
}

function audit(home, action, fields) {
  appendJsonl(storePaths(home).audit, [Object.assign({ ts: new Date().toISOString(), harness: HARNESS, action }, fields)]);
}

// Current intent for a session, written by route-hint.js on every routable
// prompt. A new session's first write also sweeps week-old scratch files.
function recordIntent(home, session, intent) {
  const file = intentPath(home, session);
  if (!fs.existsSync(file)) pruneScratch(home, Date.now());
  writeJson(file, { intent: intent || 'unknown', ts: new Date().toISOString() });
}

function readIntent(home, session) {
  const j = readJson(intentPath(home, session), null);
  return j && typeof j.intent === 'string' && j.intent ? j.intent : 'unknown';
}

function pruneScratch(home, now) {
  const dir = storePaths(home).scratch;
  let names = [];
  try { names = fs.readdirSync(dir); } catch { return; }
  for (const name of names) {
    const file = path.join(dir, name);
    try {
      if (now - fs.statSync(file).mtimeMs > SCRATCH_TTL_DAYS * DAY_MS) fs.unlinkSync(file);
    } catch { /* raced with another session */ }
  }
}

// ---------------------------------------------------------------- weighting

// 90-day half-life over whole days (so 5 events from today count as n = 5);
// events older than 180 days (or undated) count for nothing.
function eventWeight(event, now) {
  const t = Date.parse(event.ts);
  if (!Number.isFinite(t)) return 0;
  const ageDays = Math.max(0, Math.floor((now - t) / DAY_MS));
  if (ageDays > WINDOW_DAYS) return 0;
  return Math.pow(0.5, ageDays / HALF_LIFE_DAYS);
}

function statKey(id, intent) {
  return `${id}\u0000${intent}`;
}

// Per (id, intent): decayed accept/reject weights (n = their sum) plus the
// raw in-window counts used for the "(adopted x/y)" annotation.
function summarize(events, now) {
  const stats = new Map();
  for (const e of events) {
    const w = eventWeight(e, now);
    if (w <= 0) continue;
    const key = statKey(e.id, e.intent);
    const s = stats.get(key) || { id: e.id, kind: e.kind || '', intent: e.intent, accept: 0, reject: 0, n: 0, accepted: 0, total: 0 };
    const next = Object.assign({}, s, { n: s.n + w, total: s.total + 1 });
    if (e.verdict === 'accept') Object.assign(next, { accept: s.accept + w, accepted: s.accepted + 1 });
    else next.reject = s.reject + w;
    stats.set(key, next);
  }
  return stats;
}

function isActive(stat) {
  return !!stat && stat.n >= MIN_EFFECTIVE_N && !SAFETY_INTENTS.has(stat.intent);
}

// acceptRate - 0.5, in [-0.5, 0.5]; 0 until the effective sample reaches 5.
function adoptionScore(stat) {
  if (!isActive(stat)) return 0;
  return stat.accept / stat.n - 0.5;
}

function loadAdoption(home, now) {
  return { stats: summarize(readLedger(home), now || Date.now()), pins: readPins(home) };
}

module.exports = {
  HARNESS,
  MIN_EFFECTIVE_N,
  SAFETY_INTENTS,
  adoptionScore,
  appendJsonl,
  audit,
  eventWeight,
  intentPath,
  isActive,
  loadAdoption,
  pendingPath,
  readIntent,
  readJson,
  readJsonl,
  readLedger,
  readPins,
  recordIntent,
  sessionKey,
  statKey,
  storePaths,
  summarize,
  writeJson,
  writeJsonl,
};
