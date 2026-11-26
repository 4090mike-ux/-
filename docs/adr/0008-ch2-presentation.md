# ADR-0008: 챕터 2 연출 — 보호 컷인, 기억 컷·기억 공유, 오디오 태그

- 상태: 승인 (개발자 위임, 2026-11-26)
- 날짜: 2026-11-26
- 제안: WP-25 (챕터 2 엔진), sibling.md 계약 변경 제안 S1·S3

## 결정

1. **보호 컷인** `ProtectCutIn`(`game/ui/cutin/`). 대사 줄의 `[#cutin=protect]`를 만나면 대사 상자가 그 줄을 보여 주기 전에 1.2초 컷인을 재생한다. 입력은 잠기고, 같은 장면·같은 줄의 컷인을 다시 볼 때만 `interact`로 건너뛴다(본 기록: `seen_cues`의 `<scene>:cutin:<line id>`). **보호자 = 활성 캐릭터, bond 3 전에는 항상 하늘**(sibling.md §7, S3). 그림은 따로 그리지 않고 초상(보호자 앞·크게, 지켜지는 사람 뒤·어둡게) + 중립색 속도선 띠로 만든다. 움직임 줄이기 = 정지 그림 페이드. 패드 진동은 새 설정 `accessibility/rumble`(기본 켜기).
2. **기억 컷·기억 공유** `MemoryView`(`game/ui/memory/`, 캔버스 층 22 — 대사 상자 25 아래). 잔향을 모으면 장면이 `open(echo_id)` → `echo_<slug>_after` 대사 → `close()` 순서로 부른다. 그림 경로는 `game/art/memory/<slug>.png`(필수 240×135, 숨김 120×68, 공명 480×270) 또는 `reward.memory_cut`. 그림이 없으면 '글 컷'(감정 기호 + 잔향 이름; 공명이면 두 사람 초상을 양쪽 반 화면에)으로 대신한다. 공명 잔향은 세로 분할 화면이 위·아래에서 닦여 들어오고 닫을 때 가운데로 합쳐진다(sibling.md §8).
3. **EchoBus 시그널 추가**(S1): `protect_cutin_played(protector)`, `memory_opened(echo_id, shared)`.
4. **오디오 대사 태그 처리**: `[#sfx=<분류>_<이름>]` → `Audio.play_sfx`, `[#bgm=<id>]` → `Audio.play_bgm`(값 `none` = 페이드 아웃). NPC 대사는 `dlg_blip_npc`(없으면 별 블립).

## 근거

- 컷인·기억 컷 그림을 30장 넘게 따로 그리는 대신, 그림이 생기기 전에도 흐름을 플레이로 확인할 수 있게 글 컷으로 먼저 연결한다. 그림은 아트 WP에서 파일만 추가하면 코드 수정 없이 바뀐다.
- 컷인을 대사 상자 안에서 처리하면 대사 작가는 태그 하나만 쓰면 되고, 장면 스크립트를 건드리지 않는다.

## 결과

- 대사 규약 §4 표의 `[#cutin=protect]`·`[#bgm]` 설명을 갱신했다.
- 테스트: `tests/unit/ui/test_protect_cutin.gd`, `tests/unit/ui/test_memory_view.gd`, EchoBus 계약 표.
