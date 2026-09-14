#!/usr/bin/env node
// BriefingVault enforcer (UserPromptSubmit): warns at 3+ messages if no vault
// entries have been written today, suggests /boss-briefing after 5+, with a
// 5-minute cooldown on warnings.
//
// Extracted from an inline `node -e` command in hooks/hooks.json so the logic
// is testable and so it emits at most one hookSpecificOutput JSON document per
// run (the inline version could write two on the same stdout, which Claude
// Code rejects as invalid JSON).
'use strict';

const fs = require('fs');

const STATE_FILE = '.briefing/state.json';
const WARNING_COOLDOWN_MS = 300000;

function readState() {
  try {
    return JSON.parse(fs.readFileSync(STATE_FILE, 'utf8'));
  } catch {
    return {};
  }
}

function writeState(update) {
  const state = readState();
  Object.assign(state, update);
  fs.writeFileSync(STATE_FILE, JSON.stringify(state, null, 2));
}

function countTodayFiles(dir, today) {
  if (!fs.existsSync(dir)) return 0;
  return fs.readdirSync(dir).filter((f) => {
    if (f.indexOf('-auto') !== -1) return false;
    try {
      return fs.statSync(dir + '/' + f).mtime.toISOString().slice(0, 10) === today;
    } catch {
      return false;
    }
  }).length;
}

function emit(messages) {
  const text = messages.filter(Boolean).join(' ');
  if (!text) return;
  process.stdout.write(JSON.stringify({
    hookSpecificOutput: {
      hookEventName: 'UserPromptSubmit',
      additionalContext: text
    }
  }) + '\n');
}

function main() {
  if (!fs.existsSync('.briefing/INDEX.md')) return;

  const state = readState();
  const mc = (parseInt(state.sessionMessageCount, 10) || 0) + 1;
  writeState({ sessionMessageCount: mc });
  if (mc < 3) return;

  const lastWarning = state.lastVaultWarning || '';
  if (lastWarning && (Date.now() - new Date(lastWarning).getTime()) < WARNING_COOLDOWN_MS) return;

  const today = new Date().toISOString().slice(0, 10);
  const workCounter = parseInt(readState().workCounter, 10) || 0;

  const sessionCount = countTodayFiles('.briefing/sessions', today);
  const dlCount = countTodayFiles('.briefing/decisions', today) + countTodayFiles('.briefing/learnings', today);
  const total = sessionCount + dlCount;

  function tipMessage() {
    const lastSync = readState().lastVaultSync || '';
    const syncToday = lastSync && lastSync.slice(0, 10) === today;
    if (mc < 5 || syncToday) return null;
    return '[BriefingVault] Tip: run /boss-briefing to sync vault, update profile, and detect workflow patterns.';
  }

  if (total > 0 && sessionCount > 0) {
    const tip = tipMessage();
    if (tip) writeState({ lastVaultWarning: new Date().toISOString() });
    emit([tip]);
    return;
  }

  if (total > 0 && sessionCount === 0) {
    writeState({ lastVaultWarning: new Date().toISOString() });
    emit(['[BriefingVault] You have written ' + dlCount + ' decisions/learnings but no session summary yet. Write .briefing/sessions/' + today + '-<topic>.md to document this conversation.']);
    return;
  }

  writeState({ lastVaultWarning: new Date().toISOString() });
  const primary = mc >= 6
    ? '[BriefingVault] WARNING: ' + mc + ' messages exchanged, ' + workCounter + ' file edits, but 0 vault entries written today. Write a session summary, decision, or learning to .briefing/ to document your work.'
    : '[BriefingVault] REQUIRED: ' + mc + ' messages exchanged this session with ' + workCounter + ' file edits. Write at least one entry to .briefing/sessions/, .briefing/decisions/, or .briefing/learnings/ NOW. Template: ---\ndate: ' + today + '\ntype: session\ntags: [relevant]\n---\n# Session: <topic>\n\n## Summary\n(what was discussed/decided/learned)';
  emit([primary, tipMessage()]);
}

try {
  main();
} catch {
  // Fail open.
}
process.exit(0);
