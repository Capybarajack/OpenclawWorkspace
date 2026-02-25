---
name: codex-openclaw-shared-lancedb
description: Configure and verify a shared LanceDB memory store between OpenClaw (memory-lancedb-pro) and Codex CLI workflows. Use when users ask for "Codex 跟 OpenClaw 共享記憶", "共用 LanceDB", "shared memory db", or to migrate both tools to one memory path.
---

# Codex + OpenClaw Shared LanceDB

Use this skill to make OpenClaw and Codex workflows read/write one shared LanceDB path.

## Use cases

1. **New shared-memory setup**
   - Trigger phrases: `共享記憶`, `同一個 LanceDB`, `shared memory`
   - Result: OpenClaw memory plugin points to a shared dbPath; Codex workflow uses the same path.

2. **Fix drifted paths**
   - Trigger phrases: `記憶不同步`, `Codex 跟 OpenClaw 記憶不一致`
   - Result: both sides are repointed to one canonical path and validated.

3. **Migration**
   - Trigger phrases: `把舊記憶搬到新庫`, `migrate to shared LanceDB`
   - Result: old data migrated and verified from both sides.

## Preconditions

- OpenClaw plugin `memory-lancedb-pro` is installed and enabled.
- User confirms a canonical shared path (example: `C:/Users/<user>/.openclaw/memory/lancedb-shared`).
- Do not run two independent writers at the exact same moment unless the workflow explicitly serializes writes.

## Workflow

### Step 1) Choose one canonical dbPath

- Normalize to absolute path (Windows use `/` or escaped `\\`).
- Store it once in notes/config so future sessions reuse the same value.

### Step 2) Point OpenClaw memory plugin to that path

Set:
- `plugins.slots.memory = "memory-lancedb-pro"`
- `plugins.entries.memory-lancedb-pro.enabled = true`
- `plugins.entries.memory-lancedb-pro.config.dbPath = <CANONICAL_PATH>`

If config edit changes plugin/runtime behavior, restart gateway after confirmation.

### Step 3) Create Codex-side shared-memory adapter contract

Because Codex CLI has no native LanceDB memory slot, enforce this contract in Codex tasks:

- Every Codex task that needs memory must receive:
  - `SHARED_LANCEDB_PATH=<CANONICAL_PATH>`
  - `MEMORY_SCOPE=<scope>` (default `global`)
- Codex task prompt must include:
  - `Before coding: recall relevant memories from shared LanceDB.`
  - `After coding: write key lessons back to shared LanceDB.`

Use `references/codex-prompt-template.md` as the default template.

### Step 4) Verification (must pass)

1. OpenClaw side: run one `memory_store` (or equivalent capture) into scope `global` with anchor text.
2. Codex side: run a task using the template and require recall of that anchor text.
3. Codex writes a new anchor memory back.
4. OpenClaw recalls Codex anchor successfully.

If any step fails, stop and fix path/scope/provider mismatch before continuing.

## Failure triage order

1. Wrong repo/plugin (editing built-in memory plugin instead of `memory-lancedb-pro`)
2. `dbPath` mismatch (different absolute paths)
3. Scope mismatch (`global` vs `agent:*`)
4. Embedding config mismatch (dimensions/model/provider)
5. Concurrent write contention / stale locks

## Success criteria

- Same canonical path documented and used by both sides.
- Two-way anchor test passes (OpenClaw -> Codex and Codex -> OpenClaw).
- No duplicate secondary memory store introduced.
