#!/usr/bin/env python3
"""Godot 애드온을 고정 버전으로 내려받아 addons/ 아래에 설치한다.

사용법:
    python tools/install_addons.py            # 없는 애드온만 설치
    python tools/install_addons.py --force    # 기존 폴더를 지우고 다시 설치

버전을 올릴 때는 아래 ADDONS 표만 고치고, docs/adr/에 이유를 한 줄 남긴다.
설치 결과(addons/)는 저장소에 커밋한다. 워크트리·CI·에이전트가 같은 버전을 쓰게 하기 위해서다.
"""
from __future__ import annotations

import argparse
import io
import shutil
import sys
import urllib.request
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ADDONS_DIR = ROOT / "addons"

# (애드온 폴더명, GitHub 저장소, 태그). Godot 4.7.x 호환 확인: 2026-11-26.
ADDONS: list[tuple[str, str, str]] = [
    ("gdUnit4", "godot-gdunit-labs/gdUnit4", "v6.2.3"),
    ("dialogue_manager", "nathanhoad/godot_dialogue_manager", "v4.2.0"),
]


def install(folder: str, repo: str, tag: str, force: bool) -> None:
    target = ADDONS_DIR / folder
    if target.exists():
        if not force:
            print(f"[skip] addons/{folder} 이미 있음 (--force 로 재설치)")
            return
        shutil.rmtree(target)

    url = f"https://api.github.com/repos/{repo}/zipball/{tag}"
    print(f"[get ] {repo}@{tag}")
    req = urllib.request.Request(url, headers={"User-Agent": "addon-installer"})
    with urllib.request.urlopen(req, timeout=120) as resp:
        data = resp.read()

    marker = f"/addons/{folder}/"
    count = 0
    with zipfile.ZipFile(io.BytesIO(data)) as zf:
        for info in zf.infolist():
            name = info.filename
            idx = name.find(marker)
            if idx < 0 or info.is_dir():
                continue
            rel = name[idx + len("/addons/"):]
            dest = ADDONS_DIR / rel
            # zip slip 방지
            if ADDONS_DIR.resolve() not in dest.resolve().parents:
                raise RuntimeError(f"잘못된 경로: {name}")
            dest.parent.mkdir(parents=True, exist_ok=True)
            with zf.open(info) as src, open(dest, "wb") as out:
                shutil.copyfileobj(src, out)
            count += 1
    if count == 0:
        raise RuntimeError(f"{repo}@{tag} 압축 안에 addons/{folder}/ 가 없음")
    (target / ".version").write_text(f"{repo}@{tag}\n", encoding="utf-8")
    print(f"[ ok ] addons/{folder} ({count} files)")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--force", action="store_true", help="기존 애드온 폴더를 지우고 재설치")
    args = parser.parse_args()
    ADDONS_DIR.mkdir(exist_ok=True)
    for folder, repo, tag in ADDONS:
        install(folder, repo, tag, args.force)
    return 0


if __name__ == "__main__":
    sys.exit(main())
