# ADR-0007: W3 런타임 — 데이터 주도 장면, 대사 상자, GDD 퍼즐

- 상태: 승인 (개발자 위임, 2026-11-26)
- 날짜: 2026-11-26
- 제안: WP-19, WP-20(일부), WP-21

## 결정

1. **장면은 데이터로 만든다.** `game/data/scenes/<scene_id>.json`(스키마 `scene.schema.json`) + 배경 메타데이터 `game/art/bg/<bg>.json`을 `ChapterScene`이 읽어 배경·벽·캐릭터·잔향·조사 대상·NPC·출구·레이어를 만든다. `.tscn`은 `tools/gen_scene_files.py`가 생성하는 한 줄짜리 파일이다(CI가 최신 여부 검사).
2. **장면 전환은 `SceneRouter` 오토로드.** 페이드, GameState 위치 갱신, `EchoBus.scene_changed`, 이야기 장면 진입 시 자동 저장(슬롯 0). 수동 저장은 일시정지 메뉴의 슬롯 1.
3. **Dialogue Manager 4를 켠다.** `DialogueManager` 오토로드 + 에디터 플러그인(임포트용). 대사 상자 `DialogueBox`는 DM의 `DialogueLabel`을 쓰고, 화자 키를 `GameState.name_display()`로 바꾼다(R-NAME). `[#choice]` 응답은 자동으로 `record_choice`.
4. **한 번만 나오는 대사**는 `GameState.mark_cue_seen("<scene>:<cue>")`로 기록하고 세이브의 `state.seen_cues`에 저장한다(save 스키마에 선택 필드 추가, schema_version 1 유지 — G1 전).
5. **입력 하나로 상호작용.** `Interactor`(캐릭터 자식)가 interact를 받아 ① 감지된 잔향 ② 가까운 `Interactable` 순서로 처리한다. `EchoSensor`는 더 이상 입력을 받지 않는다.
6. **GDD 퍼즐 2종**: `ColorMatchPuzzle`(CM-A), `MemoryOrderPuzzle`(MO-A/B), 공통 `EchoPuzzle`(실패 없음·힌트 타이머·2힌트 뒤 건너뛰기). 내용은 `game/data/puzzles/<slug>.json`(스키마 `puzzle.schema.json`). MO는 "다음 순서 카드 고르기" 방식으로 조작을 단순화했다(정답 판정은 GDD와 같음). 프로토타입 고리 퍼즐(`ResonancePuzzle`)은 dev 씬에만 남긴다.
7. **UI 글꼴은 갈무리11/9**(OFL, `game/art/fonts/OFL.txt` 동봉), 안티에일리어싱 끔. 프로젝트 테마 `game/ui/theme.tres`.
8. F5 기본 씬은 타이틀(`game/scenes/ui/title.tscn`).
