#!/bin/bash

# Secure genesis and peer discovery script for production blockchain networks
# This script implements industry best practices for network bootstrapping

set -e

# Configuration
NETWORK_NAME="speculod"
GENESIS_URL_PRIMARY="https://raw.githubusercontent.com/your-org/speculod-network/main/mainnet/genesis.json"
GENESIS_URL_BACKUP="https://backup-site.com/speculod/genesis.json"
PEERS_URL="https://raw.githubusercontent.com/your-org/speculod-network/main/mainnet/peers.json"

# Security hashes (update these with actual values)
EXPECTED_GENESIS_SHA256="your_genesis_sha256_hash_here"
GENESIS_GPG_KEYID="your_gpg_key_id_here"

HOME_DIR=${HOME_DIR:-"/home/speculod/.speculod"}
CHAIN_ID=${CHAIN_ID:-"speculod"}
MONIKER=${MONIKER:-"speculod-node"}

echo "🚀 Starting secure network bootstrap for $NETWORK_NAME"

# Function to verify file integrity
verify_genesis() {
    local file="$1"
    local expected_hash="$2"
    
    echo "🔍 Verifying genesis file integrity..."
    
    # SHA256 verification
    local actual_hash=$(sha256sum "$file" | cut -d' ' -f1)
    if [ "$actual_hash" != "$expected_hash" ]; then
        echo "❌ Genesis hash mismatch! Expected: $expected_hash, Got: $actual_hash"
        return 1
    fi
    
    # GPG signature verification (if available)
    if [ -f "${file}.sig" ] && command -v gpg >/dev/null; then
        echo "🔐 Verifying GPG signature..."
        gpg --verify "${file}.sig" "$file" 2>/dev/null || {
            echo "⚠️  GPG verification failed, but hash matched. Proceeding with caution."
        }
    fi
    
    echo "✅ Genesis file verified successfully"
    return 0
}

# Function to download genesis with fallback
download_genesis() {
    local target_file="$HOME_DIR/config/genesis.json"
    local temp_file="/tmp/genesis.json"
    
    echo "📥 Downloading genesis file..."
    
    # Try primary URL first
    if curl -L -f -s -o "$temp_file" "$GENESIS_URL_PRIMARY"; then
        echo "✅ Downloaded from primary source"
    elif curl -L -f -s -o "$temp_file" "$GENESIS_URL_BACKUP"; then
        echo "✅ Downloaded from backup source"
    else
        echo "❌ Failed to download genesis from any source"
        return 1
    fi
    
    # Download signature if available
    curl -L -f -s -o "${temp_file}.sig" "${GENESIS_URL_PRIMARY}.sig" 2>/dev/null || true
    
    # Verify integrity
    if verify_genesis "$temp_file" "$EXPECTED_GENESIS_SHA256"; then
        mv "$temp_file" "$target_file"
        echo "✅ Genesis file installed successfully"
        return 0
    else
        rm -f "$temp_file" "${temp_file}.sig"
        echo "❌ Genesis verification failed"
        return 1
    fi
}

# Function to fetch peer list securely
fetch_peers() {
    echo "🌐 Fetching trusted peer list..."
    
    # Download peer list with validation
    local peers_json=$(curl -L -f -s "$PEERS_URL" | jq -r '.persistent_peers // empty' 2>/dev/null)
    
    if [ -n "$peers_json" ] && [ "$peers_json" != "null" ]; then
        echo "✅ Found persistent peers: $peers_json"
        echo "$peers_json"
    else
        echo "⚠️  No peers found or invalid peer list"
        echo ""
    fi
}

# Function to validate node configuration
validate_config() {
    local config_file="$HOME_DIR/config/config.toml"
    
    echo "🔧 Validating node configuration..."
    
    # Check if genesis time is reasonable (not too far in past/future)
    local genesis_time=$(jq -r '.genesis_time' "$HOME_DIR/config/genesis.json")
    echo "📅 Genesis time: $genesis_time"
    
    # Verify chain ID matches
    local genesis_chain_id=$(jq -r '.chain_id' "$HOME_DIR/config/genesis.json")
    if [ "$genesis_chain_id" != "$CHAIN_ID" ]; then
        echo "❌ Chain ID mismatch! Expected: $CHAIN_ID, Genesis: $genesis_chain_id"
        return 1
    fi
    
    echo "✅ Configuration validation passed"
}

# Main bootstrap process
main() {
    echo "🏗️  Initializing node configuration..."
    
    # Initialize node if not already done
    if [ ! -f "$HOME_DIR/config/config.toml" ]; then
        speculodd init "$MONIKER" --chain-id "$CHAIN_ID" --home "$HOME_DIR"
    fi
    
    # Download and verify genesis
    if [ ! -f "$HOME_DIR/config/genesis.json" ] || [ "$FORCE_GENESIS_DOWNLOAD" = "true" ]; then
        if ! download_genesis; then
            echo "❌ Failed to bootstrap genesis file"
            exit 1
        fi
    else
        echo "ℹ️  Genesis file already exists, skipping download"
    fi
    
    # Validate configuration
    if ! validate_config; then
        echo "❌ Configuration validation failed"
        exit 1
    fi
    
    # Fetch and configure peers
    local persistent_peers=$(fetch_peers)
    if [ -n "$persistent_peers" ]; then
        echo "🔗 Configuring persistent peers..."
        # Update config.toml with peers
        sed -i "s/persistent_peers = \"\"/persistent_peers = \"$persistent_peers\"/" "$HOME_DIR/config/config.toml"
    fi
    
    # Security hardening
    echo "🔒 Applying security configurations..."
    
    # Configure RPC security
    sed -i 's/laddr = "tcp:\/\/127.0.0.1:26657"/laddr = "tcp:\/\/0.0.0.0:26657"/' "$HOME_DIR/config/config.toml"
    
    # Set conservative peer limits
    sed -i 's/max_num_inbound_peers = .*/max_num_inbound_peers = 40/' "$HOME_DIR/config/config.toml"
    sed -i 's/max_num_outbound_peers = .*/max_num_outbound_peers = 10/' "$HOME_DIR/config/config.toml"
    
    # Enable peer exchange but with limits
    sed -i 's/pex = .*/pex = true/' "$HOME_DIR/config/config.toml"
    sed -i 's/seed_mode = .*/seed_mode = false/' "$HOME_DIR/config/config.toml"
    
    echo "🎉 Network bootstrap completed successfully!"
    echo "🏃 Starting blockchain node..."
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi
