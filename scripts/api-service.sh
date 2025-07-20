#!/bin/bash

# Speculod REST API Service - Standalone
set -e

echo "Starting Speculod REST API Service..."

# Cloud Run port configuration
PORT=${PORT:-8080}
echo "Using port: $PORT"

# Default environment variables
export MONIKER=${MONIKER:-"api-node"}
export CHAIN_ID=${CHAIN_ID:-"speculod-testnet"}
export MINIMUM_GAS_PRICES=${MINIMUM_GAS_PRICES:-"0.001stake"}
export TENDERMINT_RPC_URL=${TENDERMINT_RPC_URL:-"tcp://localhost:26657"}

echo "Tendermint RPC URL: $TENDERMINT_RPC_URL"

# Home directory setup
export HOME=/home/speculod
SPECULOD_HOME="$HOME/.speculod"

echo "API service home: $SPECULOD_HOME"

# Minimal initialization for API only
if [ ! -d "$SPECULOD_HOME/config" ]; then
    echo "Initializing API configuration..."
    speculodd init $MONIKER --chain-id=$CHAIN_ID --home=$SPECULOD_HOME
    
    # Configure client to connect to external Tendermint RPC
    echo "Configuring client to connect to: $TENDERMINT_RPC_URL"
    cat > "$SPECULOD_HOME/config/client.toml" << EOF
chain-id = "$CHAIN_ID"
node = "$TENDERMINT_RPC_URL"
output = "json"
broadcast-mode = "block"
EOF
fi

# Wait for Tendermint to be available
echo "Waiting for Tendermint RPC at $TENDERMINT_RPC_URL to be available..."
for i in $(seq 1 30); do
    if curl -s "${TENDERMINT_RPC_URL/tcp:\/\//http://}/status" > /dev/null 2>&1; then
        echo "Tendermint RPC is available!"
        break
    fi
    echo "Waiting for Tendermint RPC... ($i/30)"
    sleep 2
done

# Get the peer node ID from the main Tendermint node
echo "Getting peer information from main Tendermint node..."
PEER_RPC_URL="${TENDERMINT_RPC_URL/tcp:\/\//http://}"
PEER_NODE_ID=$(curl -s "$PEER_RPC_URL/status" | jq -r '.result.node_info.id')
PEER_P2P_ADDRESS="${TENDERMINT_RPC_URL/tcp:\/\//}:26656"
PEER_INFO="$PEER_NODE_ID@${PEER_P2P_ADDRESS/8080/26656}"

echo "Main node ID: $PEER_NODE_ID"
echo "Will connect to peer: $PEER_INFO"

# Configure this node to connect to the main node as a peer
if [ ! -f "$SPECULOD_HOME/config/config.toml" ]; then
    echo "Generating Tendermint configuration..."
    speculodd comet init --home=$SPECULOD_HOME
fi

# Update configuration to connect as a peer
echo "Configuring peer connection..."
sed -i 's|persistent_peers = ""|persistent_peers = "'$PEER_INFO'"|g' $SPECULOD_HOME/config/config.toml
sed -i 's|create_empty_blocks = true|create_empty_blocks = false|g' $SPECULOD_HOME/config/config.toml
sed -i 's|rpc.laddr = "tcp://127.0.0.1:26657"|rpc.laddr = "tcp://0.0.0.0:26657"|g' $SPECULOD_HOME/config/config.toml

# Copy genesis file from main node
echo "Downloading genesis file from main node..."
curl -s "$PEER_RPC_URL/genesis" | jq '.result.genesis' > $SPECULOD_HOME/config/genesis.json

echo "Starting API node with Tendermint and REST API on port $PORT..."
echo "API endpoints will be available at: http://0.0.0.0:$PORT"
echo "Swagger UI: http://0.0.0.0:$PORT/swagger"
echo "Tendermint RPC: http://0.0.0.0:26657"
echo "Connected to peer: $PEER_INFO"

# Start the full node with API enabled
exec speculodd start \
    --home=$SPECULOD_HOME \
    --api.enable=true \
    --api.swagger=true \
    --api.address=tcp://0.0.0.0:$PORT \
    --grpc.enable=true \
    --grpc.address=0.0.0.0:9090 \
    --minimum-gas-prices="$MINIMUM_GAS_PRICES"
