#!/bin/bash
# Check container status and logs on EC2

set -e

KEY_PATH="${AWS_KEY_PATH:-~/.ssh/mock-fitband-api-key.pem}"
INSTANCE_NAME="mock-fitband-api"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=== Checking Container Status ===${NC}"

# Get instance details
INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=${INSTANCE_NAME}" "Name=instance-state-name,Values=running" \
  --query 'Reservations[0].Instances[0].InstanceId' \
  --output text 2>/dev/null || echo "")

if [ -z "$INSTANCE_ID" ] || [ "$INSTANCE_ID" == "None" ]; then
  echo -e "${YELLOW}No running instance found.${NC}"
  exit 1
fi

PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

echo -e "${GREEN}Found instance: ${INSTANCE_ID}${NC}"
echo -e "${GREEN}Public IP: ${PUBLIC_IP}${NC}"
echo ""

# Check SSH key
if [ ! -f "$KEY_PATH" ]; then
  echo -e "${YELLOW}SSH key not found at: ${KEY_PATH}${NC}"
  exit 1
fi

# Check status
ssh -i ${KEY_PATH} -o StrictHostKeyChecking=no ubuntu@${PUBLIC_IP} << 'EOF'
cd /home/ubuntu/mock-fitband-api

echo "=== Container Status ==="
sudo docker-compose -f docker-compose.prod.yml --env-file .env.prod ps

echo ""
echo "=== Recent Logs (last 50 lines) ==="
sudo docker-compose -f docker-compose.prod.yml --env-file .env.prod logs --tail=50 app

echo ""
echo "=== Container Health ==="
sudo docker ps -a --filter "name=mock-fitband-api-app" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
EOF

echo ""
echo -e "${GREEN}✓ Status check complete!${NC}"

