#!/bin/bash
# Troubleshoot DNS and Let's Encrypt issues

set -e

DOMAIN=${1:-"mock-fitband-api.duckdns.org"}

echo "Checking DNS for $DOMAIN..."

# Check if domain resolves
echo "1. Checking DNS resolution:"
nslookup $DOMAIN || dig $DOMAIN +short

echo ""
echo "2. Checking if domain points to this server:"
DOMAIN_IP=$(dig +short $DOMAIN | tail -1)
SERVER_IP=$(curl -s ifconfig.me)

echo "Domain IP: $DOMAIN_IP"
echo "Server IP: $SERVER_IP"

if [ "$DOMAIN_IP" = "$SERVER_IP" ]; then
    echo "✓ DNS is correct!"
else
    echo "✗ DNS mismatch! Update DuckDNS with IP: $SERVER_IP"
fi

echo ""
echo "3. Checking port 80 accessibility:"
curl -I http://$DOMAIN || echo "Cannot reach domain on port 80"

echo ""
echo "4. Testing Let's Encrypt verification:"
curl -I http://$DOMAIN/.well-known/acme-challenge/test || echo "ACME challenge path not accessible"

