#!/bin/bash
# Update DuckDNS IP address

set -e

DUCKDNS_TOKEN="${DUCKDNS_TOKEN}"
DUCKDNS_SUBDOMAIN="${DUCKDNS_SUBDOMAIN}"

if [ -z "$DUCKDNS_TOKEN" ] || [ -z "$DUCKDNS_SUBDOMAIN" ]; then
  echo "Usage:"
  echo "  export DUCKDNS_TOKEN='your-token'"
  echo "  export DUCKDNS_SUBDOMAIN='your-subdomain'"
  echo "  ./scripts/update-duckdns.sh"
  echo ""
  echo "Or get EC2 IP and update:"
  echo "  EC2_IP=\$(./scripts/get-ec2-ip.sh | grep 'Public IP:' | awk '{print \$3}')"
  echo "  curl \"https://www.duckdns.org/update?domains=\${DUCKDNS_SUBDOMAIN}&token=\${DUCKDNS_TOKEN}&ip=\${EC2_IP}\""
  exit 1
fi

# Get current IP
if [ -n "$1" ]; then
  IP="$1"
else
  # Try to get EC2 IP first
  if command -v aws &> /dev/null; then
    IP=$(aws ec2 describe-instances \
      --filters "Name=tag:Name,Values=mock-fitband-api" "Name=instance-state-name,Values=running" \
      --query 'Reservations[0].Instances[0].PublicIpAddress' \
      --output text 2>/dev/null || echo "")
  fi
  
  # Fallback to checkip
  if [ -z "$IP" ] || [ "$IP" == "None" ]; then
    IP=$(curl -s https://checkip.amazonaws.com)
  fi
fi

# Update DuckDNS
echo "Updating DuckDNS: ${DUCKDNS_SUBDOMAIN}.duckdns.org -> ${IP}"
RESPONSE=$(curl -s "https://www.duckdns.org/update?domains=${DUCKDNS_SUBDOMAIN}&token=${DUCKDNS_TOKEN}&ip=${IP}")

if [ "$RESPONSE" == "OK" ]; then
  echo "✓ DuckDNS updated successfully"
  echo ""
  echo "DNS may take a few minutes to propagate. Test with:"
  echo "  dig +short ${DUCKDNS_SUBDOMAIN}.duckdns.org"
  echo "  curl http://${DUCKDNS_SUBDOMAIN}.duckdns.org:8080/health"
else
  echo "✗ Failed to update DuckDNS: $RESPONSE"
  echo ""
  echo "Common causes of 'KO' response:"
  echo "  1. Invalid DuckDNS token"
  echo "  2. Subdomain doesn't exist in your DuckDNS account"
  echo "  3. Rate limiting (too many requests)"
  echo ""
  echo "To fix:"
  echo "  1. Go to https://www.duckdns.org/"
  echo "  2. Sign in and check your token"
  echo "  3. Make sure the subdomain '${DUCKDNS_SUBDOMAIN}' exists in your account"
  echo "  4. Wait a few minutes if you've made many requests"
  echo ""
  echo "Verify your token and subdomain, then try again:"
  echo "  DUCKDNS_TOKEN='your-actual-token' DUCKDNS_SUBDOMAIN='your-subdomain' ./scripts/deployment/update-duckdns.sh"
  exit 1
fi

