extends GdUnitTestSuite
## WP-13 색 복원 통합: 감정 대역 켜기, EchoBus 연동, 모은 잔향 재현.


func before_test() -> void:
	GameData.clear_cache()
	GameState.reset()


func after_test() -> void:
	GameState.reset()


func _layer() -> ColorRestoreLayer:
	var layer: ColorRestoreLayer = auto_free(ColorRestoreLayer.new())
	add_child(layer)
	return layer


func test_restore_turns_on_band_once() -> void:
	var layer := _layer()
	assert_int(layer.band_count()).is_equal(0)
	layer.restore("longing", Vector2(40, 40), 30.0, false)
	layer.restore("longing", Vector2(80, 40), 30.0, false)
	assert_int(layer.band_count()).is_equal(1)
	assert_array(layer.active_emotions).contains_exactly(["longing"])
	assert_int(layer.painter().stamp_count()).is_equal(2)


func test_unknown_emotion_is_ignored() -> void:
	var layer := _layer()
	layer.restore("purple", Vector2.ZERO, 10.0, false)
	assert_int(layer.band_count()).is_equal(0)


func test_listens_to_echo_bus() -> void:
	var layer := _layer()
	layer.animate_restores = false
	EchoBus.color_restored.emit("warmth", Vector2(10, 10), 20.0)
	assert_array(layer.active_emotions).contains_exactly(["warmth"])


func test_collected_echoes_are_restored_on_scene_load() -> void:
	var root: Node2D = auto_free(Node2D.new())
	var echo := EchoObject.new()
	echo.echo_id = "echo.ch1.loaded"
	echo.fallback_emotion = "healing"
	root.add_child(echo)
	GameState.collect_echo("echo.ch1.loaded")
	var layer := ColorRestoreLayer.new()
	root.add_child(layer)
	add_child(root)
	await await_idle_frame()
	assert_array(layer.active_emotions).contains_exactly(["healing"])
	assert_int(layer.painter().stamp_count()).is_equal(1)


func test_global_saturation_reaches_shader() -> void:
	var layer := _layer()
	layer.global_saturation = 0.4
	var filter := layer.get_node("Filter") as ColorRect
	var mat := filter.material as ShaderMaterial
	assert_float(float(mat.get_shader_parameter("global_saturation"))).is_equal_approx(0.4, 0.0001)
