# LAMP Stack 部署與自動化維運專案

## 專案概述

本專案以 Shell Script 自動化建置 LAMP 環境並部署 WordPress 網站，
並實作系統自動化維運機制（資料庫備份、磁碟健康檢查、舊檔清理），
落實**最小權限原則**與敏感憑證保護。

## 環境需求

- Ubuntu 22.04 / 24.04 LTS（建議在 VM 上執行）
- 具備 `sudo` 權限的一般使用者

## 部署步驟

只需執行一支腳本即可完成 LAMP + WordPress 部署：

```bash
chmod +x install_lamp.sh
./install_lamp.sh
```

`install_lamp.sh` 會自動完成：

1. 安裝 Apache、MySQL、PHP 及 WordPress 所需模組。
2. 建立 `wordpress` 資料庫與 `wp_user` 帳號（僅授權單一資料庫，符合最小權限）。
3. 安全強化：移除 MySQL 匿名帳號、刪除預設 `test` 資料庫。
4. 下載 WordPress 並產生含**官方安全金鑰 (salts)** 的 `wp-config.php`。
5. 設定檔案權限（Web 檔歸 `www-data`、`wp-config.php` 設為 640）。
6. 將資料庫憑證寫入 `~/.my.cnf`（權限 600），供備份腳本共用。
7. 設定 Apache 站台並放行防火牆。

`wordpress/` 核心程式不納入版控，由部署腳本在安裝時自動下載，避免 repo 混入大量第三方上游檔案。

完成後以瀏覽器開啟 `http://<VM_IP>/` 進行 WordPress 安裝精靈即可。

若需安裝每日凌晨 03:00 的自動維護排程，另執行：

```bash
chmod +x setup_cron.sh
./setup_cron.sh
```

## 自動化維運機制

`system_maintenance.sh` 透過讀取 `install_lamp.sh` 產生的 `~/.my.cnf` 進行維運，
無需重複輸入帳密：

- **磁碟健康檢查**：根目錄使用率超過 90% 時寫入警告 log。
- **資料庫備份**：`mysqldump` 匯出至 `~/backups/wordpress/wp_backup_YYYYMMDD.sql`。
- **舊檔清理**：自動刪除 30 天前的備份檔。
- **日誌**：所有動作記錄於 `~/logs/maintenance.log`。

手動執行一次以驗證：

```bash
chmod +x system_maintenance.sh
./system_maintenance.sh
```

### 備份還原驗證

備份需確認可還原才有意義，建議定期測試：

```bash
mysql --defaults-extra-file=~/.my.cnf -e "CREATE DATABASE wp_restore;"
mysql --defaults-extra-file=~/.my.cnf wp_restore < ~/backups/wordpress/wp_backup_YYYYMMDD.sql
mysql --defaults-extra-file=~/.my.cnf -e "USE wp_restore; SHOW TABLES;"
```

## Debug 紀錄（驗證與除錯）

- **問題**：早期版本將 log 與備份寫入 `/var/log`、`/var/backups`，執行時出現 `Permission denied`。
- **解決**：分析後確認為系統目錄權限不足。改為寫入使用者家目錄下的 `~/logs`、`~/backups`，
  避免維運腳本需要 root 權限，同時符合最小權限原則。
