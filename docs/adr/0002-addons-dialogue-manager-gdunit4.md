# ADR-0002: 애드온 고정 — Dialogue Manager 4.2.0, gdUnit4 6.2.3

- 상태: 제안 (G1에서 개발자 승인)
- 날짜: 2026-11-26
- 제안: WP-03

## 배경

대사는 텍스트 기반이어야 에이전트가 작성·검사할 수 있다(계획서 3-2). 테스트는 헤드리스 CI가 가능해야 한다.

## 결정

| 애드온 | 버전 | 용도 |
|---|---|---|
| Dialogue Manager (nathanhoad) | v4.2.0 (2026-10-30) | `.dialogue` 텍스트 대사·분기 |
| gdUnit4 (godot-gdunit-labs) | v6.2.3 (2026-11-01) | 단위·씬 테스트, CI |

1. `tools/install_addons.py`가 고정 태그를 내려받아 `addons/`에 설치하고, **결과를 저장소에 커밋**한다. 워크트리·CI·에이전트가 같은 버전을 쓰게 하기 위해서다.
2. `addons/`는 직접 고치지 않는다. 버전을 바꿀 때는 install_addons.py의 표를 고치고 `--force`로 재설치한 뒤 이 ADR을 대체하는 ADR을 쓴다.
3. 에디터 플러그인 활성화(Project Settings → Plugins)는 개발자가 에디터에서 한 번 켠다. Dialogue Manager는 켤 때 `DialogueManager` 오토로드를 스스로 등록한다. W0에서는 아직 켜지 않았다(대사 작업은 W3부터).
4. gdUnit4 v6은 기본적으로 헤드리스 실행을 거부한다. 로컬 빠른 검사는 `--ignoreHeadlessMode`로 돌리고(렌더링 테스트는 자동 건너뜀), CI는 xvfb(가상 디스플레이)에서 렌더링 테스트까지 실행한다.

## 대안

| 대안 | 판단 |
|---|---|
| Yarn Spinner for Godot | 아직 Early Access |
| Dialogic 2 | 장기 알파, 비주얼 에디터 중심 — 에이전트 작업에 불리 |
| 애드온을 커밋하지 않고 CI에서 설치 | 워크트리마다 설치가 필요하고 버전이 어긋날 수 있음 |

## 영향

- `.gitignore`에서 `addons/gdUnit4/test/`(애드온 자체 테스트)는 제외한다.
