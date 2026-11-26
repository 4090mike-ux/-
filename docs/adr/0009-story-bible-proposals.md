# ADR-0009: story_bible 설정 변경 제안 반영 (C1·C2·C4·C5·C6·C11·C12)

- 상태: 승인 (개발자 위임, 2026-11-26)
- 날짜: 2026-11-26
- 제안: WP-06 story_bible 「설정 변경 제안」

## 결정

| # | 반영 | 파일 |
|---|---|---|
| C1 | canon 본문의 남은 TODO-확인을 §12·story_bible 근거의 [확정]으로 바꿨다(W-COLOR, W-STONE, 하늘 = '공허의 화가', 지은·직원 세부, 작업실·방, H.S 첫 등장, 프롤로그, 감정 이름 D8) | `docs/bible/canon_v1.md` |
| C2 | 희생 엔딩 동점이면 **하늘**이 바친다 [확정] | canon §10-1 |
| C4 | W-FACE 1단계 조건에 "재결합 단서 1개 이상(사이드 가족)" 추가, 부모 얼굴은 공개 전 0단계 고정·공개 후 2단계 | canon §2 |
| C5 | 보호 엔딩 전역 채도 0.90 → **0.55** | `docs/gdd/progression.md` §3-7 |
| C6 | 폴백 ② 조건 `families_reunited < 2` → `< 1`(D7), 예시 경로 7을 가족 0으로 | `docs/gdd/endings.md` |
| C11 | 효과음 3개(시계탑 종, 불꽃놀이, 개 짖음)를 110개 안에서 교체 | `docs/audio/audio_direction.md` §7 |
| C12 | 챕터 배경 담당 WP, `game/art/props·memory`, `tools/pixelart`, `tools/audio`, `docs/audio` 소유권 | `docs/ownership.md` |

미반영: C3·C7·C8(화자·장소·잔향 i18n)은 챕터별 대사 WP에서 그 챕터 몫을 넣는다. C9 변경 없음. C10(독백 카드 태그, 공개 후 별의 반말 규칙)은 챕터 4 대사 WP 전에 대사 규약에 넣는다.

## 근거

원작 원문이 저장소에 없고, 개발자가 설정·이야기 결정을 위임했다. canon에 TODO가 남아 있으면 이후 작가(사람·AI)가 다시 추측하므로, story_bible을 근거로 한 번에 닫는다. 원문이 생기면 `docs/bible/source/story_original.md`로 넣고 대조한다.
