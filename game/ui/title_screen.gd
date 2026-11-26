extends Control
## 타이틀 화면: 새로 시작 / 이어하기(자동 저장 슬롯 0) / 종료.
## 배경은 흑백 위로 감정 기호 다섯 개가 천천히 떠다니고, 고른 메뉴의 기호만 색을 띤다.

const FIRST_SCENE := "prologue_atelier"
const ITEMS: Array[String] = ["new", "continue", "settings", "quit"]
const LABELS := {"new": "새로 시작", "continue": "이어하기", "settings": "설정", "quit": "종료"}

var _index: int = 0
var _available: Array[String] = []
var _time: float = 0.0
var _starting: bool = false
var _settings: SettingsMenu


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_available.clear()
	for item in ITEMS:
		if item == "continue" and not SaveService.has_slot(SaveService.AUTOSAVE_SLOT):
			continue
		_available.append(item)
	if _available.has("continue"):
		_index = _available.find("continue")
	GameState.count_playtime = false
	Settings.apply()
	_settings = SettingsMenu.new()
	add_child(_settings)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if _starting or _settings.is_open:
		return
	if event.is_action_pressed(InputActions.MOVE_UP) or event.is_action_pressed(&"ui_up"):
		_index = wrapi(_index - 1, 0, _available.size())
	elif event.is_action_pressed(InputActions.MOVE_DOWN) or event.is_action_pressed(&"ui_down"):
		_index = wrapi(_index + 1, 0, _available.size())
	elif event.is_action_pressed(InputActions.INTERACT) or event.is_action_pressed(&"ui_accept"):
		_select(_available[_index])
	else:
		return
	get_viewport().set_input_as_handled()


func _select(item: String) -> void:
	match item:
		"new":
			_starting = true
			GameState.reset()
			GameState.count_playtime = true
			await SceneRouter.go(FIRST_SCENE)
		"continue":
			_starting = true
			if SaveService.load_slot(SaveService.AUTOSAVE_SLOT) == OK:
				GameState.count_playtime = true
				await SceneRouter.continue_from_save()
			_starting = false
		"settings":
			_settings.open()
		"quit":
			get_tree().quit()


func _draw() -> void:
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), Color("#151417"))
	var font := get_theme_default_font()
	var ids := EmotionBands.EMOTION_IDS
	for i in ids.size():
		var a := _time * 0.25 + TAU * i / ids.size()
		var pos := size * 0.5 + Vector2(cos(a) * 170.0, sin(a * 1.3) * 70.0 + 10.0)
		var lit := i == _index % ids.size()
		var c := EmotionBands.main_color(ids[i]) if lit else Color("#4a494f")
		EmotionSymbols.draw(self, EmotionSymbols.symbol_of(ids[i]), pos, c, 7.0)
	draw_string(font, Vector2(0, 96), "공허의 화가", HORIZONTAL_ALIGNMENT_CENTER, size.x, 22, Color("#edebf0"))
	draw_string(font, Vector2(0, 118), "잔향의 색", HORIZONTAL_ALIGNMENT_CENTER, size.x, 11, Color("#99969e"))
	for i in _available.size():
		var selected := i == _index
		var text := ("▶ " if selected else "   ") + str(LABELS[_available[i]])
		draw_string(font, Vector2(0, 170 + i * 18), text, HORIZONTAL_ALIGNMENT_CENTER, size.x, 11,
			Color("#edebf0") if selected else Color("#6e6c73"))
	draw_string(font, Vector2(4, size.y - 6), "v" + str(ProjectSettings.get_setting("application/config/version", "")),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("#4a494f"))
