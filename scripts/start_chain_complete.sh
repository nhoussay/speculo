#!/bin/bash

# Complete Speculod Blockchain Startup Script
# This script initializes and starts the Speculod blockchain with validator

set -e  # Exit on any error

echo "=================================================="
echo "🚀 SPECULOD BLOCKCHAIN STARTUP SCRIPT"
echo "=================================================="

# Configuration
CHAIN_ID="speculod"
MONIKER="mynode"
HOME_DIR=".speculod"
KEY_NAME="alice"
KEYRING_BACKEND="test"
GENESIS_COINS="1000000000000stake"
STAKING_AMOUNT="500000000stake"
MIN_GAS_PRICES="0stake"

echo "📋 Configuration:"
echo "   Chain ID: $CHAIN_ID"
echo "   Moniker: $MONIKER"
echo "   Home Directory: $HOME_DIR"
echo "   Key Name: $KEY_NAME"
echo ""

# Step 1: Clean previous setup
echo "🧹 Cleaning previous blockchain data..."
if [ -d "$HOME_DIR" ]; then
    rm -rf "$HOME_DIR"
    echo "   ✓ Removed existing $HOME_DIR"
fi

# Step 2: Build the binary
echo "🔨 Building speculodd binary..."
if ! make build; then
    echo "❌ Failed to build speculodd binary"
    exit 1
fi
echo "   ✓ Binary built successfully"

# Step 3: Initialize the chain
echo "🏗️  Initializing blockchain..."
if ! ./speculodd init "$MONIKER" --chain-id "$CHAIN_ID" --home "$HOME_DIR" > /dev/null; then
    echo "❌ Failed to initialize blockchain"
    exit 1
fi
echo "   ✓ Blockchain initialized with chain-id: $CHAIN_ID"

# Step 4: Create genesis account key
echo "🔑 Creating genesis account..."
if ! ./speculodd keys add "$KEY_NAME" --home "$HOME_DIR" --keyring-backend "$KEYRING_BACKEND" > genesis_account.txt 2>&1; then
    echo "❌ Failed to create genesis account"
    exit 1
fi

# Extract account address
ACCOUNT_ADDRESS=$(grep -A 10 "^- address:" genesis_account.txt | grep "address:" | cut -d' ' -f3)
if [ -z "$ACCOUNT_ADDRESS" ]; then
    echo "❌ Failed to extract account address"
    exit 1
fi

echo "   ✓ Genesis account created: $ACCOUNT_ADDRESS"
echo "   ✓ Account details saved to genesis_account.txt"

# Step 5: Add genesis account to genesis file
echo "💰 Adding genesis account with initial funds..."
if ! ./speculodd genesis add-genesis-account "$KEY_NAME" "$GENESIS_COINS" --home "$HOME_DIR" --keyring-backend "$KEYRING_BACKEND"; then
    echo "❌ Failed to add genesis account"
    exit 1
fi
echo "   ✓ Added $GENESIS_COINS to account $ACCOUNT_ADDRESS"

# Step 6: Create genesis transaction (gentx)
echo "👑 Creating validator genesis transaction..."
if ! ./speculodd genesis gentx "$KEY_NAME" "$STAKING_AMOUNT" --home "$HOME_DIR" --keyring-backend "$KEYRING_BACKEND" --chain-id "$CHAIN_ID"; then
    echo "❌ Failed to create genesis transaction"
    exit 1
fi
echo "   ✓ Genesis transaction created with stake: $STAKING_AMOUNT"

# Step 7: Collect genesis transactions
echo "📚 Collecting genesis transactions..."
if ! ./speculodd genesis collect-gentxs --home "$HOME_DIR"; then
    echo "❌ Failed to collect genesis transactions"
    exit 1
fi
echo "   ✓ Genesis transactions collected successfully"

# Step 8: Start the blockchain
echo ""
echo "=================================================="
echo "🎉 BLOCKCHAIN INITIALIZATION COMPLETE!"
echo "=================================================="
echo ""
echo "📊 Summary:"
echo "   • Chain ID: $CHAIN_ID"
echo "   • Genesis Account: $ACCOUNT_ADDRESS"
echo "   • Initial Balance: $GENESIS_COINS"
echo "   • Validator Stake: $STAKING_AMOUNT"
echo "   • Account Details: saved in genesis_account.txt"
echo ""
echo "🔗 Endpoints (once started):"
echo "   • RPC: http://localhost:26657"
echo "   • API: http://localhost:1317"  
echo "   • gRPC: localhost:9090"
echo ""
echo "🚀 Starting blockchain node..."
echo "   (Press Ctrl+C to stop)"
echo ""

# Start the node
exec ./speculodd start \
    --home "$HOME_DIR" \
    --minimum-gas-prices="$MIN_GAS_PRICES"
