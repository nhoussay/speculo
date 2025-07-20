#!/bin/bash

# Stop Speculod Local Deployment
set -e

echo "=================================================="
echo "🛑 STOPPING SPECULOD LOCAL DEPLOYMENT"
echo "=================================================="

CONTAINER_NAME="speculod-local"

# Stop blockchain container
echo "🔴 Stopping blockchain container..."
if docker ps --filter "name=$CONTAINER_NAME" --filter "status=running" | grep -q $CONTAINER_NAME; then
    docker stop $CONTAINER_NAME
    echo "✅ Blockchain container stopped"
else
    echo "ℹ️  Blockchain container not running"
fi

# Stop faucet server
echo "🚰 Stopping token faucet..."
if pgrep -f "faucet-server.py" > /dev/null; then
    pkill -f faucet-server.py
    echo "✅ Token faucet stopped"
else
    echo "ℹ️  Token faucet not running"
fi

# Clean up log files
if [ -f "faucet.log" ]; then
    rm -f faucet.log
    echo "🗑️  Cleaned up log files"
fi

echo ""
echo "🎯 All services stopped successfully!"
echo "   To restart: ./scripts/deploy-local.sh"
