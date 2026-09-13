#!/usr/bin/env node
// Context budget nudge.
//
// Long-lived sessions are the single largest driver of cached-token cost: every
// request re-sends the whole transcript. /clear throws that transcript away
// along with everything the session learned; /compact keeps a summary. This hook
// counts user prompts since the last compaction and, every N of them, prints one
// line reminding Boss to compact at the next task boundary.
//
// Modes (argv[2]):
//   prompt (default) — UserPromptSubmit: count, and emit the nudge on every Nth.
//   reset            — compaction happened: zero the counter, print nothing.
//
// Fail-open in every branch: a broken counter must never block a prompt.
'use strict';

const fs = require('fs');
const path = require('path');

const BRIEFING_DIR = '.briefing';
const INDEX_FILE = path.join(BRIEFING_DIR, 'INDEX.md');
const STATE_FILE = path.join(BRIEFING_DIR, 'state.json');
const COUNTER_KEY = 'promptsSinceCompact';
const DEFAULT_EVERY = 40;

function compactEvery() {
  const parsed = parseInt(process.env.MY_CLAUDE_COMPACT_EVERY || '', 10);
  if (!Number.isFinite(parsed) || parsed < 1) return DEFAULT_EVERY;
  return parsed;
}

function readState() {
  try {
    return JSON.parse(fs.readFileSync(STATE_FILE, 'utf8')) || {};
  } catch {
    return {};
  }
}

function writeState(state) {
  try {
    fs.writeFileSync(STATE_FILE, JSON.stringify(state, null, 2), 'utf8');
  } catch {}
}

function main() {
  // Same gate as the other vault hooks: no vault, no bookkeeping.
  if (!fs.existsSync(INDEX_FILE)) return;

  const mode = process.argv[2] === 'reset' ? 'reset' : 'prompt';
  const state = readState();

  if (mode === 'reset') {
    if (state[COUNTER_KEY]) {
      state[COUNTER_KEY] = 0;
      writeState(state);
    }
    return;
  }

  const previous = Number(state[COUNTER_KEY]);
  const count = (Number.isFinite(previous) && previous > 0 ? previous : 0) + 1;
  state[COUNTER_KEY] = count;
  writeState(state);

  const every = compactEvery();
  if (count % every !== 0) return;

  process.stdout.write(
    JSON.stringify({
      hookSpecificOutput: {
        hookEventName: 'UserPromptSubmit',
        additionalContext:
          '[ContextBudget] ' +
          count +
          ' prompts since the last compaction — at the next task boundary run /compact and keep: ' +
          'current task, decisions, open items, file paths.'
      }
    }) + '\n'
  );
}

try {
  main();
} catch {
  // Fail open.
}
process.exit(0);
