# 엔딩·분기 — 평가 순서 · 선택지 예산 · bond · 사이드 가족 · 예시 경로

- 상태: **초안 (WP-06).** §1은 canon을 옮긴 것이다. §2 이후의 수치는 모두 **[제안]**이다.
- 근거: [canon_v1.md](../bible/canon_v1.md) §9·§10 / [계획서](../plan/dev_plan_v1.md) ②-2 / [dialogue_conventions.md](../schemas/dialogue_conventions.md) §5·§6 / [flags.json](../../game/data/flags.json)
- 검증: WP-07 분기 시뮬레이터(`tools/branch_sim.py`)가 §1 표와 §3 선택지 목록을 입력으로 쓴다.
- 표기: 진실 공개 전 콘텐츠에는 **하늘 / 별**만 쓴다(R-NAME). 이 문서도 본명을 쓰지 않는다.

---

## 1. 평가 순서 (canon §10-1 그대로)

챕터 5 최종 대화가 끝나면 위에서부터 차례로 검사해 **처음 맞는 엔딩**으로 간다.

| 순서 | 엔딩 id | 이름 | 조건 | 상태 |
|---|---|---|---|---|
| 1 | `sacrifice` | 💔 희생(트루) | `persist.seen_endings`에 `family` 또는 `miracle` 있음 + `echo_found == 30` + 최종 선택에서 숨은 선택지 "내 색을 바친다" 선택 | [확정] |
| 2 | `miracle` | 🌈 기적(히든) | 가족 조건 충족 + `hidden_echo_found == 12` + `flag.ch5.rainbow_flower_bloomed` | [확정] |
| 3 | `family` | 💜 가족(균형) | `abs(protect - heal) <= 2` 그리고 `bond == 4` 그리고 `families_reunited >= 3` | [확정] |
| 4 | `heal` | 💚 치유 | `heal - protect >= 3` 그리고 `families_reunited >= 1` | [확정] |
| 5 | `protect` | 💙 보호 | `protect - heal >= 3` | [확정] |
| 6 | `protect` | 💙 보호 (폴백) | 위 어느 것에도 해당하지 않을 때 | **[제안] 서명 필요** |

- 희생 엔딩에서 누가 색을 바칠지는 `protect`/`heal` 중 큰 쪽으로 정한다(대사 변형 2개). 같으면 **[제안]** 하늘이 바친다. **TODO-확인**
- 희생은 클리어 후 해금되는 **트루 엔딩**, 기적은 1회차에서도 가능한 **완벽 수집 히든 엔딩**으로 계층을 나눈다.
- "치유 vs 보호 vs 함께"는 챕터 5의 선택 한 번이 아니라 챕터 2~5에 흩어진 작은 선택의 누적으로 정해진다. 챕터 5 최종 대화는 결과를 확인하는 장치다.
- 폴백이 필요한 이유(canon §10-2 요약): ① 균형인데 `bond < 4` 또는 `families_reunited < 3`인 경우, ② `heal - protect >= 3`인데 `families_reunited < 2`인 경우, 위 표 1~5 어디에도 해당하지 않는다. 두 경우 모두 보호 엔딩으로 보낸다(canon D7, G0 서명 대상).

### 1-1. 평가 의사 코드

```gdscript
# GameState.resolve_ending() 후보 (계약 변경 제안 N3). 실제 구현은 WP-08.
func resolve_ending() -> String:
	var diff := protect - heal
	var family_ok := absi(diff) <= 2 and bond == 4 and families_reunited >= 3
	if (seen_ending("family") or seen_ending("miracle")) and echo_found == 30 \
			and flag("flag.ch5.offered_color"):
		return "sacrifice"
	if family_ok and hidden_echo_found == 12 and flag("flag.ch5.rainbow_flower_bloomed"):
		return "miracle"
	if family_ok:
		return "family"
	if -diff >= 3 and families_reunited >= 1:
		return "heal"
	if diff >= 3:
		return "protect"
	return "protect"  # 폴백 (canon D7)
```

- 숨은 선택지 "내 색을 바친다"는 희생 조건 앞 두 개(`seen_endings`, `echo_found == 30`)를 만족할 때만 `ch5_final`에 나온다. 고르면 `flag.ch5.offered_color = true`.
- 엔딩이 정해지면 `flag.endings.reached = <id>`, `persist.seen_endings`에 추가, `clear_count + 1`.

---

## 2. 결과를 납득시키는 장치

| 장치 | 위치 | 하는 일 |
|---|---|---|
| 마음 화단 | 정원 방문마다 | 파랑:초록 봉오리 비율로 `protect`:`heal`을 보여 준다([garden.md](garden.md) §8) |
| 성향 확인 대화 | `ch5_talk` | `GameState.lean()`(`protect` / `heal` / `balanced`)으로 3분기. 최종 선택 전에 지금 어디로 가는지 알려 준다 |
| 가족 조건 힌트 | `ch5_talk`의 `balanced` 분기 | `bond < 4`이면 "아직 다 함께라고 말하기 어렵다"는 뉘앙스의 대사 1줄, `families_reunited < 3`이면 재결합 가족을 떠올리는 대사 1줄 **[제안]** |

---

## 3. 성향 선택지 예산

### 3-1. 규칙

| 규칙 | 내용 |
|---|---|
| 선택 지점 | **24개**(챕터 2~5). canon "약 24개" |
| 값 | 응답 하나는 `protect` **또는** `heal` 한쪽에만 +1 또는 +2(canon D9, 증가만) |
| 일반 지점 | **18개.** 보호 응답 +1 / 치유 응답 +1. 그중 **10개**에는 중립 응답(0, 태그 없음)이 있다 |
| 핵심 지점 | **6개.** 보호 응답 +2 / 치유 응답 +2. **중립 응답 없음**(결정적 순간) |
| 대칭 | 모든 지점은 보호·치유 응답의 값이 같다. 한쪽으로 몰아도 축별 최대치는 **30**으로 같다 |
| 응답 id | `[#choice=<구간>_<장소토큰>_<NN>]`. **응답마다** id를 단다(dialogue_conventions §6 예시와 같은 방식). 24지점 × 2 = **48개** |
| 번호 | 장소 토큰 안에서 01부터 이어서 매긴다. 장면 번호와는 상관없다(예: 장면 `ch2_cafe_02`의 응답은 `ch2_cafe_03`, `ch2_cafe_04`) |
| 위치 | 모든 선택 지점은 **메인 동선**에 둔다. 사이드 퀘스트 안에 두지 않는다 → 모든 플레이어가 24개를 다 만난다 |
| 표시 | 화면에 점수·화살표를 보이지 않는다 |

### 3-2. 챕터별 배분

| 챕터 | 지점 | 일반(+1) | 핵심(+2) | 중립 있는 지점 | 챕터 최대(한 축) | 누적 최대 |
|---|---|---|---|---|---|---|
| ch2 | 7 | 6 | 1 | 3 | 8 | 8 |
| ch3 | 7 | 5 | 2 | 3 | 9 | 17 |
| ch4 | 6 | 4 | 2 | 2 | 8 | 25 |
| ch5 | 4 | 3 | 1 | 2 | 5 | 30 |
| **계** | **24** | **18** | **6** | **10** | — | **30** |

### 3-3. 전체 목록

| 지점 | 장면 | 보호 응답 (값) | 치유 응답 (값) | 중립 | 핵심 | 보호 컷인 |
|---|---|---|---|---|---|---|
| C2-1 | `ch2_street` | `ch2_street_01` (+1) | `ch2_street_02` (+1) | ○ | | |
| C2-2 | `ch2_cafe` | `ch2_cafe_01` (+1) | `ch2_cafe_02` (+1) | ○ | | |
| C2-3 | `ch2_cafe_02` | `ch2_cafe_03` (+1) | `ch2_cafe_04` (+1) | | | |
| C2-4 | `ch2_park` | `ch2_park_01` (+1) | `ch2_park_02` (+1) | ○ | | |
| C2-5 | `ch2_park_03` | `ch2_park_03` (+1) | `ch2_park_04` (+1) | | | |
| C2-6 | `ch2_alley` | `ch2_alley_01` (+1) | `ch2_alley_02` (+1) | | | #1 |
| C2-7 | `ch2_attic` | `ch2_attic_01` (+2) | `ch2_attic_02` (+2) | | ★ | |
| C3-1 | `ch3_road` | `ch3_road_01` (+1) | `ch3_road_02` (+1) | ○ | | |
| C3-2 | `ch3_studio` | `ch3_studio_01` (+1) | `ch3_studio_02` (+1) | ○ | | |
| C3-3 | `ch3_studio_02` | `ch3_studio_03` (+2) | `ch3_studio_04` (+2) | | ★ | #2 |
| C3-4 | `ch3_room` | `ch3_room_01` (+1) | `ch3_room_02` (+1) | ○ | | |
| C3-5 | `ch3_bridge` | `ch3_bridge_01` (+1) | `ch3_bridge_02` (+1) | | | |
| C3-6 | `ch3_hill` | `ch3_hill_01` (+1) | `ch3_hill_02` (+1) | | | #3 |
| C3-7 | `ch3_artwork` | `ch3_artwork_01` (+2) | `ch3_artwork_02` (+2) | | ★ | |
| C4-1 | `ch4_conflict_01` | `ch4_conflict_01` (+1) | `ch4_conflict_02` (+1) | ○ | | |
| C4-2 | `ch4_conflict_02` | `ch4_conflict_03` (+1) | `ch4_conflict_04` (+1) | | | #4 |
| C4-3 | `ch4_conflict_03` | `ch4_conflict_05` (+1) | `ch4_conflict_06` (+1) | ○ | | |
| C4-4 | `ch4_conflict_04` | `ch4_conflict_07` (+2) | `ch4_conflict_08` (+2) | | ★ | |
| C4-5 | `ch4_storm_before` | `ch4_storm_01` (+2) | `ch4_storm_02` (+2) | | ★ | #5 |
| C4-6 | `ch4_town` | `ch4_town_01` (+1) | `ch4_town_02` (+1) | | | |
| C5-1 | `ch5_morning` | `ch5_morning_01` (+1) | `ch5_morning_02` (+1) | ○ | | |
| C5-2 | `ch5_atelier` | `ch5_atelier_01` (+1) | `ch5_atelier_02` (+1) | ○ | | |
| C5-3 | `ch5_street` | `ch5_street_01` (+1) | `ch5_street_02` (+1) | | | |
| C5-4 | `ch5_square` | `ch5_square_01` (+2) | `ch5_square_02` (+2) | | ★ | #6 |

- 모든 id는 린터 정규식 `^(prologue|ch[1-5]|endings)_[a-z0-9]+_[0-9]{2}$`에 맞는다. 그래서 선택지가 있는 장면의 장소 이름은 **한 단어**(`[a-z0-9]+`)로 지었다([progression.md](progression.md) 계약 변경 제안 P3).
- C2-2의 id는 dialogue_conventions §6 예시와 같다.
- 선택지의 실제 문장·상황은 대사 WP(WP-23 이후)가 쓴다. 보호 응답 = "지킨다·막아선다·먼저 나선다" 쪽, 치유 응답 = "다독인다·기다린다·상대가 괜찮아지는 것을 먼저 본다" 쪽 **[제안]**.
- `ch4_storm_before`는 진실 공개 전(`r-name: pre`), `ch4_town`은 공개 후(`post`) 파일이다.

---

## 4. bond 상승 이벤트

bond는 **스토리 이벤트로만** 오른다(canon §9). 1~3단계는 필수 이벤트에서 자동, 4단계는 조건부다. 그래야 `bond == 4`가 가족 조건으로서 의미가 있다.

| bond | 챕터 | 장면 · 이벤트 | 필수 | 조건 | 대사 |
|---|---|---|---|---|---|
| 1 | ch1 | `ch1_square` · `ev_ch1_square_meeting` | ✓ | 없음 | `$> GameState.raise_bond(1)` |
| 2 | ch2 | `ch2_attic` · `ev_ch2_attic_memory` (신규 이벤트 id) | ✓ | 없음 | `$> GameState.raise_bond(2)` |
| 3 | ch3 | `ch3_artwork` · `ev_ch3_joint_artwork` | ✓ | 없음 | `$> GameState.raise_bond(3)` |
| 4 | ch4 | `ch4_storm_after` · `ev_ch4_storm` 종료 직후 | 조건부 | `shared_echo_found >= 7` | `if` 블록 안에서 `raise_bond(4)` |
| 4 (만회) | ch5 | `ch5_echo` · 마지막 잔향 수집 직후 | 조건부 | `bond == 3` 그리고 `shared_echo_found >= 7` | 같음 |

- `shared_echo_found` = 수집한 공명 잔향(`sensed_by == both`) 수. **신규 파생 변수 제안**(계약 변경 제안 N1).
- 공명 잔향은 9개: 필수 5(ch1·ch2·ch3·ch4·ch5에 하나씩) + 숨김 4(표시형, 반짝임 힌트).
- `ch4_storm_after` 시점까지 모을 수 있는 공명 잔향은 8개(필수 4 + 숨김 4) → 7개가 되려면 **숨김 공명 잔향 4개 중 3개**가 필요하다.
- `ch5_echo`에서 마지막 필수 공명 잔향이 더해지므로 만회 판정에서는 **숨김 공명 잔향 2개**면 된다.
- 결과: 기억 공유 지점(표시형 숨김 잔향)을 2개 이상 찾은 플레이어는 bond 4에 닿는다. 하나도 안 찾으면 bond 3으로 끝난다(가족·기적 불가 → 균형이면 보호 폴백).

---

## 5. 사이드 가족 재결합 (`families_reunited` 0~6)

| id | 챕터 | 장면 | 진입 | 단계 | 예상 시간 | 6 → 3 컷 시 |
|---|---|---|---|---|---|---|
| `family_cafe` | ch2 | `ch2_cafe_02` | 메인 동선에서 바로 보임(길목형) | 3 | 6~8분 | 유지 |
| `family_park` | ch2 | `ch2_park_03` | 길목형 | 3 | 6~8분 | 자름 |
| `family_bridge` | ch3 | `ch3_bridge` | 곁길 | 3 | 8~10분 | 유지 |
| `family_hill` | ch3 | `ch3_hill` | 곁길, bond ≥ 2 | 3 | 8~10분 | 자름 |
| `family_town` | ch4 | `ch4_town` | 진실 공개 후 | 2 | 6~8분 | 유지 |
| `family_street` | ch5 | `ch5_street` | 곁길 | 2 | 6~8분 | 자름 |

- slug는 **자리표시**다. 가족들의 이야기, 지은·놀이공원 직원과의 관계는 **TODO-확인**(canon §3).
- 퀘스트 틀: ① 발견 — 스케치 얼굴(W-FACE 0단계) 인물이 누군가를 찾는다 → ② 단서 — 관련 장소 2곳 조사(잔향 아님, 색 조각 없음) → ③ 재회 — 두 사람을 만나게 함 → 두 사람 얼굴 2단계 + `$> GameState.reunite_family("family_cafe")`. 2단계 퀘스트는 ②가 1곳.
- 챕터 2의 두 가족을 **길목형**(메인 동선에서 바로 보이고 짧음)으로 둔 이유: 치유 성향 플레이어가 `families_reunited < 2` 때문에 보호 폴백으로 떨어지는 일을 줄이려는 것이다.
- NPC 범위: 6가족 × 2명 = 12명은 canon의 NPC 10~12명 한도를 넘는다. 재결합 가족은 **초상화 없이 스케치 얼굴 공용 몸체 4종 + 팔레트 변형**으로 만든다(계획서 ⑩ 스코프 컷 5순위와 같은 방향). **[제안]**
- 스코프 컷(계획서 ⑩ 2순위, 6 → 3)을 하면 가족 엔딩(`>= 3`)에 남은 3가족이 **모두** 필요해진다. 계약 변경 제안 N4 참고.

---

## 6. 엔딩별 예시 경로

선택 집계는 "핵심 지점(보호/치유) + 일반 지점(보호/치유/중립)"이다. 핵심 지점에는 중립이 없으므로 핵심 보호 + 핵심 치유 = 6, 일반 보호 + 일반 치유 + 중립 = 18이다.

| # | 결과 | 핵심 보/치 | 일반 보/치/중 | protect | heal | 차이 | bond | 가족 | 잔향 (전체 / 숨김 / 공명) | 무지개 | seen_endings | 평가 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | **보호** | 4 / 2 | 13 / 3 / 2 | 21 | 7 | +14 | 3 | 1 | 20 / 2 / 5 | ✗ | [] | 5번 `protect - heal >= 3` |
| 2 | **치유** | 2 / 4 | 4 / 12 / 2 | 8 | 20 | −12 | 4 | 3 | 24 / 6 / 7 | ✗ | [] | 4번 `heal - protect >= 3`, 가족 3 ≥ 2 |
| 3 | **가족** | 3 / 3 | 6 / 6 / 6 | 12 | 12 | 0 | 4 | 4 | 25 / 7 / 8 | ✗ | [] | 3번 (기적은 숨김 7 ≠ 12라서 통과 못 함) |
| 4 | **기적** | 3 / 3 | 5 / 7 / 6 | 11 | 13 | −2 | 4 | 3 | 30 / 12 / 9 | ✓ | [] | 2번 (희생은 seen_endings가 비어서 통과 못 함) |
| 5 | **희생** (2회차) | 4 / 2 | 8 / 6 / 4 | 16 | 10 | +6 | 4 | 5 | 30 / 12 / 9 | ✓ | [family] | 1번. 숨은 선택지 선택. protect가 커서 **하늘**이 바친다 |
| 6 | 보호 (폴백 ①) | 3 / 3 | 5 / 5 / 8 | 11 | 11 | 0 | 3 | 2 | 22 / 4 / 6 | ✗ | [] | 3번 bond 3 ✗ → 4·5번 차이 0 ✗ → 6번 |
| 7 | 보호 (폴백 ②) | 2 / 4 | 5 / 10 / 3 | 9 | 18 | −9 | 4 | 1 | 23 / 5 / 7 | ✗ | [] | 4번 가족 1 < 2 ✗ → 5번 ✗ → 6번 |

- 계산 확인(경로 1): 보호 = 핵심 4×2 + 일반 13×1 = 21, 치유 = 2×2 + 3×1 = 7.
- 경로 4·5의 공명 잔향 9 = 필수 5 + 숨김 4. 숨김 12에 숨김 공명 잔향 4개가 포함된다.
- 경로 5에서 희생 대신 숨은 선택지를 고르지 않으면, 같은 상태에서 차이가 +6이라 보호 엔딩으로 간다. 2회차에 희생을 노리는 플레이어는 성향과 상관없이 숨은 선택지만 고르면 된다.

---

## 7. 분기 시뮬레이터(WP-07) 검사 항목

| # | 검사 | 기대 |
|---|---|---|
| 1 | 모든 입력 조합(성향 0~30 × 0~30, bond 0~4, 가족 0~6, 잔향 수, 플래그, seen_endings)이 **정확히 하나**의 엔딩에 도달 | 통과 |
| 2 | 5엔딩 모두 대표 경로(§6 1~5)로 도달 | 통과 |
| 3 | 대사 파일의 `[#choice]` 응답 id가 §3-3의 48개와 일치, 중복 없음 | 통과 |
| 4 | 한 응답 블록에 `add_protect`·`add_heal`이 동시에 없음, 값은 1 또는 2 | 통과 |
| 5 | 축별 최대치가 30, 핵심 지점에 중립 응답 없음 | 통과 |
| 6 | 무작위 선택(중립 포함 균등) 1만 회: 엔딩 분포 기록. 가족 조건(차이 ≤ 2)에 드는 비율이 15~35%면 적정, 벗어나면 핵심 지점 수를 조정 | 기록·검토 |
| 7 | 폴백 도달 비율 기록. 무작위 기준 20%를 넘으면 ch5 성향 확인 대화의 힌트를 강화 | 기록·검토 |

---

## 계약 변경 제안

| # | 대상 | 제안 | 종류 |
|---|---|---|---|
| N1 | `flags.json` variables + `dialogue_conventions.md` §5 | 파생 변수 `shared_echo_found` 추가: `type: int`, `scope: derived`, `min 0`, `max 9`, `derived_from: "state.echoes_collected 중 sensed_by == both 인 개수"`. 읽기 API `GameState.shared_echo_found`. bond 4 판정(§4)에 필요 | 데이터 추가 + API 추가 |
| N2 | `flags.json` flags | 사이드 가족 중복 집계를 막고 어떤 가족을 만났는지 기억하려면 저장 장소가 필요하다(지금은 정수 `families_reunited`만 있다). 제안: bool 플래그 6개 추가 — `flag.ch2.family_cafe_reunited`, `flag.ch2.family_park_reunited`, `flag.ch3.family_bridge_reunited`, `flag.ch3.family_hill_reunited`, `flag.ch4.family_town_reunited`, `flag.ch5.family_street_reunited`. `reunite_family(id)`가 플래그가 false일 때만 플래그를 세우고 +1. **대안**: `families_reunited`를 이 플래그들의 개수로 계산하는 `derived` 변수로 바꾸기(기존 항목 수정 → ADR) | 데이터 추가 (대안은 ADR) |
| N3 | `dialogue_conventions.md` §5 (GameState 계약) | 읽기 API 2개 추가: `GameState.seen_ending(id) -> bool`(persist 기록 확인 — 숨은 선택지 표시 조건에 필요, 지금 대사에서 persist를 읽을 방법이 없다), `GameState.resolve_ending() -> String`(§1-1). 분기 시뮬레이터와 게임이 같은 규칙을 쓰게 한다 | API 추가 |
| N4 | `canon_v1.md` §10 | 사이드 가족을 6 → 3으로 자르면 가족 조건 `families_reunited >= 3`이 "전부 완료"가 된다. 컷을 실행하면 가족 `>= 2`, 치유 `>= 1`로 낮추는 ADR을 같이 올린다 | canon 변경 (ADR, 조건부) |
| N5 | `dialogue_conventions.md` §5 | `reunite_family(family_id)`의 인자 형식을 `family_<slug>`(`^family_[a-z][a-z0-9_]*$`)로 정하고, 유효한 id 목록(§5 표)을 데이터로 둔다(N2의 플래그 목록이 그 역할을 할 수 있다) | 규약 추가 |
