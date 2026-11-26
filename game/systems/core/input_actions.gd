class_name InputActions
extends RefCounted
## 입력 액션 이름. project.godot 의 [input] 과 같아야 한다 (tests/unit/core/test_input_map.gd 가 검사).
## 기본 키: docs/gdd/controls_accessibility.md

const MOVE_LEFT := &"move_left"
const MOVE_RIGHT := &"move_right"
const MOVE_UP := &"move_up"
const MOVE_DOWN := &"move_down"
const INTERACT := &"interact"
const ECHO_SENSE := &"echo_sense"   # 누르고 있는 동안 감지
const TAG_SWITCH := &"tag_switch"
const PAUSE := &"pause"

const ALL: Array[StringName] = [
	MOVE_LEFT, MOVE_RIGHT, MOVE_UP, MOVE_DOWN, INTERACT, ECHO_SENSE, TAG_SWITCH, PAUSE,
]
