// Backs up ~/.claude/settings.json before an installer script rewrites it.
// Required by scripts/merge-settings.js (install.sh step [4/6]) and
// scripts/merge-hooks.js (step [4b]); each calls backupSettings() right before
// its write, so every rewrite is preceded by a copy of what it replaces.
//
// The copy sits next to the file as <name>.my-claude-backup-<UTC stamp>, where
// the stamp is YYYYMMDDTHHMMSSmmmZ: fixed width, so names sort oldest to newest.
// The file can hold credentials, so the copy is created readable by its owner
// only (mode 600), whatever the umask and whatever mode the original has. After
// each backup only the newest SETTINGS_BACKUP_KEEP are kept, and nothing but a
// file with exactly that name pattern is ever deleted.
//
// No settings file means nothing to protect: nothing happens. A backup that
// cannot be made is reported on stderr and the install carries on, because
// stopping here would leave ~/.claude half installed.
'use strict';
const fs = require('fs');
const path = require('path');

const SETTINGS_BACKUP_KEEP = 5;
const BACKUP_MODE = 0o600;
const BACKUP_INFIX = '.my-claude-backup-';
const STAMP_PATTERN = /^\d{8}T\d{9}Z$/;
// The two merge steps run back to back, so two backups can land in one
// millisecond; each retry moves the stamp on by one millisecond.
const MAX_NAME_ATTEMPTS = 100;

// 2026-11-19T15:30:45.123Z -> 20261119T153045123Z
const stampOf = (ms) => new Date(ms).toISOString().replace(/[-:.]/g, '');

// Writes `bytes` to a new backup file and returns its path. The create is
// exclusive, so an earlier backup (or a planted symlink) is never overwritten.
function writeNewBackup(dir, base, bytes) {
  const now = Date.now();
  for (let attempt = 0; attempt < MAX_NAME_ATTEMPTS; attempt++) {
    const backupPath = path.join(dir, base + BACKUP_INFIX + stampOf(now + attempt));
    let fd;
    try {
      fd = fs.openSync(backupPath, 'wx', BACKUP_MODE);
    } catch (err) {
      if (err.code === 'EEXIST') continue;
      throw err;
    }
    let written = false;
    try {
      fs.writeFileSync(fd, bytes);
      // The umask can only have narrowed the mode given to openSync; this makes
      // it exactly 600. Windows has no such modes.
      if (process.platform !== 'win32') fs.fchmodSync(fd, BACKUP_MODE);
      written = true;
    } finally {
      fs.closeSync(fd);
      // A truncated copy must not survive to be counted as a backup.
      if (!written) fs.rmSync(backupPath, { force: true });
    }
    return backupPath;
  }
  throw new Error(`no free backup name after ${MAX_NAME_ATTEMPTS} tries`);
}

// Deletes the oldest backups so that SETTINGS_BACKUP_KEEP remain. The backup
// just made is never a candidate, even if a clock that went backwards makes it
// sort oldest.
function pruneBackups(dir, base, justMade) {
  const prefix = base + BACKUP_INFIX;
  const others = fs.readdirSync(dir)
    .filter((name) => name.startsWith(prefix) && STAMP_PATTERN.test(name.slice(prefix.length)) && name !== justMade)
    .sort();
  const surplus = others.slice(0, Math.max(0, others.length - (SETTINGS_BACKUP_KEEP - 1)));
  for (const name of surplus) {
    try {
      fs.rmSync(path.join(dir, name), { force: true });
    } catch (err) {
      console.error(`  WARNING: could not remove the old backup ${name} (${err.message})`);
    }
  }
}

// Copies settingsPath to a new timestamped backup and prints its path. Returns
// the backup's path, or null when there was no file or no backup could be made.
function backupSettings(settingsPath) {
  if (!fs.existsSync(settingsPath)) return null;
  const dir = path.dirname(settingsPath);
  const base = path.basename(settingsPath);
  let backupPath;
  try {
    backupPath = writeNewBackup(dir, base, fs.readFileSync(settingsPath));
  } catch (err) {
    console.error(`  WARNING: could not back up ${settingsPath} (${err.message}); continuing without a backup`);
    return null;
  }
  console.log(`  ${base} backup: ${backupPath}`);
  try {
    pruneBackups(dir, base, path.basename(backupPath));
  } catch (err) {
    console.error(`  WARNING: could not prune old ${base} backups (${err.message})`);
  }
  return backupPath;
}

module.exports = { backupSettings, SETTINGS_BACKUP_KEEP };
