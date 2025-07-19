# 🐳 Speculod Blockchain - Docker Files Overview

## 📁 Core Docker Files

### `Dockerfile`
Multi-stage Docker build configuration for the Speculod blockchain:
- **Base**: Golang 1.24 Alpine for building
- **Final**: Alpine Linux with minimal runtime dependencies
- **Size**: Optimized for production deployment
- **User**: Runs as non-root `speculod` user
- **Ports**: 26656 (P2P), 26657 (RPC), 1317 (API), 9090 (gRPC)

### `docker-compose.yml`
Local development setup with Docker Compose:
- **Volumes**: Persistent blockchain data storage
- **Networks**: Isolated container network
- **Configuration**: Environment variables and port mapping

### `.dockerignore`
Optimizes Docker build by excluding unnecessary files:
- Git files, documentation, tests
- Build artifacts and IDE files
- Local development configurations

## 🚀 Deployment Scripts

### `scripts/docker-startup.sh`
Docker-optimized blockchain startup script:
- **Environment**: Configurable via environment variables
- **Initialization**: Handles fresh setup and existing chain restart
- **Networking**: Configured for containerized environment
- **Features**: Automatic genesis account creation and validator setup

### `scripts/deploy-gcp.sh`
Google Cloud Platform deployment automation:
- **Services**: Enables required GCP services
- **Build**: Builds and pushes container to GCR
- **Deploy**: Deploys to Cloud Run with optimal configuration
- **Output**: Provides service URLs and testing commands

### `scripts/test-docker.sh`
Comprehensive Docker deployment testing:
- **Build**: Tests image building process
- **Runtime**: Verifies container startup and initialization
- **APIs**: Tests all endpoint accessibility
- **Modules**: Validates custom module availability
- **Monitoring**: Provides detailed test results and logs

## ☁️ Cloud Configuration Files

### `gcp-cloudrun-service.yaml`
Google Cloud Run service configuration:
- **Resources**: 2 CPU, 4GB memory configuration
- **Scaling**: Min/max instance settings
- **Environment**: Container environment variables
- **Networking**: Port and endpoint configuration

### `k8s-deployment.yaml`
Kubernetes deployment configuration:
- **Deployment**: Pod specification with resource limits
- **Service**: LoadBalancer for external access
- **Storage**: Persistent volume claim for blockchain data
- **Health**: Liveness and readiness probes

## 📚 Documentation

### `DOCKER_DEPLOYMENT_GUIDE.md`
Comprehensive deployment guide covering:
- **Local Development**: Docker and Docker Compose usage
- **Cloud Deployment**: GCP Cloud Run and GKE options
- **Configuration**: Environment variables and port mapping
- **Testing**: Health checks and API testing
- **Troubleshooting**: Common issues and solutions
- **Production**: Security and performance considerations

## 🧪 Usage Examples

### Quick Local Test
```bash
# Build and test locally
bash scripts/test-docker.sh
```

### Docker Compose Development
```bash
# Start for development
docker-compose up -d

# View logs
docker-compose logs -f
```

### Google Cloud Deployment
```bash
# Deploy to Cloud Run
export PROJECT_ID=your-gcp-project-id
bash scripts/deploy-gcp.sh
```

## 🔧 Configuration Options

### Environment Variables
All scripts support these environment variables:
- `CHAIN_ID`: Blockchain identifier
- `MONIKER`: Node name/identifier  
- `PROJECT_ID`: GCP project ID
- `REGION`: GCP deployment region

### Resource Requirements
- **Minimum**: 2 CPU, 2GB RAM
- **Recommended**: 2 CPU, 4GB RAM
- **Storage**: 50GB for production use

## 🎯 Production Ready Features

✅ **Multi-stage builds** for optimized image size
✅ **Non-root user** for security
✅ **Health checks** for monitoring
✅ **Environment configuration** for flexibility
✅ **Persistent storage** for data retention
✅ **Load balancer support** for high availability
✅ **Auto-scaling configuration** for Cloud Run
✅ **Resource limits** for cost optimization

---

🎉 **Your Speculod blockchain is now containerized and ready for cloud deployment!**
