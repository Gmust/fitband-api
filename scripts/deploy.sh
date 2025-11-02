#!/bin/bash
# Deploy to Azure VM - Single VM with app and database

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

ENV_FILE=".env.prod"
COMPOSE_FILE="docker-compose.prod.yml"

# Detect docker-compose command (try plugin first, then standalone)
if docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
elif command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
else
    echo -e "${RED}Error: docker-compose not found!${NC}"
    echo -e "${YELLOW}Please install Docker Compose first:${NC}"
    echo "  sudo bash scripts/setup-azure-vm.sh"
    echo "  OR"
    echo "  curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m) -o /usr/local/bin/docker-compose"
    echo "  sudo chmod +x /usr/local/bin/docker-compose"
    exit 1
fi

# Check if .env.prod exists
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}Error: $ENV_FILE not found!${NC}"
    echo -e "${YELLOW}Please copy env.prod.example to $ENV_FILE and configure it.${NC}"
    exit 1
fi

echo -e "${BLUE}Deploying Mock Fitband API to Azure VM...${NC}"

# Build and start services
echo -e "${BLUE}Building images and starting services...${NC}"
$DOCKER_COMPOSE -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d --build

# Wait for services to be healthy
echo -e "${BLUE}Waiting for services to be ready...${NC}"
sleep 10

# Check service health
echo -e "${BLUE}Checking service status...${NC}"
$DOCKER_COMPOSE -f "$COMPOSE_FILE" --env-file "$ENV_FILE" ps

echo -e "${GREEN}✓ Deployment complete!${NC}"
echo ""
echo -e "${BLUE}Useful commands:${NC}"
echo "  View logs:        $DOCKER_COMPOSE -f $COMPOSE_FILE --env-file $ENV_FILE logs -f"
echo "  View app logs:    $DOCKER_COMPOSE -f $COMPOSE_FILE --env-file $ENV_FILE logs -f app"
echo "  View db logs:     $DOCKER_COMPOSE -f $COMPOSE_FILE --env-file $ENV_FILE logs -f db"
echo "  Stop services:    $DOCKER_COMPOSE -f $COMPOSE_FILE --env-file $ENV_FILE down"
echo "  Restart services: $DOCKER_COMPOSE -f $COMPOSE_FILE --env-file $ENV_FILE restart"
echo "  View status:      $DOCKER_COMPOSE -f $COMPOSE_FILE --env-file $ENV_FILE ps"

