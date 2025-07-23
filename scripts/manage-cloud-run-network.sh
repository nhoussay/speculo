#!/bin/bash

# ============================================================================
# Speculo Cloud Run Network Management Script
# ============================================================================
# This script provides unified management for the Speculo blockchain P2P
# network on Google Cloud Run, including persistent and peer nodes.
#
# Features:
# - Deploy complete P2P network infrastructure
# - Manage individual nodes
# - Monitor network health
# - Clean up deployments
# ============================================================================

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ID="speculo-blockchain"
REGION="europe-west1"

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
    echo "Usage: $0 COMMAND [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  deploy-persistent     Deploy the persistent node with domain mapping"
    echo "  deploy-peers          Deploy peer nodes (use -c for count)"
    echo "  deploy-network        Deploy complete network (persistent + peers)"
    echo "  status                Show status of all nodes"
    echo "  logs                  Show logs for a specific service"
    echo "  cleanup               Remove all blockchain services"
    echo "  help                  Show this help message"
    echo ""
    echo "Options:"
    echo "  -c, --count NUMBER    Number of peer nodes to deploy (default: 2)"
    echo "  -s, --service NAME    Service name for logs command"
    echo "  -f, --force          Force cleanup without confirmation"
    echo ""
    echo "Examples:"
    echo "  $0 deploy-network             # Deploy persistent node + 2 peer nodes"
    echo "  $0 deploy-peers -c 3          # Deploy 3 peer nodes"
    echo "  $0 status                     # Show all node status"
    echo "  $0 logs -s speculo-peer-node-1  # Show logs for specific node"
    echo "  $0 cleanup -f                 # Force cleanup all services"
}

# Deploy persistent node
deploy_persistent() {
    log_info "Deploying persistent node..."
    
    if [ ! -f "$SCRIPT_DIR/deploy-persistent-node.sh" ]; then
        log_error "deploy-persistent-node.sh not found"
        exit 1
    fi
    
    "$SCRIPT_DIR/deploy-persistent-node.sh"
}

# Deploy peer nodes
deploy_peers() {
    local peer_count=${1:-2}
    
    log_info "Deploying $peer_count peer node(s)..."
    
    if [ ! -f "$SCRIPT_DIR/deploy-peer-nodes.sh" ]; then
        log_error "deploy-peer-nodes.sh not found"
        exit 1
    fi
    
    "$SCRIPT_DIR/deploy-peer-nodes.sh" -c "$peer_count"
}

# Deploy complete network
deploy_network() {
    local peer_count=${1:-2}
    
    echo "============================================================================"
    echo "🌐 Deploying Complete Speculo P2P Network"
    echo "============================================================================"
    
    log_info "Deploying persistent node..."
    deploy_persistent
    
    echo ""
    log_info "Waiting 30 seconds for persistent node to stabilize..."
    sleep 30
    
    log_info "Deploying $peer_count peer node(s)..."
    deploy_peers "$peer_count"
    
    log_success "Complete network deployment finished!"
}

# Show status of all nodes
show_status() {
    log_info "Checking status of all Speculo nodes..."
    
    echo ""
    echo "Persistent Nodes:"
    echo "----------------------------------------"
    gcloud run services list \
        --region="$REGION" \
        --filter="metadata.labels.type=persistent-node" \
        --format="table(metadata.name,status.url,status.conditions[0].status,metadata.creationTimestamp)" 2>/dev/null || echo "No persistent nodes found"
    
    echo ""
    echo "Peer Nodes:"
    echo "----------------------------------------"
    gcloud run services list \
        --region="$REGION" \
        --filter="metadata.labels.type=peer-node" \
        --format="table(metadata.name,status.url,status.conditions[0].status,metadata.creationTimestamp)" 2>/dev/null || echo "No peer nodes found"
    
    echo ""
    echo "Domain Mappings:"
    echo "----------------------------------------"
    gcloud beta run domain-mappings list \
        --region="$REGION" \
        --format="table(metadata.name,spec.routeName,status.conditions[0].status)" 2>/dev/null || echo "No domain mappings found"
    
    # Show network health
    echo ""
    log_info "Network Health Check:"
    
    # Check if persistent node is accessible
    if dig +short persistent.specu.io | grep -q .; then
        log_success "✅ persistent.specu.io DNS resolution working"
    else
        log_warning "⚠️  persistent.specu.io DNS resolution issues"
    fi
    
    # Check recent blockchain activity
    RECENT_LOGS=$(gcloud logging read "resource.type=cloud_run_revision AND (resource.labels.service_name:speculo-persistent-node OR resource.labels.service_name:speculo-peer-node) AND textPayload:(\"committed state\" OR \"finalized block\")" --limit=5 --format="value(timestamp,resource.labels.service_name)" 2>/dev/null || echo "")
    
    if [ -n "$RECENT_LOGS" ]; then
        log_success "✅ Recent blockchain activity detected"
        echo "$RECENT_LOGS" | head -3
    else
        log_warning "⚠️  No recent blockchain activity detected"
    fi
}

# Show logs for a specific service
show_logs() {
    local service_name="$1"
    local lines="${2:-50}"
    
    log_info "Showing last $lines log entries for $service_name..."
    
    gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=$service_name" \
        --limit="$lines" \
        --format="table(timestamp,textPayload)" \
        --sort-by="timestamp"
}

# Cleanup all services
cleanup_services() {
    local force="$1"
    
    if [ "$force" != "true" ]; then
        echo ""
        log_warning "This will delete ALL Speculo blockchain services in region $REGION"
        echo "Services to be deleted:"
        gcloud run services list --region="$REGION" --filter="metadata.labels.network=mainnet" --format="value(metadata.name)" 2>/dev/null | sed 's/^/  - /' || echo "  (None found)"
        echo ""
        read -p "Are you sure you want to continue? (y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Cleanup cancelled"
            exit 0
        fi
    fi
    
    log_info "Cleaning up all blockchain services..."
    
    # Delete all blockchain services
    SERVICES=$(gcloud run services list --region="$REGION" --filter="metadata.labels.network=mainnet" --format="value(metadata.name)" 2>/dev/null || echo "")
    
    if [ -n "$SERVICES" ]; then
        echo "$SERVICES" | while read -r service; do
            if [ -n "$service" ]; then
                log_info "Deleting service: $service"
                gcloud run services delete "$service" --region="$REGION" --quiet
            fi
        done
    else
        log_info "No services found to delete"
    fi
    
    # Delete domain mappings
    DOMAINS=$(gcloud beta run domain-mappings list --region="$REGION" --format="value(metadata.name)" 2>/dev/null | grep "\.specu\.io" || echo "")
    
    if [ -n "$DOMAINS" ]; then
        echo "$DOMAINS" | while read -r domain; do
            if [ -n "$domain" ]; then
                log_info "Deleting domain mapping: $domain"
                gcloud beta run domain-mappings delete "$domain" --region="$REGION" --quiet
            fi
        done
    else
        log_info "No domain mappings found to delete"
    fi
    
    log_success "Cleanup completed"
}

# Parse command line arguments
parse_args() {
    local command="$1"
    shift
    
    case "$command" in
        deploy-persistent)
            deploy_persistent
            ;;
        deploy-peers)
            local peer_count=2
            while [[ $# -gt 0 ]]; do
                case $1 in
                    -c|--count)
                        peer_count="$2"
                        shift 2
                        ;;
                    *)
                        log_error "Unknown option for deploy-peers: $1"
                        exit 1
                        ;;
                esac
            done
            deploy_peers "$peer_count"
            ;;
        deploy-network)
            local peer_count=2
            while [[ $# -gt 0 ]]; do
                case $1 in
                    -c|--count)
                        peer_count="$2"
                        shift 2
                        ;;
                    *)
                        log_error "Unknown option for deploy-network: $1"
                        exit 1
                        ;;
                esac
            done
            deploy_network "$peer_count"
            ;;
        status)
            show_status
            ;;
        logs)
            local service_name=""
            local lines=50
            while [[ $# -gt 0 ]]; do
                case $1 in
                    -s|--service)
                        service_name="$2"
                        shift 2
                        ;;
                    -l|--lines)
                        lines="$2"
                        shift 2
                        ;;
                    *)
                        log_error "Unknown option for logs: $1"
                        exit 1
                        ;;
                esac
            done
            if [ -z "$service_name" ]; then
                log_error "Service name required for logs command. Use -s SERVICE_NAME"
                exit 1
            fi
            show_logs "$service_name" "$lines"
            ;;
        cleanup)
            local force=false
            while [[ $# -gt 0 ]]; do
                case $1 in
                    -f|--force)
                        force=true
                        shift
                        ;;
                    *)
                        log_error "Unknown option for cleanup: $1"
                        exit 1
                        ;;
                esac
            done
            cleanup_services "$force"
            ;;
        help|--help|-h)
            usage
            ;;
        *)
            log_error "Unknown command: $command"
            usage
            exit 1
            ;;
    esac
}

# Main execution
main() {
    if [ $# -eq 0 ]; then
        usage
        exit 1
    fi
    
    # Set gcloud project
    gcloud config set project "$PROJECT_ID" 2>/dev/null
    
    parse_args "$@"
}

# Handle script termination
trap 'log_error "Script interrupted"; exit 1' INT TERM

# Run main function
main "$@"
