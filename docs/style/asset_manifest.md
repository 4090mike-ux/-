# 에셋 목록 — 버티컬 슬라이스 (프롤로그 + 챕터 1)

- 상태: **초안 (WP-18, WP-18b 슬라이스 소품 보강).** 아트 스타일 승인(사람, 위임 금지) 전이다. 승인 전까지 모든 그림은 바뀔 수 있다.
- 만든 방법: Claude 가 **코드로** 그렸다(`tools/pixelart/`). 이미지 생성 AI 는 쓰지 않았다. 원본 = 파이썬 코드(ASCII 격자 + 도형). `.aseprite` 원본은 없다.
- 공개: [docs/ai_usage.md](../ai_usage.md)에 기록(출시물 포함, 공개 대상 예).

## 다시 만들기

```bash
pip install -r tools/requirements.txt          # Pillow>=11
python tools/pixelart/build_all.py             # 아래 PNG·JSON 전부 (결정적: 몇 번을 돌려도 같은 파일)
python tools/pixelart/build_all.py --only bg   # 묶음만: char, portrait, npc, props, bg
python tools/pixelart/check_art.py             # 팔레트·감정 색 배치·배경 메타데이터·슬라이스 조사 지점·철문 퍼즐 검사 (오류면 종료 코드 1)
python tools/pixelart/preview.py               # 6배 확대·흑백 미리보기 + 배경 목업(디버그 판: 조사 지점·반경·이름 표시) → tools/pixelart/_preview/ (커밋 안 함)
```

PNG 를 손으로 고치지 않는다. 고칠 때는 코드를 고치고 다시 만든다(손으로 고친 PNG 는 다음 빌드 때 덮어써진다).

## 1. 공통 규칙

| 항목 | 규칙 | 근거 |
|---|---|---|
| 색 | [palette.gpl](palette.gpl) 35색만. 반투명 픽셀 없음(알파 0 또는 255) | art_style §3, `check_art.py` |
| 감정 색 | 잔향 소품 스프라이트에만. 주인공은 정체성 포인트 하나씩만(하늘 = 앞치마 파란 물감 자국, 별 = 노란 별 머리핀). **배경·NPC 는 중립색만** | art_style §3·§5, `check_art.py` |
| 외곽선 | 바깥 1px `neutral-ink` | art_style §5 |
| 흑백 | 모든 그림은 Rec.709 휘도(셰이더와 같은 식)로 확인했다. `preview.py` 의 `*_gray_*` 파일 | art_style §2 |
| 필터 | 최근접(project.godot `default_texture_filter=0`). 임포트 기본값 그대로 | |

## 2. 캐릭터 (`game/art/char/`)

### 2-1. 보행 시트

| 파일 | 크기 | 키(외곽선 포함) | 정체성 포인트 | 머리 흔들림 |
|---|---|---|---|---|
| `haneul_walk.png` | 96×128 | 약 30px | 앞치마의 파란 물감 자국 (`longing-mid/light`, 3px) | 있음 |
| `byeol_walk.png` | 96×128 | 약 25px | 노란 별 머리핀 (`warmth-mid/highlight`, 3×3) | 있음 |
| `npc_a_walk.png` | 96×128 | 약 29px | 없음 (중립색만) | **없음** |
| `npc_b_walk.png` | 96×128 | 약 30px | 없음 (중립색만) | **없음** |

- 프레임 **24×32**, 시트 **4열 × 4행**.
- 행(위→아래): `down`, `left`, `right`, `up`. 열(왼→오): `stand`, `stepA`, `stand`, `stepB` (0·2열은 같은 그림).
- 발 = 프레임 **바닥 중앙** (x 12, y 31). Godot: `Sprite2D` `centered = false`, `offset = (-12, -32)` 이면 노드 위치 = 발. y 정렬은 발 기준.
- `right` 행은 `left` 행의 좌우 반전이다(별의 머리핀도 같이 반전).
- 주인공은 걷는 열(1·3열)에서 윗몸이 1px 내려간다(보폭). NPC 는 머리가 모든 열에서 같은 자리에 있다 → 얼굴 오버레이를 프레임마다 옮길 필요가 없다.
- 실루엣 구분(흑백): 하늘 = 키 크고 부스스한 머리 + 밝은 앞치마 / 별 = 작고 양 갈래 머리 + 어두운 원피스 + 흰 둥근 깃 / NPC A = 납작 모자 + 조끼 / NPC B = 올림머리(쪽) + 숄 + 긴 치마.

### 2-2. 초상

| 파일 | 크기 | 배치 |
|---|---|---|
| `haneul_portrait.png` | 256×64 | 64×64 × 4열: `neutral`, `smile`, `sad`, `surprised` |
| `byeol_portrait.png` | 256×64 | 같음 |

- 열 이름은 [dialogue_conventions.md](../schemas/dialogue_conventions.md) §4 의 `portrait` 값과 같다. 나머지 8종(angry, scared, worried, determined, tearful, laugh, thinking, blank)은 아직 없다 → 없으면 `neutral` 로 대체하는 것을 권장.
- 정체성 포인트는 초상에도 같다: 하늘 = 앞치마 가슴판의 파란 물감 자국, 별 = 노란 별 머리핀.

### 2-3. NPC 얼굴 오버레이 (W-FACE, canon §2)

| 파일 | 크기 | 배치 | 쓰는 단계 |
|---|---|---|---|
| (없음) | — | — | 0단계: NPC 시트의 빈 얼굴 그대로 |
| `npc_face_l1.png` | 96×32 | 24×32 × 4열: `down`, `left`, `right`, `up` | 1단계: 흐린 눈·입 선 (`skin-shadow`, `skin-mid`) |
| `npc_face_l2.png` | 96×32 | 같음 | 2단계: 완성(검은 눈, 눈썹, 입) |

- 사용법: NPC `Sprite2D` 의 자식으로 같은 offset 의 `Sprite2D` 를 두고, `frame = 방향 행 번호`(0 down, 1 left, 2 right, 3 up)로만 바꾼다. 걷는 열과 상관없이 같은 프레임.
- `up` 프레임은 뒤통수라 비어 있다. 두 NPC 가 오버레이 한 장을 같이 쓴다(얼굴 픽셀 자리가 같다).
- 얼굴 픽셀: down 눈 (9,10)(9,11)(14,10)(14,11), 입 (11,13)(12,13), 눈썹 (8..9,9)(14..15,9) / left 눈 (7,10)(7,11), 입 (7,13), 눈썹 (7..8,9).

## 3. 잔향 소품 (`game/art/props/`)

기준점 = 스프라이트의 **바닥 중앙**. 배경 json 의 `props.<slug>` 좌표에 이 점을 맞춘다. 엔진(`chapter_scene.gd`)은 `EchoObject.position = props[slug]`, 스프라이트 `offset = (0, -h/2)` 로 그린다 → 같은 뜻이다.

| 파일 | 크기 | 감정 | 잔향 id | 배경 |
|---|---|---|---|---|
| `atelier_brush.png` | 17×24 | 그리움 | `echo.prologue.atelier_brush` | atelier — 붓 세 자루가 꽂힌 유리병(파란 헹굼물), 바닥의 파란 물감 |
| `garden_pot.png` | 23×21 | 온기 | `echo.prologue.garden_pot` | garden — 별 모양 화분(canon '별 화분') + 회색 새싹 |
| `atelier_easel.png` | 24×36 | 그리움 | `echo.ch1.atelier_easel` | atelier — 창가 이젤 위 파란 바다·하늘 그림 |
| `garden_sprinkler.png` | 22×17 | 온기 | `echo.ch1.garden_sprinkler` | garden — 노란 물뿌리개 |
| `lane_poster.png` | 19×24 | 그리움 | `echo.ch1.lane_poster` (숨김) | lane — 벽에 붙은 파란 포스터(물결 + 달). 벽 아래쪽 눈높이 |
| `path_lamp.png` | 13×43 | 온기 | `echo.ch1.path_lamp` | path — 노란 유리 가로등 |
| `square_clock.png` | 21×49 | 그리움 | `echo.ch1.square_clock` | square_gate — 시계탑 발치의 파란 테 기둥 시계(시계 장치) |
| `square_bench.png` | 34×24 | 온기 | `echo.ch1.square_bench` (숨김) | square_gate — 노랗게 칠한 벤치 |

- 각 소품은 그 감정의 4단계 램프(`dark/mid/light/highlight`) + 중립색만 쓴다. 흑백에서도 바깥 외곽선이 또렷하고, 같은 모양의 중립 물건보다 한 단계 밝다(art_style §2-3 감지 전 힌트).
- 소품의 충돌 영역은 배경 json `blockers` 에 **넣지 않았다**(소품이 없는 장면도 있으므로). 필요하면 장면 정의에서 붙인다.
- 잔향 상호작용 거리는 감지기(발 위 8px)에서 20px 이다. 모든 잔향 기준점은 캐릭터가 설 수 있는 자리에서 20px 안에 있다. `lane_poster` 만 벽에 붙는데, 기준점 y 124 는 바닥 맨 위에 선 캐릭터의 감지기 높이와 같다(WP-18b 에서 y 102 → 124 로 내림).

## 4. 배경 (`game/art/bg/`)

### 4-1. 목록과 장면

| 파일 | 장소 | 쓰는 장면 ([progression.md](../gdd/progression.md) §3-1·3-2, [slice_beats.md](../narrative/slice_beats.md) §1) | 잔향 자리 | 출구 → |
|---|---|---|---|---|
| `atelier.png` | 화실 | `prologue_atelier`, `ch1_atelier` (+ `ch5_atelier`) | `atelier_brush`, `atelier_easel` | `atelier_door` |
| `garden.png` | 정원 | `prologue_garden`, `ch1_garden`, `ch1_garden_02` (+ 이후 `*_garden*` 공용 허브) | `garden_pot`, `garden_sprinkler` | `garden_gate` |
| `atelier_door.png` | 화실 앞† | `prologue_door` | — | `atelier`, `lane` |
| `garden_gate.png` | 정원 문† | `prologue_gate` | — | `garden`, `path` |
| `lane.png` | 골목† | `ch1_lane` | `lane_poster` | `atelier_door`, `stairs` |
| `path.png` | 오솔길† | `ch1_path` | `path_lamp` | `garden_gate`, `market` |
| `stairs.png` | 계단길† | `ch1_stairs` | — | `lane`, `square` |
| `market.png` | 시장† | `ch1_market` | — | `path`, `square` |
| `square.png` | 광장 | `ch1_square` (+ `ch5_square`) | (보여 주기만: `square_clock`·`square_bench` 같은 자리) | `stairs`, `market` |
| `square_gate.png` | 광장 시계탑 아래 | `ch1_square_02` | `square_clock`, `square_bench` | `garden` |
| `square_night.png` | 광장(밤)† | `ch1_night` | (보여 주기만: 같은 자리) | `stairs`, `market` |

† = progression.md 의 자리표시 장소 이름(원작 확인 전, **TODO-확인**). ch1 아침 화실은 `atelier` 를 그대로 쓴다(별도 `atelier_morning` 없음).

마을 동선 **[제안]**: 하늘 길 = 화실 → 화실 앞 → 골목 → 계단길 → 광장 / 별 길 = 정원 → 정원 문 → 오솔길 → 시장 → 광장. 두 길이 광장에서 만난다(첫 만남). 마을 한가운데 = 광장의 **시계탑**(정원 담 너머·정원 문 원경에서도 보인다).

### 4-2. 메타데이터 형식 (`<이름>.json`)

좌표는 모두 픽셀(배경 왼쪽 위 = 0,0). 사각형 = `[x, y, w, h]`.

```json
{
  "size": [480, 270],
  "walkable": [[x, y], ...],
  "blockers": [[x, y, w, h], ...],
  "spawns": {"default": [x, y], "from_<배경>": [x, y]},
  "exits": [{"name": "<이어지는 배경 이름>", "rect": [x, y, w, h]}],
  "props": {"<id>": [x, y]},
  "gate_rect": [x, y, w, h],
  "notes": "설명"
}
```

| 키 | 뜻 |
|---|---|
| `walkable` | 다각형 하나. 캐릭터 **발**이 있을 수 있는 영역 (엔진이 외곽선 충돌로 만든다) |
| `blockers` | walkable 안의 가구·물건·난간 **발밑** 충돌 사각형 |
| `spawns` | 발 위치. `default` 는 항상 있다. `from_<배경>` = 그 배경에서 들어올 때. 두 사람이면 두 번째는 +26px 오른쪽 |
| `exits` | `name` = 이어지는 배경 이름. rect 는 walkable 과 겹친다. 장면 정의의 출구 이름(slice_beats 의 `door`, `gate`, `lane_end` …)과 다르면 장면 정의에서 `rect` 를 직접 주거나 이 이름을 가리킨다 |
| `props` | 두 종류. **잔향 slug**(`atelier_brush` 등) = 잔향 스프라이트 **바닥 중앙**. **조사 id**(`sofa`, `window` …) = 그 물건 **바로 앞 바닥**의 상호작용 지점(캐릭터가 서서 E 를 누르는 자리, 반경 24px). NPC id(`passerby`, `sweeper`, `vendor`) = NPC 의 발 위치. 장치 id(`gate_hold`, `gate_latch`) = 장치 위치(반경 20px) |
| `gate_rect` | (square_gate 만) 철문 통로. 장면 정의의 `gates[].rect` 에 그대로 쓴다. 엔진이 이 사각형에 창살과 충돌을 그리고, 열리면 위쪽 3px 만 남긴다 |
| `notes` | 장소 설명과 주의할 점 |

### 4-3. 슬라이스 조사 지점 (slice_beats.md §2 의 id = props 키)

장면 정의(`game/data/scenes/*.json`)가 `inspectables[].at` 을 주지 않으면 엔진이 `props[<id>]` 에 둔다. ★ = 잔향 기준점.

| 배경 | id (x, y) |
|---|---|
| `atelier` | `sofa` (70,190), `window` (88,134), `palette` (130,234), `canvas` (281,136), `sketchbook` (186,234), `brushes` (224,236), `coat` (452,136), `atelier_brush` (224,236) ★, `atelier_easel` (152,162) ★ |
| `garden` | `flowers` (52,228), `shed` (404,130), `swing` (431,206), `can` (70,168), `pot` (292,190), `fence` (250,128), `garden_pot` (292,190) ★, `garden_sprinkler` (70,168) ★ |
| `atelier_door` | `mailbox` (320,144), `lamp` (72,212), `sign` (262,144), `passerby` (360,186) |
| `garden_gate` | `gate` (240,144), `signpost` (154,162), `town` (400,146), `bird` (120,146) |
| `lane` | `sweeper` (240,166), `laundry` (96,140), `cat` (382,186), `puddle` (140,176) |
| `path` | `tree` (64,164), `sign` (426,164), `butterfly` (252,140), `wildflowers` (184,238), `path_lamp` (300,166) ★ |
| `stairs` | `railing` (186,200), `pots` (282,216), `chalk` (240,156), `view` (210,64) |
| `market` | `vendor` (96,130), `apples` (42,130), `cloth` (245,130), `bakery` (400,130) |
| `square` | `fountain` (240,218), `board` (36,124), `pigeons` (312,232), `clock` (112,162) |
| `square_night` | `clock` (112,162), `board` (36,124), `fountain` (240,218), `bench` (376,158) |
| `square_gate` | `square_clock` (112,150) ★, `square_bench` (280,250) ★, `gate_hold` (190,208), `gate_latch` (152,174), `clockface` (136,140), `lamp` (40,162), `plaque` (91,138) · `gate_rect` [142,180,28,18] |

- 같은 자리 쌍(의도): `brushes` = `atelier_brush`, `can` = `garden_sprinkler`, `pot` = `garden_pot`. 이 조사 대상들은 잔향을 이미 모은 장면(§0-9, 상호작용 없는 보여 주기 잔향)에서 쓰인다.
- 조사 지점끼리는 모두 24px 넘게 떨어져 있다(가장 가까운 대상이 선택되므로 헷갈리지 않게).
- `check_art.py` 가 위 표 전체를 검사한다: id 존재, 바닥 위·blocker 밖, 서로 간격.

### 4-4. square_gate — 철문 퍼즐 배치 (ch1_square_02, sibling.md §4-1 붙잡기-이동)

| 항목 | 값 |
|---|---|
| 막힌 구역 | 왼쪽 시계탑 발치 x 16~182, y 120~198 (둥근 돌 포장) |
| 난간 blockers | 앞쪽(동서) `[16,192,126,8]`, 철문 오른쪽 기둥~모서리 `[170,192,12,8]`, 오른쪽(남북) `[176,114,6,86]` |
| `gate_rect` | `[142,180,28,18]` — 앞쪽 난간 오른쪽 끝의 통로. 배경에는 기둥 두 개·아치·문턱만 그렸다(창살은 엔진) |
| `gate_hold` | (190, 208) — 철문 바깥 오른쪽 앞. 붙잡는 사람이 서도 통로를 막지 않는다 |
| `gate_latch` | (152, 174) — 철문 바로 안쪽 |
| 안쪽 | `square_clock` ★ (112,150) 탑 발치 시계 장치, `clockface` (136,140) 높은 시계판을 올려다보는 자리, `plaque` (91,138) 닳은 머릿돌, `lamp` (40,162) 탑 옆 가로등 |
| 바깥 | `square_bench` ★ (280,250) — 탑 발치에서 195px. 배경에는 벤치를 그리지 않았다(엔진이 잔향 스프라이트를 그린다) |
| 스폰 | `default` (380,200), `from_square` (120,220) — 둘 다 철문 밖 |
| 출구 | `garden` `[472,152,8,60]` 오른쪽 끝 (정원 가는 길) |

`check_art.py` 가 바닥 채우기로 확인한다: 문이 닫히면 `gate_latch`·`square_clock` 에 갈 수 없고, 열면 갈 수 있다. `gate_hold`·`from_square` 는 문 밖에서 닿는다.

### 4-5. 배경별 메모 (엔진 쪽이 알아야 할 것)

- **atelier**: 왼쪽 벽에 낡은 소파(담요가 바닥으로 흘러내림) — 기본 스폰 = 소파 옆. 창가에 이젤(`atelier_easel`), 가운데 아래 작업대 위에 팔레트(`palette`)·빈 스케치북(`sketchbook`), 작업대 오른쪽 바닥에 붓통(`atelier_brush` = `brushes`). 벽 풍경화 오른쪽 아래 'H.S' 서명 — `canvas` 는 그 아래 바닥, `hs_signature` 는 벽면 좌표(참고). 문 옆 옷걸이의 낡은 외투(`coat`). `atelier_window` = ch5 잔향 자리(범위 밖, 별도 커튼/창틀 스프라이트 필요).
- **garden**: garden.md §2 배치 그대로(`plot_01`~`10`, `special_pot`, `heart_bed_01`~`12`). 별 화분(`garden_pot` = `pot`)은 별이 깨어나는 가운데 풀밭(기본 스폰) 발치로 옮겼다(WP-18b, slice_beats §2-2). 왼쪽 회색 꽃밭, 헛간 아래 2인용 그네, 뒷담 위로 마을 시계탑 꼭대기(`fence`). 별 화분과 특별 화분이 같은 물건인지는 **TODO-확인**.
- **atelier_door**: 글자가 지워진 간판(`sign`), 이름표가 닳은 우편함(`mailbox`), 낮에도 켜진 아래 왼쪽 가로등(`lamp`), 말 없는 행인 자리(`passerby`).
- **garden_gate**: 원경에 굴뚝 연기와 마을 한가운데 시계탑. 담 위 회색 새(`bird`, 나무 틈으로 하늘이 보이는 자리), 화살표만 시계탑 쪽을 가리키는 이정표(`signpost`), 마을 전망(`town`).
- **lane**: 청소부 NPC 자리(`sweeper`, 골목 한가운데), 처마(담) 위 고양이(`cat`), 웅덩이(`puddle`), 빨랫줄(`laundry`). 숨김 잔향 포스터 양옆에 낡은 중립 포스터 두 장.
- **path**: 연필 빗금 껍질의 나무(`tree`), 화살표만 시장 쪽을 가리키는 표지판(`sign`), 회색 나비(`butterfly`), 들꽃 무리(`wildflowers`). `path_lamp` 높이 43px.
- **stairs**: 반질반질 닳은 손잡이(`railing`), 계단 화분(`pots`), 층계참의 희미한 사방치기(`chalk`), 계단 꼭대기 전망(`view`). 계단 단차 8px.
- **market**: 과일(회색 사과 — `apples`) / 꽃무늬 천(`cloth`) / 빵(바구니·김 — `bakery`) 가게. `vendor` = 과일 가게 진열대 바로 앞의 상인 발 위치. 진열대 뒤에 세우면 NPC 가 배경 위에 그려져 진열대 앞에 선 것처럼 보이므로 이 자리를 권장.
- **square / square_night / square_gate**: 같은 광장, 같은 좌표. 왼쪽 위 **시계탑**(화면 위로 솟음, 높은 곳에 숫자가 반쯤 지워진 멈춘 시계판), 가운데 회색 물이 흐르는 **분수**(배경에 그림 — ch5 잔향 `square_fountain` 은 덧그림 스프라이트가 필요), 왼쪽 건물 벽의 **'사람을 찾습니다' 게시판**(전단의 얼굴 칸이 흐릿), 분수 앞 비둘기. 기둥 시계(잔향 `square_clock`)는 탑 발치 `(112,150)` 에 엔진이 그린다 — `square`(ch1_square)에서는 그리지 않고, `clock` 조사는 탑 발치에서 높은 시계판을 올려다보는 자리다. `square_night` 은 시계판 분침이 낮보다 한 칸(5분) 앞이다(slice_beats §2-12 "바늘이 한 칸 앞으로"). `bench`(밤) = 오른쪽 위 중립 벤치 앞.
- 같은 장면에 잔향이 둘인 배경(atelier, garden, square_gate)은 두 기준점이 96px 넘게 떨어져 있다 → 하나를 모았을 때 다른 잔향의 색이 같이 돌아오지 않는다.

## 5. 문서 사이 차이 (art_style.md 를 따름)

| 항목 | 차이 | 처리 |
|---|---|---|
| 파일 경로 | art_style §5 는 `game/art/<bg\|char\|ui\|vfx>/<챕터>/<이름>.png` | 배경이 여러 챕터에서 같이 쓰여서(화실 = 프롤로그·1·5장) 챕터 폴더 없이 평평하게 두었다. 승인 때 결정 필요 |
| 원본 파일 | art_style §5 는 `.aseprite` 원본을 함께 둔다 | 원본 = `tools/pixelart/*.py` 코드. `.aseprite` 없음 |
| 소품 폴더 | ownership.md T4 쓰기 경로는 `game/art/{bg,char,ui}/` | WP-18 지시에 따라 `game/art/props/` 를 새로 만들었다. ownership 표에 추가 필요(개발자) |
| 중립색 채도 | art_style §3 은 셰이더 하한 0.30, 셰이더(`band_min_saturation`) 기본값은 0.35 | 중립색 팔레트는 전부 0.28 이하라 둘 다 만족 |
| 별 화분 | 화분 모양 '별'은 꿈(보라)의 기호 '별'과 겹친다 | 화분은 온기(노랑)이고 UI 기호는 해(☀)를 쓴다. 색각 이상 모드에서 헷갈리지 않는지 WP-14/36 에서 확인 |
| 시계탑 | slice_beats 는 '시계탑'(높은 시계판, 기단의 시계 장치), 잔향 스프라이트는 기둥 시계 | 광장에 시계탑을 그리고, 기둥 시계 스프라이트를 탑 발치의 '시계 장치'로 둔다 |
| 분수 | WP-18 에서는 ch5 잔향 자리라 비워 두었다 | slice_beats §2-11 이 분수를 요구해 배경에 그렸다. ch5 잔향은 분수 위에 덧그리는 스프라이트로 처리 |

## 6. 아직 없는 것 (다음 WP 후보)

- 초상 표정 8종, 보호 컷인 그림 2장(sibling.md §7), 감정 기호 UI 7×7(art_style §4), 정원 식물 성장 6단계 스프라이트, ch5 잔향 소품(`atelier_window`, `square_fountain` 덧그림).
- 주인공의 상호작용·대기·`habit_circle`(허공에 동그라미 두 번) 애니메이션, 감지 중 걷기 전용 프레임. NPC 청소부·상인 전용 시트(지금은 `npc_a`/`npc_b` 공용).
- 철문을 붙잡는 손잡이·고정 장치 스프라이트(지금은 엔진이 사각형으로 그린다), `square_clock` 을 모은 뒤 바늘이 한 칸 움직인 기둥 시계 그림.
