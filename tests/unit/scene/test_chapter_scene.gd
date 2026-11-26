extends GdUnitTestSuite
## WP-19 장면 뼈대: JSON 정의로 캐릭터·조사 대상·출구·레이어를 만들고, 진입 대사는 한 번만.

const DEV_ROOM := "res://game/scenes/dev/dev_room.tscn"


func before_test() -> void:
	GameData.clear_cache()
	GameState.reset()
	SceneRouter.pending_spawn = "default"


func after_test() -> void:
	GameState.reset()
	get_tree().paused = false


func _finish_dialogue(scene: ChapterScene) -> void:
	for i in 12:
		await await_idle_frame()
		if not scene.dialogue_box.is_playing:
			return
		scene.dialogue_box.advance()


func test_builds_scene_from_definition() -> void:
	var runner := scene_runner(DEV_ROOM)
	var scene := runner.scene() as ChapterScene
	assert_object(scene).is_not_null()
	assert_int(scene.characters.size()).is_equal(2)
	assert_object(scene.switcher).is_not_null()
	assert_object(scene.restore_layer).is_not_null()
	assert_object(scene.find_child("Inspect_box", true, false)).is_not_null()
	assert_int(scene.find_children("*", "SceneExit", true, false).size()).is_equal(1)
	assert_str(GameState.active_character).is_equal("haneul")
	await _finish_dialogue(scene)


func test_enter_cue_plays_once() -> void:
	var runner := scene_runner(DEV_ROOM)
	var scene := runner.scene() as ChapterScene
	await await_idle_frame()
	await await_idle_frame()
	assert_bool(scene.dialogue_box.is_playing).is_true()
	await _finish_dialogue(scene)
	assert_bool(GameState.has_seen_cue("dev_room:start")).is_true()


func test_inspect_plays_cue_and_exit_requires_flag() -> void:
	GameState.mark_cue_seen("dev_room:start")
	var runner := scene_runner(DEV_ROOM)
	var scene := runner.scene() as ChapterScene
	await await_idle_frame()
	var haneul := scene.characters["haneul"] as SiblingCharacter
	haneul.global_position = Vector2(240, 160)
	var interactor := haneul.get_node("Interactor") as Interactor
	assert_bool(interactor.interact()).is_true()
	await await_idle_frame()
	await await_idle_frame()
	assert_bool(scene.dialogue_box.is_playing).is_true()
	await _finish_dialogue(scene)
	var exit := scene.find_children("*", "SceneExit", true, false)[0] as SceneExit
	assert_bool(exit.requirements_met()).is_false()
	GameState.set_flag("flag.ch1.met_in_square", true)
	assert_bool(exit.requirements_met()).is_true()


func test_router_paths() -> void:
	assert_str(SceneRouter.scene_path("prologue_atelier")).is_equal("res://game/scenes/prologue/prologue_atelier.tscn")
	assert_str(SceneRouter.scene_path("ch1_square_02")).is_equal("res://game/scenes/ch1/ch1_square_02.tscn")
	assert_str(SceneRouter.section_of("end_family")).is_equal("endings")
