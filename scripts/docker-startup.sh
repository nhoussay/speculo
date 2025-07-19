#!/bin/bash

# Docker-optimized Speculod Blockchain Startup Script
set -e

echo "=================================================="
echo "🐳 SPECULOD BLOCKCHAIN - DOCKER STARTUP"
echo "=================================================="

# Configuration from environment variables or defaults
CHAIN_ID="${CHAIN_ID:-speculod}"
MONIKER="${MONIKER:-speculod-docker}"
HOME_DIR="${HOME_DIR:-/home/speculod/.speculod}"
KEY_NAME="${KEY_NAME:-alice}"
KEYRING_BACKEND="${KEYRING_BACKEND:-test}"
GENESIS_COINS="${GENESIS_COINS:-1000000000000stake}"
STAKING_AMOUNT="${STAKING_AMOUNT:-500000000stake}"
MIN_GAS_PRICES="${MIN_GAS_PRICES:-0stake}"
BINARY="speculodd"

echo "📋 Container Configuration:"
echo "   Chain ID: $CHAIN_ID"
echo "   Moniker: $MONIKER"
echo "   Home Directory: $HOME_DIR"
echo "   Key Name: $KEY_NAME"
echo ""

# Check if blockchain is already initialized
if [ -f "$HOME_DIR/config/genesis.json" ]; then
    echo "🔄 Blockchain already initialized, starting existing chain..."
    echo "   Existing genesis found at: $HOME_DIR/config/genesis.json"
else
    echo "🏗️  Initializing new blockchain..."
    
    # Step 1: Initialize the chain
    echo "   Initializing with chain-id: $CHAIN_ID"
    $BINARY init "$MONIKER" --chain-id "$CHAIN_ID" --home "$HOME_DIR"
    
    # Step 2: Create genesis account key
    echo "🔑 Creating genesis account..."
    $BINARY keys add "$KEY_NAME" --home "$HOME_DIR" --keyring-backend "$KEYRING_BACKEND" > /home/speculod/genesis_account.txt 2>&1
    
    # Extract account address
    ACCOUNT_ADDRESS=$(grep -A 10 "^- address:" /home/speculod/genesis_account.txt | grep "address:" | cut -d' ' -f3)
    echo "   ✓ Genesis account created: $ACCOUNT_ADDRESS"
    
    # Step 3: Add genesis account to genesis file
    echo "💰 Adding genesis account with initial funds..."
    $BINARY genesis add-genesis-account "$KEY_NAME" "$GENESIS_COINS" --home "$HOME_DIR" --keyring-backend "$KEYRING_BACKEND"
    echo "   ✓ Added $GENESIS_COINS to account"
    
    # Step 4: Create genesis transaction (gentx)
    echo "👑 Creating validator genesis transaction..."
    $BINARY genesis gentx "$KEY_NAME" "$STAKING_AMOUNT" --home "$HOME_DIR" --keyring-backend "$KEYRING_BACKEND" --chain-id "$CHAIN_ID"
    echo "   ✓ Genesis transaction created"
    
    # Step 5: Collect genesis transactions
    echo "📚 Collecting genesis transactions..."
    $BINARY genesis collect-gentxs --home "$HOME_DIR"
    echo "   ✓ Genesis transactions collected"
    
    echo ""
    echo "🎉 Blockchain initialization complete!"
fi

# Configure for containerized environment
echo "🐳 Configuring for Docker environment..."

# Update config for external access
CONFIG_FILE="$HOME_DIR/config/config.toml"
APP_CONFIG_FILE="$HOME_DIR/config/app.toml"

if [ -f "$CONFIG_FILE" ]; then
    # Allow external connections
    sed -i 's/laddr = "tcp:\/\/127.0.0.1:26657"/laddr = "tcp:\/\/0.0.0.0:26657"/g' "$CONFIG_FILE"
    sed -i 's/laddr = "tcp:\/\/0.0.0.0:26656"/laddr = "tcp:\/\/0.0.0.0:26656"/g' "$CONFIG_FILE"
    echo "   ✓ RPC configured for external access"
fi

if [ -f "$APP_CONFIG_FILE" ]; then
    # Configure API server for external access
    sed -i 's/address = "tcp:\/\/localhost:1317"/address = "tcp:\/\/0.0.0.0:1317"/g' "$APP_CONFIG_FILE"
    sed -i 's/address = "localhost:9090"/address = "0.0.0.0:9090"/g' "$APP_CONFIG_FILE"
    echo "   ✓ API and gRPC configured for external access"
fi

echo ""
echo "=================================================="
echo "🚀 STARTING SPECULOD BLOCKCHAIN NODE"
echo "=================================================="
echo ""
echo "🔗 Container Endpoints:"
echo "   • RPC: http://0.0.0.0:26657"
echo "   • API: http://0.0.0.0:1317"
echo "   • gRPC: 0.0.0.0:9090"
echo "   • P2P: 0.0.0.0:26656"
echo ""
echo "📊 To check status from host:"
echo "   curl http://localhost:26657/status"
echo ""

# Start the blockchain node
exec $BINARY start \
    --home "$HOME_DIR" \
    --minimum-gas-prices="$MIN_GAS_PRICES"
