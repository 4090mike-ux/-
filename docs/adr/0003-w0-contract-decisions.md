# ADR-0003: Wave 0 계약 결정 모음

- 상태: 제안 (G1에서 개발자 승인)
- 날짜: 2026-11-26
- 제안: WP-02, WP-04, WP-05

계획서에 없거나 모호했던 부분을 W0에서 정한 기록이다. 설정(스토리) 결정은 여기가 아니라 [canon_v1.md §11](../bible/canon_v1.md)의 서명란에 있다.

## 결정

1. **스키마 5종.** 계획서의 3종(flags, echo, save)에 `persist.schema.json`(세이브 간 기록)과 `emotions.schema.json`(감정 색 계약)을 더했다. 둘 다 여러 트랙이 의존하는 데이터라 별도 계약이 필요하다.
2. **계산 가능한 값은 저장하지 않는다.** `echo_found`, `hidden_echo_found`는 세이브의 `echoes_collected` 목록에서 계산한다. 값이 두 군데 있으면 언젠가 어긋난다.
3. **잔향 데이터에 색·기호를 쓰지 않는다.** 잔향은 `emotion` id만 갖고, 색·대역·기호는 `emotions.json`에서 가져온다(계획서는 echo 스키마에 "색, 기호"를 넣으라고 했지만 중복이라 뺐다). 위치도 좌표 대신 씬 안 `Marker2D` 이름으로 참조한다 — 씬이 위치의 원천.
4. **플래그 이름 규칙 통일.** 계획서 본문의 `flag.truth_revealed`를 이름 규칙 `flag.<챕터>.<의미>`에 맞춰 `flag.ch4.truth_revealed`로 쓴다(canon D10).
5. **대사는 GameState API로만 상태를 바꾼다.** 직접 대입 금지. API 목록은 [dialogue_conventions.md §5](../schemas/dialogue_conventions.md)가 계약이고 WP-08이 구현한다.
6. **성향 선택지에 `[#choice=id]` 태그.** 분기 시뮬레이터가 대사 파일을 직접 읽어 엔딩 도달성을 검증할 수 있게 한다.
7. **색 복원은 화면 좌표 마스크 + Hue 대역.** 마스크는 화면과 같은 해상도의 SubViewport에 그린다. 카메라가 움직이면 월드→화면 변환은 호출자가 한다(WP-13).
8. **배경은 원색 한 장, 흑백은 셰이더가 만든다.** 계획서의 "흑백 + 채색 레이어"는 "잔향 오브젝트를 별도 레이어로 분리"로 바꿔 해석했다(art_style.md §5). 배경 작업량이 절반으로 준다.
9. **중립색 보호.** 채도 0.30 미만 픽셀은 감정 대역 판정에서 뺀다(`band_min_saturation = 0.35`, 경계 ±0.05). 팔레트 규칙(중립색 채도 ≤ 0.28)과 짝을 이룬다.

## 영향

- `tools/validate_data.py`가 2·3·9번 규칙을 교차 검사한다.
- `tools/lint_names.py`가 5·6번 형식(화자 키, 태그, choice id 중복)을 검사한다.
