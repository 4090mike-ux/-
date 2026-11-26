class_name GameData
extends RefCounted
## game/data/*.json 계약 데이터를 읽는다 (처음 한 번만 읽고 캐시). 감정 색은 EmotionBands 가 담당한다.

const FLAGS_PATH := "res://game/data/flags.json"
const SPEAKERS_PATH := "res://game/data/speakers.json"
const ECHOES_DIR := "res://game/data/echoes"

static var _flag_defs: Dictionary = {}
static var _variable_defs: Dictionary = {}
static var _speakers: Dictionary = {}
static var _echo_defs: Dictionary = {}
static var _echoes_loaded := false


## 플래그 id → 정의 (type, default, values, chapter, ...)
static func flag_defs() -> Dictionary:
	if _flag_defs.is_empty():
		_load_flags()
	return _flag_defs


static func flag_def(flag_id: String) -> Dictionary:
	return flag_defs().get(flag_id, {})


## 변수 id → 정의 (protect, heal, bond, ...)
static func variable_defs() -> Dictionary:
	if _variable_defs.is_empty():
		_load_flags()
	return _variable_defs


## 화자 키 → {key, name_key, truth_name_key?}
static func speaker(key: String) -> Dictionary:
	if _speakers.is_empty():
		var data: Variant = read_json(SPEAKERS_PATH)
		if data is Dictionary:
			for entry: Dictionary in (data as Dictionary).get("speakers", []):
				_speakers[entry["key"]] = entry
	return _speakers.get(key, {})


## 잔향 id → 정의. game/data/echoes/*.json 전체를 읽는다.
static func echo_def(echo_id: String) -> Dictionary:
	if not _echoes_loaded:
		_load_echoes()
	return _echo_defs.get(echo_id, {})


## 테스트 전용: 잔향 정의를 직접 넣는다 (실제 데이터 파일이 아직 없을 때).
static func override_echo_defs(defs: Array[Dictionary]) -> void:
	_echo_defs.clear()
	for entry in defs:
		_echo_defs[entry["id"]] = entry
	_echoes_loaded = true


## 캐시를 비운다 (테스트·핫리로드용)
static func clear_cache() -> void:
	_flag_defs.clear()
	_variable_defs.clear()
	_speakers.clear()
	_echo_defs.clear()
	_echoes_loaded = false


static func read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_error("GameData: 파일 없음 %s" % path)
		return null
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed == null:
		push_error("GameData: JSON 파싱 실패 %s" % path)
	return parsed


static func _load_flags() -> void:
	var data: Variant = read_json(FLAGS_PATH)
	if not data is Dictionary:
		return
	var dict := data as Dictionary
	for entry: Dictionary in dict.get("flags", []):
		_flag_defs[entry["id"]] = entry
	for entry: Dictionary in dict.get("variables", []):
		_variable_defs[entry["id"]] = entry


static func _load_echoes() -> void:
	_echoes_loaded = true
	var dir := DirAccess.open(ECHOES_DIR)
	if dir == null:
		return  # 잔향 데이터는 WP-06 이후에 생긴다
	for file in dir.get_files():
		if file.get_extension() != "json":
			continue
		var data: Variant = read_json(ECHOES_DIR.path_join(file))
		if data is Dictionary:
			for entry: Dictionary in (data as Dictionary).get("echoes", []):
				_echo_defs[entry["id"]] = entry
