extends GdUnitTestSuite
## WP-08 GameState 계약 테스트 (dialogue_conventions.md §5, canon_v1 §9).

var _events: Array = []


func before_test() -> void:
	GameData.clear_cache()
	GameState.reset()
	TranslationServer.set_locale("ko")
	_events.clear()


func after_test() -> void:
	GameData.clear_cache()
	GameState.reset()
	for sig: Dictionary in EchoBus.get_signal_list():
		for c: Dictionary in EchoBus.get_signal_connection_list(sig["name"]):
			var callable: Callable = c["callable"]
			if callable.get_object() == self:
				EchoBus.disconnect(sig["name"], callable)


func _record(a: Variant = null, b: Variant = null) -> void:
	_events.append([a, b])


func test_tendency_only_increases_by_one_or_two() -> void:
	GameState.add_protect(1)
	GameState.add_protect(2)
	GameState.add_heal(2)
	assert_int(GameState.protect).is_equal(3)
	assert_int(GameState.heal).is_equal(2)
	GameState.add_protect(3)
	GameState.add_heal(0)
	GameState.add_heal(-1)
	assert_int(GameState.protect).is_equal(3)
	assert_int(GameState.heal).is_equal(2)


func test_direct_assignment_is_rejected() -> void:
	GameState.protect = 10
	GameState.heal = 10
	GameState.bond = 4
	assert_int(GameState.protect).is_equal(0)
	assert_int(GameState.heal).is_equal(0)
	assert_int(GameState.bond).is_equal(0)


func test_stat_changes_are_announced_on_echo_bus() -> void:
	EchoBus.stat_changed.connect(_record)
	GameState.add_heal(2)
	GameState.raise_bond(1)
	assert_array(_events).contains_exactly([["heal", 2], ["bond", 1]])


func test_bond_never_decreases_and_caps_at_four() -> void:
	GameState.raise_bond(2)
	GameState.raise_bond(1)
	assert_int(GameState.bond).is_equal(2)
	GameState.raise_bond(9)
	assert_int(GameState.bond).is_equal(4)


func test_reunite_family_is_idempotent_and_capped() -> void:
	GameState.reunite_family("family_baker")
	GameState.reunite_family("family_baker")
	assert_int(GameState.families_reunited).is_equal(1)
	GameState.reunite_family("bad id")
	assert_int(GameState.families_reunited).is_equal(1)
	for i in 10:
		GameState.reunite_family("family_%d" % i)
	assert_int(GameState.families_reunited).is_equal(GameState.MAX_FAMILIES)


func test_flags_use_registry_defaults() -> void:
	assert_bool(GameState.flag("flag.ch1.met_in_square")).is_false()
	GameState.set_flag("flag.ch1.met_in_square", true)
	assert_bool(GameState.flag("flag.ch1.met_in_square")).is_true()
	assert_str(GameState.flag("flag.endings.reached")).is_equal("none")


func test_unknown_or_mistyped_flags_are_rejected() -> void:
	assert_object(GameState.flag("flag.ch9.nope")).is_null()
	GameState.set_flag("flag.ch1.met_in_square", 1)
	assert_bool(GameState.flag("flag.ch1.met_in_square")).is_false()
	GameState.set_flag("flag.endings.reached", "not_an_ending")
	assert_str(GameState.flag("flag.endings.reached")).is_equal("none")


func test_default_valued_flags_are_not_saved() -> void:
	GameState.set_flag("flag.ch1.met_in_square", true)
	GameState.set_flag("flag.ch1.met_in_square", false)
	var flags: Dictionary = GameState.to_save_state()["flags"]
	assert_bool(flags.is_empty()).is_true()


func test_truth_reveal_switches_display_names() -> void:
	EchoBus.truth_revealed.connect(_record)
	assert_str(GameState.name_display("haneul")).is_equal("하늘")
	assert_str(GameState.name_display("byeol")).is_equal("별")
	GameState.set_flag("flag.ch4.truth_revealed", true)
	assert_int(_events.size()).is_equal(1)
	assert_str(GameState.name_display("haneul")).is_equal("은하늘")
	assert_str(GameState.name_display("byeol")).is_equal("은별")
	assert_str(GameState.name_display("jieun")).is_equal("지은")


func test_lean_uses_balance_threshold_two() -> void:
	assert_str(GameState.lean()).is_equal("balanced")
	GameState.add_protect(2)
	assert_str(GameState.lean()).is_equal("balanced")
	GameState.add_protect(1)
	assert_str(GameState.lean()).is_equal("protect")
	GameState.add_heal(2)
	GameState.add_heal(2)
	GameState.add_heal(2)
	assert_str(GameState.lean()).is_equal("heal")


func test_echoes_are_counted_once_and_hidden_ones_separately() -> void:
	var defs: Array[Dictionary] = [
		{"id": "echo.ch1.a", "kind": "required", "emotion": "longing", "sensed_by": "both"},
		{"id": "echo.ch1.b", "kind": "hidden", "emotion": "warmth", "sensed_by": "byeol"},
	]
	GameData.override_echo_defs(defs)
	EchoBus.echo_collected.connect(_record)
	assert_bool(GameState.collect_echo("echo.ch1.a")).is_true()
	assert_bool(GameState.collect_echo("echo.ch1.a")).is_false()
	assert_bool(GameState.collect_echo("echo.ch1.b")).is_true()
	assert_bool(GameState.collect_echo("not-an-echo")).is_false()
	assert_int(GameState.echo_found).is_equal(2)
	assert_int(GameState.hidden_echo_found).is_equal(1)
	assert_int(GameState.shared_echo_found).is_equal(1)
	assert_array(_events).contains_exactly([["echo.ch1.a", "longing"], ["echo.ch1.b", "warmth"]])


func test_switch_character_validates_and_announces() -> void:
	EchoBus.character_switched.connect(_record)
	GameState.switch_character("byeol")
	GameState.switch_character("byeol")
	GameState.switch_character("nobody")
	assert_str(GameState.active_character).is_equal("byeol")
	assert_array(_events).contains_exactly([["byeol", null]])


func test_save_state_round_trip() -> void:
	GameState.add_protect(2)
	GameState.add_heal(1)
	GameState.raise_bond(3)
	GameState.reunite_family("family_baker")
	GameState.set_flag("flag.ch1.met_in_square", true)
	GameState.collect_echo("echo.ch1.atelier_easel")
	GameState.record_choice("ch2_cafe_01")
	GameState.mark_cue_seen("ch2_cafe:start")
	GameState.chapter = "ch2"
	GameState.scene_path = "res://game/scenes/ch2/cafe.tscn"
	GameState.switch_character("byeol")
	var state := GameState.to_save_state()
	var location := GameState.to_save_location()
	GameState.reset()
	GameState.apply_save(location, state, 42.0)
	assert_int(GameState.protect).is_equal(2)
	assert_int(GameState.heal).is_equal(1)
	assert_int(GameState.bond).is_equal(3)
	assert_int(GameState.families_reunited).is_equal(1)
	assert_bool(GameState.flag("flag.ch1.met_in_square")).is_true()
	assert_bool(GameState.has_echo("echo.ch1.atelier_easel")).is_true()
	assert_bool(GameState.has_chosen("ch2_cafe_01")).is_true()
	assert_bool(GameState.has_seen_cue("ch2_cafe:start")).is_true()
	assert_str(GameState.chapter).is_equal("ch2")
	assert_str(GameState.active_character).is_equal("byeol")
	assert_float(GameState.playtime_sec).is_equal(42.0)


func test_ending_state_matches_ending_rules_inputs() -> void:
	var seen: Array[String] = ["family"]
	var state := GameState.ending_state(seen)
	for key: String in ["protect", "heal", "bond", "families_reunited", "echo_found",
			"hidden_echo_found", "rainbow_flower", "offered_color", "seen_endings"]:
		assert_bool(state.has(key)).override_failure_message("키 없음: %s" % key).is_true()
	assert_str(EndingRules.evaluate(state)).is_equal(EndingRules.PROTECT)
