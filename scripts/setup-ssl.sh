#!/bin/bash
# Setup HTTPS/SSL with Let's Encrypt on Azure VM

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}Setting up HTTPS/SSL with Let's Encrypt...${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root or with sudo${NC}"
    exit 1
fi

# Get domain name
read -p "Enter your domain name (e.g., api.yourdomain.com): " DOMAIN

if [ -z "$DOMAIN" ]; then
    echo -e "${RED}Domain name is required${NC}"
    exit 1
fi

echo -e "${BLUE}Domain: $DOMAIN${NC}"

# Install certbot
echo -e "${BLUE}Installing certbot...${NC}"
apt-get update
apt-get install -y certbot python3-certbot-nginx

# Install nginx if not installed
if ! command -v nginx &> /dev/null; then
    echo -e "${BLUE}Installing nginx...${NC}"
    apt-get install -y nginx
fi

# Configure nginx for domain (temporary HTTP config)
echo -e "${BLUE}Creating nginx configuration...${NC}"
cat > /etc/nginx/sites-available/$DOMAIN <<EOF
server {
    listen 80;
    server_name $DOMAIN;

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

# Test nginx config
nginx -t

# Restart nginx
systemctl restart nginx

# Obtain SSL certificate
echo -e "${BLUE}Obtaining SSL certificate from Let's Encrypt...${NC}"
echo -e "${YELLOW}Make sure your domain $DOMAIN points to this server's IP!${NC}"
read -p "Press Enter to continue after DNS is configured..."

certbot --nginx -d $DOMAIN --non-interactive --agree-tos --register-unsafely-without-email

# Update nginx config with better SSL settings
cat > /etc/nginx/sites-available/$DOMAIN <<EOF
server {
    listen 80;
    server_name $DOMAIN;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    # SSL Configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
}
EOF

# Test and reload nginx
nginx -t
systemctl reload nginx

# Setup auto-renewal
echo -e "${BLUE}Setting up automatic certificate renewal...${NC}"
systemctl enable certbot.timer
systemctl start certbot.timer

echo -e "${GREEN}✓ HTTPS setup complete!${NC}"
echo ""
echo -e "${BLUE}Your API is now available at:${NC}"
echo "  https://$DOMAIN"
echo ""
echo -e "${YELLOW}Note: Update your CORS_ORIGIN in .env.prod to include:${NC}"
echo "  CORS_ORIGIN=https://$DOMAIN,http://$DOMAIN"
echo ""
echo -e "${BLUE}Test SSL:${NC}"
echo "  curl https://$DOMAIN/health"

