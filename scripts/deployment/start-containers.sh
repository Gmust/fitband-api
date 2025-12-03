#!/bin/bash
# Manually start containers and show logs in real-time

set -e

KEY_PATH="${AWS_KEY_PATH:-$HOME/.ssh/mock-fitband-api-key.pem}"
INSTANCE_NAME="${INSTANCE_NAME:-mock-fitband-api}"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=== Starting Containers ===${NC}"
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

# Start containers and show logs
ssh -i ${KEY_PATH} -o StrictHostKeyChecking=no ubuntu@${PUBLIC_IP} << EOF
set -e

cd /home/ubuntu/mock-fitband-api

echo "=== Checking .env.prod ==="
if [ ! -f ".env.prod" ]; then
  echo -e "\033[0;31mERROR: .env.prod not found!\033[0m"
  exit 1
fi

echo "=== Required environment variables ==="
grep -E "^(DATABASE_URL|JWT_SECRET|NODE_ENV)=" .env.prod || echo "Warning: Some required vars may be missing"

echo ""
echo "=== Starting containers ==="
sudo docker-compose -f docker-compose.prod.yml --env-file .env.prod up -d

echo ""
echo "=== Waiting 5 seconds for containers to start ==="
sleep 5

echo ""
echo "=== Container status ==="
sudo docker-compose -f docker-compose.prod.yml --env-file .env.prod ps

echo ""
echo "=== Recent logs (last 50 lines) ==="
sudo docker-compose -f docker-compose.prod.yml --env-file .env.prod logs --tail=50

echo ""
echo "=== Checking if container is running ==="
if sudo docker ps | grep -q mock-fitband-api-app; then
  echo -e "\033[0;32m✓ Container is running\033[0m"
else
  echo -e "\033[0;31m✗ Container is NOT running\033[0m"
  echo ""
  echo "=== Checking stopped containers ==="
  sudo docker ps -a | grep mock-fitband-api || echo "No containers found"
  echo ""
  echo "=== Exit code of stopped container ==="
  sudo docker ps -a --filter "name=mock-fitband-api-app" --format "{{.Status}}" || true
fi
EOF

echo ""
echo -e "${GREEN}✓ Done!${NC}"

