#!/bin/bash

# Update Nginx Proxy to Connect to Validator
# This script updates the nginx proxy configuration to connect to the validator service

set -e

PROJECT_ID="speculo-blockchain"
REGION="europe-west1"
NGINX_SERVICE="speculo-nginx-proxy"
VALIDATOR_SERVICE="speculod-validator"

echo "🔗 Updating Nginx Proxy to connect to Validator..."

# Get validator service URL
echo "📡 Getting validator service URL..."
VALIDATOR_URL=$(gcloud run services describe $VALIDATOR_SERVICE --region=$REGION --project=$PROJECT_ID --format="value(status.url)" 2>/dev/null || echo "")

if [ -z "$VALIDATOR_URL" ]; then
    echo "❌ Validator service not found. Please deploy the validator first with:"
    echo "   ./deploy-validator-simple.sh"
    exit 1
fi

echo "✅ Found validator at: $VALIDATOR_URL"

# Check if validator is ready
echo "🧪 Testing validator connectivity..."
if curl -s --max-time 10 "$VALIDATOR_URL/health" >/dev/null 2>&1; then
    echo "✅ Validator health check passed"
else
    echo "⚠️  Validator health check failed, but continuing..."
fi

# For now, we need to rebuild the nginx proxy with the validator URL
# This would require updating the nginx configuration and redeploying
echo ""
echo "📋 Manual Steps Required:"
echo "1. The validator is now running at: $VALIDATOR_URL"
echo "2. To connect the nginx proxy, you need to:"
echo "   a) Update nginx configuration to proxy to $VALIDATOR_URL"
echo "   b) Redeploy the nginx proxy with the new configuration"
echo ""
echo "🔧 Quick Test Commands:"
echo "   # Test validator directly:"
echo "   curl $VALIDATOR_URL/health"
echo "   curl $VALIDATOR_URL/ready"
echo "   # Once ready, test RPC:"
echo "   curl $VALIDATOR_URL/status"

echo ""
echo "✅ Validator URL captured: $VALIDATOR_URL"
echo "💡 Next: Update nginx proxy configuration to use this validator"
