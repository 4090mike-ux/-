extends GdUnitTestSuite
## 버티컬 슬라이스 14장면 통합 검사: 장면이 뜨고, 캐릭터가 걷는 영역 안에서 시작하며,
## 그 장면에서 할 일(잔향 수집·심기·대화·대사 속 상태 변화)을 하면 주 출구가 열리는가.

const ORDER: Array[String] = [
	"prologue_atelier", "prologue_garden", "prologue_door", "prologue_gate",
	"ch1_atelier", "ch1_garden", "ch1_lane", "ch1_path", "ch1_stairs", "ch1_market",
	"ch1_square", "ch1_square_02", "ch1_garden_02", "ch1_night",
]


func before_test() -> void:
	GameData.clear_cache()
	GardenModel.clear_cache()
	GameState.reset()
	SceneRouter.pending_spawn = "default"


func after_test() -> void:
	GameState.reset()
	get_tree().paused = false


func _path(scene_id: String) -> String:
	return SceneRouter.scene_path(scene_id)


## 앞 장면들을 끝낸 상태를 만든다 (모든 잔향·대사 상태)
func _progress_until(scene_id: String) -> void:
	for sid in ORDER:
		if sid == scene_id:
			return
		var def: Dictionary = GameData.read_json("res://game/data/scenes/%s.json" % sid)
		_complete(sid, def)


func _complete(sid: String, def: Dictionary) -> void:
	var section := SceneRouter.section_of(sid)
	for e: Variant in def.get("echoes", []):
		var entry: Dictionary = e if e is Dictionary else {"slug": str(e)}
		if not bool(entry.get("display_only", false)):
			GameState.collect_echo(str(entry.get("id", "echo.%s.%s" % [section, str(entry.get("slug", ""))])))
	GameState.mark_cue_seen("%s:start" % sid)
	GameState.mark_cue_seen("%s:title_card" % sid)
	if sid == "ch1_square":  # start 대사 안의 상태 변화
		GameState.set_flag("flag.ch1.met_in_square", true)
		GameState.raise_bond(1)
	for x: Variant in def.get("exits", []):
		var req: Dictionary = (x as Dictionary).get("requires", {})
		for plot: Variant in req.get("plots", []):
			var owner := GardenModel.owner_of(str(plot))
			var pocket := GardenModel.pocket(owner)
			for emotion: String in pocket:
				if int(pocket[emotion]) > 0:
					GardenModel.plant(str(plot), emotion, owner)
					break
		if req.has("owner_planted"):
			var owner2 := str(req["owner_planted"])
			var pocket2 := GardenModel.pocket(owner2)
			for emotion2: String in pocket2:
				if int(pocket2[emotion2]) > 0:
					GardenModel.plant(GardenModel.plot_ids(owner2)[0], emotion2, owner2)
					break


func test_every_slice_scene_loads_with_characters_on_walkable_floor() -> void:
	for sid in ORDER:
		GameState.reset()
		_progress_until(sid)
		GameState.mark_cue_seen("%s:start" % sid)
		GameState.mark_cue_seen("%s:title_card" % sid)
		var runner := scene_runner(_path(sid))
		var scene := runner.scene() as ChapterScene
		assert_object(scene).override_failure_message("%s 가 뜨지 않음" % sid).is_not_null()
		var walk: Array = scene.definition.get("walkable", scene.background_meta.get("walkable", []))
		var poly := ChapterScene._to_points(walk)
		for c: SiblingCharacter in scene.characters.values():
			assert_bool(Geometry2D.is_point_in_polygon(c.position, poly)) \
				.override_failure_message("%s: %s 시작 위치 %s 가 걷는 영역 밖" % [sid, c.character_key, c.position]).is_true()
		await await_idle_frame()


func test_main_exit_opens_after_doing_the_scene() -> void:
	for sid in ORDER:
		GameState.reset()
		_progress_until(sid)
		var def: Dictionary = GameData.read_json("res://game/data/scenes/%s.json" % sid)
		_complete(sid, def)
		GameState.mark_cue_seen("%s:start" % sid)
		var runner := scene_runner(_path(sid))
		var scene := runner.scene() as ChapterScene
		await await_idle_frame()
		for target: Interactable in scene.find_children("*", "Interactable", true, false):
			scene._inspected[target.interact_id] = true  # 그 장면의 대화·조사를 모두 했다고 본다
		var open_exits := 0
		for exit: SceneExit in scene.find_children("*", "SceneExit", true, false):
			if exit.requirements_met() and scene._local_requirements_met(exit.requires):
				open_exits += 1
		assert_int(open_exits).override_failure_message("%s: 할 일을 다 해도 열리는 출구가 없음" % sid).is_greater(0)


func test_echo_objects_exist_where_data_says() -> void:
	for sid in ORDER:
		GameState.reset()
		_progress_until(sid)
		GameState.mark_cue_seen("%s:start" % sid)
		var runner := scene_runner(_path(sid))
		var scene := runner.scene() as ChapterScene
		var section := SceneRouter.section_of(sid)
		for e: Variant in scene.definition.get("echoes", []):
			var entry: Dictionary = e if e is Dictionary else {"slug": str(e)}
			if bool(entry.get("display_only", false)):
				continue
			var id := str(entry.get("id", "echo.%s.%s" % [section, str(entry.get("slug", ""))]))
			assert_object(scene.find_child("Echo_" + id.get_slice(".", 2), true, false)) \
				.override_failure_message("%s: 잔향 %s 오브젝트 없음" % [sid, id]).is_not_null()
		await await_idle_frame()


func test_arriving_inside_an_exit_does_not_trigger_it() -> void:
	# ch1_square 는 하늘이 계단 출구 안(from_stairs)에서 시작한다 → 막힌 출구 대사가 바로 나오면 안 된다
	_progress_until("ch1_square")
	GameState.mark_cue_seen("ch1_square:start")
	var runner := scene_runner(_path("ch1_square"))
	var scene := runner.scene() as ChapterScene
	await runner.simulate_frames(20)
	assert_bool(scene.dialogue_box.is_playing).is_false()
	assert_bool(get_tree().paused).is_false()
