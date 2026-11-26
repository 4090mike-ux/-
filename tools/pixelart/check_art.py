#!/usr/bin/env python3
"""game/art/ 아래 모든 PNG 가 팔레트(docs/style/palette.gpl) 색만 쓰는지 검사한다.

검사 항목
  1. 알파 0 이 아닌 픽셀의 RGB 는 팔레트 35색 중 하나여야 한다.
  2. 반투명 픽셀(0 < 알파 < 255)은 금지한다(합성되면 팔레트 밖 색이 생긴다). 단 game/art/vfx/ 는 예외.
  3. 감정 색 배치 규칙 (art_style.md §3·§5, --no-rules 로 끔)
     - bg/      : 감정 색·예약 빨강 0 픽셀 (배경은 중립색만. 감정 색은 잔향 소품 스프라이트에만)
     - char/npc_: 감정 색 0 픽셀
     - char/ 나머지, props/ : 한 파일에 감정 계열 1개까지
  4. 배경 메타데이터 game/art/bg/*.json (asset_manifest.md §4 형식)
     - 필수 키, 다각형 3점 이상, 좌표가 화면(480×270) 안
     - spawns 는 walkable 안 + blockers 밖, 각 출구 rect 는 walkable 과 겹침, 짝 PNG 존재

사용법
  python tools/pixelart/check_art.py            # 오류가 있으면 종료 코드 1
  python tools/pixelart/check_art.py --verbose  # 파일별 색 사용량
"""
from __future__ import annotations

import argparse
import json
import sys
from collections import Counter
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import palette as P  # noqa: E402

ART = P.ROOT / "game/art"


def check_file(path: Path, rules: bool) -> tuple[list[str], Counter]:
    errors: list[str] = []
    rel = path.relative_to(P.ROOT).as_posix()
    img = Image.open(path).convert("RGBA")
    counts: Counter = Counter()
    bad: Counter = Counter()
    partial = 0
    allow_partial = "/vfx/" in f"/{path.relative_to(ART).as_posix()}"
    for r, g, b, a in getattr(img, "get_flattened_data", img.getdata)():
        if a == 0:
            continue
        if a != 255 and not allow_partial:
            partial += 1
        name = P.RGB_TO_NAME.get((r, g, b))
        if name is None:
            bad[(r, g, b)] += 1
        else:
            counts[name] += 1
    for color, n in bad.most_common(5):
        errors.append(f"{rel}: 팔레트 밖 색 #{color[0]:02x}{color[1]:02x}{color[2]:02x} ({n}px)")
    if len(bad) > 5:
        errors.append(f"{rel}: 그 밖에 팔레트 밖 색 {len(bad) - 5}종")
    if partial:
        errors.append(f"{rel}: 반투명 픽셀 {partial}개 (알파는 0 또는 255 만)")

    if rules:
        sub = path.relative_to(ART).as_posix()
        families = {P.family(n) for n in counts if P.family(n) != "neutral"}
        emo_px = sum(n for k, n in counts.items() if P.family(k) != "neutral")
        if sub.startswith("bg/") and families:
            errors.append(f"{rel}: 배경에 감정/예약 색 {sorted(families)} {emo_px}px — 배경은 중립색만 쓴다")
        elif sub.startswith("char/npc_") and families:
            errors.append(f"{rel}: NPC 에 감정 색 {sorted(families)} — NPC 는 중립색만")
        elif (sub.startswith("char/") or sub.startswith("props/")) and len(families) > 1:
            errors.append(f"{rel}: 감정 계열이 {len(families)}개 {sorted(families)} — 한 파일에 1개까지")
        if "reserved" in families:
            errors.append(f"{rel}: 예약 빨강(reserved-*)은 무지개 꽃·히든 이벤트 전용")
    return errors, counts


def _in_poly(x: float, y: float, poly: list) -> bool:
    res = False
    j = len(poly) - 1
    for i in range(len(poly)):
        (xi, yi), (xj, yj) = poly[i], poly[j]
        if (yi > y) != (yj > y) and x < (xj - xi) * (y - yi) / (yj - yi) + xi:
            res = not res
        j = i
    return res


def check_meta(path: Path) -> list[str]:
    rel = path.relative_to(P.ROOT).as_posix()
    errs: list[str] = []
    try:
        m = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        return [f"{rel}: JSON 오류 {e}"]
    for k in ("walkable", "blockers", "spawns", "exits", "props", "notes"):
        if k not in m:
            errs.append(f"{rel}: 키 '{k}' 없음")
    if errs:
        return errs
    if not path.with_suffix(".png").exists():
        errs.append(f"{rel}: 짝 PNG 없음")
    w, h = m.get("size", [480, 270])
    poly = m["walkable"]
    if len(poly) < 3:
        errs.append(f"{rel}: walkable 점이 3개 미만")

    def on_screen(x: float, y: float) -> bool:
        return 0 <= x <= w and 0 <= y <= h

    for x, y in poly:
        if not on_screen(x, y):
            errs.append(f"{rel}: walkable 점 ({x},{y}) 화면 밖")
    for b in m["blockers"]:
        if len(b) != 4 or not on_screen(b[0], b[1]) or not on_screen(b[0] + b[2], b[1] + b[3]):
            errs.append(f"{rel}: blocker {b} 형식/범위 오류")
    if "default" not in m["spawns"]:
        errs.append(f"{rel}: spawns.default 없음")
    for name, (x, y) in m["spawns"].items():
        if not _in_poly(x + 0.5, y + 0.5, poly):
            errs.append(f"{rel}: spawn {name} ({x},{y}) 가 walkable 밖")
        for bx, by, bw, bh in m["blockers"]:
            if bx <= x < bx + bw and by <= y < by + bh:
                errs.append(f"{rel}: spawn {name} ({x},{y}) 가 blocker {[bx, by, bw, bh]} 안")
    for ex in m["exits"]:
        x, y, ew, eh = ex["rect"]
        pts = [(x + i * ew / 4, y + j * eh / 2) for i in range(5) for j in range(3)]
        if not any(_in_poly(px, py, poly) for px, py in pts):
            errs.append(f"{rel}: exit {ex['name']} rect 가 walkable 과 겹치지 않음")
    for name, (x, y) in m["props"].items():
        if not on_screen(x, y):
            errs.append(f"{rel}: prop {name} ({x},{y}) 화면 밖")
    return errs


def main(argv: list[str] | None = None) -> int:
    P.utf8_stdout()
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--no-rules", action="store_true", help="감정 색 배치 규칙 검사를 끈다")
    ap.add_argument("--verbose", "-v", action="store_true")
    ap.add_argument("paths", nargs="*", help="검사할 PNG (기본: game/art/**/*.png)")
    args = ap.parse_args(argv)

    files = [Path(p).resolve() for p in args.paths] if args.paths else sorted(ART.rglob("*.png"))
    all_errors: list[str] = []
    for f in files:
        errs, counts = check_file(f, not args.no_rules)
        all_errors += errs
        if args.verbose:
            emo = {k: v for k, v in counts.items() if P.family(k) != "neutral"}
            print(f"{f.relative_to(P.ROOT).as_posix()}: {len(counts)}색, 감정 색 {sum(emo.values())}px {sorted(emo)}")
    metas = sorted((ART / "bg").glob("*.json")) if not args.paths else []
    for mp in metas:
        all_errors += check_meta(mp)
    for e in all_errors:
        print(f"오류: {e}")
    status = "실패" if all_errors else "통과"
    print(f"check_art: PNG {len(files)}개 + 배경 메타 {len(metas)}개 검사, 오류 {len(all_errors)}건 — {status}")
    return 1 if all_errors else 0


if __name__ == "__main__":
    sys.exit(main())
