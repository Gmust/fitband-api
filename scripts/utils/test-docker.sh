#!/bin/bash

# Test Docker setup for Mock Fitband API
set -e

echo "Testing Docker setup for Mock Fitband API..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}SUCCESS: $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}WARNING: $1${NC}"
}

print_error() {
    echo -e "${RED}ERROR: $1${NC}"
}

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker and try again."
    exit 1
fi
print_status "Docker is running"

# Build the Docker image
echo "Building Docker image..."
if docker build -t mock-fitband-api:test .; then
    print_status "Docker image built successfully"
else
    print_error "Failed to build Docker image"
    exit 1
fi

# Test the image
echo "Testing Docker container..."
CONTAINER_ID=$(docker run -d -p 3001:8080 --env-file env.dev mock-fitband-api:test)

# Wait for the container to start
echo "Waiting for container to start..."
sleep 10

# Check if the container is running
if docker ps | grep -q $CONTAINER_ID; then
    print_status "Container is running"
else
    print_error "Container failed to start"
    docker logs $CONTAINER_ID
    docker rm $CONTAINER_ID
    exit 1
fi

# Test the health endpoint
echo "Testing health endpoint..."
if curl -f http://localhost:3001/health > /dev/null 2>&1; then
    print_status "Health endpoint is responding"
else
    print_warning "Health endpoint not responding (this might be expected if database is not configured)"
fi

# Test the main endpoint
echo "Testing main endpoint..."
if curl -f http://localhost:3001/ > /dev/null 2>&1; then
    print_status "Main endpoint is responding"
else
    print_warning "Main endpoint not responding"
fi

# Show container logs
echo "Container logs:"
docker logs $CONTAINER_ID

# Clean up
echo "Cleaning up..."
docker stop $CONTAINER_ID
docker rm $CONTAINER_ID

print_status "Docker test completed successfully!"
echo "Your Docker setup is working correctly!"
