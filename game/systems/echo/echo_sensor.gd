class_name EchoSensor
extends Node2D
## 잔향 감지 (WP-12). SiblingCharacter 의 자식으로 둔다.
## echo_sense 를 hold_time 이상 누르고 있으면 감지 반경이 radius 까지 커지고, 반경 안의 잔향이 맥동한다.
## 감지된 잔향 가까이에서 interact 를 누르면 interact_requested 를 보낸다(공명 퍼즐은 받는 쪽이 연다).

signal interact_requested(echo: EchoObject)

## 이만큼 누르고 있어야 감지가 시작된다(실수로 스치는 입력 방지) [제안]
@export var hold_time: float = 0.3
## 최대 감지 반경(px) [제안]
@export var radius: float = 96.0
## 반경이 0 → radius 로 커지는 시간(초) [제안]
@export var grow_time: float = 0.6
## 상호작용 가능 거리(px) [제안]
@export var interact_radius: float = 28.0

var current_radius: float = 0.0
var _held: float = 0.0
var _announced: Dictionary = {}


func character() -> SiblingCharacter:
	return get_parent() as SiblingCharacter


func is_active() -> bool:
	var c := character()
	return c != null and c.active


func _process(delta: float) -> void:
	if not is_active():
		_held = 0.0
		current_radius = 0.0
		_announced.clear()
		queue_redraw()
		return
	update_sense(delta, Input.is_action_pressed(InputActions.ECHO_SENSE))
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not is_active() or not event.is_action_pressed(InputActions.INTERACT):
		return
	var echo := nearest_interactable()
	if echo != null:
		get_viewport().set_input_as_handled()
		interact_requested.emit(echo)


## 한 프레임 감지 갱신 (테스트에서 직접 부른다)
func update_sense(delta: float, holding: bool) -> void:
	if holding:
		_held += delta
	else:
		_held = 0.0
		_announced.clear()
	if _held >= hold_time:
		current_radius = move_toward(current_radius, radius, radius / maxf(grow_time, 0.01) * delta)
	else:
		current_radius = move_toward(current_radius, 0.0, radius * 3.0 * delta)
	if current_radius <= 0.0:
		return
	var key := character().character_key if character() != null else "both"
	for echo in targets_in(current_radius):
		var dist := global_position.distance_to(echo.global_position)
		echo.sense(1.0 - dist / (current_radius + 0.001) * 0.5)
		if not _announced.has(echo.echo_id):
			_announced[echo.echo_id] = true
			EchoBus.echo_sensed.emit(echo.echo_id, key)


## 반경 안에서 이 캐릭터가 감지할 수 있는 잔향
func targets_in(range_px: float) -> Array[EchoObject]:
	var result: Array[EchoObject] = []
	var key := character().character_key if character() != null else "both"
	for node in get_tree().get_nodes_in_group(EchoObject.GROUP):
		var echo := node as EchoObject
		if echo == null or not echo.can_be_sensed_by(key):
			continue
		if global_position.distance_to(echo.global_position) <= range_px:
			result.append(echo)
	return result


## 상호작용 거리 안의 '감지된' 잔향 중 가장 가까운 것
func nearest_interactable() -> EchoObject:
	var best: EchoObject = null
	var best_dist := INF
	for echo in targets_in(interact_radius):
		if not echo.is_sensed():
			continue
		var d := global_position.distance_to(echo.global_position)
		if d < best_dist:
			best = echo
			best_dist = d
	return best


func _draw() -> void:
	if current_radius > 1.0:
		var alpha := 0.35 * current_radius / radius
		draw_arc(Vector2.ZERO, current_radius, 0.0, TAU, 48, Color(1, 1, 1, alpha), 1.0)
