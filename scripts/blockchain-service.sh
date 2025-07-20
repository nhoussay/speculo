#!/bin/bash

# Blockchain Service Startup Script - Cloud Run Compatible

set -e

echo "Starting Speculod Blockchain Core Service..."

# Cloud Run port configuration
PORT=${PORT:-8080}
echo "Using port: $PORT"

# Initialize chain if not already done
if [ ! -f "$HOME_DIR/config/genesis.json" ]; then
    echo "Initializing blockchain..."
    
    # Initialize chain
    speculodd init $MONIKER --chain-id $CHAIN_ID --home $HOME_DIR
    
    # Add genesis account (non-sensitive default for demo)
    speculodd keys add alice --keyring-backend $KEYRING_BACKEND --home $HOME_DIR
    speculodd genesis add-genesis-account alice 100000000000stake --keyring-backend $KEYRING_BACKEND --home $HOME_DIR
    speculodd genesis gentx alice 1000000stake --keyring-backend $KEYRING_BACKEND --chain-id $CHAIN_ID --home $HOME_DIR
    speculodd genesis collect-gentxs --home $HOME_DIR
    
    # Configure RPC to use standard port (26657) and bind to all interfaces
    sed -i "s/laddr = \"tcp:\/\/127.0.0.1:26657\"/laddr = \"tcp:\/\/0.0.0.0:26657\"/" $HOME_DIR/config/config.toml
    
    # Configure API server to use Cloud Run port
    sed -i "s/address = \"tcp:\/\/localhost:1317\"/address = \"tcp:\/\/0.0.0.0:$PORT\"/" $HOME_DIR/config/app.toml
    
    echo "Blockchain initialized successfully"
else
    echo "Blockchain already initialized"
    # Update port configuration in case it changed
    sed -i "s/laddr = \"tcp:\/\/.*:26657\"/laddr = \"tcp:\/\/0.0.0.0:26657\"/" $HOME_DIR/config/config.toml
    sed -i "s/address = \"tcp:\/\/.*:1317\"/address = \"tcp:\/\/0.0.0.0:$PORT\"/" $HOME_DIR/config/app.toml
fi

# Configure for production - Enable API server
sed -i 's/enable = false/enable = true/' $HOME_DIR/config/app.toml
sed -i 's/swagger = false/swagger = true/' $HOME_DIR/config/app.toml

# Configure CORS for cross-service communication
sed -i 's/enabled-unsafe-cors = false/enabled-unsafe-cors = true/' $HOME_DIR/config/app.toml

# Set minimum gas prices
sed -i 's/minimum-gas-prices = ""/minimum-gas-prices = "0.0001stake"/' $HOME_DIR/config/app.toml

echo "Starting blockchain node..."
echo "API Server: http://0.0.0.0:$PORT"
echo "RPC Server: http://0.0.0.0:26657"
echo "Health endpoint: http://0.0.0.0:$PORT/cosmos/base/tendermint/v1beta1/node_info"

# Start the blockchain node - API server will handle port 8080, RPC on 26657
exec speculodd start --home $HOME_DIR --minimum-gas-prices "0.0001stake"
