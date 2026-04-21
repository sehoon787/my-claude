#!/usr/bin/env node
'use strict';
try {
var fs = require('fs');
var path = require('path');
var BRIEFING_DIR = '.briefing';
var INDEX_FILE = path.join(BRIEFING_DIR, 'INDEX.md');
var STATE_FILE = path.join(BRIEFING_DIR, 'state.json');
var SESSIONS_DIR = path.join(BRIEFING_DIR, 'sessions');

if (!fs.existsSync(INDEX_FILE)) { process.exit(0); }

var todayStr = new Date().toISOString().slice(0, 10);
function readState() {
  try { return JSON.parse(fs.readFileSync(STATE_FILE, 'utf8')); } catch(e) { return {}; }
}

var state = readState();

// Check if boss-briefing was run today
var lastSync = state.lastVaultSync || '';
var syncToday = lastSync && lastSync.slice(0, 10) === todayStr;
if (syncToday) { process.exit(0); } // All good

// Check for meaningful activity
var wc = parseInt(state.workCounter, 10) || 0;
var mc = parseInt(state.sessionMessageCount, 10) || 0;
var hasAgent = false;
try {
  var agentLog = path.join(BRIEFING_DIR, 'agents', 'agent-log.jsonl');
  if (fs.existsSync(agentLog)) {
    hasAgent = fs.statSync(agentLog).mtime.toISOString().slice(0, 10) === todayStr;
  }
} catch(e) {}

// No meaningful activity → pass silently
if (wc === 0 && mc <= 2 && !hasAgent) { process.exit(0); }

// Detect language
var lang = 'en';
try {
  var idx = fs.readFileSync(INDEX_FILE, 'utf8');
  var lm = idx.match(/^language:\s*(\S+)/m);
  if (lm) lang = lm[1].trim();
} catch(e) {}
var isKo = (lang === 'ko' || lang === 'kr');

// Check for session summary as final safety net
var hasSession = false;
try {
  if (fs.existsSync(SESSIONS_DIR)) {
    hasSession = fs.readdirSync(SESSIONS_DIR).some(function(f) {
      return f.slice(0, 10) === todayStr && f.indexOf('-auto') === -1;
    });
  }
} catch(e) {}

// Block: meaningful work but no vault sync
var reason = isKo
  ? '[BriefingVault] /boss-briefing 미실행. 세션 종료 전 /boss-briefing을 실행하세요.'
  : '[BriefingVault] Run /boss-briefing before ending the session to sync your vault.';

// Session exists but boss-briefing not run — pass silently
// UserPromptSubmit hook already reminds about /boss-briefing during session
if (hasSession) { process.exit(0); }

process.stdout.write(JSON.stringify({ decision: 'block', reason: reason }) + '\n');
process.exit(0);
} catch(e) { process.exit(0); }
