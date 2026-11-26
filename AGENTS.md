# AGENTS.md — 「공허의 화가: 잔향의 색」

모든 AI 에이전트(Claude Code, Codex 등)와 사람이 따르는 작업 규칙의 단일 원천이다. `CLAUDE.md`는 이 파일을 가리키기만 한다.

색을 잃은 세계에서 잔향을 모아 남매의 기억을 되찾는 2D 탐색 어드벤처. Godot 4.7.2 / GDScript / 480×270 픽셀아트 / 1인 개발 + AI 병렬 진행.

## 1. 작업 전에 반드시 읽을 것

| 순서 | 문서 | 내용 |
|---|---|---|
| 1 | 이 파일 | 명령, 금지 사항, 완료 정의 |
| 2 | [docs/bible/canon_v1.md](docs/bible/canon_v1.md) | 설정 확정본, **R-NAME**, 엔딩 조건 |
| 3 | [docs/schemas/](docs/schemas/) | 데이터 스키마, [대사 규약](docs/schemas/dialogue_conventions.md) |
| 4 | [docs/ownership.md](docs/ownership.md) | 트랙별로 고칠 수 있는 경로 |
| 5 | 작업과 관련 있을 때 | [아트 가이드](docs/style/art_style.md), [ADR](docs/adr/), [전체 계획서](docs/plan/dev_plan_v1.md)(WP 카드 ⑥) |

## 2. 명령

Windows에서는 Git Bash로 실행한다. Godot 실행 파일 경로는 `GODOT_BIN` 환경 변수로 지정한다.

```bash
pip install -r tools/requirements.txt            # 처음 한 번 (jsonschema)
python tools/install_addons.py                    # 애드온 재설치가 필요할 때만 (addons/ 는 커밋돼 있음)

tools/ci_local.sh                                 # ★ 완료 전 필수: 린트 + 데이터 검증 + 파싱 검사 + 테스트
python tools/lint_names.py                        # R-NAME·대사 규약·i18n 키
python tools/validate_data.py                     # 스키마·교차 검사·팔레트 규칙
python tools/branch_sim.py                        # 엔딩 분기 보고서 (--check: CI용, --write-fixture: 규칙 변경 후)

"$GODOT_BIN" --headless --path . --import         # 임포트 + 클래스 캐시 (새 워크트리에서 처음 한 번)
"$GODOT_BIN" --headless --path . -s res://tests/check_scripts.gd   # 스크립트 파싱 오류 검사
"$GODOT_BIN" --path . res://game/scenes/dev/color_demo.tscn        # 색 복원 데모 실행
"$GODOT_BIN" --path . res://game/scenes/dev/color_demo.tscn -- --bench   # 셰이더 성능 측정 (60fps 미만이면 종료 코드 1)
"$GODOT_BIN" --path . res://game/scenes/dev/color_demo.tscn -- --shot=user://shot.png   # 스크린샷 저장 후 종료
"$GODOT_BIN" --path . res://game/scenes/dev/sibling_demo.tscn      # 이동·태그 전환 데모
"$GODOT_BIN" --path .                                              # F5 기본: W2 잔향 프로토타입 (감지 → 공명 → 색 복원)

tools/new_worktree.sh WP-12 echo-sense            # WP 작업용 워크트리 + 브랜치 wp/WP-12-echo-sense
```

## 3. 절대 하지 말 것

1. **R-NAME 위반**: 진실 공개(`flag.ch4.truth_revealed`) 전 콘텐츠에 본명(은하늘, 은별)을 쓰지 않는다. 코드·씬·데이터에는 공개 전후 상관없이 이름을 직접 쓰지 않고 i18n 키를 쓴다.
2. **소유권 밖 수정**: [ownership.md](docs/ownership.md)에서 내 트랙에 허용되지 않은 경로를 고치지 않는다. 필요하면 보고서에 적는다.
3. **스키마·계약 직접 수정**: `docs/schemas/`, canon, 공유 데이터(`emotions.json`, `flags.json`, `speakers.json`)를 바꿔야 하면 `docs/adr/`에 제안서만 쓴다.
4. **다른 시스템의 노드 경로 직접 참조**: 시스템 간 통신은 `EchoBus` 시그널로만 한다(WP-09에서 생성).
5. **상태 직접 대입**: 대사·스크립트는 `GameState` API로만 상태를 바꾼다(`$> GameState.protect = 3` 금지).
6. **감정 색 수치 하드코딩**: Hue 대역·색은 `game/data/emotions.json`에서 읽는다(`EmotionBands`).
7. `addons/`, `.godot/` 직접 수정. 바이너리 씬(.scn/.res) 생성. 비밀 정보(.env, butler/steam 키) 커밋.
8. **추측을 사실처럼 쓰기**: 원작에서 확인되지 않은 설정은 `TODO-확인`으로 표시한다.
9. AI가 만든 이미지·음악을 출시 에셋으로 넣으면서 [docs/ai_usage.md](docs/ai_usage.md)에 기록하지 않는 것.

## 4. 코딩 규칙 (요약 — 자세한 내용은 `.claude/skills/godot-conventions/SKILL.md`)

- GDScript 정적 타입. 타입 없는 선언은 오류다(`untyped_declaration = error`). `:=` 추론은 허용.
- 파일 snake_case, 클래스 PascalCase, 시그널은 과거형(`echo_collected`), 플래그는 `flag.<챕터>.<의미>`.
- UI 문자열은 전부 `tr("키")`. 키는 `game/i18n/*.csv`에 먼저 추가한다. 진실 공개 후 전용 문자열 키는 `truth.` 접두사.
- 대사 파일은 [dialogue_conventions.md](docs/schemas/dialogue_conventions.md)를 따른다(머리말, 화자 키, 태그, `[#choice=id]`).
- `.tscn`을 손으로 고칠 때: `ext_resource`/`sub_resource` id와 `load_steps`를 일관되게 유지하고, 고친 뒤 반드시 임포트 + `check_scripts.gd`를 돌린다. 복잡한 씬은 에디터나 Godot MCP로 만든다.
- 테스트: gdUnit4, `tests/` 아래 `test_*.gd`, `extends GdUnitTestSuite`. 렌더링이 필요한 테스트는 `_do_skip := DisplayServer.get_name() == "headless"` 인자를 단다.

## 5. 완료 정의 (Definition of Done)

1. `tools/ci_local.sh`가 통과하고, 그 출력 요약을 보고서에 붙인다. Godot이 없는 환경이면 "3·4단계 미실행"이라고 분명히 적는다.
2. 새 로직에는 테스트가 있다. 콘텐츠 WP는 린터·검증기·(W1부터) 분기 시뮬레이터로 확인한다.
3. 소유권 표를 지켰다.
4. "완료했다"는 말만으로는 병합하지 않는다. 사람이 CI 결과와 실제 플레이를 확인한다.
5. 보고서 형식: **변경 요약 / 실행한 검증과 결과 / 미해결 질문 / 다음 WP 제안**.

## 6. 브랜치·워크트리·병합

- 트렁크 기반: `main` + 짧은 브랜치 `wp/<WP-ID>-<설명>`. 작은 PR, 매일 병합.
- 구현 에이전트는 반드시 워크트리에서 작업한다(`tools/new_worktree.sh`, Claude는 `isolation: worktree`, Codex는 앱 워크트리). 워크트리 변경은 자동 병합되지 않는다 — PR로 사람이 병합한다.
- 공유 파일(ownership.md 상단 표)은 통합 담당 세션 하나만 수정한다.
- 주 1회 '통합의 날': 전체 브랜치 정리 + 처음부터 끝까지 플레이 + 회고.

## 7. 사람만 하는 일 (위임 금지)

G0~G7 게이트 판정 · 설정·엔딩·대사 최종 검수 · 아트 스타일 승인 · 스키마 변경 승인(ADR) · 출시·계약·결제.

## 8. WP 프롬프트 템플릿

```
너는 「공허의 화가: 잔향의 색」(Godot 4.7, GDScript) 프로젝트의 [에이전트 역할]이다.
먼저 AGENTS.md, docs/bible/canon_v1.md, docs/schemas/, docs/ownership.md를 읽어라.
작업: [WP 목표]. 입력: [입력 문서]. 산출물: [경로·형식].
규칙: (1) ownership.md에서 [트랙]에 허용된 경로만 수정 (2) 진실 공개 전 본명 표기 금지(R-NAME)
(3) 스키마를 바꿔야 하면 수정하지 말고 docs/adr/에 제안서만 작성 (4) 완료 전 tools/ci_local.sh 실행 후 결과 첨부
(5) 추측한 사실은 'TODO-확인'으로 표시. 완료 기준: [검증 방법].
끝나면 변경 요약·실행한 검증·미해결 질문·다음 WP 제안을 보고하라.
```

## 9. 현재 상태

- W0(계약)·W1(기반) 완료, W2(프로토타입) 구현 완료 — G2 셀프 플레이·외부 3인 테스트 대기. canon의 [제안] 항목은 개발자 위임(2026-11-26)에 따라 **작업 기본값**으로 쓰되, G0 서명 전이므로 바뀔 수 있다.
- 오토로드: `EchoBus`, `GameState`, `SaveService` (ADR-0004). 입력 액션: `InputActions` 상수 참조.
- 엔딩 규칙: `EndingRules`(GDScript) ↔ `tools/branch_sim.py`(Python), 픽스처로 교차 검증.
- W2 프로토타입: `EchoSensor`/`EchoObject`/`EchoHighlightLayer`(잔향), `ColorRestoreLayer`(색 복원, 씬마다 하나), `ResonancePuzzle` (ADR-0005). G2 판정 대기.
- 에디터 플러그인(gdUnit4, Dialogue Manager)은 설치만 돼 있고 아직 켜지 않았다.
- `project.godot`는 에디터·ProjectSettings.save()가 통째로 다시 쓰므로 주석을 넣지 않는다.
