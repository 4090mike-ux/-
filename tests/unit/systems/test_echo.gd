extends GdUnitTestSuite
## WP-12 잔향 감지·수집 (수치: docs/gdd/echo.md §2).

var _events: Array = []


func before_test() -> void:
	GameData.clear_cache()
	GameState.reset()
	_events.clear()


func after_test() -> void:
	GameState.reset()
	for sig: String in ["echo_sensed", "color_restored"]:
		for c: Dictionary in EchoBus.get_signal_connection_list(sig):
			var callable: Callable = c["callable"]
			if callable.get_object() == self:
				EchoBus.disconnect(sig, callable)


func _record(a: Variant = null, b: Variant = null, c: Variant = null) -> void:
	_events.append([a, b, c])


func _echo(root: Node, id: String, pos: Vector2, emotion: String, sensed_by: String = "haneul",
		hidden: bool = false) -> EchoObject:
	var e := EchoObject.new()
	e.echo_id = id
	e.position = pos
	e.fallback_emotion = emotion
	e.fallback_sensed_by = sensed_by
	e.fallback_hidden = hidden
	root.add_child(e)
	return e


func _character(root: Node, key: String, pos: Vector2) -> SiblingCharacter:
	var c := SiblingCharacter.new()
	c.character_key = key
	c.position = pos
	root.add_child(c)
	return c


## haneul(활성, 원점) + 센서. byeol 위치는 인자로 (멀리 두면 '함께'가 아님)
func _scene(byeol_pos: Vector2 = Vector2(400, 0)) -> Dictionary:
	var root: Node2D = auto_free(Node2D.new())
	var haneul := _character(root, "haneul", Vector2.ZERO)
	var sensor := EchoSensor.new()
	haneul.add_child(sensor)
	var byeol := _character(root, "byeol", byeol_pos)
	var near := _echo(root, "echo.ch1.near", Vector2(30, 0), "longing")
	var far := _echo(root, "echo.ch1.far", Vector2(300, 0), "warmth")
	var byeol_only := _echo(root, "echo.ch1.byeol_only", Vector2(-20, 0), "healing", "byeol")
	var hidden := _echo(root, "echo.ch1.hidden", Vector2(0, 60), "dream", "haneul", true)
	var shared := _echo(root, "echo.ch1.shared", Vector2(0, -30), "courage", "both")
	var done := _echo(root, "echo.ch1.done", Vector2(0, 20), "dream")
	GameState.collect_echo("echo.ch1.done")
	add_child(root)
	haneul.active = true
	return {"sensor": sensor, "haneul": haneul, "byeol": byeol, "near": near, "far": far,
		"byeol_only": byeol_only, "hidden": hidden, "shared": shared, "done": done}


func _hold(sensor: EchoSensor, seconds: float) -> void:
	var t := 0.0
	while t < seconds:
		sensor.update_sense(0.05, true)
		t += 0.05


func test_radius_grows_to_max_over_grow_time() -> void:
	var s := _scene()
	var sensor: EchoSensor = s["sensor"]
	_hold(sensor, 0.1)
	var early := sensor.current_radius
	_hold(sensor, sensor.grow_time)
	assert_float(early).is_less(sensor.current_radius)
	assert_float(sensor.current_radius).is_equal_approx(80.0, 0.01)


func test_bond_and_resonance_extend_radius() -> void:
	var s := _scene()
	var sensor: EchoSensor = s["sensor"]
	assert_float(sensor.max_radius()).is_equal(80.0)
	GameState.raise_bond(3)
	assert_float(sensor.max_radius()).is_equal(96.0)
	(s["byeol"] as SiblingCharacter).position = Vector2(30, 0)  # 40px 안 → ×1.25
	assert_float(sensor.max_radius()).is_equal_approx(120.0, 0.001)


func test_holding_senses_only_reachable_echoes() -> void:
	var s := _scene()
	var sensor: EchoSensor = s["sensor"]
	_hold(sensor, 1.0)
	assert_bool((s["near"] as EchoObject).is_sensed()).is_true()
	assert_bool((s["far"] as EchoObject).is_sensed()).is_false()
	assert_bool((s["byeol_only"] as EchoObject).is_sensed()).is_false()
	assert_bool((s["done"] as EchoObject).is_sensed()).is_false()


func test_hidden_echo_needs_sixty_percent_radius() -> void:
	var s := _scene()
	var sensor: EchoSensor = s["sensor"]
	_hold(sensor, 1.0)  # 반경 80 → 숨김은 48 안. 숨김 잔향은 60 거리
	assert_bool((s["hidden"] as EchoObject).is_sensed()).is_false()
	(s["hidden"] as EchoObject).position = Vector2(0, 40)
	_hold(sensor, 0.1)
	assert_bool((s["hidden"] as EchoObject).is_sensed()).is_true()


func test_shared_echo_needs_siblings_together() -> void:
	var s := _scene()
	var sensor: EchoSensor = s["sensor"]
	_hold(sensor, 1.0)
	assert_bool((s["shared"] as EchoObject).is_sensed()).is_false()
	(s["byeol"] as SiblingCharacter).position = Vector2(50, 0)  # 64px 안
	_hold(sensor, 0.1)
	assert_bool((s["shared"] as EchoObject).is_sensed()).is_true()


func test_sensing_slows_walking() -> void:
	var s := _scene()
	var sensor: EchoSensor = s["sensor"]
	var haneul: SiblingCharacter = s["haneul"]
	_hold(sensor, 0.1)
	assert_float(haneul.speed_multiplier).is_equal(0.6)
	sensor.update_sense(0.05, false)
	assert_float(haneul.speed_multiplier).is_equal(1.0)


func test_outline_lingers_after_release() -> void:
	var s := _scene()
	var sensor: EchoSensor = s["sensor"]
	var near: EchoObject = s["near"]
	_hold(sensor, 1.0)
	sensor.update_sense(0.05, false)
	near._process(1.5)
	assert_bool(near.is_sensed()).is_true()
	near._process(1.0)  # 2초 유지 끝 → 페이드 시작
	near._process(0.6)
	assert_bool(near.is_sensed()).is_false()


func test_echo_sensed_is_announced_once_per_hold() -> void:
	EchoBus.echo_sensed.connect(_record)
	var s := _scene()
	var sensor: EchoSensor = s["sensor"]
	_hold(sensor, 1.0)
	assert_array(_events).contains_exactly([["echo.ch1.near", "haneul", null]])
	sensor.update_sense(0.05, false)
	_hold(sensor, 1.0)
	assert_int(_events.size()).is_equal(2)


func test_nearest_interactable_requires_sensing_and_distance() -> void:
	var s := _scene()
	var sensor: EchoSensor = s["sensor"]
	(s["near"] as EchoObject).position = Vector2(15, 0)
	assert_object(sensor.nearest_interactable()).is_null()
	_hold(sensor, 1.0)
	assert_object(sensor.nearest_interactable()).is_same(s["near"])


func test_collect_restores_color_once() -> void:
	EchoBus.color_restored.connect(_record)
	var s := _scene()
	var near: EchoObject = s["near"]
	assert_bool(near.collect()).is_true()
	assert_bool(near.collect()).is_false()
	assert_bool(GameState.has_echo("echo.ch1.near")).is_true()
	assert_array(_events).contains_exactly([["longing", near.global_position, near.restore_radius]])


func test_definition_data_overrides_fallbacks() -> void:
	var defs: Array[Dictionary] = [{"id": "echo.ch1.near", "emotion": "courage", "sensed_by": "byeol", "kind": "hidden"}]
	GameData.override_echo_defs(defs)
	var s := _scene()
	var near: EchoObject = s["near"]
	assert_str(near.emotion()).is_equal("courage")
	assert_bool(near.is_hidden()).is_true()
	assert_bool(near.can_be_sensed_by("haneul")).is_false()
	assert_bool(near.can_be_sensed_by("byeol")).is_true()
