#!/bin/bash

# Enhanced Speculod Startup Script with Faucet Support
# Supports both local and cloud deployment modes

set -e

# Determine deployment mode and port configuration
if [ "$DEPLOYMENT_MODE" = "cloud" ] || [ ! -z "$PORT" ]; then
    DEPLOYMENT_MODE="cloud"
    RPC_PORT="${PORT:-8080}"  # Use Cloud Run's PORT env var
    API_PORT="1317"
    FAUCET_PORT="4500" 
    echo "☁️ CLOUD DEPLOYMENT MODE - Port: $RPC_PORT"
else
    DEPLOYMENT_MODE="local"
    RPC_PORT="8080"
    API_PORT="1317" 
    FAUCET_PORT="4500"
    echo "🏠 LOCAL DEPLOYMENT MODE"
fi

echo "=================================================="
echo "🐳 SPECULOD BLOCKCHAIN STARTUP"
echo "=================================================="

# Configuration from environment variables or defaults
CHAIN_ID="${CHAIN_ID:-speculod}"
MONIKER="${MONIKER:-speculod-node}"
HOME_DIR="${HOME_DIR:-/home/speculod/.speculod}"
KEY_NAME="${KEY_NAME:-alice}"
KEYRING_BACKEND="${KEYRING_BACKEND:-test}"
GENESIS_COINS="${GENESIS_COINS:-1000000000000stake}"
STAKING_AMOUNT="${STAKING_AMOUNT:-500000000stake}"
MIN_GAS_PRICES="${MIN_GAS_PRICES:-0stake}"
BINARY="speculodd"

echo "📋 Configuration:"
echo "   Mode: $DEPLOYMENT_MODE"
echo "   Chain ID: $CHAIN_ID"
echo "   Moniker: $MONIKER"
echo "   Home Directory: $HOME_DIR"
echo ""

# Check if blockchain is already initialized
if [ -f "$HOME_DIR/config/genesis.json" ]; then
    echo "🔄 Blockchain already initialized, using existing chain..."
else
    echo "🏗️  Initializing new blockchain..."
    
    # Step 1: Initialize the chain
    $BINARY init "$MONIKER" --chain-id "$CHAIN_ID" --home "$HOME_DIR"
    
    # Step 2: Create genesis account key
    echo "🔑 Creating genesis account..."
    $BINARY keys add "$KEY_NAME" --home "$HOME_DIR" --keyring-backend "$KEYRING_BACKEND" > /tmp/genesis_account.txt 2>&1
    
    # Extract account address
    ACCOUNT_ADDRESS=$(grep -A 10 "^- address:" /tmp/genesis_account.txt | grep "address:" | cut -d' ' -f3)
    echo "   ✓ Genesis account created: $ACCOUNT_ADDRESS"
    
    # Step 3: Add genesis account to genesis file
    echo "💰 Adding genesis account with initial funds..."
    $BINARY genesis add-genesis-account "$KEY_NAME" "$GENESIS_COINS" --home "$HOME_DIR" --keyring-backend "$KEYRING_BACKEND"
    
    # Step 4: Create genesis transaction
    echo "👑 Creating validator genesis transaction..."
    $BINARY genesis gentx "$KEY_NAME" "$STAKING_AMOUNT" --home "$HOME_DIR" --keyring-backend "$KEYRING_BACKEND" --chain-id "$CHAIN_ID"
    
    # Step 5: Collect genesis transactions
    echo "📚 Collecting genesis transactions..."
    $BINARY genesis collect-gentxs --home "$HOME_DIR"
    
    echo "✅ Blockchain initialization complete!"
fi

echo ""
echo "🔧 Configuring for $DEPLOYMENT_MODE deployment..."

# Configure ports based on deployment mode
CONFIG_FILE="$HOME_DIR/config/config.toml"
APP_CONFIG_FILE="$HOME_DIR/config/app.toml"

if [ "$DEPLOYMENT_MODE" = "cloud" ]; then
    # Cloud deployment configuration
    API_PORT="1317"
    GRPC_PORT="9090"
    FAUCET_PORT="4500"
    
    # Update RPC to use the primary cloud port (the PORT env var from Cloud Run)
    sed -i "s/laddr = \"tcp:\/\/.*:26657\"/laddr = \"tcp:\/\/0.0.0.0:$RPC_PORT\"/" "$CONFIG_FILE"
    # Also update any existing port 8080 references
    sed -i "s/:8080/:$RPC_PORT/g" "$CONFIG_FILE"
else
    # Local deployment configuration - use standard Cosmos ports
    API_PORT="1317" 
    GRPC_PORT="9090"
    FAUCET_PORT="4500"
    
    # Use standard Cosmos ports for local
    sed -i "s/laddr = \"tcp:\/\/.*:26657\"/laddr = \"tcp:\/\/0.0.0.0:26657\"/" "$CONFIG_FILE"
fi

# Always configure for external access and enable API
if [ -f "$APP_CONFIG_FILE" ]; then
    sed -i 's/enable = false/enable = true/' "$APP_CONFIG_FILE"
    sed -i 's/swagger = false/swagger = true/' "$APP_CONFIG_FILE"
    sed -i "s/address = \"tcp:\/\/.*:1317\"/address = \"tcp:\/\/0.0.0.0:$API_PORT\"/" "$APP_CONFIG_FILE"
    sed -i "s/address = \".*:9090\"/address = \"0.0.0.0:$GRPC_PORT\"/" "$APP_CONFIG_FILE"
fi

echo "   ✓ Configuration updated for $DEPLOYMENT_MODE mode"

echo ""
echo "=================================================="
echo "🚀 STARTING SPECULOD SERVICES"
echo "=================================================="
echo ""
echo "🔗 Available Endpoints:"
echo "   • RPC:              http://0.0.0.0:$RPC_PORT"
echo "   • REST API:         http://0.0.0.0:$API_PORT"
echo "   • Token Faucet:     http://0.0.0.0:$FAUCET_PORT"
echo "   • gRPC:             0.0.0.0:$GRPC_PORT"

if [ "$DEPLOYMENT_MODE" = "cloud" ]; then
    echo "   • Public Access:    https://[your-cloud-run-url]"
fi

echo ""

# Export environment variables for faucet
export CONTAINER_NAME="localhost"
export HOME_DIR="$HOME_DIR"
export KEY_NAME="$KEY_NAME"

# Start the blockchain node
exec $BINARY start \
    --home "$HOME_DIR" \
    --minimum-gas-prices="$MIN_GAS_PRICES" \
    --rpc.laddr="tcp://0.0.0.0:$RPC_PORT"
