#!/bin/bash
setup_cron() {
    local script_path="$(realpath "$0")"
    local cron_job="0 3 * * * $script_path" # 設定為每天凌晨 3 點執行

    # 檢查是否已經存在於 crontab
    if crontab -l 2>/dev/null | grep -q "$script_path"; then
        echo "[INFO] 自動排程已存在，跳過設定。"
    else
        echo "[INFO] 正在設定自動排程..."
        (crontab -l 2>/dev/null; echo "$cron_job") | crontab -
        echo "[OK] 已成功設定每日凌晨 3 點自動執行維護。"
    fi
}
setup_cron
# --- 環境變數 ---
# 確保這些目錄由當前使用者擁有
LOG_DIR="$HOME/logs"
BACKUP_DIR="$HOME/backups/wordpress"
LOG_FILE="$LOG_DIR/maintenance.log"

# 建立目錄 (若不存在)
mkdir -p "$LOG_DIR" "$BACKUP_DIR"

# --- 函數：記錄日誌 ---
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log_message "開始執行維護任務..."

# 1. 健康檢查：檢查磁碟空間
DISK_USAGE=$(df / | grep / | awk '{ print $5 }' | sed 's/%//')
if [ "$DISK_USAGE" -gt 90 ]; then
    log_message "警告：磁碟空間不足，目前使用率 ${DISK_USAGE}%"
fi

# 2. 執行資料庫備份
# 使用 --defaults-extra-file 從 ~/.my.cnf 讀取帳號密碼
# 請確保 ~/.my.cnf 權限為 600
BACKUP_FILE="$BACKUP_DIR/wp_backup_$(date +%Y%m%d).sql"

if mysqldump --defaults-extra-file="$HOME/.my.cnf" wordpress > "$BACKUP_FILE" 2>> "$LOG_FILE"; then
    log_message "資料庫備份成功: $BACKUP_FILE"
else
    log_message "錯誤：資料庫備份失敗！"
    exit 1
fi

# 3. 自動清除 30 天前的檔案
find "$BACKUP_DIR" -type f -mtime +30 -name "*.sql" -delete
log_message "舊備份已清除"

log_message "維護工作成功完成。"
