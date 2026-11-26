# ADR-0005: W2 잔향 프로토타입 구조

- 상태: 승인 (개발자 위임, 2026-11-26) — G2 판정은 개발자가 직접
- 날짜: 2026-11-26
- 제안: WP-12, WP-13, WP-14

## 결정

1. **감지 하이라이트는 흑백 필터 위에 그린다.** `EchoHighlightLayer`(CanvasLayer 15, follow_viewport)가 감지된 잔향의 윤곽·기호를 그린다. 필터(레이어 10) 아래에 그리면 감지 윤곽까지 회색이 된다.
2. **색 복원 마스크는 월드 좌표.** `ColorRestoreLayer`가 매 프레임 마스크 SubViewport의 `canvas_transform`을 메인 뷰포트와 맞춘다. 카메라가 움직여도 복원된 자리가 따라간다. 따라서 `EchoBus.color_restored`의 위치 인자는 `world_pos`다.
3. **씬을 열면 이미 모은 잔향 자리를 애니메이션 없이 다시 칠한다.** 마스크 자체는 저장하지 않는다 — 세이브의 `echoes_collected`만으로 화면을 재현한다.
4. **잔향 정의의 원천은 데이터.** `EchoObject`는 `echo_id`로 `game/data/echoes/*.json`을 찾고, 없을 때만 `fallback_*` 값을 쓴다(프로토타입 전용).
5. **공명 퍼즐 프로토타입 = 기호 고리 타이밍.** 가운데 기호가 위쪽 표시에 올 때 누른다. 3번 맞히면 성공, 맞힐 때마다 반대로 더 빨리, 45초 제한. 색 없이 기호만으로 풀 수 있다. 최종 퍼즐 2종(color_match, memory_order)의 규칙은 GDD(`docs/gdd/echo.md`)를 따르고, 이 프로토타입은 G2 재미 검증용이다.
6. **조정 값은 노드의 `@export`** (감지 hold 0.3초, 반경 96px, 상호작용 28px, 퍼즐 속도 등 — 모두 [제안]). GDD 수치가 확정되면 그 값으로 바꾼다.
7. F5 기본 씬을 `game/scenes/dev/echo_prototype.tscn`으로 바꾼다(G2 셀프 플레이).
