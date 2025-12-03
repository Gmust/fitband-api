#!/bin/bash
# Check deployment status and logs on EC2

set -e

KEY_PATH="${AWS_KEY_PATH:-$HOME/.ssh/mock-fitband-api-key.pem}"
INSTANCE_NAME="${INSTANCE_NAME:-mock-fitband-api}"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=== Checking Deployment Status ===${NC}"
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

# Check status on server
ssh -i ${KEY_PATH} -o StrictHostKeyChecking=no ubuntu@${PUBLIC_IP} << EOF
set -e

cd /home/ubuntu/mock-fitband-api

echo "=== Docker Containers Status ==="
sudo docker ps -a

echo ""
echo "=== Docker Compose Status ==="
if [ -f "docker-compose.prod.yml" ] && [ -f ".env.prod" ]; then
  sudo docker-compose -f docker-compose.prod.yml --env-file .env.prod ps 2>/dev/null || echo "No containers from docker-compose.prod.yml"
else
  echo "docker-compose.prod.yml or .env.prod not found"
fi

echo ""
echo "=== Recent Container Logs ==="
sudo docker ps -a --format "{{.Names}}" | head -5 | while read container; do
  if [ -n "\$container" ]; then
    echo "--- Logs for \$container ---"
    sudo docker logs --tail=20 \$container 2>&1 || true
    echo ""
  fi
done

echo "=== Docker Images ==="
sudo docker images | grep mock-fitband || echo "No mock-fitband images found"

echo ""
echo "=== .env.prod file exists? ==="
if [ -f ".env.prod" ]; then
  echo "✓ .env.prod exists"
  echo "File size: \$(wc -l < .env.prod) lines"
else
  echo "✗ .env.prod NOT FOUND"
fi

echo ""
echo "=== Disk Space ==="
df -h / | tail -1

echo ""
echo "=== Port 8080 Status ==="
sudo lsof -i :8080 2>/dev/null || echo "Port 8080 is free"

echo ""
echo "=== Docker System Info ==="
sudo docker system df
EOF

echo ""
echo -e "${GREEN}✓ Status check complete!${NC}"
