class_name SiblingSwitcher
extends Node
## 태그 전환 (Tab / 패드 Y). 광장에서 만나기 전(flag.ch1.met_in_square = false)에는 잠겨 있다.
## 프롤로그~챕터 1의 파트 교대는 씬 전환으로 처리하므로 이 노드와 무관하다.
##
## 같은 씬 안의 두 SiblingCharacter 를 NodePath 로 지정한다. 다른 시스템에는 EchoBus.character_switched 로 알린다.

const UNLOCK_FLAG := "flag.ch1.met_in_square"

@export var haneul_path: NodePath
@export var byeol_path: NodePath
## 개발용 씬에서 플래그 없이 전환을 허용
@export var force_unlocked: bool = false

var _characters: Dictionary = {}  # key → SiblingCharacter


func _ready() -> void:
	_register(haneul_path)
	_register(byeol_path)
	EchoBus.character_switched.connect(_apply)
	_apply(GameState.active_character)


func can_switch() -> bool:
	if _characters.size() < 2:
		return false
	return force_unlocked or GameState.flag(UNLOCK_FLAG) == true


## 지정한 캐릭터로 전환. 전환했으면 true.
func switch_to(character_key: String) -> bool:
	if not can_switch() or not _characters.has(character_key):
		return false
	if GameState.active_character == character_key:
		return false
	GameState.switch_character(character_key)  # → EchoBus.character_switched → _apply
	return true


func toggle() -> bool:
	return switch_to("byeol" if GameState.active_character == "haneul" else "haneul")


func active_character() -> SiblingCharacter:
	return _characters.get(GameState.active_character) as SiblingCharacter


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(InputActions.TAG_SWITCH) and toggle():
		get_viewport().set_input_as_handled()


func _register(path: NodePath) -> void:
	if path.is_empty():
		return
	var node := get_node_or_null(path) as SiblingCharacter
	if node == null:
		push_error("SiblingSwitcher: %s 는 SiblingCharacter 가 아님" % path)
		return
	_characters[node.character_key] = node


func _apply(character_key: String) -> void:
	for key: String in _characters:
		(_characters[key] as SiblingCharacter).active = key == character_key
