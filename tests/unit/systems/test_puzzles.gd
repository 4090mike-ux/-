extends GdUnitTestSuite
## GDD 공명 퍼즐 2종 (docs/gdd/echo.md §3-2, §3-3): 기호로 풀기, 실패 없음, 힌트·건너뛰기.

var _results: Array[String] = []


func before_test() -> void:
	_results.clear()


func _open(p: EchoPuzzle, data: Dictionary) -> EchoPuzzle:
	auto_free(p)
	p.pause_tree = false
	p.use_settings = false
	add_child(p)
	p.solved.connect(func(id: String) -> void: _results.append("solved:" + id))
	p.open("echo.ch1.test", data)
	return p


func test_color_match_accepts_only_matching_symbol() -> void:
	var p := _open(ColorMatchPuzzle.new(), {"slots": ["longing", "warmth", "longing"], "palette": ["warmth", "longing"]}) as ColorMatchPuzzle
	assert_bool(p.place(0, "warmth")).is_false()
	assert_bool(p.place(0, "longing")).is_true()
	assert_bool(p.place(0, "longing")).is_false()  # 이미 채움
	p.place(1, "warmth")
	assert_bool(p.is_complete()).is_false()
	p.place(2, "longing")
	p._check_complete()
	assert_array(_results).contains_exactly(["solved:echo.ch1.test"])


func test_color_match_hint_fills_a_slot() -> void:
	var p := _open(ColorMatchPuzzle.new(), {"slots": ["longing", "warmth"], "palette": ["warmth", "longing"], "time_limit_sec": 30}) as ColorMatchPuzzle
	p.advance(31.0)
	assert_int(p.hints_given).is_equal(1)
	assert_int(p.filled.count(true)).is_equal(1)
	p.advance(31.0)
	assert_array(_results).contains_exactly(["solved:echo.ch1.test"])  # 칸 2개 → 힌트 2번으로 완성


func test_memory_order_needs_story_order_and_ignores_decoy() -> void:
	var data := {
		"echo_id": "echo.ch1.test",
		"cards": [{"id": "seed", "caption": "씨앗"}, {"id": "sprout", "caption": "새싹"}, {"id": "flower", "caption": "꽃"}],
		"decoy": {"id": "cup", "caption": "찻잔"},
	}
	var p := _open(MemoryOrderPuzzle.new(), data) as MemoryOrderPuzzle
	assert_int(p.hand.size()).is_equal(4)
	assert_str(str(p.hand[0]["id"])).is_not_equal("seed")  # 정답 순서 그대로 섞이지 않음
	assert_bool(p.pick("sprout")).is_false()
	assert_bool(p.pick("cup")).is_false()
	assert_bool(p.pick("seed")).is_true()
	assert_bool(p.pick("sprout")).is_true()
	assert_bool(p.pick("flower")).is_true()
	p._check_complete()
	assert_array(_results).contains_exactly(["solved:echo.ch1.test"])
	assert_int(p.hand.size()).is_equal(1)  # 미끼만 남음


func test_skip_after_two_hints() -> void:
	var data := {"cards": [{"id": "a", "caption": "1"}, {"id": "b", "caption": "2"}, {"id": "c", "caption": "3"}]}
	var p := _open(MemoryOrderPuzzle.new(), data)
	assert_bool(p.skip()).is_false()
	p.give_hint()
	p.give_hint()
	assert_bool(p.can_skip()).is_true()
	assert_bool(p.skip()).is_true()
	assert_bool(p.was_skipped).is_true()
	assert_array(_results).contains_exactly(["solved:echo.ch1.test"])


func test_host_without_data_succeeds_immediately() -> void:
	var host: PuzzleHost = auto_free(PuzzleHost.new())
	host.pause_tree = false
	add_child(host)
	var outcome: Array = await host.run("echo.ch9.missing", "none")
	assert_array(outcome).is_equal([true, false])
	assert_str(PuzzleHost.slug_of("echo.ch1.square_clock")).is_equal("square_clock")


func test_color_match_afterimage_hides_clues_and_reveals_on_sense() -> void:
	var p := _open(ColorMatchPuzzle.new(), {"slots": ["longing", "warmth", "longing", "warmth", "longing"],
		"palette": ["warmth", "longing"], "difficulty": 3, "time_limit_sec": 0}) as ColorMatchPuzzle
	assert_float(p.afterimage_sec).is_equal(4.0)  # CM-B: 난이도 3 → 4초
	assert_bool(p.clues_visible()).is_true()
	p.advance(4.1)
	assert_bool(p.clues_visible()).is_false()
	assert_bool(p.reveal()).is_true()
	assert_bool(p.clues_visible()).is_true()
	assert_bool(p.reveal()).is_false()  # 쿨다운
	p.advance(1.1)
	assert_bool(p.clues_visible()).is_false()
	assert_bool(p.place(0, "longing")).is_true()  # 단서가 안 보여도 기호가 맞으면 들어간다


func test_easy_color_match_keeps_clues_visible() -> void:
	var p := _open(ColorMatchPuzzle.new(), {"slots": ["longing", "warmth"], "palette": ["warmth", "longing"], "difficulty": 2}) as ColorMatchPuzzle
	p.advance(10.0)
	assert_bool(p.clues_visible()).is_true()


func test_two_player_color_match_splits_slots_by_side() -> void:
	GameState.reset()
	GameState.raise_bond(1)
	GameState.raise_bond(2)
	var defs: Array[Dictionary] = [{"id": "echo.ch3.pair_test", "emotion": "dream", "kind": "required", "sensed_by": "both"}]
	GameData.override_echo_defs(defs)
	var p: ColorMatchPuzzle = auto_free(ColorMatchPuzzle.new())
	p.pause_tree = false
	p.use_settings = false
	add_child(p)
	p.open("echo.ch3.pair_test", {"slots": ["dream", "longing", "warmth", "dream"], "palette": ["dream", "longing", "warmth"], "difficulty": 2})
	assert_bool(p.two_player).is_true()
	assert_str(p.side_of(0)).is_equal("haneul")
	assert_str(p.side_of(1)).is_equal("haneul")
	assert_str(p.side_of(2)).is_equal("byeol")
	assert_str(p.side).is_equal("haneul")
	assert_bool(p.place(2, "warmth")).is_false()  # 별 쪽 칸은 하늘이 못 채운다
	assert_bool(p.place(0, "dream")).is_true()
	p.switch_side()
	assert_bool(p.place(1, "longing")).is_false()
	assert_bool(p.place(2, "warmth")).is_true()
	GameData.clear_cache()
	GameState.reset()


func test_two_player_needs_bond_2() -> void:
	GameState.reset()
	var defs: Array[Dictionary] = [{"id": "echo.ch3.pair_test", "emotion": "dream", "kind": "required", "sensed_by": "both"}]
	GameData.override_echo_defs(defs)
	var p: ColorMatchPuzzle = auto_free(ColorMatchPuzzle.new())
	p.pause_tree = false
	p.use_settings = false
	add_child(p)
	p.open("echo.ch3.pair_test", {"slots": ["dream", "longing"], "palette": ["dream", "longing"]})
	assert_bool(p.two_player).is_false()
	GameData.clear_cache()
