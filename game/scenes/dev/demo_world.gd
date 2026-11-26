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
	EmotionSymbols.draw(self, symbol, symbol_center, c)


func _draw_neutrals(origin: Vector2) -> void:
	for i in NEUTRALS.size():
		draw_rect(Rect2(origin + Vector2(i * 49, 0), Vector2(45, 40)), Color(NEUTRALS[i]))
