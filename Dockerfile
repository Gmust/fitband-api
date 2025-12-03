# -------- Build stage --------
FROM node:20.18.0-alpine3.20 AS build
WORKDIR /app

# Install dependencies for building native modules
RUN apk add --no-cache python3 make g++

# Copy package files
COPY package*.json ./
COPY prisma ./prisma

# Configure npm for better reliability and speed
RUN npm config set fetch-timeout 600000 && \
    npm config set fetch-retry-mintimeout 20000 && \
    npm config set fetch-retry-maxtimeout 120000 && \
    npm config set progress false

# Install all dependencies (using npm install instead of ci for better network handling)
RUN npm install --no-audit --legacy-peer-deps

# Generate Prisma client
RUN npx prisma generate

# Copy source code
COPY tsconfig.json ./
COPY src ./src

# Build application
RUN npm run build

# -------- Runtime stage --------
FROM node:20.18.0-alpine3.20
WORKDIR /app

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nestjs -u 1001

# Set environment variables
ENV NODE_ENV=production
ENV PORT=8080

# Copy package files and install only production dependencies
COPY --chown=nestjs:nodejs package*.json ./
COPY --chown=nestjs:nodejs prisma ./prisma

# Configure npm for better reliability
RUN npm config set fetch-timeout 600000 && \
    npm config set fetch-retry-mintimeout 20000 && \
    npm config set fetch-retry-maxtimeout 120000 && \
    npm config set progress false

# Install all dependencies (skip postinstall script that needs prisma CLI)
RUN npm install --no-audit --legacy-peer-deps --ignore-scripts && npm cache clean --force

# Install prisma CLI temporarily to generate client, then remove it
RUN npm install --no-save prisma@^6.17.1 && npx prisma generate && npm uninstall prisma

# Copy built application (for production)
COPY --from=build --chown=nestjs:nodejs /app/dist ./dist

# Create entrypoint script
RUN echo '#!/bin/sh' > /app/entrypoint.sh && \
    echo 'set -e' >> /app/entrypoint.sh && \
    echo '' >> /app/entrypoint.sh && \
    echo '# Run database migrations if needed' >> /app/entrypoint.sh && \
    echo 'if [ "$RUN_MIGRATIONS" = "true" ]; then' >> /app/entrypoint.sh && \
    echo '  echo "Running database migrations..."' >> /app/entrypoint.sh && \
    echo '  npx prisma migrate deploy' >> /app/entrypoint.sh && \
    echo 'fi' >> /app/entrypoint.sh && \
    echo '' >> /app/entrypoint.sh && \
    echo '# Start the application' >> /app/entrypoint.sh && \
    echo 'if [ "$NODE_ENV" = "development" ]; then' >> /app/entrypoint.sh && \
    echo '  echo "Starting NestJS application in development mode..."' >> /app/entrypoint.sh && \
    echo '  # Install dev dependencies if not present (for anonymous node_modules volume)' >> /app/entrypoint.sh && \
    echo '  if [ ! -f "node_modules/.bin/nest" ]; then' >> /app/entrypoint.sh && \
    echo '    echo "Installing dependencies..."' >> /app/entrypoint.sh && \
    echo '    npm install --no-audit --legacy-peer-deps' >> /app/entrypoint.sh && \
    echo '  fi' >> /app/entrypoint.sh && \
    echo '  exec npm run start:dev' >> /app/entrypoint.sh && \
    echo 'else' >> /app/entrypoint.sh && \
    echo '  echo "Starting NestJS application in production mode on port ${PORT}..."' >> /app/entrypoint.sh && \
    echo '  exec node dist/main.js' >> /app/entrypoint.sh && \
    echo 'fi' >> /app/entrypoint.sh && \
    chmod +x /app/entrypoint.sh && \
    chown nestjs:nodejs /app/entrypoint.sh

# Change ownership of entire /app directory to nestjs user
# This ensures the user can write/delete files in development mode
RUN chown -R nestjs:nodejs /app

# Switch to non-root user
USER nestjs

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD node -e "require('http').get('http://localhost:8080/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) })" || exit 1

# Start the application
WORKDIR /app
CMD ["/app/entrypoint.sh"]
