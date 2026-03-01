# Local Team-Tasks Template (Keep Telegram Mode Too)

This template runs the same `team-tasks` pipeline locally (no Telegram dispatch), while preserving Telegram worker groups for future use.

## 1) Initialize project

Resolve `<skill-dir>` as the directory containing this skill (the folder that has `SKILL.md`).
Use `<python>` as `python` on Windows and typically `python3` on Linux/macOS.

```powershell
# Windows PowerShell
python <skill-dir>/scripts/task_manager.py init local-template -g "Build feature via local multi-agent pipeline" -p "code-agent,test-agent,docs-agent,monitor-bot"
```

```bash
# Linux/macOS
python3 <skill-dir>/scripts/task_manager.py init local-template -g "Build feature via local multi-agent pipeline" -p "code-agent,test-agent,docs-agent,monitor-bot"
```

## 2) Assign stage tasks

```bash
<python> <skill-dir>/scripts/task_manager.py assign local-template code-agent "Implement feature X in <repo-path>"
<python> <skill-dir>/scripts/task_manager.py assign local-template test-agent "Add/update tests for feature X"
<python> <skill-dir>/scripts/task_manager.py assign local-template docs-agent "Update docs/changelog for feature X"
<python> <skill-dir>/scripts/task_manager.py assign local-template monitor-bot "Audit quality, risk, and readiness"
```

## 3) Local dispatch loop (orchestrator behavior)

Repeat until done:

1. Get next stage
   - `task_manager.py next local-template --json`
2. Mark stage in-progress
   - `task_manager.py update local-template <agent> in-progress`
3. Dispatch locally (no Telegram)
   - `sessions_spawn(task=<formatted task>, agentId=<agent>, label="tt:local-template:<agent>", cleanup="keep")`
4. On completion, write summary in fixed visible format
   - `task_manager.py result local-template <agent> "<TT_RESULT block>"`
5. Mark done
   - `task_manager.py update local-template <agent> done`

Recommended `<TT_RESULT block>`:

```text
[TT_RESULT]
stage: <code-agent|test-agent|docs-agent|monitor-bot>
status: <ok|warn|fail>
summary: <1 sentence>
deliverables:
- <artifact or action 1>
- <artifact or action 2>
risks:
- <risk or none>
next:
- <next step>
[/TT_RESULT]
```

## 4) Keep Telegram mode available

Do not remove Telegram bindings/groups. Local mode only changes dispatch method per run:

- Local run: `sessions_spawn(..., agentId=...)`
- Telegram run: `sessions_send(sessionKey="agent:<agent>:telegram:group:<id>", ...)`

Both can coexist with the same `task_manager.py` project/state model.

## 5) Cross-machine portability checklist

- Keep this whole folder in git: `skills/team-tasks/`
- Keep pipeline state in repo path: `data/team-tasks/` (or set `TEAM_TASKS_DIR` explicitly)
- On a new machine, clone repo then run commands via `<python> <skill-dir>/scripts/task_manager.py ...`

## 6) Quick smoke test task texts

- code-agent: `Create hello endpoint and wiring`
- test-agent: `Add endpoint tests`
- docs-agent: `Document endpoint usage`
- monitor-bot: `Check quality and release notes`

Use these first to verify local orchestration before real workloads.
