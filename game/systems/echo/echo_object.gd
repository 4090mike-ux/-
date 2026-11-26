class_name EchoObject
extends Node2D
## 잔향 오브젝트 (WP-12). 감지되면 감정 색 윤곽 + 기호가 맥동하고(EchoHighlightLayer 가 그림),
## 모으면 주변의 같은 감정 색이 돌아온다(EchoBus.color_restored → ColorRestoreLayer).
##
## 정의(emotion, kind, sensed_by)의 원천은 game/data/echoes/*.json 이다.
## 데이터가 아직 없는 프로토타입에서는 fallback_* 값을 쓴다.

const GROUP := &"echo_objects"

@export var echo_id: String = ""
@export_enum("longing", "warmth", "dream", "courage", "healing") var fallback_emotion: String = "longing"
@export_enum("haneul", "byeol", "both") var fallback_sensed_by: String = "both"
@export var fallback_hidden: bool = false
## 윤곽 원 반지름 (오브젝트 크기에 맞춘다)
@export var outline_radius: float = 12.0
## 모았을 때 색이 돌아오는 반경 (GDD 기본 48px, 큰 소품은 씬에서 키운다)
@export var restore_radius: float = 48.0

const LINGER_SEC := 2.0   # 손을 뗀 뒤 윤곽 유지 (docs/gdd/echo.md §2-1)
const FADE_SEC := 0.5

## 0~1. EchoSensor 가 감지 중에 sense() 로 올린다. 마지막 감지 후 2초 유지 + 0.5초 페이드.
var sense_strength: float = 0.0
var _linger: float = 0.0


func _ready() -> void:
	add_to_group(GROUP)


func _process(delta: float) -> void:
	if _linger > 0.0:
		_linger -= delta
	else:
		sense_strength = move_toward(sense_strength, 0.0, delta / FADE_SEC)


func definition() -> Dictionary:
	return GameData.echo_def(echo_id)


func emotion() -> String:
	return str(definition().get("emotion", fallback_emotion))


func sensed_by() -> String:
	return str(definition().get("sensed_by", fallback_sensed_by))


func is_collected() -> bool:
	return GameState.has_echo(echo_id)


func is_hidden() -> bool:
	var def := definition()
	return str(def.get("kind", "")) == "hidden" if not def.is_empty() else fallback_hidden


## sensed_by: haneul/byeol = 그 사람만, both(공명 잔향) = 두 사람이 함께 있을 때만 (docs/gdd/echo.md §2-2)
func can_be_sensed_by(character_key: String, together: bool = false) -> bool:
	if is_collected():
		return false
	var who := sensed_by()
	if who == "both":
		return together
	return who == character_key


func sense(strength: float) -> void:
	sense_strength = maxf(sense_strength, clampf(strength, 0.0, 1.0))
	_linger = LINGER_SEC


func is_sensed() -> bool:
	return sense_strength > 0.05


## 공명 퍼즐을 풀었을 때 호출. 새로 모았으면 true.
func collect() -> bool:
	if not GameState.collect_echo(echo_id):
		return false
	sense_strength = 0.0
	EchoBus.color_restored.emit(emotion(), global_position, restore_radius)
	return true
