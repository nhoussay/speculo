# 🏗️ Speculo Hybrid Architecture Guide

## Overview

This guide explains Speculo's hybrid architecture that leverages Google Cloud Run for P2P networking and Compute Engine/Local machines for API services.

## 🎯 Architecture Rationale

**Google Cloud Run Constraints:**
- Single port exposure limitation
- Serverless auto-scaling optimized for stateless workloads
- HTTPS-only external traffic routing

**Solution:**
- **Cloud Run**: P2P network infrastructure (consensus layer)
- **Compute Engine/Local**: API services (application layer)

## 🌐 Network Topology

```
┌─────────────────────────────────────────────────────────────────┐
│                        Internet Traffic                         │
└─────────────────────┬───────────────────────────────────────────┘
                      │
    ┌─────────────────┼─────────────────┐
    │                 │                 │
    ▼                 ▼                 ▼
┌─────────┐    ┌─────────────┐    ┌─────────────┐
│ End     │    │ API Gateway │    │ P2P Network │
│ Users   │◄──►│(Compute Eng)│◄──►│(Cloud Run)  │
│         │    │             │    │             │
│ Apps    │    │ REST: 1317  │    │ P2P: 26656  │
│ UIs     │    │ RPC:  26657 │    │ Consensus   │
│ APIs    │    │ gRPC: 9090  │    │ Blocks      │
└─────────┘    └─────────────┘    └─────────────┘
```

## 🔧 Deployment Components

### Network Configurations

#### Testnet (speculod-local-1)
```yaml
Network:
  - Chain ID: speculod-local-1
  - Genesis: https://raw.githubusercontent.com/nhoussay/speculo/main/networks/local-testnet/genesis.json
  - Domain: persistent.specu.io
  - API Domain: api.specu.io

Configuration:
  - Purpose: Development and testing
  - Consensus: Tendermint
  - Block Time: ~6 seconds
  - Initial Validators: 1
```

#### Mainnet (speculod-mainnet-1)
```yaml
Network:
  - Chain ID: speculod-mainnet-1
  - Genesis: https://raw.githubusercontent.com/nhoussay/speculo/main/networks/mainnet/genesis.json
  - Domain: persistent.specu.io
  - API Domain: api-mainnet.specu.io

Configuration:
  - Purpose: Production blockchain
  - Consensus: Tendermint
  - Block Time: ~6 seconds
  - Initial Validators: 1
```

### Cloud Run Tier (P2P Network)
```yaml
Services:
  - speculo-persistent-node-1: Bootstrap/seed node
  - speculo-peer-node-{1-3}: Network participants

Characteristics:
  - Port: 26656 (P2P only)
  - Access: HTTPS via persistent.specu.io
  - Scaling: Auto-scale based on network demand
  - Cost: Pay-per-use
```

### Compute Engine Tier (API Services)
```yaml
Services:
  - speculo-api-gateway-1: Full-service node

Characteristics:
  - Ports: 26657 (RPC), 1317 (REST), 9090 (gRPC), 26656 (P2P)
  - Access: Direct HTTP/HTTPS via api.specu.io
  - Scaling: Manual VM scaling
  - Cost: Fixed compute costs
```

## 🚀 Deployment Commands

### 1. Deploy P2P Network Infrastructure

#### Testnet (speculod-local-1)
```bash
# Deploy Cloud Run P2P network for testnet
export CHAIN_ID="speculod-local-1"
./scripts/deploy-cloud-run-p2p-network.sh

# Verify network status
curl -s "https://persistent.specu.io/status" | jq '.result.sync_info.latest_block_height'
```

#### Mainnet (speculod-mainnet-1)
```bash
# Deploy Cloud Run P2P network for mainnet
export CHAIN_ID="speculod-mainnet-1"
./scripts/deploy-cloud-run-p2p-network.sh

# Verify mainnet network status
curl -s "https://persistent.specu.io/status" | jq '.result.sync_info.latest_block_height'
```

### 2. Deploy API Gateway

#### Testnet API Gateway
```bash
# Deploy Compute Engine API services for testnet
export CHAIN_ID="speculod-local-1"
./scripts/deploy-compute-engine-api.sh

# Test API connectivity
curl -s http://api.specu.io:26657/net_info | jq '.result.n_peers'
curl -s http://api.specu.io:1317/cosmos/bank/v1beta1/supply
```

#### Mainnet API Gateway
```bash
# Deploy Compute Engine API services for mainnet
export CHAIN_ID="speculod-mainnet-1"
./scripts/deploy-compute-engine-api.sh

# Test mainnet API connectivity
curl -s http://api-mainnet.specu.io:26657/net_info | jq '.result.n_peers'
curl -s http://api-mainnet.specu.io:1317/cosmos/bank/v1beta1/supply
```

### 3. Local Development

#### Connect to Testnet
```bash
# Connect local node to Cloud Run testnet network
export CHAIN_ID="speculod-local-1"
export PERSISTENT_PEERS="838ebde14991541b3bdbe325e4e1009fa3e96cbc@persistent.specu.io:443"
docker compose -f docker-compose-local-peer-test.yml up -d

# All services available locally
curl http://localhost:26657/status
curl http://localhost:1317/cosmos/bank/v1beta1/supply
```

#### Connect to Mainnet
```bash
# Connect local node to Cloud Run mainnet network
export CHAIN_ID="speculod-mainnet-1"
export PERSISTENT_PEERS="838ebde14991541b3bdbe325e4e1009fa3e96cbc@persistent.specu.io:443"
docker compose -f docker-compose-local-peer-test.yml up -d

# All mainnet services available locally
curl http://localhost:26657/status
curl http://localhost:1317/cosmos/bank/v1beta1/supply
```

## 📊 Service Matrix

| Service Type | Cloud Run | Compute Engine | Local Dev |
|--------------|-----------|----------------|-----------|
| P2P Network  | ✅ Primary | ✅ Secondary   | ✅ Dev    |
| REST API     | ❌ No      | ✅ Primary     | ✅ Dev    |
| RPC Service  | ❌ No      | ✅ Primary     | ✅ Dev    |
| gRPC Service | ❌ No      | ✅ Primary     | ✅ Dev    |
| Auto-Scaling | ✅ Yes     | ❌ Manual      | ❌ N/A    |
| Multi-Port   | ❌ No      | ✅ Yes         | ✅ Yes    |
| Cost Model   | Pay/Use    | Fixed VM       | Free      |

## 🌍 Network Availability

| Network | Chain ID | Status | Genesis URL |
|---------|----------|--------|-------------|
| Testnet | speculod-local-1 | ✅ Active | [genesis.json](https://raw.githubusercontent.com/nhoussay/speculo/main/networks/local-testnet/genesis.json) |
| Mainnet | speculod-mainnet-1 | ✅ Active | [genesis.json](https://raw.githubusercontent.com/nhoussay/speculo/main/networks/mainnet/genesis.json) |

## 🔗 Network Connectivity

### P2P Communication Flow
```
1. Cloud Run persistent nodes establish network bootstrap
2. Compute Engine API nodes connect to Cloud Run via HTTPS
3. Local development nodes connect to Cloud Run persistent peers
4. All nodes participate in consensus through P2P layer
```

### API Access Flow
```
1. Client applications connect to Compute Engine API gateway
2. API gateway provides REST/RPC/gRPC endpoints
3. API gateway maintains P2P connection to Cloud Run network
4. Blockchain state synchronized across hybrid infrastructure
```

## 💡 Benefits

- **Scalability**: Cloud Run auto-scales P2P infrastructure
- **Cost Efficiency**: Pay-per-use for network, fixed costs for APIs
- **Reliability**: Separation of network consensus and API services
- **Flexibility**: Can deploy additional API gateways as needed
- **Development**: Local nodes connect to production P2P network

## ⚠️ Limitations

- **Cloud Run**: Single port, no direct P2P over TCP
- **Complexity**: Hybrid deployment requires coordination
- **Latency**: HTTPS adds overhead to P2P communication
- **Dependencies**: API services depend on Cloud Run network health
