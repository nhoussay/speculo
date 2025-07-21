# Multi-stage build for Speculod blockchain
FROM golang:1.24-alpine AS builder

# Set up build environment
RUN apk add --no-cache \
    git \
    make \
    gcc \
    musl-dev \
    linux-headers

# Set working directory
WORKDIR /app

# Copy go mod files first (for better caching)
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Debug: List directory structure to verify cmd/speculodd exists
RUN ls -la /app && echo "=== CMD DIRECTORY ===" && ls -la /app/cmd/ && echo "=== SPECULODD DIRECTORY ===" && ls -la /app/cmd/speculodd/

# Create build directory
RUN mkdir -p build

# Build the binary using Go without git initialization (avoid complexity)
RUN go build -o build/speculodd ./cmd/speculodd

# Production stage
FROM alpine:latest

# Install runtime dependencies including Python for faucet
RUN apk add --no-cache \
    ca-certificates \
    jq \
    curl \
    bash \
    dos2unix \
    sed \
    python3 \
    py3-pip \
    supervisor

# Create non-root user
RUN adduser -D -s /bin/bash speculod

# Set working directory
WORKDIR /home/speculod

# Copy binary and scripts from builder stage
COPY --from=builder /app/build/speculodd /usr/local/bin/speculodd
COPY --from=builder /app/scripts/docker-startup.sh /usr/local/bin/docker-startup.sh
COPY scripts/cloud-startup.sh /usr/local/bin/cloud-startup.sh

# Copy faucet scripts and supervisor config
COPY scripts/faucet.sh /usr/local/bin/faucet.sh
COPY scripts/faucet-server.py /usr/local/bin/faucet-server.py
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Ensure scripts have proper format and permissions (as root)
RUN dos2unix /usr/local/bin/docker-startup.sh /usr/local/bin/cloud-startup.sh /usr/local/bin/faucet.sh /usr/local/bin/faucet-server.py || true \
    && sed -i 's/\r$//' /usr/local/bin/docker-startup.sh /usr/local/bin/cloud-startup.sh /usr/local/bin/faucet.sh /usr/local/bin/faucet-server.py \
    && chmod +x /usr/local/bin/speculodd /usr/local/bin/docker-startup.sh /usr/local/bin/cloud-startup.sh /usr/local/bin/faucet.sh /usr/local/bin/faucet-server.py

# Create necessary directories
RUN mkdir -p /home/speculod/.speculod

# Change ownership to speculod user
RUN chown -R speculod:speculod /home/speculod \
    && chmod 755 /usr/local/bin/docker-startup.sh

# Switch to non-root user
USER speculod

# Set environment variables
ENV CHAIN_ID=speculod
ENV MONIKER=speculod-node
ENV HOME_DIR=/home/speculod/.speculod
ENV KEY_NAME=alice
ENV KEYRING_BACKEND=test

# Expose ports
# 8080 - Primary port (RPC for Cloud Run compatibility)
# 1317 - REST API port  
# 4500 - Token faucet port
# 9090 - gRPC port
# 26656 - P2P port (internal)
EXPOSE 8080 1317 4500 9090 26656

# Health check (check blockchain only - faucet will be on different port in cloud)
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=5 \
    CMD curl -f http://localhost:8080/status || exit 1

# Use supervisor to run both blockchain and faucet
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
