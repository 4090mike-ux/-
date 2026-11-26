extends GdUnitTestSuite
## WP-09 EchoBus 시그널 계약. 시그널을 추가·변경하면 이 표도 함께 바꾼다.

const CONTRACT := {
	"echo_sensed": 2,
	"echo_collected": 2,
	"color_restored": 3,
	"resonance_triggered": 1,
	"character_switched": 1,
	"stat_changed": 2,
	"flag_changed": 2,
	"truth_revealed": 0,
	"event_triggered": 1,
	"ending_reached": 1,
	"scene_changed": 1,
	"dialogue_started": 1,
	"dialogue_finished": 1,
	"game_saved": 1,
	"game_loaded": 1,
}


func _own_signals() -> Dictionary:
	var base := {}
	for sig: Dictionary in ClassDB.class_get_signal_list("Node"):
		base[sig["name"]] = true
	var result := {}
	for sig: Dictionary in EchoBus.get_signal_list():
		if not base.has(sig["name"]):
			result[sig["name"]] = (sig["args"] as Array).size()
	return result


func test_signals_match_contract() -> void:
	assert_dict(_own_signals()).is_equal(CONTRACT)


func test_signal_names_are_past_tense() -> void:
	for name: String in _own_signals():
		assert_bool(name.ends_with("ed")).override_failure_message("과거형이 아님: %s" % name).is_true()
