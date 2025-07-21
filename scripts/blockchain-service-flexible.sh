#!/bin/bash

# Service-Aware Blockchain Startup Script
# Supports different service types: tendermint, rest-api, grpc, or all
# Supports persistent peer configuration for multi-node networks

set -e

SERVICE_TYPE=${SERVICE_TYPE:-"all"}
NODE_TYPE=${NODE_TYPE:-"standalone"}  # standalone, persistent, or peer
PORT=${PORT:-8080}
CHAIN_ID=${CHAIN_ID:-"speculod"}
MONIKER=${MONIKER:-"speculod-node"}
HOME_DIR=${HOME_DIR:-"/home/speculod/.speculod"}
KEYRING_BACKEND=${KEYRING_BACKEND:-"test"}

# P2P Configuration
P2P_LADDR=${P2P_LADDR:-"tcp://0.0.0.0:26656"}
RPC_LADDR=${RPC_LADDR:-"tcp://0.0.0.0:26657"}
PERSISTENT_PEERS=${PERSISTENT_PEERS:-""}
SEEDS=${SEEDS:-""}
EXTERNAL_ADDRESS=${EXTERNAL_ADDRESS:-""}
MAX_NUM_INBOUND_PEERS=${MAX_NUM_INBOUND_PEERS:-40}
MAX_NUM_OUTBOUND_PEERS=${MAX_NUM_OUTBOUND_PEERS:-10}

echo "Starting Speculod Service: $SERVICE_TYPE"
echo "Node Type: $NODE_TYPE"
echo "Using port: $PORT"
echo "Chain ID: $CHAIN_ID"
echo "Home directory: $HOME_DIR"
echo "P2P Listen Address: $P2P_LADDR"
echo "RPC Listen Address: $RPC_LADDR"

# Enable debug mode to find the problematic sed command
set -x

if [ -n "$PERSISTENT_PEERS" ]; then
    echo "Persistent Peers: $PERSISTENT_PEERS"
fi

if [ -n "$SEEDS" ]; then
    echo "Seeds: $SEEDS"  
fi

if [ -n "$EXTERNAL_ADDRESS" ]; then
    echo "External Address: $EXTERNAL_ADDRESS"
fi

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
    
    echo "Blockchain initialized successfully"
fi

# Configure P2P settings based on node type
echo "Configuring P2P settings for node type: $NODE_TYPE"

# Add debug tracing
set -x

# Configure based on node type
echo "About to enter NODE_TYPE case statement"
case $NODE_TYPE in
    "persistent")
        echo "Configuring as persistent node (seed/bootstrap node)..."
        # Enable as seed node
        sed -i 's/seed_mode = false/seed_mode = true/' $HOME_DIR/config/config.toml
        # Higher peer limits for persistent nodes
        sed -i "s/max_num_inbound_peers = [0-9]*/max_num_inbound_peers = 100/" $HOME_DIR/config/config.toml
        sed -i "s/max_num_outbound_peers = [0-9]*/max_num_outbound_peers = 50/" $HOME_DIR/config/config.toml
        # Enable addr book
        sed -i 's/addr_book_strict = true/addr_book_strict = false/' $HOME_DIR/config/config.toml
        echo "Node configured as persistent seed node"
        ;;
        
    "peer")
        echo "Configuring as peer node (connects to persistent peers)..."
        # Configure persistent peers
        if [ -n "$PERSISTENT_PEERS" ]; then
            sed -i 's/persistent_peers = ""/persistent_peers = "'"$PERSISTENT_PEERS"'"/' $HOME_DIR/config/config.toml
            echo "Persistent peers configured: $PERSISTENT_PEERS"
        fi
        
        # Configure seeds
        if [ -n "$SEEDS" ]; then
            sed -i 's/seeds = ""/seeds = "'"$SEEDS"'"/' $HOME_DIR/config/config.toml
            echo "Seeds configured: $SEEDS"
        fi
        
        # Disable seed mode
        sed -i 's/seed_mode = true/seed_mode = false/' $HOME_DIR/config/config.toml
        echo "Node configured to connect to persistent peers"
        ;;
        
    "standalone"|*)
        echo "Configuring as standalone node..."
        # Clear persistent peers and seeds for standalone mode
        sed -i 's/persistent_peers = ".*"/persistent_peers = ""/' $HOME_DIR/config/config.toml
        sed -i 's/seeds = ".*"/seeds = ""/' $HOME_DIR/config/config.toml
        sed -i 's/seed_mode = true/seed_mode = false/' $HOME_DIR/config/config.toml
        echo "Node configured in standalone mode"
        ;;
esac

# Configure external address if provided
if [ -n "$EXTERNAL_ADDRESS" ]; then
    sed -i 's/external_address = ""/external_address = "'"$EXTERNAL_ADDRESS"'"/' $HOME_DIR/config/config.toml
    echo "External address configured: $EXTERNAL_ADDRESS"
fi

# Configure based on service type
case $SERVICE_TYPE in
    "tendermint")
        echo "Configuring for Tendermint RPC service..."
        # Configure RPC to use specified address
        sed -i 's/laddr = "tcp:\/\/127\.0\.0\.1:26657"/laddr = "tcp:\/\/0.0.0.0:26657"/' $HOME_DIR/config/config.toml
        # Disable API and gRPC for this service
        sed -i 's/enable = true/enable = false/' $HOME_DIR/config/app.toml
        echo "Service endpoints:"
        echo "  Tendermint RPC: $RPC_LADDR"
        echo "  P2P: $P2P_LADDR"
        echo "  Status: ${RPC_LADDR//tcp:/http:}/status"
        ;;
        
    "rest-api")
        echo "Configuring for REST API service..."
        # Configure API server to use the specified port
        sed -i "s/address = \"tcp:\/\/.*:1317\"/address = \"tcp:\/\/0.0.0.0:$PORT\"/" $HOME_DIR/config/app.toml
        sed -i 's/enable = false/enable = true/' $HOME_DIR/config/app.toml
        sed -i 's/swagger = false/swagger = true/' $HOME_DIR/config/app.toml
        # Configure CORS
        sed -i 's/enabled-unsafe-cors = false/enabled-unsafe-cors = true/' $HOME_DIR/config/app.toml
        echo "Service endpoints:"
        echo "  REST API: http://0.0.0.0:$PORT"
        echo "  Health: http://0.0.0.0:$PORT/cosmos/base/tendermint/v1beta1/node_info"
        echo "  Swagger: http://0.0.0.0:$PORT/swagger/"
        ;;
        
    "grpc")
        echo "Configuring for gRPC service..."
        # Configure gRPC server
        sed -i 's/enable = false/enable = true/' $HOME_DIR/config/app.toml
        # Enable API for health checks
        sed -i "s/address = \"tcp:\/\/.*:1317\"/address = \"tcp:\/\/0.0.0.0:$PORT\"/" $HOME_DIR/config/app.toml
        echo "Service endpoints:"
        echo "  gRPC: http://0.0.0.0:9090"
        echo "  Health (REST): http://0.0.0.0:$PORT/cosmos/base/tendermint/v1beta1/node_info"
        ;;
        
    "all"|*)
        echo "Configuring for all services..."
        # Configure RPC
        sed -i.bak 's/laddr = "tcp:\/\/127\.0\.0\.1:26657"/laddr = "tcp:\/\/0.0.0.0:26657"/' $HOME_DIR/config/config.toml
        # Configure API server
        sed -i "s/address = \"tcp:\/\/.*:1317\"/address = \"tcp:\/\/0.0.0.0:$PORT\"/" $HOME_DIR/config/app.toml
        sed -i 's/enable = false/enable = true/' $HOME_DIR/config/app.toml
        sed -i 's/swagger = false/swagger = true/' $HOME_DIR/config/app.toml
        sed -i 's/enabled-unsafe-cors = false/enabled-unsafe-cors = true/' $HOME_DIR/config/app.toml
        echo "Service endpoints:"
        echo "  REST API: http://0.0.0.0:$PORT"
        echo "  Tendermint RPC: $RPC_LADDR"
        echo "  P2P: $P2P_LADDR"  
        echo "  gRPC: http://0.0.0.0:9090"
        echo "  Health: http://0.0.0.0:$PORT/cosmos/base/tendermint/v1beta1/node_info"
        ;;
esac

# Set minimum gas prices
sed -i 's/minimum-gas-prices = ""/minimum-gas-prices = "0.0001stake"/' $HOME_DIR/config/app.toml

echo "P2P Configuration Summary:"
echo "  Node Type: $NODE_TYPE"
echo "  P2P Listen: $P2P_LADDR"
echo "  RPC Listen: $RPC_LADDR"
if [ -n "$PERSISTENT_PEERS" ]; then
    echo "  Persistent Peers: $PERSISTENT_PEERS"
fi
if [ -n "$SEEDS" ]; then
    echo "  Seeds: $SEEDS"
fi
if [ -n "$EXTERNAL_ADDRESS" ]; then
    echo "  External Address: $EXTERNAL_ADDRESS"
fi

echo "Starting blockchain node..."

# Build the command based on service type
CMD_ARGS="--home $HOME_DIR --minimum-gas-prices 0.0001stake"

# Extract port from RPC_LADDR for command line args
RPC_PORT=$(echo $RPC_LADDR | sed 's/.*://')

case $SERVICE_TYPE in
    "tendermint")
        CMD_ARGS="$CMD_ARGS --rpc.laddr=$RPC_LADDR"
        ;;
    "rest-api")
        CMD_ARGS="$CMD_ARGS --api.enable=true --api.address=tcp://0.0.0.0:$PORT"
        ;;
    "grpc")
        CMD_ARGS="$CMD_ARGS --api.enable=true --api.address=tcp://0.0.0.0:$PORT --grpc.enable=true --grpc.address=0.0.0.0:9090"
        ;;
    "all"|*)
        CMD_ARGS="$CMD_ARGS --api.enable=true --api.address=tcp://0.0.0.0:$PORT --grpc.enable=true --grpc.address=0.0.0.0:9090 --rpc.laddr=$RPC_LADDR"
        ;;
esac

# Start the blockchain node
exec speculodd start $CMD_ARGS
