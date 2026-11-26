class_name GardenModel
extends RefCounted
## 색의 정원 규칙 (WP-20, docs/gdd/garden.md). 상태는 GameState.garden_state() 에 있고, 규칙은 game/data/garden.json.
##
## - 주머니는 저장하지 않는다: (모은 잔향의 색 조각) − (자기 줄에 심긴 칸).
## - 각자 자기 줄에만 심는다(01~05 하늘, 06~10 별). 다시 심기는 공짜(조각이 주머니로 돌아옴).
## - 성장: 방문 마무리 틱 +1(틱 장면에서만), 공명 잔향 수집 시 같은 감정 칸 +1. 최대 5.
## - 짝 칸(같은 col)의 두 감정이 조합표에 있고 둘 다 3 이상이면 조합 꽃(영구 기록).

const DATA_PATH := "res://game/data/garden.json"
const EMOTIONS: Array[String] = ["longing", "warmth", "dream", "courage", "healing"]

static var _rules: Dictionary = {}


static func rules() -> Dictionary:
	if _rules.is_empty():
		var data: Variant = GameData.read_json(DATA_PATH)
		if data is Dictionary:
			_rules = data
	return _rules


static func plot_ids(owner: String = "") -> Array[String]:
	var ids: Array[String] = []
	for p: Dictionary in rules().get("plots", []):
		if owner.is_empty() or str(p["owner"]) == owner:
			ids.append(str(p["id"]))
	return ids


static func owner_of(plot_id: String) -> String:
	for p: Dictionary in rules().get("plots", []):
		if str(p["id"]) == plot_id:
			return str(p["owner"])
	return ""


static func col_of(plot_id: String) -> int:
	for p: Dictionary in rules().get("plots", []):
		if str(p["id"]) == plot_id:
			return int(p["col"])
	return 0


## 심긴 칸: plot_id → {id, planted_by, emotion, growth, resonance_bonus?}
static func planted() -> Dictionary:
	var result := {}
	for p: Variant in GameState.garden_state().get("plots", []):
		var d: Dictionary = p
		result[str(d["id"])] = d
	return result


static func bloomed() -> Array[String]:
	var result: Array[String] = []
	result.assign(GameState.garden_state().get("bloomed", []))
	return result


## 받은 색 조각: owner → {emotion: count}
static func shards_received(owner: String) -> Dictionary:
	var counts := {}
	for e in EMOTIONS:
		counts[e] = 0
	for id: String in GameState.to_save_state()["echoes_collected"]:
		var def := GameData.echo_def(id)
		if def.is_empty():
			continue
		var n := int((def.get("reward", {}) as Dictionary).get("color_shards", 1))
		var who := str(def.get("sensed_by", ""))
		var emotion := str(def.get("emotion", ""))
		if not counts.has(emotion):
			continue
		if who == "both":
			counts[emotion] = int(counts[emotion]) + n / 2
		elif who == owner:
			counts[emotion] = int(counts[emotion]) + n
	return counts


## 주머니: owner → {emotion: 남은 개수}
static func pocket(owner: String) -> Dictionary:
	var counts := shards_received(owner)
	for d: Dictionary in planted().values():
		if str(d["planted_by"]) == owner and counts.has(str(d["emotion"])):
			counts[str(d["emotion"])] = int(counts[str(d["emotion"])]) - 1
	return counts


## 심기 / 다시 심기. 주인 줄이 아니거나 조각이 없으면 false.
static func plant(plot_id: String, emotion: String, by: String) -> bool:
	if owner_of(plot_id) != by or not EMOTIONS.has(emotion):
		return false
	var existing: Dictionary = planted().get(plot_id, {})
	var available := int(pocket(by).get(emotion, 0))
	if not existing.is_empty() and str(existing["emotion"]) == emotion:
		return false  # 같은 감정으로 다시 심기 = 의미 없음
	if available <= 0:
		return false
	_set_plot(plot_id, {"id": plot_id, "planted_by": by, "emotion": emotion, "growth": 0, "resonance_bonus": 0})
	return true


## 칸 비우기 (조각은 주머니로 돌아온다)
static func clear(plot_id: String) -> void:
	var garden := GameState.garden_state()
	var plots: Array = garden.get("plots", [])
	garden["plots"] = plots.filter(func(p: Dictionary) -> bool: return str(p["id"]) != plot_id)
	GameState.set_garden_state(garden)


## 성장 틱: 심긴 모든 칸 +1
static func tick() -> void:
	_grow(func(_d: Dictionary) -> bool: return true, false)


## 공명: 같은 감정 칸 +1 (공명 잔향 수집 시)
static func resonance(emotion: String) -> void:
	_grow(func(d: Dictionary) -> bool: return str(d["emotion"]) == emotion, true)


## 짝 칸 조합 확인. 새로 핀 조합 id 목록.
static func check_combos() -> Array[String]:
	var growth_min := int((rules().get("growth", {}) as Dictionary).get("combo_min", 3))
	var by_col := {}
	for d: Dictionary in planted().values():
		var col := col_of(str(d["id"]))
		if not by_col.has(col):
			by_col[col] = []
		(by_col[col] as Array).append(d)
	var already := bloomed()
	var fresh: Array[String] = []
	for col: int in by_col:
		var pair: Array = by_col[col]
		if pair.size() != 2:
			continue
		var a: Dictionary = pair[0]
		var b: Dictionary = pair[1]
		if int(a["growth"]) < growth_min or int(b["growth"]) < growth_min:
			continue
		var combo := combo_for(str(a["emotion"]), str(b["emotion"]))
		if not combo.is_empty() and not already.has(combo) and not fresh.has(combo):
			fresh.append(combo)
	if not fresh.is_empty():
		_add_bloomed(fresh)
	return fresh


static func combo_for(a: String, b: String) -> String:
	for c: Dictionary in rules().get("combos", []):
		if (str(c["a"]) == a and str(c["b"]) == b) or (str(c["a"]) == b and str(c["b"]) == a):
			return str(c["id"])
	return ""


## 가족의 꽃 조건: 서로 다른 5감정이 각각 성장 2 이상인 칸을 하나씩
static func family_flower_ready() -> bool:
	var min_growth := int(((rules().get("special", {}) as Dictionary).get("family_flower", {}) as Dictionary).get("min_growth", 2))
	var ok := {}
	for d: Dictionary in planted().values():
		if int(d["growth"]) >= min_growth:
			ok[str(d["emotion"])] = true
	for e in EMOTIONS:
		if not ok.has(e):
			return false
	return true


## 방문 마무리: 틱(틱 장면만) → 특별 꽃 → 조합. 결과 요약을 돌려준다.
static func finish_visit(scene_id: String) -> Dictionary:
	var result := {"ticked": false, "combos": [] as Array[String], "family_flower": false, "rainbow_flower": false}
	var growth: Dictionary = rules().get("growth", {})
	if (growth.get("tick_scenes", []) as Array).has(scene_id):
		tick()
		result["ticked"] = true
	var special: Dictionary = rules().get("special", {})
	var family: Dictionary = special.get("family_flower", {})
	if str(family.get("scene", "")) == scene_id and family_flower_ready() and not bloomed().has("family_flower"):
		_add_bloomed(["family_flower"] as Array[String])
		GameState.set_flag(str(family["flag"]), true)
		result["family_flower"] = true
	var rainbow: Dictionary = special.get("rainbow_flower", {})
	if str(rainbow.get("scene", "")) == scene_id and bloomed().has("family_flower") \
			and GameState.hidden_echo_found >= int(rainbow.get("hidden_echoes", 12)) and not bloomed().has("rainbow_flower"):
		_add_bloomed(["rainbow_flower"] as Array[String])
		GameState.set_flag(str(rainbow["flag"]), true)
		result["rainbow_flower"] = true
	result["combos"] = check_combos()
	return result


## 마음 화단: protect:heal 비율 → 파랑·초록 칸 수 (합이 0이면 둘 다 0 = 무채색)
static func heart_bed() -> Dictionary:
	var cells := int((rules().get("heart_bed", {}) as Dictionary).get("cells", 12))
	var total := GameState.protect + GameState.heal
	if total == 0:
		return {"blue": 0, "green": 0, "gray": cells}
	var blue := int(floor(float(cells) * GameState.protect / total + 0.5))
	return {"blue": blue, "green": cells - blue, "gray": 0}


static func clear_cache() -> void:
	_rules.clear()


# ---------------------------------------------------------------- 내부

static func _set_plot(plot_id: String, plot: Dictionary) -> void:
	var garden := GameState.garden_state()
	var plots: Array = (garden.get("plots", []) as Array).filter(func(p: Dictionary) -> bool: return str(p["id"]) != plot_id)
	plots.append(plot)
	plots.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return str(x["id"]) < str(y["id"]))
	garden["plots"] = plots
	GameState.set_garden_state(garden)


static func _grow(match_fn: Callable, is_resonance: bool) -> void:
	var max_growth := int((rules().get("growth", {}) as Dictionary).get("max", 5))
	var garden := GameState.garden_state()
	for p: Variant in garden.get("plots", []):
		var d: Dictionary = p
		if not bool(match_fn.call(d)) or int(d["growth"]) >= max_growth:
			continue
		d["growth"] = int(d["growth"]) + 1
		if is_resonance:
			d["resonance_bonus"] = int(d.get("resonance_bonus", 0)) + 1
	GameState.set_garden_state(garden)


static func _add_bloomed(ids: Array[String]) -> void:
	var garden := GameState.garden_state()
	var list: Array = garden.get("bloomed", [])
	for id in ids:
		if not list.has(id):
			list.append(id)
	garden["bloomed"] = list
	GameState.set_garden_state(garden)
