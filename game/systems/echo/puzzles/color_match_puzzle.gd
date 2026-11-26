class_name ColorMatchPuzzle
extends EchoPuzzle
## color_match — 그림의 빈 칸에 같은 기호의 감정 조각을 채운다 (docs/gdd/echo.md §3-2).
## - CM-A: 단서가 계속 보임 (난이도 1~2)
## - CM-B 잔상: 난이도 3/4/5 → 단서가 4/3/2초 뒤 사라짐. echo_sense 짧게 = 1초 다시 보기(쿨다운 2초)
## - CM-C 2인: 공명 잔향(sensed_by both) + bond ≥ 2 → 칸이 하늘 쪽(왼쪽 절반)/별 쪽으로 나뉘고 자기 쪽만 채운다.
##   tag_switch 로 쪽을 바꾼다(퍼즐 안에서만. 건너뛰기는 tag_switch 길게).
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
## CM-B
var afterimage_sec: float = 0.0
var clue_time: float = 0.0          # 남은 단서 표시 시간 (afterimage_sec > 0 일 때만 의미)
var reveal_cooldown: float = 0.0
## CM-C
var two_player: bool = false
var side: String = "haneul"

const AFTERIMAGE_BY_DIFFICULTY := {3: 4.0, 4: 3.0, 5: 2.0}
const REVEAL_SEC := 1.0
const REVEAL_COOLDOWN := 2.0


func _setup(puzzle_data: Dictionary) -> void:
	slots.assign(puzzle_data.get("slots", []))
	palette.assign(puzzle_data.get("palette", []))
	filled.clear()
	for i in slots.size():
		filled.append(false)
	slot_cursor = 0
	palette_cursor = 0
	choosing_piece = false
	afterimage_sec = float(AFTERIMAGE_BY_DIFFICULTY.get(int(puzzle_data.get("difficulty", 1)), 0.0))
	clue_time = afterimage_sec
	reveal_cooldown = 0.0
	var def := GameData.echo_def(echo_id)
	two_player = str(def.get("sensed_by", "")) == "both" and GameState.bond >= 2 and slots.size() >= 2
	side = GameState.active_character if GameState.active_character in ["haneul", "byeol"] else "haneul"


## 2인 변형에서 칸의 주인: 왼쪽 절반(올림) = 하늘, 나머지 = 별
func side_of(slot_index: int) -> String:
	return "haneul" if slot_index < int(ceil(slots.size() / 2.0)) else "byeol"


func clues_visible() -> bool:
	return afterimage_sec <= 0.0 or clue_time > 0.0


func switch_side() -> void:
	side = "byeol" if side == "haneul" else "haneul"
	Audio.play_sfx("sib_tag_switch", "UI")


## 잔상 단서를 1초 다시 본다 (쿨다운 2초)
func reveal() -> bool:
	if afterimage_sec <= 0.0 or reveal_cooldown > 0.0:
		return false
	clue_time = REVEAL_SEC
	reveal_cooldown = REVEAL_SEC + REVEAL_COOLDOWN
	return true


func advance(delta: float) -> void:
	super.advance(delta)
	clue_time = maxf(0.0, clue_time - delta)
	reveal_cooldown = maxf(0.0, reveal_cooldown - delta)


func _uses_tag_switch() -> bool:
	return two_player


func is_complete() -> bool:
	return not filled.is_empty() and not filled.has(false)


## 칸에 조각을 놓는다. 맞으면 true.
func place(slot_index: int, emotion: String) -> bool:
	if slot_index < 0 or slot_index >= slots.size() or filled[slot_index]:
		return false
	if two_player and side_of(slot_index) != side:
		flash("no")  # 상대 쪽 칸 — 튕겨 나온다
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
	if two_player and event.is_action_pressed(InputActions.TAG_SWITCH):
		switch_side()
		return true
	if afterimage_sec > 0.0 and event.is_action_pressed(InputActions.ECHO_SENSE):
		reveal()
		return true
	if is_left(event) or is_right(event):
		var step := -1 if is_left(event) else 1
		if choosing_piece:
			palette_cursor = wrapi(palette_cursor + step, 0, palette.size())
		else:
			slot_cursor = wrapi(slot_cursor + step, 0, slots.size())
		return true
	if is_confirm(event):
		if not choosing_piece:
			if two_player and side_of(slot_cursor) != side:
				flash("no")
			elif not filled[slot_cursor]:
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
	var text := "←→ 고르기 · E 놓기" if choosing_piece else "←→ 칸 고르기 · E 선택"
	if two_player:
		text += " · Tab 쪽 바꾸기 (지금: %s)" % GameState.name_display(side)
	if afterimage_sec > 0.0:
		text += " · Q 단서 다시 보기"
	return text


func _draw_puzzle(canvas: Control) -> void:
	var size := canvas.get_viewport_rect().size
	var gap := 10.0
	var total := slots.size() * SLOT_SIZE.x + (slots.size() - 1) * gap
	var x0 := (size.x - total) * 0.5
	for i in slots.size():
		var r := Rect2(Vector2(x0 + i * (SLOT_SIZE.x + gap), 70), SLOT_SIZE)
		var emotion := slots[i]
		canvas.draw_rect(r, Color(1, 1, 1, 0.08))
		if two_player and side_of(i) != side and not filled[i]:
			canvas.draw_rect(r, Color(0, 0, 0, 0.35))
		if filled[i]:
			canvas.draw_rect(r, EmotionBands.main_color(emotion))
			EmotionSymbols.draw(canvas, EmotionSymbols.symbol_of(emotion), r.get_center(), Color(1, 1, 1, 0.95), 9.0)
		elif clues_visible():
			EmotionSymbols.draw(canvas, EmotionSymbols.symbol_of(emotion), r.get_center(), Color(1, 1, 1, 0.35), 9.0)
		else:
			canvas.draw_rect(Rect2(r.get_center() - Vector2(1, 1), Vector2(2, 2)), Color(1, 1, 1, 0.25))
		var border := Color.WHITE if i == slot_cursor else Color(1, 1, 1, 0.3)
		canvas.draw_rect(r, border, false, 2.0 if i == slot_cursor else 1.0)
	if two_player:
		var split := int(ceil(slots.size() / 2.0))
		var mid_x := x0 + split * (SLOT_SIZE.x + gap) - gap * 0.5
		canvas.draw_line(Vector2(mid_x, 60), Vector2(mid_x, 70 + SLOT_SIZE.y + 10), Color(1, 1, 1, 0.5), 1.0)
		var font := canvas.get_theme_default_font()
		for s: String in ["haneul", "byeol"]:
			var label := GameState.name_display(s)
			var lx := x0 if s == "haneul" else mid_x + gap * 0.5
			var lw := (mid_x - x0) if s == "haneul" else (x0 + total - mid_x)
			var col := Color(1, 1, 1, 0.95) if s == side else Color(1, 1, 1, 0.4)
			canvas.draw_string(font, Vector2(lx, 126), label, HORIZONTAL_ALIGNMENT_CENTER, lw, 9, col)
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
