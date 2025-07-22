#!/bin/bash

# Enhanced blockchain startup script with shared genesis configuration
# This script ensures all nodes use the same genesis.json file

set -e

SERVICE_TYPE=${SERVICE_TYPE:-"all"}
NODE_TYPE=${NODE_TYPE:-"standalone"}
PORT=${PORT:-8080}
CHAIN_ID=${CHAIN_ID:-"speculod"}
MONIKER=${MONIKER:-"speculod-node"}
HOME_DIR=${HOME_DIR:-"/home/speculod/.speculod"}
KEYRING_BACKEND=${KEYRING_BACKEND:-"test"}

# P2P Configuration
PERSISTENT_PEER_HOST=${PERSISTENT_PEER_HOST:-""}
PERSISTENT_PEER_PORT=${PERSISTENT_PEER_PORT:-"26656"}

# Shared genesis configuration  
GENESIS_SHARED_DIR="/shared/genesis"
SHARED_GENESIS_FILE="$GENESIS_SHARED_DIR/genesis.json"

echo "Starting Speculod Service: $SERVICE_TYPE"
echo "Node Type: $NODE_TYPE"
echo "Using port: $PORT"
echo "Chain ID: $CHAIN_ID"
echo "Home directory: $HOME_DIR"

# Initialize node if not already done
if [ ! -f "$HOME_DIR/config/config.toml" ]; then
    echo "Initializing node configuration..."
    speculodd init $MONIKER --chain-id $CHAIN_ID --home $HOME_DIR
fi

# Handle genesis creation and sharing based on node type
case $NODE_TYPE in
    "persistent")
        echo "Setting up persistent node (genesis coordinator)"
        
        # Check if shared genesis already exists
        if [ ! -f "$SHARED_GENESIS_FILE" ]; then
            echo "Creating shared genesis configuration..."
            
            # Add accounts for testing
            echo "century toddler mystery need salt embody orient dilemma armed crush skirt tail tired blouse apart number empower rapid high weird already penalty turtle drama" | \
            speculodd keys add alice --recover --keyring-backend $KEYRING_BACKEND --home $HOME_DIR
            
            # Add genesis account
            speculodd genesis add-genesis-account alice 100000000000stake --keyring-backend $KEYRING_BACKEND --home $HOME_DIR
            
            # Create genesis transaction
            speculodd genesis gentx alice 1000000stake --keyring-backend $KEYRING_BACKEND --chain-id $CHAIN_ID --home $HOME_DIR
            
            # Collect genesis transactions
            speculodd genesis collect-gentxs --home $HOME_DIR
            
            # Copy the genesis file to shared location
            cp "$HOME_DIR/config/genesis.json" "$SHARED_GENESIS_FILE"
            
            echo "Shared genesis created and saved to $SHARED_GENESIS_FILE"
        else
            echo "Using existing shared genesis file"
            # Copy shared genesis to this node
            cp "$SHARED_GENESIS_FILE" "$HOME_DIR/config/genesis.json"
        fi
        
        # Configure RPC to listen on all interfaces for peer discovery
        sed -i 's|laddr = "tcp://127.0.0.1:26657"|laddr = "tcp://0.0.0.0:26657"|g' ~/.speculod/config/config.toml
        ;;
        
    "peer")
        echo "Setting up peer node (will use shared genesis)"
        
        # Wait for persistent node to create shared genesis
        timeout=180
        counter=0
        while [ ! -f "$SHARED_GENESIS_FILE" ] && [ $counter -lt $timeout ]; do
            echo "Waiting for shared genesis file... ($counter/$timeout)"
            sleep 2
            counter=$((counter + 2))
        done
        
        if [ ! -f "$SHARED_GENESIS_FILE" ]; then
            echo "Timeout waiting for shared genesis file"
            exit 1
        fi
        
        echo "Using shared genesis file from persistent node"
        cp "$SHARED_GENESIS_FILE" "$HOME_DIR/config/genesis.json"
        
        # Add the same test account for this node
        echo "century toddler mystery need salt embody orient dilemma armed crush skirt tail tired blouse apart number empower rapid high weird already penalty turtle drama" | \
        speculodd keys add alice --recover --keyring-backend $KEYRING_BACKEND --home $HOME_DIR
        
        # Wait for persistent node to be ready for P2P connections
        echo "Waiting for persistent node to be ready..."
        timeout=120
        counter=0
        while [ $counter -lt $timeout ]; do
            if curl -s "http://$PERSISTENT_PEER_HOST:26657/status" >/dev/null 2>&1; then
                echo "Persistent node is ready!"
                break
            fi
            echo "Waiting for persistent node... ($counter/$timeout)"
            sleep 2
            counter=$((counter + 2))
        done
        
        if [ $counter -ge $timeout ]; then
            echo "Timeout waiting for persistent node"
            exit 1
        fi
        
        # Get the node ID from the persistent node
        echo "Getting node ID from persistent node..."
        NODE_ID=$(curl -s "http://$PERSISTENT_PEER_HOST:26657/status" | jq -r '.result.node_info.id')
        
        if [ "$NODE_ID" != "null" ] && [ -n "$NODE_ID" ]; then
            PERSISTENT_PEERS="${NODE_ID}@${PERSISTENT_PEER_HOST}:${PERSISTENT_PEER_PORT}"
            echo "Setting persistent peer: $PERSISTENT_PEERS"
            export PERSISTENT_PEERS
        else
            echo "Failed to get node ID from persistent node"
            exit 1
        fi
        ;;
        
    *)
        echo "Starting as standalone node"
        # For standalone, create own genesis if needed
        if [ ! -f "$HOME_DIR/config/genesis.json" ]; then
            echo "century toddler mystery need salt embody orient dilemma armed crush skirt tail tired blouse apart number empower rapid high weird already penalty turtle drama" | \
            speculodd keys add alice --recover --keyring-backend $KEYRING_BACKEND --home $HOME_DIR
            speculodd genesis add-genesis-account alice 100000000000stake --keyring-backend $KEYRING_BACKEND --home $HOME_DIR
            speculodd genesis gentx alice 1000000stake --keyring-backend $KEYRING_BACKEND --chain-id $CHAIN_ID --home $HOME_DIR
            speculodd genesis collect-gentxs --home $HOME_DIR
        fi
        ;;
esac

echo "Starting blockchain with NODE_TYPE: $NODE_TYPE"

# Start the blockchain with appropriate flags
echo "Starting speculodd..."

# Build the start command with necessary flags
START_CMD="speculodd start --home $HOME_DIR --minimum-gas-prices 0.001stake"

# Add persistent peers if configured
if [ -n "$PERSISTENT_PEERS" ]; then
    START_CMD="$START_CMD --p2p.persistent_peers $PERSISTENT_PEERS"
fi

echo "Executing: $START_CMD"
exec $START_CMD
