# 📚 Speculod Documentation Index

**Updated**: July 29, 2025  
**Status**: Complete Project Organization - 200+ files systematically organized

## 🚀 Quick Navigation

### 🎯 **Start Here**
- [� README.md](README.md) - Main project overview
- [🎉 COMPLETE_ORGANIZATION_SUMMARY.md](COMPLETE_ORGANIZATION_SUMMARY.md) - Complete organization overview
- [⚡ Local Mainnet Quick Start](#active-deployment) - Currently running 3-validator mainnet

### �‍♂️ **Active Deployment**
- **Current**: 3-Validator Local Mainnet (`speculod-mainnet-1`)
- **Status**: � **PRODUCING BLOCKS**
- **Access**: http://localhost:8080/rpc/status
- **Config**: [docker-compose-all-mainnet-validators.yml](deployments/docker-compose/docker-compose-all-mainnet-validators.yml)
- **Genesis**: [local-mainnet-genesis.json](local-mainnet-genesis.json)

## 📁 Organized Structure

### 📦 **Deployments** (`deployments/`)
| Category | Location | Count | Description |
|----------|----------|-------|-------------|
| Docker Compose | `deployments/docker-compose/` | 37 files | All container orchestration |
| Dockerfiles | `deployments/docker/` | 19 files | Container definitions |
| Nginx Configs | `deployments/nginx/` | 4 files | Proxy configurations |
| GCP Cloud Run | `deployments/gcp/cloud-run/` | 28 files | Serverless deployments |
| GCP Cloud Build | `deployments/gcp/cloud-build/` | 24 files | CI/CD pipelines |
| Kubernetes | `deployments/kubernetes/` | 5 files | K8s configurations |
| Supervisor | `deployments/supervisor/` | 3 files | Process management |
| Deploy Scripts | `deployments/scripts/` | 10 files | Deployment automation |

**📋 Complete Inventory**: [DEPLOYMENT_ARCHIVE.md](deployments/DEPLOYMENT_ARCHIVE.md)

### ⚙️ **Configuration** (`config/`)
| File | Purpose |
|------|---------|
| `package.json` | Node.js dependencies |
| `requirements.txt` | Python dependencies |
| `config.yml` | Project configuration |
| `buf.yaml` | Protobuf build config |
| `build.log` | Build outputs |

**📋 Complete Inventory**: [CONFIGURATION_ARCHIVE.md](CONFIGURATION_ARCHIVE.md)

### 🔧 **Scripts** (`scripts/`)
| Category | Count | Purpose |
|----------|-------|---------|
| Shell Scripts | 21 | Node management, testing, deployment |
| Python Scripts | 5 | WebSocket bridges, combined services |

**Key Scripts**:
- `local-standalone.sh` - Single node development
- `network-status.sh` - Comprehensive monitoring
- `websocket-bridge.py` - P2P over WebSocket
- `start-combined.py` - Multi-service startup

### 📚 **Documentation** (`docs/`)
| Category | Location | Content |
|----------|----------|---------|
| Deployment | `docs/deployment/` | Setup and deployment guides |
| User Guides | `docs/guides/` | How-to and tutorials |
| Architecture | `docs/architecture/` | System design docs |
| Status | `docs/status/` | Implementation tracking |

**📋 Complete Inventory**: [DOCUMENTATION_ARCHIVE.md](docs/DOCUMENTATION_ARCHIVE.md)

### 🌐 **Networks** (`networks/`)

## 🎯 Usage Scenarios

### 👨‍💻 **Local Development**
```bash
# Start local development node
./scripts/local-standalone.sh start

# Check node status
curl http://localhost:26659/status | jq '.result.node_info'
```

### 🏗️ **3-Validator Mainnet (Active)**
```bash
# Access active mainnet
curl http://localhost:8080/rpc/status | jq '.result.sync_info'

# View configuration
cat deployments/docker-compose/docker-compose-all-mainnet-validators.yml
```

### ☁️ **Cloud Deployment**
```bash
# Deploy to Google Cloud Run
./deployments/scripts/deploy-gcp.sh

# Deploy persistent node with domain
./deployments/scripts/deploy-persistent-node-gcp.sh
```

### 🔧 **Project Management**
```bash
# Organize project files
./organize-project-enhanced.sh

# View complete organization
cat COMPLETE_ORGANIZATION_SUMMARY.md

# Monitor network status
./scripts/network-status.sh
```

## 📊 Architecture Overview

### 🎯 **Core Components**
1. **Blockchain Node** - Speculod consensus engine
2. **API Services** - RPC, REST, gRPC endpoints
3. **P2P Network** - Validator communication
4. **Proxy Layer** - Nginx reverse proxy
5. **WebSocket Bridge** - P2P over WebSocket for Cloud Run

### 🌐 **Deployment Options**
- **Local Development** - Single node or multi-validator setup
- **Google Cloud Run** - Serverless blockchain services
- **Google Compute Engine** - Full VM deployment
- **Hybrid Architecture** - Combined Cloud Run + Compute Engine
- **Kubernetes** - Container orchestration

### 🔒 **Security Features**
- **Key Management** - Secure validator keys
- **Network Security** - P2P encryption
- **API Security** - CORS and proxy protection
- **Domain Security** - HTTPS with custom domains

## 🚀 Getting Started

### 1️⃣ **Quick Start (2 minutes)**
```bash
# Clone repository
git clone https://github.com/nhoussay/speculo.git
cd speculo

# Start local node
./scripts/local-standalone.sh start

# Check status
curl http://localhost:26659/status
```

### 2️⃣ **Multi-Validator Setup (5 minutes)**
```bash
# Start 3-validator mainnet
cd deployments/docker-compose
docker-compose -f docker-compose-all-mainnet-validators.yml up -d

# Monitor status
curl http://localhost:8080/rpc/status | jq '.result.sync_info'
```

### 3️⃣ **Cloud Deployment (10 minutes)**
```bash
# Configure Google Cloud
gcloud auth login
gcloud config set project YOUR_PROJECT_ID

# Deploy to Cloud Run
./deployments/scripts/deploy-gcp.sh
```

## 📞 Support

### 📋 **Documentation Links**
- [Complete Organization](COMPLETE_ORGANIZATION_SUMMARY.md) - Full project overview
- [Deployment Archive](deployments/DEPLOYMENT_ARCHIVE.md) - All deployment configs
- [Configuration Archive](CONFIGURATION_ARCHIVE.md) - All config files
- [Documentation Archive](docs/DOCUMENTATION_ARCHIVE.md) - All documentation

### 🛠️ **Troubleshooting**
- Check active deployment: `docker-compose ps`
- View logs: `docker-compose logs -f`
- Monitor network: `./scripts/network-status.sh`
- Restart services: `docker-compose restart`

### 🎯 **Key Endpoints**
- **Local RPC**: http://localhost:26659/status
- **Mainnet RPC**: http://localhost:8080/rpc/status
- **Local API**: http://localhost:1318/cosmos/base/tendermint/v1beta1/node_info
- **Mainnet API**: http://localhost:8080/api/cosmos/base/tendermint/v1beta1/node_info

---

*This documentation index provides complete navigation for the Speculod blockchain project with its 200+ organized files and active 3-validator mainnet deployment.*
```bash
./scripts/dev.sh dev     # Start blockchain
./scripts/dev.sh test    # Test connectivity
```

### 🚀 **DevOps/Deployment**
**I want to deploy Speculod to production**
1. [📊 WORKING_DEPLOYMENT_STATUS.md](WORKING_DEPLOYMENT_STATUS.md) - Check readiness
2. [🚀 DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) - Full deployment guide  
3. [✅ SUCCESS_STATUS.md](SUCCESS_STATUS.md) - Validate success
4. [🌐 DOMAIN_SETUP_GUIDE.md](DOMAIN_SETUP_GUIDE.md) - Configure domains

**Commands**:
```bash
export PROJECT_ID="your-gcp-project-id"
./scripts/deploy-gcp-multi-service.sh
```

### � **Problem Solving**
**I'm having deployment or build issues**
1. [🔧 TROUBLESHOOTING_GUIDE.md](TROUBLESHOOTING_GUIDE.md) - Complete issue resolution
2. [🐛 BUG_FIX_STATUS.md](BUG_FIX_STATUS.md) - Current known issues
3. [📊 WORKING_DEPLOYMENT_STATUS.md](WORKING_DEPLOYMENT_STATUS.md) - System status

**Common Issues**:
- Google Cloud Build failures
- Docker file inclusion problems  
- Missing source directories
- Image caching issues

### �🐳 **Docker/Container Focus**
**I want to understand the container architecture**
1. [🐳 DOCKER_FILES_OVERVIEW.md](DOCKER_FILES_OVERVIEW.md) - Complete container guide
2. [🐳 DOCKER_DEPLOYMENT_GUIDE.md](DOCKER_DEPLOYMENT_GUIDE.md) - Docker deployment
3. [🐛 BUG_FIX_STATUS.md](BUG_FIX_STATUS.md) - Current container issues

**Commands**:
```bash
docker-compose -f docker-compose-local-test.yml up -d
```

### 🧪 **Testing/QA**
**I want to test and validate the blockchain**
1. [🧪 docs/testing.md](docs/testing.md) - Testing procedures
2. [📝 readme_testing.md](readme_testing.md) - Testing documentation
3. [✅ SUCCESS_STATUS.md](SUCCESS_STATUS.md) - Success validation

## 🏗️ Architecture Documentation

### 📋 **System Architecture**
```
┌─────────────────────┐    ┌─────────────────────┐    ┌─────────────────────┐
│   Documentation     │    │   Implementation    │    │    Validation       │
│                     │    │                     │    │                     │
│  📖 README.md       │    │  🐳 Dockerfile.api  │    │  ✅ SUCCESS_STATUS  │
│  ⚡ QUICK_START     │◄──►│  🏗️ docker-compose  │◄──►│  🧪 testing.md     │
│  🚀 DEPLOYMENT      │    │  ☁️ gcp-cloudrun    │    │  📊 WORKING_STATUS  │
│  🐳 DOCKER_FILES    │    │  🔧 scripts/*.sh    │    │  🐛 BUG_FIX_STATUS  │
└─────────────────────┘    └─────────────────────┘    └─────────────────────┘
```

### 🔄 **Documentation Flow**
1. **Planning**: Start with `README.md` for overview
2. **Quick Start**: Use `QUICK_START.md` for immediate deployment  
3. **Deep Dive**: Read `DEPLOYMENT_GUIDE.md` for comprehensive setup
4. **Containers**: Understand `DOCKER_FILES_OVERVIEW.md` for architecture
5. **Status**: Check `WORKING_DEPLOYMENT_STATUS.md` for current state
6. **Validation**: Use `SUCCESS_STATUS.md` to confirm deployment
7. **Issues**: Track `BUG_FIX_STATUS.md` for current problems

## 🎯 Current Priority Documents

### 🔥 **High Priority** (Active Development)
1. [🐛 BUG_FIX_STATUS.md](BUG_FIX_STATUS.md) - Critical API peer connection fix
2. [📊 WORKING_DEPLOYMENT_STATUS.md](WORKING_DEPLOYMENT_STATUS.md) - Current architecture status
3. [🐳 DOCKER_FILES_OVERVIEW.md](DOCKER_FILES_OVERVIEW.md) - Updated container architecture

### ✅ **Stable & Complete** (Production Ready)
1. [📖 README.md](readme.md) - Main project documentation
2. [⚡ QUICK_START.md](QUICK_START.md) - Fast deployment guide
3. [🚀 DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) - Comprehensive deployment
4. [✅ SUCCESS_STATUS.md](SUCCESS_STATUS.md) - Production readiness

## 📈 Documentation Maturity

### 🌟 **Excellent** (Comprehensive & Current)
- `README.md` - Complete architecture overview
- `QUICK_START.md` - Peer-to-peer deployment guide  
- `WORKING_DEPLOYMENT_STATUS.md` - Current system state
- `DOCKER_FILES_OVERVIEW.md` - Container architecture
- `BUG_FIX_STATUS.md` - Current issue tracking

### ✅ **Good** (Functional & Accurate)
- `DEPLOYMENT_GUIDE.md` - Detailed deployment instructions
- `SUCCESS_STATUS.md` - Production validation
- `docs/testing.md` - Testing procedures

### 🔄 **Stable** (Legacy but Functional)  
- `STARTUP_GUIDE.md` - Manual setup procedures
- `DOCKER_DEPLOYMENT_GUIDE.md` - Docker specifics
- `readme_testing.md` - Testing documentation

---

**🎯 Best Practice**: Start with `README.md` for overview, then use `QUICK_START.md` for immediate deployment. Refer to `WORKING_DEPLOYMENT_STATUS.md` for current system status and `BUG_FIX_STATUS.md` for any active issues.
