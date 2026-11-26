extends SceneTree
## 모든 GDScript·씬을 로드해 파싱 오류(정적 타입 경고 → 오류 포함)를 잡는다.
## 사용: godot --headless --path . -s res://tests/check_scripts.gd
## 먼저 godot --headless --path . --import 로 클래스 캐시(class_name)를 만들어 둔다.
## 테스트 스위트가 아니다(GdUnitTestSuite 를 상속하지 않으므로 gdUnit4 가 건너뛴다).

const ROOTS: Array[String] = ["res://game", "res://tests"]


func _init() -> void:
	# -s 모드에서는 _init 시점에 오토로드(EchoBus, GameState...)가 아직 전역 이름으로 등록되지 않는다.
	# 첫 프레임까지 기다렸다가 검사한다.
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	var failures: Array[String] = []
	var checked := 0
	for root in ROOTS:
		checked += _scan(root, failures)
	if failures.is_empty():
		print("check_scripts: OK (%d files)" % checked)
		quit(0)
		return
	for f in failures:
		printerr("check_scripts: FAIL ", f)
	quit(1)


func _scan(dir_path: String, failures: Array[String]) -> int:
	var count := 0
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return 0
	for sub in dir.get_directories():
		count += _scan(dir_path.path_join(sub), failures)
	for file in dir.get_files():
		var path := dir_path.path_join(file)
		match file.get_extension():
			"gd":
				count += 1
				var script := load(path) as GDScript
				if script == null or not script.can_instantiate():
					failures.append(path)
			"tscn":
				count += 1
				var scene := load(path) as PackedScene
				if scene == null or not scene.can_instantiate():
					failures.append(path)
	return count
