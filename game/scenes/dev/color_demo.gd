extends Node2D
## WP-05 색 복원 셰이더 스파이크 데모.
##
## 조작: 왼쪽 드래그 = 색 칠하기, 오른쪽 클릭 = 잔향 펄스, 1~5 = 감정 대역 켜기/끄기, 0 = 대역 해제(모든 색),
##       Q/W = 전역 채도 -/+, N = 중립색 보호 켜기/끄기, R = 마스크 지우기
## 성능 측정: godot --path . res://game/scenes/dev/color_demo.tscn -- --bench
##   (vsync 끄고 최악 조건(전 화면 마스크 + 5대역)으로 600프레임 측정 후 결과를 출력하고 종료)

const BENCH_WARMUP_FRAMES := 60
const BENCH_FRAMES := 600

@onready var _painter: ColorMaskPainter = $MaskViewport/MaskPainter
@onready var _mask_viewport: SubViewport = $MaskViewport
@onready var _rect: ColorRect = $RestoreLayer/RestoreRect
@onready var _hud: Label = $HudLayer/Hud

var _material: ShaderMaterial
var _active: Array[String] = []
var _painting := false
var _last_pos := Vector2.ZERO
var _neutral_guard := true
var _bench := false
var _bench_frame := 0
var _bench_start_usec := 0


func _ready() -> void:
	_mask_viewport.size = Vector2i(get_viewport().get_visible_rect().size)
	_material = _rect.material as ShaderMaterial
	_material.set_shader_parameter("color_mask", _mask_viewport.get_texture())
	EmotionBands.apply(_material, _active)
	_bench = OS.get_cmdline_user_args().has("--bench")
	if _bench:
		_start_bench()
	_update_hud()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		var pos := get_global_mouse_position()
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_painting = mb.pressed
			if mb.pressed:
				_painter.stamp(pos)
				_last_pos = pos
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			_painter.pulse(pos)
	elif event is InputEventMouseMotion and _painting:
		var pos := get_global_mouse_position()
		_painter.stroke(_last_pos, pos)
		_last_pos = pos
	elif event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and not key.echo:
			_handle_key(key.keycode)


func _handle_key(code: Key) -> void:
	match code:
		KEY_1, KEY_2, KEY_3, KEY_4, KEY_5:
			var id := EmotionBands.EMOTION_IDS[int(code) - int(KEY_1)]
			if _active.has(id):
				_active.erase(id)
			else:
				_active.append(id)
			EmotionBands.apply(_material, _active)
		KEY_0:
			_active.clear()
			EmotionBands.apply(_material, _active)
		KEY_Q, KEY_W:
			var delta := -0.1 if code == KEY_Q else 0.1
			var s := float(_material.get_shader_parameter("global_saturation"))
			_material.set_shader_parameter("global_saturation", clampf(s + delta, 0.0, 1.0))
		KEY_N:
			_neutral_guard = not _neutral_guard
			_material.set_shader_parameter("band_min_saturation", 0.35 if _neutral_guard else 0.0)
		KEY_R:
			_painter.clear()
		_:
			return
	_update_hud()


func _process(_delta: float) -> void:
	if _bench:
		_tick_bench()
	elif Engine.get_process_frames() % 15 == 0:
		_update_hud()


func _update_hud() -> void:
	var names := ", ".join(PackedStringArray(_active)) if not _active.is_empty() else "(없음: 마스크 영역 전체 복원)"
	_hud.text = "색 복원 스파이크  FPS %d\n대역: %s\n전역 채도 %.1f  중립색 보호 %s  도장 %d\n좌드래그 칠하기 / 우클릭 펄스 / 1~5 대역 / 0 해제 / Q,W 채도 / N 보호 / R 지우기" % [
		Engine.get_frames_per_second(),
		names,
		float(_material.get_shader_parameter("global_saturation")),
		"켬" if _neutral_guard else "끔",
		_painter.stamp_count(),
	]


func _start_bench() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	_active.assign(EmotionBands.EMOTION_IDS)
	EmotionBands.apply(_material, _active)
	# 최악 조건: 화면 전체를 마스크로 덮는다
	var size := get_viewport().get_visible_rect().size
	for y in range(0, int(size.y) + 24, 24):
		for x in range(0, int(size.x) + 24, 24):
			_painter.stamp(Vector2(x, y), 24.0)


func _tick_bench() -> void:
	_bench_frame += 1
	if _bench_frame == BENCH_WARMUP_FRAMES:
		_bench_start_usec = Time.get_ticks_usec()
	elif _bench_frame == BENCH_WARMUP_FRAMES + BENCH_FRAMES:
		var elapsed := float(Time.get_ticks_usec() - _bench_start_usec) / 1_000_000.0
		var fps := BENCH_FRAMES / elapsed
		print("BENCH color_restore: renderer=%s frames=%d avg_fps=%.1f avg_frame_ms=%.3f stamps=%d bands=%d" % [
			RenderingServer.get_current_rendering_method(),
			BENCH_FRAMES, fps, 1000.0 / fps, _painter.stamp_count(), _active.size(),
		])
		get_tree().quit(0 if fps >= 60.0 else 1)
