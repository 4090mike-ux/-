extends Node
## 세이브·공유 기록 (오토로드 "SaveService").
##
## - 슬롯 세이브: user://save_{slot}.json   스키마 docs/schemas/save.schema.json
## - 공유 기록:   user://persist.json        스키마 docs/schemas/persist.schema.json
## 파일은 임시 파일에 먼저 쓰고 바꿔 끼운다(쓰는 도중 꺼져도 기존 세이브가 깨지지 않게).
## 스키마를 바꾸면 SCHEMA_VERSION 을 올리고 _migrate_save() 에 변환을 추가한다.

const SCHEMA_VERSION := 1
const PERSIST_SCHEMA_VERSION := 1
const MAX_SLOT := 9
const AUTOSAVE_SLOT := 0

## 테스트에서 다른 폴더로 바꿀 수 있다
var save_dir: String = "user://"

var _persist: Dictionary = {}


func _ready() -> void:
	load_persist()


func slot_path(slot: int) -> String:
	return save_dir.path_join("save_%d.json" % slot)


func persist_path() -> String:
	return save_dir.path_join("persist.json")


# ---------------------------------------------------------------- 슬롯

func save_slot(slot: int) -> Error:
	if slot < 0 or slot > MAX_SLOT:
		push_error("SaveService: 슬롯 범위 0~%d (받은 값 %d)" % [MAX_SLOT, slot])
		return ERR_PARAMETER_RANGE_ERROR
	var err := _write_json(slot_path(slot), build_save(slot))
	if err == OK:
		EchoBus.game_saved.emit(slot)
	return err


func load_slot(slot: int) -> Error:
	var path := slot_path(slot)
	if not FileAccess.file_exists(path):
		return ERR_FILE_NOT_FOUND
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("SaveService: 세이브 파싱 실패 %s" % path)
		return ERR_PARSE_ERROR
	var err := apply_save(parsed as Dictionary)
	if err == OK:
		EchoBus.game_loaded.emit(slot)
	return err


func has_slot(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))


func delete_slot(slot: int) -> Error:
	if not has_slot(slot):
		return ERR_FILE_NOT_FOUND
	return DirAccess.remove_absolute(slot_path(slot))


## 세이브 목록 UI 용 요약. 슬롯이 없으면 빈 Dictionary.
func slot_summary(slot: int) -> Dictionary:
	if not has_slot(slot):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(slot_path(slot)))
	if not parsed is Dictionary:
		return {"slot": slot, "broken": true}
	var data := parsed as Dictionary
	var loc: Dictionary = data.get("location", {})
	return {
		"slot": slot,
		"saved_at": str(data.get("saved_at", "")),
		"playtime_sec": int(data.get("playtime_sec", 0)),
		"chapter": str(loc.get("chapter", "")),
		"broken": false,
	}


## 현재 GameState 로 세이브 Dictionary 를 만든다 (save.schema.json 형식)
func build_save(slot: int) -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"slot": slot,
		"saved_at": Time.get_datetime_string_from_system(true) + "Z",
		"game_version": str(ProjectSettings.get_setting("application/config/version", "0.0.0")),
		"playtime_sec": int(GameState.playtime_sec),
		"location": GameState.to_save_location(),
		"state": GameState.to_save_state(),
	}


## 검사 후 GameState 에 적용한다
func apply_save(data: Dictionary) -> Error:
	var migrated := _migrate_save(data)
	if migrated.is_empty():
		return ERR_FILE_UNRECOGNIZED
	var problems := validate_save(migrated)
	if not problems.is_empty():
		for p in problems:
			push_error("SaveService: 세이브 오류 — %s" % p)
		return ERR_INVALID_DATA
	GameState.apply_save(migrated["location"], migrated["state"], float(migrated.get("playtime_sec", 0)))
	return OK


## 최소 구조 검사 (전체 스키마 검사는 tools/validate_data.py 가 한다)
func validate_save(data: Dictionary) -> PackedStringArray:
	var problems := PackedStringArray()
	for key: String in ["schema_version", "slot", "location", "state"]:
		if not data.has(key):
			problems.append("필수 키 없음: %s" % key)
	if not problems.is_empty():
		return problems
	var loc: Variant = data["location"]
	var state: Variant = data["state"]
	if not loc is Dictionary or not state is Dictionary:
		problems.append("location/state 는 객체여야 한다")
		return problems
	var state_dict := state as Dictionary
	for key: String in ["vars", "flags", "echoes_collected", "reunited_families", "garden"]:
		if not state_dict.has(key):
			problems.append("state.%s 없음" % key)
	if not GameState.CHARACTERS.has(str((loc as Dictionary).get("active_character", ""))):
		problems.append("location.active_character 가 haneul/byeol 이 아님")
	if not GameState.CHAPTERS.has(str((loc as Dictionary).get("chapter", ""))):
		problems.append("location.chapter 값 오류")
	return problems


func _migrate_save(data: Dictionary) -> Dictionary:
	var version := int(data.get("schema_version", 0))
	if version > SCHEMA_VERSION:
		push_error("SaveService: 더 새로운 버전의 세이브 (v%d > v%d)" % [version, SCHEMA_VERSION])
		return {}
	if version < 1:
		push_error("SaveService: schema_version 없음 또는 잘못됨")
		return {}
	# 버전이 올라가면 여기에 v1 → v2 변환을 추가한다
	return data


# ---------------------------------------------------------------- 공유 기록

func load_persist() -> void:
	_persist = {"schema_version": PERSIST_SCHEMA_VERSION, "seen_endings": [], "clear_count": 0}
	var path := persist_path()
	if not FileAccess.file_exists(path):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("SaveService: persist.json 파싱 실패 — 새로 시작")
		return
	var data := parsed as Dictionary
	if int(data.get("schema_version", 0)) > PERSIST_SCHEMA_VERSION:
		push_error("SaveService: 더 새로운 버전의 persist.json — 읽지 않음")
		return
	var seen: Array[String] = []
	for e: Variant in data.get("seen_endings", []):
		if EndingRules.ALL.has(str(e)) and not seen.has(str(e)):
			seen.append(str(e))
	_persist["seen_endings"] = seen
	_persist["clear_count"] = maxi(0, int(data.get("clear_count", 0)))
	if data.has("first_clear_at"):
		_persist["first_clear_at"] = str(data["first_clear_at"])


func seen_endings() -> Array[String]:
	var result: Array[String] = []
	result.assign(_persist.get("seen_endings", []))
	return result


func clear_count() -> int:
	return int(_persist.get("clear_count", 0))


func record_ending(ending_id: String) -> Error:
	if not EndingRules.ALL.has(ending_id):
		push_error("SaveService: 알 수 없는 엔딩 '%s'" % ending_id)
		return ERR_INVALID_PARAMETER
	var seen := seen_endings()
	if not seen.has(ending_id):
		seen.append(ending_id)
	_persist["seen_endings"] = seen
	_persist["clear_count"] = clear_count() + 1
	if not _persist.has("first_clear_at"):
		_persist["first_clear_at"] = Time.get_datetime_string_from_system(true) + "Z"
	return _write_json(persist_path(), _persist)


## 테스트용: 공유 기록 초기화 (파일은 지우지 않음)
func reset_persist_in_memory() -> void:
	_persist = {"schema_version": PERSIST_SCHEMA_VERSION, "seen_endings": [], "clear_count": 0}


# ---------------------------------------------------------------- 내부

func _write_json(path: String, data: Dictionary) -> Error:
	var dir_err := DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if dir_err != OK and dir_err != ERR_ALREADY_EXISTS:
		return dir_err
	var tmp := path + ".tmp"
	var file := FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		push_error("SaveService: 쓰기 실패 %s (%s)" % [tmp, error_string(FileAccess.get_open_error())])
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data, "\t") + "\n")
	file.close()
	if FileAccess.file_exists(path):
		var rm := DirAccess.remove_absolute(path)
		if rm != OK:
			return rm
	return DirAccess.rename_absolute(tmp, path)
