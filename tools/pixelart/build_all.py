#!/usr/bin/env python3
"""버티컬 슬라이스(프롤로그 + 챕터 1) 아트를 코드로 전부 다시 만든다. 결과는 항상 같다(결정적).

  python tools/pixelart/build_all.py              # 전부
  python tools/pixelart/build_all.py --only props # 일부만 (char, portrait, npc, props, bg)

출력: game/art/char/*.png, game/art/props/*.png, game/art/bg/*.png + *.json
목록과 규격: docs/style/asset_manifest.md
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import palette as P  # noqa: E402

ART = P.ROOT / "game/art"
GROUPS = ("char", "portrait", "npc", "props", "bg")


def save_png(img: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    img = img.convert("RGBA")
    img.save(path, format="PNG", optimize=False, compress_level=9)
    print(f"  {path.relative_to(P.ROOT).as_posix()}  {img.width}x{img.height}")


def dump_json(data: dict, path: Path) -> None:
    """들여쓰기 2칸, 숫자 목록은 한 줄로."""
    text = json.dumps(data, ensure_ascii=False, indent=2)
    text = re.sub(r"\[\s+(-?\d+(?:\.\d+)?(?:,\s+-?\d+(?:\.\d+)?)*)\s+\]",
                  lambda m: "[" + re.sub(r",\s+", ", ", m.group(1)) + "]", text)
    path.write_text(text + "\n", encoding="utf-8", newline="\n")
    print(f"  {path.relative_to(P.ROOT).as_posix()}")


def build_char() -> None:
    import chars
    for name, fn in chars.WALK_SHEETS.items():
        save_png(fn(), ART / "char" / f"{name}_walk.png")


def build_npc() -> None:
    import chars
    for name, fn in chars.NPC_SHEETS.items():
        save_png(fn(), ART / "char" / f"{name}_walk.png")
    for level, fn in chars.FACE_OVERLAYS.items():
        save_png(fn(), ART / "char" / f"npc_face_{level}.png")


def build_portrait() -> None:
    import portraits
    for name, fn in portraits.PORTRAITS.items():
        save_png(fn(), ART / "char" / f"{name}_portrait.png")


def build_props() -> None:
    import props
    for name, fn in props.PROPS.items():
        save_png(fn(), ART / "props" / f"{name}.png")


def build_bg() -> None:
    import backgrounds
    for name, fn in backgrounds.BACKGROUNDS.items():
        img, meta = fn()
        save_png(img, ART / "bg" / f"{name}.png")
        dump_json(meta, ART / "bg" / f"{name}.json")


def main(argv: list[str] | None = None) -> int:
    P.utf8_stdout()
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--only", choices=GROUPS, action="append", help="이 묶음만 만든다 (여러 번 가능)")
    args = ap.parse_args(argv)
    todo = args.only or list(GROUPS)
    for g in todo:
        print(f"[{g}]")
        globals()[f"build_{g}"]()
    print("build_all: 완료")
    return 0


if __name__ == "__main__":
    sys.exit(main())
