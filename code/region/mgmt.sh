#!/bin/bash
set -euxo pipefail

dnf install -y mysql curl jq

cat >/home/3team/DB_TEST.txt <<'EOF'
DB 검증 예시

mysql -h <DB_FQDN> -u <DB_ADMIN> -p

접속 후:
USE 3teamdb;
SELECT @@hostname, @@read_only, @@super_read_only;
SELECT id, userid, username, email, signup_region, created_at FROM users ORDER BY id;
EOF

chown 3team:3team /home/3team/DB_TEST.txt || true
