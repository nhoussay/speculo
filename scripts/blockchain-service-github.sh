#!/bin/bash

# GitHub-based blockchain startup script with genesis and peer discovery
# Downloads genesis.json and peer information from GitHub repository

set -e

SERVICE_TYPE=${SERVICE_TYPE:-"all"}
NODE_TYPE=${NODE_TYPE:-"standalone"}
PORT=${PORT:-8080}
CHAIN_ID=${CHAIN_ID:-"speculod-local-1"}
MONIKER=${MONIKER:-"speculod-node"}
HOME_DIR=${HOME_DIR:-"/home/speculod/.speculod"}
KEYRING_BACKEND=${KEYRING_BACKEND:-"test"}

# GitHub Configuration - UPDATE THESE FOR YOUR REPOSITORY
GITHUB_REPO=${GITHUB_REPO:-"nhoussay/speculo"}
GITHUB_BRANCH=${GITHUB_BRANCH:-"main"}
NETWORK_NAME=${NETWORK_NAME:-"local-testnet"}

# Constructed URLs
if [[ "$GITHUB_REPO" == localhost:* ]]; then
    # Local server for testing
    NETWORK_BASE_URL="http://${GITHUB_REPO}/${NETWORK_NAME}"
else
    # GitHub hosted
    NETWORK_BASE_URL="https://raw.githubusercontent.com/${GITHUB_REPO}/${GITHUB_BRANCH}/networks/${NETWORK_NAME}"
fi
GENESIS_URL="${NETWORK_BASE_URL}/genesis.json"
PEERS_URL="${NETWORK_BASE_URL}/peers.json"
NETWORK_CONFIG_URL="${NETWORK_BASE_URL}/network-config.json"

# P2P Configuration
PERSISTENT_PEER_HOST=${PERSISTENT_PEER_HOST:-""}
PERSISTENT_PEER_PORT=${PERSISTENT_PEER_PORT:-"26656"}
PEER_NODE_HOST=${PEER_NODE_HOST:-""}
PEER_NODE_PORT=${PEER_NODE_PORT:-"26656"}

# Local Genesis Configuration
CREATE_LOCAL_GENESIS=${CREATE_LOCAL_GENESIS:-"false"}
VALIDATOR_KEY_NAME=${VALIDATOR_KEY_NAME:-"validator"}

echo "🚀 Starting Speculod Service: $SERVICE_TYPE"
echo "📡 Node Type: $NODE_TYPE"
echo "🌐 Using port: $PORT"
echo "⛓️  Chain ID: $CHAIN_ID"
echo "🏠 Home directory: $HOME_DIR"
echo "📁 GitHub Repository: $GITHUB_REPO"
echo "🌿 Branch: $GITHUB_BRANCH"
echo "🌍 Network: $NETWORK_NAME"

# Function to download file with retries
download_file() {
    local url="$1"
    local output="$2"
    local retries=3
    local wait_time=5
    
    for i in $(seq 1 $retries); do
        echo "📥 Downloading $url (attempt $i/$retries)..."
        if curl -L -f -s -o "$output" "$url"; then
            echo "✅ Successfully downloaded to $output"
            return 0
        else
            echo "⚠️  Download failed (attempt $i/$retries)"
            if [ $i -lt $retries ]; then
                echo "⏳ Waiting ${wait_time}s before retry..."
                sleep $wait_time
            fi
        fi
    done
    
    echo "❌ Failed to download $url after $retries attempts"
    return 1
}

# Function to validate downloaded genesis
validate_genesis() {
    local genesis_file="$1"
    
    echo "🔍 Validating genesis file..."
    
    # Check if file exists and is valid JSON
    if [ ! -f "$genesis_file" ]; then
        echo "❌ Genesis file not found: $genesis_file"
        return 1
    fi
    
    # Validate JSON format
    if ! jq . "$genesis_file" > /dev/null 2>&1; then
        echo "❌ Invalid JSON format in genesis file"
        return 1
    fi
    
    # Check chain ID matches
    local genesis_chain_id=$(jq -r '.chain_id' "$genesis_file")
    if [ "$genesis_chain_id" != "$CHAIN_ID" ]; then
        echo "❌ Chain ID mismatch! Expected: $CHAIN_ID, Genesis: $genesis_chain_id"
        return 1
    fi
    
    # Check for required fields
    local required_fields=("chain_id" "genesis_time" "app_state")
    for field in "${required_fields[@]}"; do
        if [ "$(jq -r "has(\"$field\")" "$genesis_file")" != "true" ]; then
            echo "❌ Missing required field in genesis: $field"
            return 1
        fi
    done
    
    echo "✅ Genesis validation passed"
    return 0
}

# Function to download and setup genesis
setup_genesis() {
    local genesis_file="$HOME_DIR/config/genesis.json"
    local temp_genesis="/tmp/genesis.json"
    
    echo "🔄 Setting up genesis file..."
    
    case "$NODE_TYPE" in
        "persistent")
            echo "📍 Persistent node: Creating or downloading genesis..."
            
            # Try to download existing genesis first
            if download_file "$GENESIS_URL" "$temp_genesis" && validate_genesis "$temp_genesis"; then
                mv "$temp_genesis" "$genesis_file"
                echo "✅ Genesis downloaded from GitHub successfully"
                
                # Add the same test account for consistency
                echo "🔑 Adding test account..."
                echo "century toddler mystery need salt embody orient dilemma armed crush skirt tail tired blouse apart number empower rapid high weird already penalty turtle drama" | \
                speculodd keys add alice --recover --keyring-backend $KEYRING_BACKEND --home $HOME_DIR 2>/dev/null || true
                
            # Check if we should generate our own genesis (for initial bootstrap)
            elif [ "$GENERATE_GENESIS" = "true" ] || [ ! -f "$genesis_file" ]; then
                echo "🎯 Generating new genesis for persistent node..."
                
                # Add test account
                echo "🔑 Adding test account..."
                echo "century toddler mystery need salt embody orient dilemma armed crush skirt tail tired blouse apart number empower rapid high weird already penalty turtle drama" | \
                speculodd keys add alice --recover --keyring-backend $KEYRING_BACKEND --home $HOME_DIR
                
                # Add genesis account
                speculodd genesis add-genesis-account alice 100000000000stake --keyring-backend $KEYRING_BACKEND --home $HOME_DIR
                
                # Create genesis transaction
                speculodd genesis gentx alice 1000000stake --keyring-backend $KEYRING_BACKEND --chain-id $CHAIN_ID --home $HOME_DIR
                
                # Collect genesis transactions
                speculodd genesis collect-gentxs --home $HOME_DIR
                
                echo "✅ Genesis generated successfully"
                
                # Display genesis info for GitHub upload
                echo ""
                echo "📋 ==================================="
                echo "📋 GENESIS READY FOR GITHUB UPLOAD"
                echo "📋 ==================================="
                echo "📋 File location: $genesis_file"
                echo "📋 Chain ID: $(jq -r '.chain_id' "$genesis_file")"
                echo "📋 Genesis time: $(jq -r '.genesis_time' "$genesis_file")"
                echo "📋 SHA256: $(sha256sum "$genesis_file" | cut -d' ' -f1)"
                echo "📋"
                echo "📋 Upload this file to:"
                echo "📋 ${GENESIS_URL}"
                echo "📋 ==================================="
                echo ""
                
            else
                echo "📥 Downloading existing genesis from GitHub..."
                if download_file "$GENESIS_URL" "$temp_genesis"; then
                    if validate_genesis "$temp_genesis"; then
                        mv "$temp_genesis" "$genesis_file"
                        echo "✅ Genesis downloaded and validated successfully"
                        
                        # Add the same test account for consistency
                        echo "🔑 Adding test account..."
                        echo "century toddler mystery need salt embody orient dilemma armed crush skirt tail tired blouse apart number empower rapid high weird already penalty turtle drama" | \
                        speculodd keys add alice --recover --keyring-backend $KEYRING_BACKEND --home $HOME_DIR 2>/dev/null || true
                    else
                        echo "❌ Genesis validation failed"
                        exit 1
                    fi
                else
                    echo "❌ Failed to download genesis, generating new one..."
                    # Fallback to generation if download fails
                    export GENERATE_GENESIS="true"
                    setup_genesis
                    return $?
                fi
            fi
            ;;
            
        "peer")
            echo "👥 Peer node: Downloading genesis from GitHub..."
            
            # Wait for genesis to be available
            local max_attempts=30
            local attempt=0
            
            while [ $attempt -lt $max_attempts ]; do
                if download_file "$GENESIS_URL" "$temp_genesis"; then
                    if validate_genesis "$temp_genesis"; then
                        mv "$temp_genesis" "$genesis_file"
                        echo "✅ Genesis downloaded and validated successfully"
                        
                        # Add the same test account
                        echo "🔑 Adding test account..."
                        echo "century toddler mystery need salt embody orient dilemma armed crush skirt tail tired blouse apart number empower rapid high weird already penalty turtle drama" | \
                        speculodd keys add alice --recover --keyring-backend $KEYRING_BACKEND --home $HOME_DIR 2>/dev/null || true
                        
                        return 0
                    else
                        echo "❌ Downloaded genesis failed validation"
                    fi
                else
                    echo "⏳ Genesis not available yet, waiting... (attempt $((attempt + 1))/$max_attempts)"
                fi
                
                attempt=$((attempt + 1))
                sleep 10
            done
            
            echo "❌ Failed to download genesis after $max_attempts attempts"
            exit 1
            ;;
            
        *)
            echo "🔧 Standalone node: Downloading genesis..."
            if download_file "$GENESIS_URL" "$temp_genesis"; then
                if validate_genesis "$temp_genesis"; then
                    mv "$temp_genesis" "$genesis_file"
                    echo "✅ Genesis setup completed"
                else
                    echo "❌ Genesis validation failed"
                    exit 1
                fi
            else
                echo "❌ Failed to download genesis"
                exit 1
            fi
            ;;
    esac
}

# Function to setup peer discovery
setup_peers() {
    echo "🌐 Setting up peer discovery..."
    
    # Download peer configuration
    local temp_peers="/tmp/peers.json"
    if download_file "$PEERS_URL" "$temp_peers"; then
        echo "📋 Downloaded peer configuration"
        
        # Parse peer information
        local seed_nodes=$(jq -r '.seed_nodes[]?.address // empty' "$temp_peers" 2>/dev/null | tr '\n' ',' | sed 's/,$//')
        local persistent_peers=$(jq -r '.persistent_peers[]?.address // empty' "$temp_peers" 2>/dev/null | tr '\n' ',' | sed 's/,$//')
        
        if [ -n "$seed_nodes" ]; then
            echo "🌱 Found seed nodes: $seed_nodes"
            # Configure seeds in config.toml
            sed -i "s/seeds = \"\"/seeds = \"$seed_nodes\"/" "$HOME_DIR/config/config.toml"
        fi
        
        if [ -n "$persistent_peers" ]; then
            echo "🔗 Found persistent peers: $persistent_peers"
            # Configure persistent peers in config.toml
            sed -i "s/persistent_peers = \"\"/persistent_peers = \"$persistent_peers\"/" "$HOME_DIR/config/config.toml"
        fi
        
        rm -f "$temp_peers"
    else
        echo "⚠️  Could not download peer configuration, will use environment variables if available"
    fi
    
    # Handle peer node specific configuration
    if [ "$NODE_TYPE" = "peer" ] && [ -n "$PERSISTENT_PEER_HOST" ]; then
        echo "👥 Peer node: Setting up connection to persistent node..."
        
        # Wait for persistent node to be ready
        local timeout=120
        local counter=0
        while [ $counter -lt $timeout ]; do
            if curl -s "http://$PERSISTENT_PEER_HOST:26657/status" >/dev/null 2>&1; then
                echo "✅ Persistent node is ready!"
                break
            fi
            echo "⏳ Waiting for persistent node... ($counter/$timeout)"
            sleep 2
            counter=$((counter + 2))
        done
        
        if [ $counter -ge $timeout ]; then
            echo "❌ Timeout waiting for persistent node"
            exit 1
        fi
        
        # Get the node ID from the persistent node
        echo "🔍 Getting node ID from persistent node..."
        local node_id=$(curl -s "http://$PERSISTENT_PEER_HOST:26657/status" | jq -r '.result.node_info.id')
        
        if [ "$node_id" != "null" ] && [ -n "$node_id" ]; then
            local persistent_peer="${node_id}@${PERSISTENT_PEER_HOST}:${PERSISTENT_PEER_PORT}"
            echo "🔗 Setting persistent peer: $persistent_peer"
            
            # Update config.toml with the discovered peer
            sed -i "s/persistent_peers = \"\"/persistent_peers = \"$persistent_peer\"/" "$HOME_DIR/config/config.toml"
            export PERSISTENT_PEERS="$persistent_peer"
        else
            echo "❌ Failed to get node ID from persistent node"
            exit 1
        fi
    fi
    
    # Handle dual-node validator setup (both nodes connect to each other)
    if [ "$NODE_TYPE" = "validator" ] && [ -n "$PEER_NODE_HOST" ]; then
        echo "🤝 Validator node: Setting up connection to peer node..."
        
        # Wait for peer node to be ready (with shorter timeout for validators)
        local timeout=60
        local counter=0
        while [ $counter -lt $timeout ]; do
            if curl -s "http://$PEER_NODE_HOST:26657/status" >/dev/null 2>&1; then
                echo "✅ Peer node is ready!"
                break
            fi
            echo "⏳ Waiting for peer node... ($counter/$timeout)"
            sleep 2
            counter=$((counter + 2))
        done
        
        # Even if peer node is not ready, continue (it might start later)
        if [ $counter -lt $timeout ]; then
            # Get the node ID from the peer node
            echo "🔍 Getting node ID from peer node..."
            local peer_node_id=$(curl -s "http://$PEER_NODE_HOST:26657/status" | jq -r '.result.node_info.id')
            
            if [ "$peer_node_id" != "null" ] && [ -n "$peer_node_id" ]; then
                local peer_connection="${peer_node_id}@${PEER_NODE_HOST}:${PEER_NODE_PORT}"
                echo "🔗 Setting peer connection: $peer_connection"
                
                # Update config.toml with the discovered peer
                sed -i "s/persistent_peers = \"\"/persistent_peers = \"$peer_connection\"/" "$HOME_DIR/config/config.toml"
                export PERSISTENT_PEERS="$peer_connection"
            else
                echo "⚠️ Could not get node ID from peer node, will try to connect later"
            fi
        else
            echo "⚠️ Peer node not ready yet, will attempt connection later"
        fi
    fi
}

# Initialize node if not already done
if [ ! -f "$HOME_DIR/config/config.toml" ]; then
    echo "🏗️  Initializing blockchain node..."
    speculodd init $MONIKER --chain-id $CHAIN_ID --home $HOME_DIR
fi

# Configure RPC to listen on all interfaces
echo "🔧 Configuring RPC server..."
sed -i 's|laddr = "tcp://127.0.0.1:26657"|laddr = "tcp://0.0.0.0:26657"|g' "$HOME_DIR/config/config.toml"

# Setup genesis
setup_genesis

# Setup peer discovery
setup_peers

echo "🎯 Starting blockchain with NODE_TYPE: $NODE_TYPE"

# Build the start command with necessary flags
START_CMD="speculodd start --home $HOME_DIR --minimum-gas-prices 0.001stake"

# Add persistent peers if configured
if [ -n "$PERSISTENT_PEERS" ]; then
    START_CMD="$START_CMD --p2p.persistent_peers $PERSISTENT_PEERS"
fi

echo "🚀 Executing: $START_CMD"
exec $START_CMD
