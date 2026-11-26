"""바깥 배경 8종: 화실 앞, 정원 문, 골목, 오솔길, 계단길, 시장, 광장, 광장(밤).

마을 동선 [제안]: 하늘 길 = 화실 → 화실 앞 → 골목 → 계단길 → 광장
                  별 길   = 정원 → 정원 문 → 오솔길 → 시장 → 광장
출구 이름 = 이어지는 배경 이름. 두 길은 광장에서 만난다(ch1_square 첫 만남).
"""
from __future__ import annotations

import random

import bgkit as K
import palette as P
from backgrounds import H, W, canopy_band, hedge_row, meta
from canvas import Canvas, bricks, cobbles, flagstones, grass, plaster, roof_tiles, stone_wall


# ---------------------------------------------------------------- 공용 도구
def facade(c: Canvas, x: int, y: int, w: int, h: int, *, kind: str = "plaster", seed: int = 0,
           roof: int = 16, roof_tile: str = K.STONE, timber: bool = False) -> None:
    """정면 건물 벽. y = 처마 윗선, y + h = 벽이 땅에 닿는 줄."""
    wy = y + roof
    if kind == "plaster":
        plaster(c, x, wy, w, h - roof, seed=seed)
    elif kind == "plaster_cool":
        plaster(c, x, wy, w, h - roof, seed=seed, base=K.FOG, spot=K.MIST)
    elif kind == "brick":
        bricks(c, x, wy, w, h - roof, seed=seed, brick=K.ASH, mortar=K.STONE, hi=K.MIST, lo=K.STONE, vary=0.12)
    elif kind == "brick_warm":
        bricks(c, x, wy, w, h - roof, seed=seed, brick=K.SKIN_S, mortar=K.WOOD, hi=K.SKIN_M, lo=K.WOOD, vary=0.15)
    elif kind == "wood":
        c.rect(x, wy, w, h - roof, K.WOOD)
        for xx in range(x + 3, x + w, 6):
            c.vline(xx, wy, y + h - 1, K.WOOD_D)
    if timber:
        for xx in (x, x + w - 4):
            c.rect(xx, wy, 4, h - roof, K.WOOD_D)
        c.rect(x, wy + (h - roof) // 2 - 2, w, 4, K.WOOD_D)
        c.hline(x, x + w - 1, wy + (h - roof) // 2 - 2, K.WOOD)
    # 벽 밑동 (땅에 닿는 돌)
    c.rect(x, y + h - 5, w, 5, K.STONE)
    c.hline(x, x + w - 1, y + h - 5, K.ASH)
    c.hline(x, x + w - 1, y + h - 1, K.SHADOW)
    if roof:
        K.roof_eave(c, x - 2, y, w + 4, roof, tile=roof_tile)
    c.vline(x, wy, y + h - 1, K.INK)
    c.vline(x + w - 1, wy, y + h - 1, K.INK)


def drainpipe(c: Canvas, x: int, y0: int, y1: int) -> None:
    c.rect(x - 1, y0, 4, y1 - y0, K.INK)
    c.vline(x, y0, y1 - 1, K.ASH)
    c.vline(x + 1, y0, y1 - 1, K.STONE)
    for yy in range(y0 + 8, y1 - 2, 18):
        c.rect(x - 2, yy, 6, 2, K.SHADOW)
    c.rect(x - 2, y1 - 3, 7, 3, K.INK)
    c.hline(x - 1, x + 3, y1 - 2, K.STONE)


def sidewalk(c: Canvas, y: int, h: int, *, seed: int) -> None:
    flagstones(c, 0, y, W, h, sw=20, sh=9, seed=seed, base=K.FOG, gap=K.ASH, hi=K.PAPERC, lo=K.MIST, crack=0.08)
    c.hline(0, W - 1, y + h - 1, K.STONE)
    c.hline(0, W - 1, y + h, K.SHADOW)


def street(c: Canvas, y: int, h: int, *, seed: int) -> None:
    cobbles(c, 0, y, W, h, cw=9, ch=6, seed=seed, base=K.MIST, gap=K.ASH, hi=K.FOG, lo=K.ASH, alt=K.FOG)


def manhole(c: Canvas, cx: int, cy: int) -> None:
    c.ellipse(cx, cy, 9, 4.5, K.INK)
    c.ellipse(cx, cy, 8, 3.5, K.STONE)
    for xx in range(cx - 6, cx + 7, 3):
        c.vline(xx, cy - 2, cy + 2, K.ASH)
    c.ellipse(cx, cy, 2, 1, K.SHADOW)


def leaves(c: Canvas, x0: int, y0: int, x1: int, y1: int, n: int, seed: int) -> None:
    rng = random.Random(seed)
    for _ in range(n):
        x, y = rng.randint(x0, x1), rng.randint(y0, y1)
        col = rng.choice((K.WOOD, K.SKIN_S, K.STONE))
        c.set(x, y, col)
        c.set(x + 1, y, col)
        c.set(x, y - 1, K.WOOD_D)


def cat(c: Canvas, x: int, y: int, *, fur: str = K.FOG) -> None:
    """식빵 자세로 웅크린 고양이 (중립). (x, y) = 왼쪽 위, 12×8."""
    from sprite import grid
    g = grid("""
        .K.K........
        KfKfK.......
        KffffKKKKK..
        KfKffffffK..
        KffffffffKK.
        .KKKKKKKKfK.
        .........KK.
    """, {"K": K.INK, "f": fur})
    c.blit(g, x, y)


def flower_patch(c: Canvas, cx: int, cy: int, *, seed: int, n: int = 7) -> None:
    rng = random.Random(seed)
    for _ in range(n):
        x = cx + rng.randint(-10, 10)
        y = cy + rng.randint(-4, 4)
        c.set(x, y + 1, K.STONE)
        c.set(x, y + 2, K.ASH)
        col = rng.choice((K.PAPERC, K.FOG, K.PAPER))
        for dx, dy in ((0, -1), (-1, 0), (1, 0), (0, 1)):
            c.set(x + dx, y + dy, col)
        c.set(x, y, K.ASH)


def low_wall_front(c: Canvas, y: int, *, seed: int) -> None:
    """화면 아래 낮은 돌담: 갓돌(윗면) + 앞면."""
    c.rect(0, y, W, 7, K.FOG)
    c.hline(0, W - 1, y, K.PAPERC)
    c.hline(0, W - 1, y - 1, K.INK)
    c.hline(0, W - 1, y + 6, K.MIST)
    stone_wall(c, 0, y + 7, W, H - y - 7, seed=seed)
    c.hline(0, W - 1, y + 7, K.INK)
    c.shade_rect(0, y + 8, W, 3, 1)


def sky(c: Canvas, y0: int, y1: int, *, seed: int, night: bool = False) -> None:
    rng = random.Random(seed)
    c.rect(0, y0, W, y1 - y0, K.PAPERC)
    for _ in range(5):
        cx, cy = rng.randint(0, W), rng.randint(y0 + 4, max(y0 + 5, y1 - 6))
        for k in range(3):
            c.ellipse(cx + k * 9 - 9, cy - (k == 1) * 2, 9, 3.5, K.FOG)


def bunting(c: Canvas, x0: int, x1: int, y: int, sag: int = 6) -> None:
    """줄에 매단 삼각 깃발 (중립)."""
    cols = [K.PAPER, K.ASH, K.FOG, K.STONE]
    n = x1 - x0
    for i in range(n):
        t = i / n
        yy = y + int(sag * 4 * t * (1 - t))
        c.set(x0 + i, yy, K.SHADOW)
        if i % 8 == 2:
            col = cols[(i // 8) % len(cols)]
            for k in range(4):
                c.hline(x0 + i + k // 2, x0 + i + 4 - k // 2, yy + 1 + k, col)
            c.set(x0 + i + 2, yy + 5, K.INK)


def umbrella(c: Canvas, cx: int, cy: int, r: int, *, a: str = K.PAPER, b: str = K.ASH) -> None:
    """위에서 본 둥근 파라솔 (줄무늬 8조각)."""
    import math
    c.shade_ellipse(cx + 4, cy + 6, r, r * 0.6)
    c.ellipse(cx, cy, r + 1, r * 0.62 + 1, K.INK)
    for yy in range(int(cy - r), int(cy + r) + 1):
        for xx in range(int(cx - r - 1), int(cx + r) + 2):
            dx, dy = xx + 0.5 - cx, (yy + 0.5 - cy) / 0.62
            if dx * dx + dy * dy <= r * r:
                ang = math.atan2(dy, dx)
                seg = int((ang + math.pi) / (math.pi / 4)) % 8
                col = a if seg % 2 == 0 else b
                if dy > r * 0.45:
                    col = P.darker(col)
                c.set(xx, yy, col)
    c.ellipse(cx, cy, 1.5, 1.2, K.SHADOW)


def produce_crate(c: Canvas, x: int, y: int, *, seed: int, fruit: str = K.FOG, w: int = 18) -> tuple[int, int, int, int]:
    """과일 상자: 위에서 본 열매 더미 + 앞면."""
    rng = random.Random(seed)
    b = K.crate(c, x, y, w, 9, 6)
    for i in range(w // 4 + 2):
        fx = x + 2 + rng.randint(0, w - 5)
        fy = y + rng.randint(-2, 3)
        c.ellipse(fx + 1.5, fy + 1.5, 2.2, 2.0, K.INK)
        c.ellipse(fx + 1.5, fy + 1.5, 1.6, 1.4, fruit)
        c.set(fx + 1, fy + 1, P.lighter(fruit))
    return b


# ====================================================================== 3. 화실 앞
def atelier_door() -> tuple:
    c = Canvas(W, H, K.INK)
    # 화실 건물 (반목조)
    facade(c, 0, 0, 300, 124, kind="plaster", seed=31, roof=18, timber=False)
    for xx in (0, 100, 186, 296):
        c.rect(xx, 18, 4, 101, K.WOOD_D)
        c.vline(xx + 1, 18, 118, K.WOOD)
    c.rect(0, 60, 300, 4, K.WOOD_D)
    c.hline(0, 299, 60, K.WOOD)
    K.window(c, 30, 30, 34, 26, cols=2, rows=2, shutters=K.WOOD, sill=K.WOOD)
    K.flower_box(c, 28, 60, 38, seed=1)
    K.window(c, 126, 30, 34, 26, cols=2, rows=2, shutters=K.WOOD, sill=K.WOOD)
    K.flower_box(c, 124, 60, 38, seed=2)
    K.window(c, 36, 76, 22, 28, cols=2, rows=2, sill=K.WOOD)
    K.window(c, 132, 76, 22, 28, cols=2, rows=2, sill=K.WOOD)
    K.door(c, 206, 68, 34, 51)
    c.rect(204, 63, 38, 4, K.WOOD_D)                     # 문 위 상인방
    c.hline(204, 241, 63, K.WOOD)
    # 간판: 팔레트 그림
    c.rect(247, 44, 2, 3, K.INK)
    c.hline(244, 274, 42, K.INK)
    c.hline(244, 274, 43, K.SHADOW)
    for sx in (250, 268):
        c.vline(sx, 44, 47, K.INK)
    K.box(c, 246, 47, 28, 18, K.SKIN_L)
    c.frame(247, 48, 26, 16, K.WOOD)
    c.ellipse(260, 56, 9, 5, K.INK)
    c.ellipse(260, 56, 8, 4, K.SKIN_M)
    c.ellipse(265, 57, 1.6, 1.4, K.SKIN_L)
    for i, col in enumerate((K.SHADOW, K.ASH, K.MIST, K.STONE)):
        c.rect(254 + i * 3, 54 + (i % 2), 2, 2, col)
    # 벽등
    c.rect(193, 74, 6, 9, K.INK)
    c.rect(194, 75, 4, 6, K.FOG)
    c.rect(192, 72, 8, 2, K.INK)
    c.hline(194, 197, 83, K.INK)
    # 계단 2단
    for i, (yy, inset) in enumerate(((119, 0), (124, 4))):
        c.rect(198 - inset, yy, 50 + inset * 2, 5, K.INK)
        c.rect(199 - inset, yy, 48 + inset * 2, 4, K.FOG)
        c.hline(199 - inset, 246 + inset, yy, K.PAPERC)

    # 이웃 건물 (벽돌, 문 닫힌 가게)
    facade(c, 300, 0, 180, 124, kind="brick", seed=32, roof=22)
    K.window(c, 320, 40, 30, 30, cols=2, rows=2, sill=K.STONE, curtain=K.MIST)
    K.window(c, 420, 40, 30, 30, cols=2, rows=2, sill=K.STONE, curtain=K.MIST)
    c.rect(360, 72, 50, 47, K.INK)                       # 내린 셔터
    c.rect(361, 73, 48, 46, K.MIST)
    for yy in range(75, 118, 3):
        c.hline(361, 408, yy, K.ASH)
    c.rect(358, 66, 54, 6, K.STONE)
    c.hline(358, 411, 66, K.ASH)
    drainpipe(c, 302, 22, 119)
    drainpipe(c, 474, 22, 119)

    # 보도·길·아래 보도·낮은 담
    sidewalk(c, 119, 16, seed=33)
    for yy, inset in ((118, 0), (123, 4)):                # 계단 (보도보다 어둡게)
        c.rect(198 - inset, yy, 50 + inset * 2, 6, K.INK)
        c.rect(199 - inset, yy, 48 + inset * 2, 4, K.MIST)
        c.hline(199 - inset, 246 + inset, yy, K.FOG)
        c.hline(199 - inset, 246 + inset, yy + 4, K.ASH)
    street(c, 136, 72, seed=34)
    sidewalk(c, 208, 22, seed=36)
    c.hline(0, W - 1, 208, K.SHADOW)
    low_wall_front(c, 236, seed=35)
    manhole(c, 300, 172)
    leaves(c, 20, 140, 470, 228, 40, seed=37)
    cat(c, 152, 228)
    low = []
    for px in (40, 96, 360, 430):                          # 아래 보도의 화분 줄
        low.append(K.potted_plant(c, px, 228, size=10, seed=px))
    low.append(K.lamp_post(c, 70, 226, h=42))
    low.append(K.lamp_post(c, 390, 226, h=42))
    # 소품: 화분, 우편함, 자전거, 상자·통, 왼쪽 울타리
    b1 = K.potted_plant(c, 192, 134, size=10, seed=5)
    b2 = K.potted_plant(c, 255, 134, size=10, seed=6)
    c.rect(282, 112, 3, 22, K.INK)                       # 우편함
    c.vline(283, 113, 133, K.STONE)
    K.box(c, 276, 100, 15, 12, K.ASH)
    c.hline(277, 289, 101, K.MIST)
    c.hline(279, 287, 105, K.SHADOW)
    c.shade_ellipse(285, 134, 7, 2)
    # 자전거 (벽에 기댄)
    for wx in (420, 446):
        c.ellipse(wx, 124, 8, 8, K.INK)
        c.ellipse(wx, 124, 6.6, 6.6, K.FOG)
        c.ellipse(wx, 124, 5.6, 5.6, K.INK)
        c.ellipse(wx, 124, 4.6, 4.6, K.FOG)
        c.remap_where(lambda x, y, wx=wx: (x - wx) ** 2 + (y - 124) ** 2 < 21, {K.INK: K.FOG}, box=(wx - 6, 118, wx + 7, 131))
        c.set(wx, 124, K.SHADOW)
    for (x0, y0, x1, y1) in ((420, 124, 432, 112), (432, 112, 446, 124), (420, 124, 436, 124), (436, 124, 432, 112),
                             (432, 112, 430, 106), (444, 108, 446, 124)):
        c.line(x0, y0, x1, y1, K.SHADOW)
    c.hline(427, 433, 105, K.INK)
    c.hline(441, 447, 107, K.INK)
    b3 = K.barrel(c, 334, 120, w=13, h=16)
    b4 = K.crate(c, 348, 124, 16, 9, 5)
    # 왼쪽 끝: 나무 울타리
    c.rect(0, 128, 12, 110, K.WOOD)
    for yy in range(128, 238, 8):
        c.hline(0, 11, yy, K.WOOD_D)
    c.vline(12, 128, 237, K.INK)
    c.vline(11, 128, 237, K.SKIN_S)

    m = meta(
        walkable=[(14, 130), (480, 130), (480, 228), (14, 228)],
        blockers=[b1, b2, (278, 128, 12, 6), b3, b4, (410, 126, 46, 6)] + low,
        spawns={"default": (223, 140), "from_atelier": (223, 140), "from_lane": (452, 190)},
        exits=[("atelier", (206, 124, 34, 10)), ("lane", (472, 136, 8, 92))],
        props={"door": (223, 119), "sign": (260, 66)},
        notes=("화실 앞 거리 (prologue_door). 무채색 바깥 세계를 처음 보는 장면: 반목조 화실 건물(왼쪽)과 셔터 내린 벽돌 가게(오른쪽), "
               "돌길, 아래쪽 낮은 돌담. 문(door) 앞 계단 위가 화실로 돌아가는 출구, 오른쪽 끝이 골목(lane)으로 이어진다. 잔향 없음."),
    )
    return c.to_image(), m


# ====================================================================== 4. 정원 문
def garden_gate() -> tuple:
    c = Canvas(W, H, K.INK)
    sky(c, 0, 60, seed=41)
    # 먼 언덕과 마을 (밝은 명도 = 멀다)
    c.poly([(0, 58), (90, 40), (190, 52), (300, 36), (400, 48), (480, 42), (480, 96), (0, 96)], K.FOG)
    rng = random.Random(42)
    for i in range(16):
        hx = 30 + i * 28 + rng.randint(-6, 6)
        hy = 50 + (i % 3) * 7 + rng.randint(0, 6)
        hw, hh = rng.randint(14, 22), rng.randint(9, 14)
        c.rect(hx, hy, hw, hh, K.PAPERC)
        c.poly([(hx - 2, hy), (hx + hw // 2, hy - 7), (hx + hw + 1, hy)], K.MIST)
        c.rect(hx + 3, hy + 3, 3, 3, K.MIST)
        if hw > 17:
            c.rect(hx + hw - 7, hy + 3, 3, 3, K.MIST)
    # 먼 시계탑 실루엣
    c.rect(300, 22, 16, 50, K.MIST)
    c.poly([(298, 22), (308, 8), (318, 22)], K.ASH)
    c.ellipse(308, 32, 4, 4, K.FOG)
    c.set(308, 31, K.ASH)
    c.set(309, 32, K.ASH)
    canopy_band(c, -10, W + 10, 82, seed=43, r=12)
    # 담 + 문
    stone_wall(c, 0, 92, W, 36, seed=44)
    c.rect(0, 88, W, 5, K.MIST)
    c.hline(0, W - 1, 88, K.FOG)
    c.hline(0, W - 1, 93, K.INK)
    c.shade_rect(0, 94, W, 2, 1)
    # 문 틈으로 보이는 먼 길
    c.rect(214, 72, 52, 56, K.FOG)
    c.poly([(222, 128), (258, 128), (246, 96), (236, 96)], K.SKIN_L)
    c.poly([(236, 96), (246, 96), (243, 84), (239, 84)], K.PAPER)
    for k, (gx, gy) in enumerate([(220, 90), (256, 86)]):
        K.foliage(c, gx, gy, 6, 5, seed=45 + k, base=K.MIST, dark=K.ASH, light=K.FOG, hi=K.PAPERC, edge=K.ASH)
    # 기둥 + 아치
    for px in (204, 266):
        c.rect(px - 1, 60, 12, 69, K.INK)
        stone_wall(c, px, 66, 10, 62, seed=46 + px, base=K.MIST, gap=K.ASH, hi=K.FOG, lo=K.ASH)
        c.rect(px - 3, 58, 16, 8, K.INK)
        c.rect(px - 2, 59, 14, 6, K.FOG)
        c.hline(px - 2, px + 11, 59, K.PAPERC)
        c.ellipse(px + 5, 54, 4, 4, K.INK)
        c.ellipse(px + 5, 54, 3, 3, K.FOG)
    for i in range(53):
        import math
        t = i / 52
        ax = 214 + i
        ay = int(66 - 10 * math.sin(math.pi * t))
        c.set(ax, ay, K.INK)
        c.set(ax, ay + 1, K.SHADOW)
        c.set(ax, ay + 2, K.INK)
    # 열린 문짝 (안쪽으로 젖혀짐)
    for (x0, x1) in ((214, 220), (260, 266)):
        c.rect(x0, 74, x1 - x0, 54, K.INK)
        for xx in range(x0 + 1, x1, 2):
            c.vline(xx, 75, 127, K.STONE)
        c.hline(x0, x1 - 1, 82, K.ASH)
        c.hline(x0, x1 - 1, 118, K.ASH)
    # 정원 쪽 땅 + 돌길
    grass(c, 0, 128, W, 142, seed=47)
    c.shade_rect(0, 128, W, 4, 1, 10)
    rng = random.Random(48)
    pts = [(10, 200), (34, 196), (60, 192), (88, 186), (116, 178), (144, 168), (170, 158), (196, 148), (218, 140), (240, 134)]
    for px, py in pts:
        rx, ry = rng.randint(7, 9), rng.randint(3, 4)
        c.ellipse(px + 1, py + 1, rx + 1, ry + 1, K.STONE)
        c.ellipse(px, py, rx, ry, K.FOG)
        c.ellipse(px - 1, py - 1, rx - 2, ry - 1.5, K.PAPERC)
        c.set(px + rx - 2, py + 1, K.MIST)
    for k, (fx, fy) in enumerate(((90, 220), (150, 236), (330, 176), (380, 230), (60, 160), (300, 214))):
        flower_patch(c, fx, fy, seed=480 + k)
    # 손수레 (중립)
    c.shade_ellipse(352, 162, 18, 3)
    c.poly([(336, 146), (366, 146), (362, 158), (340, 158)], K.INK)
    c.poly([(337, 147), (365, 147), (361, 157), (341, 157)], K.ASH)
    c.hline(338, 364, 148, K.MIST)
    c.ellipse(334, 159, 4, 4, K.INK)
    c.ellipse(334, 159, 2.5, 2.5, K.STONE)
    c.line(366, 150, 378, 156, K.WOOD)
    c.line(362, 157, 376, 162, K.WOOD)
    c.line(358, 158, 360, 163, K.INK)
    for k in range(3):
        K.foliage(c, 344 + k * 7, 144, 4, 3, seed=300 + k, base=K.MIST, dark=K.STONE, light=K.FOG, hi=K.PAPERC, edge=K.SHADOW)
    # 담 밑 꽃밭 (중립 꽃)
    for x0, x1 in ((8, 196), (284, 472)):
        c.rect(x0, 128, x1 - x0, 10, K.WOOD_D)
        c.hline(x0, x1 - 1, 137, K.SHADOW)
        fr = random.Random(x0)
        for xx in range(x0 + 3, x1 - 3, 5):
            K.foliage(c, xx, 130 + fr.randint(-1, 1), 3.5, 3, seed=fr.randint(0, 99), base=K.ASH, dark=K.STONE,
                      light=K.MIST, hi=None, edge=K.SHADOW)
            c.set(xx + fr.randint(-1, 1), 128 + fr.randint(0, 2), fr.choice((K.PAPERC, K.FOG, K.PAPER)))
    hedge_row(c, -8, W, 246, seed=49)
    t1 = K.tree(c, 420, 216, r=22, seed=50)
    t2 = K.potted_plant(c, 186, 150, size=12, seed=51)
    t3 = K.potted_plant(c, 294, 150, size=12, seed=52)

    m = meta(
        walkable=[(8, 140), (222, 140), (222, 126), (258, 126), (258, 140), (470, 140), (470, 240), (8, 240)],
        blockers=[t1, t2, t3, (334, 152, 34, 8)],
        spawns={"default": (40, 200), "from_garden": (24, 200), "from_path": (240, 138)},
        exits=[("path", (222, 126, 36, 6)), ("garden", (0, 170, 8, 60))],
        props={"gate": (240, 128)},
        notes=("정원 문 (prologue_gate). 돌담 가운데 열린 아치 문 너머로 무채색 마을 원경(지붕들, 먼 시계탑 실루엣)이 보인다. "
               "먼 것일수록 밝은 회색(대기 원근). 왼쪽 끝 = 정원으로 돌아가는 출구, 문 = 오솔길(path)로 나가는 출구. 잔향 없음."),
    )
    return c.to_image(), m


# ====================================================================== 5. 골목
def lane() -> tuple:
    c = Canvas(W, H, K.INK)
    # 건물 세 채 (뒤쪽 벽)
    facade(c, 0, 0, 152, 128, kind="plaster", seed=51, roof=0, timber=True)
    facade(c, 152, 0, 176, 128, kind="brick", seed=52, roof=0)
    facade(c, 328, 0, 152, 128, kind="plaster_cool", seed=53, roof=0)
    c.rect(0, 0, W, 6, K.SHADOW)
    c.hline(0, W - 1, 6, K.INK)
    K.window(c, 24, 18, 26, 24, shutters=K.WOOD, sill=K.WOOD)
    K.window(c, 96, 18, 26, 24, shutters=K.WOOD, sill=K.WOOD)
    K.door(c, 52, 76, 26, 47, wood=K.WOOD_D, pane=False)
    c.rect(48, 70, 34, 4, K.STONE)
    K.window(c, 104, 80, 20, 20, sill=K.WOOD)
    K.window(c, 176, 18, 24, 22, sill=K.STONE)
    K.window(c, 286, 18, 24, 22, sill=K.STONE, curtain=K.MIST)
    # 작은 발코니 + 화분
    c.rect(170, 42, 36, 4, K.INK)
    c.hline(171, 204, 43, K.ASH)
    for xx in range(172, 206, 4):
        c.vline(xx, 46, 54, K.SHADOW)
    c.hline(170, 205, 54, K.INK)
    K.potted_plant(c, 178, 42, size=7, seed=2)
    K.potted_plant(c, 196, 42, size=6, seed=3)
    # 낡은 포스터 두 장 (중립) + 잔향 포스터 자리
    for (px, py, pw, ph, s) in ((214, 74, 16, 20, 1), (300, 70, 18, 22, 2)):
        c.shade_rect(px + 2, py + 2, pw, ph, 1)
        c.rect(px, py, pw, ph, K.FOG)
        c.frame(px, py, pw, ph, K.MIST)
        rr = random.Random(s)
        for k in range(4):
            c.hline(px + 3, px + pw - rr.randint(4, 7), py + 4 + k * 4, K.MIST)
        c.poly([(px + pw - 5, py + ph), (px + pw, py + ph - 6), (px + pw, py + ph)], K.ASH)
    K.door(c, 176, 82, 22, 41, wood=K.STONE, pane=False)
    K.window(c, 352, 20, 24, 24, sill=K.STONE)
    K.window(c, 420, 20, 24, 24, sill=K.STONE, shutters=K.MIST)
    K.window(c, 380, 72, 30, 26, cols=3, rows=2, sill=K.STONE)
    drainpipe(c, 150, 8, 123)
    drainpipe(c, 330, 8, 123)
    # 통풍구
    c.rect(452, 82, 16, 10, K.INK)
    for yy in range(84, 91, 2):
        c.hline(453, 466, yy, K.ASH)
    # 빨랫줄
    for (x0, x1, y0, sag) in ((10, 150, 52, 8), (160, 470, 58, 10)):
        n = x1 - x0
        for i in range(n):
            t = i / n
            c.set(x0 + i, y0 + int(sag * 4 * t * (1 - t)), K.SHADOW)
        rr = random.Random(x0)
        xx = x0 + 10
        while xx < x1 - 20:
            t = (xx - x0) / n
            yy = y0 + int(sag * 4 * t * (1 - t)) + 1
            kind = rr.choice(("shirt", "towel", "sock"))
            col = rr.choice((K.PAPERC, K.FOG, K.MIST, K.PAPER))
            if kind == "shirt":
                c.rect(xx - 1, yy, 16, 13, K.INK)
                c.rect(xx, yy + 1, 14, 11, col)
                c.rect(xx - 3, yy, 4, 5, K.INK)
                c.rect(xx + 13, yy, 4, 5, K.INK)
                c.rect(xx - 2, yy + 1, 3, 3, col)
                c.rect(xx + 14, yy + 1, 3, 3, col)
                c.vline(xx + 7, yy + 1, yy + 11, P.darker(col))
                xx += 26
            elif kind == "towel":
                c.rect(xx - 1, yy, 12, 16, K.INK)
                c.rect(xx, yy + 1, 10, 14, col)
                c.hline(xx, xx + 9, yy + 12, P.darker(col))
                xx += 20
            else:
                c.rect(xx - 1, yy, 5, 9, K.INK)
                c.rect(xx, yy + 1, 3, 7, col)
                xx += 12
            c.set(xx - 4, yy - 1, K.STONE)
    # 길 (좁은 판석)
    flagstones(c, 0, 128, W, 70, sw=18, sh=10, seed=54, base=K.MIST, gap=K.STONE, hi=K.FOG, lo=K.ASH, crack=0.2)
    c.shade_rect(0, 128, W, 6, 1, 10)
    c.rect(0, 160, W, 3, K.ASH)                           # 가운데 배수로
    c.hline(0, W - 1, 160, K.STONE)
    for xx in range(20, W, 60):
        c.rect(xx, 159, 10, 5, K.SHADOW)
        for k in range(xx + 1, xx + 10, 2):
            c.vline(k, 160, 162, K.STONE)
    K.puddle(c, 140, 176, 16, 4)
    K.puddle(c, 372, 150, 10, 3)
    # 앞쪽 건물 지붕 (내려다봄)
    roof_tiles(c, 0, 204, W, 66, tw=8, th=5, base=K.STONE, edge=K.SHADOW, hi=K.ASH)
    c.rect(0, 197, W, 7, K.ASH)                           # 처마 홈통
    c.hline(0, W - 1, 197, K.MIST)
    c.hline(0, W - 1, 203, K.INK)
    c.hline(0, W - 1, 196, K.INK)
    for (cx0, cy0) in ((96, 222), (300, 214), (420, 230)):
        c.rect(cx0 - 1, cy0 - 1, 16, 22, K.INK)
        bricks(c, cx0, cy0, 14, 20, bw=7, bh=4, seed=cx0, brick=K.ASH, mortar=K.STONE, hi=K.MIST)
        c.rect(cx0 - 2, cy0 - 3, 18, 4, K.INK)
        c.rect(cx0 - 1, cy0 - 2, 16, 2, K.MIST)
    for xx in (200, 360):
        c.vline(xx, 204, 269, K.SHADOW)
    # 골목 잡동사니
    bl = []
    bl.append(K.crate(c, 10, 116, 18, 10, 6))
    bl.append(K.crate(c, 16, 104, 14, 9, 5))
    bl.append(K.barrel(c, 128, 110, w=13, h=17))
    # 쓰레기통 두 개 (뚜껑)
    for tx in (294, 312):
        c.shade_ellipse(tx + 8, 128, 8, 2)
        c.rect(tx, 110, 14, 18, K.INK)
        c.rect(tx + 1, 111, 12, 16, K.ASH)
        for xx in range(tx + 3, tx + 12, 3):
            c.vline(xx, 112, 126, K.STONE)
        c.ellipse(tx + 7, 110, 8, 3, K.INK)
        c.ellipse(tx + 7, 109.5, 7, 2, K.MIST)
        c.rect(tx + 5, 106, 4, 2, K.INK)
    bl.append((294, 122, 32, 6))
    bl.append(K.potted_plant(c, 352, 128, size=11, seed=7))
    bl.append(K.potted_plant(c, 366, 128, size=8, seed=8))
    # 사다리 (벽에 기댄)
    for lx in (440, 452):
        c.line(lx, 58, lx + 4, 126, K.WOOD)
    for k in range(7):
        y = 64 + k * 9
        c.hline(441 + k * 4 // 7, 455 + k * 4 // 7, y, K.WOOD_D)
    bl.append((438, 122, 22, 6))
    bl.append(K.crate(c, 196, 186, 16, 7, 5))

    m = meta(
        walkable=[(0, 132), (480, 132), (480, 194), (0, 194)],
        blockers=bl,
        spawns={"default": (24, 166), "from_atelier_door": (16, 166), "from_stairs": (462, 166)},
        exits=[("atelier_door", (0, 136, 8, 56)), ("stairs", (472, 136, 8, 56))],
        props={"lane_poster": (254, 102)},
        notes=("좁은 골목 (ch1_lane). 걸을 수 있는 띠가 y 132~194 로 좁다. 뒤쪽 건물 세 채, 빨랫줄, 앞쪽 건물 지붕(내려다봄). "
               "lane_poster 는 벽돌 건물 벽에 붙는 숨김 잔향: 좌표 = 포스터 바닥 중앙(벽면, 바닥 아님). "
               "그 양옆에 낡은 중립 포스터 두 장을 그려 두어 흑백에서는 섞여 보이게 했다. 상호작용 지점은 포스터 아래 바닥 (254, 136) 권장."),
    )
    return c.to_image(), m


# ====================================================================== 6. 오솔길
def path() -> tuple:
    c = Canvas(W, H, K.INK)
    # 숲 (위쪽)
    c.rect(0, 0, W, 110, K.SHADOW)
    canopy_band(c, -16, W + 16, 14, seed=61, r=26)
    rng = random.Random(62)
    for i in range(14):                                    # 줄기
        tx = 10 + i * 35 + rng.randint(-8, 8)
        c.rect(tx - 3, 40, 7, 64, K.INK)
        c.rect(tx - 2, 40, 5, 64, K.WOOD_D)
        c.vline(tx - 1, 40, 103, K.WOOD)
    canopy_band(c, -10, W + 10, 46, seed=63, r=20)
    # 덤불 줄
    x = -6
    while x < W + 10:
        r = rng.randint(9, 14)
        K.foliage(c, x, 96, r, r * 0.7, seed=rng.randint(0, 999), base=K.ASH, dark=K.STONE, light=K.MIST, hi=K.FOG)
        x += r + rng.randint(3, 8)
    # 풀밭 + 흙길
    grass(c, 0, 106, W, 164, seed=64)
    c.shade_rect(0, 106, W, 5, 1, 10)

    def path_y(x: float) -> float:
        import math
        return 190 - 18 * math.sin(x / 480 * math.pi * 1.4) - x * 0.04

    for xx in range(-4, W + 4):
        yc = path_y(xx)
        half = 13 + 2 * ((xx // 37) % 2)
        for yy in range(int(yc - half), int(yc + half) + 1):
            edge = abs(yy - yc) > half - 2
            c.set(xx, yy, K.SKIN_S if edge else K.SKIN_M)
    pr = random.Random(65)
    for _ in range(260):                                   # 자갈
        xx = pr.randint(0, W - 1)
        yy = int(path_y(xx) + pr.uniform(-10, 10))
        c.set(xx, yy, pr.choice((K.SKIN_S, K.SKIN_L, K.WOOD, K.SKIN_S)))
    for xx in range(0, W, 3):                              # 길 가장자리 풀
        for side in (-1, 1):
            yy = int(path_y(xx) + side * (14 + pr.randint(-1, 1)))
            c.set(xx, yy, K.ASH)
            c.set(xx, yy - 1, K.ASH)
    # 나무 울타리 (위쪽 숲 경계)
    for xx in range(0, W, 24):
        c.rect(xx, 100, 4, 22, K.INK)
        c.rect(xx + 1, 101, 2, 20, K.WOOD)
        c.set(xx + 1, 101, K.SKIN_S)
    for yy in (106, 114):
        c.rect(0, yy, W, 3, K.INK)
        c.hline(0, W - 1, yy + 1, K.SKIN_S)
    c.shade_rect(0, 122, W, 3, 1, 8)
    # 소품: 쓰러진 통나무, 그루터기, 바위, 이정표
    bl = []
    c.shade_ellipse(112, 150, 28, 4)
    c.rect(86, 136, 50, 13, K.INK)
    c.rect(87, 137, 48, 11, K.WOOD)
    c.hline(87, 134, 138, K.SKIN_S)
    c.hline(87, 134, 146, K.WOOD_D)
    c.ellipse(87, 142.5, 4, 6.5, K.INK)
    c.ellipse(87, 142.5, 3, 5.5, K.SKIN_M)
    c.ellipse(87, 142.5, 1.5, 3, K.SKIN_S)
    bl.append((86, 142, 50, 8))
    c.shade_ellipse(404, 232, 12, 3)
    c.rect(394, 222, 18, 10, K.INK)
    c.rect(395, 223, 16, 8, K.WOOD)
    c.ellipse(403, 222, 9, 3.5, K.INK)
    c.ellipse(403, 222, 8, 2.5, K.SKIN_M)
    c.ellipse(403, 222, 4, 1.2, K.SKIN_S)
    bl.append((394, 226, 18, 6))
    for (rx, ry, r) in ((36, 236, 9), (200, 132, 7), (330, 238, 6)):
        c.shade_ellipse(rx + 2, ry + 2, r + 1, r * 0.45)
        c.ellipse(rx, ry, r + 1, r * 0.7 + 1, K.INK)
        c.ellipse(rx, ry, r, r * 0.7, K.ASH)
        c.ellipse(rx - 2, ry - 2, r * 0.55, r * 0.35, K.MIST)
        bl.append((rx - r, ry - 2, 2 * r, 5))
    # 이정표
    c.shade_ellipse(426, 152, 6, 2)
    c.rect(424, 120, 4, 32, K.INK)
    c.vline(425, 121, 151, K.WOOD)
    c.poly([(410, 122), (440, 122), (446, 127), (440, 132), (410, 132)], K.INK)
    c.poly([(411, 123), (439, 123), (444, 127), (439, 131), (411, 131)], K.SKIN_S)
    c.hline(414, 434, 127, K.WOOD)
    bl.append((422, 148, 8, 5))
    for k, (fx, fy) in enumerate(((60, 140), (250, 136), (160, 228), (270, 236), (460, 228), (350, 138), (40, 210))):
        flower_patch(c, fx, fy, seed=660 + k, n=8)
    for k, (bx, by, r) in enumerate(((216, 226, 10), (470, 136, 9), (140, 124, 8))):
        K.foliage(c, bx, by, r, r * 0.7, seed=670 + k, base=K.ASH, dark=K.STONE, light=K.MIST, hi=K.FOG)
        bl.append((bx - r, by, 2 * r, 5))
    hedge_row(c, -8, W, 248, seed=66, r=11)

    m = meta(
        walkable=[(0, 128), (480, 128), (480, 244), (0, 244)],
        blockers=bl,
        spawns={"default": (20, 196), "from_garden_gate": (14, 196), "from_market": (466, 172)},
        exits=[("garden_gate", (0, 160, 8, 64)), ("market", (472, 140, 8, 64))],
        props={"path_lamp": (300, 166), "signpost": (426, 152)},
        notes=("숲가 오솔길 (ch1_path). 위쪽은 나무 울타리 너머 숲, 가운데로 흙길이 왼쪽→오른쪽으로 굽어 지나간다. "
               "path_lamp(온기 잔향 가로등, 높이 약 43px)는 흙길 위쪽 가장자리에 선다. 이정표(signpost)는 조사 지점 후보."),
    )
    return c.to_image(), m


# ====================================================================== 7. 계단길
def stairs() -> tuple:
    c = Canvas(W, H, K.INK)
    stone_wall(c, 0, 0, W, H, seed=70, base=K.ASH, gap=K.STONE, hi=K.MIST, lo=K.STONE)   # 축대(틈 메움)
    for (gx, gy, gw) in ((0, 136, 168), (312, 134, 168)):                                  # 집 사이 화단
        c.rect(gx, gy, gw, 14, K.WOOD_D)
        c.hline(gx, gx + gw - 1, gy, K.SHADOW)
        x = gx + 4
        rr = random.Random(gx)
        while x < gx + gw:
            K.foliage(c, x, gy + 6, 6, 5, seed=rr.randint(0, 999), base=K.ASH, dark=K.STONE, light=K.MIST, hi=K.FOG)
            x += 9
    sky(c, 0, 22, seed=71)
    # 윗길 (광장 쪽)
    flagstones(c, 0, 22, W, 26, sw=20, sh=9, seed=72, base=K.FOG, gap=K.ASH, hi=K.PAPERC, lo=K.MIST)
    for xx in range(0, W, 12):                             # 윗길 난간
        c.rect(xx, 14, 3, 10, K.INK)
        c.vline(xx + 1, 15, 22, K.STONE)
    c.rect(0, 12, W, 3, K.INK)
    c.hline(0, W - 1, 13, K.ASH)
    # 양옆 계단식 집들
    houses = [  # x, y(처마), w, h, kind, side
        (0, 50, 160, 92, "plaster", 0), (0, 150, 166, 120, "brick_warm", 0),
        (320, 44, 160, 96, "plaster_cool", 1), (314, 148, 166, 122, "plaster", 1),
    ]
    for i, (hx, hy, hw, hh, kind, side) in enumerate(houses):
        facade(c, hx, hy, hw, hh, kind=kind, seed=73 + i, roof=16)
        wy = hy + 26
        for k in range(2):
            wx = hx + 22 + k * 64 if side == 0 else hx + 44 + k * 64
            K.window(c, wx, wy, 24, 22, shutters=K.WOOD if (i + k) % 2 else None, sill=K.WOOD)
            K.flower_box(c, wx - 2, wy + 26, 28, seed=i * 3 + k)
        dx = hx + hw - 40 if side == 0 else hx + 14
        K.door(c, dx, hy + hh - 47, 24, 42, wood=K.WOOD if i % 2 else K.WOOD_D)
        c.rect(dx - 4, hy + hh - 5, 32, 5, K.INK)
        c.rect(dx - 3, hy + hh - 5, 30, 4, K.MIST)
    # 계단
    sx0, sx1 = 176, 304
    c.rect(sx0 - 8, 48, sx1 - sx0 + 16, 222, K.STONE)
    y = 269
    k = 0
    while y > 48:
        if 140 <= y <= 170:
            y = 139
            continue
        c.rect(sx0, y - 8, sx1 - sx0, 3, K.ASH)             # 챌판
        c.rect(sx0, y - 5, sx1 - sx0, 5, K.FOG)             # 디딤판
        c.hline(sx0, sx1 - 1, y - 5, K.PAPERC)
        if y - 9 >= 48:
            c.hline(sx0, sx1 - 1, y - 9, K.INK)
        if k % 3 == 1:
            c.set(sx0 + 20 + (k * 37) % 80, y - 3, K.MIST)
        y -= 8
        k += 1
    # 층계참 (넓은 판석)
    flagstones(c, 150, 140, 180, 30, sw=16, sh=10, seed=79, base=K.FOG, gap=K.ASH, hi=K.PAPERC, lo=K.MIST)
    c.hline(150, 329, 140, K.INK)
    c.shade_rect(150, 141, 180, 2, 1)
    # 양쪽 돌 난간벽 + 손잡이
    for (x0, y0, y1) in ((168, 48, 140), (304, 48, 140), (168, 170, 270), (304, 170, 270)):
        c.rect(x0, y0, 8, y1 - y0, K.INK)
        c.rect(x0 + 1, y0, 6, y1 - y0, K.MIST)
        c.vline(x0 + 1, y0, y1 - 1, K.FOG)
        for yy in range(y0 + 6, y1, 14):
            c.hline(x0 + 1, x0 + 6, yy, K.ASH)
    for hx in (172, 307):
        c.vline(hx, 48, 139, K.SHADOW)
        c.vline(hx, 171, 269, K.SHADOW)
    # 계단 위 화분들
    bl = []
    for (px, py, s) in ((186, 232, 9), (292, 208, 8), (162, 166, 11), (320, 166, 10), (190, 110, 8), (290, 82, 9)):
        bl.append(K.potted_plant(c, px, py, size=s, seed=px))
    K.lamp_post(c, 158, 140, h=40)
    K.lamp_post(c, 322, 140, h=40)

    m = meta(
        walkable=[(178, 50), (302, 50), (302, 142), (328, 142), (328, 168), (302, 168), (302, 269),
                  (178, 269), (178, 168), (152, 168), (152, 142), (178, 142)],
        blockers=[b for b in bl if 150 <= b[0] <= 330],
        spawns={"default": (240, 256), "from_lane": (240, 262), "from_square": (240, 58)},
        exits=[("lane", (178, 262, 124, 8)), ("square", (178, 48, 124, 6))],
        props={"landing": (240, 156)},
        notes=("계단길 (ch1_stairs). 화면 아래(골목)에서 위(광장 윗길)로 오르는 돌계단. 가운데 층계참(landing)이 넓어서 "
               "'닮은 습관(하늘 쪽)' 연출 자리로 쓰기 좋다. 양옆은 계단식으로 올라가는 집 정면. 계단 단차 = 8px. 잔향 없음."),
    )
    return c.to_image(), m


# ====================================================================== 8. 시장
def market() -> tuple:
    c = Canvas(W, H, K.INK)
    facade(c, 0, 0, 170, 112, kind="plaster", seed=81, roof=16, timber=True)
    facade(c, 170, 0, 150, 112, kind="brick_warm", seed=82, roof=20)
    facade(c, 320, 0, 160, 112, kind="plaster_cool", seed=83, roof=16)
    for wx in (20, 120, 200, 270, 350, 430):
        K.window(c, wx, 26, 22, 18, sill=K.WOOD)
    bunting(c, 0, 240, 52, sag=10)
    bunting(c, 240, 480, 50, sag=12)
    # 가게 차양 + 진열대
    bl = []
    for (ax, aw, a, b, s) in ((10, 140, K.PAPER, K.ASH, 1), (180, 130, K.FOG, K.STONE, 2), (330, 140, K.PAPERC, K.MIST, 3)):
        c.rect(ax + 4, 64, aw - 8, 44, K.SHADOW)              # 가게 안 어둠
        K.awning(c, ax, 58, aw, 14, a=a, b=b)
        # 진열대
        c.rect(ax + 2, 98, aw - 4, 24, K.INK)
        c.rect(ax + 3, 99, aw - 6, 6, K.SKIN_S)
        c.rect(ax + 3, 105, aw - 6, 16, K.WOOD)
        for xx in range(ax + 8, ax + aw - 6, 10):
            c.vline(xx, 106, 120, K.WOOD_D)
        rr = random.Random(s)
        xx = ax + 6
        while xx < ax + aw - 22:
            fruit = rr.choice((K.FOG, K.MIST, K.PAPERC, K.ASH, K.SKIN_M))
            produce_crate(c, xx, 90, seed=rr.randint(0, 999), fruit=fruit, w=18)
            xx += 21
        bl.append((ax + 2, 114, aw - 4, 8))
        # 매단 간판
        c.vline(ax + aw // 2, 72, 76, K.INK)
        K.box(c, ax + aw // 2 - 10, 76, 20, 9, K.SKIN_L)
        c.hline(ax + aw // 2 - 6, ax + aw // 2 + 5, 80, K.WOOD)
    # 길
    street(c, 122, 92, seed=84)
    c.shade_rect(0, 122, W, 3, 1, 10)
    flagstones(c, 0, 218, W, 52, sw=22, sh=11, seed=85, base=K.FOG, gap=K.ASH, hi=K.PAPERC, lo=K.MIST, crack=0.1)
    leaves(c, 10, 130, 470, 206, 30, seed=86)
    manhole(c, 300, 168)
    # 앞쪽 노점: 파라솔 + 바구니
    for (ux, uy, a, b) in ((70, 236, K.PAPER, K.SKIN_M), (230, 244, K.FOG, K.MIST), (400, 236, K.PAPERC, K.FOG)):
        c.rect(ux - 26, uy - 12, 52, 30, K.INK)
        c.rect(ux - 25, uy - 11, 50, 28, K.WOOD)
        c.hline(ux - 25, ux + 24, uy - 11, K.SKIN_S)
        umbrella(c, ux, uy - 8, 30, a=a, b=b)
    c.rect(0, 214, W, 4, K.STONE)
    c.hline(0, W - 1, 214, K.ASH)
    for (bx, by) in ((150, 208), (164, 210), (330, 206)):
        c.shade_ellipse(bx + 6, by + 6, 8, 2)
        c.ellipse(bx + 5, by, 7, 3, K.INK)
        c.rect(bx - 2, by, 15, 7, K.INK)
        c.rect(bx - 1, by, 13, 6, K.SKIN_S)
        for xx in range(bx, bx + 12, 2):
            c.vline(xx, by + 1, by + 5, K.WOOD)
        c.ellipse(bx + 5, by, 6, 2, K.SKIN_M)
        for k in range(4):
            c.set(bx + 2 + k * 2, by - 1, K.FOG)
        bl.append((bx - 2, by + 2, 15, 5))
    bl.append(K.barrel(c, 448, 194, w=12, h=15))
    bl.append(K.crate(c, 20, 196, 16, 8, 5))

    m = meta(
        walkable=[(0, 126), (480, 126), (480, 210), (0, 210)],
        blockers=bl,
        spawns={"default": (20, 170), "from_path": (14, 170), "from_square": (466, 170)},
        exits=[("path", (0, 136, 8, 64)), ("square", (472, 136, 8, 64))],
        props={"stall_left": (80, 124), "stall_mid": (245, 124), "stall_right": (400, 124)},
        notes=("시장 거리 (ch1_market). 위쪽 가게 세 곳(줄무늬 차양 + 과일 진열대), 아래쪽 파라솔 노점. 과일도 모두 회색(색을 잃은 세계). "
               "걸을 수 있는 띠 y 126~210. stall_* = 상인 NPC 가 서기 좋은 자리. '닮은 습관(별 쪽)' 연출은 가운데 진열대 앞 권장. 잔향 없음."),
    )
    return c.to_image(), m


# ====================================================================== 9·10. 광장 (낮·밤)
def square_scene(night: bool = False) -> tuple:
    c = Canvas(W, H, K.INK)
    sky(c, 0, 24, seed=91)
    windows = []
    # 양옆 건물 + 가운데 시청
    facade(c, 0, 14, 140, 100, kind="brick", seed=92, roof=16)
    facade(c, 340, 14, 140, 100, kind="plaster", seed=93, roof=16, timber=True)
    facade(c, 140, 0, 200, 114, kind="plaster_cool", seed=94, roof=0)
    c.rect(136, 0, 208, 8, K.STONE)                        # 시청 처마 돌림띠
    c.hline(136, 343, 7, K.INK)
    c.hline(136, 343, 1, K.MIST)
    # 시청: 박공 + 둥근 창 자리(빈 원형 장식) + 기둥 + 아치 입구
    c.poly([(196, 8), (240, 0), (284, 8)], K.FOG)
    for xx in range(150, 334, 26):
        c.rect(xx, 12, 8, 98, K.INK)
        c.rect(xx + 1, 12, 6, 98, K.PAPERC)
        c.vline(xx + 6, 12, 109, K.FOG)
        c.rect(xx - 1, 12, 10, 3, K.FOG)
    for (wx, wy) in ((160, 22), (186, 22), (264, 22), (290, 22), (160, 60), (290, 60)):
        windows.append((wx, wy, 14, 22))
    c.rect(212, 66, 56, 48, K.INK)                         # 아치 입구
    c.rect(214, 70, 52, 44, K.SHADOW)
    for i in range(52):
        import math
        yy = int(70 - 8 * math.sin(math.pi * i / 51))
        c.vline(214 + i, yy, 70, K.SHADOW)
        c.set(214 + i, yy - 1, K.INK)
    K.door(c, 226, 76, 28, 38, wood=K.WOOD_D, pane=False)
    c.ellipse(240, 40, 12, 12, K.INK)                      # 둥근 장식 (시계 없음: 시계는 잔향 소품)
    c.ellipse(240, 40, 11, 11, K.FOG)
    c.ellipse(240, 40, 8, 8, K.MIST)
    c.ellipse(240, 40, 7, 7, K.FOG)
    for (wx, wy) in ((20, 40), (90, 40), (360, 40), (430, 40), (20, 74), (430, 74)):
        windows.append((wx, wy, 22, 20))
    for (wx, wy, ww, wh) in windows:
        K.window(c, wx, wy, ww, wh, sill=K.STONE)
    K.awning(c, 64, 70, 60, 10, a=K.PAPER, b=K.ASH)
    K.door(c, 76, 82, 22, 31, wood=K.WOOD)
    K.awning(c, 356, 70, 60, 10, a=K.FOG, b=K.STONE)
    K.door(c, 376, 82, 22, 31, wood=K.WOOD_D)
    # 시청 계단
    for i in range(3):
        c.rect(196 - i * 6, 114 + i * 4, 88 + i * 12, 4, K.INK)
        c.rect(197 - i * 6, 114 + i * 4, 86 + i * 12, 3, K.FOG)
        c.hline(197 - i * 6, 282 + i * 6, 114 + i * 4, K.PAPERC)
    # 광장 바닥: 판석 + 가운데 원형 무늬
    flagstones(c, 0, 114, W, 156, sw=24, sh=12, seed=95, base=K.MIST, gap=K.ASH, hi=K.FOG, lo=K.ASH, crack=0.1)
    for i in range(3):                                     # 계단 다시 (바닥 위)
        c.rect(196 - i * 6, 114 + i * 4, 88 + i * 12, 4, K.INK)
        c.rect(197 - i * 6, 114 + i * 4, 86 + i * 12, 3, K.FOG)
        c.hline(197 - i * 6, 282 + i * 6, 114 + i * 4, K.PAPERC)
    c.shade_rect(0, 114, 190, 3, 1, 10)
    c.shade_rect(290, 114, 190, 3, 1, 10)
    cx, cy = 240, 186
    for (rx, ry, col) in ((60, 30, K.ASH), (58, 28.5, K.FOG), (50, 24.5, K.MIST), (42, 20.5, K.FOG),
                          (40, 19.5, K.ASH), (28, 13.5, K.MIST), (26, 12.5, K.FOG), (12, 6, K.ASH), (11, 5.4, K.PAPERC)):
        c.ellipse(cx, cy, rx, ry, col)
    import math
    for k in range(16):                                    # 바큇살 무늬
        a = k * math.pi / 8
        for t in range(14, 40):
            c.set(int(cx + math.cos(a) * t * 1.45), int(cy + math.sin(a) * t * 0.71), K.ASH)
    # 나무 화단 4개, 가로등, 벤치(중립)
    bl = []
    lamps = []
    for (tx, ty) in ((44, 172), (436, 172), (60, 252), (420, 252)):
        c.ellipse(tx + 2, ty + 3, 18, 7, K.ASH)              # 바닥 그늘
        c.ellipse(tx, ty, 18, 8, K.INK)
        c.ellipse(tx, ty, 17, 7, K.FOG)                      # 돌 테두리 (밝게)
        c.ellipse(tx, ty + 1, 17, 6, K.MIST)
        c.ellipse(tx, ty - 0.5, 14, 4.5, K.SHADOW)
        c.ellipse(tx, ty, 13, 4, K.WOOD_D)                   # 흙
        bl.append((tx - 16, ty - 5, 32, 10))
        K.tree(c, tx, ty, r=18, seed=tx + ty, trunk_h=14)
    for (lx, ly) in ((150, 148), (330, 148), (150, 236), (330, 236)):
        bl.append(K.lamp_post(c, lx, ly, h=40, lit=night))
        lamps.append((lx, ly))
    for (bx, by) in ((88, 128), (360, 128), (196, 236)):
        bl.append(K.bench(c, bx, by, w=32))
    # 비둘기 (중립) 몇 마리
    for (px, py) in ((270, 140), (276, 144), (110, 210)):
        c.rect(px, py, 4, 3, K.INK)
        c.rect(px + 1, py, 2, 2, K.MIST)
        c.set(px + 4, py, K.INK)

    if night:
        c.remap_all(P.NIGHT)
        # 하늘: 짙게 + 별
        c.rect(0, 0, W, 14, K.SHADOW)
        sr = random.Random(97)
        for _ in range(26):
            sx, sy = sr.randint(0, W - 1), sr.randint(0, 12)
            if c.get(sx, sy) == K.SHADOW:
                c.set(sx, sy, sr.choice((K.FOG, K.MIST, K.PAPERC)))
        # 불 켜진 창 (몇 개만)
        for i, (wx, wy, ww, wh) in enumerate(windows):
            if i % 3 != 1:
                K.window(c, wx, wy, ww, wh, sill=K.STONE, lit=True)
                c.light_rect(wx - 4, wy + wh + 2, ww + 8, 6, 1, 6)
        K.door(c, 226, 76, 28, 38, wood=K.WOOD_D, pane=False)
        # 가로등 빛 웅덩이
        for (lx, ly) in lamps:
            c.glow(lx, ly + 2, 40, 18, rings=((1.0, 4), (0.75, 8), (0.5, 16)))
            c.glow(lx, ly - 46, 10, 10, rings=((1.0, 8), (0.6, 16)))
            K.lamp_post(c, lx, ly, h=40, lit=True)
        c.glow(240, 120, 40, 10, rings=((1.0, 6), (0.6, 12)))   # 시청 입구 불빛

    props = {"square_clock": (176, 176), "square_bench": (378, 212), "square_fountain": (cx, cy), "town_hall_door": (240, 114)}
    notes = ("마을 광장 (ch1_square, ch1_square_02). 위쪽 가운데 시청(둥근 장식만, 시계 없음), 양옆 상점. 가운데 원형 바닥 무늬. "
             "나무 화단 4, 가로등 4(중립), 중립 벤치 3. square_clock(그리움)과 square_bench(온기)는 잔향 소품 자리: "
             "중립 벤치와 모양이 같지만 노란 벤치는 흑백에서도 한 단계 밝다. square_fountain = ch5 잔향 자리(이번 범위 밖, 가운데 무늬 위). "
             "아래 왼쪽 = 계단길(stairs), 오른쪽 = 시장(market) 출구.")
    if night:
        notes = ("광장 밤 (ch1_night). square.png 와 배치·좌표가 같다(이 json 은 square.json 과 같은 값). "
                 "어두운 명도로 바꾸고 일부 창과 가로등 4개에 빛(밝은 디더 웅덩이)을 넣었다. 잔향 소품은 엔진이 같은 좌표에 그린다.")
    m = meta(
        walkable=[(16, 120), (464, 120), (464, 150), (480, 150), (480, 214), (464, 214), (464, 254),
                  (110, 254), (110, 269), (16, 269)],
        blockers=bl,
        spawns={"default": (240, 226), "from_stairs": (60, 262), "from_market": (468, 182)},
        exits=[("stairs", (16, 262, 94, 8)), ("market", (472, 152, 8, 60))],
        props=props,
        notes=notes,
    )
    return c.to_image(), m


def square() -> tuple:
    return square_scene(False)


def square_night() -> tuple:
    return square_scene(True)


SCENES = {
    "atelier_door": atelier_door,
    "garden_gate": garden_gate,
    "lane": lane,
    "path": path,
    "stairs": stairs,
    "market": market,
    "square": square,
    "square_night": square_night,
}
