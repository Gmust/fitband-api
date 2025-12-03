#!/bin/bash
# Setup Nginx reverse proxy for HTTP (port 80) - simpler than HTTPS setup

set -e

KEY_PATH="${AWS_KEY_PATH:-$HOME/.ssh/mock-fitband-api-key.pem}"
INSTANCE_NAME="${INSTANCE_NAME:-mock-fitband-api}"
DOMAIN="${1:-mock-fitband-api.duckdns.org}"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=== Setting up Nginx Reverse Proxy ===${NC}"
echo "Domain: ${DOMAIN}"
echo ""

# Get instance details
INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=${INSTANCE_NAME}" "Name=instance-state-name,Values=running" \
  --query 'Reservations[0].Instances[0].InstanceId' \
  --output text 2>/dev/null || echo "")

if [ -z "$INSTANCE_ID" ] || [ "$INSTANCE_ID" == "None" ]; then
  echo -e "${RED}Error: No running instance found${NC}"
  exit 1
fi

PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

echo -e "${GREEN}Instance: ${INSTANCE_ID}${NC}"
echo -e "${GREEN}Public IP: ${PUBLIC_IP}${NC}"
echo ""

# Check SSH key
if [ ! -f "$KEY_PATH" ]; then
  echo -e "${RED}Error: SSH key not found at: ${KEY_PATH}${NC}"
  exit 1
fi

# Setup Nginx on server
ssh -i ${KEY_PATH} -o StrictHostKeyChecking=no ubuntu@${PUBLIC_IP} << EOF
set -e

echo "=== Installing Nginx ==="
sudo apt-get update -qq
sudo apt-get install -y nginx

echo ""
echo "=== Creating Nginx configuration ==="
sudo tee /etc/nginx/sites-available/mock-fitband-api > /dev/null <<NGINX_CONFIG
server {
    listen 80;
    server_name ${DOMAIN};

    # Proxy to NestJS app on port 8080
    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
}
NGINX_CONFIG

echo ""
echo "=== Enabling site ==="
sudo ln -sf /etc/nginx/sites-available/mock-fitband-api /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

echo ""
echo "=== Testing Nginx configuration ==="
if sudo nginx -t; then
  echo -e "\033[0;32m✓ Nginx configuration is valid\033[0m"
else
  echo -e "\033[0;31m✗ Nginx configuration error\033[0m"
  exit 1
fi

echo ""
echo "=== Restarting Nginx ==="
sudo systemctl restart nginx
sudo systemctl enable nginx

echo ""
echo "=== Checking Nginx status ==="
sudo systemctl status nginx --no-pager | head -5

echo ""
echo "=== Checking port 80 ==="
sudo lsof -i :80 || echo "Port 80 not in use"

echo ""
echo "=== Testing local connection ==="
curl -s http://localhost/health | head -3 || echo "API not responding on localhost"
EOF

echo ""
echo -e "${GREEN}✓ Nginx setup complete!${NC}"
echo ""
echo -e "${BLUE}Your API is now accessible at:${NC}"
echo "  http://${DOMAIN}"
echo "  http://${DOMAIN}/api (Swagger UI)"
echo "  http://${DOMAIN}/health"
echo ""
echo -e "${YELLOW}Note: This is HTTP only. For HTTPS, run:${NC}"
echo "  ./scripts/deployment/setup-https-duckdns.sh"
echo ""
echo "Make sure your EC2 security group allows port 80!"

