#!/usr/bin/env python3
"""R-NAME 금지어·대사 규약·i18n 키 린터.

검사 항목
  1. R-NAME: 진실 공개 전 콘텐츠에 본명(은하늘, 은별 등)이 있는가        (docs/bible/canon_v1.md §4)
  2. 금지 문장·원문 미션명                                                (docs/bible/forbidden_terms.json)
  3. .dialogue 머리말(# scene, # r-name), 화자 키, 태그, [#choice] id 중복 (docs/schemas/dialogue_conventions.md)
  4. i18n: tr("키")와 데이터의 name_key 가 game/i18n/*.csv 에 있는가, 키 중복

사용법
  python tools/lint_names.py              # 저장소 전체 검사, 오류가 있으면 종료 코드 1
  python tools/lint_names.py --self-test  # 린터 자체 테스트
"""
from __future__ import annotations

import argparse
import csv
import json
import re
import sys
import tempfile
from dataclasses import dataclass, field
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

PRE_SECTIONS = {"prologue", "ch1", "ch2", "ch3"}
POST_SECTIONS = {"ch5", "endings"}
HEADER_SECTIONS = {"ch4"}
ALL_SECTIONS = PRE_SECTIONS | POST_SECTIONS | HEADER_SECTIONS

# 태그 이름 → 허용 값 집합 (None = 값 없음, "*" = 형식만 검사)
EMOTIONS = {"longing", "warmth", "dream", "courage", "healing"}
PORTRAITS = {
    "neutral", "smile", "sad", "surprised", "angry", "scared",
    "worried", "determined", "tearful", "laugh", "thinking", "blank",
}
TAG_RULES: dict[str, object] = {
    "sync": None,
    "portrait": PORTRAITS,
    "emotion": EMOTIONS,
    "cutin": {"protect"},
    "echo": re.compile(r"^echo\.(prologue|ch[1-5])\.[a-z][a-z0-9_]*$"),
    "choice": re.compile(r"^(prologue|ch[1-5]|endings)_[a-z0-9]+_[0-9]{2}$"),
    "sfx": re.compile(r"^[a-z0-9_]+$"),
    "bgm": re.compile(r"^[a-z0-9_]+$"),
}

NON_SPEAKER_PREFIXES = (
    "~ ", "=> ", "=>< ", "- ", "if ", "elif ", "else", "while ", "match ", "when ",
    "$>", "set ", "do ", "import ", "using ", "#",
)
TAG_BLOCK_RE = re.compile(r"\[#([^\]]*)\]")
TR_CALL_RE = re.compile(r"""\btr\(\s*(["'])([^"']+)\1""")
HANGUL = "가-힣"


@dataclass
class Report:
    errors: list[str] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)

    def error(self, path: Path, line: int, msg: str, root: Path) -> None:
        self.errors.append(f"{_rel(path, root)}:{line}: {msg}")

    def warn(self, path: Path, line: int, msg: str, root: Path) -> None:
        self.warnings.append(f"{_rel(path, root)}:{line}: {msg}")


def _rel(path: Path, root: Path) -> str:
    try:
        return path.relative_to(root).as_posix()
    except ValueError:
        return path.as_posix()


@dataclass
class TermRule:
    rule_id: str
    scope: str  # "pre_truth" | "game"
    message: str
    patterns: list[re.Pattern[str]]


def load_term_rules(root: Path) -> list[TermRule]:
    data = json.loads((root / "docs/bible/forbidden_terms.json").read_text(encoding="utf-8"))
    rules: list[TermRule] = []
    for r in data["rules"]:
        pats: list[re.Pattern[str]] = []
        for term in r.get("terms", []):
            prefix = f"(?<![{HANGUL}])" if re.match(f"[{HANGUL}]", term) else ""
            pats.append(re.compile(prefix + re.escape(term)))
        for term in r.get("terms_ci", []):
            pats.append(re.compile(r"\b" + re.escape(term) + r"\b", re.IGNORECASE))
        rules.append(TermRule(r["id"], r["scope"], r["message"], pats))
    return rules


def check_terms(text: str, pre_truth: bool, rules: list[TermRule]) -> list[str]:
    hits: list[str] = []
    for rule in rules:
        if rule.scope == "pre_truth" and not pre_truth:
            continue
        for pat in rule.patterns:
            m = pat.search(text)
            if m:
                hits.append(f"[{rule.rule_id}] '{m.group(0)}' — {rule.message}")
    return hits


def load_speakers(root: Path) -> set[str]:
    path = root / "game/data/speakers.json"
    if not path.exists():
        return set()
    data = json.loads(path.read_text(encoding="utf-8"))
    return {s["key"] for s in data["speakers"]}


def load_i18n(root: Path, report: Report, rules: list[TermRule]) -> set[str]:
    keys: set[str] = set()
    for csv_path in sorted((root / "game/i18n").glob("*.csv")) if (root / "game/i18n").exists() else []:
        with csv_path.open(encoding="utf-8", newline="") as f:
            reader = csv.reader(f)
            header = next(reader, None)
            if not header or header[0] != "keys":
                report.error(csv_path, 1, "첫 열 머리글은 'keys' 여야 한다 (Godot 번역 CSV 형식)", root)
                continue
            for lineno, row in enumerate(reader, start=2):
                if not row or not row[0].strip():
                    continue
                key = row[0].strip()
                if key in keys:
                    report.error(csv_path, lineno, f"i18n 키 중복: {key}", root)
                keys.add(key)
                pre_truth = not key.startswith("truth.")
                for hit in check_terms(" | ".join(row[1:]), pre_truth, rules):
                    report.error(csv_path, lineno, f"{key}: {hit}", root)
    return keys


def dialogue_phase(path: Path, root: Path, header: dict[str, str], report: Report) -> bool | None:
    """True = 진실 공개 전(pre), False = 후(post), None = 판정 불가(오류 보고됨)."""
    rel = path.relative_to(root / "game/dialogue")
    section = rel.parts[0] if len(rel.parts) > 1 else ""
    declared = header.get("r-name")
    if section not in ALL_SECTIONS:
        report.error(path, 1, f"알 수 없는 구간 폴더 '{section}' (허용: {sorted(ALL_SECTIONS)})", root)
        return None
    if declared is not None and declared not in ("pre", "post"):
        report.error(path, 1, f"# r-name 값은 pre 또는 post (현재: {declared})", root)
        return None
    if section in HEADER_SECTIONS:
        if declared is None:
            report.error(path, 1, "ch4 대사는 머리말 '# r-name: pre|post' 가 필수", root)
            return None
        return declared == "pre"
    auto = "pre" if section in PRE_SECTIONS else "post"
    if declared is not None and declared != auto:
        report.error(path, 1, f"{section} 은(는) 항상 r-name: {auto} (머리말과 충돌)", root)
    return auto == "pre"


def parse_header(lines: list[str]) -> dict[str, str]:
    header: dict[str, str] = {}
    for line in lines:
        s = line.strip()
        if not s:
            continue
        if not s.startswith("#"):
            break
        m = re.match(r"#\s*([a-z-]+)\s*:\s*(.+)$", s)
        if m:
            header[m.group(1)] = m.group(2).strip()
    return header


def check_tags(text: str) -> list[str]:
    problems: list[str] = []
    for block in TAG_BLOCK_RE.findall(text):
        for raw in block.split(","):
            tag = raw.strip().lstrip("#")
            if not tag:
                continue
            name, _, value = tag.partition("=")
            rule = TAG_RULES.get(name)
            if name not in TAG_RULES:
                problems.append(f"규약에 없는 태그 [#{tag}] (dialogue_conventions.md §4)")
            elif rule is None and value:
                problems.append(f"[#{name}] 은(는) 값을 받지 않는다")
            elif isinstance(rule, set) and value not in rule:
                problems.append(f"[#{name}={value}] 허용 값: {sorted(rule)}")
            elif isinstance(rule, re.Pattern) and not rule.match(value):
                problems.append(f"[#{name}={value}] 형식 오류 ({rule.pattern})")
    return problems


def speaker_of(line: str) -> str | None:
    s = line.lstrip("\t ")
    s = re.sub(r"^(\|\s|%\d*\s+)", "", s)
    if not s or s.startswith(NON_SPEAKER_PREFIXES):
        return None
    s = s.replace("\\:", "")
    if ": " not in s:
        return None
    return s.split(": ", 1)[0].strip()


def lint_dialogue(path: Path, root: Path, speakers: set[str], rules: list[TermRule],
                  choice_ids: dict[str, str], report: Report) -> None:
    lines = path.read_text(encoding="utf-8").splitlines()
    header = parse_header(lines)
    if header.get("scene") != path.stem:
        report.error(path, 1, f"머리말 '# scene: {path.stem}' 가 필요 (현재: {header.get('scene')})", root)
    if not any(l.strip() == "~ start" for l in lines):
        report.error(path, 1, "'~ start' 큐가 없다", root)
    pre = dialogue_phase(path, root, header, report)
    for lineno, line in enumerate(lines, start=1):
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        if pre is not None:
            for hit in check_terms(line, pre, rules):
                report.error(path, lineno, hit, root)
        spk = speaker_of(line)
        if spk is not None and not (spk.startswith("{{") and spk.endswith("}}")):
            if spk not in speakers:
                report.error(path, lineno,
                             f"화자 '{spk}' 는 speakers.json 에 없는 키 (표시 이름 대신 키를 쓴다, R-NAME)", root)
        for problem in check_tags(line):
            report.error(path, lineno, problem, root)
        for cid in re.findall(r"#choice=([^\],\s]+)", line):
            where = f"{_rel(path, root)}:{lineno}"
            if cid in choice_ids:
                report.error(path, lineno, f"[#choice={cid}] 중복 (먼저 나온 곳: {choice_ids[cid]})", root)
            else:
                choice_ids[cid] = where


def lint_code_and_data(root: Path, rules: list[TermRule], i18n: set[str], report: Report) -> None:
    game = root / "game"
    if not game.exists():
        return
    for path in sorted(game.rglob("*")):
        if not path.is_file() or path.suffix not in {".gd", ".tscn", ".tres", ".json", ".gdshader"}:
            continue
        text = path.read_text(encoding="utf-8", errors="replace")
        for lineno, line in enumerate(text.splitlines(), start=1):
            # 코드·씬·데이터에는 본명을 직접 쓰지 않는다. 이름은 i18n 키(truth.*)로만.
            for hit in check_terms(line, True, rules):
                report.error(path, lineno, hit, root)
            if path.suffix == ".gd":
                for _, key in TR_CALL_RE.findall(line):
                    if key not in i18n:
                        report.error(path, lineno, f"tr(\"{key}\") 키가 game/i18n/*.csv 에 없다", root)
        if path.suffix == ".json":
            check_data_keys(path, root, text, i18n, report)


def check_data_keys(path: Path, root: Path, text: str, i18n: set[str], report: Report) -> None:
    try:
        data = json.loads(text)
    except json.JSONDecodeError as exc:
        report.error(path, exc.lineno, f"JSON 파싱 실패: {exc.msg}", root)
        return

    def walk(node: object) -> None:
        if isinstance(node, dict):
            for k, v in node.items():
                if k in ("name_key", "truth_name_key") and isinstance(v, str) and v and v not in i18n:
                    report.error(path, 1, f"{k} '{v}' 가 game/i18n/*.csv 에 없다", root)
                walk(v)
        elif isinstance(node, list):
            for item in node:
                walk(item)

    walk(data)


def run(root: Path) -> Report:
    report = Report()
    rules = load_term_rules(root)
    speakers = load_speakers(root)
    i18n = load_i18n(root, report, rules)
    choice_ids: dict[str, str] = {}
    dialogue_root = root / "game/dialogue"
    if dialogue_root.exists():
        for path in sorted(dialogue_root.rglob("*.dialogue")):
            lint_dialogue(path, root, speakers, rules, choice_ids, report)
    lint_code_and_data(root, rules, i18n, report)
    return report


# ---------------------------------------------------------------- self-test

def _self_test() -> int:
    terms = (ROOT / "docs/bible/forbidden_terms.json").read_text(encoding="utf-8")
    cases: list[tuple[str, dict[str, str], list[str]]] = [
        ("정상 pre 대사", {
            "game/dialogue/ch1/ch1_atelier.dialogue":
                "# scene: ch1_atelier\n~ start\nhaneul: [#portrait=smile] 하늘이 웃었다. 작은별 노래.\n"
                "| byeol: [#sync] 같은 말!\n지문\\: 시간은 오후.\n=> END\n",
        }, []),
        ("pre 구간 본명", {
            "game/dialogue/ch2/ch2_cafe.dialogue":
                "# scene: ch2_cafe\n~ start\njieun: 은별 씨 맞죠?\n=> END\n",
        }, ["R-NAME"]),
        ("post 구간 본명 허용", {
            "game/dialogue/ch5/ch5_final.dialogue":
                "# scene: ch5_final\n~ start\nhaneul: 은별아.\n=> END\n",
        }, []),
        ("ch4 머리말 누락", {
            "game/dialogue/ch4/ch4_storm.dialogue": "# scene: ch4_storm\n~ start\nhaneul: …\n=> END\n",
        }, ["ch4 대사는 머리말"]),
        ("표시 이름 화자", {
            "game/dialogue/ch1/ch1_square.dialogue": "# scene: ch1_square\n~ start\n하늘: 안녕.\n=> END\n",
        }, ["화자 '하늘'"]),
        ("미등록 태그·choice 중복", {
            "game/dialogue/ch2/ch2_park.dialogue":
                "# scene: ch2_park\n~ start\n- [#choice=ch2_park_01] 가자\n\t$> GameState.add_protect(1)\n"
                "- [#choice=ch2_park_01] 쉬자\n\t$> GameState.add_heal(1)\nbyeol: [#mood=happy] 응\n=> END\n",
        }, ["중복", "규약에 없는 태그"]),
        ("i18n truth 키 허용 / 일반 키 금지", {
            "game/i18n/x.csv": "keys,ko\ntruth.name.byeol,은별\nmission.bad,은별의 방\n",
        }, ["mission.bad"]),
        ("코드 본명·tr 키 누락", {
            "game/systems/x.gd": 'var a := "은하늘"\nvar b := tr("missing.key")\n',
        }, ["R-NAME", "missing.key"]),
        ("폐기 문장", {
            "game/dialogue/endings/end_family.dialogue":
                "# scene: end_family\n~ start\n사랑은 어떤 실험보다도 강하다.\n=> END\n",
        }, ["R-QUOTE"]),
    ]
    failed = 0
    for name, files, expected in cases:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "docs/bible").mkdir(parents=True)
            (root / "docs/bible/forbidden_terms.json").write_text(terms, encoding="utf-8")
            (root / "game/data").mkdir(parents=True)
            (root / "game/data/speakers.json").write_text(
                json.dumps({"speakers": [{"key": k} for k in ("haneul", "byeol", "jieun")]}), encoding="utf-8")
            for rel, content in files.items():
                p = root / rel
                p.parent.mkdir(parents=True, exist_ok=True)
                p.write_text(content, encoding="utf-8")
            report = run(root)
            joined = "\n".join(report.errors)
            ok = all(e in joined for e in expected) and (bool(report.errors) == bool(expected))
            print(f"[{'PASS' if ok else 'FAIL'}] {name}")
            if not ok:
                failed += 1
                print("   기대:", expected)
                print("   실제:", report.errors or "(오류 없음)")
    print(f"self-test: {len(cases) - failed}/{len(cases)} 통과")
    return 1 if failed else 0


def main() -> int:
    parser = argparse.ArgumentParser(description="R-NAME·대사 규약·i18n 린터")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        return _self_test()
    report = run(ROOT)
    for w in report.warnings:
        print(f"WARN  {w}")
    for e in report.errors:
        print(f"ERROR {e}")
    print(f"lint_names: 오류 {len(report.errors)}건, 경고 {len(report.warnings)}건")
    return 1 if report.errors else 0


if __name__ == "__main__":
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    sys.exit(main())
