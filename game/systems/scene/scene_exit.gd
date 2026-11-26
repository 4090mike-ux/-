class_name SceneExit
extends Area2D
## 장면 출구. 활성 캐릭터가 들어오면 exit_requested 를 보낸다(조건 검사·이동은 ChapterScene 이 한다).

signal exit_requested(exit: SceneExit)

@export var exit_name: String = ""
@export var target_scene: String = ""
@export var target_spawn: String = "default"
@export var rect_size: Vector2 = Vector2(16, 16)
## {"flags": [...], "echoes": [...]} — 모두 만족해야 나갈 수 있다
@export var requires: Dictionary = {}
## 조건을 못 채웠을 때 재생할 cue
@export var blocked_cue: String = "exit_blocked"

## 장면 시작 직후에는 반응하지 않는다: 도착 지점이 출구 안에 있어도 바로 다시 나가지 않게.
## (이미 안에 있는 몸은 나갔다가 다시 들어와야 body_entered 가 다시 온다)
var _cooldown: float = 1.0


func _ready() -> void:
	monitoring = true
	var shape := RectangleShape2D.new()
	shape.size = rect_size
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = rect_size * 0.5
	add_child(col)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)


func requirements_met() -> bool:
	for f: Variant in requires.get("flags", []):
		if GameState.flag(str(f)) != true:
			return false
	for e: Variant in requires.get("echoes", []):
		if not GameState.has_echo(str(e)):
			return false
	return true


func _on_body_entered(body: Node2D) -> void:
	var c := body as SiblingCharacter
	if c == null or not c.active or _cooldown > 0.0:
		return
	_cooldown = 1.0
	exit_requested.emit(self)
