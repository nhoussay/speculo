#!/bin/bash

# Deploy persistent node to Google Compute Engine for hybrid architecture
# This allows us to expose P2P ports that Cloud Run cannot handle

PROJECT_ID="speculo-blockchain"
INSTANCE_NAME="speculo-persistent-hybrid"
ZONE="europe-west1-b"
MACHINE_TYPE="e2-standard-2"
IMAGE_FAMILY="cos-stable"
IMAGE_PROJECT="cos-cloud"

echo "🚀 Deploying persistent node to Google Compute Engine..."

# Create the instance with Docker support
gcloud compute instances create $INSTANCE_NAME \
    --project=$PROJECT_ID \
    --zone=$ZONE \
    --machine-type=$MACHINE_TYPE \
    --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default \
    --maintenance-policy=MIGRATE \
    --provisioning-model=STANDARD \
    --service-account=347630569936-compute@developer.gserviceaccount.com \
    --scopes=https://www.googleapis.com/auth/cloud-platform \
    --tags=blockchain-node,http-server \
    --create-disk=auto-delete=yes,boot=yes,device-name=$INSTANCE_NAME,image=projects/$IMAGE_PROJECT/global/images/family/$IMAGE_FAMILY,mode=rw,size=50,type=projects/$PROJECT_ID/zones/$ZONE/diskTypes/pd-balanced \
    --no-shielded-secure-boot \
    --shielded-vtpm \
    --shielded-integrity-monitoring \
    --labels=environment=hybrid,node-type=persistent \
    --reservation-affinity=any

# Create firewall rules for blockchain ports
echo "🔥 Creating firewall rules..."

gcloud compute firewall-rules create allow-blockchain-p2p \
    --project=$PROJECT_ID \
    --direction=INGRESS \
    --priority=1000 \
    --network=default \
    --action=ALLOW \
    --rules=tcp:26656,tcp:26657 \
    --source-ranges=0.0.0.0/0 \
    --target-tags=blockchain-node

# Get the external IP
EXTERNAL_IP=$(gcloud compute instances describe $INSTANCE_NAME --zone=$ZONE --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

echo "✅ Instance created with external IP: $EXTERNAL_IP"
echo "🔧 Now connecting to configure the blockchain node..."

# Create startup script for the instance
cat > startup-script.sh << 'EOF'
#!/bin/bash

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Clone the repository (you might want to use a specific tag/commit)
git clone https://github.com/nhoussay/speculo.git /tmp/speculo
cd /tmp/speculo

# Build the blockchain image
sudo docker build -f Dockerfile.blockchain -t speculod-persistent .

# Create data directory
sudo mkdir -p /opt/speculod-data

# Run the persistent node
sudo docker run -d \
    --name speculod-persistent-hybrid \
    --restart unless-stopped \
    -p 26656:26656 \
    -p 26657:26657 \
    -v /opt/speculod-data:/home/speculod/.speculod \
    -e SERVICE_TYPE=tendermint \
    -e NODE_TYPE=persistent \
    -e CHAIN_ID=speculod-local-1 \
    -e MONIKER=speculo-persistent-hybrid-gce \
    -e HOME_DIR=/home/speculod/.speculod \
    -e KEYRING_BACKEND=test \
    -e P2P_LADDR=tcp://0.0.0.0:26656 \
    -e RPC_LADDR=tcp://0.0.0.0:26657 \
    -e MAX_NUM_INBOUND_PEERS=100 \
    -e MAX_NUM_OUTBOUND_PEERS=50 \
    -e GITHUB_REPO=nhoussay/speculo \
    -e GITHUB_BRANCH=main \
    -e NETWORK_NAME=local-testnet \
    speculod-persistent

echo "✅ Persistent node started on Google Compute Engine"
echo "🌐 External IP: $(curl -s ifconfig.me)"
echo "📊 P2P: $(curl -s ifconfig.me):26656"
echo "🔧 RPC: $(curl -s ifconfig.me):26657"
EOF

# Copy and execute the startup script
gcloud compute scp startup-script.sh $INSTANCE_NAME:/tmp/startup-script.sh --zone=$ZONE
gcloud compute ssh $INSTANCE_NAME --zone=$ZONE --command="chmod +x /tmp/startup-script.sh && sudo /tmp/startup-script.sh"

echo ""
echo "🎉 Deployment completed!"
echo "📍 Instance: $INSTANCE_NAME"
echo "🌍 External IP: $EXTERNAL_IP"
echo "🔗 P2P Endpoint: $EXTERNAL_IP:26656"
echo "🔧 RPC Endpoint: $EXTERNAL_IP:26657"
echo ""
echo "You can now connect your local peer to: $EXTERNAL_IP:26656"
