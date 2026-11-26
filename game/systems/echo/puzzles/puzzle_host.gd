class_name PuzzleHost
extends Node
## 잔향 정의의 puzzle.type 에 맞는 퍼즐을 열고 결과를 돌려준다.
## 퍼즐 내용: game/data/puzzles/<slug>.json (docs/schemas/puzzle.schema.json). type == "none" 이면 바로 성공.

signal finished(echo_id: String, solved: bool, skipped: bool)

const PUZZLE_DIR := "res://game/data/puzzles"

var active: EchoPuzzle = null
## 테스트에서 끈다
var pause_tree: bool = true


static func slug_of(echo_id: String) -> String:
	return echo_id.get_slice(".", 2)


static func puzzle_data(echo_id: String) -> Dictionary:
	var path := "%s/%s.json" % [PUZZLE_DIR, slug_of(echo_id)]
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = GameData.read_json(path)
	return parsed as Dictionary if parsed is Dictionary else {}


## 퍼즐을 연다. 끝나면 finished(echo_id, solved, skipped). await 하면 [solved, skipped] 를 돌려준다.
func run(echo_id: String, puzzle_type: String) -> Array:
	var data := puzzle_data(echo_id)
	if puzzle_type == "none" or data.is_empty():
		if puzzle_type != "none":
			push_warning("PuzzleHost: %s 퍼즐 데이터 없음 — 바로 성공 처리" % echo_id)
		finished.emit(echo_id, true, false)
		return [true, false]
	active = ColorMatchPuzzle.new() if puzzle_type == "color_match" else MemoryOrderPuzzle.new()
	active.pause_tree = pause_tree
	add_child(active)
	active.open(echo_id, data)
	var outcome: Array = await _wait(active)
	active.queue_free()
	active = null
	finished.emit(echo_id, bool(outcome[0]), bool(outcome[1]))
	return outcome


func _wait(puzzle: EchoPuzzle) -> Array:
	var result: Array = []
	var on_solved := func(_id: String) -> void: result.assign([true, puzzle.was_skipped])
	var on_cancel := func(_id: String) -> void: result.assign([false, false])
	puzzle.solved.connect(on_solved, CONNECT_ONE_SHOT)
	puzzle.cancelled.connect(on_cancel, CONNECT_ONE_SHOT)
	while result.is_empty():
		await get_tree().process_frame
	return result
