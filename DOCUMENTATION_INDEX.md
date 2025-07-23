# 📚 Speculod Documentation Index

**Complete documentation guide for the Speculod peer-to-peer blockchain architecture**

## 🎯 Quick Navigation

### 🚀 **Getting Started**
- [📖 README.md](readme.md) - Main project overview and architecture
- [⚡ QUICK_START.md](QUICK_START.md) - Fast deployment scenarios
- [✅ SUCCESS_STATUS.md](SUCCESS_STATUS.md) - Current production readiness

### 🏗️ **Architecture & Deployment**  
- [🏗️ HYBRID_ARCHITECTURE_GUIDE.md](HYBRID_ARCHITECTURE_GUIDE.md) - **NEW!** Cloud Run + Compute Engine hybrid deployment
- [📊 WORKING_DEPLOYMENT_STATUS.md](WORKING_DEPLOYMENT_STATUS.md) - Current system status
- [🚀 DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) - Comprehensive deployment guide
- [🐳 DOCKER_FILES_OVERVIEW.md](DOCKER_FILES_OVERVIEW.md) - Container architecture
- [🐛 BUG_FIX_STATUS.md](BUG_FIX_STATUS.md) - Current bug fix tracking
- [🔧 TROUBLESHOOTING_GUIDE.md](TROUBLESHOOTING_GUIDE.md) - Complete troubleshooting reference

### 🌐 **GitHub-Hosted Network Configuration** (NEW! ✅)
- [📘 GITHUB_NETWORK_DEPLOYMENT_GUIDE.md](GITHUB_NETWORK_DEPLOYMENT_GUIDE.md) - External genesis hosting
- [🔗 NETWORK_BOOTSTRAP_GUIDE.md](NETWORK_BOOTSTRAP_GUIDE.md) - Secure network bootstrapping  
- [� PERSISTENT_NODES_REGISTRY_GUIDE.md](PERSISTENT_NODES_REGISTRY_GUIDE.md) - Dynamic node discovery system
- [�📂 networks/local-testnet/](networks/local-testnet/) - Live network configuration files
- [🌐 networks/persistent-nodes.json](networks/persistent-nodes.json) - Network nodes registry
- [🎛️ SINGLE_SERVICE_DEPLOYMENT_GUIDE.md](SINGLE_SERVICE_DEPLOYMENT_GUIDE.md) - Individual service deployment
- [🌐 MULTI_NODE_DEPLOYMENT_GUIDE.md](MULTI_NODE_DEPLOYMENT_GUIDE.md) - P2P network setup

### ☁️ **Cloud & Infrastructure**
- [☁️ CLOUD_RUN_DEPLOYMENT_GUIDE.md](CLOUD_RUN_DEPLOYMENT_GUIDE.md) - **NEW!** Google Cloud Run automated deployment
- [🏗️ HYBRID_ARCHITECTURE_GUIDE.md](HYBRID_ARCHITECTURE_GUIDE.md) - Cloud Run + Compute Engine architecture
- [🌐 DOMAIN_SETUP_GUIDE.md](DOMAIN_SETUP_GUIDE.md) - Custom domain configuration
- [🐳 DOCKER_DEPLOYMENT_GUIDE.md](DOCKER_DEPLOYMENT_GUIDE.md) - Docker deployment specifics

### 🧪 **Development & Testing**
- [🧪 docs/testing.md](docs/testing.md) - Testing procedures  
- [🚀 STARTUP_GUIDE.md](STARTUP_GUIDE.md) - Manual blockchain setup
- [📝 readme_testing.md](readme_testing.md) - Testing documentation

## 🎯 Documentation by Use Case

### 👨‍💻 **Developers**
**I want to start developing on Speculod blockchain immediately**
1. [📖 README.md](readme.md) - Understand the architecture
2. [⚡ QUICK_START.md](QUICK_START.md) - Get blockchain running in 2 minutes
3. [🐳 DOCKER_FILES_OVERVIEW.md](DOCKER_FILES_OVERVIEW.md) - Understand containers
4. [🧪 docs/testing.md](docs/testing.md) - Test your changes

**Commands**:
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
