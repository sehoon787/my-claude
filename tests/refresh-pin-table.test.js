#!/usr/bin/env node
// Unit tests for scripts/refresh-pin-table.js — builds a throwaway repo tree
// (SOURCES.json + a README carrying a stale pin row) and runs the real script
// against it. `node tests/refresh-pin-table.test.js`
'use strict';
const fs = require('fs'), os = require('os'), path = require('path'), cp = require('child_process');
const SCRIPT = path.resolve(__dirname, '..', 'scripts', 'refresh-pin-table.js');

// Two submodule-backed entries plus one that is not a submodule and has no row
// in the table (the real manifest carries andrej-karpathy-skills that way).
const SOURCES = {
  'everything-claude-code': {
    repo: 'https://github.com/affaan-m/everything-claude-code',
    path: 'upstream/ecc',
    pinned_sha: 'bf70150eb2df8070024e5bdf08e4aa08959e2735',
    pinned_date: '2026-09-22',
  },
  archify: {
    repo: 'https://github.com/tt-a1i/archify',
    path: 'upstream/archify',
    pinned_tag: 'v2.9.0',
    pinned_sha: '62904f3b73dc469ceb1f1fd500ff44c8dee70b06',
    pinned_date: '2026-09-19',
  },
  'andrej-karpathy-skills': {
    repo: 'https://github.com/forrestchang/andrej-karpathy-skills',
    pinned_sha: 'aa4467f0b33e1e80d11c7c043d4b27e7c79a73a3',
    pinned_date: '2026-09-19',
  },
};

// Rows that must survive untouched: the tool-overview row and the skill-count
// row both lead with a link to the same repo, so anything that anchored on the
// repo link alone instead of the full row shape would corrupt them.
const DECOY_TOOLS = '| 4 | **[everything-claude-code](https://github.com/affaan-m/everything-claude-code)** (ECC) — affaan-m | 278 skills upstream. | Submodule `upstream/ecc`, SHA-pinned. |';
const DECOY_COUNTS = '| [everything-claude-code](https://github.com/affaan-m/everything-claude-code) | 61 | coding-standards, fastapi-patterns |';

// `label` is the translated text of the diff link ("compare" / "comparer").
function readme(heading, label) {
  return [
    '# my-claude',
    '',
    DECOY_TOOLS,
    DECOY_COUNTS,
    '',
    '## ' + heading,
    '',
    '| Source | SHA | Date | Diff |',
    '|--------|-----|------|------|',
    '| [everything-claude-code](https://github.com/affaan-m/everything-claude-code) | `07756ce` | 2026-09-19 | [' + label + '](https://github.com/affaan-m/everything-claude-code/compare/07756ce...HEAD) |',
    '| [archify](https://github.com/tt-a1i/archify) | `62904f3` (`v2.9.0`) | 2026-09-19 | [' + label + '](https://github.com/tt-a1i/archify/compare/62904f3...HEAD) |',
    '',
    '---',
    '',
  ].join('\n');
}

const ECC_FIXED = '| [everything-claude-code](https://github.com/affaan-m/everything-claude-code) | `bf70150` | 2026-09-22 | [compare](https://github.com/affaan-m/everything-claude-code/compare/bf70150...HEAD) |';
const ARCHIFY_ROW = '| [archify](https://github.com/tt-a1i/archify) | `62904f3` (`v2.9.0`) | 2026-09-19 | [compare](https://github.com/tt-a1i/archify/compare/62904f3...HEAD) |';

const assert = (cond, msg) => { if (!cond) throw new Error(msg); };

// Lays down a fake repo root: the script resolves its own paths from
// __dirname, so a copy of it inside the fixture tree targets that tree.
function scenario(name, body) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'rpt-'));
  fs.mkdirSync(path.join(root, 'scripts'));
  fs.mkdirSync(path.join(root, 'upstream'));
  fs.mkdirSync(path.join(root, 'docs', 'i18n'), { recursive: true });
  fs.copyFileSync(SCRIPT, path.join(root, 'scripts', 'refresh-pin-table.js'));
  fs.writeFileSync(path.join(root, 'upstream', 'SOURCES.json'), JSON.stringify(SOURCES, null, 2) + '\n');
  const write = (rel, text) => fs.writeFileSync(path.join(root, rel), text);
  const read = (rel) => fs.readFileSync(path.join(root, rel), 'utf8');
  const run = () => {
    const out = cp.spawnSync('node', [path.join(root, 'scripts', 'refresh-pin-table.js')], { encoding: 'utf8' });
    return { stdout: out.stdout, stderr: out.stderr, status: out.status };
  };
  let ok = false, detail = '';
  try {
    body({ write, read, run });
    ok = true;
  } catch (e) {
    detail = e.message;
  }
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${ok ? '' : '  → ' + detail}`);
  fs.rmSync(root, { recursive: true, force: true });
  return ok;
}

const results = [
  scenario('(a) stale row → matches SOURCES.json, second run is a no-op', ({ write, read, run }) => {
    write('README.md', readme('Bundled Upstream Versions', 'compare'));
    const r = run();
    assert(r.status === 0, 'exit status ' + r.status + ' ' + r.stderr);
    const after = read('README.md');
    assert(after.includes(ECC_FIXED), 'stale row not refreshed:\n' + after);
    assert(!after.includes('07756ce'), 'the old sha survived somewhere');
    assert(r.stdout.includes('everything-claude-code 07756ce -> bf70150'), 'stdout: ' + JSON.stringify(r.stdout));

    const second = run();
    assert(second.status === 0, 'second run exit status ' + second.status + ' ' + second.stderr);
    assert(read('README.md') === after, 'the second run rewrote the file');
    assert(second.stdout.trim() === '[refresh-pin-table] all pin rows current', 'stdout: ' + JSON.stringify(second.stdout));
  }),

  scenario('(b) tag annotation and untouched rows survive; absent source not inserted', ({ write, read, run }) => {
    write('README.md', readme('Bundled Upstream Versions', 'compare'));
    run();
    const after = read('README.md');
    assert(after.includes(ARCHIFY_ROW), 'archify row was rewritten or lost its (`v2.9.0`) tag');
    assert(after.includes(DECOY_TOOLS), 'the tool-overview row was touched');
    assert(after.includes(DECOY_COUNTS), 'the skill-count row was touched');
    assert(!after.includes('andrej-karpathy-skills'), 'a source with no row was inserted into the table');
    assert(after.split('\n').length === readme('Bundled Upstream Versions', 'compare').split('\n').length, 'line count changed');
  }),

  scenario('(c) translations: translated heading and diff label are preserved', ({ write, read, run }) => {
    write('README.md', readme('Bundled Upstream Versions', 'compare'));
    write(path.join('docs', 'i18n', 'README.fr.md'), readme('Versions amont intégrées', 'comparer'));
    write(path.join('docs', 'i18n', 'README.ko.md'), readme('번들된 업스트림 버전', 'compare'));
    const r = run();
    assert(r.status === 0, 'exit status ' + r.status + ' ' + r.stderr);
    const fr = read(path.join('docs', 'i18n', 'README.fr.md'));
    assert(fr.includes('`bf70150` | 2026-09-22 | [comparer]'), 'fr row not refreshed or label changed:\n' + fr);
    assert(fr.includes('## Versions amont intégrées'), 'the translated heading was altered');
    assert(fr.includes('/compare/bf70150...HEAD'), 'the compare target was not repointed');
    const ko = read(path.join('docs', 'i18n', 'README.ko.md'));
    assert(ko.includes(ECC_FIXED), 'ko row not refreshed:\n' + ko);
  }),
];

const failed = results.filter((r) => !r).length;
console.log(failed ? `${failed} FAILED` : 'ALL PASSED');
process.exit(failed ? 1 : 0);
