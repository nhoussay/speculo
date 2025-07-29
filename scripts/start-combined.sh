#!/bin/bash
set -e

echo "Starting combined nginx proxy service..."

# Set defaults
export GENESIS_URL=${GENESIS_URL:-"https://mainnet-rpc.specu.io/genesis"}
export PERSISTENT_PEERS=${PERSISTENT_PEERS:-"9ff2468b686dd79ee94509a99e8a4e9ab2d5f88f@mainnet-tendermint.specu.io:26656"}
export MIN_GAS_PRICE=${MIN_GAS_PRICE:-"0.001uspect"}
export CHAIN_ID=${CHAIN_ID:-"speculo-1"}

# Initialize if needed
if [ ! -f "/root/.speculod/config/genesis.json" ]; then
    echo "Initializing speculodd..."
    speculodd init speculo-persistent-node --chain-id="$CHAIN_ID" --home="/root/.speculod"
    
    echo "Downloading genesis..."
    curl -s "$GENESIS_URL" > /root/.speculod/config/genesis.json
    
    if [ -n "$PERSISTENT_PEERS" ]; then
        sed -i 's/persistent_peers = ""/persistent_peers = "'$PERSISTENT_PEERS'"/' /root/.speculod/config/config.toml
    fi
fi

# Start speculodd in background
echo "Starting speculodd in background..."
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

# Wait a bit for speculodd to initialize
sleep 30

# Start nginx in foreground (this keeps the container running)
echo "Starting nginx..."
exec nginx -g "daemon off;"
