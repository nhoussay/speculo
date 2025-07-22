# Speculod Local Testnet

This directory contains the configuration for the Speculod local testnet.

## Network Information

- **Chain ID**: `speculod-local-1`
- **Network Type**: Local Development/Testing
- **Genesis Time**: Will be set dynamically
- **Consensus**: Tendermint

## Files

- `network-config.json` - Network metadata and endpoints
- `genesis.json` - Genesis state (generated automatically)
- `peers.json` - Seed and persistent peer information

## Usage

### Download Genesis
```bash
curl -L -o genesis.json https://raw.githubusercontent.com/nhoussay/speculo/main/networks/local-testnet/genesis.json
```

### Download Peers
```bash
curl -L https://raw.githubusercontent.com/nhoussay/speculo/main/networks/local-testnet/peers.json
```

### Quick Start
```bash
# Initialize node
speculodd init my-node --chain-id speculod-local-1

# Download network config
curl -L -o ~/.speculod/config/genesis.json https://raw.githubusercontent.com/nhoussay/speculo/main/networks/local-testnet/genesis.json

# Start node
speculodd start --minimum-gas-prices="0.001stake"
```
