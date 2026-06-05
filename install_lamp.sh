#!/bin/bash
# ============================================================
# install_lamp.sh
# 一鍵部署 LAMP + WordPress，並建立資料庫、安全憑證與權限
# 適用環境：Ubuntu (建議 22.04 / 24.04 LTS)
#
# 設計重點：
#   - 與 system_maintenance.sh 共用 ~/.my.cnf (備份腳本可直接使用)
#   - 實踐最小權限：Web 檔案歸 www-data，DB 使用者只授權單一資料庫
#   - 冪等：重複執行不會重建已存在的資料庫 / WordPress
# ============================================================
set -euo pipefail

# ---------- 可調整參數 ----------
DB_NAME="wordpress"
DB_USER="wp_user"
WP_ROOT="/var/www/html/wordpress"
MYCNF="$HOME/.my.cnf"
# --------------------------------

echo ">>> [1/7] 更新系統套件..."
sudo apt update

echo ">>> [2/7] 安裝 LAMP 與 WordPress 必要套件..."
sudo apt install -y apache2 mysql-server php libapache2-mod-php php-mysql \
    php-curl php-gd php-xml php-mbstring php-zip wget curl openssl

echo ">>> [3/7] 啟用服務並設定開機自動啟動..."
sudo systemctl enable --now apache2
sudo systemctl enable --now mysql
sudo a2enmod rewrite

echo ">>> [4/7] 建立資料庫、最小權限使用者並做安全強化..."
# 沿用既有密碼；若無則產生隨機密碼
if [ -f "$MYCNF" ]; then
    echo "[INFO] 偵測到既有 $MYCNF，沿用既有密碼。"
    DB_PASS="$(awk -F= '/password/{gsub(/^[ \t]+|[ \t]+$/,"",$2); print $2}' "$MYCNF")"
else
    DB_PASS="$(openssl rand -base64 16)"
fi

sudo mysql <<SQL
CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
ALTER USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
-- 最小權限原則：僅授權 WordPress 專用資料庫，不給全域權限
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
-- 取代 mysql_secure_installation 的關鍵動作：移除匿名帳號與測試庫
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
FLUSH PRIVILEGES;
SQL

# 寫入安全憑證檔（供備份腳本 system_maintenance.sh 使用），權限 600
cat > "$MYCNF" <<EOF
[client]
user=${DB_USER}
password=${DB_PASS}
database=${DB_NAME}
EOF
chmod 600 "$MYCNF"
echo "[OK] 已寫入 $MYCNF (chmod 600)，備份腳本可直接使用此憑證。"

echo ">>> [5/7] 下載並部署 WordPress..."
if [ ! -f "$WP_ROOT/wp-load.php" ]; then
    TMP="$(mktemp -d)"
    wget -q https://wordpress.org/latest.tar.gz -O "$TMP/wp.tar.gz"
    tar -xzf "$TMP/wp.tar.gz" -C "$TMP"
    sudo mkdir -p "$WP_ROOT"
    sudo cp -r "$TMP/wordpress/." "$WP_ROOT/"
    rm -rf "$TMP"
    echo "[OK] WordPress 已部署至 $WP_ROOT"
else
    echo "[INFO] $WP_ROOT 已存在 WordPress，略過下載。"
fi

echo ">>> [6/7] 產生 wp-config.php..."
WP_CONFIG="$WP_ROOT/wp-config.php"
if [ ! -f "$WP_CONFIG" ]; then
    sudo cp "$WP_ROOT/wp-config-sample.php" "$WP_CONFIG"
    sudo sed -i "s/database_name_here/${DB_NAME}/" "$WP_CONFIG"
    sudo sed -i "s/username_here/${DB_USER}/"     "$WP_CONFIG"
    sudo sed -i "s/password_here/${DB_PASS}/"     "$WP_CONFIG"

    # 寫入官方產生的安全金鑰 (salts)：刪除預設佔位行，插入真實金鑰於 $table_prefix 前
    SALTS="$(curl -s https://api.wordpress.org/secret-key/1.1/salt/ || true)"
    if [ -n "$SALTS" ]; then
        awk -v salts="$SALTS" '
            /put your unique phrase here/ { next }
            /\$table_prefix/ && !done    { print salts; done=1 }
            { print }
        ' "$WP_CONFIG" | sudo tee "${WP_CONFIG}.tmp" >/dev/null
        sudo mv "${WP_CONFIG}.tmp" "$WP_CONFIG"
        echo "[OK] 已寫入官方安全金鑰。"
    else
        echo "[WARN] 無法取得官方 salts，請手動到 https://api.wordpress.org/secret-key/1.1/salt/ 取得並貼入 wp-config.php"
    fi
else
    echo "[INFO] wp-config.php 已存在，略過。"
fi

echo ">>> [7/7] 設定權限與 Apache 站台..."
# 最小權限：檔案歸 Apache 執行身分 www-data，目錄 755 / 檔案 644
sudo chown -R www-data:www-data "$WP_ROOT"
sudo find "$WP_ROOT" -type d -exec chmod 755 {} \;
sudo find "$WP_ROOT" -type f -exec chmod 644 {} \;
# wp-config.php 含密碼，收緊權限
sudo chmod 640 "$WP_CONFIG"

# 將預設站台 DocumentRoot 指向 WordPress
sudo sed -i "s#DocumentRoot /var/www/html#DocumentRoot ${WP_ROOT}#" \
    /etc/apache2/sites-available/000-default.conf

# 允許 .htaccess（WordPress 永久連結需要）
sudo tee /etc/apache2/conf-available/wordpress.conf >/dev/null <<APACHE
<Directory ${WP_ROOT}>
    AllowOverride All
    Require all granted
</Directory>
APACHE
sudo a2enconf wordpress

# 防火牆放行 Apache
sudo ufw allow in "Apache Full" || true

sudo systemctl restart apache2

IP_ADDR="$(hostname -I | awk '{print $1}')"
echo "=========================================="
echo "LAMP + WordPress 安裝完成！"
echo "Apache 狀態: $(systemctl is-active apache2)"
echo "MySQL  狀態: $(systemctl is-active mysql)"
echo "資料庫     : ${DB_NAME} (使用者 ${DB_USER})"
echo "DB 密碼已安全儲存於 ${MYCNF} (chmod 600)，未顯示於畫面。"
echo ""
echo "請用瀏覽器開啟以下網址完成 WordPress 安裝精靈："
echo "    http://${IP_ADDR}/"
echo "=========================================="
