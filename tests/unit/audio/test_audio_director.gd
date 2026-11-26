extends GdUnitTestSuite
## WP-22 소리 감독: 버스, 채도 연동 필터, 슬라이스에서 쓰는 소리 파일.

const USED_SFX: Array[String] = [
	"ui_move", "ui_save", "dlg_blip_haneul", "dlg_blip_byeol", "dlg_sync", "step_wood", "step_stone", "step_grass",
	"step_door", "echo_sense_start", "echo_sense_end", "echo_found_longing", "echo_found_warmth", "echo_hidden_sparkle",
	"pzl_open", "pzl_place_ok", "pzl_place_no", "pzl_hint", "pzl_solved", "color_restore_longing", "color_restore_warmth",
	"garden_plant", "garden_grow", "sib_tag_switch",
]


func test_buses_exist_with_lowpass() -> void:
	for bus: String in ["Music", "Ambience", "SFX", "UI"]:
		assert_int(AudioServer.get_bus_index(bus)).is_greater_equal(0)
	var music := AudioServer.get_bus_index("Music")
	assert_object(AudioServer.get_bus_effect(music, 0)).is_instanceof(AudioEffectLowPassFilter)


func test_saturation_controls_cutoff() -> void:
	Audio.set_saturation(0.0)
	assert_float(Audio.cutoff_hz()).is_equal_approx(3000.0, 1.0)
	Audio.set_saturation(1.0)
	assert_float(Audio.cutoff_hz()).is_equal_approx(20000.0, 1.0)
	Audio.set_saturation(0.5)
	assert_float(Audio.cutoff_hz()).is_between(7600.0, 7800.0)
	Audio.set_saturation(0.0)


func test_slice_sounds_exist() -> void:
	var missing: Array[String] = []
	for name in USED_SFX:
		var path := "res://game/audio/sfx/%s/sfx_%s.wav" % [name.get_slice("_", 0), name]
		if not ResourceLoader.exists(path):
			missing.append(path)
	for bgm: String in ["haneul", "byeol", "square"]:
		if not ResourceLoader.exists("res://game/audio/bgm/bgm_%s.ogg" % bgm):
			missing.append(bgm)
	assert_array(missing).is_empty()
