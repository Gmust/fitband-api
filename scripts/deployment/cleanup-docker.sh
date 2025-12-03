#!/bin/bash
# Clean up Docker resources on EC2 instance to free disk space

set -e

KEY_PATH="${AWS_KEY_PATH:-$HOME/.ssh/mock-fitband-api-key.pem}"
INSTANCE_NAME="${INSTANCE_NAME:-mock-fitband-api}"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=== Cleaning up Docker resources on EC2 ===${NC}"
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

# Clean up Docker resources
ssh -i ${KEY_PATH} -o StrictHostKeyChecking=no ubuntu@${PUBLIC_IP} << EOF
set -e

echo "=== Disk space before cleanup ==="
df -h / | tail -1

echo ""
echo "=== Stopping containers ==="
sudo docker-compose -f /home/ubuntu/mock-fitband-api/docker-compose.prod.yml --env-file /home/ubuntu/mock-fitband-api/.env.prod down 2>/dev/null || true

echo ""
echo "=== Removing unused Docker images ==="
sudo docker image prune -a -f || true

echo ""
echo "=== Removing unused Docker containers ==="
sudo docker container prune -f || true

echo ""
echo "=== Removing unused Docker volumes ==="
sudo docker volume prune -f || true

echo ""
echo "=== Removing unused Docker build cache ==="
sudo docker builder prune -a -f || true

echo ""
echo "=== Removing system package cache ==="
sudo apt-get clean || true
sudo apt-get autoclean || true

echo ""
echo "=== Removing old logs ==="
sudo journalctl --vacuum-time=3d || true

echo ""
echo "=== Disk space after cleanup ==="
df -h / | tail -1

echo ""
echo "=== Docker disk usage ==="
sudo docker system df || true
EOF

echo ""
echo -e "${GREEN}✓ Cleanup complete!${NC}"

