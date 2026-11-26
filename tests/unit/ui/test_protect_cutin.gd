extends GdUnitTestSuite
## 보호 본능 컷인 (sibling.md §7): 보호자 규칙, 1.2초 재생, 본 적 있는 컷인만 건너뛰기, 대사 상자 연동.

const TEXT := """~ start
[#cutin=protect] 상자가 무너진다!
haneul: 괜찮아?
=> END
"""

var _played: Array[String] = []


func before_test() -> void:
	GameData.clear_cache()
	GameState.reset()
	_played.clear()
	EchoBus.protect_cutin_played.connect(_on_played)


func after_test() -> void:
	EchoBus.protect_cutin_played.disconnect(_on_played)
	GameState.reset()


func _on_played(protector: String) -> void:
	_played.append(protector)


func test_protector_is_haneul_before_bond_3_then_active_character() -> void:
	assert_str(ProtectCutIn.protector_for(0, "byeol")).is_equal("haneul")
	assert_str(ProtectCutIn.protector_for(2, "byeol")).is_equal("haneul")
	assert_str(ProtectCutIn.protector_for(3, "byeol")).is_equal("byeol")
	assert_str(ProtectCutIn.protector_for(4, "haneul")).is_equal("haneul")
	assert_str(ProtectCutIn.other_of("haneul")).is_equal("byeol")


func test_plays_for_about_1_2_seconds_and_reports_protector() -> void:
	var cutin: ProtectCutIn = auto_free(ProtectCutIn.new())
	add_child(cutin)
	var start := Time.get_ticks_msec()
	await cutin.play("test:cutin:a")
	var elapsed := (Time.get_ticks_msec() - start) / 1000.0
	assert_float(elapsed).is_between(0.9, 2.5)
	assert_bool(cutin.is_playing).is_false()
	assert_array(_played).contains_exactly(["haneul"])
	assert_bool(GameState.has_seen_cue("test:cutin:a")).is_true()


func test_only_seen_cutins_can_be_skipped() -> void:
	var cutin: ProtectCutIn = auto_free(ProtectCutIn.new())
	add_child(cutin)
	cutin.play("test:cutin:b")
	await await_idle_frame()
	cutin.skip()  # 처음 보는 컷인: 건너뛸 수 없다
	await await_millis(300)
	assert_bool(cutin.is_playing).is_true()
	await cutin.finished
	cutin.play("test:cutin:b")
	await await_idle_frame()
	cutin.skip()  # 두 번째: 건너뛴다
	await await_idle_frame()
	await await_idle_frame()
	assert_bool(cutin.is_playing).is_false()


func test_dialogue_box_plays_cutin_before_the_tagged_line() -> void:
	var box: DialogueBox = auto_free(DialogueBox.new())
	box.pause_tree = false
	box.use_settings = false
	box.seconds_per_char = 0.0
	add_child(box)
	var res: DialogueResource = DialogueManager.create_resource_from_text(TEXT)
	box.play(res, "start", "test_scene")
	await await_idle_frame()
	await await_idle_frame()
	assert_object(box.cutin()).is_not_null()
	assert_bool(box.cutin().is_playing).is_true()
	assert_bool(box._panel.visible).is_false()
	await box.cutin().finished
	await await_idle_frame()
	assert_bool(box._panel.visible).is_true()
	assert_str(box.current_line.text).is_equal("상자가 무너진다!")
	assert_array(_played).has_size(1)
	box.advance()
	await await_idle_frame()
	box.advance()
	await await_idle_frame()
	box.advance()
	await await_idle_frame()
	await await_idle_frame()
	assert_bool(box.is_playing).is_false()


func test_npc_lines_use_npc_blip_when_present() -> void:
	var box: DialogueBox = auto_free(DialogueBox.new())
	add_child(box)
	assert_str(box.blip_for("haneul")).is_equal("dlg_blip_haneul")
	assert_str(box.blip_for("byeol")).is_equal("dlg_blip_byeol")
	var expected := "dlg_blip_npc" if Audio.has_sfx("dlg_blip_npc") else "dlg_blip_byeol"
	assert_str(box.blip_for("jieun")).is_equal(expected)
