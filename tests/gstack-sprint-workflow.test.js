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
const PHASE1_SHA256 = 'f437128dad52c3ba7d5ee04fe75d733fd7d1b539da0fc06dd88812125f7f2f3c';

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
  .filter((line) => line.includes('/plan-eng-review') && /\b(mandatory|required)\b/i.test(line));
check('A2 no SKILL.md or Boss sprint line makes /plan-eng-review mandatory or required',
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

const bossMissing = missing(bossSprint, ['writing-plans', 'momus', '.briefing/plans/', 'one AskUserQuestion']);
check('A6 Boss sprint section names writing-plans, momus, .briefing/plans/ and "one AskUserQuestion"', bossMissing.length === 0,
  bossMissing.length ? `missing: ${bossMissing.join(', ')}` : '');

check('C1 Phase 2 still names oh-my-claudecode:ralph', phase2.includes('oh-my-claudecode:ralph'));

console.log(failed ? `${failed} FAILED` : 'ALL PASSED');
process.exit(failed ? 1 : 0);
