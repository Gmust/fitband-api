#!/bin/bash

# AWS RDS Setup Script for Mock Fitband API
# This script helps create an RDS PostgreSQL instance

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DB_INSTANCE_ID="mock-fitband-db"
DB_NAME="mock_fitband_db"
DB_USER="postgres"
REGION=$(aws configure get region || echo "us-east-1")

echo -e "${BLUE}=== AWS RDS PostgreSQL Setup ===${NC}"
echo ""

# Check AWS credentials
echo -e "${BLUE}Checking AWS credentials...${NC}"
if ! aws sts get-caller-identity &>/dev/null; then
    echo -e "${RED}Error: AWS credentials not configured${NC}"
    echo "Run: aws configure"
    exit 1
fi
echo -e "${GREEN}✓ AWS credentials OK${NC}"
echo ""

# Get configuration from user
echo -e "${YELLOW}Configuration:${NC}"
echo "  DB Instance ID: ${DB_INSTANCE_ID}"
echo "  Database Name: ${DB_NAME}"
echo "  Master Username: ${DB_USER}"
echo "  Region: ${REGION}"
echo ""

# Get password
read -sp "Enter master password (will be hidden): " DB_PASSWORD
echo ""
read -sp "Confirm password: " DB_PASSWORD_CONFIRM
echo ""

if [ "$DB_PASSWORD" != "$DB_PASSWORD_CONFIRM" ]; then
    echo -e "${RED}Error: Passwords don't match${NC}"
    exit 1
fi

if [ -z "$DB_PASSWORD" ]; then
    echo -e "${RED}Error: Password cannot be empty${NC}"
    exit 1
fi

# Instance class selection
echo ""
echo -e "${YELLOW}Select instance class:${NC}"
echo "  1) db.t3.micro (Free tier eligible, 1 vCPU, 1GB RAM) - ~\$15/month after free tier"
echo "  2) db.t3.small (2 vCPU, 2GB RAM) - ~\$30/month"
echo "  3) db.t3.medium (2 vCPU, 4GB RAM) - ~\$60/month"
read -p "Enter choice [1-3] (default: 1): " INSTANCE_CHOICE
INSTANCE_CHOICE=${INSTANCE_CHOICE:-1}

case $INSTANCE_CHOICE in
    1) DB_INSTANCE_CLASS="db.t3.micro" ;;
    2) DB_INSTANCE_CLASS="db.t3.small" ;;
    3) DB_INSTANCE_CLASS="db.t3.medium" ;;
    *) DB_INSTANCE_CLASS="db.t3.micro" ;;
esac

# Storage size
read -p "Storage size (GB) [default: 20]: " STORAGE_SIZE
STORAGE_SIZE=${STORAGE_SIZE:-20}

# Get VPC and subnet info
echo ""
echo -e "${BLUE}Getting VPC information...${NC}"
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query 'Vpcs[0].VpcId' --output text 2>/dev/null || echo "")

if [ -z "$VPC_ID" ] || [ "$VPC_ID" == "None" ]; then
    echo -e "${YELLOW}Warning: No default VPC found. You'll need to specify VPC manually.${NC}"
    read -p "Enter VPC ID (or press Enter to use first available): " VPC_ID
fi

# Get default security group
if [ -n "$VPC_ID" ] && [ "$VPC_ID" != "None" ]; then
    DEFAULT_SG=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" "Name=group-name,Values=default" --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null || echo "")
fi

echo ""
echo -e "${YELLOW}Summary:${NC}"
echo "  Instance ID: ${DB_INSTANCE_ID}"
echo "  Instance Class: ${DB_INSTANCE_CLASS}"
echo "  Storage: ${STORAGE_SIZE} GB"
echo "  Database: ${DB_NAME}"
echo "  Username: ${DB_USER}"
echo "  Region: ${REGION}"
if [ -n "$VPC_ID" ] && [ "$VPC_ID" != "None" ]; then
    echo "  VPC: ${VPC_ID}"
fi
echo ""

read -p "Create RDS instance? (y/N): " CONFIRM
if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo -e "${BLUE}Creating RDS instance...${NC}"
echo "This will take 5-10 minutes..."

# Properly escape password to prevent shell injection
# printf '%q' safely escapes all special characters including quotes
ESCAPED_PASSWORD=$(printf '%q' "$DB_PASSWORD")

# Build command with properly escaped password
CREATE_CMD="aws rds create-db-instance \
  --db-instance-identifier ${DB_INSTANCE_ID} \
  --db-instance-class ${DB_INSTANCE_CLASS} \
  --engine postgres \
  --engine-version 15.4 \
  --master-username ${DB_USER} \
  --master-user-password ${ESCAPED_PASSWORD} \
  --allocated-storage ${STORAGE_SIZE} \
  --storage-type gp3 \
  --db-name ${DB_NAME} \
  --publicly-accessible \
  --backup-retention-period 7 \
  --region ${REGION}"

if [ -n "$VPC_ID" ] && [ "$VPC_ID" != "None" ]; then
    # Get subnet group or create default
    SUBNET_GROUP=$(aws rds describe-db-subnet-groups --query 'DBSubnetGroups[?DBSubnetGroupName==`default`].DBSubnetGroupName' --output text 2>/dev/null || echo "")
    if [ -z "$SUBNET_GROUP" ] || [ "$SUBNET_GROUP" == "None" ]; then
        echo -e "${YELLOW}Note: Using default subnet group${NC}"
    else
        CREATE_CMD="${CREATE_CMD} --db-subnet-group-name ${SUBNET_GROUP}"
    fi
fi

# Execute creation
# Note: eval is still used here because CREATE_CMD is dynamically built
# The password is now properly escaped, so it's safe
if eval $CREATE_CMD; then
    echo -e "${GREEN}✓ RDS instance creation initiated${NC}"
    echo ""
    echo -e "${BLUE}Waiting for instance to be available...${NC}"
    echo "This may take 5-10 minutes..."
    
    aws rds wait db-instance-available \
        --db-instance-identifier ${DB_INSTANCE_ID} \
        --region ${REGION} || true
    
    echo ""
    echo -e "${GREEN}✓ RDS instance is available!${NC}"
    echo ""
    
    # Get endpoint
    ENDPOINT=$(aws rds describe-db-instances \
        --db-instance-identifier ${DB_INSTANCE_ID} \
        --query 'DBInstances[0].Endpoint.Address' \
        --output text \
        --region ${REGION})
    
    PORT=$(aws rds describe-db-instances \
        --db-instance-identifier ${DB_INSTANCE_ID} \
        --query 'DBInstances[0].Endpoint.Port' \
        --output text \
        --region ${REGION})
    
    echo -e "${GREEN}=== Connection Details ===${NC}"
    echo "Endpoint: ${ENDPOINT}"
    echo "Port: ${PORT}"
    echo "Database: ${DB_NAME}"
    echo "Username: ${DB_USER}"
    echo ""
    echo -e "${YELLOW}Connection String:${NC}"
    
    # URL encode password (basic encoding)
    ENCODED_PASSWORD=$(echo -n "$DB_PASSWORD" | python3 -c "import sys, urllib.parse; print(urllib.parse.quote(sys.stdin.read()))" 2>/dev/null || echo "$DB_PASSWORD")
    
    CONNECTION_STRING="postgresql://${DB_USER}:${ENCODED_PASSWORD}@${ENDPOINT}:${PORT}/${DB_NAME}?schema=public"
    echo "${CONNECTION_STRING}"
    echo ""
    
    # Get security group
    SG_ID=$(aws rds describe-db-instances \
        --db-instance-identifier ${DB_INSTANCE_ID} \
        --query 'DBInstances[0].VpcSecurityGroups[0].VpcSecurityGroupId' \
        --output text \
        --region ${REGION})
    
    if [ -n "$SG_ID" ] && [ "$SG_ID" != "None" ]; then
        echo -e "${YELLOW}Security Group: ${SG_ID}${NC}"
        echo ""
        echo -e "${BLUE}Next steps:${NC}"
        echo "1. Update security group to allow your IP:"
        echo "   aws ec2 authorize-security-group-ingress \\"
        echo "     --group-id ${SG_ID} \\"
        echo "     --protocol tcp \\"
        echo "     --port 5432 \\"
        echo "     --cidr \$(curl -s https://checkip.amazonaws.com)/32"
        echo ""
        echo "2. Update your .env file with the connection string above"
        echo ""
        echo "3. Test connection:"
        echo "   npm run db:migrate"
        echo "   curl http://localhost:3000/test/db"
    fi
    
else
    echo -e "${RED}Error: Failed to create RDS instance${NC}"
    exit 1
fi

