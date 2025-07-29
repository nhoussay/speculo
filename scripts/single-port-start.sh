#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting Speculod Single-Port Validator...${NC}"

# Set default values
export NODE_HOME=${NODE_HOME:-"/home/speculod/.speculod"}
export CHAIN_ID=${CHAIN_ID:-"speculod-local-1"}
export MONIKER=${MONIKER:-"single-port-validator"}
export VALIDATOR_KEY_NAME=${VALIDATOR_KEY_NAME:-"validator"}
export MINIMUM_GAS_PRICES=${MINIMUM_GAS_PRICES:-"0.001stake"}
export API_ADDRESS=${API_ADDRESS:-"tcp://127.0.0.1:1317"}
export GRPC_LADDR=${GRPC_LADDR:-"127.0.0.1:9090"}
export RPC_LADDR=${RPC_LADDR:-"tcp://127.0.0.1:26657"}
export P2P_LADDR=${P2P_LADDR:-"tcp://127.0.0.1:26656"}

echo -e "${YELLOW}📁 Setting up node directory: $NODE_HOME${NC}"

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
    echo -e "${YELLOW}⚙️ Initializing new node...${NC}"
    speculodd init $MONIKER --chain-id $CHAIN_ID --home $NODE_HOME
    
    # Create genesis with a single validator
    echo -e "${YELLOW}� Creating validator account...${NC}"
    speculodd keys add $VALIDATOR_KEY_NAME --keyring-backend test --home $NODE_HOME
    
    # Add genesis account with large initial balance
    VALIDATOR_ADDRESS=$(speculodd keys show $VALIDATOR_KEY_NAME -a --keyring-backend test --home $NODE_HOME)
    speculodd genesis add-genesis-account $VALIDATOR_ADDRESS 100000000000000stake --home $NODE_HOME
    
    # Create genesis validator transaction with large stake
    speculodd genesis gentx $VALIDATOR_KEY_NAME 10000000000000stake --keyring-backend test --chain-id $CHAIN_ID --home $NODE_HOME
    
    # Collect genesis transactions
    speculodd genesis collect-gentxs --home $NODE_HOME
    
    echo -e "${GREEN}✅ Genesis configuration created${NC}"
else
    echo -e "${BLUE}📋 Using existing genesis configuration${NC}"
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
echo -e "${YELLOW}⚙️ Configuring config.toml...${NC}"
CONFIG_FILE="$NODE_HOME/config/config.toml"

if [ -f "$CONFIG_FILE" ]; then
    # Set RPC and P2P addresses
    safe_sed "$CONFIG_FILE" 's|laddr = "tcp://127.0.0.1:26657"|laddr = "'$RPC_LADDR'"|g'
    safe_sed "$CONFIG_FILE" 's|laddr = "tcp://0.0.0.0:26656"|laddr = "'$P2P_LADDR'"|g'
    
    # Disable external peer connections (single node setup)
    safe_sed "$CONFIG_FILE" 's/persistent_peers = ""/persistent_peers = ""/g'
    safe_sed "$CONFIG_FILE" 's/seeds = ""/seeds = ""/g'
    
    # Enable unsafe CORS for local development
    safe_sed "$CONFIG_FILE" 's/cors_allowed_origins = \[\]/cors_allowed_origins = ["*"]/g'
    
    echo -e "${GREEN}✅ config.toml configured${NC}"
else
    echo "⚠️ config.toml not found, using defaults"
fi

echo "🎯 Starting Speculod validator..."
echo "🌐 RPC: $RPC_LADDR"
echo "🤝 P2P: $P2P_LADDR"
echo "🔌 API: $API_ADDRESS"
echo "📡 gRPC: $GRPC_LADDR"
echo "💰 Gas Prices: $MINIMUM_GAS_PRICES"

# Start the validator
exec /usr/local/bin/speculodd start \
    --home "$NODE_HOME" \
    --rpc.laddr "$RPC_LADDR" \
    --p2p.laddr "$P2P_LADDR" \
    --grpc.address "$GRPC_LADDR" \
    --minimum-gas-prices "$MINIMUM_GAS_PRICES"
