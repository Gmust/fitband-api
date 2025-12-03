#!/bin/bash
# Connect to AWS EC2 instance via SSH

set -e

KEY_PATH="${AWS_KEY_PATH:-$HOME/.ssh/mock-fitband-api-key.pem}"
INSTANCE_NAME="${INSTANCE_NAME:-mock-fitband-api}"
USER="${EC2_USER:-ubuntu}"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=== Connecting to EC2 Instance ===${NC}"
echo ""

# Get instance details
INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=${INSTANCE_NAME}" "Name=instance-state-name,Values=running" \
  --query 'Reservations[0].Instances[0].InstanceId' \
  --output text 2>/dev/null || echo "")

if [ -z "$INSTANCE_ID" ] || [ "$INSTANCE_ID" == "None" ]; then
  echo -e "${RED}Error: No running instance found with name: ${INSTANCE_NAME}${NC}"
  echo ""
  echo "Available instances:"
  aws ec2 describe-instances \
    --filters "Name=instance-state-name,Values=running" \
    --query 'Reservations[*].Instances[*].[Tags[?Key==`Name`].Value|[0],InstanceId,PublicIpAddress,State.Name]' \
    --output table
  exit 1
fi

PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

if [ -z "$PUBLIC_IP" ] || [ "$PUBLIC_IP" == "None" ]; then
  echo -e "${RED}Error: Could not get public IP address${NC}"
  exit 1
fi

# Check SSH key
if [ ! -f "$KEY_PATH" ]; then
  echo -e "${RED}Error: SSH key not found at: ${KEY_PATH}${NC}"
  echo ""
  echo "Please set AWS_KEY_PATH environment variable:"
  echo "  export AWS_KEY_PATH=/path/to/your/key.pem"
  echo ""
  echo "Or place your key at: $KEY_PATH"
  exit 1
fi

# Set correct permissions on key
chmod 400 "$KEY_PATH" 2>/dev/null || true

echo -e "${GREEN}Instance: ${INSTANCE_ID}${NC}"
echo -e "${GREEN}Public IP: ${PUBLIC_IP}${NC}"
echo -e "${GREEN}User: ${USER}${NC}"
echo ""
echo -e "${BLUE}Connecting...${NC}"
echo ""

# Connect via SSH
ssh -i "$KEY_PATH" \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    ${USER}@${PUBLIC_IP}

