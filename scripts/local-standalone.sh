#!/bin/bash

# Local Standalone Peer Management Script
# This script manages a standalone local blockchain node for development

set -e

COMPOSE_FILE="docker-compose-local-standalone.yml"
SERVICE_NAME="local-peer-standalone"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}🚀 Speculod Local Standalone Node Manager${NC}"
    echo -e "${BLUE}===============================================${NC}"
}

start_node() {
    print_header
    echo -e "${CYAN}🏗️ Starting local standalone blockchain node...${NC}"
    
    docker-compose -f "$COMPOSE_FILE" up -d --build
    
    echo -e "${GREEN}✅ Local standalone node started${NC}"
    echo ""
    show_status
}

stop_node() {
    print_header
    echo -e "${YELLOW}⏹️ Stopping local standalone node...${NC}"
    
    docker-compose -f "$COMPOSE_FILE" down
    
    echo -e "${GREEN}✅ Local standalone node stopped${NC}"
}

show_status() {
    echo -e "${PURPLE}📊 Container status:${NC}"
    docker-compose -f "$COMPOSE_FILE" ps
    echo ""
    
    # Check if local node is responding
    echo -e "${CYAN}🔍 Checking local node status...${NC}"
    if curl -s http://localhost:26659/status > /dev/null 2>&1; then
        NODE_ID=$(curl -s http://localhost:26659/status | jq -r '.result.node_info.id' 2>/dev/null || echo "unknown")
        CHAIN_ID=$(curl -s http://localhost:26659/status | jq -r '.result.node_info.network' 2>/dev/null || echo "unknown")
        LATEST_HEIGHT=$(curl -s http://localhost:26659/status | jq -r '.result.sync_info.latest_block_height' 2>/dev/null || echo "0")
        CATCHING_UP=$(curl -s http://localhost:26659/status | jq -r '.result.sync_info.catching_up' 2>/dev/null || echo "true")
        
        echo -e "${GREEN}✅ Local node is responding${NC}"
        echo -e "🆔 Node ID: ${NODE_ID}"
        echo -e "🌐 Chain ID: ${CHAIN_ID}"
        echo -e "📈 Latest Height: ${LATEST_HEIGHT}"
        echo -e "🔄 Catching Up: ${CATCHING_UP}"
    else
        echo -e "${RED}❌ Local node is not responding yet${NC}"
    fi
    
    echo ""
    show_endpoints
}

show_logs() {
    print_header
    echo -e "${CYAN}📜 Showing recent logs...${NC}"
    docker-compose -f "$COMPOSE_FILE" logs --tail=50 -f
}

show_endpoints() {
    echo -e "${CYAN}🌐 Local Node API Endpoints:${NC}"
    echo -e "${CYAN}==============================${NC}"
    echo -e "RPC:      http://localhost:26659"
    echo -e "REST API: http://localhost:1318"
    echo -e "gRPC:     http://localhost:9091"
    echo ""
    
    echo -e "${CYAN}🧪 Test Commands:${NC}"
    echo -e "${CYAN}=================${NC}"
    echo -e "# Node status"
    echo -e "curl http://localhost:26659/status | jq '.result.node_info'"
    echo ""
    echo -e "# Block height"
    echo -e "curl http://localhost:26659/status | jq '.result.sync_info.latest_block_height'"
    echo ""
    echo -e "# Account balances"
    echo -e "curl http://localhost:1318/cosmos/bank/v1beta1/balances/{address}"
    echo ""
}

restart_node() {
    stop_node
    sleep 2
    start_node
}

cleanup() {
    print_header
    echo -e "${YELLOW}🧹 Cleaning up local standalone node...${NC}"
    
    docker-compose -f "$COMPOSE_FILE" down -v
    docker system prune -f
    
    echo -e "${GREEN}✅ Cleanup completed${NC}"
}

# Main script logic
case "${1:-}" in
    "start")
        start_node
        ;;
    "stop")
        stop_node
        ;;
    "status")
        print_header
        show_status
        ;;
    "logs")
        show_logs
        ;;
    "restart")
        restart_node
        ;;
    "endpoints")
        print_header
        show_endpoints
        ;;
    "cleanup")
        cleanup
        ;;
    *)
        print_header
        echo -e "${YELLOW}Usage: $0 {start|stop|status|logs|restart|endpoints|cleanup}${NC}"
        echo ""
        echo -e "${CYAN}Commands:${NC}"
        echo -e "  start     - Start the local standalone node"
        echo -e "  stop      - Stop the local standalone node"
        echo -e "  status    - Show node status and health"
        echo -e "  logs      - Show recent logs (follow mode)"
        echo -e "  restart   - Restart the node"
        echo -e "  endpoints - Show API endpoints and test commands"
        echo -e "  cleanup   - Stop and remove all containers and volumes"
        exit 1
        ;;
esac
