#!/bin/bash
# file name setup_nginx_and_certificates.sh

# file name setup_nginx_and_certificates.sh
# rm -rf setup_nginx_and_certificates.sh
# sudo nano setup_nginx_and_certificates.sh
# sudo bash setup_nginx_and_certificates.sh

sudo apt update && sudo apt upgrade -y

sudo apt install -y nginx

sudo apt install -y certbot python3-certbot-nginx

# Define services and ports
declare -A services=(
    ["pipelines.cleanerp.com"]="8080"
    ["docker.cleanerp.com"]="5000"
    ["grafana.cleanerp.com"]="32000"
)

declare -A EXTRA_CONFIG=(
  ["docker.cleanerp.com"]="client_max_body_size 2G; proxy_read_timeout 900; proxy_connect_timeout 900; proxy_send_timeout 900;"
)

# Default values if not specified above
DEFAULT_EXTRA_CONFIG=""

# Path to Nginx configurations
nginx_available="/etc/nginx/sites-available"
nginx_enabled="/etc/nginx/sites-enabled"

# Email for Certbot
email="admin@cleanerp.com"

# Function to create Nginx configuration
create_nginx_config() {
    local domain=$1
    local port=$2

    config_file="$nginx_available/$domain"
    local EXTRA_CONFIG_FOR_DOMAIN="${EXTRA_CONFIG[$domain]:-$DEFAULT_EXTRA_CONFIG}"
    echo "Creating Nginx config for $domain on port $port..."

    sudo tee "$config_file" > /dev/null <<EOL
server {
    listen 80;
    listen [::]:80;

    server_name $domain;

    $EXTRA_CONFIG_FOR_DOMAIN

    location / {
        proxy_pass http://localhost:$port;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOL
}

# Create Nginx config and symlink for each service
for domain in "${!services[@]}"; do
    port=${services[$domain]}
    config_file="$nginx_available/$domain"

    # Check if the Nginx config file already exists
    if [ -f "$config_file" ]; then
        echo "Nginx config for $domain already exists. Skipping creation..."
    else
        create_nginx_config "$domain" "$port"
        
        # Create symlink in sites-enabled
        sudo ln -sf "$nginx_available/$domain" "$nginx_enabled/$domain"
    fi
done

# Reload Nginx to apply the changes
echo "Reloading Nginx..."
sudo systemctl reload nginx

# Install SSL certificates with Certbot for domains
declare -A domain_groups=(
    ["pipelines.cleanerp.com"]="pipelines.cleanerp.com"
    ["docker.cleanerp.com"]="docker.cleanerp.com"
    ["grafana.cleanerp.com"]="grafana.cleanerp.com"
)


# Install or renew certificates for each domain group
for domain_group in "${!domain_groups[@]}"; do
    domains=${domain_groups[$domain_group]}
    echo "Processing SSL certificates for: $domains..."

    # Split domains with -d flag for each domain
    certbot_domains=""
    for domain in $domains; do
        certbot_domains="$certbot_domains -d $domain"
    done

    # Run certbot with domain flags; --force-renewal ensures renewal if it exists
    echo "Installing or renewing SSL certificates for: $domains..."
    sudo certbot --nginx $certbot_domains --email "$email" --agree-tos --non-interactive --force-renewal
done

# Reload Nginx to apply SSL certificates
sudo systemctl reload nginx

# Final status check
echo "Nginx setup and SSL certificates installation completed!"
echo "------------------------"
echo "SSL Certificates Status:"
echo "------------------------"
sudo certbot certificates
