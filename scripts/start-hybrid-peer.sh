#!/bin/bash

# Script to connect local peer to Google Compute Engine persistent node

PROJECT_ID="speculo-blockchain"
INSTANCE_NAME="speculo-persistent-hybrid"
ZONE="europe-west1-b"

echo "🔍 Getting Google Compute Engine persistent node IP..."

# Get the external IP of the GCE instance
GCE_IP=$(gcloud compute instances describe $INSTANCE_NAME --zone=$ZONE --format='get(networkInterfaces[0].accessConfigs[0].natIP)' 2>/dev/null)

if [ -z "$GCE_IP" ]; then
    echo "❌ Could not get GCE instance IP. Make sure the instance is running."
    echo "Run: ./deploy-hybrid-gce.sh first"
    exit 1
fi

echo "✅ Found GCE persistent node at: $GCE_IP"

# Create the updated docker-compose file with the real IP
cp docker-compose-hybrid-gce.yml docker-compose-hybrid-gce-configured.yml
sed -i '' "s/GCE_EXTERNAL_IP/$GCE_IP/g" docker-compose-hybrid-gce-configured.yml

echo "🔧 Updated docker-compose configuration with IP: $GCE_IP"

# Check if GCE node is accessible
echo "🔍 Checking if GCE persistent node is accessible..."
if curl -s --connect-timeout 5 "http://$GCE_IP:26657/status" > /dev/null; then
    echo "✅ GCE persistent node is accessible"
else
    echo "⚠️  GCE persistent node not yet accessible. It might still be starting up."
    echo "   The local peer will try to connect anyway."
fi

# Stop any existing hybrid containers
echo "🧹 Cleaning up any existing hybrid containers..."
docker-compose -f docker-compose-hybrid-gce-configured.yml down -v

# Start the hybrid peer
echo "🚀 Starting local hybrid peer..."
docker-compose -f docker-compose-hybrid-gce-configured.yml up -d

echo ""
echo "🎉 Hybrid deployment started!"
echo "🌐 GCE Persistent Node: $GCE_IP:26656 (P2P) / $GCE_IP:26657 (RPC)"
echo "🏠 Local Peer Node: localhost:26670 (P2P) / localhost:26671 (RPC) / localhost:1321 (API)"
echo ""
echo "📊 Check status with:"
echo "  docker-compose -f docker-compose-hybrid-gce-configured.yml logs -f"
echo ""
echo "🔗 Test connectivity:"
echo "  curl http://localhost:26671/status"
echo "  curl http://$GCE_IP:26657/status"
