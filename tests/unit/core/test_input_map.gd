extends GdUnitTestSuite
## WP-09 입력 맵: InputActions 상수가 project.godot 에 있고, 키보드·패드 둘 다 지원하는가.


func test_all_actions_exist_with_keyboard_and_gamepad() -> void:
	for action in InputActions.ALL:
		assert_bool(InputMap.has_action(action)).override_failure_message("액션 없음: %s" % action).is_true()
		var has_key := false
		var has_pad := false
		for e in InputMap.action_get_events(action):
			has_key = has_key or e is InputEventKey
			has_pad = has_pad or e is InputEventJoypadButton or e is InputEventJoypadMotion
		assert_bool(has_key).override_failure_message("%s: 키보드 입력 없음" % action).is_true()
		assert_bool(has_pad).override_failure_message("%s: 패드 입력 없음" % action).is_true()


func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	return e


func test_default_keys_follow_gdd_controls_table() -> void:
	# docs/gdd/controls_accessibility.md §1
	assert_bool(_key(KEY_TAB).is_action(InputActions.TAG_SWITCH)).is_true()
	assert_bool(_key(KEY_SHIFT).is_action(InputActions.ECHO_SENSE)).is_true()
	assert_bool(_key(KEY_X).is_action(InputActions.ECHO_SENSE)).is_true()
	assert_bool(_key(KEY_SPACE).is_action(InputActions.INTERACT)).is_true()
	assert_bool(_key(KEY_E).is_action(InputActions.INTERACT)).is_true()
	assert_bool(_key(KEY_P).is_action(InputActions.PAUSE)).is_true()
