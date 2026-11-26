class_name ColorRestoreLayer
extends CanvasLayer
## 씬마다 하나 두는 색 복원 필터 (WP-13). 노드 하나만 추가하면 자식(마스크 SubViewport, 필터 ColorRect)을 스스로 만든다.
##
## - EchoBus.color_restored(emotion, world_pos, radius) 를 받으면 그 감정 대역을 켜고, 그 위치에 원형으로 색을 되돌린다.
## - 씬을 열 때 이미 모은 잔향(EchoObject.is_collected) 자리는 애니메이션 없이 바로 복원한다 → 세이브에서 결정적으로 재현.
## - 마스크는 월드 좌표로 칠하고, 매 프레임 메인 뷰포트의 canvas_transform 을 따라가므로 카메라가 움직여도 맞는다.

const DEFAULT_LAYER := 10
const SHADER := preload("res://game/shaders/color_restore.gdshader")

## 챕터 진행도에 따른 전역 채도 (0 = 완전 흑백)
@export_range(0.0, 1.0) var global_saturation: float = 0.0:
	set(value):
		global_saturation = clampf(value, 0.0, 1.0)
		if _material != null:
			_material.set_shader_parameter("global_saturation", global_saturation)
## false 면 복원 시 원이 퍼지는 연출 없이 바로 칠한다
@export var animate_restores: bool = true

var active_emotions: Array[String] = []

var _material: ShaderMaterial
var _rect: ColorRect
var _mask_viewport: SubViewport
var _painter: ColorMaskPainter


func _ready() -> void:
	if layer == 1:
		layer = DEFAULT_LAYER
	_mask_viewport = SubViewport.new()
	_mask_viewport.name = "MaskViewport"
	_mask_viewport.transparent_bg = true
	_mask_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_mask_viewport.size = Vector2i(get_viewport().get_visible_rect().size)
	add_child(_mask_viewport)
	_painter = ColorMaskPainter.new()
	_painter.name = "MaskPainter"
	_mask_viewport.add_child(_painter)

	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_rect = ColorRect.new()
	_rect.name = "Filter"
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.material = _material
	add_child(_rect)

	_material.set_shader_parameter("color_mask", _mask_viewport.get_texture())
	_material.set_shader_parameter("global_saturation", global_saturation)
	EmotionBands.apply(_material, active_emotions)
	EchoBus.color_restored.connect(_on_color_restored)
	_restore_collected.call_deferred()


func _process(_delta: float) -> void:
	_mask_viewport.canvas_transform = get_viewport().canvas_transform


## 감정 대역을 켜고 world_pos 주변을 복원한다
func restore(emotion: String, world_pos: Vector2, radius: float, animate: bool = true) -> void:
	if not EmotionBands.EMOTION_IDS.has(emotion):
		push_error("ColorRestoreLayer: 알 수 없는 감정 '%s'" % emotion)
		return
	if not active_emotions.has(emotion):
		active_emotions.append(emotion)
		EmotionBands.apply(_material, active_emotions)
	if animate:
		_painter.pulse(world_pos, radius)
	else:
		_painter.stamp(world_pos, radius)


func band_count() -> int:
	return int(_material.get_shader_parameter("band_count"))


func painter() -> ColorMaskPainter:
	return _painter


func _on_color_restored(emotion: String, world_pos: Vector2, radius: float) -> void:
	restore(emotion, world_pos, radius, animate_restores)


func _restore_collected() -> void:
	for node in get_tree().get_nodes_in_group(EchoObject.GROUP):
		var echo := node as EchoObject
		if echo != null and echo.is_collected():
			restore(echo.emotion(), echo.global_position, echo.restore_radius, false)
