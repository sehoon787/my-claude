#!/usr/bin/env node
// Capability registry v2 — what Boss can route to on this machine.
//
// Collects agents and skills from every place Claude Code loads them:
//   global   ~/.claude/agents/**/*.md, ~/.claude/skills/*/SKILL.md
//   project  ./.claude/agents/**/*.md, ./.claude/skills/*/SKILL.md
//   plugin   agents/*.md and skills/*/SKILL.md of each ENABLED plugin
//            (settings.json enabledPlugins), addressed as <plugin>:<name>
// then ranks candidates for each intent in routing-map.json and writes
// ~/.omc/state/capability-registry.json (override: REGISTRY_OUT).
//
// The registry is rebuilt only when it is not version 2, was built for a
// different project, or any recorded source's mtime changed (a new or removed
// file changes its directory's mtime). SessionStart calls this with
// --summary to inject a compact per-intent routing table.
//
//   node build-registry.js [--summary] [--force]
'use strict';
const fs = require('fs');
const path = require('path');

const REGISTRY_VERSION = 2;
const SKILL_DESC_MAX = 200;
const AGENT_DESC_MAX = 400;
const CANDIDATES_PER_INTENT = 8;
const SUMMARY_TOP_N = 3;
const SUMMARY_MAX_CHARS = 6000; // ~1,500 tokens
const MAX_AGENT_DEPTH = 4;
const SCOPE_WEIGHT = { project: 3, global: 2, plugin: 1 };
const MEMBER_BASE = 1000;
const MEMBER_STEP = 10;
const KEYWORD_POINTS = 5;

function defaultPaths(overrides) {
  const home = process.env.HOME || process.env.USERPROFILE || require('os').homedir();
  const o = overrides || {};
  const h = o.home || home;
  return {
    home: h,
    cwd: o.cwd || process.cwd(),
    out: o.out || process.env.REGISTRY_OUT || path.join(h, '.omc', 'state', 'capability-registry.json'),
    mapPath: o.mapPath || process.env.ROUTING_MAP || path.join(__dirname, 'routing-map.json'),
  };
}

// ---------------------------------------------------------------- fs helpers

function statOrNull(p) {
  try { return fs.statSync(p); } catch { return null; }
}

function mtimeOf(p) {
  const st = statOrNull(p);
  return st ? st.mtimeMs : null;
}

function readJson(p) {
  try { return JSON.parse(fs.readFileSync(p, 'utf8')); } catch { return null; }
}

function listDir(p) {
  try { return fs.readdirSync(p); } catch { return []; }
}

// ---------------------------------------------------------------- frontmatter

function unquote(v) {
  const t = v.trim();
  if (t.length >= 2 && ((t[0] === '"' && t.endsWith('"')) || (t[0] === "'" && t.endsWith("'")))) {
    return t.slice(1, -1);
  }
  return t;
}

// Minimal YAML frontmatter reader: top-level `key: value` pairs, quoted
// values, and block scalars (`|`, `>`, `>-`) whose indented lines are joined.
function parseFrontmatter(text) {
  const m = /^---\r?\n([\s\S]*?)\r?\n---/.exec(text);
  if (!m) return null;
  const out = {};
  const lines = m[1].split(/\r?\n/);
  for (let i = 0; i < lines.length; i++) {
    const kv = /^([A-Za-z_][\w-]*):\s*(.*)$/.exec(lines[i]);
    if (!kv) continue;
    const key = kv[1];
    const raw = kv[2];
    if (/^[|>][-+]?\s*$/.test(raw)) {
      const block = [];
      while (i + 1 < lines.length && (/^\s+\S/.test(lines[i + 1]) || lines[i + 1].trim() === '')) {
        block.push(lines[++i].trim());
      }
      out[key] = block.filter(Boolean).join(' ');
    } else {
      out[key] = unquote(raw);
    }
  }
  return out;
}

function oneLine(s) {
  return String(s || '').replace(/\s+/g, ' ').trim();
}

function capDescription(desc, max) {
  const d = oneLine(desc);
  if (d.length <= max) return d;
  const sentenceEnd = d.indexOf('. ');
  if (sentenceEnd > 0 && sentenceEnd < max) return d.slice(0, sentenceEnd + 1);
  return d.slice(0, max - 1) + '…';
}

// ---------------------------------------------------------------- collectors

function collectAgentFiles(dir, depth, sources, acc) {
  if (depth > MAX_AGENT_DEPTH) return acc;
  const st = statOrNull(dir);
  if (!st || !st.isDirectory()) return acc;
  sources[dir] = st.mtimeMs;
  for (const name of listDir(dir).sort()) {
    const p = path.join(dir, name);
    const s = statOrNull(p);
    if (!s) continue;
    if (s.isDirectory()) collectAgentFiles(p, depth + 1, sources, acc);
    else if (name.endsWith('.md')) acc.push(p);
  }
  return acc;
}

function readItem(file, sources) {
  let text;
  try { text = fs.readFileSync(file, 'utf8'); } catch { return null; }
  sources[file] = mtimeOf(file);
  return parseFrontmatter(text);
}

function collectAgents(dir, scope, prefix, sources) {
  const agents = [];
  for (const file of collectAgentFiles(dir, 0, sources, [])) {
    const fm = readItem(file, sources);
    if (!fm || !fm.name) continue; // README/AGENTS.md style files are not agents
    const fullDesc = oneLine(fm.description);
    agents.push({
      id: prefix ? `${prefix}:${fm.name}` : fm.name,
      name: fm.name,
      kind: 'agent',
      scope,
      description: capDescription(fullDesc, AGENT_DESC_MAX),
      model: fm.model || '',
      _match: `${fm.name} ${fullDesc}`.toLowerCase(),
    });
  }
  return agents;
}

function collectSkills(dir, scope, prefix, sources) {
  const st = statOrNull(dir);
  if (!st || !st.isDirectory()) return [];
  sources[dir] = st.mtimeMs;
  const skills = [];
  for (const entry of listDir(dir).sort()) {
    const file = path.join(dir, entry, 'SKILL.md');
    if (!statOrNull(file)) continue;
    const fm = readItem(file, sources) || {};
    const name = fm.name || entry;
    const fullDesc = oneLine(fm.description);
    skills.push({
      id: prefix ? `${prefix}:${name}` : name,
      name,
      kind: 'skill',
      scope,
      description: capDescription(fullDesc, SKILL_DESC_MAX),
      _match: `${name} ${fullDesc}`.toLowerCase(),
    });
  }
  return skills;
}

function compareVersions(a, b) {
  const pa = a.split(/[.-]/).map((x) => parseInt(x, 10) || 0);
  const pb = b.split(/[.-]/).map((x) => parseInt(x, 10) || 0);
  for (let i = 0; i < Math.max(pa.length, pb.length); i++) {
    const d = (pa[i] || 0) - (pb[i] || 0);
    if (d !== 0) return d;
  }
  return 0;
}

// Resolve each enabled plugin to its install dir. installed_plugins.json's
// installPath is what Claude Code actually loads; the newest cached version
// dir is the fallback when that file is missing or points nowhere.
function enabledPluginRoots(home, sources) {
  const settingsPath = path.join(home, '.claude', 'settings.json');
  const installedPath = path.join(home, '.claude', 'plugins', 'installed_plugins.json');
  sources[settingsPath] = mtimeOf(settingsPath);
  sources[installedPath] = mtimeOf(installedPath);
  const enabled = (readJson(settingsPath) || {}).enabledPlugins || {};
  const installed = (readJson(installedPath) || {}).plugins || {};
  const roots = [];
  for (const [key, on] of Object.entries(enabled)) {
    if (on !== true) continue;
    const at = key.lastIndexOf('@');
    if (at <= 0) continue;
    const plugin = key.slice(0, at);
    const marketplace = key.slice(at + 1);
    const records = Array.isArray(installed[key]) ? installed[key] : [];
    let root = records.map((r) => r && r.installPath).find((p) => p && statOrNull(p));
    if (!root) {
      const base = path.join(home, '.claude', 'plugins', 'cache', marketplace, plugin);
      const versions = listDir(base).filter((v) => statOrNull(path.join(base, v))?.isDirectory());
      versions.sort(compareVersions);
      if (versions.length) root = path.join(base, versions[versions.length - 1]);
    }
    if (root) roots.push({ plugin, root });
  }
  return roots;
}

function collectMcpServers(home, cwd) {
  const names = new Set();
  for (const f of [path.join(home, '.claude', 'settings.json'), path.join(cwd, '.mcp.json')]) {
    const j = readJson(f);
    if (j && j.mcpServers && typeof j.mcpServers === 'object') Object.keys(j.mcpServers).forEach((k) => names.add(k));
  }
  return [...names];
}

// ---------------------------------------------------------------- ranking

// Adoption signal per (item, intent) — how often Boss actually routed this
// intent to this item. Stub until usage data is wired in; keep the signature.
function adoptionWeight(item, intent) { // eslint-disable-line no-unused-vars
  return 0;
}

function memberSpec(m) {
  return typeof m === 'string' ? { name: m, advisor: false } : { name: m.name, advisor: m.advisor === true };
}

function scopeKey(scope) {
  return scope.startsWith('plugin:') ? 'plugin' : scope;
}

// A bare member name matches an item whose id or short name equals it; a
// qualified name (plugin:name) must match the id exactly. Prefer project >
// global > plugin, then agents over skills.
function resolveMember(name, items) {
  const hits = items.filter((it) => (name.includes(':') ? it.id === name : it.id === name || it.name === name));
  hits.sort((a, b) => (SCOPE_WEIGHT[scopeKey(b.scope)] - SCOPE_WEIGHT[scopeKey(a.scope)])
    || (a.kind === b.kind ? 0 : a.kind === 'agent' ? -1 : 1));
  return hits[0] || null;
}

// Latin keywords match at a word start ("test" hits "testing", not "latest");
// others (Korean) match anywhere, since particles attach to the word.
function keywordMatcher(keyword) {
  const k = String(keyword).toLowerCase();
  if (!/^[\x00-\x7f]+$/.test(k)) return (text) => text.includes(k);
  const re = new RegExp(`(^|[^a-z0-9])${k.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}`);
  return (text) => re.test(text);
}

function countMatches(text, matchers) {
  return matchers.reduce((n, m) => n + (m(text) ? 1 : 0), 0);
}

function rankIntent(intent, items) {
  const byId = new Map();
  const add = (item, priority, advisor) => {
    const rank = priority + SCOPE_WEIGHT[scopeKey(item.scope)] + adoptionWeight(item, intent.name);
    const prev = byId.get(item.id);
    if (!prev || prev.rank < rank) {
      byId.set(item.id, { id: item.id, kind: item.kind, scope: item.scope, advisor: advisor || (prev ? prev.advisor : false), rank });
    }
  };
  (intent.members || []).map(memberSpec).forEach((m, i) => {
    const item = resolveMember(m.name, items);
    if (item) add(item, MEMBER_BASE - i * MEMBER_STEP, m.advisor);
  });
  const matchers = (intent.description_keywords || []).map(keywordMatcher);
  if (matchers.length) {
    for (const item of items) {
      const hits = countMatches(item._match, matchers);
      if (hits > 0 && !byId.has(item.id)) add(item, hits * KEYWORD_POINTS, false);
    }
  }
  // One entry per short name: a flat global copy and the plugin copy of the
  // same agent are the same choice for routing purposes.
  const seen = new Set();
  return [...byId.values()]
    .sort((a, b) => b.rank - a.rank || a.id.localeCompare(b.id))
    .filter((c) => {
      const short = `${c.kind}:${c.id.split(':').pop()}`;
      if (seen.has(short)) return false;
      seen.add(short);
      return true;
    })
    .slice(0, CANDIDATES_PER_INTENT);
}

// ---------------------------------------------------------------- build

function buildRegistry(overrides) {
  const p = defaultPaths(overrides);
  const sources = {};
  const agents = [
    ...collectAgents(path.join(p.cwd, '.claude', 'agents'), 'project', '', sources),
    ...collectAgents(path.join(p.home, '.claude', 'agents'), 'global', '', sources),
  ];
  const skills = [
    ...collectSkills(path.join(p.cwd, '.claude', 'skills'), 'project', '', sources),
    ...collectSkills(path.join(p.home, '.claude', 'skills'), 'global', '', sources),
  ];
  // Record the project .claude dir even when absent, so creating it later
  // invalidates the cache.
  const projectClaude = path.join(p.cwd, '.claude');
  sources[projectClaude] = mtimeOf(projectClaude);
  for (const { plugin, root } of enabledPluginRoots(p.home, sources)) {
    agents.push(...collectAgents(path.join(root, 'agents'), `plugin:${plugin}`, plugin, sources));
    skills.push(...collectSkills(path.join(root, 'skills'), `plugin:${plugin}`, plugin, sources));
  }
  sources[p.mapPath] = mtimeOf(p.mapPath);
  const map = readJson(p.mapPath) || { intents: [] };
  const items = [...agents, ...skills];
  const intents = (map.intents || []).map((intent) => ({
    name: intent.name,
    prompt_keywords: intent.prompt_keywords || [],
    candidates: rankIntent(intent, items),
  }));
  const strip = ({ _match, ...rest }) => rest; // eslint-disable-line no-unused-vars
  return {
    version: REGISTRY_VERSION,
    generated_at: new Date().toISOString(),
    project_root: p.cwd,
    sources,
    agents: agents.map(strip),
    skills: skills.map(strip),
    intents,
    mcp_servers: collectMcpServers(p.home, p.cwd),
    recommended_packs: [],
  };
}

function isFresh(registry, overrides) {
  const p = defaultPaths(overrides);
  if (!registry || registry.version !== REGISTRY_VERSION) return false;
  if (registry.project_root !== p.cwd) return false;
  const sources = registry.sources || {};
  if (!(p.mapPath in sources)) return false;
  return Object.entries(sources).every(([file, mtime]) => mtimeOf(file) === mtime);
}

// Returns { registry, status } where status is fresh | rebuilt | kept | failed.
function ensureRegistry(overrides, force) {
  const p = defaultPaths(overrides);
  const existing = readJson(p.out);
  if (!force && isFresh(existing, overrides)) return { registry: existing, status: 'fresh' };
  const registry = buildRegistry(overrides);
  // A scan that lands inside install.sh's delete-then-copy window sees zero
  // agents. Keep the previous registry rather than cache that; the changed
  // mtimes make the next session rescan.
  if (registry.agents.length === 0 && existing) return { registry: existing, status: 'kept' };
  try {
    fs.mkdirSync(path.dirname(p.out), { recursive: true });
    const tmp = `${p.out}.${process.pid}.tmp`;
    fs.writeFileSync(tmp, JSON.stringify(registry) + '\n');
    fs.renameSync(tmp, p.out);
    return { registry, status: 'rebuilt' };
  } catch {
    return { registry, status: 'failed' };
  }
}

// ---------------------------------------------------------------- summary

function formatCandidate(c) {
  const label = c.kind === 'skill' ? `/${c.id}` : c.id;
  return c.advisor ? `${label}[advisor]` : label;
}

function renderSummary(registry, registryPath) {
  const header = '[Routing] Top candidates per intent (agent = Agent tool subagent_type, /name = Skill; [advisor] = Advisor Group):';
  const footer = `[Routing] Full registry with descriptions: ${registryPath}`;
  const lines = (registry.intents || [])
    .filter((i) => i.candidates && i.candidates.length)
    .map((i) => `${i.name} → ${i.candidates.slice(0, SUMMARY_TOP_N).map(formatCandidate).join(', ')}`);
  // Drop the lowest intents (end of the map) until it fits the budget.
  while (lines.length && [header, ...lines, footer].join('\n').length > SUMMARY_MAX_CHARS) lines.pop();
  return [header, ...lines, footer].join('\n');
}

function main(argv) {
  const args = new Set(argv);
  const p = defaultPaths();
  const { registry, status } = ensureRegistry({}, args.has('--force'));
  if (args.has('--summary')) process.stdout.write(renderSummary(registry, p.out) + '\n');
  else process.stdout.write(`registry ${status}: ${p.out}\n`);
}

module.exports = {
  REGISTRY_VERSION,
  SUMMARY_MAX_CHARS,
  adoptionWeight,
  buildRegistry,
  countMatches,
  defaultPaths,
  ensureRegistry,
  formatCandidate,
  isFresh,
  keywordMatcher,
  parseFrontmatter,
  renderSummary,
};

if (require.main === module) {
  try { main(process.argv.slice(2)); } catch (e) { process.stderr.write(`build-registry: ${e.message}\n`); }
}
