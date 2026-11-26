class_name EmotionSymbols
extends RefCounted
## 감정 기호(물결·해·별·불꽃·잎)를 그린다. 색각 이상 대응을 위해 감정 색은 항상 이 기호와 함께 표시한다.
## size = 기호의 대략적인 반지름(px). 480×270 기준 최소 3.5(=7×7px).


static func draw(canvas: CanvasItem, symbol: String, center: Vector2, color: Color, size: float = 14.0) -> void:
	var k := size / 14.0
	match symbol:
		"wave":
			for row in 3:
				var pts := PackedVector2Array()
				for i in 17:
					var px := center.x + (-16.0 + i * 2.0) * k
					pts.append(Vector2(px, center.y + (-8.0 + row * 8.0 + sin(i * 0.8) * 2.5) * k))
				canvas.draw_polyline(pts, color, maxf(1.0, 2.0 * k))
		"sun":
			canvas.draw_circle(center, 7.0 * k, color)
			for i in 8:
				var a := TAU * i / 8.0
				canvas.draw_line(center + Vector2.from_angle(a) * 10.0 * k, center + Vector2.from_angle(a) * 15.0 * k,
					color, maxf(1.0, 2.0 * k))
		"star":
			var pts := PackedVector2Array()
			for i in 10:
				var rad := (14.0 if i % 2 == 0 else 6.0) * k
				pts.append(center + Vector2.from_angle(-PI / 2.0 + TAU * i / 10.0) * rad)
			canvas.draw_colored_polygon(pts, color)
		"flame":
			canvas.draw_colored_polygon(PackedVector2Array([
				center + Vector2(0, -15) * k, center + Vector2(8, 0) * k, center + Vector2(6, 9) * k,
				center + Vector2(0, 13) * k, center + Vector2(-6, 9) * k, center + Vector2(-8, 0) * k,
			]), color)
		"leaf":
			var pts := PackedVector2Array()
			for i in 24:
				var a := TAU * i / 24.0
				pts.append(center + (Vector2(cos(a) * 7.0, sin(a) * 14.0) * k).rotated(0.6))
			canvas.draw_colored_polygon(pts, color)
		_:
			canvas.draw_circle(center, 8.0 * k, color)


## 감정 id 로 기호 이름 찾기
static func symbol_of(emotion_id: String) -> String:
	var entry: Dictionary = EmotionBands.load_emotions().get(emotion_id, {})
	return str(entry.get("symbol", ""))
