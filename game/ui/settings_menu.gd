class_name SettingsMenu
extends CanvasLayer
## 설정 메뉴. ↑↓ 항목, ←→ 값 바꾸기(바로 저장), Esc 닫기.

signal closed()

const DEFAULT_LAYER := 45
const KEYS: Array[String] = ["text/speed", "accessibility/echo_sense_mode", "accessibility/puzzle_timer",
	"accessibility/reduced_motion", "accessibility/rumble", "display/scale"]

var is_open: bool = false
var _index: int = 0
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


func open() -> void:
	is_open = true
	visible = true
	_index = 0
	_view.queue_redraw()


func close() -> void:
	is_open = false
	visible = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not is_open:
		return
	if event.is_action_pressed(InputActions.PAUSE) or event.is_action_pressed(&"ui_cancel"):
		close()
	elif event.is_action_pressed(InputActions.MOVE_UP) or event.is_action_pressed(&"ui_up"):
		_index = wrapi(_index - 1, 0, KEYS.size())
	elif event.is_action_pressed(InputActions.MOVE_DOWN) or event.is_action_pressed(&"ui_down"):
		_index = wrapi(_index + 1, 0, KEYS.size())
	elif EchoPuzzle.is_left(event):
		Settings.cycle(KEYS[_index], -1)
	elif EchoPuzzle.is_right(event) or EchoPuzzle.is_confirm(event):
		Settings.cycle(KEYS[_index], 1)
	else:
		return
	Audio.play_sfx("ui_move", "UI")
	get_viewport().set_input_as_handled()
	_view.queue_redraw()


func _on_draw() -> void:
	var size := _view.get_viewport_rect().size
	var font := _view.get_theme_default_font()
	_view.draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.85))
	_view.draw_string(font, Vector2(0, 50), "설정", HORIZONTAL_ALIGNMENT_CENTER, size.x, 11, Color("#99969e"))
	for i in KEYS.size():
		var key := KEYS[i]
		var selected := i == _index
		var c := Color("#edebf0") if selected else Color("#6e6c73")
		var y := 84.0 + i * 20.0
		_view.draw_string(font, Vector2(90, y), ("▶ " if selected else "   ") + str(Settings.LABELS[key]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, c)
		_view.draw_string(font, Vector2(260, y), "◀ %s ▶" % Settings.label_of(key) if selected else Settings.label_of(key),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 11, c)
	_view.draw_string(font, Vector2(0, size.y - 14), "↑↓ 항목 · ←→ 바꾸기 · Esc 닫기", HORIZONTAL_ALIGNMENT_CENTER, size.x, 9, Color("#6e6c73"))
