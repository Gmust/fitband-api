#!/bin/bash
# Fix common deployment issues: stop all containers, free port 80, clean volumes

set -e

KEY_PATH="${AWS_KEY_PATH:-$HOME/.ssh/mock-fitband-api-key.pem}"
INSTANCE_NAME="${INSTANCE_NAME:-mock-fitband-api}"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=== Fixing Deployment Issues ===${NC}"
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

# Fix issues on server
ssh -i ${KEY_PATH} -o StrictHostKeyChecking=no ubuntu@${PUBLIC_IP} << EOF
set -e

cd /home/ubuntu/mock-fitband-api

echo "=== Stopping all containers ==="
sudo docker-compose -f docker-compose.yml down 2>/dev/null || true
sudo docker-compose -f docker-compose.prod.yml --env-file .env.prod down 2>/dev/null || true
sudo docker-compose down 2>/dev/null || true

echo ""
echo "=== Stopping processes using port 80 ==="
sudo systemctl stop nginx 2>/dev/null || true
sudo pkill -f nginx 2>/dev/null || true
sudo lsof -ti:80 | xargs -r sudo kill -9 2>/dev/null || true

echo ""
echo "=== Removing old database volumes ==="
sudo docker volume ls | grep postgres_data | awk '{print \$2}' | xargs -r sudo docker volume rm 2>/dev/null || true

echo ""
echo "=== Removing orphaned containers ==="
sudo docker ps -a --filter "name=mock-fitband" -q | xargs -r sudo docker rm -f 2>/dev/null || true

echo ""
echo "=== Checking port 80 ==="
if sudo lsof -i :80 2>/dev/null | grep -q LISTEN; then
  echo -e "\033[0;33mWarning: Port 80 is still in use\033[0m"
  sudo lsof -i :80
else
  echo -e "\033[0;32m✓ Port 80 is free\033[0m"
fi

echo ""
echo "=== Docker containers status ==="
sudo docker ps -a | grep mock-fitband || echo "No mock-fitband containers found"

echo ""
echo "=== Disk space ==="
df -h / | tail -1
EOF

echo ""
echo -e "${GREEN}✓ Cleanup complete!${NC}"
echo ""
echo "You can now run the deployment again:"
echo "  ./scripts/deployment/deploy-to-aws.sh"

