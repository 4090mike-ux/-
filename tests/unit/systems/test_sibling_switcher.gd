extends GdUnitTestSuite
## WP-09 태그 전환 골격: 잠금(광장 만남 전), 전환, 입력, 이동.

const DEMO := "res://game/scenes/dev/sibling_demo.tscn"


func before_test() -> void:
	GameData.clear_cache()
	GameState.reset()


func after_test() -> void:
	GameState.reset()


func _build(force_unlocked: bool) -> SiblingSwitcher:
	var root: Node2D = auto_free(Node2D.new())
	for key: String in ["haneul", "byeol"]:
		var c := SiblingCharacter.new()
		c.name = key.capitalize()
		c.character_key = key
		root.add_child(c)
	var switcher := SiblingSwitcher.new()
	switcher.haneul_path = NodePath("../Haneul")
	switcher.byeol_path = NodePath("../Byeol")
	switcher.force_unlocked = force_unlocked
	root.add_child(switcher)
	add_child(root)
	return switcher


func test_locked_until_met_in_square() -> void:
	var switcher := _build(false)
	assert_bool(switcher.can_switch()).is_false()
	assert_bool(switcher.toggle()).is_false()
	assert_str(GameState.active_character).is_equal("haneul")
	GameState.set_flag("flag.ch1.met_in_square", true)
	assert_bool(switcher.toggle()).is_true()
	assert_str(GameState.active_character).is_equal("byeol")


func test_only_active_character_takes_input() -> void:
	var switcher := _build(true)
	assert_str(switcher.active_character().character_key).is_equal("haneul")
	assert_bool(switcher.active_character().active).is_true()
	switcher.toggle()
	var byeol := switcher.active_character()
	assert_str(byeol.character_key).is_equal("byeol")
	assert_bool(byeol.active).is_true()
	assert_bool((switcher.get_node("../Haneul") as SiblingCharacter).active).is_false()


func test_switch_follows_game_state_on_load() -> void:
	var switcher := _build(true)
	GameState.switch_character("byeol")  # 예: 세이브 불러오기
	assert_str(switcher.active_character().character_key).is_equal("byeol")


func test_tab_switches_and_arrows_move_only_active() -> void:
	var runner := scene_runner(DEMO)
	var haneul := runner.find_child("Haneul") as SiblingCharacter
	var byeol := runner.find_child("Byeol") as SiblingCharacter
	var haneul_start := haneul.position
	var byeol_start := byeol.position
	runner.simulate_action_press("move_right")
	await runner.simulate_frames(20, 20)  # 프레임당 20ms 실제 시간 → 물리 틱이 확실히 돈다
	runner.simulate_action_release("move_right")
	assert_float(haneul.position.x).is_greater(haneul_start.x + 5.0)
	assert_vector(byeol.position).is_equal(byeol_start)
	runner.simulate_action_pressed("tag_switch")
	await runner.simulate_frames(2)
	assert_str(GameState.active_character).is_equal("byeol")
	assert_bool(byeol.active).is_true()
	assert_bool(haneul.active).is_false()


func test_four_way_facing() -> void:
	assert_vector(SiblingCharacter.four_way(Vector2(0.9, 0.3))).is_equal(Vector2.RIGHT)
	assert_vector(SiblingCharacter.four_way(Vector2(-0.2, -0.8))).is_equal(Vector2.UP)
	assert_vector(SiblingCharacter.four_way(Vector2(-0.7, 0.1))).is_equal(Vector2.LEFT)
	assert_vector(SiblingCharacter.four_way(Vector2(0.1, 0.5))).is_equal(Vector2.DOWN)
