# 버티컬 슬라이스 비트 시트 — 프롤로그 + 챕터 1 (WP-16 · WP-17)

- 상태: **초안. 사람 검수 필요.** 대사·설정의 최종 검수는 개발자만 한다(AGENTS.md §7). canon_v1은 G0 서명 전이다.
- 근거: [canon_v1.md](../bible/canon_v1.md) §2(W-FACE·W-NAME) §4(R-NAME) §5(H.S) §7 / [progression.md](../gdd/progression.md) §2·§3-1·§3-2 / [echo.md](../gdd/echo.md) §2·§3·§5-3 / [sibling.md](../gdd/sibling.md) §2~§4·§8 / [garden.md](../gdd/garden.md) §3·§4 / [dialogue_conventions.md](../schemas/dialogue_conventions.md)
- 이 문서의 독자: **씬 조립 세션**(챕터 통합 WP-19, 대사 UI WP-21, 정원 WP-20, 남매 전환 WP-22). 씬마다 무엇을 배치하고 어느 큐를 언제 틀지 이 문서만 보고 만들 수 있게 썼다.
- 화면에 나오는 이름은 **하늘 / 별 / 청년 / 소녀**만 쓴다(R-NAME). H.S의 뜻은 어디에도 쓰지 않는다(R-NAME 6항).

## 산출물

| 종류 | 경로 |
|---|---|
| 대사 14개 | `game/dialogue/prologue/prologue_{atelier,garden,door,gate}.dialogue`, `game/dialogue/ch1/ch1_{atelier,garden,lane,path,stairs,market,square,square_02,garden_02,night}.dialogue` |
| 잔향 데이터 8개 | `game/data/echoes/prologue.json`(2), `game/data/echoes/ch1.json`(6) |
| 퍼즐 내용 8개 | `game/data/puzzles/<slug>.json` |
| i18n | `game/i18n/ui.csv` — 잔향 이름 `echo.*` 8, 장소 `place.*` 14, NPC `name.*` 2 |
| 화자 추가 | `game/data/speakers.json` — `lane_sweeper`, `market_vendor` (추가만) |

대사 줄 수: 프롤로그 85줄, 챕터 1 225줄(파일당 14~38줄, 모두 40줄 이하). progression.md 추정치(120 / 300)보다 적다 — 튜토리얼 문구를 UI 안내로 뺐기 때문이다.

---

## 0. 공통 규약

### 0-1. 경로

| 항목 | 규칙 | 예 |
|---|---|---|
| 대사 | `game/dialogue/<구간>/<장면id>.dialogue` | `game/dialogue/ch1/ch1_square_02.dialogue` |
| 씬 | `res://game/scenes/<구간>/<장면id>.tscn` — 잔향 데이터 `location.scene`과 같다 | `res://game/scenes/ch1/ch1_square_02.tscn` |
| 잔향 위치 | 씬 안 `Marker2D` 이름 = 잔향 slug (`location.marker`) | `atelier_brush` |
| 퍼즐 내용 | `game/data/puzzles/<slug>.json` | `game/data/puzzles/square_clock.json` |
| 장소 표시 이름 | i18n `place.<장면id>` | `place.ch1_lane` = 골목 |

> progression.md §3·echo.md §6의 [제안]은 씬 이름에서 구간 접두사를 빼고(`ch1/square_02.tscn`), 정원 장면은 공용 허브 `game/scenes/hub/garden.tscn`을 쓰자고 한다. 이 초안은 WP 지시대로 접두사를 붙인 이름을 썼다. 씬 조립 세션이 다른 규칙을 쓰면 `game/data/echoes/*.json`의 `location.scene`을 같이 고쳐야 한다(§7 질문 1).

### 0-2. 큐 계약

| 큐 | 언제 재생하나 | 비고 |
|---|---|---|
| `~ start` | 씬에 들어온 직후 1회(자동 저장 다음). 대사가 끝나야 조작할 수 있다 | 모든 파일 |
| `~ inspect_<소품>` | 그 소품·NPC에서 `interact` | 소품 노드 이름(상호작용 id) = `<소품>`. 몇 번이든 다시 볼 수 있고 매번 같은 대사 |
| `~ echo_<slug>_intro` | 공명 퍼즐 패널이 열릴 때, 퍼즐 조작 전 | 1~2줄. `memory_order`는 퍼즐 json의 `intro_cue`로도 연결. 첫 줄의 `[#echo=…]`는 정보용 |
| `~ echo_<slug>_after` | 수집 처리 뒤(색 조각·색 복원·기억 컷/분할 화면이 닫힌 다음) | echo.md §2-5의 3~6단계 이후 |
| `~ exit_blocked` | 아직 허용되지 않은 출구에 닿았을 때 | 재생 뒤 캐릭터를 출구 밖으로 한 걸음 되돌린다 |
| `~ leave` | 허용된 출구를 지날 때, 장면 전환 직전 | 있는 파일만(prologue_door, prologue_gate, ch1_square_02, ch1_garden_02, ch1_night) |
| `~ plant_done` | 정원에서 **그 장면의 첫 심기**를 마친 직후 1회 | prologue_garden, ch1_garden, ch1_garden_02 |
| `~ coop_gate_hint_*`, `~ coop_gate_done` | ch1_square_02 동시 조작 퍼즐 전용(§2-12) | |

- 모든 큐는 `=> END`로 끝난다. 큐 이름은 영문 snake_case.
- 대사가 바꾸는 상태는 ch1_square의 두 줄뿐이다(§5). 잔향 수집(`collect_echo`)·심기·성장 틱은 각 시스템이 처리하고 대사는 결과를 말로만 받는다.

### 0-3. 출구 조건 판정

| 조건 종류 | 판정 방법 |
|---|---|
| 잔향 수집 | `GameState.has_echo("echo.…")` |
| 심기 완료 | `GameState.garden_state()`에서 그 칸(`plot_06` 등)이 심겨 있음 — 다시 불러와도 맞다 |
| 대화 완료(로컬) | 이 씬에서 해당 `inspect_` 큐를 한 번 재생함. 저장하지 않는다(씬 진입 때 자동 저장되므로 불러오면 처음부터) |
| 항상 막힘 | 그 씬의 맵 가장자리. 늘 `exit_blocked` |

### 0-4. 조작 방식

| 구간 | 조작 | 규칙 |
|---|---|---|
| prologue_atelier ~ ch1_market | **교대 파트(단독 구간)** | 태그 전환 금지(sibling.md §3). 장면이 끝나면 다음 사람 파트로 넘어가며 감정 기호가 화면을 쓸고 지나간다(1.0초, sibling.md §2-1) |
| ch1_square `start` | 컷신(입력 잠금) | `start` 안에서 `flag.ch1.met_in_square` → 태그 전환 해금 |
| ch1_square 탐색 ~ ch1_night | 태그 전환 | 활성 캐릭터 기본값 하늘(제안) |

### 0-5. 튜토리얼 입력 안내 (UI가 띄운다)

대사에는 키 이름을 쓰지 않았다. 지금 설정된 키는 UI가 보여 준다(controls_accessibility.md).

| 장면 | 시점 | 안내 내용 |
|---|---|---|
| prologue_atelier | `start` 끝 | 이동(`move_*`), 조사(`interact`) |
| prologue_atelier | 소품 2개를 조사했거나 `atelier_brush` 마커 80 px 안에 들어왔을 때 | 감지(`echo_sense` 누르고 있기) |
| prologue_atelier | 첫 `color_match` 패널 | 칸 고르기 → 조각 고르기 → 놓기. "같은 기호끼리" |
| prologue_garden | 첫 `memory_order` 패널 | 카드를 일어난 순서대로 놓고 확인 |
| prologue_garden | `echo_garden_pot_after` 끝 | 심기: 빈 칸에서 `interact` → 감정 고르기 |
| ch1_square | `start` 끝 | 태그 전환(`tag_switch`) |
| ch1_square_02 | `start` 끝 | 붙잡기: 장치에서 `interact` 유지 → `tag_switch` |
| ch1_square_02 | `coop_gate_done` 끝 | 공명 잔향: 두 사람이 가까이 있을 때만 느껴진다 |
| ch1_garden_02 | `start` 끝 | 하늘 줄에 심기 / "정원 나가기" |

### 0-6. 태그 처리

| 태그 | 쓰인 곳 | 처리 |
|---|---|---|
| `[#sync]` | ch1_stairs, ch1_market, ch1_garden_02 | **닮은 습관**: 그 줄에서 말하는(또는 지문이 가리키는) 캐릭터의 습관 동작 애니메이션 재생(가칭 `habit_circle` — 검지로 허공에 작은 동그라미 두 번) + 화음 효과음 |
| `[#sync]` | ch1_square, ch1_square_02 | **같은 말 동시에**: `| ` 동시 발화 두 줄을 한 번에 띄우고 화음 효과음, 두 초상이 같이 흔들림(sibling.md §6) |
| `[#portrait=…]` | 전체 | 초상 표정 12종 중 8종 사용 |
| `[#emotion=longing / warmth]` | 전체 | 그 줄의 말풍선 테두리·기호 |
| `[#echo=…]` | 각 `_intro` 첫 줄 | 정보용. 별도 동작 없음 |

- `[#choice]`는 없다. 성향 선택지는 챕터 2부터다. `[#bgm]`·`[#sfx]` 태그도 쓰지 않았다 — 음악은 아래 장면표대로 씬이 고른다.

### 0-7. 문장·지문 규칙

- 화자 없는 줄 = 지문. `「 」` = 잔향 속에서 들리는 목소리(누구 목소리인지 밝히지 않는다).
- **이름을 짓기 전 속말은 지문으로 썼다**(prologue_atelier·prologue_garden `start` 1~6줄). 이름표에 '하늘/별'이 이름을 짓기 전에 뜨지 않게 하려는 것이다.
- 잔향 기억(`_after`) 지문은 감지한 사람의 1인칭 시점이다.
- 힌트성 대사에 색 이름만 쓰지 않는다("노란 조각" ✗ → "따뜻한 조각").

### 0-8. NPC (W-FACE: 얼굴 0단계 — 윤곽선뿐인 스케치)

| 화자 키 | 표시 이름 | 장면 | 비고 |
|---|---|---|---|
| `lane_sweeper` | 골목 청소부 | ch1_lane | 빗자루질 대기 동작. **신규 NPC — TODO-확인** |
| `market_vendor` | 시장 상인 | ch1_market | 과일 좌판 뒤. **신규 NPC — TODO-확인** |
| (화자 없음) 행인 | — | prologue_door | 말하지 않는 스프라이트. 길을 천천히 오간다. 조사하면 지문만 나온다 |

- 두 주인공은 ch1_square에서 만난 순간부터 서로에게 **1단계 얼굴**(눈·입이 흐린 선)로 보인다(canon §2 W-FACE 연출 단계 [제안], TODO-확인).

### 0-9. 이미 모은 잔향의 색이 남아 있어야 하는 곳

대사가 이 색을 직접 말하므로 꼭 맞춰야 한다. 해당 잔향의 `EchoObject`를 **수집된 상태**로 같은 자리에 두면 `ColorRestoreLayer`가 씬 로드 때 복원한다.

| 씬 | 두어야 할 수집된 잔향 | 대사 |
|---|---|---|
| ch1_atelier | `echo.prologue.atelier_brush`(붓통) | `start` "붓통 둘레는 아직 파랗네", `inspect_brushes` |
| ch1_garden | `echo.prologue.garden_pot`(별 화분) | `start` "별 화분 둘레는 아직 노랗네", `inspect_pot` |
| ch1_garden_02 | `garden_pot`, `garden_sprinkler` | `start` "노란 빛이 군데군데", `inspect_pot` |

수집된 `EchoObject`와 같은 자리에 조사 소품(`brushes`, `pot`)이 있으면 **조사 소품이 `interact`를 받아야 한다.**

---

## 1. 장면 흐름 한눈에

| # | 장면 | 배경 | 조작 | 잔향(★필수 / ☆숨김) | 상태 변화 | 다음 장면 | BGM (VS 3곡 기준) |
|---|---|---|---|---|---|---|---|
| 1 | prologue_atelier | `atelier` | 하늘 | ★ atelier_brush | | prologue_garden | `haneul` |
| 2 | prologue_garden | `garden` | 별 | ★ garden_pot | plot_06 심기 | prologue_door | `byeol` |
| 3 | prologue_door | `atelier_door` | 하늘 | | | prologue_gate | `haneul` |
| 4 | prologue_gate | `garden_gate` | 별 | | | ch1_atelier (챕터 1 제목 카드) | `byeol` |
| 5 | ch1_atelier | `atelier` | 하늘 | ★ atelier_easel | | ch1_garden | `haneul` |
| 6 | ch1_garden | `garden` | 별 | ★ garden_sprinkler | plot_07 심기 | ch1_lane | `byeol` |
| 7 | ch1_lane | `lane` | 하늘 | ☆ lane_poster | | ch1_path | `haneul` |
| 8 | ch1_path | `path` | 별 | ★ path_lamp | | ch1_stairs | `byeol` |
| 9 | ch1_stairs | `stairs` | 하늘 | | 닮은 습관 ① | ch1_market | `haneul` |
| 10 | ch1_market | `market` | 별 | | 닮은 습관 ② | ch1_square | `byeol` |
| 11 | ch1_square | `square` | 둘 → 태그 | | **met_in_square, bond 1**, 같은 말 ① | ch1_square_02 | `square` |
| 12 | ch1_square_02 | `square` | 태그 | ★ square_clock, ☆ square_bench | 같은 말 ② · ★ 데모 끊는 점 | ch1_garden_02 | `square` |
| 13 | ch1_garden_02 | `garden` | 태그 | | plot_01~ 심기, 성장 틱 T1 | ch1_night | `garden_hub`(P1) — 없으면 `byeol` |
| 14 | ch1_night | `square_night` | 태그 | | 미수집 숨김 안내 | 챕터 1 끝 | `square`(밤 믹스) |

- 거리 장면(7~10)은 audio_direction.md의 `gray_town`(P1)으로 바꿀 수 있다. VS에는 3곡만 있어 파트 모티프를 그대로 썼다.
- 전역 채도: 챕터 1 필수 잔향 4개(atelier_easel, garden_sprinkler, path_lamp, square_clock) 수집 비율로 0.00 → 0.10(progression.md §4).

---

## 2. 장면별 사양

### 2-1. prologue_atelier — 화실 (하늘)

**요약.** 하늘이 낯선 화실에서 기억 없이 깨어난다. 벽에 기대 둔 그림 구석의 서명 "H.S"를 보자 입이 먼저 "하늘"이라는 말을 꺼내고, 그것을 임시 이름으로 삼는다. 이동·조사·감지·색 맞추기 튜토리얼. 붓의 잔향에서 '누군가 내 등 뒤에서 그림이 끝나길 기다리던 오후'를 떠올린다.

- 스폰: 하늘 — 소파 옆(누웠다 일어나는 동작 권장).
- 그림 속 "H.S" 두 글자는 화면에서 읽을 수 있어야 한다(필요하면 확대 컷).

| 소품 | 무엇 | 큐 |
|---|---|---|
| `sofa` | 깨어난 소파, 흘러내린 담요 | `inspect_sofa` |
| `window` | 회색 바깥이 보이는 창 | `inspect_window` |
| `palette` | 회색으로 말라붙은 팔레트 | `inspect_palette` |
| `canvas` | 벽에 기대 둔 들판 그림, 구석에 H.S 서명(ch1_atelier에서도 같은 자리) | `inspect_canvas` |

| 잔향 마커 | 물건 | 감지 | 퍼즐 |
|---|---|---|---|
| `atelier_brush` | 작업대 붓통의 붓 | 하늘 | color_match 1 (30초) |

| 큐 | 트리거 | 내용 요지 | 상태 변화 |
|---|---|---|---|
| `start` | 진입 | 깨어남 → H.S → "하늘" → 회색 세상 → 어딘가의 울림 | |
| `inspect_*` 4개 | 소품 조사 | | |
| `echo_atelier_brush_intro` | 퍼즐 열림 | 붓끝의 물결, 「조금만 기다려. 거의 다 됐어.」 | |
| `echo_atelier_brush_after` | 수집 후 | 기다리던 누군가, "이 파랑이 그리워" | (잔향 시스템이 수집) |
| `exit_blocked` | 문, 잔향 미수집 | | |

| 출구 | 조건 | 막혔을 때 | 다음 |
|---|---|---|---|
| `door` 화실 문 | `has_echo("echo.prologue.atelier_brush")` | `exit_blocked` | prologue_garden (교대 → 별) |

### 2-2. prologue_garden — 정원 (별)

**요약.** 별이 작은 정원 한가운데서 깨어난다. 발치의 별 모양 화분을 보고 "별"이라는 이름을 짓는다. 화분의 잔향(순서 퍼즐)에서 '매일 물 주기로 한 약속'을 떠올리고, 얻은 조각을 처음으로 심는다.

- 스폰: 별 — 정원 가운데 풀밭(누운 상태).
- **공감 연결 잔상 ①**: `start` 2번째 줄과 동시에 물결 기호(longing) 0.5초(echo.md §2-4).
- 정원: 별 줄 `plot_06` 심기 가능. 성장 틱 없음(garden.md §4-2).

| 소품 | 무엇 | 큐 |
|---|---|---|
| `flowers` | 회색 꽃밭 | `inspect_flowers` |
| `shed` | 작은 창고(모종삽, 글씨 지워진 씨앗 봉투) | `inspect_shed` |
| `swing` | 바람에 혼자 흔들리는 그네 | `inspect_swing` |
| `can` | 빈 물뿌리개 — ch1_garden 잔향 `garden_sprinkler`와 같은 자리 | `inspect_can` |

| 잔향 마커 | 물건 | 감지 | 퍼즐 |
|---|---|---|---|
| `garden_pot` | 별 모양 화분(별이 깨어난 자리 발치). 이름의 단서와 같은 물건 — TODO-확인 | 별 | memory_order 1 (30초) |

| 큐 | 트리거 | 내용 요지 | 상태 변화 |
|---|---|---|---|
| `start` | 진입 | 깨어남 → 물결 잔상 → 별 화분 → "별" → 아픈 꽃들 → 따뜻한 무언가 | |
| `inspect_*` 4개 | 소품 조사 | | |
| `echo_garden_pot_intro` | 퍼즐 열림 | 「처음엔 아주 작았어. 그다음엔?」 | |
| `echo_garden_pot_after` | 수집 후 | 흙을 토닥이던 작은 손과 조금 더 큰 손, 약속 → 빈 화단에 심자 | 심기 안내 표시 |
| `plant_done` | `plot_06` 첫 심기 직후 | "꾹꾹. 잘 자라라." | (정원 시스템이 저장) |
| `exit_blocked` | 정원 문, 조건 미충족 | | |

| 출구 | 조건 | 막혔을 때 | 다음 |
|---|---|---|---|
| `gate` 정원 문 | `garden_pot` 수집 **그리고** `plot_06` 심김 | `exit_blocked` | prologue_door (교대 → 하늘) |

### 2-3. prologue_door — 화실 앞 (하늘)

**요약.** 하늘이 화실 문을 열고 처음 바깥을 본다. 지붕도 길도 구름도 회색이고, 지나가는 사람들의 얼굴은 연필로 대충 그린 스케치 같다(W-FACE). 해가 기울자 내일을 기약하고 화실로 돌아간다.

- 스폰: 하늘 — 화실 문 앞.

| 소품 / NPC | 무엇 | 큐 |
|---|---|---|
| `mailbox` | 이름표 자리가 닳은 우편함 | `inspect_mailbox` |
| `lamp` | 낮에도 켜진 가로등 | `inspect_lamp` |
| `sign` | 글자가 지워진 화실 간판 | `inspect_sign` |
| `passerby` | 행인 NPC(말 없음, 얼굴 0단계) | `inspect_passerby` |

| 출구 | 조건 | 막혔을 때 | 다음 |
|---|---|---|---|
| `door_back` 화실 문(돌아가기) | 없음 | — | `leave` 재생 → prologue_gate |
| `road` 길 저편(마을 쪽) | 항상 막힘 | `exit_blocked` | — |

### 2-4. prologue_gate — 정원 문 (별)

**요약.** 별이 정원 문 너머로 회색 마을을 내려다본다. 마을 한가운데 시계탑을 보고 내일 저기까지 가 보기로 한다.

- 스폰: 별 — 정원 문 안쪽.
- 배경 원경에 **광장의 시계탑**이 보여야 한다(`start` 5번째 줄, 챕터 1 목적지).

| 소품 | 무엇 | 큐 |
|---|---|---|
| `gate` | 녹슨 문고리의 정원 문 | `inspect_gate` |
| `signpost` | 글씨는 지워지고 화살표만 시계탑 쪽 | `inspect_signpost` |
| `town` | 마을 전망 지점(지붕 위 연기) | `inspect_town` |
| `bird` | 울타리 위 회색 새 | `inspect_bird` |

| 출구 | 조건 | 막혔을 때 | 다음 |
|---|---|---|---|
| `garden_back` 정원으로 | 없음 | — | `leave` 재생 → ch1_atelier (**챕터 1 제목 카드** 권장) |
| `road_down` 마을로 내려가는 길 | 항상 막힘 | `exit_blocked` | — |

### 2-5. ch1_atelier — 화실, 아침 (하늘)

**요약.** 다음 날 아침. 붓통 둘레에 어제 되찾은 파랑이 남아 있다. 이젤 위 반쯤 그린 그림의 잔향에서 '다음에 마저 그리자'던 약속을 떠올리고, 이 파랑이 그리워하는 사람을 찾으러 나가기로 한다.

- 배경: prologue_atelier와 같은 방, 아침 조명. 스폰: 소파 옆.
- `atelier_brush` 수집된 `EchoObject`를 붓통 자리에 둔다(§0-9).

| 소품 | 무엇 | 큐 |
|---|---|---|
| `canvas` | H.S 서명 그림(같은 자리) | `inspect_canvas` |
| `sketchbook` | 작업대 위 빈 스케치북 | `inspect_sketchbook` |
| `window` | 골목이 보이는 창 | `inspect_window` |
| `brushes` | 붓통(어제의 파랑) | `inspect_brushes` |
| `coat` | 옷걸이의 낡은 외투(몽당연필) | `inspect_coat` |

| 잔향 마커 | 물건 | 감지 | 퍼즐 |
|---|---|---|---|
| `atelier_easel` | 창가의 작은 이젤, 반쯤 그린 그림 | 하늘 | color_match 1 (30초) |

| 큐 | 트리거 | 내용 요지 |
|---|---|---|
| `start` | 진입 | 아침, 남아 있는 파랑, 이젤의 새 울림 |
| `echo_atelier_easel_intro` | 퍼즐 열림 | 「다음엔 같이 그리자. 꼭.」 |
| `echo_atelier_easel_after` | 수집 후 | 반쯤에서 멈춘 그림, 약속 → "이 파랑이 그리워하는 사람을" 찾으러 |
| `exit_blocked` | 문, 미수집 | |

| 출구 | 조건 | 막혔을 때 | 다음 |
|---|---|---|---|
| `door` 화실 문 | `has_echo("echo.ch1.atelier_easel")` | `exit_blocked` | ch1_garden (교대 → 별) |

### 2-6. ch1_garden — 정원, 아침 (별)

**요약.** 별의 아침. 별 화분 둘레에 노랑이 남아 있다. 물뿌리개의 잔향에서 '무거우면 같이 들자'며 손잡이 반대쪽을 들어 주던 손을 떠올린다. 조각을 심고 마을로 떠난다.

- **공감 연결 잔상 ②**: `start` 2번째 줄과 동시에 물결 기호 0.5초(직전 하늘 파트 잔향 = longing).
- `garden_pot` 수집된 `EchoObject`를 별 화분 자리에 둔다(§0-9). 정원: `plot_07` 심기, 틱 없음.

| 소품 | 무엇 | 큐 |
|---|---|---|
| `pot` | 별 화분(노랑이 남음) | `inspect_pot` |
| `swing` | 2인용 그네 | `inspect_swing` |
| `flowers` | 이슬 맺힌 회색 꽃밭 | `inspect_flowers` |
| `fence` | 울타리(너머로 시계탑 꼭대기) | `inspect_fence` |

| 잔향 마커 | 물건 | 감지 | 퍼즐 |
|---|---|---|---|
| `garden_sprinkler` | 수돗가 옆 물뿌리개(prologue의 `can` 자리) | 별 | memory_order 1 (30초) |

| 큐 | 트리거 | 내용 요지 |
|---|---|---|
| `start` | 진입 | 또 물결 꿈, 남아 있는 노랑, 마을에 가기 전에 물 주기 |
| `echo_garden_sprinkler_intro` | 퍼즐 열림 | 「무거우면 같이 들자.」 |
| `echo_garden_sprinkler_after` | 수집 후 | 함께 들어 준 손 → "그때는 혼자가 아니었구나" → 심고 가자 |
| `plant_done` | `plot_07` 첫 심기 직후 | "금방 돌아올게." |
| `exit_blocked` | 조건 미충족 | |

| 출구 | 조건 | 막혔을 때 | 다음 |
|---|---|---|---|
| `gate` 정원 문 | `garden_sprinkler` 수집 **그리고** `plot_07` 심김 | `exit_blocked` | ch1_lane (교대 → 하늘) |

### 2-7. ch1_lane — 골목 (하늘)

**요약.** 하늘이 골목에 들어선다. 골목 청소부는 하늘을 알아보지 못하고, 색이 언제부터 없었는지도 가물가물하다고 말한다. 목소리와 걸음걸이는 남는다는 말(W-FACE), 그리고 "사람을 찾으면 광장에 가 보라"는 길 안내를 듣는다. 숨김 잔향: 빛바랜 축제 포스터.

| 소품 / NPC | 무엇 | 큐 |
|---|---|---|
| `sweeper` | **NPC `lane_sweeper`** 골목 청소부 | `inspect_sweeper` (6줄) |
| `laundry` | 빨랫줄의 셔츠 | `inspect_laundry` |
| `cat` | 담 위 고양이 | `inspect_cat` |
| `puddle` | 물웅덩이 | `inspect_puddle` |

| 잔향 마커 | 물건 | 감지 | 퍼즐 |
|---|---|---|---|
| `lane_poster` | 담벼락의 빛바랜 축제 포스터. **숨김(비밀형)** — 감지 반경 60% 안에서만 보인다. 포스터에 조사 큐를 두지 않는다 | 하늘 | color_match 2 (35초) |

| 큐 | 트리거 | 내용 요지 |
|---|---|---|
| `start` | 진입 | 회색 골목, 빗자루 소리 |
| `echo_lane_poster_intro` | 퍼즐 열림 | 「불꽃놀이, 같이 보러 가자.」 |
| `echo_lane_poster_after` | 수집 후 | 소매를 잡던 작은 손 → "기억이 안 나는 게… 조금 아파." |
| `exit_blocked` | 청소부와 대화 전 | |

| 출구 | 조건 | 막혔을 때 | 다음 |
|---|---|---|---|
| `lane_end` 계단 쪽 골목 끝 | 이 씬에서 `inspect_sweeper`를 한 번 재생함(로컬) | `exit_blocked` | ch1_path (교대 → 별) |

### 2-8. ch1_path — 오솔길 (별)

**요약.** 별이 정원에서 오솔길을 따라 내려간다. 낮에도 켜진 등불의 잔향에서 '등불을 든 누군가가 마중 나와 내 이름을 부르는데, 그 이름만 들리지 않는' 기억을 떠올린다. 이번엔 자기가 찾으러 가겠다고 다짐한다.

| 소품 | 무엇 | 큐 |
|---|---|---|
| `tree` | 연필 자국 같은 나무껍질 | `inspect_tree` |
| `sign` | 화살표만 시장 쪽을 가리키는 표지판 | `inspect_sign` |
| `butterfly` | 회색 나비(앰비언트) | `inspect_butterfly` |
| `wildflowers` | 들꽃 | `inspect_wildflowers` |

| 잔향 마커 | 물건 | 감지 | 퍼즐 |
|---|---|---|---|
| `path_lamp` | 낮에도 켜진 길가 등불 | 별 | color_match 2 (35초) |

| 출구 | 조건 | 막혔을 때 | 다음 |
|---|---|---|---|
| `path_end` 길 아래쪽 | `has_echo("echo.ch1.path_lamp")` | `exit_blocked` | ch1_stairs (교대 → 하늘) |

### 2-9. ch1_stairs — 계단길 (하늘) · 닮은 습관 ①

**요약.** 계단길이 두 갈래로 갈라진다. 하늘은 저도 모르게 검지로 허공에 작은 동그라미를 두 번 그리고 "…이쪽."을 고른다. 몸이 먼저 기억하는 게 많다고 혼잣말한다.

- `start` 3번째 줄(지문)~4번째 줄(`[#sync]`): 하늘 `habit_circle` 애니메이션. ch1_market과 **같은 동작·같은 말**.

| 소품 | 무엇 | 큐 |
|---|---|---|
| `railing` | 반질반질 닳은 난간 | `inspect_railing` |
| `pots` | 계단마다 놓인 화분 | `inspect_pots` |
| `chalk` | 계단참의 희미한 사방치기 분필 그림 | `inspect_chalk` |
| `view` | 마을 전망 지점 | `inspect_view` |

| 출구 | 조건 | 막혔을 때 | 다음 |
|---|---|---|---|
| `fork_up` 손가락이 고른 쪽(위) | 없음(`start` 후) | — | ch1_market (교대 → 별) |
| `fork_down` 다른 갈래 | 항상 막힘 | `exit_blocked` | — |

### 2-10. ch1_market — 시장 (별) · 닮은 습관 ②

**요약.** 시장 끝 갈림길에서 별이 하늘과 **똑같은 버릇**으로 길을 고른다. 시장 상인은 별의 얼굴을 알아보지 못하고, 사과가 빨갰다는 건 아는데 어떤 빨강이었는지는 모른다고 말한다. 빵 냄새를 맡은 별은 "누구랑 반 나눠 먹고 싶다"고 중얼거린다(square_bench 복선).

- `start` 5번째 줄(지문)~6번째 줄(`[#sync]`): 별 `habit_circle` 애니메이션.

| 소품 / NPC | 무엇 | 큐 |
|---|---|---|
| `vendor` | **NPC `market_vendor`** 시장 상인(과일 좌판 뒤) | `inspect_vendor` (5줄) |
| `apples` | 회색 사과 | `inspect_apples` |
| `cloth` | 꽃무늬 천 가게 | `inspect_cloth` |
| `bakery` | 빵 가게(냄새) | `inspect_bakery` |

| 출구 | 조건 | 막혔을 때 | 다음 |
|---|---|---|---|
| `fork_main` 손가락이 고른 쪽 | 없음(`start` 후) | — | ch1_square (둘) |
| `fork_side` 다른 갈래 | 항상 막힘 | `exit_blocked` | — |

### 2-11. ch1_square — 광장 · 첫 만남 (둘)

**요약.** 계단 쪽에서 청년이, 시장 쪽에서 소녀가 광장에 들어선다. 두 사람은 동시에 "혹시, 우리 어디서 본 적 있…"이라고 말하고 입을 다문다(**같은 말 동시에 ①**). 다른 사람들과 달리 서로의 얼굴은 조금 보인다. 둘 다 기억이 없고, 둘 다 물건에서 이름을 빌렸다(화분 / 그림 서명). "그래도 이제 혼자는 아니네." 시계탑 아래의 울림을 함께 따라가기로 한다.

- `start`는 컷신이다(입력 잠금). 스폰: 하늘 — 계단 쪽(왼쪽) 입구, 별 — 시장 쪽(오른쪽) 입구. `start` 2번째 줄에서 둘이 광장 가운데로 걸어 나온다.
- `start` 6~7번째 줄(`haneul` + `| byeol`, 둘 다 `[#sync]`): 동시 발화 + BGM `square` 두 모티프 **1마디 겹침**(audio_direction.md §3-5).
- **상태 변화**(이벤트 `ev_ch1_square_meeting`의 내용): `start` 안 `$> GameState.set_flag("flag.ch1.met_in_square", true)`, `$> GameState.raise_bond(1)`. 대사 밖에서 같은 처리를 중복하지 않는다. 이 순간부터 태그 전환 해금, 두 사람은 서로에게 얼굴 1단계.
- `start`가 끝나면 태그 전환 모드. 조사 대사는 두 사람이 주고받는 형태라 누가 활성이어도 같다.

| 소품 | 무엇 | 큐 |
|---|---|---|
| `fountain` | 회색 물이 흐르는 분수 | `inspect_fountain` |
| `board` | '사람을 찾습니다' 전단이 빼곡한 게시판(얼굴 칸이 흐릿) | `inspect_board` |
| `pigeons` | 발치로 모여드는 비둘기 | `inspect_pigeons` |
| `clock` | 멈춘 시계탑 시계판(높은 곳) | `inspect_clock` |

| 출구 | 조건 | 막혔을 때 | 다음 |
|---|---|---|---|
| `clock_gate` 시계탑 아래로 | `start` 이후 항상 | — | ch1_square_02 |
| `back_stairs`, `back_market` 왔던 길 | 항상 막힘 | `exit_blocked` | — |

### 2-12. ch1_square_02 — 광장 시계탑 아래 (태그) · ★ 데모 끊는 점

**요약.** 시계탑 아래 철문이 무거워 혼자서는 열 수 없다. 하늘과 별을 번갈아 조작해 한 명이 문을 붙잡고 다른 한 명이 들어가 안쪽에서 고정한다(동시 조작 퍼즐 #1 붙잡기-이동). 문이 고정되자 둘이 동시에 "둘이 하니까 되네."(**같은 말 동시에 ②**) — "이걸로 두 번째야." 가까이 붙어 있어야만 들리는 공명 잔향(시계탑)을 함께 모은다: 하늘은 시계 아래서 누군가를 오래 기다렸고, 별은 누군가에게 숨이 차도록 달려가고 있었다. 숨김 공명 잔향(벤치)에는 하나뿐인 빵을 반으로 나눈 기억이 있다. 별이 하늘을 자기 정원에 초대한다.

동시 조작 장치(sibling.md §4-1 붙잡기-이동):

| 노드 | 역할 |
|---|---|
| `gate_hold` | 철문 바깥 손잡이. `interact` 유지 = 붙잡기(그 캐릭터는 머물기 상태) |
| `gate` | 붙잡는 동안 열리는 통로 |
| `gate_latch` | 철문 안쪽 고정 장치. 건너간 사람이 `interact` → 철문 고정, 붙잡던 사람 풀림 |

| 큐 | 트리거 | 내용 요지 |
|---|---|---|
| `start` | 진입 | 반쯤 내려온 철문, "번갈아 가면서 해 봐요!" → 붙잡기 안내 |
| `coop_gate_hint_hold` | 막힘 30초 + 아무도 붙잡지 않음 | 비활성 캐릭터: "문을 붙잡아요/붙잡아 줘" |
| `coop_gate_hint_switch` | 막힘 30초 + 한 명이 붙잡고 있고 아직 전환 안 함 | "이제 바꿔요/바꾸자" |
| `coop_gate_hint_latch` | 막힘 30초 + 한 명이 안쪽에 들어갔고 고정 안 함 | "안쪽에서 받쳐 줘요 / 고정하는 게 있을 거야" |
| `coop_gate_done` | `gate_latch` 고정 직후 1회 | 같은 말 동시에 ② → 공명 잔향 안내 |
| `inspect_clockface` / `inspect_lamp` / `inspect_plaque` | 소품 조사 | |
| `echo_square_clock_intro` | 퍼즐 열림 | 「몇 시에 만나기로 했더라?」 |
| `echo_square_clock_after` | 수집 + 분할 화면 뒤 | 바늘이 한 칸 움직임, 기다린 기억 / 달려간 기억 |
| `echo_square_bench_intro` | 퍼즐 열림 | 「하나밖에 없네. …반씩 먹자.」 |
| `echo_square_bench_after` | 수집 + 분할 화면 뒤 | 큰 쪽을 받은 기억 / 작은 쪽인데도 배불렀던 기억 |
| `exit_blocked` | 시계 잔향 미수집 | |
| `leave` | 허용된 출구 | 정원 초대 |

- 힌트는 30초마다 1개, 최대 3개(sibling.md §4-2). 대사는 `GameState.active_character`로 분기해 **비활성 캐릭터**가 말한다.
- `coop_gate_done` 끝에 공명 잔향 튜토리얼 안내(§0-5).

| 소품 | 무엇 | 큐 |
|---|---|---|
| `clockface` | 숫자가 반쯤 지워진 시계판 | `inspect_clockface` |
| `lamp` | 시계탑 옆 가로등 | `inspect_lamp` |
| `plaque` | 글자가 닳은 머릿돌 | `inspect_plaque` |

| 잔향 마커 | 물건 | 감지 | 퍼즐 | 비고 |
|---|---|---|---|---|
| `square_clock` | 철문 안쪽 시계탑 기단의 시계 장치 | **both** | memory_order 2 (35초) | 필수. 두 사람이 64 px 안 |
| `square_bench` | 광장 쪽 낡은 벤치 | **both** | memory_order 2 (35초) | 숨김(표시형): 둘이 함께 있으면 감지 없이도 희미한 반짝임. 벤치에 조사 큐를 두지 않는다 |

- 두 잔향 모두 `requires`: `flag.ch1.met_in_square` + `bond_min 1`(이 시점엔 항상 충족). 수집하면 기억 공유 분할 화면(왼쪽 하늘·오른쪽 별, sibling.md §8) → 정원의 같은 감정 칸 +1(garden.md §4-3) → `_after` 큐.
- `square_clock`을 모으면 광장 시계 바늘이 한 칸 앞으로 간 그림으로 바뀐다(ch1_night에서 이어짐).

| 출구 | 조건 | 막혔을 때 | 다음 |
|---|---|---|---|
| `to_garden` 정원 가는 길 | `has_echo("echo.ch1.square_clock")` | `exit_blocked` | `leave` 재생 → ch1_garden_02. **데모 빌드는 여기서 데모 종료 화면** |

### 2-13. ch1_garden_02 — 정원 (태그) · 하늘의 첫 방문

**요약.** 별이 하늘을 정원에 데려온다. 둘 다 물건에서 이름을 빌렸다는 걸 확인하며 "이름 빌린 사람끼리"라고 웃는다. 하늘이 심을 자리를 고르며 허공에 동그라미를 그리자, 별이 "저도 길 고를 때 그러는데" 하고 놀란다. 하늘이 첫 조각을 심는다("기다리는 거, 잘해요?" "…잘하는 것 같아. 이상하게."). 정원을 나설 때 첫 성장 틱으로 싹이 난다.

- 흐름(garden.md §4-4): `start` → 자유 시간 → 하늘 첫 심기 → `plant_done` → "정원 나가기" → 마무리(**성장 틱 T1**, 개화 연출) → `leave` → ch1_night.
- `start` 10번째 줄(`[#sync]` 지문): 하늘 `habit_circle` 애니메이션.
- 하늘 줄 `plot_01`~`plot_05` 해금. 하늘 주머니: `atelier_brush`·`atelier_easel`·`square_clock`(+ 숨김 `lane_poster`·`square_bench`) 조각. 별 줄도 태그 전환으로 심을 수 있다.
- `garden_pot`·`garden_sprinkler` 수집된 `EchoObject`를 둔다(§0-9).

| 소품 | 무엇 | 큐 |
|---|---|---|
| `pot` | 별 화분(노랑이 남음) | `inspect_pot` |
| `swing` | 2인용 그네 | `inspect_swing` |
| `shed` | 창고 — 모종삽 두 개, 하나는 조금 작다 | `inspect_shed` |

| 출구 | 조건 | 막혔을 때 | 다음 |
|---|---|---|---|
| "정원 나가기" | 하늘 줄에 1칸 이상 심김 | `exit_blocked` | 마무리(T1) → `leave` → ch1_night |

### 2-14. ch1_night — 밤의 광장 (태그)

**요약.** 밤. 시계탑 바늘이 낮보다 한 칸 앞에 있다. 하루를 돌아보고, 아직 못 들은 울림이 남았는지 넌지시 말한 뒤, "여기서 만나요. 시계탑 아래서." / "응. 기다릴게."로 헤어져 각자 화실과 정원으로 돌아간다.

| 소품 | 무엇 | 큐 |
|---|---|---|
| `clock` | 밤의 시계탑(바늘 한 칸 앞) | `inspect_clock` |
| `board` | 밤의 '찾습니다' 게시판 | `inspect_board` |
| `fountain` | 분수 | `inspect_fountain` |
| `bench` | 낡은 벤치(일반 소품 — 숨김 잔향은 ch1_square_02에만 있다). `square_bench` 수집 여부로 대사 분기 | `inspect_bench` |

| 출구 | 조건 | 막혔을 때 | 다음 |
|---|---|---|---|
| `go_home` 돌아가기(어느 출구든) | 없음 | — | `leave` → **챕터 1 끝**(슬라이스 끝, 다음은 ch2_street) |

- `leave` 첫 줄 = **미수집 숨김 잔향 안내**(echo.md §5-4): `lane_poster`·`square_bench` 둘 다 수집 / 하나 / 없음 3분기. 위치는 알려 주지 않는다.

---

## 3. 잔향 8개 (echo.md §5-3 1~8행)

| id | 장면 · 마커 | 감정 | 종류 | 감지 | 퍼즐 | 난이도 · 목표 | 조각 | requires | 기억 요지 |
|---|---|---|---|---|---|---|---|---|---|
| `echo.prologue.atelier_brush` | prologue_atelier · `atelier_brush` | longing | 필수 | haneul | color_match | 1 · 30초 | 1 | — | 등 뒤에서 그림을 기다리던 누군가 |
| `echo.prologue.garden_pot` | prologue_garden · `garden_pot` | warmth | 필수 | byeol | memory_order | 1 · 30초 | 1 | — | 매일 물 주기로 한 약속 |
| `echo.ch1.atelier_easel` | ch1_atelier · `atelier_easel` | longing | 필수 | haneul | color_match | 1 · 30초 | 1 | — | "다음에 마저 그리자" |
| `echo.ch1.garden_sprinkler` | ch1_garden · `garden_sprinkler` | warmth | 필수 | byeol | memory_order | 1 · 30초 | 1 | — | 함께 들어 준 물뿌리개 |
| `echo.ch1.lane_poster` | ch1_lane · `lane_poster` | longing | 숨김 | haneul | color_match | 2 · 35초 | 1 | — | 불꽃놀이 밤, 소매를 잡던 손 |
| `echo.ch1.path_lamp` | ch1_path · `path_lamp` | warmth | 필수 | byeol | color_match | 2 · 35초 | 1 | — | 등불 들고 마중 나온 누군가, 들리지 않는 이름 |
| `echo.ch1.square_clock` | ch1_square_02 · `square_clock` | longing | 필수 | both | memory_order | 2 · 35초 | 2 | met_in_square, bond ≥ 1 | 기다린 기억 / 달려간 기억 |
| `echo.ch1.square_bench` | ch1_square_02 · `square_bench` | warmth | 숨김 | both | memory_order | 2 · 35초 | 2 | met_in_square, bond ≥ 1 | 하나뿐인 빵을 반으로 |

- 이름(i18n): 마르지 않은 붓 / 별 모양 화분 / 반쯤 그린 그림 / 작은 물뿌리개 / 빛바랜 포스터 / 길가의 등불 / 멈춘 시계탑 / 따뜻한 벤치.
- `memory_cut`은 비워 두었다(에셋 없음). 아트가 나오면 `reward.memory_cut`을 채운다.

## 4. 퍼즐 내용 요약

| 파일 | 유형 | 내용 |
|---|---|---|
| `atelier_brush.json` | CM 1 | 칸 3: 물결·해·물결 / 팔레트 물결·해 / "붓끝에 남은 오후" |
| `atelier_easel.json` | CM 1 | 칸 3: 물결·물결·해 / "반쯤 그린 그림" |
| `lane_poster.json` | CM 2 | 칸 4: 물결·해·해·물결 / 팔레트 **2색** / "여름밤 불꽃놀이" |
| `path_lamp.json` | CM 2 | 칸 4: 해·물결·해·해 / 팔레트 **2색** / "해 질 녘의 등불" |
| `garden_pot.json` | MO 1 | 씨앗을 심음 → 떡잎 두 장 → 꽃이 핌 (식물 성장) |
| `garden_sprinkler.json` | MO 1 | 빈 물뿌리개 → 가득 채워 함께 듦 → 꽃에 물을 줌 (물 양) |
| `square_clock.json` | MO 2 | 3:00 혼자 → 3:30 기다림 → 4:00 달려오는 그림자 → 4:10 나란히 둘 (시계 바늘) |
| `square_bench.json` | MO 2 | 김 나는 봉투 → 빵 하나 → 반으로 쪼갬 → 빈 봉투와 부스러기 (빵 상태) |

- `memory_order`의 순서 단서는 모두 그림 내용(식물·물·시계 바늘·빵의 상태)과 캡션에만 있다. 감정 기호는 모든 카드에 같게 붙고 순서 단서로 쓰지 않는다(echo.md §3-3). 미끼 카드는 난이도 3부터라 모두 `null`.

## 5. 상태 변화 총정리

| 무엇 | 어디서 | 누가 |
|---|---|---|
| `flag.ch1.met_in_square = true` | ch1_square `start` | 대사(`$> GameState.set_flag`) |
| `bond` → 1 | ch1_square `start` | 대사(`$> GameState.raise_bond(1)`) |
| 잔향 수집 8개 | 각 장면 | 잔향 시스템(`collect_echo`) |
| 정원 `plot_06` / `plot_07` / 하늘 줄 1칸 이상 | prologue_garden / ch1_garden / ch1_garden_02 | 정원 시스템 |
| 성장 틱 T1 | ch1_garden_02 마무리 | 정원 시스템 |
| `protect` / `heal` | **없음** — 선택지는 챕터 2부터 | |

## 6. TODO-확인 목록 (대사 파일 머리말에도 있다)

| 장면 | 항목 |
|---|---|
| prologue_atelier | 화실이 누구의 것인지·깨어나는 정황 / H.S 서명 첫 등장 위치(이 초안: 프롤로그 화실 벽의 그림) / 이름 짓는 장면의 연출 / 붓 기억 내용 |
| prologue_garden | 깨어나는 정황 / 별 화분 = 잔향 garden_pot / 이름 짓는 장면의 연출 / 화분 기억 내용 |
| prologue_door | 장소 이름 '화실 앞' / 우편함 이름표·간판이 지워져 있다는 연출 |
| prologue_gate | 장소 이름 '정원 문' / 정원에서 광장 시계탑이 보이는 지형 |
| ch1_atelier | 이젤 기억 내용 / 손이 그림을 기억한다는 연출(W-STONE 근거) |
| ch1_garden | 물뿌리개 기억 내용 / 2인용 그네 |
| ch1_lane | 장소 이름 / **신규 NPC 골목 청소부** / 사람들도 색이 언제 사라졌는지 모른다는 대사(W-COLOR) / 포스터 기억 내용 |
| ch1_path | 장소 이름 / 등불 기억 내용 / "그 이름만 들리지 않는다" W-NAME 복선이 챕터 4 독백과 맞는지 |
| ch1_stairs · ch1_market | **닮은 습관의 내용**(이 초안: 길을 고를 때 검지로 허공에 작은 동그라미 두 번 + "…이쪽.") / 장소 이름 / **신규 NPC 시장 상인** |
| ch1_square | 서로의 얼굴이 조금 보이는 연출(W-FACE 1단계 [제안]) / 계단 쪽·시장 쪽에서 들어오는 동선 |
| ch1_square_02 | 시계탑 철문 장치 / 시계·벤치 기억 내용 / `active_character` 읽기 |
| ch1_garden_02 | 서로의 습관을 알아채는 장면(위화감 3종 밖에서 더함) / 모종삽 두 개 |
| ch1_night | 장소 이름 '밤의 광장' / 둘이 밤마다 각자 화실·정원으로 돌아간다는 생활 설정 |

## 7. 미해결 질문 · 계약 제안

1. **씬 경로 규칙**: WP 지시(`<구간>/<장면id>.tscn`)와 progression.md §3·echo.md §6 [제안](`<구간>/<접두사 뺀 이름>.tscn`, 정원은 `hub/garden.tscn`)이 다르다. 정원 잔향 2개(garden_pot, garden_sprinkler)는 허브 씬을 쓰면 `location.scene`이 바뀐다. 씬 조립 전에 하나로 정해야 한다.
2. **CM 난이도 2 팔레트**: echo.md §3-2는 난이도 2에 팔레트 3감정을 요구하지만, 챕터 1까지는 감정이 2색(파랑·노랑)뿐이다(색 도입 순서 §5-4). lane_poster·path_lamp는 2색으로 두었다. 표를 "그 시점에 쓸 수 있는 감정 수까지"로 고칠지, 이 두 잔향을 난이도 1로 내릴지 정해야 한다.
3. **퍼즐 캡션의 현지화**: `game/data/puzzles/*.json`의 `caption`·`sketch`는 한국어 문자열이다(지시된 형식). UI 문자열 `tr()` 규칙과 맞추려면 캡션을 i18n 키로 바꾸거나 로컬라이즈 단계에서 추출해야 한다. 퍼즐 json 스키마(`docs/schemas/puzzle.schema.json`)와 `validate_data.py` 검사 추가도 ADR로 제안할 만하다.
4. **`GameState.active_character` 읽기**: ch1_square_02 힌트 큐가 쓴다. 공개 변수라 동작하지만 dialogue_conventions §5 읽기 표에 없다 — 표에 추가하는 ADR 제안.
5. **추가 큐**: WP 큐 계약(`start`/`inspect_`/`echo_*`/`exit_blocked`) 밖에 `leave`, `plant_done`, `coop_gate_hint_*`, `coop_gate_done`을 썼다. 씬 조립 세션이 받아들일 수 있는지 확인.
6. **신규 NPC 2명**(`lane_sweeper`, `market_vendor`)을 speakers.json·ui.csv에 추가했다. canon §3 인물 표에는 없다 — 승인 또는 교체.
7. **이름 짓기 전 줄 처리**: 화자 없는 지문으로 썼다. 대사 UI가 "???" 같은 임시 이름표를 지원하면 그쪽이 더 자연스러울 수 있다.
8. **복선의 세기**: square_clock(기다린 기억 / 달려간 기억), square_bench(큰 쪽 / 작은 쪽)는 공명 잔향의 분할 화면 특성상 "같은 기억의 두 시점"이 드러난다. 관계 호칭은 없지만 챕터 1치고 강할 수 있다 — 사람 검수 때 판단.
9. **위화감 연출 추가분**: ch1_garden_02에서 서로의 습관을 알아채는 장면은 canon의 3종 밖이다. `start` 10~13번째 줄을 빼도 흐름은 이어진다.

## 8. 다음 WP 제안

- **WP-19(챕터 통합)**: 이 문서 §2대로 씬 14개 조립. 출구 판정·큐 재생 순서(§0-2)와 이미 모은 잔향의 색 유지(§0-9)를 먼저 확인.
- **WP-21(대사 UI)**: `[#sync]` 두 가지 처리(습관 동작 / 동시 발화), `| ` 동시 발화 표시, 「」 지문 스타일.
- **WP-14/퍼즐 UI**: `game/data/puzzles/*.json` 읽기 — `color_match`의 `slots`/`palette`, `memory_order`의 `cards`(정답 순서대로 저장, 화면에서 섞기)와 `intro_cue`.
- **ADR**: 퍼즐 스키마 + 검증기, `active_character` 읽기 API, 씬 경로 규칙 확정.
