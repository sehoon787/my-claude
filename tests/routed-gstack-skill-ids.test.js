#!/usr/bin/env node
// Every routed id that names a gstack skill directory must equal that skill's
// frontmatter `name` at the pinned upstream/gstack — Claude Code (and
// hooks/build-registry.js) expose a skill by frontmatter name, not directory.
// `node tests/routed-gstack-skill-ids.test.js`
'use strict';
const fs = require('fs'), path = require('path');

const ROOT = path.resolve(__dirname, '..');
const GSTACK = path.join(ROOT, 'upstream', 'gstack');
const map = JSON.parse(fs.readFileSync(path.join(ROOT, 'hooks', 'routing-map.json'), 'utf8'));

function frontmatterName(file) {
  const m = /^---\r?\n([\s\S]*?)\r?\n---/.exec(fs.readFileSync(file, 'utf8'));
  const n = m && /^name:\s*["']?([^"'\r\n]+?)["']?\s*$/m.exec(m[1]);
  return n ? n[1] : null;
}

if (!fs.existsSync(path.join(GSTACK, 'ship', 'SKILL.md'))) {
  console.error('FAIL  upstream/gstack not initialised (git submodule update --init upstream/gstack)');
  process.exit(1);
}

const byName = new Map(); // frontmatter name -> dir
const byDir = new Map(); // dir -> frontmatter name
for (const dir of fs.readdirSync(GSTACK)) {
  const f = path.join(GSTACK, dir, 'SKILL.md');
  if (!fs.existsSync(f)) continue;
  const name = frontmatterName(f);
  if (!name) continue;
  byDir.set(dir, name);
  byName.set(name, dir);
}

let failed = 0, checked = 0;
for (const intent of map.intents) {
  for (const m of intent.members) {
    const id = typeof m === 'string' ? m : m.name;
    if (byDir.has(id) && byDir.get(id) !== id) {
      console.log(`FAIL  ${intent.name}: routed "${id}" but upstream/gstack/${id}/SKILL.md name is "${byDir.get(id)}"`);
      failed++;
    } else if (byName.has(id)) {
      console.log(`PASS  ${intent.name}: ${id}`);
      checked++;
    }
  }
}
if (!checked) { console.log('FAIL  no routed gstack skill ids found'); failed++; }
console.log(failed ? `${failed} failed` : `ok: ${checked} routed gstack skill ids match frontmatter names`);
process.exit(failed ? 1 : 0);
