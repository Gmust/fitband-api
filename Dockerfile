# -------- Build stage --------
FROM node:20.18.0-alpine3.20 AS build
WORKDIR /app

# Install dependencies for building native modules
RUN apk add --no-cache python3 make g++

# Copy package files
COPY package*.json ./
COPY prisma ./prisma

# Install all dependencies (including dev dependencies for build)
RUN npm ci --silent

# Copy source code
COPY tsconfig.json ./
COPY src ./src

# Build application
RUN npm run build
RUN npm run postinstall

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
RUN npm ci --only=production --silent && npm cache clean --force

# Copy built application and Prisma files
COPY --from=build --chown=nestjs:nodejs /app/dist ./dist
COPY --from=build --chown=nestjs:nodejs /app/prisma ./prisma

# Create entrypoint script
RUN echo '#!/bin/sh\n\
set -e\n\
\n\
# Run database migrations if needed\n\
if [ "$RUN_MIGRATIONS" = "true" ]; then\n\
  echo "Running database migrations..."\n\
  npx prisma migrate deploy\n\
fi\n\
\n\
# Start the application\n\
echo "Starting NestJS application..."\n\
exec node dist/main.js\n\
' > /app/entrypoint.sh && \
chmod +x /app/entrypoint.sh && \
chown nestjs:nodejs /app/entrypoint.sh

# Switch to non-root user
USER nestjs

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:8080/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) })" || exit 1

# Start the application
CMD ["./entrypoint.sh"]
  