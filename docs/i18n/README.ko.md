[English](../../README.md) | [한국어](./README.ko.md) | [日本語](./README.ja.md) | [中文](./README.zh.md) | [Deutsch](./README.de.md) | [Français](./README.fr.md)

> [![Codex CLI](https://img.shields.io/badge/Codex_CLI-my--codex-10b981?style=flat-square&logo=openai&logoColor=white)](https://github.com/sehoon787/my-codex) Codex CLI를 찾으시나요? → **my-codex** — 네이티브 TOML 형식으로 제공하는 동일한 오케스트레이션

---

<div align="center">

# my-claude

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Agents](https://img.shields.io/badge/agents-32-blue)
![Skills](https://img.shields.io/badge/skills-107-purple)
![Rules](https://img.shields.io/badge/rules-48-orange)
![MCP Servers](https://img.shields.io/badge/MCP-3-green)
![Hooks](https://img.shields.io/badge/hooks-10-red)
![LSP Servers](https://img.shields.io/badge/LSP-2-008b8b)
![Workflows](https://img.shields.io/badge/workflows-2-blueviolet)

**Claude Code를 위한 올인원 에이전트 하네스.**
**플러그인 하나로 엄선된 32개 에이전트가 준비됩니다.**

Boss가 런타임에 모든 에이전트, 스킬, MCP 도구를 자동으로 탐색하고,<br>
작업을 적합한 전문가에게 라우팅합니다. 설정 파일도, 보일러플레이트도 없습니다.

<img src="../../assets/owl-claude-social.svg" alt="The Maestro Owl — my-claude" width="700">

</div>

---

## 설치

### 사람을 위한 설치

```bash
git clone --depth 1 https://github.com/sehoon787/my-claude.git /tmp/my-claude
bash /tmp/my-claude/install.sh
rm -rf /tmp/my-claude
```

또는 Claude Code 플러그인으로 먼저 설치한 후 동반 인스톨러를 실행하세요:

```bash
# Claude Code 세션 내에서:
/plugin marketplace add sehoon787/my-claude
/plugin install my-claude@my-claude

# 그런 다음 동반 도구 설치:
git clone --depth 1 https://github.com/sehoon787/my-claude.git /tmp/my-claude
bash /tmp/my-claude/install.sh
rm -rf /tmp/my-claude
```

설치 프로그램은 my-claude와 my-codex가 함께 쓰는 codeburn 대시보드와 Headroom 프록시를 하나씩 준비합니다. 나중에 실행한 설치 프로그램은 정상 서비스에 연결하고 중복 실행하지 않습니다. 상태와 시작 로그는 `${XDG_STATE_HOME:-$HOME/.local/state}/agent-harness-services`에 저장되며 `ANTHROPIC_BASE_URL`과 `OPENAI_BASE_URL`은 변경하지 않습니다.

### AI 에이전트를 위한 설치

```bash
curl -s https://raw.githubusercontent.com/sehoon787/my-claude/main/AI-INSTALL.md
```

전체 출력을 읽은 후, 각 단계를 순서대로 실행하세요. `WebFetch`가 아닌 `curl`을 사용하세요.

---

<a id="open-source-tools-used"></a>

## 사용하는 오픈소스 도구

이 스택이 기반으로 삼는 프로젝트는 모두 여기 한 곳에서만 설명합니다.
MIT 라이선스 업스트림 5개는 명시적인 SHA에 고정한 git 서브모듈로 연결되며,
나머지는 버전을 고정한 CLI, 호스팅 MCP 서버, 또는 출처 표기와 함께 가져온 파일로 편입됩니다.

| # | 프로젝트 | my-claude가 가져오는 것 | 편입 방식 |
|---|----------|--------------------------|-----------|
| 1 | <img src="https://github.com/Yeachan-Heo.png?size=32" width="20" height="20" align="center"/> **[oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode)** (OMC) — Yeachan Heo | 역할별로 작업을 나누는 전문가 에이전트 19개(architect, debugger, code reviewer, security reviewer, …)와 autopilot·ralph·team을 포함한 오케스트레이션 스킬 16개. `autopilot:` 같은 매직 키워드가 자동 병렬 실행을 켭니다. | 서브모듈 `upstream/omc`, SHA 고정(「번들된 업스트림 버전」 참조). `install.sh`가 `npm i -g oh-my-claude-sisyphus@latest`를 실행하고 `oh-my-claudecode@omc` 플러그인을 활성화합니다. |
| 2 | <img src="https://github.com/code-yeongyu.png?size=32" width="20" height="20" align="center"/> **[oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent)** (omo) — code-yeongyu | 8개 제공자(Claude, GPT, Gemini, …)에 카테고리별로 라우팅하고 `claude-code-agent-loader`, `claude-code-plugin-loader`로 Claude Code에 연결하는 멀티 플랫폼 하네스. 그 에이전트 9개(Sisyphus, Atlas, Oracle, …)를 독립 `.md` 파일로 이식했습니다. | 서브모듈이 아닙니다. 에이전트 9개는 `agents/omo/`에 있고, `install.sh`가 `omo` CLI를 위해 `npm i -g oh-my-opencode@latest`를 실행합니다. |
| 3 | <img src="https://github.com/forrestchang.png?size=32" width="20" height="20" align="center"/> **[andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills)** — forrestchang | AI 코딩 행동 가이드라인 4가지 — Think Before Coding, Simplicity First, Surgical Changes, Goal-Driven Execution — 가 항상 활성화됩니다. | `install.sh`가 고정 SHA `aa4467f`의 `CLAUDE.md`를 curl로 받아 체크섬을 검증한 뒤 `~/.claude/CLAUDE.md`에 덧붙입니다. 코드는 가져오지 않습니다. |
| 4 | <img src="https://github.com/affaan-m.png?size=32" width="20" height="20" align="center"/> **[everything-claude-code](https://github.com/affaan-m/everything-claude-code)** (ECC) — affaan-m | 업스트림에는 스킬 278개 + 에이전트 67개 + 커맨드 94개 + 언어 룰이 있습니다. my-claude는 엄선한 스킬 61개(옵트인 `web` 레인을 더하면 79개) — 스택 패턴, AI·에이전트 엔지니어링, 코드베이스 도구 — 와 룰셋 9개, `/tdd`, `/plan`, `/code-review`, `/build-fix` 같은 슬래시 커맨드를 설치합니다. | 서브모듈 `upstream/ecc`, SHA 고정. `install.sh`는 `claude plugin add affaan-m/everything-claude-code`를 먼저 시도하고 실패하면 서브모듈로 폴백합니다. |
| 5 | <img src="https://www.anthropic.com/favicon.ico" width="20" height="20" align="center"/> **[anthropic/skills](https://github.com/anthropics/skills)** — Anthropic | Anthropic 공식 스킬 저장소: PDF 파싱, Word/Excel/PowerPoint 조작, MCP 서버 생성. | `install.sh`가 `claude plugin add anthropics/skills`로 설치합니다. 의도적으로 매니페스트 추적 대상이 아닙니다. |
| 6 | <img src="https://github.com/garrytan.png?size=32" width="20" height="20" align="center"/> **[gstack](https://github.com/garrytan/gstack)** — garrytan | Garry Tan의 스프린트 프로세스 하네스: 스킬 26개와 `gstack` 루트 라우터(총 27개) — 브라우저 QA(`/qa`), 스코프 드리프트 코드 리뷰(`/review`), 보안 감사(`/cso`), 그리고 Plan→Review→QA→Ship 전체 워크플로(Boss P0 레인). 실제 브라우저 테스트용으로 컴파일된 Playwright 브라우저 데몬을 함께 제공합니다. | 서브모듈 `upstream/gstack`, SHA 고정. |
| 7 | <img src="https://github.com/obra.png?size=32" width="20" height="20" align="center"/> **[superpowers](https://github.com/obra/superpowers)** — Jesse Vincent | Jesse Vincent의 개발 프로세스 라이브러리: 15개 스킬 중 14개 — 브레인스토밍, 체계적 디버깅, TDD, 계획 작성과 실행, 코드 리뷰 에티켓. `dispatching-parallel-agents`는 Boss와 Agent Teams가 이미 그 경로를 담당하므로 제외했습니다. | 서브모듈 `upstream/superpowers`, SHA 고정. |
| 8 | <img src="https://github.com/getagentseal.png?size=32" width="20" height="20" align="center"/> **[codeburn](https://github.com/getagentseal/codeburn)** — getagentseal | Claude Code와 Codex가 이미 기록하는 세션 파일을 읽는 로컬 우선 토큰·비용 추적 — 프록시도 API 키도 없고 머신 밖으로 나가는 것이 없습니다. 예산 가드 훅은 `bash install.sh --with-codeburn-guard`로 옵트인입니다. 하드 캡(기본 $15/세션)이 해제 명령 `codeburn guard allow`를 포함한 그 세션의 모든 툴 호출을 막기 때문입니다(해제는 외부 터미널에서 실행). | `npm i -g codeburn@0.9.23`. `install.sh`는 두 하네스가 공유하는 대시보드도 시작하거나 재사용합니다 — 「결과를 확인하는 곳」 참조. MIT. |
| 9 | <img src="https://github.com/oraios.png?size=32" width="20" height="20" align="center"/> **[serena](https://github.com/oraios/serena)** — oraios | MCP로 쓰는 언어 서버의 심볼 그래프: `find_symbol`, `get_symbols_overview`, `find_referencing_symbols`, `replace_symbol_body`, `insert_after_symbol` — 소비 토큰이 파일이 아니라 심볼 크기에 비례합니다. | `uv tool install -p 3.13 serena-agent==1.7.0`으로 설치해 사용자 스코프 stdio MCP 서버(`serena start-mcp-server --context claude-code --project-from-cwd`)로 등록합니다. 배포 패키지는 전체가 GPL-3.0-or-later이며(PyPI의 MIT classifier는 부정확) 외부 서버로만 사용하고 벤더링하지 않습니다. |
| 10 | <img src="https://github.com/headroomlabs-ai.png?size=32" width="20" height="20" align="center"/> **[headroom](https://github.com/headroomlabs-ai/headroom)** — Headroom Labs | 툴 출력 압축: `headroom mcp serve`가 `headroom_compress`, `headroom_retrieve`, `headroom_stats`를 노출해 과도하게 큰 툴 결과가 통째로 트랜스크립트에 들어가지 않게 합니다. | `uv tool install --python 3.13 "headroom-ai[all]==0.37.0"`으로 설치해 `headroom` stdio MCP 서버로 등록합니다. `install.sh`는 변경을 가하지 않는 영구 프로필 `agent-harness-shared`도 시작하거나 재사용합니다. Apache-2.0. |
| 11 | <img src="https://github.com/tt-a1i.png?size=32" width="20" height="20" align="center"/> **[archify](https://github.com/tt-a1i/archify)** — tt-a1i | 아키텍처·워크플로·시퀀스·데이터 흐름·라이프사이클 다이어그램을 자체 완결형 HTML로 그리는 에이전트 스킬 — 인라인 SVG, 라이트/다크 테마 토글, PNG/JPEG/WebP/SVG 내보내기 메뉴, 생성 파일에 런타임 의존성 없음. 붙여 넣은 Mermaid도 입력 방언으로 받습니다. | 서브모듈 `upstream/archify`, 태그 `v2.9.0`에 고정. `install.sh`가 업스트림 `archify/` 스킬 디렉터리를 `~/.claude/skills/archify`로 복사하므로 설치 시 `npx skills add`가 실행되지 않습니다. |
| 12 | <img src="https://github.com/msitarzewski.png?size=32" width="20" height="20" align="center"/> **[agency-agents](https://github.com/msitarzewski/agency-agents)** — msitarzewski | 스택 내에 대체재가 없는 엔지니어링 에이전트 3개: AI Engineer, DevOps Automator, Multi-Agent Systems Architect. | 서브모듈은 2026-07-27에 제거했습니다. 같은 날 에이전트 3개를 `agents/vendored/`로 스냅샷했고 각 파일에 출처 표기가 들어 있습니다. MIT. |
| 13 | <img src="https://github.com/ast-grep.png?size=32" width="20" height="20" align="center"/> **[ast-grep](https://github.com/ast-grep/ast-grep)** — ast-grep | 구문 트리를 이해하는 구조적 코드 검색·치환. 에이전트가 정규식이 아니라 코드 형태를 매칭합니다. | `npm i -g @ast-grep/cli@0.42.0`. MIT. |
| 14 | <img src="https://github.com/upstash.png?size=32" width="20" height="20" align="center"/> **[context7](https://github.com/upstash/context7)** — Upstash | 버전까지 정확한 최신 라이브러리 문서. 에이전트가 기억이 아니라 실제 API를 읽습니다. | `https://mcp.context7.com/mcp` 호스팅 MCP 서버. `install.sh`가 등록합니다. |
| 15 | <img src="https://github.com/exa-labs.png?size=32" width="20" height="20" align="center"/> **[exa](https://github.com/exa-labs/exa-mcp-server)** — Exa Labs | 키워드 검색이 놓치는 조사를 위한 뉴럴(의미 기반) 웹 검색. | `https://mcp.exa.ai/mcp` 호스팅 MCP 서버. `install.sh`가 등록합니다. |
| 16 | <img src="https://github.com/grep-app.png?size=32" width="20" height="20" align="center"/> **[grep.app](https://github.com/grep-app)** — grep.app | 공개 GitHub 저장소 전반의 코드 검색. 어떤 패턴이 실제로 어떻게 쓰이는지 찾을 수 있습니다. | `https://mcp.grep.app` 호스팅 MCP 서버. `install.sh`가 등록합니다. |


---

## Boss의 작동 방식

Boss는 my-claude의 핵심에 있는 메타 오케스트레이터입니다. 코드를 직접 작성하지 않고, 탐색하고 분류하고 매칭하고 위임하고 검증합니다.

| 단계 | 동작 |
|------|------|
| **Phase 0 · DISCOVERY** | 런타임에 에이전트·스킬·MCP·훅을 스캔해 살아 있는 역량 레지스트리를 구축 |
| **Phase 1 · INTENT GATE** | 요청을 분류(trivial, build, refactor, mid-sized, architecture, research, …)하고, 더 잘 맞는 스킬이 있으면 역제안 |
| **Phase 2 · CAPABILITY MATCHING** | 아래 우선순위 체인을 순차적으로 적용 (P0 gstack 스킬 → P1 정확한 스킬 매칭 → P2 전문가 에이전트 → P3 멀티에이전트 오케스트레이션 → P4 범용 폴백) |
| **Phase 3 · DELEGATION** | 전문가에게 6개 섹션으로 구조화된 프롬프트를 전달: TASK / OUTCOME / TOOLS / DO / DON'T / CTX |
| **Phase 4 · VERIFICATION** | 변경된 파일을 독립적으로 읽고, 테스트·린트·빌드를 실행하며, 원래 의도와 교차 검증. 실패 시 최대 3회 재시도 |

### 우선순위 라우팅

Boss는 가장 적합한 매칭을 찾을 때까지 모든 요청을 우선순위 체인을 통해 순차적으로 처리합니다:

| 우선순위 | 매칭 유형 | 조건 | 예시 |
|:--------:|-----------|------|---------|
| **P0** | gstack 스킬 | 배포·QA·보안 워크플로 | `"ship this"` → gstack `/ship` |
| **P1** | 스킬 매칭 | 작업이 독립적인 스킬에 해당 | `"merge PDFs"` → pdf 스킬 |
| **P2** | 전문가 에이전트 | 도메인별 에이전트 존재 | `"security audit"` → security-reviewer |
| **P3a** | Boss 직접 | 독립적인 에이전트 2~4개 | `"fix 3 bugs"` → 병렬 스폰 |
| **P3b** | 서브 오케스트레이터 | 복잡한 다단계 워크플로 | `"refactor + test"` → Sisyphus |
| **P3c** | 에이전트 팀 | P2P 통신이 필요한 경우 | `"implement + review"` → Review Chain |
| **P4** | 폴백 | 전문가 매칭 없음 | `"explain this"` → 범용 에이전트 |

### 모델 라우팅

| 복잡도 | 모델 | 사용 대상 |
|-----------|-------|----------|
| 최상위 오케스트레이션 | `claude-fable-5-1` | Boss |
| 심층 분석, 아키텍처 | `claude-opus-5` | Sisyphus, Atlas, Hephaestus, Oracle, Metis, Momus, Prometheus |
| 표준 구현 | `claude-sonnet-5` | Librarian, Multimodal-Looker, OMC 전문가 |
| 빠른 조회, 탐색 | `claude-haiku-4-5` | 경량 OMC 에이전트, 간단한 자문 |

### Effort 계층

모델 선택이 *어떤* 두뇌가 작업할지 정한다면, `effort:` 프론트매터 필드는 *얼마나 깊게* 사고할지를 정합니다. 자체 관리 에이전트는 모두 이 값을 선언합니다.

| Effort | 에이전트 |
|--------|--------|
| `xhigh` | Boss, Oracle, Prometheus, Multi-Agent Systems Architect |
| `high` | Sisyphus, Hephaestus, Atlas, Metis, Momus |
| `medium` | Librarian, Multimodal-Looker, AI Engineer, DevOps Automator |

스킬도 effort를 선언합니다 — `boss-briefing`은 `medium`, `briefing-vault`는 `low`입니다. `boss-advanced`와 `gstack-sprint`는 의도적으로 선언하지 않습니다. 스킬의 effort는 실행되는 동안 세션 레벨을 덮어쓰기 때문에, 선언하면 작업 도중 Boss의 effort가 조용히 낮아집니다.

우선순위는 `CLAUDE_CODE_EFFORT_LEVEL`(환경 변수) > 프론트매터 > 세션 effort 레벨 순입니다. `xhigh`는 Fable이 지원하는 상한이며, `max`는 opus 계열 전용이라 그 외 모델에서는 조용히 하위 값으로 대체됩니다.

### 3단계 스프린트 워크플로

엔드투엔드 기능 구현을 위해 Boss는 구조화된 스프린트를 오케스트레이션합니다:

| 단계 | 모드 | 동작 |
|------|------|------|
| **1 · DESIGN** | interactive | 사용자가 범위를 결정 · 엔지니어링 리뷰 · "design done" 확인 |
| **2 · EXECUTE** | autonomous | ralph가 실행을 수행 · 자동 코드 리뷰 · 아키텍트 검증 |
| **3 · REVIEW** | interactive | 설계 문서와 대조 · 비교표 제시 · 사용자가 승인하거나 개선 요청 |

### 정형화된 최종 보고

Boss는 작업이 있던 모든 턴 — 파일 편집·생성, 커밋/PR/머지, 설정 변경, 검증 실행이 있었던 턴 — 을 diff를 열지 않고도 훑어볼 수 있는 정형화된 최종 보고로 마무리합니다. 보고는 고정된 표 5종으로 구성되며, 각 표는 해당 상황이 실제로 발생했을 때만 출력됩니다(빈 표는 만들지 않음):

| 상황 | 표 | 컬럼 |
|-----------|-------|---------|
| 파일/설정 변경 | 변경 대조 (Changes) | 대상 / Before / After / 근거 |
| 여러 작업 완료 | 작업 요약 (Work summary) | 항목 / 결과 / 근거 |
| 검증 실행 | 검증 결과 (Verification) | 항목 / 기대 / 실제 / 판정 |
| 커밋/PR 산출 | 산출물 (Deliverables) | PR / 저장소 / 내용 / 상태 |
| 미해결 존재 | 남은 것 (Remaining) | 항목 / 상태 / 다음 조치 |

이 보고는 요청의 맨 마지막에만 발동하며 — 백그라운드 작업을 띄우거나 그 완료를 중계하는 턴, 작업 중간의 진행 상황 보고로는 절대 출력되지 않음 — 순수 질답 턴은 보고 없이 정상 종료됩니다. 규격은 `boss.md § FINAL REPORT`에 있고, `stop-final-report.js` Stop 훅이 이를 강제합니다.

### 네임드 워크플로

결정적으로 실행되는 멀티에이전트 워크플로입니다. `install.sh`가 `~/.claude/workflows/`로 복사하므로 이 레포뿐 아니라 어느 프로젝트에서든 Workflow 도구로 호출할 수 있습니다.

| 워크플로 | 동작 | 호출 |
|----------|------|------|
| **code-review-fanout** | 4개 관점 리뷰어(정확성, 보안, 성능, 테스트)가 병렬로 펼쳐지고, 보고 전에 모든 발견 사항을 적대적으로 검증합니다 | `Workflow({name: "code-review-fanout"})` — 인자: 리뷰 대상(브랜치, 커밋 범위, 경로). 기본값은 작업 트리 diff |
| **upstream-audit** | 업스트림별 분석가가 핀 델타, 허용목록 적합성, 신규 중복, 보안 시그널, 건전성을 점검한 뒤 종합 액션 목록을 만듭니다 | `Workflow({name: "upstream-audit"})` — 분기별 또는 동기화 전 감사용 |

---

## 구성 요소

| 카테고리 | 수량 | 출처 |
|----------|------:|--------|
| **에이전트** (항상 로드됨) | 32 | Boss 1 + OMO 9 + OMC 19 + 벤더링 3 |
| **스킬** | 107 | ECC 61 · gstack 27 · Superpowers 14 · Core 4 · Archify 1 |
| **규칙** | 48개 파일 / 9개 룰셋 | ECC 46 (common + 8개 언어 디렉터리) + Core 2 |
| **MCP 서버** | 3 | Context7, Exa, grep.app |
| **훅** | 10개 파일 / 6개 이벤트 | 위임 가드, 텔레메트리, 검증, 지식 금고 |
| **LSP 서버** | 2 | typescript (`typescript-language-server`), python (`pyright-langserver`) |
| **네임드 워크플로** | 2 | code-review-fanout, upstream-audit |
| **업스트림 서브모듈** | 5 | ecc, omc, gstack, superpowers, archify |
| **CLI 도구** | 7 | omc, omo, ast-grep, comment-checker, codeburn, serena, headroom |

위의 에이전트·스킬·룰은 모두 [`scripts/skill-allowlists.sh`](../../scripts/skill-allowlists.sh)의 허용목록에 등재되어 설치 매니페스트로 추적됩니다. Anthropic 공식 문서 스킬(pdf, docx 등)은 `claude plugin add anthropics/skills`로 별도 설치되며 의도적으로 매니페스트에서 제외됩니다.

<details>
<summary><strong>전문가 에이전트 — 4개 티어, 32개</strong></summary>

에이전트별 모델은 위의 모델 라우팅 표에 정리되어 있습니다. 32개 전부가 `~/.claude/agents/`에 항상 로드되며, 온디맨드 에이전트 팩과 `--with-packs` 플래그는 더 이상 제공되지 않습니다. 각 출처가 어디에서 왔는지는 [사용하는 오픈소스 도구](#open-source-tools-used)에 있습니다.

| 에이전트 | 티어 | 역할 | 출처 |
|-------|------|------|--------|
| Boss | core | 동적 런타임 탐색 → 역량 매칭 → 최적 라우팅. 코드를 직접 작성하지 않습니다. | my-claude |
| Sisyphus | omo | 의도 분류 → 전문가 위임 → 검증 | [oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent) |
| Hephaestus | omo | 자율적 탐색 → 계획 → 실행 → 검증 | oh-my-openagent |
| Atlas | omo | 작업 분해 + 4단계 QA 검증 | oh-my-openagent |
| Oracle | omo | 전략적 기술 컨설팅 (읽기 전용) | oh-my-openagent |
| Metis | omo | 의도 분석, 모호성 탐지 | oh-my-openagent |
| Momus | omo | 계획 실현 가능성 검토 | oh-my-openagent |
| Prometheus | omo | 인터뷰 기반 세부 계획 수립 | oh-my-openagent |
| Librarian | omo | MCP를 통한 오픈소스 문서 검색 | oh-my-openagent |
| Multimodal-Looker | omo | 이미지/스크린샷/다이어그램 분석 | oh-my-openagent |
| analyst | omc | 계획 전 사전 분석 | [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) |
| architect | omc | 시스템 설계 및 아키텍처 | oh-my-claudecode |
| code-reviewer | omc | 집중적인 코드 리뷰 | oh-my-claudecode |
| code-simplifier | omc | 코드 단순화 및 정리 | oh-my-claudecode |
| critic | omc | 비판적 분석, 대안 제안 | oh-my-claudecode |
| debugger | omc | 집중적인 디버깅 | oh-my-claudecode |
| designer | omc | UI/UX 디자인 가이드 | oh-my-claudecode |
| document-specialist | omc | 문서 작성 | oh-my-claudecode |
| executor | omc | 작업 실행 | oh-my-claudecode |
| explore | omc | 코드베이스 탐색 | oh-my-claudecode |
| git-master | omc | Git 워크플로 관리 | oh-my-claudecode |
| planner | omc | 신속한 계획 수립 | oh-my-claudecode |
| qa-tester | omc | 품질 보증 테스팅 | oh-my-claudecode |
| scientist | omc | 연구 및 실험 | oh-my-claudecode |
| security-reviewer | omc | 보안 리뷰 | oh-my-claudecode |
| test-engineer | omc | 테스트 작성 및 유지 관리 | oh-my-claudecode |
| tracer | omc | 실행 추적 및 분석 | oh-my-claudecode |
| verifier | omc | 최종 검증 | oh-my-claudecode |
| writer | omc | 콘텐츠 및 문서 작성 | oh-my-claudecode |
| AI Engineer | vendored | AI/ML 엔지니어링, 모델 통합, 데이터 파이프라인 | agency-agents (벤더링) |
| DevOps Automator | vendored | 인프라 자동화, CI/CD, 클라우드 운영 | agency-agents (벤더링) |
| Multi-Agent Systems Architect | vendored | 에이전트 토폴로지, 컨텍스트 관리, 장애 복구 | agency-agents (벤더링) |

</details>

<details>
<summary><strong>스킬 — 5개 출처에서 107개</strong></summary>

각 출처는 [`scripts/skill-allowlists.sh`](../../scripts/skill-allowlists.sh)의 허용목록으로 관리되며, 목록에 없는 스킬은 설치되지 않습니다.

| 출처 | 수량 | 주요 스킬 |
|--------|------:|------------|
| [everything-claude-code](https://github.com/affaan-m/everything-claude-code) | 61 | coding-standards, fastapi-patterns, agent-architecture-audit, springboot-patterns, kubernetes-patterns |
| [gstack](https://github.com/garrytan/gstack) | 27 | /qa, /review, /ship, /cso, /investigate, /office-hours |
| [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) | 16 (플러그인) | autopilot, ralph, team, ultrawork, ralplan, omc-reference |
| [superpowers](https://github.com/obra/superpowers) | 14 | brainstorming, systematic-debugging, test-driven-development, writing-plans |
| [my-claude Core](https://github.com/sehoon787/my-claude) | 4 | boss-advanced, boss-briefing, briefing-vault, gstack-sprint |
| [archify](https://github.com/tt-a1i/archify) | 1 | archify |

</details>

<details>
<summary><strong>MCP 서버 (3) + 훅 (8)</strong></summary>

**MCP 서버** — 각 서버가 무엇을 하고 어떻게 등록되는지는 [사용하는 오픈소스 도구](#open-source-tools-used)에 있습니다.

| 서버 | 비용 |
|--------|------|
| <img src="https://context7.com/favicon.ico" width="16" height="16" align="center"/> [Context7](https://context7.com) | 무료 |
| <img src="https://exa.ai/images/favicon-32x32.png" width="16" height="16" align="center"/> [Exa](https://exa.ai) | 월 1천 건 무료 |
| <img src="https://www.google.com/s2/favicons?domain=grep.app&sz=32" width="16" height="16" align="center"/> [grep.app](https://github.com/grep-app) | 무료 |

**동작 훅**

| 훅 | 이벤트 | 동작 |
|------|-------|----------|
| Session Setup | SessionStart | 누락된 도구 자동 감지 + Briefing Vault 컨텍스트 주입 |
| Delegation Guard | PreToolUse | Boss가 파일을 직접 수정하지 못하도록 차단 |
| Agent Telemetry | PostToolUse | 에이전트 사용 기록을 `agent-usage.jsonl`에 저장 |
| Subagent Logger | SubagentStop | 에이전트 실행을 Briefing Vault에 기록 |
| Completion Check | Stop | 작업 검증 확인 + 세션 요약 프롬프트 |

</details>

<details>
<summary><strong>LSP 서버 (2)</strong></summary>

플러그인은 `.lsp.json`에 두 개의 언어 서버를 선언합니다. Claude Code가 필요할 때 자동으로 띄우므로, 에이전트는 빌드를 한 번 돌리지 않고도 즉시 진단과 코드 탐색을 사용할 수 있습니다.

| 서버 | 명령 | 확장자 |
|--------|------|--------|
| typescript | `typescript-language-server --stdio` | `.ts` `.tsx` `.js` `.jsx` `.mjs` `.cjs` |
| python | `pyright-langserver --stdio` | `.py` |

`install.sh`는 두 바이너리를 비치명적으로 설치합니다 — 하나를 설치하지 못해도 해당 서버만 비활성화되고 나머지 설치는 계속됩니다.

</details>

---

## <img src="https://obsidian.md/images/obsidian-logo-gradient.svg" width="24" height="24" align="center"/> Briefing Vault

Obsidian 호환 영구 메모리입니다. 모든 프로젝트는 세션에 걸쳐 자동으로 채워지는 `.briefing/` 디렉터리를 유지합니다.

### 서브 Vault

| 경로 | 설명 |
|------|------|
| `INDEX.md` | 프로젝트 개요와 최근 의사결정/학습 링크. 첫 세션에 자동 생성, 주기적으로 갱신. |
| `sessions/` | **세션 요약.** `YYYY-MM-DD-auto.md` — git diff 통계와 에이전트 수를 포함한 스캐폴드. `YYYY-MM-DD-<topic>.md` — 훅에 의해 강제되는 AI 작성 요약. |
| `decisions/` | **아키텍처 및 설계 의사결정** 기록과 근거. `YYYY-MM-DD-<decision>.md` — AI 작성, 작업 중 강제. |
| `learnings/` | **패턴, 주의사항, 비자명한 해결책.** `YYYY-MM-DD-auto-session.md` — 파일 목록 스캐폴드. `YYYY-MM-DD-<pattern>.md` — AI 작성. |
| `references/` | **웹 조사 URL.** `auto-links.md` — WebSearch/WebFetch 호출 시 자동 수집. |
| `agents/` | **에이전트 텔레메트리.** `agent-log.jsonl` — 호출별 로그. `YYYY-MM-DD-summary.md` — 일별 사용 요약. |
| `persona/` | **사용자 작업 스타일 프로필.** `profile.md` — 도구 친화도 통계. `suggestions.jsonl` — 라우팅 제안. `rules/`, `skills/` — 승인된 선호도. |
| `archives/` | **완료/비활성 노트.** 30일 이상 지난 노트는 아카이브 후보. PARA의 Archives 개념. `sessions/`, `decisions/`, `learnings/` 하위로 보관하며, 각 노트는 frontmatter의 `type:` 필드로 원본 카테고리를 식별. |
| `wiki/` | **개념 위키 페이지.** 3회 이상 반복 등장한 키워드는 자동 제안. LLM-wiki 개념 적용. `_schema.md`로 형식 정의. |

### 지식 관리 (v2)

BriefingVault v2는 세 가지 지식 관리 방법론을 통합합니다:

| 방법론 | 개념 | BriefingVault 적용 |
|--------|------|-------------------|
| **PARA** (Tiago Forte) | 실행 가능성 기준 분류: Projects, Areas, Resources, Archives | sessions/ = Projects, decisions/ = Areas, references/ = Resources, archives/ = Archives |
| **Zettelkasten** (Luhmann) | 고유 ID와 명시적 링크를 가진 원자적 노트 | learnings/ 파일: `YYYYMMDDHHMMSS` ID, `related:` 링크 2개 이상 필수 |
| **LLM-wiki** (Karpathy) | 소스 노트에서 AI가 관리하는 개념 페이지 | wiki/ 페이지: 3회 이상 반복 키워드에 자동 제안 |

### 세션별 Diff

세션 시작 시 현재 git HEAD를 `.briefing/.session-start-head`에 저장합니다. 세션 종료 시 이 저장된 시점을 기준으로 diff를 계산하여, 이전 세션의 미커밋 변경 사항이 아닌 현재 세션의 변경 사항만 표시합니다.

### Obsidian과 함께 사용하기

1. Obsidian 열기 → **폴더를 보관함으로 열기** → `.briefing/` 선택
2. 노트가 그래프 뷰에 `[[wiki-links]]`로 연결되어 표시됩니다
3. YAML 프론트매터(`date`, `type`, `tags`)로 구조화 검색이 가능합니다
4. 의사결정과 학습의 타임라인이 세션에 걸쳐 자동으로 쌓입니다

---

## 결과를 확인하는 곳

설치된 도구들이 만들어 내는 결과를 어디에서 볼 수 있는지 정리했습니다. 각 도구가 무엇인지는 [사용하는 오픈소스 도구](#open-source-tools-used)에 있습니다.

| 도구 | 열기 | 실행 방법 | 확인 위치 |
|------|------|-----------|-----------|
| **codeburn** | <http://127.0.0.1:4747/> | `install.sh`가 `codeburn web --provider all --port 4747 --no-open`을 시작하거나 재사용 · `codeburn`은 TUI 실행 · `codeburn report --format json --period week`은 비대화형 출력 | 공유 대시보드. 시작 로그는 `${XDG_STATE_HOME:-$HOME/.local/state}/agent-harness-services/logs/codeburn.log`. 세션 파일은 읽기 전용이며 달러 금액은 API 정가 기준 추정치입니다. |
| **Serena** | <http://localhost:24282/dashboard/index.html> | MCP 서버로 자동 시작됩니다. 어느 세션에서든 `get_symbols_overview` / `find_symbol`을 호출하세요 | 서버가 실행 중일 때 쓸 수 있는 대시보드 (로그 + 도구별 호출 횟수). 프로젝트별 메모리는 작업 중인 저장소 안의 `.serena/`에 쌓이고, 전역 설정은 `~/.serena/serena_config.yml`입니다. |
| **Headroom** | <http://127.0.0.1:8787/stats> | MCP 도구 `headroom_compress` / `headroom_retrieve` / `headroom_stats`; `install.sh`가 공유 프록시 프로필 `agent-harness-shared`를 시작하거나 재사용 | 압축 통계. 프록시로 라우팅되기 전에는 비어 있을 수 있습니다. 시작 로그는 `${XDG_STATE_HOME:-$HOME/.local/state}/agent-harness-services/logs/headroom.log`. |
| **Archify** | `out.html` | 다이어그램을 요청하면 Boss가 `archify` 스킬로 라우팅합니다. 수동으로 하려면 `~/.claude/skills/archify`에서: `node bin/archify.mjs render workflow examples/agent-tool-call.workflow.json out.html` | 생성된 파일 — 아무 브라우저에서나 열면 됩니다. `node bin/archify.mjs check out.html`로 검증할 수 있습니다. |
| **OMC HUD** | Claude Code 스테이터스라인 | `install.sh`가 스테이터스라인으로 설치합니다. `/oh-my-claudecode:hud`로 재설정할 수 있습니다 | 세션 하단에 컨텍스트·할당량·모드가 실시간으로 표시됩니다. codeburn을 보완합니다 — HUD는 현재 세션, codeburn은 모든 세션. |

---

## GitHub Actions

| 워크플로 | 트리거 | 목적 |
|----------|---------|---------|
| **CI** | push, PR | JSON 설정, 에이전트 프론트매터, 스킬 존재 여부, 업스트림 파일 수 검증 |
| **Smoke** | push, PR | 4개 잡 — `hooks`(훅 실행), `shell`(설치 스크립트 형태), `drift`(모델 드리프트), `routing-refs`(끊어진 에이전트·스킬 참조) |
| **Update Upstream** | 3일마다 / 수동 | `git submodule update --remote` → `SOURCES.json` SHA 핀 갱신 → 업스트림 diff 보안 스캔 → 스캔 통과 시에만 자동 병합, 아니면 사람이 검토하도록 PR을 열어 둠 |
| **Auto Tag** | main에 push | `plugin.json` 버전 읽고 신규 시 git 태그 생성 |
| **Pages** | main에 push | `docs/index.html`을 GitHub Pages에 배포 |
| **CLA** | PR | 기여자 라이선스 동의 확인 |
| **Lint Workflows** | push, PR | GitHub Actions 워크플로 YAML 문법 검증 |

---

## my-claude 오리지널

업스트림 소스를 넘어 이 프로젝트를 위해 특별히 구축된 기능들:

| 기능 | 설명 |
|---------|-------------|
| **Boss 메타 오케스트레이터** | 동적 역량 탐색 → 의도 분류 → 5단계 우선순위 라우팅 → 위임 → 검증 |
| **3단계 스프린트** | 설계 (대화형) → 실행 (ralph를 통한 자율) → 리뷰 (설계 문서와 대화형 비교) |
| **에이전트 티어 우선순위** | core > omo > omc > vendored 중복 제거. 가장 특화된 에이전트가 선택됩니다. |
| **레인 소유권** | 오케스트레이션 → OMC, 개발 프로세스 → superpowers, 배포·QA·보안 → gstack (Boss P0), 언어·스택 지식 → ECC, AI·도메인 → 벤더링 에이전트 |
| **큐레이션 허용목록** | `scripts/skill-allowlists.sh`가 단일 진실 공급원 — 업스트림 수천 개 중 스킬 107개와 룰셋 9개만 살아남아, 목록에 없는 것은 세션 컨텍스트에 절대 올라오지 않습니다 |
| **Briefing Vault** | 세션, 의사결정, 학습, 참조를 포함하는 Obsidian 호환 `.briefing/` 디렉터리 |
| **에이전트 텔레메트리** | PostToolUse 훅이 에이전트 사용량을 `agent-usage.jsonl`에 기록 |
| **무변경 동기화 스킵** | 업스트림 동기화는 서브모듈 범프와 `SOURCES.json` 핀을 스테이징한 뒤, 그 diff가 비어 있지 않을 때만 PR을 생성 |
| **에이전트 중복 탐지** | `tests/validate-sync.sh`가 `agents/`와 omc·superpowers 서브모듈의 에이전트 파일명을 비교해 충돌을 보고 |

---

## 번들된 업스트림 버전

git 서브모듈을 통해 연결됩니다. 고정된 커밋은 `.gitmodules`가 기본으로 추적하며, [`upstream/SOURCES.json`](../../upstream/SOURCES.json)에 AI-BOM으로 미러링됩니다. `install.sh`는 `main`을 따라가지 않고 아래 SHA를 그대로 체크아웃합니다.

| 출처 | SHA | 날짜 | 비교 |
|--------|-----|------|------|
| [everything-claude-code](https://github.com/affaan-m/everything-claude-code) | `07756ce` | 2026-09-19 | [compare](https://github.com/affaan-m/everything-claude-code/compare/07756ce...HEAD) |
| [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) | `5281b19` | 2026-09-13 | [compare](https://github.com/Yeachan-Heo/oh-my-claudecode/compare/5281b19...HEAD) |
| [gstack](https://github.com/garrytan/gstack) | `a6b3a57` | 2026-09-16 | [compare](https://github.com/garrytan/gstack/compare/a6b3a57...HEAD) |
| [superpowers](https://github.com/obra/superpowers) | `5bf4e78` | 2026-09-19 | [compare](https://github.com/obra/superpowers/compare/5bf4e78...HEAD) |
| [archify](https://github.com/tt-a1i/archify) | `62904f3` (`v2.9.0`) | 2026-09-19 | [compare](https://github.com/tt-a1i/archify/compare/62904f3...HEAD) |

---

## 기여

이슈와 PR을 환영합니다. 새 에이전트를 추가할 때는 `agents/core/` 또는 `agents/omo/`에 `.md` 파일을 추가하고 `SETUP.md`를 업데이트하세요.

## 크레딧

[사용하는 오픈소스 도구](#open-source-tools-used)에 정리된 프로젝트들을 기반으로 구축되었습니다. 모든 작성자에게 감사드립니다.

## 라이선스

MIT 라이선스. 자세한 내용은 [LICENSE](../../LICENSE) 파일을 참조하세요.
