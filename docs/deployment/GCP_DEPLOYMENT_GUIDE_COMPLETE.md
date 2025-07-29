# Google Cloud Deployment Guide for Speculod Blockchain

## 🎯 Multi-Port Deployment Strategy

The Speculod blockchain uses multiple ports that require special handling in Google Cloud:

### Port Architecture
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Validator     │    │   API Service   │    │  Faucet Service │
│                 │    │                 │    │                 │
│ :26656 (P2P)    │◄──►│ HTTP :8080      │    │ HTTP :8080      │
│ :26657 (RPC)    │    │ REST API        │    │ Token Requests  │
│ :8080 (Health)  │    │ gRPC Proxy      │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
      Internal              Public                Public
```

## 🚀 Quick Deployment

### Option 1: Single Service (Recommended for Testing)
```bash
# Set your project ID
export PROJECT_ID="your-gcp-project-id"
export REGION="europe-west1"

# Deploy single service
./scripts/deploy-gcp-enhanced.sh
```

### Option 2: Multi-Service Architecture (Production)
```bash
# Set deployment type to multi-service
export DEPLOYMENT_TYPE="multi"
export PROJECT_ID="your-gcp-project-id"

# Deploy all services
./scripts/deploy-gcp-enhanced.sh
```

## 📋 Prerequisites

### 1. Google Cloud Setup
```bash
# Install gcloud CLI
curl https://sdk.cloud.google.com | bash
exec -l $SHELL

# Authenticate
gcloud auth login
gcloud auth configure-docker

# Set project
gcloud config set project YOUR_PROJECT_ID
```

### 2. Enable Required APIs
```bash
gcloud services enable \
    run.googleapis.com \
    containerregistry.googleapis.com \
    cloudbuild.googleapis.com \
    monitoring.googleapis.com \
    logging.googleapis.com \
    compute.googleapis.com
```

### 3. Create Service Accounts (Multi-Service Only)
```bash
# Validator service account
gcloud iam service-accounts create speculod-validator-sa \
    --display-name="Speculod Validator Service Account"

# API service account
gcloud iam service-accounts create speculod-api-sa \
    --display-name="Speculod API Service Account"

# Faucet service account  
gcloud iam service-accounts create speculod-faucet-sa \
    --display-name="Speculod Faucet Service Account"
```

## 🏗️ Architecture Options

### Single Service Deployment
**Best for**: Development, testing, small networks
```yaml
Services: 1
Resources: 2 CPU, 4GB RAM
Scaling: 1-3 instances
Ports: HTTP only (8080)
Internal: All blockchain ports available internally
```

### Multi-Service Deployment  
**Best for**: Production, high availability
```yaml
Services: 3 (Validator + API + Faucet)
Resources: 
  - Validator: 2 CPU, 4GB RAM
  - API: 1 CPU, 2GB RAM  
  - Faucet: 0.5 CPU, 1GB RAM
Scaling: API and Faucet can auto-scale
Network: Internal VPC communication
```

## 🔧 Configuration

### Environment Variables
```bash
# Required
PROJECT_ID=your-gcp-project-id
REGION=europe-west1

# Optional
DEPLOYMENT_TYPE=single|multi|hybrid
CHAIN_ID=speculod
MONIKER=speculod-gcp
```

### Resource Configuration
Edit the deployment script variables:
```bash
VALIDATOR_RESOURCES="cpu=2,memory=4Gi"
API_RESOURCES="cpu=1,memory=2Gi"  
FAUCET_RESOURCES="cpu=0.5,memory=1Gi"
```

## 🌐 Networking Solution

### Cloud Run Port Limitations
- **Issue**: Cloud Run only supports HTTP/HTTPS on port 8080
- **Solution**: Internal service mesh with port translation

### VPC Setup (Auto-created)
```yaml
Network: speculod-vpc
Subnet: speculod-subnet (10.0.0.0/16)
Connector: speculod-connector (10.1.0.0/28)
```

### Service Communication
```
Validator (:26657) ←→ VPC ←→ API Service (:8080)
                            ↑
                       Public Internet
```

## 📊 Monitoring & Health Checks

### Health Endpoints
```bash
# Single service
curl $SERVICE_URL/health
curl $SERVICE_URL/ready

# Multi-service
curl $API_URL/health
curl $FAUCET_URL/health
curl $VALIDATOR_URL/health  # Internal only
```

### Monitoring Setup
```bash
# View logs
gcloud logs read "resource.type=cloud_run_revision AND resource.labels.service_name=speculod-api"

# Monitor resources
gcloud monitoring dashboards list
```

## 🔄 Scaling Configuration

### Auto-scaling Settings
```yaml
Validator:
  min-instances: 1    # Always running
  max-instances: 1    # Single validator
  
API:
  min-instances: 1
  max-instances: 5    # Scale with demand
  
Faucet:
  min-instances: 1  
  max-instances: 3    # Moderate scaling
```

### Manual Scaling
```bash
# Scale API service
gcloud run services update speculod-api \
    --min-instances=2 \
    --max-instances=10 \
    --region=$REGION

# Update resources
gcloud run services update speculod-api \
    --cpu=2 \
    --memory=4Gi \
    --region=$REGION
```

## 🔐 Security

### Service Accounts
```bash
# Validator: Internal only, no external permissions needed
# API: Needs read access to validator
# Faucet: Needs transaction signing capabilities
```

### Network Security
```bash
# Firewall rules (auto-created)
- Allow internal VPC communication
- Allow HTTP/HTTPS from internet to API/Faucet
- Block direct access to validator
```

## 💰 Cost Optimization

### Estimated Costs (europe-west1)
```yaml
Single Service:
  - 2 CPU, 4GB RAM, always-on: ~$50/month
  
Multi-Service:
  - Validator (always-on): ~$50/month
  - API (scales 1-5): ~$25-125/month
  - Faucet (scales 1-3): ~$12-36/month
  - Total: ~$87-211/month
```

### Optimization Tips
```bash
# Use sustained use discounts
# Scale down non-critical services
# Use committed use discounts for predictable workloads
```

## 🚨 Troubleshooting

### Common Issues

#### Port Connection Errors
```bash
# Check VPC connector
gcloud compute networks vpc-access connectors describe speculod-connector --region=$REGION

# Verify internal DNS
gcloud run services describe speculod-validator --region=$REGION
```

#### Service Communication
```bash
# Test internal connectivity
gcloud run services proxy speculod-api --region=$REGION
curl http://localhost:8080/health
```

#### Resource Limits
```bash
# Check service logs
gcloud logs read "resource.type=cloud_run_revision" --limit=50

# Monitor resource usage
gcloud monitoring metrics list --filter="metric.type:cloud_run"
```

## 📋 Deployment Checklist

### Pre-deployment
- [ ] GCP project created and configured
- [ ] gcloud CLI installed and authenticated  
- [ ] Required APIs enabled
- [ ] Environment variables set

### Deployment
- [ ] Run deployment script
- [ ] Verify service URLs
- [ ] Test health endpoints
- [ ] Check service logs

### Post-deployment
- [ ] Configure monitoring alerts
- [ ] Set up log retention
- [ ] Document service URLs
- [ ] Test blockchain functionality

## 🔄 Updates and Maintenance

### Rolling Updates
```bash
# Update single service
gcloud builds submit --tag gcr.io/$PROJECT_ID/speculod:v2.0
gcloud run services update speculod-blockchain \
    --image gcr.io/$PROJECT_ID/speculod:v2.0 \
    --region=$REGION

# Update multi-service
./scripts/deploy-gcp-enhanced.sh  # Redeploy all services
```

### Backup and Recovery
```bash
# Export blockchain state
gcloud run services proxy speculod-validator --region=$REGION &
curl http://localhost:8080/export > blockchain-state.json

# Persistent storage (if using Filestore)
gcloud filestore backups create blockchain-backup \
    --instance=speculod-data \
    --region=$REGION
```

## 🎯 Next Steps

1. **Test Deployment**: Deploy single service first
2. **Monitor Performance**: Set up dashboards and alerts
3. **Scale Gradually**: Move to multi-service when needed
4. **Optimize Costs**: Use committed use discounts
5. **Multi-Region**: Deploy in multiple regions for HA
