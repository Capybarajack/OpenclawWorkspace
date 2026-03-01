---
name: team-tasks
description: "Coordinate multi-agent development pipelines using shared JSON task files. Use when dispatching work across dev team agents (code-agent, test-agent, docs-agent, monitor-bot), tracking pipeline progress, or running sequential/parallel workflows. Covers project init, task assignment, status tracking, agent dispatch via sessions_send, and result collection. Supports two modes: linear (sequential pipeline) and dag (dependency graph with parallel execution)."
---

# Team Tasks — Multi-Agent Pipeline Coordination

## Overview

Coordinate dev team agents through shared JSON task files and AGI dispatch.
AGI is the command center; agents do not talk to each other directly.

**Two modes:**
- **Mode A (linear):** fixed pipeline order (`code → test → docs → monitor`)
- **Mode B (dag):** task dependencies with parallel dispatch when deps are satisfied

## Runtime Setup (Cross-Platform)

Resolve `<skill-dir>` as the directory containing this `SKILL.md`.

Prefer this command pattern:

```bash
<python> <skill-dir>/scripts/task_manager.py <command> [args]
```

- On Linux/macOS, `<python>` is usually `python3`
- On Windows, `<python>` is usually `python`

If needed, set a convenience alias/variable once per shell:

```bash
TM="<python> <skill-dir>/scripts/task_manager.py"
```

## Quick Reference

| Command | Mode | Usage | Description |
|---------|------|-------|-------------|
| `init` | both | `init <project> -g "goal" [-m linear\|dag]` | Create project |
| `add` | dag | `add <project> <task-id> -a <agent> -d <deps>` | Add task with deps |
| `status` | both | `status <project> [--json]` | Show progress |
| `assign` | both | `assign <project> <task> "desc"` | Set task description |
| `update` | both | `update <project> <task> <status>` | Change status |
| `next` | linear | `next <project> [--json]` | Get next stage |
| `ready` | dag | `ready <project> [--json]` | Get all dispatchable tasks |
| `graph` | dag | `graph <project>` | Show dependency tree |
| `log` | both | `log <project> <task> "msg"` | Add log entry |
| `result` | both | `result <project> <task> "output"` | Save output |
| `reset` | both | `reset <project> [task] [--all]` | Reset to pending |
| `list` | both | `list` | List all projects |

### Status Values

- `pending` — waiting for dispatch
- `in-progress` — agent is working
- `done` — stage completed
- `failed` — stage failed (pipeline blocks)
- `skipped` — intentionally skipped

## Pipeline Workflow (Mode A: Linear)

### Step 1: Initialize Project

```bash
$TM init my-project \
  -g "Build a REST API with tests and docs" \
  -p "code-agent,test-agent,docs-agent,monitor-bot"
```

Default pipeline order: `code-agent → test-agent → docs-agent → monitor-bot`.

### Step 2: Assign Tasks to All Stages

```bash
$TM assign my-project code-agent "Implement REST API with Flask: GET/POST/DELETE /items"
$TM assign my-project test-agent "Write pytest tests for all endpoints, target 90%+ coverage"
$TM assign my-project docs-agent "Write README.md with API docs, setup guide, examples"
$TM assign my-project monitor-bot "Verify code quality, check for security issues, validate deployment readiness"
```

### Step 3: Dispatch Agents Sequentially

For each stage, AGI follows this loop:

```
1. Check next stage:   task_manager.py next <project> --json
2. Mark in-progress:   task_manager.py update <project> <agent> in-progress
3. Dispatch agent:     sessions_send(sessionKey="agent:<agent>:<channel>:<scope>:<id>", message=<task>)
4. Wait for reply      (sessions_send returns the agent's response)
5. Save result:        task_manager.py result <project> <agent> "<summary>"
6. Mark done:          task_manager.py update <project> <agent> done
7. Repeat from 1       (currentStage auto-advances)
```

### Step 4: Handle Failures

If an agent fails:

```bash
$TM update my-project code-agent failed
$TM log my-project code-agent "Failed: syntax error in main.py"
```

To retry:

```bash
$TM reset my-project code-agent
$TM update my-project code-agent in-progress
# Re-dispatch...
```

### Step 5: Check Progress Anytime

```bash
$TM status my-project
```

Example output:

```
📋 Project: my-project
🎯 Goal: Build a REST API with tests and docs
📊 Status: active
▶️  Current: test-agent

  ✅ code-agent: done
     Task: Implement REST API with Flask
     Output: Created <project-path>/app.py
  🔄 test-agent: in-progress
     Task: Write pytest tests for all endpoints
  ⬜ docs-agent: pending
  ⬜ monitor-bot: pending

  Progress: [██░░] 2/4
```

## Agent Dispatch Details

### Session Keys

Do not hardcode channel/group IDs in this skill.
Use your environment’s real session keys from OpenClaw (`sessions_list`) or your local notes.

Common pattern:

- `agent:code-agent:<channel>:<scope>:<id>`
- `agent:test-agent:<channel>:<scope>:<id>`
- `agent:docs-agent:<channel>:<scope>:<id>`
- `agent:monitor-bot:<channel>:<scope>:<id>`

### Dispatch Template

When dispatching to an agent, include:
1. **Project context** — what the project is about
2. **Specific task** — what this agent should do
3. **Working directory** — where to create/find files
4. **Previous stage output** — if relevant (for example, test-agent needs code-agent output)

Example dispatch message:

```
Project: my-project
Goal: Build a REST API with tests and docs
Your task: Write pytest tests for all endpoints in <project-path>/app.py
Target: 90%+ coverage, test GET/POST/DELETE /items
Working directory: <project-path>/
Previous stage (code-agent) output: Created app.py with Flask REST API, 3 endpoints
```

### Delivery Context Note

If an agent session was first created via `sessions_send`, its delivery context can differ from the target chat channel.
When needed, relay key results with `message` after collecting the sub-agent output.

## Mode B: DAG Workflow (Parallel Dependencies)

### Step 1: Initialize DAG Project

```bash
$TM init my-project -m dag -g "Build REST API with parallel workstreams"
```

### Step 2: Add Tasks with Dependencies

```bash
# Root tasks (no deps — can run in parallel)
$TM add my-project design      -a docs-agent  --desc "Write API spec"
$TM add my-project scaffold    -a code-agent  --desc "Create project skeleton"

# Tasks with dependencies (blocked until deps are done)
$TM add my-project implement   -a code-agent  -d "design,scaffold" --desc "Implement API"
$TM add my-project write-tests -a test-agent  -d "design"          --desc "Write test cases from spec"

# Fan-in: depends on multiple tasks
$TM add my-project run-tests   -a test-agent  -d "implement,write-tests" --desc "Run all tests"
$TM add my-project write-docs  -a docs-agent  -d "implement"             --desc "Write final docs"

# Final gate
$TM add my-project review      -a monitor-bot -d "run-tests,write-docs"  --desc "Final review"
```

### Step 3: View DAG Graph

```bash
$TM graph my-project
```

### Step 4: Dispatch Ready Tasks

```bash
$TM ready my-project
```

For each ready task, AGI follows this loop:

```
1. Get ready tasks:     task_manager.py ready <project> --json
2. For each ready task (can dispatch in parallel):
   a. Mark in-progress: task_manager.py update <project> <task> in-progress
   b. Dispatch agent:   sessions_send(sessionKey=..., message=<task + dep outputs>)
3. When agent replies:
   a. Save result:      task_manager.py result <project> <task> "<summary>"
   b. Mark done:        task_manager.py update <project> <task> done
   c. Check newly unblocked tasks (printed automatically)
4. Repeat until all done
```

### Key DAG Features

- **Parallel dispatch**: `ready` returns all tasks whose deps are satisfied
- **Dep outputs forwarding**: `ready --json` includes `depOutputs`
- **Auto-unblock notification**: completion prints newly unblocked tasks
- **Cycle detection**: `add` rejects circular dependencies
- **Partial failure**: unrelated branches continue when one task fails
- **Graph visualization**: `graph` shows task tree with status icons

## Custom Pipelines

### Linear (Mode A)

```bash
# Code + test only
$TM init quick-fix -g "Hotfix" -p "code-agent,test-agent"

# Docs first, then code
$TM init spec-driven -g "Spec-driven dev" -p "docs-agent,code-agent,test-agent"
```

### DAG (Mode B)

```bash
# Diamond pattern: 2 parallel branches merge for review
$TM init diamond -m dag -g "Parallel dev"
$TM add diamond code      -a code-agent  --desc "Write code"
$TM add diamond test      -a test-agent  --desc "Write tests"
$TM add diamond integrate -a code-agent  -d "code,test" --desc "Integration"
$TM add diamond review    -a monitor-bot -d "integrate" --desc "Final review"
```

## Choosing Between Modes

| | Mode A (linear) | Mode B (dag) | Mode C (local workers, no Telegram) |
|---|---|---|---|
| **When** | Sequential tasks, simple flows | Parallel workstreams, complex deps | You want local orchestration and lower channel/network dependency |
| **Dispatch** | One at a time, auto-advance | Multiple simultaneous, dependency-driven | Use `sessions_spawn(agentId=...)` or local session routing |
| **Setup** | `init -p agents` (one command) | `init -m dag` + `add` per task | Keep task manager JSON + dispatch to local workers |
| **Best for** | Bug fixes, simple features | Larger features, spec-driven dev | Stable local pipelines while keeping Telegram workers optional |

## Mode C: Local Worker Template (No Telegram)

Keep Telegram worker mode available, but dispatch tasks locally.

### Step 1: Initialize a local template project

```bash
$TM init local-template -g "Build feature via local multi-agent pipeline" -p "code-agent,test-agent,docs-agent,monitor-bot"
```

### Step 2: Assign stage tasks

```bash
$TM assign local-template code-agent "Implement feature X in <repo-path>"
$TM assign local-template test-agent "Create/update tests for feature X"
$TM assign local-template docs-agent "Update docs/changelog for feature X"
$TM assign local-template monitor-bot "Review quality, risks, and release readiness"
```

### Step 3: Dispatch each stage to local workers

For each stage from `task_manager.py next <project> --json`:

1. Mark stage in progress.
2. Run local sub-agent task:
   - `sessions_spawn(task=<task text>, agentId=<stage-agent>, label="tt:<project>:<stage>")`
3. Capture completion summary.
4. Save result with `task_manager.py result ...`.
5. Mark stage done with `task_manager.py update ... done`.

This preserves the same task-manager state machine while avoiding Telegram transport.

Reference workflow: `docs/LOCAL_TEMPLATE.md`.

## Data Location

Task files are stored under `TEAM_TASKS_DIR/<project>.json`.
If `TEAM_TASKS_DIR` is not set, default is `<workspace>/data/team-tasks/<project>.json` (portable across machines after clone).

## Common Pitfalls

### Mode A: Stage ID is agent name, not a number

In linear mode, stage ID is the **agent name** (for example `code-agent`), not a numeric index.

```bash
# ❌ WRONG — stage '1' not found
$TM assign my-project 1 "Build API"
$TM update my-project 1 done

# ✅ CORRECT
$TM assign my-project code-agent "Build API"
$TM update my-project code-agent done
$TM result my-project code-agent "Created main.py"
```

This applies to `assign`, `update`, `result`, `log`, and `reset`.

## Tips

- Keep one project per focused goal
- Use meaningful project slugs (`rest-api-v2`, `bug-fix-auth`, `refactor-db`)
- Save `result` before setting `done` to preserve context
- Use `log` aggressively to simplify debugging
- Use `reset --all` for clean reruns and `reset <stage>` for targeted retries
- Design DAGs with fan-out/fan-in patterns for efficient parallelism
