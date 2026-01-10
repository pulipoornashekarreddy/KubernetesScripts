#!/bin/bash
# file name setup_nginx_and_certificates.sh

# file name setup_nginx_and_certificates.sh
# rm -rf setup_nginx_and_certificates.sh
# sudo nano setup_nginx_and_certificates.sh
# sudo bash setup_nginx_and_certificates.sh

sudo apt update && sudo apt upgrade -y

sudo apt install -y nginx

sudo apt install -y certbot python3-certbot-nginx

#!/bin/bash
# file name setup_nginx_and_certificates.sh

# file name setup_nginx_and_certificates.sh
# rm -rf setup_nginx_and_certificates.sh
# sudo nano setup_nginx_and_certificates.sh
# sudo bash setup_nginx_and_certificates.sh


# Define services and ports
declare -A services=(
    ["compiler.cleanerp.com"]="2358"
)

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
    echo "Creating Nginx config for $domain on port $port..."

    sudo tee "$config_file" > /dev/null <<EOL
server {
    listen 80;
    listen [::]:80;

    server_name $domain;

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
    ["compiler.cleanerp.com"]="compiler.cleanerp.com"
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
