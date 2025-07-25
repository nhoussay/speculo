#!/bin/bash

# Streamlined WebSocket P2P Bridge Deployment
# This script deploys the WebSocket bridge infrastructure using existing working containers

set -e

PROJECT_ID="speculo-blockchain"
REGION="europe-west1"
SERVICE_NAME="speculo-nginx-proxy"

echo "🚀 Deploying WebSocket P2P Bridge (streamlined approach)..."

# Step 1: Build images using working Dockerfiles
echo "📦 Building Docker images with proven configurations..."

# Build nginx with simple approach
echo "Building nginx-websocket..."
docker build -f Dockerfile.nginx-websocket-simple -t gcr.io/${PROJECT_ID}/nginx-websocket:latest .
echo "Pushing nginx-websocket..."
docker push gcr.io/${PROJECT_ID}/nginx-websocket:latest

# Build WebSocket bridge
echo "Building websocket-bridge..."
docker build -f Dockerfile.websocket-bridge -t gcr.io/${PROJECT_ID}/websocket-bridge:latest .
echo "Pushing websocket-bridge..."
docker push gcr.io/${PROJECT_ID}/websocket-bridge:latest

# Build speculod using main Dockerfile
echo "Building speculod..."
docker build -f Dockerfile -t gcr.io/${PROJECT_ID}/speculod:latest .
echo "Pushing speculod..."
docker push gcr.io/${PROJECT_ID}/speculod:latest

echo "✅ All images built and pushed successfully"

# Step 2: Deploy to Cloud Run
echo "🌩️ Deploying to Cloud Run..."

gcloud run services replace gcp-cloudrun-websocket-proxy.yaml \
    --region=${REGION} \
    --project=${PROJECT_ID}

echo "✅ Deployment command sent to Cloud Run"

# Step 3: Wait for deployment and verify
echo "⏳ Waiting for deployment to complete..."

# Wait for service to be ready
for i in {1..60}; do
    STATUS=$(gcloud run services describe ${SERVICE_NAME} \
        --region=${REGION} \
        --project=${PROJECT_ID} \
        --format="value(status.conditions[0].status)" 2>/dev/null || echo "Unknown")
    
    if [[ "$STATUS" == "True" ]]; then
        echo "✅ Service is ready!"
        break
    fi
    
    echo "Attempt $i/60: Service status is '$STATUS', waiting..."
    sleep 10
    
    if [[ $i -eq 60 ]]; then
        echo "⚠️ Timeout waiting for service to be ready"
        break
    fi
done

# Get service URL
SERVICE_URL=$(gcloud run services describe ${SERVICE_NAME} \
    --region=${REGION} \
    --project=${PROJECT_ID} \
    --format="value(status.url)" 2>/dev/null || echo "")

if [[ -n "$SERVICE_URL" ]]; then
    echo "🔗 Service URL: ${SERVICE_URL}"
    
    # Quick endpoint test
    echo "🧪 Testing basic endpoint..."
    if curl -s --max-time 30 "${SERVICE_URL}/rpc/status" > /dev/null 2>&1; then
        echo "✅ RPC endpoint responding"
    else
        echo "⚠️ RPC endpoint may still be starting up"
    fi
else
    echo "⚠️ Could not retrieve service URL"
fi

echo ""
echo "🎉 Deployment process complete!"
echo ""
echo "📊 Service Information:"
echo "  - Service Name: ${SERVICE_NAME}"
echo "  - Project: ${PROJECT_ID}"
echo "  - Region: ${REGION}"
echo "  - URL: ${SERVICE_URL}"
echo "  - Domain: persistent.specu.io (if domain mapping exists)"
echo ""
echo "🔗 Available Endpoints:"
echo "  - RPC: ${SERVICE_URL}/rpc"
echo "  - API: ${SERVICE_URL}/api"
echo "  - gRPC: ${SERVICE_URL}/grpc"
echo "  - WebSocket P2P: wss://${SERVICE_URL#https://}/"
echo ""
echo "🔍 To verify deployment:"
echo "  ./verify-websocket-proxy.sh"
echo ""
echo "📋 To check logs:"
echo "  gcloud logging read \"resource.type=cloud_run_revision AND resource.labels.service_name=${SERVICE_NAME}\" --limit=50"
