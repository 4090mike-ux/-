# 조작·접근성

- 상태: **초안 (WP-06).** 키 배치와 수치는 모두 **[제안]**이다.
- 근거: [canon_v1.md](../bible/canon_v1.md) §7(태그 전환 = Tab), §8(색 + 기호 병기) / [art_style.md](../style/art_style.md) §4 / [dialogue_conventions.md](../schemas/dialogue_conventions.md) §8(`user://settings.cfg`) / [계획서](../plan/dev_plan_v1.md) ④ U 단계(접근성)
- 입력 액션 이름은 엔진 팀(WP-09)이 정의 중인 8개를 그대로 쓴다: `move_left`, `move_right`, `move_up`, `move_down`, `interact`, `echo_sense`(홀드), `tag_switch`, `pause`. 메뉴 조작은 Godot 기본 `ui_*` 액션을 쓴다.
- 구현: WP-09(입력 맵), WP-21(대사 UI 옵션), WP-36(접근성)

---

## 1. 기본 배치

키보드는 **두 세트를 동시에** 켜 둔다. WASD로 하는 사람과 방향키로 하는 사람이 겹치지 않는다.

| 액션 | 키보드 (WASD 세트) | 키보드 (방향키 세트) | 게임패드 | Godot 참고 상수 |
|---|---|---|---|---|
| `move_left` | A | ← | 왼쪽 스틱 ←, 방향 패드 ← | `KEY_A`, `KEY_LEFT`, `JOY_AXIS_LEFT_X`(−), `JOY_BUTTON_DPAD_LEFT` |
| `move_right` | D | → | 왼쪽 스틱 →, 방향 패드 → | `KEY_D`, `KEY_RIGHT`, `JOY_AXIS_LEFT_X`(+), `JOY_BUTTON_DPAD_RIGHT` |
| `move_up` | W | ↑ | 왼쪽 스틱 ↑, 방향 패드 ↑ | `KEY_W`, `KEY_UP`, `JOY_AXIS_LEFT_Y`(−), `JOY_BUTTON_DPAD_UP` |
| `move_down` | S | ↓ | 왼쪽 스틱 ↓, 방향 패드 ↓ | `KEY_S`, `KEY_DOWN`, `JOY_AXIS_LEFT_Y`(+), `JOY_BUTTON_DPAD_DOWN` |
| `interact` | E, Space | Z | 아래 버튼 (Xbox A / PS ✕) | `KEY_E`, `KEY_SPACE`, `KEY_Z`, `JOY_BUTTON_A` |
| `echo_sense` (홀드) | Shift | X | 오른쪽 트리거 (RT / R2), 보조: 오른쪽 범퍼 (RB / R1) | `KEY_SHIFT`, `KEY_X`, `JOY_AXIS_TRIGGER_RIGHT`(+), `JOY_BUTTON_RIGHT_SHOULDER` |
| `tag_switch` | Tab | C | 위 버튼 (Xbox Y / PS △) | `KEY_TAB`, `KEY_C`, `JOY_BUTTON_Y` |
| `pause` | Esc | P | Start (Xbox Menu / PS Options) | `KEY_ESCAPE`, `KEY_P`, `JOY_BUTTON_START` |

- 키보드는 **물리 키 위치**(`physical_keycode`)로 등록한다. 다른 자판 배열에서도 같은 자리를 쓴다.
- 트리거 축 데드존 **0.3**, 스틱 데드존 **0.2**.
- 마우스는 메뉴에서만 쓴다(게임 플레이에는 쓰지 않는다).
- 게임패드 아이콘은 연결된 패드 종류(Xbox / PlayStation / 기타)에 맞춰 바꾼다. 모르면 Xbox 표기.

---

## 2. 상황별 동작

| 상황 | `move_*` | `interact` | `echo_sense` | `tag_switch` | `pause` |
|---|---|---|---|---|---|
| 탐색 | 이동 | 조사·대화·잔향 열기 | 감지 | 남매 전환(광장 이후) | 메뉴 |
| 대사 | 선택지 위/아래 | 다음 줄·선택 확정. **0.5초 누르고 있으면 빨리 넘기기** | — | — | 메뉴(대사 기록 포함) |
| 공명 퍼즐 | 커서 | 집기·놓기·확인 | 단서 다시 보기 | 2인 변형에서 쪽 바꾸기 | 퍼즐 중단 |
| 정원 | 이동 | 심기·다시 심기 | — | 남매 전환 | 메뉴 |
| 동시 조작 퍼즐 | 이동 | 붙잡기·놓기·고정 | 감지(기억의 다리 고정용) | 남매 전환 | 메뉴 |
| 컷신·컷인 | — | 건너뛰기(본 적 있는 것만) | — | — | 메뉴 |
| 메뉴 | `ui_up/down/left/right` | `ui_accept` | — | — | 닫기 |

- 대사 빨리 넘기기는 `interact` 길게 누르기로 처리해서 **새 액션을 만들지 않는다.** 2회차 편의 기능이다.
- `pause`는 리맵해도 Esc가 항상 메뉴를 연다(안전장치).

---

## 3. 이동·홀드 수치

| 항목 | 값 |
|---|---|
| 걷기 속도 | **80 px/s**(타일 5칸/초). 달리기 없음 |
| 방향 | 8방향 입력, 대각선은 정규화. 스프라이트는 4방향 |
| 가속 | 0 → 최고 속도 **0.08초** |
| 감지 중 이동 | ×0.6 = 48 px/s ([echo.md](echo.md) §2-1) |
| 상호작용 거리 | 잔향 20 px, NPC 24 px |
| `tag_switch` 쿨다운 | 0.5초 ([sibling.md](sibling.md) §3) |
| 길게 누르기 판정 | 0.5초(`interact` 빨리 넘기기). 접근성 옵션으로 배율 조정 |

---

## 4. 접근성 옵션

저장 위치는 `user://settings.cfg`(Godot ConfigFile). 섹션·키 이름은 제안이다(계약 변경 제안 C1).

| 옵션 | 섹션 / 키 | 값 | 기본값 |
|---|---|---|---|
| 색각 모드 | `accessibility/colorblind_mode` | `off` / `protan`(제1색맹) / `deutan`(제2색맹) / `tritan`(제3색맹) | `off` |
| 기호 표시 | — | **항상 켜짐(끌 수 없음).** canon §8 | — |
| 기호 크기 | `accessibility/symbol_scale` | 1 (7×7) / 2 (14×14) | 1 |
| 기호 대비 강화 | `accessibility/symbol_outline` | 기호에 검은 2px 테두리 | `false` |
| 글자 속도 | `text/speed` | 느림 15 / 보통 30 / 빠름 60 글자/초 / 즉시 | 보통 |
| 글자 크기 | `text/size` | 기본(갈무리 11px) / 크게(갈무리 14px, 말풍선 3줄) | 기본 |
| 대사 자동 넘김 | `text/auto_advance`, `text/auto_delay` | 켜기/끄기, 1.0~3.0초 | 끄기, 1.5초 |
| 리듀스 모션 | `accessibility/reduced_motion` | §6 목록 적용 | `false` |
| 화면 흔들림 | `accessibility/screen_shake` | 0~100% | 100% |
| 감지 방식 | `accessibility/echo_sense_mode` | `hold`(누르고 있기) / `toggle`(한 번 눌러 켜고 한 번 더 눌러 끔) | `hold` |
| 길게 누르기 배율 | `accessibility/hold_scale` | 0.5 / 1.0 / 2.0 | 1.0 |
| 퍼즐 타이머 | `accessibility/puzzle_timer` | `soft`(목표 시간 후 자동 힌트) / `off`(자동 힌트 없음, 수동 힌트) | `soft` |
| 소리 자막 | `accessibility/captions` | 중요한 소리를 글로 표시("[가까이에서 잔향이 울린다]") | `true` |
| 진동 | `accessibility/rumble` | 잔향 발견·보호 컷인 때 패드 진동 | `true` |
| 볼륨 | `audio/master`, `music`, `ambience`, `sfx`, `ui`, `voice` | 0~100% | [audio_direction.md](../audio/audio_direction.md) §8 |
| 모노 오디오 | `audio/mono` | 켜기/끄기 | 끄기 |
| 화면 배율 | `display/scale` | 정수배 2~6, 전체 화면 | 창 3배 |
| 키 설정 | `input/<액션>` | §7 | §1 |

- **토글 감지**: 대사·퍼즐·컷신이 시작되거나 장면이 바뀌면 자동으로 꺼진다. 켜져 있는 동안 화면 왼쪽 아래에 감지 기호 아이콘을 띄운다.
- **퍼즐 건너뛰기**는 옵션이 아니라 퍼즐 규칙이다: 힌트 2번 뒤 고를 수 있고 보상은 같다([echo.md](echo.md) §3-1).
- 소리 자막을 둔 이유: 잔향 감지에는 거리 소리 단서가 있다. 같은 정보를 화면(윤곽·기호)으로도 주지만, 소리만으로 전하는 정보가 하나도 없게 한다.

---

## 5. 색각 이상 대응 요구사항

자르면 안 되는 항목이다(계획서 ⑩).

| # | 요구 | 검사 |
|---|---|---|
| 1 | 감정 색이 나오는 모든 곳(잔향 윤곽, 정원 꽃, 마음 화단, UI 아이콘, 퍼즐 조각, 대사 감정 큐)에 **기호를 함께** 그린다 | 아트 리뷰 |
| 2 | 기호 최소 7×7 px, 퍼즐 안 9×9 px. 흑백에서 다섯 모양이 구분된다 | 흑백 캡처 |
| 3 | 퍼즐은 기호만으로 풀린다 | [echo.md](echo.md) §3-5 체크리스트 |
| 4 | 안내 문구에 색 이름만 쓰지 않는다("물결 칸", "해 꽃") | 문구 리뷰 |
| 5 | 색각 모드 3종: 감정 표시 색(윤곽·UI·꽃)의 Hue를 그 색각 유형에서 서로 구분되는 값으로 다시 매핑한다. 다섯 색이 시뮬레이션에서 서로 구분돼야 한다 | 색각 시뮬레이터 |
| 6 | 색각 모드는 아트를 새로 만들지 않고 Hue 대역 재매핑으로 처리한다(art_style §4). 재매핑 표의 원천은 `emotions.json`과 같은 계약 안에 둔다 | WP-36 |
| 7 | 빨강(무지개 꽃)도 기호를 가진다(무지개 기호는 WP-10에서 정함) | 아트 리뷰 |

---

## 6. 리듀스 모션 적용 목록

| 대상 | 기본 | 리듀스 모션 |
|---|---|---|
| 잔향 윤곽 맥동 | 1.2 Hz 깜박임 | 고정 2px 윤곽 |
| 감지 파문 | 원형 색 번짐 | 없음 |
| 교대 파트 전환 | 기호 닦아내기 1.0초 | 페이드 0.5초 |
| 태그 전환 카메라 | 0.3초 이동 | 즉시 컷 |
| 보호 컷인 | 줌·흔들림 | 정지 그림 페이드 |
| 기억 공유 분할 화면 | 닦아내기 | 교차 페이드 |
| 기억의 폭풍 | 흔들림·빠른 색 깜박임 | 흔들림 없음, 색 변화는 2초 이상에 걸쳐 천천히 |
| 정원 개화·조합 | 꽃잎 입자 | 입자 없이 그림 교체 |
| 화면 흔들림 | 이벤트별 | 0% |

**깜박임 규칙(옵션과 상관없이 항상)**: 화면 밝기가 크게 바뀌는 깜박임은 1초에 3번을 넘지 않는다. 폭풍 연출도 이 규칙을 지킨다.

---

## 7. 키 리맵

| 규칙 | 내용 |
|---|---|
| 대상 | 8개 액션 전부. 키보드·게임패드 따로 |
| 칸 | 액션마다 키보드 2칸, 게임패드 2칸 |
| 충돌 | 이미 쓰는 키를 고르면 경고하고 **서로 맞바꿀지** 묻는다 |
| 초기화 | 장치별 "기본값으로" 버튼 |
| 안전장치 | Esc는 항상 메뉴를 연다. `pause`를 다른 키로 옮겨도 Esc는 남는다 |
| 저장 | `user://settings.cfg`의 `input` 섹션 |
| 표시 | 화면 안내(예: "Shift 누르고 있기: 감지")는 지금 설정된 키를 보여 준다 |

---

## 계약 변경 제안

| # | 대상 | 제안 | 종류 |
|---|---|---|---|
| C1 | `dialogue_conventions.md` §8 (`user://settings.cfg`) | 지금은 "스키마 없음"이다. §4의 섹션·키 표를 계약으로 정해 WP-21(대사 UI), WP-36(접근성), T8(UI)이 같은 이름을 쓰게 한다 | 규약 추가 |
| C2 | WP-09 입력 맵 구현 메모 | ① Tab은 Godot GUI의 `ui_focus_next`와 겹친다 → 게임 플레이 중에는 GUI 포커스 이동을 막고, 메뉴에서는 `tag_switch`를 처리하지 않는다. ② 키보드는 `physical_keycode`로 등록한다. ③ 웹 빌드에서 Tab이 브라우저 포커스를 빼앗는지 확인 **TODO-확인** | 구현 메모 (WP-09) |
| C3 | 색각 재매핑 표의 위치 | §5-6: 색각 모드별 재매핑 값이 어디에 있어야 하는지 정해야 한다. 제안: `emotions.json`에 선택 필드 `cvd_remap`(모드별 표시 Hue)을 추가하거나 별도 파일. 감정 색 계약이라 ADR | 스키마 추가 (ADR) |
