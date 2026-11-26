extends GdUnitTestSuite
## 설정 저장·선택지 순환 (docs/gdd/controls_accessibility.md §5).

const TEST_PATH := "user://test_settings.cfg"


func before_test() -> void:
	Settings.path_override = TEST_PATH
	Settings.reset_cache()
	DirAccess.remove_absolute(TEST_PATH)


func after_test() -> void:
	DirAccess.remove_absolute(TEST_PATH)
	Settings.path_override = ""
	Settings.reset_cache()


func test_defaults_follow_gdd() -> void:
	assert_str(str(Settings.get_value("text/speed"))).is_equal("normal")
	assert_float(Settings.text_seconds_per_char()).is_equal_approx(1.0 / 30.0, 0.0001)
	assert_bool(Settings.echo_sense_toggle()).is_false()
	assert_bool(Settings.puzzle_auto_hint()).is_true()


func test_cycle_persists() -> void:
	Settings.cycle("text/speed", 1)
	Settings.cycle("accessibility/echo_sense_mode", 1)
	Settings.reset_cache()
	assert_str(str(Settings.get_value("text/speed"))).is_equal("fast")
	assert_bool(Settings.echo_sense_toggle()).is_true()
	Settings.cycle("text/speed", 1)
	assert_float(Settings.text_seconds_per_char()).is_equal(0.0)
