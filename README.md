# 공허의 화가: 잔향의 색

색을 잃은 세계에서 감정의 잔향을 모아, 서로가 남매라는 사실을 잊은 하늘과 별이 기억을 되찾는 2D 탐색 어드벤처.

- 엔진: Godot 4.7.2 (GDScript, GL Compatibility) · 480×270 픽셀아트
- 대사: Dialogue Manager 4 · 테스트: gdUnit4 · CI: GitHub Actions
- 진행 방식: 1인 개발 + AI 에이전트 병렬 작업 ([계획서](docs/plan/dev_plan_v1.md))

## 빠른 시작

1. [Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/) 표준판을 받는다.
2. Git LFS를 켠다: `git lfs install`
3. Python 도구: `pip install -r tools/requirements.txt`
4. Godot 에디터에서 `project.godot`를 연다. 처음 열면 **Project → Project Settings → Plugins**에서 gdUnit4와 Dialogue Manager를 켠다.
5. F5로 실행하면 색 복원 셰이더 데모(`game/scenes/dev/color_demo.tscn`)가 뜬다.
6. 커밋 전: Git Bash에서 `GODOT_BIN=<godot 경로> tools/ci_local.sh`

작업 규칙은 [AGENTS.md](AGENTS.md)에 있다.

## 문서 지도

| 문서 | 내용 |
|---|---|
| [docs/bible/canon_v1.md](docs/bible/canon_v1.md) | 설정 확정본 (G0 서명란 포함) |
| [docs/schemas/](docs/schemas/) | 데이터 스키마 5종 + 대사 규약 |
| [docs/style/art_style.md](docs/style/art_style.md) | 아트 스타일 가이드 + [팔레트](docs/style/palette.gpl) |
| [docs/ownership.md](docs/ownership.md) | 트랙별 파일 소유권 |
| [docs/adr/](docs/adr/) | 기술 결정 기록 |
| [docs/ai_usage.md](docs/ai_usage.md) | AI 사용 기록 (스팀 공개용) |

## 현재 단계

**Wave 0 — 계약.** 다음 게이트: G0(설정 확정본 서명), G1(계약 동결 v1.0).
