#!/usr/bin/env node
// Guards the gstack-sprint planning phase: Phase 1 runs recall, clarify,
// writing-plans, a momus review and one approval gate; /plan-eng-review is
// optional; Phase 2 stays on ralph; Boss's sprint summary follows the same
// flow. The Phase 1 block is shared with the my-codex repo byte for byte, so
// its sha256 is pinned here and in my-codex's copy of this test.
// `node tests/gstack-sprint-workflow.test.js`
'use strict';
const crypto = require('crypto'), fs = require('fs'), path = require('path');
const ROOT = path.resolve(__dirname, '..');
const read = (rel) => fs.readFileSync(path.join(ROOT, rel), 'utf8').replace(/\r\n/g, '\n');

// sha256 of the Phase 1 block as phaseBlock() returns it.
const PHASE1_SHA256 = '74d3682ecb29a2098dcee36552e4408004969eaaf3b272d543f246cb8b9c0df7';
// Boss's Phase 1 bullets, also byte-identical in my-codex's codex-agents/core/boss.toml.
const BOSS_PHASE1_BULLETS = [
  '- Recall: search `.briefing/decisions/`, `.briefing/learnings/` and `.briefing/plans/` for related notes.',
  '- Clarify only when the request is ambiguous: `metis`, then at most two questions in one AskUserQuestion.',
  '- Plan: `writing-plans` saves a task plan to `.briefing/plans/YYYY-MM-DD-<topic>.md` and asks no review or execution question.',
  '- Plan review: `momus`, at most two rounds; the verdict is appended to the plan.',
  '- Approval gate: exactly one AskUserQuestion (approve / revise / stop); Phase 2 starts only on approve, unless the user already said the design is done.',
  '- `/plan-ceo-review`, `/plan-eng-review` and `/autoplan` are optional extra reviews, run only on request.',
];
// What Phase 3 reloads, in lookup order: plan file, gstack design doc, original request.
const PHASE3_ORDER = ['.briefing/plans/', '~/.gstack/projects/', 'the original request'];

let failed = 0;
function check(name, ok, detail) {
  if (!ok) failed++;
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? '  (' + detail + ')' : ''}`);
}

// Lines from the first one that starts with `start` up to, not including, the
// next one `isEnd` accepts (or the end of the text); '' when `start` is absent.
function section(text, start, isEnd) {
  const lines = text.split('\n');
  const from = lines.findIndex((line) => line.startsWith(start));
  if (from === -1) return '';
  const to = lines.findIndex((line, i) => i > from && isEnd(line));
  return lines.slice(from, to === -1 ? lines.length : to).join('\n');
}
// A SKILL.md phase runs from its heading to the next line that is exactly `---`.
const phaseBlock = (text, heading) => section(text, heading, (line) => line === '---').trimEnd() + '\n';
const missing = (text, terms) => terms.filter((term) => !text.includes(term));

const skill = read('skills/core/gstack-sprint/SKILL.md');
const phase1 = phaseBlock(skill, '## Phase 1:');
const phase2 = phaseBlock(skill, '## Phase 2:');
const bossSprint = section(read('agents/core/boss.md'), '### gstack 3-Phase Sprint Workflow', (line) => line.startsWith('### '));

check('A1 SKILL.md never says "mandatory for all scales"', !skill.includes('mandatory for all scales'));

const engReviewRequired = [skill, bossSprint].flatMap((text) => text.split('\n'))
  .filter((line) => line.includes('/plan-eng-review') && /\b(mandatory|required|always|must)\b/i.test(line));
check('A2 no SKILL.md or Boss sprint line makes /plan-eng-review mandatory, required, always or must',
  engReviewRequired.length === 0, engReviewRequired.map((line) => line.trim()).join(' | '));

const phase1Missing = missing(phase1, ['writing-plans', 'momus', '.briefing/plans/']);
check('A3 Phase 1 names writing-plans, momus and .briefing/plans/', phase1Missing.length === 0,
  phase1Missing.length ? `missing: ${phase1Missing.join(', ')}` : '');

const gates = phase1.split('APPROVAL GATE').length - 1;
const perAmbiguity = phase1.includes('for each ambiguity');
check('A4 Phase 1 has exactly one APPROVAL GATE and no "for each ambiguity"', gates === 1 && !perAmbiguity,
  gates === 1 && !perAmbiguity ? '' : `APPROVAL GATE x${gates}${perAmbiguity ? ', has "for each ambiguity"' : ''}`);

const phase1Sha = crypto.createHash('sha256').update(phase1).digest('hex');
check('A5 Phase 1 block sha256 equals PHASE1_SHA256', phase1Sha === PHASE1_SHA256,
  phase1Sha === PHASE1_SHA256 ? phase1Sha : `got ${phase1Sha}. Phase 1 must stay identical in my-claude and my-codex: ` +
    "make the same change to the my-codex repo's skills/core/gstack-sprint/SKILL.md and update PHASE1_SHA256 in both repos' tests/gstack-sprint-workflow.test.js");

// The bullets are the consecutive "- " lines right after the Phase 1 label line.
const bossLines = bossSprint.split('\n');
const labelAt = bossLines.findIndex((line) => line.startsWith('**Phase 1:'));
const bullets = [];
for (let i = labelAt + 1; labelAt !== -1 && (bossLines[i] || '').startsWith('- '); i++) bullets.push(bossLines[i]);
const diffAt = [...BOSS_PHASE1_BULLETS, ...bullets].findIndex((_, i) => bullets[i] !== BOSS_PHASE1_BULLETS[i]);
check('A6 Boss Phase 1 bullets equal BOSS_PHASE1_BULLETS (same order, nothing extra, nothing missing)', diffAt === -1,
  diffAt === -1 ? '' : `bullet ${diffAt + 1}: expected ${JSON.stringify(BOSS_PHASE1_BULLETS[diffAt])}, got ${JSON.stringify(bullets[diffAt])}`);

const phase2Missing = missing(phase2, ['oh-my-claudecode:ralph', 'absolute path of the Phase 1 plan file', 'does not apply']);
check('C1 Phase 2 names oh-my-claudecode:ralph, the absolute plan path and that the plan header "does not apply"',
  phase2Missing.length === 0, phase2Missing.length ? `missing: ${phase2Missing.join(', ')}` : '');

// Phase 3 runs from its heading to the end of <Steps>.
const phase3 = section(skill, '## Phase 3:', (line) => line === '</Steps>');
const order = PHASE3_ORDER.map((term) => phase3.indexOf(term));
const inOrder = order.every((at, i) => at >= 0 && (i === 0 || at > order[i - 1]));
check('C2 Phase 3 lookup order: plan file, then gstack design doc, then the original request', inOrder,
  inOrder ? '' : `first indexes ${order.join(', ')}`);

console.log(failed ? `${failed} FAILED` : 'ALL PASSED');
process.exit(failed ? 1 : 0);
