extends GdUnitTestSuite
## WP-12 잔향 감지·수집.

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


func _echo(root: Node, id: String, pos: Vector2, emotion: String, sensed_by: String = "both") -> EchoObject:
	var e := EchoObject.new()
	e.echo_id = id
	e.position = pos
	e.fallback_emotion = emotion
	e.fallback_sensed_by = sensed_by
	root.add_child(e)
	return e


## haneul(활성) + 센서, 잔향 4개: 가까움 / 멂 / 별 전용 / 이미 모음
func _scene() -> Dictionary:
	var root: Node2D = auto_free(Node2D.new())
	var c := SiblingCharacter.new()
	c.character_key = "haneul"
	root.add_child(c)
	var sensor := EchoSensor.new()
	c.add_child(sensor)
	var near := _echo(root, "echo.ch1.near", Vector2(20, 0), "longing")
	var far := _echo(root, "echo.ch1.far", Vector2(300, 0), "warmth")
	var byeol_only := _echo(root, "echo.ch1.byeol_only", Vector2(-20, 0), "healing", "byeol")
	var done := _echo(root, "echo.ch1.done", Vector2(0, 20), "dream")
	GameState.collect_echo("echo.ch1.done")
	add_child(root)
	c.active = true
	return {"sensor": sensor, "near": near, "far": far, "byeol_only": byeol_only, "done": done}


func _hold(sensor: EchoSensor, seconds: float) -> void:
	var t := 0.0
	while t < seconds:
		sensor.update_sense(0.05, true)
		t += 0.05


func test_short_press_does_not_sense() -> void:
	var s := _scene()
	var sensor: EchoSensor = s["sensor"]
	_hold(sensor, sensor.hold_time * 0.5)
	assert_float(sensor.current_radius).is_equal(0.0)
	assert_bool((s["near"] as EchoObject).is_sensed()).is_false()


func test_holding_senses_only_reachable_echoes() -> void:
	var s := _scene()
	var sensor: EchoSensor = s["sensor"]
	_hold(sensor, sensor.hold_time + sensor.grow_time + 0.1)
	assert_float(sensor.current_radius).is_equal_approx(sensor.radius, 0.01)
	assert_bool((s["near"] as EchoObject).is_sensed()).is_true()
	assert_bool((s["far"] as EchoObject).is_sensed()).is_false()
	assert_bool((s["byeol_only"] as EchoObject).is_sensed()).is_false()
	assert_bool((s["done"] as EchoObject).is_sensed()).is_false()


func test_echo_sensed_is_announced_once_per_hold() -> void:
	EchoBus.echo_sensed.connect(_record)
	var s := _scene()
	var sensor: EchoSensor = s["sensor"]
	_hold(sensor, 1.5)
	assert_array(_events).contains_exactly([["echo.ch1.near", "haneul", null]])
	sensor.update_sense(0.05, false)
	_hold(sensor, 1.5)
	assert_int(_events.size()).is_equal(2)


func test_nearest_interactable_requires_sensing_and_distance() -> void:
	var s := _scene()
	var sensor: EchoSensor = s["sensor"]
	assert_object(sensor.nearest_interactable()).is_null()
	_hold(sensor, 1.5)
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
	assert_bool(near.can_be_sensed_by("haneul")).is_false()
	assert_bool(near.can_be_sensed_by("byeol")).is_true()
