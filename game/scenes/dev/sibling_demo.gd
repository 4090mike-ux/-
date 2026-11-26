extends Node2D
## WP-09 태그 전환 데모. 방향키/WASD 이동, Tab(패드 Y) 전환. 실제 아트 전까지 도형으로 표시한다.

const BG := Color("#2c2c30")
const FLOOR := Color("#4a494f")
const MARKER := Color("#edebf0")

@onready var _switcher: SiblingSwitcher = $Switcher
@onready var _hud: Label = $HudLayer/Hud


func _enter_tree() -> void:
	# 자식(Switcher)의 _ready 보다 먼저 상태를 초기화한다
	GameState.reset()


func _ready() -> void:
	EchoBus.character_switched.connect(_on_character_switched)
	_update_hud()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 480, 270), BG)
	draw_rect(Rect2(16, 16, 448, 238), FLOOR)
	var active := _switcher.active_character()
	if active != null:
		var top := active.position + Vector2(0, -28)
		draw_colored_polygon(PackedVector2Array([top, top + Vector2(-4, -6), top + Vector2(4, -6)]), MARKER)


func _on_character_switched(_character_key: String) -> void:
	_update_hud()


func _update_hud() -> void:
	_hud.text = "태그 전환 데모 — 지금: %s\n방향키/WASD 이동 · Tab 전환" % GameState.name_display(GameState.active_character)
