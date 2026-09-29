// Learning store: suggestions the learning loop detected, the rules/skills the
// user approved from them, and a ledger of every mutation.
//
// Shared directory (same as the adoption store):
//   ~/.config/agent-harness/learning-suggestions.jsonl  {id, kind, status, key, ...}
//   ~/.config/agent-harness/learning-items.json         {items: {slug: item}, last_curate_at}
//   ~/.config/agent-harness/learning-audit.jsonl        one row per mutation (id A<n>)
//   ~/.config/agent-harness/learned-archive/            files moved out by curate/rollback
// Approved files live only in the user-owned layer, which install.sh never
// manages: ~/.claude/rules/user/learned-*.md and ~/.claude/skills/learned-*/.
//
// Suggestion status: pending | approved | dismissed. Item status: active |
// stale | archived. Nothing is ever deleted: files move to learned-archive/.
'use strict';
const fs = require('fs');
const path = require('path');
const adoption = require('./adoption-store.js');

const HARNESS = 'claude';
const MAX_PENDING = 5;
const MAX_ACTIVE_ITEMS = 20;
const LEARNED_PREFIX = 'learned-';
const DAY_MS = 24 * 60 * 60 * 1000;

function learningPaths(home) {
  const base = adoption.storePaths(home);
  const h = path.dirname(path.dirname(base.shared));
  return {
    shared: base.shared,
    ledger: base.ledger,
    suggestions: path.join(base.shared, 'learning-suggestions.jsonl'),
    items: path.join(base.shared, 'learning-items.json'),
    audit: path.join(base.shared, 'learning-audit.jsonl'),
    archive: path.join(base.shared, 'learned-archive'),
    rulesDir: path.join(h, '.claude', 'rules', 'user'),
    skillsDir: path.join(h, '.claude', 'skills'),
  };
}

function iso(now) {
  return new Date(now).toISOString();
}

// ---------------------------------------------------------------- keys

// Case, punctuation, and spacing never make two suggestions different.
function normalizeText(text) {
  return String(text || '').toLowerCase().replace(/[\p{P}\p{S}]+/gu, ' ').replace(/\s+/g, ' ').trim();
}

function suggestionKey(s) {
  if (s.kind === 'skill') return `skill:${(s.steps || []).map((st) => st.id).join('>')}`;
  return `rule:${normalizeText(s.text)}`;
}

// ASCII words joined by '-', cut at a word boundary within maxLen.
function slugify(text, maxLen) {
  const max = maxLen || 48;
  const slug = String(text || '').toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '');
  if (slug.length <= max) return slug;
  const cut = slug.slice(0, max + 1);
  const at = cut.lastIndexOf('-');
  return (at > 0 ? cut.slice(0, at) : slug.slice(0, max)).replace(/-+$/, '');
}

// ---------------------------------------------------------------- suggestions

function isOurs(row) {
  return !!row && (row.harness || HARNESS) === HARNESS;
}

function readSuggestions(home) {
  return adoption.readJsonl(learningPaths(home).suggestions)
    .filter((s) => s && typeof s.id === 'string' && (s.kind === 'rule' || s.kind === 'skill'));
}

function writeSuggestions(home, rows) {
  adoption.writeJsonl(learningPaths(home).suggestions, rows);
}

function nextSuggestionId(rows) {
  const n = rows.reduce((max, s) => Math.max(max, parseInt(String(s.id).slice(1), 10) || 0), 0);
  return `L${n + 1}`;
}

// ---------------------------------------------------------------- items

function readState(home) {
  const j = adoption.readJson(learningPaths(home).items, null);
  const items = j && j.items && typeof j.items === 'object' ? j.items : {};
  return { items, last_curate_at: (j && j.last_curate_at) || null };
}

function writeState(home, state) {
  adoption.writeJson(learningPaths(home).items, state);
}

function exists(p) {
  try { fs.statSync(p); return true; } catch { return false; }
}

// Items that count toward the cap: not archived, file still in place.
function liveItems(state) {
  return Object.values(state.items).filter((it) => isOurs(it) && it.status !== 'archived' && exists(it.path));
}

function mtimeOf(p) {
  try { return fs.statSync(p).mtimeMs; } catch { return 0; }
}

// Latest sign of use: approval, a recorded use (Skill tool call, the same
// correction repeated), a ledger event for the skill, or an edit to the file.
function lastUseMs(item, ledgerEvents) {
  const file = item.kind === 'skill' ? path.join(item.path, 'SKILL.md') : item.path;
  const times = [Date.parse(item.approved_at), Date.parse(item.last_used_at), mtimeOf(file)];
  for (const e of ledgerEvents || []) if (e.id === item.slug) times.push(Date.parse(e.ts));
  return Math.max(0, ...times.filter(Number.isFinite));
}

// ---------------------------------------------------------------- audit

function readAudit(home) {
  return adoption.readJsonl(learningPaths(home).audit).filter((r) => r && typeof r.id === 'string');
}

// Appends one audit row and returns its id (A1, A2, ...).
function audit(home, now, action, fields) {
  const rows = readAudit(home);
  const n = rows.reduce((max, r) => Math.max(max, parseInt(r.id.slice(1), 10) || 0), 0);
  const id = `A${n + 1}`;
  adoption.appendJsonl(learningPaths(home).audit, [Object.assign({ id, ts: iso(now), harness: HARNESS, action }, fields)]);
  return id;
}

// ---------------------------------------------------------------- files

function writeAtomic(file, text) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  const tmp = `${file}.${process.pid}.tmp`;
  fs.writeFileSync(tmp, text);
  fs.renameSync(tmp, file);
}

// Move a rule file or skill directory into learned-archive/; returns the
// archive path. Never deletes.
function moveToArchive(home, src, now) {
  const stamp = iso(now).replace(/[-:]/g, '').replace(/\.\d+Z$/, 'Z');
  const dir = path.join(learningPaths(home).archive, stamp);
  let dest = path.join(dir, path.basename(src));
  for (let i = 2; exists(dest); i++) dest = path.join(dir, `${i}-${path.basename(src)}`);
  fs.mkdirSync(dir, { recursive: true });
  fs.renameSync(src, dest);
  return dest;
}

function moveBack(src, dest) {
  if (exists(dest)) throw new Error(`${dest} already exists; move it away first`);
  fs.mkdirSync(path.dirname(dest), { recursive: true });
  fs.renameSync(src, dest);
}

module.exports = {
  DAY_MS,
  HARNESS,
  LEARNED_PREFIX,
  MAX_ACTIVE_ITEMS,
  MAX_PENDING,
  audit,
  exists,
  iso,
  isOurs,
  lastUseMs,
  learningPaths,
  liveItems,
  moveBack,
  moveToArchive,
  nextSuggestionId,
  normalizeText,
  readAudit,
  readState,
  readSuggestions,
  slugify,
  suggestionKey,
  writeAtomic,
  writeState,
  writeSuggestions,
};
