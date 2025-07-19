# 🐳 Speculod Blockchain - Docker & Google Cloud Deployment Guide

## 🚀 Quick Start Options

### Option 1: Local Docker (Recommended for Testing)
```bash
# Build and run with Docker Compose
docker-compose up --build

# Or build and run manually
docker build -t speculod .
docker run -p 26656:26656 -p 26657:26657 -p 1317:1317 -p 9090:9090 speculod
```

### Option 2: Google Cloud Run (Serverless)
```bash
# Set your project ID
export PROJECT_ID=your-gcp-project-id

# Deploy to Cloud Run
bash scripts/deploy-gcp.sh
```

### Option 3: Google Kubernetes Engine (GKE)
```bash
# Update PROJECT_ID in k8s-deployment.yaml
# Then apply the configuration
kubectl apply -f k8s-deployment.yaml
```

## 📋 Prerequisites

### For Local Docker
- Docker and Docker Compose installed
- At least 4GB RAM available
- Ports 26656, 26657, 1317, 9090 available

### For Google Cloud
- Google Cloud SDK installed and configured
- Docker installed
- A Google Cloud project with billing enabled
- Required permissions for Cloud Run, Container Registry, and Cloud Build

## 🔧 Configuration

### Environment Variables
The Docker container accepts these environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `CHAIN_ID` | `speculod` | Blockchain chain identifier |
| `MONIKER` | `speculod-docker` | Node moniker/name |
| `HOME_DIR` | `/home/speculod/.speculod` | Blockchain data directory |
| `KEY_NAME` | `alice` | Genesis account key name |
| `KEYRING_BACKEND` | `test` | Keyring backend type |
| `GENESIS_COINS` | `1000000000000stake` | Initial coins for genesis account |
| `STAKING_AMOUNT` | `500000000stake` | Validator stake amount |
| `MIN_GAS_PRICES` | `0stake` | Minimum gas prices |

### Port Mapping
- **26656**: P2P communication port
- **26657**: RPC server (main API endpoint)
- **1317**: REST API server
- **9090**: gRPC server

## 🛠️ Local Development

### Build and Test Locally
```bash
# Build the Docker image
docker build -t speculod .

# Run with custom configuration
docker run -e CHAIN_ID=my-test-chain -e MONIKER=my-node \
  -p 26657:26657 -p 1317:1317 speculod

# Check if it's running
curl http://localhost:26657/status
```

### Docker Compose Development
```bash
# Start the blockchain
docker-compose up -d

# View logs
docker-compose logs -f

# Stop the blockchain
docker-compose down

# Reset blockchain data
docker-compose down -v
```

## ☁️ Google Cloud Deployment

### Cloud Run Deployment
```bash
# Set your project ID
export PROJECT_ID=your-gcp-project-id

# Optional: Set region (default: us-central1)
export REGION=us-west1

# Deploy
bash scripts/deploy-gcp.sh
```

### Manual Cloud Run Deployment
```bash
# Build and push image
docker build -t gcr.io/PROJECT_ID/speculod .
docker push gcr.io/PROJECT_ID/speculod

# Deploy to Cloud Run
gcloud run deploy speculod-blockchain \
  --image gcr.io/PROJECT_ID/speculod \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --memory 4Gi \
  --cpu 2 \
  --port 26657
```

### GKE Deployment
```bash
# Create GKE cluster
gcloud container clusters create speculod-cluster \
  --num-nodes=1 \
  --machine-type=e2-standard-4

# Get credentials
gcloud container clusters get-credentials speculod-cluster

# Update PROJECT_ID in k8s-deployment.yaml
sed -i 's/PROJECT_ID/your-gcp-project-id/g' k8s-deployment.yaml

# Deploy
kubectl apply -f k8s-deployment.yaml

# Get external IP
kubectl get services speculod-service
```

## 🔍 Testing Your Deployment

### Health Checks
```bash
# Local Docker
curl http://localhost:26657/health
curl http://localhost:26657/status

# Google Cloud (replace with your service URL)
curl https://speculod-blockchain-xxx-uc.a.run.app/health
curl https://speculod-blockchain-xxx-uc.a.run.app/status
```

### API Testing
```bash
# Check current block height
curl -s http://localhost:26657/status | jq '.result.sync_info.latest_block_height'

# Query blockchain parameters
curl http://localhost:1317/cosmos/base/tendermint/v1beta1/node_info

# Test custom modules
curl http://localhost:1317/speculod/prediction/v1/params
curl http://localhost:1317/speculod/reputation/v1/params
curl http://localhost:1317/speculod/settlement/v1/params
```

## 📊 Monitoring and Logs

### Docker Logs
```bash
# View container logs
docker logs speculod-blockchain -f

# Docker Compose logs
docker-compose logs -f
```

### Google Cloud Logs
```bash
# Cloud Run logs
gcloud run logs tail speculod-blockchain --region us-central1

# GKE logs
kubectl logs -f deployment/speculod-blockchain
```

## 🔧 Troubleshooting

### Common Issues

1. **Container won't start**
   - Check port availability: `netstat -tulpn | grep :26657`
   - Verify Docker resources: Ensure at least 4GB RAM

2. **Blockchain not producing blocks**
   - Check validator status: `curl http://localhost:26657/status`
   - Verify genesis account: Look for initialization logs

3. **External access issues (Cloud deployments)**
   - Verify firewall rules
   - Check service configuration
   - Ensure proper port mapping

### Reset Blockchain Data
```bash
# Docker Compose
docker-compose down -v
docker-compose up

# Manual Docker
docker stop speculod-container
docker rm speculod-container
docker run --name speculod-container -p 26657:26657 speculod
```

## 💡 Production Considerations

### Security
- Use proper authentication for public deployments
- Configure firewall rules appropriately
- Consider using private container registries
- Implement proper monitoring and alerting

### Performance
- Adjust CPU and memory limits based on load
- Consider using persistent storage for blockchain data
- Set up proper backup strategies

### High Availability
- Deploy multiple validator nodes
- Use load balancers for API endpoints
- Implement proper health checks and auto-recovery

## 📚 Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Google Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Cosmos SDK Documentation](https://docs.cosmos.network/)

---

🎉 **Your Speculod blockchain is now ready for cloud deployment!**
