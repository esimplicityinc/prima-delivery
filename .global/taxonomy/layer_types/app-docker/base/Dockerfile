# syntax=docker/dockerfile:1

# Multi-stage Dockerfile for {{ layer_name }}
# Layer: {{ system_name }}/{{ stack_name }}/{{ layer_name }}

# -----------------------------------------------------------------------------
# Build stage
# -----------------------------------------------------------------------------
FROM {{ build_image | default("node:20-alpine") }} AS builder

WORKDIR /app

# Copy dependency manifests first (for better caching)
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy application source
COPY . .

# Build application (if applicable)
# RUN npm run build

# -----------------------------------------------------------------------------
# Production stage
# -----------------------------------------------------------------------------
FROM {{ runtime_image | default("node:20-alpine") }} AS runtime

# Add non-root user for security
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

WORKDIR /app

# Copy built application from builder stage
COPY --from=builder --chown=appuser:appgroup /app .

# Set environment variables
ENV NODE_ENV=production
ENV PORT=8080

# Expose application port
EXPOSE 8080

# Run as non-root user
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

# Start application
CMD ["node", "index.js"]
