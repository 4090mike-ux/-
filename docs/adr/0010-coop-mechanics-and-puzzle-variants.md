# ADR-0010: 동시 조작 퍼즐 확장(기억의 다리·엇갈린 시선)과 퍼즐 변형(CM-B 잔상·CM-C 2인)

- 상태: 승인 (개발자 위임, 2026-11-26)
- 날짜: 2026-11-26
- 제안: WP-25b (챕터 2~4 동시 퍼즐 준비), sibling.md §4, echo.md §3-2

## 결정

1. **기억의 다리** `bridge` (bond ≥ 2): A가 공명대(`at`)에서 `interact` → 감지 고정(반경 40 px 고리 표시) → 회색 공백(`gates[].style = "void"`)이 판자 다리가 된다 → `tag_switch` → B가 건너 건너편 장치(`lock_at`)에서 `interact` → 다리가 영구히 굳는다. A가 움직이거나 A로 다시 바꾸면 풀린다. GDD의 "`echo_sense` 중 `interact`"는 입력 두 개를 동시에 누르는 부담이 있어 **공명대에서 `interact` 한 번**으로 줄였다(감지 고정은 연출로 보여 준다).
2. **엇갈린 시선** `gaze` (bond ≥ 2): `seer`만 보는 단서 표식(`clues`, 점선 원 + 감정 기호 + 순서 번호)은 seer가 조작 중일 때만 그려진다. 장치(`at`)는 다른 사람만 맞출 수 있고, `SymbolSequencePuzzle`(새 퍼즐 UI — 기호를 순서대로 넣기, 틀리면 처음부터, 힌트 = 다음 기호 자동 입력, 2힌트 뒤 건너뛰기)로 입력한다. seer가 장치를 쓰면 `hint_cues.wrong_person` 대사.
3. **힌트 cue 키 확장**: hold(hold/switch/latch), bridge(anchor/switch/cross), plates(stand/switch), gaze(look/enter/wrong_person).
4. **끼임 방지**: 문·공백이 닫힐 때 그 안에 사람이 있으면 비킬 때까지 닫지 않는다.
5. **CM-B 잔상**: color_match 난이도 3/4/5 → 단서가 4/3/2초 뒤 사라진다. `echo_sense` 짧게 = 1초 다시 보기(쿨다운 2초).
6. **CM-C 2인**: 공명 잔향(`sensed_by both`) + bond ≥ 2 → 칸의 왼쪽 절반(올림)은 하늘, 나머지는 별만 채운다. 퍼즐 안의 `tag_switch` = 쪽 바꾸기(실제 캐릭터는 바꾸지 않음). 이때 건너뛰기는 `tag_switch` **1초 길게**.
7. **수동 힌트**: 자동 힌트를 끈 설정에서는 `echo_sense`를 **3초 길게** 눌러 힌트(echo.md §3-1과 일치). 짧게 누르기는 퍼즐이 쓴다.
8. 스키마: `scene.schema.json`의 `mechanisms[].type`에 bridge·gaze, `seer`·`clues`·`sequence`·`palette`·`caption`·`time_limit_sec`, `gates[].style`. `validate_data.py`가 장치 지점 이름·문 id·clues/sequence 길이를 검사한다.

## 결과

- 테스트: `tests/unit/systems/test_mechanisms.gd`(다리·시선·끼임), `tests/unit/systems/test_puzzles.gd`(잔상·2인).
- 챕터 3 장면 조립(WP-28)에서 `ch3_studio_02`(다리), `ch3_room_02`(시선), `ch3_hill`(발판 + 다리)에 쓴다.
