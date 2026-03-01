---
name: memory-lancedb-pro
description: Use the memory-lancedb-pro plugin tools for long-term memory capture and recall. Trigger when users ask to remember lessons, retrieve past decisions, store preferences, or clean up memory records.
---

# Memory LanceDB Pro Workflow

Use this skill when the user wants durable memory operations.

## When to trigger

- User says: remember this / 記住這件事 / store this lesson
- User asks: what did we decide before? / we did this last time?
- User asks to update/delete an existing memory

## Steps

1. Identify intent: `store`, `recall`, `update`, or `forget`.
2. Choose category (`preference`, `fact`, `decision`, `entity`, `other`) and scope (default `global` unless user specifies).
3. Execute memory tool:
   - Store → `memory_store`
   - Recall → `memory_recall`
   - Update → `memory_update`
   - Delete → `memory_forget`
4. For lesson capture, store two entries:
   - Technical fact (root cause + fix)
   - Decision rule (when to apply + action)
5. Confirm result briefly and include IDs when available.

## Quality rules

- Keep entries atomic and concise (<500 chars each).
- Avoid secrets in memory unless user explicitly asks.
- Prefer high-importance (>=0.8) for durable engineering lessons.
