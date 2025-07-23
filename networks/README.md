# Networks Configuration

This directory contains network configuration files for the Speculod blockchain networks.

## Directory Structure

```
networks/
├── mainnet/                    # Production mainnet configuration
│   ├── genesis.json           # Mainnet genesis file (chain-id: speculod-mainnet-1)
│   ├── network-config.json    # Mainnet network parameters
│   ├── persistent-nodes.json  # Mainnet persistent nodes registry
│   └── README.md
├── local-testnet/             # Local development and testing
│   ├── genesis.json          # Local testnet genesis (chain-id: speculod-local-1)
│   ├── network-config.json   # Local network parameters
│   ├── persistent-nodes.json # Local persistent nodes registry
│   └── README.md
└── README.md                  # This file
```

## Networks

### Mainnet (`speculod-mainnet-1`)
- **Purpose**: Production network for live prediction markets
- **Persistent Node**: `persistent.specu.io:26656` (Google Cloud Run)
- **Domain**: `specu.io`
- **Configuration**: `networks/mainnet/`
- **Registry**: `networks/mainnet/persistent-nodes.json`

### Local Testnet (`speculod-local-1`)
- **Purpose**: Local development and testing
- **Persistent Node**: `localhost:26656`
- **Configuration**: `networks/local-testnet/`
- **Registry**: `networks/local-testnet/persistent-nodes.json`

## Dynamic Discovery Process

The dynamic discovery system automatically selects the correct network configuration based on the `CHAIN_ID` environment variable:

1. **Mainnet**: `CHAIN_ID=speculod-mainnet-1` → uses `networks/mainnet/`
2. **Local**: `CHAIN_ID=speculod-local-1` → uses `networks/local-testnet/`

### Configuration URLs

**Mainnet**:
- Genesis: `https://raw.githubusercontent.com/nhoussay/speculo/main/networks/mainnet/genesis.json`
- Registry: `https://raw.githubusercontent.com/nhoussay/speculo/main/networks/mainnet/persistent-nodes.json`

**Local Testnet**:
- Genesis: `https://raw.githubusercontent.com/nhoussay/speculo/main/networks/local-testnet/genesis.json`
- Registry: `https://raw.githubusercontent.com/nhoussay/speculo/main/networks/local-testnet/persistent-nodes.json`

## Usage Examples

### Deploy Mainnet Peer
```bash
docker-compose -f docker-compose-dynamic.yml up -d
# Uses CHAIN_ID=speculod-mainnet-1 by default
```

### Deploy Local Testnet Peer
```bash
CHAIN_ID=speculod-local-1 docker-compose -f docker-compose-dynamic.yml up -d
```

### Manual Network Selection
```bash
# Force mainnet
CHAIN_ID=speculod-mainnet-1 NETWORK_NAME=mainnet ./scripts/blockchain-service-dynamic.sh

# Force local testnet  
CHAIN_ID=speculod-local-1 NETWORK_NAME=local-testnet ./scripts/blockchain-service-dynamic.sh
```
