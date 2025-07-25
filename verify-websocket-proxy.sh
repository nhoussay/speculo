#!/bin/bash

# Verify WebSocket P2P Bridge Deployment
# This script tests all endpoints and functionality after deployment

set -e

# Configuration
SERVICE_NAME="speculo-nginx-proxy"
REGION="europe-west1"
PROJECT_ID="speculo-blockchain"
DOMAIN="persistent.specu.io"

echo "🔍 Verifying WebSocket P2P Bridge Deployment..."

# Get service URL
SERVICE_URL=$(gcloud run services describe ${SERVICE_NAME} \
    --region=${REGION} \
    --project=${PROJECT_ID} \
    --format="value(status.url)" 2>/dev/null || echo "")

if [[ -z "$SERVICE_URL" ]]; then
    echo "❌ Service not found or not deployed"
    exit 1
fi

echo "📍 Service URL: ${SERVICE_URL}"
echo "📍 Domain: https://${DOMAIN}"

# Test functions
test_endpoint() {
    local url=$1
    local description=$2
    local timeout=${3:-10}
    
    echo -n "Testing ${description}... "
    if curl -s --max-time ${timeout} "${url}" > /dev/null 2>&1; then
        echo "✅"
        return 0
    else
        echo "❌"
        return 1
    fi
}

test_json_endpoint() {
    local url=$1
    local description=$2
    local jq_filter=$3
    local timeout=${4:-10}
    
    echo -n "Testing ${description}... "
    local result=$(curl -s --max-time ${timeout} "${url}" 2>/dev/null | jq -r "${jq_filter}" 2>/dev/null || echo "error")
    if [[ "$result" != "error" && "$result" != "null" && -n "$result" ]]; then
        echo "✅ (${result})"
        return 0
    else
        echo "❌"
        return 1
    fi
}

test_websocket() {
    local url=$1
    local description=$2
    
    echo -n "Testing ${description}... "
    if command -v wscat &> /dev/null; then
        # Test WebSocket connection
        if timeout 5 wscat -c "${url}" -x 'quit' &> /dev/null; then
            echo "✅"
            return 0
        else
            echo "❌"
            return 1
        fi
    else
        echo "⚠️  (wscat not available, skipping)"
        return 0
    fi
}

# Test with both Cloud Run URL and custom domain
for BASE_URL in "${SERVICE_URL}" "https://${DOMAIN}"; do
    echo ""
    echo "🌐 Testing endpoints for: ${BASE_URL}"
    echo "----------------------------------------"
    
    # Basic connectivity
    test_endpoint "${BASE_URL}" "Basic connectivity" 15
    
    # RPC endpoints
    test_json_endpoint "${BASE_URL}/rpc/status" "RPC status" '.result.node_info.network' 15
    test_json_endpoint "${BASE_URL}/rpc/net_info" "RPC net info" '.result.n_peers' 15
    test_json_endpoint "${BASE_URL}/rpc/genesis" "RPC genesis" '.result.genesis.chain_id' 15
    
    # API endpoints
    test_json_endpoint "${BASE_URL}/api/cosmos/base/tendermint/v1beta1/node_info" "API node info" '.default_node_info.network' 15
    test_json_endpoint "${BASE_URL}/api/cosmos/staking/v1beta1/params" "API staking params" '.params.bond_denom' 15
    
    # WebSocket P2P endpoint
    WS_URL="${BASE_URL/https:/wss:}"
    test_websocket "${WS_URL}/" "WebSocket P2P"
    
    # Test fallback documentation
    test_endpoint "${BASE_URL}/" "Documentation fallback" 10
done

echo ""
echo "🔧 Additional Checks"
echo "--------------------"

# Check service health
echo -n "Service health status... "
STATUS=$(gcloud run services describe ${SERVICE_NAME} \
    --region=${REGION} \
    --project=${PROJECT_ID} \
    --format="value(status.conditions[0].status)" 2>/dev/null || echo "Unknown")

if [[ "$STATUS" == "True" ]]; then
    echo "✅ Ready"
else
    echo "❌ Not ready (${STATUS})"
fi

# Check service configuration
echo -n "Multi-container setup... "
CONTAINER_COUNT=$(gcloud run services describe ${SERVICE_NAME} \
    --region=${REGION} \
    --project=${PROJECT_ID} \
    --format="value(spec.template.spec.containers[].name)" 2>/dev/null | wc -l)

if [[ "$CONTAINER_COUNT" == "3" ]]; then
    echo "✅ (3 containers: nginx, websocket-bridge, speculod)"
else
    echo "❌ (Expected 3 containers, found ${CONTAINER_COUNT})"
fi

# Check domain mapping
echo -n "Domain mapping... "
DOMAIN_STATUS=$(gcloud run domain-mappings describe ${DOMAIN} \
    --region=${REGION} \
    --project=${PROJECT_ID} \
    --format="value(status.conditions[0].status)" 2>/dev/null || echo "NotFound")

if [[ "$DOMAIN_STATUS" == "True" ]]; then
    echo "✅ Active"
elif [[ "$DOMAIN_STATUS" == "NotFound" ]]; then
    echo "⚠️  Not configured"
else
    echo "❌ Issues (${DOMAIN_STATUS})"
fi

echo ""
echo "📊 Summary"
echo "----------"
echo "Service: ${SERVICE_NAME}"
echo "Region: ${REGION}"
echo "URL: ${SERVICE_URL}"
echo "Domain: https://${DOMAIN}"
echo ""
echo "Available endpoints:"
echo "  - RPC: /rpc/*"
echo "  - API: /api/*"
echo "  - gRPC: /grpc/*"  
echo "  - WebSocket P2P: wss://${DOMAIN}/"
echo "  - Documentation: https://${DOMAIN}/"
echo ""

# P2P connection example
NODE_ID=$(curl -s --max-time 10 "https://${DOMAIN}/rpc/status" 2>/dev/null | jq -r '.result.node_info.id' 2>/dev/null || echo "unknown")
if [[ "$NODE_ID" != "unknown" && "$NODE_ID" != "null" ]]; then
    echo "🔗 P2P Connection String:"
    echo "   ${NODE_ID}@${DOMAIN}:443"
    echo ""
fi

echo "✅ Verification complete!"
