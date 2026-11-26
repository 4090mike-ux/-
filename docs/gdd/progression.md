# 진행 — 챕터 흐름 · 장면 목록 · 플래그 위치 · 전역 채도 · 플레이타임

- 상태: **초안 (WP-06).** 장면 구성, 시간, 채도 수치는 모두 **[제안]**이다.
- 근거: [canon_v1.md](../bible/canon_v1.md) §7 챕터 구조 / [계획서](../plan/dev_plan_v1.md) ②-4 분량(약 55씬 + 엔딩 5, 1회차 6~9시간, 대사 약 3,000줄) / [flags.json](../../game/data/flags.json) / [dialogue_conventions.md](../schemas/dialogue_conventions.md) §1·§2
- 표기
  - 장소 표시명 뒤의 **†** = 자리표시 이름(원작 확인 전). 화실·정원·광장·카페·놀이공원·작은 집의 다락방·잃어버린 작업실·그 아이의 방만 canon에 있다. 나머지는 **TODO-확인**.
  - 화면에 나오는 이름은 **하늘 / 별**만 쓴다(R-NAME). 미션명은 canon §4의 바뀐 이름을 쓴다.
  - 조작: 하 = 하늘, 별 = 별, 태그 = 태그 전환 가능, 둘 = 컷신 위주.
  - 잔향 칸: **굵게** = 필수, 보통 = 숨김. 선택 칸의 지점 번호는 [endings.md](endings.md) §3-3.

---

## 1. 요약

| 구간 | 장면 | 잔향 (필수/숨김) | 선택 지점 | 사이드 가족 | bond | 전역 채도 (시작 → 끝) | 플레이타임 | 대사 줄 |
|---|---|---|---|---|---|---|---|---|
| prologue | 4 | 2 / 0 | 0 | 0 | 0 | 0.00 → 0.00 | 10~15분 | 120 |
| ch1 | 10 | 4 / 2 | 0 | 0 | → 1 | 0.00 → 0.10 | 20~25분 | 300 |
| ch2 | 12 | 4 / 3 | 7 | 2 | → 2 | 0.10 → 0.25 | 1.6~2.4시간 | 700 |
| ch3 | 11 | 4 / 3 | 7 | 2 | → 3 | 0.25 → 0.40 | 1.6~2.3시간 | 700 |
| ch4 | 10 | 3 / 2 | 6 | 1 | → 4 (조건부) | 0.40 → 0.50 / 폭풍 후 0.70 | 1.3~2.0시간 | 600 |
| ch5 | 8 | 1 / 2 | 4 | 1 | 4 (만회) | 0.70 → 0.85 | 0.8~1.2시간 | 330 |
| 엔딩 | 5 (1회차엔 1개) | — | — | — | — | 0.90~1.00 | 12~18분 | 250 (5 × 50) |
| **계** | **55 + 5** | **18 / 12** | **24** | **6** | | | **6.0~8.9시간** | **3,000** |

- 버티컬 슬라이스(프롤로그 + 챕터 1)는 30~40분이다. G3 목표 "20~30분 데모"에 맞추려면 **데모 빌드를 `ch1_square_02`(광장 첫 만남과 첫 동시 퍼즐) 직후에서 끊는다.** 이야기상 자연스러운 끊는 점이다.

---

## 2. 플래그·이벤트 위치

### 2-1. flags.json에 있는 플래그

| 플래그 | 세우는 장면 | 이벤트 | 쓰는 곳 |
|---|---|---|---|
| `flag.ch1.met_in_square` | `ch1_square` | `ev_ch1_square_meeting` | 태그 전환 해금, 공명 잔향 `requires` |
| `flag.ch3.hs_signature_found` | `ch3_artwork` | `ev_ch3_joint_artwork` | 진실 공개 후 H.S 해설 대사 조건 |
| `flag.ch4.family_flower_bloomed` | `ch4_garden` | `ev_ch4_family_flower` (신규 id, garden.md G4) | `echo.ch4.photo_frame` 해금 → 챕터 4 진행 |
| `flag.ch4.storm_done` | `ch4_storm_before` 끝 → `ch4_storm_after` 시작 | `ev_ch4_storm` | `echo.ch5.last_light` 조건 |
| `flag.ch4.truth_revealed` | 같음 | `ev_ch4_storm` | 표시 이름 전환(R-NAME), `echo.ch4.town_bell` 조건 |
| `flag.ch5.rainbow_flower_bloomed` | `ch5_garden` | `ev_ch5_rainbow_flower` (신규 id) | 기적 엔딩 |
| `flag.ch5.offered_color` | `ch5_final` | 숨은 선택지 "내 색을 바친다" | 희생 엔딩 |
| `flag.endings.reached` | `ch5_final` 끝 | 엔딩 평가([endings.md](endings.md) §1-1) | 엔딩 장면 선택, 세이브 슬롯 표시 |

### 2-2. 신규 제안 플래그 (flags.json에 아직 없음)

모두 **[신규 제안]**. 사이드 가족 중복 집계 방지용이다([endings.md](endings.md) 계약 변경 제안 N2).

| 플래그 | 종류 | 세우는 장면 | 세우는 것 |
|---|---|---|---|
| `flag.ch2.family_cafe_reunited` | bool | `ch2_cafe_02` | `GameState.reunite_family("family_cafe")` |
| `flag.ch2.family_park_reunited` | bool | `ch2_park_03` | `reunite_family("family_park")` |
| `flag.ch3.family_bridge_reunited` | bool | `ch3_bridge` | `reunite_family("family_bridge")` |
| `flag.ch3.family_hill_reunited` | bool | `ch3_hill` | `reunite_family("family_hill")` |
| `flag.ch4.family_town_reunited` | bool | `ch4_town` | `reunite_family("family_town")` |
| `flag.ch5.family_street_reunited` | bool | `ch5_street` | `reunite_family("family_street")` |

### 2-3. 변수가 바뀌는 곳

| 변수 | 바뀌는 곳 |
|---|---|
| `bond` | `ch1_square`(1), `ch2_attic`(2), `ch3_artwork`(3), `ch4_storm_after`(4, 조건부), `ch5_echo`(4, 만회) |
| `protect` / `heal` | 선택 지점 24곳(ch2~ch5) |
| `families_reunited` | 위 사이드 가족 6곳 |
| `echo_found` 등 | 계산값. 잔향 수집 때마다 |

### 2-4. 이벤트 id

| 이벤트 | 장면 | 출처 |
|---|---|---|
| `ev_ch1_square_meeting` | `ch1_square` | flags.json `set_by` |
| `ev_ch2_attic_memory` | `ch2_attic` | **신규** (bond 2) |
| `ev_ch3_joint_artwork` | `ch3_artwork` | flags.json `set_by` |
| `ev_ch3_garden_resonance` | `ch3_garden_02` | **신규** (정원 전체 +1) |
| `ev_ch4_family_flower` | `ch4_garden` | **신규** |
| `ev_ch4_storm` | `ch4_storm_before` 끝 | canon §4, flags.json |
| `ev_ch5_rainbow_flower` | `ch5_garden` | **신규** |

---

## 3. 챕터별 장면

파일 규칙 **[제안]**: 대사 `game/dialogue/<구간>/<장면 id>.dialogue`(규약 §1), 씬 `game/scenes/<구간>/<장면 id에서 구간 접두사를 뺀 이름>.tscn`(예: `ch2_park_03` → `ch2/park_03.tscn`). **정원 방문 장면**(`*_garden*`)은 모두 공용 허브 씬 `game/scenes/hub/garden.tscn`을 쓰고 대사만 챕터별로 둔다([garden.md](garden.md) 계약 변경 제안 G2).

### 3-1. 프롤로그 (4장면, 10~15분, 전역 채도 0.00)

| # | 장면 id | 장소 | 조작 | 내용 | 잔향 | 선택 | 플래그·이벤트 | 정원 | 분 |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `prologue_atelier` | 화실 | 하 | 하늘 파트 시작. 이동·조사·감지 튜토리얼, 첫 퍼즐(CM 난이도 1) | **atelier_brush** | | | | 4 |
| 2 | `prologue_garden` | 정원 | 별 | 별 파트 시작. 순서 퍼즐(MO 난이도 1), 첫 심기 튜토리얼. 공감 연결 잔상 ① | **garden_pot** | | | 심기 | 4 |
| 3 | `prologue_door` | 화실 앞† | 하 | 무채색 바깥 세계 첫 노출 | | | | | 2 |
| 4 | `prologue_gate` | 정원 문† | 별 | 무채색 마을 원경 → 챕터 1로 | | | | | 2 |

### 3-2. 챕터 1 (10장면, 20~25분, 0.00 → 0.10)

| # | 장면 id | 장소 | 조작 | 내용 | 잔향 | 선택 | 플래그·이벤트 | 정원 | 분 |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `ch1_atelier` | 화실 | 하 | 그리움의 파랑 | **atelier_easel** | | | | 3 |
| 2 | `ch1_garden` | 정원 | 별 | 온기의 노랑. 공감 연결 잔상 ② | **garden_sprinkler** | | | 심기 | 3 |
| 3 | `ch1_lane` | 골목† | 하 | 탐색 | lane_poster | | | | 2 |
| 4 | `ch1_path` | 오솔길† | 별 | 탐색 | **path_lamp** | | | | 2 |
| 5 | `ch1_stairs` | 계단길† | 하 | 닮은 습관(하늘 쪽) `[#sync]` | | | | | 2 |
| 6 | `ch1_market` | 시장† | 별 | 닮은 습관(별 쪽) `[#sync]` | | | | | 2 |
| 7 | `ch1_square` | 광장 | 둘 | **첫 만남.** 같은 말 동시에 ① | | | `ev_ch1_square_meeting` → `flag.ch1.met_in_square`, bond 1 | | 3 |
| 8 | `ch1_square_02` | 광장 | 태그 | 태그 전환·동시 퍼즐(붙잡기-이동) 튜토리얼, 같은 말 동시에 ②, 공명 잔향 튜토리얼. **★ 데모 끊는 점** | **square_clock**, square_bench | | | | 4 |
| 9 | `ch1_garden_02` | 정원 | 태그 | 하늘의 첫 정원 방문, 하늘 심기 | | | | 심기, **T1** | 2 |
| 10 | `ch1_night` | 광장(밤)† | 태그 | 챕터 마무리, 미수집 숨김 안내 | | | | | 1 |

### 3-3. 챕터 2 (12장면, 약 120분, 0.10 → 0.25)

| # | 장면 id | 장소 | 조작 | 내용 | 잔향 | 선택 | 플래그·이벤트 | 정원 | 분 |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `ch2_street` | 거리† | 태그 | 챕터 도입 | | C2-1 | | | 6 |
| 2 | `ch2_cafe` | 카페 | 태그 | 지은(얼굴을 확신하지 못함, W-FACE) | **cafe_cup** | C2-2 | | | 12 |
| 3 | `ch2_cafe_02` | 카페 | 태그 | 지은 2. 사이드 가족(길목형) | cafe_window | C2-3 | `family_cafe` | | 14 |
| 4 | `ch2_garden` | 정원 | 태그 | 보라·주황 첫 심기, 마음 화단 첫 등장 | | | | 심기, **T2** | 6 |
| 5 | `ch2_park` | 놀이공원 | 태그 | 놀이공원 직원 | **park_carousel** | C2-4 | | | 12 |
| 6 | `ch2_park_02` | 놀이공원 | 태그 | 동시 퍼즐(두 발판) | **park_mirror** | | | | 12 |
| 7 | `ch2_park_03` | 놀이공원 | 태그 | 사이드 가족(길목형), 기억 공유 지점 | park_ticket (공명) | C2-5 | `family_park` | | 14 |
| 8 | `ch2_alley` | 뒷골목† | 태그 | 동시 퍼즐(붙잡기-이동), 보호 컷인 #1 | | C2-6 | | | 10 |
| 9 | `ch2_house` | 작은 집 | 태그 | 물건으로 이야기하는 탐색(Unpacking식) | | | | | 10 |
| 10 | `ch2_attic` | 작은 집의 다락방 (미션) | 태그 | 다락방의 기억 | **attic_box** (공명), attic_sketch | C2-7 ★ | `ev_ch2_attic_memory`, bond 2 | | 14 |
| 11 | `ch2_garden_02` | 정원 | 태그 | 첫 조합 꽃(함께의 새싹)이 필 수 있음 | | | | 심기, **T3** | 6 |
| 12 | `ch2_night` | 거리(밤)† | 태그 | 챕터 마무리, 미수집 안내 | | | | | 4 |

### 3-4. 챕터 3 (11장면, 약 116분, 0.25 → 0.40)

| # | 장면 id | 장소 | 조작 | 내용 | 잔향 | 선택 | 플래그·이벤트 | 정원 | 분 |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `ch3_road` | 언덕길† | 태그 | 챕터 도입 | | C3-1 | | | 6 |
| 2 | `ch3_studio` | 잃어버린 작업실 (미션) | 태그 | 초록 첫 등장 | **studio_canvas**, studio_palette | C3-2 | | | 14 |
| 3 | `ch3_studio_02` | 잃어버린 작업실 | 태그 | 동시 퍼즐(기억의 다리), 보호 컷인 #2 | | C3-3 ★ | | | 12 |
| 4 | `ch3_garden` | 정원 | 태그 | 초록 심기 | | | | 심기, **T4** | 6 |
| 5 | `ch3_room` | 그 아이의 방 (미션) | 태그 | | **room_mobile** | C3-4 | | | 14 |
| 6 | `ch3_room_02` | 그 아이의 방 | 태그 | 동시 퍼즐(엇갈린 시선) | room_lamp | | | | 10 |
| 7 | `ch3_bridge` | 다리† | 태그 | 사이드 가족(곁길) | **bridge_kite** | C3-5 | `family_bridge` | | 14 |
| 8 | `ch3_hill` | 언덕† | 태그 | 동시 퍼즐, 보호 컷인 #3, 사이드 가족(곁길), 기억 공유 지점 | hill_bench (공명) | C3-6 | `family_hill` | | 14 |
| 9 | `ch3_artwork` | 협력 작품† (장소 TODO-확인) | 태그 | **H.S 서명 재발견**(의미는 진실 공개 후, R-NAME 6항). 2인 퍼즐 CM-C | **artwork_sign** (공명) | C3-7 ★ | `ev_ch3_joint_artwork` → `flag.ch3.hs_signature_found`, bond 3 | | 14 |
| 10 | `ch3_garden_02` | 정원 | 태그 | **정원 공명**, 자동 심기 안전장치 | | | `ev_ch3_garden_resonance` | 전체 +1, **T5** | 8 |
| 11 | `ch3_night` | 언덕(밤)† | 태그 | 챕터 마무리, 미수집 안내 | | | | | 4 |

### 3-5. 챕터 4 (10장면, 약 100분, 0.40 → 0.50 / 폭풍 0.00 / 폭풍 후 0.70)

| # | 장면 id | 장소 | 조작 | r-name | 내용 | 잔향 | 선택 | 플래그·이벤트 | 정원 | 분 |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | `ch4_garden` | 정원 | 태그 | pre | **가족의 꽃** 개화 | | | `ev_ch4_family_flower` → `flag.ch4.family_flower_bloomed` | **T6** | 8 |
| 2 | `ch4_photo` | 가족사진†(장소 TODO-확인) | 태그 | pre | 가족사진 잔향 | **photo_frame** (공명) | | | | 12 |
| 3 | `ch4_conflict_01` | 감정 충돌 1† | 태그 | pre | 감정 충돌 ① | **conflict_a** | C4-1 | | | 10 |
| 4 | `ch4_conflict_02` | 감정 충돌 2† | 태그 | pre | 감정 충돌 ②, 보호 컷인 #4, 기억 공유 지점 | share_window (공명) | C4-2 | | | 12 |
| 5 | `ch4_conflict_03` | 감정 충돌 3† | 태그 | pre | 감정 충돌 ③ | **conflict_c** | C4-3 | | | 10 |
| 6 | `ch4_conflict_04` | 감정 충돌 4† | 태그 | pre | 감정 충돌 ④, 동시 퍼즐(엇갈린 시선) | | C4-4 ★ | | | 12 |
| 7 | `ch4_storm_before` | 폭풍 전† | 태그 | **pre** | 동시 퍼즐(기억의 다리), 보호 컷인 #5, 끝에서 폭풍 시작 | | C4-5 ★ | `GameState.trigger("ev_ch4_storm")` | | 10 |
| 8 | `ch4_storm_after` | 폭풍 후† | 둘 | **post** | 진실 공개, 표시 이름이 본명으로 바뀜, bond 4 판정 | | | `flag.ch4.storm_done`, `flag.ch4.truth_revealed`, bond 4(조건부) | | 8 |
| 9 | `ch4_name` | 폭풍 후† | 둘 | post | 이름의 잔향 독백 한 줄(W-NAME 회수) | | | | | 6 |
| 10 | `ch4_town` | 마을† | 태그 | post | 사이드 가족(진실 공개 후) | town_bell | C4-6 | `family_town` | | 12 |

- 감정 충돌 4종의 내용·장소는 **TODO-확인**. 장면 이름은 기능(충돌 1~4)만 담았다.
- 폭풍 장면은 dialogue_conventions §2대로 **pre/post 파일을 나눈다.** 폭풍 컷신 자체는 `ch4_storm_before` 파일 끝의 이벤트가 맡는다.

### 3-6. 챕터 5 (8장면, 약 60분, 0.70 → 0.85, 전부 post)

| # | 장면 id | 장소 | 조작 | 내용 | 잔향 | 선택 | 플래그·이벤트 | 정원 | 분 |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `ch5_morning` | 아침 거리† | 태그 | 챕터 도입 | | C5-1 | | | 6 |
| 2 | `ch5_atelier` | 화실 | 태그 | 다시 찾은 화실 | atelier_window | C5-2 | | | 8 |
| 3 | `ch5_street` | 거리† | 태그 | 사이드 가족(곁길) | | C5-3 | `family_street` | | 10 |
| 4 | `ch5_square` | 광장 | 태그 | 보호 컷인 #6 | square_fountain | C5-4 ★ | | | 8 |
| 5 | `ch5_garden` | 정원 | 태그 | **무지개 꽃**(조건부), 마음 화단 최종 | | | `ev_ch5_rainbow_flower` → `flag.ch5.rainbow_flower_bloomed` | **T7** | 8 |
| 6 | `ch5_talk` | 정원(밤)† | 둘 | **성향 확인 대화** — `lean()` 3분기 | | | | | 8 |
| 7 | `ch5_echo` | 장소 TODO-확인 | 태그 | 마지막 잔향(퍼즐 없음), bond 4 만회 판정 | **last_light** (공명) | | bond 4(조건부) | | 6 |
| 8 | `ch5_final` | 장소 TODO-확인 | 둘 | **최종 선택.** 숨은 선택지 → 엔딩 평가 | | | `flag.ch5.offered_color`, `flag.endings.reached` | | 6 |

### 3-7. 엔딩 (5장면, 각 8~12분 + 크레딧 3~5분)

| 장면 id | 엔딩 | 무대 | 전역 채도 | 비고 |
|---|---|---|---|---|
| `endings_protect` | 보호 (폴백 포함) | 공용 엔딩 무대 | 0.55 (canon §12-5 "절반쯤", ADR-0009) | 하늘 모티프 주도 BGM |
| `endings_heal` | 치유 | 공용 엔딩 무대 | 0.90 | 별 모티프 주도 BGM |
| `endings_family` | 가족 | 공용 엔딩 무대 | 1.00 | 남매 테마 완성형 |
| `endings_miracle` | 기적 | 공용 엔딩 무대 + 무지개 꽃 | 1.00 + 빨강 대역 | |
| `endings_sacrifice` | 희생 | 공용 엔딩 무대 | 1.00, 바친 사람의 스프라이트만 0.00 | 대사 변형 2개(누가 바치나) |

- 계획서 ⑩ "공통 연출 + 대사 변형": 엔딩 5종이 **무대 씬 하나**(`game/scenes/endings/ending_stage.tscn`)를 같이 쓰고, 대사·BGM·채도·소품 레이어만 바꾼다. **[제안]**

---

## 4. 전역 채도 (`global_saturation`)

색 복원 셰이더의 `global_saturation` uniform(0.0~1.0)에 넣는 값이다. 잔향 자리의 **국소 복원**(마스크 + 감정 대역)과는 따로 움직인다.

| 구간 | 시작 | 끝 | 규칙 |
|---|---|---|---|
| prologue | 0.00 | 0.00 | 국소 복원만 |
| ch1 | 0.00 | 0.10 | 챕터 안에서는 **그 챕터 필수 잔향 수집 비율**로 시작 → 끝 선형 보간 |
| ch2 | 0.10 | 0.25 | 같음 |
| ch3 | 0.25 | 0.40 | 같음 |
| ch4 (폭풍 전) | 0.40 | 0.50 | 같음(ch4 필수 3개는 모두 폭풍 전) |
| ch4 (폭풍 중) | 0.00 | — | 컷신 연출. 일시적 |
| ch4 (폭풍 후) | 0.70 | 0.70 | 고정 |
| ch5 | 0.70 | 0.85 | `ch5_echo`에서 0.85 |
| 엔딩 | 0.90~1.00 | — | §3-7 |

- 숨김 잔향은 전역 채도를 바꾸지 않는다(국소 복원만). 그래서 수집률과 상관없이 모든 플레이어의 화면 분위기가 같다.
- 정원은 예외: 만개(성장 5)한 꽃 주변만 반경 24 px 국소 복원([garden.md](garden.md) §4-1).
- 계산값이라 저장하지 않는다(챕터 + 수집 목록에서 계산).
- 오디오도 이 값을 따라간다: 음악·환경음 버스의 저역 통과 필터([audio_direction.md](../audio/audio_direction.md) §5).

---

## 5. 플레이타임 산정

| 구간 | 장면 합계(분, 중앙값) | 범위 | 근거 |
|---|---|---|---|
| prologue | 12 | 10~15분 | 튜토리얼 위주, 짧은 장면 |
| ch1 | 24 | 20~25분 | 교대 파트는 장면당 2~3분 |
| ch2 | 120 | 1.6~2.4시간 | 사이드 가족 2, 퍼즐 7, 정원 2 |
| ch3 | 116 | 1.6~2.3시간 | 사이드 가족 2, 퍼즐 7, 동시 퍼즐 3 |
| ch4 | 100 | 1.3~2.0시간 | 감정 충돌 4, 폭풍 |
| ch5 | 60 | 0.8~1.2시간 | 확인 대화·최종 선택 |
| 엔딩 1개 | 15 | 12~18분 | 크레딧 포함 |
| **1회차** | **447 (약 7.5시간)** | **6.0~8.9시간** | 계획서 6~9시간 |

- 숨김 잔향을 다 찾는 플레이는 위 범위의 위쪽(8~9시간)이다.
- 전 엔딩(희생까지)은 2~3회차가 필요하다. 계획서 "전 엔딩 15~20시간"과 맞다.

---

## 6. 저장 규칙 (요약)

| 저장 | 언제 | 슬롯 |
|---|---|---|
| 자동 저장 | 장면에 들어갈 때, 잔향 수집 직후 | 0 |
| 수동 저장 | 탐색 상태에서 `pause` 메뉴 | 1~9 |
| 저장 불가 | 대사·퍼즐·컷신 중 | — |
| 위치 | `location.scene` = 장면의 `.tscn`, `location.spawn` = 가장 가까운 스폰 `Marker2D` | |

---

## 계약 변경 제안

| # | 대상 | 제안 | 종류 |
|---|---|---|---|
| P1 | `flags.json` flags | §2-2의 사이드 가족 플래그 6개 추가([endings.md](endings.md) N2와 같은 항목) | 데이터 추가 |
| P2 | 이벤트 id 목록 | 이벤트 id(`ev_*`)를 등록하는 계약 문서가 없다. `GameState.trigger(id)`가 받을 수 있는 id 목록이 필요하다. 제안: §2-4 표를 원천으로 삼거나 `flags.json`처럼 `game/data/events.json`을 둔다 | 새 계약 (ADR) |
| P3 | `dialogue_conventions.md` §1 | "선택지가 있는 장면의 장소 이름은 한 단어(`[a-z0-9]+`)로 짓는다"를 명시. `[#choice]` id 정규식이 장소 부분에 밑줄을 허용하지 않기 때문이다(예: `ch2_park_gate`라는 장면에서는 규칙에 맞는 choice id를 만들 수 없다) | 규약 추가 |
| P4 | `docs/ownership.md` | 공용 정원 허브 씬 `game/scenes/hub/`([garden.md](garden.md) G2)와 공용 엔딩 무대 `game/scenes/endings/ending_stage.tscn`의 주인을 정한다 | 소유권 추가 |
| P5 | `dialogue_conventions.md` §1 | 씬 파일 이름 규칙(장면 id에서 구간 접두사를 뺀 이름, §3 머리말)을 대사 파일 규칙 옆에 적는다 | 규약 추가 |
