extends GdUnitTestSuite
## WP-14 공명 퍼즐 프로토타입 논리.

var _results: Array[String] = []


func _puzzle() -> ResonancePuzzle:
	var p: ResonancePuzzle = auto_free(ResonancePuzzle.new())
	p.pause_tree = false
	add_child(p)
	p.solved.connect(func(id: String) -> void: _results.append("solved:" + id))
	return p


func before_test() -> void:
	_results.clear()


func _align(p: ResonancePuzzle) -> void:
	p.ring_angle = wrapf(ResonancePuzzle.MARKER_ANGLE - TAU * p.target_index() / 5.0, 0.0, TAU)


func test_hit_when_target_symbol_is_under_marker() -> void:
	var p := _puzzle()
	p.open("echo.ch1.x", "dream")
	_align(p)
	assert_bool(p.is_target_aligned()).is_true()
	assert_bool(p.press()).is_true()
	assert_int(p.hits).is_equal(1)
	assert_float(p.speed).is_less(0.0)  # 맞히면 반대 방향으로 더 빨리


func test_miss_reduces_hits() -> void:
	var p := _puzzle()
	p.open("echo.ch1.x", "warmth")
	_align(p)
	p.press()
	p.ring_angle += PI  # 반대편
	assert_bool(p.press()).is_false()
	assert_int(p.hits).is_equal(0)


func test_three_hits_solve() -> void:
	var p := _puzzle()
	p.open("echo.ch1.x", "longing")
	for i in 3:
		_align(p)
		p.press()
	assert_bool(p.is_open).is_false()
	assert_array(_results).contains_exactly(["solved:echo.ch1.x"])


func test_timer_gives_hints_never_fails() -> void:
	var p := _puzzle()
	p.open("echo.ch1.y", "courage")
	p.advance(p.time_limit + 0.1)
	assert_bool(p.is_open).is_true()
	assert_int(p.hints_given).is_equal(1)
	assert_float(p.current_tolerance_deg()).is_greater(p.tolerance_deg)
	assert_bool(p.can_skip()).is_false()
	p.advance(p.time_limit + 0.1)
	assert_bool(p.can_skip()).is_true()
	assert_array(_results).is_empty()


func test_skip_after_two_hints_solves_with_same_reward() -> void:
	var p := _puzzle()
	p.open("echo.ch1.z", "healing")
	assert_bool(p.skip()).is_false()
	p.give_hint()
	p.give_hint()
	assert_bool(p.skip()).is_true()
	assert_bool(p.was_skipped).is_true()
	assert_array(_results).contains_exactly(["solved:echo.ch1.z"])


func test_every_emotion_has_a_distinct_symbol() -> void:
	# 색 없이 기호만으로 풀 수 있어야 한다
	var symbols := {}
	for id in EmotionBands.EMOTION_IDS:
		symbols[EmotionSymbols.symbol_of(id)] = true
	assert_int(symbols.size()).is_equal(5)
