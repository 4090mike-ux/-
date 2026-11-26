#!/usr/bin/env bash
# WP 작업용 git 워크트리를 만든다. 구현 에이전트는 반드시 워크트리에서 작업한다(AGENTS.md).
#
# 사용: tools/new_worktree.sh WP-05 color-shader
#   → 폴더  ../<저장소 폴더명>-wt/WP-05-color-shader
#   → 브랜치 wp/WP-05-color-shader (origin/main 또는 main 에서 시작)
# 끝나면: PR 병합 후  git worktree remove "<폴더>"  그리고  git branch -d wp/...
set -euo pipefail

if [ $# -lt 2 ]; then
  echo "사용: $0 <WP-ID> <짧은-설명>   예: $0 WP-12 echo-sense"
  exit 1
fi
wp="$1"
slug="$2"
if ! [[ "$wp" =~ ^WP-[0-9]{2}[a-z]?$ ]]; then
  echo "WP id 형식: WP-05, WP-33a"
  exit 1
fi
if ! [[ "$slug" =~ ^[a-z0-9-]+$ ]]; then
  echo "설명은 영문 소문자·숫자·하이픈만"
  exit 1
fi

root="$(git rev-parse --show-toplevel)"
name="$(basename "$root")"
dir="$(dirname "$root")/${name}-wt/${wp}-${slug}"
branch="wp/${wp}-${slug}"

git -C "$root" fetch --quiet origin 2>/dev/null || true
start="main"
if git -C "$root" rev-parse --verify --quiet origin/main >/dev/null; then
  start="origin/main"
fi

git -C "$root" worktree add -b "$branch" "$dir" "$start"
echo
echo "워크트리: $dir"
echo "브랜치:   $branch  (시작점: $start)"
echo "처음 한 번: Godot 캐시 생성  \"\$GODOT_BIN\" --headless --path \"$dir\" --import"
