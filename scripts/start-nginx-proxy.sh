#!/bin/bash

# Start script for nginx proxy with speculodd
set -e

echo "Starting nginx proxy with speculodd..."

# Set default environment variables
export GENESIS_URL=${GENESIS_URL:-"https://mainnet-rpc.specu.io/genesis"}
export PERSISTENT_PEERS=${PERSISTENT_PEERS:-"9ff2468b686dd79ee94509a99e8a4e9ab2d5f88f@mainnet-tendermint.specu.io:26656"}
export MIN_GAS_PRICE=${MIN_GAS_PRICE:-"0.001uspect"}
export CHAIN_ID=${CHAIN_ID:-"speculo-1"}

# Function to handle shutdown
shutdown() {
    echo "Shutting down processes..."
    kill -TERM "$speculodd_pid" 2>/dev/null || true
    kill -TERM "$nginx_pid" 2>/dev/null || true
    wait "$speculodd_pid" 2>/dev/null || true
    wait "$nginx_pid" 2>/dev/null || true
    exit 0
}

# Set up signal handlers
trap shutdown SIGTERM SIGINT

# Initialize speculodd if needed
if [ ! -f "/root/.speculod/config/genesis.json" ]; then
    echo "Initializing speculodd..."
    speculodd init speculo-persistent-node --chain-id="$CHAIN_ID" --home="/root/.speculod"
    
    # Download genesis
    echo "Downloading genesis..."
    curl -s "$GENESIS_URL" > /root/.speculod/config/genesis.json
    
    # Set persistent peers
    if [ -n "$PERSISTENT_PEERS" ]; then
        sed -i.bak 's/persistent_peers = ""/persistent_peers = "'$PERSISTENT_PEERS'"/' /root/.speculod/config/config.toml
    fi
fi

# Start speculodd in the background
echo "Starting speculodd..."
speculodd start \
    --home="/root/.speculod" \
    --rpc.laddr=tcp://0.0.0.0:26657 \
    --p2p.laddr=tcp://0.0.0.0:26656 \
    --grpc.address=0.0.0.0:9090 \
    --api.address=tcp://0.0.0.0:1317 \
    --api.enable=true \
    --grpc.enable=true \
    --api.enabled-unsafe-cors=true \
    --minimum-gas-prices="$MIN_GAS_PRICE" &

speculodd_pid=$!
echo "speculodd started with PID: $speculodd_pid"

# Wait a moment for speculodd to start
sleep 10

# Start nginx in the foreground
echo "Starting nginx..."
nginx -g "daemon off;" &
nginx_pid=$!
echo "nginx started with PID: $nginx_pid"

# Wait for both processes
wait "$speculodd_pid" "$nginx_pid"
