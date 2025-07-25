#!/bin/bash

# Local Peer Node Connection to Nginx Proxy
# Connects local development node to production nginx proxy on Google Cloud Run

set -e

echo "🚀 Starting Local Peer Node Connection to Nginx Proxy"
echo "=================================================="

# Configuration
NGINX_PROXY_URL="https://speculo-nginx-proxy-809714550777.europe-west1.run.app"
COMPOSE_FILE="docker-compose-local-nginx-peer.yml"

# Function to check nginx proxy status
check_nginx_proxy() {
    echo -e "${CYAN}🔍 Checking nginx proxy status...${NC}"
    
    if curl -s --max-time 10 https://speculo-nginx-proxy-809714550777.europe-west1.run.app/rpc/status > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Nginx proxy is accessible${NC}"
        
        # Get network info
        NETWORK=$(curl -s https://speculo-nginx-proxy-809714550777.europe-west1.run.app/rpc/status | jq -r '.result.node_info.network' 2>/dev/null || echo "unknown")
        echo -e "📡 Network: ${NETWORK}"
        
        # Check if there are any peers (probably 0 due to Cloud Run P2P limitations)
        PEER_COUNT=$(curl -s https://speculo-nginx-proxy-809714550777.europe-west1.run.app/rpc/net_info | jq -r '.result.n_peers' 2>/dev/null || echo "0")
        echo -e "👥 Proxy peer count: ${PEER_COUNT}"
        
        # Get latest block height
        LATEST_HEIGHT=$(curl -s https://speculo-nginx-proxy-809714550777.europe-west1.run.app/rpc/status | jq -r '.result.sync_info.latest_block_height' 2>/dev/null || echo "0")
        echo -e "📈 Latest height: ${LATEST_HEIGHT}"
        
        if [ "$PEER_COUNT" = "0" ]; then
            echo -e "${YELLOW}⚠️  Note: Nginx proxy has no P2P peers (Cloud Run limitation)${NC}"
            echo -e "${YELLOW}   Local node will sync via RPC/API instead of P2P${NC}"
        fi
        
        return 0
    else
        echo -e "${RED}❌ Nginx proxy is not accessible${NC}"
        return 1
    fi
}

# Function to start local peer
start_peer() {
    echo ""
    echo "🏗️ Starting local peer node..."
    
    # Clean up any existing containers
    docker-compose -f "$COMPOSE_FILE" down --remove-orphans 2>/dev/null || true
    
    # Start the local peer
    docker-compose -f "$COMPOSE_FILE" up -d
    
    echo "✅ Local peer node started"
    echo ""
    echo "📊 Container status:"
    docker-compose -f "$COMPOSE_FILE" ps
}

# Function to show logs
show_logs() {
    echo ""
    echo "📜 Showing recent logs..."
    docker-compose -f "$COMPOSE_FILE" logs --tail=50 -f
}

# Function to check local peer status
check_local_status() {
    echo ""
    echo "🔍 Checking local peer status..."
    
    # Wait a moment for the node to start
    sleep 5
    
    if curl -s "http://localhost:26659/status" > /dev/null; then
        echo "✅ Local peer is running"
        
        # Get local node info
        LOCAL_NETWORK=$(curl -s "http://localhost:26659/status" | jq -r '.result.node_info.network // "unknown"')
        echo "📡 Local network: $LOCAL_NETWORK"
        
        # Get local peer count
        LOCAL_PEERS=$(curl -s "http://localhost:26659/net_info" | jq -r '.result.n_peers // "0"')
        echo "👥 Local peer connections: $LOCAL_PEERS"
        
        # Check if we're connected to the nginx proxy
        if [ "$LOCAL_PEERS" -gt "0" ]; then
            echo "🔗 Checking peer connections..."
            curl -s "http://localhost:26659/net_info" | jq -r '.result.peers[] | "  - \(.node_info.moniker) (\(.remote_ip))"'
        fi
    else
        echo "❌ Local peer is not responding yet"
    fi
}

# Function to stop peer
stop_peer() {
    echo ""
    echo "⏹️ Stopping local peer node..."
    docker-compose -f "$COMPOSE_FILE" down
    echo "✅ Local peer stopped"
}

# Function to show API endpoints
show_endpoints() {
    echo ""
    echo "🌐 Local Peer API Endpoints:"
    echo "=============================="
    echo "RPC:      http://localhost:26659"
    echo "REST API: http://localhost:1318"
    echo "gRPC:     http://localhost:9091"
    echo ""
    echo "🌐 Nginx Proxy Endpoints:"
    echo "=========================="
    echo "RPC:      ${NGINX_PROXY_URL}/rpc"
    echo "REST API: ${NGINX_PROXY_URL}/api"
    echo "gRPC:     ${NGINX_PROXY_URL}/grpc"
    echo ""
    echo "🧪 Test Commands:"
    echo "================="
    echo "# Local peer status"
    echo "curl http://localhost:26659/status | jq '.result.node_info'"
    echo ""
    echo "# Local peer connections (will likely be 0 due to no P2P)"
    echo "curl http://localhost:26659/net_info | jq '.result.n_peers'"
    echo ""
    echo "# Compare local vs nginx proxy heights"
    echo "echo 'Local:' && curl -s http://localhost:26659/status | jq '.result.sync_info.latest_block_height'"
    echo "echo 'Proxy:' && curl -s ${NGINX_PROXY_URL}/rpc/status | jq '.result.sync_info.latest_block_height'"
    echo ""
    echo "📝 Note: Due to Cloud Run limitations, P2P connections may not work."
    echo "   The local node will sync using RPC/API endpoints instead."
}

# Main menu
case "${1:-}" in
    "start")
        check_nginx_proxy
        start_peer
        sleep 10
        check_local_status
        show_endpoints
        ;;
    "stop")
        stop_peer
        ;;
    "status")
        check_nginx_proxy
        check_local_status
        ;;
    "logs")
        show_logs
        ;;
    "endpoints")
        show_endpoints
        ;;
    "restart")
        stop_peer
        sleep 2
        check_nginx_proxy
        start_peer
        sleep 10
        check_local_status
        ;;
    *)
        echo "Usage: $0 {start|stop|status|logs|endpoints|restart}"
        echo ""
        echo "Commands:"
        echo "  start     - Start local peer and connect to nginx proxy"
        echo "  stop      - Stop local peer"
        echo "  status    - Check status of both local peer and nginx proxy"
        echo "  logs      - Show local peer logs"
        echo "  endpoints - Show all available API endpoints"
        echo "  restart   - Restart local peer connection"
        echo ""
        echo "🎯 Quick start: $0 start"
        exit 1
        ;;
esac
