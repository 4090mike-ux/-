extends Node2D
## 색 복원 데모용 테스트 그림 (480×270). 실제 아트가 나오기 전까지 셰이더 검증용으로만 쓴다.
## 위: 전체 Hue 무지개 / 가운데: 감정 5색 ramp + 기호 / 아래: 중립색(회색·피부·나무)

const BG := Color("#2c2c30")
const NEUTRALS: Array[String] = [
	"#151417", "#4a494f", "#99969e", "#edebf0",
	"#e8d3c3", "#c9ac99", "#9e8375", "#7a6858", "#52443c",
]


func _draw() -> void:
	draw_rect(Rect2(0, 0, 480, 270), BG)
	_draw_rainbow(Rect2(16, 70, 448, 14))
	var x := 16.0
	for id in EmotionBands.EMOTION_IDS:
		_draw_emotion_block(id, Vector2(x, 96))
		x += 92.0
	_draw_neutrals(Vector2(16, 214))


func _draw_rainbow(r: Rect2) -> void:
	var steps := int(r.size.x)
	for i in steps:
		var c := Color.from_hsv(float(i) / float(steps), 0.85, 0.9)
		draw_rect(Rect2(r.position.x + i, r.position.y, 1, r.size.y), c)


func _draw_emotion_block(id: String, origin: Vector2) -> void:
	var ramp := EmotionBands.ramp(id)
	for i in ramp.size():
		draw_rect(Rect2(origin + Vector2(i * 20, 0), Vector2(20, 60)), ramp[i])
	# 색각 이상 대응: 모든 감정 색에 기호를 함께 표시한다 (docs/style/art_style.md)
	var symbol_center := origin + Vector2(40, 84)
	var c := EmotionBands.main_color(id)
	var symbol: String = (EmotionBands.load_emotions()[id] as Dictionary)["symbol"]
	_draw_symbol(symbol, symbol_center, c)


func _draw_symbol(symbol: String, center: Vector2, c: Color) -> void:
	match symbol:
		"wave":
			for row in 3:
				var pts := PackedVector2Array()
				for i in 17:
					var px := center.x - 16 + i * 2
					pts.append(Vector2(px, center.y - 8 + row * 8 + sin(i * 0.8) * 2.5))
				draw_polyline(pts, c, 2.0)
		"sun":
			draw_circle(center, 7, c)
			for i in 8:
				var a := TAU * i / 8.0
				draw_line(center + Vector2.from_angle(a) * 10, center + Vector2.from_angle(a) * 15, c, 2.0)
		"star":
			var pts := PackedVector2Array()
			for i in 10:
				var rad := 14.0 if i % 2 == 0 else 6.0
				pts.append(center + Vector2.from_angle(-PI / 2 + TAU * i / 10.0) * rad)
			draw_colored_polygon(pts, c)
		"flame":
			draw_colored_polygon(PackedVector2Array([
				center + Vector2(0, -15), center + Vector2(8, 0), center + Vector2(6, 9),
				center + Vector2(0, 13), center + Vector2(-6, 9), center + Vector2(-8, 0),
			]), c)
		"leaf":
			var pts := PackedVector2Array()
			for i in 24:
				var a := TAU * i / 24.0
				pts.append(center + Vector2(cos(a) * 7, sin(a) * 14).rotated(0.6))
			draw_colored_polygon(pts, c)
			draw_line(center + Vector2(-5, 11), center + Vector2(5, -11), BG, 1.0)
		_:
			draw_circle(center, 8, c)


func _draw_neutrals(origin: Vector2) -> void:
	for i in NEUTRALS.size():
		draw_rect(Rect2(origin + Vector2(i * 49, 0), Vector2(45, 40)), Color(NEUTRALS[i]))
