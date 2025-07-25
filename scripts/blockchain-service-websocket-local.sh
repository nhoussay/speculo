#!/bin/bash

# Simple blockchain startup script for local WebSocket bridge development
# Based on start_chain_working.sh but adapted for Docker containers

set -e

echo "🚀 Speculod Local WebSocket Node Startup"
echo "========================================"

# Configuration
CHAIN_ID=${CHAIN_ID:-"speculod-local"}
MONIKER=${MONIKER:-"local-websocket-node"}
HOME_DIR=${HOME_DIR:-"/home/speculod/.speculod"}
KEYRING="test"
GENESIS_ACCOUNT_NAME="alice"
GENESIS_ACCOUNT_COINS="100000000stake"

echo "📋 Configuration:"
echo "   Chain ID: $CHAIN_ID"
echo "   Moniker: $MONIKER"
echo "   Home Directory: $HOME_DIR"
echo ""

# Clean any existing data
if [ -d "$HOME_DIR" ]; then
  echo "🧹 Removing existing chain data in $HOME_DIR..."
  rm -rf "$HOME_DIR"
fi

echo "🏗️  Initializing blockchain..."
speculodd init $MONIKER --chain-id $CHAIN_ID --home $HOME_DIR
echo "✅ Chain initialized successfully."

echo ""
echo "👤 Creating genesis account '$GENESIS_ACCOUNT_NAME'..."
# Use a known mnemonic for consistency in development
echo "century toddler mystery need salt embody orient dilemma armed crush skirt tail tired blouse apart number empower rapid high weird already penalty turtle drama" | \
speculodd keys add $GENESIS_ACCOUNT_NAME --recover --keyring-backend $KEYRING --home $HOME_DIR

GENESIS_ACCOUNT_ADDR=$(speculodd keys show $GENESIS_ACCOUNT_NAME -a --keyring-backend $KEYRING --home $HOME_DIR)
echo "✅ Genesis account recovered:"
echo "   Name: $GENESIS_ACCOUNT_NAME"
echo "   Address: $GENESIS_ACCOUNT_ADDR"

echo ""
echo "💰 Adding genesis account to blockchain..."
speculodd genesis add-genesis-account $GENESIS_ACCOUNT_NAME $GENESIS_ACCOUNT_COINS --home $HOME_DIR --keyring-backend $KEYRING

echo ""
echo "🏛️ Creating validator genesis transaction..."
speculodd genesis gentx $GENESIS_ACCOUNT_NAME 1000000stake --keyring-backend $KEYRING --chain-id $CHAIN_ID --home $HOME_DIR

echo ""
echo "📝 Collecting genesis transactions..."
speculodd genesis collect-gentxs --home $HOME_DIR

echo ""
echo "✅ Validating genesis configuration..."
speculodd genesis validate-genesis --home $HOME_DIR
echo "✅ Genesis file is valid."

# Configure RPC to listen on all interfaces
echo "🔧 Configuring RPC to listen on all interfaces..."
sed -i 's|laddr = "tcp://127.0.0.1:26657"|laddr = "tcp://0.0.0.0:26657"|g' "$HOME_DIR/config/config.toml"
sed -i 's|laddr = "tcp://0.0.0.0:26656"|laddr = "tcp://0.0.0.0:26656"|g' "$HOME_DIR/config/config.toml"

# Configure API to be accessible
echo "🔧 Configuring API to be accessible..."
sed -i 's|address = "tcp://localhost:1317"|address = "tcp://0.0.0.0:1317"|g' "$HOME_DIR/config/app.toml"
sed -i 's|enable = false|enable = true|g' "$HOME_DIR/config/app.toml"

# Configure gRPC to be accessible  
sed -i 's|address = "localhost:9090"|address = "0.0.0.0:9090"|g' "$HOME_DIR/config/app.toml"

echo ""
echo "🚀 Starting Speculod blockchain node..."
echo "   - API Server: http://0.0.0.0:1317"
echo "   - RPC Server: http://0.0.0.0:26657"
echo "   - gRPC Server: 0.0.0.0:9090"
echo "   - P2P: 0.0.0.0:26656"
echo ""

# Start with flags for development
exec speculodd start \
  --home $HOME_DIR \
  --minimum-gas-prices=0.025stake \
  --api.enable=true \
  --api.swagger=true \
  --grpc.enable=true \
  --rpc.laddr=tcp://0.0.0.0:26657 \
  --api.address=tcp://0.0.0.0:1317 \
  --grpc.address=0.0.0.0:9090 \
  --log_level=info
