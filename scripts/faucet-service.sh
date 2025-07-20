#!/bin/bash

# Faucet Service Startup Script - Cloud Run Compatible

set -e

echo "Starting Speculod Token Faucet Service..."

# Cloud Run port configuration  
PORT=${PORT:-8080}
echo "Using port: $PORT"

# Set blockchain RPC URL
BLOCKCHAIN_RPC=${BLOCKCHAIN_RPC_URL:-"http://blockchain-service:8080"}
echo "Connecting to blockchain at: $BLOCKCHAIN_RPC"

# Wait for Tendermint RPC service to be available
echo "Waiting for Tendermint RPC service to be ready..."
for i in {1..30}; do
    if curl -s -f "$BLOCKCHAIN_RPC/status" > /dev/null 2>&1; then
        echo "Tendermint RPC service is ready"
        break
    fi
    echo "Attempt $i: Tendermint RPC service not ready, waiting..."
    sleep 10
done

echo "Starting faucet server on port $PORT..."
echo "Faucet endpoint: http://0.0.0.0:$PORT"
echo "Health endpoint: http://0.0.0.0:$PORT/health"

# Export environment variables for Python script
export FAUCET_PORT="$PORT"
export BLOCKCHAIN_RPC_URL="$BLOCKCHAIN_RPC"

# Start the faucet server
exec python faucet-server-flask.py
