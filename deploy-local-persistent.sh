#!/bin/bash

# Local Persistent Node Deployment Script
# Deploys a complete local blockchain setup with validator, proxy, and websocket bridge

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}🚀 Local Persistent Node Deployment${NC}"
    echo -e "${BLUE}====================================${NC}"
}

print_status() {
    echo -e "${CYAN}$1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

cleanup_old_containers() {
    print_status "🧹 Cleaning up existing containers..."
    
    # Stop and remove containers if they exist
    docker-compose -f docker-compose-local-persistent-proxy.yml down --remove-orphans 2>/dev/null || true
    
    # Remove old images to ensure fresh build
    docker image rm speculod-speculod-validator:latest 2>/dev/null || true
    docker image rm speculod-nginx-proxy:latest 2>/dev/null || true
    docker image rm speculod-websocket-bridge:latest 2>/dev/null || true
    docker image rm speculod-faucet:latest 2>/dev/null || true
    
    print_success "Cleanup completed"
}

build_images() {
    print_status "🏗️  Building Docker images..."
    
    # Build all images in parallel
    docker-compose -f docker-compose-local-persistent-proxy.yml build --parallel
    
    print_success "All images built successfully"
}

start_services() {
    print_status "🚀 Starting services..."
    
    # Start services in dependency order
    docker-compose -f docker-compose-local-persistent-proxy.yml up -d
    
    print_success "All services started"
}

wait_for_services() {
    print_status "⏳ Waiting for services to be ready..."
    
    # Wait for validator
    echo -n "Validator: "
    for i in {1..30}; do
        if curl -s http://localhost:8080/health >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Ready${NC}"
            break
        fi
        echo -n "."
        sleep 2
    done
    
    # Wait for proxy
    echo -n "Proxy:     "
    for i in {1..20}; do
        if curl -s http://localhost:8090/health >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Ready${NC}"
            break
        fi
        echo -n "."
        sleep 2
    done
    
    # Wait for websocket bridge
    echo -n "WebSocket: "
    for i in {1..20}; do
        if curl -s http://localhost:8082/health >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Ready${NC}"
            break
        fi
        echo -n "."
        sleep 2
    done
    
    # Wait for faucet
    echo -n "Faucet:    "
    for i in {1..20}; do
        if curl -s http://localhost:8000/health >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Ready${NC}"
            break
        fi
        echo -n "."
        sleep 2
    done
}

test_endpoints() {
    print_status "🧪 Testing all endpoints..."
    
    echo -n "RPC (direct):     "
    if curl -s http://localhost:26657/status >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Working${NC}"
    else
        echo -e "${RED}❌ Failed${NC}"
    fi
    
    echo -n "RPC (via proxy):  "
    if curl -s http://localhost/rpc/status >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Working${NC}"
    else
        echo -e "${RED}❌ Failed${NC}"
    fi
    
    echo -n "API (direct):     "
    if curl -s http://localhost:1317/cosmos/base/tendermint/v1beta1/node_info >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Working${NC}"
    else
        echo -e "${RED}❌ Failed${NC}"
    fi
    
    echo -n "API (via proxy):  "
    if curl -s http://localhost/api/cosmos/base/tendermint/v1beta1/node_info >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Working${NC}"
    else
        echo -e "${RED}❌ Failed${NC}"
    fi
    
    echo -n "WebSocket Bridge: "
    if curl -s http://localhost:8081 >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Working${NC}"
    else
        echo -e "${RED}❌ Failed${NC}"
    fi
    
    echo -n "Faucet:           "
    if curl -s http://localhost:8000/health >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Working${NC}"
    else
        echo -e "${RED}❌ Failed${NC}"
    fi
}

show_network_info() {
    print_status "📊 Network Information:"
    
    # Get network status
    if curl -s http://localhost:26657/status >/dev/null 2>&1; then
        STATUS=$(curl -s http://localhost:26657/status)
        CHAIN_ID=$(echo "$STATUS" | jq -r '.result.node_info.network' 2>/dev/null || echo "unknown")
        MONIKER=$(echo "$STATUS" | jq -r '.result.node_info.moniker' 2>/dev/null || echo "unknown")
        NODE_ID=$(echo "$STATUS" | jq -r '.result.node_info.id' 2>/dev/null || echo "unknown")
        BLOCK_HEIGHT=$(echo "$STATUS" | jq -r '.result.sync_info.latest_block_height' 2>/dev/null || echo "0")
        
        echo -e "Chain ID:     ${YELLOW}${CHAIN_ID}${NC}"
        echo -e "Moniker:      ${YELLOW}${MONIKER}${NC}"
        echo -e "Node ID:      ${YELLOW}${NODE_ID}${NC}"
        echo -e "Block Height: ${YELLOW}${BLOCK_HEIGHT}${NC}"
        
        if [ "$BLOCK_HEIGHT" -gt "0" ]; then
            print_success "Blockchain is producing blocks!"
        else
            print_warning "Blockchain starting up, blocks should appear soon..."
        fi
    else
        print_error "Could not retrieve network status"
    fi
}

show_endpoints() {
    print_status "🌐 Available Endpoints:"
    echo ""
    echo -e "${CYAN}Direct Access:${NC}"
    echo -e "  RPC:      http://localhost:26657"
    echo -e "  API:      http://localhost:1317"
    echo -e "  gRPC:     localhost:9090"
    echo -e "  P2P:      localhost:26656"
    echo ""
    echo -e "${CYAN}Via Reverse Proxy:${NC}"
    echo -e "  RPC:      http://localhost/rpc"
    echo -e "  API:      http://localhost/api"
    echo -e "  gRPC:     http://localhost/grpc"
    echo ""
    echo -e "${CYAN}Additional Services:${NC}"
    echo -e "  WebSocket: ws://localhost:8081"
    echo -e "  Faucet:    http://localhost:8000"
    echo -e "  Health:    http://localhost:8080/health"
    echo ""
    echo -e "${CYAN}Useful Commands:${NC}"
    echo -e "  Status:    curl http://localhost/rpc/status | jq"
    echo -e "  Logs:      docker-compose -f docker-compose-local-persistent-proxy.yml logs -f"
    echo -e "  Stop:      docker-compose -f docker-compose-local-persistent-proxy.yml down"
}

# Main deployment process
main() {
    print_header
    
    echo -e "${YELLOW}This will deploy a complete local blockchain setup:${NC}"
    echo -e "- Persistent validator node (block producer)"
    echo -e "- Nginx reverse proxy"
    echo -e "- WebSocket-to-P2P bridge"
    echo -e "- Faucet service"
    echo ""
    
    read -p "Continue with deployment? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Deployment cancelled."
        exit 0
    fi
    
    cleanup_old_containers
    build_images
    start_services
    wait_for_services
    test_endpoints
    show_network_info
    show_endpoints
    
    print_success "Local persistent node deployment completed!"
    echo ""
    print_status "Monitor with: docker-compose -f docker-compose-local-persistent-proxy.yml logs -f"
}

# Command line argument handling
case "${1:-}" in
    "start")
        start_services
        ;;
    "stop")
        docker-compose -f docker-compose-local-persistent-proxy.yml down
        ;;
    "restart")
        docker-compose -f docker-compose-local-persistent-proxy.yml restart
        ;;
    "logs")
        docker-compose -f docker-compose-local-persistent-proxy.yml logs -f
        ;;
    "status")
        show_network_info
        ;;
    "test")
        test_endpoints
        ;;
    "clean")
        cleanup_old_containers
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  (no args) - Full deployment"
        echo "  start     - Start services"
        echo "  stop      - Stop services"
        echo "  restart   - Restart services"
        echo "  logs      - Show logs"
        echo "  status    - Show network status"
        echo "  test      - Test endpoints"
        echo "  clean     - Clean up containers"
        echo "  help      - Show this help"
        ;;
    "")
        main
        ;;
    *)
        echo "Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac
