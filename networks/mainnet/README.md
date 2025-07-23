# Speculod Mainnet Configuration

This directory contains the production mainnet configuration for the Speculod blockchain network.

## Network Parameters

- **Chain ID**: `speculod-mainnet-1`
- **Network Type**: Production Mainnet
- **Primary Persistent Node**: `persistent.specu.io:26656`
- **Domain**: `specu.io`

## Files

### `genesis.json`
The genesis file for the mainnet network. This is the production genesis file used by:
- Google Cloud Run persistent node (`persistent.specu.io`)
- All mainnet peer nodes
- Production deployments

### `network-config.json`
Network configuration parameters including:
- Chain ID
- Network type
- Persistent node addresses
- Bootstrap configuration

### `persistent-nodes.json`
Registry of persistent nodes for the mainnet (symlinked from parent directory for consistency).

## Usage

This configuration is used by:
1. Google Cloud Run persistent node deployment
2. Production peer nodes connecting to mainnet
3. Dynamic discovery system for mainnet nodes

## Bootstrap Process

1. Nodes download genesis from: `https://raw.githubusercontent.com/nhoussay/speculo/main/networks/mainnet/genesis.json`
2. Persistent nodes registry: `https://raw.githubusercontent.com/nhoussay/speculo/main/networks/persistent-nodes.json`
3. Primary persistent node: `persistent.specu.io:26656`
