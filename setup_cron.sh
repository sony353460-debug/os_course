#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAINTENANCE_SCRIPT="$SCRIPT_DIR/system_maintenance.sh"
CRON_JOB="0 3 * * * $MAINTENANCE_SCRIPT"

if [ ! -f "$MAINTENANCE_SCRIPT" ]; then
    echo "[ERROR] 找不到 $MAINTENANCE_SCRIPT"
    exit 1
fi

if crontab -l 2>/dev/null | grep -F -q "$MAINTENANCE_SCRIPT"; then
    echo "[INFO] 自動排程已存在，跳過設定。"
else
    echo "[INFO] 正在設定自動排程..."
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo "[OK] 已成功設定每日凌晨 3 點自動執行維護。"
fi
