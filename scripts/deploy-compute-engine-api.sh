#!/bin/bash

# Deploy Speculo API Gateway on Google Compute Engine
# This script deploys a full-service node with REST, RPC, gRPC, and P2P connectivity

set -e

# Configuration
PROJECT_ID="${PROJECT_ID:-speculo-blockchain}"
ZONE="${ZONE:-europe-west1-b}"
MACHINE_TYPE="${MACHINE_TYPE:-e2-standard-2}"
IMAGE_FAMILY="${IMAGE_FAMILY:-cos-stable}"
IMAGE_PROJECT="${IMAGE_PROJECT:-cos-cloud}"
INSTANCE_NAME="${INSTANCE_NAME:-speculo-api-gateway-1}"

echo "💻 Deploying Speculo API Gateway on Google Compute Engine"
echo "📋 Configuration:"
echo "  - Project: $PROJECT_ID"
echo "  - Zone: $ZONE"
echo "  - Machine Type: $MACHINE_TYPE"
echo "  - Instance: $INSTANCE_NAME"

# Create startup script for the VM
cat > /tmp/startup-script.sh << 'EOF'
#!/bin/bash

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
sudo usermod -aG docker $USER

# Pull and run Speculo API node
sudo docker run -d \
  --name speculo-api-node \
  --restart unless-stopped \
  -p 26657:26657 \
  -p 1317:1317 \
  -p 9090:9090 \
  -p 26656:26656 \
  -e NODE_TYPE=peer \
  -e SERVICE_TYPE=api \
  -e CHAIN_ID=speculod-mainnet-1 \
  -e NETWORK=mainnet \
  -e PERSISTENT_PEERS=838ebde14991541b3bdbe325e4e1009fa3e96cbc@persistent.specu.io:443 \
  -e ENABLE_API=true \
  -e ENABLE_RPC=true \
  -e ENABLE_GRPC=true \
  gcr.io/speculo-blockchain/speculod-api:latest

# Setup nginx reverse proxy for API endpoints
sudo apt-get update
sudo apt-get install -y nginx

# Configure nginx for API access
sudo tee /etc/nginx/sites-available/speculo-api > /dev/null << 'NGINX_CONF'
server {
    listen 80;
    server_name api.specu.io;

    # REST API
    location /rest/ {
        proxy_pass http://localhost:1317/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    # RPC
    location /rpc/ {
        proxy_pass http://localhost:26657/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    # Direct access to ports
    location /status {
        proxy_pass http://localhost:26657/status;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
NGINX_CONF

sudo ln -sf /etc/nginx/sites-available/speculo-api /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

# Setup firewall rules
sudo ufw allow 22
sudo ufw allow 80
sudo ufw allow 443
sudo ufw allow 26656
sudo ufw allow 26657
sudo ufw allow 1317
sudo ufw allow 9090
sudo ufw --force enable

echo "✅ Speculo API Gateway started successfully"
EOF

# Create the VM instance
echo ""
echo "🔧 Creating Compute Engine instance..."
gcloud compute instances create $INSTANCE_NAME \
  --zone=$ZONE \
  --machine-type=$MACHINE_TYPE \
  --network-interface=network-tier=PREMIUM,subnet=default \
  --metadata-from-file startup-script=/tmp/startup-script.sh \
  --maintenance-policy=MIGRATE \
  --provisioning-model=STANDARD \
  --scopes=https://www.googleapis.com/auth/cloud-platform \
  --tags=speculo-api,http-server,https-server \
  --image-family=$IMAGE_FAMILY \
  --image-project=$IMAGE_PROJECT \
  --boot-disk-size=20GB \
  --boot-disk-type=pd-balanced \
  --boot-disk-device-name=$INSTANCE_NAME \
  --project=$PROJECT_ID

# Create firewall rules for the API gateway
echo ""
echo "🔧 Setting up firewall rules..."
gcloud compute firewall-rules create speculo-api-ports \
  --direction=INGRESS \
  --priority=1000 \
  --network=default \
  --action=ALLOW \
  --rules=tcp:26656,tcp:26657,tcp:1317,tcp:9090 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=speculo-api \
  --project=$PROJECT_ID || echo "Firewall rule may already exist"

# Get the external IP
EXTERNAL_IP=$(gcloud compute instances describe $INSTANCE_NAME \
  --zone=$ZONE \
  --project=$PROJECT_ID \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

echo ""
echo "✅ API Gateway Deployed Successfully!"
echo ""
echo "📊 Service Endpoints:"
echo "  - External IP: $EXTERNAL_IP"
echo "  - RPC: http://$EXTERNAL_IP:26657/status"
echo "  - REST API: http://$EXTERNAL_IP:1317/cosmos/bank/v1beta1/supply"
echo "  - gRPC: $EXTERNAL_IP:9090"
echo "  - P2P: Connected to persistent.specu.io"
echo ""
echo "🌐 Domain Setup (Optional):"
echo "  1. Point api.specu.io to $EXTERNAL_IP"
echo "  2. Configure SSL certificate"
echo "  3. Access via: https://api.specu.io/rest/"
echo ""
echo "🔗 Test Commands:"
echo "  curl -s http://$EXTERNAL_IP:26657/status | jq '.result.sync_info.latest_block_height'"
echo "  curl -s http://$EXTERNAL_IP:26657/net_info | jq '.result.n_peers'"
echo "  curl -s http://$EXTERNAL_IP:1317/cosmos/bank/v1beta1/supply"

# Clean up
rm -f /tmp/startup-script.sh
