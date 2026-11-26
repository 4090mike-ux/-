#!/usr/bin/env python3
"""검수용 미리보기를 만든다. 결과는 커밋하지 않는 폴더(기본 tools/pixelart/_preview/)에 쓴다.

만드는 것
  <이름>_x6.png        원색 6배 (최근접). 스프라이트는 체크무늬 위에
  <이름>_gray_x6.png   흑백(Rec.709 휘도 = 셰이더와 같은 식) 6배
  _chars.png / _props.png        캐릭터·소품 모아 보기 (원색 | 흑백)
  mock_<배경>.png / mock_<배경>_gray.png   배경 + 소품(앵커) + 하늘·별(스폰) 3배
  mock_<배경>_debug.png          + 걸을 수 있는 영역(초록 선)·막힘(빨강)·출구(노랑) 표시

사용법
  python tools/pixelart/preview.py
  python tools/pixelart/preview.py --out C:/tmp/pv --scale 6
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
import palette as P  # noqa: E402

ART = P.ROOT / "game/art"
DEFAULT_OUT = Path(__file__).resolve().parent / "_preview"


def to_gray(img: Image.Image) -> Image.Image:
    img = img.convert("RGBA")
    out = Image.new("RGBA", img.size)
    out.putdata([
        (round(P.luma((r, g, b))),) * 3 + (a,) for r, g, b, a in getattr(img, "get_flattened_data", img.getdata)()
    ])
    return out


def checker(size: tuple[int, int], cell: int = 4) -> Image.Image:
    a, b = (170, 170, 176, 255), (196, 196, 202, 255)
    img = Image.new("RGBA", size, a)
    d = ImageDraw.Draw(img)
    for y in range(0, size[1], cell):
        for x in range(0, size[0], cell):
            if (x // cell + y // cell) % 2:
                d.rectangle([x, y, x + cell - 1, y + cell - 1], fill=b)
    return img


def on_checker(img: Image.Image) -> Image.Image:
    if img.getextrema()[3][0] == 255:  # 완전 불투명
        return img
    bg = checker(img.size)
    bg.alpha_composite(img)
    return bg


def up(img: Image.Image, k: int) -> Image.Image:
    return img.resize((img.width * k, img.height * k), Image.Resampling.NEAREST)


def side_by_side(imgs: list[Image.Image], gap: int = 4, bg=(60, 60, 64, 255)) -> Image.Image:
    w = sum(i.width for i in imgs) + gap * (len(imgs) + 1)
    h = max(i.height for i in imgs) + gap * 2
    out = Image.new("RGBA", (w, h), bg)
    x = gap
    for i in imgs:
        out.alpha_composite(i, (x, gap))
        x += i.width + gap
    return out


def stack(imgs: list[Image.Image], gap: int = 4, bg=(60, 60, 64, 255)) -> Image.Image:
    w = max(i.width for i in imgs) + gap * 2
    h = sum(i.height for i in imgs) + gap * (len(imgs) + 1)
    out = Image.new("RGBA", (w, h), bg)
    y = gap
    for i in imgs:
        out.alpha_composite(i, (gap, y))
        y += i.height + gap
    return out


def mock(bg_png: Path, meta: dict) -> tuple[Image.Image, Image.Image]:
    """배경 + 소품 + 캐릭터. (그림, 디버그 그림)"""
    scene = Image.open(bg_png).convert("RGBA")
    items: list[tuple[int, Image.Image, int, int]] = []
    for key, (x, y) in meta.get("props", {}).items():
        p = ART / "props" / f"{key}.png"
        if p.exists():
            s = Image.open(p).convert("RGBA")
            items.append((y, s, x - s.width // 2, y - s.height))
    spawn = meta.get("spawns", {}).get("default")
    if spawn:
        for i, who in enumerate(("haneul", "byeol")):
            sheet = ART / "char" / f"{who}_walk.png"
            if sheet.exists():
                f = Image.open(sheet).convert("RGBA").crop((0, 0, 24, 32))
                x, y = spawn[0] + (i * 22 - 11), spawn[1]
                items.append((y, f, x - 12, y - 32))
    for _, s, x, y in sorted(items, key=lambda t: t[0]):
        scene.alpha_composite(s, (x, y))
    dbg = scene.copy()
    d = ImageDraw.Draw(dbg)
    poly = [tuple(p) for p in meta.get("walkable", [])]
    if len(poly) > 2:
        d.line(poly + [poly[0]], fill=(60, 220, 90, 255))
    for x, y, w, h in meta.get("blockers", []):
        d.rectangle([x, y, x + w - 1, y + h - 1], outline=(230, 50, 50, 255))
    for ex in meta.get("exits", []):
        x, y, w, h = ex["rect"]
        d.rectangle([x, y, x + w - 1, y + h - 1], outline=(240, 220, 40, 255))
    for name, (x, y) in meta.get("spawns", {}).items():
        d.rectangle([x - 1, y - 1, x + 1, y + 1], fill=(40, 200, 240, 255))
    for name, (x, y) in meta.get("props", {}).items():
        d.point((x, y), fill=(255, 0, 255, 255))
    return scene, dbg


def main(argv: list[str] | None = None) -> int:
    P.utf8_stdout()
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--out", type=Path, default=DEFAULT_OUT)
    ap.add_argument("--scale", type=int, default=6)
    ap.add_argument("--mock-scale", type=int, default=3)
    args = ap.parse_args(argv)
    out: Path = args.out
    out.mkdir(parents=True, exist_ok=True)

    pngs = sorted(ART.rglob("*.png"))
    for p in pngs:
        rel = p.relative_to(ART).with_suffix("").as_posix().replace("/", "__")
        img = Image.open(p).convert("RGBA")
        up(on_checker(img), args.scale).save(out / f"{rel}_x{args.scale}.png")
        up(on_checker(to_gray(img)), args.scale).save(out / f"{rel}_gray_x{args.scale}.png")

    for group, folder, k in (("_chars", "char", 4), ("_props", "props", 6)):
        files = sorted((ART / folder).glob("*.png"))
        if not files:
            continue
        rows = []
        for f in files:
            img = Image.open(f).convert("RGBA")
            rows.append(side_by_side([up(on_checker(img), k), up(on_checker(to_gray(img)), k)]))
        stack(rows).save(out / f"{group}.png")

    for meta_path in sorted((ART / "bg").glob("*.json")):
        png = meta_path.with_suffix(".png")
        if not png.exists():
            continue
        meta = json.loads(meta_path.read_text(encoding="utf-8"))
        scene, dbg = mock(png, meta)
        k = args.mock_scale
        up(scene, k).save(out / f"mock_{png.stem}.png")
        up(to_gray(scene), k).save(out / f"mock_{png.stem}_gray.png")
        up(dbg, k).save(out / f"mock_{png.stem}_debug.png")

    print(f"preview: PNG {len(pngs)}개 → {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
