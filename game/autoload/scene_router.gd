extends Node
## 장면 전환 (오토로드 "SceneRouter").
##
## 장면 id → res://game/scenes/<구간>/<id>.tscn (구간 = id 의 첫 토큰: prologue, ch1~ch5, end→endings, ui, dev).
## 검은 화면으로 페이드 → 장면 교체 → GameState 위치 갱신 → EchoBus.scene_changed → 자동 저장(슬롯 0) → 페이드 인.

const FADE_TIME := 0.35
const STORY_SECTIONS: Array[String] = ["prologue", "ch1", "ch2", "ch3", "ch4", "ch5", "endings"]

var current_scene_id: String = ""
## 다음 장면이 캐릭터를 놓을 스폰 이름 (ChapterScene 이 읽는다)
var pending_spawn: String = "default"
var autosave_enabled: bool = true

var _layer: CanvasLayer
var _fade: ColorRect
var _busy: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_layer = CanvasLayer.new()
	_layer.layer = 100
	add_child(_layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layer.add_child(_fade)


static func section_of(scene_id: String) -> String:
	var first := scene_id.get_slice("_", 0)
	return "endings" if first == "end" else first


static func scene_path(scene_id: String) -> String:
	return "res://game/scenes/%s/%s.tscn" % [section_of(scene_id), scene_id]


func is_busy() -> bool:
	return _busy


## 장면으로 이동한다. await 할 수 있다.
func go(scene_id: String, spawn: String = "default", fade: bool = true) -> Error:
	if _busy:
		return ERR_BUSY
	var path := scene_path(scene_id)
	if not ResourceLoader.exists(path):
		push_error("SceneRouter: 장면 파일 없음 %s" % path)
		return ERR_FILE_NOT_FOUND
	_busy = true
	pending_spawn = spawn
	if fade:
		await _fade_to(1.0)
	get_tree().paused = false
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("SceneRouter: 장면 전환 실패 %s (%s)" % [path, error_string(err)])
		_busy = false
		await _fade_to(0.0)
		return err
	await get_tree().scene_changed
	current_scene_id = scene_id
	var section := section_of(scene_id)
	if STORY_SECTIONS.has(section):
		GameState.chapter = section
		GameState.scene_path = path
		GameState.spawn = spawn
	EchoBus.scene_changed.emit(scene_id)
	if autosave_enabled and STORY_SECTIONS.has(section):
		SaveService.save_slot(SaveService.AUTOSAVE_SLOT)
	if fade:
		await _fade_to(0.0)
	_busy = false
	return OK


## 세이브의 위치로 이동 (이어하기)
func continue_from_save() -> Error:
	var scene_id := GameState.scene_path.get_file().get_basename()
	if scene_id.is_empty():
		return ERR_DOES_NOT_EXIST
	var spawn := GameState.spawn if not GameState.spawn.is_empty() else "default"
	return await go(scene_id, spawn)


func _fade_to(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", alpha, FADE_TIME)
	await tween.finished
