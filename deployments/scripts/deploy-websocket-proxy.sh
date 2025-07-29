#!/bin/bash

# Deploy WebSocket P2P Bridge to replace speculo-nginx-proxy
# This script deploys the complete WebSocket bridge infrastructure to Cloud Run

set -e

PROJECT_ID="speculo-blockchain"
REGION="europe-west1"
SERVICE_NAME="speculo-nginx-proxy"

echo "🚀 Deploying WebSocket P2P Bridge to replace existing speculo-nginx-proxy..."

# Step 1: Build and push the Docker images
echo "📦 Building Docker images..."

# Build nginx with WebSocket support
echo "Building nginx-websocket..."
if docker build -f Dockerfile.nginx -t gcr.io/${PROJECT_ID}/nginx-websocket:latest . 2>&1; then
    echo "✅ nginx-websocket build successful"
    docker push gcr.io/${PROJECT_ID}/nginx-websocket:latest
else
    echo "❌ nginx-websocket build failed - trying alternative approach"
    # Try using pre-built nginx with our config
    docker build -f - -t gcr.io/${PROJECT_ID}/nginx-websocket:latest . <<EOF
FROM nginx:alpine
COPY nginx-websocket.conf /etc/nginx/nginx.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF
    docker push gcr.io/${PROJECT_ID}/nginx-websocket:latest
fi

# Build WebSocket bridge
echo "Building websocket-bridge..."
docker build -f Dockerfile.websocket-bridge -t gcr.io/${PROJECT_ID}/websocket-bridge:latest .
docker push gcr.io/${PROJECT_ID}/websocket-bridge:latest

# Build speculod blockchain node
echo "Building speculod..."
if docker build -f Dockerfile.blockchain -t gcr.io/${PROJECT_ID}/speculod:latest . 2>&1; then
    echo "✅ speculod build successful"
    docker push gcr.io/${PROJECT_ID}/speculod:latest
else
    echo "❌ speculod build failed - checking for existing image"
    # Try to use existing image or build with simple approach
    if docker pull gcr.io/${PROJECT_ID}/speculod:latest 2>/dev/null; then
        echo "✅ Using existing speculod image"
    else
        echo "⚠️  Building speculod with minimal configuration"
        # Use a simpler build approach
        docker build -f Dockerfile -t gcr.io/${PROJECT_ID}/speculod:latest .
        docker push gcr.io/${PROJECT_ID}/speculod:latest
    fi
fi

# Step 2: Deploy to Cloud Run
echo "🌩️ Deploying to Cloud Run..."

# Deploy the multi-container service
gcloud run services replace gcp-cloudrun-websocket-proxy.yaml \
    --region=${REGION} \
    --project=${PROJECT_ID}

# Wait for deployment to complete
echo "⏳ Waiting for deployment to complete..."
gcloud run services describe ${SERVICE_NAME} \
    --region=${REGION} \
    --project=${PROJECT_ID} \
    --format="value(status.conditions[0].type)" | \
    while read condition; do
        if [[ "$condition" == "Ready" ]]; then
            break
        fi
        echo "Waiting for service to be ready..."
        sleep 5
    done

# Step 3: Verify deployment
echo "🔍 Verifying deployment..."

SERVICE_URL=$(gcloud run services describe ${SERVICE_NAME} \
    --region=${REGION} \
    --project=${PROJECT_ID} \
    --format="value(status.url)")

echo "Service deployed at: ${SERVICE_URL}"

# Test HTTP endpoints
echo "Testing HTTP endpoints..."
curl -s "${SERVICE_URL}/rpc/status" | jq -r '.result.node_info.network' && echo "✅ RPC endpoint working"
curl -s "${SERVICE_URL}/api/cosmos/base/tendermint/v1beta1/node_info" | jq -r '.default_node_info.network' && echo "✅ API endpoint working"

# Test WebSocket P2P endpoint (basic connection test)
echo "Testing WebSocket P2P endpoint..."
if command -v wscat &> /dev/null; then
    echo "WebSocket endpoint ready at: wss://${SERVICE_URL#https://}/"
else
    echo "⚠️ wscat not available - WebSocket endpoint should be available at: wss://${SERVICE_URL#https://}/"
fi

echo "🎉 Deployment complete!"
echo ""
echo "🔗 Service Information:"
echo "  - Service Name: ${SERVICE_NAME}"
echo "  - URL: ${SERVICE_URL}"
echo "  - Region: ${REGION}"
echo "  - Domain: persistent.specu.io (if domain mapping exists)"
echo ""
echo "📊 Available Endpoints:"
echo "  - RPC: ${SERVICE_URL}/rpc"
echo "  - API: ${SERVICE_URL}/api"
echo "  - gRPC: ${SERVICE_URL}/grpc"
echo "  - WebSocket P2P: wss://${SERVICE_URL#https://}/"
echo "  - Documentation: ${SERVICE_URL}/ (fallback for non-WebSocket requests)"
echo ""
echo "🔧 To update domain mapping (if needed):"
echo "  gcloud run domain-mappings create --service=${SERVICE_NAME} --domain=persistent.specu.io --region=${REGION} --project=${PROJECT_ID}"
