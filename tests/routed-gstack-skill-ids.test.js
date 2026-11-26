#!/usr/bin/env node
// Every routed id that names a gstack skill directory must equal that skill's
// frontmatter `name` at the pinned upstream/gstack — Claude Code (and
// hooks/build-registry.js) expose a skill by frontmatter name, not directory.
// It also fails — never skips — when the pinned gstack no longer ships a skill
// that GSTACK_SKILL_ALLOWLIST installs or hooks/routing-map.json routes to
// (e.g. upstream removed /cso), so a bump that drops one cannot auto-merge.
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
  console.error('FAIL  upstream/gstack submodule not initialised or incomplete (git submodule update --init upstream/gstack)');
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

const sh = fs.readFileSync(path.join(ROOT, 'scripts', 'skill-allowlists.sh'), 'utf8');
const block = /^GSTACK_SKILL_ALLOWLIST="([^"]*)"/m.exec(sh);
const allowlist = block ? block[1].split(/\s+/).filter(Boolean) : [];

let failed = 0, checked = 0;
if (!allowlist.length) { console.log('FAIL  GSTACK_SKILL_ALLOWLIST not found in scripts/skill-allowlists.sh'); failed++; }
for (const name of allowlist) {
  if (!fs.existsSync(path.join(GSTACK, name, 'SKILL.md'))) {
    console.log(`FAIL  GSTACK_SKILL_ALLOWLIST: "${name}" has no upstream/gstack/${name}/SKILL.md at the pinned commit`);
    failed++;
  }
}
const allowed = new Set(allowlist);
for (const intent of map.intents) {
  for (const m of intent.members) {
    const id = typeof m === 'string' ? m : m.name;
    if (byDir.has(id) && byDir.get(id) !== id) {
      console.log(`FAIL  ${intent.name}: routed "${id}" but upstream/gstack/${id}/SKILL.md name is "${byDir.get(id)}"`);
      failed++;
    } else if (!byName.has(id) && (allowed.has(id) || (id.startsWith('gstack-') && allowed.has(id.slice(7))))) {
      console.log(`FAIL  ${intent.name}: routed gstack skill "${id}" resolves to no upstream/gstack directory or frontmatter name`);
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
