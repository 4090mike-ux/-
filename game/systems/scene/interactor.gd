class_name Interactor
extends Node
## SiblingCharacter 의 자식. 활성 캐릭터의 interact 입력을 하나로 처리한다.
## 우선순위: ① 감지된 잔향(EchoSensor, 20px) ② 가장 가까운 Interactable(각자의 radius).

signal echo_requested(echo: EchoObject)
signal interactable_requested(target: Interactable)

var enabled: bool = true
var _highlighted: Interactable = null


func character() -> SiblingCharacter:
	return get_parent() as SiblingCharacter


func sensor() -> EchoSensor:
	var c := character()
	return null if c == null else c.get_node_or_null("EchoSensor") as EchoSensor


func is_active() -> bool:
	var c := character()
	return enabled and c != null and c.active


func nearest_interactable() -> Interactable:
	var c := character()
	if c == null:
		return null
	var best: Interactable = null
	var best_dist := INF
	for node in get_tree().get_nodes_in_group(Interactable.GROUP):
		var target := node as Interactable
		if target == null or not target.is_visible_in_tree():
			continue
		var d := c.global_position.distance_to(target.global_position)
		if d <= target.radius and d < best_dist:
			best = target
			best_dist = d
	return best


func _process(_delta: float) -> void:
	var target: Interactable = nearest_interactable() if is_active() else null
	if target != _highlighted:
		if is_instance_valid(_highlighted):
			_highlighted.highlighted = false
		_highlighted = target
		if target != null:
			target.highlighted = true


## interact 한 번 (입력 대신 테스트에서도 부른다). 무언가 처리했으면 true.
func interact() -> bool:
	if not is_active():
		return false
	var s := sensor()
	if s != null:
		var echo := s.nearest_interactable()
		if echo != null:
			echo_requested.emit(echo)
			return true
	var target := nearest_interactable()
	if target != null:
		interactable_requested.emit(target)
		return true
	return false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(InputActions.INTERACT) and interact():
		get_viewport().set_input_as_handled()
