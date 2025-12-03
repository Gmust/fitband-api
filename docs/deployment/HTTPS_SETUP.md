# HTTPS Setup with Free DNS (DuckDNS)

This guide shows how to set up HTTPS for your API using DuckDNS (free DNS) and Let's Encrypt SSL certificates.

## Options for Free DNS

1. **DuckDNS** (easiest, recommended)
   - Free subdomain: `yourname.duckdns.org`
   - Simple API-based updates
   - No registration required

2. **No-IP** (alternative)
   - Free subdomain: `yourname.ddns.net`
   - Requires account

3. **FreeDNS** (alternative)
   - Various free domains
   - Requires account

## Step 1: Get DuckDNS Domain

1. Go to https://www.duckdns.org/
2. Sign in with Google/GitHub/Twitter
3. Create a subdomain (e.g., `mock-fitband-api`)
4. Copy your **Token**
5. Your domain will be: `mock-fitband-api.duckdns.org`

## Step 2: Update DNS to Point to EC2

### Option A: Automatic Script (Recommended)

```bash
# Set your DuckDNS credentials
export DUCKDNS_TOKEN="your-token-here"
export DUCKDNS_DOMAIN="your-subdomain"  # e.g., "mock-fitband-api"

# Get EC2 IP
EC2_IP=$(./scripts/get-ec2-ip.sh | grep "Public IP:" | awk '{print $3}')

# Update DuckDNS
curl "https://www.duckdns.org/update?domains=${DUCKDNS_DOMAIN}&token=${DUCKDNS_TOKEN}&ip=${EC2_IP}"
```

### Option B: Manual Update

Visit this URL (replace with your values):
```
https://www.duckdns.org/update?domains=your-subdomain&token=your-token&ip=35.175.136.111
```

## Step 3: Setup SSL Certificate on EC2

SSH into your EC2 instance and run:

```bash
ssh -i ~/.ssh/mock-fitband-api-key.pem ubuntu@35.175.136.111
```

On the EC2 instance:

```bash
# Install Certbot
sudo apt-get update
sudo apt-get install -y certbot python3-certbot-nginx

# Get SSL certificate (replace with your domain)
sudo certbot certonly --standalone \
  -d your-subdomain.duckdns.org \
  --email your-email@example.com \
  --agree-tos \
  --non-interactive

# Certificates will be saved to:
# /etc/letsencrypt/live/your-subdomain.duckdns.org/
```

## Step 4: Setup Nginx with SSL

Create Nginx configuration:

```bash
sudo nano /etc/nginx/sites-available/mock-fitband-api
```

Add this configuration (replace `your-subdomain.duckdns.org`):

```nginx
# HTTP to HTTPS redirect
server {
    listen 80;
    server_name your-subdomain.duckdns.org;

    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }

    location / {
        return 301 https://$server_name$request_uri;
    }
}

# HTTPS server
server {
    listen 443 ssl http2;
    server_name your-subdomain.duckdns.org;

    # SSL certificates
    ssl_certificate /etc/letsencrypt/live/your-subdomain.duckdns.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-subdomain.duckdns.org/privkey.pem;

    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Proxy to NestJS app
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
        
        # Timeouts
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
}
```

Enable the site:

```bash
sudo ln -s /etc/nginx/sites-available/mock-fitband-api /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

## Step 5: Auto-Renewal Setup

```bash
# Test renewal
sudo certbot renew --dry-run

# Certbot auto-renewal is already set up via systemd timer
# Check status
sudo systemctl status certbot.timer
```

## Step 6: Update CORS in .env.prod

On EC2, update `.env.prod`:

```bash
nano /home/ubuntu/mock-fitband-api/.env.prod
```

Add/update:
```env
CORS_ORIGIN=https://your-subdomain.duckdns.org,http://your-subdomain.duckdns.org
```

Restart the app:
```bash
cd /home/ubuntu/mock-fitband-api
sudo docker-compose -f docker-compose.prod.yml --env-file .env.prod restart app
```

## Step 7: Update DuckDNS Automatically (Optional)

If your EC2 IP changes, you'll need to update DuckDNS. Create a cron job:

```bash
# Create update script
sudo nano /usr/local/bin/update-duckdns.sh
```

Add:
```bash
#!/bin/bash
TOKEN="your-token-here"
DOMAIN="your-subdomain"
CURRENT_IP=$(curl -s https://checkip.amazonaws.com)
curl -s "https://www.duckdns.org/update?domains=${DOMAIN}&token=${TOKEN}&ip=${CURRENT_IP}"
```

```bash
chmod +x /usr/local/bin/update-duckdns.sh

# Add to crontab (runs every 5 minutes)
(crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/update-duckdns.sh >/dev/null 2>&1") | crontab -
```

## URLs After Setup

- **HTTPS API**: https://your-subdomain.duckdns.org
- **Swagger UI**: https://your-subdomain.duckdns.org/api
- **Health**: https://your-subdomain.duckdns.org/health

## Troubleshooting

### Certificate not working
- Check DNS propagation: `nslookup your-subdomain.duckdns.org`
- Verify port 80 is open for Let's Encrypt validation
- Check Nginx config: `sudo nginx -t`

### Nginx not starting
- Check logs: `sudo tail -f /var/log/nginx/error.log`
- Verify certificate paths are correct

### DuckDNS not updating
- Check token is correct
- Verify IP is correct: `curl https://checkip.amazonaws.com`

