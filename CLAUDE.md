@AGENTS.md

## Claude Code 전용 메모

- 프로젝트 규칙은 위 AGENTS.md가 전부다. 여기에는 Claude 전용 사항만 둔다.
- GDScript·.tscn·셰이더·.dialogue를 다룰 때는 `godot-conventions` 스킬을 먼저 읽는다(`.claude/skills/godot-conventions/SKILL.md`).
- 구현 서브에이전트는 `isolation: "worktree"`로 띄운다. 동시 실행은 평시 3개, 최대 5개.
- Godot·Dialogue Manager·gdUnit4 API가 확실하지 않으면 Context7로 최신 문서를 확인한다. 기억에 의존하지 않는다.
- Godot MCP(`claude mcp add godot -- npx @coding-solo/godot-mcp`)를 연결했다면 실행·디버그 출력 확인에 쓴다. 한 프로젝트에는 MCP 서버 하나만 연결한다.
