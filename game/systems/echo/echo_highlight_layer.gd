class_name EchoHighlightLayer
extends CanvasLayer
## 감지된 잔향의 윤곽·기호를 색 복원 레이어(흑백 필터) '위'에 그린다.
## 흑백 필터 아래에 그리면 감지 윤곽까지 회색이 되기 때문이다. follow_viewport 로 카메라를 따라간다.

const DEFAULT_LAYER := 15

var _drawer: Node2D


func _ready() -> void:
	if layer == 1:
		layer = DEFAULT_LAYER
	follow_viewport_enabled = true
	_drawer = Node2D.new()
	_drawer.name = "Drawer"
	_drawer.draw.connect(_on_draw)
	add_child(_drawer)


func _process(_delta: float) -> void:
	_drawer.queue_redraw()


func _on_draw() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	for node in get_tree().get_nodes_in_group(EchoObject.GROUP):
		var echo := node as EchoObject
		if echo == null or not echo.is_sensed():
			continue
		var color := EmotionBands.main_color(echo.emotion())
		var pulse := 0.5 + 0.5 * sin(t * 6.0)
		var a := echo.sense_strength
		color.a = a * (0.55 + 0.45 * pulse)
		_drawer.draw_arc(echo.global_position, echo.outline_radius + pulse * 2.0, 0.0, TAU, 32, color, 1.5)
		var symbol_color := EmotionBands.main_color(echo.emotion())
		symbol_color.a = a
		EmotionSymbols.draw(_drawer, EmotionSymbols.symbol_of(echo.emotion()),
			echo.global_position + Vector2(0, -echo.outline_radius - 9.0), symbol_color, 4.0)
