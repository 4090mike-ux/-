# 에셋 목록 — 버티컬 슬라이스 (프롤로그 + 챕터 1)

- 상태: **초안 (WP-18).** 아트 스타일 승인(사람, 위임 금지) 전이다. 승인 전까지 모든 그림은 바뀔 수 있다.
- 만든 방법: Claude 가 **코드로** 그렸다(`tools/pixelart/`). 이미지 생성 AI 는 쓰지 않았다. 원본 = 파이썬 코드(ASCII 격자 + 도형). `.aseprite` 원본은 없다.
- 공개: [docs/ai_usage.md](../ai_usage.md)에 기록(출시물 포함, 공개 대상 예).

## 다시 만들기

```bash
pip install -r tools/requirements.txt          # Pillow>=11
python tools/pixelart/build_all.py             # 아래 PNG·JSON 전부 (결정적: 몇 번을 돌려도 같은 파일)
python tools/pixelart/build_all.py --only bg   # 묶음만: char, portrait, npc, props, bg
python tools/pixelart/check_art.py             # 팔레트·감정 색 배치·배경 메타데이터 검사 (오류면 종료 코드 1)
python tools/pixelart/preview.py               # 6배 확대·흑백 미리보기 + 배경 목업 → tools/pixelart/_preview/ (커밋 안 함)
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

기준점 = 스프라이트의 **바닥 중앙**. 배경 json 의 `props.<slug>` 좌표에 이 점을 맞춘다(`offset = (-w/2, -h)`).

| 파일 | 크기 | 감정 | 잔향 id | 배경 |
|---|---|---|---|---|
| `atelier_brush.png` | 17×24 | 그리움 | `echo.prologue.atelier_brush` | atelier — 붓 세 자루가 꽂힌 유리병(파란 헹굼물), 바닥의 파란 물감 |
| `garden_pot.png` | 23×21 | 온기 | `echo.prologue.garden_pot` | garden — 별 모양 화분(canon '별 화분') + 회색 새싹 |
| `atelier_easel.png` | 24×36 | 그리움 | `echo.ch1.atelier_easel` | atelier — 이젤 위 파란 바다·하늘 그림 |
| `garden_sprinkler.png` | 22×17 | 온기 | `echo.ch1.garden_sprinkler` | garden — 노란 물뿌리개 |
| `lane_poster.png` | 19×24 | 그리움 | `echo.ch1.lane_poster` (숨김) | lane — 벽에 붙은 파란 포스터(물결 + 달). **벽면 좌표** |
| `path_lamp.png` | 13×43 | 온기 | `echo.ch1.path_lamp` | path — 노란 유리 가로등 |
| `square_clock.png` | 21×49 | 그리움 | `echo.ch1.square_clock` | square — 파란 테 기둥 시계 |
| `square_bench.png` | 34×24 | 온기 | `echo.ch1.square_bench` (숨김) | square — 노랗게 칠한 벤치 |

- 각 소품은 그 감정의 4단계 램프(`dark/mid/light/highlight`) + 중립색만 쓴다. 흑백에서도 바깥 외곽선이 또렷하고, 같은 모양의 중립 물건(광장의 중립 벤치 등)보다 한 단계 밝다(art_style §2-3 감지 전 힌트).
- 소품의 충돌 영역은 배경 json `blockers` 에 **넣지 않았다**(소품이 없는 챕터도 있으므로). 엔진이 소품을 놓을 때 발밑에 작은 충돌을 붙인다(권장: 이젤·벤치·시계·가로등).

## 4. 배경 (`game/art/bg/`)

### 4-1. 목록과 장면

| 파일 | 장소 | 쓰는 장면 ([progression.md](../gdd/progression.md) §3-1·3-2) | 잔향 자리 | 출구 → |
|---|---|---|---|---|
| `atelier.png` | 화실 | `prologue_atelier`, `ch1_atelier` (+ `ch5_atelier`) | `atelier_brush`, `atelier_easel` | `atelier_door` |
| `garden.png` | 정원 | `prologue_garden`, `ch1_garden`, `ch1_garden_02` (+ 이후 `*_garden*` 공용 허브) | `garden_pot`, `garden_sprinkler` | `garden_gate` |
| `atelier_door.png` | 화실 앞† | `prologue_door` | — | `atelier`, `lane` |
| `garden_gate.png` | 정원 문† | `prologue_gate` | — | `garden`, `path` |
| `lane.png` | 골목† | `ch1_lane` | `lane_poster` | `atelier_door`, `stairs` |
| `path.png` | 오솔길† | `ch1_path` | `path_lamp` | `garden_gate`, `market` |
| `stairs.png` | 계단길† | `ch1_stairs` | — | `lane`, `square` |
| `market.png` | 시장† | `ch1_market` | — | `path`, `square` |
| `square.png` | 광장 | `ch1_square`, `ch1_square_02` (+ `ch5_square`) | `square_clock`, `square_bench` | `stairs`, `market` |
| `square_night.png` | 광장(밤)† | `ch1_night` | (square 와 같은 자리) | `stairs`, `market` |

† = progression.md 의 자리표시 장소 이름(원작 확인 전, **TODO-확인**).

마을 동선 **[제안]**: 하늘 길 = 화실 → 화실 앞 → 골목 → 계단길 → 광장 / 별 길 = 정원 → 정원 문 → 오솔길 → 시장 → 광장. 두 길이 광장에서 만난다(첫 만남). 교대 파트에서는 출구가 '장면 끝' 트리거로 쓰일 것이다.

### 4-2. 메타데이터 형식 (`<이름>.json`)

좌표는 모두 픽셀(배경 왼쪽 위 = 0,0). 사각형 = `[x, y, w, h]`.

```json
{
  "size": [480, 270],
  "walkable": [[x, y], ...],
  "blockers": [[x, y, w, h], ...],
  "spawns": {"default": [x, y], "from_<배경>": [x, y]},
  "exits": [{"name": "<이어지는 배경 이름>", "rect": [x, y, w, h]}],
  "props": {"<잔향 slug 또는 소품 이름>": [x, y]},
  "notes": "설명"
}
```

| 키 | 뜻 |
|---|---|
| `walkable` | 다각형 하나. 캐릭터 **발**이 있을 수 있는 영역 (벽·건물 정면 아래선까지) |
| `blockers` | walkable 안의 가구·물건 **발밑** 충돌 사각형 |
| `spawns` | 발 위치. `default` 는 항상 있다. `from_<배경>` = 그 배경에서 들어올 때 |
| `exits` | `name` = 이어지는 배경 이름. rect 는 walkable 과 겹친다 |
| `props` | 소품 스프라이트의 **바닥 중앙**. 잔향 slug 는 `echo.<구간>.<slug>` 의 slug 와 같다. 그 밖의 이름은 조사 지점·NPC 자리 후보 |
| `notes` | 장소 설명과 주의할 점 |

`check_art.py` 가 필수 키, 화면 범위, spawn 이 walkable 안·blocker 밖인지, 출구가 walkable 과 겹치는지 검사한다.

### 4-3. 배경별 메모 (엔진 쪽이 알아야 할 것)

- **atelier**: `hs_signature` = 벽 풍경화 오른쪽 아래의 작은 'H.S' 서명(벽면 좌표, 조사 지점). canon §5 의 첫 등장 위치는 **TODO-확인**이라 그림 속에 작게만 넣었다. `atelier_window` = ch5 잔향 자리 — 창이 배경에 그려져 있으므로 ch5 에는 별도 커튼/창틀 스프라이트가 필요(범위 밖).
- **garden**: garden.md §2 배치 그대로. `plot_01`~`plot_05` = 하늘 줄(위), `plot_06`~`plot_10` = 별 줄(아래), 짝 칸은 세로. `special_pot` = 가운데 둥근 판석. `heart_bed_01`~`12` = 담 밑 마음 화단. 좌표 = 식물 스프라이트 바닥 중앙. 칸(흙 두둑)은 blocker. 별 화분(`garden_pot`)과 가운데 특별 화분을 같은 물건으로 볼지는 **TODO-확인**(지금은 따로 둠).
- **lane**: `lane_poster` 는 벽에 붙는다(좌표 = 포스터 바닥 중앙, 벽면 y 102). 상호작용 거리는 바닥 (254, 136) 기준을 권장. 양옆에 낡은 중립 포스터 두 장이 있어 흑백에서는 섞여 보인다(숨김 잔향).
- **path**: `path_lamp` 는 높이 43px. 흙길 위쪽 가장자리에 선다.
- **stairs**: 계단 단차 8px. 가운데 층계참(`landing`)이 넓다 — '닮은 습관(하늘 쪽)' 연출 자리 후보.
- **market**: `stall_*` = 상인 NPC 자리 후보. 과일도 모두 회색이다(색을 잃은 세계).
- **square / square_night**: 두 json 은 같은 좌표다. 시청 정면의 둥근 장식은 **빈 장식**(시계는 잔향 소품 `square_clock`). `square_fountain` = ch5 잔향 자리(범위 밖, 가운데 원형 무늬 위). 같은 장면의 두 잔향은 복원 반경(48px)이 겹치지 않게 200px 떨어져 있다. 밤 배경에서 소품은 엔진이 같은 좌표에 그린다(밤 톤은 엔진 쪽 modulate 로 맞추는 것을 권장).
- 같은 장면에 잔향이 둘인 배경(atelier, garden, square)은 두 앵커가 96px 이상 떨어져 있다 → 하나를 모았을 때 다른 잔향의 색이 같이 돌아오지 않는다.

## 5. 문서 사이 차이 (art_style.md 를 따름)

| 항목 | 차이 | 처리 |
|---|---|---|
| 파일 경로 | art_style §5 는 `game/art/<bg\|char\|ui\|vfx>/<챕터>/<이름>.png` | 배경이 여러 챕터에서 같이 쓰여서(화실 = 프롤로그·1·5장) 챕터 폴더 없이 평평하게 두었다. 승인 때 결정 필요 |
| 원본 파일 | art_style §5 는 `.aseprite` 원본을 함께 둔다 | 원본 = `tools/pixelart/*.py` 코드. `.aseprite` 없음 |
| 소품 폴더 | ownership.md T4 쓰기 경로는 `game/art/{bg,char,ui}/` | WP-18 지시에 따라 `game/art/props/` 를 새로 만들었다. ownership 표에 추가 필요(개발자) |
| 중립색 채도 | art_style §3 은 셰이더 하한 0.30, 셰이더(`band_min_saturation`) 기본값은 0.35 | 중립색 팔레트는 전부 0.28 이하라 둘 다 만족 |
| 별 화분 | 화분 모양 '별'은 꿈(보라)의 기호 '별'과 겹친다 | 화분은 온기(노랑)이고 UI 기호는 해(☀)를 쓴다. 색각 이상 모드에서 헷갈리지 않는지 WP-14/36 에서 확인 |

## 6. 아직 없는 것 (다음 WP 후보)

- 초상 표정 8종, 보호 컷인 그림 2장(sibling.md §7), 감정 기호 UI 7×7(art_style §4), 정원 식물 성장 6단계 스프라이트, ch5 잔향 소품(`atelier_window`, `square_fountain`).
- 주인공의 상호작용·대기 애니메이션, 감지 중 걷기(×0.6 속도) 전용 프레임.
