extends GdUnitTestSuite
## canon_v1 §10 엔딩 규칙. tools/branch_sim.py 가 만든 픽스처로 파이썬 구현과 교차 검증한다.

const FIXTURE := "res://tests/fixtures/ending_cases.json"


func test_matches_branch_sim_fixture() -> void:
	var data: Dictionary = GameData.read_json(FIXTURE)
	var cases: Array = data["cases"]
	assert_int(cases.size()).is_greater(100)
	var mismatches: Array[String] = []
	for c: Dictionary in cases:
		var state: Dictionary = c["state"]
		var got := EndingRules.explain(state)
		if got["ending"] != c["ending"] or int(got["rule"]) != int(c["rule"]):
			mismatches.append("%s → %s(규칙 %d), 기대 %s(규칙 %d)" % [
				JSON.stringify(state), got["ending"], int(got["rule"]), c["ending"], int(c["rule"])])
	assert_array(mismatches).override_failure_message("\n".join(PackedStringArray(mismatches.slice(0, 5)))).is_empty()


func test_balanced_without_full_bond_falls_back_to_protect() -> void:
	# canon §10-2 빈틈 1: 균형인데 bond 3 → 폴백
	var state := {"protect": 10, "heal": 10, "bond": 3, "families_reunited": 6}
	assert_dict(EndingRules.explain(state)).is_equal({"ending": "protect", "rule": 6})


func test_heal_lean_without_reunions_falls_back_to_protect() -> void:
	# canon §10-2 빈틈 2
	var state := {"protect": 2, "heal": 9, "bond": 4, "families_reunited": 1}
	assert_dict(EndingRules.explain(state)).is_equal({"ending": "protect", "rule": 6})


func test_sacrifice_needs_previous_family_or_miracle() -> void:
	var state := {"protect": 5, "heal": 5, "bond": 4, "families_reunited": 3, "echo_found": 30,
		"hidden_echo_found": 12, "rainbow_flower": true, "offered_color": true, "seen_endings": []}
	assert_str(EndingRules.evaluate(state)).is_equal("miracle")
	state["seen_endings"] = ["family"]
	assert_str(EndingRules.evaluate(state)).is_equal("sacrifice")
	assert_str(EndingRules.sacrificer(state)).is_equal("haneul")
	state["heal"] = 7
	assert_str(EndingRules.sacrificer(state)).is_equal("byeol")
