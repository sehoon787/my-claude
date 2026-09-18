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
# Lanes:
#   $ECC_SKILL_ALLOWLIST      — the default install (always copied).
#   $ECC_SKILL_OPTIONAL_WEB   — the "web" lane, opt-in via `install.sh
#                               --skills=web`, `--full-skills`, or
#                               MY_CLAUDE_SKILLS=web. Browser-UI work only
#                               (React/Vue/Nuxt/Nest, motion, a11y, browser
#                               e2e) — 18 skill descriptions that every
#                               non-frontend session would otherwise pay for.
ECC_SKILL_ALLOWLIST="
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
error-handling
eval-harness
exa-search
fastapi-patterns
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
mysql-patterns
postgres-patterns
prisma-patterns
prompt-optimizer
python-patterns
python-testing
redis-patterns
regex-vs-llm-structured-text
repo-scan
security-scan
springboot-patterns
springboot-security
springboot-tdd
springboot-verification
"

# ── ECC optional lane: web / frontend ──
# Not installed by default. Opt in with `bash install.sh --skills=web` (or
# --full-skills / MY_CLAUDE_SKILLS=web); the choice is persisted to
# ~/.claude/.my-claude-skills so later reinstalls keep it.
ECC_SKILL_OPTIONAL_WEB="
accessibility
bun-runtime
e2e-testing
frontend-a11y
frontend-patterns
motion-advanced
motion-foundations
motion-patterns
nestjs-patterns
nextjs-turbopack
nuxt4-patterns
react-patterns
react-performance
react-testing
ui-to-vue
vite-patterns
vue-patterns
windows-desktop-e2e
"

# Every optional lane name, in install order. Add a lane here and define the
# matching ECC_SKILL_OPTIONAL_<UPPER> variable above.
ECC_SKILL_OPTIONAL_LANES="web"

# ── ECC rule sets ──
# Language dirs only. Each upstream language rule file carries a `paths:` scope,
# so it costs nothing until a matching file is opened — the whole set stays.
# rules/common is the opposite: every file in it is injected into every session,
# so it is allowlisted per file below instead of by directory.
ECC_RULES_ALLOWLIST="
java
kotlin
nuxt
python
react
typescript
vue
web
"

# ── ECC rules/common — per-file allowlist ──
# These three are always-on context, so only universally true guidance stays.
# Deliberately dropped: agents.md (names agents this stack does not install —
# tdd-guide, rust-reviewer, …), code-review.md and development-workflow.md
# (duplicated by boss.md Phase 4 and the gstack 3-Phase Sprint), hooks.md,
# patterns.md, performance.md (stale harness advice), and testing.md (its
# mandatory-TDD framing conflicts with Boss routing "tdd" to the
# test-driven-development skill on request). Dropped files are manifest-owned,
# so an existing install loses them on the next `bash install.sh`.
ECC_RULES_COMMON_ALLOWLIST="
coding-style.md
git-workflow.md
security.md
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
# Deliberately NOT copied into ~/.claude/skills/. install.sh enables the OMC
# plugin (enabledPlugins["oh-my-claudecode@omc"]), which already exposes every
# one of these as `oh-my-claudecode:<name>`. A local copy adds a second, bare
# description of the same skill to every session's context for no new
# capability. Routing targets therefore use the prefixed plugin name. Kept here
# as documentation of which names Boss routes to; install.sh never reads it.
OMC_PLUGIN_SKILL_NAMES="
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

# ── archify skill ──
# The archify upstream ships one agent skill directory at its repo root
# (`archify/SKILL.md` plus the renderers, schemas, and examples it reads).
# That is exactly the directory `npx skills add tt-a1i/archify -g` installs;
# install.sh copies it from the pinned submodule instead, so no package
# manager runs at install time. Name it here so the routing-reference check
# and the installer read the same single source of truth.
# Tag-pinned, not branch-tracked: the submodule sits on $ARCHIFY_PINNED_TAG
# and the clone fallback in install.sh checks out the same tag.
ARCHIFY_SKILL_NAME="archify"
ARCHIFY_SKILL_SRC_DIR="archify"
ARCHIFY_PINNED_TAG="v2.9.0"
