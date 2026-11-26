class_name MemoryView
extends CanvasLayer
## 기억 컷 (echo.md §4) + 기억 공유 분할 화면 (sibling.md §8).
##
## 잔향을 모으면 장면이 open(echo_id) → 그 잔향의 _after 대사 → close() 순으로 부른다.
## 대사 상자(층 25)보다 아래(층 22)에 그려서, 기억 컷을 보면서 대사를 읽는다.
##
## - 그림: res://game/art/memory/<slug>.png (필수 240×135, 숨김 120×68, 공명 480×270).
##   reward.memory_cut 에 경로가 있으면 그것을 쓴다.
## - 그림이 아직 없으면 '글 컷': 감정 기호 + 잔향 이름 카드 (공명이면 두 사람 초상을 양쪽에).
## - 공명(sensed_by both): 세로로 반 나눈 화면이 위·아래에서 닦여 들어오고, 닫을 때 가운데로 합쳐진다.
## - 움직임 줄이기: 닦아내기 대신 교차 페이드.

signal opened()
signal closed()

const DEFAULT_LAYER := 22
const MEMORY_DIR := "res://game/art/memory"
const CUT_TOP := 26.0
const PAPER := Color("#2a2830")
const INK := Color("#e8e6eb")

var is_open: bool = false
var shared: bool = false
var echo_id: String = ""
var emotion: String = ""
var _root: Control
var _dim: ColorRect
var _halves: Array[Control] = []
var _texture: Texture2D = null


func _ready() -> void:
	layer = DEFAULT_LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_root = Control.new()
	_root.size = Vector2(480, 270)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.55)
	_dim.size = Vector2(480, 270)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_dim)


static func image_path(id: String) -> String:
	var def := GameData.echo_def(id)
	var custom := str((def.get("reward", {}) as Dictionary).get("memory_cut", ""))
	if custom.ends_with(".png") and ResourceLoader.exists(custom):
		return custom
	var path := "%s/%s.png" % [MEMORY_DIR, id.get_slice(".", 2)]
	return path if ResourceLoader.exists(path) else ""


func open(id: String) -> void:
	if is_open:
		await close()
	echo_id = id
	var def := GameData.echo_def(id)
	emotion = str(def.get("emotion", "longing"))
	shared = str(def.get("sensed_by", "")) == "both"
	var path := image_path(id)
	_texture = load(path) as Texture2D if not path.is_empty() else null
	for h in _halves:
		h.queue_free()
	_halves.clear()
	is_open = true
	visible = true
	Audio.play_sfx("sib_split_open" if shared else "color_memory_open")
	EchoBus.memory_opened.emit(id, shared)
	var reduced := bool(Settings.get_value("accessibility/reduced_motion"))
	var tween := create_tween().set_parallel(true)
	_dim.color.a = 0.0
	tween.tween_property(_dim, "color:a", 0.55, 0.3)
	if shared:
		for side in 2:
			var half := _make_half(side)
			_halves.append(half)
			_root.add_child(half)
			if reduced:
				half.modulate.a = 0.0
				tween.tween_property(half, "modulate:a", 1.0, 0.4)
			else:
				half.position.y = -270.0 if side == 0 else 270.0
				tween.tween_property(half, "position:y", 0.0, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		if _texture == null:
			var caption := _make_caption(def)
			_halves.append(caption)
			_root.add_child(caption)
			caption.modulate.a = 0.0
			tween.tween_property(caption, "modulate:a", 1.0, 0.3).set_delay(0.3)
	else:
		var card := _make_card(def)
		_halves.append(card)
		_root.add_child(card)
		card.modulate.a = 0.0
		tween.tween_property(card, "modulate:a", 1.0, 0.35)
	await tween.finished
	opened.emit()


func close() -> void:
	if not is_open:
		return
	Audio.play_sfx("sib_split_close" if shared else "color_memory_close")
	var reduced := bool(Settings.get_value("accessibility/reduced_motion"))
	var tween := create_tween().set_parallel(true)
	if shared and not reduced and _halves.size() == 2:
		# 가운데로 합쳐진다: 두 반쪽이 서로를 향해 좁아지며 겹친다
		tween.tween_property(_halves[0], "position:x", 120.0, 0.4).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(_halves[1], "position:x", -120.0, 0.4).set_trans(Tween.TRANS_CUBIC)
		tween.chain().tween_property(_root, "modulate:a", 0.0, 0.35)
	else:
		tween.tween_property(_root, "modulate:a", 0.0, 0.35)
	await tween.finished
	for h in _halves:
		h.queue_free()
	_halves.clear()
	_root.modulate.a = 1.0
	visible = false
	is_open = false
	closed.emit()


## 필수·숨김 잔향의 기억 컷 (그림 또는 글 컷)
func _make_card(def: Dictionary) -> Control:
	var hidden := str(def.get("kind", "required")) == "hidden"
	var size := Vector2(120, 68) if hidden else Vector2(240, 135)
	if _texture != null:
		size = _texture.get_size()
	var card := Control.new()
	card.size = size + Vector2(4, 4)
	card.position = Vector2(roundf((480.0 - card.size.x) / 2.0), CUT_TOP)
	var accent := _accent()
	var name_text := tr(str(def.get("name_key", echo_id)))
	var tex := _texture
	card.draw.connect(func() -> void:
		card.draw_rect(Rect2(Vector2.ZERO, card.size), accent)
		card.draw_rect(Rect2(Vector2.ONE, card.size - Vector2(2, 2)), Color.BLACK)
		if tex != null:
			card.draw_texture(tex, Vector2(2, 2))
		else:
			card.draw_rect(Rect2(Vector2(2, 2), size), PAPER)
			EmotionSymbols.draw(card, EmotionSymbols.symbol_of(emotion), Vector2(card.size.x / 2.0, card.size.y / 2.0 - 10.0),
				accent, 10.0 if not hidden else 6.0)
			var font := card.get_theme_default_font()
			var w := font.get_string_size(name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
			card.draw_string(font, Vector2((card.size.x - w) / 2.0, card.size.y - 18.0), name_text,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 11, INK))
	return card


## 공명 잔향 분할 화면의 한쪽 (0 = 왼쪽·하늘, 1 = 오른쪽·별)
func _make_half(side: int) -> Control:
	var half := Control.new()
	half.size = Vector2(480, 270)
	half.clip_contents = false
	var view := Control.new()
	view.position = Vector2(240.0 * side, 0)
	view.size = Vector2(240, 270)
	view.clip_contents = true
	half.add_child(view)
	var accent := _accent()
	var tex := _texture
	var key := "haneul" if side == 0 else "byeol"
	var portrait := _portrait(key)
	view.draw.connect(func() -> void:
		if tex != null:
			view.draw_texture(tex, Vector2(-240.0 * side, 0))
		else:
			view.draw_rect(Rect2(Vector2.ZERO, view.size), PAPER if side == 0 else PAPER.lightened(0.04))
			if portrait != null:
				view.draw_texture_rect(portrait, Rect2(Vector2(56, 34), Vector2(128, 128)), false)
			EmotionSymbols.draw(view, EmotionSymbols.symbol_of(emotion), Vector2(120, 22), accent, 8.0)
		# 가운데 경계선
		var edge_x := 239.0 if side == 0 else 0.0
		view.draw_rect(Rect2(edge_x, 0, 1, 270), accent))
	return half


## 글 컷 공명 화면의 가운데 이름표 (두 반쪽 위에 그린다)
func _make_caption(def: Dictionary) -> Control:
	var name_text := tr(str(def.get("name_key", echo_id)))
	var caption := Control.new()
	caption.size = Vector2(480, 270)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.draw.connect(func() -> void:
		var font := caption.get_theme_default_font()
		var w := font.get_string_size(name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		caption.draw_rect(Rect2(240.0 - w / 2.0 - 6.0, 168, w + 12.0, 16), Color(0, 0, 0, 0.7))
		caption.draw_string(font, Vector2(240.0 - w / 2.0, 180), name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, INK))
	return caption


func _accent() -> Color:
	return EmotionBands.main_color(emotion) if EmotionBands.EMOTION_IDS.has(emotion) else Color("#c4c1c9")


func _portrait(key: String) -> Texture2D:
	var path := "res://game/art/char/%s_portrait.png" % key
	if not ResourceLoader.exists(path):
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = load(path) as Texture2D
	atlas.region = Rect2(0, 0, 64, 64)
	return atlas
