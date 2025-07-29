#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting Speculod Peer Node...${NC}"

# Set default values
export NODE_HOME=${NODE_HOME:-"/home/speculod/.speculod"}
export CHAIN_ID=${CHAIN_ID:-"speculod-local-1"}
export MONIKER=${MONIKER:-"peer-node"}
export VALIDATOR_KEY_NAME=${VALIDATOR_KEY_NAME:-"peer"}
export MINIMUM_GAS_PRICES=${MINIMUM_GAS_PRICES:-"0.001stake"}
export API_ADDRESS=${API_ADDRESS:-"tcp://127.0.0.1:1317"}
export GRPC_LADDR=${GRPC_LADDR:-"127.0.0.1:9090"}
export RPC_LADDR=${RPC_LADDR:-"tcp://127.0.0.1:26657"}
export P2P_LADDR=${P2P_LADDR:-"tcp://127.0.0.1:26656"}
export PERSISTENT_PEERS=${PERSISTENT_PEERS:-""}
export IS_VALIDATOR=${IS_VALIDATOR:-"false"}

echo -e "${YELLOW}📁 Setting up peer node directory: $NODE_HOME${NC}"

# Ensure proper ownership of the data directory - try different approaches
if [ -w "$NODE_HOME" ]; then
    echo -e "${GREEN}✅ Directory is writable${NC}"
else
    echo -e "${YELLOW}⚠️ Attempting to fix directory permissions...${NC}"
    # Try to create config directory if it doesn't exist
    mkdir -p "$NODE_HOME/config" 2>/dev/null || true
    chmod -R u+w "$NODE_HOME" 2>/dev/null || true
fi

# If the node directory doesn't exist, initialize it
if [ ! -d "$NODE_HOME" ]; then
    echo -e "${YELLOW}⚙️ Initializing new peer node...${NC}"
    speculodd init $MONIKER --chain-id $CHAIN_ID --home $NODE_HOME
    
    # For peer nodes, we need to get the genesis from the validator
    echo -e "${YELLOW}📥 Getting genesis from validator node...${NC}"
    # We'll copy the genesis from the validator node
    if [ ! -z "$PERSISTENT_PEERS" ]; then
        # Extract validator host from persistent peers
        VALIDATOR_HOST=$(echo $PERSISTENT_PEERS | cut -d'@' -f2 | cut -d':' -f1)
        echo -e "${BLUE}📡 Fetching genesis from validator at $VALIDATOR_HOST${NC}"
        
        # Wait for validator to be available and fetch genesis
        max_attempts=30
        attempt=1
        while [ $attempt -le $max_attempts ]; do
            if curl -s "http://$VALIDATOR_HOST:8080/rpc/genesis" > "$NODE_HOME/config/genesis.json.tmp" 2>/dev/null; then
                # Extract the genesis from the RPC response
                if jq -r '.result.genesis' "$NODE_HOME/config/genesis.json.tmp" > "$NODE_HOME/config/genesis.json" 2>/dev/null; then
                    echo -e "${GREEN}✅ Genesis downloaded successfully${NC}"
                    rm -f "$NODE_HOME/config/genesis.json.tmp"
                    break
                fi
            fi
            echo -e "${YELLOW}⏳ Waiting for validator node... (attempt $attempt/$max_attempts)${NC}"
            sleep 2
            attempt=$((attempt + 1))
        done
        
        if [ $attempt -gt $max_attempts ]; then
            echo -e "${RED}❌ Failed to get genesis from validator node${NC}"
            exit 1
        fi
    fi
    
    echo -e "${GREEN}✅ Peer node initialization completed${NC}"
else
    echo -e "${BLUE}📋 Using existing peer node configuration${NC}"
fi

# Fix ownership and permissions of all config files
echo -e "${YELLOW}🔧 Fixing file permissions...${NC}"
if [ -d "$NODE_HOME" ]; then
    # Ensure proper ownership of entire directory tree
    chown -R speculod:speculod "$NODE_HOME" 2>/dev/null || true
    
    # Fix permissions for directories
    chmod 755 "$NODE_HOME" 2>/dev/null || true
    chmod -R 755 "$NODE_HOME/config" 2>/dev/null || true
    chmod -R 755 "$NODE_HOME/data" 2>/dev/null || true
    chmod -R 755 "$NODE_HOME/keyring-test" 2>/dev/null || true
    
    # Fix permissions for config files
    chmod -R 644 "$NODE_HOME/config/"*.toml 2>/dev/null || true
    chmod -R 644 "$NODE_HOME/config/"*.json 2>/dev/null || true
    chmod 600 "$NODE_HOME/config/priv_validator_key.json" 2>/dev/null || true
    chmod 600 "$NODE_HOME/config/node_key.json" 2>/dev/null || true
    
    # Fix permissions for data files
    chmod -R 644 "$NODE_HOME/data/"* 2>/dev/null || true
    
    echo -e "${GREEN}✅ File permissions fixed${NC}"
fi

# Configure app.toml
echo -e "${YELLOW}⚙️ Configuring app.toml...${NC}"
APP_CONFIG="$NODE_HOME/config/app.toml"

# Function to safely edit config files
safe_sed() {
    local file="$1"
    local pattern="$2"
    local replacement="$3"
    
    if [ -w "$file" ]; then
        sed -i "$pattern" "$file"
    else
        echo -e "${YELLOW}⚠️ File not writable, creating new version: $(basename $file)${NC}"
        sed "$pattern" "$file" > "$file.tmp" && mv "$file.tmp" "$file" 2>/dev/null || {
            echo -e "${RED}❌ Failed to update $(basename $file)${NC}"
            return 1
        }
    fi
}

# Set minimum gas prices
if [ -f "$APP_CONFIG" ]; then
    safe_sed "$APP_CONFIG" 's/minimum-gas-prices = ""/minimum-gas-prices = "'$MINIMUM_GAS_PRICES'"/g'
    
    # Enable API
    safe_sed "$APP_CONFIG" 's/enable = false/enable = true/g'
    safe_sed "$APP_CONFIG" 's|address = "tcp://localhost:1317"|address = "'$API_ADDRESS'"|g'
    
    # Configure gRPC
    safe_sed "$APP_CONFIG" 's|address = "localhost:9090"|address = "'$GRPC_LADDR'"|g'
    
    echo -e "${GREEN}✅ app.toml configured${NC}"
else
    echo -e "${YELLOW}⚠️ app.toml not found, using defaults${NC}"
fi

# Configure config.toml
echo -e "${YELLOW}⚙️ Configuring config.toml for peer node...${NC}"
CONFIG_FILE="$NODE_HOME/config/config.toml"

if [ -f "$CONFIG_FILE" ]; then
    # Set RPC and P2P addresses
    safe_sed "$CONFIG_FILE" 's|laddr = "tcp://127.0.0.1:26657"|laddr = "'$RPC_LADDR'"|g'
    safe_sed "$CONFIG_FILE" 's|laddr = "tcp://0.0.0.0:26656"|laddr = "'$P2P_LADDR'"|g'
    
    # Set persistent peers to connect to validator
    if [ ! -z "$PERSISTENT_PEERS" ]; then
        safe_sed "$CONFIG_FILE" 's/persistent_peers = ""/persistent_peers = "'$PERSISTENT_PEERS'"/g'
        safe_sed "$CONFIG_FILE" 's/persistent_peers = ".*"/persistent_peers = "'$PERSISTENT_PEERS'"/g'
        echo -e "${GREEN}✅ Persistent peers configured: $PERSISTENT_PEERS${NC}"
    fi
    
    # Enable unsafe CORS for local development
    safe_sed "$CONFIG_FILE" 's/cors_allowed_origins = \[\]/cors_allowed_origins = ["*"]/g'
    
    echo -e "${GREEN}✅ config.toml configured for peer mode${NC}"
else
    echo -e "${YELLOW}⚠️ config.toml not found, using defaults${NC}"
fi

echo -e "${BLUE}🎯 Starting Speculod peer node...${NC}"
echo -e "${BLUE}🌐 RPC: $RPC_LADDR${NC}"
echo -e "${BLUE}🤝 P2P: $P2P_LADDR${NC}"
echo -e "${BLUE}🔌 API: $API_ADDRESS${NC}"
echo -e "${BLUE}📡 gRPC: $GRPC_LADDR${NC}"
echo -e "${BLUE}💰 Gas Prices: $MINIMUM_GAS_PRICES${NC}"
if [ ! -z "$PERSISTENT_PEERS" ]; then
    echo -e "${BLUE}👥 Connecting to peers: $PERSISTENT_PEERS${NC}"
fi
echo -e "${BLUE}🏷️ Node type: ${IS_VALIDATOR}${NC}"

# Start the peer node
exec /usr/local/bin/speculodd start \
    --home "$NODE_HOME" \
    --rpc.laddr "$RPC_LADDR" \
    --p2p.laddr "$P2P_LADDR" \
    --grpc.address "$GRPC_LADDR" \
    --minimum-gas-prices "$MINIMUM_GAS_PRICES"
