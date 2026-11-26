# 「공허의 화가: 잔향의 색」 A→Z 개발 계획서 — 1인 개발자 + AI 에이전트 병렬 진행판

결론부터: **엔진은 Godot 4.7.x(GDScript)를 쓰고, 대사는 Dialogue Manager 4로 쓰고, 작업은 11개 병렬 트랙과 7개 웨이브(W0~W6)로 쪼개는 것을 권합니다.** 웨이브마다 Claude Code 서브에이전트(워크트리 격리)와 Codex를 **동시에 3~5개까지만** 돌리는 구조가 현실적입니다. 첫 주에는 코드를 짜지 말고 "계약"(설정 확정본, 데이터 스키마, 스타일 가이드, 파일 소유권 표, AGENTS.md)부터 고정하세요. 병렬 작업은 그 뒤에야 깨지지 않습니다.

## TL;DR
- **엔진**: 1순위는 Godot 4.7.x입니다. 텍스트 씬(.tscn), 헤드리스 빌드·테스트, 다수의 Godot MCP 서버, MIT 라이선스가 근거입니다. 2순위는 Unity 6 Personal로, 보유 중인 unity:* 스킬과 공식 `unity mcp` CLI를 쓸 수 있습니다. 대사는 Dialogue Manager 4(텍스트 기반, 안정판), 테스트는 gdUnit4 + GitHub Actions로 합니다.
- **병렬 구조**: A~Z 26단계와 게이트 8개, 11개 트랙(기획·코어·게임플레이·아트·VFX/셰이더·오디오·대사데이터·UI·QA·빌드·마케팅), 약 40개 작업 패키지(WP)로 나눕니다. 크리티컬 패스는 "설정 확정 → 색 복원 셰이더+잔향 프로토타입 → 버티컬 슬라이스 → 챕터 대사 검수 → 엔딩 분기 검증"입니다.
- **출시**: 미성년자는 유료 정산을 직접 할 수 없습니다(itch.io는 18세 이상 또는 성인이 정산을 맡아야 함). [itch](https://itch.io/post/2595868) 1차 출시는 **itch.io 무료 웹/PC 데모(비영리, 등급분류 면제 범위)**로 하고, **BIC 루키(만 14세 이상, 학생 또는 2002년 이후 출생 미취업자) → GIGDC 중·고등부** 공모전으로 검증받은 뒤, 유료판은 보호자 명의로 스팀이나 스토브에 내는 2단계 경로를 권장합니다. 전체 완성판은 학업과 병행하면 **18~30개월(추정)**이 걸립니다.

---

## ① 한 화면 요약

| 항목 | 결정 |
|---|---|
| 엔진 | Godot 4.7.x 표준판(GDScript). 차선은 Unity 6 |
| 대사/분기 | Dialogue Manager 4(`.dialogue` 텍스트) + 전역 상태 `GameState` 오토로드 |
| 버전 관리 | GitHub + Git LFS(png/ogg/wav/aseprite), 트렁크 기반 + 단기 브랜치 + 워크트리 |
| 전체 단계 | A~Z 26단계, 게이트 G0~G7 |
| 병렬 트랙 | 11개 |
| 동시 에이전트 | 평시 3개, 피크 5개(코드 2 + 콘텐츠/아트 2 + 리뷰 1) |
| 첫 주 | Wave 0 계약 5종 확정. 셰이더 스파이크 1개만 코드로 진행 |
| 1차 출시 | itch.io 무료 데모(웹+Windows) → BIC 루키 → GIGDC → 보호자 명의 유료 출시 |

---

## ② 스토리 분석과 기획 보강(기획 확정 WP의 입력)

### 2-1. 원문의 문제와 해결안

| 문제 | 해결안(권장) |
|---|---|
| 챕터 2에 "은별의 집", 챕터 3에 "은하늘/은별"이 진실 공개(챕터 4) 전에 노출됨 | **표기 규칙 R-NAME**: 프롤로그~챕터 4의 '기억의 폭풍' 직전까지는 화면·대사·UI·미션명에 "하늘/별/청년/소녀"만 씁니다. 성 '은'은 챕터 4 이벤트 `ev_ch4_storm` 이후에만 씁니다. 미션명은 "작은 집의 다락방", "잃어버린 작업실", "그 아이의 방"으로 바꿉니다. 데이터에서는 `name_display` 키가 `flag.truth_revealed`에 따라 자동으로 바뀌게 하고, QA 린터가 금지어("은하늘", "은별")를 검사합니다. |
| "H.S" 사인과 '은하늘'의 이니셜이 맞지 않음 | 사인을 **남매 공동 서명 "H.S = Haneul & Star"**로 재정의합니다. 어릴 적 별이 "나는 영어로 스타야"라고 해서 만든 둘만의 서명입니다. 챕터 3의 '협력 작품'에서 같은 서명이 다시 발견되고, 이 장면이 남매 단서가 됩니다. 의미는 진실 공개 후에만 풀립니다. |
| 임시 이름이 본명과 우연히 일치함 | **"이름의 잔향" 설정**을 추가합니다. 원석의 보호 본능은 '가족 관계 기억'만 지웠고, 자기 이름은 가장 깊은 잔향으로 남아 무의식이 단서(H.S, 별 화분)에 반응했다는 설정입니다. 챕터 4 독백에 한 줄을 넣어 회수합니다. |
| 지은·놀이공원 직원이 "색이 없어 얼굴을 확신 못 함" | **세계 규칙 W-FACE**: 색은 감정의 각인이며, 색이 사라지면 사람 얼굴은 "미완성 스케치"처럼 흐려 보입니다. 목소리·키·체형·습관은 남습니다. 연출에서도 모든 NPC 얼굴을 반쯤 지워진 스케치로 그려 규칙을 시각화합니다. 잔향을 되찾을수록 얼굴 디테일이 늘어납니다. |
| "사랑은 어떤 실험보다도 강하다"의 '실험'이 본문에 없음 | 이전 버전의 잔재로 보고 **삭제하고 대체**합니다: "혈연은 기억보다 강하고, 사랑은 어떤 망각보다도 강하다." 실험 설정을 새로 넣으면 원석 설정과 충돌하므로 추가하지 않습니다. |
| 히든 엔딩이 2개(기적·희생) | 기적 = 1회차에서도 가능한 '완벽 수집' 히든, 희생 = **클리어 후 해금되는 트루 엔딩**으로 계층을 분리합니다(아래 표). |

### 2-2. 엔딩 분기 설계(변수·플래그)
- `protect`(하늘 성향)와 `heal`(별 성향)은 챕터 2~5의 선택지 약 24개로 ±1~2씩 누적합니다. `bond`(0~4)는 관계 복원 4단계를 나타내며 스토리 이벤트로만 올라갑니다.
- `echo_found`는 잔향 수집 수로, 필수 18개 + 숨김 12개입니다. `families_reunited`는 사이드 재결합 수(0~6)입니다. `persist.seen_endings`는 세이브 간에 공유되는 기록입니다.

| 엔딩 | 조건(평가 순서대로) |
|---|---|
| 💔 희생(트루) | `persist.seen_endings`에 가족 또는 기적이 있음 + `echo_found==30` + 최종 선택에서 숨은 선택지 "내 색을 바친다" 선택 |
| 🌈 기적(히든) | 가족 조건 충족 + 숨김 잔향 12개 전부 + '무지개 꽃'(신규 색 조합) 개화 |
| 💜 가족(균형) | \|protect−heal\| ≤ 2, `bond==4`, `families_reunited ≥ 3` |
| 💙 보호 | protect − heal ≥ 3 |
| 💚 치유 | heal − protect ≥ 3, `families_reunited ≥ 2` (미달하면 보호/가족으로 폴백) |

"치유 vs 보호 vs 함께"는 챕터 5 한 번의 선택이 아닙니다. **챕터 2~5에 흩어진 작은 선택의 누적**으로 결정되고, 챕터 5의 최종 대화는 그 결과를 확인하는 장치로 둡니다. 플레이어가 결과를 납득하도록, 정원의 꽃 색 비율(파랑:초록)로 현재 성향을 은근히 보여줍니다.

### 2-3. 게임플레이 정의(원문의 공백 메우기)
- **잔향 감지(Echo Sense)**: 버튼을 누르고 있으면 반경 내 잔향 오브젝트가 해당 감정 색의 윤곽으로 맥동합니다. 다가가 상호작용하면 30~60초짜리 **공명 퍼즐**(감정 색 맞추기, 기억 조각 순서 맞추기)이 열리고, 성공하면 색 조각과 기억 컷을 얻습니다.
- **색의 정원(허브)**: 색 조각이 씨앗입니다. 하늘과 별이 각각 심고, 실시간이 아니라 챕터·이벤트 진행으로 자랍니다. 같은 감정을 동시에 느낀 공명 이벤트가 있으면 성장이 +1 됩니다. 조합표는 예컨대 파랑+노랑 = '함께의 새싹'이고, 5색이 모두 맞으면 '가족의 꽃'이 핍니다(챕터 4 트리거).
- **두 주인공 조작**: 프롤로그~챕터 1은 하늘과 별의 파트를 번갈아 진행합니다. 광장에서 만난 뒤에는 **태그 전환(Tab)** 방식으로 바뀌고, 특정 구간은 **동시 조작 퍼즐**(한 명이 붙잡고 다른 한 명이 이동)로 진행합니다.
- **남매 상호작용 4종을 규칙으로**: 보호 본능은 위험 이벤트 시 자동 컷인 + `protect` 선택지, 공감 연결은 한쪽이 감지한 잔향이 다른 쪽 화면에도 표시되는 것으로 구현합니다. 기억 공유는 특정 장소에서 두 시점을 분할 화면으로 겹치고, 협력 강화는 `bond` 단계별로 공명 반경·동시 퍼즐을 해금합니다.
- **색 복원 비주얼(기술)**: 화면 전체에 CanvasLayer + ColorRect 셰이더를 씌우고 `hint_screen_texture`로 화면을 샘플링합니다. 처리는 그레이스케일 → `color_mask` 텍스처(SubViewport에 원형 브러시·오브젝트 실루엣을 그림) → `mix(gray, color, mask)` 순서입니다. 감정별로 **색상(Hue) 대역 선택 복원**(파랑 잔향은 파랑 대역만 복원)을 지원하고, 챕터 진행도에 따른 전역 채도 uniform을 둡니다.
- **색각 이상 대응(필수)**: 모든 감정 색에 **모양·패턴 기호**를 병행 표기합니다(파랑=물결, 노랑=해, 보라=별, 주황=불꽃, 초록=잎). 색약 모드에서는 Hue 대역을 재매핑하고, 퍼즐은 색 대신 기호로도 풀 수 있게 합니다.

### 2-4. 분량 산정(추정)
| 항목 | 추정치 |
|---|---|
| 씬(장면) | 프롤로그 4 + 챕터당 8~12 → 약 55씬 + 엔딩 5 |
| 대사 | 약 3,000줄(한국어 4만~5만 자) |
| 배경 | 고유 장소 30~35곳 × (흑백 + 채색 레이어) |
| 캐릭터 | 주인공 2명(4방향 보행·상호작용 스프라이트, 초상 12감정), NPC 10~12명 |
| 오디오 | BGM 15~20곡, SFX 80~120개 |
| 플레이타임 | 1회차 6~9시간, 전 엔딩 15~20시간 |

### 2-5. 장르 레퍼런스에서 배울 점(모방 금지, 원리만)
- **GRIS**: 색 하나가 회복될 때마다 이동 능력이 하나 늘어나는 구조. '감정 색 = 능력 해금'으로 차용합니다.
- **Hue**: 색이 퍼즐 규칙 자체가 되는 방식. 단, 색각 이상 접근성 문제를 반면교사로 삼습니다.
- **Chicory**: 플레이어가 직접 칠하는 쾌감. 정원 꾸미기에 제한적으로 차용합니다.
- **To the Moon**: 기억을 역순으로 탐색하는 서사와 적은 시스템으로 큰 감정을 만드는 방식.
- **Brothers**: 두 캐릭터 조작 자체가 서사가 되는 구조. 동시 조작 퍼즐에 차용합니다.
- **Unpacking**: 물건만으로 인물사를 말하는 방식. 다락방·방 탐색에 차용합니다.
- **Spiritfarer**: 돌봄 루프와 이별 엔딩의 톤. 희생 엔딩에 참고합니다.

---

## ③ 엔진 추천과 기술 스택

### 3-1. 비교(2026년 11월 기준)
| 후보 | 최신/라이선스 | 이 게임 적합성 | 색 복원 연출 | AI 에이전트 친화성 | 판정 |
|---|---|---|---|---|---|
| **Godot 4.7.x** | 4.7 안정판 2026-06-18, 패치 4.7.2(2026-08-18). MIT, 무료 [godotawesome](https://godotawesome.com/godot-4-7-features/) | 2D 탐색 + 시스템 + 분기 모두 적합 | 캔버스 셰이더·스크린 텍스처로 쉬움 | ★★★ 텍스트 씬·리소스, `--headless` 빌드/테스트, 공개 MCP 서버 다수 | **1순위** |
| Unity 6 | Personal은 매출·투자 20만 달러 미만이면 무료, Pro는 좌석당 연 2,310달러 [ai-game](https://ai-game.dev/blog/unity-pricing-unreal-royalties-2026) | 적합 | URP 2D + Shader Graph로 쉬움 | ★★ 공식 `unity mcp` CLI 무료, 보유 unity:* 스킬 다수. 단 YAML 씬·.meta 병합 충돌이 잦고 에디터 의존도가 높음 | **2순위** |
| Ren'Py 8.6 | 무료 [github](https://github.com/renpy/renpy/releases) | VN에는 최강이지만 탐색·정원 시스템에는 부적합 | 셰이더 지원 제한적 | ★★ 순수 텍스트 | 탈락 |
| RPG Maker MZ | 유료 | 탐색은 쉬우나 커스텀 시스템이 고통스러움 | 플러그인 의존 | ★ JSON이지만 에디터 중심 | 탈락 |
| Phaser/Canvas | 무료 | 기존 역량과 가장 가까움 | 직접 구현(WebGL) | ★★★ | 세이브·로컬라이즈·데스크톱 빌드를 직접 만들어야 해 범위 리스크가 큼 |
| GDevelop / Unreal | — | 과소 또는 과대 | — | ★ | 탈락 |

**Godot을 고르는 이유**
- **대안 대비 장점**
  - 씬·리소스가 사람이 읽을 수 있는 텍스트라서 에이전트가 에디터 없이 수정할 수 있습니다.
  - `godot --headless --export-release`와 gdUnit4로 CI를 짤 수 있습니다. gdUnit4는 Godot 4.5~4.7을 지원하고, 종료 코드 0/100/101을 반환하며, 공식 GitHub Action에 headless 옵션이 있습니다. [github](https://github.com/snackpackgames/Rubbley/issues/31) [github](https://github.com/godot-gdunit-labs/gdUnit4-action/pull/130)
  - 무료이고 MIT 라이선스입니다.
- **Unity 6가 유리한 점**: 보유 스킬이 많습니다. 다만 Unity의 기존 AI Assistant 내장 MCP 서버는 폐기(deprecated)됐고 Unity CLI의 `unity mcp`로 대체됐다는 점을 알고 쓰세요. [dev](https://dev.to/indiebots/unitys-mcp-server-is-deprecated-what-to-use-instead-2026-3khl) [unity3d](https://docs.unity3d.com/Packages/com.unity.ai.assistant@2.18/manual/integration/unity-mcp-get-started.html) [skillselion](https://skillselion.com/mcp/unity)
- **Godot의 약점**: Godot 전용 스킬이 [보유] 목록에 없습니다. W0에서 `godot-conventions` 스킬을 직접 만드는 WP(WP-03)로 보완합니다.

### 3-2. 확정 스택
- **엔진**: Godot 4.7.x 표준판(.NET 아님), GDScript 정적 타입 강제(`untyped_declaration` 경고를 에러로 처리)
- **대사**: Dialogue Manager 4(텍스트 `.dialogue`, Godot 4.6+). 대안은 Yarn Spinner for Godot(GDScript, 무료 오픈소스, Godot 4.6+, 아직 Early Access)입니다. [github](https://github.com/YarnSpinnerTool/YarnSpinner-Godot-GDScript) [yarnspinner](https://yarnspinner.dev/features/) [storyflow-editor](https://storyflow-editor.com/blog/best-godot-dialogue-systems/) Dialogic 2는 장기 알파 상태이고 비주얼 에디터 중심이라 에이전트 작업에 불리해 제외합니다. [storyflow-editor](https://storyflow-editor.com/blog/best-godot-dialogue-systems/)
- **Godot MCP [추가]**
  - Coding-Solo/godot-mcp: `claude mcp add godot -- npx @coding-solo/godot-mcp`. Codex에서도 같은 형식(`codex mcp add`)으로 연결됩니다. [github](https://github.com/Coding-Solo/godot-mcp) [ziva](https://ziva.sh/blogs/use-claude-or-chatgpt-with-godot)
  - 4.7+ 에디터 실시간 조작이 필요하면 godot-ai를 평가해 보세요. [gamedevaihub](https://gamedevaihub.com/best-godot-mcp-servers-claude-code/)
  - 한 프로젝트에는 하나만 연결합니다.
- **테스트·CI**: gdUnit4 + chickensoft-games/setup-godot + GitHub Actions(ubuntu). 입력 이벤트가 필요한 테스트는 xvfb로 분리합니다. [github](https://github.com/godot-gdunit-labs/gdUnit4Net/discussions/350) [github](https://github.com/snackpackgames/Rubbley/issues/31)
- **세이브**: `user://save_{slot}.json`(스키마 버전 필드 포함) + `user://persist.json`(엔딩 기록)
- **로컬라이즈**: Godot 번역 CSV/PO. 모든 UI 문자열은 `tr()` 키로 처리합니다.
- **폰트**: 갈무리(Galmuri, SIL OFL 1.1). 게임 내장·상업적 이용이 가능하고, 폰트 단독 판매만 금지됩니다. [noonnu](https://noonnu.cc/en/font_page/801) [taedonn](https://fonts.taedonn.com/post/Galmuri14) [github](https://github.com/quiple/galmuri/blob/main/ofl.md) 본문용 고딕은 OFL 계열을 별도로 선정합니다.

### 3-3. 폴더 구조와 코딩 규칙
```
/AGENTS.md  /CLAUDE.md(→AGENTS.md 참조)  /docs/{gdd,bible,adr,schemas,style}/
/game/autoload/ (GameState, SaveService, EchoBus)   /game/systems/{echo,garden,sibling,color}/
/game/scenes/{prologue,ch1..ch5,endings,ui}/   /game/dialogue/{prologue,ch1..ch5,endings}/*.dialogue
/game/art/{bg,char,ui,vfx}/   /game/audio/{bgm,sfx}/   /game/shaders/   /game/i18n/
/tests/{unit,flow}/   /tools/ (린터·변환 스크립트)   /.github/workflows/
```
- **네이밍**: 파일은 snake_case, 클래스는 PascalCase, 플래그는 `flag.<챕터>.<의미>`, 시그널은 과거형(`echo_collected`)으로 씁니다.
- **경계**: 시스템 간 통신은 `EchoBus` 시그널로만 합니다. 다른 시스템의 노드 경로를 직접 참조하면 금지입니다.
- **완료 조건**: 모든 PR은 gdUnit4 통과와 `tools/lint_names.py`(금지어·키 누락 검사) 통과가 필수입니다.

---

## ④ A~Z 전체 로드맵(마일스톤·게이트)

| 라벨 | 단계 | 게이트(완료 기준) |
|---|---|---|
| A | 콘셉트·디자인 필러 3개(감정=색 / 남매의 재발견 / 상실 후의 따뜻함) | 한 장짜리 피치 |
| B | 기획 확정(②의 보강안 승인) | **G0**: 설정 확정본에 사람(개발자) 서명 |
| C | GDD | 시스템별 규칙·수치 표 완성 |
| D | 내러티브 바이블(인물, 세계 규칙 W-FACE, R-NAME) | 금지어 목록 확정 |
| E | 분기 설계(플래그 사전, 엔딩 조건) | 시뮬레이터로 5엔딩 모두 도달 가능 |
| F | 아트 디렉션·스타일 가이드(팔레트, 해상도 480×270 픽셀아트 권장) | 레퍼런스 보드 + 기준 에셋 5종 |
| G | 오디오 디렉션 | 무드 레퍼런스, 테마 모티프 1개 |
| H | 기술 아키텍처·계약(스키마·인터페이스) | **G1**: 계약 문서 동결(v1.0) |
| I | 저장소·CI·워크트리 셋업 | 빈 프로젝트에서 CI 녹색 |
| J | 프로토타입: 잔향 감지 + 색 복원 | **G2**: 셀프 플레이 5분이 "재밌다" + 외부 3인 테스트 |
| K | 프로토타입 회고·범위 재조정 | 스코프 컷 목록 갱신 |
| L | 버티컬 슬라이스: 프롤로그~챕터 1(출시 품질) | **G3**: 20~30분 데모, 크래시 0 |
| M | 코어 시스템 완성(정원, 남매, 세이브, 분기) | 시스템 테스트 커버리지 |
| N~Q | 챕터 2·3·4·5 + 엔딩 5종 콘텐츠 | 챕터별 "콘텐츠 완료" 체크 |
| R | 알파(전 챕터 플레이 가능, 임시 에셋 허용) | **G4**: 처음부터 끝까지 진행 가능 |
| S | 베타(외부 플레이테스트 2회, 밸런스, 버그) | **G5**: P0/P1 버그 0 |
| T | 폴리싱(연출, 게임필) | — |
| U | 접근성(색각 모드, 자막 크기, 리듀스 모션, 키 리맵) | 접근성 리뷰 통과 |
| V | 로컬라이제이션(한국어 확정 → 영어 선택) | 키 누락 0 |
| W | 빌드·릴리스 파이프라인(itch butler, 스팀) | 태그를 찍으면 자동 배포 |
| X | 스토어 페이지·트레일러·마케팅 | **G6**: 스토어 공개, 찜/팔로우 수집 |
| Y | 출시 | **G7**: 출시 체크리스트 100% |
| Z | 사후 지원(핫픽스, 패치 노트, 회고) | 30일 회고 문서 |

**기간 추정(학업 병행, 주 15~20시간, 범위)**

| 구간 | 기간 |
|---|---|
| A~I | 1~2개월 |
| J~K | 1~2개월 |
| L | 2~3개월 |
| M~Q | 9~15개월 |
| R~V | 3~5개월 |
| W~Y | 1~2개월 |
| **총계** | **약 18~30개월** |

공모전에 맞추면 이렇게 됩니다(아래 ⑨ 참고). 버티컬 슬라이스(G3)를 **BIC 루키 접수(예년 4~6월)**에 맞추고, 알파 데모를 **GIGDC 중·고등부 제작 부문(예년 6월 접수)**에 맞추는 것이 이상적입니다. [bicfest](https://bicfest.org/enroll/information) [thisisgame](https://www.thisisgame.com/articles/425641)

---

## ⑤ 병렬 트랙과 의존성·웨이브

### 5-1. 11개 트랙
T1 기획/내러티브 · T2 엔진 코어 · T3 게임플레이 시스템 · T4 아트(배경/캐릭터) · T5 VFX/셰이더 · T6 오디오 · T7 대사 스크립트·분기 데이터 · T8 UI/UX · T9 QA/테스트 자동화 · T10 빌드/배포 · T11 마케팅/스토어

### 5-2. 먼저 고정할 '계약'(이게 없으면 병렬화가 깨짐)
1. `docs/bible/canon_v1.md`: 설정 확정본, R-NAME, W-FACE
2. `docs/schemas/`: `flags.schema.json`, `echo.schema.json`(id, 감정, 색, 기호, 위치), `save.schema.json`, `dialogue_conventions.md`(태그·화자 키)
3. `docs/style/art_style.md` + `palette.gpl`: 팔레트, 해상도, 외곽선 규칙
4. `docs/ownership.md`: 트랙별 쓰기 가능 경로
5. `AGENTS.md`: 빌드·테스트 명령, 금지 사항, 완료 정의

### 5-3. 웨이브
| 웨이브 | 동시 실행 묶음 | 선행 조건 |
|---|---|---|
| **W0 계약** | WP-01 설정 확정, WP-02 스키마, WP-03 저장소+CI+스킬, WP-04 스타일 가이드, WP-05 셰이더 스파이크 | 없음 |
| **W1 기반** | WP-06 GDD, WP-07 분기 시뮬레이터, WP-08 GameState/Save, WP-09 EchoBus·입력, WP-10 아트 기준 에셋, WP-11 오디오 디렉션 | G0, G1 |
| **W2 프로토타입** | WP-12 잔향 감지, WP-13 색 복원 통합, WP-14 공명 퍼즐 1종, WP-15 테스트 하네스 | W1 |
| **W3 버티컬 슬라이스** | WP-16~WP-22(프롤로그·챕터 1 대사/씬/아트/오디오/UI, 정원 v1, 남매 전환) | G2 |
| **W4 프로덕션** | 챕터 2~5 파이프라인(WP-23~WP-34)을 **챕터 단위로 시간차 병렬 진행**: 대사(N+1) ∥ 아트(N) ∥ 통합(N−1) | G3 |
| **W5 알파→베타** | WP-35~WP-38(엔딩 검증, 접근성, 로컬라이즈, 플레이테스트) | 전 챕터 통합 |
| **W6 출시** | WP-39~WP-42(파이프라인, 스토어, 트레일러, 출시 체크) | G5 |

**크리티컬 패스**: WP-01 → WP-02 → WP-05/13(색 복원) → WP-12(잔향) → G2 → W3 → 각 챕터 대사의 **사람 검수** → WP-35(엔딩 분기 검증) → 베타 → 출시.
병목은 사람의 검수 시간입니다. 그래서 대사 초안은 항상 한 챕터 앞서 미리 생성해 둡니다.

---

## ⑥ 작업 패키지 카드

### 6-1. 공통 프롬프트 템플릿(모든 WP에 붙여 넣기)
```
너는 「공허의 화가: 잔향의 색」(Godot 4.7, GDScript) 프로젝트의 [에이전트 역할]이다.
먼저 AGENTS.md, docs/bible/canon_v1.md, docs/schemas/, docs/ownership.md를 읽어라.
작업: [WP 목표]. 입력: [입력 문서]. 산출물: [경로·형식].
규칙: (1) ownership.md에서 [트랙]에 허용된 경로만 수정 (2) 진실 공개 전 본명 표기 금지(R-NAME)
(3) 스키마를 바꿔야 하면 수정하지 말고 docs/adr/에 제안서만 작성 (4) 완료 전 `tools/ci_local.sh` 실행 후 결과 첨부
(5) 추측한 사실은 'TODO-확인'으로 표시. 완료 기준: [검증 방법]. 끝나면 변경 요약·미해결 질문·다음 WP 제안을 보고하라.
```

### 6-2. 카드 목록
(형식: 목표·산출물 | 의존 → 병행 가능 | 에이전트·툴/스킬/커넥터 | 완료 기준 | 소요 | 프롬프트 핵심)

| ID | 목표·산출물 | 의존→병행 | 에이전트 / 툴·스킬·커넥터 | 완료 기준 | 소요 |
|---|---|---|---|---|---|
| WP-01 | 설정 확정본 `docs/bible/canon_v1.md` | 없음 → 02,03,04,05 | Claude(agentic-council:council·Skeptic) / superpowers:brainstorming, mattpocock-skills:grill-me, Notion | 개발자 서명, ② 표 6건 해결 | 2~3일 |
| WP-02 | 스키마 3종 + 대사 규약 `docs/schemas/` | 01 초안 → 03,04,05 | Plan / agent-protocols:spec, spec-driven-development, documentation-and-adrs | JSON Schema 검증 통과, 예제 파일 | 2일 |
| WP-03 | 저장소, LFS, CI, AGENTS.md, `godot-conventions` 스킬 [추가 제작] | 없음 → 전부 | Codex 또는 general-purpose / git-workflow-and-versioning, ci-cd-and-automation, Context7(Godot 문서) | 빈 프로젝트 CI 녹색, 워크트리 스크립트 | 2일 |
| WP-04 | 아트 스타일 가이드 + 팔레트 | 01 → 02,03,05 | Artisan / Figma(figma-generate-library), design:design-system, vectorlab colour-palette | 기준 이미지 5장 승인 | 3일 |
| WP-05 | 색 복원 셰이더 스파이크 `game/shaders/color_restore.gdshader` | 03 → 04 | general-purpose(worktree) / Godot MCP [추가], Context7, superpowers:test-driven-development | 마스크·Hue 대역 복원 데모 씬, 60fps | 2~3일 |
| WP-06 | GDD `docs/gdd/*.md` | G0 → 07~11 | Plan / product-management:write-spec, Notion, anthropic-skills:docx(제출용) | 시스템별 수치표 | 4일 |
| WP-07 | 분기 시뮬레이터 `tools/branch_sim.py` | 02 → 06,08 | test-engineer / Python, superpowers:test-driven-development | 5엔딩 도달 경로 자동 출력 | 2일 |
| WP-08 | GameState·SaveService 오토로드 | 02 → 09,10 | Codex(worktree) / gdUnit4 [추가], tdd | 세이브 왕복 테스트 | 3일 |
| WP-09 | EchoBus·입력 맵·태그 전환 골격 | 02 → 08 | Claude 서브에이전트(worktree) / Godot MCP | 시그널 계약 테스트 | 2일 |
| WP-10 | 주인공 2명·NPC 스케치 기준 에셋 | 04 → 08,09 | Artisan / Aseprite [추가], creativeclaw-create-character(콘셉트용), image-generation | 스타일 가이드 준수 리뷰 | 1주 |
| WP-11 | 오디오 디렉션 + 테마 모티프 | 01 → 전부 | general-purpose / creativeclaw-generate-music, social-media-skills:suno(스케치), Audacity [추가] | 30초 모티프 3안 중 1개 선정 | 3일 |
| WP-12 | 잔향 감지(홀드 스캔·윤곽) `systems/echo/` | 05,09 → 13,14 | Codex / Godot MCP, tdd | 테스트 씬에서 잔향 5개 감지 | 4일 |
| WP-13 | 색 복원 통합(진행도·감정별) | 05,12 → 14 | Claude(worktree) / systematic-debugging | 잔향 획득 시 해당 Hue만 복원 | 3일 |
| WP-14 | 공명 퍼즐 1종 | 12 → 13 | Codex / prototype(mattpocock) | 기호만으로도 풀이 가능 | 3일 |
| WP-15 | 테스트 하네스·린터(R-NAME 금지어, tr 키) | 02,03 → W2 전부 | test-engineer / gdUnit4-action, claude-security | CI에 연결 | 2일 |
| WP-16 | 프롤로그 대사 `dialogue/prologue/` | G2 → 17~22 | Chronicler / doc-coauthoring, design:ux-copy | 사람 검수 + 린트 통과 | 3일 |
| WP-17 | 챕터 1 대사(하늘·별 파트, 광장) | 16 → 18~22 | Chronicler / 동일 | 위화감 연출 3종 반영 | 5일 |
| WP-18 | 프롤로그·챕터 1 배경(화실, 집, 광장, 흑백+채색) | 04 → 16,17 | Artisan / Aseprite, LDtk 또는 Godot TileMap, krea-generate(레퍼런스 한정) | 레이어 분리 규칙 준수 | 2주 |
| WP-19 | 프롤로그·챕터 1 씬 조립·이벤트 | 12,13,16 → 18,20 | Codex(worktree) / Godot MCP | 처음부터 끝까지 플레이 가능 | 1주 |
| WP-20 | 정원 v1(심기·성장·조합표) | 08,09 → 19 | Claude(worktree) / tdd | 조합표 데이터 주도, 테스트 | 1주 |
| WP-21 | 대사 UI·타자기·초상·자막 설정 | 09 → 19 | general-purpose / frontend-design, design:accessibility-review, Figma | 글자 속도·크기 옵션 | 4일 |
| WP-22 | VS 오디오(BGM 3, SFX 30) | 11 → 18~21 | general-purpose / creativeclaw-generate-sound-effects, jsfxr [추가], unity 없음 | 라우드니스 기준 −16 LUFS(권장) | 1주 |
| WP-23/24 | 챕터 2 대사 / 아트(카페, 놀이공원, 다락방) | G3 → 25 | Chronicler / Artisan | R-NAME 린트 0건 | 2주/3주 |
| WP-25 | 챕터 2 통합 + 사이드 재결합 퀘스트 1~2 | 23,24 → 26 | Codex(worktree) | 플래그 시뮬 통과 | 1~2주 |
| WP-26/27/28 | 챕터 3 대사 / 아트(진짜 작업실, 그 아이의 방) / 통합(정원 공명·'가족의 꽃' 조건) | 25 → 29 | 동일 + performance-engineer | 공명 이벤트 테스트 | 각 2~3주 |
| WP-29/30/31 | 챕터 4 대사(기억의 폭풍, 감정 충돌 4종) / 아트(가족사진 잔향 연출) / 통합(본명 전환 `truth_revealed`) | 28 → 32 | 동일 / remotion 아님, 인게임 컷신 | 본명 전환 전후 스냅샷 테스트 | 각 2~3주 |
| WP-32 | 챕터 5 대사·최종 선택 | 31 → 33,34 | Chronicler + Skeptic 리뷰 | 성향 확인 대화 3분기 | 2주 |
| WP-33a~e | 엔딩 5종(보호·치유·가족·기적·희생) 각 대사+연출 | 32 → 서로 병렬 | Chronicler ×2 + Artisan / creativeclaw-generate-music(엔딩 테마) | 조건별 자동 도달 테스트 | 각 1주 |
| WP-34 | 챕터 5 아트·통합·크레딧 | 32 → 33 | Codex(worktree) | 5엔딩 모두 플레이 가능 | 2~3주 |
| WP-35 | 엔딩 분기 검증·밸런스 | 33,34 → 36,37 | test-engineer / branch_sim + gdUnit4 flow 테스트 | 5엔딩 × 대표 경로 통과 | 1주 |
| WP-36 | 접근성(색각 모드, 기호, 리듀스 모션, 리맵) | R → 37 | accessibility-specialist / vectorlab reduced-motion, design:accessibility-review | 체크리스트 100% | 1~2주 |
| WP-37 | 로컬라이즈(영어 선택) | R → 36 | general-purpose / zizi-skills:i18n | 키 누락 0, 길이 초과 0 | 2~3주 |
| WP-38 | 플레이테스트 운영(설문, 로그) | R → 35 | general-purpose / Supabase(익명 이벤트 로그, 선택), Gmail, Notion DB | 2회 × 8명 이상 | 3주 |
| WP-39 | 릴리스 파이프라인(itch butler, 웹/Windows) | G5 → 40~42 | release-engineer / ci-cd-and-automation, shipping-and-launch, Cloudflare(웹 미러, 선택), hawkscan(웹 빌드) | 태그 → 자동 업로드 | 3일 |
| WP-40 | 스토어 페이지·캡슐 아트·SEO 문구 | G3부터 상시 → 39 | Advocate / marketing:content-creation, thumbnail-design, OpenRush(키워드, 선택) | 페이지 공개 | 1주 |
| WP-41 | 트레일러(60~90초) | L 이후 → 40 | general-purpose / remotion:remotion-create, ai-video-editor:video-editing, codesign:launch-video | 1080p, 자막 포함 | 1주 |
| WP-42 | 출시 체크·AI 공개 문구·등급 확인 | 39 → 없음 | security-auditor + 개발자 / deploy-checklist, pr-launch-pack, Gamma(보도자료) | ⑨ 체크리스트 완료 | 3일 |

### 6-3. 대표 프롬프트 3개(템플릿 아래에 덧붙여 사용)
- **WP-05**: "`game/shaders/color_restore.gdshader`와 데모 씬 `game/scenes/dev/color_demo.tscn`을 만들어라. CanvasLayer 위 ColorRect에서 `hint_screen_texture`를 샘플링해 휘도 기반 그레이스케일로 바꾼 뒤, SubViewport에 그린 `color_mask`와 `restore_hue_ranges`(배열 uniform) 안의 색상만 원색으로 복원하라. 마우스로 마스크를 칠하는 디버그 모드를 넣고, 성능을 측정해 보고하라."
- **WP-17**: "`dialogue/ch1/*.dialogue`에 챕터 1 대사를 작성하라. 하늘 파트(화실, 그리움의 파랑), 별 파트(정원, 온기의 노랑), 광장 첫 만남을 쓴다. '같은 말 동시에 하기' 2회와 '닮은 습관' 연출 태그 `[#sync]`를 넣어라. 화자는 `haneul`/`byeol` 키만 쓰고 표시 이름은 `name_display`를 따른다. 회당 40줄 이하로 나눠라."
- **WP-33e(희생)**: "희생 엔딩 대사와 연출 큐를 작성하라. 조건은 docs/gdd/endings.md의 표를 따른다. 누가 색을 바칠지는 `protect`/`heal` 우세로 분기하고 대사 변형은 2개다. 톤은 Spiritfarer식 담담한 이별이다. 15세 이용가 기준을 넘는 표현은 쓰지 마라."

---

## ⑦ 전체 도구 매트릭스

| 도구 | 용도 | 단계 | 상태 | 비용·설치·라이선스 주의 |
|---|---|---|---|---|
| Claude Code(서브에이전트, 워크트리) | 구현·리뷰·오케스트레이션 | 전 단계 | [보유] | — |
| OpenAI Codex | 병렬 구현(앱 내장 워크트리) | H~Y | [보유] | AGENTS.md를 읽음 [intuitionlabs](https://intuitionlabs.ai/articles/openai-codex-app-ai-coding-agents) [agentastic](https://www.agentastic.dev/blog/run-codex-agents-in-parallel) |
| superpowers:* / agent-protocols:* / mattpocock-skills:* | 계획·TDD·리뷰·워크트리·출시 | 전 단계 | [보유] | — |
| agentic-council / zizi-skills | 설정 검증, 오케스트레이션, i18n | A~E, V | [보유] | — |
| Notion | 작업 보드(WP DB), 결정 로그 | 전 단계 | [보유] | notion-spec-to-implementation으로 WP 생성 |
| Figma / FigJam | 의존성 그래프, UI·스타일 라이브러리 | E~F, UI | [보유] | figma-generate-diagram |
| Gamma | 공모전 발표자료·피치덱 | A, X | [보유] | — |
| Gmail | 플레이테스터·공모전 연락 | S, X | [보유] | — |
| Supabase | 플레이테스트 이벤트 로그(선택) | S | [보유] | 미성년자·개인정보 수집 최소화 |
| Cloudflare | 웹 빌드 미러·랜딩 페이지 | W~Y | [보유](인증 필요) | wrangler |
| Context7 / Microsoft Learn | Godot·라이브러리 최신 문서 | 전 단계 | [보유] | 에이전트 프롬프트에 "Context7로 확인" 명시 |
| Claude in Chrome | 스토어 페이지·웹 빌드 QA | S~Y | [보유] | — |
| 예약 작업 / 메모리 | 야간 CI 요약, 주간 회고 | 전 단계 | [보유] | — |
| 이미지·음악·영상 생성 스킬(creativeclaw, krea, suno, remotion 등) | 콘셉트, 임시 에셋, 트레일러 | F~X | [보유] | 출시 에셋으로 쓰면 스팀 AI 공개 대상. [assetforgeindex](https://assetforgeindex.com/guides/steam-ai-disclosure) 각 서비스의 상업 이용 약관 확인 필요 |
| unity:* 스킬 | 2순위 엔진 전환 시 | — | [보유] | Godot 채택 시 미사용 |
| **Godot 4.7.x** | 엔진 | 전 단계 | [추가] | 무료, MIT |
| **Godot MCP**(Coding-Solo/godot-mcp 등) | 에이전트의 실행·디버그 출력 확인 | H~Y | [추가] | 무료, `npx` 설치, Node 18+ [godotawesome](https://godotawesome.com/godot-mcp-claude-code-setup/) |
| **Dialogue Manager 4** | 대사·분기 | D~Q | [추가] | 무료, MIT |
| **gdUnit4 + gdUnit4-action, setup-godot** | 테스트·CI | H~Y | [추가] | 무료 [github](https://github.com/snackpackgames/Rubbley/issues/31) [github](https://github.com/MikeSchulze/gdUnit4-action) |
| **GitHub + Git LFS + Actions** | 버전 관리·CI | I~ | [추가](계정이 있으면 보유) | 개인 무료 한도 내에서 운영. LFS 용량 주의(추정) |
| **Aseprite** | 픽셀 아트·애니메이션 | F~T | [추가] | 유료(스팀 정가 19.99달러, Igara Studio, 2026년 11월 기준). 무료 대안은 LibreSprite, Pixelorama |
| **LDtk 또는 Tiled** | 맵 편집 | L~Q | [추가] | 무료. Godot TileMap만으로도 가능 |
| **Krita** | 일러스트·초상 | F~T | [추가] | 무료, GPL(산출물 이용 자유) |
| **Audacity, jsfxr, LMMS** | SFX·편집·작곡 | G~T | [추가] | 무료 |
| **갈무리 폰트** | 픽셀 UI 폰트 | F~ | [추가] | OFL 1.1. 라이선스 파일 동봉 필수 [designbase](https://designbase.co.kr/freefonts/galmuri9/) [github](https://github.com/quiple/galmuri/blob/main/ofl.md) |
| **itch.io + butler** | 1차 배포 | W~Z | [추가] | 무료. 판매하려면 성인 보호자가 정산 담당 [itch](https://itch.io/post/2595868) |
| **Steamworks** | 유료 출시 | Y | [추가] | 앱당 100달러, [steamgames](https://partner.steamgames.com/steamdirect) 보호자 명의 [trapster](https://www.trapster.gg/blog/how-to-publish-a-game-on-steam) |
| **플레이테스트 수집**(Google Forms/Notion 폼) | 설문 | S | [추가]/[보유] | 무료 |

마케팅 분석 커넥터 중 **OpenRush**는 스토어 키워드 조사에 선택적으로 씁니다. Supermetrics, Bigdata.com, Crypto.com은 게임 개발과 무관하므로 제외합니다.

---

## ⑧ 1인 오케스트레이션 운영 규칙

1. **사람이 직접 하는 일(위임 금지)**
   - G0~G7 게이트 판정
   - 설정·엔딩·대사 최종 검수
   - 아트 스타일 승인
   - 스키마 변경 승인(ADR)
   - 출시·계약·결제
2. **동시 실행 수**: 평시 3개, 피크 5개.
   - Codex는 동시 스레드 기본 상한이 6이고, Claude Code는 서브에이전트를 백그라운드로 돌릴 수 있습니다. [claudemap](https://www.claudemap.org/en/guides/claude-code-subagents-deep-dive) [firecrawl](https://www.firecrawl.dev/blog/codex-multi-agent-orchestration)
   - 실제 병목은 도구가 아니라 **사람의 리뷰 처리량과 RAM**입니다. 에이전트당 8~10GB를 쓴다는 2차 보고도 있습니다. [danielvaughan](https://codex.danielvaughan.com/2026/04/18/running-multiple-codex-agents-parallel-orchestration/)
3. **격리**
   - 구현 에이전트는 반드시 `isolation: worktree`(Claude)나 Codex 워크트리로 돌립니다. [claude](https://code.claude.com/docs/en/sub-agents) [aakashx](https://www.aakashx.com/blog/parallel-claude-code-agents/) [verdent](https://www.verdent.ai/guides/codex-app-worktrees-explained)
   - 워크트리 변경은 **자동 병합되지 않습니다**. 브랜치로 PR을 만들어 직접 병합합니다. [claudemap](https://www.claudemap.org/en/guides/claude-code-subagents-deep-dive)
4. **파일 소유권**: `docs/ownership.md`에 트랙별 쓰기 경로를 고정합니다. 공유 파일(`project.godot`, autoload, schemas)은 **통합 담당 세션 하나만** 수정합니다.
5. **단일 진실 원천**
   - 규칙은 `AGENTS.md`, 설정은 `canon_v1.md`, 데이터 계약은 `schemas/`에 둡니다. [danielvaughan](https://codex.danielvaughan.com/2026/04/18/running-multiple-codex-agents-parallel-orchestration/) [agentastic](https://www.agentastic.dev/blog/run-codex-agents-in-parallel) `CLAUDE.md`는 AGENTS.md를 가리키기만 합니다.
   - Notion은 "상태판" 역할만 합니다. 사실의 원천은 항상 저장소입니다.
6. **통합 주기**
   - 매일: 작은 PR 병합
   - 주 1회: '통합의 날'(전 브랜치 정리, 풀 플레이스루, 회고)
   - 웨이브 종료: 게이트 판정
7. **검증 루프**
   - 모든 WP는 "CI 통과 + code-reviewer 서브에이전트 리뷰 + superpowers:verification-before-completion"을 거칩니다.
   - "완료했다"는 보고만으로는 병합하지 않습니다. 콘텐츠 WP는 린터와 분기 시뮬레이터로 검증합니다.
8. **스타일 일관성**: 아트 에이전트에게 매번 `art_style.md`, 팔레트 파일, 기준 이미지 3장을 입력으로 줍니다. 결과물은 팔레트 양자화 스크립트(`tools/quantize.py`)로 강제 정규화합니다.

---

## ⑨ 출시·법적 체크(한국, 미성년 1인 개발자)

| 항목 | 확인 내용 | 판단 |
|---|---|---|
| 비영리 공개 | 2019-09-03부터 개인·동호회가 비영리 단순 공개 목적으로 만든 게임은 등급분류가 면제됩니다(청소년이용불가 내용은 제외). [mcst](https://www.mcst.go.kr/site/s_notice/press/pressView.jsp?pSeq=17434) 단, 수익 배분 마켓 유통, 결제, 광고, '후원하기' 중 하나라도 있으면 영리로 판단합니다(GRAC 답변). [inven](https://www.inven.co.kr/webzine/news/?news=227071&site=indie) [namu](https://namu.wiki/w/%EA%B2%8C%EC%9E%84%EB%AC%BC%EA%B4%80%EB%A6%AC%EC%9C%84%EC%9B%90%ED%9A%8C/%EC%8B%AC%EC%9D%98%20%EA%B3%BC%EC%A0%95) | itch.io 무료 공개 시 결제·후원을 끄면 면제 범위에 해당할 가능성이 높습니다 |
| 수수료 면제 | GRAC는 사업자등록이 없는 개인 개발자의 비영리 게임(전체~15세)에 등급분류 수수료를 면제합니다. 간소화 시스템을 거치면 자동 적용됩니다. [deu](https://ee.deu.ac.kr/game/sub06_03.do?mode=view&articleNo=48464&article.offset=0&articleLimit=10) [gcon](https://www.gcon.or.kr/gcon/bbs/B0000004/view.do?nttId=10390&menuNo=200064&pageIndex=1) | 필요하면 신청 |
| 스팀 | 앱당 100달러. 조정 총수익 1,000달러 이후 환급되고, [steamgames](https://partner.steamgames.com/steamdirect) [steampageanalyzer](https://www.steampageanalyzer.com/blog/steam-direct-fee-explained) 은행·세금 정보와 신원 확인을 마쳐야 출시할 수 있습니다. [steamgames](https://partner.steamgames.com/doc/gettingstarted/faq) [trapster](https://www.trapster.gg/blog/how-to-publish-a-game-on-steam) 2차 보도에 따르면 스팀은 자체등급분류사업자가 아니라 국내 유료 출시 시 등급분류가 필요할 수 있습니다(2026년 현황은 미확인). [thisisgame](https://www.thisisgame.com/articles/185399) [inews24](https://www.inews24.com/view/1435322) | 계약·세금 서류는 **보호자 명의**로 처리 [steamcommunity](https://steamcommunity.com/discussions/forum/1/3118160027728867568) [steamcommunity](https://steamcommunity.com/discussions/forum/7/1762481957323838036) |
| 스토브인디 | 스마일게이트 스토브는 2022년 7월 20일 자체등급분류 자격을 취득했고, 재지정으로 2026년 3월 3일~2031년 3월 2일까지 유지됩니다(서울경제TV·일간투데이 보도). 청소년이용불가 등급은 여전히 GRAC 심의 대상입니다. 수수료 15%는 출처 불명의 계약서 사본에서만 확인됐고, 미성년자 등록 정책은 미확인입니다. [lawinsider](https://www.lawinsider.com/ko/contracts/jbI92yJpi1l) | store.biz@smilegate.com에 문의 |
| itch.io | 게시자는 18세 이상이거나 보호자 동의가 있어야 합니다. 판매하려면 성인이 계정 재정을 관리해야 하며, 세금 양식과 정산 계정도 18세 이상 명의여야 합니다. 무료 업로드는 13세 이상이면 가능합니다. [itch](https://itch.io/post/2595868) [itch](https://itch.io/t/1584786/question-about-age-requirements) [itch](https://itch.io/docs/legal/terms) | 1차 출시 경로로 적합 |
| AI 공개 | Valve는 2026년 1월 16일 Content Survey 문구를 개정해 "efficiency gains through the use of these tools are not the focus of this section"이라고 밝혔고, 코드 보조 같은 개발 도구는 공개 대상에서 빠졌습니다(PC Gamer·Game Developer 보도). 반면 **플레이어가 소비하는 사전 생성 콘텐츠**(아트, 사운드, 서사, 현지화, 마케팅 자료)는 공개해야 합니다. | AI 생성물을 쓴 에셋 목록을 `docs/ai_usage.md`에 상시 기록 |
| 공모전 | **BIC 2026**: 루키 접수 4/8~6/17 오후 3시, 만 14세 이상이면서 학생 또는 2002년 이후 출생 미취업자로만 구성, 빌드 2GB 미만. 오프라인은 8/14~16 벡스코. **GIGDC 2026**: 접수 6/8~6/25 오후 3시(한국콘텐츠진흥원 주최, 5개 부문, 부문별 대상에 문체부 장관상), 중·고등부(학교 밖 청소년 포함), 개인 또는 10인 이하. 시상은 11/10 게임데이즈였고, 고등학생 장원혁(Zang)이 1인 개발로 시작한 '던킵(Dawnkeep)'이 BIC 2026 루키에 이어 GIGDC 2026 중고등부 제작 부문 동상을 받았습니다(인디게임닷컴). | 2027년 일정은 미발표이므로 2026년 패턴으로 계획(추정) [citcoding](https://citcoding.com/competitions/international-game-development-competitions.html) |

**추천 경로**: G3 데모를 itch.io에 무료 공개 → BIC 루키 출품 → 알파로 GIGDC 중·고등부 제작 부문 출품 → 성인 또는 보호자 명의로 스팀(혹은 스토브) 유료 출시 → 비영리 버전 유지 여부를 결정합니다.

---

## ⑩ 리스크·스코프 컷

| 리스크 | 대응 |
|---|---|
| 5챕터·5엔딩 범위 과다 | 엔딩 5종은 **공통 연출 + 대사 변형**으로 만들어 신규 에셋을 최소화합니다 |
| 컨텍스트 불일치(에이전트마다 설정이 다름) | 모든 프롬프트에 canon·schemas 필독을 명시하고, 금지어 린터로 막습니다 |
| 병합 충돌 | 소유권 표, 통합 담당 세션 1개, 작은 PR로 대응합니다 |
| 검증 없는 "완료" 보고 | CI + 리뷰 서브에이전트 + 사람 플레이 확인을 거쳐야 병합합니다 |
| AI 아트 화풍 불일치 | AI 생성은 **레퍼런스·콘셉트용**으로 한정하고, 최종 픽셀은 직접 그리거나 수정합니다. 팔레트를 양자화하고 기준 이미지와 대조해 리뷰합니다 |
| 학업 공백·번아웃 | 웨이브 단위로 쉬어도 저장소 문서만으로 재개할 수 있게 핸드오프 문서(mattpocock-skills:handoff)를 씁니다 |

**스코프 컷 우선순위(먼저 자르는 순)**
1. 영어 로컬라이즈
2. 사이드 가족 재결합 퀘스트 수(6 → 3)
3. 공명 퍼즐 종류(5 → 3)
4. 정원 조합 수
5. NPC 초상화를 스케치 얼굴로 통일

**자르면 안 되는 것**: 색 복원 연출, 남매 위화감 연출, 5엔딩, 색각 접근성.

---

## ⑪ "지금 바로 시작" 체크리스트(Wave 0)

- [ ] (사람, 1일차) ② 표 6건을 결정하고 R-NAME·W-FACE·H.S 재정의 승인
- [ ] 동시에 띄울 에이전트 5개
  1. **WP-01**: Claude + agentic-council:council로 canon_v1 초안 작성, Skeptic이 모순 검토
  2. **WP-02**: Plan 에이전트로 스키마 3종 + 대사 규약 작성
  3. **WP-03**: Codex로 저장소·LFS·CI·AGENTS.md·워크트리 스크립트 구축, `godot-conventions` 스킬 초안
  4. **WP-04**: Artisan + Figma로 스타일 가이드·팔레트·기준 이미지 5장 제작
  5. **WP-05**: Claude 서브에이전트(isolation: worktree)로 색 복원 셰이더 스파이크
- [ ] Godot 4.7.x, Godot MCP, gdUnit4, Dialogue Manager 4 설치([추가])
- [ ] Notion에 WP 데이터베이스 생성(ID·트랙·웨이브·상태·소유 경로)
- [ ] 예약 작업으로 야간 CI 요약을 메모리/Notion에 기록
- [ ] 주말: G0·G1 판정 → Wave 1 시작