# ADR-0001: 엔진 Godot 4.7.2 + GDScript + GL Compatibility

- 상태: 제안 (G1에서 개발자 승인)
- 날짜: 2026-11-26
- 제안: WP-03

## 배경

계획서 ③에서 Godot 4.7.x(1순위)와 Unity 6(2순위)를 비교했다. 1차 출시는 itch.io **웹 + Windows** 무료 데모다.

## 결정

1. **Godot 4.7.2-stable 표준판**(2026-08-18 릴리스), .NET 아님. 언어는 GDScript 정적 타입.
   - `project.godot`에서 `untyped_declaration` 경고를 **오류**로, unsafe 접근 경고 3종을 경고로 둔다.
2. 렌더러는 **GL Compatibility**(데스크톱·모바일 모두). Godot 웹 내보내기는 Compatibility 렌더러만 지원하므로 처음부터 맞춘다. 색 복원 셰이더의 `hint_screen_texture`는 Compatibility에서 동작한다.
3. 화면은 480×270 viewport 스트레치 + 정수 배율, 텍스처 필터 nearest, 2D 픽셀 스냅.
4. 텍스트 씬·리소스(.tscn/.tres)만 쓴다(바이너리 .scn/.res 금지) — 에이전트가 읽고 고칠 수 있게.

## 대안

| 대안 | 장점 | 단점 |
|---|---|---|
| Unity 6 Personal | 보유 unity:* 스킬, 공식 `unity mcp` | YAML 씬·.meta 병합 충돌, 에디터 의존 |
| Forward+ 렌더러 | 고급 2D 조명 | 웹 내보내기 불가 |

## 영향

- CI: `godot-gdunit-labs/gdUnit4-action`에 `godot-version: 4.7.2`.
- Godot 버전을 올릴 때는 이 ADR을 대체하는 새 ADR을 쓰고 CI·`project.godot`의 `config/features`를 함께 바꾼다.
