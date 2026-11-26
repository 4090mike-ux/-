extends GdUnitTestSuite
## 동시 조작 퍼즐: 붙잡기-이동, 두 발판 (docs/gdd/sibling.md §4).

func before_test() -> void:
	GameState.reset()


func after_test() -> void:
	GameState.reset()


func _setup(mechs: Array) -> Dictionary:
	var root: Node2D = auto_free(Node2D.new())
	var a := SiblingCharacter.new()
	a.character_key = "haneul"
	a.position = Vector2(100, 100)
	var b := SiblingCharacter.new()
	b.character_key = "byeol"
	b.position = Vector2(300, 100)
	root.add_child(a)
	root.add_child(b)
	var m := SiblingMechanisms.new()
	root.add_child(m)
	add_child(root)
	m.setup("ch1_test", [{"id": "g1", "rect": [200, 80, 8, 40]}], mechs)
	return {"m": m, "a": a, "b": b}


func _target(m: SiblingMechanisms, iid: String) -> Interactable:
	return m.find_child("Mech_" + iid, false, false) as Interactable


func test_hold_opens_gate_and_lock_solves() -> void:
	var s := _setup([{"type": "hold", "id": "shutter", "gate": "g1", "at": [100, 100], "lock_at": [300, 100],
		"hint_cues": {"hold": "h_hold", "switch": "h_switch", "latch": "h_latch"}}])
	var m: SiblingMechanisms = s["m"]
	assert_str(m.current_hint_cue()).is_equal("h_hold")
	assert_bool(m.is_gate_open("g1")).is_false()
	(s["a"] as SiblingCharacter).active = true
	m.handle(_target(m, "hold_shutter"), s["a"])
	assert_bool(m.is_gate_open("g1")).is_true()
	assert_str(m.current_hint_cue()).is_equal("h_switch")
	(s["a"] as SiblingCharacter).active = false
	assert_str(m.current_hint_cue()).is_equal("h_latch")
	m.handle(_target(m, "lock_shutter"), s["a"])   # 붙잡은 사람이 직접 고정은 못 함
	assert_bool(m.is_solved("shutter")).is_false()
	m.handle(_target(m, "lock_shutter"), s["b"])
	assert_bool(m.is_solved("shutter")).is_true()
	assert_bool(GameState.has_seen_cue("ch1_test:mech_shutter")).is_true()


func test_moving_holder_releases() -> void:
	var s := _setup([{"type": "hold", "id": "shutter", "gate": "g1", "at": [100, 100], "lock_at": [300, 100]}])
	var m: SiblingMechanisms = s["m"]
	m.handle(_target(m, "hold_shutter"), s["a"])
	(s["a"] as SiblingCharacter).position += Vector2(20, 0)
	m._process(0.016)
	assert_bool(m.is_gate_open("g1")).is_false()


func test_solved_state_survives_reload() -> void:
	GameState.mark_cue_seen("ch1_test:mech_shutter")
	var s := _setup([{"type": "hold", "id": "shutter", "gate": "g1", "at": [100, 100], "lock_at": [300, 100]}])
	assert_bool((s["m"] as SiblingMechanisms).is_gate_open("g1")).is_true()
