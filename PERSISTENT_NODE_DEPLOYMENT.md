# Persistent Node Deployment Instructions

## Deploy a Persistent Node to Google Cloud

This guide will help you deploy a persistent Tendermint node to Google Cloud that can serve as a seed node for your blockchain network.

### Prerequisites

1. **Set up your Google Cloud project:**
   ```bash
   export PROJECT_ID=your-gcp-project-id
   ```

2. **Authenticate with Google Cloud:**
   ```bash
   gcloud auth login
   gcloud config set project $PROJECT_ID
   ```

3. **Optional: Set custom region/zone:**
   ```bash
   export REGION=europe-west1
   export ZONE=europe-west1-b
   ```

### Deploy the Persistent Node

Run the deployment script:
```bash
./scripts/deploy-persistent-node-gcp.sh
```

### What the Deployment Creates

✅ **VPC Infrastructure:**
- VPC network and subnet for secure networking
- VPC connector for Cloud Run
- Firewall rules for P2P (26656) and RPC (26657) ports

✅ **Networking:**
- Static external IP address for P2P connections
- Load balancer configuration

✅ **Services:**
- Container image optimized for persistent node
- Cloud Run service with persistent configuration
- Service account with appropriate permissions

✅ **Monitoring:**
- Uptime checks for RPC endpoints
- Cloud Monitoring integration

### What the Persistent Node Provides

🔗 **Tendermint RPC:** Available on port 26657
- `/status` - Node status and blockchain info
- `/health` - Health check endpoint
- `/node_info` - Node information for P2P connections

🌐 **P2P Network:** Available on port 26656
- Acts as a seed node for other blockchain nodes
- Supports up to 100 inbound peer connections
- Provides stable network entry point

### After Deployment

1. **Test the RPC endpoint:**
   ```bash
   SERVICE_URL=$(gcloud run services describe speculod-persistent-node --region=$REGION --format="value(status.url)")
   curl $SERVICE_URL/status
   ```

2. **Get the node ID for peer connections:**
   ```bash
   curl -s $SERVICE_URL/status | jq -r '.result.node_info.id'
   ```

3. **Use this node as a persistent peer:**
   ```bash
   # For other nodes connecting to this persistent node
   EXTERNAL_IP=$(gcloud compute addresses describe speculod-persistent-ip --region=$REGION --format="value(address)")
   NODE_ID=$(curl -s $SERVICE_URL/status | jq -r '.result.node_info.id')
   export PERSISTENT_PEERS="$NODE_ID@$EXTERNAL_IP:26656"
   ```

### Monitoring and Management

- **View logs:** `gcloud logs read speculod-persistent-node`
- **Monitor metrics:** Google Cloud Console > Cloud Run > speculod-persistent-node
- **Scale resources:** `gcloud run services update speculod-persistent-node --cpu=4 --memory=8Gi`

### Cost Optimization

The persistent node is configured to:
- Always run (min-instances=1) for network stability
- Use appropriate resource limits (2 CPU, 4GB RAM)
- Single instance only (max-instances=1) for consistency

This ensures your persistent node is always available for other nodes to connect to while maintaining cost efficiency.
