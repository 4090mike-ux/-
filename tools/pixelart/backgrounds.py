"""배경 10종 (480×270) + 메타데이터.

시점: 프로토타입(echo_prototype.gd)과 같은 3/4 탑다운. 화면 위쪽 = 벽·건물 정면(세로면), 아래쪽 = 바닥(가로면).
색: 중립색만(check_art.py 가 검사). 잔향 소품은 그리지 않고 props 좌표만 남긴다.

메타데이터 (game/art/bg/<이름>.json, 좌표 = 픽셀)
  walkable : 다각형 하나. 캐릭터 '발'이 있을 수 있는 영역
  blockers : [x, y, w, h]  walkable 안의 가구·물건 발밑 (충돌)
  spawns   : {"default": [x, y], "from_<출구>": [x, y]}  캐릭터 발 위치
  exits    : [{"name": 목적지 배경 이름, "rect": [x, y, w, h]}]
  props    : {"<잔향 slug 또는 소품>": [x, y]}  소품 스프라이트의 바닥 중앙
  notes    : 설명
"""
from __future__ import annotations

import random

import bgkit as K
from canvas import Canvas, planks, plaster

W, H = 480, 270


def meta(walkable, blockers, spawns, exits, props, notes) -> dict:
    return {
        "size": [W, H],
        "walkable": [list(p) for p in walkable],
        "blockers": [list(b) for b in blockers],
        "spawns": {k: list(v) for k, v in spawns.items()},
        "exits": [{"name": n, "rect": list(r)} for n, r in exits],
        "props": {k: list(v) for k, v in props.items()},
        "notes": notes,
    }


def splatter(c: Canvas, cx: int, cy: int, r: int, n: int, seed: int, colors=(K.MIST, K.FOG, K.ASH, K.PAPERC)) -> None:
    rng = random.Random(seed)
    for _ in range(n):
        x = cx + rng.randint(-r, r)
        y = cy + rng.randint(-r // 2, r // 2)
        col = rng.choice(colors)
        c.set(x, y, col)
        if rng.random() < 0.35:
            c.set(x + 1, y, col)
        if rng.random() < 0.15:
            c.set(x, y + 1, col)
            c.set(x + 1, y + 1, col)


def interior_shell(c: Canvas, wall_bottom: int = 119) -> None:
    """방 테두리: 위 천장선, 좌우 벽 윗면, 아래 앞벽 윗면."""
    c.rect(0, 0, W, 8, K.SHADOW)
    c.hline(0, W - 1, 7, K.INK)
    c.rect(0, 0, 16, H, K.SHADOW)
    c.rect(W - 16, 0, 16, H, K.SHADOW)
    c.vline(15, 8, H - 17, K.STONE)
    c.vline(W - 16, 8, H - 17, K.STONE)
    c.vline(14, 8, H - 17, K.INK)
    c.vline(W - 15, 8, H - 17, K.INK)
    c.rect(0, H - 16, W, 16, K.SHADOW)
    c.hline(14, W - 15, H - 16, K.STONE)
    c.hline(14, W - 15, H - 17, K.INK)
    # 구석 그늘 (벽과 바닥이 만나는 곳)
    c.shade_rect(16, wall_bottom + 1, 448, 3, 1, 10)
    c.shade_rect(16, 8, 3, H - 24, 1, 8)
    c.shade_rect(W - 19, 8, 3, H - 24, 1, 8)


# ====================================================================== 1. 화실
def atelier() -> tuple:
    c = Canvas(W, H, K.INK)
    # 벽: 회벽 + 나무 징두리판
    plaster(c, 16, 8, 448, 88, seed=11)
    c.shade_rect(16, 8, 448, 5, 1, 6)
    c.rect(16, 96, 448, 24, K.WOOD)
    c.hline(16, 463, 96, K.SKIN_S)
    c.hline(16, 463, 97, K.WOOD)
    c.hline(16, 463, 98, K.WOOD_D)
    for px in range(20, 460, 40):
        c.frame(px, 102, 34, 12, K.WOOD_D)
        c.hline(px + 1, px + 32, 103, K.SKIN_S)
    c.rect(16, 116, 448, 4, K.WOOD_D)
    c.hline(16, 463, 119, K.SHADOW)
    # 바닥: 마루
    planks(c, 16, 120, 448, 134, plank_h=7, seed=12)
    interior_shell(c)

    # 큰 창 + 커튼 + 창빛
    K.window(c, 44, 24, 88, 62, cols=3, rows=2, curtain=K.FOG, view=K.MIST)
    c.light_poly([(40, 120), (136, 120), (190, 206), (94, 206)], 1, 6)
    c.light_poly([(50, 120), (126, 120), (176, 198), (100, 198)], 1, 16)
    K.potted_plant(c, 120, 88, size=8, seed=3)
    K.jar(c, 56, 88, w=5, h=6, body=K.MIST)

    # 선반 두 단
    for sy in (50, 78):
        c.rect(150, sy, 84, 3, K.WOOD)
        c.hline(150, 233, sy, K.SKIN_S)
        c.hline(150, 233, sy + 3, K.INK)
        c.shade_rect(151, sy + 4, 82, 3, 1, 8)
        for bx in (154, 228):
            c.rect(bx, sy + 3, 2, 4, K.WOOD_D)
    K.books(c, 152, 50, 34, seed=4)
    K.jar(c, 192, 50, w=6, h=9, body=K.FOG)
    K.jar(c, 202, 50, w=5, h=6, body=K.ASH)
    # 석고 흉상
    c.ellipse(220, 39, 5, 6, K.INK)
    c.ellipse(220, 39, 4, 5, K.PAPERC)
    c.rect(214, 44, 13, 6, K.INK)
    c.rect(215, 45, 11, 5, K.FOG)
    c.set(222, 38, K.FOG)
    c.vline(223, 36, 41, K.FOG)
    K.jar(c, 156, 78, w=7, h=10, body=K.STONE)
    c.rect(168, 72, 14, 6, K.PAPERC)          # 종이 더미
    c.frame(168, 72, 14, 6, K.INK)
    c.hline(169, 180, 74, K.FOG)
    K.books(c, 186, 78, 44, seed=5, max_h=11)

    # 그림 (H.S 서명)
    fx, fy, fw, fh = 248, 22, 66, 50
    c.rect(fx - 1, fy - 1, fw + 2, fh + 2, K.INK)
    c.rect(fx, fy, fw, fh, K.WOOD_D)
    c.frame(fx + 1, fy + 1, fw - 2, fh - 2, K.WOOD)
    ix, iy, iw, ih = fx + 3, fy + 3, fw - 6, fh - 6
    c.rect(ix, iy, iw, ih, K.FOG)
    c.rect(ix, iy, iw, 12, K.PAPERC)
    c.ellipse(ix + 44, iy + 10, 5, 5, K.PAPER)
    c.poly([(ix, iy + 28), (ix + 14, iy + 18), (ix + 26, iy + 24), (ix + 40, iy + 15), (ix + iw, iy + 26), (ix + iw, iy + ih), (ix, iy + ih)], K.MIST)
    c.poly([(ix, iy + 34), (ix + 20, iy + 28), (ix + 38, iy + 33), (ix + iw, iy + 30), (ix + iw, iy + ih), (ix, iy + ih)], K.ASH)
    c.rect(ix + 12, iy + 22, 2, 10, K.SHADOW)
    c.ellipse(ix + 13, iy + 20, 5, 4, K.STONE)
    c.rect(ix + iw - 18, iy + ih - 8, 18, 8, K.MIST)          # 그림 속 밝은 풀밭 (서명 바탕)
    c.hline(ix + iw - 22, ix + iw - 19, iy + ih - 8, K.MIST)
    sig_end = c.text("H.S", ix + iw - 13, iy + ih - 6, K.SHADOW)
    c.shade_rect(fx, fy + fh + 1, fw + 2, 2, 1)

    # 핀으로 꽂은 스케치들
    for (sx, sy, sw, sh), seed in zip([(326, 26, 18, 22), (346, 22, 20, 16), (348, 42, 16, 22), (368, 28, 22, 18), (370, 50, 18, 18)], range(5)):
        c.shade_rect(sx + 2, sy + 2, sw, sh, 1)
        c.rect(sx, sy, sw, sh, K.PAPERC)
        c.frame(sx, sy, sw, sh, K.MIST)
        rng = random.Random(seed + 40)
        for _ in range(3):
            y = sy + rng.randint(4, sh - 4)
            x0 = sx + rng.randint(2, 5)
            c.line(x0, y, sx + sw - rng.randint(3, 6), y + rng.randint(-3, 3), K.ASH)
        c.ellipse(sx + sw // 2, sy + sh // 2 + 1, 3, 2, K.MIST)
        c.set(sx + sw // 2, sy + 1, K.STONE)

    # 서랍장
    cx0, cy0, cw, ch = 334, 80, 60, 46
    c.rect(cx0 - 1, cy0 - 7, cw + 2, ch + 8, K.INK)
    c.rect(cx0, cy0 - 6, cw, 6, K.SKIN_S)
    c.hline(cx0, cx0 + cw - 1, cy0 - 6, K.SKIN_M)
    c.rect(cx0, cy0, cw, ch, K.WOOD)
    for i in range(3):
        dy = cy0 + 3 + i * 14
        c.frame(cx0 + 3, dy, cw - 6, 12, K.WOOD_D)
        c.hline(cx0 + 4, cx0 + cw - 5, dy + 1, K.SKIN_S)
        for kx in (cx0 + 14, cx0 + cw - 16):
            c.rect(kx, dy + 5, 3, 2, K.MIST)
    c.rect(cx0 + 2, cy0 + ch - 2, 4, 2, K.WOOD_D)
    c.rect(cx0 + cw - 6, cy0 + ch - 2, 4, 2, K.WOOD_D)
    K.jar(c, cx0 + 8, cy0 - 6, w=6, h=7, body=K.FOG)
    c.rect(cx0 + 22, cy0 - 10, 24, 4, K.PAPERC)       # 말아 둔 종이
    c.frame(cx0 + 22, cy0 - 10, 24, 4, K.INK)
    c.vline(cx0 + 27, cy0 - 9, cy0 - 8, K.MIST)
    c.ellipse(cx0 + 52, cy0 - 9, 3, 3, K.INK)
    c.ellipse(cx0 + 52, cy0 - 9, 2, 2, K.PAPERC)
    c.shade_rect(cx0 - 2, cy0 + ch, cw + 6, 3, 1)

    # 기대 놓은 캔버스들 (뒷면)
    for (x, y, w, h) in [(252, 92, 30, 34), (268, 98, 26, 28), (286, 104, 18, 22)]:
        c.rect(x - 1, y - 1, w + 2, h + 2, K.INK)
        c.rect(x, y, w, h, K.WOOD)
        c.rect(x + 2, y + 2, w - 4, h - 4, K.SKIN_L)
        c.hline(x + 2, x + w - 3, y + h // 2, K.WOOD)          # 캔버스 틀 십자 버팀목
        c.vline(x + w // 2, y + 2, y + h - 3, K.WOOD)
        c.vline(x + w - 3, y + 2, y + h - 3, K.SKIN_M)
        c.set(x + 3, y + 3, K.WOOD_D)
        c.set(x + w - 4, y + 3, K.WOOD_D)
    c.shade_rect(252, 127, 54, 3, 1)

    # 문 + 발판 + 옷걸이
    K.door(c, 410, 70, 32, 49)
    K.rug(c, 406, 121, 40, 8, base=K.STONE, border=K.SHADOW, pattern=K.ASH)
    c.rect(452, 66, 3, 58, K.INK)
    c.vline(453, 67, 122, K.WOOD)
    c.rect(448, 122, 11, 3, K.INK)
    c.hline(449, 457, 123, K.WOOD_D)
    c.rect(447, 70, 13, 2, K.INK)
    c.poly([(447, 72), (458, 72), (461, 104), (444, 104)], K.INK)   # 걸어 둔 외투
    c.poly([(448, 73), (457, 73), (460, 103), (445, 103)], K.STONE)
    c.line(452, 74, 450, 102, K.SHADOW)
    c.line(453, 74, 455, 102, K.ASH)
    c.rect(449, 70, 7, 3, K.FOG)                                 # 목도리
    c.vline(450, 73, 84, K.FOG)
    c.vline(451, 73, 82, K.MIST)
    for hx in (446, 459):                                        # 고리
        c.set(hx, 68, K.INK)
        c.set(hx, 69, K.INK)

    # 바닥: 러그, 물감 자국
    K.rug(c, 262, 176, 104, 50)
    splatter(c, 156, 168, 28, 40, seed=7)
    splatter(c, 216, 236, 18, 14, seed=8)

    # 낡은 소파 (왼쪽 벽에 붙어 오른쪽을 본다) + 흘러내린 담요 — 하늘이 깨어나는 곳
    sx0, sy0 = 18, 140
    fab, fab_hi, fab_lo, fab_dk = K.SKIN_S, K.SKIN_M, K.WOOD, K.WOOD_D
    c.shade_rect(sx0 + 6, sy0 + 10, 46, 84, 1, 10)
    c.rect(sx0, sy0 + 1, 41, 89, K.INK)
    c.rect(sx0 + 1, sy0 + 6, 13, 78, fab)                        # 등받이 (벽 쪽)
    c.vline(sx0 + 1, sy0 + 6, sy0 + 83, fab_lo)
    c.vline(sx0 + 4, sy0 + 6, sy0 + 83, fab_hi)
    c.vline(sx0 + 13, sy0 + 6, sy0 + 83, fab_dk)
    for by in range(sy0 + 18, sy0 + 80, 13):                      # 단추 장식
        c.set(sx0 + 8, by, fab_dk)
        c.set(sx0 + 8, by - 1, fab_hi)
    for i in range(3):                                            # 앉는 쿠션 3개 (둥근 모서리)
        cy = sy0 + 14 + i * 21
        c.rect(sx0 + 14, cy, 26, 20, fab_lo)
        c.rect(sx0 + 15, cy + 1, 24, 18, fab)
        c.hline(sx0 + 16, sx0 + 37, cy + 1, fab_hi)
        c.rect(sx0 + 17, cy + 3, 9, 5, fab_hi)
        c.hline(sx0 + 15, sx0 + 38, cy + 18, fab_lo)
        for x, y in ((sx0 + 14, cy), (sx0 + 39, cy), (sx0 + 14, cy + 19), (sx0 + 39, cy + 19)):
            c.set(x, y, K.INK)
    for x, y in ((sx0 + 30, sy0 + 44), (sx0 + 31, sy0 + 44), (sx0 + 22, sy0 + 66)):
        c.set(x, y, K.SKIN_L)                                     # 닳아 반들반들한 자리
    for ay in (sy0, sy0 + 76):                                     # 둥근 팔걸이 (윗면 + 앞면)
        c.rect(sx0, ay, 41, 14, K.INK)
        c.rect(sx0 + 1, ay + 1, 39, 8, fab)
        c.hline(sx0 + 2, sx0 + 38, ay + 2, fab_hi)
        c.hline(sx0 + 2, sx0 + 38, ay + 3, fab_hi)
        c.rect(sx0 + 1, ay + 9, 39, 4, fab_lo)
        c.hline(sx0 + 1, sx0 + 39, ay + 12, fab_dk)
        c.set(sx0 + 1, ay + 1, K.INK)
        c.set(sx0 + 39, ay + 1, K.INK)
    for fx in (sx0 + 2, sx0 + 35):                                 # 나무 다리
        c.rect(fx, sy0 + 90, 4, 2, K.INK)
        c.hline(fx + 1, fx + 2, sy0 + 90, fab_dk)
    c.rect(sx0 + 16, sy0 + 15, 13, 10, K.INK)                     # 베개
    c.rect(sx0 + 17, sy0 + 16, 11, 8, K.PAPERC)
    c.hline(sx0 + 17, sx0 + 27, sy0 + 23, K.FOG)
    c.set(sx0 + 22, sy0 + 19, K.FOG)
    blanket = [(sx0 + 18, sy0 + 32), (sx0 + 38, sy0 + 30), (sx0 + 42, sy0 + 38), (sx0 + 60, sy0 + 46),
               (sx0 + 62, sy0 + 68), (sx0 + 52, sy0 + 72), (sx0 + 40, sy0 + 64), (sx0 + 32, sy0 + 66), (sx0 + 19, sy0 + 58)]
    c.poly([(x + 1, y + 1) for x, y in blanket], K.INK)
    c.poly(blanket, K.PAPER)
    for k in range(4):                                             # 담요 체크무늬·주름
        c.line(sx0 + 22 + k * 9, sy0 + 33, sx0 + 26 + k * 9, sy0 + 62, K.SKIN_M)
    c.line(sx0 + 20, sy0 + 46, sx0 + 58, sy0 + 54, K.SKIN_M)
    c.line(sx0 + 42, sy0 + 42, sx0 + 54, sy0 + 68, K.SKIN_L)
    c.line(sx0 + 46, sy0 + 42, sx0 + 60, sy0 + 62, K.SKIN_M)
    c.shade_poly([(sx0 + 42, sy0 + 40), (sx0 + 44, sy0 + 40), (sx0 + 44, sy0 + 66), (sx0 + 42, sy0 + 64)], 1)
    sofa_block = (sx0, sy0 + 16, 41, 74)

    # 작업대 (가운데 아래): 팔레트(회색으로 말라붙음), 물감 튜브, 빈 스케치북
    tx, ty, tw = 112, 184, 92
    c.shade_rect(tx + 2, ty + 26, tw + 4, 20, 1, 10)
    c.rect(tx - 1, ty - 1, tw + 2, 29, K.INK)
    c.rect(tx, ty, tw, 18, K.SKIN_S)
    c.hline(tx, tx + tw - 1, ty, K.SKIN_M)
    for gx in range(tx + 3, tx + tw - 2, 11):
        c.set(gx, ty + 6, K.WOOD)
        c.set(gx + 4, ty + 12, K.WOOD)
    c.rect(tx, ty + 18, tw, 9, K.WOOD_D)
    c.hline(tx, tx + tw - 1, ty + 18, K.INK)
    c.frame(tx + 30, ty + 20, 32, 5, K.SHADOW)
    c.rect(tx + 44, ty + 22, 4, 1, K.MIST)
    for lx in (tx + 1, tx + tw - 5):
        c.rect(lx - 1, ty + 27, 6, 16, K.INK)
        c.rect(lx, ty + 27, 4, 15, K.WOOD_D)
        c.vline(lx, ty + 27, ty + 41, K.WOOD)
    c.ellipse(tx + 18, ty + 8, 12, 5.5, K.INK)                  # 팔레트
    c.ellipse(tx + 18, ty + 8, 11, 4.5, K.SKIN_M)
    c.ellipse(tx + 25, ty + 9, 2, 1.5, K.SKIN_S)
    for i, col in enumerate((K.PAPERC, K.FOG, K.MIST, K.ASH, K.STONE, K.SHADOW)):
        c.rect(tx + 9 + i * 3, ty + 5 + (i % 2), 2, 2, col)
    c.line(tx + 30, ty + 3, tx + 36, ty + 9, K.WOOD)            # 팔레트 나이프
    for i, col in enumerate((K.FOG, K.MIST, K.PAPERC)):          # 물감 튜브
        bx = tx + 39 + i * 7
        c.rect(bx - 1, ty + 4 + i % 2, 6, 4, K.INK)
        c.rect(bx, ty + 5 + i % 2, 4, 2, col)
        c.set(bx + 4, ty + 5 + i % 2, K.STONE)
    c.rect(tx + 62, ty + 1, 25, 15, K.INK)                       # 빈 스케치북 (펼침)
    c.rect(tx + 63, ty + 2, 11, 13, K.PAPERC)
    c.rect(tx + 75, ty + 2, 11, 13, K.PAPERC)
    c.vline(tx + 74, ty + 2, ty + 14, K.MIST)
    for yy in range(ty + 3, ty + 15, 3):
        c.set(tx + 74, yy, K.SHADOW)                             # 스프링
    c.hline(tx + 64, tx + 73, ty + 14, K.FOG)
    c.line(tx + 78, ty + 12, tx + 88, ty + 7, K.WOOD)            # 연필
    c.set(tx + 88, ty + 7, K.SHADOW)
    table_block = (tx, ty + 14, tw, 28)
    # 둥근 의자 (이젤 옆)
    sx, sy = 178, 162
    c.shade_ellipse(sx + 2, sy + 15, 9, 3)
    for lx in (sx - 6, sx + 5):
        c.rect(lx - 1, sy + 2, 3, 14, K.INK)
        c.vline(lx, sy + 3, sy + 14, K.WOOD_D)
    c.hline(sx - 6, sx + 6, sy + 10, K.INK)
    c.ellipse(sx, sy, 9, 4, K.INK)
    c.ellipse(sx, sy - 0.5, 8, 3, K.SKIN_S)
    c.hline(sx - 5, sx + 3, sy - 2, K.SKIN_M)
    # 바닥 잡동사니: 물감 통, 책 더미, 둘둘 만 종이 바구니
    for i, (px, py) in enumerate(((318, 134), (328, 136), (322, 128))):
        c.shade_ellipse(px + 2, py + 1, 5, 1.5)
        c.rect(px - 4, py - 8, 9, 9, K.INK)
        c.rect(px - 3, py - 7, 7, 7, (K.FOG, K.MIST, K.PAPERC)[i])
        c.ellipse(px, py - 8, 4, 1.6, K.INK)
        c.ellipse(px, py - 8, 3, 0.9, K.ASH)
        c.hline(px - 3, px + 3, py - 3, K.ASH)
    for k, (bw, col) in enumerate(((16, K.STONE), (14, K.FOG), (15, K.WOOD))):
        c.rect(404 - k, 246 - k * 4, bw + 2, 5, K.INK)
        c.rect(405 - k, 247 - k * 4, bw, 3, col)
        c.hline(405 - k, 404 - k + bw, 247 - k * 4, K.PAPERC)
    bx0 = 372
    c.shade_ellipse(bx0 + 10, 246, 10, 3)
    c.rect(bx0, 230, 20, 16, K.INK)
    c.rect(bx0 + 1, 231, 18, 14, K.SKIN_S)
    for xx in range(bx0 + 2, bx0 + 19, 3):
        c.vline(xx, 232, 244, K.WOOD)
    for k, rx in enumerate((bx0 + 3, bx0 + 8, bx0 + 13)):
        c.rect(rx, 220 + k * 3, 4, 12, K.INK)
        c.rect(rx + 1, 221 + k * 3, 2, 10, K.PAPERC)
        c.set(rx + 1, 221 + k * 3, K.FOG)
    # 화분
    plant1 = K.potted_plant(c, 446, 246, size=14, seed=9)
    plant2 = K.potted_plant(c, 142, 132, size=10, seed=10)

    m = meta(
        walkable=[(18, 124), (462, 124), (462, 250), (18, 250)],
        blockers=[sofa_block, table_block, (169, 172, 19, 8), (334, 118, 60, 10), (252, 118, 54, 10),
                  (447, 116, 13, 10), plant1, plant2, (312, 126, 22, 10), (400, 238, 20, 10), (370, 236, 24, 12)],
        spawns={"default": (76, 224), "from_atelier_door": (426, 138)},
        exits=[("atelier_door", (408, 122, 36, 8))],
        props={
            # 잔향 기준점 (스프라이트 바닥 중앙)
            "atelier_brush": (224, 236), "atelier_easel": (152, 162),
            # 조사 지점 (그 물건 바로 앞 바닥 — 캐릭터가 서서 E 를 누르는 자리)
            "sofa": (70, 190), "window": (88, 134), "palette": (130, 234), "sketchbook": (186, 234),
            "canvas": (281, 136), "brushes": (224, 236), "coat": (452, 136),
            # 벽면 좌표 (참고용)
            "hs_signature": (sig_end - 5, 66), "atelier_window": (88, 92), "door": (426, 119),
        },
        notes=("화실 (prologue_atelier, ch1_atelier, ch5_atelier). 왼쪽 벽에 낡은 소파(담요가 바닥으로 흘러내림) — "
               "기본 스폰은 소파 옆. 창가에 이젤(atelier_easel), 가운데 아래 작업대 위에 팔레트·빈 스케치북, "
               "작업대 오른쪽 바닥에 붓통(atelier_brush = brushes 조사 지점). 벽 풍경화 오른쪽 아래 'H.S' 서명(canvas 조사 지점은 그 아래 바닥). "
               "문 옆 옷걸이의 낡은 외투(coat). 조사 지점은 모두 걸을 수 있는 바닥 위, 서로 24px 넘게 떨어져 있다. "
               "두 잔향(붓·이젤)은 복원 반경 48px 이 겹치지 않게 96px 넘게 떨어뜨렸다."),
    )
    return c.to_image(), m


# ====================================================================== 2. 정원
def hedge_row(c: Canvas, x0: int, x1: int, y: int, *, seed: int, r: int = 12) -> None:
    """화면 아래 가장자리를 막는 산울타리 (y = 윗선)."""
    rng = random.Random(seed)
    x = x0
    while x < x1 + r:
        rr = r + rng.randint(-3, 3)
        K.foliage(c, x, y + rr * 0.8, rr, rr * 0.75, seed=rng.randint(0, 999), base=K.STONE,
                  dark=K.SHADOW, light=K.ASH, hi=K.MIST)
        x += rr + rng.randint(2, 6)


def canopy_band(c: Canvas, x0: int, x1: int, y: int, *, seed: int, r: int = 16,
                gap: tuple[int, int] | None = None) -> None:
    """담 너머로 보이는 나무 윗부분 (y = 중심선). gap = 나무를 비워 둘 x 구간(먼 풍경이 보이게)."""
    rng = random.Random(seed)
    x = x0
    while x < x1 + r:
        rr = r + rng.randint(-4, 5)
        dy, s = rng.randint(-4, 4), rng.randint(0, 999)
        if not (gap and gap[0] - rr * 0.6 <= x <= gap[1] + rr * 0.6):
            K.foliage(c, x, y + dy, rr, rr * 0.8, seed=s, base=K.ASH, dark=K.STONE, light=K.MIST, hi=K.FOG)
        x += rr + rng.randint(4, 10)


def distant_clock_tower(c: Canvas, cx: int, top: int, bottom: int) -> None:
    """먼 시계탑 실루엣 (대기 원근: 밝은 회색)."""
    c.rect(cx - 5, top + 6, 11, bottom - top - 6, K.MIST)
    c.vline(cx + 4, top + 6, bottom - 1, K.ASH)
    c.poly([(cx - 7, top + 7), (cx, top - 2), (cx + 7, top + 7)], K.ASH)
    c.rect(cx - 6, top + 6, 13, 2, K.ASH)
    c.ellipse(cx + 0.5, top + 13.5, 3.5, 3.5, K.FOG)
    c.set(cx, top + 13, K.STONE)
    c.set(cx + 1, top + 12, K.STONE)
    c.set(cx, top + 12, K.STONE)
    c.rect(cx - 2, top + 20, 2, 4, K.ASH)


def soil_plot(c: Canvas, x: int, y: int, w: int = 32, h: int = 16) -> None:
    c.shade_rect(x + 2, y + h, w, 2, 1)
    c.rect(x - 1, y - 1, w + 2, h + 2, K.INK)
    c.rect(x, y, w, h, K.SKIN_S)
    c.hline(x, x + w - 1, y, K.SKIN_M)
    c.rect(x + 2, y + 2, w - 4, h - 4, K.WOOD_D)
    for yy in range(y + 4, y + h - 2, 3):
        c.hline(x + 3, x + w - 4, yy, K.SHADOW)
        for xx in range(x + 4, x + w - 4, 5):
            c.set(xx, yy - 1, K.WOOD)


def garden() -> tuple:
    from canvas import grass, stone_wall
    c = Canvas(W, H, K.INK)
    # 하늘 조금 + 담 너머 나무
    c.rect(0, 0, W, 34, K.PAPERC)
    distant_clock_tower(c, 250, 2, 31)                 # 담 너머 마을의 시계탑 꼭대기 (fence 조사)
    canopy_band(c, 0, W, 18, seed=21, gap=(234, 266))
    # 뒷담 (돌담 + 갓돌)
    stone_wall(c, 0, 34, W, 70, seed=22)
    c.rect(0, 30, W, 5, K.MIST)
    c.hline(0, W - 1, 30, K.FOG)
    c.hline(0, W - 1, 35, K.INK)
    c.shade_rect(0, 36, W, 3, 1)
    # 나무 격자 시렁 + 타고 오르는 덩굴 (중립)
    for i, (tx0, ty0) in enumerate([(26, 44), (150, 44), (262, 44)]):
        tw, th = 28, 54
        c.rect(tx0 - 1, ty0 - 1, tw + 2, th + 2, K.STONE)
        for k in range(-th, tw, 7):
            c.line(tx0 + k, ty0, tx0 + k + th, ty0 + th, K.SKIN_S)
            c.line(tx0 + k + th, ty0, tx0 + k, ty0 + th, K.SKIN_S)
        c.remap_where(lambda x, y, a=tx0, b=ty0: not (a <= x < a + tw and b <= y < b + th),
                      {K.SKIN_S: K.ASH}, box=(tx0 - th, ty0, tx0 + tw + th, ty0 + th))
        c.frame(tx0, ty0, tw, th, K.WOOD)
        vr = random.Random(70 + i)
        import math
        for v in range(3):                                     # 타고 오르는 덩굴: 줄기 + 잎 쌍
            vx0 = tx0 + 5 + v * 9 + vr.randint(-2, 2)
            ph = vr.random() * 6.28
            for vy in range(ty0 + th + 6, ty0 + vr.randint(2, 14), -1):
                vx = int(vx0 + 2.5 * math.sin(vy / 5 + ph))
                c.set(vx, vy, K.SHADOW)
                if vy % 4 == 0:
                    side = 1 if (vy // 4) % 2 else -1
                    c.set(vx + side, vy, K.MIST)
                    c.set(vx + 2 * side, vy, K.FOG)
                    c.set(vx + side, vy - 1, K.FOG)
                    c.set(vx + 2 * side, vy + 1, K.STONE)
                if vy % 13 == 0:
                    c.set(vx - 1, vy - 1, K.PAPERC)
                    c.set(vx, vy - 2, K.PAPERC)
                    c.set(vx + 1, vy - 1, K.PAPERC)
                    c.set(vx, vy - 1, K.ASH)
    # 바닥 잔디
    grass(c, 0, 104, W, 166, seed=23)
    c.shade_rect(0, 104, W, 4, 1, 10)

    # 헛간 (오른쪽 위)
    hx, hy, hw, hh = 362, 40, 90, 72
    c.rect(hx - 1, hy - 1, hw + 2, hh + 2, K.INK)
    c.rect(hx, hy, hw, hh, K.WOOD)
    for xx in range(hx + 5, hx + hw, 6):
        c.vline(xx, hy, hy + hh - 1, K.WOOD_D)
        if xx + 1 < hx + hw:
            c.vline(xx + 1, hy, hy + hh - 1, K.SKIN_S)
    K.roof_eave(c, hx - 6, hy - 18, hw + 12, 20, tile=K.STONE)
    K.door(c, 392, 70, 24, 42, wood=K.WOOD_D, pane=False)
    K.window(c, 428, 58, 16, 16, cols=2, rows=2, frame=K.WOOD_D, sill=K.WOOD)
    c.rect(388, 112, 32, 5, K.INK)              # 디딤돌
    c.rect(389, 112, 30, 4, K.MIST)
    c.hline(389, 418, 112, K.FOG)
    # 기대 놓은 도구 (갈퀴·삽)
    c.line(356, 66, 350, 112, K.INK)
    c.line(357, 66, 351, 112, K.WOOD)
    c.rect(350, 60, 11, 3, K.INK)
    for k in range(5):
        c.vline(351 + k * 2, 63, 65, K.INK)
    c.line(458, 70, 461, 112, K.WOOD)
    c.line(459, 70, 462, 112, K.INK)
    c.poly([(458, 104), (466, 104), (465, 114), (459, 114)], K.ASH)
    # 쌓아 둔 화분
    for i, (px, py) in enumerate([(430, 124), (440, 124), (435, 118)]):
        c.rect(px - 5, py - 7, 10, 7, K.INK)
        c.rect(px - 4, py - 6, 8, 6, K.SKIN_S)
        c.hline(px - 5, px + 4, py - 7, K.SKIN_M)

    # 마음 화단 12칸 (담 밑 긴 화단)
    bx0, by0, cell = 60, 106, 24
    c.rect(bx0 - 2, by0 - 2, cell * 12 + 4, 16, K.INK)
    c.rect(bx0 - 1, by0 - 1, cell * 12 + 2, 14, K.SKIN_S)
    c.hline(bx0 - 1, bx0 + cell * 12, by0 - 1, K.SKIN_M)
    heart = {}
    for i in range(12):
        x = bx0 + i * cell
        c.rect(x + 2, by0 + 1, cell - 4, 9, K.WOOD_D)
        c.hline(x + 3, x + cell - 4, by0 + 4, K.SHADOW)
        c.hline(x + 3, x + cell - 4, by0 + 7, K.SHADOW)
        if i:
            c.vline(x, by0, by0 + 11, K.WOOD)
        heart[f"heart_bed_{i + 1:02d}"] = (x + cell // 2, by0 + 8)
    c.shade_rect(bx0, by0 + 14, cell * 12, 2, 1)

    # 디딤돌 길: 헛간 → 가운데 → 오른쪽 출구
    rng = random.Random(24)
    path_pts = [(404, 126), (396, 138), (386, 150), (376, 163), (372, 178), (378, 193), (396, 205), (420, 211), (444, 213), (466, 213)]
    for px, py in path_pts + [(232, 184)]:
        if (px, py) == (232, 184):
            continue
        rx, ry = rng.randint(6, 8), rng.randint(3, 4)
        c.ellipse(px + 1, py + 1, rx, ry, K.STONE)
        c.ellipse(px, py, rx, ry, K.MIST)
        c.ellipse(px - 1, py - 1, rx - 2, ry - 1.5, K.FOG)
    # 가운데 특별 화분 자리 (둥근 판석)
    c.ellipse(232, 186, 16, 7, K.INK)
    c.ellipse(232, 186, 15, 6, K.MIST)
    c.ellipse(232, 185, 12, 4.5, K.FOG)
    c.ellipse(232, 186, 8, 3, K.MIST)

    # 칸 10개: 위 줄 = 하늘(plot_01~05), 아래 줄 = 별(plot_06~10)
    plots = {}
    blockers = []
    for row, py in enumerate((142, 206)):
        for i in range(5):
            px = 88 + i * 58
            soil_plot(c, px, py)
            plots[f"plot_{row * 5 + i + 1:02d}"] = (px + 16, py + 10)
            blockers.append((px, py + 2, 32, 14))
    # 손펌프 + 양동이 (왼쪽)
    c.shade_ellipse(44, 150, 12, 3)
    c.rect(36, 120, 10, 30, K.INK)
    c.rect(37, 121, 8, 28, K.STONE)
    c.vline(38, 122, 147, K.ASH)
    c.rect(44, 126, 10, 4, K.INK)
    c.hline(45, 52, 127, K.STONE)
    c.line(36, 120, 26, 112, K.INK)
    c.line(37, 121, 27, 113, K.ASH)
    c.rect(34, 116, 14, 5, K.INK)
    c.rect(35, 117, 12, 3, K.SHADOW)
    K.barrel(c, 48, 136, w=12, h=14)
    # 회색 꽃밭 (왼쪽) — 이슬 맺힌, 조금 시든 꽃들
    fx, fy = 48, 204
    c.ellipse(fx + 2, fy + 3, 31, 13, K.ASH)
    c.ellipse(fx, fy, 31, 14, K.INK)
    c.ellipse(fx, fy, 30, 13, K.MIST)
    c.ellipse(fx, fy - 1, 27, 10.5, K.WOOD_D)
    fr = random.Random(27)
    for _ in range(16):
        lx, ly = fx + fr.randint(-23, 23), fy + fr.randint(-7, 6)
        K.foliage(c, lx, ly, 4, 3, seed=fr.randint(0, 999), base=K.ASH, dark=K.STONE, light=K.MIST, hi=None, edge=K.SHADOW)
    for _ in range(22):
        bx, by = fx + fr.randint(-24, 24), fy + fr.randint(-9, 5)
        col = fr.choice((K.PAPERC, K.FOG, K.FOG, K.MIST, K.PAPER))
        droop = fr.random() < 0.3
        c.vline(bx, by + 1, by + 3, K.STONE)
        for dx, dy in ((0, -1), (-1, 0), (1, 0), (0, 1)):
            c.set(bx + dx, by + dy + (1 if droop else 0), col)
        c.set(bx, by + (1 if droop else 0), K.ASH)
        if fr.random() < 0.25:
            c.set(bx + 1, by - 2, K.PAPERC)                 # 이슬
    flower_block = (18, 194, 60, 20)
    # 2인용 그네 (오른쪽, 헛간 아래)
    gx0, gx1, gy0, gy1 = 402, 460, 150, 196
    c.shade_ellipse(431, 197, 26, 3.5)
    for lx0, lx1, col in ((gx0 + 6, gx0 + 3, K.WOOD_D), (gx1 - 6, gx1 - 3, K.WOOD_D)):   # 뒷다리
        c.line(lx0, gy0 + 2, lx1, gy1 - 6, K.INK)
        c.line(lx0 + 1, gy0 + 2, lx1 + 1, gy1 - 6, col)
    for lx0, lx1 in ((gx0 + 4, gx0), (gx1 - 4, gx1)):                                  # 앞다리
        for k in range(3):
            c.line(lx0 + k - 1, gy0 + 2, lx1 + k - 1, gy1, K.INK if k != 1 else K.WOOD)
    c.rect(gx0, gy0 - 2, gx1 - gx0 + 1, 5, K.INK)                                      # 윗 들보
    c.hline(gx0 + 1, gx1 - 1, gy0 - 1, K.SKIN_S)
    c.hline(gx0 + 1, gx1 - 1, gy0, K.WOOD)
    c.hline(gx0 + 1, gx1 - 1, gy0 + 1, K.WOOD_D)
    for rx in (gx0 + 10, gx1 - 10):                                                     # 줄
        c.vline(rx, gy0 + 3, gy0 + 28, K.SHADOW)
    c.rect(gx0 + 8, gy0 + 16, gx1 - gx0 - 15, 4, K.INK)                                # 등받이
    c.hline(gx0 + 9, gx1 - 8, gy0 + 17, K.SKIN_S)
    c.hline(gx0 + 9, gx1 - 8, gy0 + 18, K.WOOD)
    c.rect(gx0 + 6, gy0 + 26, gx1 - gx0 - 11, 7, K.INK)                                # 앉는 판 (둘이 앉는 폭)
    c.rect(gx0 + 7, gy0 + 27, gx1 - gx0 - 13, 3, K.SKIN_S)
    c.hline(gx0 + 7, gx1 - 6, gy0 + 27, K.SKIN_M)
    c.rect(gx0 + 7, gy0 + 30, gx1 - gx0 - 13, 2, K.WOOD)
    c.vline((gx0 + gx1) // 2, gy0 + 27, gy0 + 31, K.WOOD_D)
    swing_block = (gx0 - 4, gy1 - 8, gx1 - gx0 + 9, 9)
    # 아래쪽: 산울타리
    hedge_row(c, -8, W, 246, seed=25)
    # 오른쪽 담 (출구 틈)
    for (y0, y1) in ((104, 186), (232, 270)):
        c.rect(466, y0, 14, y1 - y0, K.MIST)
        c.vline(466, y0, y1 - 1, K.INK)
        c.vline(467, y0, y1 - 1, K.FOG)
    c.rect(466, 186, 14, 4, K.STONE)
    c.rect(466, 228, 14, 4, K.STONE)

    props = {
        # 잔향 기준점 (스프라이트 바닥 중앙)
        "garden_pot": (292, 190), "garden_sprinkler": (70, 168),
        # 조사 지점 (그 물건 바로 앞 바닥)
        "pot": (292, 190), "can": (70, 168), "flowers": (52, 228), "shed": (404, 130),
        "swing": (431, 206), "fence": (250, 128),
        # 정원 시스템 자리
        "special_pot": (232, 186), "shed_door": (404, 114),
    }
    props.update(plots)
    props.update(heart)
    m = meta(
        walkable=[(18, 122), (462, 122), (462, 188), (479, 188), (479, 230), (462, 230), (462, 242), (18, 242)],
        blockers=blockers + [(32, 144, 30, 8), (386, 112, 34, 6), (424, 118, 22, 8), (224, 182, 17, 7),
                             flower_block, swing_block],
        spawns={"default": (264, 194), "from_garden_gate": (448, 214)},
        exits=[("garden_gate", (470, 190, 10, 40))],
        props=props,
        notes=("작은 돌담 정원 (prologue_garden, ch1_garden, ch1_garden_02, 이후 모든 *_garden* 공용 허브). "
               "garden.md §2 배치: 위 줄 plot_01~05 = 하늘, 아래 줄 plot_06~10 = 별, 짝 칸은 세로(01-06 …). "
               "가운데 둥근 판석 = 특별 화분 자리(special_pot). 담 밑 긴 화단 12칸 = 마음 화단(heart_bed_01~12). "
               "칸·화단 좌표는 식물 스프라이트의 바닥 중앙. 별 화분(garden_pot = pot)은 별이 깨어나는 가운데 풀밭(기본 스폰) 발치. "
               "별 화분을 가운데 특별 화분과 같은 물건으로 볼지는 TODO-확인. 물뿌리개(garden_sprinkler = can)는 왼쪽 수돗가 옆. "
               "왼쪽 회색 꽃밭(flowers), 헛간 문(shed), 헛간 아래 2인용 그네(swing), 뒷담 너머로 마을 시계탑 꼭대기가 보이는 자리(fence). "
               "오른쪽 담 틈 = 정원 문(garden_gate)으로 나가는 출구."),
    )
    return c.to_image(), m


def _registry() -> dict:
    import bg_town
    return {"atelier": atelier, "garden": garden, **bg_town.SCENES}


class _Lazy(dict):
    """bg_town 이 이 모듈을 import 하므로 목록은 처음 쓸 때 만든다."""
    def _fill(self) -> None:
        if not dict.__len__(self):
            self.update(_registry())

    def items(self):
        self._fill()
        return dict.items(self)

    def __getitem__(self, k):
        self._fill()
        return dict.__getitem__(self, k)

    def keys(self):
        self._fill()
        return dict.keys(self)


BACKGROUNDS = _Lazy()
