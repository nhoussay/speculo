# Speculod Nginx Reverse Proxy Solution

## Overview

This solution uses **nginx as a reverse proxy** to expose multiple blockchain services through a single HTTPS port (443) on Google Cloud Run. This solves the fundamental limitation where Cloud Run only exposes one port per service.

## Architecture

```
Internet → Cloud Run (Port 443) → Nginx Proxy → Multiple Internal Services
                                                  ├── RPC (26657)
                                                  ├── REST API (1317) 
                                                  ├── gRPC (9090)
                                                  └── P2P (26656)
```

## Service Endpoints

Once deployed, the following endpoints will be available:

### Health & Status
- `https://your-domain.com/health` - Health check
- `https://your-domain.com/status` - Blockchain status (RPC)
- `https://your-domain.com/` - API documentation

### RPC Endpoints (Tendermint)
- `https://your-domain.com/rpc/status` - Prefixed RPC access
- `https://your-domain.com/status` - Direct RPC access
- `https://your-domain.com/genesis` - Genesis file
- `https://your-domain.com/validators` - Validator set
- `https://your-domain.com/block` - Latest block

### REST API Endpoints (Cosmos SDK)
- `https://your-domain.com/api/cosmos/bank/v1beta1/supply` - Prefixed API access
- `https://your-domain.com/cosmos/bank/v1beta1/supply` - Direct API access
- `https://your-domain.com/cosmos/staking/v1beta1/validators` - Validators
- `https://your-domain.com/ibc/` - IBC endpoints
- `https://your-domain.com/speculod/` - Custom module endpoints

### gRPC Endpoints
- `https://your-domain.com/grpc/` - gRPC-Web access

## Benefits

1. **Single Port Deployment**: Works within Cloud Run's single port limitation
2. **Multiple Services**: Exposes RPC, REST API, and gRPC through one endpoint
3. **HTTPS Termination**: SSL handled by Cloud Run
4. **Path-based Routing**: Clean URLs for different services
5. **CORS Support**: Enabled for web applications
6. **Health Checks**: Built-in monitoring endpoints

## Implementation Files

### Core Files
- `nginx.conf` - Nginx reverse proxy configuration
- `Dockerfile.nginx` - Multi-stage Docker build
- `scripts/blockchain-service-nginx.sh` - Blockchain service script
- `docker-compose-nginx-proxy.yml` - Local testing
- `scripts/deploy-nginx-proxy.sh` - Cloud Run deployment

### Deployment
```bash
# Local testing
docker compose -f docker-compose-nginx-proxy.yml up -d

# Cloud Run deployment
./scripts/deploy-nginx-proxy.sh
```

## Technical Details

### Nginx Configuration Highlights

1. **Upstream Servers**: Configured for each service type
   ```nginx
   upstream rpc_backend {
       server localhost:26657;
   }
   upstream api_backend {
       server localhost:1317;
   }
   ```

2. **Path-based Routing**: Routes requests based on URL paths
   ```nginx
   location /rpc/ {
       proxy_pass http://rpc_backend/;
   }
   location /cosmos/ {
       proxy_pass http://api_backend$uri$is_args$args;
   }
   ```

3. **CORS Headers**: Enabled for web application access
4. **WebSocket Support**: For RPC subscriptions
5. **Health Checks**: Multiple endpoints for monitoring

### Process Management

Uses **supervisor** to manage multiple processes:
- `speculodd` - Blockchain service with all APIs enabled
- `nginx` - Reverse proxy server

## Usage Examples

### RPC Queries
```bash
# Node status
curl https://nginx-proxy.specu.io/status

# Latest block
curl https://nginx-proxy.specu.io/block

# Prefixed access
curl https://nginx-proxy.specu.io/rpc/status
```

### REST API Queries
```bash
# Token supply
curl https://nginx-proxy.specu.io/cosmos/bank/v1beta1/supply

# Validators
curl https://nginx-proxy.specu.io/cosmos/staking/v1beta1/validators

# Prefixed access
curl https://nginx-proxy.specu.io/api/cosmos/bank/v1beta1/supply
```

### Health Monitoring
```bash
# Health check
curl https://nginx-proxy.specu.io/health

# Service documentation
curl https://nginx-proxy.specu.io/
```

## Advantages over Peer Node Approach

1. **No Genesis Issues**: Runs as persistent node, no complex peer synchronization
2. **All Services Available**: RPC, REST, gRPC all accessible via HTTPS
3. **Simple Architecture**: Single container, well-understood nginx proxy pattern
4. **Cloud Run Optimized**: Works within platform constraints
5. **Scalable**: Can handle multiple concurrent requests
6. **Monitoring Ready**: Built-in health checks and status endpoints

## Next Steps

1. **Deploy to Production**: Use the deployment script for Cloud Run
2. **Domain Configuration**: Set up DNS for your chosen domain
3. **Monitoring Setup**: Configure alerting on health endpoints
4. **Load Testing**: Verify performance under load
5. **Documentation**: Update application docs with new endpoints

This approach provides a robust, scalable solution for exposing all blockchain services through a single HTTPS endpoint, solving the Cloud Run port limitation while maintaining full API access.
