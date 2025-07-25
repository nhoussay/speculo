#!/bin/bash

# Comprehensive Blockchain Network Status Checker
# Monitors validator service, nginx proxy, and overall network health

set -e

PROJECT_ID="speculo-blockchain"
REGION="europe-west1"
DOMAIN="persistent.specu.io"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}🌐 Speculod Blockchain Network Status${NC}"
    echo -e "${BLUE}====================================${NC}"
    echo "$(date)"
    echo ""
}

check_cloud_run_services() {
    echo -e "${CYAN}☁️  Cloud Run Services Status:${NC}"
    
    # Check nginx proxy
    echo -n "  speculo-nginx-proxy: "
    if gcloud run services describe speculo-nginx-proxy --region=$REGION --project=$PROJECT_ID --format="value(status.url)" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Running${NC}"
        NGINX_URL=$(gcloud run services describe speculo-nginx-proxy --region=$REGION --project=$PROJECT_ID --format="value(status.url)")
        echo "    URL: $NGINX_URL"
    else
        echo -e "${RED}❌ Not Found${NC}"
        NGINX_URL=""
    fi
    
    # Check validator
    echo -n "  speculod-validator: "
    if gcloud run services describe speculod-validator --region=$REGION --project=$PROJECT_ID --format="value(status.url)" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Running${NC}"
        VALIDATOR_URL=$(gcloud run services describe speculod-validator --region=$REGION --project=$PROJECT_ID --format="value(status.url)")
        echo "    URL: $VALIDATOR_URL"
    else
        echo -e "${RED}❌ Not Found${NC}"
        VALIDATOR_URL=""
    fi
    echo ""
}

check_validator_health() {
    if [ -n "$VALIDATOR_URL" ]; then
        echo -e "${CYAN}🔗 Validator Service Health:${NC}"
        
        echo -n "  Health Check: "
        if curl -s --max-time 10 "$VALIDATOR_URL/health" >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Healthy${NC}"
        else
            echo -e "${RED}❌ Failed${NC}"
        fi
        
        echo -n "  Ready Check: "
        if curl -s --max-time 10 "$VALIDATOR_URL/ready" >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Ready${NC}"
        else
            echo -e "${YELLOW}⚠️  Not Ready${NC}"
        fi
        
        # Try to get blockchain status from validator
        echo -n "  RPC Status: "
        if curl -s --max-time 10 "$VALIDATOR_URL/status" >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Accessible${NC}"
            
            # Get block height
            BLOCK_HEIGHT=$(curl -s --max-time 5 "$VALIDATOR_URL/status" | jq -r '.result.sync_info.latest_block_height // "0"' 2>/dev/null || echo "0")
            echo "    Block Height: $BLOCK_HEIGHT"
            
            if [ "$BLOCK_HEIGHT" != "0" ] && [ "$BLOCK_HEIGHT" != "null" ]; then
                echo -e "    ${GREEN}🎉 PRODUCING BLOCKS!${NC}"
            else
                echo -e "    ${YELLOW}⚠️  No blocks produced yet${NC}"
            fi
        else
            echo -e "${RED}❌ Failed${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Validator service not deployed${NC}"
    fi
    echo ""
}

check_domain_status() {
    echo -e "${CYAN}🌐 Domain Status ($DOMAIN):${NC}"
    
    echo -n "  Accessibility: "
    if curl -s --max-time 10 "https://$DOMAIN/rpc/status" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Accessible${NC}"
        
        # Get blockchain info
        MONIKER=$(curl -s "https://$DOMAIN/rpc/status" | jq -r '.result.node_info.moniker' 2>/dev/null || echo "unknown")
        CHAIN_ID=$(curl -s "https://$DOMAIN/rpc/status" | jq -r '.result.node_info.network' 2>/dev/null || echo "unknown")
        BLOCK_HEIGHT=$(curl -s "https://$DOMAIN/rpc/status" | jq -r '.result.sync_info.latest_block_height' 2>/dev/null || echo "0")
        
        echo "    Moniker: $MONIKER"
        echo "    Chain ID: $CHAIN_ID"
        echo "    Block Height: $BLOCK_HEIGHT"
        
        if [ "$BLOCK_HEIGHT" != "0" ] && [ "$BLOCK_HEIGHT" != "null" ]; then
            echo -e "    ${GREEN}🎉 BLOCKCHAIN IS PRODUCING BLOCKS!${NC}"
        else
            echo -e "    ${YELLOW}⚠️  No blocks being produced${NC}"
        fi
        
        # Test all endpoints
        echo "  Endpoint Tests:"
        echo -n "    RPC: "
        if curl -s --max-time 5 "https://$DOMAIN/rpc/status" >/dev/null 2>&1; then
            echo -e "${GREEN}✅${NC}"
        else
            echo -e "${RED}❌${NC}"
        fi
        
        echo -n "    API: "
        if curl -s --max-time 5 "https://$DOMAIN/api/cosmos/base/tendermint/v1beta1/node_info" >/dev/null 2>&1; then
            echo -e "${GREEN}✅${NC}"
        else
            echo -e "${RED}❌${NC}"
        fi
        
    else
        echo -e "${RED}❌ Not Accessible${NC}"
    fi
    echo ""
}

show_recommendations() {
    echo -e "${CYAN}💡 Recommendations:${NC}"
    
    if [ -z "$VALIDATOR_URL" ]; then
        echo -e "${YELLOW}1. Deploy validator service:${NC}"
        echo "   ./deploy-validator-simple.sh"
        echo ""
    fi
    
    if [ -n "$VALIDATOR_URL" ] && [ -n "$NGINX_URL" ]; then
        echo -e "${YELLOW}2. Connect nginx proxy to validator:${NC}"
        echo "   ./connect-nginx-to-validator.sh"
        echo ""
    fi
    
    echo -e "${YELLOW}3. Monitor block production:${NC}"
    echo "   watch -n 5 './network-status.sh'"
    echo ""
    
    if [ "$BLOCK_HEIGHT" = "0" ] || [ "$BLOCK_HEIGHT" = "null" ]; then
        echo -e "${YELLOW}4. Troubleshoot block production:${NC}"
        echo "   - Check validator logs in Cloud Run console"
        echo "   - Verify validator has proper genesis configuration"
        echo "   - Ensure validator is running as single-node network"
    fi
}

# Main execution
print_header
check_cloud_run_services
check_validator_health
check_domain_status
show_recommendations
