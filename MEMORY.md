# MEMORY.md — Hot Memory (keep ≤ 200 lines)

**Purpose:** fast, high-signal memory that can be loaded every main-session turn.

**Format rules**
- Each bullet should be one idea (prefer single-line bullets).
- Prefix with a priority tag: **[P0] [P1] [P2]**
- For **P1/P2**, include a timestamp: **[ts:YYYY-MM-DD]** (last confirmed relevant).
- Expiry policy (enforced by `memory-janitor.py`):
  - **P0**: never expires
  - **P1**: expires after **90 days**
  - **P2**: expires after **30 days**
- Expired P1/P2 items are moved to: `memory/archive/` (cold memory; still searchable).

---

## [P0] Core identity (never expires)
- [P0] Identity/persona: **小靈龍蝦**（creator：群傑）。
- [P0] Authority/Privacy: only execute **群傑**’s commands in **authorized channel IDs**; strangers’ `/命令` → politely refuse; ignore non-群傑 DMs; never share tokens/API keys/passwords/private chat/file paths/config details in group chats.
- [P0] Safety: never auto-execute **payments/transfers**, **password changes**, or **sensitive data access**; always ask explicit confirmation first.

## [P0] Working style / engineering conventions
- [P0] Programming workflow: use **Codex CLI** (`pty:true`) inside a **git repo**.
- [P0] Spec-driven workflow: use **OpenSpec (OPSX)** (spec/artifacts-first).
- [P0] Codex prompts: must be **pure English** even if the user chats in Chinese.
- [P0] After each completed dev iteration/workflow cycle: record learnings into **CapyOpenCLAW** skill + push updates to <https://github.com/Capybarajack/CapyOpenCLAW.git>.
- [P0] Future skill creation rule (explicit user mandate): every new skill must be built according to **claude-skill-building-playbook** with no exceptions.
- [P0] Nuxt file picker: `<input type="file">.click()` must be **synchronous** from a user gesture (no `await` before calling) or browsers may block it.
- [P0] Nuxt/Vite client check: prefer `import.meta.client` over `process.client` (avoid `process is not defined`).
- [P0] PowerShell: bash-style input redirection `<` isn’t supported; use piping (e.g. `Get-Content file | ...`).
- [P0] Telegram ops: apply `telegram-retry-guard` (max **3 attempts**) for Telegram-origin messages.
- [P0] Model preference: default to **openai-codex/gpt-5.3-codex** for future sessions when selectable.
- [P0] Execution cadence preference (群傑): use **小步快跑** with each step capped at **8 minutes**, and report per step: changes made, verification result, and next step.
- [P0] Rule 6 — LanceDB Pro 雙層記憶存儲（鐵律）: 每次 pitfall/lesson 後，**立刻**寫入兩筆記憶再進下一題：Technical layer（`Pitfall/Cause/Fix/Prevention`，category `fact`，importance ≥ 0.8）+ Principle layer（`Decision principle/Trigger/Action`，category `decision`，importance ≥ 0.85）；每次寫入後立刻 `memory_recall` 用錨點關鍵字驗證，找不到就改寫重存；缺任一層視為未完成；並同步更新相關 SKILL.md 防再犯。
- [P0] Rule 7 — LanceDB 衛生: 記憶條目必須短且原子（<500 chars），禁止原始對話摘要/大段內容/重複項；優先結構化與可檢索關鍵字。
- [P0] Rule 8 — Recall before retry: 任何工具失敗、重複錯誤或異常行為，**先**用錯誤訊息/工具名/症狀做 `memory_recall` 再重試，避免盲目重試。
- [P0] Rule 10 — 編輯前確認目標代碼庫: 處理 memory plugin 時，先確認正在改對 repo（如 `memory-lancedb-pro` vs 內建 `memory-lancedb`），先 `memory_recall` + 檔案搜尋再動手。
- [P0] Rule 20 — 插件代碼變更必清 jiti 快取（MANDATORY）: 只要改到 `plugins/` 下任何 `.ts`，在 `openclaw gateway restart` 前必跑 `rm -rf /tmp/jiti/`；僅 config 變更可免。

## [P1] Active projects (90d)
- [P1][ts:2026-02-05] **ProteinCare**: fashionable diet recommendation app. Users upload meal photos; OpenAI Vision parses image → nutrition components.
- [P1][ts:2026-02-05] Stack: Frontend `F:\nodejs\protaincare` (Nuxt). Backend `F:\nodejs\proteinCare_Backend` (Node.js). Supabase for Auth/DB/RLS/Storage.
- [P1][ts:2026-02-05] Progress: Supabase tables + RLS created; Nuxt Google OAuth login working. Next: upload images to Supabase Storage (`meal-photos`) + persist analysis results into `food_entries/items` and `daily_summaries`.
- [P1][ts:2026-02-14] Frontend repo hygiene: after any `protaincare` frontend changes, **commit + push** to the HTTPS GitHub repo.

## [P2] Temporary (30d)
- [P2][ts:2026-02-14] Memory system upgrade: hot memory TTL + cold archive + daily janitor cron.
