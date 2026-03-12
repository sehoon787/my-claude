# my-claude

Claude Code 멀티에이전트 오케스트레이션 환경을 한 번에 세팅하기 위한 레포지토리입니다.

## 이 레포가 하는 일

AI 코딩 에이전트(Claude Code)의 성능을 극대화하기 위해, 여러 오픈소스 도구들을 조합하여 **멀티에이전트 오케스트레이션 환경**을 구성합니다. 이 레포의 `SETUP.md`를 AI에게 제공하면 동일한 환경을 그대로 재현할 수 있습니다.

## 레포 구성

```
├── README.md      # 이 파일 (한글 소개)
├── SETUP.md       # 전체 세팅 가이드 (영문, AI 재현용)
├── REFACTOR.md
└── agents/        # omo에서 Claude Code로 포팅한 커스텀 에이전트
    ├── metis.md   # 사전 의도 분석 에이전트
    └── atlas.md   # 마스터 태스크 오케스트레이터
```

---

## 사용하는 오픈소스 & 레포지토리

### 1. [Oh My Claude Code (OMC)](https://github.com/Yeachan-Heo/oh-my-claudecode)

**무엇인가:** Claude Code 전용 멀티에이전트 오케스트레이션 플러그인

**왜 사용하는가:** Claude Code 단독으로는 하나의 에이전트가 모든 작업을 처리합니다. OMC를 적용하면 18개의 전문 에이전트(아키텍트, 디버거, 코드리뷰어, 보안검토자 등)가 역할별로 분업하여, 복잡한 멀티스텝 작업의 정확도와 효율성이 크게 향상됩니다. `autopilot:`, `ulw` 같은 매직 키워드로 자동 실행과 병렬화를 간단히 활성화할 수 있고, HUD 상태표시줄로 실시간 모니터링도 가능합니다.

---

### 2. [Oh My OpenCode (omo)](https://github.com/code-yeongyu/oh-my-openagent)

**무엇인가:** OpenCode 기반 멀티모델 에이전트 오케스트레이션 플러그인

**왜 사용하는가:** OMC가 Claude 단일 모델에 특화되어 있다면, omo는 Claude, GPT, Gemini 등 8개 프로바이더를 카테고리별로 자동 라우팅합니다. 특히 Sisyphus(오케스트레이터), Prometheus(사전계획), Metis(의도분석), Atlas(태스크관리) 등 OMC에 없는 고유 에이전트들이 있어, 이 중 핵심 2개(Metis, Atlas)를 Claude Code 형식으로 포팅하여 함께 사용합니다.

---

### 3. [Andrej Karpathy Skills](https://github.com/forrestchang/andrej-karpathy-skills)

**무엇인가:** Andrej Karpathy가 제안한 AI 코딩 행동 가이드라인 4원칙

**왜 사용하는가:** LLM이 코드를 생성할 때 가장 흔한 실수들 — 과잉 엔지니어링, 불필요한 리팩토링, 요청하지 않은 기능 추가 — 을 구조적으로 방지합니다. 4가지 원칙(Think Before Coding, Simplicity First, Surgical Changes, Goal-Driven Execution)이 CLAUDE.md에 포함되어 **모든 세션에서 항상 활성화**되므로, 코드 품질의 기본 수준을 일관되게 유지합니다.

---

### 4. [Everything Claude Code (ECC)](https://github.com/affaan-m/everything-claude-code)

**무엇인가:** 67개 스킬 + 17개 에이전트 + 45개 커맨드 + 언어별 룰을 제공하는 종합 프레임워크

**왜 사용하는가:** OMC와 omo가 "에이전트 오케스트레이션"에 집중한다면, ECC는 **실무 워크플로우**를 제공합니다. `/tdd`(테스트 주도 개발), `/plan`(구현 계획), `/code-review`(코드 리뷰), `/build-fix`(빌드 에러 수정) 같은 슬래시 커맨드로 반복적인 개발 패턴을 자동화합니다. 또한 언어별 룰(TypeScript, Python, Go, Swift 등)이 코딩 스타일, 보안, 테스트 관행을 프로젝트에 맞게 강제합니다.

---

### 5. [Anthropic Official Skills](https://github.com/anthropics/skills)

**무엇인가:** Anthropic이 직접 제공하는 공식 에이전트 스킬 레포지토리

**왜 사용하는가:** 다른 도구들이 "어떻게 일할 것인가"(오케스트레이션, 룰)에 집중한다면, 이 스킬들은 **"무엇을 할 수 있는가"(능력)**를 확장합니다. PDF 파싱, Word/Excel/PowerPoint 문서 조작, MCP 서버 생성 등 Claude가 기본적으로 할 수 없는 전문 태스크를 가능하게 합니다. Anthropic 공식이므로 Claude와의 호환성이 가장 높고, `skill-creator` 메타스킬로 커스텀 스킬을 직접 만들 수도 있습니다.

---

### 6. [Agency Agents](https://github.com/msitarzewski/agency-agents)

**무엇인가:** 164개의 비즈니스 전문 에이전트 페르소나 라이브러리

**왜 사용하는가:** OMC/omo 에이전트가 "코드리뷰어", "디버거" 같은 기술 역할이라면, Agency Agents는 **비즈니스 역할까지 확장**합니다. UX 아키텍트, 데이터 엔지니어, 보안 감사자, QA 매니저 등 각 에이전트가 고유한 성격, 워크플로우, 산출물 템플릿을 가지고 있어, 단순 코드 생성을 넘어 제품 설계, 테스트 전략, 보안 감사 등 다양한 비즈니스 맥락에서 전문적인 관점을 제공합니다.

---

## 전체 아키텍처

```
┌─────────────────────────────────────────────────────────┐
│                    사용자 요청                            │
└─────────────────────┬───────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────────┐
│  Karpathy Guidelines (행동 가이드라인, 항상 활성화)        │
│  ECC Rules (언어별 코딩 룰, 항상 활성화)                  │
└─────────────────────┬───────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────────┐
│  [Metis] 의도 분석 → [Planner] 계획 수립                 │
└─────────────────────┬───────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────────┐
│  [Atlas] 태스크 오케스트레이션                             │
│    ├── OMC 에이전트 (executor, debugger, test-engineer)  │
│    ├── Agency 에이전트 (UX architect, security auditor)  │
│    ├── ECC 커맨드 (/tdd, /code-review, /build-fix)      │
│    └── Anthropic 스킬 (pdf, docx, mcp-builder)          │
└─────────────────────┬───────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────────┐
│  [Verifier] 최종 검증                                    │
└─────────────────────────────────────────────────────────┘
```

---

## 빠른 시작

자세한 설치 방법은 [SETUP.md](./SETUP.md)를 참고하세요.
