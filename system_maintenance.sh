#!/bin/bash
LOG_FILE="/var/log/my_project.log"
BACKUP_DIR="/var/backups/wordpress"

sudo mkdir -p "$BACKUP_DIR"

# 函數：記錄日誌
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> $LOG_FILE
}

log_message "開始執行維護任務..."

# 1. 防呆機制：檢查磁碟空間是否充足 (若低於 10% 則發出警告)
DISK_USAGE=$(df / | grep / | awk '{ print $5 }' | sed 's/%//')
if [ "$DISK_USAGE" -gt 90 ]; then
    log_message "警告：磁碟空間不足，目前使用率 $DISK_USAGE%"
fi

# 2. 執行資料庫備份並檢查成功與否
if mysqldump wordpress > "$BACKUP_DIR/wp_backup_$(date +%Y%m%d).sql"; then
    log_message "資料庫備份成功"
else
    log_message "錯誤：資料庫備份失敗！"
    exit 1 # 終止腳本並回報錯誤
fi

# 3. 自動清除 30 天前的檔案
find $BACKUP_DIR -type f -mtime +30 -name "*.sql" -delete
log_message "舊備份已清除"

log_message "維護工作成功完成。"
