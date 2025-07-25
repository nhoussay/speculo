# Block Production Setup Documentation

## Overview
This document outlines the setup and deployment of a validator service to enable block production on the Speculod blockchain network.

## Problem Analysis

### Initial Issue
The persistent node at `persistent.specu.io` was **not producing blocks** despite being accessible and serving RPC/API endpoints.

### Root Cause Discovery
1. **Missing Validator Service**: Only nginx proxy service was deployed
2. **Block Height**: Remained at `0` - no blocks were being created
3. **Network State**: Chain `speculod-local-1` lacked an active block-producing validator

### Current Status
- ✅ Domain: `persistent.specu.io` accessible
- ✅ RPC/API Endpoints: Working correctly
- ❌ Block Production: Not active (height = 0)
- ❌ Validator Service: Not deployed

## Solution Implementation

### Architecture
```
Internet → Domain (persistent.specu.io) → Nginx Proxy → Validator Service
                                      ↓
                               Block Production
```

### Components
1. **Nginx Proxy** (`speculo-nginx-proxy`): API gateway and load balancer
2. **Validator Service** (`speculod-validator`): Block-producing blockchain node
3. **Domain Mapping**: Google Cloud Run domain mapping to `persistent.specu.io`

### Deployment Process

#### 1. Validator Image Build
```bash
# Build validator Docker image
docker build -t gcr.io/speculo-blockchain/speculod-validator:latest -f Dockerfile.validator .

# Push to registry
docker push gcr.io/speculo-blockchain/speculod-validator:latest
```

#### 2. Validator Service Deployment
```bash
# Deploy validator to Cloud Run
./deploy-validator-simple.sh
```

#### 3. Network Configuration
- **Chain ID**: `speculod-local-1`
- **Consensus**: Single validator node
- **Genesis**: Auto-generated with validator key
- **Ports**: Health check on 8080, RPC on 26657, P2P on 26656

#### 4. Connection Update
```bash
# Connect nginx proxy to validator
./connect-nginx-to-validator.sh
```

## Monitoring and Verification

### Network Status Check
```bash
# Comprehensive network monitoring
./network-status.sh
```

### Block Production Verification
```bash
# Check block height
curl https://persistent.specu.io/rpc/status | jq '.result.sync_info.latest_block_height'

# Monitor block production
watch -n 5 'curl -s https://persistent.specu.io/rpc/status | jq ".result.sync_info.latest_block_height"'
```

### Health Monitoring
```bash
# Validator health
curl https://VALIDATOR_URL/health

# Validator readiness
curl https://VALIDATOR_URL/ready

# RPC status
curl https://VALIDATOR_URL/rpc/status
```

## Key Features Implemented

### Automated Deployment Scripts
- `deploy-validator-simple.sh`: Single-command validator deployment
- `network-status.sh`: Comprehensive network monitoring
- `connect-nginx-to-validator.sh`: Service connection automation
- `domain-mapping.sh`: Domain management utilities

### Docker Configuration
- **Multi-stage build**: Optimized Go compilation and runtime
- **Go Version**: 1.24.0 (latest stable)
- **Health checks**: Built-in health and readiness endpoints
- **Security**: Non-root user execution
- **Compatibility**: Latest Go version for optimal dependency resolution

### Cloud Run Integration
- **Scalability**: Min/max instances configured
- **Resources**: 2 CPU, 4GB RAM allocation
- **Timeout**: Extended to 3600s for blockchain operations
- **Health**: HTTP health checks on port 8080

## Expected Outcomes

Once deployment completes:
1. **Block Production**: Height > 0 and incrementing
2. **Validator Active**: Voting power > 0
3. **Network Health**: All endpoints responding correctly
4. **Domain Access**: `persistent.specu.io` serving live blockchain data

## Troubleshooting

### Common Issues
1. **Go Version Conflicts**: Use Go 1.22 for dependency compatibility
2. **Port Configuration**: Cloud Run requires single port (8080) for health checks
3. **Genesis Setup**: Validator must be included in genesis configuration
4. **Domain Mapping**: Use `gcloud beta` commands for domain operations

### Debug Commands
```bash
# Check Cloud Run services
gcloud run services list --region=europe-west1

# View service logs
gcloud run services logs read speculod-validator --region=europe-west1

# Test validator directly
curl https://VALIDATOR_URL/rpc/status

# Verify domain mapping
./domain-mapping.sh gcloud-status
```

## Next Steps

1. **Monitor deployment** until validator image build completes
2. **Execute deployment** using `./deploy-validator-simple.sh`
3. **Verify block production** starts within 2-3 minutes
4. **Update documentation** with final deployment details
5. **Set up monitoring** for ongoing network health

---

*Documentation created: July 25, 2025*
*Status: In Progress - Validator deployment in progress*
