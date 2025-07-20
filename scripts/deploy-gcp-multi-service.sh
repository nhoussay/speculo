#!/bin/bash

# Multi-Service Google Cloud Deployment
set -e

echo "=================================================="
echo "☁️ SPECULOD MULTI-SERVICE CLOUD DEPLOYMENT"
echo "=================================================="

# Configuration
PROJECT_ID="${PROJECT_ID}"
REGION="${REGION:-europe-west1}"

# Validate project ID
if [ -z "$PROJECT_ID" ]; then
    echo "❌ Error: PROJECT_ID environment variable is required"
    echo "   Set it with: export PROJECT_ID=your-gcp-project-id"
    echo "   Example: export PROJECT_ID=speculod-prod-123"
    echo ""
    echo "📚 For detailed instructions, see: DEPLOYMENT_GUIDE.md"
    exit 1
fi

# Check authentication
echo "🔐 Checking Google Cloud authentication..."
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -1 > /dev/null 2>&1; then
    echo "❌ Error: Not authenticated with Google Cloud"
    echo "   Run: gcloud auth login"
    echo "   Then: gcloud auth configure-docker"
    exit 1
fi

# Verify project exists and user has access
echo "🔍 Verifying project access..."
if ! gcloud projects describe $PROJECT_ID >/dev/null 2>&1; then
    echo "❌ Error: Cannot access project $PROJECT_ID"
    echo "   - Verify project exists: https://console.cloud.google.com/"
    echo "   - Check you have Project Editor/Owner permissions"
    echo "   - Run: gcloud projects list (to see available projects)"
    exit 1
fi

# Set up project
echo "🔍 Setting up project configuration..."
gcloud config set project $PROJECT_ID

echo "🚀 Enabling required Google Cloud services (this may take a moment)..."
gcloud services enable run.googleapis.com containerregistry.googleapis.com cloudbuild.googleapis.com --project=$PROJECT_ID

echo "✅ Project setup complete!"
echo "🔧 Configuration:"
echo "   Project ID: $PROJECT_ID"
echo "   Region: $REGION"
echo "   Account: $(gcloud config get-value account)"
echo ""

# Configure Docker for GCR
echo "🔐 Configuring Docker for Google Container Registry..."
gcloud auth configure-docker

echo "=================================================="
echo "🏗️ BUILDING DOCKER IMAGES"
echo "=================================================="

# Build blockchain service image
echo "📦 Building Blockchain Core service..."
if ! docker build -f Dockerfile.blockchain -t speculod-blockchain:latest . ; then
    echo "❌ Failed to build blockchain image"
    exit 1
fi
echo "🏷️ Tagging and pushing blockchain image..."
docker tag speculod-blockchain:latest gcr.io/$PROJECT_ID/speculod-blockchain:latest
if ! docker push gcr.io/$PROJECT_ID/speculod-blockchain:latest ; then
    echo "❌ Failed to push blockchain image"
    exit 1
fi
echo "✅ Blockchain image pushed successfully"

# Build API service image
echo "📦 Building REST API service..."
if ! docker build -f Dockerfile.api -t speculod-api:latest . ; then
    echo "❌ Failed to build API image"
    exit 1
fi
echo "🏷️ Tagging and pushing API image..."
docker tag speculod-api:latest gcr.io/$PROJECT_ID/speculod-api:latest
if ! docker push gcr.io/$PROJECT_ID/speculod-api:latest ; then
    echo "❌ Failed to push API image"
    exit 1
fi
echo "✅ API image pushed successfully"

# Build faucet service image
echo "📦 Building Token Faucet service..."
if ! docker build -f Dockerfile.faucet -t speculod-faucet:latest . ; then
    echo "❌ Failed to build faucet image"
    exit 1
fi
echo "🏷️ Tagging and pushing faucet image..."
docker tag speculod-faucet:latest gcr.io/$PROJECT_ID/speculod-faucet:latest
if ! docker push gcr.io/$PROJECT_ID/speculod-faucet:latest ; then
    echo "❌ Failed to push faucet image"
    exit 1
fi
echo "✅ Faucet image pushed successfully"

echo "=================================================="
echo "⚙️ DEPLOYING TO CLOUD RUN"
echo "=================================================="

# Deploy Blockchain Core Service
echo "🚀 Deploying Blockchain Core service..."
gcloud run deploy speculod-blockchain \
    --image gcr.io/$PROJECT_ID/speculod-blockchain:latest \
    --region=$REGION \
    --project=$PROJECT_ID \
    --platform managed \
    --allow-unauthenticated \
    --port=8080 \
    --memory=4Gi \
    --cpu=2 \
    --max-instances=3 \
    --min-instances=1 \
    --timeout=3600 \
    --concurrency=1000 \
    --cpu-throttling \
    --execution-environment=gen2 \
    --set-env-vars="SERVICE_TYPE=blockchain,CHAIN_ID=speculod,MONIKER=speculod-blockchain"

# Deploy REST API Service
echo "🚀 Deploying REST API service..."
gcloud run deploy speculod-api \
    --image gcr.io/$PROJECT_ID/speculod-api:latest \
    --region=$REGION \
    --project=$PROJECT_ID \
    --platform managed \
    --allow-unauthenticated \
    --port=8080 \
    --memory=2Gi \
    --cpu=1 \
    --max-instances=5 \
    --min-instances=0 \
    --timeout=300 \
    --concurrency=1000 \
    --set-env-vars="SERVICE_TYPE=api,BLOCKCHAIN_ENDPOINT=https://speculod-blockchain-[HASH]-ew.a.run.app"

# Deploy Token Faucet Service
echo "🚀 Deploying Token Faucet service..."
gcloud run deploy speculod-faucet \
    --image gcr.io/$PROJECT_ID/speculod-faucet:latest \
    --region=$REGION \
    --project=$PROJECT_ID \
    --platform managed \
    --allow-unauthenticated \
    --port=8080 \
    --memory=512Mi \
    --cpu=1 \
    --max-instances=10 \
    --min-instances=0 \
    --timeout=300 \
    --concurrency=1000 \
    --set-env-vars="SERVICE_TYPE=faucet,BLOCKCHAIN_ENDPOINT=https://speculod-blockchain-[HASH]-ew.a.run.app"

# Get service URLs
echo "=================================================="
echo "🔗 GETTING SERVICE URLS"
echo "=================================================="

BLOCKCHAIN_URL=$(gcloud run services describe speculod-blockchain \
    --region=$REGION \
    --project=$PROJECT_ID \
    --format='value(status.url)')

API_URL=$(gcloud run services describe speculod-api \
    --region=$REGION \
    --project=$PROJECT_ID \
    --format='value(status.url)')

FAUCET_URL=$(gcloud run services describe speculod-faucet \
    --region=$REGION \
    --project=$PROJECT_ID \
    --format='value(status.url)')

# Update API and Faucet services with correct blockchain endpoint
echo "🔄 Updating service configurations with blockchain endpoint..."
if [ -n "$BLOCKCHAIN_URL" ]; then
    echo "   Updating API service..."
    gcloud run services update speculod-api \
        --region=$REGION \
        --project=$PROJECT_ID \
        --set-env-vars="SERVICE_TYPE=api,BLOCKCHAIN_ENDPOINT=$BLOCKCHAIN_URL" \
        --quiet || echo "⚠️ Warning: Could not update API service configuration"
    
    echo "   Updating Faucet service..."
    gcloud run services update speculod-faucet \
        --region=$REGION \
        --project=$PROJECT_ID \
        --set-env-vars="SERVICE_TYPE=faucet,BLOCKCHAIN_ENDPOINT=$BLOCKCHAIN_URL" \
        --quiet || echo "⚠️ Warning: Could not update Faucet service configuration"
    echo "✅ Service configurations updated"
else
    echo "⚠️ Warning: Could not retrieve blockchain URL for service configuration"
fi

echo ""
echo "🎉 DEPLOYMENT COMPLETE!"
echo "=================================================="
echo ""
echo "🌐 **LIVE SERVICES:**"
echo ""
echo "🔗 Blockchain Core:"
echo "   URL:        $BLOCKCHAIN_URL"
echo "   Status:     $BLOCKCHAIN_URL/status"
echo "   Health:     $BLOCKCHAIN_URL/health"
echo ""
echo "🔗 REST API:"
echo "   URL:        $API_URL"
echo "   Swagger:    $API_URL/swagger/"
echo "   Cosmos:     $API_URL/cosmos/*"
echo ""
echo "🔗 Token Faucet:"
echo "   URL:        $FAUCET_URL"
echo "   Web UI:     $FAUCET_URL/"
echo "   Request:    $FAUCET_URL/request"
echo ""
echo "📊 **MONITORING:**"
echo "   • Cloud Console: https://console.cloud.google.com/run?project=$PROJECT_ID"
echo "   • View Logs:     gcloud logs tail --service=[SERVICE_NAME] --region=$REGION"
echo ""
echo "🛠️ **MANAGEMENT:**"
echo "   • Update:        Re-run this script"
echo "   • Scale down:    gcloud run services update [SERVICE] --min-instances=0"
echo "   • Delete:        gcloud run services delete [SERVICE] --region=$REGION"
echo ""

# Test connectivity
echo "🔍 Testing connectivity..."
echo "Testing blockchain service..."
if curl -s --max-time 10 "$BLOCKCHAIN_URL/health" >/dev/null; then
    echo "✅ Blockchain: Healthy"
else
    echo "⏳ Blockchain: Starting up..."
fi

echo "Testing faucet service..."
if curl -s --max-time 10 "$FAUCET_URL/" >/dev/null; then
    echo "✅ Faucet: Accessible"
else
    echo "⏳ Faucet: Starting up..."
fi

echo ""
echo "🎯 Your multi-service Speculod deployment is now live!"
echo "   Each service runs independently and can scale based on demand."
