extends GdUnitTestSuite
## WP-08 SaveService: 슬롯 세이브 왕복, 공유 기록, 손상·버전 처리.
## 만든 세이브를 tests/out/ 에 복사해 두면 tools/validate_data.py --generated tests/out 이 JSON Schema 로 검사한다.

const TEST_DIR := "user://test_saves"
const OUT_DIR := "res://tests/out"


func before_test() -> void:
	SaveService.save_dir = TEST_DIR
	_clear_dir(TEST_DIR)
	SaveService.reset_persist_in_memory()
	GameData.clear_cache()
	GameState.reset()


func after_test() -> void:
	_clear_dir(TEST_DIR)
	SaveService.save_dir = "user://"
	SaveService.load_persist()
	GameState.reset()


func _clear_dir(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	for file in dir.get_files():
		DirAccess.remove_absolute(path.path_join(file))


func _sample_state() -> void:
	GameState.add_protect(2)
	GameState.add_heal(1)
	GameState.raise_bond(2)
	GameState.reunite_family("family_baker")
	GameState.set_flag("flag.ch1.met_in_square", true)
	GameState.collect_echo("echo.ch1.atelier_easel")
	GameState.record_choice("ch2_cafe_01")
	GameState.chapter = "ch2"
	GameState.scene_path = "res://game/scenes/ch2/cafe.tscn"
	GameState.spawn = "FromStreet"
	GameState.switch_character("byeol")
	GameState.set_garden_state({"plots": [{"id": "plot_01", "planted_by": "haneul", "emotion": "longing", "growth": 2}], "bloomed": []})
	GameState.playtime_sec = 123.0


func _copy_to_out(src: String, name: String) -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	if not FileAccess.file_exists(OUT_DIR.path_join(".gdignore")):
		FileAccess.open(OUT_DIR.path_join(".gdignore"), FileAccess.WRITE).close()
	DirAccess.copy_absolute(src, OUT_DIR.path_join(name))


func test_slot_round_trip() -> void:
	_sample_state()
	assert_int(SaveService.save_slot(1)).is_equal(OK)
	assert_bool(SaveService.has_slot(1)).is_true()
	_copy_to_out(SaveService.slot_path(1), "save_generated.json")
	GameState.reset()
	assert_int(SaveService.load_slot(1)).is_equal(OK)
	assert_int(GameState.protect).is_equal(2)
	assert_int(GameState.heal).is_equal(1)
	assert_int(GameState.bond).is_equal(2)
	assert_int(GameState.families_reunited).is_equal(1)
	assert_bool(GameState.flag("flag.ch1.met_in_square")).is_true()
	assert_bool(GameState.has_echo("echo.ch1.atelier_easel")).is_true()
	assert_str(GameState.active_character).is_equal("byeol")
	assert_str(GameState.spawn).is_equal("FromStreet")
	assert_int(int(GameState.playtime_sec)).is_equal(123)
	assert_int((GameState.garden_state()["plots"] as Array).size()).is_equal(1)


func test_save_file_has_schema_fields() -> void:
	_sample_state()
	SaveService.save_slot(2)
	var data: Dictionary = GameData.read_json(SaveService.slot_path(2))
	assert_int(int(data["schema_version"])).is_equal(SaveService.SCHEMA_VERSION)
	assert_str(str(data["saved_at"])).ends_with("Z")
	assert_str(str(data["game_version"])).is_equal("0.1.0")
	assert_bool((data["state"] as Dictionary).has("reunited_families")).is_true()
	assert_bool(((data["state"] as Dictionary)["vars"] as Dictionary).has("families_reunited")).is_false()


func test_slot_summary_and_delete() -> void:
	_sample_state()
	SaveService.save_slot(3)
	var summary := SaveService.slot_summary(3)
	assert_str(str(summary["chapter"])).is_equal("ch2")
	assert_int(int(summary["playtime_sec"])).is_equal(123)
	assert_int(SaveService.delete_slot(3)).is_equal(OK)
	assert_bool(SaveService.has_slot(3)).is_false()
	assert_dict(SaveService.slot_summary(3)).is_empty()


func test_rejects_out_of_range_slot_and_missing_file() -> void:
	assert_int(SaveService.save_slot(10)).is_equal(ERR_PARAMETER_RANGE_ERROR)
	assert_int(SaveService.load_slot(7)).is_equal(ERR_FILE_NOT_FOUND)


func test_rejects_newer_schema_and_broken_saves() -> void:
	_sample_state()
	var data := SaveService.build_save(1)
	data["schema_version"] = SaveService.SCHEMA_VERSION + 1
	assert_int(SaveService.apply_save(data)).is_equal(ERR_FILE_UNRECOGNIZED)
	var broken := SaveService.build_save(1)
	(broken["location"] as Dictionary)["active_character"] = "stranger"
	assert_int(SaveService.apply_save(broken)).is_equal(ERR_INVALID_DATA)
	var f := FileAccess.open(SaveService.slot_path(4), FileAccess.WRITE)
	f.store_string("{ not json")
	f.close()
	assert_int(SaveService.load_slot(4)).is_equal(ERR_PARSE_ERROR)


func test_persist_records_endings_across_reload() -> void:
	assert_int(SaveService.record_ending("family")).is_equal(OK)
	assert_int(SaveService.record_ending("family")).is_equal(OK)
	assert_int(SaveService.record_ending("nope")).is_equal(ERR_INVALID_PARAMETER)
	SaveService.load_persist()
	assert_array(SaveService.seen_endings()).contains_exactly(["family"])
	assert_int(SaveService.clear_count()).is_equal(2)
	_copy_to_out(SaveService.persist_path(), "persist_generated.json")


func test_reach_ending_records_and_unlocks_sacrifice_choice() -> void:
	GameState.add_protect(2)
	GameState.add_heal(2)
	GameState.raise_bond(4)
	for id: String in ["family_a", "family_b", "family_c"]:
		GameState.reunite_family(id)
	assert_bool(GameState.can_offer_color()).is_false()
	assert_str(GameState.reach_ending()).is_equal("family")
	assert_str(GameState.flag("flag.endings.reached")).is_equal("family")
	assert_array(SaveService.seen_endings()).contains(["family"])
