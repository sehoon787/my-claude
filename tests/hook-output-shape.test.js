#!/usr/bin/env node
// Regression test for the two bugs that made Claude Code reject hook stdout:
//   1. hookSpecificOutput missing the required "hookEventName" field
//      (session-sync.js emitAdditionalContext()).
//   2. two JSON documents written to stdout in one run (the old inline
//      BriefingVault UserPromptSubmit enforcer in hooks/hooks.json).
//
// For every UserPromptSubmit/PostToolUse/SubagentStop/Stop/SessionStart
// command in hooks/hooks.json, runs it against a temp project + a synthetic
// (never real) $HOME and asserts stdout is either empty or exactly one JSON
// document, and that any hookSpecificOutput carries a hookEventName matching
// the firing event. `node tests/hook-output-shape.test.js`
//
// hooks/session-start.sh is intentionally NOT executed here: it does network
// installs (git clone, npm i -g) that are unsafe and irrelevant to hook JSON
// shape. It never writes hookSpecificOutput.
'use strict';
const fs = require('fs'), os = require('os'), path = require('path'), cp = require('child_process');

const REPO_ROOT = path.resolve(__dirname, '..');
const HOOKS_JSON_PATH = path.join(REPO_ROOT, 'hooks', 'hooks.json');
const hooksJson = JSON.parse(fs.readFileSync(HOOKS_JSON_PATH, 'utf8'));

function check(name, ok, detail) {
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? '  (' + detail + ')' : ''}`);
  return ok;
}

// -- locate a hook's raw command string in hooks.json, so this test stays
//    tied to the real file instead of a hand-copied duplicate. --
function findCommand(event, substr) {
  const groups = hooksJson.hooks[event] || [];
  for (const g of groups) {
    for (const h of g.hooks || []) {
      if ((h.command && h.command.includes(substr)) || (h.description && h.description.includes(substr))) {
        return h.command;
      }
    }
  }
  throw new Error(`no ${event} command/description containing: ${substr}`);
}

function tmpProject() {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'hook-shape-'));
  fs.mkdirSync(path.join(dir, '.briefing', 'sessions'), { recursive: true });
  fs.mkdirSync(path.join(dir, '.briefing', 'decisions'), { recursive: true });
  fs.mkdirSync(path.join(dir, '.briefing', 'learnings'), { recursive: true });
  fs.writeFileSync(path.join(dir, '.briefing', 'INDEX.md'), '---\nlanguage: en\n---\n# x\n');
  return dir;
}

function writeState(dir, state) {
  fs.writeFileSync(path.join(dir, '.briefing', 'state.json'), JSON.stringify(state || {}));
}

// A fresh, empty, never-real $HOME so nothing this test runs can touch the
// developer's actual ~/.claude or ~/.briefing.
const FAKE_HOME = fs.mkdtempSync(path.join(os.tmpdir(), 'hook-shape-home-'));

function baseEnv(extra) {
  return Object.assign({}, process.env, { HOME: FAKE_HOME, USERPROFILE: FAKE_HOME }, extra || {});
}

// Run an inline `node -e "..."` command exactly as extracted from hooks.json.
function runInlineNodeE(rawCommand, { cwd, input, env }) {
  const m = rawCommand.match(/node -e "([\s\S]*)"$/);
  if (!m) throw new Error('not an inline node -e command: ' + rawCommand);
  const script = m[1].replace(/\\"/g, '"');
  return cp.spawnSync('node', ['-e', script], {
    cwd, input: input || '{}', encoding: 'utf8', env: baseEnv(env)
  });
}

// Run a `node "$HOME/.claude/hooks/X.js" [arg]` / `echo '{}' | node ... [arg]`
// command against this repo's own copy of X.js (not whatever, if anything,
// happens to be installed for real on this machine).
function runResolvedFile(rawCommand, { cwd, input, env }) {
  const m = rawCommand.match(/\$HOME\/\.claude\/(hooks|scripts)\/([\w.-]+)"?(?:\s+(\w+))?/);
  if (!m) throw new Error('cannot resolve path from: ' + rawCommand);
  const resolved = path.join(REPO_ROOT, m[1], m[2]);
  const args = m[3] ? [m[3]] : [];
  const bin = resolved.endsWith('.sh') ? 'bash' : 'node';
  return cp.spawnSync(bin, [resolved, ...args], {
    cwd, input: input || '', encoding: 'utf8', env: baseEnv(env)
  });
}

// Run the raw command exactly through bash -c (for wrapper commands like the
// PostToolUse Agent-matcher analytics logger), with HOME faked so any `~`
// expansion lands in FAKE_HOME instead of the real home directory.
function runViaBash(rawCommand, { cwd, input, env }) {
  return cp.spawnSync('bash', ['-c', rawCommand], {
    cwd, input: input || '{}', encoding: 'utf8', env: baseEnv(env)
  });
}

const results = [];

function assertShape(label, event, result) {
  const stdout = result.stdout || '';
  const trimmed = stdout.trim();
  if (trimmed === '') {
    results.push(check(`${label} -> empty stdout ok`, true));
    return;
  }
  const lines = trimmed.split('\n').filter(Boolean);
  let parsed = null, parseOk = true;
  try { parsed = JSON.parse(trimmed); } catch { parseOk = false; }
  const singleDoc = lines.length === 1 && parseOk;
  results.push(check(`${label} -> single JSON document`, singleDoc, `stdout=${JSON.stringify(stdout)}`));
  if (singleDoc && parsed && parsed.hookSpecificOutput) {
    results.push(check(
      `${label} -> hookEventName === ${event}`,
      parsed.hookSpecificOutput.hookEventName === event,
      `got ${JSON.stringify(parsed.hookSpecificOutput.hookEventName)}`
    ));
  }
}

// ---------------------------------------------------------------- SessionStart

{
  const dir = tmpProject();
  const cmd = findCommand('SessionStart', 'validate-hooks.js');
  const r = runResolvedFile(cmd, { cwd: dir });
  assertShape('SessionStart validate-hooks.js (no settings.json)', 'SessionStart', r);
  fs.rmSync(dir, { recursive: true, force: true });
}

{
  const dir = tmpProject();
  const cmd = findCommand('SessionStart', 'context-budget.js" reset');
  const r = runResolvedFile(cmd, { cwd: dir });
  assertShape('SessionStart context-budget.js reset', 'SessionStart', r);
  fs.rmSync(dir, { recursive: true, force: true });
}

// ---------------------------------------------------------------- PostToolUse

{
  const dir = tmpProject();
  const cmd = findCommand('PostToolUse', 'gstack/analytics');
  const r = runViaBash(cmd, { cwd: dir, input: JSON.stringify({ tool_input: { name: 'executor', model: 'sonnet' } }) });
  assertShape('PostToolUse Agent analytics logger', 'PostToolUse', r);
  fs.rmSync(dir, { recursive: true, force: true });
}

{
  // Edit|Write BriefingVault edit-counter enforcer, tuned to trip the
  // counter>=3 && todayCount===0 REQUIRED branch.
  const dir = tmpProject();
  writeState(dir, { workCounter: 2, prevEntryCount: 0 });
  const cmd = findCommand('PostToolUse', 'BriefingVault enforcer: warns at 3 edits');
  const r = runInlineNodeE(cmd, { cwd: dir });
  assertShape('PostToolUse edit-counter enforcer (>=3 edits, 0 entries)', 'PostToolUse', r);
  fs.rmSync(dir, { recursive: true, force: true });
}

{
  const dir = tmpProject();
  const cmd = findCommand('PostToolUse', 'session-sync.js" edit');
  const r = runResolvedFile(cmd, { cwd: dir, input: '{}' });
  assertShape('PostToolUse session-sync.js edit', 'PostToolUse', r);
  fs.rmSync(dir, { recursive: true, force: true });
}

{
  const dir = tmpProject();
  const cmd = findCommand('PostToolUse', 'auto-links.md');
  const r = runInlineNodeE(cmd, { cwd: dir, input: JSON.stringify({ tool_input: { url: 'https://example.com' } }) });
  assertShape('PostToolUse web auto-link collector', 'PostToolUse', r);
  fs.rmSync(dir, { recursive: true, force: true });
}

{
  const dir = tmpProject();
  const cmd = findCommand('PostToolUse', 'session-sync.js" search');
  const r = runResolvedFile(cmd, { cwd: dir, input: JSON.stringify({ tool_input: { url: 'https://example.com' } }) });
  assertShape('PostToolUse session-sync.js search', 'PostToolUse', r);
  fs.rmSync(dir, { recursive: true, force: true });
}

// ---------------------------------------------------------------- SubagentStop

{
  const dir = tmpProject();
  const cmd = findCommand('SubagentStop', 'agent-log.jsonl');
  const r = runInlineNodeE(cmd, { cwd: dir, input: JSON.stringify({ agent_id: 'a1', agent_type: 'executor' }) });
  assertShape('SubagentStop agent-log writer', 'SubagentStop', r);
  fs.rmSync(dir, { recursive: true, force: true });
}

{
  const dir = tmpProject();
  const cmd = findCommand('SubagentStop', 'session-sync.js" subagent');
  const r = runResolvedFile(cmd, { cwd: dir, input: '{}' });
  assertShape('SubagentStop session-sync.js subagent', 'SubagentStop', r);
  fs.rmSync(dir, { recursive: true, force: true });
}

// ---------------------------------------------------------------- Stop

{
  const dir = tmpProject();
  const cmd = findCommand('Stop', 'stop-profile-update.js');
  const r = runResolvedFile(cmd, { cwd: dir, input: '{}' });
  assertShape('Stop stop-profile-update.js', 'Stop', r);
  fs.rmSync(dir, { recursive: true, force: true });
}

{
  // Meaningful work, no sync today, no session note today -> block.
  const dir = tmpProject();
  writeState(dir, { workCounter: 5, sessionMessageCount: 5 });
  const cmd = findCommand('Stop', 'stop-session-enforcement.js');
  const r = runResolvedFile(cmd, { cwd: dir, input: '{}' });
  assertShape('Stop stop-session-enforcement.js (blocks)', 'Stop', r);
  fs.rmSync(dir, { recursive: true, force: true });
}

{
  const dir = tmpProject();
  const cmd = findCommand('Stop', 'session-end.js');
  const r = runResolvedFile(cmd, { cwd: dir, input: '{}' });
  assertShape('Stop session-end.js', 'Stop', r);
  fs.rmSync(dir, { recursive: true, force: true });
}

{
  // Human turn, work happened, final message lacks the report table -> block.
  const dir = tmpProject();
  writeState(dir, { workCounter: 5, finalReport: { ackWorkCounter: 0 } });
  fs.writeFileSync(path.join(dir, 't.jsonl'), '\n');
  const cmd = findCommand('Stop', 'stop-final-report.js');
  const r = runResolvedFile(cmd, {
    cwd: dir,
    input: JSON.stringify({
      hook_event_name: 'Stop',
      prompt_id: 'p1',
      transcript_path: path.join(dir, 't.jsonl'),
      last_assistant_message: 'Done, no report table here.'
    })
  });
  assertShape('Stop stop-final-report.js (blocks)', 'Stop', r);
  fs.rmSync(dir, { recursive: true, force: true });
}

// ---------------------------------------------------------------- UserPromptSubmit

{
  const dir = tmpProject();
  writeState(dir, { profileUpdateCounter: 4, sessionMessageCount: 5 });
  const cmd = findCommand('UserPromptSubmit', 'throttled mid-session update');
  const r = runInlineNodeE(cmd, { cwd: dir });
  assertShape('UserPromptSubmit throttled profile-update', 'UserPromptSubmit', r);
  fs.rmSync(dir, { recursive: true, force: true });
}

{
  // The exact historical repro state: this used to write two JSON documents.
  const dir = tmpProject();
  writeState(dir, { sessionMessageCount: 5, workCounter: 3, lastVaultSync: '' });
  const cmd = findCommand('UserPromptSubmit', 'vault-enforcer.js');
  const r = runResolvedFile(cmd, { cwd: dir });
  assertShape('UserPromptSubmit vault-enforcer.js (>=5 msgs, no vault, no sync)', 'UserPromptSubmit', r);
  fs.rmSync(dir, { recursive: true, force: true });
}

{
  // Branch: vault entries exist today, no session note -> single message.
  const dir = tmpProject();
  writeState(dir, { sessionMessageCount: 4, workCounter: 1, lastVaultSync: '' });
  fs.writeFileSync(path.join(dir, '.briefing', 'decisions', 'x.md'), '# x\n');
  const cmd = findCommand('UserPromptSubmit', 'vault-enforcer.js');
  const r = runResolvedFile(cmd, { cwd: dir });
  assertShape('UserPromptSubmit vault-enforcer.js (entries, no session note)', 'UserPromptSubmit', r);
  fs.rmSync(dir, { recursive: true, force: true });
}

{
  // Branch: session note exists today, mc>=5, no sync -> Tip only.
  const dir = tmpProject();
  writeState(dir, { sessionMessageCount: 4, workCounter: 1, lastVaultSync: '' });
  fs.writeFileSync(path.join(dir, '.briefing', 'sessions', '2026-01-01-x.md'), '# x\n');
  fs.utimesSync(path.join(dir, '.briefing', 'sessions', '2026-01-01-x.md'), new Date(), new Date());
  const cmd = findCommand('UserPromptSubmit', 'vault-enforcer.js');
  const r = runResolvedFile(cmd, { cwd: dir });
  assertShape('UserPromptSubmit vault-enforcer.js (session note today, tip)', 'UserPromptSubmit', r);
  fs.rmSync(dir, { recursive: true, force: true });
}

{
  // Historical bug #2: session-sync.js prompt mode reminder had no hookEventName.
  const dir = tmpProject();
  writeState(dir, { promptCount: 5, workCounter: 1, sessionMessageCount: 5, lastVaultSync: '' });
  const cmd = findCommand('UserPromptSubmit', 'session-sync.js" prompt');
  const r = runResolvedFile(cmd, { cwd: dir, input: '{}' });
  assertShape('UserPromptSubmit session-sync.js prompt (reminder)', 'UserPromptSubmit', r);
  fs.rmSync(dir, { recursive: true, force: true });
}

{
  const dir = tmpProject();
  const cmd = findCommand('UserPromptSubmit', 'CalibratedResponse');
  const r = runInlineNodeE(cmd, { cwd: dir });
  assertShape('UserPromptSubmit CalibratedResponse', 'UserPromptSubmit', r);
  fs.rmSync(dir, { recursive: true, force: true });
}

{
  const dir = tmpProject();
  const cmd = findCommand('UserPromptSubmit', 'context-budget.js');
  const r = runResolvedFile(cmd, { cwd: dir, input: '{}', env: { MY_CLAUDE_COMPACT_EVERY: '1' } });
  assertShape('UserPromptSubmit context-budget.js (threshold)', 'UserPromptSubmit', r);
  fs.rmSync(dir, { recursive: true, force: true });
}

fs.rmSync(FAKE_HOME, { recursive: true, force: true });

const failed = results.filter((r) => !r).length;
console.log(failed ? `${failed} FAILED` : 'ALL PASSED');
process.exit(failed ? 1 : 0);
