# GitHub-Hosted Network Deployment Guide

This guide explains how to deploy the Speculod blockchain using GitHub-hosted genesis and peer configuration files.

## Overview

The GitHub-hosted approach provides:
- **Centralized Configuration**: Genesis and peer information hosted on GitHub
- **Easy Updates**: Network configuration can be updated via GitHub
- **Security**: Cryptographic verification of downloaded files
- **Scalability**: New nodes can join by downloading configuration

## Network Configuration

### Files Structure

```
networks/local-testnet/
├── genesis.json          # The network genesis file
├── peers.json           # Peer and seed node information
├── network-config.json  # Network metadata
└── README.md           # Usage instructions
```

### Network Details

- **Chain ID**: `speculod-local-1`
- **Genesis Time**: 2025-07-22T19:12:37.918912754Z
- **Genesis SHA256**: `b6fc7a624308816db3d4a79fba1ec9837350983447ce2e6e8d4ec7ef515eec12`

## Deployment Methods

### Method 1: Docker Compose (Recommended for Local Testing)

1. **Clone and prepare the repository**:
   ```bash
   git clone https://github.com/nhoussay/speculo.git
   cd speculo
   ```

2. **Start the network**:
   ```bash
   # Start persistent node (generates/downloads genesis)
   docker-compose -f docker-compose-github.yml up persistent-node -d
   
   # Wait for genesis to be ready, then start peer node
   docker-compose -f docker-compose-github.yml up peer-node -d
   ```

3. **Monitor the nodes**:
   ```bash
   # Check logs
   docker-compose -f docker-compose-github.yml logs -f
   
   # Check node status
   curl -s http://localhost:26657/status | jq .
   curl -s http://localhost:26659/status | jq .
   ```

### Method 2: Manual Node Setup

1. **Download network configuration**:
   ```bash
   # Create config directory
   mkdir -p ~/.speculod/config
   
   # Download genesis
   curl -L https://raw.githubusercontent.com/nhoussay/speculo/main/networks/local-testnet/genesis.json \
        -o ~/.speculod/config/genesis.json
   
   # Download peer configuration
   curl -L https://raw.githubusercontent.com/nhoussay/speculo/main/networks/local-testnet/peers.json \
        -o /tmp/peers.json
   ```

2. **Initialize and configure node**:
   ```bash
   # Initialize node
   speculodd init my-node --chain-id speculod-local-1 --home ~/.speculod
   
   # Configure persistent peers (extract from peers.json)
   PERSISTENT_PEERS=$(jq -r '.persistent_peers[]?.address // empty' /tmp/peers.json | tr '\n' ',' | sed 's/,$//')
   sed -i "s/persistent_peers = \"\"/persistent_peers = \"$PERSISTENT_PEERS\"/" ~/.speculod/config/config.toml
   
   # Configure RPC server
   sed -i 's|laddr = "tcp://127.0.0.1:26657"|laddr = "tcp://0.0.0.0:26657"|g' ~/.speculod/config/config.toml
   ```

3. **Start the node**:
   ```bash
   speculodd start --home ~/.speculod --minimum-gas-prices 0.001stake
   ```

### Method 3: Google Cloud Run Deployment

1. **Update environment variables in `cloudbuild-persistent-node.yaml`**:
   ```yaml
   env:
     - name: GITHUB_REPO
       value: "nhoussay/speculo"
     - name: GITHUB_BRANCH
       value: "main"
     - name: NETWORK_NAME
       value: "local-testnet"
     - name: NODE_TYPE
       value: "persistent"
   ```

2. **Deploy to Google Cloud**:
   ```bash
   gcloud builds submit --config cloudbuild-persistent-node.yaml
   ```

## Configuration Parameters

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `GITHUB_REPO` | `nhoussay/speculo` | GitHub repository for network config |
| `GITHUB_BRANCH` | `main` | Git branch to use |
| `NETWORK_NAME` | `local-testnet` | Network configuration directory |
| `NODE_TYPE` | `standalone` | Node type: `persistent`, `peer`, `standalone` |
| `CHAIN_ID` | `speculod-local-1` | Blockchain chain identifier |
| `GENERATE_GENESIS` | `false` | Force genesis generation (persistent nodes only) |

### Node Types

- **Persistent Node**: Main network node that can generate genesis
- **Peer Node**: Connects to persistent nodes for synchronization
- **Standalone Node**: Independent node for testing

## Network Security

### Genesis Verification

The startup script automatically verifies:
- JSON format validity
- Chain ID matches expected value
- Required genesis fields present
- SHA256 checksum (when available)

### Cryptographic Verification (Optional)

For production networks, implement GPG signature verification:

```bash
# Download and verify genesis signature
curl -L https://raw.githubusercontent.com/nhoussay/speculo/main/networks/local-testnet/genesis.json.sig \
     -o genesis.json.sig
gpg --verify genesis.json.sig genesis.json
```

## Troubleshooting

### Common Issues

1. **Genesis Download Fails**:
   - Check internet connectivity
   - Verify GitHub repository access
   - Ensure correct branch and network name

2. **Peer Discovery Issues**:
   - Verify persistent node is running
   - Check network connectivity
   - Confirm peer addresses are correct

3. **Node Sync Problems**:
   - Check genesis file consistency
   - Verify chain ID matches
   - Ensure proper RPC configuration

### Debugging Commands

```bash
# Check node status
curl -s http://localhost:26657/status | jq .

# Check peers
curl -s http://localhost:26657/net_info | jq .

# View logs
docker-compose -f docker-compose-github.yml logs persistent-node
docker-compose -f docker-compose-github.yml logs peer-node

# Validate genesis
jq . ~/.speculod/config/genesis.json > /dev/null && echo "Valid JSON" || echo "Invalid JSON"
```

## Updating Network Configuration

To update the network configuration:

1. **Update files in GitHub**:
   - Modify `genesis.json`, `peers.json`, or `network-config.json`
   - Commit changes to the repository

2. **Restart nodes**:
   ```bash
   docker-compose -f docker-compose-github.yml down
   docker-compose -f docker-compose-github.yml up -d
   ```

3. **Nodes will automatically download the updated configuration**

## Production Considerations

1. **Use HTTPS endpoints with proper SSL certificates**
2. **Implement GPG signature verification for all configuration files**
3. **Use multiple GitHub repositories for redundancy**
4. **Monitor network configuration for unauthorized changes**
5. **Implement proper backup strategies for genesis and keys**
6. **Use proper environment variable management for secrets**

## Support

For issues and questions:
- GitHub Issues: https://github.com/nhoussay/speculo/issues
- Network Status: Check node endpoints for real-time status
