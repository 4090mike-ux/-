---
name: godot-conventions
description: Use when writing or editing GDScript (.gd), scenes (.tscn/.tres), shaders (.gdshader), Dialogue Manager files (.dialogue) or gdUnit4 tests in the 「공허의 화가: 잔향의 색」 Godot 4.7 project. Covers typing rules, naming, system boundaries (EchoBus/GameState), hand-editing .tscn safely, test patterns and the R-NAME rule.
---

# Godot 4.7 작업 규칙 (이 프로젝트 전용)

AGENTS.md가 상위 규칙이다. 이 스킬은 Godot 파일을 실제로 쓸 때 필요한 세부 사항이다.

## 1. GDScript

```gdscript
class_name EchoSensor          # 다른 곳에서 타입으로 쓸 때만 class_name
extends Node2D
## 한 줄 설명. 왜 존재하는지.

signal echo_sensed(echo_id: String)        # 시그널은 과거형

const SENSE_RADIUS := 48.0
@export var hold_time: float = 0.4
@onready var _area: Area2D = $SenseArea      # 자기 씬 안의 자식만 경로로 참조

var _held := 0.0                              # := 추론 OK, 타입 없는 var 는 오류


func sense(origin: Vector2) -> Array[String]:  # 매개변수·반환 타입 필수
	var found: Array[String] = []
	for body: Node2D in _area.get_overlapping_bodies():
		found.append(body.name)
	return found
```

- `project.godot`: `untyped_declaration = 오류`, `unsafe_property_access / unsafe_method_access / unsafe_call_argument = 경고`.
- Variant를 받으면 `as`로 캐스팅하거나 타입 있는 변수에 담는다. `Dictionary` 값은 `float(d["x"])`처럼 변환한다.
- 시그널 연결은 `signal_name.connect(_on_x)`. 문자열 기반 `connect("x", ...)` 금지.
- 다른 시스템을 부를 때 노드 경로(`get_node("/root/Main/Garden")`)를 쓰지 않는다. `EchoBus`(시그널 허브 오토로드)로 알리고, 상태는 `GameState` API로 읽고 쓴다.
- 감정 색·대역은 `EmotionBands`(`game/systems/color/emotion_bands.gd`)로 읽는다. 숫자를 하드코딩하지 않는다.
- 사용자에게 보이는 문자열: `tr("key")`. 키는 `game/i18n/*.csv`에 먼저 추가. 본명은 `truth.` 키에만.

## 2. 폴더

```
game/autoload/   GameState, SaveService, EchoBus (공유 — 통합 세션만)
game/systems/<echo|garden|sibling|color>/   시스템 코드
game/scenes/<prologue|ch1..ch5|endings|ui|dev>/
game/dialogue/<구간>/<장면id>.dialogue
game/data/       JSON 계약 데이터 (스키마: docs/schemas/)
game/shaders/    .gdshader
tests/unit/, tests/flow/
```

## 3. .tscn 손으로 고치기

텍스트 씬은 고칠 수 있지만 깨지기 쉽다.

- 머리말 `[gd_scene load_steps=N format=3]`: N = ext_resource 수 + sub_resource 수 + 1.
- `ext_resource`의 `id`는 파일 안에서 유일하면 된다(`"1_demo"` 같은 형식). `uid=`는 생략해도 되고, 에디터가 저장할 때 붙인다. 이미 있는 uid는 지우거나 바꾸지 않는다.
- 노드 순서 = 그리기 순서. `parent="."`, `parent="A/B"` 경로를 정확히.
- 마우스 입력을 막지 않아야 하는 전체 화면 ColorRect는 `mouse_filter = 2`.
- 고친 뒤에는 반드시:
  ```bash
  "$GODOT_BIN" --headless --path . --import
  "$GODOT_BIN" --headless --path . -s res://tests/check_scripts.gd
  ```
- 노드가 10개를 넘는 씬, 애니메이션·타일맵이 있는 씬은 에디터나 Godot MCP로 만든다.

## 4. 셰이더

- `shader_type canvas_item;` 화면 효과는 맨 위 CanvasLayer의 ColorRect에 건다.
- 화면 샘플링: `uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;`
- 렌더러는 GL Compatibility(웹 내보내기 때문). Forward+ 전용 기능을 쓰지 않는다.
- uniform 배열은 `#define MAX_X 8` + `uniform vec4 arr[MAX_X];`, GDScript에서는 `PackedVector4Array`로 넣는다.
- 셰이더 계약 uniform 이름을 바꾸면 `tests/unit/test_color_restore.gd`도 바꾼다.

## 5. Dialogue Manager 4 문법 요약

```
# scene: ch2_cafe          ← 머리말 (규약 §2)
~ start                    ← 큐 (영문 snake_case만)
jieun: [#portrait=smile] 어서 오세요.        ← 화자는 speakers.json 키
| byeol: [#sync] 같은 말!                   ← 동시 발화
지문은 화자 없이. 콜론은 \: 로.
- [#choice=ch2_cafe_01] 응답 텍스트          ← 성향 선택지
	$> GameState.add_protect(1)             ← 상태 변경은 $> + GameState API
- 조건 응답 [if GameState.bond >= 2 /] => other_cue
if GameState.flag("flag.ch2.met_jieun")
	jieun: 또 오셨네요.
else
	jieun: 처음 뵙겠습니다.
=> END
```

- `set`/`do`는 폐기 예정 문법. `$>`를 쓴다.
- 상세: `docs/schemas/dialogue_conventions.md`, 원문 `addons/dialogue_manager/` 또는 Context7.

## 6. gdUnit4 테스트

```gdscript
extends GdUnitTestSuite

func test_add_protect_only_increases() -> void:
	var state: Node = auto_free(preload("res://game/autoload/game_state.gd").new())
	state.add_protect(2)
	assert_int(state.protect).is_equal(2)

func test_needs_rendering(
		_do_skip := DisplayServer.get_name() == "headless",
		_skip_reason := "실제 렌더링 필요") -> void:
	var runner := scene_runner("res://game/scenes/dev/color_demo.tscn")
	await runner.simulate_frames(2)
```

- 파일: `tests/<unit|flow>/test_<대상>.gd`. 메서드: `test_<동작>`.
- 노드는 `auto_free()`로 감싼다. 씬은 `scene_runner()`.
- 로컬: `tools/ci_local.sh`(헤드리스, 렌더링 테스트 건너뜀). CI: xvfb에서 전부 실행.

## 7. 흔한 실수

| 실수 | 바로잡기 |
|---|---|
| `var x = 1` | `var x := 1` 또는 `var x: int = 1` |
| `for e in dict_array:` 후 `e.id` | `for e: Dictionary in arr:` + `e["id"]` |
| Godot 3 문법 (`onready`, `export`, `yield`, `KinematicBody2D`) | `@onready`, `@export`, `await`, `CharacterBody2D` |
| 화자 자리에 `하늘:` | `haneul:` (R-NAME) |
| 감정 Hue 를 코드에 숫자로 | `EmotionBands.band_for("longing")` |
| 새 플래그를 대사에서 바로 사용 | `game/data/flags.json`에 먼저 등록 |
