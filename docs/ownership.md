# 파일 소유권 표 v1

병렬 작업이 서로의 파일을 덮어쓰지 않게 하는 계약이다. 에이전트는 **자기 트랙에 허용된 경로만** 수정한다. 다른 경로를 고쳐야 하면 수정하지 말고 보고서의 "미해결 질문"에 적는다.

## 공유 파일 — 통합 담당 세션만 수정

아래 파일은 여러 트랙이 함께 의존한다. **통합 담당 세션 하나**(사람이 지정한 세션, 기본은 main 브랜치에서 작업하는 개발자 본인 세션)만 수정한다.

| 경로 | 변경 절차 |
|---|---|
| `project.godot` | 오토로드·입력 맵·렌더 설정. 요청은 보고서로 |
| `game/autoload/` | GameState, SaveService, EchoBus. 인터페이스 변경은 ADR |
| `docs/schemas/` | 스키마·대사 규약. **수정 금지, `docs/adr/`에 제안서만** |
| `docs/bible/canon_v1.md`, `docs/bible/forbidden_terms.json` | G0 서명 후에는 ADR + 개발자 승인 |
| `game/data/emotions.json`, `game/data/flags.json`, `game/data/speakers.json` | 계약 데이터. 추가는 PR, 수정·삭제는 ADR |
| `AGENTS.md`, `CLAUDE.md`, `docs/ownership.md` | 개발자만 |
| `addons/` | 직접 수정 금지. `tools/install_addons.py`의 버전만 바꾼다 |

## 트랙별 쓰기 가능 경로

| 트랙 | 쓰기 가능 경로 | 비고 |
|---|---|---|
| T1 기획/내러티브 | `docs/gdd/`, `docs/bible/`(canon 제외), `docs/adr/` | canon 수정은 위 절차 |
| T2 엔진 코어 | `game/autoload/`(통합 세션), `game/systems/core/`, `tests/unit/core/` | |
| T3 게임플레이 시스템 | `game/systems/{echo,garden,sibling}/`, `tests/unit/systems/`, `tests/flow/` | 시스템 간 통신은 `EchoBus` 시그널로만 |
| T3 챕터 통합 | `game/scenes/{prologue,ch1,ch2,ch3,ch4,ch5,endings}/` | 챕터 통합 WP(WP-19, 25, 28, 31, 34)만 |
| T4 아트 | `game/art/{bg,char,ui,props,memory}/`, `tools/pixelart/`, `docs/style/`(가이드 수정은 개발자 승인) | 배경은 코드로 생성(`tools/pixelart/build_all.py`). 챕터 배경 담당: 챕터 2 WP-24, 챕터 3 WP-27, 챕터 4 WP-30, 챕터 5·엔딩 WP-34 (story_bible §10) |
| T5 VFX/셰이더 | `game/shaders/`, `game/art/vfx/`, `game/systems/color/`, `game/scenes/dev/`, `tests/unit/color/` | 감정 대역 수치는 emotions.json(공유) |
| T6 오디오 | `game/audio/{bgm,sfx}/`, `tools/audio/`, `docs/audio/` | 오디오는 코드로 합성(`tools/audio/build_audio.py`) |
| T7 대사·분기 데이터 | `game/dialogue/`, `game/data/echoes/`, `game/i18n/` | 새 화자·플래그는 공유 데이터 PR 먼저 |
| T8 UI/UX | `game/scenes/ui/`, `game/ui/` | 문자열은 전부 `tr()` 키 |
| T9 QA/테스트 | `tests/`, `tools/lint_names.py`, `tools/validate_data.py`, `tools/branch_sim.py` | 다른 트랙 테스트 폴더는 그 트랙과 공동 |
| T10 빌드/배포 | `.github/workflows/`, `tools/ci_local.sh`, `tools/new_worktree.sh`, `tools/install_addons.py`, `export_presets.cfg`(로컬, 커밋 안 함) | |
| T11 마케팅/스토어 | `marketing/` | AI 사용 기록은 `docs/ai_usage.md`에 추가만 |

## 모든 트랙 공통

- `docs/ai_usage.md`: 누구나 **줄 추가만** 가능(수정·삭제 금지).
- `docs/adr/`: 누구나 새 제안서 추가 가능. 기존 ADR 수정은 개발자만.
- 테스트는 자기 코드 옆 트랙 테스트 폴더에 추가한다. W0 테스트는 `tests/unit/`에 있다.
