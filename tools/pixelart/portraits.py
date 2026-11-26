"""대화 초상 64×64 × 표정 4종 = 256×64.  열 순서: neutral, smile, sad, surprised
(dialogue_conventions.md §4 의 portrait 값 이름과 같다. 나머지 8종은 이후 WP 에서 같은 틀로 추가)

몸·머리는 도형(타원·다각형)으로 쌓고, 눈·눈썹·입만 작은 ASCII 격자로 찍는다. 바깥 외곽선은 자동.
"""
from __future__ import annotations

import math

from PIL import Image

from canvas import Canvas, ellipse_mask
from sprite import grid, mirror, outline, paste, sheet

SIZE = 64
EXPRESSIONS = ("neutral", "smile", "sad", "surprised")

FEATURE_LEGEND = {
    "K": "neutral-ink",
    "I": "neutral-stone",        # 눈동자
    "f": "neutral-paper-cool",   # 눈 반짝임·흰자·눈물
    "b": "neutral-stone",        # 눈썹 (머리카락보다 한 계단 밝게 → 앞머리와 구분)
    "d": "neutral-skin-shadow",  # 입·주름
    "s": "neutral-skin-mid",     # 볼 그늘
    "m": "neutral-shadow",       # 입 안
}

# 왼쪽 눈 (보는 사람 기준). 오른쪽은 좌우 반전. 기준점 = 격자 왼쪽 위.
EYES = {
    "neutral": """
        .KKKKK.
        KKKKKKK
        .KfIIK.
        .KIIIK.
        ..KKK..
    """,
    "smile": """
        .......
        ..KKK..
        .K...K.
        K.....K
        .......
    """,
    "sad": """
        .......
        ....KKK
        ..KKKK.
        .KfIIK.
        ..KKKf.
    """,
    "surprised": """
        ..KKK..
        .KfffK.
        .KfIfK.
        .KfIfK.
        ..KKK..
    """,
}
EYES_BIG = {  # 별: 더 크고 둥근 눈
    "neutral": """
        .KKKKK.
        KKKKKKK
        KKfIIKK
        .KffIK.
        .KIIIK.
        ..KKK..
    """,
    "smile": """
        .......
        .......
        ..KKK..
        .K...K.
        K.....K
        .......
    """,
    "sad": """
        .......
        ....KKK
        ..KKKK.
        .KfIIK.
        .KIIIK.
        ..KKKf.
    """,
    "surprised": """
        ..KKK..
        .KfffK.
        KffIffK
        KffIffK
        .KfffK.
        ..KKK..
    """,
}
BROWS = {
    "neutral": """
        .......
        .bbbbb.
    """,
    "smile": """
        ..bbb..
        .b...b.
    """,
    "sad": """
        ....bb.
        .bbb...
    """,
    "surprised": """
        ..bbb..
        .b...b.
    """,
}
MOUTHS = {
    "neutral": """
        .......
        ..ddd..
        .......
    """,
    "smile": """
        d.....d
        .dKKKd.
        ..ddd..
    """,
    "sad": """
        .......
        ..ddd..
        .d...d.
    """,
    "surprised": """
        ..KK...
        .KmmK..
        ..KK...
    """,
}
BROW_LIFT = {"neutral": 0, "smile": 0, "sad": 0, "surprised": -2}


def _star(cx: float, cy: float, ro: float, ri: float) -> list[tuple[int, int]]:
    pts = []
    for i in range(10):
        a = -math.pi / 2 + i * math.pi / 5
        r = ro if i % 2 == 0 else ri
        pts.append((round(cx + r * math.cos(a)), round(cy + r * math.sin(a))))
    return pts


def _features(c: Canvas, expr: str, eyes: dict, eye_l: tuple[int, int], eye_r_x: int,
              brow_y: int, mouth: tuple[int, int]) -> None:
    eye = grid(eyes[expr], FEATURE_LEGEND)
    paste(c.img, eye, eye_l[0], eye_l[1])
    paste(c.img, mirror(eye), eye_r_x, eye_l[1])
    brow = grid(BROWS[expr], FEATURE_LEGEND)
    by = brow_y + BROW_LIFT[expr]
    paste(c.img, brow, eye_l[0], by)
    paste(c.img, mirror(brow), eye_r_x, by)
    m = grid(MOUTHS[expr], FEATURE_LEGEND)
    paste(c.img, m, mouth[0] - m.width // 2, mouth[1])
    if expr == "smile":  # 볼 그늘
        for x0 in (eye_l[0] - 1, eye_r_x + 5):
            for dx in range(3):
                c.set(x0 + dx, eye_l[1] + len(eyes[expr].strip().splitlines()) + 1, "neutral-skin-mid")


def _shirt_shoulders(c: Canvas, cloth: str, cloth_shade: str) -> None:
    c.poly([(5, 64), (7, 56), (13, 51), (24, 48), (40, 48), (51, 51), (57, 56), (59, 64)], cloth)
    c.remap_where(lambda x, y: x >= 46 or (x >= 43 and y >= 56), {cloth: cloth_shade}, box=(40, 48, 64, 64))
    c.remap_where(lambda x, y: x <= 8, {cloth: cloth_shade}, box=(0, 48, 12, 64), level=8)


# ---------------------------------------------------------------- 하늘
def haneul_base() -> Canvas:
    c = Canvas(SIZE, SIZE, None)
    hair, hair_hi = "neutral-shadow", "neutral-stone"
    # 뒷머리 (머리통에 붙게)
    c.ellipse(32, 25, 17.5, 16.5, hair)
    # 몸통: 셔츠 + 앞치마 끈·가슴판
    _shirt_shoulders(c, "neutral-ash", "neutral-stone")
    c.poly([(27, 48), (32, 55), (37, 48)], "neutral-skin-mid")          # V 넥
    c.line(26, 48, 31, 55, "neutral-mist")
    c.line(38, 48, 33, 55, "neutral-mist")
    for x0 in (20, 21, 22):
        c.line(x0, 64, x0 + 4, 50, "neutral-paper")                    # 왼쪽 끈
        c.line(x0 + 22, 64, x0 + 18, 50, "neutral-paper")              # 오른쪽 끈
    c.poly([(21, 58), (44, 58), (45, 64), (20, 64)], "neutral-paper")  # 가슴판
    c.hline(21, 43, 58, "neutral-fog")
    c.line(44, 59, 45, 63, "neutral-fog")
    for x, y in ((25, 61), (26, 61), (29, 62)):                         # 회색 물감 얼룩
        c.set(x, y, "neutral-mist")
    for x, y, col in ((37, 60, "longing-mid"), (38, 60, "longing-mid"), (38, 61, "longing-mid"),
                      (39, 61, "longing-light"), (36, 61, "longing-light")):
        c.set(x, y, col)                                               # ★ 파란 물감 자국
    # 목
    c.rect(27, 43, 10, 7, "neutral-skin-light")
    c.rect(27, 43, 10, 3, "neutral-skin-mid")
    c.vline(36, 43, 49, "neutral-skin-mid")
    # 귀
    for ex in (17.5, 46.5):
        c.ellipse(ex, 34, 2.8, 4.0, "neutral-skin-light")
        c.ellipse(ex, 34.5, 1.3, 2.2, "neutral-skin-mid")
    # 얼굴 (턱은 살짝 갸름하게)
    c.ellipse(32, 31, 14.6, 13.2, "neutral-skin-light")
    c.poly([(18, 33), (46, 33), (43, 41), (37, 46), (27, 46), (21, 41)], "neutral-skin-light")
    c.remap_where(ellipse_mask(50, 35, 6, 13), {"neutral-skin-light": "neutral-skin-mid"}, box=(40, 18, 50, 48))
    c.remap_where(ellipse_mask(32, 47.5, 8, 2.5), {"neutral-skin-light": "neutral-skin-mid"}, box=(20, 42, 44, 50))
    c.set(32, 37, "neutral-skin-mid")                                  # 코
    c.set(33, 38, "neutral-skin-mid")
    # 앞머리 덩어리: 눈썹 위에서 끝난다
    c.ellipse(32, 17.5, 17.6, 8.6, hair)
    bangs = [(14, 21, 16, 36), (17, 25, 20, 28), (22, 29, 25, 27), (27, 34, 31, 29),
             (32, 39, 36, 27), (37, 44, 41, 27), (42, 50, 48, 36)]
    for x0, x1, tx, ty in bangs:
        c.poly([(x0, 22), (x1, 22), (tx, ty)], hair)
    # 부스스한 삐침 (몇 가닥만, 비대칭)
    for pts in ([(19, 13), (27, 9), (16, 5)], [(26, 10), (33, 8), (29, 4)],
                [(35, 9), (42, 11), (44, 7)], [(43, 13), (49, 17), (53, 12)]):
        c.poly(pts, hair)
    # 머리 하이라이트 (위쪽 둥근 결)
    for pts in ([(20, 13), (21, 12), (22, 11), (23, 11)], [(27, 10), (28, 9), (29, 9), (30, 9)],
                [(35, 10), (36, 10), (37, 10)], [(22, 18), (23, 17), (24, 17)], [(39, 15), (40, 14), (41, 14)]):
        for x, y in pts:
            c.set(x, y, hair_hi)
    return c


def haneul_portrait() -> Image.Image:
    frames = []
    for expr in EXPRESSIONS:
        c = haneul_base()
        _features(c, expr, EYES, (22, 31), 35, 28, (32, 41))
        frames.append(outline(c.to_image()))
    return sheet([frames], SIZE, SIZE)


# ---------------------------------------------------------------- 별
def byeol_base() -> Canvas:
    c = Canvas(SIZE, SIZE, None)
    hair, hair_hi = "neutral-shadow", "neutral-stone"
    # 양 갈래 머리 (뒤)
    for cx in (11.5, 52.5):
        c.ellipse(cx, 47, 5.2, 8.0, hair)
        c.ellipse(cx, 40, 3.6, 3.0, hair)
    c.ellipse(32, 30, 17.5, 17, hair)                                   # 뒷머리
    # 원피스 + 둥근 깃
    c.poly([(9, 64), (11, 58), (17, 53), (25, 51), (39, 51), (47, 53), (53, 58), (55, 64)], "neutral-stone")
    c.remap_where(lambda x, y: x >= 45, {"neutral-stone": "neutral-shadow"}, box=(40, 50, 64, 64))
    for cx in (25.5, 38.5):
        c.ellipse(cx, 54.5, 8.5, 4.6, "neutral-paper-cool")
        c.ellipse(cx, 56.0, 7, 3, "neutral-paper-cool")
    c.remap_where(lambda x, y: y >= 57, {"neutral-paper-cool": "neutral-fog"}, box=(16, 55, 48, 61))
    c.vline(32, 51, 60, "neutral-fog")
    # 목
    c.rect(28, 46, 8, 6, "neutral-skin-light")
    c.rect(28, 46, 8, 2, "neutral-skin-mid")
    # 얼굴 (둥글게)
    for ex in (17.5, 46.5):
        c.ellipse(ex, 37, 2.5, 3.4, "neutral-skin-light")
    c.ellipse(32, 35, 14.6, 13.4, "neutral-skin-light")
    c.remap_where(ellipse_mask(50, 38, 6, 12), {"neutral-skin-light": "neutral-skin-mid"}, box=(40, 22, 50, 50))
    c.remap_where(ellipse_mask(32, 49.5, 7, 2.2), {"neutral-skin-light": "neutral-skin-mid"}, box=(22, 46, 42, 52))
    c.set(32, 40, "neutral-skin-mid")
    # 앞머리: 가지런한 앞머리(눈썹 위까지) + 볼 옆으로 내려오는 옆머리
    c.ellipse(32, 20, 17.6, 8.5, hair)
    for x0, x1, tx, ty in [(14, 21, 16, 42), (17, 24, 20, 28), (22, 29, 25, 28), (27, 34, 30, 28),
                           (32, 39, 35, 28), (37, 44, 41, 28), (43, 50, 48, 42)]:
        c.poly([(x0, 25), (x1, 25), (tx, ty)], hair)
    for pts in ([(20, 16), (21, 15), (22, 14), (23, 14)], [(27, 13), (28, 13), (29, 13), (30, 13), (31, 13)],
                [(23, 21), (24, 20), (25, 20)], [(9, 44), (9, 45), (10, 43)], [(51, 43), (52, 43)]):
        for x, y in pts:
            c.set(x, y, hair_hi)
    # 머리끈 (중립)
    for cx in (11, 52):
        c.rect(cx - 2, 38, 5, 2, "neutral-fog")
    # ★ 노란 별 머리핀
    c.poly(_star(44, 16, 5.2, 2.3), "warmth-mid")
    c.poly(_star(43.6, 15.6, 3.2, 1.4), "warmth-light")
    c.set(43, 15, "warmth-highlight")
    c.set(44, 20, "warmth-dark")
    c.set(47, 19, "warmth-dark")
    return c


def byeol_portrait() -> Image.Image:
    frames = []
    for expr in EXPRESSIONS:
        c = byeol_base()
        _features(c, expr, EYES_BIG, (21, 33), 36, 30, (32, 43))
        frames.append(outline(c.to_image()))
    return sheet([frames], SIZE, SIZE)


PORTRAITS = {
    "haneul": haneul_portrait,
    "byeol": byeol_portrait,
}
