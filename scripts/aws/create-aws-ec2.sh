#!/bin/bash
# Create AWS EC2 instance for Mock Fitband API

set -e

# Configuration
KEY_NAME="${AWS_KEY_NAME:-mock-fitband-api-key}"
SG_NAME="mock-fitband-api-sg"
INSTANCE_NAME="mock-fitband-api"
INSTANCE_TYPE="${INSTANCE_TYPE:-t3.micro}"
REGION="${AWS_REGION:-us-east-1}"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=== Creating AWS EC2 Instance ===${NC}"
echo ""

# Check AWS credentials
if ! aws sts get-caller-identity &>/dev/null; then
  echo -e "${RED}Error: AWS credentials not configured${NC}"
  echo "Run: aws configure"
  exit 1
fi

# Get latest Ubuntu AMI
echo -e "${BLUE}Getting latest Ubuntu 22.04 AMI...${NC}"
AMI_ID=$(aws ec2 describe-images \
  --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" \
            "Name=state,Values=available" \
  --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
  --output text \
  --region ${REGION})

if [ -z "$AMI_ID" ] || [ "$AMI_ID" == "None" ]; then
  echo -e "${RED}Error: Could not find Ubuntu AMI${NC}"
  exit 1
fi

echo -e "${GREEN}Using AMI: ${AMI_ID}${NC}"
echo ""

# Check if key pair exists, create if not
echo -e "${BLUE}Checking key pair...${NC}"
if ! aws ec2 describe-key-pairs --key-names ${KEY_NAME} &>/dev/null; then
  echo -e "${YELLOW}Creating key pair: ${KEY_NAME}${NC}"
  aws ec2 create-key-pair \
    --key-name ${KEY_NAME} \
    --query 'KeyMaterial' \
    --output text > ~/.ssh/${KEY_NAME}.pem
  chmod 400 ~/.ssh/${KEY_NAME}.pem
  echo -e "${GREEN}✓ Key pair created and saved to ~/.ssh/${KEY_NAME}.pem${NC}"
else
  echo -e "${GREEN}✓ Key pair already exists${NC}"
fi
echo ""

# Create security group
echo -e "${BLUE}Creating security group...${NC}"
SG_ID=$(aws ec2 create-security-group \
  --group-name ${SG_NAME} \
  --description "Security group for Mock Fitband API" \
  --query 'GroupId' \
  --output text 2>/dev/null || \
  aws ec2 describe-security-groups \
    --group-names ${SG_NAME} \
    --query 'SecurityGroups[0].GroupId' \
    --output text)

echo -e "${GREEN}Security Group ID: ${SG_ID}${NC}"

# Add rules
echo -e "${BLUE}Configuring security group rules...${NC}"

# SSH
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0 2>/dev/null || echo "SSH rule already exists"

# HTTP
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0 2>/dev/null || echo "HTTP rule already exists"

# HTTPS
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 443 \
  --cidr 0.0.0.0/0 2>/dev/null || echo "HTTPS rule already exists"

# App port
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 8080 \
  --cidr 0.0.0.0/0 2>/dev/null || echo "App port rule already exists"

echo -e "${GREEN}✓ Security group configured${NC}"
echo ""

# Check if user data script exists
USER_DATA_FILE="scripts/ec2-user-data.sh"
if [ ! -f "$USER_DATA_FILE" ]; then
  echo -e "${YELLOW}Warning: User data script not found at ${USER_DATA_FILE}${NC}"
  USER_DATA=""
else
  USER_DATA="file://${USER_DATA_FILE}"
fi

# Launch instance
echo -e "${BLUE}Launching EC2 instance...${NC}"
echo "  Instance Type: ${INSTANCE_TYPE}"
echo "  AMI: ${AMI_ID}"
echo "  Key: ${KEY_NAME}"
echo "  Security Group: ${SG_ID}"
echo ""

INSTANCE_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type ${INSTANCE_TYPE} \
  --key-name ${KEY_NAME} \
  --security-group-ids $SG_ID \
  ${USER_DATA:+--user-data $USER_DATA} \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${INSTANCE_NAME}}]" \
  --query 'Instances[0].InstanceId' \
  --output text \
  --region ${REGION})

echo -e "${GREEN}✓ Instance created: ${INSTANCE_ID}${NC}"
echo ""

# Wait for instance to be running
echo -e "${BLUE}Waiting for instance to be running...${NC}"
aws ec2 wait instance-running --instance-ids $INSTANCE_ID --region ${REGION}
echo -e "${GREEN}✓ Instance is running${NC}"
echo ""

# Get public IP
echo -e "${BLUE}Getting instance details...${NC}"
PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text \
  --region ${REGION})

echo ""
echo -e "${GREEN}=== Instance Ready ===${NC}"
echo "Instance ID: ${INSTANCE_ID}"
echo "Public IP: ${PUBLIC_IP}"
echo "SSH Key: ~/.ssh/${KEY_NAME}.pem"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Wait 2-3 minutes for Docker installation to complete"
echo "2. SSH into instance:"
echo "   ssh -i ~/.ssh/${KEY_NAME}.pem ubuntu@${PUBLIC_IP}"
echo ""
echo "3. Clone or copy your application:"
echo "   git clone <your-repo> /home/ubuntu/mock-fitband-api"
echo ""
echo "4. Configure .env.prod with your database URL"
echo ""
echo "5. Deploy:"
echo "   cd /home/ubuntu/mock-fitband-api"
echo "   sudo docker-compose -f docker-compose.prod.yml --env-file .env.prod up -d --build"
echo ""
echo "Or use the deploy script:"
echo "   ./scripts/deploy-to-aws.sh"

