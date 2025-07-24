#!/bin/bash

# Enhanced blockchain service script with dynamic persistent node discovery
# Fetches persistent nodes from GitHub registry

set -e

echo "🚀 Starting Speculod Blockchain Service with Dynamic Node Discovery..."

# Configuration
GITHUB_REPO="${GITHUB_REPO:-nhoussay/speculo}"
GITHUB_BRANCH="${GITHUB_BRANCH:-main}"
NETWORK_NAME="${NETWORK_NAME:-local-testnet}"
CHAIN_ID="${CHAIN_ID:-speculod-local-1}"

# Default configuration
HOME_DIR="${HOME_DIR:-/home/speculod/.speculod}"
CHAIN_ID="${CHAIN_ID:-speculod-local-1}"
KEYRING_BACKEND="${KEYRING_BACKEND:-test}"
MONIKER="${MONIKER:-speculod-node-$(date +%s)}"

# Determine network path based on chain ID
if [[ "$CHAIN_ID" == *"mainnet"* ]]; then
    NETWORK_PATH="mainnet"
    NETWORK_NAME="mainnet"
elif [[ "$CHAIN_ID" == *"local"* ]]; then
    NETWORK_PATH="local-testnet"
    NETWORK_NAME="local-testnet"
    # Override for persistent.specu.io connection
    PERSISTENT_NODE_OVERRIDE="838ebde14991541b3bdbe325e4e1009fa3e96cbc@persistent.specu.io:443"
else
    NETWORK_PATH="${NETWORK_NAME:-local-testnet}"
fi

PERSISTENT_NODES_URL="https://raw.githubusercontent.com/${GITHUB_REPO}/${GITHUB_BRANCH}/networks/${NETWORK_PATH}/persistent-nodes.json"
GENESIS_URL="https://raw.githubusercontent.com/${GITHUB_REPO}/${GITHUB_BRANCH}/networks/${NETWORK_PATH}/genesis.json"
NODE_TYPE="${NODE_TYPE:-peer}"
SERVICE_TYPE="${SERVICE_TYPE:-tendermint}"

echo "📋 Configuration:"
echo "  - Node Type: $NODE_TYPE"
echo "  - Service Type: $SERVICE_TYPE"
echo "  - Chain ID: $CHAIN_ID"
echo "  - Moniker: $MONIKER"
echo "  - Home Directory: $HOME_DIR"
echo "  - Network: $NETWORK_NAME"

# Check for Cloud Run P2P-only mode
if [[ "$SERVICE_TYPE" == "p2p" ]]; then
    echo "  - Mode: P2P Only (Cloud Run)"
    P2P_ONLY_MODE=true
else
    echo "  - Mode: Full Service"
    P2P_ONLY_MODE=false
fi

# Function to fetch persistent nodes from GitHub registry
fetch_persistent_nodes() {
    # Check for persistent node override first
    if [[ -n "$PERSISTENT_NODE_OVERRIDE" ]]; then
        echo "🔧 Using persistent node override: $PERSISTENT_NODE_OVERRIDE"
        PERSISTENT_PEERS="$PERSISTENT_NODE_OVERRIDE"
        echo "✅ Configured override persistent peer: $PERSISTENT_PEERS"
        return 0
    fi
    
    local registry_url="$PERSISTENT_NODES_URL"
    local local_registry="/networks/${NETWORK_PATH}/persistent-nodes.json"
    local max_retries=3
    local retry_delay=5
    
    echo "🔍 Fetching persistent nodes from registry..."
    echo "   Network: $CHAIN_ID"
    echo "   Registry URL: $registry_url"
    
    # Try GitHub first
    for i in $(seq 1 $max_retries); do
        if nodes_info=$(curl -sf --connect-timeout 10 --max-time 30 "$registry_url" 2>/dev/null); then
            echo "✅ Successfully fetched persistent nodes registry from GitHub"
            return 0
        else
            echo "⚠️  Failed to fetch from GitHub (attempt $i/$max_retries)"
            if [ $i -lt $max_retries ]; then
                echo "   Retrying in ${retry_delay}s..."
                sleep $retry_delay
            fi
        fi
    done
    
    # Try local backup
    if [ -f "$local_registry" ]; then
        echo "🔄 Trying local registry backup..."
        if nodes_info=$(cat "$local_registry" 2>/dev/null); then
            echo "✅ Successfully loaded persistent nodes from local registry"
            return 0
        fi
    fi
    
    echo "❌ Failed to fetch persistent nodes registry from GitHub and no local backup available"
    return 1
}

# Function to wait for genesis file
wait_for_genesis() {
    echo "⏳ Waiting for shared genesis file from GitHub..."
    
    local max_attempts=180
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if curl -s -f "$GENESIS_URL" > /tmp/genesis.json; then
            echo "✅ Genesis file downloaded successfully"
            return 0
        fi
        
        attempt=$((attempt + 2))
        echo "Waiting for shared genesis file... ($attempt/$max_attempts)"
        sleep 2
    done
    
    echo "❌ Failed to download genesis file after $max_attempts attempts"
    return 1
}

# Function to disable state sync for regular blockchain sync
disable_state_sync() {
    echo "🔧 Disabling state sync for regular blockchain synchronization..."
    
    # Ensure state sync is disabled in config.toml
    sed -i 's/enable = true/enable = false/g' "$HOME_DIR/config/config.toml"
    
    # Clear any state sync configuration
    sed -i 's/trust_height = [0-9]*/trust_height = 0/g' "$HOME_DIR/config/config.toml"
    sed -i 's/trust_hash = ".*"/trust_hash = ""/g' "$HOME_DIR/config/config.toml" 
    sed -i 's/rpc_servers = ".*"/rpc_servers = ""/g' "$HOME_DIR/config/config.toml"
    
    echo "✅ State sync disabled - node will sync via P2P"
}

# Function to configure state sync for peer nodes
configure_state_sync() {
    echo "🔧 Configuring state sync for fast peer synchronization..."
    
    # Enable state sync in config.toml
    sed -i 's/enable = false/enable = true/g' "$HOME_DIR/config/config.toml"
    
    # Set trust height and hash (we'll use a recent block from the persistent node)
    # For now, let the node discover this automatically
    sed -i 's/trust_height = 0/trust_height = 0/g' "$HOME_DIR/config/config.toml"
    sed -i 's/trust_hash = ""/trust_hash = ""/g' "$HOME_DIR/config/config.toml"
    
    # Set RPC servers for state sync (use the persistent node)
    RPC_SERVERS="persistent.specu.io:443,persistent.specu.io:443"
    sed -i "s|rpc_servers = \"\"|rpc_servers = \"$RPC_SERVERS\"|g" "$HOME_DIR/config/config.toml"
    
    echo "✅ State sync configured for peer node"
}

# Function to create a peer-compatible genesis file
create_peer_genesis() {
    echo "🔧 Creating peer-compatible genesis file from mainnet genesis..."
    
    # First download the mainnet genesis
    if wait_for_genesis; then
        echo "✅ Downloaded mainnet genesis file"
        
        # Copy and modify the genesis file to remove genesis transactions
        cp /tmp/genesis.json "$HOME_DIR/config/genesis.json"
        
        # Remove genesis transactions that cause signature verification issues
        # Keep the app_state but clear the genutil.gen_txs array
        if command -v jq >/dev/null 2>&1; then
            echo "🔧 Removing genesis transactions for peer compatibility..."
            jq '.app_state.genutil.gen_txs = []' "$HOME_DIR/config/genesis.json" > "$HOME_DIR/config/genesis_temp.json"
            mv "$HOME_DIR/config/genesis_temp.json" "$HOME_DIR/config/genesis.json"
            echo "✅ Genesis transactions removed - peer can sync from existing state"
        else
            # Fallback: use sed to clear the gen_txs array
            sed -i 's/"gen_txs": \[.*\]/"gen_txs": []/g' "$HOME_DIR/config/genesis.json"
            echo "✅ Genesis transactions cleared using sed"
        fi
    else
        echo "❌ Failed to download mainnet genesis file"
        return 1
    fi
}

# Function to initialize node
initialize_node() {
    echo "🔧 Initializing Speculod node..."
    
    # Initialize the node if not already initialized
    if [ ! -d "$HOME_DIR/config" ]; then
        speculodd init "$MONIKER" --chain-id "$CHAIN_ID" --home "$HOME_DIR"
        echo "✅ Node initialized with moniker: $MONIKER"
    else
        echo "✅ Node already initialized"
    fi
    
    # Handle genesis file based on node type
    if [ "$NODE_TYPE" = "peer" ] && [[ "$CHAIN_ID" == *"mainnet"* ]]; then
        echo "🔄 Configuring peer node for regular blockchain sync..."
        # For peer nodes, we'll use regular sync instead of state sync
        # since our persistent node is P2P-only and doesn't provide RPC endpoints
        disable_state_sync
        # Use the mainnet genesis file but adapt it for peer sync
        if wait_for_genesis; then
            cp /tmp/genesis.json "$HOME_DIR/config/genesis.json"
            
            # For peer nodes, we need to preserve validators but remove problematic genesis transactions
            # Also set the genesis to a state that allows the node to sync from the network
            if command -v jq >/dev/null 2>&1; then
                echo "🔧 Adapting genesis for peer node synchronization..."
                # Remove genesis transactions but keep validator set
                jq '.app_state.genutil.gen_txs = []' "$HOME_DIR/config/genesis.json" > "$HOME_DIR/config/genesis_temp.json"
                # Set initial height to 1 to allow sync from network
                jq '.initial_height = "1"' "$HOME_DIR/config/genesis_temp.json" > "$HOME_DIR/config/genesis.json"
                rm -f "$HOME_DIR/config/genesis_temp.json"
                echo "✅ Genesis adapted for peer synchronization"
            else
                # Fallback: use sed to clear the gen_txs array
                sed -i 's/"gen_txs": \[.*\]/"gen_txs": []/g' "$HOME_DIR/config/genesis.json"
                sed -i 's/"initial_height": "[0-9]*"/"initial_height": "1"/g' "$HOME_DIR/config/genesis.json"
                echo "✅ Genesis adapted using sed"
            fi
            
            echo "✅ Genesis file configured for peer blockchain sync"
        fi
    else
        # Download and set genesis file for persistent nodes or local networks
        if wait_for_genesis; then
            cp /tmp/genesis.json "$HOME_DIR/config/genesis.json"
            echo "✅ Genesis file configured"
        else
            echo "❌ Failed to configure genesis file"
            exit 1
        fi
    fi
    
    # Configure for the specific node type
    if [ "$NODE_TYPE" = "persistent" ]; then
        echo "🏗️  Configuring as persistent node..."
        
        # Persistent nodes should be more permissive
        sed -i 's/pex = true/pex = true/g' "$HOME_DIR/config/config.toml"
        sed -i 's/addr_book_strict = true/addr_book_strict = false/g' "$HOME_DIR/config/config.toml"
        
        # Set higher peer limits for persistent nodes
        sed -i "s/max_num_inbound_peers = 40/max_num_inbound_peers = ${MAX_NUM_INBOUND_PEERS:-100}/g" "$HOME_DIR/config/config.toml"
        sed -i "s/max_num_outbound_peers = 10/max_num_outbound_peers = ${MAX_NUM_OUTBOUND_PEERS:-50}/g" "$HOME_DIR/config/config.toml"
        
    else
        echo "🤝 Configuring as peer node..."
        
        # Fetch persistent nodes from registry
        fetch_persistent_nodes
        
        # Configure peer connections
        if [[ -n "$PERSISTENT_PEERS" ]]; then
            sed -i "s/persistent_peers = \"\"/persistent_peers = \"$PERSISTENT_PEERS\"/g" "$HOME_DIR/config/config.toml"
            echo "✅ Configured persistent peers: $PERSISTENT_PEERS"
        fi
        
        if [[ -n "$SEEDS" ]]; then
            sed -i "s/seeds = \"\"/seeds = \"$SEEDS\"/g" "$HOME_DIR/config/config.toml"
            echo "✅ Configured seeds: $SEEDS"
        fi
        
        # Set peer limits for regular nodes
        sed -i "s/max_num_inbound_peers = 40/max_num_inbound_peers = ${MAX_NUM_INBOUND_PEERS:-40}/g" "$HOME_DIR/config/config.toml"
        sed -i "s/max_num_outbound_peers = 10/max_num_outbound_peers = ${MAX_NUM_OUTBOUND_PEERS:-10}/g" "$HOME_DIR/config/config.toml"
    fi
    
    # Configure listening addresses
    if [[ -n "$P2P_LADDR" ]]; then
        sed -i "s|laddr = \"tcp://127.0.0.1:26656\"|laddr = \"$P2P_LADDR\"|g" "$HOME_DIR/config/config.toml"
        echo "✅ P2P listening on: $P2P_LADDR"
    fi
    
    if [[ -n "$RPC_LADDR" ]]; then
        sed -i "s|laddr = \"tcp://127.0.0.1:26657\"|laddr = \"$RPC_LADDR\"|g" "$HOME_DIR/config/config.toml"
        echo "✅ RPC listening on: $RPC_LADDR"
    fi
    
    # Configure external address for persistent nodes
    if [[ -n "$EXTERNAL_ADDRESS" && "$NODE_TYPE" = "persistent" ]]; then
        sed -i "s|external_address = \"\"|external_address = \"$EXTERNAL_ADDRESS\"|g" "$HOME_DIR/config/config.toml"
        echo "✅ External address: $EXTERNAL_ADDRESS"
    fi
    
    echo "✅ Node configuration completed"
}

# Function to start the appropriate service
start_service() {
    echo "🚀 Starting $SERVICE_TYPE service..."
    
    # Set minimum gas prices
    GAS_PRICES="${MINIMUM_GAS_PRICES:-0.01stake}"
    
    case "$SERVICE_TYPE" in
        "tendermint"|"rpc")
            echo "🔧 Starting Tendermint RPC service..."
            exec speculodd start --home "$HOME_DIR" --rpc.laddr "$RPC_LADDR" --minimum-gas-prices "$GAS_PRICES"
            ;;
        "api"|"rest")
            echo "🌐 Starting REST API service..."
            exec speculodd start --home "$HOME_DIR" --rpc.laddr "$RPC_LADDR" --api.enable --api.enabled-unsafe-cors --api.address "tcp://0.0.0.0:${PORT:-8080}" --minimum-gas-prices "$GAS_PRICES"
            ;;
        "p2p")
            echo "🌐 Starting P2P-only service (Cloud Run mode)..."
            exec speculodd start --home "$HOME_DIR" --p2p.laddr "tcp://0.0.0.0:${PORT:-26656}" --rpc.laddr "tcp://127.0.0.1:26657" --minimum-gas-prices "$GAS_PRICES"
            ;;
        "all"|"full")
            echo "🚀 Starting full service (RPC + REST API)..."
            exec speculodd start --home "$HOME_DIR" --rpc.laddr "$RPC_LADDR" --api.enable --api.enabled-unsafe-cors --api.address "tcp://0.0.0.0:${PORT:-8080}" --minimum-gas-prices "$GAS_PRICES"
            ;;
        *)
            echo "❌ Unknown service type: $SERVICE_TYPE"
            echo "Valid options: tendermint, rpc, api, rest, p2p, all, full"
            exit 1
            ;;
    esac
}

# Main execution flow
main() {
    echo "🎯 Starting blockchain service initialization..."
    
    # Create necessary directories
    mkdir -p "$HOME_DIR"
    
    # Initialize and configure the node
    initialize_node
    
    # Start the service
    start_service
}

# Run main function
main "$@"
