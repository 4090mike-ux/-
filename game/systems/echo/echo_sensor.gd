class_name EchoSensor
extends Node2D
## 잔향 감지 (WP-12). SiblingCharacter 의 자식으로 둔다. 수치는 docs/gdd/echo.md §2 [제안].
##
## - echo_sense 를 누르고 있으면 감지 반경이 0.6초에 걸쳐 최대 반경까지 넓어진다(ease-out).
## - 최대 반경 = 80px + bond 보너스(2:+8, 3:+16, 4:+24). 두 사람이 40px 안 + bond ≥ 1 이면 ×1.25.
## - 숨김 잔향은 현재 반경의 60% 안에서만, 공명 잔향(both)은 두 사람이 64px 안에 함께 있을 때만 감지된다.
## - 감지 중 이동 속도 ×0.6. 감지된 잔향 20px 안에서의 interact 입력은 Interactor 가 처리한다.

@export var base_radius: float = 80.0
## bond 0~4 별 추가 반경
@export var bond_radius_bonus: Array[float] = [0.0, 0.0, 8.0, 16.0, 24.0]
@export var resonance_multiplier: float = 1.25
@export var resonance_distance: float = 40.0
@export var together_distance: float = 64.0
@export var hidden_radius_ratio: float = 0.6
@export var sensing_speed_multiplier: float = 0.6
## 이만큼 누른 뒤부터 반경이 넓어진다 (0 = 바로)
@export var hold_time: float = 0.0
@export var grow_time: float = 0.6
@export var interact_radius: float = 20.0

var current_radius: float = 0.0
var _held: float = 0.0
var _toggled: bool = false
var _announced: Dictionary = {}


func character() -> SiblingCharacter:
	return get_parent() as SiblingCharacter


func character_key() -> String:
	var c := character()
	return c.character_key if c != null else "haneul"


func is_active() -> bool:
	var c := character()
	return c != null and c.active


## 상대 캐릭터까지 거리 (상대가 없으면 INF)
func partner_distance() -> float:
	var c := character()
	if c == null:
		return INF
	var other := c.partner()
	return INF if other == null else c.global_position.distance_to(other.global_position)


func siblings_together() -> bool:
	return partner_distance() <= together_distance


func max_radius() -> float:
	var bond := clampi(GameState.bond, 0, bond_radius_bonus.size() - 1)
	var r := base_radius + bond_radius_bonus[bond]
	if GameState.bond >= 1 and partner_distance() <= resonance_distance:
		r *= resonance_multiplier
	return r


func _process(delta: float) -> void:
	if not is_active():
		_held = 0.0
		current_radius = 0.0
		_announced.clear()
		queue_redraw()
		return
	var holding := Input.is_action_pressed(InputActions.ECHO_SENSE)
	if Settings.echo_sense_toggle():  # 접근성: 한 번 눌러 켜고 한 번 더 눌러 끔
		if Input.is_action_just_pressed(InputActions.ECHO_SENSE):
			_toggled = not _toggled
		holding = _toggled
	update_sense(delta, holding)
	queue_redraw()


## 한 프레임 감지 갱신 (테스트에서 직접 부른다)
func update_sense(delta: float, holding: bool) -> void:
	var c := character()
	if c != null:
		c.speed_multiplier = sensing_speed_multiplier if holding else 1.0
	if not holding:
		_held = 0.0
		_announced.clear()
		current_radius = move_toward(current_radius, 0.0, base_radius * 4.0 * delta)
		return
	_held += delta
	var t := clampf((_held - hold_time) / maxf(grow_time, 0.01), 0.0, 1.0)
	current_radius = max_radius() * ease(t, 0.4)
	if current_radius <= 0.0:
		return
	for echo in targets_in(current_radius):
		var dist := global_position.distance_to(echo.global_position)
		echo.sense(1.0 - dist / (current_radius + 0.001) * 0.5)
		if not _announced.has(echo.echo_id):
			_announced[echo.echo_id] = true
			EchoBus.echo_sensed.emit(echo.echo_id, character_key())


## 반경 안에서 이 캐릭터가 지금 감지할 수 있는 잔향 (숨김은 반경의 60% 안)
func targets_in(range_px: float) -> Array[EchoObject]:
	var result: Array[EchoObject] = []
	var key := character_key()
	var together := siblings_together()
	for node in get_tree().get_nodes_in_group(EchoObject.GROUP):
		var echo := node as EchoObject
		if echo == null or not echo.can_be_sensed_by(key, together):
			continue
		var limit := range_px * (hidden_radius_ratio if echo.is_hidden() else 1.0)
		if global_position.distance_to(echo.global_position) <= limit:
			result.append(echo)
	return result


## 상호작용 거리 안의 '감지된' 잔향 중 가장 가까운 것
func nearest_interactable() -> EchoObject:
	var best: EchoObject = null
	var best_dist := INF
	for node in get_tree().get_nodes_in_group(EchoObject.GROUP):
		var echo := node as EchoObject
		if echo == null or not echo.is_sensed() or not echo.can_be_sensed_by(character_key(), siblings_together()):
			continue
		var d := global_position.distance_to(echo.global_position)
		if d <= interact_radius and d < best_dist:
			best = echo
			best_dist = d
	return best


func _draw() -> void:
	if current_radius > 1.0:
		var alpha := 0.3 * current_radius / max_radius()
		draw_arc(Vector2.ZERO, current_radius, 0.0, TAU, 48, Color(1, 1, 1, alpha), 1.0)
