class_name SymbolSequencePuzzle
extends EchoPuzzle
## 엇갈린 시선 장치 입력 (docs/gdd/sibling.md §4-1). 한 사람만 본 기호 순서를 다른 사람이 장치에 넣는다.
## 데이터: {"sequence": [감정 id...], "palette": [감정 id...] (생략하면 5감정), "caption": "..."}
## 조작: ←→ 기호 고르기 · 확인 = 넣기. 틀리면 부드럽게 튕기고 처음부터(감점 없음).
## 힌트 = 다음 기호 하나를 자동으로 넣는다. 기호만으로 풀린다(색은 보조).

const CELL := Vector2(34, 34)

var sequence: Array[String] = []
var palette: Array[String] = []
var entered: int = 0
var cursor: int = 0


func _setup(puzzle_data: Dictionary) -> void:
	sequence.assign(puzzle_data.get("sequence", []))
	var pal: Array = puzzle_data.get("palette", EmotionBands.EMOTION_IDS)
	palette.assign(pal)
	entered = 0
	cursor = 0


func is_complete() -> bool:
	return not sequence.is_empty() and entered >= sequence.size()


## 기호 하나를 넣는다. 맞으면 true, 틀리면 처음부터.
func enter(emotion: String) -> bool:
	if is_complete():
		return false
	if sequence[entered] == emotion:
		entered += 1
		flash("ok")
		return true
	entered = 0
	flash("no")
	return false


func _on_hint() -> void:
	if entered < sequence.size():
		entered += 1
		flash("ok")


func _on_input(event: InputEvent) -> bool:
	if is_left(event) or is_right(event):
		cursor = wrapi(cursor + (-1 if is_left(event) else 1), 0, palette.size())
		return true
	if is_confirm(event):
		enter(palette[cursor])
		return true
	return false


func _help_text() -> String:
	return "←→ 기호 고르기 · E 넣기"


func _draw_puzzle(canvas: Control) -> void:
	var size := canvas.get_viewport_rect().size
	var gap := 8.0
	# 넣은 순서 칸
	var total := sequence.size() * CELL.x + (sequence.size() - 1) * gap
	var x0 := (size.x - total) * 0.5
	for i in sequence.size():
		var r := Rect2(Vector2(x0 + i * (CELL.x + gap), 70), CELL)
		canvas.draw_rect(r, Color(1, 1, 1, 0.08))
		canvas.draw_rect(r, Color(1, 1, 1, 0.3), false, 1.0)
		if i < entered:
			var e := sequence[i]
			canvas.draw_rect(r.grow(-2), EmotionBands.main_color(e))
			EmotionSymbols.draw(canvas, EmotionSymbols.symbol_of(e), r.get_center(), Color(1, 1, 1, 0.95), 9.0)
		else:
			var font := canvas.get_theme_default_font()
			canvas.draw_string(font, r.position + Vector2(0, 22), str(i + 1), HORIZONTAL_ALIGNMENT_CENTER, CELL.x, 11, Color(1, 1, 1, 0.3))
	# 기호 팔레트
	var ptotal := palette.size() * CELL.x + (palette.size() - 1) * gap
	var px0 := (size.x - ptotal) * 0.5
	for i in palette.size():
		var r := Rect2(Vector2(px0 + i * (CELL.x + gap), 160), CELL)
		var e := palette[i]
		canvas.draw_rect(r, EmotionBands.main_color(e).darkened(0.35))
		EmotionSymbols.draw(canvas, EmotionSymbols.symbol_of(e), r.get_center(), Color(1, 1, 1, 0.95), 9.0)
		if i == cursor:
			canvas.draw_rect(r.grow(3), Color.WHITE, false, 2.0)
	if feedback_time > 0.0 and feedback == "no":
		canvas.draw_rect(Rect2(Vector2(x0 - 8, 62), Vector2(total + 16, CELL.y + 16)), Color(0.35, 0.35, 0.35, 0.8), false, 1.0)
