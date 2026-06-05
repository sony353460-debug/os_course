# LAMP Stack 部署與自動化維運專案 — 期末報告

> 專案類型：**技術-實作型 (TP)**　|　組別：[請填寫]　|　日期：[請填寫]
> GitHub：https://github.com/sony353460-debug/os_course
>
> ⚠️ 標示 `[請填寫]` / `[附截圖]` 的地方為待補欄位，請各組成員依實際情況補齊。

---

## 1. 專案動機與目標

### 1.1 動機
[請填寫，2–3 句即可。可參考方向：]
許多服務（網站、論壇、內部系統）在 Linux 上以 LAMP 架構運行，而真正困難的不是「裝起來」，
而是「裝好之後如何長期、安全、且自動化地維運」。本專案希望透過實作一套可自動備份、
自動清理、可被排程的維運機制，體會系統管理的重複性工作如何用 Shell Script 解決。

### 1.2 目標
- 成功以腳本自動化架設 LAMP 環境並部署 WordPress 服務。
- 以 Shell Script 處理重複性系統任務（資料庫備份、磁碟健康檢查、舊檔清理）。
- 實踐資安基本原則：最小權限、敏感憑證不入版控、安全金鑰管理。

---

## 2. 團隊組成與角色分配

> 角色代表該領域的「最終責任人」，但所有人皆共同參與討論。

| 角色 | 負責人 | 對應工作 | 本專案實際產出 |
|------|--------|----------|----------------|
| A 系統架構師（流程設計） | [姓名] | 整體流程、服務選型、架構圖 | 第 3 節架構設計 |
| B 腳本開發員（編碼） | [姓名] | 撰寫 `install_lamp.sh`、`system_maintenance.sh` | 第 4 節執行過程 |
| C 測試與 Debug（驗證） | [姓名] | 功能測試、除錯、備份還原驗證 | 第 5 節驗證與測試 |
| D 部署手冊撰寫（紀錄） | [姓名] | README、本報告、交付物整理 | README + 本報告 |

---

## 3. 系統架構（角色 A）

### 3.1 技術選型
| 元件 | 選用 | 理由 |
|------|------|------|
| OS | Ubuntu [版本] (VM) | LTS 長期支援、套件齊全 |
| Web | Apache2 | 設定直觀、`.htaccess` 支援 WordPress 永久連結 |
| DB | MySQL | WordPress 原生支援 |
| 語言 | PHP | WordPress 執行環境 |
| 自動化 | Bash + cron | 系統內建、無額外依賴 |

### 3.2 架構與資料流
[建議補一張架構圖，可用小畫家 / draw.io / PowerPoint 畫，描述如下流程：]

```
使用者瀏覽器
      │ HTTP (80)
      ▼
  Apache2  ──►  PHP  ──►  MySQL (wordpress DB)
                                  │
                          每日 03:00 cron
                                  ▼
                   system_maintenance.sh
              ├─ 磁碟健康檢查 (>90% 警告)
              ├─ mysqldump → ~/backups/wordpress/
              └─ 清除 30 天前舊備份
```

---

## 4. 執行過程（角色 B）

### 4.1 環境建置（W7–W11）
1. 於 VM 安裝 Ubuntu，更新套件。
2. 執行 `install_lamp.sh` 一鍵完成：安裝 LAMP → 建立 `wordpress` 資料庫與 `wp_user`
   最小權限帳號 → 下載部署 WordPress → 產生含官方安全金鑰的 `wp-config.php`
   → 設定 www-data 權限與 Apache 站台 → 放行防火牆。
3. 以瀏覽器開啟 `http://<VM_IP>/` 完成 WordPress 安裝精靈。

### 4.2 自動化維運（`system_maintenance.sh`）
- **冪等排程**：腳本自動檢查 crontab，若尚未設定才寫入「每日 03:00」排程，避免重複。
- **安全憑證**：備份使用 `~/.my.cnf`（權限 600）讀取帳密，密碼不寫死於腳本。
- **健康檢查**：偵測根目錄磁碟使用率，超過 90% 寫入警告 log。
- **資料庫備份**：`mysqldump` 匯出至 `~/backups/wordpress/wp_backup_YYYYMMDD.sql`。
- **自動清理**：`find ... -mtime +30 -delete` 移除 30 天前舊備份。
- **日誌**：所有動作記錄至 `~/logs/maintenance.log`。

### 4.3 資安措施
- `.gitignore` 排除 `.my.cnf`、`wp-config.php`、`*.sql`，避免敏感資料上傳。
- `install_lamp.sh` 內含安全強化：移除 MySQL 匿名帳號、刪除 test 資料庫。
- Web 檔案歸 `www-data`、`wp-config.php` 設為 640，落實最小權限。

---

## 5. 驗證與測試（角色 C）

### 5.1 功能驗證
| 驗證項目 | 方法 | 預期結果 | 實際結果 |
|----------|------|----------|----------|
| Apache 運行 | `systemctl is-active apache2` | active | [請填寫] [附截圖] |
| 網站可存取 | 瀏覽器開 `http://<IP>/` | 顯示 WordPress | [附截圖] |
| 資料庫連線 | 完成 WP 安裝精靈 | 成功建站 | [附截圖] |
| 自動排程 | `crontab -l` | 出現 03:00 排程 | [請填寫] |
| 備份產生 | 手動執行腳本後查看 `~/backups` | 出現 .sql 檔 | [附截圖] |

### 5.2 備份還原測試（重要，請務必補做）
備份若未驗證能還原，等同沒有備份。建議步驟並記錄結果：
```bash
# 1. 建立測試還原用空庫
mysql --defaults-extra-file=~/.my.cnf -e "CREATE DATABASE wp_restore;"
# 2. 還原最新備份
mysql --defaults-extra-file=~/.my.cnf wp_restore < ~/backups/wordpress/wp_backup_YYYYMMDD.sql
# 3. 確認資料表存在
mysql --defaults-extra-file=~/.my.cnf -e "USE wp_restore; SHOW TABLES;"
```
還原結果：[請填寫] [附截圖]

### 5.3 Debug 紀錄
| 編號 | 問題 | 原因分析 | 解決方式 |
|------|------|----------|----------|
| 1 | 執行維護腳本出現 `Permission denied` | `/var/log`、`/var/backups` 權限不足 | 改用使用者家目錄下的 `~/logs`、`~/backups`，避免需要 root |
| 2 | [請填寫團隊實際遇到的問題] | | |
| 3 | [請填寫] | | |

---

## 6. 結果與成果展示

- 成功以單一腳本完成 LAMP + WordPress 自動部署。
- 維運腳本可每日自動備份並清理，全程有 log 可追蹤。
- [附：網站首頁截圖、備份檔列表截圖、maintenance.log 片段]
- 影片：[請填寫 YouTube / 雲端連結]

---

## 7. 心得

[各成員各寫 3–5 句，建議扣回「重複性任務自動化」「最小權限」等學到的概念。]
- [姓名 A]：
- [姓名 B]：
- [姓名 C]：
- [姓名 D]：

---

## 8. 成員貢獻比例表

> 總和須等於 100%。個人最終分數 = 小組總分 ×（個人貢獻% / 平均貢獻%，4 人組平均為 25%）。

| 成員 | 主要貢獻摘要 | 貢獻比例 |
|------|--------------|----------|
| [姓名 A] | [請填寫] | [  ]% |
| [姓名 B] | [請填寫] | [  ]% |
| [姓名 C] | [請填寫] | [  ]% |
| [姓名 D] | [請填寫] | [  ]% |
| **合計** | | **100%** |

---

## 附錄：交付物清單（對照手冊第 7 點）

- [x] 程式碼/腳本：`install_lamp.sh`、`system_maintenance.sh`（已於 GitHub）
- [ ] 本專案報告（轉成 **PDF** 後繳交）
- [ ] 成果展示影片
- [ ] 驗證截圖（網站、備份、log、還原測試）
