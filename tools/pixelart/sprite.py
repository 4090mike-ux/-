"""ASCII 격자 → 스프라이트.

격자 한 줄 = 픽셀 한 줄, 글자 하나 = 픽셀 하나. 글자의 뜻은 스프라이트마다 legend 로 정한다.
    legend = {"K": "neutral-ink", "S": "neutral-skin-light"}
    img = grid('''
        .KK.
        KSSK
        .KK.
    ''', legend)
'.' 은 항상 투명이다. legend 에 없는 글자가 나오면 바로 오류를 낸다(오타 방지).
"""
from __future__ import annotations

import textwrap
from typing import Iterable

from PIL import Image

from palette import rgba

TRANSPARENT = "."
CLEAR = (0, 0, 0, 0)


def rows_of(text: str | Iterable[str]) -> list[str]:
    """여러 줄 문자열(들여쓰기 무시) 또는 줄 목록 → 줄 목록. 앞뒤 빈 줄은 버린다."""
    if isinstance(text, str):
        lines = textwrap.dedent(text).split("\n")
    else:
        lines = list(text)
    while lines and not lines[0].strip():
        lines.pop(0)
    while lines and not lines[-1].strip():
        lines.pop()
    return [ln.rstrip("\n") for ln in lines]


def grid(text: str | Iterable[str], legend: dict[str, str], name: str = "grid",
         size: tuple[int, int] | None = None) -> Image.Image:
    """ASCII 격자를 RGBA 이미지로. size 를 주면 그 크기인지 검사한다."""
    rows = rows_of(text)
    if not rows:
        raise ValueError(f"{name}: 빈 격자")
    width = max(len(r) for r in rows)
    for i, r in enumerate(rows):
        if len(r) != width:
            raise ValueError(f"{name}: {i}번째 줄 너비 {len(r)} != {width}: {r!r}")
    if size is not None and (width, len(rows)) != size:
        raise ValueError(f"{name}: 크기 {(width, len(rows))} != {size}")
    img = Image.new("RGBA", (width, len(rows)), CLEAR)
    px = img.load()
    for y, r in enumerate(rows):
        for x, ch in enumerate(r):
            if ch == TRANSPARENT:
                continue
            if ch not in legend:
                raise ValueError(f"{name}: ({x},{y}) 글자 {ch!r} 가 legend 에 없음")
            px[x, y] = rgba(legend[ch])
    return img


def patch(base: Image.Image, text: str | Iterable[str], legend: dict[str, str], x: int, y: int,
          name: str = "patch") -> Image.Image:
    """base 위에 격자를 덮어쓴다. '.' 은 '그대로 둠', '_' 는 '투명으로 지움'."""
    out = base.copy()
    px = out.load()
    for dy, r in enumerate(rows_of(text)):
        for dx, ch in enumerate(r):
            if ch == TRANSPARENT:
                continue
            tx, ty = x + dx, y + dy
            if not (0 <= tx < out.width and 0 <= ty < out.height):
                raise ValueError(f"{name}: ({tx},{ty}) 가 이미지 밖")
            if ch == "_":
                px[tx, ty] = CLEAR
                continue
            if ch not in legend:
                raise ValueError(f"{name}: 글자 {ch!r} 가 legend 에 없음")
            px[tx, ty] = rgba(legend[ch])
    return out


def paste(dst: Image.Image, src: Image.Image, x: int, y: int) -> None:
    """알파 0 이 아닌 픽셀만 그대로 복사(반투명 합성 없음 → 팔레트 밖 색이 생기지 않는다)."""
    sp = src.load()
    dp = dst.load()
    for sy in range(src.height):
        ty = y + sy
        if not 0 <= ty < dst.height:
            continue
        for sx in range(src.width):
            tx = x + sx
            if not 0 <= tx < dst.width:
                continue
            c = sp[sx, sy]
            if c[3] > 0:
                dp[tx, ty] = c
    return None


def mirror(img: Image.Image) -> Image.Image:
    return img.transpose(Image.Transpose.FLIP_LEFT_RIGHT)


def shift(img: Image.Image, dx: int, dy: int) -> Image.Image:
    out = Image.new("RGBA", img.size, CLEAR)
    paste(out, img, dx, dy)
    return out


def outline(img: Image.Image, color: str = "neutral-ink", diagonal: bool = False) -> Image.Image:
    """불투명 영역 바깥에 1px 외곽선. 4방향(기본) 또는 8방향."""
    w, h = img.size
    src = img.load()
    out = img.copy()
    op = out.load()
    c = rgba(color)
    nbrs = [(1, 0), (-1, 0), (0, 1), (0, -1)]
    if diagonal:
        nbrs += [(1, 1), (1, -1), (-1, 1), (-1, -1)]
    for y in range(h):
        for x in range(w):
            if src[x, y][3] != 0:
                continue
            for dx, dy in nbrs:
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and src[nx, ny][3] != 0:
                    op[x, y] = c
                    break
    return out


def recolor(img: Image.Image, mapping: dict[str, str]) -> Image.Image:
    """팔레트 이름 → 이름 치환."""
    table = {rgba(a): rgba(b) for a, b in mapping.items()}
    out = img.copy()
    px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            c = px[x, y]
            if c[3] and c in table:
                px[x, y] = table[c]
    return out


def sheet(frames: list[list[Image.Image]], fw: int, fh: int) -> Image.Image:
    """frames[row][col] → 한 장. 모든 프레임은 fw×fh 여야 한다."""
    rows = len(frames)
    cols = max(len(r) for r in frames)
    out = Image.new("RGBA", (cols * fw, rows * fh), CLEAR)
    for r, row in enumerate(frames):
        for c, f in enumerate(row):
            if f.size != (fw, fh):
                raise ValueError(f"프레임 ({r},{c}) 크기 {f.size} != {(fw, fh)}")
            paste(out, f, c * fw, r * fh)
    return out


def bbox_bottom_center(img: Image.Image) -> tuple[int, int]:
    """불투명 영역의 바닥 중앙 (x, y). 소품 기준점 계산용."""
    box = img.getbbox()
    if box is None:
        return (img.width // 2, img.height)
    return ((box[0] + box[2]) // 2, box[3])
