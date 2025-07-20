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

# Initialize git (needed for Makefile version info)
RUN git init . && git add . && git config user.email "build@docker.com" && git config user.name "Docker Build" && git commit -m "initial"

# Set build variables and build the binary
RUN export APPNAME=speculod && \
    export VERSION=docker-build && \
    export COMMIT=$(git rev-parse HEAD 2>/dev/null || echo "unknown") && \
    export GO111MODULE=on && \
    go mod verify && \
    go build \
    -ldflags "-X github.com/cosmos/cosmos-sdk/version.Name=${APPNAME} -X github.com/cosmos/cosmos-sdk/version.AppName=${APPNAME}d -X github.com/cosmos/cosmos-sdk/version.Version=${VERSION} -X github.com/cosmos/cosmos-sdk/version.Commit=${COMMIT}" \
    -o build/speculodd ./cmd/speculodd

# Production stage
FROM alpine:latest

# Install runtime dependencies
RUN apk add --no-cache \
    ca-certificates \
    jq \
    curl \
    bash \
    dos2unix \
    sed

# Create non-root user
RUN adduser -D -s /bin/bash speculod

# Set working directory
WORKDIR /home/speculod

# Copy binary from builder stage
COPY --from=builder /app/build/speculodd /usr/local/bin/speculodd
COPY --from=builder /app/scripts/docker-startup.sh /usr/local/bin/docker-startup.sh

# Ensure script has proper format and permissions (as root)
RUN dos2unix /usr/local/bin/docker-startup.sh || true \
    && chmod +x /usr/local/bin/speculodd /usr/local/bin/docker-startup.sh \
    && ls -la /usr/local/bin/docker-startup.sh \
    && head -1 /usr/local/bin/docker-startup.sh \
    && cat /usr/local/bin/docker-startup.sh | head -5

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
# 26656 - P2P port
# 26657 - RPC port
# 1317 - REST API port
# 9090 - gRPC port
EXPOSE 26656 26657 1317 9090

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:26657/health || exit 1

# Default command
CMD ["/usr/local/bin/docker-startup.sh"]
