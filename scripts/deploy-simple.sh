#!/bin/bash

# Simple Google Cloud Run Deployment
set -e

PROJECT_ID="speculo-blockchain"
REGION="europe-west1" 
SERVICE_NAME="speculod-blockchain"
IMAGE_NAME="gcr.io/$PROJECT_ID/speculod:latest"

echo "🚀 Deploying Speculod to Google Cloud Run"
echo "   Project: $PROJECT_ID"
echo "   Region: $REGION"
echo "   Service: $SERVICE_NAME"

# Deploy to Cloud Run
echo "📦 Deploying container to Cloud Run..."
gcloud run deploy $SERVICE_NAME \
    --image $IMAGE_NAME \
    --platform managed \
    --region $REGION \
    --allow-unauthenticated \
    --port 8080 \
    --cpu 2 \
    --memory 4Gi \
    --max-instances 3 \
    --min-instances 1 \
    --timeout 3600 \
    --concurrency 1000 \
    --set-env-vars DEPLOYMENT_MODE=cloud,CHAIN_ID=speculod,MONIKER=speculod-gcp,PORT=8080 \
    --project=$PROJECT_ID

# Get the service URL
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --region=$REGION --project=$PROJECT_ID --format="value(status.url)")

echo ""
echo "🎉 Deployment Complete!"
echo "===================="
echo "🌐 Service URL: $SERVICE_URL"
echo "📊 API Docs: $SERVICE_URL/swagger"  
echo "🔍 Health Check: $SERVICE_URL/health"
echo "💰 Faucet: $SERVICE_URL/faucet"
echo ""
echo "📋 Management Commands:"
echo "   View logs: gcloud logs read $SERVICE_NAME --project=$PROJECT_ID"
echo "   Scale up: gcloud run services update $SERVICE_NAME --min-instances=2 --region=$REGION --project=$PROJECT_ID"
echo "   Monitor: https://console.cloud.google.com/run/detail/$REGION/$SERVICE_NAME"
