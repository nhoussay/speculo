# Dual Node Blockchain Network Setup

## Overview

This setup creates two identical blockchain validator nodes that connect to each other on the same network. Both nodes have the same capabilities and configuration, making them perfect for testing peer-to-peer connectivity and preparing for production deployments.

## Architecture

```
┌─────────────────┐         ┌─────────────────┐
│   Node 1        │◄──────► │   Node 2        │
│ speculod-node1  │         │ speculod-node2  │
│                 │         │                 │
│ Ports:          │         │ Ports:          │
│ - 26656: P2P    │         │ - 26666: P2P    │
│ - 26657: RPC    │         │ - 26667: RPC    │
│ - 1317: REST    │         │ - 1327: REST    │
│ - 9090: gRPC    │         │ - 9091: gRPC    │
│ - 8080: Custom  │         │ - 8081: Custom  │
└─────────────────┘         └─────────────────┘
```

## Features

- **Identical Configuration**: Both nodes use the same GitHub-hosted genesis and configuration
- **Peer-to-Peer Connection**: Nodes automatically discover and connect to each other
- **Full Validator Capabilities**: Each node can validate transactions and produce blocks
- **Health Monitoring**: Docker health checks ensure nodes are operational
- **Production Ready**: Uses remote configuration suitable for cloud deployment

## Configuration Files

### docker-compose-dual-nodes.yml
The main orchestration file that defines both nodes with their networking and dependencies.

### blockchain-service-github.sh
Startup script that:
- Downloads genesis.json from GitHub
- Configures peer connections
- Sets up blockchain parameters
- Starts the validator node

## Environment Variables

Both nodes share these base configuration variables:

- `SERVICE_TYPE=all`: Full blockchain service with all components
- `NODE_TYPE=validator`: Node acts as a validator
- `CHAIN_ID=speculod-local-1`: Blockchain network identifier
- `GITHUB_REPO=nhoussay/speculo`: Remote configuration source
- `GITHUB_BRANCH=main`: Branch to use for configuration
- `NETWORK_NAME=local-testnet`: Network configuration set

### Node-Specific Variables

**Node 1:**
- `MONIKER=speculod-node1`
- `PEER_NODE_HOST=node2`

**Node 2:**
- `MONIKER=speculod-node2`
- `PEER_NODE_HOST=node1`

## Usage

### Starting the Network

```bash
docker-compose -f docker-compose-dual-nodes.yml up -d
```

### Checking Node Status

```bash
# Check both containers
docker ps | grep speculod

# Check Node 1 status
curl -s localhost:26657/status | jq '{moniker: .result.node_info.moniker, chain_id: .result.node_info.network, height: .result.sync_info.latest_block_height}'

# Check Node 2 status  
curl -s localhost:26667/status | jq '{moniker: .result.node_info.moniker, chain_id: .result.node_info.network, height: .result.sync_info.latest_block_height}'
```

### Checking Peer Connections

```bash
# Check Node 1 peers
curl -s localhost:26657/net_info | jq '{n_peers: .result.n_peers, peers: [.result.peers[]?.node_info.moniker]}'

# Check Node 2 peers
curl -s localhost:26667/net_info | jq '{n_peers: .result.n_peers, peers: [.result.peers[]?.node_info.moniker]}'
```

### Stopping the Network

```bash
docker-compose -f docker-compose-dual-nodes.yml down
```

## Network Access

### Node 1 Endpoints
- **RPC**: http://localhost:26657
- **REST API**: http://localhost:1317
- **gRPC**: localhost:9090
- **Custom API**: http://localhost:8080

### Node 2 Endpoints
- **RPC**: http://localhost:26667
- **REST API**: http://localhost:1327
- **gRPC**: localhost:9091
- **Custom API**: http://localhost:8081

## Development and Testing

This setup is ideal for:

1. **P2P Testing**: Verify peer discovery and communication
2. **Consensus Testing**: Test block production and validation across nodes
3. **Load Balancing**: Distribute requests across multiple nodes
4. **Failover Testing**: Test network resilience when one node goes down
5. **Production Preparation**: Validate configurations before cloud deployment

## Next Steps

- Add nginx reverse proxy for load balancing
- Implement WebSocket tunneling for real-time updates
- Add monitoring and logging
- Configure SSL/TLS for production use
- Set up automated deployment scripts

## Troubleshooting

### Peer Connection Issues
- Check that both nodes are healthy: `docker ps`
- Verify network connectivity: `docker network ls`
- Check logs: `docker logs speculod-node1` / `docker logs speculod-node2`

### Chain ID Mismatches
- Ensure both nodes download the same genesis file
- Clear volumes if needed: `docker volume rm speculod_node1_data speculod_node2_data`

### Port Conflicts
- Verify no other services are using the mapped ports
- Check port availability: `netstat -tulpn | grep :26657`
