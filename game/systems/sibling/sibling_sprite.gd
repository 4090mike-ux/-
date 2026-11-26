class_name SiblingSprite
extends AnimatedSprite2D
## 걷기 시트로 4방향 애니메이션을 만든다 (docs/style/asset_manifest.md).
## 시트: 프레임 24×32, 4열 × 4행. 행 = down, left, right, up / 열 = stand, stepA, stand, stepB. 발이 프레임 아래 가운데.
## 부모가 SiblingCharacter 면 facing·velocity 를 따라 자동으로 재생한다.

const FRAME := Vector2i(24, 32)
const DIRS: Array[String] = ["down", "left", "right", "up"]
const WALK_FPS := 8.0

@export var sheet: Texture2D
## 발소리 재질 (wood / stone / grass). 비우면 발소리 없음
@export var surface: String = ""


func _ready() -> void:
	if sheet != null:
		sprite_frames = build_frames(sheet)
	centered = true
	offset = Vector2(0, -FRAME.y * 0.5)
	if sprite_frames != null:
		play("idle_down")
	frame_changed.connect(_on_frame_changed)


func _on_frame_changed() -> void:
	if surface.is_empty() or not String(animation).begins_with("walk_") or (frame != 1 and frame != 3):
		return
	var c := get_parent() as SiblingCharacter
	if c != null and c.active:
		Audio.play_sfx("step_%s" % surface, "SFX", true)


static func build_frames(texture: Texture2D) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for row in DIRS.size():
		var dir := DIRS[row]
		var idle := StringName("idle_" + dir)
		var walk := StringName("walk_" + dir)
		frames.add_animation(idle)
		frames.add_animation(walk)
		frames.set_animation_speed(walk, WALK_FPS)
		frames.add_frame(idle, _region(texture, 0, row))
		for col in 4:
			frames.add_frame(walk, _region(texture, col, row))
	return frames


static func _region(texture: Texture2D, col: int, row: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(col * FRAME.x, row * FRAME.y, FRAME.x, FRAME.y)
	return atlas


static func dir_name(facing: Vector2) -> String:
	if facing == Vector2.LEFT:
		return "left"
	if facing == Vector2.RIGHT:
		return "right"
	if facing == Vector2.UP:
		return "up"
	return "down"


func _process(_delta: float) -> void:
	var c := get_parent() as SiblingCharacter
	if c == null or sprite_frames == null:
		return
	var moving := c.velocity.length() > 1.0
	var anim := StringName(("walk_" if moving else "idle_") + dir_name(c.facing))
	if animation != anim:
		play(anim)
