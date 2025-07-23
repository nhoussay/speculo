#!/bin/bash

# ============================================================================
# Speculo Peer Node Deployment Script
# ============================================================================
# This script deploys peer nodes to Google Cloud Run that connect to the
# persistent node for P2P networking in the Speculo blockchain network.
#
# Features:
# - Deploys peer nodes with P2P port configuration
# - Automatically configures connection to persistent node
# - Supports multiple peer node instances
# - Validates deployment and P2P connectivity
# ============================================================================

set -euo pipefail

# Configuration
PROJECT_ID="speculo-blockchain"
BASE_SERVICE_NAME="speculo-peer-node"
REGION="europe-west1"
IMAGE="gcr.io/speculo-blockchain/speculod-persistent-node:latest"
CHAIN_ID="speculod-mainnet-1"
PERSISTENT_NODE_DOMAIN="persistent.specu.io"

# Default values
PEER_COUNT=1
INSTANCE_SUFFIX=""

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

# Usage function
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -c, --count NUMBER     Number of peer nodes to deploy (default: 1)"
    echo "  -s, --suffix TEXT      Suffix for service names (default: auto-numbered)"
    echo "  -h, --help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                     # Deploy 1 peer node"
    echo "  $0 -c 3               # Deploy 3 peer nodes"
    echo "  $0 -s europe          # Deploy peer node with suffix 'europe'"
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--count)
                PEER_COUNT="$2"
                shift 2
                ;;
            -s|--suffix)
                INSTANCE_SUFFIX="-$2"
                shift 2
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    # Validate peer count
    if ! [[ "$PEER_COUNT" =~ ^[0-9]+$ ]] || [ "$PEER_COUNT" -lt 1 ] || [ "$PEER_COUNT" -gt 10 ]; then
        log_error "Peer count must be between 1 and 10"
        exit 1
    fi
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
    
    # Check if persistent node exists
    if ! gcloud beta run domain-mappings list --region="$REGION" --format="value(metadata.name)" | grep -q "$PERSISTENT_NODE_DOMAIN"; then
        log_error "Persistent node domain mapping not found. Please deploy the persistent node first using deploy-persistent-node.sh"
        exit 1
    fi
    
    log_success "Prerequisites checked"
}

# Deploy a single peer node
deploy_peer_node() {
    local node_number=$1
    local service_name
    
    if [ -n "$INSTANCE_SUFFIX" ]; then
        service_name="${BASE_SERVICE_NAME}${INSTANCE_SUFFIX}"
    else
        service_name="${BASE_SERVICE_NAME}-${node_number}"
    fi
    
    log_info "Deploying peer node: $service_name"
    
    # Check if service already exists
    if gcloud run services describe "$service_name" --region="$REGION" &>/dev/null; then
        log_warning "Service $service_name already exists. Updating..."
    fi
    
    gcloud run deploy "$service_name" \
        --image="$IMAGE" \
        --port=26656 \
        --region="$REGION" \
        --allow-unauthenticated \
        --memory=2Gi \
        --cpu=1 \
        --max-instances=5 \
        --min-instances=0 \
        --concurrency=1000 \
        --timeout=3600 \
        --set-env-vars="CHAIN_ID=$CHAIN_ID,NODE_TYPE=peer,SERVICE_TYPE=p2p,GITHUB_NETWORK_CONFIG=true,NETWORK_CONFIG_REPO=nhoussay/speculo,NETWORK_CONFIG_BRANCH=main,PERSISTENT_PEERS=838ebde14991541b3bdbe325e4e1009fa3e96cbc@$PERSISTENT_NODE_DOMAIN:443" \
        --labels="type=peer-node,network=mainnet,service=p2p,node-number=$node_number"
    
    if [ $? -eq 0 ]; then
        log_success "Peer node $service_name deployed successfully"
        return 0
    else
        log_error "Failed to deploy peer node $service_name"
        return 1
    fi
}

# Deploy multiple peer nodes
deploy_all_peer_nodes() {
    log_info "Deploying $PEER_COUNT peer node(s)..."
    
    local failed_deployments=0
    local deployed_services=()
    
    for ((i=1; i<=PEER_COUNT; i++)); do
        if deploy_peer_node "$i"; then
            if [ -n "$INSTANCE_SUFFIX" ]; then
                deployed_services+=("${BASE_SERVICE_NAME}${INSTANCE_SUFFIX}")
            else
                deployed_services+=("${BASE_SERVICE_NAME}-${i}")
            fi
        else
            ((failed_deployments++))
        fi
        
        # Small delay between deployments to avoid rate limits
        if [ $i -lt $PEER_COUNT ]; then
            sleep 2
        fi
    done
    
    if [ $failed_deployments -eq 0 ]; then
        log_success "All $PEER_COUNT peer node(s) deployed successfully"
        echo "${deployed_services[@]}"
    else
        log_error "$failed_deployments deployment(s) failed"
        exit 1
    fi
}

# Validate deployments
validate_deployments() {
    local services=("$@")
    
    log_info "Validating peer node deployments..."
    
    for service in "${services[@]}"; do
        log_info "Checking $service..."
        
        # Check service status
        STATUS=$(gcloud run services describe "$service" --region="$REGION" --format="value(status.conditions[0].status)" 2>/dev/null || echo "False")
        if [ "$STATUS" = "True" ]; then
            log_success "$service is ready and serving traffic"
        else
            log_error "$service is not ready. Status: $STATUS"
            continue
        fi
        
        # Check logs for P2P connectivity
        sleep 5
        LOGS=$(gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=$service" --limit=10 --format="value(textPayload)" 2>/dev/null || echo "")
        
        if echo "$LOGS" | grep -q "committed state\|finalized block\|dialing peer\|connected to peer"; then
            log_success "$service is active and connecting to the network"
        else
            log_warning "$service may still be starting up. Check logs manually if issues persist."
        fi
    done
}

# Display deployment information
show_deployment_info() {
    local services=("$@")
    
    log_info "Deployment Summary:"
    echo "----------------------------------------"
    echo "Deployed Services: ${#services[@]}"
    echo "Region: $REGION"
    echo "Chain ID: $CHAIN_ID"
    echo "Image: $IMAGE"
    echo "Port: 26656 (P2P)"
    echo "Persistent Node: $PERSISTENT_NODE_DOMAIN"
    echo "----------------------------------------"
    
    log_info "Deployed Peer Nodes:"
    for service in "${services[@]}"; do
        SERVICE_URL=$(gcloud run services describe "$service" --region="$REGION" --format="value(status.url)" 2>/dev/null || echo "Unknown")
        echo "  - $service: $SERVICE_URL"
    done
    
    log_info "Management Commands:"
    echo "List all services:"
    echo "  gcloud run services list --region=$REGION --filter='metadata.labels.type=peer-node'"
    
    echo ""
    echo "View logs for a specific service:"
    echo "  gcloud logging read \"resource.type=cloud_run_revision AND resource.labels.service_name=SERVICE_NAME\" --limit=20"
    
    echo ""
    echo "Delete a peer node:"
    echo "  gcloud run services delete SERVICE_NAME --region=$REGION"
    
    log_success "Peer node deployment completed successfully!"
}

# Main execution
main() {
    echo "============================================================================"
    echo "🔗 Speculo Peer Node Deployment"
    echo "============================================================================"
    
    parse_args "$@"
    check_prerequisites
    
    deployed_services=($(deploy_all_peer_nodes))
    validate_deployments "${deployed_services[@]}"
    show_deployment_info "${deployed_services[@]}"
    
    echo ""
    log_success "🎉 Peer node deployment completed successfully!"
    echo "Your peer node(s) are now connecting to the network at: $PERSISTENT_NODE_DOMAIN"
}

# Handle script termination
trap 'log_error "Script interrupted"; exit 1' INT TERM

# Run main function
main "$@"
