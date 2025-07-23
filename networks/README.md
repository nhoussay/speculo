# Networks Configuration

This directory contains network configuration files for the Speculod blockchain.

## Files

### `persistent-nodes.json`
GitHub-hosted persistent nodes registry that enables dynamic node discovery. This file contains:

- **Active Persistent Nodes**: Production nodes that peer nodes automatically connect to
- **Backup Nodes**: Standby nodes for redundancy
- **Network Information**: Chain ID, genesis location, and network metadata

**Usage**:
- Peer nodes automatically fetch this registry from GitHub
- Nodes with `"status": "active"` are used for P2P connections
- Provides fallback mechanism when GitHub is unavailable

**Management**:
Use the management script to update this registry:
```bash
# List all nodes
./scripts/manage-persistent-nodes.sh list

# Add a new node
./scripts/manage-persistent-nodes.sh add --id node-1 --address node.example.com:26656

# Update node status
./scripts/manage-persistent-nodes.sh update node-1 --status active
```

### `local-testnet/`
Contains the network configuration for the local testnet including genesis.json and other configuration files.

## Dynamic Discovery Process

1. New peer nodes fetch `persistent-nodes.json` from GitHub
2. Extract active persistent nodes with `status: "active"`
3. Configure P2P connections automatically
4. Fall back to local registry or hardcoded nodes if GitHub is unavailable

For detailed information, see [PERSISTENT_NODES_REGISTRY_GUIDE.md](../PERSISTENT_NODES_REGISTRY_GUIDE.md).
