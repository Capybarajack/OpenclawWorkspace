# Codex 讀取 OpenClaw LanceDB 記憶：方案 1（DB 快照同步）

日期：2026-02-25  
狀態：Approved（群傑確認採用方案 1）

## 1. 目標

在 **Codex 與 OpenClaw 不同機器且無法直連** 前提下，讓 Codex 可讀取 OpenClaw 建立的 LanceDB 記憶資料。

## 2. 非目標

- 不追求即時同步
- 不做雙向回寫（先不讓 Codex 寫回 OpenClaw）
- 不把 LanceDB 原始資料夾直接納入 Git 版本控管

## 3. 架構

- **OpenClaw 主機**：唯一記憶主庫（source of truth）
- **Codex 機器**：唯讀副本（讀取快照匯入後的本地庫）
- **CapyOpenCLAW repo**：僅存流程、腳本、清單；不存主庫原始 DB

資料流：
1) OpenClaw 匯出快照（snapshot）
2) 手動/半自動搬運快照到 Codex 機器
3) Codex 匯入快照，重建/覆蓋本地唯讀副本
4) Codex 任務前做 recall smoke test

## 4. 快照格式

快照目錄內容：
- `manifest.json`
- `db/`（LanceDB 複製內容）

`manifest.json` 最小欄位：
- `snapshotVersion`: 版本字串（UTC timestamp）
- `createdAt`: ISO 時間
- `sourceDbPath`: 來源路徑
- `fileCount`
- `totalBytes`
- `aggregateSha256`

## 5. 一致性與安全策略

- 單向同步：OpenClaw -> Codex
- 只接受新版本快照（避免舊版覆蓋新版）
- 匯入前檢查 `aggregateSha256`
- 匯入前先備份 Codex 既有副本（`*.bak-<timestamp>`）
- 發生驗證失敗則中止匯入並保留舊副本

## 6. 失敗處理

1) 快照缺檔/manifest 缺失 -> 中止
2) checksum 不一致 -> 中止
3) 權限不足/目錄不可寫 -> 中止
4) 匯入中斷 -> 回滾到 backup

## 7. 驗證方案（Anchor Test）

1) OpenClaw 端新增 anchor 記憶（`ANCHOR_<ts>`）
2) export -> transfer -> import
3) Codex 端 recall 必須命中 anchor
4) 檢查筆數與最新 timestamp

成功條件：
- Codex 可讀到 anchor
- 匯入筆數與快照宣告一致
- 無 checksum 錯誤

## 8. Repo 交付項（本次）

位置：`skills/codex-openclaw-shared-lancedb/`

- `scripts/export-memory-snapshot.ps1`
- `scripts/import-memory-snapshot.ps1`
- `references/runbook.md`
- `assets/memory-snapshot/.gitkeep`

## 9. 後續升級路線

- Phase 2：加入增量同步（event log）
- Phase 3：可選擇回寫策略（需衝突解決規則）
