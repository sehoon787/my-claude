#!/usr/bin/env node
//
// dedupe-karpathy.js — remove stale, unmarked Karpathy guideline blocks from
// a CLAUDE.md.
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

'use strict';
const fs = require('fs');

const MARKER = '<!-- my-claude:karpathy-guidelines -->';
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

const file = process.argv[2];
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
