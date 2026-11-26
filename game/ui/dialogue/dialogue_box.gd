class_name DialogueBox
extends CanvasLayer
## 대사 상자 (WP-21). Dialogue Manager 의 DialogueLine 을 받아 타자기 효과로 보여 준다.
##
## - 화자 키 → GameState.name_display() (R-NAME). 화자 없는 줄은 지문.
## - 태그: [#portrait=표정] 초상, [#emotion=id] 테두리 색 + 기호, [#sync] 남매 동시 발화 연출,
##   [#cutin=protect] 줄 앞에 보호 컷인, [#sfx=id] 효과음, [#bgm=id] 배경음 (빈 값·none = 끄기),
##   응답의 [#choice=id] → GameState.record_choice() 자동 호출.
## - interact/ui_accept: 타자 중이면 끝까지 보여 주고, 다 보였으면 다음 줄. 응답은 위/아래 + 확인.
## - 대사 중에는 게임을 일시정지한다(이 노드는 PROCESS_MODE_ALWAYS).

signal line_shown(character: String, text: String)
signal finished()

const DEFAULT_LAYER := 25
const BOX_RECT := Rect2(8, 194, 464, 70)
const PORTRAIT_SIZE := Vector2(64, 64)
const PORTRAIT_EXPRESSIONS: Array[String] = ["neutral", "smile", "sad", "surprised"]
## 12종 표정 → 지금 있는 4종 초상으로 대체
const EXPRESSION_FALLBACK := {
	"angry": "sad", "scared": "surprised", "worried": "sad", "determined": "neutral",
	"tearful": "sad", "laugh": "smile", "thinking": "neutral", "blank": "neutral",
}

## 글자당 초. use_settings 면 Settings(text/speed) 값을 쓴다
@export var seconds_per_char: float = 0.03
@export var use_settings: bool = true
@export var pause_tree: bool = true

var is_playing: bool = false
var current_line: DialogueLine = null

var _panel: Panel
var _style: StyleBoxFlat
var _name_panel: PanelContainer
var _name_label: Label
var _label: DialogueLabel
var _portrait: TextureRect
var _responses_box: VBoxContainer
var _indicator: Label
var _responses: Array = []
var _response_index: int = 0
var _choosing: bool = false
var _emotion: String = ""
var _scene_id: String = ""
var _cutin: ProtectCutIn

signal _advanced()
signal _chosen(index: int)


func _ready() -> void:
	if layer == 1:
		layer = DEFAULT_LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_ui()


## 대사를 재생하고 끝날 때까지 기다린다.
func play(resource: DialogueResource, cue: String, scene_id: String = "") -> void:
	if resource == null or is_playing:
		return
	is_playing = true
	visible = true
	_scene_id = scene_id
	if use_settings:
		seconds_per_char = Settings.text_seconds_per_char()
	if pause_tree:
		get_tree().paused = true
	DialogueManager.process_mode = Node.PROCESS_MODE_ALWAYS
	EchoBus.dialogue_started.emit(scene_id)
	var line: DialogueLine = await DialogueManager.get_next_dialogue_line(resource, cue)
	while line != null:
		var next_id := await _show_line(line)
		if next_id.is_empty():
			break
		line = await DialogueManager.get_next_dialogue_line(resource, next_id)
	current_line = null
	visible = false
	is_playing = false
	if pause_tree:
		get_tree().paused = false
	EchoBus.dialogue_finished.emit(scene_id)
	finished.emit()


## 다음으로 (입력 대신 테스트에서도 부른다)
func advance() -> void:
	if _choosing:
		_chosen.emit(_response_index)
	elif _label.is_typing:
		_label.skip_typing()
	else:
		_advanced.emit()


func choose(index: int) -> void:
	if _choosing:
		_response_index = clampi(index, 0, _responses.size() - 1)
		_chosen.emit(_response_index)


func _unhandled_input(event: InputEvent) -> void:
	if not is_playing:
		return
	if event.is_action_pressed(InputActions.INTERACT) or event.is_action_pressed(&"ui_accept"):
		advance()
		get_viewport().set_input_as_handled()
	elif _choosing and (event.is_action_pressed(InputActions.MOVE_UP) or event.is_action_pressed(&"ui_up")):
		_move_cursor(-1)
		get_viewport().set_input_as_handled()
	elif _choosing and (event.is_action_pressed(InputActions.MOVE_DOWN) or event.is_action_pressed(&"ui_down")):
		_move_cursor(1)
		get_viewport().set_input_as_handled()


func _show_line(line: DialogueLine) -> String:
	current_line = line
	if line.get_tag_value("cutin") == "protect":
		await _play_cutin(line)
	_apply_speaker(line)
	_apply_tags(line)
	_label.dialogue_line = line
	_label.seconds_per_step = seconds_per_char
	_indicator.visible = false
	_label.type_out()
	line_shown.emit(line.character, line.text)
	if _label.is_typing:
		await _label.finished_typing
	_indicator.visible = line.responses.is_empty()
	if line.responses.is_empty():
		await _advanced
		return line.next_id
	var allowed: Array = line.responses.filter(func(r: DialogueResponse) -> bool: return r.is_allowed)
	var index: int = await _choose(allowed)
	var response: DialogueResponse = allowed[index]
	var choice_id := response.get_tag_value("choice")
	if not choice_id.is_empty():
		GameState.record_choice(choice_id)
	return response.next_id


## 보호 컷인 동안 대사 상자를 숨긴다. 같은 장면·같은 줄의 컷인은 두 번째부터 건너뛸 수 있다.
func _play_cutin(line: DialogueLine) -> void:
	if _cutin == null:
		_cutin = ProtectCutIn.new()
		add_child(_cutin)
	_panel.visible = false
	_name_panel.visible = false
	_portrait.visible = false
	await _cutin.play("%s:cutin:%s" % [_scene_id, line.id])
	_panel.visible = true


func cutin() -> ProtectCutIn:
	return _cutin


func _choose(responses: Array) -> int:
	_responses = responses
	_response_index = 0
	_choosing = true
	_refresh_responses()
	_responses_box.visible = true
	var index: int = await _chosen
	_choosing = false
	_responses_box.visible = false
	return index


func _move_cursor(step: int) -> void:
	_response_index = wrapi(_response_index + step, 0, _responses.size())
	_refresh_responses()


func _refresh_responses() -> void:
	for child in _responses_box.get_children():
		child.queue_free()
	for i in _responses.size():
		var r: DialogueResponse = _responses[i]
		var l := Label.new()
		l.text = ("▶ " if i == _response_index else "   ") + r.text
		l.modulate = Color.WHITE if i == _response_index else Color(1, 1, 1, 0.6)
		_responses_box.add_child(l)


func _apply_speaker(line: DialogueLine) -> void:
	var key := line.character
	var names: Array[String] = []
	if not key.is_empty():
		names.append(_display_name(key))
	for c: DialogueLine in line.concurrent_lines:
		if not c.character.is_empty():
			names.append(_display_name(c.character))
	_name_panel.visible = not names.is_empty()
	_name_label.text = " · ".join(PackedStringArray(names))
	var expression := line.get_tag_value("portrait")
	_set_portrait(key, expression)


func _display_name(key: String) -> String:
	if GameData.speaker(key).is_empty():
		return key  # {{표현식}} 화자 등
	return GameState.name_display(key)


func _set_portrait(key: String, expression: String) -> void:
	var path := "res://game/art/char/%s_portrait.png" % key
	if key.is_empty() or not ResourceLoader.exists(path):
		_portrait.visible = false
		return
	var expr := expression if not expression.is_empty() else "neutral"
	expr = str(EXPRESSION_FALLBACK.get(expr, expr))
	var index := maxi(0, PORTRAIT_EXPRESSIONS.find(expr))
	var atlas := AtlasTexture.new()
	atlas.atlas = load(path) as Texture2D
	atlas.region = Rect2(index * PORTRAIT_SIZE.x, 0, PORTRAIT_SIZE.x, PORTRAIT_SIZE.y)
	_portrait.texture = atlas
	_portrait.visible = true


func _apply_tags(line: DialogueLine) -> void:
	_emotion = line.get_tag_value("emotion")
	var border := Color("#c4c1c9")
	if EmotionBands.EMOTION_IDS.has(_emotion):
		border = EmotionBands.main_color(_emotion)
	_style.border_color = border
	var sync := line.has_tag("sync")
	if sync:
		Audio.play_sfx("dlg_sync", "UI")
	var sfx := line.get_tag_value("sfx")
	if not sfx.is_empty():
		Audio.play_sfx(sfx)
	if line.has_tag("bgm"):
		var bgm := line.get_tag_value("bgm")
		Audio.play_bgm("" if bgm == "none" else bgm)
	_label.modulate = Color(1.0, 1.0, 0.92) if sync else Color.WHITE
	_panel.queue_redraw()


func _build_ui() -> void:
	_style = StyleBoxFlat.new()
	_style.bg_color = Color(0.06, 0.06, 0.07, 0.92)
	_style.border_color = Color("#c4c1c9")
	_style.set_border_width_all(1)
	_style.set_corner_radius_all(2)
	_panel = Panel.new()
	_panel.position = BOX_RECT.position
	_panel.size = BOX_RECT.size
	_panel.add_theme_stylebox_override("panel", _style)
	_panel.draw.connect(_draw_emotion_symbol)
	add_child(_panel)

	_label = DialogueLabel.new()
	_label.spoke.connect(_on_spoke)
	_label.position = Vector2(10, 8)
	_label.size = BOX_RECT.size - Vector2(20, 14)
	_label.bbcode_enabled = true
	_label.scroll_active = false
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_constant_override("line_separation", 3)
	_panel.add_child(_label)

	_indicator = Label.new()
	_indicator.text = "▼"
	_indicator.position = Vector2(BOX_RECT.size.x - 14, BOX_RECT.size.y - 16)
	_panel.add_child(_indicator)

	var name_style := StyleBoxFlat.new()
	name_style.bg_color = Color(0.06, 0.06, 0.07, 0.95)
	name_style.border_color = Color("#c4c1c9")
	name_style.set_border_width_all(1)
	name_style.content_margin_left = 6
	name_style.content_margin_right = 6
	name_style.content_margin_top = 1
	name_style.content_margin_bottom = 1
	_name_panel = PanelContainer.new()
	_name_panel.add_theme_stylebox_override("panel", name_style)
	_name_panel.position = BOX_RECT.position + Vector2(8, -15)
	_name_label = Label.new()
	_name_panel.add_child(_name_label)
	add_child(_name_panel)

	_portrait = TextureRect.new()
	_portrait.size = PORTRAIT_SIZE
	_portrait.position = Vector2(BOX_RECT.end.x - PORTRAIT_SIZE.x - 4, BOX_RECT.position.y - PORTRAIT_SIZE.y)
	_portrait.visible = false
	add_child(_portrait)

	_responses_box = VBoxContainer.new()
	_responses_box.position = Vector2(BOX_RECT.position.x + 12, BOX_RECT.position.y - 64)
	_responses_box.size = Vector2(300, 60)
	_responses_box.alignment = BoxContainer.ALIGNMENT_END
	_responses_box.visible = false
	add_child(_responses_box)


func _on_spoke(letter: String, index: int, _speed: float) -> void:
	if letter.strip_edges().is_empty() or index % 3 != 0 or current_line == null:
		return
	Audio.play_sfx(blip_for(current_line.character), "UI")


func _draw_emotion_symbol() -> void:
	if EmotionBands.EMOTION_IDS.has(_emotion):
		EmotionSymbols.draw(_panel, EmotionSymbols.symbol_of(_emotion), Vector2(BOX_RECT.size.x - 12, 10),
			EmotionBands.main_color(_emotion), 4.5)


## 화자별 글자 블립: 하늘·별은 각자 소리, 나머지는 NPC 블립(없으면 별 소리)
func blip_for(character: String) -> String:
	if character == "haneul":
		return "dlg_blip_haneul"
	if character == "byeol" or not Audio.has_sfx("dlg_blip_npc"):
		return "dlg_blip_byeol"
	return "dlg_blip_npc"
