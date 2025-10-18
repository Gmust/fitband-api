# Mock Fitband API - Local Development & Deployment Guide

## Table of Contents
- [Prerequisites](#prerequisites)
- [Local Development](#local-development)
- [Docker Testing](#docker-testing)
- [Production Deployment](#production-deployment)
- [Troubleshooting](#troubleshooting)
- [Azure Deployment (Future)](#azure-deployment-future)

## Prerequisites

Before you begin, ensure you have the following installed:

- **Node.js** (v20 or higher)
- **Docker** and **Docker Compose**
- **Git**
- **npm** or **yarn**

## Local Development

### Quick Start

1. **Clone and setup the project:**
   ```bash
   git clone <your-repo-url>
   cd mock-fitband-api
   npm install
   ```

2. **Start development environment:**
   ```bash
   npm run docker:dev
   ```

3. **Access your application:**
   - **API**: http://localhost:3000
   - **Health Check**: http://localhost:3000/health
   - **Database Admin**: http://localhost:8080

### Development Commands

| Command | Description |
|---------|-------------|
| `npm run docker:dev` | Start full development environment (app + database + adminer) |
| `npm run docker:dev:down` | Stop development environment |
| `npm run start:dev` | Start app in watch mode (without Docker) |
| `npm run db:migrate` | Run database migrations |
| `npm run db:studio` | Open Prisma Studio |
| `npm run lint` | Run ESLint |
| `npm run build` | Build the application |

### Environment Configuration

The development environment uses `env.dev` file with the following settings:

```env
NODE_ENV=development
PORT=3000
DATABASE_URL="postgresql://postgres:password@localhost:5433/mock_fitband_dev"
RUN_MIGRATIONS=true
```

## Docker Testing

### Test Docker Build

1. **Run the automated test script:**
   ```bash
   chmod +x test-docker.sh
   ./test-docker.sh
   ```

2. **Or use npm scripts:**
   ```bash
   npm run test:docker
   ```

### Manual Docker Testing

1. **Build the Docker image:**
   ```bash
   npm run docker:build
   ```

2. **Run the container:**
   ```bash
   npm run docker:run
   ```

3. **Test the endpoints:**
   ```bash
   curl http://localhost:3000/health
   curl http://localhost:3000/
   ```

### Docker Compose Testing

1. **Start production-like environment:**
   ```bash
   docker-compose up --build
   ```

2. **Access the application:**
   - **API**: http://localhost:8080
   - **Health Check**: http://localhost:8080/health

## Production Deployment

### Using Docker Compose (Recommended for VPS/Server)

1. **Prepare environment:**
   ```bash
   cp env.example .env
   # Edit .env with your production values
   ```

2. **Deploy:**
   ```bash
   chmod +x deploy.sh
   ./deploy.sh
   ```

3. **Or manually:**
   ```bash
   docker-compose up -d
   ```

### Using Docker Only

1. **Build production image:**
   ```bash
   docker build -t mock-fitband-api:latest .
   ```

2. **Run with environment file:**
   ```bash
   docker run -d \
     --name mock-fitband-api \
     -p 8080:8080 \
     --env-file .env \
     --restart unless-stopped \
     mock-fitband-api:latest
   ```

### Environment Variables for Production

Create a `.env` file with:

```env
NODE_ENV=production
PORT=8080
DATABASE_URL="postgresql://username:password@your-db-host:5432/mock_fitband_db"
JWT_SECRET=your-super-secret-jwt-key
API_KEY=your-api-key
CORS_ORIGIN=https://yourdomain.com
RUN_MIGRATIONS=true
```

## Monitoring & Health Checks

### Health Check Endpoint

The application provides a health check endpoint at `/health`:

```json
{
  "status": "ok",
  "timestamp": "2024-01-01T00:00:00.000Z",
  "uptime": 123.45,
  "environment": "production",
  "version": "1.0.0"
}
```

### Docker Health Check

The Dockerfile includes a built-in health check that runs every 30 seconds.

### Logs

View application logs:

```bash
# Docker Compose
docker-compose logs -f app

# Docker container
docker logs -f mock-fitband-api
```

## Troubleshooting

### Common Issues

#### 1. **Port Already in Use**
```bash
# Check what's using the port
lsof -i :3000
# Kill the process or use a different port
```

#### 2. **Database Connection Issues**
```bash
# Check if PostgreSQL is running
docker-compose ps db

# View database logs
docker-compose logs db
```

#### 3. **Docker Build Fails**
```bash
# Clean Docker cache
docker system prune -a

# Rebuild without cache
docker build --no-cache -t mock-fitband-api:latest .
```

#### 4. **Permission Issues**
```bash
# Make scripts executable
chmod +x deploy.sh test-docker.sh
```

### Debug Mode

Run the application in debug mode:

```bash
npm run start:debug
```

### Database Issues

1. **Reset database:**
   ```bash
   docker-compose down -v
   docker-compose up -d
   ```

2. **Run migrations manually:**
   ```bash
   docker-compose exec app npx prisma migrate deploy
   ```

## Azure Deployment (Future)

### Azure Container Instances

1. **Build and push to Azure Container Registry:**
   ```bash
   # Login to Azure
   az login
   
   # Create resource group
   az group create --name myResourceGroup --location eastus
   
   # Create container registry
   az acr create --resource-group myResourceGroup --name myregistry --sku Basic
   
   # Build and push image
   az acr build --registry myregistry --image mock-fitband-api:latest .
   ```

2. **Deploy to Azure Container Instances:**
   ```bash
   az container create \
     --resource-group myResourceGroup \
     --name mock-fitband-api \
     --image myregistry.azurecr.io/mock-fitband-api:latest \
     --ports 8080 \
     --environment-variables NODE_ENV=production
   ```

### Azure App Service

1. **Deploy using Docker:**
   ```bash
   az webapp create \
     --resource-group myResourceGroup \
     --plan myAppServicePlan \
     --name myAppName \
     --deployment-container-image-name myregistry.azurecr.io/mock-fitband-api:latest
   ```

### Azure Database for PostgreSQL

1. **Create PostgreSQL server:**
   ```bash
   az postgres server create \
     --resource-group myResourceGroup \
     --name myPostgresServer \
     --location eastus \
     --admin-user myadmin \
     --admin-password mypassword \
     --sku-name GP_Gen5_2
   ```

## Additional Resources

- [NestJS Documentation](https://docs.nestjs.com/)
- [Prisma Documentation](https://www.prisma.io/docs/)
- [Docker Documentation](https://docs.docker.com/)
- [Azure Container Instances](https://docs.microsoft.com/en-us/azure/container-instances/)
