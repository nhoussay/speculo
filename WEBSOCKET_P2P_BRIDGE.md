# WebSocket P2P Bridge Setup

This document describes the WebSocket-to-TCP P2P bridge infrastructure that enables Tendermint P2P connections over HTTPS for Cloud Run deployment.

## Overview

The WebSocket P2P bridge solves the challenge of running P2P blockchain networks on Google Cloud Run, which only supports HTTPS traffic. The bridge translates WebSocket connections to TCP connections, allowing P2P communication over HTTPS.

## Architecture

```
Client (WebSocket) → Nginx Proxy → WebSocket Bridge → Speculod P2P (TCP:26656)
```

### Components

1. **Nginx Proxy** (`nginx-websocket.conf`)
   - Handles HTTPS termination and routing
   - Routes WebSocket connections to the bridge
   - Serves RPC, REST API, and gRPC endpoints
   - **WebSocket P2P Endpoint**: `wss://domain/` (root path)

2. **WebSocket Bridge** (`websocket-bridge-complete.py`)
   - Python asyncio server on port 8081
   - Converts WebSocket messages to TCP packets
   - Maintains bidirectional communication

3. **Speculod Blockchain Node**
   - Cosmos SDK blockchain node
   - P2P port 26656, RPC port 26657
   - REST API port 1317, gRPC port 9090

## Endpoints

| Service | Endpoint | Protocol | Description |
|---------|----------|----------|-------------|
| **P2P** | `wss://domain/` | WebSocket | Tendermint P2P over WebSocket |
| RPC | `/rpc/*` | HTTP | Tendermint RPC endpoints |
| REST API | `/cosmos/*`, `/api/*` | HTTP | Cosmos SDK REST API |
| gRPC | `/grpc/*` | HTTP/2 | gRPC services |
| Health | `/health` | HTTP | Health check endpoint |

## Usage

### Local Development

1. **Start all services**:
   ```bash
   docker-compose -f docker-compose-local-websocket-bridge.yml up -d
   ```

### Production Deployment (Google Cloud Run)

The WebSocket P2P bridge is designed to replace the existing `speculo-nginx-proxy` service on Cloud Run while maintaining domain mapping compatibility.

1. **Deploy using the automated script**:
   ```bash
   ./deploy-websocket-proxy.sh
   ```

2. **Or deploy using Cloud Build**:
   ```bash
   gcloud builds submit --config cloudbuild-websocket-proxy.yaml .
   ```

3. **Or deploy manually**:
   ```bash
   # Build and push images
   docker build -f Dockerfile.nginx -t gcr.io/speculo-blockchain/nginx-websocket:latest .
   docker build -f Dockerfile.websocket-bridge -t gcr.io/speculo-blockchain/websocket-bridge:latest .
   docker build -f Dockerfile.blockchain -t gcr.io/speculo-blockchain/speculod:latest .
   
   docker push gcr.io/speculo-blockchain/nginx-websocket:latest
   docker push gcr.io/speculo-blockchain/websocket-bridge:latest
   docker push gcr.io/speculo-blockchain/speculod:latest
   
   # Deploy to Cloud Run
   gcloud run services replace gcp-cloudrun-websocket-proxy.yaml \
       --region=europe-west1 --project=speculo-blockchain
   ```

4. **Verify deployment**:
   ```bash
   ./verify-websocket-proxy.sh
   ```

**Deployment Details**:
- **Service Name**: `speculo-nginx-proxy` (replaces existing service)
- **URL**: `https://speculo-nginx-proxy-809714550777.europe-west1.run.app`
- **Domain**: `https://persistent.specu.io` (preserved from existing mapping)
- **Multi-container**: nginx-proxy, websocket-bridge, speculod
- **Resources**: 2 CPU, 4Gi Memory total
- **WebSocket P2P**: `wss://persistent.specu.io/`

2. **Connect to P2P via WebSocket**:
   - WebSocket URL: `ws://localhost:8080/`
   - Protocol: Tendermint P2P over WebSocket

3. **Access other services**:
   - RPC: `http://localhost:8080/rpc/status`
   - REST API: `http://localhost:8080/cosmos/base/tendermint/v1beta1/node_info`
   - Health: `http://localhost:8080/health`

### Cloud Run Deployment

1. **Build and deploy** containers to Google Cloud Run
2. **Configure domain** with HTTPS certificate
3. **Connect peers** using WebSocket P2P:
   - WebSocket URL: `wss://your-domain.run.app/`
   - All P2P traffic flows through HTTPS/WebSocket tunnel

## Configuration Files

### Nginx Configuration (`nginx-websocket.conf`)

- **Root Location**: Handles both HTTP documentation and WebSocket P2P
- **WebSocket Detection**: Uses `$http_upgrade` header to route WebSocket connections
- **Named Location**: `@websocket_p2p` handles the actual WebSocket proxy
- **Error Page Trick**: Uses HTTP 418 status to route WebSocket connections

### WebSocket Bridge (`websocket-bridge-complete.py`)

- **Asyncio Server**: High-performance async WebSocket server
- **TCP Bridge**: Bidirectional message forwarding
- **Connection Management**: Tracks active connections and handles cleanup
- **Error Handling**: Graceful error handling with JSON error messages

### Docker Compose (`docker-compose-local-websocket-bridge.yml`)

- **Multi-service Setup**: Orchestrates all components
- **Health Checks**: Monitors service health
- **Network Configuration**: Proper Docker networking for service communication

## Testing

### WebSocket Connection Test
```bash
curl -H "Connection: Upgrade" -H "Upgrade: websocket" \
     -H "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==" \
     -H "Sec-WebSocket-Version: 13" \
     -i http://localhost:8080/
```

Expected response: `HTTP/1.1 101 Switching Protocols`

### Service Health Check
```bash
# Check all container status
docker-compose -f docker-compose-local-websocket-bridge.yml ps

# Check logs
docker-compose -f docker-compose-local-websocket-bridge.yml logs websocket-bridge
```

## Management

### Start Services
```bash
docker-compose -f docker-compose-local-websocket-bridge.yml up -d
```

### Stop Services
```bash
docker-compose -f docker-compose-local-websocket-bridge.yml down
```

### View Logs
```bash
# All services
docker-compose -f docker-compose-local-websocket-bridge.yml logs -f

# Specific service
docker-compose -f docker-compose-local-websocket-bridge.yml logs -f websocket-bridge
```

### Rebuild Services
```bash
# Rebuild all
docker-compose -f docker-compose-local-websocket-bridge.yml up -d --build

# Rebuild specific service
docker-compose -f docker-compose-local-websocket-bridge.yml up -d --build nginx
```

## Production Considerations

### Security
- Use HTTPS certificates for production domains
- Configure proper CORS headers if needed
- Implement rate limiting for WebSocket connections

### Monitoring
- Monitor WebSocket connection counts
- Track TCP bridge connection success rates
- Set up health check endpoints

### Scalability
- WebSocket bridge can handle multiple concurrent connections
- Consider load balancing for high-traffic scenarios
- Monitor resource usage (CPU, memory, network)

## Troubleshooting

### Common Issues

1. **WebSocket Connection Refused**
   - Check if WebSocket bridge is running and healthy
   - Verify nginx upstream configuration
   - Check Docker network connectivity

2. **TCP Connection Failed**
   - Verify Speculod node is running on port 26656
   - Check Docker service networking
   - Ensure proper container linking

3. **502 Bad Gateway**
   - Check upstream service health
   - Verify Docker container networking
   - Check nginx error logs

### Debug Commands
```bash
# Check container networking
docker exec speculod-local-websocket netstat -tlnp

# Test direct service access
curl http://localhost:26657/status

# Check WebSocket bridge logs
docker logs speculod-websocket-bridge
```

## Files Modified

- `nginx-websocket.conf` - Enhanced nginx configuration with root WebSocket handling
- `websocket-bridge-complete.py` - Python WebSocket-to-TCP bridge
- `docker-compose-local-websocket-bridge.yml` - Multi-service Docker composition
- `Dockerfile.nginx` - Nginx container with WebSocket support
- `Dockerfile.websocket-bridge` - Python WebSocket bridge container

This setup provides a complete solution for running Tendermint P2P networks over HTTPS/WebSocket, enabling deployment on platforms like Google Cloud Run that only support HTTPS traffic.
