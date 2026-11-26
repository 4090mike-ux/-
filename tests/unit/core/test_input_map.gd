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


func test_tag_switch_is_tab() -> void:
	var tab := InputEventKey.new()
	tab.physical_keycode = KEY_TAB
	assert_bool(tab.is_action(InputActions.TAG_SWITCH)).is_true()
