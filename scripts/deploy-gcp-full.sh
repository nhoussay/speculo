#!/bin/bash

# Enhanced Google Cloud Deployment with Faucet Support
set -e

echo "=================================================="
echo "☁️ SPECULOD CLOUD DEPLOYMENT WITH FAUCET"
echo "=================================================="

# Configuration
PROJECT_ID="${PROJECT_ID}"
REGION="${REGION:-europe-west1}"
SERVICE_NAME="speculod-blockchain-with-faucet"
IMAGE_NAME="speculod:latest"

# Validate project ID
if [ -z "$PROJECT_ID" ]; then
    echo "❌ Error: PROJECT_ID environment variable is required"
    echo "   Set it with: export PROJECT_ID=your-gcp-project-id"
    exit 1
fi

# Check authentication
echo "🔐 Checking Google Cloud authentication..."
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -1 > /dev/null; then
    echo "❌ Error: Not authenticated with Google Cloud"
    echo "   Run: gcloud auth login"
    exit 1
fi

# Check if project exists and set it
echo "🔍 Setting up project configuration..."
gcloud config set project $PROJECT_ID
if ! gcloud projects describe $PROJECT_ID > /dev/null 2>&1; then
    echo "❌ Error: Project $PROJECT_ID not found or no access"
    echo "   Make sure the project exists and you have access"
    exit 1
fi

# Enable required APIs
echo "🔧 Enabling required APIs..."
gcloud services enable run.googleapis.com containerregistry.googleapis.com --project=$PROJECT_ID

echo "🔧 Configuration:"
echo "   Project ID: $PROJECT_ID"
echo "   Region: $REGION"
echo "   Service Name: $SERVICE_NAME"
echo "   Image: $IMAGE_NAME"
echo ""

echo "=================================================="
echo "🏗️ BUILDING AND PUSHING DOCKER IMAGE"
echo "=================================================="

# Configure Docker for GCR
echo "🔐 Configuring Docker for Google Container Registry..."
gcloud auth configure-docker

# Build the enhanced image
echo "📦 Building enhanced Docker image with faucet support..."
docker build -t $IMAGE_NAME .

# Tag and push to GCR
echo "🚀 Pushing to Google Container Registry..."
docker tag $IMAGE_NAME gcr.io/$PROJECT_ID/$IMAGE_NAME
docker push gcr.io/$PROJECT_ID/$IMAGE_NAME

echo "=================================================="
echo "⚙️ DEPLOYING TO CLOUD RUN"
echo "=================================================="

# Update the service configuration with the correct project ID
sed "s/PROJECT_ID/$PROJECT_ID/g" gcp-cloudrun-full.yaml > gcp-cloudrun-full-configured.yaml

# Deploy to Cloud Run with error handling
echo "🌐 Deploying to Cloud Run..."
if gcloud run services replace gcp-cloudrun-full-configured.yaml \
    --region=$REGION \
    --project=$PROJECT_ID; then
    echo "✅ Service deployed successfully!"
else
    echo "⚠️ Service replace failed, trying direct deployment..."
    # Alternative deployment method
    gcloud run deploy speculod-blockchain-with-faucet \
        --image gcr.io/$PROJECT_ID/speculod:latest \
        --region=$REGION \
        --project=$PROJECT_ID \
        --platform managed \
        --allow-unauthenticated \
        --port=8080 \
        --memory=4Gi \
        --cpu=2 \
        --max-instances=1 \
        --min-instances=1 \
        --timeout=3600 \
        --concurrency=1000 \
        --set-env-vars="DEPLOYMENT_MODE=cloud,CHAIN_ID=speculod,MONIKER=speculod-gcp-full,CONTAINER_NAME=localhost"
fi

# Get the service URL
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME \
    --region=$REGION \
    --project=$PROJECT_ID \
    --format='value(status.url)')

# Clean up temporary file
rm -f gcp-cloudrun-full-configured.yaml

echo ""
echo "=================================================="
echo "🎉 DEPLOYMENT COMPLETE!"
echo "=================================================="
echo ""
echo "🔗 Your Speculod blockchain is now running on Google Cloud:"
echo ""
echo "🌐 **PRIMARY ENDPOINTS:**"
echo "   • Blockchain RPC:    $SERVICE_URL"
echo "   • REST API:          $SERVICE_URL:1317"
echo "   • Token Faucet:      $SERVICE_URL:4500"
echo "   • gRPC Services:     $SERVICE_URL:9090"
echo ""
echo "📱 **FAUCET ACCESS:**"
echo "   • Web Interface:     $SERVICE_URL:4500"
echo "   • Status Check:      $SERVICE_URL:4500/status"
echo ""
echo "🔍 **HEALTH CHECKS:**"
echo "   • Blockchain:        $SERVICE_URL/status"
echo "   • Faucet:           $SERVICE_URL:4500/health"
echo ""
echo "📊 **MONITORING:**"
echo "   • Cloud Run Console: https://console.cloud.google.com/run"
echo "   • Service Logs:      gcloud logs read --service=$SERVICE_NAME --region=$REGION"
echo ""
echo "🛠️ **MANAGEMENT COMMANDS:**"
echo "   • Update service:    ./scripts/deploy-gcp-full.sh"
echo "   • View logs:         gcloud logs tail --service=$SERVICE_NAME --region=$REGION"
echo "   • Scale to zero:     gcloud run services update $SERVICE_NAME --min-instances=0 --region=$REGION"
echo ""

# Test connectivity
echo "🔍 Testing connectivity..."
if curl -s --max-time 30 "$SERVICE_URL/status" >/dev/null; then
    echo "✅ Blockchain: Accessible"
else
    echo "⏳ Blockchain: Starting up (may take a few minutes)"
fi

echo ""
echo "🎯 Your complete Starport-style environment is now running in the cloud!"
echo "   Access the faucet at: $SERVICE_URL:4500"
