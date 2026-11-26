class_name Settings
extends RefCounted
## 사용자 설정 user://settings.cfg (키 이름: docs/gdd/controls_accessibility.md §5).
## 지금 효과가 있는 항목: 글자 속도, 감지 방식(누르기/토글), 퍼즐 타이머, 리듀스 모션(저장만), 화면 배율.

const PATH := "user://settings.cfg"
## 테스트에서 바꿀 수 있다
static var path_override: String = ""

## 키 → [선택지..., 기본값 인덱스]
const OPTIONS := {
	"text/speed": [["slow", "normal", "fast", "instant"], 1],
	"accessibility/echo_sense_mode": [["hold", "toggle"], 0],
	"accessibility/puzzle_timer": [["soft", "off"], 0],
	"accessibility/reduced_motion": [[false, true], 0],
	"accessibility/rumble": [[true, false], 0],
	"display/scale": [[2, 3, 4, 5, 6], 1],
}
const LABELS := {
	"text/speed": "글자 속도", "accessibility/echo_sense_mode": "감지 방식", "accessibility/puzzle_timer": "퍼즐 자동 힌트",
	"accessibility/reduced_motion": "움직임 줄이기", "accessibility/rumble": "진동", "display/scale": "화면 배율",
}
const VALUE_LABELS := {
	"slow": "느림", "normal": "보통", "fast": "빠름", "instant": "즉시", "hold": "누르고 있기", "toggle": "눌러서 켜고 끄기",
	"soft": "켜기", "off": "끄기",
}
## 글자당 초 (15/30/60 글자/초, 즉시)
const TEXT_SPEED_SEC := {"slow": 1.0 / 15.0, "normal": 1.0 / 30.0, "fast": 1.0 / 60.0, "instant": 0.0}

static var _cfg: ConfigFile = null


static func _file() -> String:
	return path_override if not path_override.is_empty() else PATH


static func _config() -> ConfigFile:
	if _cfg == null:
		_cfg = ConfigFile.new()
		_cfg.load(_file())  # 없으면 빈 설정
	return _cfg


static func get_value(key: String) -> Variant:
	var spec: Array = OPTIONS[key]
	var choices: Array = spec[0]
	var value: Variant = _config().get_value(key.get_slice("/", 0), key.get_slice("/", 1), choices[int(spec[1])])
	return value if choices.has(value) else choices[int(spec[1])]


static func set_value(key: String, value: Variant) -> void:
	_config().set_value(key.get_slice("/", 0), key.get_slice("/", 1), value)
	_config().save(_file())
	apply()


## 선택지를 한 칸 옮긴다 (메뉴용)
static func cycle(key: String, step: int) -> void:
	var choices: Array = (OPTIONS[key] as Array)[0]
	var i := choices.find(get_value(key))
	set_value(key, choices[wrapi(i + step, 0, choices.size())])


static func label_of(key: String) -> String:
	var v: Variant = get_value(key)
	if v is bool:
		return "켜기" if v else "끄기"
	if v is int:
		return "%d배" % int(v)
	return str(VALUE_LABELS.get(str(v), str(v)))


static func text_seconds_per_char() -> float:
	return float(TEXT_SPEED_SEC[str(get_value("text/speed"))])


static func echo_sense_toggle() -> bool:
	return get_value("accessibility/echo_sense_mode") == "toggle"


static func puzzle_auto_hint() -> bool:
	return get_value("accessibility/puzzle_timer") == "soft"


## 화면 배율 등 즉시 적용할 것
static func apply() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var scale := int(get_value("display/scale"))
	var base := Vector2i(480, 270)
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_size(base * scale)


static func reset_cache() -> void:
	_cfg = null
