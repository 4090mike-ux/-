// 색 복원 셰이더 (WP-05 스파이크 → WP-13 통합 예정)
//
// 화면 전체를 흑백으로 만든 뒤, 다음 두 경로로 원색을 되돌린다.
//   1) global_saturation : 챕터 진행도에 따른 전역 채도
//   2) color_mask × 감정 대역 : 마스크(R 채널)가 칠해진 곳에서, 활성화된 감정 Hue 대역의 색만 복원
//
// 사용법: 맨 위 CanvasLayer > ColorRect(전체 화면, mouse_filter=IGNORE) > ShaderMaterial(이 셰이더)
//         color_mask 에는 같은 해상도의 SubViewport 텍스처를 넣는다 (화면 좌표 기준).
// 계약: 감정 대역 값은 game/data/emotions.json 이 원천이다. 숫자를 여기 하드코딩하지 말 것.
//       EmotionBands.apply() 가 bands / band_count 를 채운다.
shader_type canvas_item;

#define MAX_BANDS 8

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
// R 채널 = 복원량(0~1). 비어 있으면 검정 = 복원 없음.
uniform sampler2D color_mask : hint_default_black, filter_linear;
// 전역 채도 (0 = 완전 흑백, 1 = 원색)
uniform float global_saturation : hint_range(0.0, 1.0) = 0.0;
// 마스크 안에서 '대역 밖' 색이 받는 복원량 (0 = 대역 색만 복원)
uniform float off_band_saturation : hint_range(0.0, 1.0) = 0.0;
// 활성 대역 수. 0이면 대역 필터 없이 마스크 영역의 모든 색을 복원한다.
uniform int band_count : hint_range(0, 8) = 0;
// 대역: x = 중심 Hue(0~1), y = 반폭(0~0.5), z = 경계 부드러움(0~0.5), w = 세기(0~1)
uniform vec4 bands[MAX_BANDS];
// 이 채도(HSV S) 미만의 픽셀은 대역 판정에서 빠진다. 피부·나무 같은 중립색이 감정 대역에 휩쓸리지 않게 한다.
uniform float band_min_saturation : hint_range(0.0, 1.0) = 0.35;
// 흑백 톤 (1,1,1 = 순수 회색). 따뜻한 회색 연출이 필요할 때만 바꾼다.
uniform vec3 gray_tint : source_color = vec3(1.0, 1.0, 1.0);

vec3 rgb_to_hsv(vec3 c) {
	vec4 k = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, k.wz), vec4(c.gb, k.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

// 0~1: 이 픽셀이 활성 대역 중 하나에 속하는 정도
float band_weight(float hue, float sat) {
	if (band_count <= 0) {
		return 1.0;
	}
	float sat_gate = smoothstep(band_min_saturation - 0.05, band_min_saturation + 0.05, sat);
	float w = 0.0;
	for (int i = 0; i < MAX_BANDS; i++) {
		if (i >= band_count) {
			break;
		}
		vec4 b = bands[i];
		// Hue 는 원형이므로 0/1 경계를 넘는 거리를 처리한다
		float d = abs(fract(hue - b.x + 0.5) - 0.5);
		float in_band = 1.0 - smoothstep(b.y, b.y + max(b.z, 0.0001), d);
		w = max(w, in_band * b.w);
	}
	return w * sat_gate;
}

void fragment() {
	vec3 src = texture(screen_texture, SCREEN_UV).rgb;
	float luma = dot(src, vec3(0.2126, 0.7152, 0.0722));
	vec3 gray = vec3(luma) * gray_tint;
	vec3 hsv = rgb_to_hsv(src);
	float mask = clamp(texture(color_mask, SCREEN_UV).r, 0.0, 1.0);
	float restore = mask * mix(off_band_saturation, 1.0, band_weight(hsv.x, hsv.y));
	float amount = max(global_saturation, restore);
	COLOR = vec4(mix(gray, src, amount), 1.0);
}
