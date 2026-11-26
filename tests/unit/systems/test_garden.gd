extends GdUnitTestSuite
## WP-20 정원 규칙 (docs/gdd/garden.md).

const DEFS: Array[Dictionary] = [
	{"id": "echo.ch1.h1", "emotion": "longing", "sensed_by": "haneul", "kind": "required", "reward": {"color_shards": 1}},
	{"id": "echo.ch1.b1", "emotion": "warmth", "sensed_by": "byeol", "kind": "required", "reward": {"color_shards": 1}},
	{"id": "echo.ch1.both", "emotion": "longing", "sensed_by": "both", "kind": "required", "reward": {"color_shards": 2}},
]


func before_test() -> void:
	GameData.clear_cache()
	GardenModel.clear_cache()
	GameState.reset()
	var defs: Array[Dictionary] = []
	defs.assign(DEFS)
	GameData.override_echo_defs(defs)


func after_test() -> void:
	GameData.clear_cache()
	GameState.reset()


func test_pocket_comes_from_collected_echoes() -> void:
	GameState.collect_echo("echo.ch1.h1")
	GameState.collect_echo("echo.ch1.b1")
	GameState.collect_echo("echo.ch1.both")
	assert_int(int(GardenModel.pocket("haneul")["longing"])).is_equal(2)  # 1 + 공명 반
	assert_int(int(GardenModel.pocket("byeol")["longing"])).is_equal(1)
	assert_int(int(GardenModel.pocket("byeol")["warmth"])).is_equal(1)


func test_plant_only_own_row_and_spends_pocket() -> void:
	GameState.collect_echo("echo.ch1.h1")
	assert_bool(GardenModel.plant("plot_06", "longing", "haneul")).is_false()  # 별 줄
	assert_bool(GardenModel.plant("plot_01", "longing", "haneul")).is_true()
	assert_int(int(GardenModel.pocket("haneul")["longing"])).is_equal(0)
	assert_bool(GardenModel.plant("plot_02", "longing", "haneul")).is_false()  # 조각 없음
	GardenModel.clear("plot_01")
	assert_int(int(GardenModel.pocket("haneul")["longing"])).is_equal(1)       # 다시 심기 공짜


func test_tick_only_in_tick_scenes_and_caps_at_five() -> void:
	GameState.collect_echo("echo.ch1.h1")
	GardenModel.plant("plot_01", "longing", "haneul")
	assert_bool(GardenModel.finish_visit("ch1_garden")["ticked"]).is_false()
	assert_bool(GardenModel.finish_visit("ch1_garden_02")["ticked"]).is_true()
	for i in 10:
		GardenModel.tick()
	assert_int(int(GardenModel.planted()["plot_01"]["growth"])).is_equal(5)


func test_shared_echo_gives_resonance_growth() -> void:
	GameState.collect_echo("echo.ch1.h1")
	GardenModel.plant("plot_01", "longing", "haneul")
	GameState.collect_echo("echo.ch1.both")
	var plot: Dictionary = GardenModel.planted()["plot_01"]
	assert_int(int(plot["growth"])).is_equal(1)
	assert_int(int(plot["resonance_bonus"])).is_equal(1)


func test_combo_blooms_when_pair_reaches_three() -> void:
	GameState.collect_echo("echo.ch1.h1")
	GameState.collect_echo("echo.ch1.b1")
	GardenModel.plant("plot_01", "longing", "haneul")
	GardenModel.plant("plot_06", "warmth", "byeol")
	GardenModel.tick()
	GardenModel.tick()
	assert_array(GardenModel.check_combos()).is_empty()
	GardenModel.tick()
	assert_array(GardenModel.check_combos()).contains_exactly(["sprout_together"])
	assert_array(GardenModel.check_combos()).is_empty()  # 한 번만
	assert_array(GardenModel.bloomed()).contains(["sprout_together"])


func test_family_flower_needs_five_emotions_at_two() -> void:
	var garden := {"plots": [], "bloomed": []}
	var i := 1
	for e in GardenModel.EMOTIONS:
		garden["plots"].append({"id": "plot_%02d" % i, "planted_by": "haneul" if i <= 5 else "byeol", "emotion": e, "growth": 2})
		i += 1
	GameState.set_garden_state(garden)
	assert_bool(GardenModel.family_flower_ready()).is_true()
	var result := GardenModel.finish_visit("ch4_garden")
	assert_bool(result["family_flower"]).is_true()
	assert_bool(GameState.flag("flag.ch4.family_flower_bloomed")).is_true()


func test_heart_bed_ratio_matches_gdd_table() -> void:
	assert_dict(GardenModel.heart_bed()).is_equal({"blue": 0, "green": 0, "gray": 12})
	for n in 3:
		GameState.add_protect(1)
	GameState.add_heal(1)
	assert_dict(GardenModel.heart_bed()).is_equal({"blue": 9, "green": 3, "gray": 0})
