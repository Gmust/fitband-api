# AWS REST API Deployment Guide (CLI)

This guide shows how to deploy the Mock Fitband REST API to AWS EC2 using CLI commands.

## Architecture

- **EC2 Instance**: Runs NestJS REST API (Docker container)
- **Existing Database**: Your cloud database (already configured)
- **Security Group**: Allows HTTP/HTTPS traffic

## Prerequisites

- AWS CLI installed and configured
- Existing database connection string
- SSH key pair for EC2 access

## Step 1: Create EC2 Instance

### Create Key Pair (if you don't have one)

```bash
# Create key pair
aws ec2 create-key-pair \
  --key-name mock-fitband-api-key \
  --query 'KeyMaterial' \
  --output text > ~/.ssh/mock-fitband-api-key.pem

# Set permissions
chmod 400 ~/.ssh/mock-fitband-api-key.pem
```

### Get Latest Ubuntu AMI

```bash
# Get latest Ubuntu 22.04 LTS AMI
AMI_ID=$(aws ec2 describe-images \
  --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" \
            "Name=state,Values=available" \
  --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
  --output text \
  --region us-east-1)

echo "Using AMI: $AMI_ID"
```

### Create Security Group

```bash
# Create security group
SG_ID=$(aws ec2 create-security-group \
  --group-name mock-fitband-api-sg \
  --description "Security group for Mock Fitband API" \
  --query 'GroupId' \
  --output text)

echo "Security Group ID: $SG_ID"

# Allow SSH (port 22)
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0

# Allow HTTP (port 80)
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0

# Allow HTTPS (port 443)
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 443 \
  --cidr 0.0.0.0/0

# Allow app port (8080) - optional, if not using nginx
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 8080 \
  --cidr 0.0.0.0/0
```

### Launch EC2 Instance

```bash
# Launch instance
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type t3.micro \
  --key-name mock-fitband-api-key \
  --security-group-ids $SG_ID \
  --user-data file://scripts/ec2-user-data.sh \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=mock-fitband-api}]' \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "Instance ID: $INSTANCE_ID"

# Wait for instance to be running
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

# Get public IP
PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

echo "Public IP: $PUBLIC_IP"
```

## Step 2: Create User Data Script

Create `scripts/ec2-user-data.sh`:

```bash
#!/bin/bash
# EC2 User Data Script - Installs Docker and Docker Compose

set -e

# Update system
apt-get update -y
apt-get upgrade -y

# Install Docker
apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Install Docker Compose standalone (if needed)
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Start Docker
systemctl start docker
systemctl enable docker

# Add ubuntu user to docker group
usermod -aG docker ubuntu

# Install Git
apt-get install -y git

# Create app directory
mkdir -p /home/ubuntu/mock-fitband-api
chown ubuntu:ubuntu /home/ubuntu/mock-fitband-api
```

## Step 3: Deploy Application

### Copy Files to EC2

```bash
# From your local machine
scp -i ~/.ssh/mock-fitband-api-key.pem \
  -r . ubuntu@$PUBLIC_IP:/home/ubuntu/mock-fitband-api/

# Or clone from Git (recommended)
ssh -i ~/.ssh/mock-fitband-api-key.pem ubuntu@$PUBLIC_IP << 'EOF'
cd /home/ubuntu
git clone <your-repo-url> mock-fitband-api
cd mock-fitband-api
EOF
```

### Configure Environment

```bash
# SSH into instance
ssh -i ~/.ssh/mock-fitband-api-key.pem ubuntu@$PUBLIC_IP

# On the EC2 instance:
cd /home/ubuntu/mock-fitband-api

# Create .env.prod file
cat > .env.prod << 'ENVEOF'
NODE_ENV=production
PORT=8080
APP_PORT=8080

# Your existing database URL
DATABASE_URL=postgresql://user:password@your-db-host:5432/database?schema=public

# Security
JWT_SECRET=your-jwt-secret-here
API_KEY=your-api-key-here

# CORS
CORS_ORIGIN=https://your-domain.com,http://your-domain.com

# Logging
LOG_LEVEL=info

# Docker
RUN_MIGRATIONS=true
ENVEOF

# Edit with your actual values
nano .env.prod
```

### Build and Start

```bash
# On EC2 instance
cd /home/ubuntu/mock-fitband-api

# Build and start
sudo docker-compose -f docker-compose.prod.yml --env-file .env.prod up -d --build

# Check logs
sudo docker-compose -f docker-compose.prod.yml --env-file .env.prod logs -f

# Check status
sudo docker-compose -f docker-compose.prod.yml --env-file .env.prod ps
```

## Step 4: Add EC2 IP to Database Whitelist

### Get EC2 Instance IP

```bash
# Quick way - use the script
./scripts/get-ec2-ip.sh

# Or manually
INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=mock-fitband-api" "Name=instance-state-name,Values=running" \
  --query 'Reservations[0].Instances[0].InstanceId' \
  --output text)

PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

echo "EC2 Public IP: $PUBLIC_IP"
```

### Add IP to Database Whitelist

**Option 1: If your database is AWS RDS**

```bash
# Get RDS security group ID
DB_SG_ID=$(aws rds describe-db-instances \
  --db-instance-identifier your-db-name \
  --query 'DBInstances[0].VpcSecurityGroups[0].VpcSecurityGroupId' \
  --output text)

# Add EC2 IP to RDS security group
aws ec2 authorize-security-group-ingress \
  --group-id $DB_SG_ID \
  --protocol tcp \
  --port 5432 \
  --cidr ${PUBLIC_IP}/32
```

**Option 2: Use the automated script**

```bash
# Set your database security group ID
export DB_SECURITY_GROUP_ID=sg-xxxxxxxxx

# Run the script
./scripts/add-ec2-to-db-whitelist.sh
```

**Option 3: If your database is external (not AWS)**

1. Get the IP using `./scripts/get-ec2-ip.sh`
2. Copy the IP address
3. Add it to your database provider's whitelist:
   - **Azure Database**: Azure Portal → Firewall rules → Add client IP
   - **Google Cloud SQL**: Cloud Console → Connections → Authorized networks
   - **Other providers**: Check their documentation for IP whitelisting

### Verify Database Connection

```bash
# Test from EC2 instance
ssh -i ~/.ssh/mock-fitband-api-key.pem ubuntu@$PUBLIC_IP

# On EC2, test database connection
sudo docker-compose -f docker-compose.prod.yml --env-file .env.prod exec app \
  npx prisma db pull
```

## Step 5: Setup Nginx (Optional but Recommended)

```bash
# On EC2 instance
sudo apt-get update
sudo apt-get install -y nginx certbot python3-certbot-nginx

# Create nginx config
sudo nano /etc/nginx/sites-available/mock-fitband-api
```

Nginx config:
```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

```bash
# Enable site
sudo ln -s /etc/nginx/sites-available/mock-fitband-api /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# Setup SSL (if you have a domain)
sudo certbot --nginx -d your-domain.com
```

## Step 5: Run Migrations

```bash
# On EC2 instance
cd /home/ubuntu/mock-fitband-api

# Run migrations
sudo docker-compose -f docker-compose.prod.yml --env-file .env.prod exec app npx prisma migrate deploy
```

## Step 6: Test Deployment

```bash
# Test health endpoint
curl http://$PUBLIC_IP/health

# Test database connection
curl http://$PUBLIC_IP/test/db
```

## Useful AWS CLI Commands

### Instance Management

```bash
# List instances
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=mock-fitband-api" \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress]' \
  --output table

# Get instance IP
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=mock-fitband-api" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text

# Stop instance
aws ec2 stop-instances --instance-ids $INSTANCE_ID

# Start instance
aws ec2 start-instances --instance-ids $INSTANCE_ID

# Terminate instance
aws ec2 terminate-instances --instance-ids $INSTANCE_ID
```

### Security Group Management

```bash
# List security groups
aws ec2 describe-security-groups \
  --group-names mock-fitband-api-sg

# Add rule (allow your IP)
MY_IP=$(curl -s https://checkip.amazonaws.com)
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 22 \
  --cidr ${MY_IP}/32

# Remove rule
aws ec2 revoke-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0
```

### Logs and Monitoring

```bash
# View CloudWatch logs (if configured)
aws logs tail /aws/ec2/mock-fitband-api --follow

# Get instance status
aws ec2 describe-instance-status --instance-ids $INSTANCE_ID
```

## Quick Deploy Script

Create `scripts/deploy-to-aws.sh` for automated deployment:

```bash
#!/bin/bash
set -e

INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=mock-fitband-api" "Name=instance-state-name,Values=running" \
  --query 'Reservations[0].Instances[0].InstanceId' \
  --output text)

if [ -z "$INSTANCE_ID" ] || [ "$INSTANCE_ID" == "None" ]; then
  echo "No running instance found. Please create one first."
  exit 1
fi

PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

echo "Deploying to: $PUBLIC_IP"

# Copy files
rsync -avz -e "ssh -i ~/.ssh/mock-fitband-api-key.pem" \
  --exclude 'node_modules' \
  --exclude '.git' \
  --exclude 'dist' \
  ./ ubuntu@$PUBLIC_IP:/home/ubuntu/mock-fitband-api/

# Deploy
ssh -i ~/.ssh/mock-fitband-api-key.pem ubuntu@$PUBLIC_IP << 'EOF'
cd /home/ubuntu/mock-fitband-api
sudo docker-compose -f docker-compose.prod.yml --env-file .env.prod down
sudo docker-compose -f docker-compose.prod.yml --env-file .env.prod up -d --build
sudo docker-compose -f docker-compose.prod.yml --env-file .env.prod logs -f --tail=50
EOF
```

## Cost Estimation

- **t3.micro**: ~$7-10/month (Free tier eligible for 12 months)
- **t3.small**: ~$15/month
- **Data transfer**: First 1GB free, then $0.09/GB

## Troubleshooting

### Can't SSH to instance
- Check security group allows port 22
- Verify key pair permissions: `chmod 400 ~/.ssh/mock-fitband-api-key.pem`
- Check instance is running

### Application not accessible
- Check security group allows port 80/443/8080
- Check Docker containers are running: `sudo docker ps`
- Check logs: `sudo docker-compose logs`

### Database connection issues
- Verify DATABASE_URL in .env.prod
- Check database security group allows EC2 IP
- Test connection: `sudo docker-compose exec app npx prisma db pull`

## Next Steps

1. ✅ Set up domain name (Route 53 or external)
2. ✅ Configure SSL certificate (Let's Encrypt)
3. ✅ Set up monitoring (CloudWatch)
4. ✅ Configure auto-scaling (if needed)
5. ✅ Set up backups

