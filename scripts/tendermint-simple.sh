#!/bin/sh

# Simple Tendermint RPC Service - Cloud Run Compatible
set -e

echo "Starting Simple Tendermint RPC Service..."

# Cloud Run port configuration
PORT=${PORT:-8080}
echo "Using port: $PORT"

# Default environment variables
export MONIKER=${MONIKER:-"tendermint-node"}
export CHAIN_ID=${CHAIN_ID:-"speculod-testnet"}

# Home directory setup
export HOME=/home/speculod
SPECULOD_HOME="$HOME/.speculod"

echo "Tendermint home: $SPECULOD_HOME"

# Initialize blockchain if not exists
if [ ! -f "$SPECULOD_HOME/config/genesis.json" ]; then
    echo "Initializing blockchain with validator..."
    
    # Initialize chain
    speculodd init $MONIKER --chain-id $CHAIN_ID --home $SPECULOD_HOME
    
    # Create genesis account
    echo "Creating genesis account..."
    speculodd keys add alice --keyring-backend test --home $SPECULOD_HOME
    
    # Add genesis account with initial balance
    speculodd genesis add-genesis-account alice 100000000000stake --keyring-backend test --home $SPECULOD_HOME
    
    # Create genesis validator transaction
    speculodd genesis gentx alice 1000000stake --keyring-backend test --chain-id $CHAIN_ID --home $SPECULOD_HOME
    
    # Collect genesis transactions
    speculodd genesis collect-gentxs --home $SPECULOD_HOME
    
    # Configure RPC to bind to all interfaces on the specified port
    sed -i "s/laddr = \"tcp:\/\/127.0.0.1:26657\"/laddr = \"tcp:\/\/0.0.0.0:$PORT\"/" $SPECULOD_HOME/config/config.toml
    
    # Set minimum gas prices
    sed -i 's/minimum-gas-prices = ""/minimum-gas-prices = "0.0001stake"/' $SPECULOD_HOME/config/app.toml
    
    echo "Blockchain initialized with validator"
else
    echo "Blockchain already initialized"
    # Update port configuration in case it changed
    sed -i "s/laddr = \"tcp:\/\/.*:26657\"/laddr = \"tcp:\/\/0.0.0.0:$PORT\"/" $SPECULOD_HOME/config/config.toml
fi

echo "Starting Tendermint RPC server on port $PORT..."
echo "RPC endpoint: http://0.0.0.0:$PORT"
echo "Status endpoint: http://0.0.0.0:$PORT/status"

# Start with minimal Tendermint RPC only
exec speculodd start \
    --home=$SPECULOD_HOME \
    --rpc.laddr=tcp://0.0.0.0:$PORT \
    --api.enable=false \
    --grpc.enable=false \
    --moniker="$MONIKER"
