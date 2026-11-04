#!/bin/bash
set -euo pipefail

REGION_CODE="${region_code}"
REGION_ROLE="${region_role}"

DB_HOST="${db_host}"
DB_USER="${db_user}"
DB_PASS="${db_password}"
DB_NAME="${db_name}"

sudo dnf install -y httpd php php-mysqlnd php-gd php-xml php-mbstring php-json rsyslog curl tar
sudo systemctl enable --now rsyslog

sudo curl -s -O https://wordpress.org/latest.tar.gz
sudo tar -xzf latest.tar.gz -C /var/www/html/ --strip-components=1
sudo rm -f latest.tar.gz

sudo cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
sudo sed -i "s/localhost/$DB_HOST/g" /var/www/html/wp-config.php
sudo sed -i "s/database_name_here/$DB_NAME/g" /var/www/html/wp-config.php
sudo sed -i "s/username_here/$DB_USER/g" /var/www/html/wp-config.php
sudo sed -i "s/password_here/$DB_PASS/g" /var/www/html/wp-config.php

sudo sed -i "/That's all, stop editing/i\\
if (isset(\\\$_SERVER['HTTP_X_FORWARDED_PROTO']) && \\\$_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {\\
    \\\$_SERVER['HTTPS'] = 'on';\\
}" /var/www/html/wp-config.php

cat << EOF | sudo tee /var/www/html/health.php > /dev/null
<?php
echo "OK $REGION_CODE $REGION_ROLE";
?>
EOF

sudo chown -R apache:apache /var/www/html
sudo find /var/www/html/ -type d -exec chmod 755 {} \;
sudo find /var/www/html/ -type f -exec chmod 644 {} \;

sudo setsebool -P httpd_can_network_connect 1 || true
sudo setsebool -P httpd_can_network_connect_db 1 || true

sudo systemctl enable --now httpd
sudo systemctl restart httpd

if sudo systemctl is-active --quiet firewalld; then
  sudo firewall-cmd --permanent --add-service=http
  sudo firewall-cmd --reload
fi
