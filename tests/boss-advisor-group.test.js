#!/usr/bin/env node
// Guards the Boss / Advisor Group model split: Boss runs on Opus, the three
// read-only advisors run on Fable, and boss.md keeps the routing rules that
// tie them together. `node tests/boss-advisor-group.test.js`
'use strict';
const fs = require('fs'), path = require('path');
const ROOT = path.resolve(__dirname, '..');
const read = (rel) => fs.readFileSync(path.join(ROOT, rel), 'utf8');
const modelOf = (rel) => (read(rel).match(/^model:\s*(\S+)\s*$/m) || [])[1];

let failed = 0;
function check(name, ok, got) {
  if (!ok) failed++;
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${got === undefined ? '' : `  (got ${JSON.stringify(got)})`}`);
}

check('boss.md model is claude-opus-5-5', modelOf('agents/core/boss.md') === 'claude-opus-5-5', modelOf('agents/core/boss.md'));
for (const advisor of ['oracle', 'metis', 'momus']) {
  const rel = `agents/omo/${advisor}.md`;
  check(`${advisor}.md model is claude-fable-5-1`, modelOf(rel) === 'claude-fable-5-1', modelOf(rel));
}

const boss = read('agents/core/boss.md');
const section = (boss.split(/^## ADVISOR GROUP.*$/m)[1] || '').split(/^---$/m)[0];
check('boss.md has an ADVISOR GROUP section', section.trim().length > 0);
for (const advisor of ['oracle', 'metis', 'momus']) {
  check(`Advisor Group table names ${advisor}`, new RegExp(`^\\| \`${advisor}\` \\|`, 'm').test(section));
}
check('Advisor Group states the 429 fallback', /429/.test(section) && /retry that same advisor ONCE with `model: "opus"`/.test(section));

const phase0 = (boss.split(/^## PHASE 0:.*$/m)[1] || '').split(/^## /m)[0];
check('Phase 0 uses [Routing] and [RouteHint] as the primary source', phase0.includes('[Routing]') && phase0.includes('[RouteHint]'));

console.log(failed ? `${failed} FAILED` : 'ALL PASSED');
process.exit(failed ? 1 : 0);
