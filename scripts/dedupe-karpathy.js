#!/usr/bin/env node
//
// dedupe-karpathy.js — keep the Karpathy guideline block in a CLAUDE.md to
// exactly one copy, and (with --install) hold that copy at the pinned content.
//
// Pre-marker versions of install.sh re-appended the whole Karpathy block on
// every run (the content sniff looked for "karpathy", which the upstream text
// never contains), so real installs accumulated a dozen copies. install.sh now
// writes the marker below before the block it owns; this script deletes every
// copy that marker does not cover.
//
// A block is: a heading line that is exactly "# CLAUDE.md" or
// "# Karpathy Guidelines", whose next non-blank line starts with the upstream
// opener, through the upstream closing line. Anything else in the file — the
// OMC section, the user-customizations marker, the user's own sections — is
// left byte-for-byte alone.
//
// Usage: node scripts/dedupe-karpathy.js <path-to-CLAUDE.md>
// Exit 0 always (missing/unreadable file is a no-op); prints a line only when
// it actually rewrote the file.
//
// Usage: node scripts/dedupe-karpathy.js --install <path-to-CLAUDE.md> <content-file>
// Replaces the marked block with <content-file> in place, or appends it when
// the marker is absent. install.sh only ever passes a file whose checksum
// matched the pin, so a bumped pin reaches machines that already carry the
// block instead of being skipped. Writes only when the result differs, so a
// re-run at the same pin leaves the file byte-identical.

'use strict';
const fs = require('fs');

const MARKER = '<!-- my-claude:karpathy-guidelines -->';
// Written by --install so a later refresh knows where the block ends without
// having to recognise its body. Blocks appended before it existed are handled
// by markedRegion()'s legacy branch, once.
const END_MARKER = '<!-- /my-claude:karpathy-guidelines -->';
const HEADINGS = ['# CLAUDE.md', '# Karpathy Guidelines'];
const OPENER = 'Behavioral guidelines to reduce common LLM coding mistakes';
const CLOSER = '**These guidelines are working if:**';

// Returns the index of the block's last line, or -1 if `i` does not start one.
function blockEnd(lines, i) {
  if (!HEADINGS.includes(lines[i])) return -1;
  let j = i + 1;
  while (j < lines.length && lines[j].trim() === '') j++;
  if (j >= lines.length || !lines[j].startsWith(OPENER)) return -1;
  for (let k = j; k < lines.length; k++) {
    if (lines[k].startsWith(CLOSER)) return k;
    // A second heading before the closer means the first block was truncated.
    if (k > j && HEADINGS.includes(lines[k])) return -1;
  }
  return -1;
}

// The marker sits on its own line, one or two lines above the heading.
function isMarked(lines, i) {
  return (i >= 1 && lines[i - 1].trim() === MARKER) ||
         (i >= 2 && lines[i - 2].trim() === MARKER);
}

// The extent of the block install.sh owns: the marker line through the end
// marker. Returns null when the file carries no marker.
function markedRegion(lines) {
  const start = lines.findIndex((l) => l.trim() === MARKER);
  if (start < 0) return null;
  for (let k = start + 1; k < lines.length; k++) {
    if (lines[k].trim() === END_MARKER) return { start, end: k };
  }
  // Legacy block: marker, no end marker. Its body is the checksum-pinned text
  // an earlier install appended, so the usual heading → closing-line shape
  // finds it. Should a pin bump have changed that shape beyond recognition,
  // the block runs up to the next blank-line-separated top-level heading, or
  // to EOF — the block's own '# ' heading is the one at `h`, so any later one
  // starts a section the user owns. Trailing blank lines stay outside the
  // region, which keeps the surrounding spacing intact.
  let h = start + 1;
  while (h < lines.length && lines[h].trim() === '') h++;
  const end = blockEnd(lines, h);
  if (end >= 0) return { start, end };
  let last = lines.length - 1;
  for (let k = h + 1; k < lines.length; k++) {
    if (lines[k].startsWith('# ') && lines[k - 1].trim() === '') { last = k - 1; break; }
  }
  while (last > h && lines[last].trim() === '') last--;
  return { start, end: last };
}

// The exact serialisation of the block, for both the append and the replace
// path, so a re-run at the same pin produces a byte-identical file.
function blockText(content) {
  return [MARKER, '', content.replace(/\n+$/, ''), '', END_MARKER].join('\n');
}

// Returns `text` with the block set to `content`: replaced where it already
// sits, appended otherwise. Never touches a byte outside the block.
function install(text, content) {
  const block = blockText(content);
  const lines = text.split('\n');
  const region = markedRegion(lines);
  if (!region) return text + '\n' + block + '\n';
  return lines.slice(0, region.start).concat(block.split('\n'), lines.slice(region.end + 1)).join('\n');
}

function dedupe(text) {
  const lines = text.split('\n');

  // Pass 1 — locate every block and note whether any carries the marker.
  const blocks = [];
  for (let i = 0; i < lines.length; i++) {
    const end = blockEnd(lines, i);
    if (end < 0) continue;
    blocks.push({ start: i, end, marked: isMarked(lines, i) });
    i = end;
  }
  // With no marked block, every copy is stale: drop them all and let
  // install.sh append one marked copy afterwards.
  const anyMarked = blocks.some((b) => b.marked);
  const doomed = new Map();
  for (const b of blocks) {
    if (anyMarked && b.marked) continue;
    doomed.set(b.start, b.end);
  }
  if (doomed.size === 0) return { text, removed: 0 };

  // Pass 2 — rebuild, collapsing the blank line a removal would double up.
  const out = [];
  const blank = (s) => s !== undefined && s.trim() === '';
  for (let i = 0; i < lines.length; ) {
    if (doomed.has(i)) {
      i = doomed.get(i) + 1;
      while (i < lines.length && blank(lines[i]) && blank(out[out.length - 1])) i++;
      continue;
    }
    out.push(lines[i]);
    i++;
  }
  return { text: out.join('\n'), removed: doomed.size };
}

const argv = process.argv.slice(2);
if (argv[0] === '--install') {
  const [, target, contentFile] = argv;
  if (!target || !contentFile) {
    console.error('usage: node scripts/dedupe-karpathy.js --install <path-to-CLAUDE.md> <content-file>');
    process.exit(1);
  }
  const content = fs.readFileSync(contentFile, 'utf8');
  let before = '';
  try {
    before = fs.readFileSync(target, 'utf8');
  } catch (e) {
    before = ''; // No CLAUDE.md yet — the block creates it.
  }
  const after = install(before, content);
  if (after === before) {
    console.log('    Karpathy guidelines already current');
  } else {
    fs.writeFileSync(target, after);
    console.log(before.includes(MARKER)
      ? '    Karpathy guidelines refreshed'
      : '    Karpathy guidelines appended');
  }
  process.exit(0);
}

const file = argv[0];
if (!file) {
  console.error('usage: node scripts/dedupe-karpathy.js <path-to-CLAUDE.md>');
  process.exit(0);
}
let original;
try {
  original = fs.readFileSync(file, 'utf8');
} catch (e) {
  process.exit(0); // No CLAUDE.md yet — nothing to dedupe.
}
const result = dedupe(original);
if (result.removed > 0 && result.text !== original) {
  fs.writeFileSync(file, result.text);
  console.log(`dedupe: removed ${result.removed} duplicate Karpathy block(s)`);
}
