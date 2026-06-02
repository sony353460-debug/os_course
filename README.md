# LAMP Stack 部署與自動化維運專案

## 專案概述
本專案旨在建置一個高可用性的 WordPress 網站，並實作系統自動化維運機制，以滿足最小權限原則與自動化作業需求。

## 部署步驟
1. **安裝 LAMP 環境**：執行 `install_lamp.sh`。
2. **初始化權限**：執行 MySQL 設定以符合資安規範。
3. **設定自動化備份**：
    - 建立 `~/.my.cnf` 以安全儲存資料庫憑證。
    - 設定 `crontab` 執行自動備份腳本。

## 自動化維運機制
- **備份腳本**：`system_maintenance.sh` 可自動備份 MySQL 資料庫。
- **排程設定**：每日凌晨 03:00 自動執行。

## Debug 紀錄 (驗證與除錯)
- **問題**：執行 `system_maintenance.sh` 時出現 `Permission denied`。
- **解決**：分析確認為 `/var/log` 與 `/var/backups` 權限不足，透過 `sudo` 與權限管理排除錯誤。

## 注意事項
- 敏感檔案 (如 `.my.cnf`, `wp-config.php`, `*.sql`) 已加入 `.gitignore` 以確保資安。
