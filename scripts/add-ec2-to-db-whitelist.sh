#!/bin/bash
# Add EC2 instance IP to database security group/whitelist

set -e

INSTANCE_NAME="${INSTANCE_NAME:-mock-fitband-api}"
DB_SECURITY_GROUP_ID="${DB_SECURITY_GROUP_ID}"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=== Add EC2 IP to Database Whitelist ===${NC}"
echo ""

# Check if DB security group ID provided
if [ -z "$DB_SECURITY_GROUP_ID" ]; then
  echo -e "${YELLOW}DB_SECURITY_GROUP_ID not set.${NC}"
  echo ""
  echo "Usage:"
  echo "  DB_SECURITY_GROUP_ID=sg-xxxxxxxxx ./scripts/add-ec2-to-db-whitelist.sh"
  echo ""
  echo "Or find your database security group:"
  echo "  # For RDS:"
  echo "  aws rds describe-db-instances --query 'DBInstances[*].[DBInstanceIdentifier,VpcSecurityGroups[0].VpcSecurityGroupId]' --output table"
  echo ""
  echo "  # For other databases, find the security group ID from your database provider"
  exit 1
fi

# Get EC2 instance IP
echo -e "${BLUE}Getting EC2 instance IP...${NC}"
INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=${INSTANCE_NAME}" "Name=instance-state-name,Values=running" \
  --query 'Reservations[0].Instances[0].InstanceId' \
  --output text 2>/dev/null || echo "")

if [ -z "$INSTANCE_ID" ] || [ "$INSTANCE_ID" == "None" ]; then
  echo -e "${RED}Error: No running EC2 instance found${NC}"
  exit 1
fi

PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

if [ -z "$PUBLIC_IP" ] || [ "$PUBLIC_IP" == "None" ]; then
  echo -e "${RED}Error: Could not get public IP${NC}"
  exit 1
fi

echo -e "${GREEN}EC2 Instance: ${INSTANCE_ID}${NC}"
echo -e "${GREEN}Public IP: ${PUBLIC_IP}${NC}"
echo ""

# Add rule to database security group
echo -e "${BLUE}Adding IP to database security group...${NC}"
echo "  Security Group: ${DB_SECURITY_GROUP_ID}"
echo "  IP: ${PUBLIC_IP}/32"
echo "  Port: 5432 (PostgreSQL)"
echo ""

if aws ec2 authorize-security-group-ingress \
  --group-id ${DB_SECURITY_GROUP_ID} \
  --protocol tcp \
  --port 5432 \
  --cidr ${PUBLIC_IP}/32 2>/dev/null; then
  echo -e "${GREEN}✓ Successfully added IP to database whitelist${NC}"
else
  EXIT_CODE=$?
  if [ $EXIT_CODE -eq 254 ]; then
    echo -e "${YELLOW}⚠ Rule already exists (IP may already be whitelisted)${NC}"
  else
    echo -e "${RED}✗ Failed to add IP to whitelist${NC}"
    exit 1
  fi
fi

echo ""
echo -e "${GREEN}✓ EC2 instance can now connect to database${NC}"

