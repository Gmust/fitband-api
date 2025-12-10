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

# Get branch to deploy (default to current branch, or use first argument)
DEPLOY_BRANCH="${1:-$(git branch --show-current 2>/dev/null || echo 'main')}"
GIT_REPO_URL=$(git remote get-url origin 2>/dev/null || echo "")

if [ -z "$GIT_REPO_URL" ]; then
  echo -e "${YELLOW}Warning: Could not detect git remote URL${NC}"
  echo "Please provide branch name as argument: ./deploy-to-aws.sh <branch-name>"
  echo "Or ensure you're in a git repository with a remote configured"
  exit 1
fi

echo -e "${GREEN}Deploying branch: ${DEPLOY_BRANCH}${NC}"
echo -e "${GREEN}Repository: ${GIT_REPO_URL}${NC}"
echo ""

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

# Deploy using git on server
echo -e "${BLUE}Setting up code on server from git branch: ${DEPLOY_BRANCH}...${NC}"
ssh -i ${KEY_PATH} -o StrictHostKeyChecking=no ubuntu@${PUBLIC_IP} << GIT_SETUP
set -e
cd /home/ubuntu

# Check if directory exists and is a git repo
if [ -d "mock-fitband-api" ] && [ -d "mock-fitband-api/.git" ]; then
  echo "Updating existing git repository..."
  cd mock-fitband-api
  git fetch origin
elif [ -d "mock-fitband-api" ]; then
  echo "Directory exists but is not a git repo. Removing and cloning fresh..."
  rm -rf mock-fitband-api
  git clone ${GIT_REPO_URL} mock-fitband-api
  cd mock-fitband-api
else
  echo "Cloning repository..."
  git clone ${GIT_REPO_URL} mock-fitband-api
  cd mock-fitband-api
fi

# Checkout the desired branch
echo "Checking out branch: ${DEPLOY_BRANCH}"
git fetch origin ${DEPLOY_BRANCH} || echo "Fetching branch..."
git checkout ${DEPLOY_BRANCH} 2>/dev/null || git checkout -b ${DEPLOY_BRANCH} origin/${DEPLOY_BRANCH} || {
  echo "Branch ${DEPLOY_BRANCH} not found. Available branches:"
  git branch -r
  exit 1
}
git pull origin ${DEPLOY_BRANCH} || echo "Already up to date"

echo ""
echo "Current branch on server:"
git branch --show-current
echo "Latest commit:"
git log -1 --oneline

echo ""
echo "Verifying code..."
if [ -f "src/app.module.ts" ]; then
  echo "✓ src/app.module.ts exists"
  if grep -q "SessionModule" src/app.module.ts 2>/dev/null; then
    echo "  → Contains SessionModule"
  else
    echo "  → No SessionModule (backend-updates branch)"
  fi
else
  echo "✗ src/app.module.ts not found!"
  exit 1
fi
GIT_SETUP
echo ""

echo ""
echo -e "${BLUE}Deploying application...${NC}"

# Deploy
ssh -i ${KEY_PATH} -o StrictHostKeyChecking=no ubuntu@${PUBLIC_IP} << EOF
set -e
cd /home/ubuntu/mock-fitband-api

echo "Stopping existing containers..."
sudo docker-compose -f docker-compose.prod.yml --env-file .env.prod down || true

echo "Resolving any failed migrations..."
# Try marking as applied first (tables may already exist), then rolled back if that fails
echo "Attempting to mark migration as APPLIED (tables may already exist)..."
sudo docker-compose -f docker-compose.prod.yml --env-file .env.prod run --rm app \
  npx prisma migrate resolve --applied 20251129194727_init 2>/dev/null || {
  echo "Marking as APPLIED failed, trying ROLLED BACK..."
  sudo docker-compose -f docker-compose.prod.yml --env-file .env.prod run --rm app \
    npx prisma migrate resolve --rolled-back 20251129194727_init || echo "Migration resolution skipped (may already be resolved)"
}

echo ""
echo "Building containers with --no-cache to ensure fresh build..."
sudo docker-compose -f docker-compose.prod.yml --env-file .env.prod build --no-cache

echo ""
echo "Starting containers..."
sudo docker-compose -f docker-compose.prod.yml --env-file .env.prod up -d

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

