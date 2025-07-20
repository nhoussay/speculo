#!/bin/bash

# Speculod Local Deployment Script
set -e

echo "=================================================="
echo "🏠 SPECULOD LOCAL DEPLOYMENT"
echo "=================================================="

# Configuration
CONTAINER_NAME="speculod-local"
IMAGE_NAME="speculod:local"
NETWORK_NAME="speculod-network"

echo "🔧 Configuration:"
echo "   Container: $CONTAINER_NAME"
echo "   Image: $IMAGE_NAME"
echo "   Network: $NETWORK_NAME"
echo ""

# Clean up existing containers and networks
echo "🧹 Cleaning up existing deployment..."
docker stop $CONTAINER_NAME 2>/dev/null || true
docker rm $CONTAINER_NAME 2>/dev/null || true
docker network rm $NETWORK_NAME 2>/dev/null || true

# Create custom network for the blockchain
echo "🌐 Creating blockchain network..."
docker network create $NETWORK_NAME

# Build the image if it doesn't exist
if ! docker image inspect $IMAGE_NAME >/dev/null 2>&1; then
    echo "🏗️  Building Docker image..."
    docker build -t $IMAGE_NAME .
else
    echo "✅ Docker image already exists"
fi

echo ""
echo "=================================================="
echo "🚀 DEPLOYING SPECULOD LOCALLY"
echo "=================================================="

# Start the container with local configuration
docker run -d \
    --name $CONTAINER_NAME \
    --network $NETWORK_NAME \
    -p 26657:26657 \
    -p 1317:1317 \
    -p 9090:9090 \
    -p 26656:26656 \
    -e DEPLOYMENT_MODE=local \
    -e CHAIN_ID=speculod-local \
    -e MONIKER=speculod-local-node \
    $IMAGE_NAME

echo "✅ Container started successfully!"
echo ""

# Wait for the blockchain to start
echo "⏳ Waiting for blockchain to initialize..."
sleep 10

# Check if the container is running
if docker ps --filter "name=$CONTAINER_NAME" --filter "status=running" | grep -q $CONTAINER_NAME; then
    echo "🎉 Speculod blockchain is running locally!"
    echo ""
    echo "=================================================="
    echo "🔗 LOCAL ENDPOINTS (Starport-style)"
    echo "=================================================="
    echo "• Tendermint node:  http://localhost:26657"
    echo "• Blockchain API:   http://localhost:1317"
    echo "• API Docs:         http://localhost:1317"
    echo "• gRPC Services:    localhost:9090"
    echo "• P2P Network:      localhost:26656"
    echo ""
    echo "=================================================="
    echo "📊 USEFUL COMMANDS"
    echo "=================================================="
    echo "• Status:           curl http://localhost:26657/status"
    echo "• Node info:        curl http://localhost:1317/cosmos/base/tendermint/v1beta1/node_info"
    echo "• Bank supply:      curl http://localhost:1317/cosmos/bank/v1beta1/supply"
    echo "• Container logs:   docker logs -f $CONTAINER_NAME"
    echo "• Stop deployment:  docker stop $CONTAINER_NAME"
    echo ""
    
    # Test connectivity
    echo "🔍 Testing connectivity..."
    sleep 5
    
    if curl -s http://localhost:26657/status >/dev/null; then
        echo "✅ Tendermint RPC: Working"
    else
        echo "❌ Tendermint RPC: Not responding"
    fi
    
    if curl -s http://localhost:1317/cosmos/base/tendermint/v1beta1/node_info >/dev/null; then
        echo "✅ REST API: Working"
    else
        echo "❌ REST API: Not responding"
    fi
    
    if nc -z localhost 9090 2>/dev/null; then
        echo "✅ gRPC: Listening"
    else
        echo "❌ gRPC: Not listening"
    fi
    
else
    echo "❌ Failed to start container. Check logs with:"
    echo "   docker logs $CONTAINER_NAME"
    exit 1
fi

    echo ""
    echo "=================================================="
    echo "🚰 STARTING TOKEN FAUCET"
    echo "=================================================="
    
    # Start the faucet server in the background
    echo "🌐 Starting web faucet on port 4500..."
    nohup python3 scripts/faucet-server.py > faucet.log 2>&1 &
    FAUCET_PID=$!
    sleep 3
    
    # Test if faucet is running
    if curl -s http://localhost:4500/health >/dev/null; then
        echo "✅ Token faucet: Working on port 4500"
    else
        echo "❌ Token faucet: Failed to start"
    fi
    
    echo ""
    echo "=================================================="
    echo "🎯 COMPLETE STARPORT-STYLE SETUP READY!"
    echo "=================================================="
    echo "• Tendermint node:  http://localhost:26657"
    echo "• Blockchain API:   http://localhost:1317" 
    echo "• Token faucet:     http://localhost:4500  ⭐ NEW!"
    echo "• gRPC Services:    localhost:9090"
    echo ""
    echo "📱 Faucet Commands:"
    echo "• Web interface:    http://localhost:4500"
    echo "• CLI create user:  ./scripts/faucet.sh create username"
    echo "• CLI send tokens:  ./scripts/faucet.sh send address amount"
    echo "• CLI check balance: ./scripts/faucet.sh balance address"
    echo ""
    echo "🛑 To stop everything:"
    echo "• Stop blockchain:  docker stop speculod-local"
    echo "• Stop faucet:      pkill -f faucet-server.py"
    echo ""
    echo "🎯 Your Speculod blockchain is ready for development!"
    echo "   Open http://localhost:1317 to explore the API"
    echo "   Open http://localhost:4500 to use the token faucet"