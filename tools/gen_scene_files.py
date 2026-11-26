#!/usr/bin/env python3
"""game/data/scenes/<scene_id>.json 마다 game/scenes/<구간>/<scene_id>.tscn 을 만든다.

장면 파일은 ChapterScene 스크립트와 scene_id 하나만 가진다. 내용은 모두 JSON 정의와 배경 메타데이터에서 온다.
  python tools/gen_scene_files.py          # 없는 파일 생성 / 다른 파일 갱신
  python tools/gen_scene_files.py --check  # CI: 빠지거나 다른 파일이 있으면 종료 코드 1
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TEMPLATE = """[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://game/systems/scene/chapter_scene.gd" id="1_scene"]

[node name="{node}" type="Node2D"]
script = ExtResource("1_scene")
scene_id = "{scene_id}"
"""


def section_of(scene_id: str) -> str:
    first = scene_id.split("_")[0]
    return "endings" if first == "end" else first


def expected() -> dict[Path, str]:
    out: dict[Path, str] = {}
    for path in sorted((ROOT / "game/data/scenes").glob("*.json")):
        sid = json.loads(path.read_text(encoding="utf-8"))["scene_id"]
        node = "".join(part.capitalize() for part in sid.split("_"))
        out[ROOT / "game/scenes" / section_of(sid) / f"{sid}.tscn"] = TEMPLATE.format(node=node, scene_id=sid)
    return out


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    problems = 0
    for path, text in expected().items():
        current = path.read_text(encoding="utf-8") if path.exists() else None
        if current == text:
            continue
        if args.check:
            print(f"ERROR {path.relative_to(ROOT).as_posix()} 가 없거나 다름 → python tools/gen_scene_files.py")
            problems += 1
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(text, encoding="utf-8", newline="\n")
            print(f"썼음 {path.relative_to(ROOT).as_posix()}")
    if args.check:
        print(f"gen_scene_files: 오류 {problems}건")
    return 1 if problems else 0


if __name__ == "__main__":
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    sys.exit(main())
