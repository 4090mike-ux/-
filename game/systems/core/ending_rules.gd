class_name EndingRules
extends RefCounted
## 엔딩 평가 규칙 (canon_v1 §10). 순수 함수만 둔다.
##
## tools/branch_sim.py 에 같은 규칙의 파이썬 구현이 있다. 두 구현은
## tests/fixtures/ending_cases.json (branch_sim.py --write-fixture 로 생성) 으로 교차 검증한다.
## 규칙을 바꾸면 canon → branch_sim.py → 이 파일 → 픽스처 순서로 함께 바꾼다.
##
## 입력 state 키: protect, heal, bond, families_reunited, echo_found, hidden_echo_found,
##               rainbow_flower(bool), offered_color(bool), seen_endings(Array)

const SACRIFICE := "sacrifice"
const MIRACLE := "miracle"
const FAMILY := "family"
const HEAL := "heal"
const PROTECT := "protect"
const ALL: Array[String] = [SACRIFICE, MIRACLE, FAMILY, HEAL, PROTECT]

const BALANCE_THRESHOLD := 2
const LEAN_THRESHOLD := 3
const MAX_BOND := 4
const FAMILY_MIN_REUNITED := 3
const HEAL_MIN_REUNITED := 2
const TOTAL_ECHOES := 30
const HIDDEN_ECHOES := 12


static func evaluate(state: Dictionary) -> String:
	return explain(state)["ending"]


## {ending, rule} — rule 은 몇 번째 규칙으로 정해졌는지 (6 = 폴백)
static func explain(state: Dictionary) -> Dictionary:
	var diff := int(state.get("protect", 0)) - int(state.get("heal", 0))
	var families := int(state.get("families_reunited", 0))
	if sacrifice_choice_available(state) and bool(state.get("offered_color", false)):
		return {"ending": SACRIFICE, "rule": 1}
	var family_ok := is_family_condition(state)
	if family_ok and int(state.get("hidden_echo_found", 0)) == HIDDEN_ECHOES and bool(state.get("rainbow_flower", false)):
		return {"ending": MIRACLE, "rule": 2}
	if family_ok:
		return {"ending": FAMILY, "rule": 3}
	if -diff >= LEAN_THRESHOLD and families >= HEAL_MIN_REUNITED:
		return {"ending": HEAL, "rule": 4}
	if diff >= LEAN_THRESHOLD:
		return {"ending": PROTECT, "rule": 5}
	return {"ending": PROTECT, "rule": 6}  # 폴백 (canon D7)


static func is_family_condition(state: Dictionary) -> bool:
	var diff := int(state.get("protect", 0)) - int(state.get("heal", 0))
	return (
		absi(diff) <= BALANCE_THRESHOLD
		and int(state.get("bond", 0)) == MAX_BOND
		and int(state.get("families_reunited", 0)) >= FAMILY_MIN_REUNITED
	)


## 최종 대화에서 숨은 선택지 "내 색을 바친다"를 보여 줄지
static func sacrifice_choice_available(state: Dictionary) -> bool:
	var seen: Array = state.get("seen_endings", [])
	return (seen.has(FAMILY) or seen.has(MIRACLE)) and int(state.get("echo_found", 0)) == TOTAL_ECHOES


## 희생 엔딩에서 색을 바치는 사람: protect 가 크거나 같으면 하늘, heal 이 크면 별 (canon §10-1)
static func sacrificer(state: Dictionary) -> String:
	return "haneul" if int(state.get("protect", 0)) >= int(state.get("heal", 0)) else "byeol"
