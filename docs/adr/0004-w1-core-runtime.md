# ADR-0004: W1 코어 런타임 — 오토로드·세이브 형식·입력 맵

- 상태: 승인 (개발자 위임, 2026-11-26)
- 날짜: 2026-11-26
- 제안: WP-07, WP-08, WP-09

## 결정

1. **오토로드 3개**, 이 순서로 등록한다: `EchoBus`(시그널 허브) → `GameState`(진행 상태) → `SaveService`(세이브·공유 기록). 오토로드 스크립트에는 `class_name`을 붙이지 않는다(싱글톤 이름과 충돌).
2. **GameState는 직접 대입을 막는다.** `protect`, `heal`, `bond`와 계산값들은 setter에서 오류를 낸다. 대사 규약 §5의 API만 상태를 바꾼다.
3. **세이브 형식 변경(아직 G1 전이므로 schema_version 1 유지):** `state.vars.families_reunited`(정수)를 없애고 `state.reunited_families`(가족 id 목록)를 추가했다. `reunite_family(id)`를 두 번 불러도 한 번만 세려면 id 목록이 필요하다. 개수는 목록 길이로 계산한다(ADR-0003의 "계산값은 저장하지 않는다" 원칙).
4. **세이브는 임시 파일에 쓴 뒤 교체한다.** 더 새로운 schema_version의 세이브는 읽지 않는다(`ERR_FILE_UNRECOGNIZED`).
5. **엔딩 규칙은 두 곳에 있다**: `game/systems/core/ending_rules.gd`(게임)와 `tools/branch_sim.py`(검증). `branch_sim.py --write-fixture`가 만든 `tests/fixtures/ending_cases.json`(1008건)으로 둘이 같은지 gdUnit4가 검사하고, CI는 픽스처가 최신인지 검사한다.
6. **입력 맵은 project.godot에 둔다**(물리 키코드, 모든 장치). 액션 이름 상수는 `InputActions`. 기본값: 이동 WASD/방향키/왼쪽 스틱/D패드, 상호작용 E·Z/A, 잔향 감지 Space·X/X(누르고 있기), 태그 전환 Tab·C/Y, 일시정지 Esc/Start.
7. **번역**: `game/i18n/ui.csv` → 임포트가 만드는 `.translation`을 project.godot에 등록, 대체 언어 `ko`. `.translation`은 생성물이라 커밋하지 않는다.
8. **게임이 만든 세이브도 스키마로 검사한다.** gdUnit4 테스트가 `tests/out/`에 세이브·persist 파일을 남기고 `validate_data.py --generated tests/out`이 JSON Schema로 검사한다(로컬 ci_local 6단계, GitHub CI test 잡).

## 영향

- `docs/schemas/save.schema.json`, `docs/schemas/examples/save.example.json`, `game/data/flags.json`(families_reunited → derived) 변경.
- `tests/check_scripts.gd`는 첫 프레임 뒤에 검사한다(-s 모드에서 `_init` 시점에는 오토로드 이름이 아직 없음).
