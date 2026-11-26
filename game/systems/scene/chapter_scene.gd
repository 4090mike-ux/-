class_name ChapterScene
extends Node2D
## 이야기 장면 공통 뼈대 (WP-19). 장면 파일은 이 스크립트 + scene_id 하나만 가진다.
##
## 정의: game/data/scenes/<scene_id>.json (docs/schemas/scene.schema.json)
## 배경: game/art/bg/<background>.png + <background>.json (걷는 영역·막힘·스폰·출구·소품 위치)
## 이 노드가 만드는 것: 배경, 벽 충돌, 캐릭터(스프라이트·감지·상호작용), 잔향 오브젝트, 조사 대상, NPC, 출구,
##   색 복원 레이어, 감지 하이라이트, 대사 상자, 퍼즐, 장소 이름 배너. 진입 대사는 한 번만 재생한다.

const SCENES_DIR := "res://game/data/scenes"
const BG_DIR := "res://game/art/bg"
const CHAR_DIR := "res://game/art/char"
const PROPS_DIR := "res://game/art/props"

@export var scene_id: String = ""

var definition: Dictionary = {}
var background_meta: Dictionary = {}
var characters: Dictionary = {}           # key → SiblingCharacter
var dialogue: DialogueResource = null
var restore_layer: ColorRestoreLayer
var dialogue_box: DialogueBox
var puzzle_host: PuzzleHost
var switcher: SiblingSwitcher = null
var garden_bed: GardenBed = null
var plant_menu: PlantMenu = null
var mechanisms: SiblingMechanisms = null

var _busy: bool = false
var _banner: Label


func _ready() -> void:
	var def: Variant = GameData.read_json("%s/%s.json" % [SCENES_DIR, scene_id])
	if not def is Dictionary:
		push_error("ChapterScene: 장면 정의 없음 %s" % scene_id)
		return
	definition = def
	var bg := str(definition.get("background", ""))
	var meta_path := "%s/%s.json" % [BG_DIR, bg]
	if FileAccess.file_exists(meta_path):
		var meta: Variant = GameData.read_json(meta_path)
		if meta is Dictionary:
			background_meta = meta
	var dialogue_path := str(definition.get("dialogue", ""))
	if not dialogue_path.is_empty() and ResourceLoader.exists(dialogue_path):
		dialogue = load(dialogue_path) as DialogueResource
	_build_background(bg)
	_build_walls()
	_spawn_characters()
	_place_echoes()
	_place_inspectables()
	_place_npcs()
	_build_exits()
	_build_layers()
	_build_garden()
	_build_mechanisms()
	_enter.call_deferred()


func is_busy() -> bool:
	return _busy


## 대사 cue 를 재생한다 (없는 cue 는 무시)
func play_cue(cue: String) -> void:
	if dialogue == null or not dialogue.cues.has(cue):
		return
	_busy = true
	await dialogue_box.play(dialogue, cue, scene_id)
	_busy = false


func has_cue(cue: String) -> bool:
	return dialogue != null and dialogue.cues.has(cue)


func active_character() -> SiblingCharacter:
	return characters.get(GameState.active_character, characters.values()[0] if not characters.is_empty() else null) as SiblingCharacter


# ---------------------------------------------------------------- 진입

func _enter() -> void:
	_show_banner()
	var cue := str(definition.get("enter_cue", "start"))
	var key := "%s:%s" % [scene_id, cue]
	if has_cue(cue) and (bool(definition.get("enter_cue_repeat", false)) or not GameState.has_seen_cue(key)):
		await play_cue(cue)
		GameState.mark_cue_seen(key)


func _show_banner() -> void:
	var place_key := "place.%s" % scene_id
	var text := tr(place_key)
	if text == place_key:
		return
	_banner.text = text
	_banner.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_banner, "modulate:a", 1.0, 0.5)
	tween.tween_interval(1.6)
	tween.tween_property(_banner, "modulate:a", 0.0, 0.8)


# ---------------------------------------------------------------- 만들기

func _build_background(bg: String) -> void:
	var path := "%s/%s.png" % [BG_DIR, bg]
	if ResourceLoader.exists(path):
		var sprite := Sprite2D.new()
		sprite.name = "Background"
		sprite.texture = load(path) as Texture2D
		sprite.centered = false
		sprite.z_index = -100
		add_child(sprite)
	else:
		var rect := ColorRect.new()
		rect.name = "Background"
		rect.color = Color("#4a494f")
		rect.size = Vector2(480, 270)
		rect.z_index = -100
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(rect)


func _build_walls() -> void:
	var body := StaticBody2D.new()
	body.name = "Walls"
	add_child(body)
	var walkable: Array = definition.get("walkable", background_meta.get("walkable", []))
	if walkable.size() >= 3:
		var poly := CollisionPolygon2D.new()
		poly.build_mode = CollisionPolygon2D.BUILD_SEGMENTS
		var points := _to_points(walkable)
		points.append(points[0])  # 닫힌 외곽선
		poly.polygon = points
		body.add_child(poly)
	for b: Variant in background_meta.get("blockers", []) + definition.get("blockers", []):
		var r := _to_rect(b)
		var shape := RectangleShape2D.new()
		shape.size = r.size
		var col := CollisionShape2D.new()
		col.shape = shape
		col.position = r.get_center()
		body.add_child(col)


func _spawn_characters() -> void:
	var keys: Array = definition.get("characters", ["haneul"])
	var spawns: Dictionary = background_meta.get("spawns", {})
	spawns.merge(definition.get("spawns", {}), true)
	var spawn_name := SceneRouter.pending_spawn if spawns.has(SceneRouter.pending_spawn) else "default"
	var base := _to_point(spawns.get(spawn_name, [240, 200]))
	var index := 0
	for key: String in keys:
		var c := SiblingCharacter.new()
		c.name = key.capitalize()
		c.character_key = key
		c.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
		c.position = base + Vector2(index * 26, 0)
		var shape := RectangleShape2D.new()
		shape.size = Vector2(12, 8)
		var col := CollisionShape2D.new()
		col.shape = shape
		col.position = Vector2(0, -4)
		c.add_child(col)
		var sheet_path := "%s/%s_walk.png" % [CHAR_DIR, key]
		if ResourceLoader.exists(sheet_path):
			var sprite := SiblingSprite.new()
			sprite.sheet = load(sheet_path) as Texture2D
			c.add_child(sprite)
		else:
			c.add_child(_placeholder_body(key))
		var sensor := EchoSensor.new()
		sensor.name = "EchoSensor"
		sensor.position = Vector2(0, -8)
		c.add_child(sensor)
		var interactor := Interactor.new()
		interactor.name = "Interactor"
		c.add_child(interactor)
		interactor.echo_requested.connect(_on_echo_requested)
		interactor.interactable_requested.connect(_on_interactable_requested)
		add_child(c)
		characters[key] = c
		index += 1
	var active := str(definition.get("active", keys[0] if not keys.is_empty() else "haneul"))
	if keys.size() >= 2:
		switcher = SiblingSwitcher.new()
		switcher.name = "Switcher"
		switcher.haneul_path = NodePath("../Haneul")
		switcher.byeol_path = NodePath("../Byeol")
		switcher.force_unlocked = bool(definition.get("switch_unlocked", false))
		add_child(switcher)
		if not keys.has(GameState.active_character):
			GameState.switch_character(active)
		elif definition.has("active"):
			GameState.switch_character(active)
	else:
		GameState.switch_character(active)
		(characters[active] as SiblingCharacter).active = true


func _place_echoes() -> void:
	var section := SceneRouter.section_of(scene_id)
	var props: Dictionary = background_meta.get("props", {})
	for entry: Variant in definition.get("echoes", []):
		var e: Dictionary = entry if entry is Dictionary else {"slug": str(entry)}
		var slug := str(e["slug"])
		var echo := EchoObject.new()
		echo.name = "Echo_" + slug
		echo.echo_id = "echo.%s.%s" % [section, slug]
		echo.position = _to_point(e.get("at", props.get(slug, [240, 160])))
		echo.restore_radius = float(e.get("restore_radius", 48.0))
		echo.outline_radius = float(e.get("outline_radius", 12.0))
		var tex_path := "%s/%s.png" % [PROPS_DIR, slug]
		if ResourceLoader.exists(tex_path):
			var sprite := Sprite2D.new()
			sprite.texture = load(tex_path) as Texture2D
			sprite.offset = Vector2(0, -sprite.texture.get_height() * 0.5)
			echo.add_child(sprite)
		add_child(echo)


func _place_inspectables() -> void:
	var props: Dictionary = background_meta.get("props", {})
	for entry: Variant in definition.get("inspectables", []):
		var e: Dictionary = entry
		var target := Interactable.new()
		target.name = "Inspect_" + str(e.get("id", "x"))
		target.interact_id = str(e.get("id", ""))
		target.cue = str(e.get("cue", "inspect_" + target.interact_id))
		target.radius = float(e.get("radius", 24.0))
		target.position = _to_point(e.get("at", props.get(target.interact_id, [240, 160])))
		add_child(target)


func _place_npcs() -> void:
	for entry: Variant in definition.get("npcs", []):
		var e: Dictionary = entry
		var npc := Node2D.new()
		var speaker := str(e.get("speaker", "npc"))
		npc.name = "Npc_" + speaker
		npc.position = _to_point(e.get("at", [240, 160]))
		var sprite := SiblingSprite.new()
		var sheet := "%s/%s_walk.png" % [CHAR_DIR, str(e.get("sprite", "npc_a"))]
		if ResourceLoader.exists(sheet):
			sprite.sheet = load(sheet) as Texture2D
		npc.add_child(sprite)
		var face := "%s/npc_face_l%d.png" % [CHAR_DIR, int(e.get("face_level", 0))]
		if int(e.get("face_level", 0)) > 0 and ResourceLoader.exists(face):
			var overlay := Sprite2D.new()
			var atlas := AtlasTexture.new()
			atlas.atlas = load(face) as Texture2D
			atlas.region = Rect2(0, 0, 24, 32)
			overlay.texture = atlas
			overlay.offset = Vector2(0, -16)
			npc.add_child(overlay)
		var body := StaticBody2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(12, 8)
		var col := CollisionShape2D.new()
		col.shape = shape
		col.position = Vector2(0, -4)
		body.add_child(col)
		npc.add_child(body)
		var talk := Interactable.new()
		talk.interact_id = speaker
		talk.cue = str(e.get("cue", "inspect_" + speaker))
		talk.radius = 24.0
		npc.add_child(talk)
		add_child(npc)


func _build_exits() -> void:
	var meta_exits := {}
	for x: Variant in background_meta.get("exits", []):
		meta_exits[str((x as Dictionary).get("name", ""))] = x
	for entry: Variant in definition.get("exits", []):
		var e: Dictionary = entry
		var exit := SceneExit.new()
		exit.exit_name = str(e.get("exit", ""))
		var rect_src: Variant = e.get("rect", (meta_exits.get(exit.exit_name, {}) as Dictionary).get("rect", [0, 0, 16, 16]))
		var r := _to_rect(rect_src)
		exit.position = r.position
		exit.rect_size = r.size
		exit.target_scene = str(e.get("to", ""))
		exit.target_spawn = str(e.get("spawn", "default"))
		exit.requires = e.get("requires", {})
		exit.blocked_cue = str(e.get("blocked_cue", "exit_blocked"))
		exit.exit_requested.connect(_on_exit_requested)
		add_child(exit)


func _build_layers() -> void:
	restore_layer = ColorRestoreLayer.new()
	restore_layer.global_saturation = float(definition.get("global_saturation", 0.0))
	add_child(restore_layer)
	add_child(EchoHighlightLayer.new())
	puzzle_host = PuzzleHost.new()
	add_child(puzzle_host)
	dialogue_box = DialogueBox.new()
	add_child(dialogue_box)
	add_child(PauseMenu.new())
	var hud := CanvasLayer.new()
	hud.layer = 20
	_banner = Label.new()
	_banner.position = Vector2(0, 14)
	_banner.size = Vector2(480, 16)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.modulate.a = 0.0
	hud.add_child(_banner)
	add_child(hud)


func _build_garden() -> void:
	if not definition.has("garden"):
		return
	var g: Dictionary = definition["garden"]
	garden_bed = GardenBed.new()
	garden_bed.name = "GardenBed"
	var rows: Array = g.get("rows_y", [160, 214])
	garden_bed.rows_y = Vector2(float(rows[0]), float(rows[1]))
	garden_bed.x0 = float(g.get("x0", 140.0))
	garden_bed.dx = float(g.get("dx", 50.0))
	garden_bed.restore_layer = restore_layer
	add_child(garden_bed)
	plant_menu = PlantMenu.new()
	add_child(plant_menu)


func _build_mechanisms() -> void:
	if not definition.has("mechanisms"):
		return
	mechanisms = SiblingMechanisms.new()
	mechanisms.name = "Mechanisms"
	add_child(mechanisms)
	mechanisms.setup(scene_id, definition.get("gates", []), definition.get("mechanisms", []))
	mechanisms.solved.connect(func(id: String) -> void: play_cue("mech_%s_solved" % id))


func show_message(text: String) -> void:
	_banner.text = text
	_banner.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_banner, "modulate:a", 1.0, 0.3)
	tween.tween_interval(1.8)
	tween.tween_property(_banner, "modulate:a", 0.0, 0.6)


# ---------------------------------------------------------------- 이벤트

func _on_echo_requested(echo: EchoObject) -> void:
	if _busy:
		return
	_busy = true
	var slug := PuzzleHost.slug_of(echo.echo_id)
	await play_cue("echo_%s_intro" % slug)
	_busy = true
	var outcome: Array = await puzzle_host.run(echo.echo_id, echo.puzzle_type())
	if bool(outcome[0]):
		echo.collect()
		await get_tree().create_timer(0.9).timeout
		await play_cue("echo_%s_after" % slug)
	_busy = false


func _on_interactable_requested(target: Interactable) -> void:
	if _busy:
		return
	if mechanisms != null and mechanisms.handle(target, active_character()):
		return
	if plant_menu != null and target.interact_id.begins_with("plot_"):
		_busy = true
		plant_menu.open(target.interact_id)
		await plant_menu.closed
		garden_bed.refresh()
		_busy = false
		return
	await play_cue(target.cue)


func _on_exit_requested(exit: SceneExit) -> void:
	if _busy:
		return
	if not exit.requirements_met():
		await play_cue(exit.blocked_cue)
		return
	_busy = true
	if garden_bed != null:
		await _finish_garden_visit()
	await SceneRouter.go(exit.target_scene, exit.target_spawn)


## 정원 방문 마무리: 틱·특별 꽃·조합 (garden.md §4-4)
func _finish_garden_visit() -> void:
	var result := GardenModel.finish_visit(scene_id)
	garden_bed.refresh()
	var lines: Array[String] = []
	if bool(result["family_flower"]):
		lines.append("가운데 화분에 가족의 꽃이 피었다")
	if bool(result["rainbow_flower"]):
		lines.append("무지개 꽃이 피었다")
	for combo: String in result["combos"]:
		var name_key := "garden.combo.%s" % combo
		lines.append("%s 이(가) 피었다" % tr(name_key))
	if bool(result["ticked"]) and lines.is_empty():
		lines.append("정원이 조금 자랐다")
	if not lines.is_empty():
		show_message(" · ".join(PackedStringArray(lines)))
		await get_tree().create_timer(1.6).timeout


## 스프라이트 시트가 아직 없을 때 쓰는 실루엣
static func _placeholder_body(key: String) -> Polygon2D:
	var body := Polygon2D.new()
	body.color = Color("#99969e") if key == "haneul" else Color("#e8d3c3")
	var h := 22.0 if key == "haneul" else 18.0
	body.polygon = PackedVector2Array([Vector2(-6, -h), Vector2(6, -h), Vector2(6, 0), Vector2(-6, 0)])
	return body


# ---------------------------------------------------------------- 좌표 변환

static func _to_point(v: Variant) -> Vector2:
	var a: Array = v
	return Vector2(float(a[0]), float(a[1]))


static func _to_points(list: Array) -> PackedVector2Array:
	var points := PackedVector2Array()
	for p: Variant in list:
		points.append(_to_point(p))
	return points


static func _to_rect(v: Variant) -> Rect2:
	var a: Array = v
	return Rect2(float(a[0]), float(a[1]), float(a[2]), float(a[3]))
