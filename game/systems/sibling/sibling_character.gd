class_name SiblingCharacter
extends CharacterBody2D
## 하늘·별 공용 이동 컨트롤러 (WP-09 골격). active 일 때만 입력을 받는다.
## 이동은 8방향, 보는 방향(facing)은 스프라이트용 4방향.

signal facing_changed(facing: Vector2)

const GROUP := &"siblings"

@export_enum("haneul", "byeol") var character_key: String = "haneul"
## 걷기 속도 80 px/s (docs/gdd/controls_accessibility.md) [제안]
@export var speed: float = 80.0

## 잔향 감지 중 ×0.6 등 일시적인 속도 배율 (EchoSensor 가 설정)
var speed_multiplier: float = 1.0

var active: bool = false:
	set(value):
		active = value
		if not active:
			velocity = Vector2.ZERO

var facing: Vector2 = Vector2.DOWN


func _ready() -> void:
	add_to_group(GROUP)


## 같은 씬에 있는 상대 캐릭터 (없으면 null)
func partner() -> SiblingCharacter:
	for node in get_tree().get_nodes_in_group(GROUP):
		var other := node as SiblingCharacter
		if other != null and other != self:
			return other
	return null


func _physics_process(_delta: float) -> void:
	if not active:
		return
	var dir := Input.get_vector(
		InputActions.MOVE_LEFT, InputActions.MOVE_RIGHT, InputActions.MOVE_UP, InputActions.MOVE_DOWN
	)
	move_with(dir)


## 입력 벡터로 한 프레임 이동 (테스트·자동 이동에서도 쓴다)
func move_with(dir: Vector2) -> void:
	if dir != Vector2.ZERO:
		var four := four_way(dir)
		if four != facing:
			facing = four
			facing_changed.emit(facing)
	velocity = dir.limit_length(1.0) * speed * speed_multiplier
	move_and_slide()


static func four_way(dir: Vector2) -> Vector2:
	if absf(dir.x) > absf(dir.y):
		return Vector2.RIGHT if dir.x > 0.0 else Vector2.LEFT
	return Vector2.DOWN if dir.y > 0.0 else Vector2.UP
