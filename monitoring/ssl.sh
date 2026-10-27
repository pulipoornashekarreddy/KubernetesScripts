#!/bin/bash
set -e

# file name: setup_nginx_and_certificates.sh
# Run:
#   chmod +x setup_nginx_and_certificates.sh
#   sudo ./setup_nginx_and_certificates.sh

DOMAIN="grafana.cleanerp.com"
PORT="32000"
EMAIL="admin@cleanerp.com"

NGINX_AVAILABLE="/etc/nginx/sites-available"
NGINX_ENABLED="/etc/nginx/sites-enabled"
CONFIG_FILE="$NGINX_AVAILABLE/$DOMAIN"
SYMLINK="$NGINX_ENABLED/$DOMAIN"

echo "=============================="
echo " Installing Nginx + Certbot"
echo "=============================="

sudo apt update
sudo apt install -y nginx certbot python3-certbot-nginx

echo "=============================="
echo " Creating Nginx HTTP config"
echo "=============================="

sudo tee "$CONFIG_FILE" > /dev/null <<EOF
server {
    listen 80;
    listen [::]:80;

    server_name $DOMAIN;

    location / {
        proxy_pass http://127.0.0.1:$PORT;
        proxy_http_version 1.1;

        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
EOF

sudo ln -sf "$CONFIG_FILE" "$SYMLINK"

# Disable Ubuntu's default site so it cannot handle the request.
sudo rm -f /etc/nginx/sites-enabled/default

echo "Testing Nginx configuration..."
sudo nginx -t

echo "Reloading Nginx..."
sudo systemctl enable nginx
sudo systemctl reload nginx

echo "=============================="
echo " Checking Grafana backend"
echo "=============================="

if ! curl -fsSI --max-time 10 "http://127.0.0.1:$PORT" > /dev/null; then
    echo "ERROR: Grafana is not reachable at 127.0.0.1:$PORT"
    echo "Check:"
    echo "  kubectl get svc -n monitoring kube-prom-stack-grafana"
    echo "  curl -I http://127.0.0.1:$PORT"
    exit 1
fi

echo "Grafana backend is reachable."

echo "=============================="
echo " Installing SSL certificate"
echo "=============================="

# Only request a certificate if one does not already exist.
if sudo test -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem"; then
    echo "SSL certificate already exists for $DOMAIN"
    echo "Skipping certificate creation."
else
    sudo certbot certonly --nginx \
        -d "$DOMAIN" \
        --email "$EMAIL" \
        --agree-tos \
        --non-interactive
fi

echo "=============================="
echo " Configuring HTTPS"
echo "=============================="

sudo tee "$CONFIG_FILE" > /dev/null <<EOF
server {
    listen 80;
    listen [::]:80;

    server_name $DOMAIN;

    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    listen [::]:443 ssl;

    server_name $DOMAIN;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    location / {
        proxy_pass http://127.0.0.1:$PORT;
        proxy_http_version 1.1;

        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";

        proxy_read_timeout 300;
        proxy_send_timeout 300;
    }
}
EOF

echo "=============================="
echo " Final Nginx validation"
echo "=============================="

sudo nginx -t
sudo systemctl reload nginx

echo "=============================="
echo " Testing HTTPS"
echo "=============================="

curl -Ik --max-time 10 "https://$DOMAIN"

echo "=============================="
echo " SSL Certificates"
echo "=============================="

sudo certbot certificates

echo "=============================="
echo " Setup completed successfully"
echo "=============================="
echo "Grafana:"
echo "  https://$DOMAIN"
echo ""
echo "Backend:"
echo "  http://127.0.0.1:$PORT"
echo "=============================="