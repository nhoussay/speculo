# Local Persistent Node Deployment Guide

## Overview

This guide provides a complete local blockchain deployment with:
- **Persistent Validator Node**: Block-producing blockchain node with data persistence
- **Nginx Reverse Proxy**: Load balancer and API gateway
- **WebSocket Bridge**: WebSocket-to-P2P tunnel for modern client connections
- **Faucet Service**: Token distribution for testing

## Quick Start

### 1. Deploy Everything
```bash
./deploy-local-persistent.sh
```

### 2. Monitor the Deployment
```bash
# Watch logs
docker-compose -f docker-compose-local-persistent-proxy.yml logs -f

# Check status
./deploy-local-persistent.sh status
```

### 3. Test Endpoints
```bash
# Check if blocks are being produced
curl http://localhost/rpc/status | jq '.result.sync_info.latest_block_height'

# Get node info
curl http://localhost/api/cosmos/base/tendermint/v1beta1/node_info | jq
```

## Architecture

```
Internet/Clients
       ↓
   Nginx Proxy (localhost:80)
       ↓
┌──────────────────────────────┐
│  Speculod Validator Node     │
│  - RPC: localhost:26657      │
│  - API: localhost:1317       │
│  - gRPC: localhost:9090      │
│  - P2P: localhost:26656      │
└──────────────────────────────┘
       ↑
WebSocket Bridge (localhost:8081)
       ↑
  WebSocket Clients
```

## Available Endpoints

### Direct Node Access
- **RPC**: `http://localhost:26657`
- **API**: `http://localhost:1317`
- **gRPC**: `localhost:9090`
- **P2P**: `localhost:26656`

### Via Reverse Proxy
- **RPC**: `http://localhost/rpc`
- **API**: `http://localhost/api`
- **gRPC**: `http://localhost/grpc`

### Additional Services
- **WebSocket**: `ws://localhost:8081`
- **Faucet**: `http://localhost:8000`
- **Health Check**: `http://localhost:8080/health`

## Features

### 🔥 Block Production
- **Chain ID**: `speculod-local-1`
- **Consensus**: Single validator (for local development)
- **Block Time**: ~5 seconds
- **Persistence**: Data stored in Docker volume

### 🌐 Reverse Proxy
- **Load Balancing**: Nginx with upstream configuration
- **Health Checks**: Automatic failover (if multiple nodes)
- **WebSocket Support**: Upgrade headers for WS connections
- **Static Serving**: Additional static content support

### 🔌 WebSocket Bridge
- **Bidirectional**: TCP ↔ WebSocket conversion
- **P2P Integration**: Direct connection to node's P2P port
- **Modern Clients**: Support for browser-based applications
- **Health Monitoring**: Built-in health checks

### 💰 Faucet Service
- **Token Distribution**: Automated token dispensing
- **Rate Limiting**: Protection against abuse
- **Multiple Formats**: Support for different address formats
- **Integration**: Direct connection to local node

## Management Commands

### Service Control
```bash
# Start services
./deploy-local-persistent.sh start

# Stop services
./deploy-local-persistent.sh stop

# Restart services
./deploy-local-persistent.sh restart

# Clean up
./deploy-local-persistent.sh clean
```

### Monitoring
```bash
# Show logs
./deploy-local-persistent.sh logs

# Check network status
./deploy-local-persistent.sh status

# Test all endpoints
./deploy-local-persistent.sh test
```

### Direct Docker Commands
```bash
# View running containers
docker ps

# Individual service logs
docker logs speculod-local-validator
docker logs speculod-local-proxy
docker logs speculod-websocket-bridge
docker logs speculod-local-faucet

# Execute commands in validator container
docker exec -it speculod-local-validator speculodd status
```

## Configuration

### Environment Variables
The setup uses environment variables for configuration:

**Validator Node**:
- `CHAIN_ID=speculod-local-1`
- `MONIKER=local-persistent-validator`
- `VALIDATOR_KEY_NAME=validator`
- `ENABLE_VALIDATOR=true`

**Proxy Settings**:
- `BACKEND_HOST=speculod-validator`
- `NGINX_WORKER_PROCESSES=2`

**WebSocket Bridge**:
- `WS_PORT=8081`
- `TARGET_HOST=speculod-validator`
- `TARGET_PORT=26656`

### Volumes
- `local_validator_data`: Persistent blockchain data
- Configuration files mounted from `./config`
- Scripts mounted from `./scripts`

## Troubleshooting

### Common Issues

#### Services Not Starting
```bash
# Check Docker is running
docker --version

# Check for port conflicts
netstat -tlnp | grep -E ':(80|443|26656|26657|1317|9090|8080|8081|8082|8000)\s'

# View detailed logs
docker-compose -f docker-compose-local-persistent-proxy.yml logs
```

#### Blocks Not Producing
```bash
# Check validator status
curl http://localhost:26657/status | jq '.result.sync_info'

# Check validator logs
docker logs speculod-local-validator

# Verify genesis configuration
docker exec speculod-local-validator cat /home/speculod/.speculod/config/genesis.json | jq '.validators'
```

#### Proxy Not Working
```bash
# Test proxy health
curl http://localhost:8090/health

# Check nginx logs
docker logs speculod-local-proxy

# Test direct backend connection
curl http://localhost:26657/status
```

#### WebSocket Issues
```bash
# Test WebSocket bridge
curl http://localhost:8082/health

# Check bridge logs
docker logs speculod-websocket-bridge

# Test with wscat (install with: npm install -g wscat)
wscat -c ws://localhost:8081
```

### Health Checks
Each service includes health checks:
```bash
# Validator health
curl http://localhost:8080/health

# Proxy health
curl http://localhost:8090/health

# WebSocket bridge health
curl http://localhost:8082/health

# Faucet health
curl http://localhost:8000/health
```

### Performance Tuning

#### For Development
- Services configured for quick startup
- Minimal resource usage
- Detailed logging enabled

#### For Production
Consider adjusting:
- `NGINX_WORKER_PROCESSES` based on CPU cores
- Validator pruning settings
- Resource limits in docker-compose
- Log levels to reduce verbosity

## Integration Examples

### Client Applications
```javascript
// RPC client
const rpc = new WebSocket('ws://localhost:8081');

// REST API client
fetch('http://localhost/api/cosmos/base/tendermint/v1beta1/node_info')
  .then(response => response.json())
  .then(data => console.log(data));

// Direct gRPC (requires grpc-web)
const client = new QueryClient('http://localhost/grpc');
```

### Faucet Usage
```bash
# Request tokens
curl -X POST http://localhost:8000/faucet \
  -H "Content-Type: application/json" \
  -d '{"address": "speculo1...", "amount": "1000000"}'
```

## Security Notes

### Local Development Only
This setup is designed for local development and testing:
- No TLS/SSL certificates
- Permissive CORS settings
- Default keys and passwords
- All services on localhost

### Production Considerations
For production deployment:
- Enable TLS with proper certificates
- Configure firewall rules
- Use secure key management
- Enable authentication where needed
- Set resource limits
- Configure monitoring and alerting

---

**Created**: July 25, 2025
**Version**: 1.0
**Status**: Ready for local deployment
