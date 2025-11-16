#!/bin/bash
# Configure nginx on port 80 and fix SSL setup

set -e

DOMAIN=${1:-"mock-fitband-api.duckdns.org"}

echo "Setting up nginx on port 80 for $DOMAIN..."

# Install nginx if needed
if ! command -v nginx &> /dev/null; then
    apt-get update
    apt-get install -y nginx
fi

# Create nginx config for port 80
cat > /etc/nginx/sites-available/$DOMAIN <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    # Let's Encrypt challenge location
    location /.well-known/acme-challenge/ {
        root /var/www/html;
        try_files \$uri =404;
    }

    # Proxy to app on port 8080
    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Enable site
ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Create directory for Let's Encrypt challenges
mkdir -p /var/www/html/.well-known/acme-challenge

# Test and start nginx
nginx -t
systemctl restart nginx
systemctl enable nginx

echo "✓ Nginx configured on port 80"
echo ""
echo "Make sure port 80 is open in Azure NSG:"
echo "  az vm open-port --port 80 --priority 1000 --resource-group mock-fitband-rg --name mock-fitband-api-vm"
echo ""
echo "Then test: curl http://$DOMAIN/health"

