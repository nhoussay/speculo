# Multi-Node Deployment Guide with Persistent Peers

This guide explains how to deploy multiple Speculod nodes with proper P2P connectivity using persistent peers.

## Node Types

### 1. Standalone Node
**Use Case**: Single-node development, testing, or isolated deployments
- Runs independently without connecting to other nodes
- Default configuration for local development

### 2. Persistent Node (Seed/Bootstrap Node)
**Use Case**: Network bootstrap node that other nodes connect to
- Acts as a seed node for network discovery
- Higher peer connection limits
- Should have a stable, publicly accessible address
- Other nodes connect to this node to join the network

### 3. Peer Node
**Use Case**: Regular network participant that connects to persistent peers
- Connects to one or more persistent nodes to join the network
- Can provide services (REST API, gRPC) while participating in consensus
- Discovers other peers through the persistent nodes

## Configuration Variables

### Node Type Configuration
```bash
NODE_TYPE=standalone|persistent|peer   # Node behavior
SERVICE_TYPE=tendermint|rest-api|grpc|all   # Exposed services
```

### P2P Configuration
```bash
P2P_LADDR="tcp://0.0.0.0:26656"        # P2P listen address
RPC_LADDR="tcp://0.0.0.0:26657"        # RPC listen address
PERSISTENT_PEERS="node_id@ip:port,..."  # Persistent peer connections
SEEDS="node_id@ip:port,..."             # Seed node addresses
EXTERNAL_ADDRESS="tcp://public-ip:port" # Public address for other nodes
MAX_NUM_INBOUND_PEERS=40                # Max incoming connections
MAX_NUM_OUTBOUND_PEERS=10               # Max outgoing connections
```

## Deployment Examples

### 1. Deploy Persistent Node (Bootstrap)

```bash
# Start persistent node
docker compose -f docker-compose-persistent-node.yml up -d

# Wait for node to start
sleep 15

# Get the node ID for peer configuration
./scripts/get-node-id.sh speculod-persistent-node-1 26657
```

**Output Example:**
```
Node ID: 1a2b3c4d5e6f7890abcdef1234567890
Persistent peer string: 1a2b3c4d5e6f7890abcdef1234567890@localhost:26656
For Docker Compose networks: 1a2b3c4d5e6f7890abcdef1234567890@persistent-node:26656
```

### 2. Deploy Peer Nodes

**Method 1: Update Docker Compose with Node ID**
```bash
# Edit docker-compose-peer-nodes.yml and replace:
# - PERSISTENT_PEERS=node_id@persistent-node:26656
# with the actual node ID from step 1:
# - PERSISTENT_PEERS=1a2b3c4d5e6f7890abcdef1234567890@persistent-node:26656

# Then start peer nodes
docker compose -f docker-compose-peer-nodes.yml up -d
```

**Method 2: Using Environment Variables**
```bash
export NODE_ID="1a2b3c4d5e6f7890abcdef1234567890"
export PERSISTENT_PEERS="$NODE_ID@persistent-node:26656"

# Start peer node with environment variable
docker run -d \
  --name peer-node-1 \
  --network speculod_speculod-network \
  -p 26658:26656 -p 26659:26657 -p 1318:8080 \
  -e SERVICE_TYPE=all \
  -e NODE_TYPE=peer \
  -e PERSISTENT_PEERS="$PERSISTENT_PEERS" \
  -e CHAIN_ID=speculod \
  -e MONIKER=peer-node-1 \
  speculod-blockchain
```

### 3. Multi-Service Architecture

**Persistent Node (RPC Only)**
```bash
# Persistent node focusing on P2P and RPC
docker compose -f docker-compose-persistent-node.yml up -d
```

**API Node (REST + gRPC)**
```bash
# Separate node for API services
docker run -d \
  --name api-node \
  --network speculod_speculod-network \
  -p 1317:8080 -p 9090:9090 \
  -e SERVICE_TYPE=all \
  -e NODE_TYPE=peer \
  -e PERSISTENT_PEERS="$NODE_ID@persistent-node:26656" \
  -e CHAIN_ID=speculod \
  -e MONIKER=api-node \
  speculod-blockchain
```

## Cloud Deployment

### AWS/GCP/Azure Deployment

**1. Deploy Persistent Node**
```bash
# Set external address to your cloud instance public IP
docker run -d \
  --name persistent-node \
  -p 26656:26656 -p 26657:26657 \
  -e SERVICE_TYPE=tendermint \
  -e NODE_TYPE=persistent \
  -e EXTERNAL_ADDRESS="tcp://your-public-ip:26656" \
  -e CHAIN_ID=speculod \
  -e MONIKER=persistent-node \
  speculod-blockchain
```

**2. Deploy Peer Nodes**
```bash
# Connect to persistent node via public IP
docker run -d \
  --name peer-node \
  -p 26658:26656 -p 1317:8080 \
  -e SERVICE_TYPE=all \
  -e NODE_TYPE=peer \
  -e PERSISTENT_PEERS="node_id@your-persistent-node-ip:26656" \
  -e CHAIN_ID=speculod \
  -e MONIKER=peer-node \
  speculod-blockchain
```

### Google Cloud Run Multi-Region

```bash
# Deploy persistent node in us-central1
gcloud run deploy persistent-node \
  --source . \
  --platform managed \
  --region us-central1 \
  --port 26657 \
  --set-env-vars SERVICE_TYPE=tendermint,NODE_TYPE=persistent

# Deploy API node in us-east1 
gcloud run deploy api-node \
  --source . \
  --platform managed \
  --region us-east1 \
  --port 8080 \
  --set-env-vars SERVICE_TYPE=all,NODE_TYPE=peer,PERSISTENT_PEERS="node_id@persistent-node-url:26656"
```

## Network Topology Examples

### Simple 3-Node Network
```
[Persistent Node] ← → [Peer Node 1] ← → [Peer Node 2]
       ↑                                      ↑
       └─ P2P + RPC                          └─ REST API + gRPC
```

### Load-Balanced API Architecture
```
                    [Load Balancer]
                           |
        ┌─────────────────┼─────────────────┐
        ↓                 ↓                 ↓
  [API Node 1]      [API Node 2]      [API Node 3]
        ↓                 ↓                 ↓
        └─────────────────┼─────────────────┘
                          ↓
               [Persistent Node Network]
               [Node 1] ← → [Node 2] ← → [Node 3]
```

## Monitoring and Validation

### Check Node Status
```bash
# Check persistent node
curl -s http://localhost:26657/status | jq '.result.sync_info'

# Check peer connections
curl -s http://localhost:26657/net_info | jq '.result.peers | length'

# Check specific peer node
curl -s http://localhost:26659/status | jq '.result.sync_info'
```

### Validate P2P Connectivity
```bash
# List connected peers
curl -s http://localhost:26657/net_info | jq '.result.peers[].node_info.id'

# Check if nodes are syncing
curl -s http://localhost:26657/status | jq '.result.sync_info.catching_up'
```

### Health Checks
```bash
# Persistent node health
curl -f http://localhost:26657/health

# Peer node health (REST API)
curl -f http://localhost:1318/cosmos/base/tendermint/v1beta1/node_info
```

## Troubleshooting

### Common Issues

1. **Nodes not connecting**
   - Verify node IDs are correct
   - Check firewall rules for P2P ports (26656)
   - Ensure PERSISTENT_PEERS format is correct: `node_id@ip:port`

2. **Address already in use**
   - Use different ports for multiple local nodes
   - Check with `docker ps` for port conflicts

3. **Genesis file mismatch**
   - Ensure all nodes use the same chain ID
   - For existing networks, copy genesis.json from persistent node

### Debug Commands
```bash
# Check node configuration
docker exec speculod-persistent-node-1 cat /home/speculod/.speculod/config/config.toml | grep -A 5 -B 5 "persistent_peers\|seeds\|external_address"

# View node logs
docker logs -f speculod-persistent-node-1

# Get detailed P2P info
curl -s http://localhost:26657/net_info | jq '.'
```

## Security Considerations

1. **Firewall Configuration**
   - Open P2P port (26656) for persistent nodes
   - Restrict RPC/API ports to trusted networks
   - Use TLS certificates for production

2. **Network Isolation**
   - Use private networks for internal communication
   - Expose only necessary ports to public internet
   - Consider VPN for sensitive deployments

3. **Key Management**
   - Use proper key management for production
   - Avoid test keyring backend in production
   - Implement proper backup strategies
