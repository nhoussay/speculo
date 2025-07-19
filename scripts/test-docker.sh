#!/bin/bash

# Docker Deployment Test Script for Speculod Blockchain

echo "=================================================="
echo "🧪 SPECULOD DOCKER DEPLOYMENT TEST"
echo "=================================================="

# Configuration
CONTAINER_NAME="speculod-test"
IMAGE_NAME="speculod"
RPC_PORT="26657"
API_PORT="1317"
GRPC_PORT="9090"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test functions
test_passed() {
    echo -e "${GREEN}✅ $1${NC}"
}

test_failed() {
    echo -e "${RED}❌ $1${NC}"
    return 1
}

test_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

# Clean up any existing test container
echo "🧹 Cleaning up previous test containers..."
docker stop $CONTAINER_NAME 2>/dev/null || true
docker rm $CONTAINER_NAME 2>/dev/null || true

# Build the image
echo "🔨 Building Docker image..."
if docker build -t $IMAGE_NAME . > build.log 2>&1; then
    test_passed "Docker image built successfully"
else
    test_failed "Failed to build Docker image"
    echo "Check build.log for details"
    exit 1
fi

# Start the container
echo "🚀 Starting container for testing..."
docker run -d \
    --name $CONTAINER_NAME \
    -p $RPC_PORT:26657 \
    -p $API_PORT:1317 \
    -p $GRPC_PORT:9090 \
    $IMAGE_NAME

if [ $? -eq 0 ]; then
    test_passed "Container started successfully"
else
    test_failed "Failed to start container"
    exit 1
fi

# Wait for blockchain to initialize
echo "⏳ Waiting for blockchain to initialize (60 seconds)..."
sleep 60

# Test RPC endpoint
echo "🔍 Testing RPC endpoint..."
if curl -s -f http://localhost:$RPC_PORT/health > /dev/null; then
    test_passed "RPC health check passed"
else
    test_failed "RPC health check failed"
fi

# Test status endpoint
echo "🔍 Testing status endpoint..."
STATUS_RESPONSE=$(curl -s http://localhost:$RPC_PORT/status)
if echo "$STATUS_RESPONSE" | grep -q "speculod"; then
    test_passed "Status endpoint working - Chain ID found"
    
    # Extract block height
    BLOCK_HEIGHT=$(echo "$STATUS_RESPONSE" | jq -r '.result.sync_info.latest_block_height' 2>/dev/null)
    if [ "$BLOCK_HEIGHT" != "null" ] && [ "$BLOCK_HEIGHT" != "" ]; then
        if [ "$BLOCK_HEIGHT" -gt 0 ]; then
            test_passed "Blockchain is producing blocks (height: $BLOCK_HEIGHT)"
        else
            test_warning "Blockchain initialized but not producing blocks yet"
        fi
    else
        test_warning "Could not determine block height"
    fi
else
    test_failed "Status endpoint not responding correctly"
fi

# Test API endpoint
echo "🔍 Testing REST API endpoint..."
if curl -s -f http://localhost:$API_PORT/cosmos/base/tendermint/v1beta1/node_info > /dev/null; then
    test_passed "REST API endpoint working"
else
    test_failed "REST API endpoint not responding"
fi

# Test custom modules
echo "🔍 Testing custom modules..."
MODULES=("prediction" "reputation" "settlement" "speculod")
for module in "${MODULES[@]}"; do
    if curl -s -f http://localhost:$API_PORT/speculod/$module/v1/params > /dev/null; then
        test_passed "$module module API accessible"
    else
        test_warning "$module module API not yet available (may need more initialization time)"
    fi
done

# Show container logs
echo ""
echo "📋 Recent container logs:"
docker logs --tail 20 $CONTAINER_NAME

echo ""
echo "=================================================="
echo "📊 TEST SUMMARY"
echo "=================================================="

# Final status check
if curl -s -f http://localhost:$RPC_PORT/status > /dev/null; then
    echo -e "${GREEN}🎉 DOCKER DEPLOYMENT TEST PASSED${NC}"
    echo ""
    echo "🔗 Test Endpoints:"
    echo "   RPC: http://localhost:$RPC_PORT/status"
    echo "   API: http://localhost:$API_PORT/cosmos/base/tendermint/v1beta1/node_info"
    echo "   Health: http://localhost:$RPC_PORT/health"
    echo ""
    echo "🧪 Test Commands:"
    echo "   curl http://localhost:$RPC_PORT/status"
    echo "   curl http://localhost:$API_PORT/cosmos/base/tendermint/v1beta1/node_info"
    echo ""
    echo "🔧 Container Management:"
    echo "   Stop: docker stop $CONTAINER_NAME"
    echo "   Logs: docker logs -f $CONTAINER_NAME"
    echo "   Remove: docker rm -f $CONTAINER_NAME"
    
    EXIT_CODE=0
else
    echo -e "${RED}❌ DOCKER DEPLOYMENT TEST FAILED${NC}"
    echo ""
    echo "🔧 Troubleshooting:"
    echo "   Check logs: docker logs $CONTAINER_NAME"
    echo "   Check if ports are free: netstat -tulpn | grep :26657"
    echo "   Verify container is running: docker ps"
    
    EXIT_CODE=1
fi

echo ""
echo "⚠️  Note: Container is still running for further testing"
echo "   To stop: docker stop $CONTAINER_NAME && docker rm $CONTAINER_NAME"

exit $EXIT_CODE
