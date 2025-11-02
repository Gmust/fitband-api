#!/bin/bash
# Certbot DNS challenge method (doesn't require port 80)

set -e

DOMAIN=${1:-"mock-fitband-api.duckdns.org"}

echo "Using DNS challenge method for $DOMAIN"
echo ""
echo "This method will ask you to add a TXT record to DuckDNS"
echo ""

sudo certbot certonly --manual \
    -d $DOMAIN \
    --preferred-challenges dns \
    --non-interactive \
    --agree-tos \
    --register-unsafely-without-email \
    --manual-public-ip-logging-ok

echo ""
echo "Certificate obtained! Now configure nginx to use it."

