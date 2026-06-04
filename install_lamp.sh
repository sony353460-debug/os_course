#!/bin/bash

# 設定腳本在發生錯誤時停止執行
set -e

echo ">>> 開始安裝 LAMP 環境..."

# 1. 更新系統
sudo apt update && sudo apt upgrade -y

# 2. 安裝 Apache, MySQL, PHP 及相關模組
sudo apt install -y apache2 mysql-server php libapache2-mod-php php-mysql

# 3. 確保服務啟動並設定開機自動啟動
sudo systemctl enable apache2
sudo systemctl start apache2

sudo systemctl enable mysql
sudo systemctl start mysql

# 4. 安全性設定：調整防火牆 (允許 Apache)
sudo ufw allow in "Apache Full"

# 5. 權限調整 (確保 Web 目錄屬於當前使用者)
sudo chown -R $USER:$USER /var/www/html

echo "=========================================="
echo "LAMP 安裝完成！"
echo "Apache 狀態: $(systemctl is-active apache2)"
echo "MySQL 狀態: $(systemctl is-active mysql)"
echo "請記得執行 'mysql_secure_installation' 來強化資料庫安全"
echo "=========================================="
