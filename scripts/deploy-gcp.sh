#!/bin/bash

# Google Cloud Deployment Script for Speculod Blockchain

set -e

# Configuration
PROJECT_ID="${PROJECT_ID:-speculo-blockchain}"
REGION="${REGION:-europe-west1}"
SERVICE_NAME="speculod-blockchain"
IMAGE_NAME="speculod"
IMAGE_TAG="${IMAGE_TAG:-latest}"

echo "=================================================="
echo "🚀 SPECULOD BLOCKCHAIN - GOOGLE CLOUD DEPLOYMENT"
echo "=================================================="

echo "📋 Configuration:"
echo "   Project ID: $PROJECT_ID"
echo "   Region: $REGION"
echo "   Service Name: $SERVICE_NAME"
echo "   Image: $IMAGE_NAME:$IMAGE_TAG"
echo ""

# Verify prerequisites
echo "🔍 Verifying prerequisites..."

if ! command -v gcloud &> /dev/null; then
    echo "❌ gcloud CLI not found. Please install it first."
    echo "   https://cloud.google.com/sdk/docs/install"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found. Please install Docker first."
    exit 1
fi

echo "   ✓ gcloud CLI found"
echo "   ✓ Docker found"

# Set the project
echo "🔧 Setting up Google Cloud project..."
gcloud config set project $PROJECT_ID
echo "   ✓ Project set to: $PROJECT_ID"

# Enable required services
echo "🛠️  Enabling required Google Cloud services..."
gcloud services enable \
    cloudbuild.googleapis.com \
    run.googleapis.com \
    containerregistry.googleapis.com
echo "   ✓ Services enabled"

# Build and push Docker image
echo "🔨 Building Docker image..."
docker build -t gcr.io/$PROJECT_ID/$IMAGE_NAME:$IMAGE_TAG .
echo "   ✓ Docker image built"

echo "📤 Pushing image to Google Container Registry..."
docker push gcr.io/$PROJECT_ID/$IMAGE_NAME:$IMAGE_TAG
echo "   ✓ Image pushed successfully"

# Deploy to Cloud Run
echo "🚀 Deploying to Google Cloud Run..."
gcloud run deploy $SERVICE_NAME \
    --image gcr.io/$PROJECT_ID/$IMAGE_NAME:$IMAGE_TAG \
    --platform managed \
    --region $REGION \
    --allow-unauthenticated \
    --memory 4Gi \
    --cpu 2 \
    --max-instances 1 \
    --min-instances 1 \
    --timeout 3600 \
    --concurrency 1000 \
    --execution-environment gen2 \
    --cpu-boost \
    --set-env-vars "CHAIN_ID=speculod,MONIKER=speculod-gcp,RPC_LISTEN_PORT=\$PORT,P2P_LISTEN_PORT=26656"

echo ""
echo "=================================================="
echo "🎉 DEPLOYMENT COMPLETE!"
echo "=================================================="

# Get the service URL
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --region $REGION --format 'value(status.url)')

echo ""
echo "📊 Service Information:"
echo "   Service Name: $SERVICE_NAME"
echo "   Service URL: $SERVICE_URL"
echo "   Region: $REGION"
echo ""
echo "🔗 Blockchain Endpoints:"
echo "   RPC: $SERVICE_URL"
echo "   Status: $SERVICE_URL/status"
echo "   Health: $SERVICE_URL/health"
echo ""
echo "🧪 Test Commands:"
echo "   # Check status"
echo "   curl $SERVICE_URL/status"
echo ""
echo "   # Check block height"
echo "   curl -s $SERVICE_URL/status | jq '.result.sync_info.latest_block_height'"
echo ""
echo "📚 Additional Information:"
echo "   • Logs: gcloud run logs tail $SERVICE_NAME --region $REGION"
echo "   • Console: https://console.cloud.google.com/run/detail/$REGION/$SERVICE_NAME"
echo ""
