class_name PlantMenu
extends CanvasLayer
## 정원 칸 심기 메뉴. 활성 캐릭터의 주머니 감정(색 + 기호 + 개수)과 "비우기"를 보여 준다.
## 상대 줄이면 심을 수 없다는 안내만 띄운다(Tab 으로 바꿔서 심는다).

signal closed()

const DEFAULT_LAYER := 32

@export var pause_tree: bool = true

var plot_id: String = ""
var options: Array[String] = []   # 감정 id 또는 "clear"
var cursor: int = 0
var is_open: bool = false
var message: String = ""
var _view: Control


func _ready() -> void:
	if layer == 1:
		layer = DEFAULT_LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_view = Control.new()
	_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_view.draw.connect(_on_draw)
	add_child(_view)


func open(id: String) -> void:
	plot_id = id
	cursor = 0
	message = ""
	options.clear()
	var owner := GardenModel.owner_of(id)
	if owner != GameState.active_character:
		message = "%s 의 줄이다. Tab 으로 바꿔서 심자." % GameState.name_display(owner)
	else:
		var pocket := GardenModel.pocket(owner)
		for e in GardenModel.EMOTIONS:
			if int(pocket.get(e, 0)) > 0:
				options.append(e)
		if GardenModel.planted().has(id):
			options.append("clear")
		if options.is_empty():
			message = "주머니에 색 조각이 없다."
	is_open = true
	visible = true
	if pause_tree:
		get_tree().paused = true
	_view.queue_redraw()


func close() -> void:
	is_open = false
	visible = false
	if pause_tree:
		get_tree().paused = false
	closed.emit()


## 현재 커서의 선택을 실행 (테스트에서도 부른다)
func confirm() -> bool:
	if options.is_empty():
		close()
		return false
	var choice := options[cursor]
	var ok := true
	if choice == "clear":
		GardenModel.clear(plot_id)
	else:
		ok = GardenModel.plant(plot_id, choice, GameState.active_character)
	close()
	return ok


func _unhandled_input(event: InputEvent) -> void:
	if not is_open:
		return
	if EchoPuzzle.is_left(event) and not options.is_empty():
		cursor = wrapi(cursor - 1, 0, options.size())
	elif EchoPuzzle.is_right(event) and not options.is_empty():
		cursor = wrapi(cursor + 1, 0, options.size())
	elif EchoPuzzle.is_confirm(event):
		confirm()
	elif event.is_action_pressed(InputActions.PAUSE) or event.is_action_pressed(&"ui_cancel"):
		close()
	else:
		return
	get_viewport().set_input_as_handled()
	_view.queue_redraw()


func _on_draw() -> void:
	var size := _view.get_viewport_rect().size
	var font := _view.get_theme_default_font()
	var box := Rect2(Vector2(size.x * 0.5 - 120, size.y - 92), Vector2(240, 56))
	_view.draw_rect(box, Color(0.06, 0.06, 0.07, 0.94))
	_view.draw_rect(box, Color("#c4c1c9"), false, 1.0)
	if not message.is_empty():
		_view.draw_string(font, box.position + Vector2(0, 32), message, HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 9, Color("#edebf0"))
		return
	var pocket := GardenModel.pocket(GameState.active_character)
	var n := options.size()
	for i in n:
		var center := box.position + Vector2(box.size.x * (i + 0.5) / n, 24)
		var choice := options[i]
		if choice == "clear":
			_view.draw_string(font, center + Vector2(-16, 4), "비우기", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("#edebf0"))
		else:
			_view.draw_circle(center, 10.0, EmotionBands.main_color(choice))
			EmotionSymbols.draw(_view, EmotionSymbols.symbol_of(choice), center, Color(1, 1, 1, 0.95), 5.0)
			_view.draw_string(font, center + Vector2(-6, 22), "×%d" % int(pocket.get(choice, 0)), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("#c4c1c9"))
		if i == cursor:
			_view.draw_rect(Rect2(center - Vector2(13, 13), Vector2(26, 26)), Color.WHITE, false, 1.0)
	_view.draw_string(font, box.position + Vector2(0, box.size.y - 4), "←→ 고르기 · E 심기", HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 9, Color("#99969e"))
