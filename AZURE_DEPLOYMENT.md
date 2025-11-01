# Azure VM Deployment Guide

This guide explains how to deploy the Mock Fitband API to a single Azure VM with both the application and database running as Docker containers.

## Architecture

The deployment runs on a **single Azure VM** with two Docker containers:
- **App Container**: NestJS application (port 8080)
- **Database Container**: PostgreSQL 15 (port 5432, internal only)

## Prerequisites

- Azure VM (Ubuntu 20.04+ or similar Linux distribution)
- SSH access to the VM
- Minimum 2 vCPUs, 4GB RAM, 20GB disk (8GB RAM recommended)

## Quick Start

### 1. Initial VM Setup

SSH into your Azure VM and run:

```bash
sudo bash scripts/setup-azure-vm.sh
```

This will install Docker and Docker Compose on your VM.

### 2. Copy Application Files

Copy the entire project to the VM:

```bash
# From your local machine
scp -r . user@your-vm-ip:/home/user/mock-fitband-api
```

Or clone from git on the VM:
```bash
# On the VM
cd /home/user
git clone <your-repo-url> mock-fitband-api
cd mock-fitband-api
```

### 3. Configure Environment Variables

```bash
cp env.prod.example .env.prod
nano .env.prod  # Edit with your actual values
```

**Important**: Update these values in `.env.prod`:
- `POSTGRES_PASSWORD`: Choose a strong, secure password
- `JWT_SECRET`: Generate a random secret string
- `API_KEY`: Your API key
- `CORS_ORIGIN`: Your frontend domain(s), comma-separated

Example `.env.prod`:
```env
POSTGRES_DB=mock_fitband_db
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your-secure-password-here
DATABASE_URL=postgresql://postgres:your-secure-password-here@db:5432/mock_fitband_db?schema=public
NODE_ENV=production
PORT=8080
APP_PORT=8080
RUN_MIGRATIONS=true
```

### 4. Deploy

```bash
chmod +x scripts/*.sh
./scripts/deploy.sh
```

The script will:
- Build the Docker images
- Start both containers (app and database)
- Run database migrations
- Wait for services to be healthy

### 5. Verify Deployment

Check that services are running:
```bash
docker-compose -f docker-compose.prod.yml --env-file .env.prod ps
```

Test the API:
```bash
curl http://localhost:8080/health
```

## Azure VM Configuration

### Network Security Group (NSG)

In Azure Portal, ensure your VM's NSG allows:
- **Port 22**: SSH access
- **Port 80**: HTTP (if using nginx/load balancer)
- **Port 443**: HTTPS (if using SSL)
- **Port 8080**: Application (optional, only if exposing directly)

The database port (5432) should **NOT** be exposed externally.

### VM Sizing Recommendations

**Minimum:**
- 2 vCPUs
- 4 GB RAM
- 20 GB SSD

**Recommended:**
- 4 vCPUs
- 8 GB RAM
- 50 GB SSD

## Common Operations

### View Logs

```bash
# All services
docker-compose -f docker-compose.prod.yml --env-file .env.prod logs -f

# App only
docker-compose -f docker-compose.prod.yml --env-file .env.prod logs -f app

# Database only
docker-compose -f docker-compose.prod.yml --env-file .env.prod logs -f db
```

### Restart Services

```bash
docker-compose -f docker-compose.prod.yml --env-file .env.prod restart
```

### Stop Services

```bash
docker-compose -f docker-compose.prod.yml --env-file .env.prod down
```

### Update Application

```bash
# Pull latest code
git pull

# Rebuild and redeploy
./scripts/deploy.sh
```

### Database Backup

```bash
# Create backup
docker-compose -f docker-compose.prod.yml --env-file .env.prod exec db pg_dump -U postgres mock_fitband_db > backup_$(date +%Y%m%d_%H%M%S).sql

# Backup the entire data volume
docker run --rm -v mock-fitband-api_postgres_data:/data -v $(pwd):/backup alpine tar czf /backup/postgres_backup_$(date +%Y%m%d_%H%M%S).tar.gz -C /data .
```

### Database Restore

```bash
# Restore from SQL dump
cat backup_file.sql | docker-compose -f docker-compose.prod.yml --env-file .env.prod exec -T db psql -U postgres mock_fitband_db

# Restore from volume backup
docker run --rm -v mock-fitband-api_postgres_data:/data -v $(pwd):/backup alpine sh -c "cd /data && tar xzf /backup/postgres_backup_file.tar.gz"
```

## Auto-Start on Boot

To automatically start services when the VM reboots, create a systemd service:

```bash
sudo nano /etc/systemd/system/mock-fitband-api.service
```

Add:
```ini
[Unit]
Description=Mock Fitband API Docker Compose
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/user/mock-fitband-api
ExecStart=/usr/bin/docker compose -f docker-compose.prod.yml --env-file .env.prod up -d
ExecStop=/usr/bin/docker compose -f docker-compose.prod.yml --env-file .env.prod down
TimeoutStartSec=0
User=user
Group=user

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl enable mock-fitband-api
sudo systemctl start mock-fitband-api
```

## Security Best Practices

1. **Strong Passwords**: Use complex passwords in `.env.prod`
2. **Firewall**: Only expose necessary ports (22, 80, 443)
3. **SSH Keys**: Use SSH key authentication instead of passwords
4. **Regular Updates**: Keep VM and Docker images updated
5. **Backups**: Schedule regular database backups
6. **SSL/TLS**: Use a reverse proxy (nginx) with SSL certificates
7. **Environment Variables**: Never commit `.env.prod` to git

## Using with Nginx (Reverse Proxy)

If you want to add nginx as a reverse proxy:

1. Install nginx on the VM:
   ```bash
   sudo apt-get install nginx
   ```

2. Configure nginx:
   ```bash
   sudo nano /etc/nginx/sites-available/mock-fitband-api
   ```

3. Add configuration:
   ```nginx
   server {
       listen 80;
       server_name your-domain.com;

       location / {
           proxy_pass http://localhost:8080;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto $scheme;
       }
   }
   ```

4. Enable and restart:
   ```bash
   sudo ln -s /etc/nginx/sites-available/mock-fitband-api /etc/nginx/sites-enabled/
   sudo nginx -t
   sudo systemctl restart nginx
   ```

## Troubleshooting

### Container Won't Start

```bash
# Check logs
docker-compose -f docker-compose.prod.yml --env-file .env.prod logs app

# Check container status
docker ps -a
```

### Database Connection Issues

```bash
# Test database connection
docker-compose -f docker-compose.prod.yml --env-file .env.prod exec db psql -U postgres -d mock_fitband_db

# Check if database is ready
docker-compose -f docker-compose.prod.yml --env-file .env.prod exec db pg_isready -U postgres
```

### Port Already in Use

If port 8080 is already in use, change `APP_PORT` in `.env.prod`:
```env
APP_PORT=3000
```

### Permission Issues

```bash
# Fix Docker permissions (if needed)
sudo usermod -aG docker $USER
# Log out and log back in
```

### Out of Disk Space

```bash
# Clean up Docker
docker system prune -a --volumes

# Check disk usage
df -h
docker system df
```

## Monitoring

### Check Resource Usage

```bash
# Container stats
docker stats

# System resources
htop
```

### Health Checks

The containers include health checks. Check status:
```bash
docker-compose -f docker-compose.prod.yml --env-file .env.prod ps
```

### Application Health

```bash
curl http://localhost:8080/health
```

## Backup Strategy

1. **Automated Database Backups**: Create a cron job for daily backups
2. **Volume Backups**: Backup the Docker volume containing PostgreSQL data
3. **Configuration Backups**: Keep `.env.prod` backed up (without committing to git)

Example backup cron job:
```bash
# Edit crontab
crontab -e

# Add daily backup at 2 AM
0 2 * * * cd /home/user/mock-fitband-api && docker-compose -f docker-compose.prod.yml --env-file .env.prod exec -T db pg_dump -U postgres mock_fitband_db > /backups/db_$(date +\%Y\%m\%d).sql
```

## Support

For issues:
- Check application logs: `docker-compose logs -f app`
- Check database logs: `docker-compose logs -f db`
- Verify environment variables in `.env.prod`
- Check Azure VM diagnostics in Azure Portal
- Verify NSG rules allow necessary ports

