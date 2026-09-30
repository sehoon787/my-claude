#!/usr/bin/env node
// Regression test: scripts/merge-hooks.js must drop hooks that were removed
// from hooks/hooks.json (e.g. the SubagentStop/TeammateIdle/TaskCompleted
// additionalContext hooks removed in fix/subagent-stop-context-loop) from an
// existing ~/.claude/settings.json on the next merge, while leaving
// unrelated third-party hooks untouched. Also covers the codeburn usage
// guard (#193): its `codeburn guard hook <event>` commands sit on
// PreToolUse/SessionStart/Stop — the same three events my-claude ships its
// own hooks on — so a harness reinstall (a fresh `merge-hooks.js` run) must
// not drop them.
//
// chore/dedupe-hooks-rules: also covers the three inline `node -e` hooks
// removed because hooks/session-sync.js already performs the same work
// (workCounter double-increment on every edit, auto-links.md written twice
// per web search/fetch, profileUpdateCounter throttle run twice per
// prompt). Every one of them touches `.briefing/`, so merge-hooks.js's
// existing ownership-marker rule (OWNERSHIP_MARKERS includes '.briefing')
// already drops them on a reinstall with no code change to merge-hooks.js
// itself — this just asserts that stays true.
// `node tests/merge-hooks-removal.test.js`
'use strict';
const fs = require('fs'), os = require('os'), path = require('path'), cp = require('child_process');
const SCRIPT = path.resolve(__dirname, '..', 'scripts', 'merge-hooks.js');
const HOOKS_JSON = path.resolve(__dirname, '..', 'hooks', 'hooks.json');

const OLD_SETTINGS = {
  hooks: {
    // codeburn guard install --global writes exactly these three groups.
    PreToolUse: [
      { hooks: [{ type: 'command', command: 'codeburn guard hook pretooluse' }] },
    ],
    SessionStart: [
      { matcher: 'startup', hooks: [{ type: 'command', command: 'codeburn guard hook sessionstart' }] },
    ],
    Stop: [
      { hooks: [{ type: 'command', command: 'codeburn guard hook stop' }] },
    ],
    // The three inline `node -e` duplicates of session-sync.js edit/search/
    // prompt modes removed by chore/dedupe-hooks-rules: workCounter double-
    // increment (PostToolUse Edit|Write), auto-links.md double-write
    // (PostToolUse WebSearch|WebFetch), and the throttled profile-update
    // spawn (UserPromptSubmit). A pre-PR settings.json still has these.
    PostToolUse: [
      {
        matcher: 'Edit|Write',
        hooks: [
          { type: 'command', command: "node -e \"const fs=require('fs');const path=require('path');try{const briefingIdx='.briefing/INDEX.md';if(!fs.existsSync(briefingIdx)){process.exit(0)}const sf='.briefing/state.json';function rs(){try{return JSON.parse(fs.readFileSync(sf,'utf8'))}catch(e){return{}}}function ws(u){var s=rs();Object.assign(s,u);fs.writeFileSync(sf,JSON.stringify(s,null,2))}var st=rs();var counter=(parseInt(st.workCounter,10)||0)+1;ws({workCounter:counter});const today=new Date().toISOString().slice(0,10);let todayCount=0;for(const sub of['decisions','learnings']){const d='.briefing/'+sub;if(fs.existsSync(d)){todayCount+=fs.readdirSync(d).filter(f=>{try{return fs.statSync(d+'/'+f).mtime.toISOString().slice(0,10)===today}catch(e){return false}}).length}}var prev=parseInt(rs().prevEntryCount,10)||0;ws({prevEntryCount:todayCount});if(counter>=10&&todayCount===0){process.stdout.write(JSON.stringify({hookSpecificOutput:{hookEventName:'PostToolUse',additionalContext:'[BriefingVault] WARNING: '+counter+' file edits this session, 0 decisions/learnings written to .briefing/. Write at least one entry to .briefing/decisions/ or .briefing/learnings/ to document your work.'}})+'\\n')}else if(counter>=3&&todayCount===0){process.stdout.write(JSON.stringify({hookSpecificOutput:{hookEventName:'PostToolUse',additionalContext:'[BriefingVault] REQUIRED: You have made '+counter+' file edits this session and written no decisions/learnings to .briefing/. Write at least one decision or learning NOW before continuing. See rules/common/knowledge-vault.md.'}})+'\\n')}process.exit(0)}catch(e){process.exit(0)}\"", timeout: 5000 },
          { type: 'command', command: 'some-unrelated-edit-hook --do-thing', timeout: 5000 },
        ],
      },
      {
        matcher: 'WebSearch|WebFetch',
        hooks: [
          { type: 'command', command: "node -e \"const fs=require('fs');try{if(!fs.existsSync('.briefing/INDEX.md')){process.exit(0)}const j=JSON.parse(require('fs').readFileSync(0,'utf8'));const url=j.tool_input&&(j.tool_input.url||j.tool_input.query||'');if(!url){process.exit(0)}const f='.briefing/references/auto-links.md';fs.mkdirSync('.briefing/references',{recursive:true});var existing='';if(fs.existsSync(f)){existing=fs.readFileSync(f,'utf8')}var line='- '+new Date().toISOString().slice(0,10)+' '+url;if(existing.indexOf(url)===-1){fs.appendFileSync(f,line+'\\n')}}catch(e){process.exit(0)}\"", timeout: 5000 },
        ],
      },
    ],
    UserPromptSubmit: [
      {
        hooks: [
          { type: 'command', command: "node -e \"const fs=require('fs');const cp=require('child_process');try{if(!fs.existsSync('.briefing/INDEX.md')){process.exit(0)}const sf='.briefing/state.json';function rs(){try{return JSON.parse(fs.readFileSync(sf,'utf8'))}catch(e){return{}}}function ws(u){var s=rs();Object.assign(s,u);fs.writeFileSync(sf,JSON.stringify(s,null,2))}var st=rs();var counter=(parseInt(st.profileUpdateCounter,10)||0)+1;var smc=parseInt(st.sessionMessageCount,10)||1;if(smc===0||counter>=5){ws({profileUpdateCounter:counter>=5?0:counter});const stub=JSON.stringify({agent_id:'user-prompt-submit',agent_type:'throttled-update'});cp.spawnSync(process.execPath,[(process.env.HOME||process.env.USERPROFILE)+'/.claude/hooks/stop-profile-update.js'],{input:stub,stdio:['pipe','ignore','ignore'],timeout:9000})}else{ws({profileUpdateCounter:counter})}}catch(e){process.exit(0)}\"", timeout: 10000 },
          { type: 'command', command: 'some-unrelated-prompt-hook --do-thing', timeout: 5000 },
        ],
      },
    ],
    TeammateIdle: [
      {
        hooks: [
          {
            type: 'command',
            command: "node -e \"console.log(JSON.stringify({hookSpecificOutput:{hookEventName:'TeammateIdle',additionalContext:'Teammate idle.'}}))\"",
            timeout: 5000,
          },
        ],
      },
    ],
    TaskCompleted: [
      {
        hooks: [
          {
            type: 'command',
            command: "node -e \"console.log(JSON.stringify({hookSpecificOutput:{hookEventName:'TaskCompleted',additionalContext:'Task completed.'}}))\"",
            timeout: 5000,
          },
        ],
      },
    ],
    SubagentStop: [
      {
        hooks: [
          {
            type: 'command',
            command: "node -e \"console.log(JSON.stringify({hookSpecificOutput:{hookEventName:'SubagentStop',additionalContext:'VERIFICATION REQUIRED.'}}))\"",
            timeout: 5000,
          },
          { type: 'command', command: 'some-unrelated-user-hook --do-thing', timeout: 5000 },
        ],
      },
    ],
  },
};

function run(name, fn) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'mhr-'));
  const home = path.join(dir, 'home');
  fs.mkdirSync(path.join(home, '.claude'), { recursive: true });
  fs.writeFileSync(path.join(home, '.claude', 'settings.json'), JSON.stringify(OLD_SETTINGS, null, 2));
  cp.spawnSync('node', [SCRIPT, HOOKS_JSON], { env: { ...process.env, HOME: home }, encoding: 'utf8' });
  const settings = JSON.parse(fs.readFileSync(path.join(home, '.claude', 'settings.json'), 'utf8'));
  const ok = fn(settings);
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}`);
  fs.rmSync(dir, { recursive: true, force: true });
  return ok;
}

const results = [
  run('removed hook events are dropped', (s) => !s.hooks.TeammateIdle && !s.hooks.TaskCompleted),
  run('stale SubagentStop additionalContext hook is dropped', (s) =>
    (s.hooks.SubagentStop || []).every((g) => (g.hooks || []).every((h) => !h.command.includes('additionalContext')))),
  run('unrelated third-party hook is preserved', (s) =>
    (s.hooks.SubagentStop || []).some((g) => (g.hooks || []).some((h) => h.command === 'some-unrelated-user-hook --do-thing'))),
  run('codeburn guard PreToolUse hook survives a reinstall', (s) =>
    (s.hooks.PreToolUse || []).some((g) => (g.hooks || []).some((h) => h.command === 'codeburn guard hook pretooluse'))),
  run('codeburn guard SessionStart hook survives a reinstall', (s) =>
    (s.hooks.SessionStart || []).some((g) => (g.hooks || []).some((h) => h.command === 'codeburn guard hook sessionstart'))),
  run('codeburn guard Stop hook survives a reinstall', (s) =>
    (s.hooks.Stop || []).some((g) => (g.hooks || []).some((h) => h.command === 'codeburn guard hook stop'))),
  run('my-claude\'s own PreToolUse hook is still installed alongside the guard', (s) =>
    (s.hooks.PreToolUse || []).some((g) => (g.hooks || []).some((h) => h.command.includes('BOSS PROTOCOL')))),
  run('stale inline workCounter-increment hook (Edit|Write) is dropped', (s) =>
    (s.hooks.PostToolUse || []).every((g) => (g.hooks || []).every((h) => !h.command.includes('workCounter:counter')))),
  run('stale inline auto-links.md hook (WebSearch|WebFetch) is dropped', (s) =>
    (s.hooks.PostToolUse || []).every((g) => (g.hooks || []).every((h) => !h.command.includes("f='.briefing/references/auto-links.md'")))),
  run('stale inline throttled profile-update hook (UserPromptSubmit) is dropped', (s) =>
    (s.hooks.UserPromptSubmit || []).every((g) => (g.hooks || []).every((h) => !h.command.includes('profileUpdateCounter')))),
  run('session-sync.js edit hook is present after the merge', (s) =>
    (s.hooks.PostToolUse || []).some((g) => g.matcher === 'Edit|Write' &&
      (g.hooks || []).some((h) => h.command.includes('session-sync.js" edit')))),
  run('session-sync.js search hook is present after the merge', (s) =>
    (s.hooks.PostToolUse || []).some((g) => g.matcher === 'WebSearch|WebFetch' &&
      (g.hooks || []).some((h) => h.command.includes('session-sync.js" search')))),
  run('session-sync.js prompt hook is present after the merge', (s) =>
    (s.hooks.UserPromptSubmit || []).some((g) => (g.hooks || []).some((h) => h.command.includes('session-sync.js" prompt')))),
  run('unrelated PostToolUse Edit|Write hook is preserved', (s) =>
    (s.hooks.PostToolUse || []).some((g) => g.matcher === 'Edit|Write' &&
      (g.hooks || []).some((h) => h.command === 'some-unrelated-edit-hook --do-thing'))),
  run('unrelated UserPromptSubmit hook is preserved', (s) =>
    (s.hooks.UserPromptSubmit || []).some((g) => (g.hooks || []).some((h) => h.command === 'some-unrelated-prompt-hook --do-thing'))),
];
const failed = results.filter((r) => !r).length;
console.log(failed ? `${failed} FAILED` : 'ALL PASSED');
process.exit(failed ? 1 : 0);
