#!/bin/bash

# Persistent Nodes Registry Management Script
# Manages the GitHub-hosted persistent nodes registry

set -e

REGISTRY_FILE="networks/persistent-nodes.json"
GITHUB_REPO="${GITHUB_REPO:-nhoussay/speculo}"
GITHUB_BRANCH="${GITHUB_BRANCH:-main}"

# Function to display help
show_help() {
    cat << EOF
Persistent Nodes Registry Management

Usage: $0 <command> [options]

Commands:
  list                    List all persistent nodes
  add <id> <address>      Add a new persistent node
  remove <id>             Remove a persistent node
  update <id> <status>    Update node status (active/inactive/pending)
  validate                Validate registry JSON format
  test <address>          Test connectivity to a node
  sync                    Sync with current deployments

Examples:
  $0 list
  $0 add "my-node" "my-node.example.com:26656"
  $0 update "speculo-persistent-node-1" "active"
  $0 test "persistent.specu.io:26656"

EOF
}

# Function to validate JSON
validate_json() {
    if ! jq empty "$REGISTRY_FILE" 2>/dev/null; then
        echo "❌ Invalid JSON format in $REGISTRY_FILE"
        return 1
    fi
    echo "✅ Registry JSON is valid"
}

# Function to list nodes
list_nodes() {
    echo "🔍 Persistent Nodes Registry:"
    echo ""
    
    if [[ ! -f "$REGISTRY_FILE" ]]; then
        echo "❌ Registry file not found: $REGISTRY_FILE"
        return 1
    fi
    
    echo "📊 Active Nodes:"
    jq -r '.persistent_nodes[] | select(.status == "active") | "  \(.id): \(.address) (\(.moniker))"' "$REGISTRY_FILE"
    
    echo ""
    echo "⏸️  Inactive/Pending Nodes:"
    jq -r '.persistent_nodes[] | select(.status != "active") | "  \(.id): \(.address) (\(.status))"' "$REGISTRY_FILE"
    
    echo ""
    echo "🔄 Backup Nodes:"
    jq -r '.backup_nodes[]? // empty | "  \(.id): \(.address) (\(.status))"' "$REGISTRY_FILE"
}

# Function to add node
add_node() {
    local node_id="$1"
    local address="$2"
    local moniker="${3:-$node_id}"
    local status="${4:-active}"
    
    if [[ -z "$node_id" || -z "$address" ]]; then
        echo "❌ Usage: add <id> <address> [moniker] [status]"
        return 1
    fi
    
    echo "➕ Adding node: $node_id at $address"
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local node_data=$(cat << EOF
{
  "id": "$node_id",
  "moniker": "$moniker", 
  "address": "$address",
  "rpc_endpoint": "http://${address%:*}:26657",
  "node_id": "unknown",
  "deployment": {
    "type": "manual",
    "added_by": "registry-script"
  },
  "status": "$status",
  "added_date": "$timestamp",
  "capabilities": ["persistent"]
}
EOF
)
    
    # Add to registry
    jq --argjson node "$node_data" \
       --arg timestamp "$timestamp" \
       '.persistent_nodes += [$node] | .last_updated = $timestamp' \
       "$REGISTRY_FILE" > "${REGISTRY_FILE}.tmp" && \
    mv "${REGISTRY_FILE}.tmp" "$REGISTRY_FILE"
    
    echo "✅ Node added successfully"
}

# Function to update node status
update_status() {
    local node_id="$1"
    local new_status="$2"
    
    if [[ -z "$node_id" || -z "$new_status" ]]; then
        echo "❌ Usage: update <id> <status>"
        return 1
    fi
    
    echo "🔄 Updating $node_id status to: $new_status"
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    jq --arg id "$node_id" \
       --arg status "$new_status" \
       --arg timestamp "$timestamp" \
       '(.persistent_nodes[] | select(.id == $id) | .status) = $status |
        (.backup_nodes[]? | select(.id == $id) | .status) = $status |
        .last_updated = $timestamp' \
       "$REGISTRY_FILE" > "${REGISTRY_FILE}.tmp" && \
    mv "${REGISTRY_FILE}.tmp" "$REGISTRY_FILE"
    
    echo "✅ Status updated successfully"
}

# Function to remove node
remove_node() {
    local node_id="$1"
    
    if [[ -z "$node_id" ]]; then
        echo "❌ Usage: remove <id>"
        return 1
    fi
    
    echo "🗑️  Removing node: $node_id"
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    jq --arg id "$node_id" \
       --arg timestamp "$timestamp" \
       '.persistent_nodes = (.persistent_nodes | map(select(.id != $id))) |
        .backup_nodes = (.backup_nodes | map(select(.id != $id))) |
        .last_updated = $timestamp' \
       "$REGISTRY_FILE" > "${REGISTRY_FILE}.tmp" && \
    mv "${REGISTRY_FILE}.tmp" "$REGISTRY_FILE"
    
    echo "✅ Node removed successfully"
}

# Function to test node connectivity
test_node() {
    local address="$1"
    
    if [[ -z "$address" ]]; then
        echo "❌ Usage: test <address>"
        return 1
    fi
    
    echo "🔍 Testing connectivity to: $address"
    
    # Extract host and port
    local host="${address%:*}"
    local port="${address##*:}"
    
    # Test RPC endpoint
    local rpc_url="http://$host:26657"
    echo "📡 Testing RPC endpoint: $rpc_url"
    
    if curl -s --connect-timeout 10 "$rpc_url/status" > /dev/null; then
        echo "✅ RPC endpoint is accessible"
        
        # Get node info
        local status_info=$(curl -s --connect-timeout 10 "$rpc_url/status")
        local node_id=$(echo "$status_info" | jq -r '.result.node_info.id // "unknown"')
        local moniker=$(echo "$status_info" | jq -r '.result.node_info.moniker // "unknown"')
        local height=$(echo "$status_info" | jq -r '.result.sync_info.latest_block_height // "unknown"')
        
        echo "  Node ID: $node_id"
        echo "  Moniker: $moniker"
        echo "  Block Height: $height"
    else
        echo "❌ RPC endpoint is not accessible"
    fi
    
    # Test P2P port
    echo "🔗 Testing P2P port: $address"
    if nc -z -w5 "$host" "$port" 2>/dev/null; then
        echo "✅ P2P port is open"
    else
        echo "❌ P2P port is not accessible"
    fi
}

# Function to sync with current deployments
sync_deployments() {
    echo "🔄 Syncing registry with current deployments..."
    
    # Test persistent.specu.io
    echo "📡 Checking persistent.specu.io..."
    if curl -s --connect-timeout 10 "https://persistent.specu.io/status" > /dev/null; then
        local status_info=$(curl -s --connect-timeout 10 "https://persistent.specu.io/status")
        local node_id=$(echo "$status_info" | jq -r '.result.node_info.id // "unknown"')
        
        # Update node_id in registry
        local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        jq --arg node_id "$node_id" \
           --arg timestamp "$timestamp" \
           '(.persistent_nodes[] | select(.address | contains("persistent.specu.io")) | .node_id) = $node_id |
            .last_updated = $timestamp' \
           "$REGISTRY_FILE" > "${REGISTRY_FILE}.tmp" && \
        mv "${REGISTRY_FILE}.tmp" "$REGISTRY_FILE"
        
        echo "✅ Updated persistent.specu.io node_id: $node_id"
    else
        echo "⚠️  persistent.specu.io not accessible"
    fi
}

# Main command handling
case "${1:-}" in
    "list"|"ls")
        list_nodes
        ;;
    "add")
        add_node "$2" "$3" "$4" "$5"
        ;;
    "remove"|"rm")
        remove_node "$2"
        ;;
    "update")
        update_status "$2" "$3"
        ;;
    "validate")
        validate_json
        ;;
    "test")
        test_node "$2"
        ;;
    "sync")
        sync_deployments
        ;;
    "help"|"-h"|"--help"|"")
        show_help
        ;;
    *)
        echo "❌ Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
