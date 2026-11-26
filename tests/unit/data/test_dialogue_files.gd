extends GdUnitTestSuite
## 모든 .dialogue 파일이 Dialogue Manager 로 컴파일되고, 장면 정의가 쓰는 cue 가 실제로 있는가.

const ROOT := "res://game/dialogue"


func _dialogue_files(dir_path: String, out: Array[String]) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	for sub in dir.get_directories():
		_dialogue_files(dir_path.path_join(sub), out)
	for file in dir.get_files():
		if file.get_extension() == "dialogue":
			out.append(dir_path.path_join(file))


func test_all_dialogue_files_compile() -> void:
	var files: Array[String] = []
	_dialogue_files(ROOT, files)
	assert_int(files.size()).is_greater(0)
	var problems: Array[String] = []
	for path in files:
		var result: DMCompilerResult = DMCompiler.compile_string(FileAccess.get_file_as_string(path), path)
		for e: DMError in result.errors:
			problems.append("%s:%d %s" % [path, e.line_number + 1, DMConstants.get_error_message(e.error)])
		if not result.cues.has("start"):
			problems.append("%s: '~ start' 없음" % path)
	assert_array(problems).override_failure_message("\n".join(PackedStringArray(problems.slice(0, 10)))).is_empty()
