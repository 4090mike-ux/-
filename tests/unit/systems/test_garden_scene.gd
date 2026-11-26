extends GdUnitTestSuite
## 정원 칸 그리기·심기 메뉴 (WP-20 UI).

func before_test() -> void:
	GameData.clear_cache()
	GardenModel.clear_cache()
	GameState.reset()
	var defs: Array[Dictionary] = [{"id": "echo.prologue.g", "emotion": "warmth", "sensed_by": "byeol", "kind": "required", "reward": {"color_shards": 1}}]
	GameData.override_echo_defs(defs)


func after_test() -> void:
	GameData.clear_cache()
	GameState.reset()


func test_bed_creates_ten_plots_and_menu_plants() -> void:
	var bed: GardenBed = auto_free(GardenBed.new())
	add_child(bed)
	assert_int(bed.find_children("Plot_*", "Interactable", false, false).size()).is_equal(10)
	GameState.switch_character("byeol")
	GameState.collect_echo("echo.prologue.g")
	var menu: PlantMenu = auto_free(PlantMenu.new())
	menu.pause_tree = false
	add_child(menu)
	menu.open("plot_01")
	assert_str(menu.message).contains("줄이다")   # 하늘 줄
	menu.close()
	menu.open("plot_06")
	assert_array(menu.options).contains_exactly(["warmth"])
	assert_bool(menu.confirm()).is_true()
	assert_str(str(GardenModel.planted()["plot_06"]["emotion"])).is_equal("warmth")
