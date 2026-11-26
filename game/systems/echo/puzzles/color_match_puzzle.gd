class_name ColorMatchPuzzle
extends EchoPuzzle
## color_match (CM-A) — 그림의 빈 칸에 같은 기호의 감정 조각을 채운다 (docs/gdd/echo.md §3-2).
## 데이터: {"slots": [감정 id...], "palette": [감정 id...], "caption": "..."}
## 조작: ←→ 칸 고르기 → 확인 → ←→ 조각 고르기 → 확인(놓기). 틀리면 튕겨 나온다. 취소 = 칸 고르기로.
## 기호만으로 풀린다: 칸 단서도 기호(회색 윤곽), 조각도 기호. 힌트 = 빈 칸 하나를 자동으로 채움.

const SLOT_SIZE := Vector2(40, 40)
const PIECE_SIZE := Vector2(34, 34)

var slots: Array[String] = []
var palette: Array[String] = []
var filled: Array[bool] = []
var slot_cursor: int = 0
var palette_cursor: int = 0
var choosing_piece: bool = false


func _setup(puzzle_data: Dictionary) -> void:
	slots.assign(puzzle_data.get("slots", []))
	palette.assign(puzzle_data.get("palette", []))
	filled.clear()
	for i in slots.size():
		filled.append(false)
	slot_cursor = 0
	palette_cursor = 0
	choosing_piece = false


func is_complete() -> bool:
	return not filled.is_empty() and not filled.has(false)


## 칸에 조각을 놓는다. 맞으면 true.
func place(slot_index: int, emotion: String) -> bool:
	if slot_index < 0 or slot_index >= slots.size() or filled[slot_index]:
		return false
	if slots[slot_index] == emotion:
		filled[slot_index] = true
		flash("ok")
		return true
	flash("no")
	return false


func _on_hint() -> void:
	var i := filled.find(false)
	if i >= 0:
		filled[i] = true
		flash("ok")


func _on_input(event: InputEvent) -> bool:
	if is_left(event) or is_right(event):
		var step := -1 if is_left(event) else 1
		if choosing_piece:
			palette_cursor = wrapi(palette_cursor + step, 0, palette.size())
		else:
			slot_cursor = wrapi(slot_cursor + step, 0, slots.size())
		return true
	if is_confirm(event):
		if not choosing_piece:
			if not filled[slot_cursor]:
				choosing_piece = true
		else:
			place(slot_cursor, palette[palette_cursor])
			choosing_piece = false
			var next := filled.find(false)
			if next >= 0:
				slot_cursor = next
		return true
	if choosing_piece and (event.is_action_pressed(InputActions.PAUSE) or event.is_action_pressed(&"ui_cancel")):
		choosing_piece = false
		return true
	return false


func _help_text() -> String:
	return "←→ 고르기 · E 놓기" if choosing_piece else "←→ 칸 고르기 · E 선택"


func _draw_puzzle(canvas: Control) -> void:
	var size := canvas.get_viewport_rect().size
	var gap := 10.0
	var total := slots.size() * SLOT_SIZE.x + (slots.size() - 1) * gap
	var x0 := (size.x - total) * 0.5
	for i in slots.size():
		var r := Rect2(Vector2(x0 + i * (SLOT_SIZE.x + gap), 70), SLOT_SIZE)
		var emotion := slots[i]
		canvas.draw_rect(r, Color(1, 1, 1, 0.08))
		if filled[i]:
			canvas.draw_rect(r, EmotionBands.main_color(emotion))
			EmotionSymbols.draw(canvas, EmotionSymbols.symbol_of(emotion), r.get_center(), Color(1, 1, 1, 0.95), 9.0)
		else:
			EmotionSymbols.draw(canvas, EmotionSymbols.symbol_of(emotion), r.get_center(), Color(1, 1, 1, 0.35), 9.0)
		var border := Color.WHITE if i == slot_cursor else Color(1, 1, 1, 0.3)
		canvas.draw_rect(r, border, false, 2.0 if i == slot_cursor else 1.0)
	# 조각 팔레트
	var ptotal := palette.size() * PIECE_SIZE.x + (palette.size() - 1) * gap
	var px0 := (size.x - ptotal) * 0.5
	for i in palette.size():
		var r := Rect2(Vector2(px0 + i * (PIECE_SIZE.x + gap), 170), PIECE_SIZE)
		var emotion := palette[i]
		canvas.draw_rect(r, EmotionBands.main_color(emotion))
		EmotionSymbols.draw(canvas, EmotionSymbols.symbol_of(emotion), r.get_center(), Color(1, 1, 1, 0.95), 8.0)
		if choosing_piece and i == palette_cursor:
			canvas.draw_rect(r.grow(3), Color.WHITE, false, 2.0)
	if feedback_time > 0.0:
		var c := Color(1, 1, 1, 0.8) if feedback == "ok" else Color(0.35, 0.35, 0.35, 0.8)
		canvas.draw_rect(Rect2(Vector2(x0 - 8, 62), Vector2(total + 16, SLOT_SIZE.y + 16)), c, false, 1.0)
