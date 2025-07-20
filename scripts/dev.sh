#!/bin/bash

# Local Development Helper Script
set -e

echo "=================================================="
echo "🏠 SPECULOD LOCAL DEVELOPMENT"
echo "=================================================="

# Function to display usage
show_usage() {
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  dev       Start blockchain for development (fastest)"
    echo "  full      Start full stack (blockchain + api + faucet)"  
    echo "  simple    Start single container with all services"
    echo "  native    Build and run natively (requires Go)"
    echo "  stop      Stop all running services"
    echo "  logs      Show logs for all services"
    echo "  test      Run connectivity tests"
    echo "  clean     Clean Docker system"
    echo ""
    echo "Examples:"
    echo "  ./scripts/dev.sh dev     # Start blockchain only"
    echo "  ./scripts/dev.sh full    # Start all services"
    echo "  ./scripts/dev.sh test    # Test all endpoints"
    echo ""
}

# Function to test connectivity
test_services() {
    echo "🧪 Testing service connectivity..."
    
    echo -n "Testing blockchain RPC... "
    if curl -s --max-time 5 http://localhost:8080/status >/dev/null 2>&1; then
        echo "✅ OK"
    else
        echo "❌ Failed"
    fi
    
    echo -n "Testing REST API... "
    if curl -s --max-time 5 http://localhost:1317/cosmos/base/tendermint/v1beta1/node_info >/dev/null 2>&1; then
        echo "✅ OK"
    else
        echo "❌ Failed"
    fi
    
    echo -n "Testing faucet... "
    if curl -s --max-time 5 http://localhost:4500/health >/dev/null 2>&1; then
        echo "✅ OK"
    else
        echo "❌ Not running or failed"
    fi
    
    echo ""
    echo "📊 Service URLs:"
    echo "   Blockchain RPC: http://localhost:8080"
    echo "   REST API:       http://localhost:1317"
    echo "   Token Faucet:   http://localhost:4500"
    echo "   Health Check:   http://localhost:8080/status"
}

# Function to show logs
show_logs() {
    echo "📋 Showing logs for all services..."
    echo "Press Ctrl+C to exit"
    sleep 2
    docker compose -f docker-compose-multi.yml logs -f
}

# Function to clean Docker system
clean_docker() {
    echo "🧹 Cleaning Docker system..."
    docker compose -f docker-compose-multi.yml down --volumes --remove-orphans 2>/dev/null || true
    docker system prune -f
    docker builder prune -f
    echo "✅ Docker system cleaned"
}

# Function to stop services
stop_services() {
    echo "🛑 Stopping all services..."
    docker compose -f docker-compose-multi.yml down
    docker compose -f docker-compose-simple.yml down 2>/dev/null || true
    echo "✅ All services stopped"
}

# Main logic
case "${1:-help}" in
    "dev")
        echo "🚀 Starting blockchain for development..."
        echo "   This is the fastest option for core blockchain development"
        echo ""
        docker compose -f docker-compose-multi.yml up blockchain --no-deps
        ;;
    
    "full") 
        echo "🚀 Starting full service stack..."
        echo "   Blockchain + REST API + Token Faucet"
        echo ""
        docker compose -f docker-compose-multi.yml up
        ;;
    
    "simple")
        echo "🚀 Starting simple single-container deployment..."
        echo ""
        docker compose -f docker-compose-simple.yml up
        ;;
    
    "native")
        echo "🔨 Building and running natively..."
        if ! command -v go &> /dev/null; then
            echo "❌ Go is not installed. Please install Go 1.21+ first."
            exit 1
        fi
        
        echo "Building binary..."
        make install
        
        echo "Initializing blockchain..."
        ./build/speculodd init speculod --chain-id speculod --home ~/.speculod
        
        echo "Creating genesis account..."
        ./build/speculodd keys add alice --keyring-backend test --home ~/.speculod
        ./build/speculodd genesis add-genesis-account alice 100000000000stake --keyring-backend test --home ~/.speculod
        ./build/speculodd genesis gentx alice 1000000stake --keyring-backend test --chain-id speculod --home ~/.speculod
        ./build/speculodd genesis collect-gentxs --home ~/.speculod
        
        echo "🚀 Starting blockchain node..."
        ./build/speculodd start --home ~/.speculod --minimum-gas-prices "0.0001stake"
        ;;
    
    "stop")
        stop_services
        ;;
    
    "logs")
        show_logs
        ;;
    
    "test")
        test_services
        ;;
    
    "clean")
        clean_docker
        ;;
    
    "help"|*)
        show_usage
        ;;
esac
