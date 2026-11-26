"""배경용 그리기 도구. 모든 색은 팔레트 이름으로만 받는다(팔레트 밖 색이 생길 수 없다).

    c = Canvas(480, 270, "neutral-shadow")
    c.rect(16, 120, 448, 134, "neutral-wood-mid")
    c.shade_rect(40, 200, 60, 8)            # 한 계단 어둡게 (그림자)
    c.dither(0, 0, 480, 30, "neutral-fog", "neutral-mist", 8)
    c.to_image().save("x.png")

무작위가 필요한 곳은 항상 seed 를 받는 random.Random 을 쓴다(build_all 이 같은 결과를 다시 만들 수 있게).
"""
from __future__ import annotations

import random
from typing import Callable, Iterable

from PIL import Image

import palette as P
from sprite import grid, paste

# 4×4 Bayer 행렬 (0~15). dither(level) 은 level/16 비율로 b 색을 섞는다.
BAYER4 = [
    [0, 8, 2, 10],
    [12, 4, 14, 6],
    [3, 11, 1, 9],
    [15, 7, 13, 5],
]


class Canvas:
    def __init__(self, w: int, h: int, fill: str | None = "neutral-ink") -> None:
        """fill=None 이면 투명 바탕(소품용)."""
        self.w, self.h = w, h
        self.img = Image.new("RGBA", (w, h), P.rgba(fill) if fill else (0, 0, 0, 0))
        self.px = self.img.load()

    # ---------------------------------------------------------------- 기본
    def inside(self, x: int, y: int) -> bool:
        return 0 <= x < self.w and 0 <= y < self.h

    def set(self, x: int, y: int, name: str) -> None:
        if self.inside(x, y):
            self.px[x, y] = P.rgba(name)

    def get(self, x: int, y: int) -> str | None:
        if not self.inside(x, y):
            return None
        c = self.px[x, y]
        return P.RGB_TO_NAME.get(c[:3]) if c[3] else None

    def rect(self, x: int, y: int, w: int, h: int, name: str) -> None:
        c = P.rgba(name)
        for yy in range(max(0, y), min(self.h, y + h)):
            for xx in range(max(0, x), min(self.w, x + w)):
                self.px[xx, yy] = c

    def frame(self, x: int, y: int, w: int, h: int, name: str) -> None:
        self.hline(x, x + w - 1, y, name)
        self.hline(x, x + w - 1, y + h - 1, name)
        self.vline(x, y, y + h - 1, name)
        self.vline(x + w - 1, y, y + h - 1, name)

    def hline(self, x0: int, x1: int, y: int, name: str) -> None:
        if x1 < x0:
            x0, x1 = x1, x0
        self.rect(x0, y, x1 - x0 + 1, 1, name)

    def vline(self, x: int, y0: int, y1: int, name: str) -> None:
        if y1 < y0:
            y0, y1 = y1, y0
        self.rect(x, y0, 1, y1 - y0 + 1, name)

    def line(self, x0: int, y0: int, x1: int, y1: int, name: str) -> None:
        """Bresenham."""
        dx, dy = abs(x1 - x0), -abs(y1 - y0)
        sx, sy = (1 if x0 < x1 else -1), (1 if y0 < y1 else -1)
        err = dx + dy
        while True:
            self.set(x0, y0, name)
            if x0 == x1 and y0 == y1:
                break
            e2 = 2 * err
            if e2 >= dy:
                err += dy
                x0 += sx
            if e2 <= dx:
                err += dx
                y0 += sy

    def poly(self, pts: list[tuple[int, int]], name: str) -> None:
        """짝-홀 규칙 다각형 채우기 (픽셀 중심 기준)."""
        self.fill_where(poly_mask(pts), name, _pts_box(pts))

    def ellipse(self, cx: float, cy: float, rx: float, ry: float, name: str) -> None:
        box = (int(cx - rx) - 1, int(cy - ry) - 1, int(cx + rx) + 2, int(cy + ry) + 2)
        self.fill_where(ellipse_mask(cx, cy, rx, ry), name, box)

    def fill_where(self, mask: Callable[[int, int], bool], name: str,
                   box: tuple[int, int, int, int] | None = None) -> None:
        c = P.rgba(name)
        x0, y0, x1, y1 = box or (0, 0, self.w, self.h)
        for y in range(max(0, y0), min(self.h, y1)):
            for x in range(max(0, x0), min(self.w, x1)):
                if mask(x, y):
                    self.px[x, y] = c

    # ---------------------------------------------------------------- 디더·명암
    def dither(self, x: int, y: int, w: int, h: int, a: str, b: str, level: int) -> None:
        """a 바탕에 b 를 level/16 비율로 (4×4 Bayer)."""
        ca, cb = P.rgba(a), P.rgba(b)
        for yy in range(max(0, y), min(self.h, y + h)):
            for xx in range(max(0, x), min(self.w, x + w)):
                self.px[xx, yy] = cb if BAYER4[yy % 4][xx % 4] < level else ca

    def remap_where(self, mask: Callable[[int, int], bool], mapping: dict[str, str],
                    level: int = 16, box: tuple[int, int, int, int] | None = None) -> None:
        """mask 안 픽셀의 색을 mapping 으로 바꾼다. level<16 이면 Bayer 비율만큼만(부드러운 가장자리)."""
        x0, y0, x1, y1 = box or (0, 0, self.w, self.h)
        cache: dict[tuple[int, int, int, int], tuple[int, int, int, int]] = {}
        for y in range(max(0, y0), min(self.h, y1)):
            for x in range(max(0, x0), min(self.w, x1)):
                if BAYER4[y % 4][x % 4] >= level or not mask(x, y):
                    continue
                c = self.px[x, y]
                if c not in cache:
                    nm = P.RGB_TO_NAME.get(c[:3])
                    cache[c] = P.rgba(mapping.get(nm, nm)) if nm else c
                self.px[x, y] = cache[c]

    def shade_rect(self, x: int, y: int, w: int, h: int, steps: int = 1, level: int = 16) -> None:
        m = _steps(P.DARKER, steps)
        self.remap_where(lambda _x, _y: True, m, level, (x, y, x + w, y + h))

    def light_rect(self, x: int, y: int, w: int, h: int, steps: int = 1, level: int = 16) -> None:
        m = _steps(P.LIGHTER, steps)
        self.remap_where(lambda _x, _y: True, m, level, (x, y, x + w, y + h))

    def shade_poly(self, pts: list[tuple[int, int]], steps: int = 1, level: int = 16) -> None:
        self.remap_where(poly_mask(pts), _steps(P.DARKER, steps), level, _pts_box(pts))

    def light_poly(self, pts: list[tuple[int, int]], steps: int = 1, level: int = 16) -> None:
        self.remap_where(poly_mask(pts), _steps(P.LIGHTER, steps), level, _pts_box(pts))

    def shade_ellipse(self, cx: float, cy: float, rx: float, ry: float, steps: int = 1, level: int = 16) -> None:
        box = (int(cx - rx) - 1, int(cy - ry) - 1, int(cx + rx) + 2, int(cy + ry) + 2)
        self.remap_where(ellipse_mask(cx, cy, rx, ry), _steps(P.DARKER, steps), level, box)

    def light_ellipse(self, cx: float, cy: float, rx: float, ry: float, steps: int = 1, level: int = 16) -> None:
        box = (int(cx - rx) - 1, int(cy - ry) - 1, int(cx + rx) + 2, int(cy + ry) + 2)
        self.remap_where(ellipse_mask(cx, cy, rx, ry), _steps(P.LIGHTER, steps), level, box)

    def glow(self, cx: float, cy: float, rx: float, ry: float, rings: Iterable[tuple[float, int]] = ((1.0, 6), (0.7, 12), (0.4, 16))) -> None:
        """빛 웅덩이: 바깥부터 (반경 비율, 디더 level) 순서로 한 계단씩 밝게."""
        for k, level in rings:
            self.light_ellipse(cx, cy, rx * k, ry * k, 1, level)

    def remap_all(self, mapping: dict[str, str]) -> None:
        self.remap_where(lambda _x, _y: True, mapping)

    # ---------------------------------------------------------------- 스프라이트
    def blit(self, img: Image.Image, x: int, y: int) -> None:
        paste(self.img, img, x, y)

    def stamp(self, text: str, legend: dict[str, str], x: int, y: int, flip: bool = False) -> Image.Image:
        img = grid(text, legend)
        if flip:
            img = img.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
        self.blit(img, x, y)
        return img

    def text(self, s: str, x: int, y: int, name: str) -> int:
        """3×5 글꼴. 돌려주는 값 = 끝 x."""
        for ch in s:
            g = FONT3x5.get(ch.upper())
            if g is None:
                x += 2
                continue
            for dy, row in enumerate(g):
                for dx, bit in enumerate(row):
                    if bit == "#":
                        self.set(x + dx, y + dy, name)
            x += len(g[0]) + 1
        return x

    def to_image(self) -> Image.Image:
        return self.img


def _steps(m: dict[str, str], n: int) -> dict[str, str]:
    out = {}
    for k in m:
        v = k
        for _ in range(n):
            v = m.get(v, v)
        out[k] = v
    return out


def _pts_box(pts: list[tuple[int, int]]) -> tuple[int, int, int, int]:
    xs = [p[0] for p in pts]
    ys = [p[1] for p in pts]
    return (min(xs), min(ys), max(xs) + 1, max(ys) + 1)


def poly_mask(pts: list[tuple[int, int]]) -> Callable[[int, int], bool]:
    n = len(pts)

    def inside(x: int, y: int) -> bool:
        px, py = x + 0.5, y + 0.5
        res = False
        j = n - 1
        for i in range(n):
            xi, yi = pts[i]
            xj, yj = pts[j]
            if (yi > py) != (yj > py) and px < (xj - xi) * (py - yi) / (yj - yi) + xi:
                res = not res
            j = i
        return res

    return inside


def ellipse_mask(cx: float, cy: float, rx: float, ry: float) -> Callable[[int, int], bool]:
    def inside(x: int, y: int) -> bool:
        dx = (x + 0.5 - cx) / max(rx, 0.01)
        dy = (y + 0.5 - cy) / max(ry, 0.01)
        return dx * dx + dy * dy <= 1.0

    return inside


# ------------------------------------------------------------------ 3×5 글꼴 (간판·서명용)
FONT3x5: dict[str, list[str]] = {
    "A": [".#.", "#.#", "###", "#.#", "#.#"],
    "B": ["##.", "#.#", "##.", "#.#", "##."],
    "C": [".##", "#..", "#..", "#..", ".##"],
    "D": ["##.", "#.#", "#.#", "#.#", "##."],
    "E": ["###", "#..", "##.", "#..", "###"],
    "F": ["###", "#..", "##.", "#..", "#.."],
    "H": ["#.#", "#.#", "###", "#.#", "#.#"],
    "I": ["###", ".#.", ".#.", ".#.", "###"],
    "K": ["#.#", "#.#", "##.", "#.#", "#.#"],
    "L": ["#..", "#..", "#..", "#..", "###"],
    "M": ["#.#", "###", "###", "#.#", "#.#"],
    "N": ["##.", "#.#", "#.#", "#.#", "#.#"],
    "O": [".#.", "#.#", "#.#", "#.#", ".#."],
    "P": ["##.", "#.#", "##.", "#..", "#.."],
    "R": ["##.", "#.#", "##.", "#.#", "#.#"],
    "S": [".##", "#..", ".#.", "..#", "##."],
    "T": ["###", ".#.", ".#.", ".#.", ".#."],
    "U": ["#.#", "#.#", "#.#", "#.#", "###"],
    "W": ["#.#", "#.#", "###", "###", "#.#"],
    "Y": ["#.#", "#.#", ".#.", ".#.", ".#."],
    ".": [".", ".", ".", ".", "#"],
    "0": ["###", "#.#", "#.#", "#.#", "###"],
    "1": [".#.", "##.", ".#.", ".#.", "###"],
    "2": ["##.", "..#", ".#.", "#..", "###"],
    "3": ["##.", "..#", ".#.", "..#", "##."],
    "4": ["#.#", "#.#", "###", "..#", "..#"],
    "5": ["###", "#..", "##.", "..#", "##."],
    "6": [".##", "#..", "###", "#.#", "###"],
    "7": ["###", "..#", ".#.", ".#.", ".#."],
    "8": ["###", "#.#", "###", "#.#", "###"],
    "9": ["###", "#.#", "###", "..#", "##."],
    "-": ["...", "...", "###", "...", "..."],
    "&": [".#.", "#.#", ".#.", "#.#", ".##"],
}


# ------------------------------------------------------------------ 바닥·벽 무늬
def planks(c: Canvas, x: int, y: int, w: int, h: int, *, plank_h: int = 7, seed: int = 1,
           base: str = "neutral-wood-mid", seam: str = "neutral-wood-dark",
           hi: str = "neutral-skin-shadow", min_len: int = 40, max_len: int = 96) -> None:
    """가로로 놓인 마루. 줄마다 이음매 위치가 엇갈린다."""
    rng = random.Random(seed)
    c.rect(x, y, w, h, base)
    row = 0
    for yy in range(y, y + h, plank_h):
        c.hline(x, x + w - 1, yy, seam)
        if yy + 1 < y + h:
            # 판자 윗면 하이라이트 (드문드문)
            for xx in range(x, x + w):
                if (xx * 7 + row * 13) % 23 == 0:
                    c.set(xx, yy + 1, hi)
        xx = x - rng.randint(0, max_len)
        while xx < x + w:
            xx += rng.randint(min_len, max_len)
            if x <= xx < x + w:
                c.vline(xx, yy, min(yy + plank_h - 1, y + h - 1), seam)
                if xx + 1 < x + w:
                    c.vline(xx + 1, yy + 1, min(yy + plank_h - 1, y + h - 1), hi)
            # 옹이
            if rng.random() < 0.18:
                kx = xx + rng.randint(6, 30)
                ky = yy + rng.randint(2, max(2, plank_h - 3))
                if x < kx < x + w - 2 and ky < y + h:
                    c.set(kx, ky, seam)
                    c.set(kx + 1, ky, seam)
        row += 1


def bricks(c: Canvas, x: int, y: int, w: int, h: int, *, bw: int = 10, bh: int = 5, seed: int = 2,
           brick: str = "neutral-ash", mortar: str = "neutral-stone", hi: str = "neutral-mist",
           lo: str | None = None, vary: float = 0.25) -> None:
    rng = random.Random(seed)
    c.rect(x, y, w, h, mortar)
    r = 0
    for yy in range(y, y + h, bh):
        off = (bw // 2) if r % 2 else 0
        for xx in range(x - off, x + w, bw):
            bx0, bx1 = max(x, xx), min(x + w, xx + bw - 1)
            by0, by1 = yy, min(y + h, yy + bh - 1)
            if bx1 <= bx0 or by1 <= by0:
                continue
            col = brick
            if lo and rng.random() < vary:
                col = lo
            c.rect(bx0, by0, bx1 - bx0, by1 - by0, col)
            c.hline(bx0, bx1 - 1, by0, hi)
        r += 1


def cobbles(c: Canvas, x: int, y: int, w: int, h: int, *, cw: int = 9, ch: int = 6, seed: int = 3,
            base: str = "neutral-mist", gap: str = "neutral-ash", hi: str = "neutral-fog",
            lo: str | None = "neutral-ash", alt: str | None = None) -> None:
    """둥근 돌길. 줄 높이·돌 너비·세로 위치를 조금씩 흔들어 벽돌처럼 보이지 않게 한다.
    하이라이트는 돌 왼쪽 위 몇 픽셀, 그늘은 오른쪽 아래 몇 픽셀만."""
    rng = random.Random(seed)
    c.rect(x, y, w, h, gap)
    yy = y
    while yy < y + h:
        rh = ch + rng.choice((0, 0, 1, -1))
        xx = x - rng.randint(0, cw)
        while xx < x + w:
            sw = cw + rng.randint(-3, 3)
            dy = rng.choice((0, 0, 0, 1))
            col = alt if (alt and rng.random() < 0.18) else base
            x0, x1 = xx + 1, xx + sw - 1
            y0, y1 = yy + 1 + dy, yy + rh - 1 + dy
            for py in range(max(y, y0), min(y + h, y1)):
                for px in range(max(x, x0), min(x + w, x1)):
                    if (px in (x0, x1 - 1)) and (py in (y0, y1 - 1)):
                        continue
                    c.px[px, py] = P.rgba(col)
            for px, py, cc in ((x0 + 1, y0, hi), (x0 + 2, y0, hi), (x0, y0 + 1, hi),
                               (x1 - 2, y1 - 1, lo), (x1 - 1, y1 - 2, lo)):
                if cc and x <= px < x + w and y <= py < y + h and x0 <= px < x1:
                    c.px[px, py] = P.rgba(cc)
            xx += sw
        yy += rh


def flagstones(c: Canvas, x: int, y: int, w: int, h: int, *, sw: int = 24, sh: int = 12, seed: int = 4,
               base: str = "neutral-mist", gap: str = "neutral-stone", hi: str = "neutral-fog",
               lo: str = "neutral-ash", crack: float = 0.15) -> None:
    """큰 판석 (광장 바닥)."""
    rng = random.Random(seed)
    c.rect(x, y, w, h, gap)
    r = 0
    for yy in range(y, y + h, sh):
        off = (sw // 2) if r % 2 else 0
        for xx in range(x - off, x + w, sw):
            x0, x1 = max(x, xx + 1), min(x + w, xx + sw)
            y0, y1 = yy + 1, min(y + h, yy + sh)
            if x1 <= x0 or y1 <= y0:
                continue
            c.rect(x0, y0, x1 - x0, y1 - y0, base)
            c.hline(x0, x1 - 1, y0, hi)
            c.hline(x0, x1 - 1, y1 - 1, lo)
            if rng.random() < crack:
                cx = rng.randint(x0 + 2, max(x0 + 2, x1 - 4))
                cy = y0 + 2
                for k in range(rng.randint(3, 7)):
                    c.set(cx, cy, lo)
                    cx += rng.choice((-1, 0, 1))
                    cy += 1
                    if cy >= y1 - 1:
                        break
        r += 1


def grass(c: Canvas, x: int, y: int, w: int, h: int, *, seed: int = 5, base: str = "neutral-mist",
          dark: str = "neutral-ash", light: str = "neutral-fog", deep: str = "neutral-stone",
          step: tuple[int, int] = (7, 5), flowers: str | None = "neutral-paper-cool") -> None:
    """잔디: 고른 바탕 + 지터 격자로 깐 'ᐯ' 풀포기. 큰 얼룩 영역에서는 풀포기만 더 진하게(바탕은 그대로)."""
    rng = random.Random(seed)
    c.rect(x, y, w, h, base)
    zones = [ellipse_mask(rng.randint(x, x + w), rng.randint(y, y + h), rng.randint(30, 70), rng.randint(12, 26))
             for _ in range(max(1, int(w * h / 9000)))]
    sx, sy = step
    for gy in range(y + 2, y + h, sy):
        off = (gy // sy) % 2 * (sx // 2)
        for gx in range(x + off, x + w, sx):
            if rng.random() < 0.28:
                continue
            tx, ty = gx + rng.randint(-2, 2), gy + rng.randint(-1, 1)
            col = deep if any(z(tx, ty) for z in zones) else dark
            c.set(tx, ty, col)
            c.set(tx - 1, ty - 1, col)
            c.set(tx + 1, ty - 1, col)
            if rng.random() < 0.5:
                c.set(tx + 1, ty - 2, light)
    if flowers:
        for _ in range(int(w * h / 1100)):
            fx, fy = rng.randint(x + 2, x + w - 3), rng.randint(y + 2, y + h - 2)
            c.set(fx, fy, flowers)
            c.set(fx + 1, fy, flowers)
            c.set(fx, fy + 1, flowers)
            c.set(fx + 1, fy + 1, "neutral-ash")


def roof_tiles(c: Canvas, x: int, y: int, w: int, h: int, *, tw: int = 6, th: int = 4,
               base: str = "neutral-stone", edge: str = "neutral-shadow", hi: str = "neutral-ash") -> None:
    """비늘 모양 기와 (아래로 볼록)."""
    c.rect(x, y, w, h, base)
    r = 0
    for yy in range(y, y + h, th):
        off = (tw // 2) if r % 2 else 0
        for xx in range(x - off, x + w, tw):
            c.hline(max(x, xx + 1), min(x + w - 1, xx + tw - 2), yy + th - 1, edge)
            if x <= xx < x + w and yy + th - 2 < y + h:
                c.set(xx, yy + th - 2, edge)
            if x <= xx + 1 < x + w:
                c.set(xx + 1, yy, hi)
        r += 1


def stone_wall(c: Canvas, x: int, y: int, w: int, h: int, *, seed: int = 6, base: str = "neutral-ash",
               gap: str = "neutral-stone", hi: str = "neutral-mist", lo: str = "neutral-stone") -> None:
    """크기가 제각각인 돌담."""
    rng = random.Random(seed)
    c.rect(x, y, w, h, gap)
    yy = y
    while yy < y + h:
        rh = rng.randint(5, 8)
        xx = x - rng.randint(0, 8)
        while xx < x + w:
            sw = rng.randint(7, 14)
            x0, x1 = max(x, xx + 1), min(x + w, xx + sw)
            y0, y1 = yy + 1, min(y + h, yy + rh)
            if x1 - x0 >= 2 and y1 - y0 >= 2:
                c.rect(x0, y0, x1 - x0, y1 - y0, base)
                c.hline(x0, x1 - 1, y0, hi)
                c.hline(x0 + 1, x1 - 1, y1 - 1, lo)
                c.set(x0, y0, gap)
                c.set(x1 - 1, y0, gap)
            xx += sw
        yy += rh


def plaster(c: Canvas, x: int, y: int, w: int, h: int, *, seed: int = 7, base: str = "neutral-paper",
            spot: str = "neutral-skin-light", density: float = 0.012) -> None:
    """회벽: 바탕 + 얼룩 점."""
    rng = random.Random(seed)
    c.rect(x, y, w, h, base)
    for _ in range(int(w * h * density)):
        sx, sy = rng.randint(x, x + w - 1), rng.randint(y, y + h - 1)
        c.set(sx, sy, spot)
        if rng.random() < 0.3:
            c.set(sx + 1, sy, spot)
