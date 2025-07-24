#!/bin/bash

# Deploy Speculod with Nginx Reverse Proxy to Google Cloud Run

set -e

echo "🚀 Deploying Speculod with Nginx Reverse Proxy to Google Cloud Run..."

# Configuration
PROJECT_ID="${PROJECT_ID:-speculo-blockchain}"
REGION="${REGION:-europe-west1}"
SERVICE_NAME="speculo-persistent-node-1"
IMAGE_NAME="gcr.io/${PROJECT_ID}/speculod-nginx-proxy"
DOMAIN="${DOMAIN:-persistent.specu.io}"

# Build and push the image
echo "🔨 Building Docker image with nginx proxy..."
docker build -f Dockerfile.nginx-simple -t "${IMAGE_NAME}:latest" .

echo "📤 Pushing image to Google Container Registry..."
docker push "${IMAGE_NAME}:latest"

# Deploy to Cloud Run
echo "🚀 Deploying to Cloud Run..."
gcloud run deploy "$SERVICE_NAME" \
    --image="${IMAGE_NAME}:latest" \
    --platform=managed \
    --region="$REGION" \
    --allow-unauthenticated \
    --memory=2Gi \
    --cpu=2 \
    --timeout=300 \
    --concurrency=80 \
    --min-instances=1 \
    --max-instances=4 \
    --execution-environment=gen2 \
    --cpu-boost \
    --no-cpu-throttling \
    --set-env-vars="NODE_TYPE=persistent,CHAIN_ID=speculod-mainnet-1,MONIKER=nginx-proxy-node,MINIMUM_GAS_PRICES=0.01stake,EXTERNAL_ADDRESS=${DOMAIN}:443" \
    --port=8080

# Get the service URL
SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" --region="$REGION" --format="value(status.url)")
echo "✅ Service deployed at: $SERVICE_URL"

# Configure domain mapping
if [ -n "$DOMAIN" ]; then
    echo "🌐 Configuring domain mapping for $DOMAIN..."
    
    # Create domain mapping
    gcloud run domain-mappings create \
        --service="$SERVICE_NAME" \
        --domain="$DOMAIN" \
        --region="$REGION" || echo "⚠️  Domain mapping might already exist"
    
    echo "✅ Domain mapping configured for $DOMAIN"
    echo "📋 DNS Configuration Required:"
    echo "   Add CNAME record: $DOMAIN -> ghs.googlehosted.com"
fi

echo ""
echo "🎉 Deployment Complete!"
echo ""
echo "📊 Service Endpoints:"
echo "   Base URL: https://$DOMAIN"
echo "   Health Check: https://$DOMAIN/health"
echo "   RPC Status: https://$DOMAIN/status"
echo "   RPC (prefixed): https://$DOMAIN/rpc/status"
echo "   REST API: https://$DOMAIN/cosmos/bank/v1beta1/supply"
echo "   API (prefixed): https://$DOMAIN/api/cosmos/bank/v1beta1/supply"
echo ""
echo "🔧 P2P Connection:"
echo "   P2P Address: Use for persistent peers - need to get node_id from /status"
echo ""
echo "📝 Usage Examples:"
echo "   curl https://$DOMAIN/status"
echo "   curl https://$DOMAIN/cosmos/bank/v1beta1/supply"
echo "   curl https://$DOMAIN/health"
