class_name MemoryOrderPuzzle
extends EchoPuzzle
## memory_order (MO-A/B) — 흩어진 기억 카드를 일어난 순서대로 고른다 (docs/gdd/echo.md §3-3).
## 데이터: {"cards": [{"id","caption","sketch"}... 올바른 순서], "decoy": null | {...}, "caption": "..."}
## 조작: ←→ 카드 고르기 → 확인. 다음 순서의 카드면 위 칸에 고정, 아니면 튕겨 나온다(감점 없음).
## 미끼 카드는 끝까지 남기면 된다. 순서 단서는 카드 내용(캡션·그림)뿐, 색·기호는 단서가 아니다.
## 힌트 = 다음 카드를 자동으로 놓음.

const CARD_SIZE := Vector2(72, 60)

var order: Array[Dictionary] = []      # 정답 순서
var hand: Array[Dictionary] = []       # 아직 남은 카드 (보이는 순서, 미끼 포함)
var placed: Array[String] = []
var cursor: int = 0


func _setup(puzzle_data: Dictionary) -> void:
	order.assign(puzzle_data.get("cards", []))
	hand.assign(order.duplicate(true))
	var decoy: Variant = puzzle_data.get("decoy")
	if decoy is Dictionary and not (decoy as Dictionary).is_empty():
		hand.append(decoy as Dictionary)
	_shuffle_deterministic(str(puzzle_data.get("echo_id", echo_id)))
	placed.clear()
	cursor = 0


func is_complete() -> bool:
	return not order.is_empty() and placed.size() == order.size()


func next_card_id() -> String:
	return "" if is_complete() else str(order[placed.size()]["id"])


## 카드를 고른다. 다음 순서면 true.
func pick(card_id: String) -> bool:
	if card_id == next_card_id():
		placed.append(card_id)
		for i in hand.size():
			if str(hand[i]["id"]) == card_id:
				hand.remove_at(i)
				break
		cursor = clampi(cursor, 0, maxi(0, hand.size() - 1))
		flash("ok")
		return true
	flash("no")
	return false


func _on_hint() -> void:
	var id := next_card_id()
	if not id.is_empty():
		pick(id)


func _on_input(event: InputEvent) -> bool:
	if hand.is_empty():
		return false
	if is_left(event) or is_right(event):
		cursor = wrapi(cursor + (-1 if is_left(event) else 1), 0, hand.size())
		return true
	if is_confirm(event):
		pick(str(hand[cursor]["id"]))
		return true
	return false


func _help_text() -> String:
	return "←→ 카드 고르기 · E 다음 기억으로"


## 같은 잔향이면 항상 같은 섞임 (정답 순서 그대로 나오지 않게)
func _shuffle_deterministic(seed_text: String) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(seed_text)
	for attempt in 8:
		for i in range(hand.size() - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var tmp: Dictionary = hand[i]
			hand[i] = hand[j]
			hand[j] = tmp
		if hand.size() < 2 or str(hand[0]["id"]) != str(order[0]["id"]):
			return


func _draw_puzzle(canvas: Control) -> void:
	var size := canvas.get_viewport_rect().size
	var font := ThemeDB.fallback_font
	var gap := 8.0
	# 위: 놓은 순서
	var n := order.size()
	var total := n * CARD_SIZE.x + (n - 1) * gap
	var x0 := (size.x - total) * 0.5
	for i in n:
		var r := Rect2(Vector2(x0 + i * (CARD_SIZE.x + gap), 46), CARD_SIZE)
		canvas.draw_rect(r, Color(1, 1, 1, 0.06))
		canvas.draw_rect(r, Color(1, 1, 1, 0.3), false, 1.0)
		canvas.draw_string(font, r.position + Vector2(4, 12), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1, 1, 1, 0.5))
		if i < placed.size():
			_draw_card(canvas, font, r, _card_by_id(placed[i]), true)
	# 아래: 남은 카드
	var m := hand.size()
	var htotal := m * CARD_SIZE.x + maxi(0, m - 1) * gap
	var hx0 := (size.x - htotal) * 0.5
	for i in m:
		var r := Rect2(Vector2(hx0 + i * (CARD_SIZE.x + gap), 140), CARD_SIZE)
		_draw_card(canvas, font, r, hand[i], false)
		if i == cursor:
			canvas.draw_rect(r.grow(3), Color.WHITE if feedback_time <= 0.0 or feedback == "ok" else Color(0.4, 0.4, 0.4), false, 2.0)


func _draw_card(canvas: Control, font: Font, r: Rect2, card: Dictionary, done: bool) -> void:
	canvas.draw_rect(r, Color("#edebf0") if not done else Color("#c4c1c9"))
	canvas.draw_rect(r, Color("#151417"), false, 1.0)
	var caption := str(card.get("caption", ""))
	canvas.draw_multiline_string(font, r.position + Vector2(4, 16), caption, HORIZONTAL_ALIGNMENT_CENTER,
		r.size.x - 8, 9, 4, Color("#151417"))


func _card_by_id(card_id: String) -> Dictionary:
	for c in order:
		if str(c["id"]) == card_id:
			return c
	return {}
