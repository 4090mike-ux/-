"""docs/style/palette.gpl 로더. 모든 그림 코드는 색을 **이름**으로만 쓴다.

    from palette import rgb, rgba, luma, family
    rgb("neutral-ink")      # (21, 20, 23)
    family("longing-mid")   # "longing"
"""
from __future__ import annotations

import colorsys
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
GPL_PATH = ROOT / "docs/style/palette.gpl"

EMOTION_FAMILIES = ("longing", "warmth", "dream", "courage", "healing")
_LINE = re.compile(r"^\s*(\d{1,3})\s+(\d{1,3})\s+(\d{1,3})\s+(\S+)")


def load(path: Path = GPL_PATH) -> dict[str, tuple[int, int, int]]:
    """이름 → (r, g, b). GIMP .gpl 형식. 순서는 파일 순서를 지킨다."""
    lines = path.read_text(encoding="utf-8").splitlines()
    if not lines or lines[0].strip() != "GIMP Palette":
        raise ValueError(f"{path}: 첫 줄은 'GIMP Palette' 여야 함")
    colors: dict[str, tuple[int, int, int]] = {}
    for line in lines[1:]:
        s = line.strip()
        if not s or s.startswith("#") or ":" in s.split()[0]:
            continue
        m = _LINE.match(line)
        if not m:
            raise ValueError(f"{path}: 형식 오류 {line!r}")
        name = m.group(4)
        if name in colors:
            raise ValueError(f"{path}: 색 이름 중복 {name}")
        colors[name] = (int(m.group(1)), int(m.group(2)), int(m.group(3)))
    return colors


PALETTE: dict[str, tuple[int, int, int]] = load()
RGB_TO_NAME: dict[tuple[int, int, int], str] = {v: k for k, v in PALETTE.items()}


def rgb(name: str) -> tuple[int, int, int]:
    try:
        return PALETTE[name]
    except KeyError:
        raise KeyError(f"팔레트에 없는 색 이름: {name!r} (docs/style/palette.gpl)") from None


def rgba(name: str) -> tuple[int, int, int, int]:
    return (*rgb(name), 255)


def luma(color: tuple[int, ...] | str) -> float:
    """Rec.709 휘도 0~255. 셰이더가 흑백으로 바꿀 때 쓰는 값과 같다."""
    r, g, b = rgb(color) if isinstance(color, str) else color[:3]
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def hsv(name: str) -> tuple[float, float, float]:
    r, g, b = rgb(name)
    return colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)


def family(name: str) -> str:
    """neutral / reserved / 감정 id."""
    return name.split("-", 1)[0]


def is_emotion(name: str) -> bool:
    return family(name) in EMOTION_FAMILIES


# ------------------------------------------------------------------ 명도 계단 (중립색만)
# 배경의 그림자·빛 웅덩이·밤 버전에 쓴다. 감정 색은 배경에 쓰지 않으므로 여기 없다.
_COOL = ["neutral-ink", "neutral-shadow", "neutral-stone", "neutral-ash",
         "neutral-mist", "neutral-fog", "neutral-paper-cool"]
_WARM = ["neutral-shadow", "neutral-wood-dark", "neutral-wood-mid", "neutral-skin-shadow",
         "neutral-skin-mid", "neutral-skin-light", "neutral-paper"]

DARKER: dict[str, str] = {"neutral-ink": "neutral-ink"}
LIGHTER: dict[str, str] = {"neutral-paper-cool": "neutral-paper-cool", "neutral-paper": "neutral-paper"}
for _ramp in (_COOL, _WARM):
    for _i in range(1, len(_ramp)):
        DARKER.setdefault(_ramp[_i], _ramp[_i - 1])
        LIGHTER.setdefault(_ramp[_i - 1], _ramp[_i])
LIGHTER["neutral-shadow"] = "neutral-stone"

# 밤: 밝은 색은 두 계단, 어두운 색은 한 계단 내리고 따뜻한 색은 차갑게(달빛).
NIGHT: dict[str, str] = {
    "neutral-paper-cool": "neutral-mist",
    "neutral-paper": "neutral-mist",
    "neutral-fog": "neutral-ash",
    "neutral-mist": "neutral-stone",
    "neutral-ash": "neutral-stone",
    "neutral-stone": "neutral-shadow",
    "neutral-shadow": "neutral-shadow",
    "neutral-ink": "neutral-ink",
    "neutral-skin-light": "neutral-ash",
    "neutral-skin-mid": "neutral-wood-mid",
    "neutral-skin-shadow": "neutral-wood-dark",
    "neutral-wood-mid": "neutral-wood-dark",
    "neutral-wood-dark": "neutral-shadow",
}


def utf8_stdout() -> None:
    """Windows 콘솔(Git Bash)에서 한글 출력이 깨지지 않게."""
    import sys
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")


def darker(name: str, steps: int = 1) -> str:
    for _ in range(steps):
        name = DARKER.get(name, name)
    return name


def lighter(name: str, steps: int = 1) -> str:
    for _ in range(steps):
        name = LIGHTER.get(name, name)
    return name


if __name__ == "__main__":
    for n, c in PALETTE.items():
        h, s, v = hsv(n)
        print(f"{n:22s} {c}  luma {luma(n):5.1f}  H {h * 360:5.1f}  S {s:.2f}")
