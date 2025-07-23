#!/bin/bash

# ============================================================================
# Speculo Persistent Node Deployment Script
# ============================================================================
# This script deploys a persistent node to Google Cloud Run with proper
# domain mapping and configuration for the Speculo blockchain network.
#
# Features:
# - Deploys persistent node with P2P port configuration
# - Handles domain mapping to persistent.specu.io
# - Configures environment variables for mainnet
# - Validates deployment and checks service health
# ============================================================================

set -euo pipefail

# Configuration
PROJECT_ID="speculo-blockchain"
SERVICE_NAME="speculo-persistent-node-1"
REGION="europe-west1"
DOMAIN="persistent.specu.io"
IMAGE="gcr.io/speculo-blockchain/speculod-persistent-node:latest"
CHAIN_ID="speculod-mainnet-1"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if gcloud is installed and authenticated
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v gcloud &> /dev/null; then
        log_error "gcloud CLI is not installed. Please install it first."
        exit 1
    fi
    
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        log_error "No active gcloud authentication found. Please run 'gcloud auth login'"
        exit 1
    fi
    
    # Set project
    gcloud config set project "$PROJECT_ID"
    log_success "Prerequisites checked"
}

# Delete existing service if it exists
cleanup_existing_service() {
    log_info "Checking for existing service..."
    
    if gcloud run services describe "$SERVICE_NAME" --region="$REGION" &>/dev/null; then
        log_warning "Existing service found. Deleting..."
        gcloud run services delete "$SERVICE_NAME" --region="$REGION" --quiet
        log_success "Existing service deleted"
        
        # Wait a moment for cleanup
        sleep 5
    else
        log_info "No existing service found"
    fi
}

# Deploy the persistent node
deploy_persistent_node() {
    log_info "Deploying persistent node..."
    
    gcloud run deploy "$SERVICE_NAME" \
        --image="$IMAGE" \
        --port=26656 \
        --region="$REGION" \
        --allow-unauthenticated \
        --memory=2Gi \
        --cpu=1 \
        --max-instances=10 \
        --min-instances=1 \
        --concurrency=1000 \
        --timeout=3600 \
        --set-env-vars="CHAIN_ID=$CHAIN_ID,NODE_TYPE=persistent,SERVICE_TYPE=p2p,GITHUB_NETWORK_CONFIG=true,NETWORK_CONFIG_REPO=nhoussay/speculo,NETWORK_CONFIG_BRANCH=main" \
        --labels="type=persistent-node,network=mainnet,service=p2p"
    
    if [ $? -eq 0 ]; then
        log_success "Persistent node deployed successfully"
    else
        log_error "Failed to deploy persistent node"
        exit 1
    fi
}

# Configure domain mapping
setup_domain_mapping() {
    log_info "Setting up domain mapping..."
    
    # Check if domain mapping already exists
    if gcloud beta run domain-mappings list --region="$REGION" --format="value(metadata.name)" | grep -q "$DOMAIN"; then
        log_warning "Domain mapping already exists. Skipping creation."
    else
        log_info "Creating domain mapping for $DOMAIN..."
        gcloud beta run domain-mappings create \
            --service="$SERVICE_NAME" \
            --domain="$DOMAIN" \
            --region="$REGION"
        
        if [ $? -eq 0 ]; then
            log_success "Domain mapping created successfully"
        else
            log_error "Failed to create domain mapping"
            exit 1
        fi
    fi
}

# Validate deployment
validate_deployment() {
    log_info "Validating deployment..."
    
    # Get service URL
    SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" --region="$REGION" --format="value(status.url)")
    log_info "Service URL: $SERVICE_URL"
    
    # Check service status
    STATUS=$(gcloud run services describe "$SERVICE_NAME" --region="$REGION" --format="value(status.conditions[0].status)")
    if [ "$STATUS" = "True" ]; then
        log_success "Service is ready and serving traffic"
    else
        log_error "Service is not ready. Status: $STATUS"
        exit 1
    fi
    
    # Check logs for blockchain activity
    log_info "Checking service logs for blockchain activity..."
    sleep 10
    
    LOGS=$(gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=$SERVICE_NAME" --limit=5 --format="value(textPayload)" 2>/dev/null || echo "")
    
    if echo "$LOGS" | grep -q "committed state\|finalized block\|received proposal"; then
        log_success "Blockchain is active and producing blocks"
    else
        log_warning "Blockchain activity not detected in recent logs. This may be normal for a new deployment."
    fi
    
    # Verify domain mapping
    log_info "Verifying domain mapping..."
    MAPPED_SERVICE=$(gcloud beta run domain-mappings list --region="$REGION" --filter="metadata.name=$DOMAIN" --format="value(spec.routeName)" 2>/dev/null || echo "")
    
    if [ "$MAPPED_SERVICE" = "$SERVICE_NAME" ]; then
        log_success "Domain mapping verified: $DOMAIN -> $SERVICE_NAME"
    else
        log_error "Domain mapping verification failed"
        exit 1
    fi
    
    # Check DNS resolution
    log_info "Checking DNS resolution..."
    if dig +short "$DOMAIN" | grep -q "ghs.googlehosted.com\|\.run\.app"; then
        log_success "DNS resolution working correctly"
    else
        log_warning "DNS resolution may still be propagating. This can take up to 24 hours."
    fi
}

# Display deployment information
show_deployment_info() {
    log_info "Deployment Summary:"
    echo "----------------------------------------"
    echo "Service Name: $SERVICE_NAME"
    echo "Region: $REGION"
    echo "Domain: $DOMAIN"
    echo "Chain ID: $CHAIN_ID"
    echo "Image: $IMAGE"
    echo "Port: 26656 (P2P)"
    echo "----------------------------------------"
    
    log_info "Service URLs:"
    SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" --region="$REGION" --format="value(status.url)")
    echo "Direct URL: $SERVICE_URL"
    echo "Domain URL: https://$DOMAIN"
    
    log_info "Connection Information for Peer Nodes:"
    echo "PERSISTENT_PEERS=\"838ebde14991541b3bdbe325e4e1009fa3e96cbc@$DOMAIN:443\""
    
    log_info "To check service status:"
    echo "gcloud run services describe $SERVICE_NAME --region=$REGION"
    
    log_info "To view logs:"
    echo "gcloud logging read \"resource.type=cloud_run_revision AND resource.labels.service_name=$SERVICE_NAME\" --limit=20"
    
    log_success "Persistent node deployment completed successfully!"
}

# Main execution
main() {
    echo "============================================================================"
    echo "🌐 Speculo Persistent Node Deployment"
    echo "============================================================================"
    
    check_prerequisites
    cleanup_existing_service
    deploy_persistent_node
    setup_domain_mapping
    validate_deployment
    show_deployment_info
    
    echo ""
    log_success "🎉 Deployment completed successfully!"
    echo "Your persistent node is now available at: https://$DOMAIN"
}

# Handle script termination
trap 'log_error "Script interrupted"; exit 1' INT TERM

# Run main function
main "$@"
