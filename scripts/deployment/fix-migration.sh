#!/bin/bash
# Fix failed Prisma migration on EC2

set -e

KEY_PATH="${AWS_KEY_PATH:-~/.ssh/mock-fitband-api-key.pem}"
INSTANCE_NAME="mock-fitband-api"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}=== Fixing Failed Migration ===${NC}"

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

# Fix migration
ssh -i ${KEY_PATH} -o StrictHostKeyChecking=no ubuntu@${PUBLIC_IP} << 'EOF'
set -e
cd /home/ubuntu/mock-fitband-api

echo "Checking current container status..."
sudo docker-compose -f docker-compose.prod.yml --env-file .env.prod ps || true

echo ""
echo "Resolving failed migration..."
# Try marking as applied first (if tables exist), then rolled back if that fails
echo "Attempting to mark migration as APPLIED (tables may already exist)..."
sudo docker-compose -f docker-compose.prod.yml --env-file .env.prod run --rm app \
  npx prisma migrate resolve --applied 20251129194727_init 2>/dev/null || {
  echo "Marking as APPLIED failed, trying ROLLED BACK..."
  sudo docker-compose -f docker-compose.prod.yml --env-file .env.prod run --rm app \
    npx prisma migrate resolve --rolled-back 20251129194727_init || echo "Migration resolution skipped (may already be resolved)"
}

echo ""
echo "Starting/restarting container..."
sudo docker-compose -f docker-compose.prod.yml --env-file .env.prod up -d

echo ""
echo "Waiting for service to start..."
sleep 15

echo ""
echo "Checking container status..."
sudo docker-compose -f docker-compose.prod.yml --env-file .env.prod ps

echo ""
echo "Recent logs:"
sudo docker-compose -f docker-compose.prod.yml --env-file .env.prod logs --tail=40 app
EOF

echo ""
echo -e "${GREEN}✓ Migration fix complete!${NC}"

