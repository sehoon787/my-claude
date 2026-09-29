#!/usr/bin/env node
// Usage: node scripts/codeburn-guard-policy.js
//
// Disables codeburn guard's $15 default hard cap right after
// `codeburn guard install --global`.
//
// Root cause: the guard estimates session cost from the transcript at API
// list-price rates ("Plan: none, API-pricing view"), so a subscription
// session reaches the $15 default in minutes — then every further tool call
// is denied (codeburn 0.9.23, dist/main.js: the hardUSD check in
// handlePreToolUse). Only the *default* cap is touched here: a value the
// user set themselves (anything other than the default 15) is left exactly
// as it is. Non-fatal: any failure here must not fail install.sh.
//
// Prints one line to stdout summarizing the result ("hard cap off" or
// "hard cap $<N>") for install.sh to fold into its summary. Diagnostics go
// to stderr so they still stream live under a `$(...)` capture.
'use strict';
const fs = require('fs');
const path = require('path');

const DEFAULT_HARD_USD = 15;

function log(msg) {
  console.error(`  ${msg}`);
}

function guardConfigDir() {
  const home = process.env.HOME || process.env.USERPROFILE;
  const base = process.env.XDG_CONFIG_HOME || path.join(home, '.config');
  return path.join(base, 'codeburn');
}

function writeGuardJson(dir, guardJsonPath, data) {
  fs.mkdirSync(dir, { recursive: true });
  const tmpPath = `${guardJsonPath}.${process.pid}.tmp`;
  fs.writeFileSync(tmpPath, JSON.stringify(data, null, 2) + '\n', 'utf8');
  fs.renameSync(tmpPath, guardJsonPath);
}

function main() {
  const dir = guardConfigDir();
  const guardJsonPath = path.join(dir, 'guard.json');

  let guard;
  try {
    guard = JSON.parse(fs.readFileSync(guardJsonPath, 'utf8'));
  } catch (err) {
    if (err.code === 'ENOENT') {
      guard = null;
    } else {
      log(`codeburn guard.json unreadable, leaving it alone (${err.message})`);
      process.exitCode = 1;
      return;
    }
  }

  if (guard === null) {
    const fresh = {
      softUSD: 5,
      hardUSD: null,
      checkpointUSD: 3,
      openerEnabled: true,
      updatedAt: new Date().toISOString(),
    };
    writeGuardJson(dir, guardJsonPath, fresh);
    log('codeburn guard.json created with the hard cap off (cost is a list-price estimate on subscriptions)');
    console.log('hard cap off');
    return;
  }

  const isDefaultCap = guard.hardUSD === undefined || guard.hardUSD === DEFAULT_HARD_USD;
  if (!isDefaultCap) {
    const label = guard.hardUSD === null ? 'off' : `$${guard.hardUSD}`;
    log(`codeburn guard hardUSD already customized (${label}) — left as is`);
    console.log(guard.hardUSD === null ? 'hard cap off' : `hard cap $${guard.hardUSD}`);
    return;
  }

  const updated = { ...guard, hardUSD: null };
  writeGuardJson(dir, guardJsonPath, updated);
  log('codeburn guard hard cap disabled (cost is a list-price estimate on subscriptions; edit guard.json to set one)');
  console.log('hard cap off');
}

main();
