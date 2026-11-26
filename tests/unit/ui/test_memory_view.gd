extends GdUnitTestSuite
## 기억 컷 / 기억 공유 분할 화면 (echo.md §4, sibling.md §8).

var _shown: Array = []


func before_test() -> void:
	GameData.clear_cache()
	GameState.reset()
	_shown.clear()
	var defs: Array[Dictionary] = [
		{"id": "echo.ch9.solo", "emotion": "warmth", "kind": "required", "name_key": "echo.ch9.solo", "sensed_by": "byeol"},
		{"id": "echo.ch9.pair", "emotion": "dream", "kind": "required", "name_key": "echo.ch9.pair", "sensed_by": "both"},
		{"id": "echo.ch9.small", "emotion": "longing", "kind": "hidden", "name_key": "echo.ch9.small", "sensed_by": "haneul"},
	]
	GameData.override_echo_defs(defs)
	EchoBus.memory_opened.connect(_on_shown)


func after_test() -> void:
	EchoBus.memory_opened.disconnect(_on_shown)
	GameData.clear_cache()
	GameState.reset()


func _on_shown(id: String, shared: bool) -> void:
	_shown.append([id, shared])


func _view() -> MemoryView:
	var view: MemoryView = auto_free(MemoryView.new())
	add_child(view)
	return view


func test_single_echo_opens_a_card_and_closes() -> void:
	var view := _view()
	await view.open("echo.ch9.solo")
	assert_bool(view.is_open).is_true()
	assert_bool(view.shared).is_false()
	assert_int(view._halves.size()).is_equal(1)
	assert_vector(view._halves[0].size).is_equal(Vector2(244, 139))  # 240×135 + 테두리
	await view.close()
	assert_bool(view.is_open).is_false()
	assert_bool(view.visible).is_false()
	assert_array(_shown).contains_exactly([["echo.ch9.solo", false]])


func test_hidden_echo_uses_the_small_cut() -> void:
	var view := _view()
	await view.open("echo.ch9.small")
	assert_vector(view._halves[0].size).is_equal(Vector2(124, 72))
	await view.close()


func test_shared_echo_splits_the_screen_in_two() -> void:
	var view := _view()
	await view.open("echo.ch9.pair")
	assert_bool(view.shared).is_true()
	assert_int(view._halves.size()).is_equal(3)  # 두 반쪽 + 글 컷 이름표
	assert_float(view._halves[0].position.y).is_equal(0.0)
	assert_float(view._halves[1].position.y).is_equal(0.0)
	await view.close()
	assert_array(_shown).contains_exactly([["echo.ch9.pair", true]])


func test_image_path_prefers_art_file_by_slug() -> void:
	assert_str(MemoryView.image_path("echo.ch9.solo")).is_empty()  # 그림이 없으면 글 컷
