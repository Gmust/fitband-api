#!/bin/bash
# Clear database via EC2 instance (where DB is accessible)

set -e

KEY_PATH="${AWS_KEY_PATH:-~/.ssh/mock-fitband-api-key.pem}"
INSTANCE_NAME="mock-fitband-api"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=== Clearing Database ===${NC}"

# Allow manual IP override via first argument
if [ -n "$1" ]; then
  PUBLIC_IP="$1"
  echo -e "${GREEN}Using provided IP: ${PUBLIC_IP}${NC}"
else
  # Try to get instance details via AWS CLI
  INSTANCE_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${INSTANCE_NAME}" "Name=instance-state-name,Values=running" \
    --query 'Reservations[0].Instances[0].InstanceId' \
    --output text 2>/dev/null || echo "")

  if [ -z "$INSTANCE_ID" ] || [ "$INSTANCE_ID" == "None" ]; then
    echo -e "${YELLOW}No running instance found via AWS CLI.${NC}"
    echo -e "${YELLOW}Please provide EC2 IP as argument:${NC}"
    echo "  ./clear-db.sh <EC2_IP>"
    echo ""
    echo "Or authenticate AWS CLI and try again:"
    echo "  aws login"
    exit 1
  fi

  PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

  echo -e "${GREEN}Found instance: ${INSTANCE_ID}${NC}"
  echo -e "${GREEN}Public IP: ${PUBLIC_IP}${NC}"
fi
echo ""

# Confirm before proceeding
echo -e "${RED}WARNING: This will DELETE ALL DATA in the database!${NC}"
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
  echo "Aborted."
  exit 0
fi

echo -e "${BLUE}Connecting to EC2 and clearing database...${NC}"

ssh -i ${KEY_PATH} -o StrictHostKeyChecking=no ubuntu@${PUBLIC_IP} << 'EOF'
  # Find app directory
  APP_DIR=$(find ~ -maxdepth 2 -name "mock-fitband-api" -o -name "fitband-mqtt-broker" 2>/dev/null | head -1)
  
  if [ -z "$APP_DIR" ]; then
    echo "App directory not found. Trying common locations..."
    APP_DIR="~/mock-fitband-api"
  fi
  
  cd "$APP_DIR" || exit 1
  
  echo "Current directory: $(pwd)"
  
  # Check if running in Docker
  if [ -f "docker-compose.prod.yml" ] && docker-compose -f docker-compose.prod.yml ps app 2>/dev/null | grep -q "Up"; then
    echo "Running reset via Docker container..."
    docker-compose -f docker-compose.prod.yml exec -T app npx prisma migrate reset --force
  else
    echo "Running reset directly..."
    # Load DATABASE_URL from .env.prod if it exists
    if [ -f ".env.prod" ]; then
      export $(cat .env.prod | grep DATABASE_URL | xargs)
    fi
    
    if [ -z "$DATABASE_URL" ]; then
      echo "ERROR: DATABASE_URL not found in .env.prod"
      exit 1
    fi
    
    npx prisma migrate reset --force
  fi
  
  echo "Database cleared successfully!"
EOF

echo -e "${GREEN}✓ Database cleared!${NC}"

