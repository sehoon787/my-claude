#!/usr/bin/env node
// Unit tests for scripts/dedupe-karpathy.js — runs the script against fixture
// CLAUDE.md files. `node tests/dedupe-karpathy.test.js`
'use strict';
const fs = require('fs'), os = require('os'), path = require('path'), cp = require('child_process');
const SCRIPT = path.resolve(__dirname, '..', 'scripts', 'dedupe-karpathy.js');
const MARKER = '<!-- my-claude:karpathy-guidelines -->';

// The real upstream block (forrestchang/andrej-karpathy-skills @ aa4467f,
// sha256 694a2d72…e196a) — the exact text install.sh appends, so the fixtures
// exercise the same headings, internal '---' rules and '## ' sub-headings that
// tripped up the old content sniff.
const KARPATHY = `# CLAUDE.md

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
\`\`\`
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
\`\`\`

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.`;
// One real install also carries a copy titled '# Karpathy Guidelines'.
const KARPATHY_ALT = KARPATHY.replace('# CLAUDE.md', '# Karpathy Guidelines');

const OMC = ['<!-- OMC:START -->', '<!-- OMC:VERSION:4.8.2 -->', '', '# omc', '', 'Say "setup omc".', '<!-- OMC:END -->'].join('\n');
const COLAB = ['# Colab / GPU Usage Principles (GLOBAL — NON-NEGOTIABLE)', '', '1. **GPU = TRAINING ONLY.** Extract features locally.', '2. Terminate the runtime the moment GPU work ends.', '(User directive: GPU는 학습만; 미사용시 즉시 세션종료)'].join('\n');

function run(name, content, check) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'dk-'));
  const file = path.join(dir, 'CLAUDE.md');
  if (content !== null) fs.writeFileSync(file, content);
  const out = cp.spawnSync('node', [SCRIPT, file], { encoding: 'utf8' });
  const after = content !== null ? fs.readFileSync(file, 'utf8') : null;
  let ok = false, detail = '';
  try {
    detail = check({ after, before: content, stdout: out.stdout, status: out.status, stderr: out.stderr });
    ok = detail === true || detail === undefined;
  } catch (e) {
    detail = e.message;
  }
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${ok ? '' : '  → ' + detail}`);
  fs.rmSync(dir, { recursive: true, force: true });
  return ok;
}

const countBlocks = (s) => (s.match(/^Behavioral guidelines to reduce/gm) || []).length;
const assert = (cond, msg) => { if (!cond) throw new Error(msg); };

// (a) The shape observed on a real machine: OMC section, one unmarked
// '# Karpathy Guidelines' copy, several unmarked '# CLAUDE.md' copies butted
// together, a user section wedged between copies, then the marked copy.
const REAL_SHAPE = [
  OMC,
  '',
  '<!-- User customizations -->',
  [KARPATHY_ALT, KARPATHY, KARPATHY, KARPATHY].join('\n'),
  '',
  '---',
  '',
  COLAB,
  '',
  KARPATHY,
  '',
  MARKER,
  '',
  KARPATHY,
  '',
].join('\n');

const results = [
  run('(a) real shape: 6 copies → 1, marker kept, user sections intact', REAL_SHAPE, ({ after, stdout }) => {
    assert(countBlocks(REAL_SHAPE) === 6, 'fixture should start with 6 copies, got ' + countBlocks(REAL_SHAPE));
    assert(countBlocks(after) === 1, 'expected 1 block left, got ' + countBlocks(after));
    assert(stdout.trim() === 'dedupe: removed 5 duplicate Karpathy block(s)', 'stdout: ' + JSON.stringify(stdout));
    assert(after.includes(MARKER), 'marker was dropped');
    const mi = after.indexOf(MARKER), bi = after.indexOf('# CLAUDE.md', mi);
    assert(bi > mi && bi - mi < 60, 'surviving block is not the marked one');
    assert(after.includes(COLAB), 'Colab user section was altered');
    assert(after.includes(OMC), 'OMC section was altered');
    assert(after.includes('<!-- User customizations -->'), 'user-customizations line was dropped');
    assert(!/\n\n\n/.test(after), 'removal left a tripled blank line');
    return true;
  }),
  run('(b) only the marked copy → untouched', MARKER + '\n\n' + KARPATHY + '\n', ({ after, before, stdout, status }) => {
    assert(after === before, 'file was rewritten');
    assert(stdout === '', 'expected no output, got ' + JSON.stringify(stdout));
    assert(status === 0, 'exit status ' + status);
    return true;
  }),
  run('(c) unmarked copies, no marker → all removed', [OMC, KARPATHY, KARPATHY, COLAB, ''].join('\n'), ({ after, stdout }) => {
    assert(countBlocks(after) === 0, 'expected 0 blocks left, got ' + countBlocks(after));
    assert(stdout.trim() === 'dedupe: removed 2 duplicate Karpathy block(s)', 'stdout: ' + JSON.stringify(stdout));
    assert(after.includes(OMC) && after.includes(COLAB), 'non-Karpathy content was altered');
    return true;
  }),
  run('(d) missing file → no crash, no output', null, ({ stdout, stderr, status }) => {
    assert(status === 0, 'exit status ' + status);
    assert(stdout === '' && stderr === '', 'expected silence, got ' + JSON.stringify(stdout + stderr));
    return true;
  }),
  run('(e) no Karpathy content at all → untouched', OMC + '\n\n' + COLAB + '\n', ({ after, before, stdout }) => {
    assert(after === before, 'file was rewritten');
    assert(stdout === '', 'unexpected output ' + JSON.stringify(stdout));
    return true;
  }),
];

// --- --install mode -------------------------------------------------------
// The block install.sh owns has to track the pinned content: a bumped
// KARPATHY_SHA must reach a machine that already carries the block, without
// duplicating it or disturbing a byte the user wrote around it.

const END_MARKER = '<!-- /my-claude:karpathy-guidelines -->';
// What a pin bump looks like: same headings and closing line, one changed
// sentence, so a stale copy shows up as a missing '(v2)'.
const KARPATHY_V2 = KARPATHY.replace('For trivial tasks, use judgment.', 'For trivial tasks, use judgment. (v2)');
const USER_TOP = ['# My own notes', '', 'Keep this exactly as it is.'].join('\n');
const USER_BOTTOM = ['# Later section', '', 'Also mine.'].join('\n');
const count = (s, needle) => s.split(needle).length - 1;

// Runs one scenario in its own temp dir. `install(content)` hands the script a
// content file the way install.sh hands over a checksum-verified download.
function scenario(name, body) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'kr-'));
  const file = path.join(dir, 'CLAUDE.md');
  const install = (content) => {
    const pinned = path.join(dir, 'pinned.md');
    fs.writeFileSync(pinned, content);
    const out = cp.spawnSync('node', [SCRIPT, '--install', file, pinned], { encoding: 'utf8' });
    return { stdout: out.stdout, stderr: out.stderr, status: out.status, after: fs.readFileSync(file, 'utf8') };
  };
  let ok = false, detail = '';
  try {
    body({ install, write: (t) => fs.writeFileSync(file, t) });
    ok = true;
  } catch (e) {
    detail = e.message;
  }
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${ok ? '' : '  → ' + detail}`);
  fs.rmSync(dir, { recursive: true, force: true });
  return ok;
}

results.push(
  scenario('(f) marker absent → appended below the user content', ({ install, write }) => {
    write(USER_TOP + '\n');
    const r = install(KARPATHY);
    assert(r.status === 0, 'exit status ' + r.status + ' ' + r.stderr);
    assert(r.stdout.trim() === 'Karpathy guidelines appended', 'stdout: ' + JSON.stringify(r.stdout));
    assert(r.after.startsWith(USER_TOP + '\n'), 'user content was disturbed');
    assert(countBlocks(r.after) === 1, 'expected 1 block, got ' + countBlocks(r.after));
    assert(count(r.after, MARKER) === 1 && count(r.after, END_MARKER) === 1, 'markers not written exactly once');
    assert(r.after.endsWith(END_MARKER + '\n'), 'block does not end at the end marker');
  }),
  scenario('(g) same pin re-run → byte-identical, no write', ({ install, write }) => {
    write(USER_TOP + '\n');
    const first = install(KARPATHY).after;
    const r = install(KARPATHY);
    assert(r.after === first, 'file changed on a re-run at the same pin');
    assert(r.stdout.trim() === 'Karpathy guidelines already current', 'stdout: ' + JSON.stringify(r.stdout));
    assert(r.status === 0, 'exit status ' + r.status + ' ' + r.stderr);
  }),
  scenario('(h) changed pin, marked block → replaced once, user text intact', ({ install, write }) => {
    write([USER_TOP, '', MARKER, '', KARPATHY, '', END_MARKER, '', USER_BOTTOM, ''].join('\n'));
    const r = install(KARPATHY_V2);
    assert(r.stdout.trim() === 'Karpathy guidelines refreshed', 'stdout: ' + JSON.stringify(r.stdout));
    assert(countBlocks(r.after) === 1, 'expected 1 block, got ' + countBlocks(r.after));
    assert(count(r.after, '(v2)') === 1, 'expected exactly one refreshed copy');
    assert(count(r.after, MARKER) === 1 && count(r.after, END_MARKER) === 1, 'markers duplicated');
    assert(r.after.startsWith(USER_TOP + '\n'), 'text above the block changed');
    assert(r.after.endsWith('\n' + USER_BOTTOM + '\n'), 'text below the block changed');
    assert(install(KARPATHY_V2).after === r.after, 'a second run at the new pin rewrote the file');
  }),
  scenario('(i) legacy block, no end marker → refreshed in place, then idempotent', ({ install, write }) => {
    write([USER_TOP, '', MARKER, '', KARPATHY, '', USER_BOTTOM, ''].join('\n'));
    const r = install(KARPATHY);
    assert(r.stdout.trim() === 'Karpathy guidelines refreshed', 'stdout: ' + JSON.stringify(r.stdout));
    assert(countBlocks(r.after) === 1, 'expected 1 block, got ' + countBlocks(r.after));
    assert(count(r.after, END_MARKER) === 1, 'end marker not added exactly once');
    assert(r.after.includes(KARPATHY), 'the pinned body was altered');
    assert(r.after.startsWith(USER_TOP + '\n'), 'text above the block changed');
    assert(r.after.endsWith('\n' + USER_BOTTOM + '\n'), 'text below the block changed');
    const second = install(KARPATHY);
    assert(second.after === r.after, 'the second run rewrote the file');
    assert(second.stdout.trim() === 'Karpathy guidelines already current', 'stdout: ' + JSON.stringify(second.stdout));
  }),
  scenario('(j) legacy body that no longer matches → replaced up to the user heading', ({ install, write }) => {
    const stale = ['# CLAUDE.md', '', 'Some older wording that no longer matches.', '', 'More of it.'].join('\n');
    write([USER_TOP, '', MARKER, '', stale, '', USER_BOTTOM, ''].join('\n'));
    const r = install(KARPATHY);
    assert(!r.after.includes('older wording'), 'the stale body survived');
    assert(countBlocks(r.after) === 1, 'expected 1 block, got ' + countBlocks(r.after));
    assert(count(r.after, MARKER) === 1 && count(r.after, END_MARKER) === 1, 'markers duplicated');
    assert(r.after.startsWith(USER_TOP + '\n'), 'text above the block changed');
    assert(r.after.endsWith('\n' + USER_BOTTOM + '\n'), 'text below the block changed');
    assert(install(KARPATHY).after === r.after, 'the second run rewrote the file');
  }),
);

const failed = results.filter((r) => !r).length;
console.log(failed ? `${failed} FAILED` : 'ALL PASSED');
process.exit(failed ? 1 : 0);
