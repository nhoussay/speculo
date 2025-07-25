#!/bin/bash

# WebSocket P2P Bridge Management Script
# Manages local node with WebSocket-to-TCP P2P bridge connection

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="${SCRIPT_DIR}/docker-compose-local-websocket-bridge.yml"
WEBSOCKET_BRIDGE_URL="wss://persistent.specu.io/p2p"
NGINX_PROXY_URL="https://speculo-nginx-proxy-809714550777.europe-west1.run.app"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

check_dependencies() {
    log_info "Checking dependencies..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose is not installed"
        exit 1
    fi
    
    if ! command -v curl &> /dev/null; then
        log_error "curl is not installed"
        exit 1
    fi
    
    log_success "All dependencies are available"
}

check_websocket_bridge_support() {
    log_info "Checking WebSocket P2P bridge support..."
    
    # Check if persistent node supports WebSocket P2P
    if curl -s -f "${NGINX_PROXY_URL}/p2p/info" > /dev/null 2>&1; then
        local p2p_info=$(curl -s "${NGINX_PROXY_URL}/p2p/info" | jq -r '.p2p_enabled // false')
        if [[ "$p2p_info" == "true" ]]; then
            log_success "WebSocket P2P bridge is supported by persistent node"
            return 0
        fi
    fi
    
    log_warning "WebSocket P2P bridge not yet supported by persistent node"
    log_warning "Local node will use RPC sync as fallback"
    return 1
}

start_bridge() {
    log_info "Starting WebSocket P2P bridge setup..."
    
    check_dependencies
    check_websocket_bridge_support
    
    # Create necessary directories
    mkdir -p config data keyring-test
    
    # Start the services
    log_info "Starting services with Docker Compose..."
    docker-compose -f "$COMPOSE_FILE" up -d
    
    # Wait for services to be ready
    log_info "Waiting for services to be ready..."
    sleep 10
    
    # Check service health
    check_services_health
    
    log_success "WebSocket P2P bridge setup completed"
    show_connection_info
}

stop_bridge() {
    log_info "Stopping WebSocket P2P bridge setup..."
    docker-compose -f "$COMPOSE_FILE" down
    log_success "WebSocket P2P bridge setup stopped"
}

restart_bridge() {
    log_info "Restarting WebSocket P2P bridge setup..."
    stop_bridge
    sleep 5
    start_bridge
}

check_services_health() {
    log_info "Checking service health..."
    
    # Check speculod node
    if curl -s -f http://localhost:26657/status > /dev/null 2>&1; then
        local node_status=$(curl -s http://localhost:26657/status | jq -r '.result.sync_info.latest_block_height')
        log_success "Speculod node is running (height: $node_status)"
    else
        log_error "Speculod node is not responding"
        return 1
    fi
    
    # Check WebSocket bridge
    if curl -s -f http://localhost:8081 > /dev/null 2>&1; then
        log_success "WebSocket bridge is running"
    else
        log_warning "WebSocket bridge may not be ready yet"
    fi
    
    # Check nginx proxy
    if curl -s -f http://localhost:8080/health > /dev/null 2>&1; then
        log_success "Nginx proxy is running"
    else
        log_error "Nginx proxy is not responding"
        return 1
    fi
    
    return 0
}

show_connection_info() {
    log_info "Connection Information:"
    echo
    echo "Local Node Services:"
    echo "  RPC:     http://localhost:26657"
    echo "  API:     http://localhost:1317"
    echo "  gRPC:    localhost:9090"
    echo "  P2P:     tcp://localhost:26656 (internal)"
    echo
    echo "WebSocket P2P Bridge:"
    echo "  Bridge:  ws://localhost:8081"
    echo "  Target:  ${WEBSOCKET_BRIDGE_URL}"
    echo
    echo "Local Nginx Proxy:"
    echo "  Proxy:   http://localhost:8080"
    echo "  Health:  http://localhost:8080/health"
    echo "  P2P WS:  ws://localhost:8080/p2p"
    echo
    echo "Persistent Node Connection:"
    echo "  Nginx:   ${NGINX_PROXY_URL}"
    echo "  P2P WS:  ${WEBSOCKET_BRIDGE_URL}"
    echo
}

show_logs() {
    local service=${1:-}
    
    if [[ -n "$service" ]]; then
        log_info "Showing logs for $service..."
        docker-compose -f "$COMPOSE_FILE" logs -f "$service"
    else
        log_info "Showing logs for all services..."
        docker-compose -f "$COMPOSE_FILE" logs -f
    fi
}

show_status() {
    log_info "Service Status:"
    docker-compose -f "$COMPOSE_FILE" ps
    echo
    
    check_services_health
    echo
    
    # Show additional status information
    if curl -s -f http://localhost:26657/status > /dev/null 2>&1; then
        local status_json=$(curl -s http://localhost:26657/status)
        local node_id=$(echo "$status_json" | jq -r '.result.node_info.id')
        local latest_height=$(echo "$status_json" | jq -r '.result.sync_info.latest_block_height')
        local catching_up=$(echo "$status_json" | jq -r '.result.sync_info.catching_up')
        local peers=$(echo "$status_json" | jq -r '.result.sync_info.peers // "0"')
        
        echo "Node Information:"
        echo "  Node ID:       $node_id"
        echo "  Latest Height: $latest_height"
        echo "  Catching Up:   $catching_up"
        echo "  Peers:         $peers"
        echo
    fi
    
    show_connection_info
}

test_p2p_bridge() {
    log_info "Testing WebSocket P2P bridge connection..."
    
    # Test local WebSocket bridge
    if command -v wscat &> /dev/null; then
        log_info "Testing local WebSocket bridge with wscat..."
        timeout 5 wscat -c ws://localhost:8081 -x "test" || log_warning "wscat test may have timed out (normal for P2P protocol)"
    else
        log_warning "wscat not available for WebSocket testing"
    fi
    
    # Test persistent node WebSocket endpoint
    if curl -s -f "${NGINX_PROXY_URL}/p2p/info" > /dev/null 2>&1; then
        log_success "Persistent node WebSocket P2P endpoint is accessible"
    else
        log_warning "Persistent node WebSocket P2P endpoint not yet available"
    fi
}

show_help() {
    echo "WebSocket P2P Bridge Management Script"
    echo
    echo "Usage: $0 [COMMAND]"
    echo
    echo "Commands:"
    echo "  start          Start the WebSocket P2P bridge setup"
    echo "  stop           Stop the WebSocket P2P bridge setup"
    echo "  restart        Restart the WebSocket P2P bridge setup"
    echo "  status         Show status of all services"
    echo "  logs [service] Show logs (optional: specify service name)"
    echo "  test           Test WebSocket P2P bridge connection"
    echo "  help           Show this help message"
    echo
    echo "Services:"
    echo "  speculod         Blockchain node"
    echo "  websocket-bridge WebSocket-to-TCP P2P bridge"
    echo "  nginx            Enhanced nginx proxy with WebSocket support"
    echo
    echo "Examples:"
    echo "  $0 start                    # Start all services"
    echo "  $0 logs speculod           # Show blockchain node logs"
    echo "  $0 logs websocket-bridge   # Show bridge logs"
    echo "  $0 status                  # Show detailed status"
    echo
}

# Main script logic
case "${1:-help}" in
    start)
        start_bridge
        ;;
    stop)
        stop_bridge
        ;;
    restart)
        restart_bridge
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs "$2"
        ;;
    test)
        test_p2p_bridge
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        log_error "Unknown command: $1"
        echo
        show_help
        exit 1
        ;;
esac
