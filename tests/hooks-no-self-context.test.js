#!/usr/bin/env node
// Regression guard: SubagentStop, TeammateIdle, TaskCompleted, and Stop hooks
// must never emit hookSpecificOutput.additionalContext. Claude Code delivers
// that additionalContext to the stopping subagent/teammate itself, not the
// leader — even though the text in this repo's hooks was written FOR the
// leader. That mismatch caused the same "advice for the leader" text to be
// re-injected into stopping subagents/teammates repeatedly (see
// fix/subagent-stop-context-loop). `node tests/hooks-no-self-context.test.js`
'use strict';
const fs = require('fs'), path = require('path');
const HOOKS_JSON = path.resolve(__dirname, '..', 'hooks', 'hooks.json');
const SELF_EVENTS = ['SubagentStop', 'TeammateIdle', 'TaskCompleted', 'Stop'];

const hooks = JSON.parse(fs.readFileSync(HOOKS_JSON, 'utf8')).hooks || {};

const results = [];
for (const event of SELF_EVENTS) {
  const groups = Array.isArray(hooks[event]) ? hooks[event] : [];
  const offenders = [];
  for (const group of groups) {
    for (const hook of Array.isArray(group.hooks) ? group.hooks : []) {
      const cmd = hook && hook.command;
      if (typeof cmd === 'string' && cmd.includes('additionalContext')) {
        offenders.push(cmd.slice(0, 80));
      }
    }
  }
  const ok = offenders.length === 0;
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${event} emits no additionalContext${ok ? '' : ` (found: ${offenders.join(', ')})`}`);
  results.push(ok);
}

const failed = results.filter((r) => !r).length;
console.log(failed ? `${failed} FAILED` : 'ALL PASSED');
process.exit(failed ? 1 : 0);
