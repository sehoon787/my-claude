// my-claude named workflow — invoke via Workflow({name: "upstream-audit"})
// args (optional): array of upstream names, e.g. ["ecc","gstack"]. Defaults to all bundled upstreams.
// Run from the my-claude (or my-codex) repo root so upstream/ submodules are reachable.
export const meta = {
  name: 'upstream-audit',
  description: 'Per-upstream health/overlap/delta audit of bundled submodules, then a synthesized keep/reduce/remove verdict',
  whenToUse: 'Quarterly (or pre-sync-merge) audit of upstream bundles: what changed since the pinned SHA, does the allowlist still fit, any new overlap or security signals',
  phases: [
    { title: 'Analyze', detail: 'one analyst per upstream' },
    { title: 'Synthesize', detail: 'cross-upstream verdict' },
  ],
}

const DEFAULT_UPSTREAMS = ['ecc', 'omc', 'gstack', 'superpowers']
const upstreams = Array.isArray(args) && args.length ? args : DEFAULT_UPSTREAMS

const AUDIT = {
  type: 'object',
  properties: {
    upstream: { type: 'string' },
    pinned_sha: { type: 'string' },
    remote_delta: { type: 'string' },
    allowlist_fit: { type: 'string' },
    new_overlaps: { type: 'array', items: { type: 'string' } },
    security_signals: { type: 'array', items: { type: 'string' } },
    health: { type: 'string' },
    verdict: { type: 'string', enum: ['keep', 'keep-reduced', 'demote', 'remove', 'bump-recommended'] },
    rationale: { type: 'string' },
  },
  required: ['upstream', 'pinned_sha', 'remote_delta', 'allowlist_fit', 'health', 'verdict', 'rationale'],
}

const SYNTHESIS = {
  type: 'object',
  properties: {
    summary: { type: 'string' },
    actions: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          upstream: { type: 'string' },
          action: { type: 'string' },
          priority: { type: 'string', enum: ['now', 'next-sync', 'backlog'] },
        },
        required: ['upstream', 'action', 'priority'],
      },
    },
  },
  required: ['summary', 'actions'],
}

phase('Analyze')
const audits = await parallel(upstreams.map(name => () =>
  agent(
    `Audit the bundled upstream submodule upstream/${name} in the current repo (read-only; use Bash git/grep/ls, never modify anything).\n` +
    `1. pinned_sha: git -C upstream/${name} rev-parse --short=12 HEAD; cross-check the recorded pin in upstream/SOURCES.json.\n` +
    `2. remote_delta: git -C upstream/${name} fetch --depth 50 origin main (network-permitting), then summarize what landed between the pin and origin/main — count commits, name notable changes; if fetch is unavailable, say so and audit the checkout only.\n` +
    `3. allowlist_fit: read scripts/skill-allowlists.sh; do allowlisted names for this upstream still exist upstream? Any renames/removals that would break install? Any NEW upstream skills that plausibly deserve allowlisting for a web/backend/AI shop?\n` +
    `4. new_overlaps: new content that duplicates another bundled upstream's lane (orchestration=OMC, dev-process=superpowers, ship/QA=gstack, language-knowledge=ECC).\n` +
    `5. security_signals: new executables, hook/install-script changes, network endpoints, credential-adjacent code in the delta.\n` +
    `6. health: commit cadence, archive risk.\n` +
    `Give verdict + one-paragraph rationale. Be cold: default is keep only what earns it.`,
    { label: `audit:${name}`, phase: 'Analyze', schema: AUDIT }
  )
))

const ok = audits.filter(Boolean)
log(`${ok.length}/${upstreams.length} upstream audits complete`)

phase('Synthesize')
const synthesis = await agent(
  `Synthesize these upstream audit results into a single prioritized action list. ` +
  `Respect the standing constraints: Boss P0 routing depends on gstack; CLAUDE.md Tier-0 depends on OMC; allowlists in scripts/skill-allowlists.sh are the single source of what installs; submodule bumps land only via the security-gated sync PR. ` +
  `Flag any audit that recommends 'remove' or found security_signals as priority 'now'.\n\nAUDITS:\n${JSON.stringify(ok, null, 1)}`,
  { label: 'synthesize', phase: 'Synthesize', schema: SYNTHESIS, effort: 'high' }
)

return { audits: ok, synthesis }
