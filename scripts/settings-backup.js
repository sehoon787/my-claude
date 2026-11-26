// Writes ~/.claude/settings.json for the installer scripts and backs up what it
// replaces. Required by scripts/merge-settings.js (install.sh step [4/6]) and
// scripts/merge-hooks.js (step [4b]); each builds the whole new file content
// first and hands it to writeSettingsIfChanged() instead of calling
// fs.writeFileSync.
//
// Content byte-identical to the file means nothing to do: no write (the mtime
// stays), no backup, no output. Otherwise the file is copied next to itself as
// <name>.my-claude-backup-<UTC stamp>, where the stamp is YYYYMMDDTHHMMSSmmmZ:
// fixed width, so names sort oldest to newest. The file can hold credentials, so
// the copy is created readable by its owner only (mode 600), whatever the umask
// and whatever mode the original has. After each backup only the newest
// SETTINGS_BACKUP_KEEP are kept, and nothing but a file with exactly that name
// pattern is ever deleted. Only a change makes a backup, so an install that is
// run again and again without changing anything cannot push the user's original
// file out of them.
//
// The very first backup ever made is also kept under its own name,
// <name>.my-claude-original, created only when absent and never pruned: it is
// the file as it was before my-claude first touched it, which the rotating pool
// would otherwise push out after a few changes.
//
// Limits worth knowing: .my-claude-original holds the file as it was at the first
// backup taken by this version, so on an install that already went through
// my-claude it is not the pre-my-claude file. A dangling settings.json symlink
// (its target missing) is not followed and is replaced by a regular file.
//
// The new content is written to a sibling temp file (fsynced, same mode as the
// file, 0600 for a new one) and renamed over the real path, so an interrupted
// write cannot leave a truncated settings.json and a symlinked settings.json
// stays a symlink.
//
// No settings file means nothing to protect: it is created without a backup. A
// backup that cannot be made is reported on stderr and the write carries on,
// because stopping here would leave ~/.claude half installed.
'use strict';
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const SETTINGS_BACKUP_KEEP = 5;
const BACKUP_MODE = 0o600;
const BACKUP_INFIX = '.my-claude-backup-';
const ORIGINAL_SUFFIX = '.my-claude-original';
const NEW_FILE_MODE = 0o600;
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

// Creates <base>.my-claude-original from `bytes` unless it already exists. The
// exclusive create means the first copy ever made is the one that stays.
function keepOriginal(dir, base, bytes) {
  const originalPath = path.join(dir, base + ORIGINAL_SUFFIX);
  try {
    const fd = fs.openSync(originalPath, 'wx', BACKUP_MODE);
    try {
      fs.writeFileSync(fd, bytes);
      if (process.platform !== 'win32') fs.fchmodSync(fd, BACKUP_MODE);
    } finally {
      fs.closeSync(fd);
    }
  } catch (err) {
    if (err.code !== 'EEXIST') {
      console.error(`  WARNING: could not keep ${base}${ORIGINAL_SUFFIX} (${err.message})`);
    }
  }
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
  keepOriginal(dir, base, fs.readFileSync(backupPath));
  try {
    pruneBackups(dir, base, path.basename(backupPath));
  } catch (err) {
    console.error(`  WARNING: could not prune old ${base} backups (${err.message})`);
  }
  return backupPath;
}

// Replaces `target` with `bytes` through a sibling temp file and a rename.
function writeAtomically(target, bytes, mode) {
  // A random suffix, so a stale temp file left by a killed run (and a reused pid)
  // can never make the exclusive create fail.
  const tmp = `${target}.${process.pid}.${crypto.randomBytes(6).toString('hex')}.tmp`;
  let fd;
  try {
    fd = fs.openSync(tmp, 'wx', mode);
  } catch (err) {
    // A directory that cannot take a new file but whose settings.json is
    // writable: write in place, as before, rather than fail the install.
    if (err.code === 'EACCES' || err.code === 'EPERM' || err.code === 'EROFS') {
      fs.writeFileSync(target, bytes);
      return;
    }
    throw err;
  }
  try {
    try {
      fs.writeFileSync(fd, bytes);
      if (process.platform !== 'win32') fs.fchmodSync(fd, mode);
      fs.fsyncSync(fd);
    } finally {
      fs.closeSync(fd);
    }
    fs.renameSync(tmp, target);
  } catch (err) {
    fs.rmSync(tmp, { force: true });
    throw err;
  }
}

// Writes `content` (a string) to settingsPath unless the file already holds
// exactly those bytes. Returns true when it wrote, so the caller can report the
// change, and false when it left the file alone.
function writeSettingsIfChanged(settingsPath, content) {
  const next = Buffer.from(content, 'utf8');
  const exists = fs.existsSync(settingsPath);
  // A symlinked settings.json is followed, so the link itself survives.
  const target = exists ? fs.realpathSync(settingsPath) : settingsPath;
  if (exists && fs.readFileSync(target).equals(next)) return false;
  const mode = exists ? fs.statSync(target).mode & 0o777 : NEW_FILE_MODE;
  backupSettings(target);
  writeAtomically(target, next, mode);
  return true;
}

module.exports = { writeSettingsIfChanged, backupSettings, SETTINGS_BACKUP_KEEP };
