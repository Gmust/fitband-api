#!/bin/bash
# Check DNS configuration and accessibility

set -e

KEY_PATH="${AWS_KEY_PATH:-$HOME/.ssh/mock-fitband-api-key.pem}"
INSTANCE_NAME="${INSTANCE_NAME:-mock-fitband-api}"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=== DNS Troubleshooting ===${NC}"
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

echo -e "${GREEN}EC2 Instance IP: ${PUBLIC_IP}${NC}"
echo ""

# Check if domain provided
if [ -z "$1" ]; then
  echo -e "${YELLOW}Usage: ./scripts/deployment/check-dns.sh <domain>${NC}"
  echo "Example: ./scripts/deployment/check-dns.sh mock-fitband-api.duckdns.org"
  echo ""
  echo "Checking if domain is accessible via IP..."
  echo ""
  
  # Test direct IP access
  echo "=== Testing Direct IP Access ==="
  if curl -s --max-time 5 "http://${PUBLIC_IP}:8080/health" > /dev/null; then
    echo -e "${GREEN}✓ API is accessible via IP: http://${PUBLIC_IP}:8080${NC}"
  else
    echo -e "${RED}✗ API is NOT accessible via IP${NC}"
    echo "  Check security group allows port 8080"
  fi
  
  echo ""
  echo "=== Security Group Check ==="
  echo "Make sure your EC2 security group allows:"
  echo "  - Port 80 (HTTP) from 0.0.0.0/0"
  echo "  - Port 443 (HTTPS) from 0.0.0.0/0"
  echo "  - Port 8080 (API) from 0.0.0.0/0"
  echo ""
  echo "To check security groups:"
  echo "  aws ec2 describe-security-groups --group-ids \$(aws ec2 describe-instances --instance-ids ${INSTANCE_ID} --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' --output text)"
  exit 0
fi

DOMAIN="$1"

echo -e "${BLUE}Checking DNS for: ${DOMAIN}${NC}"
echo ""

# Check DNS resolution
echo "=== DNS Resolution ==="
RESOLVED_IP=$(dig +short ${DOMAIN} @8.8.8.8 | tail -1 || echo "")

if [ -z "$RESOLVED_IP" ]; then
  echo -e "${RED}✗ Domain does not resolve${NC}"
  echo ""
  echo "Possible issues:"
  echo "  1. Domain not configured in DuckDNS"
  echo "  2. DNS not propagated yet (can take up to 5 minutes)"
  echo "  3. Wrong domain name"
  echo ""
  echo "To update DuckDNS:"
  echo "  DUCKDNS_TOKEN=xxx DUCKDNS_SUBDOMAIN=xxx ./scripts/deployment/update-duckdns.sh"
  exit 1
fi

echo "Resolved IP: ${RESOLVED_IP}"
echo "EC2 IP:      ${PUBLIC_IP}"

if [ "$RESOLVED_IP" == "$PUBLIC_IP" ]; then
  echo -e "${GREEN}✓ DNS points to correct IP${NC}"
else
  echo -e "${RED}✗ DNS points to wrong IP!${NC}"
  echo ""
  echo "Update DuckDNS:"
  echo "  DUCKDNS_TOKEN=xxx DUCKDNS_SUBDOMAIN=xxx ./scripts/deployment/update-duckdns.sh"
  exit 1
fi

echo ""
echo "=== Testing HTTP Access ==="
if curl -s --max-time 5 "http://${DOMAIN}" > /dev/null 2>&1; then
  echo -e "${GREEN}✓ Domain is accessible via HTTP${NC}"
else
  echo -e "${YELLOW}⚠ Domain not accessible via HTTP${NC}"
  echo "  This is OK if you're using HTTPS only"
fi

echo ""
echo "=== Testing HTTPS Access ==="
if curl -s --max-time 5 "https://${DOMAIN}" > /dev/null 2>&1; then
  echo -e "${GREEN}✓ Domain is accessible via HTTPS${NC}"
else
  echo -e "${RED}✗ Domain not accessible via HTTPS${NC}"
  echo "  Check if SSL certificate is installed"
  echo "  Check if Nginx is running and configured"
fi

echo ""
echo "=== Testing API Endpoint ==="
if curl -s --max-time 5 "http://${DOMAIN}:8080/health" > /dev/null 2>&1 || curl -s --max-time 5 "https://${DOMAIN}/health" > /dev/null 2>&1; then
  echo -e "${GREEN}✓ API endpoint is accessible${NC}"
else
  echo -e "${YELLOW}⚠ API endpoint not accessible via domain${NC}"
  echo "  Try direct IP: http://${PUBLIC_IP}:8080/health"
fi

echo ""
echo "=== Summary ==="
echo "Domain: ${DOMAIN}"
echo "Resolves to: ${RESOLVED_IP}"
echo "EC2 IP: ${PUBLIC_IP}"
echo ""
if [ "$RESOLVED_IP" == "$PUBLIC_IP" ]; then
  echo -e "${GREEN}✓ DNS is configured correctly${NC}"
  echo ""
  echo "If domain still not accessible:"
  echo "  1. Check security group allows ports 80/443/8080"
  echo "  2. Check if Nginx is running (if using HTTPS)"
  echo "  3. Wait a few minutes for DNS propagation"
else
  echo -e "${RED}✗ DNS needs to be updated${NC}"
fi

