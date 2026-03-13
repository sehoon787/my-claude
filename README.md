> **LLM 에이전트라면 이 README를 건너뛰세요.** 아래 명령어로 설치 가이드를 직접 읽으세요:
> ```
> curl -s https://raw.githubusercontent.com/sehoon787/my-claude/main/SETUP.md
> ```

---

# my-claude

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Agents](https://img.shields.io/badge/agents-9-blue)
![MCP Servers](https://img.shields.io/badge/MCP_servers-3-green)
![Open Source Tools](https://img.shields.io/badge/open_source_tools-6-orange)

Claude Code 멀티에이전트 오케스트레이션 환경을 한 번에 구성하기 위한 레포지토리입니다.

6개 오픈소스 도구를 조합하여 9개의 전문 에이전트, 3개의 행동 교정 훅, 3개의 MCP 서버를 하나의 환경에 통합합니다. Sisyphus 오케스트레이터가 사용자 요청의 의도를 분류하고 적합한 전문 에이전트에게 위임합니다.

---

## 빠른 시작

### 사람이라면

**방법 1: Claude Code 플러그인으로 설치**

```bash
claude /plugin add sehoon787/my-claude
```

**방법 2: 수동 설치**

```bash
git clone https://github.com/sehoon787/my-claude.git
```

이후 `SETUP.md`의 지침에 따라 파일을 복사하세요.

### LLM 에이전트라면

SETUP.md를 fetch하여 지침을 따르세요:

```bash
curl -s https://raw.githubusercontent.com/sehoon787/my-claude/main/SETUP.md | head -50
```

---

## 주요 기능

### 멀티에이전트 오케스트레이션
- **Sisyphus 오케스트레이터**: 사용자 요청의 의도를 자동 분류하고, 최적의 전문 에이전트에게 위임
- **Hephaestus 자율 워커**: 탐색 → 계획 → 실행 → 검증 사이클을 중단 없이 자율 수행
- **모델 최적화 라우팅**: 작업 복잡도에 따라 Opus(고난도) / Sonnet(구현) 자동 선택

### 런타임 행동 교정
- **Delegation Guard** (PreToolUse): 오케스트레이터가 직접 파일 수정 시도 시 서브에이전트 위임을 강제
- **Subagent Verifier** (SubagentStop): 서브에이전트 작업 완료 후 독립 검증을 강제
- **Completion Check** (Stop): 모든 태스크가 완료·검증되었는지 확인 후 세션 종료 허용

### 외부 지식 연동 (MCP)
- **Context7**: 라이브러리 공식 문서를 실시간으로 조회
- **Exa**: 의미 기반 웹 검색 (월 1,000건 무료)
- **grep.app**: GitHub 오픈소스 코드 검색

### 통합 생태계
- SETUP.md를 따르면 **70+ 에이전트, 33 스킬, 14 룰**을 한 환경에 구성
- 6개 오픈소스 도구(OMC, omo, ECC, Anthropic Skills, Agency, Karpathy)를 하나로 통합

---

## my-claude 에이전트

이 프로젝트에서 제공하는 9개의 전문 에이전트입니다. 설치 후 전체 에이전트 목록(70+)은 아래 [설치 후 전체 구성 요소](#설치-후-전체-구성-요소)를 참고하세요.

| 에이전트 | 모델 | 역할 |
|---------|------|------|
| **Sisyphus** | Opus | 마스터 오케스트레이터. 사용자 요청의 의도를 분류하고 적합한 전문 에이전트에게 위임 |
| **Hephaestus** | Opus | 자율 딥 워커. 탐색 → 계획 → 실행 → 검증 사이클을 자율적으로 수행 |
| **Metis** | Opus | 사전 의도 분석. AI-slop 방지를 위해 요청을 실행 전에 구조화 |
| **Atlas** | Opus | 마스터 태스크 오케스트레이터. 4단계 QA 사이클로 복잡한 작업을 분해 및 조율 |
| **Oracle** | Opus | 전략적 기술 자문가. 코드를 변경하지 않고 read-only로 분석하여 방향 제시 |
| **Momus** | Opus | 작업 계획 검토자. 승인 편향적 관점에서 계획을 검토. read-only |
| **Prometheus** | Opus | 인터뷰 기반 계획 수립 컨설턴트. 대화를 통해 요구사항을 명확화 |
| **Librarian** | Sonnet | MCP를 활용한 오픈소스 문서 연구 에이전트 |
| **Multimodal-Looker** | Sonnet | 시각 분석 에이전트. 이미지/스크린샷을 분석. read-only |

---

## 설치 후 전체 구성 요소

SETUP.md를 따라 설치하면 다음이 구성됩니다:

| 구분 | 수량 | 출처 |
|------|------|------|
| 에이전트 | 70+ | my-claude 9 + OMC 19 + Agency 42+ |
| 스킬 | 33 | Anthropic Official + ECC |
| 룰 | 14 | ECC (common 9 + typescript 5) |
| MCP 서버 | 3 | Context7, Exa, grep.app |
| 훅 | 3 | my-claude (Sisyphus protocol) |

<details>
<summary>my-claude 에이전트 (9개) — omo 에이전트의 Claude Code standalone 버전</summary>

| 에이전트 | 모델 | 유형 | 역할 | Read-only |
|---------|------|------|------|-----------|
| Sisyphus | Opus | 오케스트레이터 | 의도 분류 → 전문 에이전트 위임 → 독립 검증. 직접 코드 작성 안 함 | No |
| Hephaestus | Opus | 자율 실행 | 탐색→계획→실행→검증 자율 수행. 허락 없이 작업 완료 | No |
| Metis | Opus | 분석 | 사용자 의도 분석, 모호성 감지, AI-slop 방지 | Yes |
| Atlas | Opus | 오케스트레이터 | 태스크 위임 + 4단계 QA 검증. 직접 코드 작성 안 함 | No |
| Oracle | Opus | 자문 | 전략적 기술 자문. 아키텍처, 디버깅 컨설팅 | Yes |
| Momus | Opus | 검토 | 작업 계획 실행 가능성 검토. 승인 편향 | Yes |
| Prometheus | Opus | 계획 | 인터뷰 기반 상세 계획 수립. .md 파일만 작성 | Partial |
| Librarian | Sonnet | 연구 | MCP 활용 오픈소스 문서 검색 | Yes |
| Multimodal-Looker | Sonnet | 시각 분석 | 이미지/스크린샷/다이어그램 분석 | Yes |

</details>

<details>
<summary>OMC 에이전트 (19개) — Oh My Claude Code 전문 에이전트</summary>

| 에이전트 | 역할 |
|---------|------|
| analyst | 사전 분석 — 계획 수립 전 상황 파악 |
| architect | 시스템 설계 및 아키텍처 결정 |
| code-reviewer | 집중 코드 리뷰 |
| code-simplifier | 코드 간소화 및 정리 |
| critic | 비판적 분석, 대안 제시 |
| debugger | 집중 디버깅 |
| designer | UI/UX 디자인 가이드 |
| document-specialist | 문서 작성 및 관리 |
| executor | 태스크 실행 |
| explore | 코드베이스 탐색 |
| git-master | Git 워크플로우 관리 |
| planner | 빠른 계획 수립 |
| qa-tester | 품질 보증 테스트 |
| scientist | 연구 및 실험 |
| security-reviewer | 보안 리뷰 |
| test-engineer | 테스트 작성 및 유지보수 |
| tracer | 실행 추적 및 분석 |
| verifier | 최종 검증 |
| writer | 콘텐츠 및 문서 작성 |

</details>

<details>
<summary>Agency 에이전트 (42+개) — 비즈니스 전문 페르소나</summary>

**Engineering (22개)**

| 에이전트 | 역할 |
|---------|------|
| ai-engineer | AI/ML 엔지니어링 |
| autonomous-optimization-architect | 자율 최적화 아키텍처 |
| backend-architect | 백엔드 아키텍처 |
| code-reviewer | 코드 리뷰 |
| data-engineer | 데이터 엔지니어링 |
| database-optimizer | 데이터베이스 최적화 |
| devops-automator | DevOps 자동화 |
| embedded-firmware-engineer | 임베디드 펌웨어 |
| feishu-integration-developer | Feishu 통합 개발 |
| frontend-developer | 프론트엔드 개발 |
| git-workflow-master | Git 워크플로우 |
| incident-response-commander | 장애 대응 |
| mobile-app-builder | 모바일 앱 빌드 |
| rapid-prototyper | 빠른 프로토타이핑 |
| security-engineer | 보안 엔지니어링 |
| senior-developer | 시니어 개발 |
| software-architect | 소프트웨어 아키텍처 |
| solidity-smart-contract-engineer | Solidity 스마트 컨트랙트 |
| sre | Site Reliability Engineering |
| technical-writer | 기술 문서 작성 |
| threat-detection-engineer | 위협 탐지 엔지니어링 |
| wechat-mini-program-developer | WeChat 미니 프로그램 개발 |

**Testing (8개)**

| 에이전트 | 역할 |
|---------|------|
| accessibility-auditor | 접근성 감사 |
| api-tester | API 테스트 |
| evidence-collector | 테스트 증거 수집 |
| performance-benchmarker | 성능 벤치마크 |
| reality-checker | 현실성 검증 |
| test-results-analyzer | 테스트 결과 분석 |
| tool-evaluator | 도구 평가 |
| workflow-optimizer | 워크플로우 최적화 |

**Design (8개)**

| 에이전트 | 역할 |
|---------|------|
| brand-guardian | 브랜드 가이드라인 수호 |
| image-prompt-engineer | 이미지 프롬프트 엔지니어링 |
| inclusive-visuals-specialist | 포용적 시각 디자인 |
| ui-designer | UI 디자인 |
| ux-architect | UX 아키텍처 |
| ux-researcher | UX 리서치 |
| visual-storyteller | 시각적 스토리텔링 |
| whimsy-injector | 재미 요소 주입 |

**Product (4개)**

| 에이전트 | 역할 |
|---------|------|
| behavioral-nudge-engine | 행동 넛지 설계 |
| feedback-synthesizer | 피드백 종합 |
| sprint-prioritizer | 스프린트 우선순위 |
| trend-researcher | 트렌드 리서치 |

</details>

<details>
<summary>스킬 (33개) — Anthropic Official + ECC</summary>

| 스킬 | 출처 | 설명 |
|------|------|------|
| algorithmic-art | Anthropic | p5.js 기반 생성형 아트 |
| backend-patterns | ECC | 백엔드 아키텍처 패턴 |
| brand-guidelines | Anthropic | Anthropic 브랜드 스타일 적용 |
| canvas-design | Anthropic | PNG/PDF 시각 디자인 |
| claude-api | Anthropic | Claude API/SDK 앱 빌드 |
| clickhouse-io | ECC | ClickHouse 쿼리 최적화 |
| coding-standards | ECC | TypeScript/React 코딩 표준 |
| continuous-learning | ECC | 세션에서 패턴 자동 추출 |
| continuous-learning-v2 | ECC | 본능 기반 학습 시스템 |
| doc-coauthoring | Anthropic | 문서 공동 작성 워크플로우 |
| docx | Anthropic | Word 문서 생성/편집 |
| eval-harness | ECC | 평가 주도 개발 (EDD) |
| frontend-design | Anthropic | 프론트엔드 UI 디자인 |
| frontend-patterns | ECC | React/Next.js 패턴 |
| internal-comms | Anthropic | 사내 커뮤니케이션 작성 |
| iterative-retrieval | ECC | 점진적 컨텍스트 검색 |
| karpathy-guidelines | Anthropic | Karpathy AI 코딩 가이드라인 |
| learned | ECC | 학습된 패턴 저장소 |
| mcp-builder | Anthropic | MCP 서버 개발 가이드 |
| pdf | Anthropic | PDF 읽기/합치기/분할/OCR |
| postgres-patterns | ECC | PostgreSQL 최적화 |
| pptx | Anthropic | PowerPoint 생성/편집 |
| project-guidelines-example | Anthropic | 프로젝트 가이드라인 예제 |
| security-review | ECC | 보안 체크리스트 |
| skill-creator | Anthropic | 커스텀 스킬 생성 메타스킬 |
| slack-gif-creator | Anthropic | Slack용 GIF 생성 |
| strategic-compact | ECC | 전략적 컨텍스트 압축 |
| tdd-workflow | ECC | TDD 워크플로우 강제 |
| theme-factory | Anthropic | 아티팩트 테마 적용 |
| verification-loop | Anthropic | 검증 루프 |
| web-artifacts-builder | Anthropic | 복합 웹 아티팩트 빌드 |
| webapp-testing | Anthropic | Playwright 웹앱 테스트 |
| xlsx | Anthropic | Excel 파일 생성/편집 |

</details>

<details>
<summary>룰 (14개) — ECC 코딩 규칙</summary>

**Common (9개)** — 모든 프로젝트에 적용

| 룰 | 설명 |
|----|------|
| agents.md | 에이전트 행동 규칙 |
| coding-style.md | 코딩 스타일 |
| development-workflow.md | 개발 워크플로우 |
| git-workflow.md | Git 워크플로우 |
| hooks.md | 훅 사용 규칙 |
| patterns.md | 디자인 패턴 |
| performance.md | 성능 최적화 |
| security.md | 보안 규칙 |
| testing.md | 테스트 규칙 |

**TypeScript (5개)** — TypeScript 프로젝트 전용

| 룰 | 설명 |
|----|------|
| coding-style.md | TS 코딩 스타일 |
| hooks.md | TS 훅 패턴 |
| patterns.md | TS 디자인 패턴 |
| security.md | TS 보안 규칙 |
| testing.md | TS 테스트 규칙 |

</details>

<details>
<summary>MCP 서버 (3개) + 행동 교정 훅 (3개)</summary>

**MCP 서버**

| 서버 | URL | 용도 | 비용 |
|------|-----|------|------|
| Context7 | mcp.context7.com | 라이브러리 문서 실시간 조회 | 무료 (키 등록 시 한도 증가) |
| Exa | mcp.exa.ai | 의미 기반 웹 검색 | 무료 1k req/월 |
| grep.app | mcp.grep.app | 오픈소스 GitHub 코드 검색 | 무료 |

**행동 교정 훅**

| 훅 | 이벤트 | 동작 |
|----|--------|------|
| Delegation Guard | PreToolUse (Edit/Write) | Sisyphus가 직접 파일 수정 시 서브에이전트 위임을 상기 |
| Subagent Verifier | SubagentStop | 서브에이전트 완료 후 독립 검증 수행을 강제 |
| Completion Check | Stop | 모든 태스크가 완료 및 검증되었는지 확인 후 세션 종료 허용 |

</details>

---

## 전체 아키텍처

```
┌─────────────────────────────────────────────────────────┐
│                    사용자 요청                            │
└─────────────────────┬───────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────────┐
│  [Sisyphus] 마스터 오케스트레이터                          │
│  의도 분류 → 전문 에이전트 위임                            │
└──────┬──────────────┬──────────────┬────────────────────┘
       ↓              ↓              ↓
┌──────────────┐ ┌──────────────┐ ┌──────────────────────┐
│  [Metis]     │ │  [Atlas]     │ │  [Hephaestus]        │
│  의도 분석   │ │  태스크 조율 │ │  자율 실행           │
└──────┬───────┘ └──────┬───────┘ └──────────────────────┘
       ↓                ↓
┌─────────────────────────────────────────────────────────┐
│  Karpathy Guidelines (행동 가이드라인, 항상 활성화)        │
│  ECC Rules (언어별 코딩 룰, 항상 활성화)                  │
│  Hooks: PreToolUse / SubagentStop / Stop                 │
└─────────────────────┬───────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────────┐
│  전문 에이전트 레이어                                     │
│    ├── OMC 에이전트 (executor, debugger, test-engineer)  │
│    ├── Agency 에이전트 (UX architect, security auditor)  │
│    ├── ECC 커맨드 (/tdd, /code-review, /build-fix)      │
│    └── Anthropic 스킬 (pdf, docx, mcp-builder)          │
└─────────────────────┬───────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────────┐
│  MCP 서버 레이어                                          │
│    ├── Context7 (라이브러리 문서 실시간 조회)              │
│    ├── Exa (의미 기반 웹 검색)                            │
│    └── grep.app (오픈소스 코드 검색)                      │
└─────────────────────────────────────────────────────────┘

    ┌─────────────────────────────────────────────────────┐
    │ omo 브릿지 (OpenCode 사용 시)                        │
    │  claude-code-agent-loader: ~/.claude/agents/*.md 로드│
    │  claude-code-plugin-loader: CC 플러그인 로드          │
    │  → OpenCode에서 OMC + omo 에이전트 모두 사용 가능     │
    └─────────────────────────────────────────────────────┘
```

---

## 사용하는 오픈소스 도구

### 1. [Oh My Claude Code (OMC)](https://github.com/Yeachan-Heo/oh-my-claudecode)

Claude Code 전용 멀티에이전트 오케스트레이션 플러그인. 18개의 전문 에이전트(아키텍트, 디버거, 코드리뷰어, 보안검토자 등)가 역할별로 분업하며, `autopilot:` 같은 매직 키워드로 자동 병렬 실행을 활성화합니다.

### 2. [Oh My OpenAgent (omo)](https://github.com/code-yeongyu/oh-my-openagent)

멀티플랫폼 에이전트 하네스. `claude-code-agent-loader`와 `claude-code-plugin-loader`로 Claude Code 에코시스템과 브릿지됩니다. Claude, GPT, Gemini 등 8개 프로바이더를 카테고리별로 자동 라우팅합니다. 이 레포의 9개 에이전트는 omo 에이전트를 Claude Code standalone `.md` 형식으로 적응한 버전입니다.

### 3. [Andrej Karpathy Skills](https://github.com/forrestchang/andrej-karpathy-skills)

Andrej Karpathy가 제안한 AI 코딩 행동 가이드라인 4원칙(Think Before Coding, Simplicity First, Surgical Changes, Goal-Driven Execution). CLAUDE.md에 포함되어 모든 세션에서 항상 활성화됩니다.

### 4. [Everything Claude Code (ECC)](https://github.com/affaan-m/everything-claude-code)

67개 스킬 + 17개 에이전트 + 45개 커맨드 + 언어별 룰을 제공하는 종합 프레임워크. `/tdd`, `/plan`, `/code-review`, `/build-fix` 같은 슬래시 커맨드로 반복적인 개발 패턴을 자동화합니다.

### 5. [Anthropic Official Skills](https://github.com/anthropics/skills)

Anthropic이 직접 제공하는 공식 에이전트 스킬 레포지토리. PDF 파싱, Word/Excel/PowerPoint 문서 조작, MCP 서버 생성 등 전문 태스크를 가능하게 합니다.

### 6. [Agency Agents](https://github.com/msitarzewski/agency-agents)

164개의 비즈니스 전문 에이전트 페르소나 라이브러리. UX 아키텍트, 데이터 엔지니어, 보안 감사자, QA 매니저 등 기술 역할을 넘어 비즈니스 맥락의 전문 관점을 제공합니다.

---

## 에이전트 겹침 가이드

OMC와 omo에는 기능이 겹치는 에이전트 쌍이 있습니다. 모두 유지하되 상황에 따라 선택합니다.

| 기능 | OMC | omo | 선택 기준 |
|------|-----|-----|-----------|
| 계획 | planner | Prometheus | 빠른 작업 → OMC planner, 복잡한 프로젝트 → omo Triad (Metis → Prometheus → Momus) |
| 코드리뷰 | code-reviewer | Momus | OMC: 집중 리뷰, omo: AI-slop 감지 포함 |
| 탐색 | explore | Explore | 현재 플랫폼의 것을 사용 |

**omo 고유 에이전트 (6개):** Sisyphus, Sisyphus-Junior, Hephaestus, Oracle, Multimodal-Looker, Librarian

**OMC 고유 에이전트 (14개):** analyst, architect, code-simplifier, critic, debugger, designer, document-specialist, executor, git-master, qa-tester, scientist, test-engineer, verifier, writer

자세한 분석은 [SETUP.md의 Agent Overlap Analysis](./SETUP.md#11-agent-overlap-analysis-omc-vs-omo)를 참고하세요.

---

## Contributing

이슈 및 PR은 환영합니다. 새로운 에이전트를 추가할 경우 `agents/` 디렉토리에 `.md` 파일로 추가하고, `SETUP.md`의 에이전트 목록을 업데이트해 주세요.

---

## Credits

이 레포지토리는 다음 오픈소스 프로젝트들의 작업에 기반합니다:

- [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) — Yeachan Heo
- [oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent) — code-yeongyu
- [andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills) — forrestchang
- [everything-claude-code](https://github.com/affaan-m/everything-claude-code) — affaan-m
- [anthropic/skills](https://github.com/anthropics/skills) — Anthropic
- [agency-agents](https://github.com/msitarzewski/agency-agents) — msitarzewski

---

## License

MIT License. 자세한 내용은 [LICENSE](./LICENSE) 파일을 참고하세요.
