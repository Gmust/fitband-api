# Azure VM Quick Start Guide

Follow these steps to deploy on Azure VM.

## Step 1: Create Azure VM

### Option A: Using Azure Portal
1. Go to [Azure Portal](https://portal.azure.com)
2. Click "Create a resource" → "Virtual Machine"
3. Configure:
   - **Resource Group**: Create new or use existing
   - **VM Name**: `mock-fitband-api-vm`
   - **Region**: Choose closest to your users
   - **Image**: Ubuntu Server 22.04 LTS (or 20.04)
   - **Size**: 
     - Minimum: Standard_B2s (2 vCPU, 4GB RAM)
     - Recommended: Standard_B2ms (2 vCPU, 8GB RAM)
   - **Authentication**: SSH public key (recommended) or password
   - **Public inbound ports**: Allow SSH (22)
4. Review and create

### Option B: Using Azure CLI
```bash
# Login to Azure
az login

# Set variables
RESOURCE_GROUP="mock-fitband-rg"
VM_NAME="mock-fitband-api-vm"
LOCATION="polandcentral" 
VM_SIZE="Standard_B1s"

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create VM
az vm create \
  --resource-group $RESOURCE_GROUP \
  --name $VM_NAME \
  --image Ubuntu2204 \
  --size $VM_SIZE \
  --admin-username azureuser \
  --generate-ssh-keys \
  --public-ip-sku Standard

# Open port 80 and 443
az vm open-port --port 80 --resource-group $RESOURCE_GROUP --name $VM_NAME
az vm open-port --port 443 --resource-group $RESOURCE_GROUP --name $VM_NAME
```

## Step 2: Get VM IP Address

```bash
# Using Azure CLI
az vm show -d -g $RESOURCE_GROUP -n $VM_NAME --query publicIps -o tsv

# Or check in Azure Portal → Virtual Machines → Your VM → Overview → Public IP address
```

## Step 3: SSH into VM

```bash
# Replace with your actual IP and username
ssh azureuser@<YOUR_VM_IP>
```

## Step 4: Run Initial Setup

Once connected to the VM:

```bash
# Update system (if needed)
sudo apt-get update && sudo apt-get upgrade -y

# Create app directory
sudo mkdir -p /opt/mock-fitband-api
sudo chown $USER:$USER /opt/mock-fitband-api
cd /opt/mock-fitband-api
```

## Step 5: Copy Application Files

### Option A: Using Git (Recommended)
```bash
cd /opt/mock-fitband-api
git clone <your-repo-url> .
```

### Option B: Using SCP from your local machine
```bash
# From your local machine terminal
scp -r . azureuser@<YOUR_VM_IP>:/opt/mock-fitband-api/
```

### Option C: Manual Upload
Upload files via Azure Portal or use `scp`/`rsync`

## Step 6: Run Setup Script

```bash
cd /opt/mock-fitband-api
chmod +x scripts/*.sh
sudo bash scripts/setup-azure-vm.sh
```

This installs:
- Docker
- Docker Compose
- Firewall configuration

## Step 7: Configure Environment

```bash
cd /opt/mock-fitband-api
cp env.prod.example .env.prod
nano .env.prod
```

**IMPORTANT**: Update these values:

```env
# Generate strong password (run on VM: openssl rand -base64 32)
POSTGRES_PASSWORD=your-very-strong-password-here

# Generate secrets
JWT_SECRET=your-jwt-secret-here
API_KEY=your-api-key-here

# Your domain or VM public IP
CORS_ORIGIN=https://your-domain.com,http://<YOUR_VM_IP>

# Keep these defaults unless you have specific needs
POSTGRES_DB=mock_fitband_db
POSTGRES_USER=postgres
NODE_ENV=production
PORT=8080
APP_PORT=8080
RUN_MIGRATIONS=true
```

## Step 8: Deploy

```bash
./scripts/deploy.sh
```

This will:
- Build Docker images
- Start containers (app + database)
- Run migrations
- Show service status

## Step 9: Verify Deployment

```bash
# Check container status
docker-compose -f docker-compose.prod.yml --env-file .env.prod ps

# Check logs
docker-compose -f docker-compose.prod.yml --env-file .env.prod logs -f

# Test API (from VM)
curl http://localhost:8080/health

# Test API from outside (from your local machine)
curl http://<YOUR_VM_IP>:8080/health
```

## Step 10: Configure Auto-Start (Optional)

To start services automatically on VM reboot:

```bash
sudo nano /etc/systemd/system/mock-fitband-api.service
```

Paste:
```ini
[Unit]
Description=Mock Fitband API Docker Compose
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/mock-fitband-api
ExecStart=/usr/bin/docker compose -f docker-compose.prod.yml --env-file .env.prod up -d
ExecStop=/usr/bin/docker compose -f docker-compose.prod.yml --env-file .env.prod down
TimeoutStartSec=0
User=$USER
Group=$USER

[Install]
WantedBy=multi-user.target
```

Replace `$USER` with your actual username, then:

```bash
sudo systemctl daemon-reload
sudo systemctl enable mock-fitband-api
sudo systemctl start mock-fitband-api
```

## Troubleshooting

### Can't connect to VM
- Check Network Security Group (NSG) rules allow SSH (port 22)
- Verify VM is running in Azure Portal

### Port 8080 not accessible
- Check NSG allows port 80/443 (if using reverse proxy)
- Or allow port 8080 directly in NSG
- Verify firewall on VM: `sudo ufw status`

### Containers won't start
```bash
# Check logs
docker-compose -f docker-compose.prod.yml --env-file .env.prod logs

# Check Docker status
sudo systemctl status docker
```

### Database connection errors
```bash
# Verify database container is running
docker-compose -f docker-compose.prod.yml --env-file .env.prod ps db

# Check database logs
docker-compose -f docker-compose.prod.yml --env-file .env.prod logs db

# Test connection manually
docker-compose -f docker-compose.prod.yml --env-file .env.prod exec db psql -U postgres -d mock_fitband_db
```

## Next Steps

1. **Set up domain** (optional): Point your domain to VM's public IP
2. **Configure SSL**: Set up Let's Encrypt certificate
3. **Set up monitoring**: Configure Azure Monitor or similar
4. **Backup strategy**: Schedule regular database backups
5. **Update regularly**: Keep system and Docker images updated

## Useful Commands

```bash
# View logs
docker-compose -f docker-compose.prod.yml --env-file .env.prod logs -f app

# Restart services
docker-compose -f docker-compose.prod.yml --env-file .env.prod restart

# Stop services
docker-compose -f docker-compose.prod.yml --env-file .env.prod down

# Update application
git pull
./scripts/deploy.sh

# Database backup
docker-compose -f docker-compose.prod.yml --env-file .env.prod exec db pg_dump -U postgres mock_fitband_db > backup.sql
```

## Security Checklist

- [ ] Changed default passwords in `.env.prod`
- [ ] Using SSH keys (not passwords) for VM access
- [ ] Firewall configured (only ports 22, 80, 443 open)
- [ ] Database port (5432) NOT exposed externally
- [ ] Regular backups configured
- [ ] SSL/TLS configured (if using domain)
- [ ] `.env.prod` file permissions: `chmod 600 .env.prod`

