#!/usr/bin/env node
// Adoption tracker: did the user adopt what an agent or skill just produced?
//
//   offer    PostToolUse Agent|Task|Skill. Appends what the main session ran
//            ({kind, id, tool_use_id, ts, intent, background}) to
//            ~/.claude/.adoption/pending-<session>.jsonl. Append-only, so
//            agents launched in parallel cannot drop each other's offers.
//   verdict  UserPromptSubmit. Classifies the user's next reply as accept,
//            reject (wins when both match), or neutral, appends one ledger
//            event per judged offer (none when neutral), and clears pending.
//            Slash commands and task-notification / teammate messages are not
//            replies: pending is kept and a turn marker is appended.
//
// Judged offers: those of the latest turn that ran anything, one per item,
// 5 max. A background agent's offer is judged only after a notification turn
// has passed (before that the user has not seen its result); until then it
// is carried over.
//
// Skills in the registry's adoption_ignore (from routing-map.json: process
// skills such as boss-briefing or cancel that run regardless of advice
// quality) are never offers; an entry also matches a plugin-qualified id
// with that short name.
//
// Both modes print nothing (no context is added) and never throw.
//   node adoption-tracker.js <offer|verdict>
'use strict';
const fs = require('fs');
const store = require('./adoption-store.js');
const { isRoutable } = require('./route-hint.js');
const { defaultPaths } = require('./build-registry.js');

const MAX_OFFERS = 5;
const EVIDENCE_MAX = 120;

// Latin phrases match as whole words; Korean ones match anywhere (particles
// attach to the stem), with guards where a common phrase shares the stem.
const ACCEPT = [
  /(^|[^a-z0-9])(go ahead|yes|yep|lgtm|apply it|ship it|sounds good|looks good|approved?|do it|merge it)($|[^a-z0-9])/,
  /진행해|진행 해|진행하자|반영해|반영 해|(?<!안\s?)좋아(?!하)|좋습니다|좋네요|그렇게 해|그렇게 하자|승인|머지해|머지 해|적용해/,
];
const REVERT = [
  /(^|[^a-z0-9])(revert|roll ?back)($|[^a-z0-9])/,
  /되돌려|롤백/,
];
const REJECT = [
  ...REVERT,
  /(^|[^a-z0-9])(wrong|redo|nope)($|[^a-z0-9])/,
  /(^|[^a-z0-9])(?<!don't |non-)stop($|[^a-z0-9])/,
  /(^|[^a-z0-9])no,/,
  /^\s*no[.!]?\s*$/,
  /아니(?!면)|틀렸|틀려|다시 해|다시해|그만(?!큼)|그렇게 하지 ?마/,
];
// Bare "하지 마"/"하지마" is a scope instruction as often as a rejection
// ("파일은 수정하지 마" while accepting the plan), so it only counts as a
// reject when no ACCEPT pattern also matches.
const WEAK_REJECT = [/하지 마|하지마/];
// "진행해도 될까?", "yes or no?": a question is not an accept.
const QUESTION = /\?\s*$/;

function matchesAny(text, patterns) {
  return patterns.some((re) => re.test(text));
}

// -> {verdict, signal} or null (neutral)
function classifyVerdict(prompt) {
  const text = String(prompt || '').toLowerCase().trim();
  if (matchesAny(text, REJECT)) return { verdict: 'reject', signal: matchesAny(text, REVERT) ? 'revert' : 'reply' };
  if (!QUESTION.test(text) && matchesAny(text, ACCEPT)) return { verdict: 'accept', signal: 'reply' };
  if (matchesAny(text, WEAK_REJECT)) return { verdict: 'reject', signal: 'reply' };
  return null;
}

// What the main session just ran. Tool calls made inside a subagent carry
// agent_id and are never shown to the user directly, so they are skipped.
function offerFrom(input) {
  if (!input || input.agent_id) return null;
  const ti = input.tool_input || {};
  if (input.tool_name === 'Agent' || input.tool_name === 'Task') {
    return { kind: 'agent', id: String(ti.subagent_type || 'general-purpose'), background: ti.run_in_background === true || !!ti.team_name };
  }
  if (input.tool_name === 'Skill' && ti.skill) {
    return { kind: 'skill', id: String(ti.skill).replace(/^\//, ''), background: false };
  }
  return null;
}

// adoption_ignore as copied into the registry at build time; the routing
// map itself until the registry has been rebuilt with it.
function adoptionIgnore(home) {
  const p = defaultPaths(home ? { home } : undefined);
  const list = [p.out, p.mapPath].map((file) => store.readJson(file, {}).adoption_ignore).find(Array.isArray);
  return new Set(list || []);
}

function isIgnored(id, ignore) {
  return ignore.has(id) || ignore.has(id.split(':').pop());
}

function recordOffer(input, home, now) {
  const offer = offerFrom(input);
  if (!offer || isIgnored(offer.id, adoptionIgnore(home))) return;
  store.appendJsonl(store.pendingPath(home, input.session_id), [Object.assign({ type: 'offer' }, offer, {
    tool_use_id: input.tool_use_id || '',
    ts: new Date(now).toISOString(),
    intent: store.readIntent(home, input.session_id),
  })]);
}

// Pending lines -> {judged, carried}. Turn markers split the lines into
// turns; the latest turn with offers wins; within it the first line per
// tool_use_id and the last per item are kept, newest 5.
function resolvePending(lines) {
  const turns = [[]];
  for (const l of lines) {
    if (l.type === 'turn') turns.push([]);
    else if (l.type === 'offer' && l.id) turns[turns.length - 1].push(l);
  }
  let k = turns.length - 1;
  while (k >= 0 && !turns[k].length) k--;
  if (k < 0) return { judged: [], carried: [] };
  const notified = k < turns.length - 1;
  const seenUse = new Set();
  const byItem = new Map();
  for (const o of turns[k]) {
    if (o.tool_use_id && seenUse.has(o.tool_use_id)) continue;
    if (o.tool_use_id) seenUse.add(o.tool_use_id);
    byItem.delete(`${o.kind}:${o.id}`);
    byItem.set(`${o.kind}:${o.id}`, o);
  }
  const offers = [...byItem.values()].slice(-MAX_OFFERS);
  return {
    judged: offers.filter((o) => !o.background || notified),
    carried: offers.filter((o) => o.background && !notified),
  };
}

function readPending(home, session) {
  return resolvePending(store.readJsonl(store.pendingPath(home, session)));
}

function recordVerdict(input, home, now) {
  const file = store.pendingPath(home, input.session_id);
  if (!fs.existsSync(file)) return;
  if (!isRoutable(input.prompt)) {
    store.appendJsonl(file, [{ type: 'turn', ts: new Date(now).toISOString() }]);
    return;
  }
  const { judged, carried } = resolvePending(store.readJsonl(file));
  const verdict = classifyVerdict(input.prompt);
  if (verdict && judged.length) {
    const ts = new Date(now).toISOString();
    const evidence = String(input.prompt).replace(/\s+/g, ' ').trim().slice(0, EVIDENCE_MAX);
    store.appendJsonl(store.storePaths(home).ledger, judged.map((o) => ({
      ts,
      harness: store.HARNESS,
      session: String(input.session_id || 'unknown'),
      kind: o.kind,
      id: o.id,
      intent: o.intent || 'unknown',
      verdict: verdict.verdict,
      signal: verdict.signal,
      evidence,
    })));
  }
  if (carried.length) store.writeJsonl(file, carried);
  else fs.unlinkSync(file);
}

function main(mode) {
  let input = {};
  try { input = JSON.parse(fs.readFileSync(0, 'utf8') || '{}'); } catch { return; }
  if (mode === 'offer') recordOffer(input, null, Date.now());
  else if (mode === 'verdict') recordVerdict(input, null, Date.now());
}

module.exports = { adoptionIgnore, classifyVerdict, isIgnored, offerFrom, readPending, recordOffer, recordVerdict, resolvePending };

if (require.main === module) {
  try { main(process.argv[2]); } catch { /* fail open: never block a prompt or a tool */ }
}
