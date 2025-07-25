#!/bin/bash

# Simple Validator Deployment Script
# This deploys a validator service to produce blocks for the blockchain network

set -e

PROJECT_ID="speculo-blockchain"
REGION="europe-west1"
SERVICE_NAME="speculod-validator"

echo "🔗 Deploying Speculod Validator Service..."
echo "   Project: $PROJECT_ID"
echo "   Region: $REGION"
echo "   Service: $SERVICE_NAME"

# Wait for image to be available (in case build is still running)
echo "⏳ Waiting for validator image to be available..."
while ! gcloud container images list-tags gcr.io/$PROJECT_ID/speculod-validator --limit=1 --format="value(timestamp)" --project=$PROJECT_ID >/dev/null 2>&1; do
    echo "   Waiting for image build to complete..."
    sleep 10
done

echo "✅ Validator image is available"

# Deploy the validator service
echo "🚀 Deploying validator service..."
gcloud run deploy $SERVICE_NAME \
    --image gcr.io/$PROJECT_ID/speculod-validator:latest \
    --platform managed \
    --region $REGION \
    --allow-unauthenticated \
    --port 8080 \
    --cpu 2 \
    --memory 4Gi \
    --max-instances 1 \
    --min-instances 1 \
    --timeout 3600 \
    --set-env-vars "DEPLOYMENT_MODE=validator,CHAIN_ID=speculod-local-1,MONIKER=speculod-validator-gcp" \
    --project=$PROJECT_ID

# Get the service URL
VALIDATOR_URL=$(gcloud run services describe $SERVICE_NAME --region=$REGION --project=$PROJECT_ID --format="value(status.url)")

echo ""
echo "✅ Validator service deployed successfully!"
echo "   Service URL: $VALIDATOR_URL"
echo "   Health Check: $VALIDATOR_URL/health"
echo "   Ready Check: $VALIDATOR_URL/ready"

# Test the deployment
echo ""
echo "🧪 Testing validator deployment..."
echo -n "   Health check: "
if curl -s --max-time 10 "$VALIDATOR_URL/health" >/dev/null 2>&1; then
    echo "✅ PASSED"
else
    echo "❌ FAILED"
fi

echo -n "   Ready check: "
if curl -s --max-time 30 "$VALIDATOR_URL/ready" >/dev/null 2>&1; then
    echo "✅ PASSED"
else
    echo "⚠️  NOT READY (this is normal for a new blockchain)"
fi

echo ""
echo "📋 Next Steps:"
echo "1. Wait 2-3 minutes for the blockchain to initialize"
echo "2. Test block production: curl $VALIDATOR_URL/rpc/status"
echo "3. Update nginx proxy to connect to this validator"
echo "4. Check persistent.specu.io for block production"

echo ""
echo "🔧 Validator Service Information:"
echo "   Internal URL: $VALIDATOR_URL"
echo "   RPC Endpoint: $VALIDATOR_URL/rpc/status"
echo "   P2P Protocol: WebSocket support for external connections"
