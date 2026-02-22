# LINE 貼圖產生器（Vue + Node + rembg）設計與實作藍圖

日期：2026-02-22  
狀態：已確認（Section 1~4 approved）

## 1) 目標與範圍（MVP）

### 目標
打造可在手機（Capacitor）使用的 LINE 靜態貼圖產生器，完整支援：
1. 上傳照片
2. AI 風格化生成（nano-banana-pro）
3. 自動去背（rembg-replicate）
4. 輸出為 LINE 靜態貼圖尺寸（370×320 PNG）
5. 一鍵下載 ZIP

### 範圍限制（本版）
- 只做「一般靜態貼圖」
- 本機測試免登入（保留資料庫程式與 future auth hooks，但不啟用）
- 支援張數：8 / 16 / 24 / 32 / 40

---

## 2) 系統架構（方案 2）

- **Frontend**：Vue 3 + Vite + Capacitor
- **Backend API**：Node.js（建議 Fastify）
- **Job Queue**：BullMQ + Redis
- **Image Worker**：Node worker（調用 nano-banana-pro + rembg service）
- **Background Removal Service**：Python rembg-replicate（HTTP 微服務）
- **Storage**：本機 MinIO（dev）/ S3（prod）
- **DB**：PostgreSQL（schema 保留，MVP 可先關閉持久化）

### 任務流程
Upload → Create Pack → Queue Job → 
for each item: generate → remove_bg → resize/crop → save → 
all done: build zip → provide download URL

---

## 3) 模組切分

## A. 前端（apps/mobile-web）
- `pages/CreatePackWizard.vue`
- `components/upload/UploadCard.vue`
- `components/config/StyleSelector.vue`
- `components/config/ActionSelector.vue`
- `components/config/CustomLinesInput.vue`
- `components/job/ProgressBoard.vue`
- `components/result/StickerGallery.vue`
- `stores/pack.store.ts`（Pinia）
- `services/api.ts`
- `services/sse.ts`

## B. 後端 API（services/api）
- `modules/sessions`（guest token）
- `modules/uploads`
- `modules/packs`
- `modules/jobs`
- `modules/exports`
- `modules/styles`
- `infra/storage`（S3 adapter）
- `infra/queue`（BullMQ）

## C. Worker（services/worker）
- `workers/generate-pack.worker.ts`
- `workers/export-zip.worker.ts`
- `pipelines/sticker.pipeline.ts`
- `adapters/nanoBanana.adapter.ts`
- `adapters/rembg.adapter.ts`
- `adapters/imageOps.adapter.ts`（sharp）

## D. Python rembg 微服務（services/rembg-service）
- `app.py`（FastAPI）
- `routes/remove_bg.py`
- `schemas.py`
- `Dockerfile`
- `requirements.txt`（針對 py3.10）

---

## 4) API 契約（MVP）

- `POST /api/v1/sessions/guest`
- `POST /api/v1/uploads/reference` (multipart)
- `POST /api/v1/packs`
- `POST /api/v1/packs/:packId/generate`
- `GET  /api/v1/packs/:packId`
- `GET  /api/v1/packs/:packId/stickers`
- `GET  /api/v1/jobs/:jobId/events` (SSE)
- `POST /api/v1/packs/:packId/items/:itemId/retry`
- `PATCH /api/v1/packs/:packId/items/:itemId`
- `POST /api/v1/packs/:packId/export`
- `GET  /api/v1/exports/:exportId`
- `GET  /api/v1/exports/:exportId/download`

---

## 5) 實作藍圖（可直接開工）

## Phase 0 — 專案骨架（0.5~1 天）
1. 建 monorepo 結構（apps + services）
2. 建立共用 `.env.example`
3. 建 `docker-compose.dev.yml`（redis + minio + postgres + rembg-service）
4. 建健康檢查 `/health`、`/ready`

**交付物**
- 可啟動全服務（API/worker/rembg/redis/minio）

## Phase 1 — 前端流程頁（1~2 天）
1. 完成 Step Wizard UI（上傳、設定、動作、確認）
2. 接上傳 API
3. 送出 `create pack` + `generate` API
4. 進度頁支援 SSE + polling fallback

**驗收**
- 可以完整送出任務並看到狀態流轉

## Phase 2 — 後端 Job Pipeline（2~3 天）
1. packs/jobs 基礎 API
2. BullMQ queue + worker 執行管線
3. nano-banana adapter（統一 timeout/retry）
4. rembg adapter（HTTP call + timeout/retry）
5. sharp resize/crop 到 370×320

**驗收**
- 8 張可跑通：產出可下載單張

## Phase 3 — 匯出 ZIP + 預覽（1 天）
1. export-zip worker
2. 產生 `manifest.json`
3. 提供下載 URL（可過期）
4. 前端預覽頁 + 下載按鈕

**驗收**
- 一鍵 ZIP 下載可用，內容正確

## Phase 4 — 穩定性強化（1~2 天）
1. 失敗單張重試
2. job cancel
3. 錯誤碼標準化
4. 加入 request-id + 結構化 logs

**驗收**
- 單張失敗不拖垮整包；可重試成功

## Phase 5 — 手機包裝與發佈準備（1 天）
1. Capacitor iOS/Android project sync
2. 手機檔案下載路徑驗證
3. loading/中斷恢復優化

**驗收**
- Android/iOS 測試機可跑完整流程

---

## 6) 環境變數（初版）

- `NODE_ENV`
- `API_PORT`
- `REDIS_URL`
- `POSTGRES_URL`（先保留）
- `S3_ENDPOINT`
- `S3_ACCESS_KEY`
- `S3_SECRET_KEY`
- `S3_BUCKET`
- `NANO_BANANA_ENDPOINT`
- `NANO_BANANA_API_KEY`
- `REMBG_SERVICE_URL`
- `JOB_MAX_RETRY=2`
- `JOB_TIMEOUT_MS`
- `ZIP_TTL_HOURS=24`

---

## 7) Done 定義（MVP）

1. 可完成 Upload → Generate → Remove BG → Resize → ZIP Download
2. 8 張場景穩定可用
3. 單張失敗可重試
4. 所有輸出符合 370×320 PNG
5. 手機端可完成整體流程

---

## 8) 風險與對策

- **Python 版本相容性**：rembg 需 py<3.11，rembg service 固定用 Python 3.10 容器
- **長任務不穩**：使用 queue + retry + idempotency key
- **生成服務波動**：單張級別容錯，不阻斷整包
- **儲存成本**：ZIP 與中間產物 TTL 清理策略

---

## 9) 下一步（Implementation Planning）

1. 先落地 monorepo + docker compose
2. 先打通 8 張流程（最小可用）
3. 再補 retry/cancel/export 強化
4. 最後做手機端體驗優化
