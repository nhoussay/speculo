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
