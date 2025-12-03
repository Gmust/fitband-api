# Mock Fitband API

A NestJS-based REST API for IoT fitness band telemetry data management. This project demonstrates secure device-to-cloud communication, data ingestion, and real-time monitoring.

## Features

- RESTful API for device, session, and telemetry management
- PostgreSQL database with Prisma ORM
- Swagger/OpenAPI documentation
- Docker containerization
- AWS deployment ready
- HTTPS support with Let's Encrypt
- Database connection testing endpoints

## Quick Start

### Prerequisites

- Node.js 20+
- Docker and Docker Compose
- PostgreSQL (or use cloud database)

### Local Development

```bash
# Install dependencies
npm install

# Setup environment
cp env.example .env
# Edit .env with your database URL

# Run database migrations
npm run migrate:dev

# Start development server
npm run start:dev

# Or use Docker
npm run docker:dev
```

The API will be available at:
- API: http://localhost:3000
- Swagger UI: http://localhost:3000/api

## Project Structure

```
├── docs/                    # Documentation
│   ├── deployment/          # Deployment guides
│   └── development/         # Development guides
├── scripts/                 # Utility scripts
│   ├── aws/                # AWS-specific scripts
│   ├── deployment/         # Deployment scripts
│   └── utils/              # Utility scripts
├── src/                     # Source code
│   ├── auth/               # Authentication module
│   ├── device/             # Device management
│   ├── session/            # Session management
│   ├── telemetry/          # Telemetry data
│   └── common/             # Shared utilities
└── prisma/                 # Database schema and migrations
```

## Documentation

- **[Deployment Guide](./docs/deployment/AWS_API_DEPLOYMENT.md)** - Deploy to AWS EC2
- **[Database Setup](./docs/deployment/AWS_RDS_SETUP.md)** - Setup AWS RDS
- **[HTTPS Setup](./docs/deployment/HTTPS_SETUP.md)** - Configure HTTPS with DuckDNS
- **[Development Guide](./docs/development/DEVELOPMENT.md)** - Local development setup
- **[API Reference](./docs/deployment/API_URLS.md)** - API endpoints

## Scripts

See [scripts/README.md](./scripts/README.md) for available scripts.

### Common Commands

```bash
# AWS EC2
./scripts/aws/create-aws-ec2.sh
./scripts/aws/get-ec2-ip.sh

# Deployment
./scripts/deployment/deploy-to-aws.sh
./scripts/deployment/setup-https-duckdns.sh
```

## Environment Variables

See `env.example` for required environment variables:

- `DATABASE_URL` - PostgreSQL connection string
- `JWT_SECRET` - JWT signing secret
- `API_KEY` - API authentication key
- `CORS_ORIGIN` - Allowed CORS origins

## API Endpoints

- `GET /health` - Health check
- `GET /test/db` - Test database read
- `POST /test/db` - Test database write
- `GET /api` - Swagger UI documentation

See [API URLs](./docs/deployment/API_URLS.md) for complete endpoint reference.

## Tech Stack

- **Framework**: NestJS
- **Database**: PostgreSQL with Prisma ORM
- **Containerization**: Docker
- **Cloud**: AWS (EC2, RDS)
- **SSL**: Let's Encrypt

## License

MIT
