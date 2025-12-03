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
else
  echo "✗ Failed to update DuckDNS: $RESPONSE"
  exit 1
fi

