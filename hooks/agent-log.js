#!/usr/bin/env node
// Persona vault subagent log (.briefing/agents/agent-log.jsonl).
//
//   map   PreToolUse Agent|Task. Appends display name -> subagent_type to
//         .briefing/agents/agent-types.jsonl. SubagentStop reports a named
//         agent's display name (e.g. "mc-reason-text") as its agent_type, so
//         without this the log keyed one-off names instead of agent types.
//         PreToolUse, because a foreground agent's SubagentStop fires before
//         its Agent call's PostToolUse; append-only, because parallel launches
//         would otherwise drop each other's entries.
//   stop  SubagentStop. Appends one log line with agent_type resolved through
//         that map; the display name is kept as `name` metadata only.
//
// Also exports the read-side helpers the persona scripts share:
// dedupeByAgentId (SubagentStop fires again every time a teammate goes idle)
// and installedAgentTypes / dismissUninstalledSuggestions (registry-backed).
// Prints nothing.
'use strict';
const fs = require('fs');
const path = require('path');

const AGENTS_DIR = path.join('.briefing', 'agents');
const INDEX_FILE = path.join('.briefing', 'INDEX.md');
const LOG_FILE = path.join(AGENTS_DIR, 'agent-log.jsonl');
const TYPES_FILE = path.join(AGENTS_DIR, 'agent-types.jsonl');
const STATE_FILE = path.join('.briefing', 'state.json');
const MAX_TYPE_LINES = 1000;
const KEEP_TYPE_LINES = 200;
const MAX_AGENT_DEPTH = 4;
const TASK_HINT_MAX = 120;
// Agent types Claude Code ships without an agent file, so the registry never
// lists them.
const BUILTIN_AGENT_TYPES = ['general-purpose', 'Explore', 'Plan', 'statusline-setup', 'claude-code-guide', 'claude', 'fork'];
const PHASES = { explore: 1, Explore: 1, research: 1, 'deep-research': 1, executor: 2, implementer: 2, 'general-purpose': 2, 'Senior Developer': 2, 'code-reviewer': 3, 'security-reviewer': 3, 'tdd-guide': 4, planner: 5, Plan: 5, architect: 5, debugger: 6 };
const PHASE_NAMES = ['', 'research', 'implement', 'review', 'test', 'plan', 'debug'];

function readJson(file, fallback) {
  try { return JSON.parse(fs.readFileSync(file, 'utf8')); } catch { return fallback; }
}

function readLines(file) {
  let text = '';
  try { text = fs.readFileSync(file, 'utf8'); } catch { return []; }
  return text.split('\n').filter((l) => l.trim());
}

function recordName(input) {
  if (!input || (input.tool_name !== 'Agent' && input.tool_name !== 'Task')) return;
  const ti = input.tool_input || {};
  if (!ti.name || !fs.existsSync(INDEX_FILE)) return;
  fs.mkdirSync(AGENTS_DIR, { recursive: true });
  const line = { name: String(ti.name), type: String(ti.subagent_type || 'general-purpose'), ts: new Date().toISOString() };
  fs.appendFileSync(TYPES_FILE, JSON.stringify(line) + '\n');
}

// Latest recorded type per display name.
function readTypeMap() {
  const map = new Map();
  for (const l of readLines(TYPES_FILE)) {
    try {
      const e = JSON.parse(l);
      if (e && e.name && e.type) map.set(e.name, e.type);
    } catch { /* skip malformed line */ }
  }
  return map;
}

// Keep the file small; runs rarely, from the SubagentStop path.
function compactTypeMap() {
  const lines = readLines(TYPES_FILE);
  if (lines.length <= MAX_TYPE_LINES) return;
  fs.writeFileSync(TYPES_FILE, lines.slice(-KEEP_TYPE_LINES).join('\n') + '\n');
}

function phaseOf(type) {
  return PHASE_NAMES[PHASES[type] || PHASES[type.split(':').pop()] || 0] || '';
}

function logStop(input) {
  if (!fs.existsSync(INDEX_FILE)) return;
  fs.mkdirSync(AGENTS_DIR, { recursive: true });
  const reported = input.agent_type || 'unknown';
  const mapped = readTypeMap().get(reported);
  const state = readJson(STATE_FILE, {}) || {};
  const seq = (parseInt(state.subagentSeq, 10) || 0) + 1;
  fs.writeFileSync(STATE_FILE, JSON.stringify(Object.assign({}, state, { subagentSeq: seq }), null, 2));
  const agentType = mapped || reported;
  const entry = {
    ts: new Date().toISOString(),
    agent_id: input.agent_id || 'unknown',
    agent_type: agentType,
    phase: phaseOf(agentType),
    seq,
    task_hint: (input.description || input.name || '').slice(0, TASK_HINT_MAX),
  };
  if (mapped) entry.name = reported;
  fs.appendFileSync(LOG_FILE, JSON.stringify(entry) + '\n');
  compactTypeMap();
}

// ---------------------------------------------------------------- read side

// First line per agent_id wins; lines without one are kept as they are.
function dedupeByAgentId(entries) {
  const seen = new Set();
  return entries.filter((e) => {
    if (!e.agent_id || e.agent_id === 'unknown') return true;
    if (seen.has(e.agent_id)) return false;
    seen.add(e.agent_id);
    return true;
  });
}

// Names of this project's .claude/agents/**/*.md agents. The registry is one
// global file built for whichever project last started a session, so the
// current project's own agents are read directly.
function projectAgentNames(cwd, parseFrontmatter) {
  const names = [];
  const walk = (dir, depth) => {
    if (depth > MAX_AGENT_DEPTH) return;
    let entries = [];
    try { entries = fs.readdirSync(dir, { withFileTypes: true }); } catch { return; }
    for (const e of entries) {
      const p = path.join(dir, e.name);
      if (e.isDirectory()) walk(p, depth + 1);
      else if (e.name.endsWith('.md')) {
        try {
          const fm = parseFrontmatter(fs.readFileSync(p, 'utf8'));
          if (fm && fm.name) names.push(fm.name);
        } catch { /* unreadable file is not an agent */ }
      }
    }
  };
  walk(path.join(cwd, '.claude', 'agents'), 0);
  return names;
}

// Set of agent types Boss can actually route to (registry ids and short
// names, this project's agents, and the built-ins), or null when the
// registry is unreadable, in which case callers must not filter anything.
function installedAgentTypes(registryPath, cwd) {
  let registryLib;
  try { registryLib = require('./build-registry.js'); } catch { return null; }
  const registry = readJson(registryPath || registryLib.defaultPaths().out, null);
  if (!registry || !Array.isArray(registry.agents) || !registry.agents.length) return null;
  const types = new Set(BUILTIN_AGENT_TYPES);
  for (const a of registry.agents) {
    if (a.id) types.add(a.id);
    if (a.name) types.add(a.name);
  }
  projectAgentNames(cwd || process.cwd(), registryLib.parseFrontmatter).forEach((n) => types.add(n));
  return types;
}

// Pending suggestions for an agent_type that is not installed (legacy one-off
// Agent display names) become "dismissed", with the reason on the record.
function dismissUninstalledSuggestions(suggestions, installed, nowIso) {
  let changed = false;
  const list = suggestions.map((s) => {
    if (!installed || s.type !== 'pending' || installed.has(s.agent_type)) return s;
    changed = true;
    return Object.assign({}, s, {
      type: 'dismissed',
      dismissed_at: nowIso,
      dismiss_reason: 'agent_type is not an installed agent type (a one-off Agent display name, not a subagent_type)',
    });
  });
  return { list, changed };
}

function main(mode) {
  let input = {};
  try { input = JSON.parse(fs.readFileSync(0, 'utf8') || '{}'); } catch { return; }
  if (mode === 'map') recordName(input);
  else if (mode === 'stop') logStop(input);
}

module.exports = { BUILTIN_AGENT_TYPES, dedupeByAgentId, dismissUninstalledSuggestions, installedAgentTypes };

if (require.main === module) {
  try { main(process.argv[2]); } catch { /* fail open: logging must never break a subagent */ }
}
