# 대사 규약 (Dialogue Manager 4) — v1

대사 작성자(사람·Chronicler·Codex)와 UI·게임 상태 구현자 사이의 계약이다. 이 규약을 바꾸려면 `docs/adr/`에 제안서를 쓴다.

- 도구: Dialogue Manager 4.2.0 (`addons/dialogue_manager`). 문법 원문: <https://github.com/nathanhoad/godot_dialogue_manager/tree/main/docs>
- 상태 API: `GameState` 오토로드 (WP-08에서 구현). 아래 §5가 그 계약이다.
- 자동 검사: `python tools/lint_names.py` (R-NAME, 화자 키, 헤더, i18n 키)

## 1. 파일 배치

```
game/dialogue/<구간>/<장면id>.dialogue
  구간  = prologue | ch1 | ch2 | ch3 | ch4 | ch5 | endings
  장면id = <구간>_<장소>[_<번호>]   예: ch1_atelier.dialogue, ch2_cafe_02.dialogue
```

- 파일 하나 = 장면 하나. 대사 40줄을 넘으면 파일을 나눈다.
- 파일 이름·큐 이름은 **영문 snake_case**만 쓴다. Dialogue Manager의 큐 이름 규칙은 한글을 허용하지 않는다.
- 모든 파일에는 `~ start` 큐가 있어야 한다.

## 2. 파일 머리말 (필수)

파일 맨 위에 주석으로 쓴다. Dialogue Manager에서 `#`로 시작하는 줄은 주석이다.

```
# scene: ch4_storm_before
# r-name: pre
# wp: WP-29
```

| 키 | 값 | 규칙 |
|---|---|---|
| `scene` | 장면 id | 파일 이름과 같아야 한다 |
| `r-name` | `pre` 또는 `post` | **ch4는 필수.** prologue~ch3은 자동으로 `pre`, ch5·endings는 자동으로 `post`. 다른 값을 쓰면 린트 오류 |
| `wp` | 작업 패키지 id | 추적용 |

챕터 4는 기억의 폭풍(`ev_ch4_storm`) 전과 후를 **다른 파일**로 나눈다. 한 파일 안에서 pre/post를 섞지 않는다.

## 3. 화자

```
haneul: 이 그림… 누가 그린 거지?
byeol: [#portrait=surprised] 어? 방금 나도 같은 말 하려고 했는데.
| haneul: [#sync] 같은 말!
```

- 화자 자리(`키: `)에는 [game/data/speakers.json](../../game/data/speakers.json)의 **키만** 쓴다. `하늘:`처럼 표시 이름을 쓰지 않는다.
- 표시 이름은 대사 UI가 `GameState.name_display(키)`로 바꿔 보여 준다. 진실 공개 전에는 "하늘", 후에는 "은하늘"이 나온다.
- 화자 없는 줄은 지문(내레이션)이다. 지문 안에 `: `(콜론+공백)이 들어가면 화자로 잘못 인식되므로 `\:`로 쓴다.
- 동시 발화는 `| ` 접두사(concurrent line)를 쓴다.
- 새 NPC는 speakers.json과 `game/i18n/ui.csv`(`name.<키>`)에 먼저 추가한다(통합 담당 승인).

## 4. 태그

태그는 줄 앞쪽에 `[#이름]` 또는 `[#이름=값]`으로 쓴다. 아래 목록에 없는 태그는 린트 경고가 난다. 새 태그는 이 표에 먼저 추가한다.

| 태그 | 값 | 뜻 | 처리 주체 |
|---|---|---|---|
| `[#sync]` | — | 남매가 같은 말을 동시에 함 / 닮은 습관 연출 | 대사 UI |
| `[#portrait=<표정>]` | neutral, smile, sad, surprised, angry, scared, worried, determined, tearful, laugh, thinking, blank | 초상 표정 12종 (WP-10에서 확정) | 대사 UI |
| `[#emotion=<id>]` | longing, warmth, dream, courage, healing | 이 줄에서 감정 색 큐(말풍선 테두리·기호) | 대사 UI / 색 복원 |
| `[#cutin=protect]` | protect | 보호 본능 자동 컷인 | 연출 |
| `[#echo=<잔향id>]` | echo.chN.xxx | 이 줄이 특정 잔향과 연결됨 | 잔향 시스템 |
| `[#choice=<id>]` | `<구간>_<장소>_<2자리>` 예: ch2_cafe_01, ch2_park_03_01 (장소에 밑줄 허용) | **성향 선택지 표시.** 분기 시뮬레이터가 센다 | 분기 시뮬레이터 |
| `[#sfx=<id>]`, `[#bgm=<id>]` | 오디오 id | 효과음·배경음 큐 | 오디오 |

## 5. 상태 읽기·쓰기 (GameState 계약)

대사는 게임 상태를 **GameState API로만** 바꾼다. 변수에 직접 대입(`$> GameState.protect = 3`)하지 않는다. API를 거쳐야 범위 검사·시그널·세이브가 일관되게 동작한다.

| 종류 | API | 설명 |
|---|---|---|
| 읽기 | `GameState.protect`, `heal`, `bond`, `families_reunited` | 정수 |
| 읽기 | `GameState.echo_found`, `hidden_echo_found`, `shared_echo_found` | 계산값 (공명 잔향 수는 bond 4 조건) |
| 읽기 | `GameState.flag("flag.ch1.met_in_square")` | 플래그 값 (없으면 기본값) |
| 읽기 | `GameState.lean()` | `"protect"` / `"heal"` / `"balanced"` (차이 2 이하면 balanced) |
| 읽기 | `GameState.name_display("haneul")` | R-NAME 적용된 표시 이름 |
| 읽기 | `GameState.has_echo("echo.ch1.x")`, `has_reunited("family_x")`, `has_chosen("ch2_cafe_01")` | 수집·재결합·선택 여부 |
| 읽기 | `GameState.can_offer_color()` | 숨은 선택지 "내 색을 바친다" 표시 조건 (canon §10) |
| 쓰기 | `$> GameState.add_protect(1)` / `add_heal(2)` | 성향 +1 또는 +2 (증가만) |
| 쓰기 | `$> GameState.set_flag("flag.ch2.xxx", true)` | flags.json에 등록된 플래그만 |
| 쓰기 | `$> GameState.raise_bond(2)` | 관계 단계를 지정 값까지 올림 (스토리 이벤트 전용) |
| 쓰기 | `$> GameState.reunite_family("family_id")` | 사이드 재결합 완료 |
| 이벤트 | `$> GameState.trigger("ev_ch4_storm")` | 이벤트 시작 (컷신·플래그 처리는 이벤트 쪽 책임) |
| 엔딩 | `$> GameState.reach_ending()` | 챕터 5 최종 대화 끝에서 한 번. 엔딩을 정하고 persist 에 기록 |

`[#choice=id]` 응답을 고르면 대사 UI(WP-21)가 `GameState.record_choice(id)`를 자동으로 부른다. 대사 파일에서 직접 부르지 않는다.
구현: `game/autoload/game_state.gd` (WP-08). 계약 테스트: `tests/unit/core/test_game_state.gd`.

플래그·변수 이름은 [game/data/flags.json](../../game/data/flags.json)에 있는 것만 쓴다. 새 플래그가 필요하면 flags.json에 추가하는 PR을 먼저 올린다.

## 6. 성향 선택지 작성법

분기 시뮬레이터(WP-07)가 대사 파일을 직접 읽어 엔딩 도달 가능성을 검사하므로 형식을 지킨다.

```
~ cafe_choice
jieun: 그 사람, 정말 모르는 사이예요?
- [#choice=ch2_cafe_01] 모르는 사이라도 내버려 둘 수 없어요.
	$> GameState.add_protect(1)
	jieun: …그렇군요.
- [#choice=ch2_cafe_02] 저 사람이 먼저 괜찮아지는 게 중요해요.
	$> GameState.add_heal(1)
	jieun: 다정하네요.
- 잘 모르겠어요.
	jieun: 그럴 수도 있죠.
=> END
```

1. 성향을 바꾸는 응답에는 반드시 `[#choice=<id>]` 태그를 단다. id는 프로젝트 전체에서 유일해야 한다.
2. `add_protect` / `add_heal`은 그 응답 블록의 **첫 줄**에 한 번만 쓴다.
3. 한 응답이 protect와 heal을 동시에 올리지 않는다.
4. 성향과 무관한 응답(위의 세 번째)은 태그를 달지 않는다.

## 7. 문장 규칙

- 말풍선 한 번에 최대 2줄, 한 줄 20자 안팎(480×270, 갈무리 11px 기준 — WP-21에서 실측 후 확정 **TODO-확인**).
- 조건 분기는 `if` / `elif` / `else` 블록, 응답 조건은 `- 응답 [if 조건 /]`.
- 줄 안의 변수 표시는 `{{GameState.name_display("byeol")}}`처럼 쓴다. 진실 공개 전 파일에서는 "하늘", "별"을 직접 써도 된다.
- 번역용 정적 ID(`[ID:...]`)는 로컬라이즈 단계(V)에서 도구로 일괄 생성한다. 그 전에는 손으로 쓰지 않는다.
- R-NAME과 15세 이용가 기준은 [canon_v1.md](../bible/canon_v1.md)를 따른다.

## 8. 기타 저장 데이터

| 파일 | 형식 | 스키마 |
|---|---|---|
| `user://save_{slot}.json` | JSON | [save.schema.json](save.schema.json) |
| `user://persist.json` | JSON | [persist.schema.json](persist.schema.json) |
| `user://settings.cfg` | Godot ConfigFile | 스키마 없음 (글자 속도·크기, 색각 모드, 리듀스 모션, 키 설정) |
| `game/data/emotions.json` | JSON | [emotions.schema.json](emotions.schema.json) |
| `game/data/flags.json` | JSON | [flags.schema.json](flags.schema.json) |
| `game/data/echoes/<구간>.json` | JSON | [echo.schema.json](echo.schema.json) |
