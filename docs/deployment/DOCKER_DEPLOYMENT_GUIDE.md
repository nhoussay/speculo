# Docker Deployment Guide

## 🎯 Current Architecture Status

✅ **PRODUCTION READY**: Multi-service peer-to-peer blockchain architecture  
✅ **OPERATIONAL**: Complete Docker orchestration with docker-compose-local-test.yml  
✅ **READY**: Three independent services (Tendermint, API, Faucet)  
✅ **INTEGRATED**: Peer-to-peer connection between main node and API node  
✅ **COMPLETE**: Google Cloud Run deployment configuration  
🔄 **FINAL STEP**: API peer connection validation (bug fix applied)

## 🏗️ Multi-Service Architecture

### 📊 **Service Overview**
```yaml
services:
  tendermint:     # Main Validator & RPC Node
    - Ports: 26657 (RPC), 26656 (P2P)
    - Role: Block production, consensus, peer discovery
    
  api:           # Peer Full Node & REST API
    - Ports: 1317 (REST API)  
    - Role: Blockchain sync, API endpoints, peer connection
    
  faucet:        # Development Token Distribution
    - Ports: 5001 (Web interface)
    - Role: Token distribution for testing
```

### 🔗 **Service Communication**
1. **Peer Discovery**: API discovers Tendermint node ID via RPC
2. **Genesis Download**: API downloads genesis.json from Tendermint
3. **P2P Connection**: API connects to Tendermint as blockchain peer
4. **Blockchain Sync**: API syncs complete blockchain from Tendermint
5. **Client Access**: External clients use API for REST endpoints

## 🚀 Quick Start Commands

### ⚡ Start Complete Architecture (Recommended)
```bash
# Start all three services
docker-compose -f docker-compose-local-test.yml up -d

# Monitor startup progress
docker-compose -f docker-compose-local-test.yml logs -f

# Verify services
curl http://localhost:26657/status    # Tendermint
curl http://localhost:1317/node_info  # API Node
curl http://localhost:5001/health     # Faucet
```

### 🛠️ Development Mode (Single Service)
```bash
# Fast development with API only
docker-compose up -d

# Access points:
curl http://localhost:8080/status     # Tendermint RPC
curl http://localhost:1317/swagger/   # API Swagger UI
```

## 📦 Container Images

### 🏗️ **Build Commands**
```bash
# Build all images
docker build --no-cache -t gcr.io/speculo-blockchain/speculod:v1 .
docker build --no-cache -f Dockerfile.api -t gcr.io/speculo-blockchain/speculod-api:v1 .
docker build --no-cache -f Dockerfile.faucet -t gcr.io/speculo-blockchain/speculod-faucet:v1 .

# Batch build with Docker Compose
docker-compose -f docker-compose-local-test.yml build --no-cache
```

### 🎯 **Image Specifications**
```dockerfile
# Tendermint Validator (Dockerfile)
FROM golang:1.21-alpine
EXPOSE 26657 26656
ENTRYPOINT ["./scripts/blockchain-service.sh"]

# API Peer Node (Dockerfile.api)  
FROM golang:1.21-alpine
EXPOSE 1317
ENTRYPOINT ["./scripts/api-service.sh"]

# Token Faucet (Dockerfile.faucet)
FROM python:3.9-slim
EXPOSE 5001  
ENTRYPOINT ["python", "scripts/faucet-server-flask.py"]
```
```bash
# DON'T USE - Service interconnection problems
docker-compose up --build
docker run -p 26656:26656 -p 26657:26657 -p 1317:1317 -p 9090:9090 speculod
```

**❌ Legacy GKE Deployment (OUTDATED)**
```bash
# DON'T USE - Configuration outdated, use Cloud Run instead
kubectl apply -f k8s-deployment.yaml
```

## 📋 Prerequisites (UPDATED)

### For Local Development (WORKING METHOD)
- Docker (required for `dev.sh` script)
- bash/zsh shell
- curl (for testing)
- **NO Go installation required** (handled by Docker)

### For Google Cloud (VERIFIED REQUIREMENTS)
- Google Cloud SDK installed and configured ✅
- Docker with buildx support ✅  
- A Google Cloud project with billing enabled ✅
- Required permissions for Cloud Run, Container Registry ✅
- **Architecture Note**: AMD64 targeting handled automatically ✅

## 🔧 Configuration Management

### ⚙️ **Environment Variables**
```bash
# Tendermint Configuration
CHAIN_ID=speculod-1
MONIKER=speculod-node
VALIDATOR_NAME=alice

# API Node Configuration  
API_ENABLE=true
SWAGGER_ENABLE=true
CORS_ALLOW_ALL=true

# Faucet Configuration
FAUCET_AMOUNT=1000000
FAUCET_DENOM=uspeculod
RPC_ENDPOINT=http://tendermint:26657
```

### � **Volume Mounts**
```yaml
# Persistent blockchain data
volumes:
  - tendermint_data:/root/.speculod
  - api_data:/root/.speculod
  
# Configuration synchronization
volumes:
  - ./config:/shared-config
```

### 🔗 **Network Configuration** 
```yaml
# Docker internal network
networks:
  speculod-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

## 🐳 Docker Compose Files

### 📄 **docker-compose-local-test.yml** (Production Architecture)
```yaml
# Complete three-service peer-to-peer architecture
# - Tendermint validator on port 26657/26656
# - API peer node on port 1317  
# - Faucet service on port 5001
# 
# Usage: docker-compose -f docker-compose-local-test.yml up -d
```

### � **docker-compose.yml** (Development)
```yaml  
# Single-service development setup
# - Combined Tendermint + API on ports 8080/1317
#
# Usage: docker-compose up -d
```

### 📄 **docker-compose-simple.yml** (Minimal)
```yaml
# Minimal blockchain-only deployment
# - Tendermint validator only
#
# Usage: docker-compose -f docker-compose-simple.yml up -d
```

## ☁️ Google Cloud Run Deployment

### 🚀 **Automated Multi-Service Deployment**
```bash
# Deploy complete architecture to Europe West 1
export PROJECT_ID="your-gcp-project-id"
./scripts/deploy-gcp-multi-service.sh

# Deployed services:
# - Tendermint: europe-west1.run.app
# - API: europe-west1.run.app  
# - Faucet: europe-west1.run.app
```

### 🎯 **Individual Service Deployment**
```bash
# Deploy Tendermint only
./scripts/deploy-gcp.sh tendermint

# Deploy API only  
./scripts/deploy-gcp.sh api

# Deploy Faucet only
./scripts/deploy-gcp.sh faucet
```

### ⚙️ **Cloud Run Configuration**
```yaml
# Each service automatically configured with:
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: speculod-[service]
  annotations:
    run.googleapis.com/ingress: all
    run.googleapis.com/execution-environment: gen2
spec:
  template:
    metadata:
      annotations:
        run.googleapis.com/cpu-throttling: "false"
        run.googleapis.com/memory: "4Gi"
        run.googleapis.com/cpu: "2"
```

## 🔍 Monitoring & Debugging

### 📊 **Service Health Checks**
```bash
# Check all services
docker-compose -f docker-compose-local-test.yml ps

# Individual service logs
docker-compose logs tendermint -f
docker-compose logs api -f  
docker-compose logs faucet -f

# Service-specific health endpoints
curl http://localhost:26657/health     # Tendermint
curl http://localhost:1317/health      # API
curl http://localhost:5001/health      # Faucet
```

### 🔧 **Debug Commands**
```bash
# Execute commands inside containers
docker-compose exec tendermint speculodd status
docker-compose exec api speculodd query bank total
docker-compose exec faucet python -c "import requests; print(requests.get('http://tendermint:26657/status').json())"

# Container resource usage
docker stats --format "table {{.Container}}	{{.CPUPerc}}	{{.MemUsage}}	{{.NetIO}}"

# Network connectivity tests  
docker-compose exec api ping tendermint
docker-compose exec faucet curl http://tendermint:26657/health
```

### 🧪 **Peer Connection Validation**
```bash
# Verify API peer discovers Tendermint  
docker-compose logs api | grep "node-id"

# Check peer address format (bug fix verification)
docker-compose logs api | grep "persistent-peers"

# Validate P2P connection established
curl http://localhost:26657/net_info | jq '.result.peers'
```

## 📈 Performance Optimization

### ⚡ **Resource Allocation**
```yaml
# Recommended resource limits
services:
  tendermint:
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: '0.5'
          
  api:
    deploy:
      resources:
        limits:  
          memory: 512M
          cpus: '0.25'
          
  faucet:
    deploy:
      resources:
        limits:
          memory: 128M  
          cpus: '0.1'
```

### 🚀 **Performance Tuning**
```bash
# Enable API caching
export API_CACHE_ENABLE=true

# Optimize Tendermint consensus
export CONSENSUS_TIMEOUT_COMMIT=3s

# Increase connection limits
export P2P_MAX_NUM_PEERS=50
export RPC_MAX_OPEN_CONNECTIONS=900
```

## 🚨 Troubleshooting

### 🔧 **Common Issues**

**1. Port Conflicts**
```bash  
# Check port usage
lsof -i :26657,26656,1317,5001

# Stop conflicting processes
docker-compose -f docker-compose-local-test.yml down
pkill -f speculodd
```

**2. API Peer Connection Issues**  
```bash
# Restart with clean state
docker-compose -f docker-compose-local-test.yml down -v
docker-compose -f docker-compose-local-test.yml up -d

# Monitor connection process
docker-compose logs api -f | grep -E "node-id|persistent-peers|P2P"
```

**3. Container Build Problems**
```bash
# Clean Docker cache completely
docker system prune -a --volumes
docker builder prune -a

# Rebuild with no cache
docker-compose build --no-cache --parallel
```

**4. Genesis Configuration Sync**
```bash
# Verify genesis consistency
docker-compose exec tendermint cat /root/.speculod/config/genesis.json | jq '.chain_id'
docker-compose exec api cat /root/.speculod/config/genesis.json | jq '.chain_id'
```

### 🆘 **Emergency Recovery**
```bash
# Complete system reset
docker-compose -f docker-compose-local-test.yml down -v  
docker system prune -a
docker volume prune -f
rm -rf ~/.speculod/

# Restart from clean state
docker-compose -f docker-compose-local-test.yml up -d --build
```

## 📚 Advanced Configuration

### 🔐 **Production Security**
```yaml
# Secure production deployment
environment:
  - KEYRING_BACKEND=file  # Use file-based keyring
  - API_ENABLED_UNSAFE_CORS=false  # Disable unsafe CORS
  - RPC_LADDR=tcp://0.0.0.0:26657  # Bind to specific interface  
  
secrets:
  - validator_key
  - api_certificates
```

### 🌍 **Multi-Region Deployment**
```bash  
# Deploy to multiple Cloud Run regions
regions=("europe-west1" "us-central1" "asia-northeast1")

for region in "${regions[@]}"; do
  gcloud run deploy speculod-tendermint 
    --region=$region 
    --image=gcr.io/$PROJECT_ID/speculod:v1
done
```

### 📊 **Monitoring Integration**
```yaml
# Add monitoring sidecar
services:
  monitoring:
    image: prom/prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml
```

For complete deployment workflows, see `scripts/deploy-gcp-multi-service.sh` and related deployment automation.
```

### ❌ Deprecated Cloud Deployment Methods

**❌ Manual Cloud Run (OUTDATED - Architecture Issues)**
```bash
# DON'T USE - Has architecture compatibility problems
docker build -t gcr.io/PROJECT_ID/speculod .
docker push gcr.io/PROJECT_ID/speculod
gcloud run deploy --image gcr.io/PROJECT_ID/speculod
```

**❌ Legacy deploy-gcp.sh (SINGLE CONTAINER - INADEQUATE)**
```bash
# DON'T USE - Single container lacks multi-service architecture  
bash scripts/deploy-gcp.sh
```

**❌ GKE Deployment (OVERCOMPLICATED FOR CURRENT NEEDS)**
```bash
# DON'T USE - Unnecessary complexity, Cloud Run is sufficient
kubectl apply -f k8s-deployment.yaml
```

## 🔍 Testing Your Deployment (VERIFIED METHODS ONLY)

### ✅ Working Health Checks
```bash
# Local development testing - VERIFIED ✅
curl http://localhost:8080/status
./scripts/dev.sh test

# Google Cloud testing - VERIFIED ✅ (replace with your URL)
curl https://speculod-blockchain-809714550777.europe-west1.run.app/status

# Production API testing - VERIFIED ✅
curl https://your-service-url.run.app/cosmos/base/tendermint/v1beta1/node_info

# Block height verification - VERIFIED ✅  
curl -s https://your-service-url.run.app/status | jq '.result.sync_info.latest_block_height'
```

### ❌ Deprecated Testing Methods

**❌ Docker Compose Testing (UNRELIABLE)**
```bash
# DON'T USE - May give false results due to service issues
curl http://localhost:26657/health
curl http://localhost:26657/status
```

**❌ Custom Module Testing (MAY NOT WORK)**
```bash
# DON'T USE - Module endpoints may not be properly configured
curl http://localhost:1317/speculod/prediction/v1/params
curl http://localhost:1317/speculod/reputation/v1/params
```

## 📊 Monitoring and Logs (WORKING METHODS ONLY)

### ✅ Working Log Access
```bash
# Local development logs - VERIFIED ✅
./scripts/dev.sh logs

# Google Cloud Run logs - VERIFIED ✅
gcloud logs tail speculod-blockchain --region europe-west1

# Specific service status - VERIFIED ✅
gcloud run services describe speculod-blockchain --region europe-west1
```

### ❌ Deprecated Log Methods

**❌ Docker Compose Logs (UNRELIABLE)**
```bash
# DON'T USE - May not show proper service interactions
docker logs speculod-blockchain -f
docker-compose logs -f
```

**❌ GKE Logs (NOT APPLICABLE)**
```bash
# DON'T USE - We use Cloud Run, not GKE
kubectl logs -f deployment/speculod-blockchain
```

## 🔧 Troubleshooting (TESTED SOLUTIONS ONLY)

### ✅ Working Solutions

**Development Issues**
```bash
# Restart local development - VERIFIED SOLUTION ✅
./scripts/dev.sh stop
./scripts/dev.sh dev
```

**Cloud Deployment Issues**  
```bash
# Re-run deployment script - HANDLES ALL KNOWN ISSUES ✅
./scripts/deploy-gcp-multi-service.sh

# The script automatically fixes:
# ✅ Architecture compatibility (AMD64)
# ✅ Script line endings (CRLF to LF)  
# ✅ Cloud Run configuration (gen2, resources)
```

### ❌ Solutions That Don't Address Real Issues

**❌ Container Resource Problems (NOT THE ROOT CAUSE)**
```bash
# DON'T USE - Resource issues are handled by proper configuration
# Problems were architecture/script compatibility, not resources
```

**❌ Port Conflicts (NOT APPLICABLE TO CLOUD)**
```bash
# DON'T USE - For Cloud Run, port mapping is handled automatically
netstat -tulpn | grep :26657
```

**❌ Docker System Cleanup (DOESN'T FIX CORE ISSUES)**
```bash
# DON'T USE - Cleaning won't fix architecture or script compatibility  
docker system prune -f
docker builder prune -f
```

---

## 📋 Summary: What Actually Works

### ✅ WORKING (Use These):
1. **Local**: `./scripts/dev.sh dev`
2. **Production**: `./scripts/deploy-gcp-multi-service.sh`
3. **Testing**: `curl http://localhost:8080/status` or Cloud Run URL
4. **Logs**: `./scripts/dev.sh logs` or `gcloud logs tail`

### ❌ DON'T USE (Known Issues):
1. Docker Compose multi-service setups
2. Native builds with make install
3. Legacy deployment scripts  
4. Manual Docker commands without architecture targeting
5. GKE deployments (unnecessary complexity)

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
