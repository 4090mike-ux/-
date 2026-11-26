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
  5. 슬라이스 조사 지점 (slice_beats.md §2): 장면별 id 가 props 에 있고, 바닥 위·막힘 밖, 서로 24px 넘게 떨어짐.
     gate_rect 가 있는 배경(square_gate)은 바닥 채우기로 철문 퍼즐을 확인한다: 문이 닫히면 gate_latch·square_clock 에
     못 가고, 열면 갈 수 있다. gate_hold 와 from_* 스폰은 문 밖에서 닿는다.

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


# ------------------------------------------------------------------ 슬라이스 조사 지점 (docs/narrative/slice_beats.md §2)
# 엔진(chapter_scene.gd)은 장면 정의에 좌표가 없으면 props[<id>] 에 조사 대상·잔향을 둔다.
# 여기 적은 id 는 모두 '걸을 수 있는 바닥 위 + 막힘 밖'이어야 하고, 조사 지점끼리는 반경 24px 보다 멀어야 한다.
SLICE_ECHOES = {"atelier_brush", "atelier_easel", "garden_pot", "garden_sprinkler", "path_lamp",
                "square_clock", "square_bench"}
SLICE_PROPS: dict[str, list[str]] = {
    "atelier": ["sofa", "window", "palette", "canvas", "sketchbook", "brushes", "coat", "atelier_brush", "atelier_easel"],
    "garden": ["flowers", "shed", "swing", "can", "pot", "fence", "garden_pot", "garden_sprinkler"],
    "atelier_door": ["mailbox", "lamp", "sign", "passerby"],
    "garden_gate": ["gate", "signpost", "town", "bird"],
    "lane": ["sweeper", "laundry", "cat", "puddle"],
    "path": ["tree", "sign", "butterfly", "wildflowers", "path_lamp"],
    "stairs": ["railing", "pots", "chalk", "view"],
    "market": ["vendor", "apples", "cloth", "bakery"],
    "square": ["fountain", "board", "pigeons", "clock"],
    "square_night": ["clock", "board", "fountain", "bench"],
    "square_gate": ["square_clock", "square_bench", "gate_hold", "gate_latch", "clockface", "lamp", "plaque"],
}
INSPECT_RADIUS = 24.0
BOX_HALF_W, BOX_H = 6, 8      # 캐릭터 발 충돌 상자 12×8 (chapter_scene.gd)


def _in_blocker(x: float, y: float, blockers: list) -> bool:
    return any(bx <= x < bx + bw and by <= y < by + bh for bx, by, bw, bh in blockers)


def check_slice(name: str, m: dict) -> list[str]:
    errs: list[str] = []
    rel = f"game/art/bg/{name}.json"
    props, poly, blockers = m.get("props", {}), m.get("walkable", []), m.get("blockers", [])
    ids = SLICE_PROPS.get(name, [])
    for pid in ids:
        if pid not in props:
            errs.append(f"{rel}: 슬라이스 id '{pid}' 가 props 에 없음")
            continue
        x, y = props[pid]
        if not _in_poly(x + 0.5, y + 0.5, poly):
            errs.append(f"{rel}: props.{pid} ({x},{y}) 가 걸을 수 있는 바닥 밖")
        if _in_blocker(x, y, blockers):
            errs.append(f"{rel}: props.{pid} ({x},{y}) 가 blocker 안")
    spots = [(pid, props[pid]) for pid in ids if pid in props and pid not in SLICE_ECHOES]
    for i, (a, pa) in enumerate(spots):
        for b, pb in spots[i + 1:]:
            d = ((pa[0] - pb[0]) ** 2 + (pa[1] - pb[1]) ** 2) ** 0.5
            if 0 < d <= INSPECT_RADIUS:
                errs.append(f"{rel}: 조사 지점 {a}·{b} 사이 {d:.0f}px ≤ 반경 {INSPECT_RADIUS:.0f} (서로 헷갈림)")
    if "gate_rect" in m:
        errs += _check_gate(rel, m)
    return errs


def _reachable(m: dict, extra: list) -> set[tuple[int, int]]:
    """기본 스폰에서 발 위치로 갈 수 있는 정수 좌표 (4방향 채우기)."""
    poly = m["walkable"]
    w, h = m.get("size", [480, 270])
    blockers = m["blockers"] + extra
    inside = [[False] * w for _ in range(h)]
    for yy in range(h):
        xs = []
        n = len(poly)
        for i in range(n):
            (x0, y0), (x1, y1) = poly[i], poly[(i + 1) % n]
            if (y0 > yy + 0.5) != (y1 > yy + 0.5):
                xs.append(x0 + (yy + 0.5 - y0) * (x1 - x0) / (y1 - y0))
        xs.sort()
        for a, b in zip(xs[::2], xs[1::2]):
            for xx in range(max(0, int(a + 0.5)), min(w, int(b + 0.5))):
                inside[yy][xx] = True

    def ok(x: int, y: int) -> bool:
        if not (BOX_HALF_W <= x < w - BOX_HALF_W and BOX_H <= y < h):
            return False
        for cx, cy in ((x - BOX_HALF_W, y - BOX_H), (x + BOX_HALF_W - 1, y - BOX_H), (x - BOX_HALF_W, y - 1),
                       (x + BOX_HALF_W - 1, y - 1)):
            if not inside[cy][cx]:
                return False
        for bx, by, bw, bh in blockers:
            if x + BOX_HALF_W > bx and x - BOX_HALF_W < bx + bw and y > by and y - BOX_H < by + bh:
                return False
        return True

    sx, sy = m["spawns"]["default"]
    seen = {(sx, sy)} if ok(sx, sy) else set()
    stack = list(seen)
    while stack:
        x, y = stack.pop()
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if (nx, ny) not in seen and ok(nx, ny):
                seen.add((nx, ny))
                stack.append((nx, ny))
    return seen


def _near(reach: set, p: list, r: float) -> bool:
    px, py = p
    ri = int(r)
    return any((px + dx, py + dy) in reach for dx in range(-ri, ri + 1) for dy in range(-ri, ri + 1)
               if dx * dx + dy * dy <= r * r)


def _check_gate(rel: str, m: dict) -> list[str]:
    """철문 퍼즐: 문이 닫혀 있으면 안쪽(gate_latch·square_clock)에 못 가고, 열면 갈 수 있어야 한다."""
    errs: list[str] = []
    g = m["gate_rect"]
    props = m["props"]
    closed = _reachable(m, [g])
    opened = _reachable(m, [])
    if not _near(closed, props.get("gate_hold", [0, 0]), 20):
        errs.append(f"{rel}: 문이 닫힌 상태에서 gate_hold 에 닿을 수 없음")
    for pid in ("gate_latch", "square_clock"):
        if pid not in props:
            continue
        if _near(closed, props[pid], 20 if pid == "gate_latch" else 20):
            errs.append(f"{rel}: 문이 닫혀 있는데 {pid} 에 닿을 수 있음 (난간에 틈)")
        if not _near(opened, props[pid], 20):
            errs.append(f"{rel}: 문을 열어도 {pid} 에 닿을 수 없음")
    for name, sp in m["spawns"].items():
        if tuple(sp) not in closed and name != "default":
            errs.append(f"{rel}: 스폰 {name} 이 문 밖 영역과 이어지지 않음")
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
        try:
            all_errors += check_slice(mp.stem, json.loads(mp.read_text(encoding="utf-8")))
        except (json.JSONDecodeError, KeyError) as e:
            all_errors.append(f"{mp.name}: 슬라이스 검사 실패 {e}")
    for e in all_errors:
        print(f"오류: {e}")
    status = "실패" if all_errors else "통과"
    print(f"check_art: PNG {len(files)}개 + 배경 메타 {len(metas)}개 검사, 오류 {len(all_errors)}건 — {status}")
    return 1 if all_errors else 0


if __name__ == "__main__":
    sys.exit(main())
