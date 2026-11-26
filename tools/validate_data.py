#!/usr/bin/env python3
"""데이터 계약 검증기: JSON Schema + 교차 검사 + 팔레트 규칙.

검사 항목
  1. docs/schemas/*.schema.json 이 올바른 JSON Schema(2020-12)인가
  2. game/data/ 와 docs/schemas/examples/ 의 JSON 이 스키마를 지키는가
  3. 교차 검사: 플래그 id 중복·챕터 일치, 잔향 id 중복·개수 상한, 참조하는 플래그가 실제로 있는가
  4. 감정 색 규칙: 대역이 겹치지 않는가, ramp 색이 대역 안·채도 0.45 이상인가, palette.gpl 에 있는가
  5. 팔레트 규칙: 중립색은 채도 0.28 이하이거나 모든 감정 대역 밖

사용법
  pip install -r tools/requirements.txt
  python tools/validate_data.py
  python tools/validate_data.py --generated tests/out   # 게임이 만든 save_*.json / persist_*.json 도 검사
"""
from __future__ import annotations

import argparse
import colorsys
import json
import re
import sys
from pathlib import Path

try:
    from jsonschema import Draft202012Validator, FormatChecker
except ImportError:  # pragma: no cover
    print("jsonschema 가 없습니다. 먼저 실행: pip install -r tools/requirements.txt")
    sys.exit(2)

ROOT = Path(__file__).resolve().parent.parent
SCHEMAS = ROOT / "docs/schemas"
DATA = ROOT / "game/data"
EXAMPLES = SCHEMAS / "examples"
PALETTE = ROOT / "docs/style/palette.gpl"

EMOTION_MIN_SAT = 0.45
NEUTRAL_MAX_SAT = 0.28
MAX_REQUIRED_ECHOES = 18
MAX_HIDDEN_ECHOES = 12

errors: list[str] = []
notes: list[str] = []


def err(where: str, msg: str) -> None:
    errors.append(f"{where}: {msg}")


def rel(p: Path) -> str:
    try:
        return p.relative_to(ROOT).as_posix()
    except ValueError:
        return p.as_posix()


def load_json(path: Path) -> object | None:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        err(rel(path), f"JSON 파싱 실패 (줄 {exc.lineno}): {exc.msg}")
        return None


def load_schemas() -> dict[str, dict]:
    schemas: dict[str, dict] = {}
    for path in sorted(SCHEMAS.glob("*.schema.json")):
        schema = load_json(path)
        if not isinstance(schema, dict):
            continue
        try:
            Draft202012Validator.check_schema(schema)
        except Exception as exc:  # jsonschema.SchemaError
            err(rel(path), f"스키마 자체가 잘못됨: {exc}")
            continue
        schemas[path.name.removesuffix(".schema.json")] = schema
    return schemas


def validate(path: Path, schema: dict) -> object | None:
    data = load_json(path)
    if data is None:
        return None
    validator = Draft202012Validator(schema, format_checker=FormatChecker())
    for e in sorted(validator.iter_errors(data), key=lambda e: list(e.absolute_path)):
        loc = "/".join(str(p) for p in e.absolute_path) or "(루트)"
        err(rel(path), f"{loc}: {e.message}")
    return data


def hue_dist(a: float, b: float) -> float:
    d = abs(a - b) % 1.0
    return min(d, 1.0 - d)


def hsv(hex_color: str) -> tuple[float, float, float]:
    h = hex_color.lstrip("#")
    r, g, b = (int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))
    return colorsys.rgb_to_hsv(r, g, b)


def check_flags(flags_data: dict) -> set[str]:
    where = "game/data/flags.json"
    seen: set[str] = set()
    for var in flags_data.get("variables", []):
        if var["id"] in seen:
            err(where, f"변수 id 중복: {var['id']}")
        seen.add(var["id"])
    flag_ids: set[str] = set()
    for flag in flags_data.get("flags", []):
        fid = flag["id"]
        if fid in flag_ids:
            err(where, f"플래그 id 중복: {fid}")
        flag_ids.add(fid)
        if fid.split(".")[1] != flag["chapter"]:
            err(where, f"{fid}: id 의 챕터와 chapter 필드({flag['chapter']})가 다름")
        if flag["type"] == "enum" and flag["default"] not in flag.get("values", []):
            err(where, f"{fid}: 기본값 '{flag['default']}' 가 values 에 없음")
    notes.append(f"플래그 {len(flag_ids)}개, 변수 {len(seen)}개")
    return flag_ids


def load_palette() -> dict[str, str]:
    """이름 → hex. GIMP .gpl 형식."""
    colors: dict[str, str] = {}
    if not PALETTE.exists():
        err(rel(PALETTE), "팔레트 파일이 없음")
        return colors
    lines = PALETTE.read_text(encoding="utf-8").splitlines()
    if not lines or lines[0].strip() != "GIMP Palette":
        err(rel(PALETTE), "첫 줄은 'GIMP Palette' 여야 함")
    for lineno, line in enumerate(lines[1:], start=2):
        s = line.strip()
        if not s or s.startswith("#") or ":" in s.split()[0]:
            continue
        m = re.match(r"^\s*(\d{1,3})\s+(\d{1,3})\s+(\d{1,3})\s+(\S+)", line)
        if not m:
            err(f"{rel(PALETTE)}:{lineno}", f"형식 오류: {line!r}")
            continue
        r, g, b = (int(m.group(i)) for i in (1, 2, 3))
        name = m.group(4)
        if name in colors:
            err(f"{rel(PALETTE)}:{lineno}", f"색 이름 중복: {name}")
        colors[name] = f"#{r:02x}{g:02x}{b:02x}"
    return colors


def check_emotions(emotions_data: dict, palette: dict[str, str]) -> dict[str, tuple[float, float]]:
    where = "game/data/emotions.json"
    bands: dict[str, tuple[float, float]] = {}  # id → (center, reach)
    palette_hexes = set(palette.values())
    for e in emotions_data.get("emotions", []):
        hb = e["hue_band"]
        center = hb["center_deg"] / 360
        half = hb["half_width_deg"] / 360
        reach = (hb["half_width_deg"] + hb["softness_deg"]) / 360
        bands[e["id"]] = (center, reach)
        for hx in e["ramp"]:
            h, s, _ = hsv(hx)
            if hue_dist(h, center) > half:
                err(where, f"{e['id']}: ramp 색 {hx} 의 Hue {h * 360:.0f}° 가 대역 밖")
            if s < EMOTION_MIN_SAT:
                err(where, f"{e['id']}: ramp 색 {hx} 채도 {s:.2f} < {EMOTION_MIN_SAT}")
            if palette and hx not in palette_hexes:
                err(where, f"{e['id']}: ramp 색 {hx} 가 docs/style/palette.gpl 에 없음")
    ids = list(bands)
    for i, a in enumerate(ids):
        for b in ids[i + 1:]:
            (ca, ra), (cb, rb) = bands[a], bands[b]
            if hue_dist(ca, cb) <= ra + rb:
                err(where, f"대역 겹침: {a} ↔ {b} (중심 거리 {hue_dist(ca, cb) * 360:.0f}° ≤ {(ra + rb) * 360:.0f}°)")
    return bands


def check_palette(palette: dict[str, str], bands: dict[str, tuple[float, float]]) -> None:
    where = rel(PALETTE)
    categories = set(bands) | {"neutral", "reserved"}
    for name, hx in palette.items():
        cat = name.split("-", 1)[0]
        if cat not in categories:
            err(where, f"색 이름 '{name}' 은 '<분류>-<이름>' 형식 (분류: {sorted(categories)})")
            continue
        h, s, _ = hsv(hx)
        if cat == "neutral":
            in_any = [eid for eid, (c, r) in bands.items() if hue_dist(h, c) <= r]
            if s > NEUTRAL_MAX_SAT and in_any:
                err(where, f"중립색 {name} {hx}: 채도 {s:.2f} > {NEUTRAL_MAX_SAT} 인데 감정 대역({in_any[0]}) 안 — 잔향 복원 때 같이 물든다")
        elif cat in bands:
            c, _ = bands[cat]
            if s < EMOTION_MIN_SAT:
                err(where, f"{name} {hx}: 감정 색 채도 {s:.2f} < {EMOTION_MIN_SAT}")
            # ramp 밖의 추가 감정 색도 반폭 안에 있어야 한다는 규칙은 check_emotions 의 ramp 와 같음
    notes.append(f"팔레트 {len(palette)}색")


def check_echoes(schema: dict, flag_ids: set[str], paths: list[Path]) -> dict[str, int] | None:
    seen: dict[str, str] = {}
    counts = {"required": 0, "hidden": 0}
    for path in paths:
        data = validate(path, schema)
        if not isinstance(data, dict):
            continue
        chapter = data.get("chapter")
        for echo in data.get("echoes", []):
            eid = echo.get("id", "?")
            if eid in seen:
                err(rel(path), f"잔향 id 중복: {eid} (먼저: {seen[eid]})")
            seen[eid] = rel(path)
            if eid.split(".")[1:2] != [chapter]:
                err(rel(path), f"{eid}: 파일 chapter({chapter})와 id 챕터가 다름")
            counts[echo.get("kind", "required")] = counts.get(echo.get("kind", "required"), 0) + 1
            refs = list(echo.get("requires", {}).get("flags", [])) + list(echo.get("reward", {}).get("sets_flags", []))
            for f in refs:
                if f not in flag_ids:
                    err(rel(path), f"{eid}: 플래그 {f} 가 game/data/flags.json 에 없음")
    return counts if paths else None


def check_generated(schemas: dict[str, dict], flag_ids: set[str], folder: Path) -> None:
    """gdUnit4 테스트(SaveService)가 실제로 쓴 파일을 스키마로 검사한다."""
    if not folder.exists():
        notes.append(f"생성 파일 폴더 없음: {folder} (테스트를 먼저 실행)")
        return
    found = 0
    for path in sorted(folder.glob("save_*.json")):
        found += 1
        data = validate(path, schemas["save"])
        if isinstance(data, dict):
            for f in data.get("state", {}).get("flags", {}):
                if f not in flag_ids:
                    err(rel(path), f"플래그 {f} 가 flags.json 에 없음")
    for path in sorted(folder.glob("persist_*.json")):
        found += 1
        validate(path, schemas["persist"])
    notes.append(f"게임이 만든 파일 {found}개 검사 ({folder.as_posix()})")


def main() -> int:
    parser = argparse.ArgumentParser(description="데이터 계약 검증기")
    parser.add_argument("--generated", type=Path, help="게임이 만든 세이브 파일 폴더 (예: tests/out)")
    args = parser.parse_args()
    schemas = load_schemas()
    for required in ("flags", "echo", "save", "persist", "emotions"):
        if required not in schemas:
            err("docs/schemas", f"{required}.schema.json 이 없거나 잘못됨")
    if errors:
        return report()

    flags_data = validate(DATA / "flags.json", schemas["flags"])
    flag_ids = check_flags(flags_data) if isinstance(flags_data, dict) else set()

    palette = load_palette()
    emotions_data = validate(DATA / "emotions.json", schemas["emotions"])
    bands = check_emotions(emotions_data, palette) if isinstance(emotions_data, dict) else {}
    check_palette(palette, bands)

    # 실제 잔향 데이터 (전체 개수 상한 검사)
    echo_files = sorted((DATA / "echoes").glob("*.json")) if (DATA / "echoes").exists() else []
    counts = check_echoes(schemas["echo"], flag_ids, echo_files)
    if counts:
        if counts["required"] > MAX_REQUIRED_ECHOES:
            err("game/data/echoes", f"필수 잔향 {counts['required']}개 > {MAX_REQUIRED_ECHOES}")
        if counts["hidden"] > MAX_HIDDEN_ECHOES:
            err("game/data/echoes", f"숨김 잔향 {counts['hidden']}개 > {MAX_HIDDEN_ECHOES}")
        notes.append(f"잔향: 필수 {counts['required']}/{MAX_REQUIRED_ECHOES}, 숨김 {counts['hidden']}/{MAX_HIDDEN_ECHOES}")
    else:
        notes.append("잔향 데이터 없음 (game/data/echoes/ — WP-06 이후)")

    # 예제 파일
    check_echoes(schemas["echo"], flag_ids, [EXAMPLES / "echo.example.json"])
    save = validate(EXAMPLES / "save.example.json", schemas["save"])
    if isinstance(save, dict):
        for f in save.get("state", {}).get("flags", {}):
            if f not in flag_ids:
                err("docs/schemas/examples/save.example.json", f"플래그 {f} 가 flags.json 에 없음")
    validate(EXAMPLES / "persist.example.json", schemas["persist"])
    if args.generated is not None:
        folder = args.generated if args.generated.is_absolute() else ROOT / args.generated
        check_generated(schemas, flag_ids, folder)
    return report()


def report() -> int:
    for n in notes:
        print(f"INFO  {n}")
    for e in errors:
        print(f"ERROR {e}")
    print(f"validate_data: 오류 {len(errors)}건")
    return 1 if errors else 0


if __name__ == "__main__":
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    sys.exit(main())
