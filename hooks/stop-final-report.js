#!/usr/bin/env node
'use strict';
// stop-final-report.js — require a structured final report when a request ends.
//
// Boss's prompt (boss.md § FINAL REPORT) defines WHAT the report looks like;
// this hook is the enforcement half: a prompt rule alone is advisory and the
// model can skip it, so the Stop hook checks the turn's actual final text and
// blocks once when the report is missing.
//
// Judgment inputs come straight from the harness:
//   - `last_assistant_message` (Stop hook input) is the final assistant text.
//   - "did work happen" is the delta of .briefing/state.json's workCounter
//     (incremented by the PostToolUse Edit|Write hook) since the last
//     acknowledged report, so a session-long counter doesn't re-trigger on
//     later chat-only turns.
//   - "is this the end of the request" comes from the transcript: the Stop
//     event fires after EVERY assistant turn, including turns that only relay
//     a background task / subagent completion. Those, and turns that just
//     launched background work, are mid-request by definition — the hook
//     never blocks there; it only records a report if one is present.
//     Enforcement happens on human-initiated turns that launched nothing.
//
// Loop safety (there is no built-in circuit breaker for Stop blocks):
//   - blocks at most ONCE per prompt_id; on the second Stop of the same turn
//     it acknowledges and lets the turn end even if the model ignored us.
//   - fails open on any error — a broken hook must never trap the session.
try {
  var fs = require('fs');
  var path = require('path');

  var BRIEFING_DIR = '.briefing';
  var INDEX_FILE = path.join(BRIEFING_DIR, 'INDEX.md');
  var STATE_FILE = path.join(BRIEFING_DIR, 'state.json');

  if (!fs.existsSync(INDEX_FILE)) { process.exit(0); }

  var input = {};
  try { input = JSON.parse(fs.readFileSync(0, 'utf8')); } catch (e) { process.exit(0); }

  // Older harnesses may not send last_assistant_message — nothing to judge.
  var lam = input.last_assistant_message;
  if (typeof lam !== 'string' || lam.length === 0) { process.exit(0); }

  var promptId = String(input.prompt_id || input.session_id || '');

  function readState() {
    try { return JSON.parse(fs.readFileSync(STATE_FILE, 'utf8')); } catch (e) { return {}; }
  }
  function writeState(update) {
    try {
      var s = readState();
      var fr = Object.assign({}, s.finalReport || {}, update);
      fs.writeFileSync(STATE_FILE, JSON.stringify(Object.assign({}, s, { finalReport: fr }), null, 2), 'utf8');
    } catch (e) {}
  }

  // Walk the transcript backwards to the entry that started this turn.
  //   human      — the turn began with a human prompt (origin.kind === 'human';
  //                notification / auto-continuation entries carry other kinds,
  //                and their text is recognisable as a fallback).
  //   background — a tool result in this turn launched background work
  //                (Agent run_in_background / Workflow / Bash background).
  function inspectTurn(transcriptPath) {
    var res = { human: true, background: false };
    try {
      if (!transcriptPath || !fs.existsSync(transcriptPath)) { return res; }
      var lines = fs.readFileSync(transcriptPath, 'utf8').split('\n');
      var launch = /Workflow launched in background|Spawned successfully|running in background/i;
      for (var i = lines.length - 1; i >= 0; i--) {
        if (!lines[i]) { continue; }
        var r; try { r = JSON.parse(lines[i]); } catch (e) { continue; }
        if (r.type !== 'user') { continue; }
        var c = r.message && r.message.content;
        var isToolResult = Array.isArray(c) && c.some(function (x) { return x && x.type === 'tool_result'; });
        if (isToolResult) {
          if (launch.test(JSON.stringify(c))) { res.background = true; }
          continue;
        }
        var kind = r.origin && r.origin.kind;
        if (kind) {
          res.human = kind === 'human';
        } else {
          var text = typeof c === 'string' ? c : JSON.stringify(c || '');
          res.human = !/<task-notification>|\[SYSTEM NOTIFICATION|<cross-session-message/.test(text);
        }
        break;
      }
    } catch (e) {}
    return res;
  }

  var state = readState();
  var wc = parseInt(state.workCounter, 10) || 0;
  var fr = state.finalReport || {};
  var acked = parseInt(fr.ackWorkCounter, 10) || 0;

  // No NEW work since the last acknowledged report → chat-only turn, pass.
  if (wc <= acked) { process.exit(0); }

  // Report present? Markdown table rows (at least a header + one data row)
  // or an explicit final-report heading — matching boss.md's spec.
  var tableRows = (lam.match(/^\s*\|.*\|\s*$/gm) || []).length;
  var hasHeading = /(^|\n)#{1,4}\s*.{0,24}(최종 보고|Final Report)/i.test(lam);
  if (tableRows >= 2 || hasHeading) {
    writeState({ ackWorkCounter: wc });
    process.exit(0);
  }

  // Mid-request turn (notification-triggered, or background work just
  // launched) → never block; the request is not over yet.
  var turn = inspectTurn(input.transcript_path);
  if (!turn.human || turn.background) { process.exit(0); }

  // Already blocked once this turn → give up gracefully (loop guard).
  if (promptId && fr.blockedPromptId === promptId) {
    writeState({ ackWorkCounter: wc });
    process.exit(0);
  }

  // Language from INDEX.md frontmatter.
  var isKo = false;
  try {
    var m = fs.readFileSync(INDEX_FILE, 'utf8').match(/^language:\s*(\S+)/m);
    isKo = !!m && (m[1] === 'ko' || m[1] === 'kr');
  } catch (e) {}

  var reason = isKo
    ? '[FinalReport] 이 요청의 작업이 끝났는데 최종 보고가 없습니다. 답변 마지막에 boss.md의 FINAL REPORT 규격대로 정리하세요: 해당되는 표만 골라 (변경 대조: 대상/Before/After/근거), (작업 요약: 항목/결과/근거), (검증 결과: 항목/기대/실제/판정), (산출물: PR/저장소/내용/상태), (남은 것: 항목/상태/다음 조치). 빈 표 금지, 표 이름과 헤더도 한국어로.'
    : '[FinalReport] Work happened for this request but the final report is missing. End your reply with the FINAL REPORT spec from boss.md: include only the applicable tables — Changes (Target/Before/After/Rationale), Work summary (Item/Result/Evidence), Verification (Item/Expected/Actual/Verdict), Deliverables (PR/Repo/Content/Status), Remaining (Item/Status/Next step). No empty tables.';

  writeState({ blockedPromptId: promptId });
  process.stdout.write(JSON.stringify({ decision: 'block', reason: reason }) + '\n');
  process.exit(0);
} catch (e) { process.exit(0); }
