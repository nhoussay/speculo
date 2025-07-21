#!/bin/bash

# Simple blockchain startup script for testing
# Minimal configuration without complex sed operations

set -e

SERVICE_TYPE=${SERVICE_TYPE:-"all"}
NODE_TYPE=${NODE_TYPE:-"standalone"}
PORT=${PORT:-8080}
CHAIN_ID=${CHAIN_ID:-"speculod"}
MONIKER=${MONIKER:-"speculod-node"}
HOME_DIR=${HOME_DIR:-"/home/speculod/.speculod"}
KEYRING_BACKEND=${KEYRING_BACKEND:-"test"}

echo "Starting Speculod Service: $SERVICE_TYPE"
echo "Node Type: $NODE_TYPE"
echo "Using port: $PORT"
echo "Chain ID: $CHAIN_ID"
echo "Home directory: $HOME_DIR"

# Initialize chain if not already done
if [ ! -f "$HOME_DIR/config/genesis.json" ]; then
    echo "Initializing blockchain..."
    
    # Initialize chain
    speculodd init $MONIKER --chain-id $CHAIN_ID --home $HOME_DIR
    
    # Add accounts for testing
    echo "century toddler mystery need salt embody orient dilemma armed crush skirt tail tired blouse apart number empower rapid high weird already penalty turtle drama" | \
    speculodd keys add alice --recover --keyring-backend $KEYRING_BACKEND --home $HOME_DIR

    # Add genesis account
    speculodd genesis add-genesis-account alice 100000000000stake --keyring-backend $KEYRING_BACKEND --home $HOME_DIR

    # Create genesis transaction
    speculodd genesis gentx alice 1000000stake --keyring-backend $KEYRING_BACKEND --chain-id $CHAIN_ID --home $HOME_DIR

    # Collect genesis transactions
    speculodd genesis collect-gentxs --home $HOME_DIR
    
    echo "Blockchain initialized successfully"
fi

echo "Starting blockchain with NODE_TYPE: $NODE_TYPE"

case $NODE_TYPE in
    "persistent")
        echo "Starting as persistent node (bootstrap/seed)"
        ;;
    "peer")
        echo "Starting as peer node"
        ;;
    *)
        echo "Starting as standalone node"
        ;;
esac

# Start the blockchain
echo "Starting speculodd..."
exec speculodd start --home $HOME_DIR
