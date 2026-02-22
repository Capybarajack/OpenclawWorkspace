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

## [P1] Active projects (90d)
- [P1][ts:2026-02-05] **ProteinCare**: fashionable diet recommendation app. Users upload meal photos; OpenAI Vision parses image → nutrition components.
- [P1][ts:2026-02-05] Stack: Frontend `F:\nodejs\protaincare` (Nuxt). Backend `F:\nodejs\proteinCare_Backend` (Node.js). Supabase for Auth/DB/RLS/Storage.
- [P1][ts:2026-02-05] Progress: Supabase tables + RLS created; Nuxt Google OAuth login working. Next: upload images to Supabase Storage (`meal-photos`) + persist analysis results into `food_entries/items` and `daily_summaries`.
- [P1][ts:2026-02-14] Frontend repo hygiene: after any `protaincare` frontend changes, **commit + push** to the HTTPS GitHub repo.
- [P1][ts:2026-02-22] New project: **LINE 貼圖產生器** at `F:\openClaw\LINEsticker` (Vue+Capacitor frontend, Node API/worker, Python rembg service).
- [P1][ts:2026-02-22] LINE 貼圖進度：Phase 0 已完成 commit `bc50782`；Phase 1 已完成 commit `8e011a6`（上傳/pack/job API、worker 去背+resize、SSE、compose、README、依賴安裝）。

## [P2] Temporary (30d)
- [P2][ts:2026-02-14] Memory system upgrade: hot memory TTL + cold archive + daily janitor cron.
