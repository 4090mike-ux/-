extends Node
## 소리 감독 (오토로드 "Audio"). docs/audio/audio_direction.md §5, §8-2.
##
## - 버스: Music / Ambience / SFX / UI (없으면 만든다). Music·Ambience 에 저역 통과 필터 — 전역 채도에 연동
##   (차단 주파수 = 3000 × (20000/3000)^채도). 대사 중에는 음악 −4 dB.
## - BGM: game/audio/bgm/bgm_<이름>.ogg, 1.5초 교차 페이드. 환경음: game/audio/sfx/amb/amb_<이름>.ogg
## - 효과음: game/audio/sfx/<분류>/sfx_<분류>_<이름>.wav → play_sfx("<분류>_<이름>")
## - EchoBus 를 듣고 자동으로 낸다: 잔향 감지·수집, 태그 전환, 저장.

const BGM_DIR := "res://game/audio/bgm"
const SFX_DIR := "res://game/audio/sfx"
const CROSSFADE := 1.5
const DUCK_DB := -4.0
const BUSES: Array[String] = ["Music", "Ambience", "SFX", "UI"]
const BUS_DB := {"Music": 0.0, "Ambience": -6.0, "SFX": 0.0, "UI": -3.0}
const POOL_SIZE := 10

var current_bgm: String = ""
var current_amb: String = ""
var _music: Array[AudioStreamPlayer] = []
var _music_index: int = 0
var _amb: AudioStreamPlayer
var _pool: Array[AudioStreamPlayer] = []
var _pool_index: int = 0
var _cache: Dictionary = {}
var _saturation: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_buses()
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.bus = &"Music"
		p.volume_db = -80.0
		add_child(p)
		_music.append(p)
	_amb = AudioStreamPlayer.new()
	_amb.bus = &"Ambience"
	add_child(_amb)
	for i in POOL_SIZE:
		var s := AudioStreamPlayer.new()
		s.bus = &"SFX"
		add_child(s)
		_pool.append(s)
	EchoBus.echo_sensed.connect(_on_echo_sensed)
	EchoBus.echo_collected.connect(_on_echo_collected)
	EchoBus.character_switched.connect(func(_k: String) -> void: play_sfx("sib_tag_switch"))
	EchoBus.game_saved.connect(func(slot: int) -> void:
		if slot != SaveService.AUTOSAVE_SLOT:
			play_sfx("ui_save", "UI"))
	EchoBus.dialogue_started.connect(func(_s: String) -> void: _duck(true))
	EchoBus.dialogue_finished.connect(func(_s: String) -> void: _duck(false))
	set_saturation(0.0)


## BGM 교차 페이드. 같은 곡이면 그대로. 빈 문자열이면 페이드 아웃.
func play_bgm(name: String) -> void:
	if name == current_bgm:
		return
	current_bgm = name
	var old := _music[_music_index]
	_music_index = 1 - _music_index
	var new := _music[_music_index]
	var tween := create_tween().set_parallel(true)
	tween.tween_property(old, "volume_db", -80.0, CROSSFADE)
	if name.is_empty():
		return
	var stream := _load("%s/bgm_%s.ogg" % [BGM_DIR, name])
	if stream == null:
		return
	_set_loop(stream)
	new.stream = stream
	new.volume_db = -80.0
	new.play()
	tween.tween_property(new, "volume_db", 0.0, CROSSFADE)


func play_ambience(name: String) -> void:
	if name == current_amb:
		return
	current_amb = name
	if name.is_empty():
		_amb.stop()
		return
	var stream := _load("%s/amb/amb_%s.ogg" % [SFX_DIR, name])
	if stream == null:
		return
	_set_loop(stream)
	_amb.stream = stream
	_amb.play()


## 효과음: "<분류>_<이름>" (예: "pzl_place_ok"). 발소리처럼 반복되는 소리는 피치를 ±5% 흔든다.
func play_sfx(name: String, bus: String = "SFX", vary: bool = false) -> void:
	var category := name.get_slice("_", 0)
	var stream := _load("%s/%s/sfx_%s.wav" % [SFX_DIR, category, name])
	if stream == null:
		return
	var p := _pool[_pool_index]
	_pool_index = (_pool_index + 1) % _pool.size()
	p.stream = stream
	p.bus = StringName(bus)
	p.pitch_scale = randf_range(0.95, 1.05) if vary else 1.0
	p.play()


## 전역 채도 → 음악·환경음 저역 통과 차단 주파수
func set_saturation(value: float) -> void:
	_saturation = clampf(value, 0.0, 1.0)
	var cutoff := 3000.0 * pow(20000.0 / 3000.0, _saturation)
	for bus_name: String in ["Music", "Ambience"]:
		var idx := AudioServer.get_bus_index(bus_name)
		if idx < 0:
			continue
		for e in AudioServer.get_bus_effect_count(idx):
			var lpf := AudioServer.get_bus_effect(idx, e) as AudioEffectLowPassFilter
			if lpf != null:
				lpf.cutoff_hz = cutoff


func cutoff_hz() -> float:
	return 3000.0 * pow(20000.0 / 3000.0, _saturation)


func _duck(on: bool) -> void:
	var idx := AudioServer.get_bus_index("Music")
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, float(BUS_DB["Music"]) + (DUCK_DB if on else 0.0))


func _on_echo_sensed(echo_id: String, _by: String) -> void:
	var def := GameData.echo_def(echo_id)
	if str(def.get("kind", "")) == "hidden":
		play_sfx("echo_hidden_sparkle")
	else:
		var emotion := str(def.get("emotion", "longing"))
		play_sfx("echo_found_%s" % emotion if _exists("echo", "echo_found_%s" % emotion) else "echo_found_longing")


func _on_echo_collected(_echo_id: String, emotion: String) -> void:
	play_sfx("pzl_solved")
	var name := "color_restore_%s" % emotion
	play_sfx(name if _exists("color", name) else "color_restore_longing")


## "<분류>_<이름>" 효과음 파일이 있는가
func has_sfx(name: String) -> bool:
	return _exists(name.get_slice("_", 0), name)


func _exists(category: String, name: String) -> bool:
	return ResourceLoader.exists("%s/%s/sfx_%s.wav" % [SFX_DIR, category, name])


func _load(path: String) -> AudioStream:
	if _cache.has(path):
		return _cache[path] as AudioStream
	if not ResourceLoader.exists(path):
		return null
	var stream := load(path) as AudioStream
	_cache[path] = stream
	return stream


func _set_loop(stream: AudioStream) -> void:
	var ogg := stream as AudioStreamOggVorbis
	if ogg != null:
		ogg.loop = true


func _ensure_buses() -> void:
	for bus_name in BUSES:
		if AudioServer.get_bus_index(bus_name) >= 0:
			continue
		AudioServer.add_bus()
		var idx := AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, &"Master")
		AudioServer.set_bus_volume_db(idx, float(BUS_DB[bus_name]))
		if bus_name == "Music" or bus_name == "Ambience":
			var lpf := AudioEffectLowPassFilter.new()
			lpf.cutoff_hz = 3000.0
			AudioServer.add_bus_effect(idx, lpf)
