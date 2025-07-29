# 🧾 Speculo: Decentralized Prediction Market Blockchain

[![Docker](https://img.shields.io/badge/Docker-Multi--Service-2496ED)](https://docker.com) [![Cosmos SDK](https://img.shields.io/badge/Cosmos_SDK-v0.50-5F4B8B)](https://cosmos.network) [![Cloud Run](https://img.shields.io/badge/Google_Cloud_Run-Production-4285F4)](https://cloud.google.com/run)

A state-of-the-art blockchain built on Cosmos SDK for decentralized prediction markets with advanced P2P networking, cloud deployment capabilities, and comprehensive API services.

## 🚀 Quick Start

### Development with Starport CLI (Recommended)
```bash
# Start development blockchain with Starport
starport chain serve --reset-once -v

# APIs will be available at:
# - Blockchain API: http://localhost:1317
# - Token faucet: http://localhost:4500
```

### Local 3-Validator Mainnet (Production)
```bash
# Start the active 3-validator mainnet deployment
cd deployments/docker-compose
docker-compose -f docker-compose-all-mainnet-validators.yml up -d

# Check status
curl http://localhost:8080/rpc/status | jq '.result.sync_info'
```

### Single Node Development (Alternative)
```bash
# Start standalone development node
./scripts/local-standalone.sh start
```

## 📁 Project Structure

The project is now fully organized with the following structure:

```
speculod/
├── 📄 README.md                              # Main documentation
├── 📄 local-mainnet-genesis.json            # Active 3-validator mainnet genesis
├── 📄 COMPLETE_ORGANIZATION_SUMMARY.md      # Complete organization overview
├── 📄 DOCUMENTATION_INDEX.md               # Navigation guide
├── 
├── 📁 deployments/                          # All deployment configurations
│   ├── � docker-compose/                   # Docker Compose files (37 configs)
│   ├── 📁 docker/                           # Dockerfiles (19 containers)
│   ├── 📁 nginx/                            # Nginx configurations (4 configs)
│   ├── 📁 gcp/                              # Google Cloud Platform
│   │   ├── � cloud-run/                    # Cloud Run services
│   │   └── 📁 cloud-build/                  # Cloud Build pipelines
│   ├── 📁 kubernetes/                       # Kubernetes deployments
│   ├── 📁 supervisor/                       # Supervisor configurations
│   └── 📁 scripts/                          # Deployment scripts (10 scripts)
├── 
├── 📁 config/                               # Project configuration files
│   ├── 📄 package.json                      # Node.js dependencies
│   ├── 📄 requirements.txt                  # Python dependencies
│   ├── 📄 config.yml                        # Project configuration
│   ├── 📄 buf.yaml                          # Protobuf configuration
│   └── 📄 build.log                         # Build outputs
├── 
├── 📁 scripts/                              # Utility scripts
│   ├── 🔧 Shell scripts                      # Node management and testing (21 scripts)
│   └── 🐍 Python scripts                    # WebSocket bridges and services (5 scripts)
├── 
├── 📁 docs/                                 # Documentation
│   ├── 📁 deployment/                       # Deployment guides
│   ├── 📁 guides/                           # User guides
│   ├── 📁 status/                           # Status tracking
│   └── 📁 architecture/                     # Architecture documentation
├── 
└── 📁 networks/                            # Network configurations
    ├── 📁 mainnet/                          # Production mainnet
    └── 📁 local-testnet/                    # Local development networks
```

## 📚 Documentation

### 🎯 **Active Deployments** 
- [🎛️ 3-Validator Local Mainnet](deployments/docker-compose/docker-compose-all-mainnet-validators.yml) - **Currently Active**
- [📊 COMPLETE_ORGANIZATION_SUMMARY.md](COMPLETE_ORGANIZATION_SUMMARY.md) - Complete project organization
- [� DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md) - Navigation guide
- [� DEPLOYMENT_ARCHIVE.md](deployments/DEPLOYMENT_ARCHIVE.md) - All deployment configurations
- [⚙️ CONFIGURATION_ARCHIVE.md](CONFIGURATION_ARCHIVE.md) - Configuration files inventory

### 🛠️ **Development & Deployment**
- [🚀 Deployment Guides](docs/deployment/) - Comprehensive deployment documentation
- [🐳 Docker Configurations](deployments/docker/) - Container architecture  
- [⚡ Quick Start Scripts](scripts/) - Development and utility scripts
- [🌐 Network Configurations](networks/) - Mainnet and testnet setups

### 🔧 **Cloud & Production**
- [☁️ GCP Deployments](deployments/gcp/) - Google Cloud configurations
- [🌐 Domain Configuration](deployments/nginx/) - Nginx and proxy setups
- [🚀 Cloud Run Services](deployments/gcp/cloud-run/) - Serverless deployments
- [🧪 Testing Documentation](docs/testing.md) - Testing procedures

### � **User Guides**
- [⚡ Quick Start](docs/guides/) - Fast deployment scenarios
- [🏗️ Architecture](docs/architecture/) - System design documentation
- [� Status Tracking](docs/status/) - Implementation and deployment status

## 🌟 Current Status

### ✅ **Active: 3-Validator Local Mainnet**
- **Chain ID**: `speculod-mainnet-1`
- **Validators**: 3 (persistent-node: 1M stake, local-validator-node[1,2]: 500K stake each)
- **Status**: **🟢 PRODUCING BLOCKS**
- **Access**: http://localhost:8080/rpc/status
- **Genesis**: [local-mainnet-genesis.json](local-mainnet-genesis.json)

### ✅ **Production Ready Components**
- **Local Multi-Validator Networks**: Complete 3-validator mainnet setup
- **Google Cloud Run P2P Network**: Persistent and peer nodes with P2P-only connectivity
- **Compute Engine API Gateway**: Full-service nodes with REST, RPC, gRPC, and P2P
- **Hybrid Architecture**: Cloud Run for network consensus + Compute Engine for API services
- **GitHub-Hosted Configuration**: External genesis and peer discovery with cryptographic verification
- **Dynamic Node Discovery**: GitHub-based persistent nodes registry with automatic peer configuration
- **Service Isolation**: Proper separation between network infrastructure and API services
- **Domain Mapping**: Stable addressing via persistent.specu.io and api.specu.io
- **Complete Project Organization**: 200+ files systematically organized with comprehensive documentation

## 🛠️ Management Scripts

### Local Development
```bash
# Local standalone node
./scripts/local-standalone.sh start

# Network status monitoring
./scripts/network-status.sh

# Local mainnet management
cd deployments/docker-compose
docker-compose -f docker-compose-all-mainnet-validators.yml up -d
```

### Cloud Deployment
```bash
# Deploy to Google Cloud Run
./deployments/scripts/deploy-gcp.sh

# Deploy persistent node
./deployments/scripts/deploy-persistent-node-gcp.sh

# Nginx proxy deployment
./deployments/scripts/deploy-nginx-proxy.sh
```

### Project Organization
```bash
# Organize project files (automated)
./organize-project-enhanced.sh

# View complete organization
cat COMPLETE_ORGANIZATION_SUMMARY.md
```

## 🔧 API Endpoints

### Local Mainnet (Active)
- **RPC**: http://localhost:8080/rpc/*
- **REST API**: http://localhost:8080/api/*
- **gRPC**: localhost:9090
- **WebSocket**: ws://localhost:8080/websocket

### Production Endpoints
- **Domain**: https://persistent.specu.io
- **RPC**: https://persistent.specu.io/rpc/*
- **REST API**: https://persistent.specu.io/api/*
- **gRPC**: https://persistent.specu.io:443

## 📊 Key Features

- **🎯 Prediction Markets**: Advanced prediction market implementation
- **🌐 P2P Networking**: Robust peer-to-peer communication
- **☁️ Cloud Native**: Google Cloud Run and Compute Engine deployment
- **🐳 Containerized**: Complete Docker ecosystem
- **📡 Multi-Protocol**: RPC, REST, gRPC, and WebSocket support
- **🔒 Secure**: Cryptographic verification and secure key management
- **📈 Scalable**: Horizontal scaling with multiple validators
- **🛠️ Developer Friendly**: Comprehensive tooling and documentation

### 🔧 **Platform Constraints**
- **Google Cloud Run**: Single port limitation - P2P nodes expose only port 26656
- **Network Communication**: Cloud Run P2P nodes accessible via HTTPS (port 443) for external connections
- **API Services**: Require Compute Engine or local deployment for multi-port access
- **Hybrid Connectivity**: P2P network on Cloud Run + API services on Compute Engine/Local

### ✅ **Production Ready Components**
- **Flexible Service Deployment**: Individual Tendermint, REST API, gRPC, and Faucet services
- **P2P Network Support**: Persistent nodes and peer node connectivity
- **GitHub-Hosted Configuration**: External genesis and peer discovery with cryptographic verification
- **Dynamic Node Discovery**: GitHub-based persistent nodes registry with automatic peer configuration
- **Multi-Node Architecture**: Complete blockchain network with automatic peer discovery
- **Service Isolation**: Port-specific deployments with automatic configuration
- **Google Cloud Deployment**: European region (europe-west1) 
- **Local Development**: Fast iteration with service-specific containers
- **REST API**: Full Cosmos SDK endpoints with Swagger UI
- **Docker Architecture**: Service-aware multi-container orchestration
- **Network Bootstrap**: Industry-standard secure genesis download and validation

### ✅ **Verified Working**
- ✅ **Cloud Run P2P Network**: Persistent node at persistent.specu.io with P2P networking
- ✅ **Gas Price Configuration**: Dynamic gas price handling for all service types
- ✅ **Network Detection**: Automatic mainnet/local-testnet/testnet chain identification
- ✅ **GitHub-Hosted Genesis**: Automatic download and validation from external repository
- ✅ **Dynamic Node Discovery**: GitHub-based persistent nodes registry with fallback mechanisms
- ✅ **Hybrid Architecture**: P2P infrastructure (Cloud Run) + API services (Compute Engine)
- ✅ **Service Isolation**: P2P-only nodes vs. full-service API gateways
- ✅ **Docker Build System**: Multi-stage builds with service-aware scripts
- ✅ **Domain Mapping**: Stable addressing and external connectivity

### 🔄 **In Active Development**  
- **Multi-Port API Deployment**: Compute Engine API gateway with full service exposure
- **P2P Connection Validation**: Testing Cloud Run P2P limitations and HTTPS connectivity
- **Production Network Topology**: Validating hybrid Cloud Run + Compute Engine architectureogo=docker)](./docker-compose-local-test.yml)
[![Google Cloud](https://img.shields.io/badge/Google%20Cloud-Europe%20West1-4285F4?logo=google-cloud)](./gcp-cloudrun-tendermint.yaml)
[![Cosmos SDK](https://img.shields.io/badge/Cosmos%20SDK-v0.50+-blue?logo=cosmos)](./go.mod)
[![Status](https://img.shields.io/badge/Status-Production%20Ready-brightgreen)](./WORKING_DEPLOYMENT_STATUS.md)

## 🔷 Overview

**Speculo** is a custom blockchain built using the Cosmos SDK, designed to host decentralized prediction markets. The platform features:

- 🎯 **Prediction Markets**: Trade probabilistic positions on future outcomes  
- 🤝 **Collective Resolution**: Schelling-point-based settlement process
- 📊 **Reputation System**: Weighted consensus and governance participation
- 🏗️ **Flexible Deployment**: Service-specific deployments with P2P networking
- ☁️ **Cloud Native**: Production-ready Google Cloud Run deployment

### 🏗️ Service Architecture

**Multi-Tier Deployment Strategy:**

#### **🌐 Google Cloud Run Tier (P2P Network)**
```
┌─────────────────────────────────────────────────────────────┐
│                    Google Cloud Run                         │
│  ┌─────────────────┐    ┌─────────────────┐                │
│  │ Persistent Node │    │   Peer Node     │                │
│  │ (Bootstrap/Seed)│    │(Network Participant)            │
│  │  P2P: 26656     │    │  P2P: 26656     │                │
│  │  (Single Port)  │    │  (Single Port)  │                │
│  └─────────────────┘    └─────────────────┘                │
└─────────────────────────────────────────────────────────────┘
```

#### **💻 Compute Engine/Local Tier (Full Services)**
```
┌─────────────────────────────────────────────────────────────┐
│              Compute Engine / Local Machines               │
│  ┌─────────────────┐    ┌─────────────────┐                │
│  │   API Gateway   │    │ Development Node│                │
│  │  RPC: 26657     │    │  RPC: 26657     │                │
│  │  REST: 1317     │    │  REST: 1317     │                │
│  │  gRPC: 9090     │    │  gRPC: 9090     │                │
│  │  P2P: 26656     │    │  P2P: 26656     │                │
│  └─────────────────┘    └─────────────────┘                │
└─────────────────────────────────────────────────────────────┘
```

**Architecture Benefits:**
- **Cloud Run**: Optimized for P2P networking with automatic scaling
- **Compute Engine**: Full service exposure with multi-port support
- **Hybrid Deployment**: Network consensus (Cloud Run) + API services (Compute Engine)
- **Cost Efficiency**: Pay-per-use P2P nodes + dedicated API infrastructure

## 🚀 Quick Start Options

### ⚡ 1. Google Cloud Run Deployment (P2P Network Only)

Deploy blockchain network infrastructure with P2P connectivity using our automated scripts:

```bash
# Option A: Deploy complete network (persistent + 2 peer nodes)
./scripts/manage-cloud-run-network.sh deploy-network

# Option B: Deploy components individually
./scripts/deploy-persistent-node.sh              # Deploy persistent node + domain mapping
./scripts/deploy-peer-nodes.sh -c 3             # Deploy 3 peer nodes

# Option C: Manual deployment (advanced users)
gcloud run deploy speculo-persistent-node-1 \
  --image gcr.io/speculo-blockchain/speculod-persistent-node:latest \
  --port 26656 \
  --region europe-west1

# Check network status
./scripts/manage-cloud-run-network.sh status
```

**Cloud Run Characteristics:**
- ✅ **Single Port**: Only P2P port (26656) exposed
- ✅ **Auto-Scaling**: Serverless scaling based on network demand
- ✅ **Cost Effective**: Pay-per-use for network infrastructure
- ❌ **No API Access**: REST/RPC services not available on Cloud Run nodes

### ⚡ 2. Compute Engine/Local Deployment (Full Services)

Deploy full-service nodes with API access:

```bash
# Local development with all services
docker compose -f docker-compose-local-peer-test.yml up -d

# Services available:
# - Tendermint RPC: http://localhost:26657/status
# - REST API: http://localhost:1317/cosmos/bank/v1beta1/supply
# - gRPC: localhost:9090
# - P2P: Connected to Cloud Run persistent nodes

# Compute Engine deployment
./scripts/deploy-compute-engine-api-gateway.sh
```

**Full Service Characteristics:**
- ✅ **Multi-Port**: All blockchain services exposed
- ✅ **API Access**: REST, RPC, gRPC endpoints available
- ✅ **P2P Connectivity**: Connects to Cloud Run network infrastructure
- ✅ **Development Ready**: Full feature set for application development

### ⚡ 3. Hybrid Architecture (Recommended Production)

Combine Cloud Run P2P network with Compute Engine API services:

```bash
# 1. Deploy P2P network infrastructure on Cloud Run
./scripts/manage-cloud-run-network.sh deploy-network

# 2. Deploy API gateway on Compute Engine
./scripts/deploy-compute-engine-api.sh

# 3. Verify hybrid connectivity
./scripts/manage-cloud-run-network.sh status

# 4. Check API gateway connectivity
curl -s http://api.specu.io:26657/net_info | jq '.result.n_peers'
```

**Hybrid Benefits:**
- 🌐 **Scalable P2P**: Cloud Run handles network consensus
- 🔌 **Full API Access**: Compute Engine provides complete service endpoints
- 💰 **Cost Optimized**: Pay-per-use P2P + dedicated API infrastructure
- 🔒 **Production Ready**: Separation of concerns for security and performance

## 🛠️ Automated Deployment Scripts

### 📦 **Cloud Run Network Management**

Our automated scripts make deployment and management of the P2P network infrastructure simple and reliable:

#### **Deploy Complete Network**
```bash
# Deploy persistent node + 2 peer nodes
./scripts/manage-cloud-run-network.sh deploy-network

# Deploy with custom peer count
./scripts/manage-cloud-run-network.sh deploy-network -c 5
```

#### **Deploy Individual Components**
```bash
# Deploy only persistent node with domain mapping
./scripts/deploy-persistent-node.sh

# Deploy multiple peer nodes
./scripts/deploy-peer-nodes.sh -c 3
```

#### **Network Management**
```bash
# Check status of all nodes
./scripts/manage-cloud-run-network.sh status

# View logs for specific service
./scripts/manage-cloud-run-network.sh logs -s speculo-persistent-node-1

# Clean up all services
./scripts/manage-cloud-run-network.sh cleanup
```

**Script Features:**
- ✅ **Automated Domain Mapping**: Automatically configures persistent.specu.io
- ✅ **Environment Configuration**: Sets up GitHub network configuration
- ✅ **Health Validation**: Checks service status and blockchain activity
- ✅ **Error Handling**: Comprehensive error checking and rollback
- ✅ **Production Ready**: Optimized resource allocation and scaling

### 🌐 3. GitHub-Hosted Network Deployment (New! ✅)

Deploy a complete blockchain network using GitHub-hosted genesis and peer configuration:

```bash
# Option A: Complete multi-node network with GitHub configuration
docker-compose -f docker-compose-multi-node.yml up -d

# Option B: Pure GitHub-hosted deployment (production-ready)
docker-compose -f docker-compose-github.yml up -d

# Monitor network status
curl -s http://localhost:26657/status | jq '.result.sync_info.latest_block_height'
curl -s http://localhost:26659/status | jq '.result.sync_info.latest_block_height'

# Check P2P connectivity
curl -s http://localhost:26657/net_info | jq '.result.n_peers'
curl -s http://localhost:26659/net_info | jq '.result.n_peers'
```

**Features:**
- ✅ **Automatic Genesis Download**: Nodes download genesis from GitHub repository
- ✅ **Peer Discovery**: Dynamic peer configuration from external sources  
- ✅ **Cryptographic Verification**: SHA256 validation and JSON integrity checks
- ✅ **Production Ready**: Industry-standard external configuration hosting
- ✅ **Multi-Node P2P**: Full network topology with persistent and peer nodes

**Network Configuration:**
- **Persistent Node**: http://localhost:26657 (RPC), http://localhost:26656 (P2P)
- **Peer Node**: http://localhost:26659 (RPC), http://localhost:26658 (P2P), http://localhost:1318 (REST API)
- **Genesis Source**: https://raw.githubusercontent.com/nhoussay/speculo/main/networks/local-testnet/genesis.json
- **Peer Config**: https://raw.githubusercontent.com/nhoussay/speculo/main/networks/local-testnet/peers.json

### ⚡ 4. Full Development Environment

```bash
# Traditional full-service deployment
./scripts/dev.sh dev

# Or use Docker Compose
docker compose up -d

# Test all services  
./scripts/dev.sh test
```

### ☁️ Google Cloud Production (Verified ✅)

```bash
# 1. Set up environment
export PROJECT_ID="your-gcp-project-id"

# 2. Deploy to Europe West 1 region
./scripts/deploy-gcp-multi-service.sh

# 3. Test production deployment
curl https://your-service-url.run.app/status
```

### 🐳 Peer-to-Peer Local Testing (New! ✅)

```bash
# Start peer-to-peer architecture with 3 services
docker-compose -f docker-compose-local-test.yml up -d

# Services will be available at:
# - Tendermint: http://localhost:26657
# - API Node:   http://localhost:1317  
# - Faucet:     http://localhost:5001
```

## 📚 Documentation

### 🎯 **Production Ready**
- [📊 WORKING_DEPLOYMENT_STATUS.md](WORKING_DEPLOYMENT_STATUS.md) - Current production status
- [⚡ QUICK_START.md](QUICK_START.md) - Fast deployment scenarios  
- [✅ SUCCESS_STATUS.md](SUCCESS_STATUS.md) - Verified deployment methods

### 🛠️ **Development & Deployment**
- [� DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) - Comprehensive deployment guide
- [🐳 DOCKER_FILES_OVERVIEW.md](DOCKER_FILES_OVERVIEW.md) - Container architecture  
- [🌐 DOMAIN_SETUP_GUIDE.md](DOMAIN_SETUP_GUIDE.md) - Custom domain configuration

### 🔧 **Technical Reference**
- [🧪 docs/testing.md](docs/testing.md) - Testing procedures
- [🚀 STARTUP_GUIDE.md](STARTUP_GUIDE.md) - Manual blockchain setup

## ⚠️ Architecture Status

### ✅ **Production Ready Components**
- **Tendermint Blockchain**: Full validator node with block production
- **Google Cloud Deployment**: European region (europe-west1) 
- **Local Development**: Fast iteration with `dev.sh`
- **Peer Discovery**: Automatic P2P node connection
- **REST API**: Cosmos SDK standard endpoints
- **Docker Architecture**: Multi-service orchestration

### 🔄 **In Development**  
- **API Service Bug Fix**: Peer address format (tendermint:26656:26656 → tendermint:26656)
- **Three-Service Integration**: Final peer connection validation
- **Faucet Integration**: Token distribution service connection

### ❌ **Known Issues**
- **docker-compose-multi.yml**: Service interconnection problems (use dev.sh instead)
- **Native builds**: Module loading issues on some systems  
- **Legacy scripts**: Several outdated scripts in `/scripts/` - use only documented methods

⸻

🎯 **UI Development Guide**

This section provides all the information needed to build user interfaces without accessing blockchain code.

## 📊 Data Structures & API Endpoints

### 🔗 REST API Base URL
```
https://api.specu.io/rest/speculod/
```

### 📋 Core Data Types

#### Prediction Market
```json
{
  "id": "123",
  "question": "Will Bitcoin reach $100k by end of 2024?",
  "outcomes": ["Yes", "No"],
  "groupId": "crypto-predictions",
  "deadline": "1704067200",
  "status": "ACTIVE", // ACTIVE, CLOSED, SETTLED
  "creator": "speculo1abc...",
  "totalVolume": "1000000",
  "participantCount": 150
}
```

#### Order
```json
{
  "id": "456",
  "marketId": "123",
  "outcomeIndex": 0,
  "side": "BUY", // BUY, SELL
  "price": "0.65",
  "quantity": "100",
  "filledQuantity": "50",
  "status": "PARTIAL", // PENDING, PARTIAL, FILLED, CANCELLED
  "creator": "speculo1abc...",
  "timestamp": "1703000000"
}
```

#### Reputation Score
```json
{
  "address": "speculo1abc...",
  "groupId": "crypto-predictions",
  "score": "85",
  "votingAccuracy": "0.78",
  "totalVotes": 45
}
```

#### Settlement Data
```json
{
  "marketId": "123",
  "commitPhase": {
    "startTime": "1704067200",
    "endTime": "1704153600",
    "totalCommits": 120
  },
  "revealPhase": {
    "startTime": "1704153600",
    "endTime": "1704240000",
    "totalReveals": 115,
    "revealRate": "0.958"
  },
  "finalOutcome": {
    "outcomeIndex": 0,
    "outcome": "Yes",
    "reputationWeightedVotes": "85.5",
    "resolvedAt": "1704240000"
  }
}
```

## 🎨 User Interface Flows

### 1. Market Creation Flow
```
1. User clicks "Create Market"
2. Form fields:
   - Question (text input)
   - Outcomes (array of strings, min 2, max 10)
   - Deadline (date picker, min 24h from now)
   - Group selection (dropdown)
3. Preview market details
4. Confirm creation (requires wallet signature)
5. Success: Market appears in active markets list
```

### 2. Trading Flow
```
1. User selects market from list
2. View market details and current prices
3. Choose outcome to trade
4. Select order type:
   - Market Order (immediate execution)
   - Limit Order (set price)
5. Enter quantity
6. Preview order details
7. Confirm trade (wallet signature)
8. Order appears in order book
9. Real-time updates on fills
```

### 3. Settlement Voting Flow
```
1. Market deadline passes
2. System shows "Voting Open" status
3. User clicks "Vote" on settled market
4. Commit Phase:
   - Select outcome
   - System generates nonce
   - User confirms commitment
5. Reveal Phase (after commit deadline):
   - User reveals their vote
   - System validates commitment
6. Finalization:
   - Anyone can trigger finalization
   - Results displayed with reputation weights
```

### 4. Reputation Display
```
1. User profile shows reputation per group
2. Reputation history chart
3. Voting accuracy percentage
4. Recent voting activity
5. Reputation impact from recent settlements
```

## 🔧 API Endpoints for UI

### Prediction Module

#### Get Markets
```
GET /speculod/prediction/v1/markets
Query Parameters:
- status: ACTIVE, CLOSED, SETTLED
- groupId: string
- creator: string
- limit: number (default 100)
- offset: number (default 0)

Response:
{
  "markets": [PredictionMarket],
  "pagination": {
    "nextKey": "string",
    "total": "number"
  }
}
```

#### Get Market Details
```
GET /speculod/prediction/v1/markets/{id}

Response: PredictionMarket
```

#### Get Order Book
```
GET /speculod/prediction/v1/markets/{marketId}/outcomes/{outcomeIndex}/orderbook

Response:
{
  "marketId": "string",
  "outcomeIndex": "number",
  "buyOrders": [Order],
  "sellOrders": [Order],
  "lastPrice": "string",
  "volume24h": "string"
}
```

#### Create Market
```
POST /speculod/prediction/v1/markets
Body: {
  "question": "string",
  "outcomes": ["string"],
  "groupId": "string",
  "deadline": "string"
}
```

#### Post Order
```
POST /speculod/prediction/v1/orders
Body: {
  "marketId": "string",
  "outcomeIndex": "number",
  "side": "BUY|SELL",
  "price": "string",
  "quantity": "string"
}
```

### Settlement Module

#### Get Settlement Status
```
GET /speculod/settlement/v1/markets/{marketId}/status

Response:
{
  "marketId": "string",
  "phase": "COMMIT|REVEAL|FINALIZED",
  "commitPhase": {
    "startTime": "string",
    "endTime": "string",
    "totalCommits": "number"
  },
  "revealPhase": {
    "startTime": "string",
    "endTime": "string",
    "totalReveals": "number"
  },
  "finalOutcome": {
    "outcomeIndex": "number",
    "outcome": "string",
    "reputationWeightedVotes": "string"
  }
}
```

#### Commit Vote
```
POST /speculod/settlement/v1/commits
Body: {
  "marketId": "string",
  "commitment": "string"
}
```

#### Reveal Vote
```
POST /speculod/settlement/v1/reveals
Body: {
  "marketId": "string",
  "outcomeIndex": "number",
  "nonce": "string"
}
```

#### Finalize Outcome
```
POST /speculod/settlement/v1/finalize
Body: {
  "marketId": "string"
}
```

### Reputation Module

#### Get User Reputation
```
GET /speculod/reputation/v1/scores/{address}/groups/{groupId}

Response: ReputationScore
```

#### Get User Reputations (All Groups)
```
GET /speculod/reputation/v1/scores/{address}

Response:
{
  "scores": [ReputationScore]
}
```

## 🎯 UI Components Needed

### 1. Market List Component
- Market cards with question, outcomes, deadline, volume
- Filter by status, group, creator
- Sort by deadline, volume, participant count
- Search functionality

### 2. Market Detail Component
- Full market information
- Order book visualization
- Trading interface
- Market history chart
- Settlement status (if applicable)

### 3. Trading Interface
- Order type selector (Market/Limit)
- Price input with validation
- Quantity input with balance check
- Order preview
- Order history

### 4. Settlement Interface
- Phase indicator (Commit/Reveal/Finalized)
- Voting interface with outcome selection
- Commitment generation
- Reveal interface
- Results display with reputation weights

### 5. User Profile
- Reputation scores by group
- Voting history
- Trading history
- Reputation charts

### 6. Group Management
- Group creation
- Member invitation
- Group reputation leaderboard

## 🔄 Real-time Updates

### WebSocket Events
```
ws://api.specu.io/websocket

Events:
- market.created
- order.posted
- order.filled
- order.cancelled
- vote.committed
- vote.revealed
- outcome.finalized
- reputation.adjusted
```

### Event Payloads
```json
{
  "type": "order.posted",
  "data": {
    "order": Order,
    "marketId": "string",
    "outcomeIndex": "number"
  }
}
```

## 🎨 Design Guidelines

### Color Scheme
- Primary: #6366f1 (Indigo)
- Secondary: #10b981 (Emerald)
- Warning: #f59e0b (Amber)
- Error: #ef4444 (Red)
- Success: #22c55e (Green)

### Typography
- Headers: Inter, sans-serif
- Body: Inter, sans-serif
- Monospace: JetBrains Mono (for addresses, hashes)

### Layout
- Mobile-first responsive design
- Card-based layout for markets
- Sidebar navigation for desktop
- Bottom navigation for mobile

### Icons
- Use Heroicons or similar icon set
- Consistent icon sizing (16px, 20px, 24px)
- Color-coded icons for different states

## 🔐 Wallet Integration

### Supported Wallets
- Keplr (primary)
- Cosmostation
- Leap Wallet
- WalletConnect (future)

### Connection Flow
```
1. User clicks "Connect Wallet"
2. Show supported wallet options
3. User selects wallet
4. Wallet prompts for connection
5. Get user address and balance
6. Display connected state
7. Enable trading features
```

### Transaction Handling
```
1. User initiates action (create market, trade, vote)
2. Show transaction preview
3. Request wallet signature
4. Show pending state
5. Poll for transaction confirmation
6. Show success/error state
7. Update UI accordingly
```

⸻

📦 Core Modules

1. 🧠 prediction Module (Probabilistic Market Engine)

This module powers the creation and exchange of outcome positions through an automated order book system:

✅ Message Types (tx.proto):
	•	MsgCreateMarket
Creates a new prediction market with:
	•	question: the prediction statement.
	•	outcomes: a list of discrete outcome labels.
	•	deadline: timestamp for trading to close.
	•	group_id: identifier linking to a community group.
	•	MsgPostOrder
Posts a buy or sell order to the order book:
	•	market_id: the prediction market identifier.
	•	outcome_index: which outcome to trade.
	•	side: "BUY" or "SELL" order type.
	•	price: price per share in base tokens.
	•	quantity: number of shares to trade.
	•	creator: the order poster's address.

🧮 Market Logic:
	•	Order Book System: All trades go through a centralized order book per market-outcome pair.
	•	Automatic Matching: New orders are automatically matched against existing opposite-side orders.
	•	Partial Fills: Orders can be partially filled, with remaining quantity staying in the order book.
	•	Price-Time Priority: Orders are matched by price first, then by timestamp.
	•	No central oracle resolves the market. Instead, settlement is crowdsourced via the settlement module.
	•	Token flows and accounting are enforced with Cosmos' BankKeeper.

🗃️ State:
	•	PredictionMarket: ID, question, outcomes, creator, status, deadline.
	•	Order: market_id, outcome_index, side, price, quantity, filled_quantity, status, creator, timestamp.
	•	OrderBook: market_id, outcome_index, buy_orders, sell_orders (maintained by keeper).

🔍 Query Methods:
	•	GetOrder: Retrieve a specific order by ID.
	•	GetOrderBook: Get all orders for a market-outcome pair, separated by side.
	•	ListOrders: List all orders with optional filtering.

⚡ Order Matching Algorithm:
	1. New order is posted to the order book.
	2. System searches for matching opposite-side orders at the same or better price.
	3. Orders are matched in price-time priority order.
	4. Partial fills are processed, updating both orders' filled quantities.
	5. Completely filled orders are removed from the order book.
	6. Partially filled orders remain with updated quantities.

⸻

2. 🏛️ settlement Module (Decentralized Market Resolution Engine)

This module manages the decentralized resolution of prediction markets created in the prediction module, using a commit-reveal voting game with reputation-weighted consensus. It determines the final outcome of each prediction market after its deadline, based on the collective input of participants.

✅ Message Types (tx.proto):
	• MsgCommitVote
	  - Commits a hashed vote on a market outcome:
	    - market_id: the prediction market identifier (must exist in the prediction module)
	    - creator: the voter's address
	    - commitment: hash of (outcome + nonce)
	• MsgRevealVote
	  - Reveals the actual vote and nonce for validation:
	    - market_id, creator, vote, nonce
	• MsgFinalizeOutcome
	  - Finalizes the outcome for a market after the reveal phase or deadline expiry:
	    - market_id, creator
	  - Tallies revealed votes, weighted by user reputation (from the reputation module), and determines the consensus outcome.

🔗 **Cross-Module Integration:**
- The settlement module references and resolves markets created in the prediction module (by market_id).
- It queries the prediction module for market data (outcomes, deadline, group_id) and the reputation module for user reputation scores.
- After finalization, it can trigger reputation adjustments in the reputation module based on voting accuracy.

🔐 Game Flow:
	1. **Commit Phase:**
	   - Users submit a hash of their vote and a secret nonce (commitment) for a specific market.
	   - Commitments are stored on-chain and cannot be changed or revealed until the next phase.
	2. **Reveal Phase:**
	   - After the market deadline, users reveal their vote and nonce.
	   - The system checks that the hash of (vote + nonce) matches the original commitment.
	   - Only valid reveals are counted.
	3. **Finalize Phase:**
	   - Once all reveals are in, or after a timeout, anyone can trigger finalization.
	   - The module tallies all revealed votes, weighting each by the voter's reputation (from the reputation module, scoped to the market's group_id).
	   - The outcome with the highest total reputation-weighted votes is selected as the final outcome.
	   - Reputation scores are adjusted: users who voted with the consensus gain reputation, those who did not lose reputation, and non-revealers may be penalized.

🗃️ State:
	• Commit: user, market_id, commitment (hash)
	• Reveal: user, market_id, outcome, nonce
	• Outcome: market_id, final_outcome, resolved_at

🔍 Query Methods:
	• GetCommit: Retrieve a user's commit for a market
	• GetReveal: Retrieve a user's reveal for a market
	• GetOutcome: Retrieve the final outcome for a market
	• GetSettlementStats: Get stats on commits, reveals, and reveal rate for a market
	• GetReputationWeightedVotes: Get the reputation-weighted vote tally for a market

⚡ **State Transitions & Logic:**
- **Market Expiry:** The settlement module only allows voting on markets whose deadline (from the prediction module) has passed.
- **Validation:** All votes are validated against the set of possible outcomes for the market (from the prediction module).
- **Reputation Integration:** All vote tallies and reputation adjustments use the group_id from the market to scope reputation scores.
- **Finalization:** Once finalized, the outcome is immutable and can be used by the prediction module for payouts/settlement.

🧩 **Summary:**
- The settlement module is the decentralized oracle for prediction markets, using a transparent, on-chain, reputation-weighted commit-reveal process to resolve outcomes after market expiry.
- It is tightly integrated with both the prediction and reputation modules, ensuring trustless, community-driven market resolution and ongoing incentive alignment.

⸻

3. 🌟 reputation Module (Truth Incentivization Engine)

This module adjusts users' reputation scores based on their voting alignment with final market outcomes, creating a robust incentive system for accurate prediction market participation.

✅ Message Types (tx.proto):
	•	MsgAdjustScore
	  - Adjusts score for a user in a group, increasing or decreasing based on their voting accuracy:
	    - address: the user whose reputation is being adjusted
	    - group_id: the group context for the reputation adjustment
	    - adjustment: the amount to adjust (positive or negative integer)
	    - authority: the authorized module or governance making the adjustment
	•	MsgUpdateParams
	  - Updates module parameters (governance operation)

📈 Business Logic:
	•	**Permissioned Access:** Only authorized modules (settlement) or governance can adjust reputation scores
	•	**Group Scoping:** Reputation is isolated per group_id, enabling isolated trust contexts
	•	**Score Validation:** Minimum score enforcement (no negative scores)
	•	**Consensus Alignment:** Users who vote with the final consensus gain reputation (+1)
	•	**Penalty System:** Users who vote against consensus lose reputation (-1)
	•	**Weighted Voting:** Higher reputation = more weight in future market resolutions
	•	**On-Chain Logic:** All reputation adjustments are blockchain-native and transparent

🔧 Keeper Methods:
	•	GetReputationScore(ctx, address, groupId): Retrieves a user's reputation score for a group
	•	SetReputationScore(ctx, address, groupId, score): Stores a reputation score
	•	AdjustReputationScore(ctx, address, groupId, adjustment): Adjusts a score with validation
	•	GetAuthority(): Returns the module's authority for permission checks

🔐 Authorization System:
	•	**Authority Validation:** All reputation adjustments require proper authority verification
	•	**Module Integration:** Settlement module can trigger reputation adjustments during outcome finalization
	•	**Governance Control:** Governance can adjust reputation scores for system maintenance
	•	**Error Handling:** Comprehensive error handling for invalid adjustments and unauthorized access

🗃️ State:
	•	ReputationScore: address, group_id, score (stored as string for precision)
	•	Params: Module parameters for governance control
	•	Schema: Collections-based storage with proper indexing

🔍 Query Methods:
	•	GetReputationScore: Retrieve a user's reputation score for a group
	•	Params: Query module parameters
	•	Genesis: Export/import reputation state

⚡ **Integration Points:**
- **Settlement Module:** Queries reputation scores for vote weighting and triggers adjustments after outcome finalization
- **Prediction Module:** Can use reputation scores for market access control or fee structures
- **Governance:** Can adjust reputation parameters and scores for system maintenance

🧪 **Testing Coverage:**
- **Message Handler Tests:** Authority validation, score adjustment, error handling
- **Keeper Tests:** Score storage, retrieval, and adjustment logic
- **Integration Tests:** Cross-module reputation integration with settlement
- **Edge Cases:** Negative score protection, unauthorized access prevention

🧩 **Summary:**
- The reputation module provides the "Truth Incentivization Engine" for the prediction market ecosystem
- Users who consistently align with consensus gain reputation, creating positive feedback loops
- Users who vote against consensus lose reputation, discouraging manipulation
- Reputation scores are scoped by group, enabling isolated trust contexts for different communities
- All logic is on-chain, transparent, and permissioned for security and trust

⸻

🏗️ Technical Setup

🛠 Initial Setup Commands

cd ~
rm -rf speculod
starport scaffold chain speculod
cd speculod

# Core modules
starport scaffold module prediction
starport scaffold module settlement
starport scaffold module reputation

# State types
starport scaffold type PredictionMarket id:uint question:string outcomes:string groupId:string deadline:int64 status:string creator:string --module prediction
starport scaffold type Position marketId:uint outcomeIndex:uint amount:string user:string --module prediction
starport scaffold type Order marketId:uint outcomeIndex:uint side:string price:string quantity:string filledQuantity:string status:string creator:string --module prediction

starport scaffold type Commit marketId:uint user:string commitment:string --module settlement
starport scaffold type Reveal marketId:uint user:string outcomeIndex:uint nonce:string --module settlement
starport scaffold type Settlement marketId:uint finalOutcomeIndex:uint resolvedAt:int64 --module settlement

starport scaffold type ReputationScore address:string score:string groupId:string --module reputation

# Generate all proto types
starport generate proto-go


⸻

🔐 Design Principles
	•	✅ On-chain logic only: All admin features, market resolution, and updates are blockchain-native.
	•	✅ Email-based group onboarding: Groups are organized via email invites; token allocations occur on sign-up.
	•	✅ No fiat: Entirely token-based economy — no real money or cash equivalents.
	•	✅ Non-custodial wallet by default: Optionally extensible with custodial solutions for Web2 onboarding.
	•	✅ Minimal-tech branding: Project name is Speculo (domain: specu.io); logo is minimalistic and tech-focused.
	•	✅ Public audience: Whitepaper and documentation are intended for a broad, non-technical public audience.

⸻

📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
