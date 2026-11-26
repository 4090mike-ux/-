extends GdUnitTestSuite
## WP-05 색 복원 셰이더 계약 테스트.
## 렌더링이 필요한 테스트는 headless 에서 건너뛴다 (CI 는 xvfb 로 실제 렌더링).

const SHADER_PATH := "res://game/shaders/color_restore.gdshader"
const DEMO_PATH := "res://game/scenes/dev/color_demo.tscn"
const CONTRACT_UNIFORMS: Array[String] = [
	"color_mask", "global_saturation", "off_band_saturation",
	"band_count", "bands", "band_min_saturation", "gray_tint",
]


func test_shader_exposes_contract_uniforms() -> void:
	var shader: Shader = load(SHADER_PATH)
	assert_object(shader).is_not_null()
	var names: Array[String] = []
	for u: Dictionary in shader.get_shader_uniform_list():
		names.append(str(u["name"]))
	assert_array(names).contains(CONTRACT_UNIFORMS)


func test_five_emotions_are_defined() -> void:
	var emotions := EmotionBands.load_emotions()
	assert_int(emotions.size()).is_equal(5)
	for id in EmotionBands.EMOTION_IDS:
		assert_bool(emotions.has(id)).is_true()
		assert_int(EmotionBands.ramp(id).size()).is_equal(4)


func test_emotion_bands_do_not_overlap() -> void:
	# 대역(반폭 + 부드러움)이 겹치면 한 잔향이 다른 감정 색까지 복원해 버린다
	var ids := EmotionBands.EMOTION_IDS
	for i in ids.size():
		for j in range(i + 1, ids.size()):
			var a := EmotionBands.band_for(ids[i])
			var b := EmotionBands.band_for(ids[j])
			var dist := absf(fposmod(a.x - b.x + 0.5, 1.0) - 0.5)
			var reach := a.y + a.z + b.y + b.z
			assert_float(dist).override_failure_message(
				"%s 와 %s 대역이 겹침 (거리 %.3f < %.3f)" % [ids[i], ids[j], dist, reach]
			).is_greater(reach)


func test_emotion_ramp_colors_sit_inside_their_band() -> void:
	# 아트 규칙: 감정 색은 자기 대역 안 + 채도 0.45 이상 (docs/style/art_style.md)
	for id in EmotionBands.EMOTION_IDS:
		var band := EmotionBands.band_for(id)
		for c in EmotionBands.ramp(id):
			var dist := absf(fposmod(c.h - band.x + 0.5, 1.0) - 0.5)
			assert_float(dist).override_failure_message("%s 색 %s 가 대역 밖" % [id, c.to_html(false)]).is_less_equal(band.y)
			assert_float(c.s).override_failure_message("%s 색 %s 채도 부족" % [id, c.to_html(false)]).is_greater_equal(0.45)


func test_apply_sets_band_uniforms() -> void:
	var mat := ShaderMaterial.new()
	mat.shader = load(SHADER_PATH)
	var ids: Array[String] = ["longing", "warmth"]
	EmotionBands.apply(mat, ids)
	assert_int(int(mat.get_shader_parameter("band_count"))).is_equal(2)
	var bands: PackedVector4Array = mat.get_shader_parameter("bands")
	assert_int(bands.size()).is_equal(EmotionBands.MAX_BANDS)
	assert_float(bands[0].x).is_equal_approx(215.0 / 360.0, 0.0001)


func test_demo_scene_instantiates() -> void:
	var runner := scene_runner(DEMO_PATH)
	assert_object(runner.scene()).is_not_null()
	assert_object(runner.find_child("MaskPainter")).is_instanceof(ColorMaskPainter)


func test_band_restore_keeps_selected_hue_only(
		_do_skip := DisplayServer.get_name() == "headless",
		_skip_reason := "실제 렌더링이 필요함 (CI 는 xvfb 에서 실행)",
		timeout := 10000) -> void:
	# 1×4 픽셀: 파랑(그리움) / 노랑(온기) / 피부(중립) / 진한 파랑. 그리움 대역 + 전체 마스크.
	var vp: SubViewport = auto_free(SubViewport.new())
	vp.size = Vector2i(4, 1)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var colors: Array[Color] = [Color("#2c5c9e"), Color("#d1b91f"), Color("#c9ac99"), Color("#153961")]
	for i in colors.size():
		var px := ColorRect.new()
		px.color = colors[i]
		px.position = Vector2(i, 0)
		px.size = Vector2.ONE
		vp.add_child(px)
	var layer := CanvasLayer.new()
	var rect := ColorRect.new()
	rect.size = Vector2(4, 1)
	var mat := ShaderMaterial.new()
	mat.shader = load(SHADER_PATH)
	var white := Image.create_empty(4, 1, false, Image.FORMAT_RGBA8)
	white.fill(Color.WHITE)
	mat.set_shader_parameter("color_mask", ImageTexture.create_from_image(white))
	var ids: Array[String] = ["longing"]
	EmotionBands.apply(mat, ids)
	rect.material = mat
	layer.add_child(rect)
	vp.add_child(layer)
	add_child(vp)
	await await_idle_frame()
	# frame_post_draw 를 기다리면 창이 최소화됐을 때 영원히 멈춘다. 동기 강제 그리기를 쓴다.
	RenderingServer.force_draw(false)
	RenderingServer.force_draw(false)
	var img := vp.get_texture().get_image()
	assert_object(img).is_not_null()
	# 파랑 계열은 원색 유지
	assert_float(img.get_pixel(0, 0).s).is_greater(0.5)
	assert_float(img.get_pixel(3, 0).s).is_greater(0.5)
	# 노랑·피부는 흑백
	assert_float(img.get_pixel(1, 0).s).is_less(0.05)
	assert_float(img.get_pixel(2, 0).s).is_less(0.05)
