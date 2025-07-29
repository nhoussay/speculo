# Persistent Nodes Registry Guide

## Overview

The Speculod network uses a GitHub-based persistent nodes registry system that allows nodes to automatically discover and connect to active persistent nodes in the network. This system enables:

- **Dynamic Node Discovery**: New peer nodes automatically discover active persistent nodes
- **Centralized Registry**: A single source of truth for network topology hosted on GitHub
- **Fallback Mechanisms**: Multiple discovery methods ensure network resilience
- **Domain-Mapped Endpoints**: Stable addressing through domain names like `persistent.specu.io`

## Registry Structure

The persistent nodes registry is stored in `/networks/persistent-nodes.json` and contains:

### Schema

```json
{
  "network": "speculod-local-1",
  "description": "Speculod Network Persistent Nodes Registry",
  "last_updated": "2025-07-23T18:52:00Z",
  "persistent_nodes": [
    {
      "id": "speculo-persistent-node-1",
      "moniker": "speculo-persistent-node-1", 
      "address": "persistent.specu.io:26656",
      "rpc_endpoint": "https://persistent.specu.io/status",
      "api_endpoint": "https://persistent.specu.io",
      "node_id": "838ebde14991541b3bdbe325e4e1009fa3e96cbc",
      "deployment": {
        "type": "google-cloud-run",
        "region": "europe-west1",
        "service": "speculo-persistent-node-1",
        "domain": "persistent.specu.io"
      },
      "status": "active",
      "added_date": "2025-07-22T19:39:00Z",
      "capabilities": ["persistent", "bootstrap", "seed", "domain-mapped"]
    }
  ],
  "backup_nodes": [
    {
      "id": "speculo-persistent-hybrid",
      "moniker": "speculo-persistent-hybrid-gce",
      "address": "34.14.12.77:26656",
      "rpc_endpoint": "http://34.14.12.77:26657",
      "deployment": {
        "type": "google-compute-engine",
        "region": "europe-west1-b",
        "instance": "speculo-persistent-hybrid"
      },
      "status": "pending",
      "added_date": "2025-07-23T18:00:00Z",
      "capabilities": ["persistent", "backup"]
    }
  ],
  "network_info": {
    "chain_id": "speculod-local-1",
    "genesis_repo": "nhoussay/speculo",
    "genesis_branch": "main",
    "genesis_path": "networks/local-testnet/genesis.json"
  }
}
```

### Field Descriptions

#### Persistent Nodes
- **id**: Unique identifier for the node
- **moniker**: Human-readable node name
- **address**: P2P address (host:port) for peer connections
- **rpc_endpoint**: RPC endpoint for status queries
- **api_endpoint**: REST API endpoint
- **node_id**: Tendermint node ID for P2P identification
- **deployment**: Deployment platform details
- **status**: Node status (`active`, `inactive`, `maintenance`, `pending`)
- **added_date**: When the node was added to the registry
- **capabilities**: Node capabilities array

#### Capabilities
- `persistent`: Node is designed to run continuously
- `bootstrap`: Node can bootstrap new peers
- `seed`: Node acts as a seed node
- `domain-mapped`: Node has a stable domain name
- `backup`: Node serves as a backup

## Dynamic Discovery Process

When a new peer node starts, it follows this discovery process:

### 1. Registry Fetch
```bash
# Fetch registry from GitHub
curl -sf "https://raw.githubusercontent.com/nhoussay/speculo/main/networks/persistent-nodes.json"
```

### 2. Active Node Extraction
```bash
# Extract active persistent nodes
jq -r '.persistent_nodes[] | select(.status == "active") | "\(.node_id)@\(.address)"'
```

### 3. Fallback Discovery
If GitHub registry is unavailable:
- Use local registry backup if mounted
- Fall back to hardcoded persistent nodes (`persistent@persistent.specu.io:26656`)

### 4. P2P Configuration
```bash
# Configure persistent peers and seeds
speculodd config set config.p2p.persistent_peers "$PERSISTENT_PEERS"
speculodd config set config.p2p.seeds "$SEEDS"
```

## Management Tools

### Registry Management Script

The `scripts/manage-persistent-nodes.sh` tool provides comprehensive registry management:

```bash
# List all nodes
./scripts/manage-persistent-nodes.sh list

# Add a new persistent node
./scripts/manage-persistent-nodes.sh add \
  --id "new-node-1" \
  --moniker "new-persistent-node" \
  --address "new-node.example.com:26656" \
  --node-id "abc123...def456" \
  --deployment-type "google-cloud-run"

# Update node status
./scripts/manage-persistent-nodes.sh update new-node-1 --status active

# Remove a node
./scripts/manage-persistent-nodes.sh remove new-node-1

# Validate registry
./scripts/manage-persistent-nodes.sh validate

# Test node connectivity
./scripts/manage-persistent-nodes.sh test new-node-1
```

### Commands Reference

#### List Nodes
```bash
./scripts/manage-persistent-nodes.sh list [--active|--backup|--all]
```

#### Add Node
```bash
./scripts/manage-persistent-nodes.sh add \
  --id <node-id> \
  --moniker <moniker> \
  --address <host:port> \
  --node-id <tendermint-node-id> \
  [--rpc-endpoint <rpc-url>] \
  [--api-endpoint <api-url>] \
  [--deployment-type <type>] \
  [--region <region>] \
  [--capabilities <cap1,cap2>] \
  [--backup]
```

#### Update Node
```bash
./scripts/manage-persistent-nodes.sh update <node-id> \
  [--status <status>] \
  [--address <host:port>] \
  [--rpc-endpoint <rpc-url>] \
  [--api-endpoint <api-url>]
```

#### Remove Node
```bash
./scripts/manage-persistent-nodes.sh remove <node-id>
```

#### Validate Registry
```bash
./scripts/manage-persistent-nodes.sh validate
```

#### Test Connectivity
```bash
./scripts/manage-persistent-nodes.sh test <node-id>
```

#### Sync with GitHub
```bash
./scripts/manage-persistent-nodes.sh sync
```

## Docker Compose Integration

### Dynamic Discovery Configuration

Use `docker-compose-dynamic.yml` for nodes with dynamic discovery:

```yaml
version: '3.8'
services:
  speculod-peer:
    build: .
    environment:
      - NODE_TYPE=peer
      - SERVICE_TYPE=all
      - CHAIN_ID=speculod-local-1
      - MONIKER=speculo-peer-dynamic
    volumes:
      - ./scripts:/scripts:ro
      - ./networks:/scripts/networks:ro  # Mount registry for local backup
    ports:
      - "26680:26656"
      - "26681:26657"
      - "1322:1317"
```

### Manual Configuration

For traditional static configuration:

```yaml
environment:
  - PERSISTENT_PEERS=838ebde14991541b3bdbe325e4e1009fa3e96cbc@persistent.specu.io:26656
  - SEEDS=838ebde14991541b3bdbe325e4e1009fa3e96cbc@persistent.specu.io:26656
```

## Deployment Patterns

### 1. Primary Persistent Node (Domain-Mapped)
- **Purpose**: Main bootstrap node for the network
- **Address**: `persistent.specu.io:26656`
- **Deployment**: Google Cloud Run with domain mapping
- **Status**: Always `active`
- **Capabilities**: `["persistent", "bootstrap", "seed", "domain-mapped"]`

### 2. Backup Persistent Nodes
- **Purpose**: Redundancy and load distribution
- **Deployment**: Google Compute Engine or other platforms
- **Status**: `active` or `pending`
- **Capabilities**: `["persistent", "backup"]`

### 3. Dynamic Peer Nodes
- **Purpose**: Regular network participants
- **Discovery**: Automatic via GitHub registry
- **Deployment**: Any platform with Docker support
- **Connection**: Automatically connects to active persistent nodes

## Network Topology

```
GitHub Registry
      ↓
[persistent.specu.io:26656] ←→ [Backup Persistent Nodes]
      ↓                              ↓
[Dynamic Peer 1] ←→ [Dynamic Peer 2] ←→ [Dynamic Peer N]
      ↓                              ↓
[Local Peers]  ←→ [Cloud Peers]   ←→ [Hybrid Deployment]
```

## Best Practices

### 1. Registry Management
- Always validate registry before committing changes
- Test node connectivity before marking as `active`
- Keep backup nodes ready for failover
- Update `last_updated` timestamp when making changes

### 2. Node Deployment
- Use domain mapping for primary persistent nodes
- Implement health checks for all persistent nodes
- Monitor node connectivity and update status accordingly
- Use meaningful monikers for easier identification

### 3. Network Security
- Verify node_id authenticity before adding to registry
- Use HTTPS endpoints for RPC/API when possible
- Implement proper firewall rules for P2P ports
- Regular security audits of persistent nodes

### 4. Monitoring
- Monitor registry fetch success rates
- Track peer connection success
- Alert on persistent node unavailability
- Log dynamic discovery events

## Troubleshooting

### Common Issues

#### Registry Fetch Failures
```bash
# Check GitHub connectivity
curl -s "https://raw.githubusercontent.com/nhoussay/speculo/main/networks/persistent-nodes.json"

# Verify local backup
cat ./networks/persistent-nodes.json | jq '.'
```

#### Node Connection Issues
```bash
# Test persistent node connectivity
curl -s "https://persistent.specu.io/status" | jq '.result.node_info.id'

# Check P2P port accessibility  
telnet persistent.specu.io 26656
```

#### Discovery Script Issues
```bash
# Run discovery manually
./scripts/blockchain-service-dynamic.sh

# Check container logs
docker logs speculod-peer
```

### Debug Commands

```bash
# Validate registry format
jq '.' networks/persistent-nodes.json

# Test node extraction
cat networks/persistent-nodes.json | jq -r '.persistent_nodes[] | select(.status == "active") | "\(.node_id)@\(.address)"'

# Check P2P configuration
speculodd config show | grep -E "(persistent_peers|seeds)"
```

## Contributing

When adding new persistent nodes to the registry:

1. Deploy and verify the node is operational
2. Test P2P connectivity from multiple locations
3. Add node to registry using management script
4. Validate registry format
5. Test dynamic discovery with the new node
6. Commit changes to GitHub repository
7. Monitor network adoption of the new node

## Security Considerations

- **Node Verification**: Always verify node authenticity before adding
- **Access Control**: Limit registry write access to trusted operators
- **Monitoring**: Implement continuous monitoring of persistent nodes
- **Backup Strategy**: Maintain multiple persistent nodes for redundancy
- **Domain Security**: Secure domain mappings with proper SSL certificates

## Future Enhancements

- **Automated Node Registration**: API-based node registration
- **Health Check Integration**: Automatic status updates based on health checks
- **Geographic Load Balancing**: Region-based node selection
- **Consensus Participation Tracking**: Monitor node participation in consensus
- **Performance Metrics**: Track node performance and connection quality
