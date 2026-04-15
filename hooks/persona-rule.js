#!/usr/bin/env node
// Persona rule CLI: list/accept/reject suggestions
// Runs synchronously — no async/await, ES5-compatible

var fs = require('fs');
var path = require('path');

var BRIEFING_DIR = '.briefing';
var PERSONA_DIR = path.join(BRIEFING_DIR, 'persona');
var SUGGESTIONS_FILE = path.join(PERSONA_DIR, 'suggestions.jsonl');
var RULES_DIR = path.join(PERSONA_DIR, 'rules');
var HOME_DIR = process.env.HOME || process.env.USERPROFILE || '';
var GLOBAL_RULES_DIR = path.join(HOME_DIR, '.claude', 'rules', 'persona');

var args = process.argv.slice(2);
var command = args[0] || '';
var agentType = args[1] || '';

// Guard: no vault = nothing to do
if (!fs.existsSync(BRIEFING_DIR)) {
  if (command === 'list') {
    process.stdout.write('No .briefing/ vault found.\n');
  }
  process.exit(0);
}

// Read suggestions.jsonl
function readSuggestions() {
  var suggestions = [];
  try {
    if (fs.existsSync(SUGGESTIONS_FILE)) {
      var raw = fs.readFileSync(SUGGESTIONS_FILE, 'utf8');
      var lines = raw.split('\n');
      for (var i = 0; i < lines.length; i++) {
        var line = lines[i].trim();
        if (!line) continue;
        try {
          suggestions.push(JSON.parse(line));
        } catch (e) {
          // skip malformed
        }
      }
    }
  } catch (e) {
    process.stderr.write('persona-rule: failed to read suggestions: ' + e.message + '\n');
  }
  return suggestions;
}

// Write suggestions back
function writeSuggestions(suggestions) {
  try {
    fs.mkdirSync(PERSONA_DIR, { recursive: true });
    var lines = [];
    for (var i = 0; i < suggestions.length; i++) {
      lines.push(JSON.stringify(suggestions[i]));
    }
    fs.writeFileSync(SUGGESTIONS_FILE, lines.join('\n') + '\n');
  } catch (e) {
    process.stderr.write('persona-rule: failed to write suggestions: ' + e.message + '\n');
  }
}

// LIST command
if (command === 'list') {
  var suggestions = readSuggestions();
  var pending = [];
  for (var i = 0; i < suggestions.length; i++) {
    if (suggestions[i].type === 'pending') {
      pending.push(suggestions[i]);
    }
  }
  if (pending.length === 0) {
    process.stdout.write('No pending suggestions.\n');
    process.exit(0);
  }
  process.stdout.write('Pending persona suggestions (' + pending.length + '):\n');
  for (var i = 0; i < pending.length; i++) {
    var s = pending[i];
    process.stdout.write('  ' + (i + 1) + '. [' + s.agent_type + '] ' + (s.message || '') + '\n');
  }
  process.exit(0);
}

// ACCEPT command
if (command === 'accept') {
  if (!agentType) {
    process.stdout.write('Usage: persona-rule.js accept <agent_type>\n');
    process.exit(0);
  }
  var suggestions = readSuggestions();
  var found = false;
  for (var i = 0; i < suggestions.length; i++) {
    if (suggestions[i].type === 'pending' && suggestions[i].agent_type === agentType) {
      suggestions[i].type = 'accepted';
      suggestions[i].accepted_at = new Date().toISOString();
      found = true;

      var count = suggestions[i].count || 0;

      // Rule content for ~/.claude/rules/persona/ (concise, actionable)
      var globalRuleContent = '# Agent Routing Preference: ' + agentType + '\n' +
        '\n' +
        'When choosing between agents for a task that matches `' + agentType + '`\'s capabilities,\n' +
        'prefer delegating to `' + agentType + '` over generic alternatives.\n' +
        '\n' +
        'This preference was auto-generated from usage patterns (' + count + ' calls in 7 days).\n' +
        'To remove: delete this file or run `node hooks/persona-rule.js reject ' + agentType + '`.\n';

      try {
        fs.mkdirSync(GLOBAL_RULES_DIR, { recursive: true });
        fs.writeFileSync(path.join(GLOBAL_RULES_DIR, 'prefer-' + agentType + '.md'), globalRuleContent);
      } catch (e) {
        process.stderr.write('persona-rule: failed to write global rule file: ' + e.message + '\n');
      }

      // Local reference/log in .briefing/persona/rules/
      var todayStr = new Date().toISOString().slice(0, 10);
      var localRuleContent = '---\n' +
        'date: ' + todayStr + '\n' +
        'type: persona-rule\n' +
        'agent_type: ' + agentType + '\n' +
        'source: auto-generated\n' +
        'status: active\n' +
        '---\n' +
        '# Routing Preference: ' + agentType + '\n' +
        '\n' +
        'When tasks match this agent\'s specialty, prefer delegating to `' + agentType + '`.\n' +
        'Auto-generated from usage pattern: used ' + count + ' times in 7 days.\n';

      try {
        fs.mkdirSync(RULES_DIR, { recursive: true });
        fs.writeFileSync(path.join(RULES_DIR, 'prefer-' + agentType + '.md'), localRuleContent);
      } catch (e) {
        process.stderr.write('persona-rule: failed to write local rule file: ' + e.message + '\n');
      }
      break;
    }
  }
  if (!found) {
    process.stdout.write('No pending suggestion found for agent_type: ' + agentType + '\n');
    process.exit(0);
  }
  writeSuggestions(suggestions);
  process.stdout.write('Accepted: ' + agentType + '. Rule created at:\n  - ~/.claude/rules/persona/prefer-' + agentType + '.md (active rule)\n  - .briefing/persona/rules/prefer-' + agentType + '.md (local log)\n');
  process.exit(0);
}

// REJECT command
if (command === 'reject') {
  if (!agentType) {
    process.stdout.write('Usage: persona-rule.js reject <agent_type>\n');
    process.exit(0);
  }
  var suggestions = readSuggestions();
  var found = false;
  var cooldownDate = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
  for (var i = 0; i < suggestions.length; i++) {
    if ((suggestions[i].type === 'pending' || suggestions[i].type === 'accepted') && suggestions[i].agent_type === agentType) {
      suggestions[i].type = 'rejected';
      suggestions[i].cooldown_until = cooldownDate.toISOString();
      found = true;
      break;
    }
  }

  // Remove rule files from both paths (in case previously accepted)
  var globalRulePath = path.join(GLOBAL_RULES_DIR, 'prefer-' + agentType + '.md');
  var localRulePath = path.join(RULES_DIR, 'prefer-' + agentType + '.md');
  var removedGlobal = false;
  var removedLocal = false;
  try { fs.unlinkSync(globalRulePath); removedGlobal = true; } catch (e) { /* not found is fine */ }
  try { fs.unlinkSync(localRulePath); removedLocal = true; } catch (e) { /* not found is fine */ }

  if (!found && !removedGlobal && !removedLocal) {
    process.stdout.write('No pending/accepted suggestion found for agent_type: ' + agentType + '\n');
    process.exit(0);
  }

  if (found) {
    writeSuggestions(suggestions);
  }
  var msg = 'Rejected: ' + agentType + '.';
  if (found) msg += ' Cooldown until ' + cooldownDate.toISOString().slice(0, 10) + '.';
  if (removedGlobal || removedLocal) msg += ' Rule files removed.';
  process.stdout.write(msg + '\n');
  process.exit(0);
}

// CLEAN command
if (command === 'clean') {
  var suggestions = readSuggestions();
  var cleaned = 0;
  var kept = [];
  var now = Date.now();
  var fourteenDays = 14 * 24 * 60 * 60 * 1000;
  for (var i = 0; i < suggestions.length; i++) {
    var s = suggestions[i];
    if (s.type !== 'pending') {
      kept.push(s);
      continue;
    }
    // Remove unknown agent_type regardless of age
    if (s.agent_type === 'unknown') {
      cleaned++;
      continue;
    }
    // Remove pending suggestions older than 14 days
    var ts = s.ts ? new Date(s.ts).getTime() : 0;
    if (ts > 0 && (now - ts) > fourteenDays) {
      cleaned++;
      continue;
    }
    kept.push(s);
  }
  writeSuggestions(kept);
  process.stdout.write('Cleaned ' + cleaned + ' stale suggestion(s). ' + kept.length + ' remaining.\n');
  process.exit(0);
}

// Unknown command or no command
process.stdout.write('Usage: persona-rule.js <list|accept|reject|clean> [agent_type]\n');
process.exit(0);
