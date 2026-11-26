"""배경용 소품 도장 (창문·문·화분·덤불·나무·상자·가로등·벤치·차양…). 모두 중립색만 쓴다.

함수는 Canvas 에 직접 그리고, 필요하면 바닥 기준 막힘 사각형(blocker)을 돌려준다.
좌표 규칙: (x, y) = 왼쪽 위, 바닥에 서는 물건은 별도 표기가 없으면 y + h 가 바닥에 닿는 줄.
"""
from __future__ import annotations

import random

from canvas import BAYER4, Canvas, ellipse_mask

INK = "neutral-ink"
SHADOW = "neutral-shadow"
STONE = "neutral-stone"
ASH = "neutral-ash"
MIST = "neutral-mist"
FOG = "neutral-fog"
PAPERC = "neutral-paper-cool"
PAPER = "neutral-paper"
SKIN_L = "neutral-skin-light"
SKIN_M = "neutral-skin-mid"
SKIN_S = "neutral-skin-shadow"
WOOD = "neutral-wood-mid"
WOOD_D = "neutral-wood-dark"


def box(c: Canvas, x: int, y: int, w: int, h: int, fill: str, edge: str = INK) -> None:
    c.rect(x, y, w, h, fill)
    c.frame(x, y, w, h, edge)


def ground_shadow(c: Canvas, cx: float, cy: float, rx: float, ry: float, level: int = 16) -> None:
    c.shade_ellipse(cx, cy, rx, ry, 1, level)


# ---------------------------------------------------------------- 건축
def window(c: Canvas, x: int, y: int, w: int, h: int, *, cols: int = 2, rows: int = 2,
           frame: str = WOOD_D, glass: str = PAPERC, glint: str = FOG, sill: str | None = WOOD,
           shutters: str | None = None, lit: bool = False, curtain: str | None = None,
           view: str | None = None) -> None:
    """벽에 붙은 창. lit=True 면 밤에 불 켜진 창(따뜻한 종이색)."""
    if shutters:
        sw = max(5, w // 3)
        for sx in (x - sw - 1, x + w + 1):
            box(c, sx, y, sw, h, shutters, INK)
            for yy in range(y + 3, y + h - 2, 3):
                c.hline(sx + 1, sx + sw - 2, yy, darker_of(shutters))
    c.rect(x - 1, y - 1, w + 2, h + 2, INK)
    c.rect(x, y, w, h, frame)
    inner_w = (w - 2 - (cols - 1) * 2) // cols
    inner_h = (h - 2 - (rows - 1) * 2) // rows
    g = SKIN_L if lit else glass
    gl = PAPER if lit else glint
    for r in range(rows):
        for col in range(cols):
            px = x + 1 + col * (inner_w + 2)
            py = y + 1 + r * (inner_h + 2)
            c.rect(px, py, inner_w, inner_h, g)
            if view and not lit:
                # 바깥 풍경: 아래쪽 지붕 실루엣
                for xx in range(px, px + inner_w):
                    top = py + inner_h - 3 - ((xx * 7) % 11 > 6) * 2 - ((xx // 5) % 3 == 0)
                    c.vline(xx, max(py, top), py + inner_h - 1, view)
            # 반사광 사선
            for k in range(0, min(inner_w, inner_h) - 1):
                if (k % 5) < 2:
                    c.set(px + inner_w - 2 - k - 1, py + 1 + k, gl)
            if lit:
                c.hline(px, px + inner_w - 1, py + inner_h - 1, SKIN_M)
    if curtain:
        cw = max(3, w // 5)
        for cx0 in (x, x + w - cw):
            c.rect(cx0, y, cw, h, curtain)
            for xx in range(cx0, cx0 + cw, 2):
                c.vline(xx, y, y + h - 1, darker_of(curtain))
    if sill:
        c.rect(x - 3, y + h + 1, w + 6, 3, sill)
        c.hline(x - 3, x + w + 2, y + h + 1, lighter_of(sill))
        c.hline(x - 3, x + w + 2, y + h + 4, INK)


def door(c: Canvas, x: int, y: int, w: int, h: int, *, wood: str = WOOD, lit: bool = False,
         pane: bool = True, arch: bool = False) -> None:
    c.rect(x - 2, y - 2, w + 4, h + 2, INK)
    c.rect(x - 1, y - 1, w + 2, h + 1, WOOD_D)
    c.rect(x, y, w, h, wood)
    for xx in range(x + 4, x + w - 1, 5):
        c.vline(xx, y, y + h - 1, darker_of(wood))
    c.hline(x, x + w - 1, y + h // 2, darker_of(wood))
    if pane:
        pw, ph = w - 10, h // 4
        c.rect(x + 5 - 1, y + 5 - 1, pw + 2, ph + 2, WOOD_D)
        c.rect(x + 5, y + 5, pw, ph, SKIN_L if lit else MIST)
        c.vline(x + 5 + pw // 2, y + 5, y + 5 + ph - 1, WOOD_D)
        c.set(x + 6, y + 6, PAPER if lit else FOG)
    c.rect(x + w - 6, y + h // 2 + 2, 2, 3, MIST)
    c.set(x + w - 6, y + h // 2 + 2, PAPERC)
    if arch:
        for i in range(w // 2):
            c.set(x + i, y - 2 - (i * 4) // w, INK)


def darker_of(name: str) -> str:
    from palette import darker
    return darker(name)


def lighter_of(name: str) -> str:
    from palette import lighter
    return lighter(name)


def roof_eave(c: Canvas, x: int, y: int, w: int, h: int, *, tile: str = STONE, edge: str = SHADOW,
              hi: str = ASH) -> None:
    """정면에서 본 처마: 기와 줄 + 아래 그늘."""
    c.rect(x, y, w, h, tile)
    for yy in range(y + 3, y + h, 4):
        c.hline(x, x + w - 1, yy, edge)
        for xx in range(x + (yy // 4) % 2 * 3, x + w, 6):
            c.set(xx, yy - 1, edge)
            c.set(xx + 1, yy - 3, hi)
    c.hline(x, x + w - 1, y + h - 1, INK)
    c.shade_rect(x, y + h, w, 3, 1)


# ---------------------------------------------------------------- 식물
def foliage(c: Canvas, cx: float, cy: float, rx: float, ry: float, *, seed: int = 0,
            base: str = ASH, dark: str = STONE, light: str = MIST, hi: str | None = FOG,
            edge: str = INK) -> None:
    """잎 덩어리. 덩이(타원) 여러 개 + 가장자리 작은 혹 → 울퉁불퉁한 실루엣,
    위·왼쪽은 밝게, 아래는 어둡게, 그 위에 잎 모양 점(2~3px)을 뿌려 결을 만든다."""
    import math
    rng = random.Random(seed)
    m = min(rx, ry)
    n = max(3, int(rx * ry / 45))
    blobs = []
    for _ in range(n):
        bx = cx + rng.uniform(-rx * 0.55, rx * 0.55)
        by = cy + rng.uniform(-ry * 0.45, ry * 0.45)
        br = rng.uniform(m * 0.45, m * 0.7)
        blobs.append((bx, by, br))
    blobs.append((cx, cy, m * 0.75))
    bumps = []
    for bx, by, br in blobs:
        k = max(5, int(br * 1.3))
        off = rng.random() * 6.283
        for i in range(k):
            a = off + i * 6.283 / k
            bumps.append((bx + math.cos(a) * br * 0.95, by + math.sin(a) * br * 0.8, rng.uniform(1.6, 2.8)))
    shapes = [(x, y, r, r * 0.82) for x, y, r in blobs] + [(x, y, r, r) for x, y, r in bumps]
    x0 = int(min(s[0] - s[2] for s in shapes)) - 2
    x1 = int(max(s[0] + s[2] for s in shapes)) + 3
    y0 = int(min(s[1] - s[3] for s in shapes)) - 2
    y1 = int(max(s[1] + s[3] for s in shapes)) + 3

    def inside(x: int, y: int, grow: float = 0.0) -> bool:
        for sx, sy, srx, sry in shapes:
            dx = (x + 0.5 - sx) / (srx + grow)
            dy = (y + 0.5 - sy) / (sry + grow)
            if dx * dx + dy * dy <= 1.0:
                return True
        return False

    if edge:
        c.fill_where(lambda x, y: inside(x, y, 1.0), edge, (x0, y0, x1, y1))
    c.fill_where(inside, dark, (x0, y0, x1, y1))
    # 밝은 면: 덩이마다 위·왼쪽
    for bx, by, br in sorted(blobs, key=lambda b: b[1]):
        c.fill_where(lambda x, y, bx=bx, by=by, br=br: inside(x, y) and
                     ((x + 0.5 - bx + br * 0.15) ** 2 / (br * 0.85) ** 2 + (y + 0.5 - by + br * 0.2) ** 2 / (br * 0.7) ** 2) <= 1.0,
                     base, (x0, y0, x1, y1))
        c.fill_where(lambda x, y, bx=bx, by=by, br=br: inside(x, y) and
                     ((x + 0.5 - bx + br * 0.35) ** 2 / (br * 0.45) ** 2 + (y + 0.5 - by + br * 0.4) ** 2 / (br * 0.35) ** 2) <= 1.0,
                     light, (x0, y0, x1, y1))
    # 위쪽 혹은 밝게
    for sx, sy, r in bumps:
        if sy < cy - ry * 0.2:
            c.fill_where(lambda x, y, sx=sx, sy=sy, r=r: (x + 0.5 - sx) ** 2 + (y + 0.5 - sy) ** 2 <= (r * 0.7) ** 2 and inside(x, y),
                         base, (int(sx - r) - 1, int(sy - r) - 1, int(sx + r) + 2, int(sy + r) + 2))
    # 잎 결: 칠해진 색에 따라 한 계단 밝거나 어두운 잎 점
    up = {dark: base, base: light, light: hi or light}
    down = {light: base, base: dark, dark: dark}
    for _ in range(int((x1 - x0) * (y1 - y0) / 7)):
        x = rng.randint(x0, x1)
        y = rng.randint(y0, y1)
        if not inside(x, y) or not inside(x + 1, y + 1):
            continue
        cur = c.get(x, y)
        if cur not in up:
            continue
        col = up[cur] if rng.random() < 0.55 else down[cur]
        c.set(x, y, col)
        if rng.random() < 0.6:
            c.set(x + 1, y, col)
        if rng.random() < 0.3 and col == down.get(cur):
            c.set(x, y + 1, col)


def potted_plant(c: Canvas, x: int, y: int, *, size: int = 10, seed: int = 0, pot: str = SKIN_S,
                 leaves: str = ASH) -> tuple[int, int, int, int]:
    """(x, y) = 화분 바닥 중앙. 돌려주는 값 = 막힘 사각형."""
    pw, ph = size, max(5, size * 2 // 3)
    px0 = x - pw // 2
    ground_shadow(c, x + 1, y, pw * 0.7, 2.5)
    c.rect(px0 - 1, y - ph - 1, pw + 2, ph + 1, INK)
    c.rect(px0, y - ph, pw, ph, pot)
    c.rect(px0 - 1, y - ph - 2, pw + 2, 2, lighter_of(pot))
    c.hline(px0 - 2, px0 + pw + 1, y - ph - 3, INK)
    c.vline(px0 + pw - 2, y - ph, y - 1, darker_of(pot))
    foliage(c, x, y - ph - size * 0.55, size * 0.75, size * 0.6, seed=seed, base=leaves)
    return (px0, y - 4, pw, 4)


def tree(c: Canvas, x: int, y: int, *, r: int = 22, seed: int = 0, trunk_h: int = 14) -> tuple[int, int, int, int]:
    """(x, y) = 줄기 밑동 중앙."""
    ground_shadow(c, x + 3, y, r * 0.9, r * 0.32)
    c.rect(x - 3, y - trunk_h - 1, 7, trunk_h + 1, INK)
    c.rect(x - 2, y - trunk_h, 5, trunk_h, WOOD_D)
    c.vline(x - 1, y - trunk_h, y - 1, WOOD)
    c.set(x - 3, y - 1, INK)
    c.set(x + 3, y - 1, INK)
    foliage(c, x, y - trunk_h - r * 0.7, r, r * 0.8, seed=seed, base=ASH, dark=STONE, light=MIST)
    return (x - 4, y - 4, 9, 5)


# ---------------------------------------------------------------- 가구·잡동사니
def crate(c: Canvas, x: int, y: int, w: int = 16, h: int = 12, top: int = 5, *, wood: str = WOOD) -> tuple[int, int, int, int]:
    """(x, y) = 왼쪽 위 (윗면 포함). 높이 h = 앞면."""
    box(c, x, y, w, top + h, wood)
    c.rect(x + 1, y + 1, w - 2, top - 1, lighter_of(wood))
    c.hline(x, x + w - 1, y + top, INK)
    for yy in range(y + top + 4, y + top + h - 1, 4):
        c.hline(x + 1, x + w - 2, yy, darker_of(wood))
    c.line(x + 1, y + top + 1, x + w - 2, y + top + h - 2, darker_of(wood))
    ground_shadow(c, x + w / 2 + 2, y + top + h + 1, w * 0.6, 2)
    return (x, y + top + h - 6, w, 6)


def barrel(c: Canvas, x: int, y: int, *, w: int = 14, h: int = 18) -> tuple[int, int, int, int]:
    ground_shadow(c, x + w / 2 + 2, y + h, w * 0.6, 2.2)
    c.rect(x, y + 3, w, h - 3, INK)
    c.rect(x + 1, y + 3, w - 2, h - 4, WOOD)
    c.ellipse(x + w / 2, y + 3.5, w / 2, 3.2, INK)
    c.ellipse(x + w / 2, y + 3.5, w / 2 - 1, 2.2, WOOD_D)
    for yy in (y + 7, y + h - 5):
        c.hline(x + 1, x + w - 2, yy, SHADOW)
    c.vline(x + 3, y + 5, y + h - 2, SKIN_S)
    c.vline(x + w - 3, y + 5, y + h - 2, WOOD_D)
    return (x, y + h - 6, w, 6)


def bench(c: Canvas, x: int, y: int, *, w: int = 32, wood: str = WOOD) -> tuple[int, int, int, int]:
    """정면 벤치(중립). (x, y) = 등받이 왼쪽 위. 높이 22."""
    ground_shadow(c, x + w / 2 + 2, y + 21, w * 0.55, 3)
    for yy, col in ((y + 1, lighter_of(wood)), (y + 2, wood), (y + 3, darker_of(wood)),
                    (y + 5, lighter_of(wood)), (y + 6, wood), (y + 7, darker_of(wood))):
        c.hline(x + 2, x + w - 3, yy, col)
    for yy, col in ((y + 10, lighter_of(lighter_of(wood))), (y + 11, lighter_of(wood)), (y + 12, wood),
                    (y + 13, lighter_of(wood)), (y + 14, wood), (y + 15, darker_of(wood))):
        c.hline(x + 1, x + w - 2, yy, col)
    for lx in (x, x + w - 2):
        c.rect(lx, y, 2, 21, SHADOW)
        c.set(lx, y, STONE)
    c.frame(x, y + 9, w, 8, INK)
    c.frame(x + 1, y, w - 2, 9, INK)
    return (x, y + 14, w, 7)


def lamp_post(c: Canvas, x: int, y: int, *, h: int = 44, lit: bool = False) -> tuple[int, int, int, int]:
    """중립 가로등. (x, y) = 밑동 중앙."""
    ground_shadow(c, x + 2, y, 6, 2)
    c.rect(x - 2, y - h, 4, h, INK)
    c.vline(x - 1, y - h + 1, y - 2, STONE)
    c.vline(x, y - h + 1, y - 2, SHADOW)
    c.rect(x - 4, y - 4, 8, 4, INK)
    c.rect(x - 3, y - 3, 6, 2, STONE)
    hx, hy = x - 5, y - h - 12
    c.rect(hx, hy, 10, 12, INK)
    c.rect(hx + 1, hy + 2, 8, 9, PAPER if lit else FOG)
    c.vline(x, hy + 2, hy + 10, SHADOW)
    c.rect(hx - 1, hy - 2, 12, 3, INK)
    c.set(x - 1, hy - 3, INK)
    c.set(x, hy - 3, INK)
    return (x - 3, y - 4, 6, 4)


def awning(c: Canvas, x: int, y: int, w: int, h: int, *, a: str = PAPER, b: str = ASH, stripe: int = 6) -> None:
    """줄무늬 차양 + 물결 끝단."""
    for xx in range(x, x + w):
        col = a if ((xx - x) // stripe) % 2 == 0 else b
        c.vline(xx, y, y + h - 1, col)
        k = (xx - x) % stripe
        if k in (0, stripe - 1):
            c.set(xx, y + h, col)
        else:
            c.vline(xx, y + h, y + h + 2, col)
    c.hline(x, x + w - 1, y, INK)
    for xx in range(x, x + w):
        k = (xx - x) % stripe
        c.set(xx, y + h + (1 if k in (0, stripe - 1) else 3), INK)
    c.shade_rect(x, y + h - 2, w, 2, 1)


def flower_box(c: Canvas, x: int, y: int, w: int, *, seed: int = 0) -> None:
    """창턱 화분 상자 (중립 꽃)."""
    rng = random.Random(seed)
    for i in range(w // 4):
        fx = x + 1 + i * 4 + rng.randint(0, 1)
        c.ellipse(fx + 1.5, y - 2, 2.6, 2.2, STONE)
        c.set(fx + 1, y - 3, FOG if i % 2 else PAPERC)
        c.set(fx + 2, y - 2, MIST)
    box(c, x, y, w, 5, WOOD)
    c.hline(x + 1, x + w - 2, y + 1, SKIN_S)


def books(c: Canvas, x: int, y: int, w: int, *, seed: int = 0, max_h: int = 10) -> None:
    """선반 위 책 (y = 선반 윗면)."""
    rng = random.Random(seed)
    cols = [STONE, ASH, MIST, WOOD, WOOD_D, FOG, SKIN_S, SHADOW]
    xx = x
    while xx < x + w - 2:
        bw = rng.randint(2, 4)
        bh = rng.randint(max_h - 4, max_h)
        col = rng.choice(cols)
        if rng.random() < 0.12 and xx + bh < x + w:   # 눕힌 책
            c.rect(xx, y - 3, bh, 3, col)
            c.hline(xx, xx + bh - 1, y - 4, INK)
            xx += bh + 1
            continue
        c.rect(xx, y - bh, bw, bh, col)
        c.vline(xx + bw, y - bh, y - 1, INK)
        c.hline(xx, xx + bw - 1, y - bh, INK)
        if bw >= 3:
            c.hline(xx, xx + bw - 1, y - bh + 2, lighter_of(col))
        xx += bw + 1


def jar(c: Canvas, x: int, y: int, *, w: int = 6, h: int = 8, body: str = FOG) -> None:
    """선반 위 병 (y = 바닥)."""
    c.rect(x - 1, y - h - 1, w + 2, h + 1, INK)
    c.rect(x, y - h, w, h, body)
    c.rect(x + 1, y - h - 3, w - 2, 3, INK)
    c.hline(x + 2, x + w - 3, y - h - 2, MIST)
    c.vline(x + 1, y - h + 1, y - 2, lighter_of(body))
    c.vline(x + w - 1, y - h, y - 1, darker_of(body))


def rug(c: Canvas, x: int, y: int, w: int, h: int, *, base: str = SKIN_M, border: str = SKIN_S,
        pattern: str = PAPER) -> None:
    c.rect(x, y, w, h, border)
    c.rect(x + 3, y + 3, w - 6, h - 6, base)
    c.frame(x + 5, y + 5, w - 10, h - 10, border)
    for xx in range(x + 9, x + w - 9, 8):
        for yy in range(y + 9, y + h - 9, 8):
            c.set(xx, yy, pattern)
            c.set(xx + 1, yy + 1, pattern)
            c.set(xx - 1, yy + 1, pattern)
            c.set(xx, yy + 2, pattern)
    for xx in range(x, x + w, 2):  # 술
        c.set(xx, y - 1, border)
        c.set(xx, y + h, border)


def soft_light(c: Canvas, pts: list[tuple[int, int]]) -> None:
    """창빛: 바깥은 디더로 부드럽게, 안쪽은 한 계단 밝게."""
    c.light_poly(pts, 1, 16)


def puddle(c: Canvas, cx: float, cy: float, rx: float, ry: float) -> None:
    c.shade_ellipse(cx, cy, rx, ry, 1)
    c.light_ellipse(cx - rx * 0.3, cy - ry * 0.3, rx * 0.35, ry * 0.3, 2)


def dither_mask(c: Canvas, mask, color: str, level: int, bbox: tuple[int, int, int, int]) -> None:
    x0, y0, x1, y1 = bbox
    for yy in range(max(0, y0), min(c.h, y1)):
        for xx in range(max(0, x0), min(c.w, x1)):
            if BAYER4[yy % 4][xx % 4] < level and mask(xx, yy):
                c.set(xx, yy, color)


__all__ = [n for n in dir() if not n.startswith("_")]
_ = ellipse_mask
