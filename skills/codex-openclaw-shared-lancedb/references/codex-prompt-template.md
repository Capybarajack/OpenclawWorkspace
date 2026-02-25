# Codex Prompt Template (Shared LanceDB)

Use this template when dispatching Codex tasks that must share memory with OpenClaw.

```text
You are working in a workflow that shares one LanceDB memory store with OpenClaw.

Environment:
- SHARED_LANCEDB_PATH={{ABSOLUTE_PATH}}
- MEMORY_SCOPE={{global_or_custom_scope}}

Rules:
1) Before implementation, recall relevant memory from SHARED_LANCEDB_PATH using MEMORY_SCOPE.
2) Use recalled constraints/lessons while implementing.
3) After implementation, write back concise lessons (Pitfall/Cause/Fix/Prevention + Decision principle).
4) Keep memory entries atomic (<500 chars) and non-secret.

Task:
{{TASK}}

Output:
- What you recalled
- What you changed
- What you stored back
```

## Notes

- Keep scope stable (default `global`) unless isolation is intended.
- If memory retrieval fails, do not continue blind; fix path/scope first.
