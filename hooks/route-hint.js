#!/usr/bin/env node
// UserPromptSubmit hook: classify the prompt against the routing map's
// prompt_keywords (as cached in the capability registry) and inject a
// one-line hint naming the top candidates for that intent.
//
// Reads the registry SessionStart built; never rebuilds it (that would cost
// seconds on the prompt path). Emits nothing when no intent matches, for
// slash commands, and for task-notification / teammate messages. Any error
// fails open with no output.
//
// Also records the prompt's intent (or "unknown") in
// ~/.claude/.adoption/intent-<session>.json, so adoption-tracker.js can file
// the agents/skills run for this prompt under that intent.
'use strict';
const fs = require('fs');
const { countMatches, defaultPaths, formatCandidate, keywordMatcher } = require('./build-registry.js');
const { recordIntent } = require('./adoption-store.js');

const HINT_TOP_N = 3;
const MACHINE_MESSAGE = /^\s*<(task-notification|teammate-message)\b/;

function isRoutable(prompt) {
  if (typeof prompt !== 'string' || !prompt.trim()) return false;
  if (prompt.trimStart().startsWith('/')) return false;
  return !MACHINE_MESSAGE.test(prompt);
}

// Highest keyword score wins; ties go to the intent listed first in the map.
function classify(prompt, intents) {
  const text = prompt.toLowerCase();
  let best = null;
  let bestScore = 0;
  for (const intent of intents || []) {
    const score = countMatches(text, (intent.prompt_keywords || []).map(keywordMatcher));
    if (score > bestScore) { best = intent; bestScore = score; }
  }
  return best;
}

// Project-scope items belong to the project the registry was built in; drop
// them when this prompt comes from another project.
function candidatesFor(intent, registry, cwd) {
  const sameProject = registry.project_root === cwd;
  return (intent.candidates || [])
    .filter((c) => sameProject || c.scope !== 'project')
    .slice(0, HINT_TOP_N);
}

function routeHint(prompt, registry, cwd) {
  if (!registry || !isRoutable(prompt)) return null;
  const intent = classify(prompt, registry.intents);
  if (!intent) return null;
  const top = candidatesFor(intent, registry, cwd);
  if (!top.length) return null;
  let text = `[RouteHint] intent=${intent.name} → ${top.map(formatCandidate).join(', ')}.`;
  if (top.some((c) => c.advisor)) text += ' Advisor Gate: call the [advisor] candidate before answering, or write one line "Advisor skipped: <reason>".';
  return { hookSpecificOutput: { hookEventName: 'UserPromptSubmit', additionalContext: text } };
}

function main() {
  let input = {};
  try { input = JSON.parse(fs.readFileSync(0, 'utf8') || '{}'); } catch { return; }
  let registry = null;
  try { registry = JSON.parse(fs.readFileSync(defaultPaths().out, 'utf8')); } catch { /* no hint; intent unknown */ }
  if (isRoutable(input.prompt)) {
    const intent = registry ? classify(input.prompt, registry.intents) : null;
    try { recordIntent(null, input.session_id, intent ? intent.name : 'unknown'); } catch { /* hint still goes out */ }
  }
  const out = routeHint(input.prompt, registry, input.cwd || process.cwd());
  if (out) process.stdout.write(JSON.stringify(out) + '\n');
}

module.exports = { classify, isRoutable, routeHint };

if (require.main === module) {
  try { main(); } catch { /* fail open: never block a prompt */ }
}
