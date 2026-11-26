# 잔향 시스템 — 잔향 감지 · 공명 퍼즐 · 잔향 30개 배치

- 상태: **초안 (WP-06).** canon_v1(G0 서명 전) 기준이다. 이 문서에 나오는 수치는 모두 **[제안]**이다.
- 근거: [canon_v1.md](../bible/canon_v1.md) §2 W-ECHO·W-RES, §7 남매 상호작용, §8 감정 색 / [계획서](../plan/dev_plan_v1.md) ②-3 / [echo.schema.json](../schemas/echo.schema.json) / [art_style.md](../style/art_style.md) §3·§4
- 데이터: `game/data/echoes/<chapter>.json`(T7 작성). §5 표를 입력으로 쓴다. [예시 파일](../schemas/examples/echo.example.json)과 수치가 다르면 이 문서를 따른다.
- 함께 보는 문서: [garden.md](garden.md)(색 조각 사용처), [sibling.md](sibling.md)(공감 연결·기억 공유), [progression.md](progression.md)(장면 배치)

---

## 1. 한눈에

| 단계 | 플레이어 행동 | 결과 |
|---|---|---|
| 감지 | `echo_sense`를 누르고 있는다 | 반경 안 잔향이 감정 색 윤곽 + 기호로 맥동한다 |
| 접근 | 감지된 잔향에 다가가 `interact` | 공명 퍼즐이 열린다(퍼즐 없는 잔향은 바로 수집) |
| 공명 퍼즐 | 30~60초 퍼즐(색 맞추기 / 순서 맞추기) | 실패 없음. 목표 시간을 넘기면 힌트가 나온다 |
| 보상 | — | 색 조각(정원 씨앗) + 기억 컷 + 그 자리의 색 복원 |

---

## 2. 잔향 감지 (Echo Sense)

### 2-1. 조작과 수치

모든 값 **[제안]**.

| 항목 | 값 | 메모 |
|---|---|---|
| 입력 | `echo_sense` 누르고 있기 | 토글 방식은 접근성 옵션([controls_accessibility.md](controls_accessibility.md) §4) |
| 반경이 넓어지는 시간 | 0 → 최대 반경까지 **0.6초**(ease-out) | 누르고 있는 동안 최대 반경 유지 |
| 기본 반경 | **80 px**(16px 타일 5칸) | `ColorMaskPainter.pulse()`의 기본 `max_radius` 80과 같게 맞춤 |
| bond 보너스 | bond 0~1: **80** / 2: **88** / 3: **96** / 4: **104** px | canon §7 "협력 강화" |
| 공명 보너스 | **×1.25** — 두 사람이 **40 px** 안에 있고 bond ≥ 1 | canon W-RES "감지 반경 증가". 최대 130 px |
| 누르고 있는 동안 이동 속도 | **×0.6**(80 → 48 px/s) | 걸으며 훑는 느낌. 정지는 강요하지 않는다 |
| 숨김 잔향 감지 거리 | 현재 반경의 **60%** 안 | 숨김은 더 가까이 가야 보인다 |
| 손을 뗀 뒤 윤곽 유지 | **2.0초** 유지 + **0.5초** 페이드 | |
| 감지된 잔향 표시 | 수집 전까지 머리 위 기호 아이콘이 남는다 | 씬을 나가면 초기화 |
| 상호작용 거리 | **20 px**(잔향 `Marker2D`에서) | |
| 비용·쿨다운 | 없음 | 감지는 언제든 공짜. 탐색의 기본 동사로 둔다 |
| 사용 불가 상태 | 대사, 퍼즐, 컷신·컷인, 메뉴 | |

### 2-2. 감지 판정 규칙

1. 잔향은 `requires`(`flags`, `bond_min`)를 모두 만족할 때만 존재한다. 미충족이면 감지·상호작용 모두 안 된다.
2. `sensed_by` 판정 **[제안]**:

   | 값 | 감지 조건 |
   |---|---|
   | `haneul` | 하늘이 활성 캐릭터일 때만 감지 |
   | `byeol` | 별이 활성 캐릭터일 때만 감지 |
   | `both` | **두 사람이 같은 씬에 함께 있고 서로 64 px 안**일 때만 감지. 어느 쪽이 활성이어도 된다. 이 문서에서는 **공명 잔향**이라 부른다 |

3. 감지 안 된 잔향은 `interact`를 눌러도 반응하지 않는다. "감지 → 상호작용" 순서를 강제해 핵심 동사를 익히게 한다.
4. 거리는 캐릭터 중심 ~ 잔향 `Marker2D` 사이 직선거리. 벽은 무시한다(탑다운이라 가림 판정을 두지 않는다).
5. 숨김 잔향 중 **공명 잔향(`both`)은 표시형**이다. 두 사람이 함께 씬에 들어오면 감지 없이도 희미한 반짝임이 보인다. 나머지 숨김 잔향(8개)은 **비밀형**이라 힌트가 없다.

### 2-3. 맥동 연출

| 요소 | 사양 **[제안]** | 리듀스 모션일 때 |
|---|---|---|
| 윤곽선 | 감정 램프 `mid` 1px + 바깥 `light` 1px 글로우 | 2px 고정 윤곽 |
| 맥동 | **1.2 Hz**, 불투명도 0.55 ↔ 1.0 | 맥동 없음(불투명도 1.0) |
| 숨김 잔향 | **0.6 Hz**, 불투명도 0.35 ↔ 0.7 | 고정 0.7 |
| 감정 기호 | 잔향 위 **7×7 px** 아이콘. 감지되면 항상 표시(끌 수 없음) | 그대로 |
| 감지 파문 | 누르기 시작할 때 `ColorMaskPainter.pulse()` 1회(최대 반경 = 현재 반경, 0.6초). 원 안의 색이 잠깐 돌아왔다 사라진다 | 파문 없음 |
| 화면 | 가장자리 비네트 15% | 그대로 |
| 반경 표시 | 캐릭터 주위 1px 점선 원, 불투명도 30% | 그대로(움직임 없음) |
| 소리 | 시작음 + 낮은 지속음. 가까운 잔향일수록 지속음이 커진다. 발견 시 감정별 음정 핑 | 그대로 |

### 2-4. 공감 연결: 다른 쪽이 보는 것

canon §7 "한쪽이 감지한 잔향이 다른 쪽 화면에도 표시"를 시기별 규칙으로 바꾼다. **[제안]**

| 시기 | 조건 | 상대에게 보이는 것 | 기능 |
|---|---|---|---|
| 프롤로그~챕터 1 교대 파트 | 연출 전용 | 상대 파트가 시작될 때 직전 파트에서 감지한 잔향의 **기호가 0.5초 잔상**으로 스친다. 총 2회(`prologue_garden`, `ch1_garden`) | 없음(위화감 연출) |
| 광장 이후, bond ≥ 1 | 활성 캐릭터가 감지 중 | **상대 전용 잔향**(`sensed_by` = 상대)도 반경 안이면 **점선 윤곽 + 상대 감정 기호**로 보인다 | 상호작용 불가 — "태그 전환하라"는 신호 |
| 광장 이후, bond ≥ 1 | 비활성 캐릭터 | 비활성 캐릭터 머리 위에 작은 `!` 기호(자기 잔향이 근처에 있음) | 알림 |
| bond 4 | 두 사람이 40 px 안에서 감지 | 상대 전용 잔향도 **실선 윤곽** | 보기만 좋아짐. 상호작용은 여전히 주인만 |

### 2-5. 수집 처리 순서

1. `interact` → `puzzle.type`이 `none`이면 3으로.
2. 공명 퍼즐(§3).
3. 보상 지급(§4): 색 조각, 마스크 도장(잔향 위치, 반경 48 px) + 이 씬에 그 감정 대역 영구 추가, 기억 컷.
4. `state.echoes_collected`에 id 추가 → `echo_collected` 시그널.
5. `reward.sets_flags` 처리.
6. 공명 잔향이면: 기억 공유 분할 화면([sibling.md](sibling.md) §9) + 정원의 같은 감정 칸 성장 +1([garden.md](garden.md) §4).
7. 자동 저장(슬롯 0) **[제안]**. 수집 직후 종료해도 잃지 않게 한다.

### 2-6. 시그널 이름 제안 (WP-09에서 확정)

과거형 규칙을 따른다. 시스템 간 통신은 `EchoBus`로만 한다.

| 시그널 | 인자 | 받는 쪽 |
|---|---|---|
| `echo_sense_started` | `character: String` | 색 복원(파문), 오디오 |
| `echo_sense_ended` | `character: String` | 오디오 |
| `echo_sensed` | `echo_id: String` | UI(기호 아이콘), 오디오 |
| `echo_collected` | `echo_id: String` | GameState, 색 복원, 정원, 남매(기억 공유) |
| `puzzle_started` | `echo_id: String, type: String` | 오디오(덕킹) |
| `puzzle_finished` | `echo_id: String, hints_used: int, skipped: bool` | GameState, 플레이테스트 로그 |

---

## 3. 공명 퍼즐

### 3-1. 공통 규칙

| 규칙 | 내용 **[제안]** |
|---|---|
| 목표 시간 | 30~60초(난이도별 표 참고) |
| 실패 | **없다.** 틀린 조각은 부드럽게 튕겨 나오고 감점이 없다 |
| `time_limit_sec`의 뜻 | **목표 시간(힌트 타이머).** 넘기면 힌트 1개를 자동으로 주고 타이머를 다시 시작한다. `0` = 힌트 타이머 없음 |
| 건너뛰기 | 힌트를 2번 받은 뒤 "건너뛰기"를 고를 수 있다. 보상은 같다(접근성 우선, 미해결 질문 참고) |
| 타이머 끄기 옵션 | 자동 힌트가 꺼진다. 대신 `echo_sense`를 3초 누르면 수동 힌트 |
| 조작 | 이동 = 커서 / `interact` = 집기·놓기·확인 / `echo_sense` = 단서 다시 보기 / `tag_switch` = 2인 변형에서 쪽 바꾸기 / `pause` = 중단(처음부터 다시) |
| 화면 | 잔향 오브젝트를 확대한 패널 **320×180 px**(480×270 화면 가운데) |
| 기호 | 모든 색 조각·칸·카드에 감정 기호. 퍼즐 안에서는 **9×9 px**(최소 7×7) |

### 3-2. `color_match` — 감정 색 맞추기

잔향 그림의 빈 칸에 맞는 감정 색 조각을 채워 그림을 복원한다.

1. 칸마다 **단서 기호**(회색 윤곽 기호)가 있다. 맞는 조각 = 같은 기호를 가진 조각.
2. 화면 아래 팔레트에 감정 조각(색 + 기호)이 있다. 몇 번이든 쓸 수 있다.
3. 칸 선택 → 조각 선택 → 놓기. 틀리면 튕겨 나온다.
4. 모든 칸이 맞으면 완성. 그림 전체에 색이 번진다.
5. **기호만으로 풀린다**: 단서도 기호, 조각도 기호. 색은 같은 정보를 한 번 더 주는 보조 수단이다. 흑백 화면에서도 똑같이 풀 수 있어야 한다.

| 난이도 | 칸 수 | 단서 표시 | 팔레트 감정 수 | 목표 시간 |
|---|---|---|---|---|
| 1 | 3 | 계속 보임 | 2 | 30초 |
| 2 | 4 | 계속 보임 | 3 | 35초 |
| 3 | 5 | **잔상**: 4초 뒤 사라짐 | 4 | 45초 |
| 4 | 6 | 잔상 3초 | 5 | 50초 |
| 5 | 8 | 잔상 2초 | 5 | 60초 |

- 잔상: 단서가 사라진 뒤 `echo_sense`를 누르면 1초간 다시 보인다(쿨다운 2초). 기억력 퍼즐이지 색 구분 퍼즐이 아니다.
- 공명 잔향 + bond ≥ 2이면 **2인 변형(CM-C)**: 칸이 하늘 쪽 / 별 쪽 절반으로 나뉘고, 자기 쪽만 채울 수 있다. `tag_switch`로 번갈아 채운다.

### 3-3. `memory_order` — 기억 조각 순서 맞추기

흩어진 기억 카드를 일어난 순서대로 놓는다.

1. 시작할 때 잔향의 **울림**(지문 또는 대사 1~2줄)이 나온다. 순서의 첫 단서다.
2. 카드 = 흑백 스케치 + 감정 기호 + 짧은 캡션(난이도 4부터 캡션 없음).
3. 순서 단서는 **그림 내용**(물건 상태 변화: 씨앗 → 새싹 → 꽃, 빈 캔버스 → 밑그림 → 완성)과 울림에만 둔다. **색과 감정 기호는 순서 단서로 쓰지 않는다** → 색각과 무관하다.
4. 슬롯을 다 채우고 `interact`(확인) → 맞는 카드는 딸깍 고정, 틀린 카드는 손으로 돌아온다. 반복하면 반드시 수렴한다.
5. **미끼 카드**: 이 기억에 속하지 않는 카드 1장. 슬롯에 넣지 않고 남겨야 정답이다. 미끼는 그림 내용(다른 장소·다른 물건)으로 구분되게 그린다. 색으로만 다르면 안 된다.

| 난이도 | 카드 | 캡션 | 목표 시간 |
|---|---|---|---|
| 1 | 3 | 있음 | 30초 |
| 2 | 4 | 있음 | 35초 |
| 3 | 4 + 미끼 1 | 있음 | 45초 |
| 4 | 5 | 없음 | 50초 |
| 5 | 5 + 미끼 1 | 없음 | 60초 |

### 3-4. 변형 5종과 스코프 컷

계획서 ⑩의 "공명 퍼즐 종류 5 → 3"을 **기본 2유형 × 변형**으로 해석한다. 스키마의 `puzzle.type`은 2종(+`none`)뿐이고, 변형은 난이도·잔향 종류에서 정해진다.

| 변형 | 내용 | 첫 등장 | 컷 순서 |
|---|---|---|---|
| CM-A 기본 | 단서가 계속 보임 | 프롤로그 | 유지 |
| CM-B 잔상 | 단서가 사라짐, 감지로 다시 보기 | 챕터 2 | 유지 |
| MO-A 기본 | 순서 맞추기 | 프롤로그 | 유지 |
| MO-B 미끼 | 미끼 카드 1장 | 챕터 2 | 2순위로 자름 |
| CM-C 공명(2인) | 칸을 남매가 나눠 채움 | 챕터 3 | 1순위로 자름 |

### 3-5. 색각 이상 검증 체크리스트 (WP-14 완료 기준)

- [ ] 퍼즐 화면을 흑백으로 캡처해도 풀 수 있다.
- [ ] 퍼즐 안 기호가 9×9 px 이상이고, 흑백에서 다섯 기호의 모양이 서로 구분된다.
- [ ] 제1·2·3색맹 시뮬레이션에서도 풀린다(색각 모드는 [controls_accessibility.md](controls_accessibility.md) §5).
- [ ] 힌트·안내 문구가 색 이름만 쓰지 않는다. "파란 칸" ✗ → "물결 칸" ✓
- [ ] `memory_order`의 순서 단서가 색·기호에 의존하지 않는다.

---

## 4. 보상

| 보상 | 필수 잔향 | 숨김 잔향 | 공명 잔향(`both`) |
|---|---|---|---|
| 색 조각 | **1** — 감지한 사람의 주머니로 | **1** — 감지한 사람 | **2** — 하늘 1 + 별 1 |
| 기억 컷 | **240×135 px** 스케치 컷(감정 색 1개 + 중립색) | **120×68 px** 소형 컷 또는 글 컷 | 분할 화면 기억 공유([sibling.md](sibling.md) §9) |
| 국소 색 복원 | 마스크 도장 반경 **48 px** + 이 씬에 감정 대역 영구 추가 | 같음 | 같음 |
| 전역 채도 | 챕터 진행에 반영([progression.md](progression.md) §4) | 영향 없음 | 필수일 때만 반영 |
| 정원 | 씨앗 | 씨앗 | 씨앗 + 같은 감정 칸 성장 +1 |

- 색 조각 합계 **39개**: 하늘 20(하늘 전용 11 + 공명 9), 별 19(별 전용 10 + 공명 9). 그중 필수 잔향에서 나오는 조각은 하늘 11, 별 12.
- 스키마 대응: `reward.color_shards`에 위 숫자(1 또는 2)를 쓴다. 공명 잔향은 반드시 2(짝수)다.
- 기억 컷 크기를 작게 잡은 이유: 30장을 혼자 그려야 한다. 필수 18장만 정식 컷, 숨김 12장은 소형 컷으로 범위를 줄인다.

---

## 5. 잔향 30개 배치

### 5-1. 챕터 × 감정 (필수 / 숨김)

| 챕터 | 그리움 `longing` | 온기 `warmth` | 꿈 `dream` | 용기 `courage` | 치유 `healing` | 필수 | 숨김 | 계 |
|---|---|---|---|---|---|---|---|---|
| prologue | 1 / 0 | 1 / 0 | — | — | — | 2 | 0 | 2 |
| ch1 | 2 / 1 | 2 / 1 | — | — | — | 4 | 2 | 6 |
| ch2 | 0 / 1 | 0 / 1 | 2 / 1 | 2 / 0 | — | 4 | 3 | 7 |
| ch3 | — | — | 1 / 1 | 1 / 1 | 2 / 1 | 4 | 3 | 7 |
| ch4 | — | 1 / 0 | — | 0 / 1 | 2 / 1 | 3 | 2 | 5 |
| ch5 | 1 / 1 | 0 / 1 | — | — | — | 1 | 2 | 3 |
| **계** | **4 / 3** | **4 / 3** | **3 / 2** | **3 / 2** | **4 / 2** | **18** | **12** | **30** |

감정 이름 꿈·용기·치유는 임시다(canon D8, **TODO-확인**). 이 표는 id만 쓰므로 이름이 바뀌어도 그대로 쓸 수 있다.

### 5-2. 챕터 × 감지 주체

| 챕터 | 하늘 `haneul` | 별 `byeol` | 공명 `both` (필수 / 숨김) |
|---|---|---|---|
| prologue | 1 | 1 | 0 |
| ch1 | 2 | 2 | 2 (1 / 1) |
| ch2 | 3 | 2 | 2 (1 / 1) |
| ch3 | 2 | 3 | 2 (1 / 1) |
| ch4 | 2 | 1 | 2 (1 / 1) |
| ch5 | 1 | 1 | 1 (1 / 0) |
| **계** | **11** | **10** | **9 (5 / 4)** |

### 5-3. 전체 목록

id 형식은 `echo.<chapter>.<slug>`. slug는 **자리표시**다. 물건의 이야기는 원작 확인 후 정한다(**TODO-확인**). `name_key`는 id와 같은 문자열을 쓴다(진실 공개 후에만 보이는 이름이면 `truth.` 접두사).

| # | id | 감정 | 종류 | 감지 | 장면 | 퍼즐 | 난이도 | 목표(초) | 조건 `requires` | 조각 |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | `echo.prologue.atelier_brush` | longing | 필수 | haneul | `prologue_atelier` | color_match | 1 | 30 | — | 하1 |
| 2 | `echo.prologue.garden_pot` | warmth | 필수 | byeol | `prologue_garden` | memory_order | 1 | 30 | — | 별1 |
| 3 | `echo.ch1.atelier_easel` | longing | 필수 | haneul | `ch1_atelier` | color_match | 1 | 30 | — | 하1 |
| 4 | `echo.ch1.garden_sprinkler` | warmth | 필수 | byeol | `ch1_garden` | memory_order | 1 | 30 | — | 별1 |
| 5 | `echo.ch1.lane_poster` | longing | 숨김 | haneul | `ch1_lane` | color_match | 2 | 35 | — | 하1 |
| 6 | `echo.ch1.path_lamp` | warmth | 필수 | byeol | `ch1_path` | color_match | 2 | 35 | — | 별1 |
| 7 | `echo.ch1.square_clock` | longing | 필수 | both | `ch1_square_02` | memory_order | 2 | 35 | met_in_square, bond ≥ 1 | 하1 별1 |
| 8 | `echo.ch1.square_bench` | warmth | 숨김 | both | `ch1_square_02` | memory_order | 2 | 35 | met_in_square, bond ≥ 1 | 하1 별1 |
| 9 | `echo.ch2.cafe_cup` | courage | 필수 | haneul | `ch2_cafe` | color_match | 2 | 35 | — | 하1 |
| 10 | `echo.ch2.cafe_window` | warmth | 숨김 | byeol | `ch2_cafe_02` | memory_order | 3 | 45 | — | 별1 |
| 11 | `echo.ch2.park_carousel` | dream | 필수 | byeol | `ch2_park` | memory_order | 2 | 35 | — | 별1 |
| 12 | `echo.ch2.park_mirror` | dream | 필수 | haneul | `ch2_park_02` | color_match | 3 | 45 | — | 하1 |
| 13 | `echo.ch2.park_ticket` | dream | 숨김 | both | `ch2_park_03` | color_match | 3 | 45 | bond ≥ 1 | 하1 별1 |
| 14 | `echo.ch2.attic_box` | courage | 필수 | both | `ch2_attic` | memory_order | 3 | 45 | bond ≥ 1 | 하1 별1 |
| 15 | `echo.ch2.attic_sketch` | longing | 숨김 | haneul | `ch2_attic` | color_match | 3 | 45 | — | 하1 |
| 16 | `echo.ch3.studio_canvas` | healing | 필수 | haneul | `ch3_studio` | color_match | 3 | 45 | — | 하1 |
| 17 | `echo.ch3.studio_palette` | dream | 숨김 | haneul | `ch3_studio` | memory_order | 4 | 50 | — | 하1 |
| 18 | `echo.ch3.room_mobile` | healing | 필수 | byeol | `ch3_room` | memory_order | 3 | 45 | — | 별1 |
| 19 | `echo.ch3.room_lamp` | healing | 숨김 | byeol | `ch3_room_02` | color_match | 4 | 50 | — | 별1 |
| 20 | `echo.ch3.bridge_kite` | courage | 필수 | byeol | `ch3_bridge` | color_match | 3 | 45 | — | 별1 |
| 21 | `echo.ch3.hill_bench` | courage | 숨김 | both | `ch3_hill` | memory_order | 4 | 50 | bond ≥ 2 | 하1 별1 |
| 22 | `echo.ch3.artwork_sign` | dream | 필수 | both | `ch3_artwork` | color_match (CM-C) | 4 | 50 | bond ≥ 2 | 하1 별1 |
| 23 | `echo.ch4.photo_frame` | warmth | 필수 | both | `ch4_photo` | memory_order | 4 | 50 | family_flower_bloomed, bond ≥ 3 | 하1 별1 |
| 24 | `echo.ch4.conflict_a` | healing | 필수 | haneul | `ch4_conflict_01` | color_match | 4 | 50 | — | 하1 |
| 25 | `echo.ch4.share_window` | courage | 숨김 | both | `ch4_conflict_02` | color_match | 5 | 60 | bond ≥ 3 | 하1 별1 |
| 26 | `echo.ch4.conflict_c` | healing | 필수 | byeol | `ch4_conflict_03` | memory_order | 4 | 50 | — | 별1 |
| 27 | `echo.ch4.town_bell` | healing | 숨김 | haneul | `ch4_town` | memory_order | 5 | 60 | truth_revealed | 하1 |
| 28 | `echo.ch5.atelier_window` | longing | 숨김 | haneul | `ch5_atelier` | color_match | 5 | 60 | — | 하1 |
| 29 | `echo.ch5.square_fountain` | warmth | 숨김 | byeol | `ch5_square` | memory_order | 5 | 60 | — | 별1 |
| 30 | `echo.ch5.last_light` | longing | 필수 | both | `ch5_echo` | none | — | 0 | storm_done | 하1 별1 |

조건 칸의 약어: `met_in_square` = `flag.ch1.met_in_square`, `family_flower_bloomed` = `flag.ch4.family_flower_bloomed`, `truth_revealed` = `flag.ch4.truth_revealed`, `storm_done` = `flag.ch4.storm_done`. 모두 [flags.json](../../game/data/flags.json)에 있는 플래그다.

- 퍼즐 수: `color_match` 15, `memory_order` 14, `none` 1. 다 모으면 퍼즐 시간은 약 22분.
- 1·2번 잔향은 원작 단서(별 화분, H.S 서명)와 연결할 수 있다. 연결 여부와 H.S 서명의 첫 등장 위치는 **TODO-확인**.

### 5-4. 배치 원칙

| 원칙 | 이유 |
|---|---|
| 5색이 **챕터 3까지 필수 잔향으로** 모두 나온다(초록은 `ch3_studio`에서 처음) | 챕터 4의 '가족의 꽃'(5색)이 진행 필수 트리거라서. 숨김 잔향에 의존하면 막힐 수 있다 |
| 색 도입 순서: 프롤로그 파랑·노랑 → 챕터 2 보라·주황 → 챕터 3 초록 | GRIS식 "색이 하나씩 돌아온다". 감정 이름이 미확정이라 장소와 감정의 의미 연결은 하지 않았다 |
| 난이도는 챕터마다 오르고, 숨김은 같은 챕터 필수보다 +1 | 학습 곡선 |
| 장면당 잔향 최대 2개 | 화면 하나에 감정 색이 너무 많이 번지지 않게(art_style §5) |
| 숨김 12 = 표시형 4(공명 잔향, 반짝임 힌트) + 비밀형 8 | bond 4 조건([endings.md](endings.md) §4)에 쓰는 공명 잔향은 찾기 쉽게 |
| 챕터 5 숨김 잔향 2개는 `ch5_garden`보다 앞에 둔다 | 무지개 꽃 조건(숨김 12개)을 정원 방문 전에 채울 수 있어야 한다 |
| 공명 잔향의 `bond_min`은 그 챕터에서 **이미 보장된** bond 값만 쓴다 | 필수 잔향이 조건부 bond 4에 막히지 않게 |
| 각 챕터 마지막 장면에서 "이 챕터에서 아직 느끼지 못한 잔향 n개"를 알려 준다(위치는 안 알려 줌) | 1회차 기적 엔딩을 노리는 플레이어를 위한 최소 안내 |

---

## 6. 데이터 작성 메모 (T7용)

`game/data/echoes/ch2.json`의 한 항목 예시(스키마 형식). 장면 경로는 [progression.md](progression.md) §3의 장면 id를 따른다.

```json
{
  "id": "echo.ch2.park_ticket",
  "emotion": "dream",
  "kind": "hidden",
  "name_key": "echo.ch2.park_ticket",
  "location": { "scene": "res://game/scenes/ch2/park_03.tscn", "marker": "EchoTicket" },
  "sensed_by": "both",
  "requires": { "bond_min": 1 },
  "puzzle": { "type": "color_match", "time_limit_sec": 45, "difficulty": 3 },
  "reward": { "color_shards": 2, "memory_cut": "res://game/art/vfx/memory_cuts/ch2_park_ticket.tres" },
  "notes": "공명 잔향(표시형). 수집 시 기억 공유 분할 화면."
}
```

- `.tscn` 파일 이름은 장면 id에서 챕터 접두사를 뺀 것으로 제안한다(`ch2_park_03` → `res://game/scenes/ch2/park_03.tscn`). **[제안]**

---

## 계약 변경 제안

아래는 스키마·공유 데이터를 고쳐야 하는 항목이다. 이 문서는 고치지 않았다. 통합 담당 세션이 `docs/adr/`에 제안서로 올린다.

| # | 대상 | 제안 | 종류 |
|---|---|---|---|
| E1 | `echo.schema.json` `sensed_by` 설명 | `both` = "두 사람이 같은 씬, 64 px 안에 함께 있을 때만 감지(어느 쪽이 활성이어도 됨)"라고 명시. 지금은 예시 파일 notes에만 암시돼 있다 | 설명 변경 |
| E2 | `echo.schema.json` `puzzle.time_limit_sec` 설명 | "목표 시간(힌트 타이머). 넘겨도 실패하지 않는다. 0 = 힌트 타이머 없음"이라고 명시 | 설명 변경 |
| E3 | `echo.schema.json` | 선택 필드 `faces: [speaker key]` 추가. canon W-FACE의 "그 인물과 관련된 잔향 1개 이상 → 얼굴 1단계"를 판정하려면 잔향과 인물의 연결이 데이터에 있어야 하는데 지금은 없다 | 스키마 추가 (ADR) |
| E4 | `tools/validate_data.py` + 스키마 설명 | 색 조각 귀속 규칙: 조각은 `sensed_by`의 주머니로 가고, `both`는 반반 나눈다. 그래서 `both`의 `color_shards`는 짝수여야 한다 — 검증 규칙 추가 | 검증 규칙 |
| E5 | WP-09 `EchoBus` | §2-6의 시그널 이름·인자를 계약 후보로 검토 | 인터페이스 (WP-09) |
| E6 | `flags.json` variables | 파생 변수 `shared_echo_found`(수집한 공명 잔향 수) 추가. 자세한 내용은 [endings.md](endings.md) 계약 변경 제안 N1 | 데이터 추가 |
