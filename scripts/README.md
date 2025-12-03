# Scripts

This directory contains utility scripts organized by category.

## Structure

```
scripts/
├── aws/                 # AWS-specific scripts
│   ├── create-aws-ec2.sh           # Create EC2 instance
│   ├── setup-aws-rds.sh            # Setup RDS database
│   ├── add-ec2-to-db-whitelist.sh  # Add EC2 IP to DB whitelist
│   ├── get-ec2-ip.sh               # Get EC2 instance IP
│   └── ec2-user-data.sh            # EC2 user data script
│
├── deployment/          # Deployment scripts
│   ├── deploy-to-aws.sh            # Deploy app to AWS EC2
│   ├── setup-https-duckdns.sh      # Setup HTTPS with DuckDNS
│   └── update-duckdns.sh           # Update DuckDNS IP
│
└── utils/              # Utility scripts
    ├── troubleshoot-dns.sh         # DNS troubleshooting
    └── wait-for-db.js              # Wait for database connection
```

## Usage

### AWS Scripts

```bash
# Create EC2 instance
./scripts/aws/create-aws-ec2.sh

# Get EC2 IP
./scripts/aws/get-ec2-ip.sh

# Add EC2 to database whitelist
DB_SECURITY_GROUP_ID=sg-xxx ./scripts/aws/add-ec2-to-db-whitelist.sh
```

### Deployment Scripts

```bash
# Deploy to AWS
./scripts/deployment/deploy-to-aws.sh

# Setup HTTPS
./scripts/deployment/setup-https-duckdns.sh

# Update DuckDNS IP
DUCKDNS_TOKEN=xxx DUCKDNS_SUBDOMAIN=xxx ./scripts/deployment/update-duckdns.sh
```

### Utility Scripts

```bash
# Troubleshoot DNS
./scripts/utils/troubleshoot-dns.sh your-domain.com
```

