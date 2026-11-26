extends Node2D
## W2 프로토타입 (G2 셀프 플레이용): 흑백 방에서 잔향 5개를 감지 → 공명 퍼즐 → 색 복원.
## 조작: 이동 WASD/방향키, 잔향 감지 Shift(X) 길게, 공명 E/Space, 전환 Tab. 실제 아트 전까지 도형으로 그린다.
## 공명 잔향(포스터·벽난로)은 두 사람이 가까이 함께 있어야 감지된다.
## 스크린샷: godot --path . res://game/scenes/dev/echo_prototype.tscn -- --shot=user://proto.png
##   (커튼·벽난로 잔향을 모은 상태 + 포스터 감지 중 + 퍼즐 화면을 각각 찍는다: proto.png, proto_puzzle.png)
## 색은 감정 대역 규칙(art_style.md §3)을 지킨다: 감정 소품은 감정 색, 나머지는 채도 0.28 이하 중립색.

const FINALE_SATURATION := 0.55

@onready var _restore: ColorRestoreLayer = $ColorRestoreLayer
@onready var _puzzle: ResonancePuzzle = $ResonancePuzzle
@onready var _hud: Label = $HudLayer/Hud

var _pending: EchoObject = null
var _message: String = ""
var _shot_path: String = ""
var _shot_frame: int = 0


func _enter_tree() -> void:
	GameState.reset()


func _ready() -> void:
	for sensor: EchoSensor in [$Haneul/EchoSensor, $Byeol/EchoSensor]:
		sensor.interact_requested.connect(_on_interact_requested)
	_puzzle.solved.connect(_on_solved)
	_puzzle.cancelled.connect(_on_cancelled)
	EchoBus.character_switched.connect(func(_k: String) -> void: _update_hud())
	_update_hud()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="):
			_shot_path = arg.trim_prefix("--shot=")
	if not _shot_path.is_empty():
		($EchoCurtain as EchoObject).collect()
		($EchoFire as EchoObject).collect()
		_update_hud()


func _process(_delta: float) -> void:
	if _shot_path.is_empty():
		return
	_shot_frame += 1
	($EchoPoster as EchoObject).sense(1.0)
	if _shot_frame == 75:
		_save_shot(_shot_path)
		_puzzle.pause_tree = false
		_puzzle.open("echo.ch1.proto_poster", "dream")
		_puzzle.advance(0.4)
	elif _shot_frame == 80:
		_save_shot(_shot_path.get_basename() + "_puzzle.png")
		get_tree().quit()


func _save_shot(path: String) -> void:
	var err := get_viewport().get_texture().get_image().save_png(path)
	print("SHOT echo_prototype: %s (%s)" % [ProjectSettings.globalize_path(path), error_string(err)])


func _on_interact_requested(echo: EchoObject) -> void:
	_pending = echo
	_message = ""
	_puzzle.open(echo.echo_id, echo.emotion())


func _on_solved(_echo_id: String) -> void:
	if _pending != null:
		_pending.collect()
		_message = "%s 의 색이 돌아왔다%s" % [tr(str(EmotionBands.load_emotions()[_pending.emotion()]["name_key"])),
			" (건너뜀)" if _puzzle.was_skipped else ""]
	_pending = null
	if _collected_count() == _total_count():
		_message = "모든 잔향을 모았다"
		create_tween().tween_property(_restore, "global_saturation", FINALE_SATURATION, 3.0)
	_update_hud()


func _on_cancelled(_echo_id: String) -> void:
	_pending = null
	_message = ""
	_update_hud()


func _collected_count() -> int:
	var n := 0
	for node in get_tree().get_nodes_in_group(EchoObject.GROUP):
		if (node as EchoObject).is_collected():
			n += 1
	return n


func _total_count() -> int:
	return get_tree().get_nodes_in_group(EchoObject.GROUP).size()


func _update_hud() -> void:
	var lines := PackedStringArray([
		"잔향 %d/%d   지금: %s" % [_collected_count(), _total_count(), GameState.name_display(GameState.active_character)],
		"Shift 길게: 감지 · E: 공명 · Tab: 전환 · 공명 잔향은 둘이 함께",
	])
	if not _message.is_empty():
		lines.append(_message)
	_hud.text = "\n".join(lines)


# ---------------------------------------------------------------- 방 그리기 (임시 도형)

func _draw() -> void:
	draw_rect(Rect2(0, 0, 480, 270), Color("#4a494f"))                 # 벽
	draw_rect(Rect2(16, 120, 448, 134), Color("#7a6858"))              # 바닥(나무)
	for x in range(16, 464, 32):
		draw_line(Vector2(x, 120), Vector2(x, 254), Color("#52443c"), 1.0)
	# 창문 + 파란 커튼 (그리움)
	draw_rect(Rect2(48, 40, 64, 56), Color("#c4c1c9"))
	draw_rect(Rect2(40, 34, 14, 72), Color("#2c5c9e"))
	draw_rect(Rect2(106, 34, 14, 72), Color("#2c5c9e"))
	draw_rect(Rect2(40, 34, 80, 6), Color("#153961"))
	# 보라 별 포스터 (꿈)
	draw_rect(Rect2(212, 30, 56, 64), Color("#edebf0"))
	EmotionSymbols.draw(self, "star", Vector2(240, 60), Color("#7d4599"), 16.0)
	draw_rect(Rect2(220, 84, 40, 4), Color("#b070cc"))
	# 노란 스탠드 (온기)
	draw_rect(Rect2(396, 70, 4, 60), Color("#52443c"))
	draw_colored_polygon(PackedVector2Array([Vector2(384, 74), Vector2(412, 74), Vector2(404, 56), Vector2(392, 56)]), Color("#d1b91f"))
	draw_circle(Vector2(398, 80), 10, Color(Color("#f2e15c"), 0.6))
	# 벽난로 + 주황 불 (용기)
	draw_rect(Rect2(52, 156, 76, 60), Color("#99969e"))
	draw_rect(Rect2(66, 176, 48, 40), Color("#151417"))
	EmotionSymbols.draw(self, "flame", Vector2(90, 200), Color("#cc6529"), 11.0)
	EmotionSymbols.draw(self, "flame", Vector2(90, 203), Color("#f2985c"), 6.0)
	# 초록 화분 (치유)
	draw_rect(Rect2(380, 214, 24, 18), Color("#9e8375"))
	for i in 5:
		EmotionSymbols.draw(self, "leaf", Vector2(392 + (i - 2) * 7, 196 + absi(i - 2) * 3), Color("#389440" if i % 2 == 0 else "#63c771"), 6.0)
	# 러그 (중립 + 파랑·노랑 무늬): 어느 잔향 반경에도 없어서 마지막 전역 채도로만 돌아온다
	draw_rect(Rect2(184, 170, 112, 52), Color("#c9ac99"))
	draw_rect(Rect2(192, 178, 96, 6), Color("#608ed6"))
	draw_rect(Rect2(192, 208, 96, 6), Color("#f2e15c"))
