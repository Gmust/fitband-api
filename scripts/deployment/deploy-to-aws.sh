#!/bin/bash
# Quick deploy script to AWS EC2

set -e

KEY_PATH="${AWS_KEY_PATH:-~/.ssh/mock-fitband-api-key.pem}"
INSTANCE_NAME="mock-fitband-api"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}=== Deploying to AWS EC2 ===${NC}"

# Get instance details
INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=${INSTANCE_NAME}" "Name=instance-state-name,Values=running" \
  --query 'Reservations[0].Instances[0].InstanceId' \
  --output text 2>/dev/null || echo "")

if [ -z "$INSTANCE_ID" ] || [ "$INSTANCE_ID" == "None" ]; then
  echo -e "${YELLOW}No running instance found. Please create one first.${NC}"
  echo "See AWS_API_DEPLOYMENT.md for instructions"
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
  echo "Please set AWS_KEY_PATH environment variable or create the key"
  exit 1
fi

# Sync files
echo -e "${BLUE}Syncing files...${NC}"
rsync -avz -e "ssh -i ${KEY_PATH} -o StrictHostKeyChecking=no" \
  --exclude 'node_modules' \
  --exclude '.git' \
  --exclude 'dist' \
  --exclude '.env' \
  --exclude '.env.*' \
  --exclude '*.log' \
  ./ ubuntu@${PUBLIC_IP}:/home/ubuntu/mock-fitband-api/

echo ""
echo -e "${BLUE}Deploying application...${NC}"

# Deploy
ssh -i ${KEY_PATH} -o StrictHostKeyChecking=no ubuntu@${PUBLIC_IP} << EOF
set -e
cd /home/ubuntu/mock-fitband-api

echo "Stopping existing containers..."
sudo docker-compose -f docker-compose.prod.yml --env-file .env.prod down || true

echo "Building and starting containers..."
sudo docker-compose -f docker-compose.prod.yml --env-file .env.prod up -d --build

echo "Waiting for services to be healthy..."
sleep 10

echo "Checking container status..."
sudo docker-compose -f docker-compose.prod.yml --env-file .env.prod ps

echo "Recent logs:"
sudo docker-compose -f docker-compose.prod.yml --env-file .env.prod logs --tail=20
EOF

echo ""
echo -e "${GREEN}✓ Deployment complete!${NC}"
echo -e "${GREEN}API available at: http://${PUBLIC_IP}:8080${NC}"
echo ""
echo "Test endpoints:"
echo "  curl http://${PUBLIC_IP}:8080/health"
echo "  curl http://${PUBLIC_IP}:8080/test/db"

