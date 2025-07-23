#!/bin/bash

# Deploy Speculo P2P Network Infrastructure on Google Cloud Run
# This script deploys persistent and peer nodes with only P2P port exposed

set -e

# Configuration
PROJECT_ID="${PROJECT_ID:-speculo-blockchain}"
REGION="${REGION:-europe-west1}"
IMAGE_TAG="${IMAGE_TAG:-latest}"

echo "🌐 Deploying Speculo P2P Network Infrastructure on Google Cloud Run"
echo "📋 Configuration:"
echo "  - Project: $PROJECT_ID"
echo "  - Region: $REGION"
echo "  - Image Tag: $IMAGE_TAG"

# Deploy Persistent Node (Network Bootstrap)
echo ""
echo "🔧 Deploying Persistent Node (Bootstrap)..."
gcloud run deploy speculo-persistent-node-1 \
  --image gcr.io/$PROJECT_ID/speculod-persistent:$IMAGE_TAG \
  --platform managed \
  --region $REGION \
  --port 26656 \
  --set-env-vars="NODE_TYPE=persistent,SERVICE_TYPE=p2p,CHAIN_ID=speculod-mainnet-1,NETWORK=mainnet" \
  --allow-unauthenticated \
  --memory 1Gi \
  --cpu 1 \
  --max-instances 3 \
  --min-instances 1 \
  --timeout 3600 \
  --project $PROJECT_ID

# Map custom domain for persistent node
echo ""
echo "🌐 Mapping domain for persistent node..."
gcloud run domain-mappings create \
  --service speculo-persistent-node-1 \
  --domain persistent.specu.io \
  --region $REGION \
  --project $PROJECT_ID || echo "Domain mapping may already exist"

# Deploy Peer Nodes (Network Participants)
echo ""
echo "🔧 Deploying Peer Nodes..."
for i in {1..3}; do
  echo "Deploying peer node $i..."
  gcloud run deploy speculo-peer-node-$i \
    --image gcr.io/$PROJECT_ID/speculod-peer:$IMAGE_TAG \
    --platform managed \
    --region $REGION \
    --port 26656 \
    --set-env-vars="NODE_TYPE=peer,SERVICE_TYPE=p2p,CHAIN_ID=speculod-mainnet-1,NETWORK=mainnet,PERSISTENT_PEERS=838ebde14991541b3bdbe325e4e1009fa3e96cbc@persistent.specu.io:443" \
    --allow-unauthenticated \
    --memory 512Mi \
    --cpu 0.5 \
    --max-instances 2 \
    --min-instances 0 \
    --timeout 3600 \
    --project $PROJECT_ID
done

echo ""
echo "✅ P2P Network Infrastructure Deployed Successfully!"
echo ""
echo "📊 Network Status:"
echo "  - Persistent Node: https://persistent.specu.io/status"
echo "  - P2P Network: Mainnet (speculod-mainnet-1)"
echo "  - Region: $REGION"
echo ""
echo "🔗 Network Endpoints:"
echo "  - Persistent Node P2P: persistent.specu.io:443"
echo "  - Node ID: 838ebde14991541b3bdbe325e4e1009fa3e96cbc"
echo ""
echo "⚠️  Note: Cloud Run nodes only expose P2P networking."
echo "   For API access, deploy Compute Engine nodes or local nodes."
