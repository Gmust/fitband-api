# AWS RDS PostgreSQL Setup Guide

This guide explains how to set up AWS RDS PostgreSQL for the Mock Fitband API.

## Prerequisites

- AWS account with appropriate permissions
- AWS CLI installed and configured (optional, but recommended)
- Basic understanding of AWS RDS

## Option 1: AWS Console (Web UI) - Recommended for First Time

### Step 1: Create RDS Instance

1. **Login to AWS Console**
   - Go to https://console.aws.amazon.com
   - Navigate to **RDS** service

2. **Create Database**
   - Click **"Create database"**
   - Choose **"Standard create"**
   - Engine: **PostgreSQL**
   - Version: **15.x** (or latest compatible)

3. **Templates**
   - For development/testing: **"Free tier"** (if eligible)
   - For production: **"Production"**

4. **Settings**
   - **DB instance identifier**: `mock-fitband-db`
   - **Master username**: `postgres` (or your preferred username)
   - **Master password**: Generate a strong password (save it securely!)
   - **Confirm password**: Re-enter the password

5. **Instance Configuration**
   - **DB instance class**: 
     - Free tier: `db.t3.micro` (1 vCPU, 1GB RAM)
     - Production: `db.t3.small` (2 vCPU, 2GB RAM) or larger
   - **Storage**: 
     - Type: `General Purpose SSD (gp3)`
     - Allocated storage: `20 GB` (minimum, increase for production)

6. **Connectivity**
   - **VPC**: Use default VPC or create new
   - **Public access**: **Yes** (for external connections)
   - **VPC security group**: Create new or use existing
   - **Availability Zone**: Leave default
   - **DB port**: `5432` (default PostgreSQL port)

7. **Database Authentication**
   - **Password authentication** (default)

8. **Additional Configuration** (optional)
   - **Initial database name**: `mock_fitband_db`
   - **Backup retention**: `7 days` (production) or `1 day` (dev)
   - **Backup window**: Leave default
   - **Enable encryption**: Recommended for production

9. **Monitoring** (optional)
   - **Enable Enhanced monitoring**: Off (for cost savings)
   - **Enable Performance Insights**: Off (for cost savings)

10. **Create Database**
    - Click **"Create database"**
    - Wait 5-10 minutes for instance to be available

### Step 2: Configure Security Group

1. **Find your RDS instance**
   - Go to RDS dashboard
   - Click on your database instance
   - Note the **Security group** name

2. **Edit Security Group Rules**
   - Click on the security group link
   - Click **"Edit inbound rules"**
   - Click **"Add rule"**
   - **Type**: PostgreSQL
   - **Port**: 5432
   - **Source**: 
     - For testing: `0.0.0.0/0` (allows from anywhere - **NOT secure for production**)
     - For production: Your application server's IP or security group
   - Click **"Save rules"**

### Step 3: Get Connection Details

1. **Find Endpoint**
   - In RDS dashboard, click your database
   - Copy the **Endpoint** (e.g., `mock-fitband-db.xxxxx.us-east-1.rds.amazonaws.com`)
   - Note the **Port** (usually 5432)

2. **Connection String Format**
   ```
   postgresql://[username]:[password]@[endpoint]:[port]/[database]?schema=public
   ```

   Example:
   ```
   postgresql://postgres:YourPassword123@mock-fitband-db.xxxxx.us-east-1.rds.amazonaws.com:5432/mock_fitband_db?schema=public
   ```

## Option 2: AWS CLI (Command Line)

### Prerequisites
```bash
# Install AWS CLI (if not installed)
# macOS:
brew install awscli

# Or download from: https://aws.amazon.com/cli/

# Configure AWS credentials
aws configure
# Enter: AWS Access Key ID, Secret Access Key, Region, Output format
```

### Create RDS Instance via CLI

```bash
# Create RDS instance
aws rds create-db-instance \
  --db-instance-identifier mock-fitband-db \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --engine-version 15.4 \
  --master-username postgres \
  --master-user-password YourSecurePassword123! \
  --allocated-storage 20 \
  --storage-type gp3 \
  --db-name mock_fitband_db \
  --vpc-security-group-ids sg-xxxxxxxxx \
  --publicly-accessible \
  --backup-retention-period 7 \
  --region us-east-1

# Wait for instance to be available (takes 5-10 minutes)
aws rds wait db-instance-available --db-instance-identifier mock-fitband-db

# Get endpoint
aws rds describe-db-instances \
  --db-instance-identifier mock-fitband-db \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text
```

### Configure Security Group

```bash
# Get your IP address
MY_IP=$(curl -s https://checkip.amazonaws.com)

# Add inbound rule to security group
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxxxxxx \
  --protocol tcp \
  --port 5432 \
  --cidr ${MY_IP}/32

# Or allow from anywhere (NOT recommended for production)
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxxxxxx \
  --protocol tcp \
  --port 5432 \
  --cidr 0.0.0.0/0
```

## Step 4: Update Your Application

### Update .env File

```env
# AWS RDS Database Configuration
DATABASE_URL=postgresql://postgres:YourPassword123@mock-fitband-db.xxxxx.us-east-1.rds.amazonaws.com:5432/mock_fitband_db?schema=public

# URL encode special characters in password if needed
# Example: password with @ becomes %40
```

**Important**: If your password contains special characters, URL encode them:
- `@` → `%40`
- `#` → `%23`
- `$` → `%24`
- `%` → `%25`
- `&` → `%26`
- `/` → `%2F`
- `:` → `%3A`
- `?` → `%3F`
- `=` → `%3D`

### Test Connection

```bash
# Test database connection
npm run db:migrate

# Or test with the test routes
curl http://localhost:3000/test/db
curl -X POST http://localhost:3000/test/db
```

## Step 5: Run Migrations

Once connected, run migrations to create tables:

```bash
# Generate Prisma client
npm run db:generate

# Run migrations
npm run migrate:deploy

# Or for development
npm run migrate:dev
```

## Security Best Practices

### For Production:

1. **Use VPC Security Groups**
   - Only allow connections from your application servers
   - Use security group rules instead of IP addresses

2. **Enable SSL/TLS**
   - Add `?sslmode=require` to connection string:
   ```
   DATABASE_URL=postgresql://user:pass@endpoint:5432/db?schema=public&sslmode=require
   ```

3. **Use IAM Database Authentication** (Advanced)
   - More secure than password authentication
   - Requires additional setup

4. **Enable Encryption at Rest**
   - Check "Enable encryption" when creating RDS instance

5. **Regular Backups**
   - Enable automated backups
   - Test restore procedures

6. **Network Isolation**
   - Use private subnets for RDS
   - Use bastion host or VPN for access

## Cost Optimization

### Free Tier (12 months)
- `db.t3.micro` instance
- 20 GB storage
- 750 hours/month

### After Free Tier
- **Development**: `db.t3.micro` (~$15/month)
- **Production**: `db.t3.small` (~$30/month) or larger based on load

### Cost Saving Tips
1. Use reserved instances for production (save up to 40%)
2. Stop instances when not in use (dev/test)
3. Use smaller instance sizes when possible
4. Monitor storage usage

## Troubleshooting

### Connection Timeout
- Check security group allows your IP
- Verify RDS instance is publicly accessible
- Check VPC route tables

### Authentication Failed
- Verify username/password
- Check password encoding in connection string
- Ensure database name is correct

### SSL Required
- Add `?sslmode=require` to connection string
- Or use `?sslmode=prefer` for optional SSL

### Migration Errors
- Ensure database exists
- Check user has CREATE privileges
- Verify connection string is correct

## Next Steps

After setting up RDS:

1. ✅ Update `.env` with RDS connection string
2. ✅ Test connection with `/test/db` routes
3. ✅ Run migrations: `npm run migrate:deploy`
4. ✅ Update production configs if needed
5. ✅ Set up monitoring and alerts

## Useful AWS CLI Commands

```bash
# List all RDS instances
aws rds describe-db-instances

# Get connection endpoint
aws rds describe-db-instances \
  --db-instance-identifier mock-fitband-db \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text

# Check instance status
aws rds describe-db-instances \
  --db-instance-identifier mock-fitband-db \
  --query 'DBInstances[0].DBInstanceStatus' \
  --output text

# Modify instance (e.g., change instance class)
aws rds modify-db-instance \
  --db-instance-identifier mock-fitband-db \
  --db-instance-class db.t3.small \
  --apply-immediately

# Create snapshot
aws rds create-db-snapshot \
  --db-instance-identifier mock-fitband-db \
  --db-snapshot-identifier mock-fitband-snapshot-$(date +%Y%m%d)
```

