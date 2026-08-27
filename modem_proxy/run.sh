#!/bin/sh
TARGET_IP=$(jq -r '.target_ip' /data/options.json)
TARGET_HOST=$(jq -r '.target_host' /data/options.json)
LISTEN_PORT=$(jq -r '.listen_port' /data/options.json)

cat > /etc/nginx/http.d/default.conf <<EOF
server {
    listen ${LISTEN_PORT};
    location / {
        proxy_pass http://${TARGET_IP};
        proxy_set_header Host ${TARGET_HOST};
    }
}
EOF

nginx -g "daemon off;"
