#!/usr/bin/env node
// Adoption ledger (hooks/adoption-store.js, adoption-tracker.js,
// adoption-cli.js), its use in registry ranking (hooks/build-registry.js), and
// the persona-vault fixes (hooks/agent-log.js, stop-profile-update.js,
// persona-rule.js). Runs against a synthetic $HOME and project — never the
// developer's real ~/.claude, ~/.config/agent-harness, or ~/.omc.
// `node tests/adoption-ledger.test.js`
'use strict';
const fs = require('fs'), os = require('os'), path = require('path'), cp = require('child_process');

const REPO_ROOT = path.resolve(__dirname, '..');
const HOOKS = path.join(REPO_ROOT, 'hooks');
const TRACKER = path.join(HOOKS, 'adoption-tracker.js');
const ROUTE_HINT = path.join(HOOKS, 'route-hint.js');
const AGENT_LOG = path.join(HOOKS, 'agent-log.js');
const PROFILE = path.join(HOOKS, 'stop-profile-update.js');
const PERSONA = path.join(HOOKS, 'persona-rule.js');
const store = require(path.join(HOOKS, 'adoption-store.js'));
const reg = require(path.join(HOOKS, 'build-registry.js'));
const tracker = require(TRACKER);
const { classifyVerdict } = tracker;
const agentLog = require(AGENT_LOG);
const cli = require(path.join(HOOKS, 'adoption-cli.js'));

const results = [];
function check(name, ok, detail) {
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? '  (' + detail + ')' : ''}`);
  results.push(!!ok);
}

function write(file, text) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, text);
}

function agent(name, description) {
  return `---\nname: ${name}\ndescription: ${description}\n---\n\nbody\n`;
}

// ---------------------------------------------------------------- fixture

const ROOT = fs.mkdtempSync(path.join(os.tmpdir(), 'adoption-'));
const HOME = path.join(ROOT, 'home');
const PROJECT = path.join(ROOT, 'project');
const OUT = path.join(ROOT, 'out', 'capability-registry.json');
const C = path.join(HOME, '.claude');
const PLUGIN = path.join(C, 'plugins', 'cache', 'mkt', 'omcx', '1.0.0');
const PATHS = store.storePaths(HOME);
const DAY = 24 * 60 * 60 * 1000;
const NOW = Date.now();

write(path.join(C, 'agents', 'oracle.md'), agent('oracle', 'Read-only second opinion.'));
write(path.join(C, 'agents', 'metis.md'), agent('metis', 'Pre-planning check.'));
write(path.join(C, 'agents', 'arch-helper.md'), agent('arch-helper', 'Answers architecture questions.'));
write(path.join(C, 'agents', 'vuln-hunter.md'), agent('vuln-hunter', 'Finds security issues.'));
write(path.join(C, 'skills', 'architecture-decision-records', 'SKILL.md'), '---\nname: architecture-decision-records\ndescription: ADRs\n---\n');
write(path.join(PLUGIN, 'agents', 'architect.md'), agent('architect', 'Strategic advisor.'));
write(path.join(PLUGIN, 'agents', 'security-reviewer.md'), agent('security-reviewer', 'Reviews code.'));
write(path.join(PLUGIN, 'skills', 'security-scan', 'SKILL.md'), '---\nname: security-scan\ndescription: Scans config\n---\n');
write(path.join(C, 'settings.json'), JSON.stringify({ enabledPlugins: { 'omcx@mkt': true } }));
fs.mkdirSync(PROJECT, { recursive: true });

const opts = { home: HOME, cwd: PROJECT, out: OUT };
const env = Object.assign({}, process.env, { HOME, USERPROFILE: HOME, REGISTRY_OUT: OUT });

function ev(id, intent, verdict, daysAgo, kind) {
  return { ts: new Date(NOW - (daysAgo || 0) * DAY).toISOString(), harness: 'claude', session: 's', kind: kind || 'agent', id, intent, verdict, signal: 'reply', evidence: 'x' };
}

function setLedger(events) {
  if (events.length) store.writeJsonl(PATHS.ledger, events);
  else fs.rmSync(PATHS.ledger, { force: true });
}

function repeat(n, fn) {
  return Array.from({ length: n }, (_, i) => fn(i));
}

function run(script, args, input, cwd) {
  return cp.spawnSync('node', [script, ...args], { cwd: cwd || PROJECT, env, encoding: 'utf8', input: JSON.stringify(input) });
}

function candidates(registry, intent) {
  return registry.intents.find((i) => i.name === intent).candidates;
}

// ---------------------------------------------------------------- verdict classification

const verdictCases = [
  ['좋아 그렇게 진행해', 'accept'],
  ['반영해줘', 'accept'],
  ['승인, 머지해', 'accept'],
  ['go ahead', 'accept'],
  ['LGTM, ship it', 'accept'],
  ['yes', 'accept'],
  ['아니 틀렸어, 다시 해', 'reject'],
  ['그만하고 되돌려', 'reject'],
  ['No, that is wrong', 'reject'],
  ['redo it', 'reject'],
  ['stop', 'reject'],
  ['좋아 근데 아니 다시 해', 'reject'],
  ['yes, but revert the config change', 'reject'],
  ['아니면 다른 방법은?', null],
  ['그만큼 중요한 거야', null],
  ['no problem, what about the tests?', null],
  ['yesterday the build broke', null],
  ['what does this function do?', null],
  ['별로 안 좋아', null],
  ['안좋아 보여', null],
  ['좋아하는 방식이 뭐야', null],
  ['진행해도 될까?', null],
  ['yes or no?', null],
  ['how do i do it?', null],
  ["don't stop, keep going", null],
  ['is this a non-stop build', null],
];
for (const [text, want] of verdictCases) {
  const got = classifyVerdict(text);
  check(`verdict ${JSON.stringify(text)} -> ${want || 'neutral'}`, (got ? got.verdict : null) === want, JSON.stringify(got));
}
check('revert keyword -> signal revert', classifyVerdict('되돌려줘').signal === 'revert' && classifyVerdict('please revert it').signal === 'revert');
check('plain reject -> signal reply', classifyVerdict('틀렸어').signal === 'reply');

// ---------------------------------------------------------------- offer -> verdict -> ledger (hooks as spawned)

const reg0 = reg.ensureRegistry(opts);
check('fixture registry builds', reg0.status === 'rebuilt');

const SESSION = 'sess-1';
const pendingFile = store.pendingPath(HOME, SESSION);
function offer(tool, toolInput, extra) {
  return run(TRACKER, ['offer'], Object.assign({ session_id: SESSION, hook_event_name: 'PostToolUse', tool_name: tool, tool_input: toolInput, tool_use_id: `tu-${Math.random()}` }, extra || {}));
}
function verdict(prompt) {
  return run(TRACKER, ['verdict'], { session_id: SESSION, hook_event_name: 'UserPromptSubmit', prompt });
}
function pendingOffers() {
  const p = tracker.readPending(HOME, SESSION);
  return [...p.judged, ...p.carried];
}

{
  const h = run(ROUTE_HINT, [], { session_id: SESSION, prompt: 'REST에서 gRPC로 옮길까?', cwd: PROJECT });
  check('route-hint still emits its hint', h.stdout.includes('[RouteHint] intent=Architecture'), h.stdout.trim());
  check('route-hint records the intent for the session', store.readIntent(HOME, SESSION) === 'Architecture');

  const o = offer('Agent', { subagent_type: 'oracle', description: 'review', prompt: 'p' });
  check('offer mode prints nothing', o.stdout === '' && o.status === 0, JSON.stringify(o.stdout));
  check('offer is pending with the prompt intent', pendingOffers().length === 1 && pendingOffers()[0].id === 'oracle' && pendingOffers()[0].intent === 'Architecture');

  const slash = verdict('/compact');
  check('slash command -> no event, pending kept', slash.stdout === '' && !fs.existsSync(PATHS.ledger) && pendingOffers().length === 1);
  const note = verdict('<task-notification><task-id>x</task-id>좋아 진행해</task-notification>');
  check('task-notification -> no event, pending kept', note.stdout === '' && !fs.existsSync(PATHS.ledger) && pendingOffers().length === 1);
  const mate = verdict('<teammate-message teammate_id="x">go ahead</teammate-message>');
  check('teammate message -> no event, pending kept', mate.stdout === '' && !fs.existsSync(PATHS.ledger) && pendingOffers().length === 1);

  const v = verdict('좋아 그렇게 진행해');
  const events = store.readLedger(HOME);
  check('verdict mode prints nothing', v.stdout === '' && v.status === 0, JSON.stringify(v.stdout));
  check('accept reply -> one ledger event', events.length === 1, `${events.length}`);
  const e = events[0] || {};
  check('event carries the documented schema',
    e.harness === 'claude' && e.session === SESSION && e.kind === 'agent' && e.id === 'oracle' && e.intent === 'Architecture'
      && e.verdict === 'accept' && e.signal === 'reply' && e.evidence === '좋아 그렇게 진행해' && !Number.isNaN(Date.parse(e.ts)), JSON.stringify(e));
  check('pending cleared after a reply', !fs.existsSync(pendingFile));

  offer('Skill', { skill: 'architecture-decision-records' });
  const n = verdict('what does the ADR say about caching?');
  check('neutral reply -> no event, pending cleared', n.stdout === '' && store.readLedger(HOME).length === 1 && !fs.existsSync(pendingFile));

  offer('Skill', { skill: 'architecture-decision-records' });
  verdict('x'.repeat(300) + ' wrong');
  const last = store.readLedger(HOME).pop();
  check('skill reject -> kind skill, evidence capped at 120 chars', last.kind === 'skill' && last.verdict === 'reject' && last.evidence.length === 120);
}

{
  // Dedupe and turn scoping, driven in-process for speed.
  const S = 'sess-dedupe';
  const ids = () => { const p = tracker.readPending(HOME, S); return [...p.judged, ...p.carried].map((o) => o.id).join(','); };
  const base = { session_id: S, tool_name: 'Agent' };
  tracker.recordOffer(Object.assign({}, base, { tool_use_id: 't1', tool_input: { subagent_type: 'oracle' } }), HOME, NOW);
  tracker.recordOffer(Object.assign({}, base, { tool_use_id: 't1', tool_input: { subagent_type: 'oracle' } }), HOME, NOW + 1);
  tracker.recordOffer(Object.assign({}, base, { tool_use_id: 't2', tool_input: { subagent_type: 'oracle' } }), HOME, NOW + 2);
  check('same tool_use_id or same item twice -> one offer', ids() === 'oracle', ids());
  tracker.recordOffer(Object.assign({}, base, { agent_id: 'sub-1', tool_use_id: 't3', tool_input: { subagent_type: 'metis' } }), HOME, NOW + 3);
  check('Agent call made inside a subagent is not an offer', ids() === 'oracle');
  for (let i = 0; i < 7; i++) tracker.recordOffer(Object.assign({}, base, { tool_use_id: `c${i}`, tool_input: { subagent_type: `a${i}` } }), HOME, NOW + 10 + i);
  check('pending is capped at 5 (newest kept)', ids() === 'a2,a3,a4,a5,a6', ids());
  tracker.recordVerdict({ session_id: S, prompt: '<task-notification>done</task-notification>' }, HOME, NOW + 100);
  check('notification keeps the offers when the next turn runs nothing', ids() === 'a2,a3,a4,a5,a6');
  tracker.recordOffer(Object.assign({}, base, { tool_use_id: 'n1', tool_input: { subagent_type: 'metis' } }), HOME, NOW + 200);
  check('a later turn that runs something replaces the older turn offers', ids() === 'metis', ids());
  tracker.recordOffer({ session_id: S, tool_name: 'Agent', tool_use_id: 'g1', tool_input: {} }, HOME, NOW + 201);
  check('Agent without subagent_type -> general-purpose', ids() === 'metis,general-purpose', ids());
  const before = store.readLedger(HOME).length;
  const t0 = process.hrtime.bigint();
  tracker.recordVerdict({ session_id: S, prompt: 'lgtm' }, HOME, NOW + 300);
  const ms = Number(process.hrtime.bigint() - t0) / 1e6;
  check('verdict appends one event per pending offer', store.readLedger(HOME).length === before + 2);
  check('verdict work is under 50 ms', ms < 50, `${ms.toFixed(2)} ms`);
  const spawnStart = Date.now();
  run(TRACKER, ['verdict'], { session_id: 'no-pending', prompt: 'yes' });
  console.log(`INFO  verdict hook wall time incl. node startup: ${Date.now() - spawnStart} ms`);
  check('pending cleared after the reply', !fs.existsSync(store.pendingPath(HOME, S)));

  // Background agents: judged only after a notification turn.
  const B = 'sess-bg';
  const bg = { session_id: B, tool_name: 'Agent' };
  tracker.recordOffer(Object.assign({}, bg, { tool_use_id: 'b1', tool_input: { subagent_type: 'oracle', run_in_background: true } }), HOME, NOW);
  tracker.recordOffer(Object.assign({}, bg, { tool_use_id: 'b2', tool_input: { subagent_type: 'metis' } }), HOME, NOW + 1);
  const n0 = store.readLedger(HOME).length;
  tracker.recordVerdict({ session_id: B, prompt: 'yes' }, HOME, NOW + 2);
  const early = store.readLedger(HOME).slice(n0);
  check('reply before the notification judges only the foreground offer', early.length === 1 && early[0].id === 'metis', early.map((e) => e.id).join(','));
  check('background offer is carried over', tracker.readPending(HOME, B).carried.map((o) => o.id).join(',') === 'oracle');
  tracker.recordVerdict({ session_id: B, prompt: '<task-notification>oracle done</task-notification>' }, HOME, NOW + 3);
  tracker.recordVerdict({ session_id: B, prompt: '틀렸어' }, HOME, NOW + 4);
  const late = store.readLedger(HOME).slice(n0 + 1);
  check('after the notification the background offer is judged', late.length === 1 && late[0].id === 'oracle' && late[0].verdict === 'reject');
  check('teammate spawn counts as background', tracker.offerFrom({ tool_name: 'Agent', tool_input: { subagent_type: 'x', team_name: 't' } }).background === true);

  // Parallel launches: concurrent offer hooks must not drop each other.
  const P = 'sess-parallel';
  const launch = repeat(4, (i) => `echo '${JSON.stringify({ session_id: P, tool_name: 'Agent', tool_use_id: `p${i}`, tool_input: { subagent_type: `par${i}` } })}' | node "${TRACKER}" offer &`).join('\n');
  cp.spawnSync('bash', ['-c', `${launch}\nwait`], { env });
  check('4 parallel offer hooks keep 4 offers', tracker.readPending(HOME, P).judged.length === 4, `${tracker.readPending(HOME, P).judged.length}`);

  check('garbage stdin -> no output, exit 0', (() => {
    const r = cp.spawnSync('node', [TRACKER, 'verdict'], { env, encoding: 'utf8', input: 'not json' });
    return r.status === 0 && r.stdout === '' && r.stderr === '';
  })());
}

// ---------------------------------------------------------------- adoptionWeight + ranking

{
  const oracle = { id: 'oracle' };
  const load = (events, pins) => {
    setLedger(events);
    store.writeJson(PATHS.pins, pins || []);
    return store.loadAdoption(HOME, NOW);
  };
  check('n < 5 -> weight 0', reg.adoptionWeight(oracle, 'Architecture', load(repeat(4, () => ev('oracle', 'Architecture', 'accept')))) === 0);
  check('n >= 5 all accepted -> positive weight', reg.adoptionWeight(oracle, 'Architecture', load(repeat(5, () => ev('oracle', 'Architecture', 'accept')))) > 0);
  check('adoption is per intent', reg.adoptionWeight(oracle, 'Ambiguity', load(repeat(5, () => ev('oracle', 'Architecture', 'accept')))) === 0);
  check('90-day half-life', Math.abs(store.eventWeight(ev('x', 'y', 'accept', 90), NOW) - 0.5) < 1e-9);
  check('5 events from earlier today pass the n >= 5 gate',
    reg.adoptionWeight(oracle, 'Architecture', (() => { setLedger(repeat(5, () => ev('oracle', 'Architecture', 'accept', 0.2))); return store.loadAdoption(HOME, NOW); })()) > 0);
  check('events older than 180 days count for nothing', store.eventWeight(ev('x', 'y', 'accept', 181), NOW) === 0);
  check('6 events 100 days old (effective n < 5) -> weight 0',
    reg.adoptionWeight(oracle, 'Architecture', load(repeat(6, () => ev('oracle', 'Architecture', 'accept', 100)))) === 0);
  check('Security ignores adoption',
    reg.adoptionWeight({ id: 'vuln-hunter' }, 'Security', load(repeat(9, () => ev('vuln-hunter', 'Security', 'accept')))) === 0);

  // Explicit member (architect) fully rejected vs keyword match (arch-helper)
  // fully accepted: the member must stay ahead.
  load([
    ...repeat(10, () => ev('omcx:architect', 'Architecture', 'reject')),
    ...repeat(10, () => ev('architecture-decision-records', 'Architecture', 'reject', 0, 'skill')),
    ...repeat(10, () => ev('arch-helper', 'Architecture', 'accept')),
  ]);
  let ids = candidates(reg.buildRegistry(opts), 'Architecture').map((c) => c.id);
  const lastMember = Math.max(ids.indexOf('oracle'), ids.indexOf('omcx:architect'), ids.indexOf('architecture-decision-records'));
  check('explicit members never drop below a keyword match', lastMember < ids.indexOf('arch-helper'), ids.join(','));

  load([...repeat(6, () => ev('omcx:architect', 'Architecture', 'accept')), ...repeat(6, () => ev('oracle', 'Architecture', 'reject'))]);
  ids = candidates(reg.buildRegistry(opts), 'Architecture').map((c) => c.id);
  check('adoption reorders within the member band', ids[0] === 'omcx:architect' && ids.indexOf('oracle') > 0
    && ids.indexOf('oracle') < ids.indexOf('arch-helper'), ids.join(','));

  load([...repeat(6, () => ev('oracle', 'Architecture', 'accept'))], [{ id: 'arch-helper', intent: 'Architecture' }]);
  const pinned = candidates(reg.buildRegistry(opts), 'Architecture');
  check('pin forces the top of its intent', pinned[0].id === 'arch-helper' && pinned[0].pinned === true, pinned.map((c) => c.id).join(','));
  check('pin applies to its intent only', candidates(reg.buildRegistry(opts), 'Ambiguity')[0].id === 'metis');
  load(repeat(9, () => ev('oracle', 'Architecture', 'accept')), [{ id: 'omcx:architect', intent: 'Architecture' }, { id: 'oracle', intent: 'Architecture' }]);
  const twoPins = candidates(reg.buildRegistry(opts), 'Architecture').map((c) => c.id);
  check('pins keep the order they were made in (scope/adoption do not reorder them)',
    twoPins[0] === 'omcx:architect' && twoPins[1] === 'oracle', twoPins.join(','));

  load(repeat(9, () => ev('vuln-hunter', 'Security', 'accept')), [{ id: 'vuln-hunter', intent: 'Security' }]);
  const sec = candidates(reg.buildRegistry(opts), 'Security');
  check('Security ignores adoption and pins (map order kept)',
    sec[0].id === 'omcx:security-reviewer' && !sec.some((c) => c.pinned || c.adoption), sec.map((c) => c.id).join(','));

  // Summary annotation only once n >= 5.
  load([...repeat(7, () => ev('oracle', 'Architecture', 'accept')), ...repeat(2, () => ev('oracle', 'Architecture', 'reject')),
    ...repeat(4, () => ev('omcx:architect', 'Architecture', 'accept'))]);
  const summary = reg.renderSummary(reg.buildRegistry(opts), OUT);
  const archLine = summary.split('\n').find((l) => l.startsWith('Architecture →')) || '';
  check('summary annotates (adopted 7/9) at n >= 5, not below', archLine.includes('oracle[advisor] (adopted 7/9)') && !archLine.includes('omcx:architect (adopted'), archLine);
  check('route hint stays unannotated', !reg.formatCandidate(candidates(reg.buildRegistry(opts), 'Architecture')[0]).includes('adopted'));

  // Registry rebuild when the ledger or pins change.
  reg.ensureRegistry(opts, true);
  check('registry fresh when ledger unchanged', reg.ensureRegistry(opts).status === 'fresh');
  const later = new Date(Date.now() + 5000);
  store.appendJsonl(PATHS.ledger, [ev('oracle', 'Architecture', 'accept')]);
  fs.utimesSync(PATHS.ledger, later, later);
  check('ledger change triggers rebuild', reg.ensureRegistry(opts).status === 'rebuilt');
  store.writeJson(PATHS.pins, [{ id: 'metis', intent: 'Architecture' }]);
  fs.utimesSync(PATHS.pins, new Date(Date.now() + 9000), new Date(Date.now() + 9000));
  check('pins change triggers rebuild', reg.ensureRegistry(opts).status === 'rebuilt');
  const noLedgerSource = JSON.parse(fs.readFileSync(OUT, 'utf8'));
  delete noLedgerSource.sources[PATHS.ledger];
  fs.writeFileSync(OUT, JSON.stringify(noLedgerSource));
  check('registry built before the ledger existed as a source is rebuilt', reg.ensureRegistry(opts).status === 'rebuilt');
  const dayOld = JSON.parse(fs.readFileSync(OUT, 'utf8'));
  dayOld.generated_at = new Date(Date.now() - 25 * 60 * 60 * 1000).toISOString();
  fs.writeFileSync(OUT, JSON.stringify(dayOld));
  check('a day-old registry is rebuilt while the ledger has events (decay)', reg.ensureRegistry(opts).status === 'rebuilt');
  store.writeJson(PATHS.pins, []);
}

// ---------------------------------------------------------------- CLI

{
  const outLines = [];
  const say = (s) => outLines.push(s);
  const run1 = (argv) => { outLines.length = 0; const code = cli.main(argv, { home: HOME, now: NOW, out: say }); return { code, text: outLines.join('') }; };
  setLedger([
    ...repeat(3, () => ev('oracle', 'Architecture', 'accept')),
    Object.assign(ev('metis', 'Ambiguity', 'reject'), { ts: '2026-01-01T00:00:00.000Z' }),
    Object.assign(ev('oracle', 'Ambiguity', 'accept'), { ts: '2026-01-02T00:00:00.000Z' }),
    Object.assign(ev('metis', 'Ambiguity', 'accept'), { ts: '2026-01-02T00:00:00.000Z' }),
  ]);
  fs.rmSync(PATHS.audit, { force: true });
  const l = run1(['list']);
  check('list prints an id x intent table', l.code === 0 && /INTENT\s+ID\s+KIND\s+ACCEPT\s+REJECT\s+N/.test(l.text) && /Architecture\s+oracle\s+agent\s+3\.0/.test(l.text), l.text.split('\n')[1]);
  const li = run1(['list', '--intent', 'architecture']);
  check('list --intent filters (case-insensitive)', li.text.includes('oracle') && !li.text.includes('Ambiguity'));
  check('pin with unknown intent is refused', run1(['pin', 'oracle', 'Nope']).code === 1);
  check('pin on a safety intent is refused', run1(['pin', 'vuln-hunter', 'security']).code === 1);
  check('pin writes adoption-pins.json', run1(['pin', 'oracle', 'architecture']).code === 0
    && store.readPins(HOME).some((p) => p.id === 'oracle' && p.intent === 'Architecture'));
  check('list marks the pin', /Architecture\s+oracle.*pinned/.test(run1(['list']).text));
  check('unpin removes it', run1(['unpin', 'oracle', 'Architecture']).code === 0 && store.readPins(HOME).length === 0);
  store.writeJson(PATHS.pins, [{ id: 'oracle', intent: 'RetiredIntent', ts: 'x' }]);
  check('unpin works for an intent no longer in the routing map', run1(['unpin', 'oracle', 'retiredintent']).code === 0 && store.readPins(HOME).length === 0);
  const evl = run1(['list', '--events', '--intent', 'Ambiguity']);
  check('list --events prints ts per event', evl.text.includes('2026-01-02T00:00:00.000Z') && !evl.text.includes('Architecture'), evl.text.split('\n')[0]);
  const amb = run1(['undo', '2026-01-02T00:00:00.000Z']);
  check('undo with a shared ts asks for the id', amb.code === 1 && amb.text.includes('oracle') && amb.text.includes('metis'));
  const u = run1(['undo', '2026-01-02T00:00:00.000Z', 'metis']);
  const archived = store.readJsonl(PATHS.archive);
  check('undo moves exactly one event to the archive', u.code === 0 && store.readLedger(HOME).length === 5
    && archived.length === 1 && archived[0].id === 'metis' && archived[0].archive_reason === 'undo');
  const r = run1(['reset', 'oracle']);
  check('reset <id> archives only that id', r.code === 0 && store.readLedger(HOME).every((e) => e.id !== 'oracle') && store.readJsonl(PATHS.archive).length === 5);
  run1(['reset']);
  check('reset archives everything, nothing hard-deleted', store.readLedger(HOME).length === 0 && store.readJsonl(PATHS.archive).length === 6);
  const audits = store.readJsonl(PATHS.audit).map((a) => a.action);
  check('every mutation is audited', audits.join(',') === 'pin,unpin,unpin,undo,reset,reset', audits.join(','));
  store.appendJsonl(PATHS.ledger, [{ ts: 'x', id: 7, intent: ['bad'], verdict: 'accept' }]);
  check('malformed rows from another harness do not crash list', run1(['list']).code === 0);
  const viaPersona = cp.spawnSync('node', [PERSONA, 'adoption', 'list'], { cwd: ROOT, env, encoding: 'utf8' });
  check('persona-rule.js adoption dispatches without a vault', viaPersona.status === 0 && viaPersona.stdout.includes('No adoption events yet.'), viaPersona.stdout);
}

// ---------------------------------------------------------------- persona fixes

{
  const VAULT = path.join(ROOT, 'vault-project');
  write(path.join(VAULT, '.briefing', 'INDEX.md'), '# x\n');
  const map = run(AGENT_LOG, ['map'], { tool_name: 'Agent', tool_input: { name: 'mc-reason-text', subagent_type: 'oracle', description: 'd' } }, VAULT);
  check('agent-log map prints nothing', map.stdout === '' && map.status === 0);
  for (let i = 0; i < 3; i++) run(AGENT_LOG, ['stop'], { agent_id: 'amc-reason-text-1', agent_type: 'mc-reason-text' }, VAULT);
  run(AGENT_LOG, ['stop'], { agent_id: 'a2', agent_type: 'metis' }, VAULT);
  const log = store.readJsonl(path.join(VAULT, '.briefing', 'agents', 'agent-log.jsonl'));
  check('SubagentStop keys on the agent type, name kept as metadata',
    log[0].agent_type === 'oracle' && log[0].name === 'mc-reason-text' && log[3].agent_type === 'metis' && !('name' in log[3]), JSON.stringify(log[0]));
  check('dedupeByAgentId keeps one line per agent_id', agentLog.dedupeByAgentId(log).length === 2);

  // Legacy lines: a one-off display name as agent_type, repeated per idle.
  const legacy = repeat(5, (i) => ({ ts: new Date(NOW - i * 1000).toISOString(), agent_id: 'amx-integrate-9', agent_type: 'mx-integrate' }));
  const metisRuns = repeat(3, (i) => ({ ts: new Date(NOW - i * 1000).toISOString(), agent_id: `m${i}`, agent_type: 'metis' }));
  store.appendJsonl(path.join(VAULT, '.briefing', 'agents', 'agent-log.jsonl'), [...legacy, ...metisRuns]);
  store.writeJsonl(path.join(VAULT, '.briefing', 'persona', 'suggestions.jsonl'), [
    { type: 'pending', pattern: 'mx-integrate>=3', agent_type: 'mx-integrate', count: 44, ts: new Date(NOW).toISOString() },
    { type: 'pending', pattern: 'oracle>=3', agent_type: 'oracle', count: 3, ts: new Date(NOW).toISOString() },
  ]);
  const prof = cp.spawnSync('node', [PROFILE], { cwd: VAULT, env, encoding: 'utf8', input: '{}' });
  check('stop-profile-update prints nothing', prof.stdout === '' && prof.status === 0, prof.stderr);
  const profile = fs.readFileSync(path.join(VAULT, '.briefing', 'persona', 'profile.md'), 'utf8');
  check('affinity counts each agent_id once, by agent type', /- metis: \d+% \(4\/5 calls/.test(profile) && /- oracle: \d+% \(1\/5 calls/.test(profile), profile.split('## Agent Affinity')[1].split('##')[0].trim());
  check('affinity skips display names that are not installed types', !profile.includes('mx-integrate') && !profile.includes('mc-reason-text'));
  const sugg = store.readJsonl(path.join(VAULT, '.briefing', 'persona', 'suggestions.jsonl'));
  const mx = sugg.find((s) => s.agent_type === 'mx-integrate');
  check('stale pending suggestion for a non-installed type is dismissed with a reason',
    mx.type === 'dismissed' && /not an installed agent type/.test(mx.dismiss_reason) && !!mx.dismissed_at, JSON.stringify(mx));
  check('pending suggestion for an installed type is kept', sugg.find((s) => s.agent_type === 'oracle').type === 'pending');
  check('new suggestion is created for the installed type (metis 4x)', sugg.some((s) => s.agent_type === 'metis' && s.type === 'pending' && s.count === 4));

  store.appendJsonl(path.join(VAULT, '.briefing', 'persona', 'suggestions.jsonl'),
    [{ type: 'pending', agent_type: 'codex-logo-strip', count: 26, ts: new Date(NOW).toISOString() }]);
  const listed = cp.spawnSync('node', [PERSONA, 'list'], { cwd: VAULT, env, encoding: 'utf8' });
  const after = store.readJsonl(path.join(VAULT, '.briefing', 'persona', 'suggestions.jsonl'));
  check('persona-rule list dismisses on read and hides it', !listed.stdout.includes('codex-logo-strip')
    && after.find((s) => s.agent_type === 'codex-logo-strip').type === 'dismissed', listed.stdout.trim());

  write(path.join(VAULT, '.claude', 'agents', 'local-only.md'), agent('local-only', 'Project agent.'));
  const types = agentLog.installedAgentTypes(OUT, VAULT);
  check('installed types include this project agents even when the registry was built elsewhere',
    types.has('local-only') && types.has('oracle') && types.has('omcx:architect') && types.has('general-purpose'));
  const hooksJson = JSON.parse(fs.readFileSync(path.join(HOOKS, 'hooks.json'), 'utf8')).hooks;
  check('name map runs on PreToolUse (a foreground SubagentStop fires before PostToolUse)',
    hooksJson.PreToolUse.some((g) => g.matcher === 'Agent|Task' && g.hooks.some((h) => h.command.includes('agent-log.js" map'))));
  run(AGENT_LOG, ['map'], { tool_name: 'TaskCreate', tool_input: { name: 'not-an-agent', subagent_type: 'x' } }, VAULT);
  check('map ignores tools other than Agent/Task', !fs.readFileSync(path.join(VAULT, '.briefing', 'agents', 'agent-types.jsonl'), 'utf8').includes('not-an-agent'));
  check('no registry -> installedAgentTypes null (no filtering)', agentLog.installedAgentTypes(path.join(ROOT, 'missing.json')) === null);
  const kept = agentLog.dismissUninstalledSuggestions([{ type: 'pending', agent_type: 'x' }], null, 'now');
  check('no registry -> nothing dismissed', !kept.changed && kept.list[0].type === 'pending');
}

check('nothing was written outside the temp HOME', !fs.existsSync(path.join(os.homedir(), '.config', 'agent-harness', 'adoption-audit.jsonl'))
  || fs.statSync(path.join(os.homedir(), '.config', 'agent-harness', 'adoption-audit.jsonl')).mtimeMs < NOW - 1000);

fs.rmSync(ROOT, { recursive: true, force: true });

const failed = results.filter((ok) => !ok).length;
console.log(failed ? `${failed} FAILED` : 'ALL PASSED');
process.exit(failed ? 1 : 0);
