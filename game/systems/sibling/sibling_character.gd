class_name SiblingCharacter
extends CharacterBody2D
## 하늘·별 공용 이동 컨트롤러 (WP-09 골격). active 일 때만 입력을 받는다.
## 이동은 8방향, 보는 방향(facing)은 스프라이트용 4방향.

signal facing_changed(facing: Vector2)

@export_enum("haneul", "byeol") var character_key: String = "haneul"
@export var speed: float = 72.0

var active: bool = false:
	set(value):
		active = value
		if not active:
			velocity = Vector2.ZERO

var facing: Vector2 = Vector2.DOWN


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
	velocity = dir.limit_length(1.0) * speed
	move_and_slide()


static func four_way(dir: Vector2) -> Vector2:
	if absf(dir.x) > absf(dir.y):
		return Vector2.RIGHT if dir.x > 0.0 else Vector2.LEFT
	return Vector2.DOWN if dir.y > 0.0 else Vector2.UP
