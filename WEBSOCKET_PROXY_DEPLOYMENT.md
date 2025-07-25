# WebSocket P2P Bridge Deployment Guide

## Overview

This guide covers deploying the WebSocket P2P Bridge infrastructure to Google Cloud Run as a replacement for the existing `speculo-nginx-proxy` service. The new deployment provides WebSocket-over-HTTPS support for P2P connections, maintaining full backward compatibility with existing endpoints.

## Architecture

The deployment consists of three containers running in a single Cloud Run service:

1. **Nginx Reverse Proxy** (`nginx-websocket`)
   - Routes HTTP requests to appropriate backends
   - Handles WebSocket upgrade for P2P connections at root path
   - Provides API documentation fallback for non-WebSocket requests

2. **WebSocket Bridge** (`websocket-bridge`)
   - Converts WebSocket connections to TCP for P2P protocol
   - Handles bidirectional message forwarding
   - Manages connection lifecycle and error handling

3. **Speculod Blockchain Node** (`speculod`)
   - Full blockchain node with validator capabilities
   - Exposes RPC, API, gRPC, and P2P endpoints
   - Maintains blockchain state and participates in consensus

## Deployment Methods

### Method 1: Manual Deployment Script

```bash
# Execute the deployment script
./deploy-websocket-proxy.sh
```

This script will:
1. Build and push all Docker images
2. Deploy the multi-container service to Cloud Run
3. Verify endpoints are working
4. Display service information

### Method 2: Cloud Build Automated Deployment

```bash
# Trigger Cloud Build deployment
gcloud builds submit --config cloudbuild-websocket-proxy.yaml .
```

This provides:
- Automated build pipeline
- Parallel image building
- Deployment verification
- Build logs and monitoring

### Method 3: Direct kubectl/gcloud Deployment

```bash
# Deploy the service configuration directly
gcloud run services replace gcp-cloudrun-websocket-proxy.yaml \
    --region=europe-west1 \
    --project=speculo-blockchain
```

## Service Configuration

### Resource Allocation

- **Total Resources**: 2 CPU, 4Gi Memory
- **Nginx**: 500m CPU, 512Mi Memory
- **WebSocket Bridge**: 500m CPU, 512Mi Memory  
- **Speculod**: 1 CPU, 2Gi Memory

### Environment Variables

Key configuration variables:

```yaml
# Nginx Configuration
NGINX_HOST: "0.0.0.0"
NGINX_PORT: "80"

# WebSocket Bridge Configuration
WEBSOCKET_PORT: "8081"
TARGET_HOST: "localhost"
TARGET_PORT: "26656"

# Speculod Configuration
DEPLOYMENT_MODE: "cloud"
CHAIN_ID: "speculod"
MONIKER: "speculod-nginx-proxy"
NODE_TYPE: "persistent"
P2P_LADDR: "tcp://0.0.0.0:26656"
RPC_LADDR: "tcp://0.0.0.0:26657"
API_ADDRESS: "tcp://0.0.0.0:1317"
GRPC_ADDRESS: "0.0.0.0:9090"
```

## Endpoint Mapping

After deployment, the following endpoints will be available:

| Endpoint | Protocol | Purpose | Example |
|----------|----------|---------|---------|
| `/rpc` | HTTP/HTTPS | Tendermint RPC | `https://persistent.specu.io/rpc/status` |
| `/api` | HTTP/HTTPS | Cosmos SDK REST API | `https://persistent.specu.io/api/cosmos/base/tendermint/v1beta1/node_info` |
| `/grpc` | HTTP/2 gRPC | Cosmos SDK gRPC | `https://persistent.specu.io/grpc/` |
| `/` | WebSocket | P2P Protocol | `wss://persistent.specu.io/` |
| `/` | HTTP (fallback) | API Documentation | `https://persistent.specu.io/` |

## Domain Mapping

The service maintains the existing domain mapping:

- **Service Name**: `speculo-nginx-proxy`
- **Cloud Run URL**: `speculo-nginx-proxy-809714550777.europe-west1.run.app`
- **Custom Domain**: `persistent.specu.io`

No changes to DNS configuration are required as the service name remains the same.

## Verification Steps

### 1. Service Health Check

```bash
# Check service status
gcloud run services describe speculo-nginx-proxy \
    --region=europe-west1 \
    --project=speculo-blockchain \
    --format="value(status.conditions[0].status)"
```

### 2. Endpoint Testing

```bash
# Test RPC endpoint
curl -s https://persistent.specu.io/rpc/status | jq -r '.result.node_info.network'

# Test API endpoint  
curl -s https://persistent.specu.io/api/cosmos/base/tendermint/v1beta1/node_info | jq -r '.default_node_info.network'

# Test WebSocket P2P (using wscat)
wscat -c wss://persistent.specu.io/
```

### 3. P2P Connectivity Test

```bash
# Test P2P connection from local node
speculod tendermint show-node-id --home ~/.speculod

# Connect to the proxy
speculod start --p2p.persistent_peers="<node-id>@persistent.specu.io:443"
```

## Monitoring and Logs

### Cloud Run Logs

```bash
# View service logs
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=speculo-nginx-proxy" \
    --limit=50 \
    --format="table(timestamp,severity,textPayload)"
```

### Container-Specific Logs

```bash
# View nginx logs
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=speculo-nginx-proxy AND labels.\"k8s-pod/serving.knative.dev/configuration\"=\"speculo-nginx-proxy\" AND jsonPayload.container=\"nginx-proxy\"" \
    --limit=20

# View WebSocket bridge logs  
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=speculo-nginx-proxy AND jsonPayload.container=\"websocket-bridge\"" \
    --limit=20

# View speculod logs
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=speculo-nginx-proxy AND jsonPayload.container=\"speculod\"" \
    --limit=20
```

## Troubleshooting

### Common Issues

1. **Service Not Ready**
   - Check container logs for startup errors
   - Verify image builds completed successfully
   - Ensure resource limits are adequate

2. **WebSocket Connection Failures**
   - Verify nginx configuration for WebSocket upgrade
   - Check WebSocket bridge service health
   - Test with different WebSocket clients

3. **P2P Connection Issues**
   - Confirm blockchain node is synced
   - Check peer connectivity through RPC
   - Verify WebSocket-to-TCP bridge functionality

### Debug Commands

```bash
# Check service configuration
gcloud run services describe speculo-nginx-proxy \
    --region=europe-west1 \
    --project=speculo-blockchain

# Test internal connectivity (from Cloud Shell)
gcloud run services proxy speculo-nginx-proxy --port=8080 &
curl http://localhost:8080/rpc/status

# Monitor real-time logs
gcloud logging tail "resource.type=cloud_run_revision AND resource.labels.service_name=speculo-nginx-proxy"
```

## Rollback Procedure

If issues occur, rollback to previous revision:

```bash
# List revisions
gcloud run revisions list --service=speculo-nginx-proxy --region=europe-west1

# Rollback to previous revision
gcloud run services update-traffic speculo-nginx-proxy \
    --to-revisions=speculo-nginx-proxy-XXXX=100 \
    --region=europe-west1
```

## Security Considerations

- All communication uses HTTPS/WSS encryption
- Container runs with minimal privileges
- No persistent volumes (stateless deployment)
- Network access controlled by Cloud Run security model
- CORS enabled for web client compatibility

## Performance Optimization

- Session affinity enabled for WebSocket connections
- CPU throttling disabled for consistent performance
- Startup CPU boost for faster cold starts
- Container concurrency optimized for blockchain workload
- Resource requests/limits tuned for efficient scaling

## Migration Notes

This deployment replaces the existing `speculo-nginx-proxy` service while:
- Maintaining the same service name and URL
- Preserving domain mapping configuration
- Adding WebSocket P2P capability
- Keeping all existing HTTP endpoints functional
- No client-side changes required for existing integrations
