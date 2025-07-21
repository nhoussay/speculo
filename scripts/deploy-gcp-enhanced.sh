#!/bin/bash

# Enhanced Multi-Service Google Cloud Deployment with Port Strategy
set -e

echo "=================================================="
echo "☁️ SPECULOD ENHANCED MULTI-SERVICE DEPLOYMENT"
echo "=================================================="

# Configuration
PROJECT_ID="${PROJECT_ID}"
REGION="${REGION:-europe-west1}"
ZONE="${ZONE:-europe-west1-b}"
DEPLOYMENT_TYPE="${DEPLOYMENT_TYPE:-single}"  # single, multi, hybrid

# Service configuration
SERVICES=("validator" "api" "faucet")
VALIDATOR_RESOURCES="cpu=2,memory=4Gi"
API_RESOURCES="cpu=1,memory=2Gi"  
FAUCET_RESOURCES="cpu=0.5,memory=1Gi"

echo "📋 Deployment Configuration:"
echo "   Project: $PROJECT_ID"
echo "   Region: $REGION"
echo "   Type: $DEPLOYMENT_TYPE"
echo "   Services: ${SERVICES[*]}"

# Validate project ID
if [ -z "$PROJECT_ID" ]; then
    echo "❌ Error: PROJECT_ID environment variable is required"
    echo "   Example: export PROJECT_ID=speculod-prod-123"
    exit 1
fi

# Function to check if service exists
service_exists() {
    local service_name=$1
    gcloud run services describe $service_name --region=$REGION --project=$PROJECT_ID >/dev/null 2>&1
}

# Function to create VPC infrastructure
setup_vpc() {
    echo "🌐 Setting up VPC infrastructure..."
    
    # Create VPC network
    if ! gcloud compute networks describe speculod-vpc --project=$PROJECT_ID >/dev/null 2>&1; then
        echo "Creating VPC network..."
        gcloud compute networks create speculod-vpc \
            --subnet-mode=custom \
            --project=$PROJECT_ID
            
        gcloud compute networks subnets create speculod-subnet \
            --network=speculod-vpc \
            --region=$REGION \
            --range=10.0.0.0/16 \
            --project=$PROJECT_ID
    fi
    
    # Create VPC connector for Cloud Run
    if ! gcloud compute networks vpc-access connectors describe speculod-connector --region=$REGION --project=$PROJECT_ID >/dev/null 2>&1; then
        echo "Creating VPC connector..."
        gcloud compute networks vpc-access connectors create speculod-connector \
            --network=speculod-vpc \
            --region=$REGION \
            --range=10.1.0.0/28 \
            --project=$PROJECT_ID
    fi
    
    echo "✅ VPC infrastructure ready"
}

# Function to deploy single service (current approach)
deploy_single() {
    echo "🚀 Deploying single all-in-one service..."
    
    # Build and push image
    echo "Building container image..."
    gcloud builds submit --tag gcr.io/$PROJECT_ID/speculod:latest --project=$PROJECT_ID .
    
    # Deploy to Cloud Run
    echo "Deploying to Cloud Run..."
    gcloud run deploy speculod-blockchain \
        --image gcr.io/$PROJECT_ID/speculod:latest \
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
        --vpc-connector speculod-connector \
        --set-env-vars DEPLOYMENT_MODE=cloud,CHAIN_ID=speculod,MONIKER=speculod-gcp \
        --project=$PROJECT_ID
        
    echo "✅ Single service deployment complete"
}

# Function to deploy validator service
deploy_validator() {
    echo "🔗 Deploying validator service..."
    
    # Build validator-specific image
    gcloud builds submit --tag gcr.io/$PROJECT_ID/speculod-validator:latest \
        --config=cloudbuild-validator.yaml --project=$PROJECT_ID .
    
    # Deploy validator (internal only)
    gcloud run deploy speculod-validator \
        --image gcr.io/$PROJECT_ID/speculod-validator:latest \
        --platform managed \
        --region $REGION \
        --no-allow-unauthenticated \
        --port 8080 \
        --cpu 2 \
        --memory 4Gi \
        --max-instances 1 \
        --min-instances 1 \
        --timeout 3600 \
        --vpc-connector speculod-connector \
        --ingress internal \
        --set-env-vars DEPLOYMENT_MODE=validator,CHAIN_ID=speculod,MONIKER=speculod-validator \
        --project=$PROJECT_ID
        
    # Get validator internal URL for other services
    VALIDATOR_URL=$(gcloud run services describe speculod-validator --region=$REGION --project=$PROJECT_ID --format="value(status.url)")
    echo "Validator URL: $VALIDATOR_URL"
    
    echo "✅ Validator service deployed"
}

# Function to deploy API service
deploy_api() {
    echo "🌐 Deploying API service..."
    
    # Build API-specific image
    gcloud builds submit --tag gcr.io/$PROJECT_ID/speculod-api:latest \
        --config=cloudbuild-api.yaml --project=$PROJECT_ID .
    
    # Deploy API service (public)
    gcloud run deploy speculod-api \
        --image gcr.io/$PROJECT_ID/speculod-api:latest \
        --platform managed \
        --region $REGION \
        --allow-unauthenticated \
        --port 8080 \
        --cpu 1 \
        --memory 2Gi \
        --max-instances 5 \
        --min-instances 1 \
        --vpc-connector speculod-connector \
        --set-env-vars TENDERMINT_RPC_URL=${VALIDATOR_URL}/rpc,DEPLOYMENT_MODE=api \
        --project=$PROJECT_ID
        
    echo "✅ API service deployed"
}

# Function to deploy faucet service
deploy_faucet() {
    echo "💰 Deploying faucet service..."
    
    # Build faucet-specific image
    gcloud builds submit --tag gcr.io/$PROJECT_ID/speculod-faucet:latest \
        --config=cloudbuild-faucet.yaml --project=$PROJECT_ID .
    
    # Deploy faucet service (public)
    gcloud run deploy speculod-faucet \
        --image gcr.io/$PROJECT_ID/speculod-faucet:latest \
        --platform managed \
        --region $REGION \
        --allow-unauthenticated \
        --port 8080 \
        --cpu 0.5 \
        --memory 1Gi \
        --max-instances 3 \
        --min-instances 1 \
        --vpc-connector speculod-connector \
        --set-env-vars TENDERMINT_RPC_URL=${VALIDATOR_URL}/rpc \
        --project=$PROJECT_ID
        
    echo "✅ Faucet service deployed"
}

# Function to setup monitoring
setup_monitoring() {
    echo "📊 Setting up monitoring..."
    
    # Create uptime checks
    gcloud alpha monitoring uptime create speculod-api-uptime \
        --display-name="Speculod API Health" \
        --resource-type=url \
        --hostname="$(gcloud run services describe speculod-api --region=$REGION --project=$PROJECT_ID --format='value(status.url)' | sed 's|https://||')" \
        --path="/health" \
        --project=$PROJECT_ID || true
        
    echo "✅ Monitoring configured"
}

# Main deployment logic
main() {
    echo "🔐 Checking authentication and project access..."
    gcloud config set project $PROJECT_ID
    
    echo "🚀 Enabling required services..."
    gcloud services enable run.googleapis.com containerregistry.googleapis.com \
        cloudbuild.googleapis.com monitoring.googleapis.com --project=$PROJECT_ID
    
    # Setup infrastructure
    setup_vpc
    
    # Deploy based on type
    case $DEPLOYMENT_TYPE in
        "single")
            deploy_single
            ;;
        "multi")
            deploy_validator
            deploy_api  
            deploy_faucet
            ;;
        "hybrid")
            echo "🔧 Hybrid deployment (GKE + Cloud Run) not yet implemented"
            echo "   Using multi-service approach instead..."
            deploy_validator
            deploy_api
            deploy_faucet
            ;;
        *)
            echo "❌ Unknown deployment type: $DEPLOYMENT_TYPE"
            echo "   Supported: single, multi, hybrid"
            exit 1
            ;;
    esac
    
    # Setup monitoring
    setup_monitoring
    
    echo ""
    echo "=================================================="
    echo "🎉 DEPLOYMENT COMPLETE!"
    echo "=================================================="
    
    if [ "$DEPLOYMENT_TYPE" = "single" ]; then
        SERVICE_URL=$(gcloud run services describe speculod-blockchain --region=$REGION --project=$PROJECT_ID --format="value(status.url)")
        echo "🌐 Service URL: $SERVICE_URL"
        echo "📊 API Docs: $SERVICE_URL/swagger"
        echo "🔍 Health Check: $SERVICE_URL/health"
    else
        API_URL=$(gcloud run services describe speculod-api --region=$REGION --project=$PROJECT_ID --format="value(status.url)")
        FAUCET_URL=$(gcloud run services describe speculod-faucet --region=$REGION --project=$PROJECT_ID --format="value(status.url)")
        echo "🌐 API Service: $API_URL"
        echo "💰 Faucet Service: $FAUCET_URL"
        echo "📊 API Docs: $API_URL/swagger"
    fi
    
    echo ""
    echo "📋 Next Steps:"
    echo "   1. Test endpoints: curl \$SERVICE_URL/health"
    echo "   2. Monitor logs: gcloud logs read speculod-blockchain"
    echo "   3. View metrics: https://console.cloud.google.com/monitoring"
    echo "   4. Scale services: gcloud run services update --min-instances=N"
}

# Execute main function
main "$@"
