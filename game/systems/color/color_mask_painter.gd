class_name ColorMaskPainter
extends Node2D
## 색 복원 마스크를 그린다. SubViewport(화면과 같은 해상도) 안에 두고, 그 텍스처를 셰이더의 color_mask 로 넣는다.
##
## 좌표는 '화면 좌표'다. 카메라가 움직이는 씬에서는 호출하는 쪽이
## get_viewport().get_canvas_transform() * world_pos 로 바꿔서 넘겨야 한다 (WP-13에서 처리).
## 현재 구현은 도장(stamp) 목록을 매 프레임 다시 그리는 방식이다. 스파이크용이며,
## 도장 수가 많아지면 WP-13에서 Image 누적 방식으로 바꾼다.

const MAX_STAMPS := 4096

@export var brush_radius: float = 18.0

var _stamps: PackedVector3Array = PackedVector3Array()  # x, y, radius
var _pulses: Array[Dictionary] = []
var _brush: GradientTexture2D


func _ready() -> void:
	_brush = _make_brush()
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


## 원형 브러시 한 번 찍기
func stamp(screen_pos: Vector2, radius: float = -1.0) -> void:
	var r := brush_radius if radius <= 0.0 else radius
	if _stamps.size() >= MAX_STAMPS:
		_stamps.remove_at(0)
	_stamps.append(Vector3(screen_pos.x, screen_pos.y, r))
	queue_redraw()


## 두 점 사이를 브러시로 메운다 (마우스 이동이 빠를 때 끊김 방지)
func stroke(from: Vector2, to: Vector2, radius: float = -1.0) -> void:
	var r := brush_radius if radius <= 0.0 else radius
	var dist := from.distance_to(to)
	var steps := maxi(1, ceili(dist / (r * 0.5)))
	for i in range(1, steps + 1):
		stamp(from.lerp(to, float(i) / float(steps)), r)


## 잔향 획득 연출: 원이 퍼지며 색이 번진다. 끝나면 최종 반경으로 고정된다.
func pulse(screen_pos: Vector2, max_radius: float = 80.0, duration: float = 0.8) -> void:
	_pulses.append({"pos": screen_pos, "max": max_radius, "t": 0.0, "dur": maxf(duration, 0.01)})


func clear() -> void:
	_stamps.clear()
	_pulses.clear()
	queue_redraw()


func stamp_count() -> int:
	return _stamps.size()


func _process(delta: float) -> void:
	if _pulses.is_empty():
		return
	var still_running: Array[Dictionary] = []
	for p in _pulses:
		p["t"] = float(p["t"]) + delta
		if float(p["t"]) >= float(p["dur"]):
			stamp(p["pos"] as Vector2, float(p["max"]))
		else:
			still_running.append(p)
	_pulses = still_running
	queue_redraw()


func _draw() -> void:
	for s in _stamps:
		_draw_soft(Vector2(s.x, s.y), s.z)
	for p in _pulses:
		var k := ease(float(p["t"]) / float(p["dur"]), 0.4)
		_draw_soft(p["pos"] as Vector2, float(p["max"]) * k)


func _draw_soft(center: Vector2, radius: float) -> void:
	if radius <= 0.5:
		return
	var size := Vector2(radius, radius) * 2.0
	draw_texture_rect(_brush, Rect2(center - size * 0.5, size), false)


func _make_brush() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.65, Color(1, 1, 1, 1))  # 안쪽은 꽉 차고 가장자리만 부드럽게
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 64
	t.height = 64
	return t
