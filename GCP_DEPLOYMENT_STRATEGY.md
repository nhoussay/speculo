# Google Cloud Deployment Strategy for Speculod Blockchain

## 🏗️ Architecture Overview

The Speculod blockchain is a multi-service application with the following port requirements:
- **26656**: P2P networking (peer discovery)
- **26657**: Tendermint RPC  
- **1317**: REST API
- **9090**: gRPC
- **4500**: Token Faucet
- **8080**: Main HTTP service (Cloud Run compatible)

## 🎯 Deployment Strategies

### Strategy 1: Single Service (Current - Recommended for MVP)
**Status**: ✅ Currently Implemented
- **Service**: All-in-one container
- **Ports**: Only HTTP (8080) exposed via Cloud Run
- **Internal**: All services communicate internally
- **Pros**: Simple, cost-effective, fast deployment
- **Cons**: Limited external P2P connectivity

### Strategy 2: Multi-Service Architecture (Recommended for Production)
**Status**: 🚧 Requires Implementation
- **Service 1**: Validator Node (Tendermint + Internal API)
- **Service 2**: Public API Gateway (REST + gRPC)
- **Service 3**: Faucet Service 
- **Service 4**: P2P Relay (if needed)

### Strategy 3: Hybrid GKE + Cloud Run (Advanced)
**Status**: 📋 Future Consideration
- **GKE**: For validator nodes requiring P2P networking
- **Cloud Run**: For stateless API services

## 🚀 Recommended Implementation Plan

### Phase 1: Enhanced Single Service (Immediate)
```yaml
# Current deployment works but optimize for:
- Better resource allocation
- Persistent storage for blockchain data
- Health checks and monitoring
- Multi-region deployment capability
```

### Phase 2: Multi-Service Split (Next Quarter)
```yaml
Services:
  1. speculod-validator:    # Core blockchain
     ports: [26656, 26657]  # Internal only
  
  2. speculod-api:         # Public REST/gRPC
     ports: [8080]         # HTTP for Cloud Run
     connects_to: speculod-validator:26657
  
  3. speculod-faucet:      # Token faucet
     ports: [8080]         # HTTP for Cloud Run
     connects_to: speculod-validator:26657
```

## 🛠️ Technical Solutions for Multi-Port Challenge

### Cloud Run Limitations
- **Issue**: Cloud Run only supports HTTP/HTTPS on port 8080
- **Solution**: Use internal networking + service mesh

### P2P Networking Challenge
- **Issue**: P2P port 26656 not available in serverless
- **Solutions**:
  1. **Internal P2P**: Validators communicate via internal IPs
  2. **GKE Hybrid**: Use GKE for validator, Cloud Run for API
  3. **Service Mesh**: Envoy proxy for port translation

## 📦 Implementation Details

### Current Single Service Optimization
```yaml
# Enhance gcp-cloudrun-full-configured.yaml
spec:
  template:
    metadata:
      annotations:
        run.googleapis.com/network-interfaces: '[{"network":"speculod-vpc"}]'
        run.googleapis.com/vpc-access-connector: speculod-connector
```

### Multi-Service Architecture
```yaml
# New services structure:
speculod-validator:    # Internal validator
speculod-api:         # Public REST API  
speculod-faucet:      # Token faucet
speculod-p2p-relay:   # Optional P2P gateway
```

## 🔧 Required Infrastructure

### VPC and Networking
```bash
# Create VPC for internal communication
gcloud compute networks create speculod-vpc --subnet-mode=regional
gcloud compute networks subnets create speculod-subnet \
  --network=speculod-vpc --region=europe-west1 --range=10.0.0.0/16

# VPC Connector for Cloud Run
gcloud compute networks vpc-access connectors create speculod-connector \
  --network=speculod-vpc --region=europe-west1 --range=10.1.0.0/28
```

### Storage and Persistence
```bash
# Persistent storage for blockchain data
gcloud filestore instances create speculod-data \
  --zone=europe-west1-b --tier=BASIC_HDD --file-share=name=speculod,capacity=100GB
```

### Service Discovery
```yaml
# Internal DNS for service communication
services:
  - speculod-validator.speculod.internal:26657
  - speculod-api.speculod.internal:8080
```

## 🚦 Migration Path

### Current State → Phase 1 (Week 1)
- [x] Single service working
- [ ] Add persistent storage
- [ ] Add monitoring
- [ ] Add auto-scaling

### Phase 1 → Phase 2 (Month 1-2)
- [ ] Split services
- [ ] Implement service mesh
- [ ] Add load balancing
- [ ] Multi-region deployment

## 🔍 Monitoring and Observability

### Required Monitoring
```yaml
Services:
- Cloud Monitoring: Resource utilization
- Cloud Logging: Application logs  
- Cloud Trace: Request tracing
- Custom Metrics: Blockchain height, peer count
```

### Health Checks
```yaml
Endpoints:
- /health         # Service health
- /ready          # Startup readiness
- /metrics        # Prometheus metrics
- /status         # Blockchain status
```

## 💰 Cost Optimization

### Resource Right-Sizing
```yaml
Development:  # 0.25 CPU, 512Mi RAM
Staging:      # 0.5 CPU, 1Gi RAM  
Production:   # 2 CPU, 4Gi RAM
```

### Auto-scaling Strategy
```yaml
Min instances: 1 (always-on validator)
Max instances: 3 (API services only)
Target CPU: 70%
```

## 🔐 Security Considerations

### Network Security
- VPC firewall rules for internal communication
- Cloud Armor for DDoS protection
- Identity-based access control

### Data Security
- Encrypted persistent storage
- Secret Manager for keys
- Service account with minimal permissions

## 📋 Next Actions

### Immediate (This Week)
1. ✅ Document current deployment
2. 🔄 Optimize resource allocation  
3. 📊 Add monitoring dashboards
4. 🔒 Implement security best practices

### Short-term (This Month)  
1. 🏗️ Design multi-service architecture
2. 🧪 Create staging environment
3. 🔧 Implement service splitting
4. 🌍 Multi-region capability

### Long-term (Next Quarter)
1. 📈 Advanced auto-scaling
2. 🔄 CI/CD automation
3. 🌐 CDN integration
4. 📊 Advanced analytics
