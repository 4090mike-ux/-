# AI 사용 기록

스팀 Content Survey(2026-01-16 개정)는 **플레이어가 소비하는 사전 생성 콘텐츠**(아트, 사운드, 서사, 현지화, 마케팅 자료)에 AI를 썼으면 공개하도록 요구한다. 코드 보조 같은 개발 도구 사용은 공개 대상이 아니지만, 추적을 위해 함께 적는다.

규칙: **줄 추가만** 한다(수정·삭제 금지). 출시 전에 "공개 대상 = 예"인 줄을 모아 스토어 공개 문구를 만든다(WP-42).

| 날짜 | 대상 (경로) | 도구 | 용도 | 출시물 포함 | 사람이 수정 | 공개 대상 |
|---|---|---|---|---|---|---|
| 2026-11-26 | `docs/`, `tools/`, `game/systems/color/`, `game/shaders/`, `tests/` (W0 계약·도구·셰이더 스파이크) | Claude Code (Claude Opus 5.5) | 개발 도구 — 문서·코드 초안 | 코드만 | 검수 예정 | 아니오 (개발 도구) |
| 2026-11-26 | `game/autoload/`, `game/systems/core/`, `game/systems/sibling/`, `tools/branch_sim.py`, `tests/` (W1 코어) | Claude Code (Claude Opus 5.5) | 개발 도구 — 코드 초안 | 코드만 | 검수 예정 | 아니오 (개발 도구) |
| 2026-11-26 | `docs/style/palette.gpl`, `game/data/emotions.json`의 ramp 색 | Claude Code (HSV 계산 스크립트) | 기준 팔레트 v0 수치 생성 | 예 (팔레트) | 아트 승인 때 조정 예정 | 검토 필요 — 아트 승인 후 판단 |
| 2026-11-26 | `docs/gdd/`, `docs/audio/` (WP-06 GDD 7종, WP-11 오디오 디렉션) | Claude Code 서브에이전트 (Claude Opus 5.5) | 기획 문서 초안 | 아니오 (문서) | 검수 예정 | 아니오 (내부 문서) |
| 2026-11-26 | `game/autoload/scene_router.gd`, `game/systems/scene/`, `game/systems/echo/puzzles/`, `game/ui/` (W3 런타임: 장면 뼈대·대사 상자·퍼즐·타이틀) | Claude Code (Claude Opus 5.5) | 개발 도구 — 코드 | 코드만 | 검수 예정 | 아니오 (개발 도구) |
| 2026-11-26 | `game/dialogue/prologue/`, `game/dialogue/ch1/`, `game/data/echoes/`, `game/data/puzzles/`, `game/i18n/ui.csv`(잔향·장소·NPC 이름), `docs/narrative/slice_beats.md` (WP-16/17 버티컬 슬라이스) | Claude Code 서브에이전트 (Claude Opus 5.5) | 서사 초안 — 프롤로그·챕터 1 대사, 잔향 기억 문구, 퍼즐 캡션, 장소·잔향 이름 | 예 | 사람 검수 필요 | 예 |
| 2026-11-26 | `docs/bible/story_bible.md` (WP-06 스토리 바이블 v1 초안 — 줄거리·인물·NPC·사이드 가족·장소·잔향 기억·선택지·엔딩·제작 목록) | Claude Code 서브에이전트 (Claude Opus 5.5) | 서사 — story bible draft by Claude | 예 (대사의 근거) | 사람 검수 필요 | 예 |
