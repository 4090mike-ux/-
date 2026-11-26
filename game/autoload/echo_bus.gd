extends Node
## 시스템 간 시그널 허브 (오토로드 "EchoBus").
##
## 시스템은 서로의 노드 경로를 모른다. 알릴 일이 생기면 여기 시그널을 emit 하고, 관심 있는 시스템이 connect 한다.
## 규칙: 시그널 이름은 과거형, 인자는 기본 타입(String/int/float/bool/Vector2)만.
## 새 시그널은 이 파일(공유 파일 — 통합 세션만 수정)과 tests/unit/core/test_echo_bus.gd 에 함께 추가한다.

# 잔향·색
signal echo_sensed(echo_id: String, by_character: String)
signal echo_collected(echo_id: String, emotion: String)
signal color_restored(emotion: String, world_pos: Vector2, radius: float)
signal resonance_triggered(emotion: String)

# 남매
signal character_switched(active_character: String)
signal protect_cutin_played(protector: String)
signal memory_opened(echo_id: String, shared: bool)

# 상태 (GameState 가 emit)
signal stat_changed(stat: String, value: int)
signal flag_changed(flag_id: String, value: Variant)
signal truth_revealed()
signal event_triggered(event_id: String)
signal ending_reached(ending_id: String)

# 장면
signal scene_changed(scene_id: String)

# 대사
signal dialogue_started(scene_id: String)
signal dialogue_finished(scene_id: String)

# 세이브 (SaveService 가 emit)
signal game_saved(slot: int)
signal game_loaded(slot: int)
