# 🐳 Docker Files Overview - Multi-Service Architecture

## � Complete Container Architecture

The Speculod blockchain uses a **peer-to-peer multi-service architecture** with specialized containers for different blockchain functions.

```
┌─────────────────────┐    ┌─────────────────────┐    ┌─────────────────────┐
│   Dockerfile.api    │    │Dockerfile.blockchain│    │ Dockerfile.faucet   │
│                     │    │                     │    │                     │
│   REST API Node     │◄──►│  Tendermint Core    │◄───┤  Token Distribution │
│   + Full P2P Node   │    │  + Validation       │    │  + Web Interface    │
│                     │    │                     │    │                     │
│  Port: 1317:8080    │    │  Port: 26657:8080   │    │  Port: 5001:8080    │
│  Port: 26667:26657  │    │  Block Production   │    │  Flask Service      │
│  Port: 26666:26656  │    │  Genesis Creation   │    │  Health Monitoring  │
└─────────────────────┘    └─────────────────────┘    └─────────────────────┘
                                       │
                                       │
                              ┌─────────────────────┐
                              │Dockerfile.nginx-amd64│
                              │                     │
                              │  Nginx Proxy Node   │
                              │  + Multi-API Access │
                              │                     │
                              │  Port: 8080 → All   │
                              │  /rpc/* → 26657     │
                              │  /api/* → 1317      │
                              │  /grpc/* → 9090     │
                              └─────────────────────┘
```

## 🎯 Core Production Services

### 🔄 `Dockerfile.nginx-amd64` - Unified API Proxy ✅ **NEW!**
**Purpose**: Nginx reverse proxy providing unified HTTPS access to all blockchain APIs

**Features**:
- Single-port Cloud Run compatibility (8080)
- Path-based routing to multiple internal services
- AMD64 architecture compatibility for Cloud Run
- Combined nginx + speculodd in single container
- CORS headers and WebSocket support
- Python-based startup process management

**API Endpoints**:
- `/rpc/*` → Tendermint RPC (port 26657)
- `/api/*` → Cosmos REST API (port 1317)  
- `/grpc/*` → gRPC API with gRPC-Web (port 9090)

**Cloud Run URL**: https://speculo-nginx-proxy-809714550777.europe-west1.run.app

### 📡 `Dockerfile.api` - REST API Peer Node ✅
**Purpose**: Full blockchain node with REST API capabilities and peer-to-peer connectivity

**Features**:
- Complete Tendermint full node with blockchain synchronization
- Cosmos SDK REST API endpoints (`/cosmos/*`)  
- Swagger UI documentation interface
- Automatic peer discovery and connection
- Genesis file synchronization from main node
- **Bug Status**: Fixed peer address format (v1.1 ready)

**Ports**:
- `8080`: REST API endpoints (Cloud Run compatible)
- `26657`: Tendermint RPC (peer communication)
- `26656`: P2P networking (peer discovery)

**Usage**:
```bash
# Local testing
docker run -p 1317:8080 gcr.io/speculo-blockchain/speculod-api:v1

# Docker Compose
services:
  api:
    image: gcr.io/speculo-blockchain/speculod-api:v1
```

### 🏗️ `Dockerfile.blockchain` / `Dockerfile.tendermint` - Core Blockchain ✅
**Purpose**: Main Tendermint validator node with block production

**Features**:  
- Genesis account creation and validator setup
- Block production and consensus participation  
- Tendermint RPC endpoints for peer connections
- Automatic initialization with test accounts
- **Status**: Fully operational, producing blocks

**Ports**:
- `8080`: Tendermint RPC (mapped from 26657)

**Usage**:
```bash  
# Main blockchain node
docker run -p 26657:8080 gcr.io/speculo-blockchain/speculod-tendermint:v1
```

### 🚰 `Dockerfile.faucet` - Token Distribution Service ✅ 
**Purpose**: Lightweight Python Flask service for development token distribution

**Features**:
- Web interface for token requests
- REST API for programmatic access  
- Health monitoring and status endpoints
- Integration with blockchain RPC for validation
- **Status**: Ready for deployment

**Ports**:
- `8080`: Flask web service (Cloud Run compatible)

**Usage**:
```bash
# Token faucet service
docker run -p 5001:8080 gcr.io/speculo-blockchain/speculod-faucet:v2
```

## 🧪 Development & Testing Services

### 🔬 `Dockerfile.rpc` - Dedicated RPC Service  
**Purpose**: Lightweight RPC-only node for specialized use cases

**Features**:
- Minimal Tendermint RPC endpoints
- No API or web interface overhead
- Fast startup for testing scenarios

### 🧪 `Dockerfile.test` - Testing & Validation
**Purpose**: Simple HTTP server for deployment testing

**Features**:  
- Mock blockchain endpoints for connectivity testing
- Health check validation
- Cloud Run deployment verification

## 📦 Container Registry Images

### 🏷️ **Current Tags** (Google Container Registry)
```bash
# Production Ready
gcr.io/speculo-blockchain/speculod-tendermint:v1    ✅ OPERATIONAL
gcr.io/speculo-blockchain/speculod-faucet:v2        ✅ READY

# In Progress  
gcr.io/speculo-blockchain/speculod-api:v1           🔄 NEEDS REBUILD (bug fix)
```

### 🚀 **Build Commands**
```bash
# Build all services
docker build -f Dockerfile.api -t speculod-api:latest .
docker build -f Dockerfile.tendermint -t speculod-tendermint:latest .  
docker build -f Dockerfile.faucet -t speculod-faucet:latest .

# Tag for registry  
docker tag speculod-api:latest gcr.io/$PROJECT_ID/speculod-api:latest
docker tag speculod-tendermint:latest gcr.io/$PROJECT_ID/speculod-tendermint:latest
docker tag speculod-faucet:latest gcr.io/$PROJECT_ID/speculod-faucet:latest

# Push to registry
docker push gcr.io/$PROJECT_ID/speculod-api:latest
docker push gcr.io/$PROJECT_ID/speculod-tendermint:latest  
docker push gcr.io/$PROJECT_ID/speculod-faucet:latest
```

## 🔗 Service Integration

### 🐳 **Docker Compose Orchestration**
```yaml
# docker-compose-local-test.yml
services:
  tendermint:    # Main validator node
    image: gcr.io/speculo-blockchain/speculod-tendermint:v1
    ports: ["26657:8080"]
    
  api:           # Peer node with REST API  
    image: gcr.io/speculo-blockchain/speculod-api:v1
    ports: ["1317:8080", "26667:26657", "26666:26656"]
    depends_on: [tendermint]
    
  faucet:        # Token distribution  
    image: gcr.io/speculo-blockchain/speculod-faucet:v2
    ports: ["5001:8080"]  
    depends_on: [tendermint]
```

### ☁️ **Google Cloud Run Deployment**
```bash
# Deploy main blockchain
gcloud run deploy speculod-tendermint 
  --image gcr.io/$PROJECT_ID/speculod-tendermint:v1 
  --region=europe-west1

# Deploy API service  
gcloud run deploy speculod-api 
  --image gcr.io/$PROJECT_ID/speculod-api:v1 \  
  --region=europe-west1

# Deploy faucet service
gcloud run deploy speculod-faucet 
  --image gcr.io/$PROJECT_ID/speculod-faucet:v2 
  --region=europe-west1
```

## 🛠️ Development Workflow

### 🔧 **Local Testing**
```bash
# Fast development iteration
./scripts/dev.sh dev

# Full multi-service testing
docker-compose -f docker-compose-local-test.yml up -d

# View service logs
docker-compose -f docker-compose-local-test.yml logs -f [api|tendermint|faucet]
```

### 🚀 **Production Deployment**  
```bash
# Complete multi-service deployment
export PROJECT_ID="your-gcp-project-id"
./scripts/deploy-gcp-multi-service.sh
```

## ⚠️ Service Dependencies

### 📋 **Startup Order**
1. **Tendermint** (main validator) - Creates genesis and starts block production
2. **API** (peer node) - Connects to Tendermint, downloads genesis, syncs blockchain  
3. **Faucet** (token service) - Connects to blockchain for token distribution

### 🔄 **Inter-Service Communication**  
- **API → Tendermint**: P2P connection on port 26656, RPC queries on port 26657
- **Faucet → Tendermint**: HTTP requests to RPC endpoints for balance queries
- **External → Services**: REST API calls, RPC queries, faucet web interface

---

**� Summary**: The Docker architecture provides a complete peer-to-peer blockchain ecosystem with specialized services for validation, API access, and token distribution, ready for both local development and production cloud deployment.
