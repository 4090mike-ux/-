# 색의 정원 — 심기 · 성장 · 조합 · 가족의 꽃 · 무지개 꽃

- 상태: **초안 (WP-06).** 수치는 모두 **[제안]**이다.
- 근거: [canon_v1.md](../bible/canon_v1.md) §2 W-RES, §8(5색 → 가족의 꽃, 무지개 꽃, 파랑:초록 비율) / [계획서](../plan/dev_plan_v1.md) ②-3 "색의 정원" / [save.schema.json](../schemas/save.schema.json) `state.garden`
- 구현: WP-20(정원 v1, `game/systems/garden/`). 조합표는 데이터로 둔다(§5, 계약 변경 제안 G1).
- 함께 보는 문서: [echo.md](echo.md) §4(색 조각 지급), [progression.md](progression.md)(정원 방문 장면)

---

## 1. 한눈에

| 항목 | 규칙 |
|---|---|
| 씨앗 | 색 조각 1개 = 씨앗 1개. 잔향을 감지한 사람의 주머니로 들어간다 |
| 칸 | 10칸: 하늘 줄 5 + 별 줄 5. 각자 **자기 줄에만** 심는다 |
| 성장 | 0~5. **실시간이 아니라** 정원 방문을 마칠 때마다 +1(챕터 진행) |
| 공명 | 공명 잔향 수집 시 같은 감정 칸 +1, 챕터 3 '정원 공명' 이벤트 때 모든 칸 +1 |
| 조합 | 위아래 짝 칸(하늘 칸 + 별 칸)이 둘 다 3 이상이면 조합 꽃이 핀다(데이터 표) |
| 가족의 꽃 | 5색이 각각 성장 2 이상 → 챕터 4 정원에서 개화 → `flag.ch4.family_flower_bloomed` |
| 무지개 꽃 | 가족의 꽃 + 숨김 잔향 12개 → 챕터 5 정원에서 함께 심어 개화 → `flag.ch5.rainbow_flower_bloomed` |
| 마음 화단 | 가장자리 12칸. 파랑:초록 봉오리 비율로 `protect`:`heal`을 은근히 보여 준다 |

---

## 2. 배치

```
            [ 마음 화단 12칸 — 파랑(물결)·초록(잎) 봉오리 ]
  ┌──────────────────────────────────────────────────────┐
  │  하늘 줄   plot_01   plot_02   plot_03   plot_04   plot_05  │
  │                      ( 가운데 특별 화분 )                     │
  │  별 줄     plot_06   plot_07   plot_08   plot_09   plot_10  │
  └──────────────────────────────────────────────────────┘
  짝 칸(세로): 01-06 · 02-07 · 03-08 · 04-09 · 05-10
```

| 요소 | 개수 | 주인 | 저장 |
|---|---|---|---|
| 하늘 줄 | 5 (`plot_01`~`plot_05`) | 하늘 | `state.garden.plots[]` |
| 별 줄 | 5 (`plot_06`~`plot_10`) | 별 | `state.garden.plots[]` |
| 가운데 특별 화분 | 1 | 둘 다 | 칸이 아니다. 핀 꽃은 `bloomed`에 `family_flower`, `rainbow_flower`로 기록 |
| 마음 화단 | 12 | 없음 | 저장 안 함. `protect`/`heal`에서 계산 |

- 정원은 별이 시작하는 장소다(canon §7). 별은 프롤로그부터, 하늘은 광장에서 만난 뒤 첫 방문(`ch1_garden_02`)부터 쓸 수 있다.
- 정원은 **정해진 방문 장면**에서만 들어간다(자유 이동 없음). 범위를 줄이려는 결정이다. **[제안]**

---

## 3. 씨앗과 심기

### 3-1. 주머니

| 규칙 | 내용 |
|---|---|
| 들어오는 조각 | `sensed_by = haneul` → 하늘 1, `byeol` → 별 1, `both` → 하늘 1 + 별 1 ([echo.md](echo.md) §4) |
| 주머니 크기 | 제한 없음 |
| 저장 | **하지 않는다.** 주머니 = (수집한 잔향에서 받은 조각) − (지금 자기 줄에 심긴 칸). 둘 다 세이브에 있는 값이라 계산된다 |
| 합계 | 하늘 20, 별 19. 필수 잔향만 모으면 하늘 11, 별 12 |

### 3-2. 심기·다시 심기

| 행동 | 조작 | 비용 | 결과 |
|---|---|---|---|
| 심기 | 빈 칸(자기 줄)에서 `interact` → 주머니에서 감정 고르기 | 그 감정 조각 1 | 성장 0 |
| 다시 심기 | 심긴 칸에서 `interact` → "바꾸기" | 없음. 뽑은 조각은 주머니로 돌아온다 | 새 감정, 성장 0, `resonance_bonus` 0 |
| 상대 줄 | 직접 못 심는다 | — | `tag_switch`로 바꿔서 심는다 |

- 다시 심기를 공짜로 둔 이유: 조합을 실험해도 손해가 없고, 주머니를 저장하지 않아도 계산이 맞는다.
- 선택 UI: 칸 위에 주머니의 감정 아이콘(색 + 기호 + 개수)을 둥글게 띄운다.

---

## 4. 성장

### 4-1. 단계

| 성장 | 이름 | 모습 | 색 |
|---|---|---|---|
| 0 | 씨앗 | 흙 둔덕 + 감정 기호 팻말 | 흑백 |
| 1 | 새싹 | 떡잎 | 흑백 |
| 2 | 줄기 | 잎 2~3장 | 흑백 + 잎끝만 감정 색 |
| 3 | 봉오리 | 봉오리 | 감정 색 |
| 4 | 개화 | 꽃 | 감정 색 |
| 5 | 만개 | 꽃 + 반짝임 | 감정 색 + 주변 마스크 반경 24 px 복원 |

### 4-2. 성장 틱 (챕터 진행)

정원 방문을 마칠 때 심긴 모든 칸이 +1 된다(최대 5). 방문 중에 심은 칸도 그 방문의 틱을 받는다.

| 틱 | 장면 (방문을 마칠 때) | 챕터 |
|---|---|---|
| T1 | `ch1_garden_02` | 1 |
| T2 | `ch2_garden` | 2 |
| T3 | `ch2_garden_02` | 2 |
| T4 | `ch3_garden` | 3 |
| T5 | `ch3_garden_02` | 3 |
| T6 | `ch4_garden` | 4 |
| T7 | `ch5_garden` | 5 |

`prologue_garden`, `ch1_garden`(별 파트)은 심기만 하고 틱은 없다.

### 4-3. 공명 +1 (canon W-RES)

| 공명 이벤트 | 대상 | 횟수 |
|---|---|---|
| 공명 잔향(`both`) 수집 | 그 잔향과 **같은 감정**의 모든 칸 +1 | 공명 잔향 9개 → 최대 9회 |
| `ev_ch3_garden_resonance`(`ch3_garden_02`) | **모든** 칸 +1 | 1회 |

- 성장 상한은 5다. 넘치는 공명은 버린다.
- 저장: `growth` = 총합(틱 + 공명), `resonance_bonus` = 그중 공명으로 얻은 양(연출·로그용). 조건 판정은 `growth`만 본다.

### 4-4. 방문 흐름

| 순서 | 내용 |
|---|---|
| 1 | 진입. 이번 방문의 이야기(대사) |
| 2 | 자유 시간: 심기, 다시 심기, 조합·마음 화단 구경 |
| 3 | "정원 나가기"를 고르면 **마무리**: ① 자동 심기(`ch3_garden_02`만) → ② 공명 이벤트(`ch3_garden_02`만) → ③ 성장 틱 → ④ 특별 꽃 판정(`ch4_garden`, `ch5_garden`) → ⑤ 새 조합 개화 연출 → 퇴장 |

조작 시간은 방문당 2~4분. 대사를 합친 장면 길이는 [progression.md](progression.md) §3.

---

## 5. 조합표 (데이터 주도)

### 5-1. 규칙

1. 짝 칸(`plot_0N`과 `plot_0(N+5)`)의 두 감정이 조합표에 있고 **둘 다 성장 3 이상**이면 그 사이에 조합 꽃이 핀다.
2. 감정 순서는 따지지 않는다. 짝 칸은 항상 하늘 칸 + 별 칸이라 "남매가 각자 심은 것"이 자동으로 조건이 된다.
3. 한 번 핀 조합은 `bloomed`에 영구 기록된다(정원 도감). 나중에 다시 심어도 기록은 남는다.
4. 효과: **보기용 + 도감 + 첫 개화 때 남매 대화 1개.** 성향·엔딩에 영향을 주지 않는다(밸런스를 단순하게).

### 5-2. 표

| id | 감정 A | 감정 B | 이름(가제) | MVP |
|---|---|---|---|---|
| `sprout_together` | longing | warmth | 함께의 새싹 (계획서 예시) | ✓ |
| `night_wave` | longing | dream | 밤물결 꽃 | |
| `lighthouse` | longing | courage | 등대 꽃 | |
| `sea_leaf` | longing | healing | 바다 잎 | ✓ |
| `daydream` | warmth | dream | 낮꿈 꽃 | ✓ |
| `sunset` | warmth | courage | 노을 꽃 | ✓ |
| `sunlit_vine` | warmth | healing | 햇살 덩굴 | |
| `flame_star` | dream | courage | 불꽃별 | |
| `forest_star` | dream | healing | 숲별 꽃 | |
| `new_spring` | courage | healing | 새봄 꽃 | ✓ |
| `twin_longing` ~ `twin_healing` (5개) | 같은 감정 | 같은 감정 | 닮은 꽃 (남매의 '닮은 습관'과 연결) | |

- 총 15개. **MVP 5개**(✓)는 감정마다 최소 1번 이상 쓰인다. 계획서 ⑩ 스코프 컷 4순위("정원 조합 수")에 걸리면 MVP만 남긴다.
- 조합 이름은 `garden.combo.<id>` i18n 키로 쓴다. 이름은 가제다.

### 5-3. 데이터 파일 초안 (`game/data/garden.json`, 계약 변경 제안 G1)

```json
{
  "schema_version": 1,
  "plots": [
    { "id": "plot_01", "owner": "haneul", "col": 1 },
    { "id": "plot_06", "owner": "byeol", "col": 1 }
  ],
  "growth": {
    "max": 5,
    "tick_scenes": ["ch1_garden_02", "ch2_garden", "ch2_garden_02", "ch3_garden", "ch3_garden_02", "ch4_garden", "ch5_garden"],
    "resonance_step": 1
  },
  "combos": [
    { "id": "sprout_together", "name_key": "garden.combo.sprout_together", "emotions": ["longing", "warmth"], "min_growth": 3, "mvp": true }
  ],
  "special": {
    "family_flower": { "distinct_emotions": 5, "min_growth": 2, "check_scene": "ch4_garden", "sets_flag": "flag.ch4.family_flower_bloomed" },
    "rainbow_flower": { "requires_flags": ["flag.ch4.family_flower_bloomed"], "hidden_echo_found": 12, "check_scene": "ch5_garden", "sets_flag": "flag.ch5.rainbow_flower_bloomed" }
  },
  "heart_bed": { "slots": 12, "protect_emotion": "longing", "heal_emotion": "healing", "first_scene": "ch2_garden" }
}
```

---

## 6. 가족의 꽃 (챕터 4 트리거)

| 항목 | 내용 |
|---|---|
| 조건 | 정원 전체에서 **서로 다른 5감정**이 각각 1칸 이상, 그 칸의 성장 **2 이상** |
| 판정 | `ch4_garden` 방문 마무리 ④(T6 틱 다음) |
| 결과 | 가운데 특별 화분에 개화 → 이벤트 `ev_ch4_family_flower` → `flag.ch4.family_flower_bloomed = true`, `bloomed`에 `family_flower` 추가 |
| 이어지는 것 | 가족사진 잔향(`echo.ch4.photo_frame`)의 `requires` 해금 → 챕터 4 진행 |
| 연출 | 5색이 차례로 가운데로 모인다. 정원 전체 전역 채도 순간 1.0 → 원래 값(1.5초) |

### 6-1. 막힘 방지

가족의 꽃은 **진행 필수**라서 정원을 대충 해도 반드시 피어야 한다.

1. 5색은 챕터 3까지 필수 잔향으로 모두 들어온다([echo.md](echo.md) §5-4).
2. **자동 심기**(`ch3_garden_02` 마무리 ①): 주머니에 있는데 정원 어디에도 없는 감정이 있으면, 그 조각을 가진 쪽이 혼잣말 한 줄과 함께 자동으로 심는다. 그 줄이 꽉 찼으면 **같은 감정이 두 칸 이상인 칸 중 성장이 가장 낮은 칸**을 바꾼다.
3. 최악의 경우(자동 심기) 계산: 성장 0 → T5 1 → T6 2 → 조건 충족.
4. 버그 대비: 그래도 조건이 안 맞으면 `ch4_garden`에서 부족한 색을 성장 2로 채워 개화시키고 경고 로그를 남긴다(플레이어는 모름).

---

## 7. 무지개 꽃 (기적 엔딩 조건)

| 항목 | 내용 |
|---|---|
| 조건 | `flag.ch4.family_flower_bloomed` + `hidden_echo_found == 12` |
| 판정 | `ch5_garden` 진입 시. 조건이 맞으면 가운데 화분 옆에 **무지개 씨앗**이 나타난다(숨김 잔향 12개의 잔광이 모인 것) |
| 심기 | 함께 심는 짧은 동시 행동: 한 사람이 씨앗을 들고(`interact`) → `tag_switch` → 다른 사람이 심는다(`interact`) |
| 결과 | 틱과 무관하게 **즉시 개화** → 이벤트 `ev_ch5_rainbow_flower` → `flag.ch5.rainbow_flower_bloomed = true`, `bloomed`에 `rainbow_flower` 추가 |
| 신규 색 | 5감정 색 + 예약된 **빨강 대역**(art_style §3 규칙 4)이 처음으로 쓰인다 |
| 조건 미충족 | 씨앗이 나타나지 않는다. 안내 문구도 없다(히든) |

- 성장 수치를 조건에 넣지 않은 이유: 숨김 잔향을 다 모은 플레이어가 정원 관리 때문에 기적 엔딩을 놓치지 않게 하려는 것이다.
- 챕터 5 숨김 잔향 2개는 `ch5_garden`보다 앞 장면에 있다.

---

## 8. 마음 화단 — 파랑:초록 = protect:heal

canon §8 "정원의 꽃 색 비율 파랑 : 초록으로 현재 성향을 은근히 보여 준다"의 구현이다.

| 항목 | 규칙 |
|---|---|
| 위치 | 정원 가장자리 12칸. 플레이어가 심지 않는다 |
| 첫 등장 | `ch2_garden`(성향 선택지가 시작된 뒤 첫 방문) |
| 계산 | `protect + heal == 0`이면 12칸 모두 무채색 봉오리. 아니면 `파랑 = round_half_up(12 × protect / (protect + heal))`, `초록 = 12 − 파랑` |
| 배치 | 파랑은 하늘 줄 쪽(왼쪽)부터, 초록은 별 줄 쪽(오른쪽)부터 채운다 |
| 표시 | 파랑 = 그리움 색 + 물결 기호, 초록 = 치유 색 + 잎 기호 (기호 항상 표시) |
| 갱신 | 정원에 들어올 때마다 다시 계산. 바뀐 칸만 피고 지는 연출(0.5초) |
| 숫자 UI | 없다. 대사로도 수치를 말하지 않는다 |

| protect | heal | 파랑 | 초록 | `lean()` |
|---|---|---|---|---|
| 0 | 0 | 0 | 0 (무채색 12) | balanced |
| 3 | 1 | 9 | 3 | balanced (차이 2) |
| 8 | 8 | 6 | 6 | balanced |
| 11 | 13 | 6 | 6 | balanced |
| 21 | 7 | 9 | 3 | protect |
| 8 | 20 | 3 | 9 | heal |

- 비율 방식이라 초반(합계가 작을 때)에는 한쪽으로 크게 기울어 보인다. 후반에는 차이 2 이내면 거의 6:6이 된다. **[대안]** 차이 방식(`파랑 = clamp(6 + protect − heal, 0, 12)`)은 엔딩 구간과 정확히 맞지만 canon 문구(비율)와 다르다. 플레이테스트에서 비교한다.

---

## 9. 성장 예시 (최소 보장 계산)

전형적인 플레이. 공명 잔향 보너스는 빼고 계산했다(최소치).

| 칸 | 심은 곳 | T1 | T2 | T3 | T4 | 공명 + T5 | T6 | T7 |
|---|---|---|---|---|---|---|---|---|
| `plot_06` 별·온기 | `prologue_garden` | 1 | 2 | 3 | 4 | 5 | 5 | 5 |
| `plot_07` 별·온기 | `ch1_garden` | 1 | 2 | 3 | 4 | 5 | 5 | 5 |
| `plot_01` 하늘·그리움 | `ch1_garden_02` | 1 | 2 | 3 | 4 | 5 | 5 | 5 |
| `plot_02` 하늘·용기 | `ch2_garden` | — | 1 | 2 | 3 | 5 | 5 | 5 |
| `plot_09` 별·꿈 | `ch2_garden_02` | — | — | 1 | 2 | 4 | 5 | 5 |
| `plot_03` 하늘·치유 | `ch3_garden` | — | — | — | 1 | 3 | 4 | 5 |
| (최악) 자동 심기·치유 | `ch3_garden_02` 마무리 | — | — | — | — | 1 | **2** | 3 |

- `ch4_garden` 판정(T6 뒤): 5감정 모두 2 이상 → 가족의 꽃 개화.
- 조합: `plot_01`+`plot_06`(그리움+온기) = 함께의 새싹이 T3(`ch2_garden_02`)에 처음 핀다. `plot_02`+`plot_07`(용기+온기) = 노을 꽃은 T4.

---

## 10. 세이브 대응

| 저장 필드 (`state.garden`) | 뜻 |
|---|---|
| `plots[].id` | `plot_01`~`plot_10`. 01~05 하늘 줄, 06~10 별 줄 |
| `plots[].planted_by` | 줄 주인과 같아야 한다(검증 규칙 후보) |
| `plots[].emotion` | 심은 감정 |
| `plots[].growth` | 0~5. 틱 + 공명 총합 |
| `plots[].resonance_bonus` | `growth` 중 공명으로 얻은 양 |
| `bloomed` | 핀 조합 id, `family_flower`, `rainbow_flower`. 한 번 피면 계속 기록 |
| (주머니) | 저장하지 않음(§3-1) |
| (마음 화단) | 저장하지 않음(§8) |

---

## 계약 변경 제안

| # | 대상 | 제안 | 종류 |
|---|---|---|---|
| G1 | `game/data/garden.json` + `docs/schemas/garden.schema.json` 신설 | 칸 배치·틱 장면·조합표·특별 꽃 조건·마음 화단을 데이터로 둔다(§5-3). 계획서 WP-20 완료 기준 "조합표 데이터 주도"를 맞추려면 필요. `game/data/` 바로 아래는 공유 데이터라 ownership.md에 주인(T3 정원 또는 T7)을 정해야 한다 | 새 계약 (ADR) |
| G2 | `docs/ownership.md` | 정원 허브 씬 `res://game/scenes/hub/garden.tscn`을 여러 챕터가 같이 쓴다. 지금 표에는 `game/scenes/hub/`가 없다 → T3 챕터 통합 경로에 추가 제안. 정원 방문 대사는 챕터 폴더(`game/dialogue/ch2/ch2_garden.dialogue`)에 둔다 | 소유권 추가 |
| G3 | `save.schema.json` `garden.plots` 설명 | `growth` = 틱 + 공명 총합(조건 판정용), `resonance_bonus` = 그중 공명분이라고 명시. 지금은 둘의 관계가 정의돼 있지 않다 | 설명 변경 |
| G4 | `flags.json` `set_by` 문자열 | `flag.ch4.family_flower_bloomed`의 `set_by`를 `ev_ch4_family_flower`, `flag.ch5.rainbow_flower_bloomed`를 `ev_ch5_rainbow_flower`로 바꾼다(지금은 "garden: 5색 조합 완성" 같은 설명문). 기존 항목 수정이라 ADR | 데이터 수정 (ADR) |
| G5 | `tools/validate_data.py` | `plots[].planted_by`가 칸 번호의 줄 주인과 같은지 검사 | 검증 규칙 |
