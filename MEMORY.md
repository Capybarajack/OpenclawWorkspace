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
- [P1][ts:2026-02-22] New project: **LINE 貼圖產生器** at `F:\openClaw\LINEsticker` (Vue+Capacitor frontend, Node API/worker, Python rembg service).
- [P1][ts:2026-02-22] LINE 貼圖進度：Phase 0 已完成 commit `bc50782`；Phase 1 已完成 commit `8e011a6`（上傳/pack/job API、worker 去背+resize、SSE、compose、README、依賴安裝）；Phase 2 已完成 commit `3942003`（單張重試 API、ZIP 匯出流程、export 狀態/下載 API、worker export-zip）。
- [P1][ts:2026-02-23] LINE 貼圖進度：Phase 3（前端 wizard 串接）已完成 commit `79aad1f`（Step UI、Vue composable、API client、SSE+polling fallback、retry/export/download 串接、README 前端說明）。
- [P1][ts:2026-02-23] LINE 貼圖進度：Phase 4（穩定化）已完成 commit `151d2aa`（retry 次數上限+backoff、export TTL/410、過期 ZIP 清理 timer、README/.env 更新）；Docker 引擎未啟動，完整 e2e smoke 待補。
- [P1][ts:2026-02-23] LINE 貼圖開發體驗：已補無 Docker 本機啟動腳本 commit `96a35f6`（`scripts/dev-local.ps1` + `scripts/dev-local-stop.ps1` + README）；後續修正 commit `8689b69`（支援 `py` fallback，`-NoRemBg` 跳過 Python 檢查）。
- [P1][ts:2026-02-24] LINE 貼圖進度：queue 雙模式（`QUEUE_MODE=redis|local`）已完成 commit `f60cd30`（API queue adapter、worker local file queue polling、README/.env/dev-local 更新）；`QUEUE_MODE=local` smoke 已驗證可消化 job。
- [P1][ts:2026-02-24] LINE 貼圖目前卡點：正在補 rembg 本機環境；已調整 `services/rembg-service/requirements.txt` 到 `rembg==2.0.72` + `pillow==12.1.0`，但依賴尚未完成安裝（目前 `fastapi` import 失敗）。
- [P1][ts:2026-02-25] 已定位 rembg 卡點根因：本機僅有 Python 3.14，當前 FastAPI/Pydantic 依賴在 3.14 會噴 `_eval_type ... prefer_fwd_module` 錯誤；已加入 `scripts/dev-local.ps1` 版本守門（要求 Python 3.10-3.13）並更新 README，commit `81b89b5`。
- [P1][ts:2026-02-25] 已安裝 Python 3.13.2，並完成 `py -3.13 -m pip install -r services/rembg-service/requirements.txt` + `rembg[cpu]==2.0.72`；`py -3.13` import 驗證通過。當前未解：`dev-local.ps1` 仍優先抓到 3.14（`python` 不在 PATH、`py` 預設指向 3.14），需改為顯式使用 `py -3.13` 或調整啟動器預設版本。

## [P2] Temporary (30d)
- [P2][ts:2026-02-14] Memory system upgrade: hot memory TTL + cold archive + daily janitor cron.
