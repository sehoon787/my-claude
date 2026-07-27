#!/usr/bin/env bash
#
# skill-allowlists.sh — single source of truth for which upstream skills and
# rules install.sh actually installs.
#
# Sourced by install.sh; defines variables only, executes nothing. Names are
# whitespace-separated and contain no spaces, so callers iterate with:
#
#   for name in $ECC_SKILL_ALLOWLIST; do ... done
#
# Anything not listed here is never copied. That is deliberate: the upstreams
# ship far more than this stack needs, and unlisted skills are dead weight in
# every session's context.

# ── ECC (everything-claude-code) skills ──
# Kept lanes:
#   1. Stack in use — TS/JS, React/Next/Vue/Nuxt/Nest, Python/Django/FastAPI,
#      Spring Boot/Java/JPA/Kotlin (server), SQL/Redis/Prisma, Docker/K8s/CI,
#      API/backend/frontend/testing/e2e/security/performance patterns.
#   2. AI + agent engineering — agent harness/audit/introspection, eval, prompt,
#      MCP, RAG/retrieval, context and LLM-cost work.
#   3. Generic codebase tooling — onboarding, tours, ADRs, research, lookup.
# Everything else upstream (mobile, other languages, ops/marketing/domain packs,
# and orchestration skills that duplicate OMC/gstack) stays out.
ECC_SKILL_ALLOWLIST="
accessibility
agent-architecture-audit
agent-harness-construction
agent-introspection-debugging
agent-self-evaluation
ai-regression-testing
api-connector-builder
api-design
architecture-decision-records
backend-patterns
benchmark-optimization-loop
bun-runtime
click-path-audit
code-tour
codebase-onboarding
coding-standards
content-hash-cache-pattern
context-budget
continuous-learning-v2
cost-aware-llm-pipeline
database-migrations
deep-research
deployment-patterns
django-celery
django-patterns
django-security
django-tdd
django-verification
docker-patterns
documentation-lookup
e2e-testing
error-handling
eval-harness
exa-search
fastapi-patterns
frontend-a11y
frontend-patterns
generating-python-installer
github-ops
hexagonal-architecture
inherit-legacy-style
iterative-retrieval
java-coding-standards
jpa-patterns
kotlin-coroutines-flows
kotlin-exposed-patterns
kotlin-ktor-patterns
kotlin-patterns
kotlin-testing
kubernetes-patterns
latency-critical-systems
mcp-server-patterns
motion-advanced
motion-foundations
motion-patterns
mysql-patterns
nestjs-patterns
nextjs-turbopack
nuxt4-patterns
postgres-patterns
prisma-patterns
prompt-optimizer
python-patterns
python-testing
react-patterns
react-performance
react-testing
redis-patterns
regex-vs-llm-structured-text
repo-scan
security-scan
springboot-patterns
springboot-security
springboot-tdd
springboot-verification
ui-to-vue
vite-patterns
vue-patterns
windows-desktop-e2e
"

# ── ECC rule sets ──
# rules/common is universal; language dirs are installed only for stacks kept
# in ECC_SKILL_ALLOWLIST above.
ECC_RULES_ALLOWLIST="
common
java
kotlin
nuxt
python
react
typescript
vue
web
"

# ── gstack skills ──
# The 26 skills Boss P0 routing depends on. The gstack root SKILL.md
# (meta-router) is installed separately by install.sh and is not listed here.
GSTACK_SKILL_ALLOWLIST="
autoplan
benchmark
browse
canary
careful
cso
design-consultation
design-review
document-release
freeze
guard
investigate
land-and-deploy
office-hours
plan-ceo-review
plan-design-review
plan-devex-review
plan-eng-review
qa
qa-only
retro
review
setup-browser-cookies
setup-deploy
ship
unfreeze
"

# ── OMC (oh-my-claudecode) skills ──
# The 16 skills wired into CLAUDE.md Tier-0 routing and OMC setup/doctor flows.
# OMC agents are unaffected by this list.
OMC_SKILL_ALLOWLIST="
ai-slop-cleaner
ask
autopilot
cancel
ccg
deep-interview
hud
omc-doctor
omc-reference
omc-setup
ralph
ralplan
setup
team
ultraqa
ultrawork
"

# ── superpowers skills ──
# Installed as a whole except these; dispatching-parallel-agents duplicates the
# Agent Teams / boss delegation path this repo already owns.
SUPERPOWERS_SKILL_EXCLUDE="
dispatching-parallel-agents
"
