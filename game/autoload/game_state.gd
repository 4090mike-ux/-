extends Node
## 게임 진행 상태의 단일 원천 (오토로드 "GameState").
##
## 계약: docs/schemas/dialogue_conventions.md §5, game/data/flags.json, canon_v1 §9~10.
## - 대사와 다른 시스템은 이 API로만 상태를 바꾼다. 직접 대입(GameState.protect = 3)은 오류를 낸다.
## - 바뀐 내용은 EchoBus 시그널로 알린다.
## - 계산값(families_reunited, echo_found, hidden_echo_found)은 저장하지 않고 목록에서 계산한다.

const CHARACTERS: Array[String] = ["haneul", "byeol"]
const CHAPTERS: Array[String] = ["prologue", "ch1", "ch2", "ch3", "ch4", "ch5", "endings"]
const TRUTH_FLAG := "flag.ch4.truth_revealed"
const RAINBOW_FLAG := "flag.ch5.rainbow_flower_bloomed"
const OFFERED_FLAG := "flag.ch5.offered_color"
const ENDING_FLAG := "flag.endings.reached"
const MAX_BOND := 4
const MAX_FAMILIES := 6
const BALANCE_THRESHOLD := 2

var _ECHO_ID := RegEx.create_from_string("^echo\\.(prologue|ch[1-5])\\.[a-z][a-z0-9_]*$")
var _FAMILY_ID := RegEx.create_from_string("^family_[a-z0-9_]+$")
var _CHOICE_ID := RegEx.create_from_string("^[a-z0-9_]+$")
var _EVENT_ID := RegEx.create_from_string("^ev_[a-z0-9_]+$")

## 하늘 성향 (증가만, add_protect)
var protect: int:
	get:
		return _protect
	set(_value):
		push_error("GameState.protect 는 직접 바꿀 수 없다. add_protect(n) 을 쓴다")

## 별 성향 (증가만, add_heal)
var heal: int:
	get:
		return _heal
	set(_value):
		push_error("GameState.heal 은 직접 바꿀 수 없다. add_heal(n) 을 쓴다")

## 관계 복원 단계 0~4 (raise_bond, 스토리 이벤트 전용)
var bond: int:
	get:
		return _bond
	set(_value):
		push_error("GameState.bond 는 직접 바꿀 수 없다. raise_bond(level) 을 쓴다")

## 계산값: 재결합한 사이드 가족 수
var families_reunited: int:
	get:
		return _reunited.size()
	set(_value):
		push_error("families_reunited 는 계산값이다. reunite_family(id) 를 쓴다")

## 계산값: 모은 잔향 수
var echo_found: int:
	get:
		return _echoes.size()
	set(_value):
		push_error("echo_found 는 계산값이다. collect_echo(id) 를 쓴다")

## 계산값: 모은 숨김 잔향 수 (game/data/echoes 의 kind == hidden)
var hidden_echo_found: int:
	get:
		var count := 0
		for id in _echoes:
			if str(GameData.echo_def(id).get("kind", "")) == "hidden":
				count += 1
		return count
	set(_value):
		push_error("hidden_echo_found 는 계산값이다")

## 계산값: 모은 공명 잔향 수 (sensed_by == both). bond 4 조건에 쓴다 (docs/gdd/endings.md §4)
var shared_echo_found: int:
	get:
		var count := 0
		for id in _echoes:
			if str(GameData.echo_def(id).get("sensed_by", "")) == "both":
				count += 1
		return count
	set(_value):
		push_error("shared_echo_found 는 계산값이다")

var active_character: String = "haneul"
var chapter: String = "prologue"
var scene_path: String = ""
var spawn: String = ""
var playtime_sec: float = 0.0
## false 면 플레이 시간을 세지 않는다 (타이틀 화면 등)
var count_playtime: bool = true

var _protect := 0
var _heal := 0
var _bond := 0
var _flags: Dictionary = {}          # 기본값과 다른 플래그만
var _echoes: Array[String] = []
var _reunited: Array[String] = []
var _choices: Array[String] = []
var _garden: Dictionary = {"plots": [], "bloomed": []}


func _process(delta: float) -> void:
	if count_playtime and not get_tree().paused:
		playtime_sec += delta


## 새 게임
func reset() -> void:
	_protect = 0
	_heal = 0
	_bond = 0
	_flags.clear()
	_echoes.clear()
	_reunited.clear()
	_choices.clear()
	_garden = {"plots": [], "bloomed": []}
	active_character = "haneul"
	chapter = "prologue"
	scene_path = ""
	spawn = ""
	playtime_sec = 0.0


# ---------------------------------------------------------------- 성향·관계

func add_protect(amount: int) -> void:
	if not _valid_tendency_amount(amount):
		return
	_protect += amount
	EchoBus.stat_changed.emit("protect", _protect)


func add_heal(amount: int) -> void:
	if not _valid_tendency_amount(amount):
		return
	_heal += amount
	EchoBus.stat_changed.emit("heal", _heal)


## 관계 단계를 level 까지 올린다. 이미 높으면 아무것도 하지 않는다 (내려가지 않음).
func raise_bond(level: int) -> void:
	var target := clampi(level, 0, MAX_BOND)
	if target <= _bond:
		return
	_bond = target
	EchoBus.stat_changed.emit("bond", _bond)


## 사이드 가족 재결합. 같은 가족을 두 번 세지 않는다.
func reunite_family(family_id: String) -> void:
	if _FAMILY_ID.search(family_id) == null:
		push_error("GameState: 가족 id 형식 오류 '%s' (family_<영문>)" % family_id)
		return
	if _reunited.has(family_id):
		return
	if _reunited.size() >= MAX_FAMILIES:
		push_error("GameState: 사이드 가족은 최대 %d" % MAX_FAMILIES)
		return
	_reunited.append(family_id)
	EchoBus.stat_changed.emit("families_reunited", _reunited.size())


func has_reunited(family_id: String) -> bool:
	return _reunited.has(family_id)


## 성향 선택지 기록 ([#choice=id]). 대사 UI 가 응답을 고를 때 호출한다.
func record_choice(choice_id: String) -> void:
	if _CHOICE_ID.search(choice_id) == null:
		push_error("GameState: choice id 형식 오류 '%s'" % choice_id)
		return
	if not _choices.has(choice_id):
		_choices.append(choice_id)


func has_chosen(choice_id: String) -> bool:
	return _choices.has(choice_id)


## "protect" / "heal" / "balanced" (차이 2 이하). 정원 꽃 비율·대사 변형용.
func lean() -> String:
	var diff := _protect - _heal
	if absi(diff) <= BALANCE_THRESHOLD:
		return "balanced"
	return "protect" if diff > 0 else "heal"


# ---------------------------------------------------------------- 플래그

## 플래그 값. 등록되지 않은 id 는 오류 + null.
func flag(flag_id: String) -> Variant:
	var def := GameData.flag_def(flag_id)
	if def.is_empty():
		push_error("GameState: 등록되지 않은 플래그 '%s' (game/data/flags.json)" % flag_id)
		return null
	return _flags.get(flag_id, def["default"])


func set_flag(flag_id: String, value: Variant) -> void:
	var def := GameData.flag_def(flag_id)
	if def.is_empty():
		push_error("GameState: 등록되지 않은 플래그 '%s' (game/data/flags.json)" % flag_id)
		return
	if not _valid_flag_value(def, value):
		push_error("GameState: 플래그 '%s' 에 맞지 않는 값 %s" % [flag_id, str(value)])
		return
	var before: Variant = flag(flag_id)
	if value == def["default"]:
		_flags.erase(flag_id)
	else:
		_flags[flag_id] = value
	if before == value:
		return
	EchoBus.flag_changed.emit(flag_id, value)
	if flag_id == TRUTH_FLAG and value == true:
		EchoBus.truth_revealed.emit()


func is_truth_revealed() -> bool:
	return flag(TRUTH_FLAG) == true


# ---------------------------------------------------------------- 잔향·이벤트

## 잔향 획득. 새로 얻었으면 true.
func collect_echo(echo_id: String) -> bool:
	if _ECHO_ID.search(echo_id) == null:
		push_error("GameState: 잔향 id 형식 오류 '%s'" % echo_id)
		return false
	if _echoes.has(echo_id):
		return false
	_echoes.append(echo_id)
	EchoBus.echo_collected.emit(echo_id, str(GameData.echo_def(echo_id).get("emotion", "")))
	return true


func has_echo(echo_id: String) -> bool:
	return _echoes.has(echo_id)


## 이벤트 시작 신호. 컷신·플래그 처리는 이벤트를 받는 쪽 책임.
func trigger(event_id: String) -> void:
	if _EVENT_ID.search(event_id) == null:
		push_error("GameState: 이벤트 id 형식 오류 '%s' (ev_<영문>)" % event_id)
		return
	EchoBus.event_triggered.emit(event_id)


# ---------------------------------------------------------------- 남매·표시

func switch_character(character_key: String) -> void:
	if not CHARACTERS.has(character_key):
		push_error("GameState: 알 수 없는 캐릭터 '%s'" % character_key)
		return
	if active_character == character_key:
		return
	active_character = character_key
	EchoBus.character_switched.emit(character_key)


## R-NAME 이 적용된 표시 이름. 진실 공개 전에는 name_key, 후에는 truth_name_key.
func name_display(speaker_key: String) -> String:
	var entry := GameData.speaker(speaker_key)
	if entry.is_empty():
		push_error("GameState: 등록되지 않은 화자 '%s' (game/data/speakers.json)" % speaker_key)
		return speaker_key
	var key := str(entry.get("name_key", speaker_key))
	if is_truth_revealed() and entry.has("truth_name_key"):
		key = str(entry["truth_name_key"])
	return tr(key)


# ---------------------------------------------------------------- 정원 (WP-20 이 내용을 관리)

func garden_state() -> Dictionary:
	return _garden.duplicate(true)


func set_garden_state(garden: Dictionary) -> void:
	_garden = {
		"plots": (garden.get("plots", []) as Array).duplicate(true),
		"bloomed": (garden.get("bloomed", []) as Array).duplicate(true),
	}


# ---------------------------------------------------------------- 엔딩

## EndingRules 입력 형태로 현재 상태를 만든다
func ending_state(seen_endings: Array[String]) -> Dictionary:
	return {
		"protect": _protect,
		"heal": _heal,
		"bond": _bond,
		"families_reunited": families_reunited,
		"echo_found": echo_found,
		"hidden_echo_found": hidden_echo_found,
		"rainbow_flower": flag(RAINBOW_FLAG) == true,
		"offered_color": flag(OFFERED_FLAG) == true,
		"seen_endings": seen_endings.duplicate(),
	}


## 숨은 선택지 "내 색을 바친다"를 보여 줄지
func can_offer_color() -> bool:
	return EndingRules.sacrifice_choice_available(ending_state(SaveService.seen_endings()))


## 챕터 5 최종 대화가 끝났을 때 호출: 엔딩을 정하고 기록한다
func reach_ending() -> String:
	var ending := EndingRules.evaluate(ending_state(SaveService.seen_endings()))
	set_flag(ENDING_FLAG, ending)
	SaveService.record_ending(ending)
	EchoBus.ending_reached.emit(ending)
	return ending


# ---------------------------------------------------------------- 세이브 연동 (SaveService 전용)

func to_save_state() -> Dictionary:
	return {
		"vars": {"protect": _protect, "heal": _heal, "bond": _bond},
		"flags": _flags.duplicate(true),
		"echoes_collected": _echoes.duplicate(),
		"reunited_families": _reunited.duplicate(),
		"choices_made": _choices.duplicate(),
		"garden": garden_state(),
	}


func to_save_location() -> Dictionary:
	var loc := {"chapter": chapter, "scene": scene_path, "active_character": active_character}
	if not spawn.is_empty():
		loc["spawn"] = spawn
	return loc


## 검증은 SaveService 가 먼저 한다. 여기서는 그대로 적용한다.
func apply_save(location: Dictionary, state: Dictionary, playtime: float) -> void:
	reset()
	var vars: Dictionary = state.get("vars", {})
	_protect = maxi(0, int(vars.get("protect", 0)))
	_heal = maxi(0, int(vars.get("heal", 0)))
	_bond = clampi(int(vars.get("bond", 0)), 0, MAX_BOND)
	var flags: Dictionary = state.get("flags", {})
	for id: String in flags:
		var def := GameData.flag_def(id)
		if def.is_empty():
			push_warning("GameState: 세이브의 알 수 없는 플래그 '%s' 무시" % id)
			continue
		var value: Variant = flags[id]
		if str(def["type"]) == "int":
			value = int(value)  # JSON 숫자는 float 로 읽힌다
		_flags[id] = value
	_echoes.assign(state.get("echoes_collected", []))
	_reunited.assign(state.get("reunited_families", []))
	_choices.assign(state.get("choices_made", []))
	set_garden_state(state.get("garden", {}))
	chapter = str(location.get("chapter", "prologue"))
	scene_path = str(location.get("scene", ""))
	spawn = str(location.get("spawn", ""))
	active_character = str(location.get("active_character", "haneul"))
	playtime_sec = playtime


# ---------------------------------------------------------------- 내부

func _valid_tendency_amount(amount: int) -> bool:
	if amount == 1 or amount == 2:
		return true
	push_error("GameState: 성향 증가량은 1 또는 2 (canon D9). 받은 값: %d" % amount)
	return false


func _valid_flag_value(def: Dictionary, value: Variant) -> bool:
	match str(def["type"]):
		"bool":
			return typeof(value) == TYPE_BOOL
		"int":
			return typeof(value) == TYPE_INT
		"enum":
			return typeof(value) == TYPE_STRING and (def.get("values", []) as Array).has(value)
	return false
