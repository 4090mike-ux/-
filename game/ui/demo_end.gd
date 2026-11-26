extends Control
## 버티컬 슬라이스 끝 화면 (ch1_night 다음). 모은 잔향 수를 보여 주고 확인을 누르면 타이틀로.

var _time: float = 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	GameState.count_playtime = false


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if _time > 1.5 and (event.is_action_pressed(InputActions.INTERACT) or event.is_action_pressed(&"ui_accept")):
		get_viewport().set_input_as_handled()
		get_tree().change_scene_to_file("res://game/scenes/ui/title.tscn")


func _draw() -> void:
	var size := get_viewport_rect().size
	var font := get_theme_default_font()
	draw_rect(Rect2(Vector2.ZERO, size), Color("#151417"))
	var a := clampf(_time / 1.2, 0.0, 1.0)
	draw_string(font, Vector2(0, 100), tr("chapter.ch1.end"), HORIZONTAL_ALIGNMENT_CENTER, size.x, 11, Color(0.93, 0.92, 0.94, a))
	var line := "모은 잔향 %d · 숨김 %d" % [GameState.echo_found, GameState.hidden_echo_found]
	draw_string(font, Vector2(0, 130), line, HORIZONTAL_ALIGNMENT_CENTER, size.x, 9, Color(0.6, 0.59, 0.62, a))
	draw_string(font, Vector2(0, 150), "플레이 시간 %d분" % int(GameState.playtime_sec / 60.0), HORIZONTAL_ALIGNMENT_CENTER, size.x, 9, Color(0.6, 0.59, 0.62, a))
	if _time > 1.5:
		draw_string(font, Vector2(0, 220), "▶ 타이틀로", HORIZONTAL_ALIGNMENT_CENTER, size.x, 11, Color("#edebf0"))
