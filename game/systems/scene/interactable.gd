class_name Interactable
extends Node2D
## 조사할 수 있는 물건·NPC. 활성 캐릭터가 radius 안에서 interact 하면 Interactor 가 interactable_requested 를 보낸다.
## 무엇을 할지(대사 cue 재생 등)는 장면(ChapterScene)이 정한다.

const GROUP := &"interactables"

@export var interact_id: String = ""
## 재생할 대사 cue (scene 의 .dialogue 안)
@export var cue: String = ""
## 상호작용 거리 (NPC 24px, 물건 20~24px — docs/gdd/controls_accessibility.md)
@export var radius: float = 24.0

var highlighted: bool = false:
	set(value):
		if highlighted != value:
			highlighted = value
			queue_redraw()


func _ready() -> void:
	add_to_group(GROUP)


func _draw() -> void:
	if highlighted:
		var top := Vector2(0, -26)
		draw_colored_polygon(PackedVector2Array([top + Vector2(0, -4), top + Vector2(3, 0), top + Vector2(0, 4), top + Vector2(-3, 0)]),
			Color(1, 1, 1, 0.9))
