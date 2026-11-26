class_name ProtectCutIn
extends CanvasLayer
## 보호 본능 컷인 (sibling.md §7). 대사 줄의 [#cutin=protect] 에서 대사 상자가 부른다.
##
## - 1.2초, 입력 잠금. 그 장면에서 본 적 있는 컷인은 interact 로 건너뛸 수 있다.
## - 보호자 = 활성 캐릭터. bond 3 전에는 항상 하늘(관계 회복 전 연출).
## - 그림: 보호자 초상(크게, 앞) + 지켜지는 사람 초상(뒤, 어둡게) + 가로 속도선 띠.
## - 움직임 줄이기: 미끄러짐·흔들림 없이 정지 그림 페이드.

signal finished()

const DEFAULT_LAYER := 40
const DURATION := 1.2
const BAND := Rect2(0, 62, 480, 132)
const PORTRAIT_SIZE := Vector2(64, 64)
const PORTRAIT_INDEX := {"neutral": 0, "smile": 1, "sad": 2, "surprised": 3}

var is_playing: bool = false
var protector: String = ""
var _root: Control
var _band: Control
var _front: TextureRect
var _back: TextureRect
var _flash: ColorRect
var _skippable: bool = false
var _skipped: bool = false
var _lines_offset: float = 0.0


func _ready() -> void:
	layer = DEFAULT_LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()


## bond 3 전에는 하늘, 그 뒤로는 활성 캐릭터
static func protector_for(bond: int, active: String) -> String:
	if bond < 3:
		return "haneul"
	return active if active in ["haneul", "byeol"] else "haneul"


static func other_of(key: String) -> String:
	return "byeol" if key == "haneul" else "haneul"


## 컷인을 보여 주고 끝날 때까지 기다린다. seen_key 로 이미 본 컷인이면 interact 로 건너뛴다.
func play(seen_key: String = "") -> void:
	if is_playing:
		return
	is_playing = true
	_skipped = false
	protector = protector_for(GameState.bond, GameState.active_character)
	_skippable = not seen_key.is_empty() and GameState.has_seen_cue(seen_key)
	_front.texture = _portrait(protector, "neutral")
	_back.texture = _portrait(other_of(protector), "surprised")
	visible = true
	Audio.play_sfx("sib_cutin")
	_vibrate()
	var reduced := bool(Settings.get_value("accessibility/reduced_motion"))
	var tween := create_tween()
	if reduced:
		_root.modulate.a = 0.0
		_flash.color.a = 0.0
		_front.position = _front_target()
		_back.position = _back_target()
		tween.tween_property(_root, "modulate:a", 1.0, 0.2)
		tween.tween_interval(DURATION - 0.45)
		tween.tween_property(_root, "modulate:a", 0.0, 0.25)
	else:
		_root.modulate.a = 1.0
		_flash.color.a = 0.9
		_front.position = _front_target() + Vector2(-180, 0)
		_back.position = _back_target() + Vector2(160, 0)
		tween.set_parallel(true)
		tween.tween_property(_flash, "color:a", 0.0, 0.15)
		tween.tween_property(_front, "position", _front_target(), 0.22).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		tween.tween_property(_back, "position", _back_target(), 0.3).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		tween.chain().tween_interval(DURATION - 0.55)
		tween.chain().tween_property(_root, "modulate:a", 0.0, 0.25)
	while tween.is_running() and not _skipped:
		await get_tree().process_frame
	tween.kill()
	if not seen_key.is_empty():
		GameState.mark_cue_seen(seen_key)
	visible = false
	is_playing = false
	EchoBus.protect_cutin_played.emit(protector)
	finished.emit()


func skip() -> void:
	if is_playing and _skippable:
		_skipped = true


func _unhandled_input(event: InputEvent) -> void:
	if not is_playing:
		return
	if event.is_action_pressed(InputActions.INTERACT) or event.is_action_pressed(&"ui_accept"):
		skip()
	get_viewport().set_input_as_handled()  # 컷인 중에는 입력을 잠근다


func _process(delta: float) -> void:
	if is_playing:
		_lines_offset = fmod(_lines_offset + delta * 900.0, 480.0)
		_band.queue_redraw()


func _front_target() -> Vector2:
	return Vector2(132, BAND.position.y + BAND.size.y - PORTRAIT_SIZE.y * 2)


func _back_target() -> Vector2:
	return Vector2(214, BAND.position.y + BAND.size.y - PORTRAIT_SIZE.y * 2 + 4)


func _portrait(key: String, expression: String) -> Texture2D:
	var path := "res://game/art/char/%s_portrait.png" % key
	if not ResourceLoader.exists(path):
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = load(path) as Texture2D
	atlas.region = Rect2(int(PORTRAIT_INDEX.get(expression, 0)) * PORTRAIT_SIZE.x, 0, PORTRAIT_SIZE.x, PORTRAIT_SIZE.y)
	return atlas


func _vibrate() -> void:
	if not bool(Settings.get_value("accessibility/rumble")):
		return
	for pad in Input.get_connected_joypads():
		Input.start_joy_vibration(pad, 0.3, 0.6, 0.25)


func _build() -> void:
	_root = Control.new()
	_root.size = Vector2(480, 270)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.size = Vector2(480, 270)
	_root.add_child(dim)
	_band = Control.new()
	_band.position = BAND.position
	_band.size = BAND.size
	_band.clip_contents = true
	_band.draw.connect(_draw_band)
	_root.add_child(_band)
	_back = TextureRect.new()
	_back.size = PORTRAIT_SIZE * 2
	_back.stretch_mode = TextureRect.STRETCH_SCALE
	_back.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_back.modulate = Color(0.55, 0.55, 0.6)
	_root.add_child(_back)
	_front = TextureRect.new()
	_front.size = PORTRAIT_SIZE * 2
	_front.stretch_mode = TextureRect.STRETCH_SCALE
	_front.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_root.add_child(_front)
	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0)
	_flash.size = Vector2(480, 270)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_flash)


## 띠 + 오른쪽에서 왼쪽으로 흐르는 가로 속도선 (중립색만 — 감정 색은 쓰지 않는다)
func _draw_band() -> void:
	var size := _band.size
	_band.draw_rect(Rect2(Vector2.ZERO, size), Color("#1c1b20"))
	_band.draw_rect(Rect2(0, 0, size.x, 2), Color("#e8e6eb"))
	_band.draw_rect(Rect2(0, size.y - 2, size.x, 2), Color("#e8e6eb"))
	var rows := [10, 22, 31, 47, 58, 69, 83, 95, 104, 117]
	for i in rows.size():
		var y: float = rows[i]
		var length := 40.0 + float((i * 37) % 70)
		var x := fmod(float(i * 113) - _lines_offset + 960.0, size.x + length) - length
		var shade := Color("#8c8a92") if i % 3 else Color("#c4c1c9")
		_band.draw_rect(Rect2(x, y, length, 1), shade)
