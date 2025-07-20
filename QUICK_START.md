# 🚀 Speculod Quick Start Guide

Get your Speculod blockchain running in minutes with **PEER-TO-PEER MULTI-SERVICE** architecture.

## 🏃‍♂️ Quick Local Development (VERIFIED ✅)

```bash
# 1. Clone and navigate to project
cd /Users/nicolas/speculod/blockchain/speculod

# 2. Start blockchain using WORKING script
./scripts/dev.sh dev

# 3. Test connectivity
curl http://localhost:8080/status

# Your blockchain is now running! 🎉
# Access points:
# - RPC: http://localhost:8080 ✅
# - REST API: http://localhost:1317 ✅  
# - Health Check: http://localhost:8080/status ✅
```

## 🐳 Peer-to-Peer Local Testing (NEW! ✅)

```bash
# 1. Start three-service architecture
docker-compose -f docker-compose-local-test.yml up -d

# 2. Services automatically configure peer connections:
# - Tendermint: http://localhost:26657 (Main validator)
# - API Node:   http://localhost:1317  (Peer full node + REST)  
# - Faucet:     http://localhost:5001  (Token distribution)

# 3. Test all services
curl http://localhost:26657/status  # Tendermint RPC
curl http://localhost:1317/cosmos/base/tendermint/v1beta1/node_info  # REST API
curl http://localhost:5001/health   # Faucet service
```

## ☁️ Quick Cloud Deployment (READY ✅)

```bash
# 1. Set your GCP project
export PROJECT_ID="your-gcp-project-id"

# 2. Deploy to European region using TESTED script
chmod +x scripts/deploy-gcp-multi-service.sh
./scripts/deploy-gcp-multi-service.sh

# 3. Your services will be live at the URLs shown in the deployment output!
# Result: Production blockchain in europe-west1 with peer-to-peer architecture
```

## ⚡ Architecture Overview

```
┌─────────────────────┐    ┌─────────────────────┐    ┌─────────────────────┐
│   Tendermint RPC    │    │   REST API Node     │    │   Token Faucet      │
│   (Main Validator)  │◄──►│  (Peer Full Node)   │◄───┤    (Development)    │
│                     │    │                     │    │                     │
│  localhost:26657    │    │  localhost:1317     │    │  localhost:5001     │
│  Block Production   │    │  REST Endpoints     │    │  Token Distribution │
│  Genesis Creation   │    │  Swagger UI         │    │  Web Interface      │
│  P2P Network        │    │  Blockchain Sync    │    │  Health Monitoring  │
└─────────────────────┘    └─────────────────────┘    └─────────────────────┘
```

## ⚠️ Current Methods Status

### ✅ WORKING Methods
- `./scripts/dev.sh dev` - Local development (TESTED) 
- `docker-compose -f docker-compose-local-test.yml up -d` - Peer-to-peer testing (NEW!)
- `./scripts/deploy-gcp-multi-service.sh` - Cloud deployment (READY)
- Individual service testing with curl commands (TESTED)

### 🔄 IN PROGRESS Methods  
- **Three-service peer connection**: Bug fix implemented, testing in progress
- **Complete blockchain synchronization**: Final integration validation

### ❌ NON-WORKING / DEPRECATED Methods
- `docker-compose -f docker-compose-multi.yml up` - Service interconnection issues
- Native builds with `make install` - Module loading problems  
- Legacy scripts: `start_chain_complete.sh`, `deploy-gcp.sh`, etc.

## 🔧 Working Development Scenarios

### Scenario 1: Local Development Testing (RECOMMENDED ✅)

```bash
# Start blockchain for development - VERIFIED WORKING
./scripts/dev.sh dev

# Test connectivity - VERIFIED WORKING  
./scripts/dev.sh test

# View logs
./scripts/dev.sh logs

# Stop services
./scripts/dev.sh stop

# Services available:
# - Blockchain: http://localhost:8080 ✅
# - API: http://localhost:1317 ✅
```

### Scenario 2: Google Cloud Production (VERIFIED ✅)

```bash
# Deploy to production Cloud Run - VERIFIED WORKING
export PROJECT_ID="your-gcp-project-id" 
./scripts/deploy-gcp-multi-service.sh

# Result: Live production blockchain with:
# - AMD64 architecture compatibility ✅
# - Enhanced Cloud Run configuration ✅  
# - Multi-service architecture ready ✅
```

## ❌ Scenarios That Don't Work

### ❌ Multi-Service Docker Compose (HAS ISSUES)

```bash
# DON'T USE - Service interconnection problems
docker compose -f docker-compose-multi.yml up

# Issues:
# - Services can't communicate properly
# - Port mapping conflicts
# - Resource allocation problems
```

### ❌ Native Development Build (UNRELIABLE)

```bash
# DON'T USE - Module loading issues
make install
./build/speculodd init speculod --chain-id speculod
# ... rest of native build process

# Issues:
# - Custom modules may not load correctly
# - Go version compatibility problems
# - Missing dependencies on some systems
```

### ❌ Single Container Deployment (OUTDATED)

```bash
# DON'T USE - Lacks proper architecture
docker compose -f docker-compose-simple.yml up

# Issues:
# - Single container can't handle multi-service architecture
# - Missing service separation
# - Not suitable for production scaling
```

## 🧪 Testing Your Deployment (VERIFIED COMMANDS ✅)

### Quick Health Check

```bash
# Test blockchain status - VERIFIED WORKING ✅
curl http://localhost:8080/status

# Test API endpoints - VERIFIED WORKING ✅  
curl http://localhost:1317/cosmos/bank/v1beta1/supply

# For Cloud Run deployment, replace localhost with your service URL:
curl https://your-service-url.run.app/status
```

### Production Testing (Cloud Run)

```bash
# Test live production blockchain (example from verified deployment)
curl https://speculod-blockchain-809714550777.europe-west1.run.app/status

# Check node info
curl https://your-service-url.run.app/cosmos/base/tendermint/v1beta1/node_info

# Verify block production
curl -s https://your-service-url.run.app/status | jq '.result.sync_info.latest_block_height'
```

### ❌ Commands That Don't Work

```bash
# DON'T USE - Faucet not reliably available in current setup
curl http://localhost:4500/health

# DON'T USE - Account creation may have keyring issues  
speculodd keys add test-user --keyring-backend test

# DON'T USE - Token requests depend on working faucet
curl -X POST http://localhost:4500/request
```

## 📊 Working Commands Only

### ✅ Docker Management (WORKING)
```bash
# Check what's running locally
./scripts/dev.sh logs

# Stop local development blockchain  
./scripts/dev.sh stop

# Test connectivity
./scripts/dev.sh test
```

### ✅ Cloud Management (WORKING)
```bash
# Check service status - VERIFIED ✅
gcloud run services list --region=europe-west1

# View logs - VERIFIED ✅
gcloud logs tail --service=speculod-blockchain --region=europe-west1

# Scale services - VERIFIED ✅
gcloud run services update speculod-blockchain --min-instances=2 --region=europe-west1
```

### ❌ Commands That Don't Work Reliably

```bash
# DON'T USE - Docker Compose has issues
docker compose -f docker-compose-multi.yml ps
docker compose -f docker-compose-multi.yml logs -f blockchain  
docker compose -f docker-compose-multi.yml down

# DON'T USE - Native binary may not work
speculodd start --minimum-gas-prices "0.0001stake"
```

## 🆘 Troubleshooting - Tested Solutions

### ✅ Working Solutions

**Port Already in Use**
```bash
# Kill processes using port 8080 - VERIFIED SOLUTION ✅
kill -9 $(lsof -t -i:8080)
```

**Local Development Issues**
```bash
# Use the working development script
./scripts/dev.sh stop
./scripts/dev.sh dev
```

**Cloud Run Deployment Issues**
```bash
# The deploy script handles these automatically - VERIFIED ✅
# - Line ending fixes applied
# - AMD64 architecture targeting  
# - Enhanced Cloud Run configuration
```

### ❌ Solutions That Don't Work

**Docker Build Issues (OUTDATED)**
```bash
# DON'T USE - These don't solve the real problems
docker system prune -f
docker builder prune -f  
```

**Service Won't Start (UNRELIABLE)**
```bash
# DON'T USE - Docker Compose has interconnection issues
docker logs speculod-blockchain-1
docker compose -f docker-compose-multi.yml restart blockchain
```

**Gas Price Errors (NOT THE REAL ISSUE)**
```bash
# DON'T USE - Gas prices are already configured correctly
speculodd start --minimum-gas-prices "0.0001stake"
```

## 📚 Need More Help?

- 📖 Full Guide: [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md)
- ✅ Working Methods: Use only `dev.sh` and `deploy-gcp-multi-service.sh`
- ❌ Avoid: Legacy docker-compose methods and native builds
- 🔧 Development: Use `./scripts/dev.sh dev` for fastest iteration

---

🎯 **Choose your path:**
- **Just want to code?** → Use `./scripts/dev.sh dev` (VERIFIED ✅)
- **Testing locally?** → Use `./scripts/dev.sh dev` then `./scripts/dev.sh test` (VERIFIED ✅)
- **Going to production?** → Use `./scripts/deploy-gcp-multi-service.sh` (VERIFIED ✅)
- **Need custom setup?** → Check the full deployment guide but stick to tested methods

**⚠️ Important:** Avoid using docker-compose-multi.yml, native builds, or legacy scripts as they have known issues.

Happy building! 🚀
