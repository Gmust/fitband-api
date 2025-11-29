# API URLs Reference

## Get Your EC2 Instance IP

```bash
./scripts/get-ec2-ip.sh
```

Or manually:
```bash
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=mock-fitband-api" "Name=instance-state-name,Values=running" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text
```

## URLs to Access

Replace `<EC2_IP>` with your actual EC2 public IP address.

### 1. **Swagger UI (API Documentation)** - Recommended First
```
http://<EC2_IP>:8080/api
```
- Interactive API documentation
- Test all endpoints
- See available routes

### 2. **Health Check**
```
http://<EC2_IP>:8080/health
```
- Check if API is running
- Check database connection status
- Returns JSON with system status

### 3. **Root Endpoint**
```
http://<EC2_IP>:8080/
```
- Simple "Hello World" response
- Quick connectivity test

### 4. **Database Test - Read**
```
http://<EC2_IP>:8080/test/db
```
- Test reading from database
- Returns list of devices (if any)

### 5. **Database Test - Write**
```bash
curl -X POST http://<EC2_IP>:8080/test/db \
  -H "Content-Type: application/json" \
  -d '{"name": "Test Device", "secret": "test-secret"}'
```
- Test writing to database
- Creates a test device

## Example URLs (Replace with your IP)

If your EC2 IP is `54.123.45.67`:

- **Swagger UI**: http://54.123.45.67:8080/api
- **Health**: http://54.123.45.67:8080/health
- **Root**: http://54.123.45.67:8080/
- **Test DB Read**: http://54.123.45.67:8080/test/db

## If Using Nginx (Port 80)

If you set up Nginx reverse proxy:

- **Swagger UI**: http://<EC2_IP>/api
- **Health**: http://<EC2_IP>/health
- **Root**: http://<EC2_IP>/

## Quick Test Commands

```bash
# Get IP first
EC2_IP=$(./scripts/get-ec2-ip.sh | grep "Public IP:" | awk '{print $3}')

# Test health
curl http://${EC2_IP}:8080/health

# Test database read
curl http://${EC2_IP}:8080/test/db

# Test database write
curl -X POST http://${EC2_IP}:8080/test/db \
  -H "Content-Type: application/json" \
  -d '{"name": "My Test Device"}'

# Open Swagger in browser
open http://${EC2_IP}:8080/api  # macOS
# or
xdg-open http://${EC2_IP}:8080/api  # Linux
```

## Troubleshooting

### Can't access the API?

1. **Check if instance is running:**
   ```bash
   aws ec2 describe-instances --filters "Name=tag:Name,Values=mock-fitband-api"
   ```

2. **Check security group allows port 8080:**
   ```bash
   aws ec2 describe-security-groups --group-names mock-fitband-api-sg
   ```

3. **Check if Docker container is running:**
   ```bash
   ssh -i ~/.ssh/mock-fitband-api-key.pem ubuntu@<EC2_IP>
   sudo docker ps
   ```

4. **Check application logs:**
   ```bash
   ssh -i ~/.ssh/mock-fitband-api-key.pem ubuntu@<EC2_IP>
   sudo docker-compose -f docker-compose.prod.yml --env-file .env.prod logs
   ```

