#!/bin/bash

# Domain Mapping Helper Script for persistent.specu.io
# This script helps set up and monitor domain mapping to Cloud Run

set -e

DOMAIN="persistent.specu.io"
SERVICE="speculo-nginx-proxy"
REGION="europe-west1"
PROJECT="speculo-blockchain"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}🌐 Domain Mapping Manager for ${DOMAIN}${NC}"
    echo -e "${BLUE}================================================${NC}"
}

check_domain_status() {
    print_header
    echo -e "${CYAN}🔍 Checking current domain status...${NC}"
    
    # Test if domain resolves
    if curl -s --max-time 10 https://$DOMAIN/rpc/status > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Domain is accessible and working!${NC}"
        
        # Get node info
        MONIKER=$(curl -s https://$DOMAIN/rpc/status | jq -r '.result.node_info.moniker' 2>/dev/null || echo "unknown")
        NODE_ID=$(curl -s https://$DOMAIN/rpc/status | jq -r '.result.node_info.id' 2>/dev/null || echo "unknown")
        CHAIN_ID=$(curl -s https://$DOMAIN/rpc/status | jq -r '.result.node_info.network' 2>/dev/null || echo "unknown")
        
        echo -e "🏷️  Moniker: ${MONIKER}"
        echo -e "🆔 Node ID: ${NODE_ID}"
        echo -e "🌐 Chain ID: ${CHAIN_ID}"
        
        # Test all endpoints
        echo -e "\n${CYAN}📡 Testing all endpoints:${NC}"
        
        echo -n "RPC:      "
        if curl -s --max-time 5 https://$DOMAIN/rpc/status > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Working${NC}"
        else
            echo -e "${RED}❌ Failed${NC}"
        fi
        
        echo -n "API:      "
        if curl -s --max-time 5 https://$DOMAIN/api/cosmos/base/tendermint/v1beta1/node_info > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Working${NC}"
        else
            echo -e "${RED}❌ Failed${NC}"
        fi
        
        echo -n "gRPC:     "
        if curl -s --max-time 5 https://$DOMAIN/grpc > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Working${NC}"
        else
            echo -e "${RED}❌ Failed${NC}"
        fi
        
        # Test WebSocket P2P endpoint (if wscat is available)
        echo -n "WebSocket P2P: "
        if command -v wscat &> /dev/null; then
            if timeout 5 wscat -c "wss://$DOMAIN/" -x 'quit' &> /dev/null; then
                echo -e "${GREEN}✅ Working${NC}"
            else
                echo -e "${RED}❌ Failed${NC}"
            fi
        else
            echo -e "${YELLOW}⚠️  wscat not available (install with: npm install -g wscat)${NC}"
        fi
        
    else
        echo -e "${RED}❌ Domain is not accessible yet${NC}"
        
        # Check DNS resolution
        echo -e "\n${CYAN}🔍 DNS Resolution Check:${NC}"
        if dig +short $DOMAIN A | grep -q "."; then
            echo -e "${YELLOW}⚠️  Domain resolves to IP but service not responding${NC}"
        else
            echo -e "${RED}❌ Domain does not resolve to any IP${NC}"
        fi
    fi
}

check_gcloud_mapping() {
    print_header
    echo -e "${CYAN}☁️  Checking Google Cloud domain mapping status...${NC}"
    
    if gcloud run domain-mappings describe $DOMAIN --region=$REGION --project=$PROJECT --format="value(metadata.name)" 2>/dev/null; then
        echo -e "${GREEN}✅ Domain mapping exists in Google Cloud${NC}"
        
        echo -e "\n${CYAN}📋 Mapping Details:${NC}"
        gcloud run domain-mappings describe $DOMAIN \
            --region=$REGION \
            --project=$PROJECT \
            --format="table(
                spec.routeName:label='SERVICE',
                status.conditions[0].type:label='STATUS_TYPE',
                status.conditions[0].status:label='READY',
                status.url:label='URL'
            )"
        
        echo -e "\n${CYAN}📝 Required DNS Records:${NC}"
        gcloud run domain-mappings describe $DOMAIN \
            --region=$REGION \
            --project=$PROJECT \
            --format="value(status.resourceRecords[].name,status.resourceRecords[].rrdata)" | \
            while IFS=$'\t' read -r name rrdata; do
                echo -e "${YELLOW}${name} → ${rrdata}${NC}"
            done
    else
        echo -e "${RED}❌ No domain mapping found in Google Cloud${NC}"
        echo -e "${YELLOW}💡 Use 'create-mapping' command to set it up${NC}"
    fi
}

create_mapping() {
    print_header
    echo -e "${CYAN}🏗️  Creating domain mapping...${NC}"
    
    echo -e "${YELLOW}⚠️  This requires appropriate Google Cloud permissions${NC}"
    
    gcloud beta run domain-mappings create \
        --service=$SERVICE \
        --domain=$DOMAIN \
        --region=$REGION \
        --project=$PROJECT
    
    echo -e "${GREEN}✅ Domain mapping created!${NC}"
    echo -e "${YELLOW}📋 Next steps:${NC}"
    echo -e "1. Get DNS records with: $0 dns-records"
    echo -e "2. Add those records to your DNS provider"
    echo -e "3. Wait for DNS propagation (5 minutes - 48 hours)"
    echo -e "4. Check status with: $0 status"
}

get_dns_records() {
    print_header
    echo -e "${CYAN}📝 DNS Records to configure:${NC}"
    
    gcloud run domain-mappings describe $DOMAIN \
        --region=$REGION \
        --project=$PROJECT \
        --format="value(status.resourceRecords[].name,status.resourceRecords[].type,status.resourceRecords[].rrdata)" | \
        while IFS=$'\t' read -r name type rrdata; do
            echo -e "${YELLOW}${type} Record:${NC} ${name} → ${rrdata}"
        done
}

test_endpoints() {
    print_header
    echo -e "${CYAN}🧪 Testing all service endpoints...${NC}"
    
    # Test both Cloud Run URL and domain (if mapped)
    ENDPOINTS=(
        "https://speculo-nginx-proxy-809714550777.europe-west1.run.app"
        "https://$DOMAIN"
    )
    
    for base_url in "${ENDPOINTS[@]}"; do
        echo -e "\n${PURPLE}Testing: ${base_url}${NC}"
        
        # RPC endpoint
        echo -n "  RPC:  "
        if curl -s --max-time 5 "${base_url}/rpc/status" > /dev/null 2>&1; then
            echo -e "${GREEN}✅${NC}"
        else
            echo -e "${RED}❌${NC}"
        fi
        
        # API endpoint
        echo -n "  API:  "
        if curl -s --max-time 5 "${base_url}/api/cosmos/base/tendermint/v1beta1/node_info" > /dev/null 2>&1; then
            echo -e "${GREEN}✅${NC}"
        else
            echo -e "${RED}❌${NC}"
        fi
        
        # gRPC endpoint
        echo -n "  gRPC: "
        if curl -s --max-time 5 "${base_url}/grpc" > /dev/null 2>&1; then
            echo -e "${GREEN}✅${NC}"
        else
            echo -e "${RED}❌${NC}"
        fi
    done
}

show_help() {
    print_header
    echo -e "${CYAN}Usage: $0 {status|gcloud-status|create-mapping|dns-records|test|help}${NC}"
    echo ""
    echo -e "${CYAN}Commands:${NC}"
    echo -e "  status         - Check if domain is accessible and working"
    echo -e "  gcloud-status  - Check Google Cloud domain mapping status"
    echo -e "  create-mapping - Create new domain mapping (requires GCloud auth)"
    echo -e "  dns-records    - Show DNS records that need to be configured"
    echo -e "  test           - Test all endpoints (both Cloud Run URL and domain)"
    echo -e "  help           - Show this help message"
    echo ""
    echo -e "${YELLOW}Domain Setup Process:${NC}"
    echo -e "1. Run: $0 create-mapping"
    echo -e "2. Run: $0 dns-records"
    echo -e "3. Add DNS records to your domain provider"
    echo -e "4. Wait for propagation"
    echo -e "5. Run: $0 status"
}

# Main script logic
case "${1:-}" in
    "status")
        check_domain_status
        ;;
    "gcloud-status")
        check_gcloud_mapping
        ;;
    "create-mapping")
        create_mapping
        ;;
    "dns-records")
        get_dns_records
        ;;
    "test")
        test_endpoints
        ;;
    "help"|"")
        show_help
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        show_help
        exit 1
        ;;
esac
