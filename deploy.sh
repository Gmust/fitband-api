#!/bin/bash

# Deployment script for Mock Fitband API
set -e

echo "Starting deployment process..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "ERROR: Docker is not running. Please start Docker and try again."
    exit 1
fi

# Build the application
echo "Building Docker image..."
docker build -t mock-fitband-api:latest .

# Stop existing containers
echo "Stopping existing containers..."
docker-compose down || true

# Start the application
echo "Starting application..."
docker-compose up -d

# Wait for the application to be ready
echo "Waiting for application to be ready..."
sleep 10

# Check if the application is running
if curl -f http://localhost:8080/health > /dev/null 2>&1; then
    echo "SUCCESS: Application is running successfully!"
    echo "API available at: http://localhost:8080"
    echo "Health check: http://localhost:8080/health"
else
    echo "ERROR: Application failed to start. Check logs with: docker-compose logs"
    exit 1
fi

echo "Deployment completed successfully!"
