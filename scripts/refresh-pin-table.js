#!/usr/bin/env node
/**
 * Refresh the "Bundled Upstream Versions" table in README.md and every
 * docs/i18n/README.*.md from upstream/SOURCES.json.
 *
 * The manifest is the single source of truth: scripts/refresh-sources-pins.js
 * re-pins it from the submodule pointers on every sync, and this script then
 * carries those pins into the docs so the table cannot go stale between syncs.
 *
 * Rows are located structurally, not by heading text: a pin row is a 4-cell
 * row whose first cell links to a repo, whose second cell is a backticked
 * short sha (optionally annotated with a `tag`), whose third cell is an ISO
 * date, and whose fourth cell links to <same repo>/compare/<sha>...HEAD. That
 * shape is identical in all six translations, so no translated heading — and
 * no translated link label — has to be hardcoded, and the other tables that
 * also link to these repos (the tool overview, the skill counts) never match.
 *
 * Only the sha, the date and the compare target change; cell spacing, link
 * labels and the archify-style "(`v2.9.0`)" annotation are preserved. A
 * manifest entry with no row in the table is left alone rather than inserted.
 *
 * Usage: node scripts/refresh-pin-table.js
 */

'use strict';

const fs = require('fs');
const path = require('path');

const REPO_ROOT = path.resolve(__dirname, '..');
const SOURCES_FILE = path.join(REPO_ROOT, 'upstream', 'SOURCES.json');
const I18N_DIR = path.join(REPO_ROOT, 'docs', 'i18n');

// github.com/o/r, github.com/o/r/ and github.com/o/r.git are the same repo.
function normalizeRepo(url) {
  return url.replace(/\.git$/, '').replace(/\/+$/, '');
}

// A row of the pin table, or null for every other line in the file.
function parsePinRow(line) {
  const trimmed = line.trimEnd();
  if (!trimmed.startsWith('| ') || !trimmed.endsWith(' |')) return null;
  const cells = trimmed.slice(1, -1).split('|');
  if (cells.length !== 4) return null;
  // Rebuild-equality guard: only touch rows laid out exactly as we would
  // re-emit them, so an unfamiliar row is skipped instead of reformatted.
  const inner = cells.map((c) => c.trim());
  if ('| ' + inner.join(' | ') + ' |' !== trimmed) return null;

  const repoLink = inner[0].match(/^\[[^\]]+\]\((https:\/\/[^\s)]+)\)$/);
  if (!repoLink) return null;
  const pin = inner[1].match(/^`([0-9a-f]{7,40})`(?: \(`([^`]+)`\))?$/);
  if (!pin) return null;
  if (!/^\d{4}-\d{2}-\d{2}$/.test(inner[2])) return null;
  const diff = inner[3].match(/^\[([^\]]+)\]\((https:\/\/[^\s)]+)\/compare\/([0-9a-f]{7,40})\.\.\.HEAD\)$/);
  if (!diff) return null;
  if (normalizeRepo(diff[2]) !== normalizeRepo(repoLink[1])) return null;

  return {
    cells: inner,
    repo: normalizeRepo(repoLink[1]),
    sha: pin[1],
    tag: pin[2] || null,
    diffLabel: diff[1],
    diffRepo: diff[2],
    diffSha: diff[3],
  };
}

function renderRow(row, entry) {
  const sha = entry.pinned_sha.slice(0, row.sha.length);
  // A tag in the manifest wins; otherwise an existing annotation survives only
  // while the sha it labels does, since a moved pin invalidates the release.
  let tag = null;
  if (typeof entry.pinned_tag === 'string') tag = entry.pinned_tag;
  else if (row.tag && sha === row.sha) tag = row.tag;

  const cells = [
    row.cells[0],
    '`' + sha + '`' + (tag ? ' (`' + tag + '`)' : ''),
    entry.pinned_date,
    `[${row.diffLabel}](${row.diffRepo}/compare/${entry.pinned_sha.slice(0, row.diffSha.length)}...HEAD)`,
  ];
  return '| ' + cells.join(' | ') + ' |';
}

const sources = JSON.parse(fs.readFileSync(SOURCES_FILE, 'utf8'));

// repo url -> manifest entry, for entries that carry both a pin and a date.
const byRepo = {};
for (const entry of Object.values(sources)) {
  if (!entry || typeof entry !== 'object') continue;
  if (typeof entry.repo !== 'string') continue;
  if (typeof entry.pinned_sha !== 'string' || typeof entry.pinned_date !== 'string') continue;
  byRepo[normalizeRepo(entry.repo)] = entry;
}

const files = [path.join(REPO_ROOT, 'README.md')];
if (fs.existsSync(I18N_DIR)) {
  for (const name of fs.readdirSync(I18N_DIR).sort()) {
    if (/^README\..+\.md$/.test(name)) files.push(path.join(I18N_DIR, name));
  }
}

const changed = [];
for (const file of files) {
  if (!fs.existsSync(file)) continue;
  const raw = fs.readFileSync(file, 'utf8');
  const lines = raw.split('\n');
  let touched = false;

  for (let i = 0; i < lines.length; i++) {
    const row = parsePinRow(lines[i]);
    if (!row) continue;
    const entry = byRepo[row.repo];
    if (!entry) continue;
    const next = renderRow(row, entry);
    if (next === lines[i]) continue;
    changed.push(`${path.relative(REPO_ROOT, file)}: ${row.repo.split('/').pop()} ${row.sha} -> ${entry.pinned_sha.slice(0, row.sha.length)}`);
    lines[i] = next;
    touched = true;
  }

  if (touched) fs.writeFileSync(file, lines.join('\n'));
}

if (!changed.length) {
  console.log('[refresh-pin-table] all pin rows current');
} else {
  console.log('[refresh-pin-table] updated:\n  ' + changed.join('\n  '));
}
