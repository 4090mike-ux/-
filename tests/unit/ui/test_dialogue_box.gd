extends GdUnitTestSuite
## WP-21 대사 상자: 줄 진행, 화자 표시 이름(R-NAME), 선택지 기록, 상태 변경.

const TEXT := """~ start
haneul: [#portrait=smile] 안녕.
byeol: [#emotion=warmth, #sync] 같은 말!
- 그래 [#choice=ch2_test_01]
	$> GameState.add_protect(1)
	haneul: 좋아.
- 아니
	haneul: 그렇구나.
=> END
"""

var _shown: Array = []


func before_test() -> void:
	GameData.clear_cache()
	GameState.reset()
	TranslationServer.set_locale("ko")
	_shown.clear()


func after_test() -> void:
	GameState.reset()


func _box() -> DialogueBox:
	var box: DialogueBox = auto_free(DialogueBox.new())
	box.pause_tree = false
	box.seconds_per_char = 0.0
	add_child(box)
	box.line_shown.connect(func(c: String, t: String) -> void: _shown.append([c, t]))
	return box


func _step(box: DialogueBox) -> void:
	await await_idle_frame()
	await await_idle_frame()
	box.advance()


func test_plays_lines_and_records_choice() -> void:
	var box := _box()
	var res: DialogueResource = DialogueManager.create_resource_from_text(TEXT)
	box.play(res, "start", "test")
	await _step(box)  # 안녕 → 다음
	await await_idle_frame()
	await await_idle_frame()
	assert_bool(box.is_playing).is_true()
	box.choose(0)     # 응답 "그래"
	await _step(box)  # 좋아 → 끝
	await await_idle_frame()
	await await_idle_frame()
	assert_bool(box.is_playing).is_false()
	assert_int(GameState.protect).is_equal(1)
	assert_bool(GameState.has_chosen("ch2_test_01")).is_true()
	assert_array(_shown).contains_exactly([["haneul", "안녕."], ["byeol", "같은 말!"], ["haneul", "좋아."]])


func test_speaker_names_follow_r_name() -> void:
	var box := _box()
	var res: DialogueResource = DialogueManager.create_resource_from_text("~ start\nhaneul: 나야.\n=> END\n")
	box.play(res, "start")
	await await_idle_frame()
	await await_idle_frame()
	var name_label := box._name_label
	assert_str(name_label.text).is_equal("하늘")
	box.advance()
	box.advance()
	await await_idle_frame()
	GameState.set_flag("flag.ch4.truth_revealed", true)
	box.play(res, "start")
	await await_idle_frame()
	await await_idle_frame()
	assert_str(name_label.text).is_equal("은하늘")
	box.advance()
	box.advance()
