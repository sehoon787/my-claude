#!/usr/bin/env node
// Learning loop (hooks/learning-store.js, learning-review.js, learning-cli.js):
// correction and repeated-workflow detection, the pending queue, approval
// into the user-owned layer, the curator, rollback, and SessionStart
// surfacing. Runs against synthetic $HOMEs only — never the developer's real
// ~/.claude, ~/.config/agent-harness, or ~/.omc.
// `node tests/learning-loop.test.js`
'use strict';
const fs = require('fs'), os = require('os'), path = require('path'), cp = require('child_process');

const REPO_ROOT = path.resolve(__dirname, '..');
const HOOKS = path.join(REPO_ROOT, 'hooks');
const REVIEW = path.join(HOOKS, 'learning-review.js');
const PERSONA = path.join(HOOKS, 'persona-rule.js');
const store = require(path.join(HOOKS, 'learning-store.js'));
const review = require(REVIEW);
const cli = require(path.join(HOOKS, 'learning-cli.js'));
const reg = require(path.join(HOOKS, 'build-registry.js'));

const results = [];
function check(name, ok, detail) {
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? '  (' + detail + ')' : ''}`);
  results.push(!!ok);
}

const ROOT = fs.mkdtempSync(path.join(os.tmpdir(), 'learning-'));
const DAY = 24 * 60 * 60 * 1000;
const NOW = Date.now();
let homeSeq = 0;
function newHome() {
  const h = path.join(ROOT, `home${++homeSeq}`);
  fs.mkdirSync(h, { recursive: true });
  return h;
}

function runCli(home, argv, now) {
  let out = '';
  const code = cli.main(argv, { home, now: now || NOW, out: (s) => { out += s; } });
  return { code, out };
}

// ---------------------------------------------------------------- transcripts

function userLine(text) {
  return JSON.stringify({ type: 'user', message: { role: 'user', content: text }, sessionId: 's' });
}
function assistantLine(tools) {
  return JSON.stringify({
    type: 'assistant',
    message: { role: 'assistant', content: [{ type: 'text', text: 'done' }, ...(tools || []).map((t, i) => ({ type: 'tool_use', id: `tu${i}`, name: t.name, input: t.input }))] },
  });
}
function toolResultLine(text) {
  return JSON.stringify({ type: 'user', message: { role: 'user', content: [{ type: 'tool_result', tool_use_id: 'tu0', content: text }] } });
}
function writeTranscript(lines) {
  const file = path.join(ROOT, `t${Math.random().toString(36).slice(2)}.jsonl`);
  fs.writeFileSync(file, lines.join('\n') + '\n');
  return file;
}

// ---------------------------------------------------------------- correction rule

const correctionCases = [
  ["Don't use tables in the summary.", true],
  ['Never push to main without asking.', true],
  ['Always write tests first', true],
  ['No, don’t add comments to every line', true],
  ['You should always run the linter before committing', true],
  ['From now on answer in Korean', true],
  ['Stop doing force pushes', true],
  ['Use pnpm instead of npm', true],
  ['표는 항상 한국어로 작성해줘, 영어 헤더 쓰지 마', true],
  ['영어 헤더 쓰지 마세요', true],
  ['다음부터 커밋 전에 테스트 돌려', true],
  ['앞으로 커밋 메시지는 영어로 써줘', true],
  ['npm 말고 pnpm 써', true],
  ['그렇게 하지 말고 파일을 나눠', true],
  ['it always fails on CI', false],
  ["I don't know why it broke", false],
  ['Should I always use pnpm?', false],
  ['Why did you use npm instead of pnpm?', false],
  ['never mind, keep going', false],
  ['Ok, never mind.', false],
  ['No, never mind, keep going', false],
  ["Don't know, you pick", false],
  ["Don't worry about the warnings", false],
  ['항상 그랬잖아', false],
  ['제가 대신 할게요', false],
  ['다음부터 이렇게 할까?', false],
  ['looks good, ship it', false],
];
for (const [text, want] of correctionCases) {
  check(`correction ${JSON.stringify(text)} -> ${want}`, review.isCorrection(text) === want);
}
check('"always" inside a code block is not a correction', review.correctionText('Run this:\n```\n# always run tests\n```') === null);
check('"never" inside inline code is not a correction', review.correctionText('the flag is `--never-fail`, check it') === null);
check('quoted line is not a correction', review.correctionText('> Always use tabs\nthat is what the doc says') === null);
check('slash command is not a correction', review.correctionText('/review never skip tests') === null);
check('task notification is not a correction', review.correctionText('<task-notification>Always ...</task-notification>') === null);
check('a long pasted brief is not a correction', review.correctionText(`Always do X. ${'context '.repeat(300)}`) === null);
check('correcting sentences are kept, others dropped',
  review.correctionText('Nice work. Don\'t use emojis in commit messages. Thanks') === "Don't use emojis in commit messages.");
check('correction text capped at 200 chars', review.correctionText(`Always ${'x'.repeat(400)}`).length === 200);

// ---------------------------------------------------------------- transcript scan

{
  const timeline = review.readTimeline(writeTranscript([
    userLine('Always use the executor for this. Build the report.'),
    assistantLine([{ name: 'Agent', input: { subagent_type: 'executor', prompt: 'x' } }]),
    toolResultLine('Always remember: results here'),
    assistantLine([]),
    userLine('표는 항상 한국어로 작성해줘, 영어 헤더 쓰지 마'),
    assistantLine([{ name: 'Skill', input: { skill: 'learned-investigate-then-debugger' } }]),
    userLine('what does it do?'),
    userLine('<command-name>/clear</command-name>'),
  ]));
  const scan = review.scanTimeline(timeline);
  check('first prompt of the session is never a correction', scan.rules.length === 1, JSON.stringify(scan.rules));
  check('tool results are not user messages', !scan.rules.some((r) => r.text.includes('remember')));
  check('context = the agent that ran just before', scan.rules[0] && scan.rules[0].context && scan.rules[0].context.id === 'executor' && scan.rules[0].context.kind === 'agent');
  check('Skill use of a learned skill is recorded', scan.skillUses.length === 1 && scan.skillUses[0] === 'learned-investigate-then-debugger');
}

{
  const picked = review.pickRules([
    { text: '수정은 하지마' },
    { text: '앞으로 표는 한국어로 써줘' },
    { text: '멈추지 말고 진행해' },
    { text: '멈추지 말고 진행해!' },
  ]).map((r) => r.text);
  check('per session: at most 2 rules, standing phrasing first, then latest, deduped',
    picked.length === 2 && picked[0] === '앞으로 표는 한국어로 써줘' && picked[1] === '멈추지 말고 진행해!', picked.join(' | '));
}

// ---------------------------------------------------------------- review hook (spawned)

{
  const HOME = newHome();
  const transcript = writeTranscript([
    userLine('Summarize the release notes'),
    assistantLine([{ name: 'Agent', input: { subagent_type: 'executor' } }]),
    userLine('표는 항상 한국어로 작성해줘, 영어 헤더 쓰지 마'),
  ]);
  const env = Object.assign({}, process.env, { HOME, USERPROFILE: HOME });
  const t0 = Date.now();
  const r = cp.spawnSync('node', [REVIEW], { env, encoding: 'utf8', input: JSON.stringify({ hook_event_name: 'SessionEnd', session_id: 'sess-a', transcript_path: transcript, reason: 'prompt_input_exit' }) });
  const ms = Date.now() - t0;
  check('learning-review.js exits 0 and prints nothing', r.status === 0 && r.stdout === '' && r.stderr === '', `stdout=${JSON.stringify(r.stdout)} stderr=${r.stderr}`);
  check('learning-review.js runs under 300 ms (process start included)', ms < 300, `${ms} ms`);
  const rows = store.readSuggestions(HOME);
  check('rule suggestion queued from the correction', rows.length === 1 && rows[0].kind === 'rule' && rows[0].status === 'pending'
    && rows[0].text === '표는 항상 한국어로 작성해줘, 영어 헤더 쓰지 마' && rows[0].context.id === 'executor' && rows[0].scope === 'global' && rows[0].session === 'sess-a', JSON.stringify(rows));
  check('nothing written to rules/ or skills/ before approval',
    !fs.existsSync(path.join(HOME, '.claude', 'rules')) && !fs.existsSync(path.join(HOME, '.claude', 'skills')));
  const bad = cp.spawnSync('node', [REVIEW], { env, encoding: 'utf8', input: 'not json' });
  check('malformed payload -> silent exit 0', bad.status === 0 && bad.stdout === '');
  const missing = cp.spawnSync('node', [REVIEW], { env, encoding: 'utf8', input: JSON.stringify({ transcript_path: path.join(ROOT, 'nope.jsonl') }) });
  check('missing transcript -> silent exit 0', missing.status === 0 && missing.stdout === '');
}

// ---------------------------------------------------------------- workflow detection

function ev(session, id, kind, verdict, daysAgo, minute, intent) {
  return { ts: new Date(NOW - daysAgo * DAY + minute * 60000).toISOString(), harness: 'claude', session, kind, id, intent: intent || 'Debug', verdict, signal: 'reply', evidence: 'x' };
}
function chainSessions(n, daysAgo) {
  const out = [];
  for (let i = 0; i < n; i++) {
    out.push(ev(`w${i}`, 'investigate', 'skill', 'accept', daysAgo || 1, 0));
    out.push(ev(`w${i}`, 'debugger', 'agent', 'accept', daysAgo || 1, 1));
  }
  return out;
}
{
  const three = review.workflowCandidates(chainSessions(3), NOW);
  check('chain accepted in 3 sessions -> skill suggestion', three.length === 1 && three[0].name === 'learned-investigate-then-debugger'
    && three[0].steps.map((s) => `${s.kind}:${s.id}`).join(',') === 'skill:investigate,agent:debugger'
    && three[0].intents[0] === 'Debug' && three[0].evidence.length === 3, JSON.stringify(three));
  check('chain accepted in 2 sessions -> nothing', review.workflowCandidates(chainSessions(2), NOW).length === 0);
  check('sessions older than 30 days do not count', review.workflowCandidates([...chainSessions(2), ...chainSessions(1, 40).map((e) => Object.assign({}, e, { session: 'old' }))], NOW).length === 0);
  const broken = chainSessions(3).flatMap((e) => (e.id === 'debugger' ? [ev(e.session, 'executor', 'agent', 'reject', 1, 0.5), e] : [e]));
  check('a reject between the two breaks the chain', review.workflowCandidates(broken, NOW).length === 0);
  const longer = [];
  for (let i = 0; i < 3; i++) {
    longer.push(ev(`x${i}`, 'investigate', 'skill', 'accept', 1, 0), ev(`x${i}`, 'debugger', 'agent', 'accept', 1, 1), ev(`x${i}`, 'test-engineer', 'agent', 'accept', 1, 2));
  }
  const l = review.workflowCandidates(longer, NOW);
  check('sub-chains of a qualifying longer chain are dropped', l.length === 1 && l[0].steps.length === 3, JSON.stringify(l.map((c) => c.name)));
  const otherHarness = chainSessions(3).map((e) => Object.assign({}, e, { harness: 'codex' }));
  check('other harnesses’ events are not Claude workflows', review.workflowCandidates(otherHarness, NOW).length === 0);
}

// ---------------------------------------------------------------- dedupe + cap

{
  const HOME = newHome();
  const rule = (text) => ({ kind: 'rule', text, context: null, scope: 'global', evidence: ['s'] });
  review.queueSuggestions(HOME, [rule("Don't use tables.")], NOW, 's1');
  review.queueSuggestions(HOME, [rule("don't use TABLES")], NOW, 's2');
  check('dedupe: same normalized text queued once', store.readSuggestions(HOME).length === 1);
  runCli(HOME, ['dismiss', 'L1']);
  review.queueSuggestions(HOME, [rule("Don't use tables!")], NOW, 's3');
  check('dismissed key is never re-queued', store.readSuggestions(HOME).length === 1 && store.readSuggestions(HOME)[0].status === 'dismissed');
  review.queueSuggestions(HOME, ['Always a', 'Always b', 'Always c', 'Always d', 'Always e', 'Always f', 'Always g'].map(rule), NOW, 's4');
  const pending = store.readSuggestions(HOME).filter((s) => s.status === 'pending');
  const refused = store.readAudit(HOME).filter((r) => r.action === 'cap_refused');
  check('cap: at most 5 pending', pending.length === 5, `${pending.length}`);
  check('cap: refusals audited as cap_refused', refused.length === 2 && refused.every((r) => r.key && r.reason), JSON.stringify(refused));
  review.queueSuggestions(HOME, ['Always f', 'Always g'].map(rule), NOW, 's5');
  check('cap: a key refused before is not re-audited', store.readAudit(HOME).filter((r) => r.action === 'cap_refused').length === 2);
  check('every queued suggestion is audited', store.readAudit(HOME).filter((r) => r.action === 'suggest').length === 6);
}

// ---------------------------------------------------------------- approve rule + skill, registry

{
  const HOME = newHome();
  const PROJECT = path.join(ROOT, 'project');
  fs.mkdirSync(PROJECT, { recursive: true });
  review.queueSuggestions(HOME, [{ kind: 'rule', text: '표는 항상 한국어로 작성해줘, 영어 헤더 쓰지 마', context: { kind: 'agent', id: 'executor' }, scope: 'global', evidence: ['sess-a'] }], NOW, 'sess-a');
  const a = runCli(HOME, ['approve', 'L1', '--as', 'Write tables in Korean, with no English headers.']);
  const ruleFile = path.join(HOME, '.claude', 'rules', 'user', 'learned-write-tables-in-korean-with-no-english.md');
  const ruleText = fs.existsSync(ruleFile) ? fs.readFileSync(ruleFile, 'utf8') : '';
  check('approve rule -> rules/user/learned-<slug>.md', a.code === 0 && ruleText !== '', a.out);
  const fm = reg.parseFrontmatter(ruleText) || {};
  check('rule frontmatter: date, source, suggestion, evidence; no paths (global)', fm.source === 'learning-loop' && fm.suggestion === 'L1' && /^\d{4}-\d{2}-\d{2}$/.test(fm.date) && fm.evidence === '["sess-a"]' && !('paths' in fm), JSON.stringify(fm));
  check('rule body: imperative English + original sentence quoted', ruleText.includes('- Write tables in Korean, with no English headers.') && ruleText.includes('> 표는 항상 한국어로 작성해줘, 영어 헤더 쓰지 마') && ruleText.includes('`executor`'));
  check('approved suggestion marked approved', store.readSuggestions(HOME)[0].status === 'approved');
  const approveAudit = store.readAudit(HOME).find((r) => r.action === 'approve');
  check('approve audited with before/after paths', approveAudit && approveAudit.before.path === null && approveAudit.after.path === ruleFile);
  check('approving twice is refused', runCli(HOME, ['approve', 'L1']).code === 1);

  review.queueSuggestions(HOME, [{ kind: 'rule', text: '항상 존댓말로 답해줘', context: null, scope: 'global', evidence: ['s'] }], NOW, 's');
  runCli(HOME, ['approve', 'L2']);
  check('Korean-only rule without --as gets a stable slug', fs.existsSync(path.join(HOME, '.claude', 'rules', 'user', 'learned-rule-l2.md')));

  review.queueSuggestions(HOME, review.workflowCandidates(chainSessions(3), NOW), NOW, 's');
  const b = runCli(HOME, ['approve', 'L3']);
  const skillFile = path.join(HOME, '.claude', 'skills', 'learned-investigate-then-debugger', 'SKILL.md');
  const skillText = fs.existsSync(skillFile) ? fs.readFileSync(skillFile, 'utf8') : '';
  const sfm = reg.parseFrontmatter(skillText) || {};
  check('approve skill -> skills/learned-<slug>/SKILL.md', b.code === 0 && sfm.name === 'learned-investigate-then-debugger', b.out);
  check('skill description names the intent and its keywords', /Debug/.test(sfm.description) && /debug, root cause/.test(sfm.description), sfm.description);
  check('skill body is an ordered procedure', skillText.includes('1. Use the `investigate` skill') && skillText.includes('2. Use the `debugger` agent') && skillText.includes('## Provenance'));
  const registry = reg.buildRegistry({ home: HOME, cwd: PROJECT, out: path.join(ROOT, 'reg.json') });
  const inReg = registry.skills.find((s) => s.id === 'learned-investigate-then-debugger');
  check('registry picks the learned skill up with its description', inReg && inReg.description.startsWith('Learned Debug workflow'), JSON.stringify(inReg));
  const debug = registry.intents.find((i) => i.name === 'Debug').candidates.map((c) => c.id);
  check('registry classifies the learned skill under its intent', debug.includes('learned-investigate-then-debugger'), debug.join(','));

  const list = runCli(HOME, ['list']);
  check('learn list shows learned items', list.out.includes('learned-investigate-then-debugger') && list.out.includes('3/20 live'), list.out);
  check('learn show <id> prints the suggestion', JSON.parse(runCli(HOME, ['show', 'L3']).out).kind === 'skill');
}

// ---------------------------------------------------------------- cap 20

{
  const HOME = newHome();
  const state = { items: {}, last_curate_at: null };
  for (let i = 0; i < 20; i++) {
    const p = path.join(HOME, '.claude', 'rules', 'user', `learned-r${i}.md`);
    store.writeAtomic(p, '# r\n');
    state.items[`learned-r${i}`] = { slug: `learned-r${i}`, kind: 'rule', status: i % 2 ? 'stale' : 'active', path: p, approved_at: new Date(NOW).toISOString(), harness: 'claude' };
  }
  store.writeState(HOME, state);
  review.queueSuggestions(HOME, [{ kind: 'rule', text: 'Always one more', context: null, scope: 'global', evidence: [] }], NOW, 's');
  const r = runCli(HOME, ['approve', 'L1']);
  check('approve beyond 20 live items is refused', r.code === 1 && /curate/.test(r.out) && store.readSuggestions(HOME)[0].status === 'pending', r.out);
  check('cap-20 refusal audited', store.readAudit(HOME).some((a) => a.action === 'cap_refused' && a.suggestion === 'L1'));
  check('no file written on refusal', fs.readdirSync(path.join(HOME, '.claude', 'rules', 'user')).length === 20);
}

// ---------------------------------------------------------------- curate + pin + rollback

{
  const HOME = newHome();
  const rule = (text) => ({ kind: 'rule', text, context: null, scope: 'global', evidence: [] });
  review.queueSuggestions(HOME, [rule('Always alpha'), rule('Always beta'), rule('Always gamma')], NOW, 's');
  runCli(HOME, ['approve', 'L1']);
  runCli(HOME, ['approve', 'L2']);
  runCli(HOME, ['approve', 'L3']);
  const slugs = Object.keys(store.readState(HOME).items).sort();
  check('three rules approved', slugs.join(',') === 'learned-always-alpha,learned-always-beta,learned-always-gamma', slugs.join(','));
  check('pin <slug>', runCli(HOME, ['pin', 'learned-always-gamma']).code === 0 && store.readState(HOME).items['learned-always-gamma'].pinned === true);

  const dry = runCli(HOME, ['curate', '--dry-run'], NOW + 31 * DAY);
  check('curate --dry-run reports but changes nothing', /Would change/.test(dry.out) && store.readState(HOME).items['learned-always-alpha'].status === 'active', dry.out);
  // A recorded use (the same correction again) keeps beta fresh.
  const beta = store.readState(HOME);
  store.writeState(HOME, Object.assign({}, beta, { items: Object.assign({}, beta.items, { 'learned-always-beta': Object.assign({}, beta.items['learned-always-beta'], { last_used_at: new Date(NOW + 20 * DAY).toISOString() }) }) }));
  runCli(HOME, ['curate'], NOW + 31 * DAY);
  let st = store.readState(HOME).items;
  check('curate: 31 days unused -> stale', st['learned-always-alpha'].status === 'stale');
  check('curate: recently used -> stays active', st['learned-always-beta'].status === 'active');
  check('curate: pinned -> exempt', st['learned-always-gamma'].status === 'active');

  const alphaPath = st['learned-always-alpha'].path;
  const out100 = runCli(HOME, ['curate'], NOW + 100 * DAY);
  st = store.readState(HOME).items;
  check('curate: 100 days unused -> archived (moved, not deleted)', st['learned-always-alpha'].status === 'archived' && !fs.existsSync(alphaPath)
    && fs.existsSync(st['learned-always-alpha'].archived_path) && st['learned-always-alpha'].archived_path.startsWith(store.learningPaths(HOME).archive), out100.out);
  check('curate: pinned still exempt at 100 days', st['learned-always-gamma'].status === 'active' && fs.existsSync(st['learned-always-gamma'].path));

  const archiveRow = store.readAudit(HOME).filter((r) => r.action === 'archive' && r.slug === 'learned-always-alpha').pop();
  const rb = runCli(HOME, ['rollback', archiveRow.id], NOW + 100 * DAY);
  st = store.readState(HOME).items;
  check('rollback archive -> file back in place, status restored', rb.code === 0 && fs.existsSync(alphaPath) && st['learned-always-alpha'].status === 'stale', rb.out);
  check('rolling back the same mutation twice is refused', runCli(HOME, ['rollback', archiveRow.id]).code === 1);
  const refusedRow = { id: 'nope' };
  check('unknown audit id is refused', runCli(HOME, ['rollback', refusedRow.id]).code === 1);

  const approveRow = store.readAudit(HOME).find((r) => r.action === 'approve' && r.suggestion === 'L2');
  const betaPath = approveRow.after.path;
  const blocked = runCli(HOME, ['rollback', approveRow.id]);
  const staleRow = store.readAudit(HOME).find((r) => r.action === 'stale' && r.slug === 'learned-always-beta');
  check('rollback is last-in-first-out per item: a later mutation must go first', blocked.code === 1 && blocked.out.includes(`roll back ${staleRow.id}`) && fs.existsSync(betaPath), blocked.out);
  check('rollback stale -> active', runCli(HOME, ['rollback', staleRow.id]).code === 0 && store.readState(HOME).items['learned-always-beta'].status === 'active');
  const rb2 = runCli(HOME, ['rollback', approveRow.id]);
  check('rollback approve -> file moved to the archive, suggestion pending again', rb2.code === 0 && !fs.existsSync(betaPath)
    && !store.readState(HOME).items['learned-always-beta'] && store.readSuggestions(HOME).find((s) => s.id === 'L2').status === 'pending', rb2.out);
  const archived = fs.readdirSync(store.learningPaths(HOME).archive, { recursive: true }).filter((f) => String(f).endsWith('learned-always-beta.md'));
  check('rolled-back approval kept in learned-archive/', archived.length === 1);

  const pinRow = store.readAudit(HOME).find((r) => r.action === 'pin');
  runCli(HOME, ['rollback', pinRow.id]);
  check('rollback pin -> unpinned', store.readState(HOME).items['learned-always-gamma'].pinned === false);

  review.queueSuggestions(HOME, [rule('Always delta')], NOW, 's');
  const dismissOut = runCli(HOME, ['dismiss', 'L4']).out;
  const dismissId = /audit (A\d+)/.exec(dismissOut)[1];
  runCli(HOME, ['rollback', dismissId]);
  check('rollback dismiss -> pending again', store.readSuggestions(HOME).find((s) => s.id === 'L4').status === 'pending');
  const suggestRow = store.readAudit(HOME).find((r) => r.action === 'suggest');
  check('a suggest row is not rollback-able (dismiss instead)', runCli(HOME, ['rollback', suggestRow.id]).code === 1);
  check('every rollback is itself audited', store.readAudit(HOME).filter((r) => r.action === 'rollback').length === 5);
}

{
  // An archived item keeps its slug: a later approval with the same wording
  // gets its own slug, and rolling back the old approval never touches it.
  const HOME = newHome();
  const rule = (text) => ({ kind: 'rule', text, context: null, scope: 'global', evidence: [] });
  review.queueSuggestions(HOME, [rule('Always zeta')], NOW, 's');
  runCli(HOME, ['approve', 'L1']);
  runCli(HOME, ['curate'], NOW + 100 * DAY);
  review.queueSuggestions(HOME, [rule('Always zeta!!')], NOW, 's');
  const second = store.readSuggestions(HOME).find((s) => s.id === 'L2');
  check('an approved key stays deduped after its item is archived', !second);
  review.queueSuggestions(HOME, [rule('Always zeta, please')], NOW, 's');
  runCli(HOME, ['approve', 'L2', '--as', 'Always zeta']);
  const items = store.readState(HOME).items;
  check('slug held by an archived item is not reused', items['learned-always-zeta'].status === 'archived' && items['learned-always-zeta-2'] && items['learned-always-zeta-2'].status === 'active', Object.keys(items).join(','));
  const firstApprove = store.readAudit(HOME).find((r) => r.action === 'approve' && r.suggestion === 'L1');
  const r = runCli(HOME, ['rollback', firstApprove.id]);
  check('rolling back the old approval leaves the newer item alone', r.code === 1 && fs.existsSync(items['learned-always-zeta-2'].path) && store.readState(HOME).items['learned-always-zeta-2'].status === 'active', r.out);
}

// ---------------------------------------------------------------- SessionStart surfacing

{
  const HOME = newHome();
  const rule = (text) => ({ kind: 'rule', text, context: null, scope: 'global', evidence: [] });
  check('no pending -> session-start prints nothing', runCli(HOME, ['session-start']).out === '');
  review.queueSuggestions(HOME, [rule('Always one'), rule('Always two'), rule('Always three')], NOW, 's');
  const out = runCli(HOME, ['session-start']).out.trim().split('\n');
  check('session-start: at most 2 [Learn] lines', out.length === 2 && out.every((l) => l.startsWith('[Learn] L')), out.join(' | '));
  check('[Learn] line carries approve and dismiss commands', out[0].includes('persona-rule.js learn approve L1') && out[0].includes('persona-rule.js learn dismiss L1'));
  check('[Learn] line notes the rest', out[1].includes('+1 more'));
  const st = store.readState(HOME);
  check('session-start ran the weekly curate', !!st.last_curate_at);
  store.writeState(HOME, Object.assign({}, st, { last_curate_at: new Date(NOW - 3 * DAY).toISOString() }));
  runCli(HOME, ['session-start']);
  check('weekly curate skipped within 7 days', store.readState(HOME).last_curate_at === new Date(NOW - 3 * DAY).toISOString());

  // Through the real session-start.sh, with network installs stubbed.
  const PROJECT = fs.mkdtempSync(path.join(ROOT, 'proj-'));
  const stubBin = fs.mkdtempSync(path.join(ROOT, 'bin-'));
  for (const tool of ['omc', 'oh-my-opencode', 'ast-grep']) fs.writeFileSync(path.join(stubBin, tool), '#!/bin/sh\nexit 0\n', { mode: 0o755 });
  fs.writeFileSync(path.join(stubBin, 'npm'), '#!/bin/sh\nexit 1\n', { mode: 0o755 });
  fs.mkdirSync(path.join(HOME, '.claude', 'skills', 'pdf'), { recursive: true });
  const env = Object.assign({}, process.env, { HOME, USERPROFILE: HOME, PATH: `${stubBin}${path.delimiter}${process.env.PATH}` });
  const r = cp.spawnSync('bash', [path.join(HOOKS, 'session-start.sh')], { cwd: PROJECT, env, encoding: 'utf8' });
  const lines = r.stdout.trim().split('\n').filter(Boolean);
  let ctx = '';
  try { ctx = JSON.parse(r.stdout).hookSpecificOutput.additionalContext; } catch { /* checked below */ }
  check('session-start.sh stays exactly one JSON document', lines.length === 1 && ctx !== '', r.stdout.slice(0, 200));
  const learnLines = ctx.split('\n').filter((l) => l.startsWith('[Learn]'));
  check('session-start.sh injects <= 2 [Learn] lines', learnLines.length === 2, learnLines.join(' | '));
}

// ---------------------------------------------------------------- CLI entry + hook registration

{
  const HOME = newHome();
  const env = Object.assign({}, process.env, { HOME, USERPROFILE: HOME });
  const r = cp.spawnSync('node', [PERSONA, 'learn', 'list'], { cwd: ROOT, env, encoding: 'utf8' });
  check('persona-rule.js learn list works without a .briefing vault', r.status === 0 && r.stdout.includes('No pending suggestions.'), r.stdout);
  const u = cp.spawnSync('node', [PERSONA, 'learn', 'bogus'], { cwd: ROOT, env, encoding: 'utf8' });
  check('unknown learn command -> usage, exit 1', u.status === 1 && u.stdout.includes('Usage'));
  const hooksJson = JSON.parse(fs.readFileSync(path.join(HOOKS, 'hooks.json'), 'utf8')).hooks;
  check('learning-review.js registered on SessionEnd', (hooksJson.SessionEnd || []).some((g) => g.hooks.some((h) => h.command === 'node "$HOME/.claude/hooks/learning-review.js"')));
  const installSh = fs.readFileSync(path.join(REPO_ROOT, 'install.sh'), 'utf8');
  check('install.sh copies and manifests the learning hooks', ['learning-store.js', 'learning-cli.js', 'learning-review.js'].every((f) => installSh.includes(`hooks/${f}"`) && new RegExp(`for f in [^\\n]*${f}`).test(installSh)));
}

check('nothing was written to the real home', !fs.existsSync(path.join(os.homedir(), '.config', 'agent-harness', 'learning-audit.jsonl'))
  || fs.statSync(path.join(os.homedir(), '.config', 'agent-harness', 'learning-audit.jsonl')).mtimeMs < NOW - 1000);

fs.rmSync(ROOT, { recursive: true, force: true });

const failed = results.filter((ok) => !ok).length;
console.log(failed ? `${failed} FAILED` : 'ALL PASSED');
process.exit(failed ? 1 : 0);
