# Free Domain Setup Guide

## Option 1: DuckDNS (Recommended - Easiest)

### Steps:

1. **Go to DuckDNS website:**
   - Visit: https://www.duckdns.org/
   - Sign in with GitHub, Google, or Reddit

2. **Create a subdomain:**
   - Choose a subdomain name (e.g., `mock-fitband-api`)
   - Your domain will be: `mock-fitband-api.duckdns.org`
   - Add your IP: `74.248.151.43`

3. **Update DNS automatically (optional script):**
   ```bash
   # On your Azure VM, create update script
   cat > ~/update-duckdns.sh << 'EOF'
   #!/bin/bash
   TOKEN="your-duckdns-token"
   DOMAIN="your-subdomain"
   
   curl "https://www.duckdns.org/update?domains=$DOMAIN&token=$TOKEN&ip=$1"
   EOF
   
   chmod +x ~/update-duckdns.sh
   ```

4. **Use with Let's Encrypt:**
   ```bash
   sudo bash scripts/setup-ssl.sh
   # Enter: your-subdomain.duckdns.org
   ```

**Pros:**
- ✅ Free
- ✅ Works with Let's Encrypt
- ✅ Easy setup
- ✅ Auto-update IP

**Cons:**
- Uses `.duckdns.org` subdomain

---

## Option 2: Freenom (.tk, .ml, .ga, .cf domains)

1. **Go to Freenom:**
   - Visit: https://www.freenom.com/
   - Create account

2. **Search and register a domain:**
   - Search for available `.tk`, `.ml`, `.ga`, `.cf` domains
   - Add to cart and complete registration

3. **Configure DNS:**
   - Go to Services → My Domains → Manage Domain
   - Add A record: `api` → `74.248.151.43`
   - Wait 24-48 hours for DNS propagation

4. **Use with Let's Encrypt:**
   ```bash
   sudo bash scripts/setup-ssl.sh
   # Enter: api.yourdomain.tk
   ```

**Pros:**
- ✅ Free domain with custom TLD
- ✅ Works with Let's Encrypt

**Cons:**
- ⚠️ May require renewal annually
- ⚠️ Some providers block Freenom domains

---

## Option 3: NoIP (Free Dynamic DNS)

1. **Sign up:**
   - Visit: https://www.noip.com/
   - Create free account

2. **Create hostname:**
   - Choose hostname (e.g., `mock-fitband-api`)
   - Domain: `.ddns.net`, `.mynetgear.com`, etc.
   - Full domain: `mock-fitband-api.ddns.net`
   - Set IP to: `74.248.151.43`

3. **Install dynamic update client (optional):**
   ```bash
   # On Azure VM
   cd /usr/local/src
   wget https://www.noip.com/client/linux/noip-duc-linux.tar.gz
   tar xzf noip-duc-linux.tar.gz
   cd noip-2.1.9-1
   make install
   ```

**Pros:**
- ✅ Free
- ✅ Works with Let's Encrypt

**Cons:**
- Requires monthly confirmation to keep free
- Uses subdomain format

---

## Option 4: Cloudflare (Free Domain + CDN)

1. **Buy a cheap domain** ($1-10/year):
   - Namecheap, Google Domains, etc.

2. **Use Cloudflare for DNS:**
   - Sign up at https://www.cloudflare.com/
   - Add your domain
   - Update nameservers
   - Add A record: `api` → `74.248.151.43`

3. **Get SSL via Cloudflare:**
   - Cloudflare provides free SSL
   - Or use Let's Encrypt on server

**Pros:**
- ✅ Free SSL via Cloudflare
- ✅ CDN included
- ✅ DDoS protection

**Cons:**
- Requires purchasing a domain first (but very cheap)

---

## Quick Setup with DuckDNS (Recommended)

### 1. Get DuckDNS subdomain:
1. Go to https://www.duckdns.org/
2. Sign in
3. Create subdomain: `mock-fitband-api`
4. Add IP: `74.248.151.43`
5. Get your token

### 2. On Azure VM:
```bash
cd /opt/mock-fitband-api/fitband-api

# Run SSL setup with your DuckDNS domain
sudo bash scripts/setup-ssl.sh
# Enter: mock-fitband-api.duckdns.org
```

### 3. Update CORS in .env.prod:
```bash
nano .env.prod
# Set:
CORS_ORIGIN=https://mock-fitband-api.duckdns.org,http://mock-fitband-api.duckdns.org
```

### 4. Restart app:
```bash
sudo docker-compose -f docker-compose.prod.yml --env-file .env.prod restart app
```

---

## DNS Propagation

After setting up DNS:
- Wait 5-60 minutes for DNS to propagate
- Check with: `nslookup your-domain.com`
- Or: `dig your-domain.com`

Then proceed with SSL setup!

