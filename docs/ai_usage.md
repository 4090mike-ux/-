# AI 사용 기록

스팀 Content Survey(2026-01-16 개정)는 **플레이어가 소비하는 사전 생성 콘텐츠**(아트, 사운드, 서사, 현지화, 마케팅 자료)에 AI를 썼으면 공개하도록 요구한다. 코드 보조 같은 개발 도구 사용은 공개 대상이 아니지만, 추적을 위해 함께 적는다.

규칙: **줄 추가만** 한다(수정·삭제 금지). 출시 전에 "공개 대상 = 예"인 줄을 모아 스토어 공개 문구를 만든다(WP-42).

| 날짜 | 대상 (경로) | 도구 | 용도 | 출시물 포함 | 사람이 수정 | 공개 대상 |
|---|---|---|---|---|---|---|
| 2026-11-26 | `docs/`, `tools/`, `game/systems/color/`, `game/shaders/`, `tests/` (W0 계약·도구·셰이더 스파이크) | Claude Code (Claude Opus 5.5) | 개발 도구 — 문서·코드 초안 | 코드만 | 검수 예정 | 아니오 (개발 도구) |
| 2026-11-26 | `game/autoload/`, `game/systems/core/`, `game/systems/sibling/`, `tools/branch_sim.py`, `tests/` (W1 코어) | Claude Code (Claude Opus 5.5) | 개발 도구 — 코드 초안 | 코드만 | 검수 예정 | 아니오 (개발 도구) |
| 2026-11-26 | `docs/style/palette.gpl`, `game/data/emotions.json`의 ramp 색 | Claude Code (HSV 계산 스크립트) | 기준 팔레트 v0 수치 생성 | 예 (팔레트) | 아트 승인 때 조정 예정 | 검토 필요 — 아트 승인 후 판단 |
