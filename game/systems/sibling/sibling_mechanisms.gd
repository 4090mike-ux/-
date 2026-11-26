class_name SiblingMechanisms
extends Node2D
## 동시 조작 퍼즐 장치 (docs/gdd/sibling.md §4). 실패 상태는 없다.
##
## - hold (붙잡기-이동): A 가 장치에서 interact → 붙잡음(움직이면 놓침). 붙잡는 동안 문이 열린다.
##   Tab 으로 B 로 바꿔 문을 지나 반대편 고정 장치(lock)에서 interact → 문이 영구히 열리고 A 가 풀려난다.
## - plates (두 발판): 두 발판에 동시에 사람이 서 있으면 문이 열린다. 한 번 열리면 계속 열림.
## - bridge (기억의 다리, bond 2): A 가 공명대(at)에서 interact → 감지가 고정되고 회색 공백(gate)이 길이 된다.
##   A 가 움직이거나 A 로 다시 바꾸면 풀린다. B 가 건너편 장치(lock_at)에서 interact → 다리가 영구히 굳는다.
## - gaze (엇갈린 시선, bond 2): seer 만 보는 단서 표식(clues, 번호 + 감정 기호)의 순서를
##   다른 사람이 장치(at)에 넣는다(SymbolSequencePuzzle). 맞히면 풀린다. gate 는 선택.
## 사람이 문·공백 안에 서 있으면 닫지 않고 비킬 때까지 기다린다(끼임 방지).
## 풀린 장치는 GameState.mark_cue_seen("<scene>:mech_<id>") 로 기록되고, solved_cue(기본 "mech_<id>_solved")를 재생한다.
## 정의: 장면 JSON 의 "gates": [{id, rect, style?}], "mechanisms": [{type, id, gate, at, lock_at | plates | clues…}]

signal solved(mechanism_id: String, cue: String)
## 막혔을 때 비활성 캐릭터의 힌트 대사 (30초마다, 최대 3번 — sibling.md §4-2)
signal hint_requested(cue: String)
## bond 가 모자라 장치를 못 쓸 때 (장면이 안내 문구를 띄운다)
signal blocked(mechanism_id: String, reason: String)

const HINT_INTERVAL := 30.0
const MAX_HINTS := 3
const BRIDGE_MIN_BOND := 2
const GAZE_MIN_BOND := 2
const ANCHOR_RADIUS := 40.0

const BAR := Color("#99969e")
const BAR_DARK := Color("#4a494f")
const VOID_DARK := Color("#1c1b20")
const VOID_EDGE := Color("#6e6c73")
const PLANK := Color("#c4c1c9")

var scene_id: String = ""
var gates: Dictionary = {}        # id → {rect: Rect2, body: StaticBody2D, open: bool, style: String, want_open: bool}
var mechanisms: Array[Dictionary] = []
var holder: SiblingCharacter = null
var holder_type: String = ""
var puzzle: SymbolSequencePuzzle = null
var _hold_pos: Vector2 = Vector2.ZERO
var _holder_left: bool = false    # 기억의 다리: 고정한 사람이 한 번 비활성이 됐는가
var _plate_bodies: Dictionary = {} # mechanism id → [Area2D...]
var _idle: float = 0.0
var _hints: int = 0
var _time: float = 0.0


func setup(owner_scene_id: String, gate_defs: Array, mech_defs: Array) -> void:
	scene_id = owner_scene_id
	for g: Variant in gate_defs:
		var gd: Dictionary = g
		var a: Array = gd["rect"]
		var r := Rect2(float(a[0]), float(a[1]), float(a[2]), float(a[3]))
		var body := StaticBody2D.new()
		var shape := RectangleShape2D.new()
		shape.size = r.size
		var col := CollisionShape2D.new()
		col.shape = shape
		col.position = r.get_center()
		body.add_child(col)
		add_child(body)
		gates[str(gd["id"])] = {"rect": r, "body": body, "open": false, "want_open": false, "style": str(gd.get("style", "bars"))}
	for m: Variant in mech_defs:
		var md: Dictionary = (m as Dictionary).duplicate(true)
		mechanisms.append(md)
		var id := str(md["id"])
		match str(md["type"]):
			"hold":
				_add_interactable("hold_" + id, md["at"])
				_add_interactable("lock_" + id, md["lock_at"])
			"bridge":
				_add_interactable("pad_" + id, md["at"])
				_add_interactable("lock_" + id, md["lock_at"])
			"gaze":
				_add_interactable("gaze_" + id, md["at"])
			"plates":
				var areas: Array = []
				for p: Variant in md.get("plates", []):
					areas.append(_add_plate(p))
				_plate_bodies[id] = areas
		if GameState.has_seen_cue(_solved_key(id)) and md.has("gate"):
			_set_gate(str(md["gate"]), true)
	queue_redraw()


func is_gate_open(gate_id: String) -> bool:
	return bool((gates.get(gate_id, {}) as Dictionary).get("open", false))


func is_solved(mechanism_id: String) -> bool:
	return GameState.has_seen_cue(_solved_key(mechanism_id))


## Interactable 처리. 이 장치 것이면 true.
func handle(target: Interactable, actor: SiblingCharacter) -> bool:
	var iid := target.interact_id
	if iid.begins_with("hold_") or iid.begins_with("pad_"):
		var m := _mechanism(iid.trim_prefix("hold_").trim_prefix("pad_"))
		if m.is_empty() or is_solved(str(m["id"])):
			return true
		_idle = 0.0
		if str(m["type"]) == "bridge" and GameState.bond < BRIDGE_MIN_BOND:
			blocked.emit(str(m["id"]), "bond")
			return true
		if holder == actor:
			_release(m)
		else:
			holder = actor
			holder_type = str(m["type"])
			_holder_left = false
			_hold_pos = actor.global_position
			_set_gate(str(m["gate"]), true)
			if holder_type == "bridge":
				Audio.play_sfx("sib_hold_start")
		return true
	if iid.begins_with("lock_"):
		var m := _mechanism(iid.trim_prefix("lock_"))
		if m.is_empty():
			return true
		if is_gate_open(str(m["gate"])) and holder != null and holder != actor and not is_solved(str(m["id"])):
			_solve(m)
		return true
	if iid.begins_with("gaze_"):
		var m := _mechanism(iid.trim_prefix("gaze_"))
		if m.is_empty() or is_solved(str(m["id"])):
			return true
		_idle = 0.0
		if GameState.bond < GAZE_MIN_BOND:
			blocked.emit(str(m["id"]), "bond")
			return true
		if actor.character_key == str(m.get("seer", "haneul")):
			# 단서를 본 사람은 장치를 못 맞춘다 — 상대에게 알려 줘야 한다
			var cue := str((m.get("hint_cues", {}) as Dictionary).get("wrong_person", ""))
			if not cue.is_empty():
				hint_requested.emit(cue)
			return true
		open_gaze_puzzle(m)
		return true
	return false


## 엇갈린 시선 장치 입력을 연다. 맞히면 풀린다. (테스트에서도 부른다)
func open_gaze_puzzle(m: Dictionary) -> SymbolSequencePuzzle:
	if puzzle != null:
		return puzzle
	puzzle = SymbolSequencePuzzle.new()
	add_child(puzzle)
	var data := {"sequence": m.get("sequence", []), "caption": str(m.get("caption", "")), "time_limit_sec": int(m.get("time_limit_sec", 40))}
	if m.has("palette"):
		data["palette"] = m["palette"]
	puzzle.solved.connect(func(_id: String) -> void:
		_close_puzzle()
		_solve(m), CONNECT_ONE_SHOT)
	puzzle.cancelled.connect(func(_id: String) -> void: _close_puzzle(), CONNECT_ONE_SHOT)
	puzzle.open("mech.%s" % str(m["id"]), data)
	return puzzle


func _close_puzzle() -> void:
	if puzzle != null:
		puzzle.queue_free()
		puzzle = null


## 단서 표식이 지금 보이는가: seer 가 조작 중일 때만
func clues_visible(m: Dictionary) -> bool:
	return GameState.active_character == str(m.get("seer", "haneul")) and GameState.bond >= GAZE_MIN_BOND


func _process(delta: float) -> void:
	_time += delta
	_tick_hints(delta)
	if holder != null:
		# 붙잡은/고정한 사람이 움직이면 놓친다
		var release := holder.global_position.distance_to(_hold_pos) > 6.0
		# 기억의 다리: 고정한 사람으로 다시 바꾸면 풀린다
		if holder_type == "bridge":
			if not holder.active:
				_holder_left = true
			elif _holder_left:
				release = true
		if release:
			for m in mechanisms:
				if str(m["type"]) == holder_type and not is_solved(str(m["id"])):
					_release(m)
	# 두 발판
	for m in mechanisms:
		if str(m["type"]) != "plates" or is_solved(str(m["id"])):
			continue
		if _plates_pressed(m) >= (_plate_bodies.get(str(m["id"]), []) as Array).size():
			_solve(m)
	# 비킬 때까지 미뤄 둔 문 닫기
	for gid: String in gates:
		var g: Dictionary = gates[gid]
		if bool(g["open"]) and not bool(g["want_open"]) and not _someone_inside(g["rect"]):
			_apply_gate(gid, false)
	if holder_type == "bridge" or not gates.is_empty():
		queue_redraw()


func _plates_pressed(m: Dictionary) -> int:
	var count := 0
	for area: Variant in _plate_bodies.get(str(m["id"]), []):
		for b in (area as Area2D).get_overlapping_bodies():
			if b is SiblingCharacter:
				count += 1
				break
	return count


func _solve(m: Dictionary) -> void:
	var id := str(m["id"])
	GameState.mark_cue_seen(_solved_key(id))
	if m.has("gate"):
		_set_gate(str(m["gate"]), true)
	holder = null
	holder_type = ""
	Audio.play_sfx("sib_gate_open")
	solved.emit(id, str(m.get("solved_cue", "mech_%s_solved" % id)))


## 상태에 맞는 힌트 cue (hint_cues 의 키)
## - hold:   hold(아무도 안 붙잡음) → switch(붙잡은 사람이 조작 중) → latch(다른 사람이 조작 중)
## - bridge: anchor → switch → cross
## - plates: stand(아무도 없음) → switch(한 명만)
## - gaze:   look(본 사람이 아직 조작 안 함) → enter(본 사람이 조작 중 = 바꿔서 입력하라)
func current_hint_cue() -> String:
	for m in mechanisms:
		if is_solved(str(m["id"])):
			continue
		var cues: Dictionary = m.get("hint_cues", {})
		match str(m["type"]):
			"hold":
				if holder == null:
					return str(cues.get("hold", ""))
				return str(cues.get("switch" if holder.active else "latch", ""))
			"bridge":
				if holder == null:
					return str(cues.get("anchor", ""))
				return str(cues.get("switch" if holder.active else "cross", ""))
			"plates":
				return str(cues.get("stand" if _plates_pressed(m) == 0 else "switch", ""))
			"gaze":
				return str(cues.get("enter" if clues_visible(m) else "look", ""))
	return ""


func _tick_hints(delta: float) -> void:
	if _hints >= MAX_HINTS or get_tree().paused:
		return
	_idle += delta
	if _idle >= HINT_INTERVAL:
		_idle = 0.0
		var cue := current_hint_cue()
		if not cue.is_empty():
			_hints += 1
			hint_requested.emit(cue)


func _release(m: Dictionary) -> void:
	if holder_type == "bridge":
		Audio.play_sfx("sib_hold_release")
	holder = null
	holder_type = ""
	if not is_solved(str(m["id"])):
		_set_gate(str(m["gate"]), false)


func _set_gate(gate_id: String, open: bool) -> void:
	if not gates.has(gate_id):
		return
	var g: Dictionary = gates[gate_id]
	g["want_open"] = open
	if open or not _someone_inside(g["rect"]):
		_apply_gate(gate_id, open)


func _apply_gate(gate_id: String, open: bool) -> void:
	var g: Dictionary = gates[gate_id]
	g["open"] = open
	(g["body"] as StaticBody2D).process_mode = Node.PROCESS_MODE_DISABLED if open else Node.PROCESS_MODE_INHERIT
	for c in (g["body"] as StaticBody2D).get_children():
		(c as CollisionShape2D).set_deferred("disabled", open)
	queue_redraw()


func _someone_inside(r: Rect2) -> bool:
	for node in get_tree().get_nodes_in_group(SiblingCharacter.GROUP):
		var c := node as SiblingCharacter
		if c != null and r.grow(4.0).has_point(c.global_position):
			return true
	return false


func _mechanism(id: String) -> Dictionary:
	for m in mechanisms:
		if str(m["id"]) == id:
			return m
	return {}


func _solved_key(id: String) -> String:
	return "%s:mech_%s" % [scene_id, id]


func _add_interactable(iid: String, at: Variant) -> void:
	var a: Array = at
	var target := Interactable.new()
	target.name = "Mech_" + iid
	target.interact_id = iid
	target.radius = 20.0
	target.position = Vector2(float(a[0]), float(a[1]))
	add_child(target)


func _add_plate(at: Variant) -> Area2D:
	var a: Array = at
	var area := Area2D.new()
	area.position = Vector2(float(a[0]), float(a[1]))
	var shape := RectangleShape2D.new()
	shape.size = Vector2(16, 12)
	var col := CollisionShape2D.new()
	col.shape = shape
	area.add_child(col)
	add_child(area)
	return area


func _draw() -> void:
	for id: String in gates:
		var g: Dictionary = gates[id]
		var r: Rect2 = g["rect"]
		if str(g["style"]) == "void":
			_draw_void(r, bool(g["open"]))
		elif bool(g["open"]):
			draw_rect(Rect2(r.position, Vector2(r.size.x, 3)), BAR_DARK)
		else:
			draw_rect(r, BAR_DARK)
			var x := r.position.x + 2.0
			while x < r.end.x:
				draw_line(Vector2(x, r.position.y), Vector2(x, r.end.y), BAR, 1.0)
				x += 4.0
	for m in mechanisms:
		match str(m["type"]):
			"hold":
				for key: String in ["at", "lock_at"]:
					var a: Array = m[key]
					var p := Vector2(float(a[0]), float(a[1]))
					draw_rect(Rect2(p + Vector2(-4, -14), Vector2(8, 14)), BAR_DARK)
					draw_rect(Rect2(p + Vector2(-2, -12), Vector2(4, 4)), BAR)
			"bridge":
				var pa: Array = m["at"]
				var pad := Vector2(float(pa[0]), float(pa[1]))
				draw_circle(pad, 9.0, BAR_DARK)
				draw_arc(pad, 9.0, 0.0, TAU, 20, BAR, 1.0)
				var la: Array = m["lock_at"]
				var lp := Vector2(float(la[0]), float(la[1]))
				draw_rect(Rect2(lp + Vector2(-3, -12), Vector2(6, 12)), BAR_DARK)
				draw_rect(Rect2(lp + Vector2(-2, -10), Vector2(4, 3)), BAR)
				if holder != null and holder_type == "bridge":
					# 고정된 감지 반경
					var pulse := 0.5 + 0.5 * sin(_time * 3.0)
					draw_arc(holder.global_position - global_position, ANCHOR_RADIUS, 0.0, TAU, 48, Color(PLANK, 0.35 + 0.3 * pulse), 1.0)
			"plates":
				for a: Variant in m.get("plates", []):
					var pa2: Array = a
					draw_rect(Rect2(Vector2(float(pa2[0]), float(pa2[1])) - Vector2(8, 6), Vector2(16, 12)), BAR_DARK)
			"gaze":
				var ga: Array = m["at"]
				var gp := Vector2(float(ga[0]), float(ga[1]))
				draw_rect(Rect2(gp + Vector2(-6, -10), Vector2(12, 10)), BAR_DARK)
				draw_rect(Rect2(gp + Vector2(-4, -8), Vector2(8, 3)), BAR)
				if clues_visible(m) and not is_solved(str(m["id"])):
					_draw_clues(m)


## 회색 공백: 닫힘 = 어두운 틈 + 점선 테두리, 열림 = 빛나는 판자 다리
func _draw_void(r: Rect2, open: bool) -> void:
	if not open:
		draw_rect(r, VOID_DARK)
		var x := r.position.x
		while x < r.end.x:
			draw_line(Vector2(x, r.position.y), Vector2(minf(x + 2.0, r.end.x), r.position.y), VOID_EDGE, 1.0)
			draw_line(Vector2(x, r.end.y - 1.0), Vector2(minf(x + 2.0, r.end.x), r.end.y - 1.0), VOID_EDGE, 1.0)
			x += 5.0
		return
	draw_rect(r, Color(VOID_DARK, 0.6))
	var vertical := r.size.y > r.size.x
	var step := 5.0
	if vertical:
		var y := r.position.y + 1.0
		while y < r.end.y - 1.0:
			draw_rect(Rect2(r.position.x + 1.0, y, r.size.x - 2.0, 3.0), PLANK)
			y += step
	else:
		var x2 := r.position.x + 1.0
		while x2 < r.end.x - 1.0:
			draw_rect(Rect2(x2, r.position.y + 1.0, 3.0, r.size.y - 2.0), PLANK)
			x2 += step


## 엇갈린 시선 단서 표식: 점선 원 + 감정 기호 + 순서 번호 (seer 에게만)
func _draw_clues(m: Dictionary) -> void:
	var seq: Array = m.get("sequence", [])
	var clues: Array = m.get("clues", [])
	var font := ThemeDB.fallback_font
	for i in mini(seq.size(), clues.size()):
		var a: Array = clues[i]
		var p := Vector2(float(a[0]), float(a[1]))
		var emotion := str(seq[i])
		var col := EmotionBands.main_color(emotion) if EmotionBands.EMOTION_IDS.has(emotion) else PLANK
		for k in 12:
			if k % 2 == 0:
				draw_arc(p, 9.0, k * TAU / 12.0, (k + 1) * TAU / 12.0, 3, col, 1.0)
		EmotionSymbols.draw(self, EmotionSymbols.symbol_of(emotion), p, col, 5.0)
		draw_string(font, p + Vector2(8, -6), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, PLANK)
