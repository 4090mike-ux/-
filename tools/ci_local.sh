#!/usr/bin/env bash
# 로컬 CI — 커밋·PR 전에 실행한다. 모든 WP의 완료 조건이다.
#   1) R-NAME·대사 규약·i18n 린트
#   2) 스키마·교차 검사·팔레트 검증
#   3) Godot 임포트 + 스크립트 파싱 검사
#   4) gdUnit4 테스트 (헤드리스. 렌더링이 필요한 테스트는 자동으로 건너뛰고 GitHub CI(xvfb)에서 실행)
#
# Godot 경로: 환경 변수 GODOT_BIN. Windows(Git Bash) 예:
#   export GODOT_BIN="/c/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe"
# CI_STRICT=1 이면 Godot 을 못 찾을 때 실패로 처리한다.
set -uo pipefail
cd "$(dirname "$0")/.."

PY="${PYTHON:-python}"
fail=0
step() { printf '\n== %s\n' "$1"; }

step "[1/4] lint_names (R-NAME·대사 규약·i18n)"
"$PY" tools/lint_names.py || fail=1

step "[2/4] validate_data (스키마·교차 검사·팔레트)"
"$PY" tools/validate_data.py || fail=1

GODOT="${GODOT_BIN:-$(command -v godot 2>/dev/null || command -v godot4 2>/dev/null || true)}"
if [ -z "$GODOT" ]; then
  step "[3/4][4/4] 건너뜀 — Godot 을 찾지 못함 (GODOT_BIN 을 설정하세요)"
  if [ "${CI_STRICT:-0}" = "1" ]; then fail=1; fi
else
  step "[3/4] Godot 임포트 + 스크립트 파싱 검사"
  "$GODOT" --headless --path . --import >/dev/null 2>&1 || true
  "$GODOT" --headless --path . -s res://tests/check_scripts.gd || fail=1

  step "[4/4] gdUnit4 테스트"
  "$GODOT" --headless --path . -s -d --remote-debug tcp://127.0.0.1:0 \
    res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -a res://tests -c
  rc=$?
  # gdUnit4 종료 코드: 0 = 성공, 101 = 경고만(통과로 봄), 그 외 = 실패
  if [ "$rc" -ne 0 ] && [ "$rc" -ne 101 ]; then fail=1; fi
fi

echo
if [ "$fail" -ne 0 ]; then
  echo "ci_local: 실패"
  exit 1
fi
echo "ci_local: 통과"
