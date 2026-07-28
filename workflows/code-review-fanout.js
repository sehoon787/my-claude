// my-claude named workflow — invoke via Workflow({name: "code-review-fanout", args: "<target>"})
// args (optional string): what to review — a branch, "HEAD~3..HEAD", a PR ref, or file paths.
// Defaults to the uncommitted working-tree diff.
export const meta = {
  name: 'code-review-fanout',
  description: 'Parallel multi-dimension code review; every finding is adversarially verified before it is reported',
  whenToUse: 'Thorough review of a diff/branch/files — four dimension reviewers fan out, findings are verified by an independent skeptic, only confirmed issues survive',
  phases: [
    { title: 'Review', detail: 'four dimension reviewers in parallel' },
    { title: 'Verify', detail: 'adversarial verification per finding' },
  ],
}

const target = (typeof args === 'string' && args.trim())
  ? args.trim()
  : 'the uncommitted working-tree diff (git diff HEAD, plus untracked files via git status)'

const FINDINGS = {
  type: 'object',
  properties: {
    findings: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          file: { type: 'string' },
          line: { type: 'number' },
          title: { type: 'string' },
          detail: { type: 'string' },
          severity: { type: 'string', enum: ['critical', 'high', 'medium', 'low'] },
        },
        required: ['file', 'title', 'detail', 'severity'],
      },
    },
  },
  required: ['findings'],
}

const VERDICT = {
  type: 'object',
  properties: {
    isReal: { type: 'boolean' },
    reason: { type: 'string' },
  },
  required: ['isReal', 'reason'],
}

const DIMENSIONS = [
  { key: 'correctness', prompt: 'logic errors, off-by-one, broken edge cases, wrong error handling, race conditions' },
  { key: 'security', prompt: 'injection, credential exposure, path traversal, unsafe deserialization, missing validation at boundaries' },
  { key: 'performance', prompt: 'N+1 patterns, unbounded loops/queries, needless sync IO, missing caching where it clearly matters' },
  { key: 'tests', prompt: 'changed behavior without test coverage, tests weakened or deleted, assertions that cannot fail' },
]

const results = await pipeline(
  DIMENSIONS,
  d => agent(
    `Review ${target} strictly for ${d.key} issues: ${d.prompt}.\n` +
    `Read the actual diff/files with git and Read — never guess from filenames. ` +
    `Report only defects you can anchor to a file (and line where possible). ` +
    `No style nits, no praise, no speculative "might be" items without a concrete failure path.`,
    { label: `review:${d.key}`, phase: 'Review', schema: FINDINGS }
  ),
  (review, d) => parallel((review?.findings ?? []).map(f => () =>
    agent(
      `Adversarially verify this ${d.key} finding — your job is to REFUTE it.\n` +
      `Finding: [${f.severity}] ${f.file}${f.line ? ':' + f.line : ''} — ${f.title}\n${f.detail}\n` +
      `Read the real code. isReal=true ONLY if you can articulate concrete inputs/state that trigger the defect. Default to isReal=false when uncertain.`,
      { label: `verify:${f.title.slice(0, 40)}`, phase: 'Verify', schema: VERDICT }
    ).then(v => ({ ...f, dimension: d.key, verdict: v }))
  ))
)

const all = results.filter(Boolean).flat().filter(Boolean)
const confirmed = all.filter(f => f.verdict?.isReal)
const sevRank = { critical: 0, high: 1, medium: 2, low: 3 }
confirmed.sort((a, b) => sevRank[a.severity] - sevRank[b.severity])

log(`review complete: ${all.length} raw findings, ${confirmed.length} confirmed`)
return {
  target,
  confirmed,
  rejected: all.length - confirmed.length,
}
