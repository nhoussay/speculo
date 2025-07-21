#!/bin/bash

# Helper script to get node ID for peer configuration

set -e

CONTAINER_NAME=${1:-speculod-persistent-node-1}
RPC_PORT=${2:-26657}

echo "Getting node ID for container: $CONTAINER_NAME"

# Wait for node to be ready
echo "Waiting for node to be ready..."
sleep 10

# Get node ID from the running container
NODE_ID=$(curl -s "http://localhost:$RPC_PORT/status" | jq -r '.result.node_info.id' 2>/dev/null || echo "")

if [ -z "$NODE_ID" ] || [ "$NODE_ID" = "null" ]; then
    echo "Failed to get node ID via RPC, trying docker exec..."
    NODE_ID=$(docker exec $CONTAINER_NAME speculodd tendermint show-node-id --home /home/speculod/.speculod 2>/dev/null || echo "")
fi

if [ -n "$NODE_ID" ] && [ "$NODE_ID" != "null" ]; then
    echo "Node ID: $NODE_ID"
    echo "Persistent peer string: $NODE_ID@localhost:26656"
    echo "For Docker Compose networks: $NODE_ID@persistent-node:26656"
    echo ""
    echo "To connect peer nodes, use:"
    echo "PERSISTENT_PEERS=$NODE_ID@persistent-node:26656"
else
    echo "Failed to retrieve node ID. Make sure the node is running and accessible."
    exit 1
fi
