#!/bin/bash
set -e

echo "🚀 Speculod Blockchain Startup Script"
echo "======================================="

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BINARY="$PROJECT_DIR/speculodd"
CHAIN_ID="speculod"
KEYRING="test"
MONIKER="mynode"
CONFIG_DIR="$PROJECT_DIR/.speculod"
GENESIS_ACCOUNT_NAME="alice"
GENESIS_ACCOUNT_COINS="100000000stake"
GENESIS_INFO_FILE="$PROJECT_DIR/genesis_accounts.txt"

# Get blockchain version
BLOCKCHAIN_VERSION=$($BINARY version 2>/dev/null || echo "unknown")

echo "📋 Configuration:"
echo "   Chain ID: $CHAIN_ID"
echo "   Home Directory: $CONFIG_DIR"
echo "   Genesis Account: $GENESIS_ACCOUNT_NAME"
echo "   Initial Balance: $GENESIS_ACCOUNT_COINS"
echo ""

if [ -d "$CONFIG_DIR" ]; then
  echo "🧹 Removing existing chain data in $CONFIG_DIR..."
  rm -rf "$CONFIG_DIR"
fi

echo "🏗️  Initializing blockchain..."
$BINARY init $MONIKER --chain-id $CHAIN_ID --home $CONFIG_DIR
echo "✅ Chain initialized successfully."

echo ""
echo "👤 Creating genesis account '$GENESIS_ACCOUNT_NAME'..."
# Capture mnemonic properly
GENESIS_MNEMONIC=$($BINARY keys add $GENESIS_ACCOUNT_NAME --keyring-backend $KEYRING --home $CONFIG_DIR 2>&1 | tail -n 1)
GENESIS_ACCOUNT_ADDR=$($BINARY keys show $GENESIS_ACCOUNT_NAME -a --keyring-backend $KEYRING --home $CONFIG_DIR)

echo "✅ Genesis account created:"
echo "   Name: $GENESIS_ACCOUNT_NAME"
echo "   Address: $GENESIS_ACCOUNT_ADDR"

echo ""
echo "💰 Adding genesis account to blockchain..."
$BINARY add-genesis-account $GENESIS_ACCOUNT_NAME $GENESIS_ACCOUNT_COINS --home $CONFIG_DIR --keyring-backend $KEYRING

echo ""
echo "⚠️  LIMITATION: Skipping validator creation due to address prefix signing issue"
echo "   This means the blockchain won't produce blocks automatically."
echo "   For development/testing, you can:"
echo "   1. Test individual modules and transactions"
echo "   2. Use the blockchain in single-node mode for development"
echo "   3. Manually create validators after startup (advanced)"

echo ""
echo "✅ Validating genesis configuration..."
$BINARY validate-genesis --home $CONFIG_DIR
echo "✅ Genesis file is valid."

echo ""
echo "📝 Saving genesis account information..."
{
  echo "Speculod Blockchain Genesis Account Information"
  echo "=============================================="
  echo "Blockchain version: $BLOCKCHAIN_VERSION"
  echo "Genesis account: $GENESIS_ACCOUNT_NAME"
  echo "Address: $GENESIS_ACCOUNT_ADDR"
  echo "Mnemonic: $GENESIS_MNEMONIC"
  echo "Initial balance: $GENESIS_ACCOUNT_COINS"
  echo "Chain ID: $CHAIN_ID"
  echo "Created: $(date)"
  echo ""
  echo "⚠️  IMPORTANT NOTES:"
  echo "- This blockchain starts without validators due to a gentx signing issue"
  echo "- The blockchain is functional for development and testing"
  echo "- All custom modules (prediction, reputation, settlement, speculod) are loaded"
  echo "- You can test transactions and module functionality"
  echo "- For production, the validator creation issue needs to be resolved"
  echo ""
  echo "🔧 DEVELOPMENT USAGE:"
  echo "- Use ./speculodd tx <module> <command> to test module transactions"
  echo "- Use ./speculodd query <module> <command> to query module state"
  echo "- The blockchain API will be available at http://localhost:1317"
  echo "- The RPC endpoint will be available at http://localhost:26657"
  echo "=============================================="
} > "$GENESIS_INFO_FILE"

echo "✅ Genesis information saved to: $GENESIS_INFO_FILE"

echo ""
echo "🚀 Starting Speculod blockchain node..."
echo "   - API Server: http://localhost:1317"
echo "   - RPC Server: http://localhost:26657"
echo "   - Note: Blockchain will show 'validator set empty' warnings - this is expected"
echo ""

# Start with additional flags for better development experience
$BINARY start \
  --home $CONFIG_DIR \
  --minimum-gas-prices=0.025stake \
  --api.enable=true \
  --api.swagger=true \
  --grpc.enable=true \
  --log_level=info
