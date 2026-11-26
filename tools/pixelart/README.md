# tools/pixelart — 코드로 그리는 픽셀아트 파이프라인

버티컬 슬라이스 아트(캐릭터·초상·NPC·잔향 소품·배경)를 파이썬 코드로 다시 만든다. 색은 `docs/style/palette.gpl` 의 이름으로만 쓴다.
에셋 목록·규격: [docs/style/asset_manifest.md](../../docs/style/asset_manifest.md)

```bash
pip install -r tools/requirements.txt        # Pillow>=11
python tools/pixelart/build_all.py           # game/art/ 의 PNG·JSON 전부 다시 만들기 (결정적)
python tools/pixelart/build_all.py --only char --only props   # 일부만 (char, portrait, npc, props, bg)
python tools/pixelart/check_art.py           # 팔레트 밖 색·반투명·감정 색 배치·배경 메타데이터·슬라이스 조사 지점·철문 퍼즐 검사
python tools/pixelart/preview.py             # 6배·흑백 미리보기 + 배경 목업 → tools/pixelart/_preview/ (커밋 안 함)
```

| 파일 | 하는 일 |
|---|---|
| `palette.py` | palette.gpl 로더(이름 → RGB), 휘도, 명도 계단(그림자·빛·밤) |
| `sprite.py` | ASCII 격자 → 스프라이트(글자별 legend, `.` = 투명), 외곽선, 반전, 시트 조립 |
| `canvas.py` | 배경용 그리기(사각형·선·다각형·타원·디더·명암)와 바닥 무늬(마루·벽돌·돌길·판석·잔디·기와) |
| `bgkit.py` | 배경 소품 도장(창·문·화분·나무·상자·가로등·벤치·차양…) |
| `chars.py` / `portraits.py` / `props.py` | 보행 시트·NPC·얼굴 오버레이 / 초상 / 잔향 소품 |
| `backgrounds.py` / `bg_town.py` | 배경 10종 + 메타데이터 json |

규칙: PNG 를 손으로 고치지 않는다(다음 빌드에서 덮어써진다). 무작위는 항상 seed 를 준 `random.Random` 을 쓴다.
