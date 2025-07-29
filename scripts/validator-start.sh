#!/bin/sh

# Smart Validator Startup Script
set -e

echo "🔗 Starting Speculod Validator Service..."

# Configuration
export NODE_HOME="/home/speculod/.speculod"
export CHAIN_ID="speculod-local-1"
export MONIKER="local-persistent-validator"
export KEY_NAME="validator"

# Function to clean up existing state on initialization error
cleanup_on_error() {
    echo "⚠️ Cleaning up existing state due to initialization error..."
    rm -rf "$NODE_HOME/config/genesis.json"
    rm -rf "$NODE_HOME/config/gentx"
    rm -rf "$NODE_HOME/keyring-test"
}

# Check if node is already initialized and working
if [ ! -f "$NODE_HOME/config/genesis.json" ] || [ ! -d "$NODE_HOME/config/gentx" ]; then
    echo "🏗️ Initializing new blockchain node..."
    
    # Ensure clean state
    cleanup_on_error
    
    # Initialize the node
    speculodd init $MONIKER --chain-id $CHAIN_ID --home $NODE_HOME --overwrite
    
    # Create validator key (ignore if exists)
    speculodd keys add $KEY_NAME --keyring-backend test --home $NODE_HOME 2>/dev/null || echo "Key already exists, continuing..."
    
    # Get the validator address
    VALIDATOR_ADDRESS=$(speculodd keys show $KEY_NAME -a --keyring-backend test --home $NODE_HOME)
    echo "🔑 Using validator address: $VALIDATOR_ADDRESS"
    
    # Add genesis account
    speculodd add-genesis-account $VALIDATOR_ADDRESS 1000000000000stake --home $NODE_HOME
    
    # Create genesis transaction
    speculodd gentx $KEY_NAME 500000000000stake \
        --keyring-backend test \
        --chain-id $CHAIN_ID \
        --home $NODE_HOME \
        --from $VALIDATOR_ADDRESS
    
    # Collect genesis transactions
    speculodd collect-gentxs --home $NODE_HOME
    
    # Validate genesis
    speculodd validate-genesis --home $NODE_HOME
    
    echo "✅ Node initialization completed"
else
    echo "✅ Node already initialized, skipping setup"
fi

# Start the validator
echo "🚀 Starting validator node..."
exec speculodd start \
    --home $NODE_HOME \
    --rpc.laddr tcp://0.0.0.0:26657 \
    --api.enable \
    --api.enabled-unsafe-cors \
    --api.address tcp://0.0.0.0:1317 \
    --grpc.address 0.0.0.0:9090 \
    --p2p.laddr tcp://0.0.0.0:26656 \
    --minimum-gas-prices 0.001stake
