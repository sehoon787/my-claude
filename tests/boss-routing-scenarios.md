# Boss Routing Test Scenarios (185)

## Test Framework

Each scenario evaluates Boss's routing decision against Phase 2 logic:
- **P1**: Skill Match (Dynamic Registry Lookup)
- **CR**: Skill vs Agent Conflict Resolution (3D: Scope/Depth×2/Interactivity)
- **P2**: Specialist Agent Match
- **P3a**: Boss Direct Orchestration (≤4 agents, simple deps)
- **P3b**: Sub-Orchestrator (5+ agents or complex deps)
- **P4**: General-Purpose Fallback
- **ASK**: Clarifying question required (ambiguous intent)

### Scoring (Depth weighted 2x)
- Scope→Skill=1, Depth→Skill=2, Interactivity→Skill=1 → max 4 Skill pts
- Scope→Agent=1, Depth→Agent=2, Interactivity→Agent=1 → max 4 Agent pts
- Higher total wins. Tie → ASK.

### Verified Skill Registry (from system-reminder)
pdf, docx, xlsx, pptx, frontend-design, tdd-workflow, security-review, skill-creator,
mcp-builder, algorithmic-art, brand-guidelines, canvas-design, claude-api, clickhouse-io,
coding-standards, continuous-learning, continuous-learning-v2, doc-coauthoring, eval-harness,
frontend-patterns, backend-patterns, internal-comms, iterative-retrieval, karpathy-guidelines,
postgres-patterns, slack-gif-creator, strategic-compact, theme-factory, verification-loop,
web-artifacts-builder, webapp-testing

### Verified Agent Registry (71 global)
analyst, architect, atlas, boss, code-reviewer, code-simplifier, critic, debugger,
designer, document-specialist, executor, explore, git-master, hephaestus, librarian,
metis, momus, multimodal-looker, oracle, planner, prometheus, qa-tester, scientist,
security-reviewer, sisyphus, test-engineer, tracer, verifier, writer,
+ 8 design-*, 22 engineering-*, 8 testing-*, 4 product-* (Agency agents, all model=sonnet)

---

## Category 1: Pure Skill Requests (1-20)

| # | Request | Expected Route | Score | Reasoning |
|---|---------|---------------|-------|-----------|
| 1 | "이 보고서를 PDF로 만들어줘" | P1→Skill(pdf) | — | File-format deliverable override |
| 2 | "Create a Word document with meeting notes" | P1→Skill(docx) | — | File-format deliverable override |
| 3 | "매출 데이터를 엑셀로 정리해줘" | P1→Skill(xlsx) | — | File-format deliverable override |
| 4 | "Make a pitch deck for investors" | P1→Skill(pptx) | — | File-format deliverable override |
| 5 | "generative art로 배경 이미지 만들어줘" | P1→Skill(algorithmic-art) | S4:A0 | Narrow/Shallow/One-shot |
| 6 | "새로운 skill 하나 만들어줘" | P1→Skill(skill-creator) | S4:A0 | Narrow/Shallow/One-shot |
| 7 | "MCP 서버 하나 만들어야 해" | P1→Skill(mcp-builder) | S4:A0 | Narrow/Shallow/One-shot, skill desc matches |
| 8 | "이 CSV를 깔끔한 스프레드시트로 변환" | P1→Skill(xlsx) | — | File-format deliverable override |
| 9 | "프레젠테이션 슬라이드 20장 만들어줘" | P1→Skill(pptx) | — | File-format deliverable override |
| 10 | "이 함수에 대한 테스트부터 짜고 구현해줘" | Skill(tdd-workflow) inside Agent | S1:A3 | Methodology+Implementation: Narrow but Deep(implement)+Iterative(TDD cycle) |
| 11 | "브랜드 가이드라인에 맞게 색상 적용해줘" | P1→Skill(brand-guidelines) | S4:A0 | Narrow/Shallow/One-shot |
| 12 | "Combine these 3 PDFs into one" | P1→Skill(pdf) | — | File-format operation |
| 13 | "이 .docx 파일에서 표 추출해줘" | P1→Skill(docx) | — | File-format operation |
| 14 | "ClickHouse 쿼리 최적화 패턴 알려줘" | P1→Skill(clickhouse-io) | S4:A0 | Narrow/Shallow/One-shot, reference lookup |
| 15 | "Slack용 GIF 만들어줘" | P1→Skill(slack-gif-creator) | S4:A0 | Narrow/Shallow/One-shot |
| 16 | "theme 적용해줘" | P1→Skill(theme-factory) | S4:A0 | Narrow/Shallow/One-shot |
| 17 | "internal comms 작성해줘" | P1→Skill(internal-comms) | S4:A0 | Narrow/Shallow/One-shot |
| 18 | "Anthropic SDK 사용법 알려줘" | P1→Skill(claude-api) | S4:A0 | Skill desc: "user asks to use Claude API" |
| 19 | "webapp 테스트해줘" | P1→Skill(webapp-testing) | S4:A0 | Skill desc: "testing local web applications" |
| 20 | "context 정리 좀 해줘" | P1→Skill(strategic-compact) | S4:A0 | Skill desc: "manual context compaction" |

## Category 2: Skill vs Agent Conflict (21-45)

| # | Request | Dimensions (S/D/I) | Score | Expected Route | Reasoning |
|---|---------|-------------------|-------|---------------|-----------|
| 21 | "이 함수의 보안 취약점 체크해줘" | N/S/O | S4:A0 | P1→Skill(security-review) | All 3 → Skill |
| 22 | "프로젝트 전체 보안 감사해줘" | W/D/I | S0:A4 | P2→Agent(security-reviewer) | All 3 → Agent |
| 23 | "auth 모듈 코드 리뷰해줘" | N/D/O | — | P2→Agent(code-reviewer) | No code-review skill exists → candidate check skips to P2 directly |
| 24 | "전체 코드베이스 코딩 표준 적용해줘" | W/D/I | S0:A4 | Skill(coding-standards) inside Agent | Methodology+Implementation pattern. Wide scope needs Agent execution |
| 25 | "TDD로 결제 모듈 전체 구현해줘" | W/D/I | S0:A4 | Skill(tdd-workflow) inside Agent | Methodology+Implementation pattern |
| 26 | "이 파일 하나 TDD로 테스트 작성" | N/S/O | S4:A0 | P1→Skill(tdd-workflow) | All 3 → Skill |
| 27 | "frontend 패턴 적용해서 컴포넌트 리팩토링" | W/D/I | S0:A4 | Skill(frontend-patterns) inside Agent | Methodology+Implementation |
| 28 | "PostgreSQL 인덱스 최적화 조언해줘" | N/S/O | S4:A0 | P1→Skill(postgres-patterns) | Advice lookup, narrow scope |
| 29 | "DB 스키마 전체 리뷰하고 최적화해줘" | W/D/I | S0:A4 | P2→Agent(Database Optimizer) | All 3 → Agent |
| 30 | "이 API 엔드포인트 보안 강화해줘" | N/D/O | S2:A2 | Tie→but security-review skill exists → CR: Narrow+One-shot(2) vs Deep×2(2)=Tie→ASK scope | "강화"=implement changes? If yes, Agent. If advice only, Skill |
| 31 | "백엔드 아키텍처 패턴 정리해줘" | N/S/O | S4:A0 | P1→Skill(backend-patterns) | Reference lookup |
| 32 | "백엔드 전체 아키텍처 재설계해줘" | W/D/I | S0:A4 | P2→Agent(Backend Architect) | All 3 → Agent |
| 33 | "이 코드에서 배울 수 있는 패턴 추출" | N/D/O | — | P2→Agent(analyst) or P4→Agent(opus) | No skill match → skip to P2. analyst handles pattern analysis, not code-simplifier |
| 34 | "프로젝트 전체에서 재사용 패턴 분석" | W/D/I | S0:A4 | P2→Agent(Software Architect) | All 3 → Agent |
| 35 | "evaluation 프레임워크 적용해줘" | N/S/O | S4:A0 | P1→Skill(eval-harness) | Framework application = shallow (apply template), narrow scope, one-shot |
| 36 | "Claude API로 챗봇 만들어줘" | W/D/I | S0:A4 | Skill(claude-api) inside Agent | Methodology+Implementation |
| 37 | "이 HTML을 예쁘게 꾸며줘" | N/S/O | S4:A0 | P1→Skill(frontend-design) | Single file, shallow styling |
| 38 | "웹앱 전체 UI 리디자인" | W/D/I | S0:A4 | P2→Agent(designer) or Agent(UI Designer) | All 3 → Agent |
| 39 | "문서 같이 작성하자" | N/S/I | S3:A1 | P1→Skill(doc-coauthoring) | Iterative but narrow+shallow → Skill wins 3:1 |
| 40 | "SQL 쿼리 하나 최적화해줘" | N/S/O | S4:A0 | P1→Skill(postgres-patterns) | Consistent with #28 |
| 41 | "보안 체크리스트 한번 돌려줘" | N/S/O | S4:A0 | P1→Skill(security-review) | Checklist = shallow, one-shot |
| 42 | "이 코드 간소화해줘" | N/D/O | S2:A2 | Tie→no simplify skill → P2→Agent(code-simplifier) | No skill candidate → skip to P2 |
| 43 | "포스터 디자인해줘" | N/S/O | S4:A0 | P1→Skill(canvas-design) | Skill desc: "create a poster" |
| 44 | "랜딩 페이지 디자인해줘" | N/S/O | S4:A0 | P1→Skill(frontend-design) | Skill desc: "landing pages" |
| 45 | "web artifact 복잡한 거 만들어줘" | N/D/I | S1:A3 | P2→Agent(designer) or Agent(Frontend Developer) | Score A3>S1 → Agent wins. web-artifacts-builder skill exists but 3D scoring overrides |

## Category 3: Pure Agent Requests (46-70)

| # | Request | Expected Route | Reasoning |
|---|---------|---------------|-----------|
| 46 | "이 버그 원인 찾아줘" | P2→Agent(debugger) | Investigation, no skill match |
| 47 | "메모리 누수 추적해줘" | P2→Agent(tracer) | Evidence-driven causal tracing |
| 48 | "production 장애 대응해줘" | P2→Agent(Incident Response Commander) | Specialist domain |
| 49 | "ESP32 펌웨어 작성해줘" | P2→Agent(Embedded Firmware Engineer) | Specialist domain |
| 50 | "Solidity 스마트 컨트랙트 작성해줘" | P2→Agent(Solidity Smart Contract Engineer) | Specialist domain |
| 51 | "CI/CD 파이프라인 구축해줘" | P2→Agent(DevOps Automator) | Specialist domain |
| 52 | "WeChat 미니프로그램 개발해줘" | P2→Agent(WeChat Mini Program Developer) | Specialist domain |
| 53 | "Feishu 봇 만들어줘" | P2→Agent(Feishu Integration Developer) | Specialist domain |
| 54 | "SLO 설정하고 에러 버짓 관리해줘" | P2→Agent(SRE) | Specialist domain |
| 55 | "SIEM 탐지 룰 작성해줘" | P2→Agent(Threat Detection Engineer) | Specialist domain |
| 56 | "데이터 파이프라인 설계해줘" | P2→Agent(Data Engineer) | Specialist domain |
| 57 | "접근성 감사해줘" | P2→Agent(Accessibility Auditor) | Specialist domain |
| 58 | "API 성능 벤치마크 돌려줘" | P2→Agent(Performance Benchmarker) | Specialist domain |
| 59 | "이 오픈소스 라이브러리 소스 분석해줘" | P2→Agent(librarian) | Source code understanding |
| 60 | "이 스크린샷 분석해줘" | P2→Agent(multimodal-looker) | Visual analysis |
| 61 | "git 히스토리 정리하고 rebase 해줘" | P2→Agent(git-master) | Git specialist |
| 62 | "사용자 피드백 분석해서 우선순위 정해줘" | P2→Agent(Feedback Synthesizer) | Product specialist |
| 63 | "스프린트 백로그 우선순위 정해줘" | P2→Agent(Sprint Prioritizer) | Product specialist |
| 64 | "시장 트렌드 리서치해줘" | P2→Agent(Trend Researcher) | Research specialist |
| 65 | "UX 리서치 계획 수립해줘" | P2→Agent(UX Researcher) | Design specialist |
| 66 | "브랜드 아이덴티티 수립해줘" | P2→Agent(Brand Guardian) | Design specialist |
| 67 | "이 코드의 아키텍처 결정 조언해줘" | P2→Agent(oracle) | Strategic advisor, read-only |
| 68 | "요구사항 분석해줘" | P2→Agent(analyst) | Pre-planning analysis |
| 69 | "이 작업 계획 리뷰해줘" | P2→Agent(momus) | Plan review, read-only |
| 70 | "MVP 빠르게 만들어줘" | P2→Agent(Rapid Prototyper) | Specialist domain |

## Category 4: P3a Boss Direct Orchestration (71-85)

| # | Request | Agents Needed | Expected Route | Reasoning |
|---|---------|--------------|---------------|-----------|
| 71 | "리팩토링하고 코드리뷰해줘" | 2 (executor→code-reviewer) | P3a | ≤4, sequential |
| 72 | "버그 고치고 테스트 작성해줘" | 2 (debugger→test-engineer) | P3a | ≤4, sequential |
| 73 | "API 구현하고 보안 체크해줘" | 2 (executor→security-reviewer) | P3a | ≤4, sequential |
| 74 | "DB 스키마 설계하고 마이그레이션 작성해줘" | 2 (Database Optimizer→executor) | P3a | ≤4, sequential |
| 75 | "코드 작성하고 테스트하고 리뷰해줘" | 3 (executor→test-engineer→code-reviewer) | P3a | ≤4, linear chain |
| 76 | "UI 만들고 접근성 검사해줘" | 2 (designer→Accessibility Auditor) | P3a | ≤4, sequential |
| 77 | "문서 작성하고 리뷰해줘" | 2 (writer→critic) | P3a | ≤4, sequential |
| 78 | "성능 벤치마크 돌리고 결과 분석해줘" | 2 (Performance Benchmarker→Test Results Analyzer) | P3a | ≤4, sequential |
| 79 | "프론트엔드 구현하고 테스트해줘" | 2 (Frontend Developer→test-engineer) | P3a | ≤4, sequential |
| 80 | "API 테스트하고 문서화해줘" | 2 (API Tester→Technical Writer) | P3a | ≤4, sequential |
| 81 | "보안 리뷰하고 취약점 고쳐줘" | 2 (security-reviewer→executor) | P3a | ≤4, sequential |
| 82 | "요구사항 분석하고 계획 세워줘" | 2 (analyst→planner) | P3a | ≤4, sequential |
| 83 | "Git 히스토리 정리해줘" | 1 (git-master) | P2→Agent(git-master) | Single agent = P2, not P3a |
| 84 | "디자인하고 구현하고 테스트해줘" | 3 (designer→executor→test-engineer) | P3a | ≤4, linear chain |
| 85 | "PDF 읽고 보안 분석해줘" | 2 steps (Skill(pdf)→Agent(security-reviewer)) | P3a (chained) | Chained routing: Skill reads, Agent analyzes |

## Category 5: P3b Sub-Orchestrator (86-95)

| # | Request | Why P3b | Expected Route |
|---|---------|---------|---------------|
| 86 | "프로젝트 전체 리팩토링해줘" | 5+ modules, complex deps | P3b→sisyphus |
| 87 | "마이크로서비스 아키텍처로 전환해줘" | Planning+multi-agent+verification | P3b→sisyphus |
| 88 | "기존 계획 실행해줘" (plan exists) | Existing plan execution | P3b→atlas |
| 89 | "전체 테스트 커버리지 80%까지 올려줘" | Multiple test types across modules | P3b→sisyphus |
| 90 | "이 프로젝트 처음부터 끝까지 완성해줘" | Full greenfield, autonomous | P3b→hephaestus |
| 91 | "모든 API 엔드포인트 보안 강화+테스트+문서화" | 3 concerns × N endpoints | P3b→sisyphus |
| 92 | "레거시 코드 전체 현대화해줘" | Multiple phases, complex deps | P3b→sisyphus |
| 93 | "CI/CD + 모니터링 + 로깅 전체 인프라 구축" | Multiple systems | P3b→sisyphus |
| 94 | "디자인 시스템 전체 구축해줘" | Components+tokens+docs+tests | P3b→sisyphus |
| 95 | "기능 A,B,C,D,E 동시에 개발해줘" | 5+ parallel features, needs planning | P3b→sisyphus |

## Category 6: Edge Cases & Ambiguous (96-120)

| # | Request | Expected Route | Reasoning |
|---|---------|---------------|-----------|
| 96 | "도와줘" | ASK | Too vague to classify |
| 97 | "이거 고쳐줘" (no context) | ASK→"어떤 파일/에러?" | No target identified |
| 98 | "코드 좀 봐줘" | ASK→"코드 리뷰? 버그? 리팩토링?" | Ambiguous intent |
| 99 | "빠르게 해줘" | ASK→"어떤 작업?" | No task specified |
| 100 | "security review해줘" (project has both skill+agent) | ASK→"특정 파일? 전체?" | Ambiguous scope |
| 101 | "엑셀 데이터로 대시보드 만들어줘" | P3a chained: Skill(xlsx)→Skill(frontend-design) | Two distinct steps |
| 102 | "잘 모르겠는데 뭔가 이상해" | ASK→"어떤 동작이 예상과 다른가요?" | Too vague per Phase 1 |
| 103 | "한국어로 코드 리뷰해줘" | P2→Agent(code-reviewer), Korean output | Language is modifier, not routing factor |
| 104 | "3개 파일만 리팩토링해줘" | P2→Agent(executor) | ≤4 files = single agent sufficient |
| 105 | "이것도 하고 저것도 하고 그것도 해줘" | ASK→specific tasks | Cannot route without clarity |
| 106 | "production 긴급 장애!" | P2→Agent(Incident Response Commander) | Urgency doesn't change routing |
| 107 | "이 Jupyter 노트북 분석해줘" | P2→Agent(scientist) | Data analysis domain |
| 108 | "이 코드 왜 느린지 알려줘" | P2→Agent(tracer) | Performance investigation = deep tracing |
| 109 | "Next.js 앱 만들어줘" | P2→Agent(Frontend Developer) | Consistent with #113 (Flutter→Mobile App Builder). Build intent clear |
| 110 | "이 PR merge해도 될까?" | P3a: Agent(code-reviewer) ∥ Agent(security-reviewer) | 2 agents parallel, Boss verifies |
| 111 | "테스트 왜 실패하는지 봐줘" | P2→Agent(debugger) | Investigation, no skill match |
| 112 | "이 에러 메시지 뭔 뜻이야?" | P4→Agent(model="haiku") | Trivial lookup |
| 113 | "Flutter 앱 만들어줘" | P2→Agent(Mobile App Builder) | Specialist match |
| 114 | "로고 만들어줘" | P1→Skill(canvas-design) | S4:A0, visual output = skill |
| 115 | "어제 한 작업 이어서 해줘" | ASK→이전 작업 확인 후 해당 task에 맞게 재라우팅 | Resume is mechanism, not routing. Identify previous task first |
| 116 | "이 코드 설명해줘" | P4→Agent(model="haiku") | Quick explanation |
| 117 | "아키텍처 리뷰 좀" | P2→Agent(architect) | Strategic analysis |
| 118 | "Help me debug this flaky test" | P2→Agent(debugger) or Agent(tracer) | Investigation, "flaky" = root cause tracing |
| 119 | "셋업 가이드 작성해줘" | P2→Agent(writer) | Documentation, model=haiku |
| 120 | "Design a REST API for user management" | P2→Agent(Backend Architect) | API design specialist |

## Category 7: Intent Classification Stress (121-140)

| # | Request | Apparent Type | Actual Type | Correct Route |
|---|---------|-------------|-------------|---------------|
| 121 | "이 버튼 색상 바꿔줘" | Trivial | Trivial | P2→Agent(executor, model=haiku) |
| 122 | "전체 디자인 시스템 색상 바꿔줘" | Trivial? | Mid-sized | P3a or P3b by component count |
| 123 | "간단한 거 하나만" + complex requirements | Trivial? | Mid-sized+ | Classify by actual complexity |
| 124 | "큰 작업인데" + actually 1 file fix | Complex? | Trivial | Classify by actual scope |
| 125 | "리팩토링해줘" (1 function) | Refactoring | Trivial | P2→Agent(executor) |
| 126 | "리팩토링해줘" (entire module) | Refactoring | Refactoring | P3a (executor→code-reviewer) |
| 127 | "리팩토링해줘" (entire project) | Refactoring | Complex | P3b→sisyphus |
| 128 | "테스트 추가해줘" (1 function) | Testing | Trivial | P1→Skill(tdd-workflow) |
| 129 | "테스트 추가해줘" (all endpoints) | Testing | Mid-sized | P2→Agent(test-engineer) |
| 130 | "테스트 추가해줘" (80% coverage goal) | Testing | Complex | P3b→sisyphus |
| 131 | "보안 점검" (single endpoint) | Testing | Trivial | P1→Skill(security-review) |
| 132 | "보안 점검" (before release) | Testing | Mid-sized | P2→Agent(security-reviewer) |
| 133 | "보안 점검" (SOC2 compliance audit) | Testing | Complex | P3b→sisyphus |
| 134 | "문서 업데이트해줘" (1 README) | Document | Trivial | P2→Agent(writer, model=haiku) |
| 135 | "문서 업데이트해줘" (all docs) | Document | Mid-sized | P3a (explore→writer) |
| 136 | "Refactor and add tests" | Mid-sized | Mid-sized | P3a (executor→test-engineer) |
| 137 | "Create a beautiful landing page with animations" | Design | Design | P1→Skill(frontend-design) |
| 138 | "Build a complete e-commerce platform" | Build | Complex | P3b→sisyphus |
| 139 | "Deploy to production" | DevOps | DevOps | P2→Agent(DevOps Automator) |
| 140 | "Fix the login bug" | Bug fix | Bug fix | P2→Agent(debugger) |

## Category 8: MCP Tool Routing (141-155) — NEW

| # | Request | Expected Route | MCP Server | Reasoning |
|---|---------|---------------|------------|-----------|
| 141 | "React 최신 문서 찾아줘" | P4→Agent(haiku) using context7 MCP | context7 | Lookup task, agent uses MCP as tool |
| 142 | "Next.js 14 App Router 사용법 알려줘" | P4→Agent(haiku) using context7 MCP | context7 | Lookup task |
| 143 | "이 에러 관련 Stack Overflow 답변 찾아줘" | P4→Agent(haiku) using exa MCP | exa | Web search via agent |
| 144 | "비슷한 오픈소스 프로젝트 있는지 찾아봐" | P2→Agent(librarian) using grep_app MCP | grep_app | Source understanding specialist |
| 145 | "Flutter GetX 패턴 예제 코드 찾아줘" | P2→Agent(librarian) using context7+grep_app MCP | context7+grep_app | Docs + code examples via agent |
| 146 | "최신 보안 취약점 뉴스 검색해줘" | P4→Agent(haiku) using exa MCP | exa | Web search via agent |
| 147 | "Tailwind CSS v4 breaking changes 알려줘" | P4→Agent(haiku) using context7 MCP | context7 | Library docs via agent |
| 148 | "이 라이브러리의 GitHub 이슈 확인해줘" | P4→Agent(haiku) using grep_app MCP | grep_app | GitHub search via agent |
| 149 | "Django REST framework 인증 패턴 찾아줘" | P4→Agent(haiku) using context7 MCP | context7 | Library docs via agent |
| 150 | "PostgreSQL 17 새 기능 알려줘" | P4→Agent(haiku) using context7 or exa MCP | context7/exa | Docs or web search via agent |
| 151 | "React 문서 보고 이 컴포넌트 구현해줘" | MCP(context7)→Agent(executor) | context7+Agent | Research → implement |
| 152 | "경쟁사 기술 스택 분석해줘" | P2→Agent(Trend Researcher) using exa MCP | exa | Research via specialist agent |
| 153 | "이 npm 패키지 대안 찾아줘" | P2→Agent(librarian) using exa+grep_app MCP | exa+grep_app | Multi-source search via agent |
| 154 | "Supabase Edge Functions 문서 확인해줘" | P4→Agent(haiku) using context7 MCP | context7 | Library docs via agent |
| 155 | "이 API의 rate limit 정책 찾아줘" | P4→Agent(haiku) using context7 or exa MCP | context7/exa | External reference via agent |

## Category 9: Model Selection (156-165) — NEW

| # | Request | Agent | Expected Model | Reasoning |
|---|---------|-------|---------------|-----------|
| 156 | "아키텍처 결정 도와줘" | oracle | opus (declared) | Agent has model field |
| 157 | "이 함수 구현해줘" | executor | sonnet (declared) | Agent has model field |
| 158 | "파일 하나 찾아줘" | explore | haiku (declared) | Agent has model field |
| 159 | "README 작성해줘" | writer | haiku (declared) | Agent has model field |
| 160 | "프로젝트 보안 감사" | security-reviewer | opus (declared) | Agent has model field |
| 161 | "브랜드 전략 수립해줘" | Brand Guardian | sonnet (Agency, declared) | Fix 1 added model |
| 162 | "API 부하 테스트해줘" | API Tester | sonnet (Agency, declared) | Fix 1 added model |
| 163 | "Workflow 최적화해줘" | Workflow Optimizer | sonnet (Agency, declared) | Fix 1 added model |
| 164 | "데이터 분석 결과 리포트" | scientist | sonnet (declared) | Agent has model field |
| 165 | "이 계획 검증해줘" | verifier | sonnet (declared) | Agent has model field |

## Category 10: Project vs Global Agent Priority (166-170) — NEW

| # | Scenario | Global Agent | Project Agent | Expected Winner | Reasoning |
|---|---------|-------------|--------------|----------------|-----------|
| 166 | "코드 리뷰해줘" in aircok_backoffice | code-reviewer (opus) | code-reviewer (opus) | Project | Project overrides global (same name) |
| 167 | "아키텍처 조언해줘" in aircok_backoffice | architect (opus) | architect (opus) | Project | Project overrides global |
| 168 | "보안 리뷰해줘" in aircok_backoffice | security-reviewer (opus) | security-reviewer (opus) | Project | Project overrides global |
| 169 | "데이터 파이프라인 만들어줘" in aircok_backoffice | Data Engineer (sonnet) | (none) | Global | No project override exists |
| 170 | "ESP32 코드 작성해줘" in aircok_backoffice | Embedded Firmware Engineer (sonnet) | (none) | Global | No project override exists |

## Category 11: Phase 4 Verification & Retry (171-175) — NEW

| # | Scenario | Expected Behavior | Step |
|---|---------|-------------------|------|
| 171 | Agent returns wrong file edits | Resume same agent with error context | Retry 1 |
| 172 | Resumed agent fails again | Fresh agent with more context | Retry 2 |
| 173 | Fresh agent also fails | Consult oracle/architect for guidance | Retry 3 |
| 174 | After 3 failures | Report to user with diagnosis | Escalation |
| 175 | Agent modified files outside scope | Reject, re-delegate with stricter MUST NOT DO | Side effect detection |

## Category 12: Parallel Execution within P3a (176-180) — NEW

| # | Request | Pattern | Expected Execution | Reasoning |
|---|---------|---------|-------------------|-----------|
| 176 | "코드 리뷰하고 보안 리뷰해줘" | Independent | Parallel (run_in_background=true) | No dependency between reviews |
| 177 | "구현하고 테스트해줘" | Dependent | Sequential (executor→test-engineer) | Tests depend on implementation |
| 178 | "API 3개 동시에 구현해줘" | Independent | 3× parallel Agent(executor) | Independent endpoints |
| 179 | "리팩토링→테스트→코드리뷰" | Linear chain | Sequential (3 steps) | Each depends on previous |
| 180 | "보안+성능+접근성 감사해줘" | Independent | 3× parallel Agents | No dependency between audits |

---

## Validation Summary

| Category | Scenarios | Count |
|----------|----------|-------|
| Pure Skill | 1-20 | 20 |
| Skill vs Agent Conflict | 21-45 | 25 |
| Pure Agent | 46-70 | 25 |
| P3a Direct Orchestration | 71-85 | 15 |
| P3b Sub-Orchestrator | 86-95 | 10 |
| Edge Cases & Ambiguous | 96-120 | 25 |
| Intent Classification Stress | 121-140 | 20 |
| MCP Tool Routing | 141-155 | 15 |
| Model Selection | 156-165 | 10 |
| Project vs Global Priority | 166-170 | 5 |
| Phase 4 Verification & Retry | 171-175 | 5 |
| Parallel Execution in P3a | 176-180 | 5 |
| gstack 3-Phase Sprint | 181-185 | 5 |
| **Total** | | **185** |

## Key Routing Principles Validated

1. **Dynamic skill matching** — Phase 0 registry, no hardcoded keyword table
2. **3D conflict resolution with Depth×2** — Weighted scoring eliminates false Skill routing for deep analysis
3. **Candidate existence check** — No candidate → skip to next Priority, never force-match
4. **File-format override** — Deliverable IS a file format → Skill always wins
5. **Methodology+Implementation** — Skill inside Agent pattern
6. **Chained routing** — Multi-step Skill→Agent or Skill→Skill via P3a
7. **P3a vs P3b threshold** — ≤4 agents vs 5+ agents
8. **Ambiguity handling** — ASK rather than guess
9. **Scope sensitivity** — Same word routes differently by scope (보안 점검 #131-133)
10. **Language neutrality** — Korean/English same routing logic
11. **Urgency independence** — Urgency doesn't change routing
12. **Intent vs framing** — Classify by actual complexity, not user's framing
13. **MCP awareness** — context7/exa/grep_app routed by information need
14. **Model declared by agent** — All 71 agents have model field post-Fix 1
15. **Project overrides global** — Same-name project agent wins
16. **Verification retry escalation** — resume→fresh→consult→report
17. **Parallel vs sequential in P3a** — Independent=parallel, dependent=sequential

---

## Category 13: gstack 3-Phase Sprint Workflow (181-185)

### P0 Priority + 3-Phase Sprint

| # | Input | Expected Route | Verify | Phase |
|---|-------|---------------|--------|-------|
| 181 | "이 기능 만들어줘" (end-to-end feature request) | Boss → 3-Phase Sprint: Phase 1 (/plan-ceo-review → /plan-eng-review) → Phase 2 (ralph with Step 7a gstack /review + Step 7b architect) → Phase 3 (design doc 대조 + AskUserQuestion) | All 3 phases execute in order; Phase transitions are explicit | Phase 1→2→3 |
| 182 | "코드 리뷰해줘" (standalone code review) | Boss → P0 → gstack `/review` directly (NOT 3-Phase Sprint) | Single skill invocation, no Sprint workflow triggered | N/A (direct P0) |
| 183 | gstack not installed + "배포해줘" | Boss → P1-P4 fallback (ralph with architect/critic only, no gstack skills) | ralph Step 7a skipped silently; Step 7b architect runs normally | Fallback |
| 184 | ralph Step 7a: /review returns findings | ralph logs /review findings → proceeds to Step 7b architect verification → both results reported | Both 7a and 7b run; neither blocks the other | Phase 2 |
| 185 | Phase 3: 사용자가 "개선 필요" 선택 | Boss → Phase 2 재진입 (ralph re-executes with updated scope) → Phase 3 재검수 | design doc re-read from disk; AskUserQuestion presented again | Phase 3→2→3 |

### Verification Rules for Category 13

1. **3-Phase trigger** — Only end-to-end requests ("만들어줘", "구현해줘", "배포해줘") trigger the full Sprint. Standalone requests ("리뷰해줘", "QA해줘") go directly to P0.
2. **Phase 1 is always interactive** — AskUserQuestion must be used for design decisions. No silent assumptions.
3. **Phase 2 always uses ralph** — Boss never calls ultrawork directly in Sprint mode. ralph handles internal routing.
4. **Step 7a is non-blocking** — gstack /review failure must not prevent Step 7b from running.
5. **Phase 3 re-reads design doc** — Context recovery from `~/.gstack/projects/` path, not from memory.

---

## Bundled Agent Routing Scenarios

### Scenario: Route to agency engineering agent
**Input**: "Review my Rust code for ownership issues"
**Expected**: Boss routes to `agents/agency/engineering/rust-reviewer.md` or similar Rust specialist
**Verify**: Agent description matches Rust expertise

### Scenario: Route to OMC agent
**Input**: "Trace the root cause of this production error"
**Expected**: Boss routes to `agents/omc/tracer.md`
**Verify**: Agent description mentions causal tracing

### Scenario: Name collision resolution
**Input**: "Do a code review"
**Expected**: Boss selects based on description specificity, not filename
**Verify**: Both `agents/omc/code-reviewer.md` and `agents/agency/engineering/code-reviewer.md` are candidates; Boss picks the most relevant one

### Scenario: Plugin-scoped agent discovery
**Input**: "Show me all available agents"
**Expected**: Boss reports 185 agents (52 core + 133 packs) from the plugin bundle
**Verify**: Count includes all three subdirectories
