#!/bin/bash
# Get EC2 instance IP address for database whitelist

set -e

INSTANCE_NAME="${INSTANCE_NAME:-mock-fitband-api}"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}=== Getting EC2 Instance IP ===${NC}"
echo ""

# Get instance ID
INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=${INSTANCE_NAME}" "Name=instance-state-name,Values=running" \
  --query 'Reservations[0].Instances[0].InstanceId' \
  --output text 2>/dev/null || echo "")

if [ -z "$INSTANCE_ID" ] || [ "$INSTANCE_ID" == "None" ]; then
  echo -e "${YELLOW}No running instance found with name: ${INSTANCE_NAME}${NC}"
  echo ""
  echo "Available instances:"
  aws ec2 describe-instances \
    --filters "Name=instance-state-name,Values=running" \
    --query 'Reservations[*].Instances[*].[Tags[?Key==`Name`].Value|[0],InstanceId,PublicIpAddress,PrivateIpAddress]' \
    --output table
  exit 1
fi

# Get IPs
PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

PRIVATE_IP=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].PrivateIpAddress' \
  --output text)

echo -e "${GREEN}Instance ID: ${INSTANCE_ID}${NC}"
echo ""
echo -e "${BLUE}IP Addresses:${NC}"
echo "  Public IP:  ${PUBLIC_IP}"
echo "  Private IP: ${PRIVATE_IP}"
echo ""

# Determine which IP to use
echo -e "${YELLOW}For Database Whitelist:${NC}"
if [ -n "$PUBLIC_IP" ] && [ "$PUBLIC_IP" != "None" ]; then
  echo "  Use Public IP: ${PUBLIC_IP}"
  echo ""
  echo "Add this IP to your database whitelist:"
  echo -e "${GREEN}${PUBLIC_IP}/32${NC}"
  echo ""
  echo "Or copy just the IP:"
  echo -e "${GREEN}${PUBLIC_IP}${NC}"
  echo ""
  
  # Copy to clipboard if available
  if command -v pbcopy &> /dev/null; then
    echo "${PUBLIC_IP}" | pbcopy
    echo "✓ IP copied to clipboard (macOS)"
  elif command -v xclip &> /dev/null; then
    echo "${PUBLIC_IP}" | xclip -selection clipboard
    echo "✓ IP copied to clipboard (Linux)"
  fi
else
  echo -e "${YELLOW}No public IP found. Instance may be in private subnet.${NC}"
  echo "  Use Private IP: ${PRIVATE_IP}"
fi

echo ""
echo -e "${BLUE}Security Group Info:${NC}"
SG_ID=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' \
  --output text)

echo "  Security Group: ${SG_ID}"

