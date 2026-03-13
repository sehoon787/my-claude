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

| 기능 | 설명 |
|------|------|
| 9개 전문 에이전트 | 오케스트레이터, 딥 워커, 분석가, 자문가 등 역할별 특화 에이전트 |
| 3개 행동 교정 훅 | PreToolUse, SubagentStop, Stop — 런타임 행동을 구조적으로 제어 |
| 3개 MCP 서버 | Context7, Exa, grep.app — 실시간 문서 검색 및 코드 탐색 |
| Sisyphus 오케스트레이션 | 요청 의도 자동 분류 후 최적 에이전트에 위임 |
| 모델 최적화 라우팅 | 작업 복잡도에 따라 Opus / Sonnet 자동 선택 |
| 백그라운드 병렬 실행 | 독립적인 서브태스크를 병렬 처리하여 응답 속도 향상 |

---

## 에이전트 카탈로그

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
