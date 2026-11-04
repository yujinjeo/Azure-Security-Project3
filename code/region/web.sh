#!/bin/bash
set -euo pipefail
sudo setsebool -P httpd_can_network_connect 1

REGION_CODE="${region_code}"
REGION_ROLE="${region_role}"
WAS_HOST="${was_lb_ip}"

sudo dnf install -y nginx rsyslog curl
sudo systemctl enable --now rsyslog

sudo cat > /etc/nginx/conf.d/wordpress.conf << EOF
server {
  listen 80;
  server_name _;

  client_max_body_size 64M;

  location / {
    proxy_pass http://$WAS_HOST:80;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_connect_timeout 60s;
    proxy_read_timeout 60s;
  }
}
EOF

sudo sed -i 's/default_server//g' /etc/nginx/nginx.conf || true
systemctl enable --now nginx
systemctl restart nginx

if systemctl is-active --quiet firewalld; then
  firewall-cmd --permanent --add-service=http
  firewall-cmd --reload
fi
