#!/bin/bash

# Speculod blockchain service for nginx reverse proxy setup
# This script starts the blockchain with all API services enabled

set -e

echo "🚀 Starting Speculod Blockchain Service with Nginx Proxy..."

# Configuration
GITHUB_REPO="${GITHUB_REPO:-nhoussay/speculo}"
GITHUB_BRANCH="${GITHUB_BRANCH:-main}"
CHAIN_ID="${CHAIN_ID:-speculod-mainnet-1}"
NODE_TYPE="${NODE_TYPE:-persistent}"
MONIKER="${MONIKER:-nginx-proxy-node}"

# Default configuration
HOME_DIR="${HOME_DIR:-/home/speculod/.speculod}"
KEYRING_BACKEND="${KEYRING_BACKEND:-test}"

# Determine network path
if [[ "$CHAIN_ID" == *"mainnet"* ]]; then
    NETWORK_PATH="mainnet"
    GENESIS_URL="https://raw.githubusercontent.com/${GITHUB_REPO}/${GITHUB_BRANCH}/networks/${NETWORK_PATH}/genesis.json"
else
    NETWORK_PATH="local-testnet"
    GENESIS_URL="https://raw.githubusercontent.com/${GITHUB_REPO}/${GITHUB_BRANCH}/networks/${NETWORK_PATH}/genesis.json"
fi

echo "📋 Configuration:"
echo "  - Node Type: $NODE_TYPE"
echo "  - Chain ID: $CHAIN_ID"
echo "  - Moniker: $MONIKER"
echo "  - Home Directory: $HOME_DIR"
echo "  - Network Path: $NETWORK_PATH"
echo "  - Services: RPC (26657), REST API (1317), gRPC (9090), P2P (26656)"

# Function to wait for genesis file
wait_for_genesis() {
    echo "⏳ Downloading genesis file..."
    
    local max_attempts=60
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if curl -s -f "$GENESIS_URL" > /tmp/genesis.json; then
            echo "✅ Genesis file downloaded successfully"
            return 0
        fi
        
        attempt=$((attempt + 1))
        echo "Waiting for genesis file... ($attempt/$max_attempts)"
        sleep 2
    done
    
    echo "❌ Failed to download genesis file after $max_attempts attempts"
    return 1
}

# Function to initialize node
initialize_node() {
    echo "🔧 Initializing Speculod node..."
    
    # Create home directory
    mkdir -p "$HOME_DIR"
    
    # Initialize the node if not already initialized
    if [ ! -d "$HOME_DIR/config" ]; then
        speculodd init "$MONIKER" --chain-id "$CHAIN_ID" --home "$HOME_DIR"
        echo "✅ Node initialized with moniker: $MONIKER"
    else
        echo "✅ Node already initialized"
    fi
    
    # Download and set genesis file
    if wait_for_genesis; then
        cp /tmp/genesis.json "$HOME_DIR/config/genesis.json"
        echo "✅ Genesis file configured"
    else
        echo "❌ Failed to configure genesis file"
        exit 1
    fi
    
    # Configure the node for full service with nginx proxy
    configure_node_for_nginx
    
    echo "✅ Node configuration completed"
}

# Function to configure node for nginx proxy
configure_node_for_nginx() {
    echo "🔧 Configuring node for nginx reverse proxy..."
    
    # Configure listening addresses for internal access
    sed -i 's|laddr = "tcp://127.0.0.1:26657"|laddr = "tcp://0.0.0.0:26657"|g' "$HOME_DIR/config/config.toml"
    echo "✅ RPC listening on: 0.0.0.0:26657"
    
    # Enable REST API
    sed -i 's|enable = false|enable = true|g' "$HOME_DIR/config/app.toml"
    sed -i 's|address = "tcp://localhost:1317"|address = "tcp://0.0.0.0:1317"|g' "$HOME_DIR/config/app.toml"
    sed -i 's|enabled-unsafe-cors = false|enabled-unsafe-cors = true|g' "$HOME_DIR/config/app.toml"
    echo "✅ REST API listening on: 0.0.0.0:1317"
    
    # Enable gRPC
    sed -i 's|address = "localhost:9090"|address = "0.0.0.0:9090"|g' "$HOME_DIR/config/app.toml"
    echo "✅ gRPC listening on: 0.0.0.0:9090"
    
    # P2P configuration
    sed -i 's|laddr = "tcp://0.0.0.0:26656"|laddr = "tcp://0.0.0.0:26656"|g' "$HOME_DIR/config/config.toml"
    echo "✅ P2P listening on: 0.0.0.0:26656"
    
    # Set external address for Cloud Run
    if [[ -n "$EXTERNAL_ADDRESS" ]]; then
        sed -i "s|external_address = \"\"|external_address = \"$EXTERNAL_ADDRESS\"|g" "$HOME_DIR/config/config.toml"
        echo "✅ External address: $EXTERNAL_ADDRESS"
    fi
    
    # Persistent node configuration
    if [ "$NODE_TYPE" = "persistent" ]; then
        echo "🏗️  Configuring as persistent node..."
        
        # More permissive settings
        sed -i 's/pex = true/pex = true/g' "$HOME_DIR/config/config.toml"
        sed -i 's/addr_book_strict = true/addr_book_strict = false/g' "$HOME_DIR/config/config.toml"
        
        # Higher peer limits
        sed -i "s/max_num_inbound_peers = 40/max_num_inbound_peers = 100/g" "$HOME_DIR/config/config.toml"
        sed -i "s/max_num_outbound_peers = 10/max_num_outbound_peers = 50/g" "$HOME_DIR/config/config.toml"
    fi
    
    # Set minimum gas prices
    MINIMUM_GAS_PRICES="${MINIMUM_GAS_PRICES:-0.01stake}"
    sed -i "s/minimum-gas-prices = \"\"/minimum-gas-prices = \"$MINIMUM_GAS_PRICES\"/g" "$HOME_DIR/config/app.toml"
    echo "✅ Minimum gas prices: $MINIMUM_GAS_PRICES"
}

# Function to start the blockchain service
start_blockchain() {
    echo "🚀 Starting Speculod with full services (RPC + REST + gRPC)..."
    
    # Start the blockchain with all services enabled
    exec speculodd start \
        --home "$HOME_DIR" \
        --rpc.laddr "tcp://0.0.0.0:26657" \
        --api.enable \
        --api.enabled-unsafe-cors \
        --api.address "tcp://0.0.0.0:1317" \
        --grpc.address "0.0.0.0:9090" \
        --p2p.laddr "tcp://0.0.0.0:26656"
}

# Main execution
main() {
    echo "🎯 Starting nginx-proxied blockchain service..."
    
    # Initialize and configure the node
    initialize_node
    
    # Start the blockchain service
    start_blockchain
}

# Run main function
main "$@"
