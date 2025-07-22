#!/bin/bash

# Deploy Persistent Tendermint Node to Google Cloud
set -e

echo "=================================================="
echo "🌟 SPECULOD PERSISTENT NODE DEPLOYMENT"
echo "=================================================="

# Configuration
PROJECT_ID="${PROJECT_ID}"
REGION="${REGION:-europe-west1}"
ZONE="${ZONE:-europe-west1-b}"
SERVICE_NAME="speculod-persistent-node"

# Resource configuration for persistent node
CPU_LIMIT="2"
MEMORY_LIMIT="4Gi"
MAX_INSTANCES="1"  # Persistent nodes should be singleton
MIN_INSTANCES="1"  # Always running

echo "📋 Deployment Configuration:"
echo "   Project: $PROJECT_ID"
echo "   Region: $REGION"
echo "   Service: $SERVICE_NAME"
echo "   Resources: ${CPU_LIMIT} CPU, ${MEMORY_LIMIT} RAM"

# Validate project ID
if [ -z "$PROJECT_ID" ]; then
    echo "❌ Error: PROJECT_ID environment variable is required"
    echo "   Example: export PROJECT_ID=speculod-prod-123"
    exit 1
fi

# Function to setup VPC infrastructure
setup_vpc() {
    echo "🌐 Setting up VPC infrastructure for persistent node..."
    
    # Create VPC network if it doesn't exist
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
    
    # Create VPC connector for Cloud Run if it doesn't exist
    if ! gcloud compute networks vpc-access connectors describe speculod-connector --region=$REGION --project=$PROJECT_ID >/dev/null 2>&1; then
        echo "Creating VPC connector..."
        gcloud compute networks vpc-access connectors create speculod-connector \
            --network=speculod-vpc \
            --region=$REGION \
            --range=10.1.0.0/28 \
            --project=$PROJECT_ID
    fi
    
    # Create firewall rules for P2P and RPC ports
    if ! gcloud compute firewall-rules describe speculod-p2p --project=$PROJECT_ID >/dev/null 2>&1; then
        echo "Creating P2P firewall rule..."
        gcloud compute firewall-rules create speculod-p2p \
            --allow tcp:26656 \
            --source-ranges 0.0.0.0/0 \
            --description "Allow P2P connections for Speculod blockchain" \
            --project=$PROJECT_ID
    fi
    
    if ! gcloud compute firewall-rules describe speculod-rpc --project=$PROJECT_ID >/dev/null 2>&1; then
        echo "Creating RPC firewall rule..."
        gcloud compute firewall-rules create speculod-rpc \
            --allow tcp:26657 \
            --source-ranges 0.0.0.0/0 \
            --description "Allow RPC connections for Speculod blockchain" \
            --project=$PROJECT_ID
    fi
    
    echo "✅ VPC infrastructure ready"
}

# Function to create service account for persistent node
create_service_account() {
    echo "🔐 Setting up service account..."
    
    local sa_name="speculod-persistent-node-sa"
    
    if ! gcloud iam service-accounts describe $sa_name@$PROJECT_ID.iam.gserviceaccount.com --project=$PROJECT_ID >/dev/null 2>&1; then
        echo "Creating service account..."
        gcloud iam service-accounts create $sa_name \
            --display-name="Speculod Persistent Node Service Account" \
            --description="Service account for Speculod persistent blockchain node" \
            --project=$PROJECT_ID
    fi
    
    echo "✅ Service account ready"
}

# Function to build and deploy persistent node
deploy_persistent_node() {
    echo "🔗 Building and deploying persistent node..."
    
    # Build persistent node image
    echo "Building container image..."
    gcloud builds submit --config=cloudbuild-persistent-node.yaml --project=$PROJECT_ID .
    
    # Get external IP (will be used for EXTERNAL_ADDRESS)
    echo "Setting up external IP..."
    if ! gcloud compute addresses describe speculod-persistent-ip --region=$REGION --project=$PROJECT_ID >/dev/null 2>&1; then
        gcloud compute addresses create speculod-persistent-ip \
            --region=$REGION \
            --project=$PROJECT_ID
    fi
    
    EXTERNAL_IP=$(gcloud compute addresses describe speculod-persistent-ip --region=$REGION --project=$PROJECT_ID --format="value(address)")
    echo "External IP: $EXTERNAL_IP"
    
    # Deploy to Cloud Run
    echo "Deploying persistent node to Cloud Run..."
    gcloud run deploy $SERVICE_NAME \
        --image gcr.io/$PROJECT_ID/speculod-persistent-node:latest \
        --platform managed \
        --region $REGION \
        --allow-unauthenticated \
        --port 26657 \
        --cpu $CPU_LIMIT \
        --memory $MEMORY_LIMIT \
        --max-instances $MAX_INSTANCES \
        --min-instances $MIN_INSTANCES \
        --timeout 3600 \
        --concurrency 1 \
        --vpc-connector speculod-connector \
        --service-account speculod-persistent-node-sa@$PROJECT_ID.iam.gserviceaccount.com \
        --set-env-vars SERVICE_TYPE=tendermint,NODE_TYPE=persistent,CHAIN_ID=speculod,MONIKER=speculod-persistent-gcp,EXTERNAL_ADDRESS=tcp://$EXTERNAL_IP:26656 \
        --project=$PROJECT_ID
        
    # Get service URL
    SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --region=$REGION --project=$PROJECT_ID --format="value(status.url)")
    
    echo "✅ Persistent node deployed successfully"
    echo "🌐 Service URL: $SERVICE_URL"
    echo "🔍 RPC Endpoint: $SERVICE_URL"
    echo "🌍 External P2P Address: tcp://$EXTERNAL_IP:26656"
}

# Function to setup monitoring for persistent node
setup_monitoring() {
    echo "📊 Setting up monitoring for persistent node..."
    
    SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --region=$REGION --project=$PROJECT_ID --format="value(status.url)")
    HOSTNAME=$(echo $SERVICE_URL | sed 's|https://||')
    
    # Create uptime check for RPC endpoint
    if ! gcloud alpha monitoring uptime list --filter="displayName:Speculod Persistent Node RPC" --project=$PROJECT_ID | grep -q "Speculod Persistent Node RPC"; then
        gcloud alpha monitoring uptime create speculod-persistent-rpc-uptime \
            --display-name="Speculod Persistent Node RPC" \
            --resource-type=url \
            --hostname="$HOSTNAME" \
            --path="/status" \
            --port=443 \
            --protocol=HTTPS \
            --project=$PROJECT_ID || true
    fi
    
    echo "✅ Monitoring configured"
}

# Function to get node information
get_node_info() {
    echo "📋 Retrieving node information..."
    
    SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --region=$REGION --project=$PROJECT_ID --format="value(status.url)")
    EXTERNAL_IP=$(gcloud compute addresses describe speculod-persistent-ip --region=$REGION --project=$PROJECT_ID --format="value(address)")
    
    echo ""
    echo "🌟 PERSISTENT NODE INFORMATION:"
    echo "   RPC URL: $SERVICE_URL"
    echo "   Status: $SERVICE_URL/status"
    echo "   Health: $SERVICE_URL/health"
    echo "   Node Info: $SERVICE_URL/node_info"
    echo ""
    echo "🔗 P2P CONNECTION INFO:"
    echo "   External P2P Address: tcp://$EXTERNAL_IP:26656"
    echo "   For other nodes to connect, use: PERSISTENT_PEERS=<node_id>@$EXTERNAL_IP:26656"
    echo ""
    echo "📋 To get the node ID for peer connections:"
    echo "   curl -s $SERVICE_URL/status | jq -r '.result.node_info.id'"
}

# Main deployment function
main() {
    echo "🔐 Checking authentication and project access..."
    gcloud config set project $PROJECT_ID
    
    echo "🚀 Enabling required services..."
    gcloud services enable run.googleapis.com containerregistry.googleapis.com \
        cloudbuild.googleapis.com monitoring.googleapis.com compute.googleapis.com \
        vpcaccess.googleapis.com --project=$PROJECT_ID
    
    # Setup infrastructure
    setup_vpc
    create_service_account
    
    # Deploy persistent node
    deploy_persistent_node
    
    # Setup monitoring
    setup_monitoring
    
    # Get node information
    get_node_info
    
    echo ""
    echo "=================================================="
    echo "🎉 PERSISTENT NODE DEPLOYMENT COMPLETE!"
    echo "=================================================="
    echo ""
    echo "📋 Next Steps:"
    echo "   1. Test RPC: curl $SERVICE_URL/status"
    echo "   2. Get node ID: curl -s $SERVICE_URL/status | jq -r '.result.node_info.id'"
    echo "   3. Monitor logs: gcloud logs read $SERVICE_NAME --project=$PROJECT_ID"
    echo "   4. View metrics: https://console.cloud.google.com/run/detail/$REGION/$SERVICE_NAME/metrics"
    echo ""
    echo "🌐 This persistent node can now serve as a seed for other nodes in your network!"
}

# Execute main function
main "$@"
