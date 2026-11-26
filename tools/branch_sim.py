#!/usr/bin/env python3
"""분기 시뮬레이터 (WP-07). canon_v1 §10 엔딩 규칙의 파이썬 구현과 검증.

하는 일
  1. 전수 검사: 끝까지 플레이한 모든 상태(성향 차이 × bond × 재결합 × 숨김 잔향 × 꽃 × 희생 선택 × 이전 엔딩)가
     정확히 한 엔딩에 도달하는지, 다섯 엔딩이 모두 도달 가능한지, 폴백(규칙 6)이 얼마나 생기는지 센다.
  2. 대사 선택지 집계: game/dialogue/**/*.dialogue 의 [#choice=id] 응답을 읽어 메뉴별 성향 변화를 모으고,
     도달 가능한 (protect, heal) 조합으로 각 엔딩이 가능한지 본다. 대사가 없으면 기본 예산(24개 × +1~2)을 가정한다.
  3. 엔딩별 예시 경로를 출력한다.
  4. tests/fixtures/ending_cases.json 을 만든다 → GDScript EndingRules 와 교차 검증 (tests/unit/core/test_ending_rules.gd).

사용법
  python tools/branch_sim.py                  # 보고서
  python tools/branch_sim.py --check          # CI: 불변식 + 픽스처 최신 여부 검사 (실패 시 종료 코드 1)
  python tools/branch_sim.py --write-fixture  # 규칙을 바꾼 뒤 픽스처 갱신
"""
from __future__ import annotations

import argparse
import itertools
import json
import re
import sys
from collections import Counter
from dataclasses import dataclass, field
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
FIXTURE = ROOT / "tests/fixtures/ending_cases.json"
DIALOGUE = ROOT / "game/dialogue"

SACRIFICE, MIRACLE, FAMILY, HEAL, PROTECT = "sacrifice", "miracle", "family", "heal", "protect"
ENDINGS = [SACRIFICE, MIRACLE, FAMILY, HEAL, PROTECT]
BALANCE_THRESHOLD = 2
LEAN_THRESHOLD = 3
MAX_BOND = 4
FAMILY_MIN_REUNITED = 3
HEAL_MIN_REUNITED = 2
REQUIRED_ECHOES = 18
HIDDEN_ECHOES = 12
TOTAL_ECHOES = REQUIRED_ECHOES + HIDDEN_ECHOES
MAX_FAMILIES = 6
DEFAULT_CHOICES = 24  # canon §9: 챕터 2~5 선택지 약 24개


# ---------------------------------------------------------------- 규칙 (game/systems/core/ending_rules.gd 와 같아야 함)

def sacrifice_choice_available(s: dict) -> bool:
    seen = s.get("seen_endings", [])
    return (FAMILY in seen or MIRACLE in seen) and s.get("echo_found", 0) == TOTAL_ECHOES


def is_family_condition(s: dict) -> bool:
    diff = s.get("protect", 0) - s.get("heal", 0)
    return abs(diff) <= BALANCE_THRESHOLD and s.get("bond", 0) == MAX_BOND \
        and s.get("families_reunited", 0) >= FAMILY_MIN_REUNITED


def explain(s: dict) -> tuple[str, int]:
    diff = s.get("protect", 0) - s.get("heal", 0)
    families = s.get("families_reunited", 0)
    if sacrifice_choice_available(s) and s.get("offered_color", False):
        return SACRIFICE, 1
    fam = is_family_condition(s)
    if fam and s.get("hidden_echo_found", 0) == HIDDEN_ECHOES and s.get("rainbow_flower", False):
        return MIRACLE, 2
    if fam:
        return FAMILY, 3
    if -diff >= LEAN_THRESHOLD and families >= HEAL_MIN_REUNITED:
        return HEAL, 4
    if diff >= LEAN_THRESHOLD:
        return PROTECT, 5
    return PROTECT, 6


def evaluate(s: dict) -> str:
    return explain(s)[0]


# ---------------------------------------------------------------- 전수 검사

def end_states(max_diff: int):
    """끝까지 플레이한 상태들. 필수 잔향 18개는 진행상 반드시 모이므로 echo_found = 18 + 숨김."""
    for diff, bond, fam, hidden, rainbow, seen_prev in itertools.product(
            range(-max_diff, max_diff + 1), range(MAX_BOND + 1), range(MAX_FAMILIES + 1),
            range(HIDDEN_ECHOES + 1), (False, True), ((), (FAMILY,))):
        p, h = (diff, 0) if diff >= 0 else (0, -diff)
        base = {"protect": p, "heal": h, "bond": bond, "families_reunited": fam,
                "echo_found": REQUIRED_ECHOES + hidden, "hidden_echo_found": hidden,
                "rainbow_flower": rainbow, "offered_color": False, "seen_endings": list(seen_prev)}
        yield base
        if sacrifice_choice_available(base):  # 숨은 선택지는 보일 때만 고를 수 있다
            yield {**base, "offered_color": True}


@dataclass
class ExhaustiveReport:
    total: int = 0
    by_ending: Counter = field(default_factory=Counter)
    by_rule: Counter = field(default_factory=Counter)
    examples: dict = field(default_factory=dict)


def exhaustive(max_diff: int = 2 * DEFAULT_CHOICES) -> ExhaustiveReport:
    rep = ExhaustiveReport()
    for s in end_states(max_diff):
        ending, rule = explain(s)
        rep.total += 1
        rep.by_ending[ending] += 1
        rep.by_rule[rule] += 1
        rep.examples.setdefault((ending, rule), s)
    return rep


# ---------------------------------------------------------------- 대사 선택지

CHOICE_RE = re.compile(r"\[#[^\]]*choice=([a-z0-9_]+)")
ADD_RE = re.compile(r"\$>\s*GameState\.add_(protect|heal)\(\s*([0-9]+)\s*\)")


@dataclass
class Menu:
    where: str
    options: list[tuple[int, int]]  # (protect 증가, heal 증가)
    choice_ids: list[str]


def parse_menus(path: Path) -> tuple[list[Menu], list[str]]:
    """응답('- ')이 같은 들여쓰기로 이어진 묶음 = 메뉴 하나. 태그 없는 응답은 (0, 0)."""
    lines = path.read_text(encoding="utf-8").splitlines()
    menus: list[Menu] = []
    problems: list[str] = []
    i = 0
    rel = path.relative_to(ROOT).as_posix()

    def indent(s: str) -> int:
        return len(s) - len(s.lstrip("\t"))

    while i < len(lines):
        line = lines[i]
        if not line.lstrip("\t").startswith("- "):
            i += 1
            continue
        level = indent(line)
        menu = Menu(where=f"{rel}:{i + 1}", options=[], choice_ids=[])
        while i < len(lines):
            line = lines[i]
            stripped = line.lstrip("\t")
            if not stripped.strip():
                i += 1
                continue
            if indent(line) < level or (indent(line) == level and not stripped.startswith("- ")):
                break
            if indent(line) == level and stripped.startswith("- "):
                cid = CHOICE_RE.search(stripped)
                body: list[str] = []
                j = i + 1
                while j < len(lines) and (not lines[j].strip() or indent(lines[j]) > level):
                    if lines[j].strip():
                        body.append(lines[j])
                    j += 1
                adds = [(m.group(1), int(m.group(2))) for b in body if indent(b) == level + 1
                        for m in [ADD_RE.search(b)] if m]
                if cid:
                    menu.choice_ids.append(cid.group(1))
                    if len(adds) != 1 or adds[0][1] not in (1, 2):
                        problems.append(f"{rel}:{i + 1}: [#choice={cid.group(1)}] 응답은 첫 단계에 add_protect/add_heal(1|2)이 정확히 하나")
                        menu.options.append((0, 0))
                    else:
                        kind, n = adds[0]
                        menu.options.append((n, 0) if kind == "protect" else (0, n))
                else:
                    if adds:
                        problems.append(f"{rel}:{i + 1}: 성향을 바꾸는 응답에 [#choice=id] 태그가 없음")
                    menu.options.append((0, 0))
                i = j
                continue
            i += 1
        if menu.choice_ids:
            menus.append(menu)
    return menus, problems


def collect_menus() -> tuple[list[Menu], list[str]]:
    menus: list[Menu] = []
    problems: list[str] = []
    if DIALOGUE.exists():
        for path in sorted(DIALOGUE.rglob("*.dialogue")):
            m, p = parse_menus(path)
            menus += m
            problems += p
    return menus, problems


def reachable_pairs(menus: list[Menu]) -> set[tuple[int, int]]:
    states = {(0, 0)}
    for menu in menus:
        states = {(p + dp, h + dh) for (p, h) in states for (dp, dh) in set(menu.options)}
    return states


def default_menus(n: int = DEFAULT_CHOICES) -> list[Menu]:
    opts = [(1, 0), (2, 0), (0, 1), (0, 2), (0, 0)]
    return [Menu(where=f"(가정 {k + 1})", options=opts, choice_ids=[f"assumed_{k:02d}"]) for k in range(n)]


def endings_reachable(pairs: set[tuple[int, int]]) -> dict[str, tuple[int, int] | None]:
    """성향 쌍만 대사로 정해지고 나머지(bond·재결합·잔향·꽃)는 최선으로 맞췄을 때 각 엔딩 가능 여부."""
    best = {"bond": MAX_BOND, "families_reunited": MAX_FAMILIES, "echo_found": TOTAL_ECHOES,
            "hidden_echo_found": HIDDEN_ECHOES}
    found: dict[str, tuple[int, int] | None] = {e: None for e in ENDINGS}
    for p, h in sorted(pairs):
        variants = [
            {**best, "protect": p, "heal": h, "rainbow_flower": True, "offered_color": True, "seen_endings": [FAMILY]},
            {**best, "protect": p, "heal": h, "rainbow_flower": True},
            {**best, "protect": p, "heal": h},
            {**best, "protect": p, "heal": h, "bond": 0},
        ]
        for s in variants:
            e = evaluate(s)
            if found[e] is None:
                found[e] = (p, h)
    return found


# ---------------------------------------------------------------- 픽스처

def fixture_cases() -> list[dict]:
    cases = []
    for diff, bond, fam, hidden, rainbow, seen in itertools.product(
            (-4, -3, -2, 0, 2, 3, 4), (3, 4), (1, 2, 3), (11, 12), (False, True), ((), (FAMILY,), (MIRACLE,))):
        p, h = (diff + 5, 5) if diff >= 0 else (5, 5 - diff)
        base = {"protect": p, "heal": h, "bond": bond, "families_reunited": fam,
                "echo_found": REQUIRED_ECHOES + hidden, "hidden_echo_found": hidden,
                "rainbow_flower": rainbow, "offered_color": False, "seen_endings": list(seen)}
        for offered in (False, True):
            s = {**base, "offered_color": offered}
            ending, rule = explain(s)
            cases.append({"state": s, "ending": ending, "rule": rule})
    return cases


def fixture_text() -> str:
    data = {
        "description": "tools/branch_sim.py --write-fixture 로 생성. 직접 고치지 말 것. GDScript EndingRules 교차 검증용.",
        "rules_version": 1,
        "cases": fixture_cases(),
    }
    return json.dumps(data, ensure_ascii=False, indent=1) + "\n"


# ---------------------------------------------------------------- 실행

def report() -> int:
    rep = exhaustive()
    print(f"== 전수 검사: 끝 상태 {rep.total:,}개 (성향 차이 ±{2 * DEFAULT_CHOICES})")
    for e in ENDINGS:
        print(f"  {e:<9} {rep.by_ending[e]:>8,}")
    print("  규칙별:", ", ".join(f"{r}번 {rep.by_rule[r]:,}" for r in sorted(rep.by_rule)))
    print(f"  폴백(규칙 6) 비율: {rep.by_rule[6] / rep.total:.1%}  ← canon §10-2 빈틈을 보호 엔딩이 받는 비율")

    print("\n== 엔딩별 예시 상태")
    for (e, r), s in sorted(rep.examples.items(), key=lambda kv: (ENDINGS.index(kv[0][0]), kv[0][1])):
        brief = {k: s[k] for k in ("protect", "heal", "bond", "families_reunited", "hidden_echo_found",
                                   "rainbow_flower", "offered_color", "seen_endings")}
        print(f"  {e} (규칙 {r}): {brief}")

    menus, problems = collect_menus()
    print(f"\n== 대사 선택지: 메뉴 {len(menus)}개, 성향 응답 {sum(len(m.choice_ids) for m in menus)}개")
    for p in problems:
        print("  문제:", p)
    use = menus if menus else default_menus()
    if not menus:
        print(f"  대사 파일에 선택지가 없어 기본 예산을 가정: {DEFAULT_CHOICES}개 × (+1|+2 한쪽, 또는 중립)")
    pairs = reachable_pairs(use)
    found = endings_reachable(pairs)
    print(f"  도달 가능한 (protect, heal) 조합: {len(pairs):,}개")
    for e in ENDINGS:
        print(f"  {e:<9} {'가능 — 예: protect,heal=' + str(found[e]) if found[e] else '불가능!'}")
    return 0


def check() -> int:
    errors: list[str] = []
    rep = exhaustive()
    for e in ENDINGS:
        if rep.by_ending[e] == 0:
            errors.append(f"엔딩 {e} 에 도달하는 끝 상태가 없음")
    menus, problems = collect_menus()
    errors += problems
    found = endings_reachable(reachable_pairs(menus if menus else default_menus()))
    errors += [f"대사 선택지로 엔딩 {e} 에 도달할 수 없음" for e, v in found.items() if v is None]
    if not FIXTURE.exists() or FIXTURE.read_text(encoding="utf-8") != fixture_text():
        errors.append(f"{FIXTURE.relative_to(ROOT).as_posix()} 가 규칙과 다름 → python tools/branch_sim.py --write-fixture")
    for e in errors:
        print("ERROR", e)
    print(f"branch_sim: 오류 {len(errors)}건 (끝 상태 {rep.total:,}개, 대사 메뉴 {len(menus)}개)")
    return 1 if errors else 0


def self_test() -> int:
    import tempfile
    global ROOT
    sample = (
        "# scene: ch2_cafe\n~ start\njieun: 질문\n"
        "- [#choice=ch2_cafe_01] 지킨다\n\t$> GameState.add_protect(2)\n\tjieun: 응\n"
        "- [#choice=ch2_cafe_02] 돌본다\n\t$> GameState.add_heal(1)\n"
        "- 모르겠다\n\tjieun: 그래\n"
        "- 몰래 바꿈\n\t$> GameState.add_heal(1)\n"
        "=> END\n"
    )
    old_root = ROOT
    with tempfile.TemporaryDirectory() as tmp:
        ROOT = Path(tmp)
        p = ROOT / "game/dialogue/ch2/ch2_cafe.dialogue"
        p.parent.mkdir(parents=True)
        p.write_text(sample, encoding="utf-8")
        menus, problems = parse_menus(p)
    ROOT = old_root
    ok = True
    ok &= len(menus) == 1 and menus[0].options == [(2, 0), (0, 1), (0, 0), (0, 0)]
    ok &= len(problems) == 1 and "태그가 없음" in problems[0]
    ok &= evaluate({"protect": 10, "heal": 10, "bond": 3, "families_reunited": 6}) == PROTECT
    ok &= explain({"protect": 2, "heal": 9, "bond": 4, "families_reunited": 2}) == (HEAL, 4)
    ok &= reachable_pairs(menus) == {(2, 0), (0, 1), (0, 0)}
    print("self-test:", "통과" if ok else f"실패 menus={menus} problems={problems}")
    return 0 if ok else 1


def main() -> int:
    parser = argparse.ArgumentParser(description="분기 시뮬레이터 (WP-07)")
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--write-fixture", action="store_true")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        return self_test()
    if args.write_fixture:
        FIXTURE.parent.mkdir(parents=True, exist_ok=True)
        with FIXTURE.open("w", encoding="utf-8", newline="\n") as f:
            f.write(fixture_text())
        print(f"썼음: {FIXTURE.relative_to(ROOT).as_posix()} ({len(fixture_cases())}건)")
        return 0
    if args.check:
        return check()
    return report()


if __name__ == "__main__":
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    sys.exit(main())
