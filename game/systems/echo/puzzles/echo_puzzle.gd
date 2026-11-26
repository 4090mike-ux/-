class_name EchoPuzzle
extends CanvasLayer
## 공명 퍼즐 공통 (docs/gdd/echo.md §3). 실패는 없다.
## - time_limit(초)은 '힌트 타이머': 넘기면 give_hint() 하고 다시 잰다. 0 = 자동 힌트 없음.
## - 힌트를 max_hints 번 받으면 tag_switch 로 건너뛸 수 있다(보상 동일). 2인 변형처럼 tag_switch 를
##   퍼즐이 쓰면(_uses_tag_switch) tag_switch 를 1초 길게 눌러 건너뛴다.
## - 자동 힌트를 끈 설정이면 echo_sense 를 3초 길게 눌러 수동 힌트 (짧게 누르기는 퍼즐이 쓴다: 잔상 다시 보기).
## - 하위 클래스: _setup(data), _on_hint(), _on_input(event) -> bool, _draw_puzzle(view), is_complete().

signal solved(echo_id: String)
signal cancelled(echo_id: String)

const DEFAULT_LAYER := 30

@export var time_limit: float = 30.0
@export var max_hints: int = 2
@export var pause_tree: bool = true
@export var use_settings: bool = true

var echo_id: String = ""
var data: Dictionary = {}
var is_open: bool = false
var hints_given: int = 0
var was_skipped: bool = false
var time_left: float = 0.0
var feedback: String = ""          # "ok" / "no" — 잠깐 보이는 반응
var feedback_time: float = 0.0

const MANUAL_HINT_HOLD := 3.0
const SKIP_HOLD := 1.0
var _sense_held: float = 0.0
var _switch_held: float = 0.0

var _view: Control


func _ready() -> void:
	if layer == 1:
		layer = DEFAULT_LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_view = Control.new()
	_view.name = "View"
	_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_view.draw.connect(_on_draw)
	add_child(_view)


func open(id: String, puzzle_data: Dictionary) -> void:
	echo_id = id
	data = puzzle_data
	hints_given = 0
	was_skipped = false
	feedback = ""
	if puzzle_data.has("time_limit_sec"):
		time_limit = float(puzzle_data["time_limit_sec"])
	if use_settings and not Settings.puzzle_auto_hint():
		time_limit = 0.0  # 자동 힌트 끔 → echo_sense 로 수동 힌트
	time_left = time_limit
	_setup(puzzle_data)
	is_open = true
	visible = true
	if pause_tree:
		get_tree().paused = true
	Audio.play_sfx("pzl_open")
	_view.queue_redraw()


func close() -> void:
	is_open = false
	visible = false
	if pause_tree:
		get_tree().paused = false


func can_skip() -> bool:
	return is_open and hints_given >= max_hints


func skip() -> bool:
	if not can_skip():
		return false
	was_skipped = true
	_finish()
	return true


func give_hint() -> void:
	if hints_given < max_hints:
		hints_given += 1
	time_left = time_limit
	Audio.play_sfx("pzl_hint")
	_on_hint()
	_check_complete()


func advance(delta: float) -> void:
	if not is_open:
		return
	feedback_time = maxf(0.0, feedback_time - delta)
	if time_limit > 0.0:
		time_left -= delta
		if time_left <= 0.0:
			give_hint()


func flash(kind: String) -> void:
	Audio.play_sfx("pzl_place_ok" if kind == "ok" else "pzl_place_no")
	feedback = kind
	feedback_time = 0.35
	_view.queue_redraw()


func _process(delta: float) -> void:
	if is_open:
		advance(delta)
		_track_holds(delta)
		_view.queue_redraw()


func _track_holds(delta: float) -> void:
	if time_limit <= 0.0 and Input.is_action_pressed(InputActions.ECHO_SENSE):
		_sense_held += delta
		if _sense_held >= MANUAL_HINT_HOLD:
			_sense_held = 0.0
			give_hint()
	else:
		_sense_held = 0.0
	if _uses_tag_switch() and can_skip() and Input.is_action_pressed(InputActions.TAG_SWITCH):
		_switch_held += delta
		if _switch_held >= SKIP_HOLD:
			_switch_held = 0.0
			skip()
	else:
		_switch_held = 0.0


func _unhandled_input(event: InputEvent) -> void:
	if not is_open:
		return
	if event.is_action_pressed(InputActions.TAG_SWITCH) and can_skip() and not _uses_tag_switch():
		skip()
	elif _on_input(event):
		_check_complete()
	elif event.is_action_pressed(InputActions.PAUSE) or event.is_action_pressed(&"ui_cancel"):
		var id := echo_id
		close()
		cancelled.emit(id)
	else:
		return
	get_viewport().set_input_as_handled()


func _check_complete() -> void:
	if is_open and is_complete():
		_finish()


func _finish() -> void:
	var id := echo_id
	close()
	solved.emit(id)


## 입력이 왼쪽/오른쪽/확인인지
static func is_left(event: InputEvent) -> bool:
	return event.is_action_pressed(InputActions.MOVE_LEFT) or event.is_action_pressed(&"ui_left")


static func is_right(event: InputEvent) -> bool:
	return event.is_action_pressed(InputActions.MOVE_RIGHT) or event.is_action_pressed(&"ui_right")


static func is_confirm(event: InputEvent) -> bool:
	return event.is_action_pressed(InputActions.INTERACT) or event.is_action_pressed(&"ui_accept")


func _on_draw() -> void:
	var size := _view.get_viewport_rect().size
	_view.draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.78))
	_draw_puzzle(_view)
	var font := ThemeDB.fallback_font
	var caption := str(data.get("caption", ""))
	if not caption.is_empty():
		_view.draw_string(font, Vector2(0, 26), caption, HORIZONTAL_ALIGNMENT_CENTER, size.x, 11, Color(1, 1, 1, 0.95))
	var hint := _help_text()
	if hints_given > 0:
		hint = "힌트 %d · " % hints_given + hint
	if can_skip():
		hint += " · Tab 길게 건너뛰기" if _uses_tag_switch() else " · Tab 건너뛰기"
	elif time_limit <= 0.0:
		hint += " · Q 3초 힌트"
	_view.draw_string(font, Vector2(0, size.y - 10), hint, HORIZONTAL_ALIGNMENT_CENTER, size.x, 9, Color(1, 1, 1, 0.75))
	if time_limit > 0.0:
		var w := 120.0 * clampf(time_left / time_limit, 0.0, 1.0)
		_view.draw_rect(Rect2(size.x * 0.5 - 60.0, size.y - 26.0, w, 2.0), Color(1, 1, 1, 0.4))


# ---------------------------------------------------------------- 하위 클래스가 채운다

func _setup(_puzzle_data: Dictionary) -> void:
	pass


func _on_hint() -> void:
	pass


func _on_input(_event: InputEvent) -> bool:
	return false


func _draw_puzzle(_canvas: Control) -> void:
	pass


func _help_text() -> String:
	return ""


## tag_switch 를 퍼즐 안에서 쓰는가 (2인 변형)
func _uses_tag_switch() -> bool:
	return false


func is_complete() -> bool:
	return false
