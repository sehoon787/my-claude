#!/usr/bin/env node
// Regression test: scripts/merge-settings.js (install.sh step [4/6]) and
// scripts/merge-hooks.js (step [4b]) rewrite ~/.claude/settings.json, which can
// hold credentials. A merge that would change the file first copies what is there
// to a timestamped backup next to it (scripts/settings-backup.js), readable by the
// owner only, and then writes; only the newest SETTINGS_BACKUP_KEEP backups are
// kept. A merge that would write the very bytes already there does nothing at
// all: no write (the mtime stays), no backup, no output, so a settled install
// never pushes the user's original file out of the backups. With no settings.json
// there is nothing to protect, so no backup is made.
//
// Root cause this guards against: an install over an existing settings.json
// replaced it with no way back — a bad merge, or a user who wanted their old
// file, had nothing to restore from.
//
// Every scenario runs the real scripts in a child whose HOME is a throwaway
// directory, so the real ~/.claude is never read or written.
// `node tests/settings-backup.test.js`
'use strict';
const fs = require('fs'), os = require('os'), path = require('path'), cp = require('child_process');

const ROOT = path.resolve(__dirname, '..');
const MERGE_SETTINGS = path.join(ROOT, 'scripts', 'merge-settings.js');
const MERGE_HOOKS = path.join(ROOT, 'scripts', 'merge-hooks.js');
const HOOKS_JSON = path.join(ROOT, 'hooks', 'hooks.json');
// <settings file>.my-claude-backup-<UTC YYYYMMDDTHHMMSSmmmZ>: the fixed-width stamp
// makes the names sort oldest to newest.
const BACKUP_NAME = /^settings\.json\.my-claude-backup-\d{8}T\d{9}Z$/;
const stampOf = (n) => `20200101T000000${String(n).padStart(3, '0')}Z`;         // fake stamps from the past
const futureStampOf = (n) => `20990101T000000${String(n).padStart(3, '0')}Z`;   // and from the future
const results = [];
const posix = process.platform !== 'win32';

function check(name, ok, detail) {
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${!ok && detail ? '  (' + detail + ')' : ''}`);
  results.push(Boolean(ok));
}

let helper = null;
try {
  helper = require(path.join(ROOT, 'scripts', 'settings-backup.js'));
} catch (err) {
  check('scripts/settings-backup.js can be required', false, err.message);
}
const KEEP = helper && Number.isInteger(helper.SETTINGS_BACKUP_KEEP) ? helper.SETTINGS_BACKUP_KEEP : 5;
check('the retention count is a named constant, SETTINGS_BACKUP_KEEP, and at least 2',
  helper !== null && Number.isInteger(helper.SETTINGS_BACKUP_KEEP) && helper.SETTINGS_BACKUP_KEEP >= 2,
  helper ? `SETTINGS_BACKUP_KEEP=${helper.SETTINGS_BACKUP_KEEP}` : 'no helper');

// A settings.json a user might really have: credentials, an unusual 4-space
// layout (so the merge's own 2-space rewrite always differs from it) and no
// trailing newline.
const ORIGINAL = JSON.stringify({
  env: { SOME_API_TOKEN: 'fake-token-for-test-only' },
  model: 'opus',
  permissions: { allow: ['Bash(ls:*)'] },
}, null, 4);

// Runs `body` against a throwaway HOME whose ~/.claude/settings.json holds
// `initial` (no file when null). `run(script, args)` runs one of the scripts in
// a child with that HOME and returns spawnSync's result.
function scenario(initial, body) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'sbk-'));
  const home = path.join(dir, 'home');
  const claude = path.join(home, '.claude');
  const file = path.join(claude, 'settings.json');
  fs.mkdirSync(claude, { recursive: true });
  if (initial !== null) {
    fs.writeFileSync(file, initial);
    fs.chmodSync(file, 0o644);
  }
  const run = (script, args = []) =>
    cp.spawnSync(process.execPath, [script, ...args], { env: { ...process.env, HOME: home }, encoding: 'utf8' });
  try {
    body({ home, claude, file, run });
  } finally {
    try { fs.chmodSync(claude, 0o755); } catch (e) { /* removed or never changed */ }
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

const backupsIn = (claude) => fs.readdirSync(claude).filter((n) => BACKUP_NAME.test(n)).sort();
const modeOf = (p) => (fs.statSync(p).mode & 0o777).toString(8);
const read = (p) => fs.readFileSync(p);
const show = (v) => JSON.stringify(v);

// (a) merge-settings.js: the backup is the file as it was before the install.
scenario(ORIGINAL, ({ claude, file, run }) => {
  const before = read(file);
  const r = run(MERGE_SETTINGS);
  const names = backupsIn(claude);
  const backup = path.join(claude, names[0] || 'no-backup');
  check('(a) merge-settings.js exits 0', r.status === 0, r.stderr);
  check('(a) merge-settings.js: exactly one backup is left next to settings.json', names.length === 1, show(fs.readdirSync(claude)));
  check('(a) merge-settings.js: the backup is byte-identical to the file before the merge',
    names.length === 1 && read(backup).equals(before));
  check('(a) merge-settings.js: settings.json itself was rewritten (the backup is the old copy)', !read(file).equals(before));
  if (posix) check('(a) merge-settings.js: the backup is mode 600', names.length === 1 && modeOf(backup) === '600', names.length === 1 ? modeOf(backup) : 'no backup');
  check('(a) merge-settings.js prints the backup path', names.length === 1 && r.stdout.includes(backup), show(r.stdout));
});

// (b) merge-hooks.js: same.
scenario(ORIGINAL, ({ claude, file, run }) => {
  const before = read(file);
  const r = run(MERGE_HOOKS, [HOOKS_JSON]);
  const names = backupsIn(claude);
  const backup = path.join(claude, names[0] || 'no-backup');
  check('(b) merge-hooks.js exits 0', r.status === 0, r.stderr);
  check('(b) merge-hooks.js: exactly one backup is left next to settings.json', names.length === 1, show(fs.readdirSync(claude)));
  check('(b) merge-hooks.js: the backup is byte-identical to the file before the merge',
    names.length === 1 && read(backup).equals(before));
  check('(b) merge-hooks.js: settings.json itself was rewritten (the backup is the old copy)', !read(file).equals(before));
  if (posix) check('(b) merge-hooks.js: the backup is mode 600', names.length === 1 && modeOf(backup) === '600', names.length === 1 ? modeOf(backup) : 'no backup');
  check('(b) merge-hooks.js prints the backup path', names.length === 1 && r.stdout.includes(backup), show(r.stdout));
});

// (c) install.sh order: merge-settings.js, then merge-hooks.js. The second
// backup must not replace the first, which is the user's original file.
scenario(ORIGINAL, ({ claude, file, run }) => {
  const original = read(file);
  run(MERGE_SETTINGS);
  const afterSettings = read(file);
  run(MERGE_HOOKS, [HOOKS_JSON]);
  const names = backupsIn(claude);
  check('(c) both steps leave their own backup', names.length === 2, show(names));
  check('(c) the older backup is the original file, untouched by step [4b]',
    names.length === 2 && read(path.join(claude, names[0])).equals(original));
  check('(c) the newer backup is the file as step [4/6] left it',
    names.length === 2 && read(path.join(claude, names[1])).equals(afterSettings));
});

// (d) No settings.json: nothing to back up, nothing printed, nothing created.
// Each script gets its own empty ~/.claude, since the first one to run creates
// the file the second would then find.
for (const [name, script, args] of [['merge-settings.js', MERGE_SETTINGS, []], ['merge-hooks.js', MERGE_HOOKS, [HOOKS_JSON]]]) {
  scenario(null, ({ claude, run }) => {
    const r = run(script, args);
    check(`(d) ${name}, no settings.json: still succeeds`, r.status === 0, r.stderr);
    check(`(d) ${name}, no settings.json: no backup is made`, backupsIn(claude).length === 0, show(fs.readdirSync(claude)));
    check(`(d) ${name}, no settings.json: only settings.json is created`, show(fs.readdirSync(claude)) === show(['settings.json']), show(fs.readdirSync(claude)));
    check(`(d) ${name}, no settings.json: no backup line is printed`, !/backup/i.test(r.stdout + r.stderr), show(r.stdout + r.stderr));
  });
}

// (e) Retention: only the newest KEEP backups survive, and only our own.
scenario(ORIGINAL, ({ claude, file, run }) => {
  const seeded = KEEP + 3;
  for (let i = 1; i <= seeded; i++) {
    fs.writeFileSync(path.join(claude, `settings.json.my-claude-backup-${stampOf(i)}`), `old-${i}`);
  }
  // Files that look similar but are not ours to prune.
  const bystanders = {
    'settings.json.bak': 'kept-1',                                       // scripts/apply-sandbox-preset.js's own backup
    'settings.json.my-claude-backup-notes.txt': 'kept-2',
    'settings.local.json': 'kept-3',
    [`settings.json.other-backup-${stampOf(1)}`]: 'kept-4',
    [`settings.json.my-claude-backup-${stampOf(1)}.tmp`]: 'kept-5',
  };
  for (const [name, content] of Object.entries(bystanders)) fs.writeFileSync(path.join(claude, name), content);
  const before = read(file);
  const r = run(MERGE_SETTINGS);
  const names = backupsIn(claude);
  const fake = names.filter((n) => n.includes('-20200101T'));   // the seeded ones
  const fresh = names.filter((n) => !fake.includes(n));
  const keptSeeded = fake.map((n) => fs.readFileSync(path.join(claude, n), 'utf8'));
  const expectedSeeded = [];
  for (let i = seeded - (KEEP - 1) + 1; i <= seeded; i++) expectedSeeded.push(`old-${i}`);
  check('(e) retention: merge-settings.js exits 0', r.status === 0, r.stderr);
  check(`(e) retention: ${seeded} old backups + the new one leave exactly ${KEEP}`, names.length === KEEP, `${names.length}: ${show(names)}`);
  check('(e) retention: the new backup is kept and holds the pre-merge file',
    fresh.length === 1 && read(path.join(claude, fresh[0])).equals(before), show(fresh));
  check(`(e) retention: the ${KEEP - 1} newest old backups are kept, the oldest are deleted`,
    show(keptSeeded) === show(expectedSeeded), show(keptSeeded));
  const intact = Object.entries(bystanders).every(([name, content]) => {
    const p = path.join(claude, name);
    return fs.existsSync(p) && fs.readFileSync(p, 'utf8') === content;
  });
  check('(e) retention: similar-looking files that are not our backups are untouched', intact);
});

// (f) Changes that keep coming never leave more than KEEP backups behind. Before
// each run the file is put into a layout the merge does not write (4-space JSON
// with a new value each time), so every run changes it and backs up exactly what
// it replaced; a run with nothing to change makes no backup at all (see (j)).
scenario(ORIGINAL, ({ claude, file, run }) => {
  const counts = [];
  let beforeLast = null;
  for (let i = 0; i < KEEP + 3; i++) {
    fs.writeFileSync(file, JSON.stringify({ ...JSON.parse(read(file).toString('utf8')), changeNumber: i }, null, 4));
    beforeLast = read(file);
    run(i % 2 === 0 ? MERGE_SETTINGS : MERGE_HOOKS, i % 2 === 0 ? [] : [HOOKS_JSON]);
    counts.push(backupsIn(claude).length);
  }
  const expected = counts.map((_, i) => Math.min(i + 1, KEEP));
  check(`(f) ${KEEP + 3} changing runs in a row: one backup each until ${KEEP} are kept, never more`,
    show(counts) === show(expected), `${show(counts)} instead of ${show(expected)}`);
  const names = backupsIn(claude);
  check('(f) the newest backup is the file as it was before the last run',
    names.length > 0 && read(path.join(claude, names[names.length - 1])).equals(beforeLast));
});

// (g) Mode 600 whatever the umask, and whatever mode the original has.
if (posix) {
  for (const umask of [0o000, 0o277]) {
    scenario(ORIGINAL, ({ claude, file, run }) => {
      fs.chmodSync(file, 0o666);
      const previous = process.umask(umask);
      let r;
      try { r = run(MERGE_SETTINGS); } finally { process.umask(previous); }
      const names = backupsIn(claude);
      check(`(g) umask ${umask.toString(8).padStart(3, '0')}, original mode 666: the backup is mode 600`,
        r.status === 0 && names.length === 1 && modeOf(path.join(claude, names[0])) === '600',
        names.length === 1 ? modeOf(path.join(claude, names[0])) : show(names));
    });
  }
}

// (h) The helper on its own: byte-exact copies, never overwriting an earlier
// backup (even in the same millisecond), never deleting the one it just made.
if (helper) {
  const { backupSettings } = helper;
  const quiet = (fn) => {
    const log = console.log, error = console.error;
    console.log = () => {}; console.error = () => {};
    try { return fn(); } finally { console.log = log; console.error = error; }
  };
  const realNow = Date.now;

  scenario(null, ({ claude, file }) => {
    check('(h) helper: a missing file is not an error and makes no backup',
      quiet(() => backupSettings(file)) === null && fs.readdirSync(claude).length === 0);
  });

  scenario(null, ({ claude, file }) => {
    const odd = Buffer.from([0x7b, 0x0d, 0x0a, 0xff, 0xfe, 0x00, 0x80, 0x0a]);   // CRLF, invalid UTF-8, NUL
    fs.writeFileSync(file, odd);
    const made = quiet(() => backupSettings(file));
    check('(h) helper: the copy is exact for bytes that are not valid UTF-8',
      typeof made === 'string' && read(made).equals(odd), show(made));
  });

  scenario(null, ({ claude, file }) => {
    Date.now = () => 1767225600000;   // every call lands in the same millisecond
    try {
      const made = [];
      for (let i = 1; i <= KEEP; i++) {
        fs.writeFileSync(file, `content-${i}`);
        made.push(quiet(() => backupSettings(file)));
      }
      const distinct = new Set(made).size === KEEP && made.every((p) => typeof p === 'string');
      check(`(h) helper: ${KEEP} backups in one millisecond are ${KEEP} distinct files`, distinct, show(made));
      check('(h) helper: none of them overwrote another (each holds its own content)',
        distinct && made.every((p, i) => fs.existsSync(p) && fs.readFileSync(p, 'utf8') === `content-${i + 1}`));
      fs.writeFileSync(file, `content-${KEEP + 1}`);
      const extra = quiet(() => backupSettings(file));
      const names = backupsIn(claude);
      check(`(h) helper: one more backup drops the oldest and keeps ${KEEP}`,
        names.length === KEEP && !fs.existsSync(made[0]) && made.slice(1).every((p) => fs.existsSync(p)) && fs.existsSync(extra),
        show(names));
    } finally {
      Date.now = realNow;
    }
  });

  scenario(null, ({ claude, file }) => {
    // A clock that went backwards: every existing backup looks newer than the new one.
    for (let i = 1; i <= KEEP; i++) {
      fs.writeFileSync(path.join(claude, `settings.json.my-claude-backup-${futureStampOf(i)}`), `future-${i}`);
    }
    fs.writeFileSync(file, 'now');
    const made = quiet(() => backupSettings(file));
    check('(h) helper: the backup just made is never the one that gets pruned',
      typeof made === 'string' && fs.existsSync(made) && read(made).toString() === 'now' && backupsIn(claude).length === KEEP,
      show(backupsIn(claude)));
  });

  // writeSettingsIfChanged is what the merge scripts call in place of writeFileSync.
  const { writeSettingsIfChanged } = helper;
  check('(h) helper: exports writeSettingsIfChanged', typeof writeSettingsIfChanged === 'function');
  if (typeof writeSettingsIfChanged === 'function') {
    const capture = (fn) => {
      const logs = [];
      const log = console.log, error = console.error;
      console.log = (...args) => logs.push(args.join(' '));
      console.error = (...args) => logs.push(args.join(' '));
      try { return { value: fn(), logs }; } finally { console.log = log; console.error = error; }
    };
    const longAgo = new Date('2001-09-09T01:46:40Z');   // 1000000000 seconds after the epoch

    scenario(null, ({ claude, file }) => {
      fs.writeFileSync(file, 'same bytes\n');
      fs.utimesSync(file, longAgo, longAgo);
      const r = capture(() => writeSettingsIfChanged(file, 'same bytes\n'));
      check('(h) helper: identical content: returns false, writes nothing, makes no backup, prints nothing',
        r.value === false && fs.readdirSync(claude).length === 1 && r.logs.length === 0 &&
        Math.floor(fs.statSync(file).mtimeMs / 1000) === 1000000000, show(r));
    });

    scenario(null, ({ claude, file }) => {
      fs.writeFileSync(file, 'old bytes\n');
      const r = capture(() => writeSettingsIfChanged(file, 'new bytes\n'));
      const names = backupsIn(claude);
      check('(h) helper: different content: one backup of the old bytes, then the new bytes, and the path printed',
        r.value === true && fs.readFileSync(file, 'utf8') === 'new bytes\n' && names.length === 1 &&
        fs.readFileSync(path.join(claude, names[0]), 'utf8') === 'old bytes\n' &&
        r.logs.length === 1 && r.logs[0].includes(names[0]), show(r));
    });

    scenario(null, ({ claude, file }) => {
      fs.writeFileSync(file, 'x');   // 'x\n' without its newline: one byte short
      const r = capture(() => writeSettingsIfChanged(file, 'x\n'));
      const names = backupsIn(claude);
      check('(h) helper: a one-byte difference (the trailing newline) is a change, compared byte for byte',
        r.value === true && fs.readFileSync(file, 'utf8') === 'x\n' && names.length === 1 &&
        fs.readFileSync(path.join(claude, names[0]), 'utf8') === 'x', show(r));
    });

    scenario(null, ({ claude, file }) => {
      const r = capture(() => writeSettingsIfChanged(file, 'first\n'));
      check('(h) helper: no file yet: it is created, with no backup and no output',
        r.value === true && fs.readFileSync(file, 'utf8') === 'first\n' && backupsIn(claude).length === 0 && r.logs.length === 0, show(r));
    });

    scenario(null, ({ file }) => {
      const text = 'café ✓\n';
      quiet(() => writeSettingsIfChanged(file, text));
      check('(h) helper: the file holds the content as UTF-8 bytes', read(file).equals(Buffer.from(text, 'utf8')));
      const again = capture(() => writeSettingsIfChanged(file, text));
      check('(h) helper: the same non-ASCII content again counts as unchanged', again.value === false && again.logs.length === 0, show(again));
    });
  }
}

// (i) A backup that cannot be made warns and lets the install continue; the
// merge writes exactly what it wrote before. (Skipped as root, which ignores
// directory permissions.)
if (posix && typeof process.getuid === 'function' && process.getuid() !== 0) {
  scenario(ORIGINAL, ({ claude, file, run }) => {
    fs.chmodSync(claude, 0o500);   // settings.json stays writable; new files cannot be created
    const r = run(MERGE_SETTINGS);
    fs.chmodSync(claude, 0o755);
    const merged = JSON.parse(fs.readFileSync(file, 'utf8'));
    check('(i) no backup possible: the merge still succeeds', r.status === 0, r.stderr);
    check('(i) no backup possible: the failure is reported on stderr', /could not back up/i.test(r.stderr), show(r.stderr));
    check('(i) no backup possible: settings.json is still merged', merged.env && merged.env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS === '1');
  });
} else {
  console.log('SKIP  (i) unwritable directory: needs a non-root POSIX user');
}

// (j) A merge that changes nothing leaves no trace: nothing written (the mtime
// stays), no backup, nothing printed. The first pass, in install.sh's order,
// changes the file and backs up what it replaced; every later pass finds the
// bytes already as the merge would write them, so the user's original stays among
// the backups however often the installer or the SessionStart update runs.
scenario(ORIGINAL, ({ claude, file, run }) => {
  const original = read(file);
  const first = [run(MERGE_SETTINGS), run(MERGE_HOOKS, [HOOKS_JSON])];
  const settled = read(file);
  const backups = backupsIn(claude);
  check('(j) first pass: each step changes the file and backs up what it replaced',
    first.every((r) => r.status === 0) && backups.length === 2 && !settled.equals(original), show(backups));
  const longAgo = new Date('2001-09-09T01:46:40Z');   // 1000000000 seconds after the epoch
  fs.utimesSync(file, longAgo, longAgo);
  let output = '';
  let allSucceeded = true;
  for (let pass = 0; pass < 3; pass++) {
    for (const r of [run(MERGE_SETTINGS), run(MERGE_HOOKS, [HOOKS_JSON])]) {
      allSucceeded = allSucceeded && r.status === 0;
      output += r.stdout + r.stderr;
    }
  }
  check('(j) unchanged merges: both scripts still succeed', allSucceeded);
  check('(j) unchanged merges: settings.json is byte-identical', read(file).equals(settled));
  check('(j) unchanged merges: settings.json is not rewritten (its mtime stays)',
    Math.floor(fs.statSync(file).mtimeMs / 1000) === 1000000000, String(fs.statSync(file).mtimeMs));
  check('(j) unchanged merges: no backup is added', show(backupsIn(claude)) === show(backups), show(backupsIn(claude)));
  check("(j) unchanged merges: the user's original is still among the backups",
    backupsIn(claude).some((n) => read(path.join(claude, n)).equals(original)));
  check('(j) unchanged merges: nothing is printed', output === '', show(output));
  // The next real change is backed up again, once.
  const edited = Buffer.from(JSON.stringify({ ...JSON.parse(settled.toString('utf8')), editedByUser: true }, null, 4));
  fs.writeFileSync(file, edited);
  const change = run(MERGE_SETTINGS);
  const added = backupsIn(claude).filter((n) => !backups.includes(n));
  check('(j) a later change makes exactly one backup, of the bytes it replaced',
    change.status === 0 && added.length === 1 && read(path.join(claude, added[0])).equals(edited), show(added));
  if (posix) check('(j) a later change: that backup is mode 600', added.length === 1 && modeOf(path.join(claude, added[0])) === '600');
});

// (k) The write is atomic and symlink-safe, a new file is private, and the very
// first backup is kept for good.
scenario(null, ({ claude, file, run }) => {
  const r = run(MERGE_SETTINGS);
  check('(k) a new settings.json is created', r.status === 0 && fs.existsSync(file), r.stderr);
  if (posix) check('(k) a new settings.json is mode 600', modeOf(file) === '600', modeOf(file));
});
scenario(ORIGINAL, ({ claude, file, run }) => {
  if (posix) fs.chmodSync(file, 0o640);
  run(MERGE_SETTINGS);
  check('(k) no temp file is left behind', fs.readdirSync(claude).every((n) => !n.endsWith('.tmp')), show(fs.readdirSync(claude)));
  if (posix) check('(k) an existing settings.json keeps its mode', modeOf(file) === '640', modeOf(file));
});
if (posix) {
  scenario(ORIGINAL, ({ home, claude, file, run }) => {
    const real = path.join(home, 'dotfiles-settings.json');
    fs.renameSync(file, real);
    fs.symlinkSync(real, file);
    const before = read(real);
    const r = run(MERGE_SETTINGS);
    check('(k) a symlinked settings.json stays a symlink', r.status === 0 && fs.lstatSync(file).isSymbolicLink(), r.stderr);
    check('(k) the merge went into the link target', !read(real).equals(before) && JSON.parse(read(real).toString()).env.SOME_API_TOKEN === 'fake-token-for-test-only');
  });
}
scenario(ORIGINAL, ({ claude, file, run }) => {
  const original = read(file);
  const orig = path.join(claude, 'settings.json.my-claude-original');
  run(MERGE_SETTINGS);
  check('(k) the first backup is also kept as settings.json.my-claude-original',
    fs.existsSync(orig) && read(orig).equals(original));
  if (posix) check('(k) settings.json.my-claude-original is mode 600', modeOf(orig) === '600', modeOf(orig));
  for (let i = 0; i < KEEP + 3; i++) {
    fs.writeFileSync(file, JSON.stringify({ ...JSON.parse(read(file).toString('utf8')), changeNumber: i }, null, 4));
    run(i % 2 === 0 ? MERGE_SETTINGS : MERGE_HOOKS, i % 2 === 0 ? [] : [HOOKS_JSON]);
  }
  check('(k) after many changes the original is still there, unchanged', fs.existsSync(orig) && read(orig).equals(original));
  check('(k) the rotating pool still caps at the constant', backupsIn(claude).length === KEEP, String(backupsIn(claude).length));
});

const failed = results.filter((ok) => !ok).length;
console.log(failed ? `${failed} FAILED` : 'ALL PASSED');
process.exit(failed ? 1 : 0);
