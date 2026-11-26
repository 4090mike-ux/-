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


func _bond(level: int) -> void:
	for i in range(1, level + 1):
		GameState.raise_bond(i)


func test_memory_bridge_needs_bond_2() -> void:
	var s := _setup([{"type": "bridge", "id": "studio", "gate": "g1", "at": [100, 100], "lock_at": [300, 100]}])
	var m: SiblingMechanisms = s["m"]
	var reasons: Array[String] = []
	m.blocked.connect(func(_id: String, r: String) -> void: reasons.append(r))
	_bond(1)
	m.handle(_target(m, "pad_studio"), s["a"])
	assert_bool(m.is_gate_open("g1")).is_false()
	assert_array(reasons).contains_exactly(["bond"])


func test_memory_bridge_anchor_cross_and_lock() -> void:
	_bond(2)
	var s := _setup([{"type": "bridge", "id": "studio", "gate": "g1", "at": [100, 100], "lock_at": [300, 100],
		"hint_cues": {"anchor": "b_anchor", "switch": "b_switch", "cross": "b_cross"}}])
	var m: SiblingMechanisms = s["m"]
	var a: SiblingCharacter = s["a"]
	var b: SiblingCharacter = s["b"]
	assert_str(m.current_hint_cue()).is_equal("b_anchor")
	a.active = true
	m.handle(_target(m, "pad_studio"), a)
	assert_bool(m.is_gate_open("g1")).is_true()
	assert_str(m.current_hint_cue()).is_equal("b_switch")
	a.active = false
	b.active = true
	m._process(0.016)
	assert_str(m.current_hint_cue()).is_equal("b_cross")
	assert_bool(m.is_gate_open("g1")).is_true()  # 바꿔도 다리는 그대로
	m.handle(_target(m, "lock_studio"), b)
	assert_bool(m.is_solved("studio")).is_true()
	assert_bool(m.is_gate_open("g1")).is_true()


func test_switching_back_to_anchor_releases_bridge() -> void:
	_bond(2)
	var s := _setup([{"type": "bridge", "id": "studio", "gate": "g1", "at": [100, 100], "lock_at": [300, 100]}])
	var m: SiblingMechanisms = s["m"]
	var a: SiblingCharacter = s["a"]
	a.active = true
	m.handle(_target(m, "pad_studio"), a)
	a.active = false
	m._process(0.016)
	a.active = true  # 고정한 사람으로 돌아옴
	m._process(0.016)
	assert_bool(m.is_gate_open("g1")).is_false()


func test_gate_waits_until_nobody_stands_in_it() -> void:
	var s := _setup([{"type": "hold", "id": "shutter", "gate": "g1", "at": [100, 100], "lock_at": [300, 100]}])
	var m: SiblingMechanisms = s["m"]
	var a: SiblingCharacter = s["a"]
	var b: SiblingCharacter = s["b"]
	m.handle(_target(m, "hold_shutter"), a)
	b.position = Vector2(204, 100)  # 문 한가운데
	a.position += Vector2(20, 0)    # 붙잡은 사람이 움직여 놓친다
	m._process(0.016)
	assert_bool(m.is_gate_open("g1")).is_true()  # 사람이 안에 있어 아직 안 닫힘
	b.position = Vector2(260, 100)
	m._process(0.016)
	assert_bool(m.is_gate_open("g1")).is_false()


func test_gaze_clues_only_for_seer_and_device_only_for_other() -> void:
	_bond(2)
	var s := _setup([{"type": "gaze", "id": "room", "gate": "g1", "at": [300, 100], "seer": "haneul",
		"clues": [[50, 50], [80, 50], [110, 50]], "sequence": ["longing", "warmth", "dream"],
		"hint_cues": {"look": "g_look", "enter": "g_enter", "wrong_person": "g_wrong"}}])
	var m: SiblingMechanisms = s["m"]
	var hints: Array[String] = []
	m.hint_requested.connect(func(c: String) -> void: hints.append(c))
	GameState.active_character = "byeol"
	assert_bool(m.clues_visible(m.mechanisms[0])).is_false()
	assert_str(m.current_hint_cue()).is_equal("g_look")
	GameState.active_character = "haneul"
	assert_bool(m.clues_visible(m.mechanisms[0])).is_true()
	assert_str(m.current_hint_cue()).is_equal("g_enter")
	m.handle(_target(m, "gaze_room"), s["a"])  # 본 사람은 장치를 못 맞춘다
	assert_object(m.puzzle).is_null()
	assert_array(hints).contains_exactly(["g_wrong"])
	m.handle(_target(m, "gaze_room"), s["b"])
	assert_object(m.puzzle).is_not_null()
	m.puzzle.pause_tree = false
	get_tree().paused = false
	assert_bool(m.puzzle.enter("warmth")).is_false()
	assert_bool(m.puzzle.enter("longing")).is_true()
	assert_bool(m.puzzle.enter("warmth")).is_true()
	assert_bool(m.puzzle.enter("dream")).is_true()
	m.puzzle._check_complete()
	await await_idle_frame()
	assert_bool(m.is_solved("room")).is_true()
	assert_bool(m.is_gate_open("g1")).is_true()
	get_tree().paused = false
