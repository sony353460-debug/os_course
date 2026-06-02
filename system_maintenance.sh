#!/bin/bash
# 自動化維運腳本 (已整合 MySQL 自動認證)
LOG_FILE="/var/log/my_project.log"
BACKUP_DIR="/var/backups/wordpress"

# 確保資料夾存在
sudo mkdir -p $BACKUP_DIR

echo "[$(date)] 開始維護任務..." >> $LOG_FILE

# 執行備份 (不需要 -p，系統會自動讀取 .my.cnf)
mysqldump wordpress > $BACKUP_DIR/wp_backup_$(date +%Y%m%d).sql

echo "[$(date)] 資料庫備份完成" >> $LOG_FILE
