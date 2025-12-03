# Terraform Infrastructure as Code

This directory contains Terraform configuration for provisioning AWS infrastructure for the Mock Fitband API.

## What It Creates

- **EC2 Instance**: Ubuntu server with Docker pre-installed
- **RDS PostgreSQL**: Managed database instance
- **Security Groups**: For EC2 and RDS with proper rules
- **Key Pair**: SSH access to EC2
- **Elastic IP**: Optional static IP address

## Prerequisites

1. **Install Terraform**
   ```bash
   # macOS
   brew install terraform
   
   # Or download from: https://www.terraform.io/downloads
   ```

2. **Configure AWS Credentials**
   ```bash
   aws configure
   # Enter: AWS Access Key ID, Secret Access Key, Region, Output format
   ```

3. **Generate SSH Key Pair** (if you don't have one)
   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/mock-fitband-api-key
   ```

## Quick Start

1. **Copy example variables file**
   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Edit terraform.tfvars**
   - Add your SSH public key
   - Set RDS password
   - Adjust instance types if needed
   - Restrict SSH access (change `ssh_allowed_cidrs`)

3. **Initialize Terraform**
   ```bash
   terraform init
   ```

4. **Review what will be created**
   ```bash
   terraform plan
   ```

5. **Create infrastructure**
   ```bash
   terraform apply
   ```

6. **Get outputs** (connection details)
   ```bash
   terraform output
   ```

## Common Commands

```bash
# Initialize Terraform
terraform init

# Plan changes
terraform plan

# Apply changes
terraform apply

# Destroy infrastructure
terraform destroy

# Show outputs
terraform output

# Show specific output
terraform output ec2_public_ip
terraform output database_url
```

## Environment-Specific Deployments

### Development
```bash
terraform workspace new dev
terraform workspace select dev
terraform apply -var-file=dev.tfvars
```

### Production
```bash
terraform workspace new production
terraform workspace select production
terraform apply -var-file=production.tfvars
```

## Outputs

After `terraform apply`, you'll get:

- `ec2_public_ip`: EC2 instance IP address
- `ec2_elastic_ip`: Elastic IP (if allocated)
- `ssh_command`: Ready-to-use SSH command
- `rds_endpoint`: RDS database endpoint
- `database_url`: PostgreSQL connection string template

## Updating Infrastructure

```bash
# Make changes to .tf files
# Review changes
terraform plan

# Apply changes
terraform apply
```

## Destroying Infrastructure

⚠️ **Warning**: This will delete all resources!

```bash
terraform destroy
```

## Security Best Practices

1. **Never commit terraform.tfvars** (already in .gitignore)
2. **Restrict SSH access** in production:
   ```hcl
   ssh_allowed_cidrs = ["YOUR_IP/32"]
   ```
3. **Use strong RDS passwords**
4. **Enable RDS encryption** (already enabled)
5. **Use S3 backend** for state in production (uncomment in main.tf)

## Cost Estimation

- **t3.micro EC2**: ~$7-10/month
- **db.t3.micro RDS**: ~$15/month (after free tier)
- **Storage**: ~$0.10/GB/month
- **Data Transfer**: First 1GB free, then $0.09/GB

## Troubleshooting

### Terraform can't find AWS credentials
```bash
aws configure
# Or set environment variables:
export AWS_ACCESS_KEY_ID=your-key
export AWS_SECRET_ACCESS_KEY=your-secret
```

### SSH key already exists
```bash
# Delete existing key pair in AWS Console or:
aws ec2 delete-key-pair --key-name mock-fitband-api-key-dev
```

### RDS creation fails
- Check if you're in free tier limits
- Verify subnet group has subnets in different AZs
- Check security group rules

## Next Steps After Terraform

1. **SSH into EC2**
   ```bash
   terraform output -raw ssh_command
   ```

2. **Clone your repository**
   ```bash
   git clone <your-repo> /home/ubuntu/mock-fitband-api
   ```

3. **Create .env.prod file** with database URL from outputs

4. **Deploy application**
   ```bash
   cd /home/ubuntu/mock-fitband-api
   sudo docker-compose -f docker-compose.prod.yml --env-file .env.prod up -d --build
   ```

## Migration from Bash Scripts

If you were using the bash scripts:

1. **Export existing infrastructure** (optional):
   ```bash
   terraform import aws_instance.app i-1234567890abcdef0
   terraform import aws_db_instance.main mock-fitband-db
   ```

2. **Or destroy old and recreate** (recommended for clean state):
   ```bash
   # Delete old resources manually or via AWS Console
   # Then use Terraform to create new ones
   ```

## State Management

For production, use S3 backend (uncomment in main.tf):

```hcl
backend "s3" {
  bucket = "your-terraform-state-bucket"
  key    = "mock-fitband-api/terraform.tfstate"
  region = "us-east-1"
}
```

This enables:
- Team collaboration
- State locking
- State history
- Remote state access

