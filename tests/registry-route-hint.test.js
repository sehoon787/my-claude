#!/usr/bin/env node
// Capability registry v2 (hooks/build-registry.js) and the UserPromptSubmit
// route hint (hooks/route-hint.js), run against a synthetic $HOME and project
// — never the developer's real ~/.claude or ~/.omc.
// `node tests/registry-route-hint.test.js`
'use strict';
const fs = require('fs'), os = require('os'), path = require('path'), cp = require('child_process');

const REPO_ROOT = path.resolve(__dirname, '..');
const BUILD = path.join(REPO_ROOT, 'hooks', 'build-registry.js');
const ROUTE_HINT = path.join(REPO_ROOT, 'hooks', 'route-hint.js');
const reg = require(BUILD);
const { routeHint } = require(ROUTE_HINT);

const results = [];
function check(name, ok, detail) {
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? '  (' + detail + ')' : ''}`);
  results.push(!!ok);
}

function write(file, text) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, text);
}

function agent(name, description, model) {
  return `---\nname: ${name}\ndescription: ${description}\n${model ? `model: ${model}\n` : ''}---\n\nbody\n`;
}

function skill(name, descriptionYaml) {
  return `---\nname: ${name}\n${descriptionYaml}\n---\n\nbody\n`;
}

// ---------------------------------------------------------------- fixture

const ROOT = fs.mkdtempSync(path.join(os.tmpdir(), 'registry-v2-'));
const HOME = path.join(ROOT, 'home');
const PROJECT = path.join(ROOT, 'project');
const OUT = path.join(ROOT, 'out', 'capability-registry.json');
const C = path.join(HOME, '.claude');
const CACHE = path.join(C, 'plugins', 'cache', 'mkt');

write(path.join(C, 'agents', 'oracle.md'), agent('oracle', 'Read-only second opinion on architecture decisions.', 'opus'));
write(path.join(C, 'agents', 'metis.md'), agent('metis', 'Pre-planning intent and ambiguity check.', 'opus'));
write(path.join(C, 'agents', 'momus.md'), agent('momus', 'Checks a finished work plan for executability.', 'opus'));
write(path.join(C, 'agents', 'nested', 'deep-helper.md'), agent('deep-helper', 'Nested global agent.'));
write(path.join(C, 'agents', 'README.md'), '# not an agent, no frontmatter\n');
write(path.join(PROJECT, '.claude', 'agents', 'proj-arch.md'), agent('proj-arch', 'Project-specific architecture reviewer.'));

write(path.join(C, 'skills', 'architecture-decision-records', 'SKILL.md'),
  skill('architecture-decision-records', 'description: >-\n  Capture architectural decisions as ADRs.\n  Maintains an ADR log.'));
write(path.join(C, 'skills', 'long-skill', 'SKILL.md'),
  skill('long-skill', `description: "${'word '.repeat(80).trim()}"`));
write(path.join(C, 'skills', 'nameless', 'SKILL.md'), '---\ndescription: dir name is the fallback\n---\n');
write(path.join(PROJECT, '.claude', 'skills', 'proj-skill', 'SKILL.md'), skill('proj-skill', 'description: project skill'));

// Enabled plugin with three cached versions: 1.10.0 must win over 1.9.0
// (numeric, not lexical, compare). A disabled plugin must be ignored.
for (const v of ['1.2.0', '1.9.0']) {
  write(path.join(CACHE, 'omcx', v, 'agents', 'stale.md'), agent('stale', 'Only in an old version.'));
}
const OMCX = path.join(CACHE, 'omcx', '1.10.0');
write(path.join(OMCX, 'agents', 'architect.md'), agent('architect', 'Strategic Architecture Advisor.', 'opus'));
write(path.join(OMCX, 'agents', 'critic.md'), agent('critic', 'Work plan and code review expert.', 'opus'));
write(path.join(OMCX, 'agents', 'analyst.md'), agent('analyst', 'Pre-planning requirements analysis.', 'opus'));
write(path.join(OMCX, 'agents', 'executor.md'), agent('executor', 'Focused task executor.', 'sonnet'));
write(path.join(OMCX, 'agents', 'AGENTS.md'), '# index file\n');
write(path.join(OMCX, 'skills', 'deep-interview', 'SKILL.md'), skill('deep-interview', 'description: Socratic interview for vague requirements'));
write(path.join(CACHE, 'offp', '1.0.0', 'agents', 'ghost.md'), agent('ghost', 'Must never be registered.'));
write(path.join(C, 'settings.json'), JSON.stringify({ enabledPlugins: { 'omcx@mkt': true, 'offp@mkt': false } }));

const opts = { home: HOME, cwd: PROJECT, out: OUT };

// ---------------------------------------------------------------- build-registry

const first = reg.ensureRegistry(opts);
const r = first.registry;
const byId = (id) => [...r.agents, ...r.skills].find((x) => x.id === id);

check('first run builds and writes the registry', first.status === 'rebuilt' && fs.existsSync(OUT), first.status);
check('version is 2', r.version === 2 && JSON.parse(fs.readFileSync(OUT, 'utf8')).version === 2);
check('global agent has scope global + model', byId('oracle') && byId('oracle').scope === 'global' && byId('oracle').model === 'opus');
check('nested global agent is collected', byId('deep-helper') && byId('deep-helper').scope === 'global');
check('files without frontmatter are not agents', !r.agents.some((a) => /readme|agents/i.test(a.name)));
check('project agent has scope project', byId('proj-arch') && byId('proj-arch').scope === 'project');
check('project skill has scope project', byId('proj-skill') && byId('proj-skill').scope === 'project');
check('plugin agent is addressed <plugin>:<name>', byId('omcx:architect') && byId('omcx:architect').scope === 'plugin:omcx');
check('plugin skill is addressed <plugin>:<name>', byId('omcx:deep-interview') && byId('omcx:deep-interview').kind === 'skill');
check('newest plugin version dir is used', !byId('omcx:stale'));
check('disabled plugin is excluded', !r.agents.some((a) => a.name === 'ghost'));
check('folded skill description is joined', byId('architecture-decision-records').description === 'Capture architectural decisions as ADRs. Maintains an ADR log.');
check('long skill description is capped at 200 chars', byId('long-skill').description.length <= 200, `${byId('long-skill').description.length}`);
check('skill without a name falls back to its dir', !!byId('nameless'));
check('internal match text is not persisted', !r.agents.some((a) => '_match' in a));
check('sources record mtimes', Object.keys(r.sources).length > 5 && Object.values(r.sources).some((m) => typeof m === 'number'));

const arch = r.intents.find((i) => i.name === 'Architecture');
const archIds = arch.candidates.map((c) => c.id);
check('Architecture: explicit members first, in map order',
  archIds[0] === 'oracle' && archIds[1] === 'omcx:architect' && archIds[2] === 'architecture-decision-records', archIds.join(','));
check('Architecture: oracle flagged advisor', arch.candidates[0].advisor === true);
check('Architecture: description match ranks after members', archIds.indexOf('proj-arch') > 2, archIds.join(','));
check('uninstalled members are skipped', !archIds.includes('plan-eng-review') && !archIds.includes('ccg'));
const amb = r.intents.find((i) => i.name === 'Ambiguity');
check('Ambiguity: metis first, bare member resolves plugin skill',
  amb.candidates[0].id === 'metis' && amb.candidates.some((c) => c.id === 'omcx:deep-interview'), amb.candidates.map((c) => c.id).join(','));
check('adoptionWeight stub returns 0', reg.adoptionWeight({ id: 'x' }, 'Architecture') === 0);

check('second run skips rebuild when fresh', reg.ensureRegistry(opts).status === 'fresh');
const later = new Date(Date.now() + 5000);
fs.utimesSync(path.join(C, 'agents', 'metis.md'), later, later);
check('touched agent file triggers rebuild', reg.ensureRegistry(opts).status === 'rebuilt');
write(path.join(C, 'skills', 'new-skill', 'SKILL.md'), skill('new-skill', 'description: added later'));
fs.utimesSync(path.join(C, 'skills'), later, later);
const afterAdd = reg.ensureRegistry(opts);
check('new skill dir triggers rebuild and is picked up', afterAdd.status === 'rebuilt' && afterAdd.registry.skills.some((s) => s.id === 'new-skill'));
check('other project cwd triggers rebuild', reg.ensureRegistry({ ...opts, cwd: ROOT }).status === 'rebuilt');
reg.ensureRegistry(opts);
fs.writeFileSync(OUT, JSON.stringify({ generated_at: new Date(Date.now() + 1e9).toISOString(), agents: [], skills: [] }));
check('v1 registry is replaced', reg.ensureRegistry(opts).status === 'rebuilt');

const summary = reg.renderSummary(reg.ensureRegistry(opts).registry, OUT);
check('summary lists Architecture with advisor tag',
  summary.includes('Architecture → oracle[advisor], omcx:architect, /architecture-decision-records'), summary.split('\n')[6]);
check('summary names the registry path', summary.includes(OUT));
check('summary fits the char budget', summary.length <= reg.SUMMARY_MAX_CHARS, `${summary.length}`);
const huge = { intents: Array.from({ length: 400 }, (_, i) => ({ name: `Intent${i}`, candidates: [{ id: 'x'.repeat(40), kind: 'agent' }] })) };
const clipped = reg.renderSummary(huge, OUT);
check('oversized summary drops the lowest intents first',
  clipped.length <= reg.SUMMARY_MAX_CHARS && clipped.includes('Intent0 →') && !clipped.includes('Intent399 →') && clipped.includes(OUT));

// ---------------------------------------------------------------- route-hint

const env = Object.assign({}, process.env, { HOME, USERPROFILE: HOME, REGISTRY_OUT: OUT });
function hint(prompt, extra) {
  const res = cp.spawnSync('node', [ROUTE_HINT], {
    cwd: PROJECT, env, encoding: 'utf8', input: JSON.stringify(Object.assign({ prompt, cwd: PROJECT }, extra || {}))
  });
  const out = res.stdout.trim();
  if (!out) return { raw: '', doc: null, text: '' };
  const lines = out.split('\n');
  let doc = null;
  try { doc = JSON.parse(out); } catch { /* checked below */ }
  return { raw: out, lines: lines.length, doc, text: doc ? doc.hookSpecificOutput.additionalContext : '' };
}

function checkDoc(label, h) {
  check(`${label} -> one JSON doc with hookEventName`,
    h.doc && h.lines === 1 && h.doc.hookSpecificOutput.hookEventName === 'UserPromptSubmit', h.raw);
}

const cases = [
  ['Should we move from REST to gRPC?', 'Architecture', 'oracle[advisor]'],
  ['내부 서비스를 gRPC로 옮기는 게 맞을까?', 'Architecture', 'oracle[advisor]'],
  ['앱 좀 더 좋게 만들어줘', 'Ambiguity', 'metis[advisor]'],
  ['Make the app better', 'Ambiguity', 'metis[advisor]'],
  ['Here is our migration plan for moving the DB to Postgres, check it before we execute', 'PlanReview', 'momus[advisor]'],
];
for (const [prompt, intent, first] of cases) {
  const h = hint(prompt);
  checkDoc(JSON.stringify(prompt), h);
  check(`${JSON.stringify(prompt)} -> ${intent}, ${first} first`, h.text.startsWith(`[RouteHint] intent=${intent} → ${first}`), h.text);
  check(`${JSON.stringify(prompt)} -> advisor sentence present`, h.text.includes('Consult the Advisor Group'));
}

{
  const h = hint('fix typo in README');
  checkDoc('"fix typo in README"', h);
  check('"fix typo in README" -> Trivial without advisors', h.text.startsWith('[RouteHint] intent=Trivial') && !/advisor/i.test(h.text), h.text);
}
check('slash command -> no output', hint('/review the diff').raw === '');
check('task-notification -> no output', hint('<task-notification>\n<task-id>a1</task-id> should we plan</task-notification>').raw === '');
check('teammate message -> no output', hint('<teammate-message teammate_id="x">should we plan</teammate-message>').raw === '');
check('no matching intent -> no output', hint('hello there').raw === '');
check('empty stdin -> no output, exit 0', (() => {
  const res = cp.spawnSync('node', [ROUTE_HINT], { cwd: PROJECT, env, encoding: 'utf8', input: '' });
  return res.status === 0 && res.stdout === '';
})());
check('missing registry -> no output, exit 0', (() => {
  const res = cp.spawnSync('node', [ROUTE_HINT], {
    cwd: PROJECT, env: Object.assign({}, env, { REGISTRY_OUT: path.join(ROOT, 'nope.json') }),
    encoding: 'utf8', input: JSON.stringify({ prompt: 'Should we move from REST to gRPC?' })
  });
  return res.status === 0 && res.stdout === '';
})());
check('route-hint never rebuilds the registry', (() => {
  const before = fs.statSync(OUT).mtimeMs;
  fs.utimesSync(path.join(C, 'agents', 'oracle.md'), new Date(Date.now() + 9000), new Date(Date.now() + 9000));
  hint('Should we move from REST to gRPC?');
  return fs.statSync(OUT).mtimeMs === before;
})());

{
  const registry = JSON.parse(fs.readFileSync(OUT, 'utf8'));
  const other = routeHint('Should we move from REST to gRPC?', registry, ROOT);
  const text = other ? other.hookSpecificOutput.additionalContext : '';
  check('project-scope candidates are dropped for another project', !text.includes('proj-arch'), text);
  const t0 = process.hrtime.bigint();
  for (let i = 0; i < 20; i++) routeHint('내부 서비스를 gRPC로 옮기는 게 맞을까?', registry, PROJECT);
  const perCallMs = Number(process.hrtime.bigint() - t0) / 1e6 / 20;
  check('classification is well under 100 ms', perCallMs < 100, `${perCallMs.toFixed(2)} ms`);
}

fs.rmSync(ROOT, { recursive: true, force: true });

const failed = results.filter((ok) => !ok).length;
console.log(failed ? `${failed} FAILED` : 'ALL PASSED');
process.exit(failed ? 1 : 0);
