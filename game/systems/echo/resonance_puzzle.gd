class_name ResonancePuzzle
extends CanvasLayer
## 공명 퍼즐 프로토타입 (WP-14, 'color_match' 계열).
## 감정 기호 5개가 고리를 따라 돈다. 가운데에 보이는 기호(이 잔향의 감정)가 위쪽 표시에 올 때 interact 를 누른다.
## 맞히면 고리가 반대로 더 빨리 돌고, required_hits 번 맞히면 성공. 틀리면 1칸 감소. 시간이 다 되면 실패.
## 색 없이 기호 모양만으로 풀 수 있다(색각 이상 대응, art_style.md §4).

signal solved(echo_id: String)
signal failed(echo_id: String)
signal cancelled(echo_id: String)

const DEFAULT_LAYER := 30
const MARKER_ANGLE := -PI / 2.0
const RING_RADIUS := 62.0

@export var required_hits: int = 3
@export var time_limit: float = 45.0
## 처음 회전 속도(rad/s) [제안]
@export var base_speed: float = 1.6
## 맞힐 때마다 속도 배율 [제안]
@export var speed_step: float = 1.25
## 판정 허용 각도(도) [제안]
@export var tolerance_deg: float = 14.0
## 퍼즐 동안 게임 일시정지 (테스트에서는 끈다)
@export var pause_tree: bool = true

var echo_id: String = ""
var target_emotion: String = ""
var ring_angle: float = 0.0
var speed: float = 0.0
var hits: int = 0
var time_left: float = 0.0
var is_open: bool = false
var last_result: String = ""

var _feedback: float = 0.0
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


func open(id: String, emotion: String) -> void:
	echo_id = id
	target_emotion = emotion
	ring_angle = 0.0
	speed = base_speed
	hits = 0
	time_left = time_limit
	last_result = ""
	is_open = true
	visible = true
	if pause_tree:
		get_tree().paused = true


func close() -> void:
	is_open = false
	visible = false
	if pause_tree:
		get_tree().paused = false


func target_index() -> int:
	return EmotionBands.EMOTION_IDS.find(target_emotion)


func symbol_angle(index: int) -> float:
	return ring_angle + TAU * index / float(EmotionBands.EMOTION_IDS.size())


func is_target_aligned() -> bool:
	return absf(angle_difference(symbol_angle(target_index()), MARKER_ANGLE)) <= deg_to_rad(tolerance_deg)


## interact 한 번. 맞혔으면 true.
func press() -> bool:
	if not is_open:
		return false
	_feedback = 0.35
	if is_target_aligned():
		hits += 1
		last_result = "hit"
		speed = -signf(speed) * absf(speed) * speed_step
		if hits >= required_hits:
			var id := echo_id
			close()
			solved.emit(id)
		return true
	hits = maxi(0, hits - 1)
	last_result = "miss"
	return false


## 시간 진행 (테스트에서 직접 부른다)
func advance(delta: float) -> void:
	if not is_open:
		return
	ring_angle = wrapf(ring_angle + speed * delta, 0.0, TAU)
	time_left -= delta
	if time_left <= 0.0:
		var id := echo_id
		close()
		failed.emit(id)


func _process(delta: float) -> void:
	advance(delta)
	_feedback = maxf(0.0, _feedback - delta)
	if is_open:
		_view.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not is_open:
		return
	if event.is_action_pressed(InputActions.INTERACT) or event.is_action_pressed(&"ui_accept"):
		press()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(InputActions.PAUSE) or event.is_action_pressed(&"ui_cancel"):
		var id := echo_id
		close()
		get_viewport().set_input_as_handled()
		cancelled.emit(id)


func _on_draw() -> void:
	var size := _view.get_viewport_rect().size
	var center := size * 0.5
	_view.draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.72))
	var ring_color := Color(1, 1, 1, 0.25)
	if _feedback > 0.0:
		ring_color = Color(1, 1, 1, 0.9) if last_result == "hit" else Color(0.3, 0.3, 0.3, 0.9)
	_view.draw_arc(center, RING_RADIUS, 0.0, TAU, 64, ring_color, 2.0)
	# 위쪽 판정 표시
	var top := center + Vector2.from_angle(MARKER_ANGLE) * (RING_RADIUS + 14.0)
	_view.draw_colored_polygon(PackedVector2Array([top + Vector2(0, 6), top + Vector2(-5, -3), top + Vector2(5, -3)]), Color.WHITE)
	# 고리 위의 기호들
	for i in EmotionBands.EMOTION_IDS.size():
		var id := EmotionBands.EMOTION_IDS[i]
		var pos := center + Vector2.from_angle(symbol_angle(i)) * RING_RADIUS
		EmotionSymbols.draw(_view, EmotionSymbols.symbol_of(id), pos, EmotionBands.main_color(id), 7.0)
	# 가운데: 찾을 기호
	EmotionSymbols.draw(_view, EmotionSymbols.symbol_of(target_emotion), center, EmotionBands.main_color(target_emotion), 12.0)
	# 맞힌 횟수
	for i in required_hits:
		var dot := center + Vector2((i - (required_hits - 1) * 0.5) * 12.0, RING_RADIUS + 30.0)
		if i < hits:
			_view.draw_circle(dot, 3.5, Color.WHITE)
		else:
			_view.draw_arc(dot, 3.5, 0.0, TAU, 16, Color.WHITE, 1.0)
	# 남은 시간
	var bar := Rect2(center.x - 60.0, size.y - 22.0, 120.0 * clampf(time_left / time_limit, 0.0, 1.0), 3.0)
	_view.draw_rect(bar, Color(1, 1, 1, 0.8))
