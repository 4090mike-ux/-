class_name SiblingMechanisms
extends Node2D
## 동시 조작 퍼즐 장치 (docs/gdd/sibling.md §4). 실패 상태는 없다.
##
## - hold (붙잡기-이동): A 가 장치에서 interact → 붙잡음(움직이면 놓침). 붙잡는 동안 문이 열린다.
##   Tab 으로 B 로 바꿔 문을 지나 반대편 고정 장치(lock)에서 interact → 문이 영구히 열리고 A 가 풀려난다.
## - plates (두 발판): 두 발판에 동시에 사람이 서 있으면 문이 열린다. 한 번 열리면 계속 열림.
## 풀린 장치는 GameState.mark_cue_seen("<scene>:mech_<id>") 로 기록되고, cue "mech_<id>_solved" 가 있으면 재생된다.
## 정의: 장면 JSON 의 "gates": [{id, rect}], "mechanisms": [{type, id, gate, at, lock_at | plates}]

signal solved(mechanism_id: String)

const BAR := Color("#99969e")
const BAR_DARK := Color("#4a494f")

var scene_id: String = ""
var gates: Dictionary = {}        # id → {rect: Rect2, body: StaticBody2D, open: bool}
var mechanisms: Array[Dictionary] = []
var holder: SiblingCharacter = null
var _hold_pos: Vector2 = Vector2.ZERO
var _plate_bodies: Dictionary = {} # mechanism id → [Area2D...]


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
		gates[str(gd["id"])] = {"rect": r, "body": body, "open": false}
	for m: Variant in mech_defs:
		var md: Dictionary = (m as Dictionary).duplicate(true)
		mechanisms.append(md)
		var id := str(md["id"])
		match str(md["type"]):
			"hold":
				_add_interactable("hold_" + id, md["at"])
				_add_interactable("lock_" + id, md["lock_at"])
			"plates":
				var areas: Array = []
				for p: Variant in md.get("plates", []):
					areas.append(_add_plate(p))
				_plate_bodies[id] = areas
		if GameState.has_seen_cue(_solved_key(id)):
			_set_gate(str(md["gate"]), true)
	queue_redraw()


func is_gate_open(gate_id: String) -> bool:
	return bool((gates.get(gate_id, {}) as Dictionary).get("open", false))


func is_solved(mechanism_id: String) -> bool:
	return GameState.has_seen_cue(_solved_key(mechanism_id))


## Interactable 처리. 이 장치 것이면 true.
func handle(target: Interactable, actor: SiblingCharacter) -> bool:
	var iid := target.interact_id
	if iid.begins_with("hold_"):
		var m := _mechanism(iid.trim_prefix("hold_"))
		if m.is_empty() or is_solved(str(m["id"])):
			return true
		if holder == actor:
			_release(m)
		else:
			holder = actor
			_hold_pos = actor.global_position
			_set_gate(str(m["gate"]), true)
		return true
	if iid.begins_with("lock_"):
		var m := _mechanism(iid.trim_prefix("lock_"))
		if m.is_empty():
			return true
		if is_gate_open(str(m["gate"])) and holder != null and holder != actor and not is_solved(str(m["id"])):
			_solve(m)
		return true
	return false


func _process(_delta: float) -> void:
	# 붙잡은 사람이 움직이면 놓친다
	if holder != null and holder.global_position.distance_to(_hold_pos) > 6.0:
		for m in mechanisms:
			if str(m["type"]) == "hold" and not is_solved(str(m["id"])):
				_release(m)
	# 두 발판
	for m in mechanisms:
		if str(m["type"]) != "plates" or is_solved(str(m["id"])):
			continue
		var all_pressed := true
		for area: Variant in _plate_bodies.get(str(m["id"]), []):
			var pressed := false
			for b in (area as Area2D).get_overlapping_bodies():
				if b is SiblingCharacter:
					pressed = true
			all_pressed = all_pressed and pressed
		if all_pressed:
			_solve(m)


func _solve(m: Dictionary) -> void:
	var id := str(m["id"])
	GameState.mark_cue_seen(_solved_key(id))
	_set_gate(str(m["gate"]), true)
	holder = null
	solved.emit(id)


func _release(m: Dictionary) -> void:
	holder = null
	if not is_solved(str(m["id"])):
		_set_gate(str(m["gate"]), false)


func _set_gate(gate_id: String, open: bool) -> void:
	if not gates.has(gate_id):
		return
	var g: Dictionary = gates[gate_id]
	g["open"] = open
	(g["body"] as StaticBody2D).process_mode = Node.PROCESS_MODE_DISABLED if open else Node.PROCESS_MODE_INHERIT
	for c in (g["body"] as StaticBody2D).get_children():
		(c as CollisionShape2D).set_deferred("disabled", open)
	queue_redraw()


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
		if bool(g["open"]):
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
			"plates":
				for a: Variant in m.get("plates", []):
					var pa: Array = a
					draw_rect(Rect2(Vector2(float(pa[0]), float(pa[1])) - Vector2(8, 6), Vector2(16, 12)), BAR_DARK)
