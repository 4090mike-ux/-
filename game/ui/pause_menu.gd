class_name PauseMenu
extends CanvasLayer
## 일시정지 메뉴 (Esc/P/Start): 계속 / 저장(슬롯 1) / 불러오기(슬롯 1) / 타이틀로.
## 대사·퍼즐 중에는 열리지 않는다(그때 pause 는 그쪽이 쓴다).

const DEFAULT_LAYER := 40
const ITEMS: Array[String] = ["resume", "save", "load", "settings", "title"]
const LABELS := {"resume": "계속", "save": "저장하기", "load": "불러오기", "settings": "설정", "title": "타이틀로"}
const MANUAL_SLOT := 1

var is_open: bool = false
var _index: int = 0
var _message: String = ""
var _view: Control
var _settings: SettingsMenu


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
	_settings = SettingsMenu.new()
	add_child(_settings)


func open() -> void:
	if get_tree().paused:
		return  # 대사·퍼즐 중
	is_open = true
	visible = true
	_index = 0
	_message = ""
	get_tree().paused = true
	_view.queue_redraw()


func close() -> void:
	is_open = false
	visible = false
	get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if _settings.is_open:
		return
	if not is_open:
		if event.is_action_pressed(InputActions.PAUSE) and not SceneRouter.is_busy():
			open()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(InputActions.PAUSE) or event.is_action_pressed(&"ui_cancel"):
		close()
	elif event.is_action_pressed(InputActions.MOVE_UP) or event.is_action_pressed(&"ui_up"):
		_index = wrapi(_index - 1, 0, ITEMS.size())
	elif event.is_action_pressed(InputActions.MOVE_DOWN) or event.is_action_pressed(&"ui_down"):
		_index = wrapi(_index + 1, 0, ITEMS.size())
	elif event.is_action_pressed(InputActions.INTERACT) or event.is_action_pressed(&"ui_accept"):
		_select(ITEMS[_index])
	else:
		return
	get_viewport().set_input_as_handled()
	_view.queue_redraw()


func _select(item: String) -> void:
	match item:
		"resume":
			close()
		"save":
			_message = "저장했다" if SaveService.save_slot(MANUAL_SLOT) == OK else "저장 실패"
		"load":
			if not SaveService.has_slot(MANUAL_SLOT):
				_message = "저장한 기록이 없다"
			elif SaveService.load_slot(MANUAL_SLOT) == OK:
				close()
				await SceneRouter.continue_from_save()
			else:
				_message = "불러오기 실패"
		"settings":
			_settings.open()
		"title":
			close()
			get_tree().change_scene_to_file("res://game/scenes/ui/title.tscn")


func _on_draw() -> void:
	var size := _view.get_viewport_rect().size
	var font := _view.get_theme_default_font()
	_view.draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.6))
	_view.draw_string(font, Vector2(0, 80), "일시정지", HORIZONTAL_ALIGNMENT_CENTER, size.x, 11, Color("#99969e"))
	for i in ITEMS.size():
		var selected := i == _index
		_view.draw_string(font, Vector2(0, 110 + i * 18), ("▶ " if selected else "   ") + str(LABELS[ITEMS[i]]),
			HORIZONTAL_ALIGNMENT_CENTER, size.x, 11, Color("#edebf0") if selected else Color("#6e6c73"))
	if not _message.is_empty():
		_view.draw_string(font, Vector2(0, 200), _message, HORIZONTAL_ALIGNMENT_CENTER, size.x, 9, Color("#c4c1c9"))
