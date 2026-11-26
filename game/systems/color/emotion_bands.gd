class_name EmotionBands
extends RefCounted
## 감정 색 정의(game/data/emotions.json)를 읽어 색 복원 셰이더 uniform 으로 바꾼다.
##
## 숫자(Hue 중심·반폭)는 emotions.json 에만 둔다. 셰이더나 다른 스크립트에 하드코딩하지 않는다.

const DATA_PATH := "res://game/data/emotions.json"
const MAX_BANDS := 8
const EMOTION_IDS: Array[String] = ["longing", "warmth", "dream", "courage", "healing"]

static var _cache: Dictionary = {}


## id → 감정 정의(Dictionary). 파일은 처음 한 번만 읽는다.
static func load_emotions() -> Dictionary:
	if not _cache.is_empty():
		return _cache
	var text := FileAccess.get_file_as_string(DATA_PATH)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("EmotionBands: %s 파싱 실패" % DATA_PATH)
		return {}
	var result: Dictionary = {}
	var list: Array = (parsed as Dictionary).get("emotions", [])
	for entry: Dictionary in list:
		result[entry["id"]] = entry
	_cache = result
	return result


## 셰이더용 대역 벡터: x=중심 Hue, y=반폭, z=부드러움 (모두 0~1), w=세기
static func band_for(emotion_id: String, strength: float = 1.0) -> Vector4:
	var entry: Dictionary = load_emotions().get(emotion_id, {})
	if entry.is_empty():
		push_error("EmotionBands: 알 수 없는 감정 id '%s'" % emotion_id)
		return Vector4.ZERO
	var band: Dictionary = entry["hue_band"]
	return Vector4(
		float(band["center_deg"]) / 360.0,
		float(band["half_width_deg"]) / 360.0,
		float(band["softness_deg"]) / 360.0,
		clampf(strength, 0.0, 1.0)
	)


## 대표 색(ramp 의 mid = 인덱스 1)
static func main_color(emotion_id: String) -> Color:
	var entry: Dictionary = load_emotions().get(emotion_id, {})
	if entry.is_empty():
		return Color.MAGENTA
	var ramp_hex: Array = entry["ramp"]
	return Color.html(str(ramp_hex[1]))


## 감정 ramp 4색 (dark, mid, light, highlight)
static func ramp(emotion_id: String) -> PackedColorArray:
	var colors := PackedColorArray()
	var entry: Dictionary = load_emotions().get(emotion_id, {})
	for hex: Variant in entry.get("ramp", []):
		colors.append(Color.html(str(hex)))
	return colors


## 머티리얼에 활성 감정 대역을 적용한다. 빈 배열이면 band_count=0 (마스크 영역의 모든 색 복원).
static func apply(material: ShaderMaterial, emotion_ids: Array[String]) -> void:
	var bands := PackedVector4Array()
	for id in emotion_ids:
		if bands.size() >= MAX_BANDS:
			push_warning("EmotionBands: 대역은 최대 %d개" % MAX_BANDS)
			break
		bands.append(band_for(id))
	var count := bands.size()
	bands.resize(MAX_BANDS)
	material.set_shader_parameter("bands", bands)
	material.set_shader_parameter("band_count", count)
