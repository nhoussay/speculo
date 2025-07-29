# Speculod Single Service Deployment Guide

This guide explains how to deploy individual Speculod services for better control and scalability.

## Available Service Types

### 1. Tendermint RPC Service
**Purpose**: Provides Tendermint RPC for blockchain queries and transactions
**Port**: 26657
**Use Case**: Direct blockchain interaction, transaction broadcasting

```bash
# Deploy only Tendermint RPC
docker compose -f docker-compose-tendermint.yml up -d

# Test the service
curl http://localhost:26657/status
curl http://localhost:26657/health
```

**Endpoints**:
- Status: `http://localhost:26657/status`
- Health: `http://localhost:26657/health` 
- Block info: `http://localhost:26657/block`
- Validators: `http://localhost:26657/validators`

---

### 2. Cosmos REST API Service
**Purpose**: Provides RESTful API for Cosmos SDK operations
**Port**: 1317
**Use Case**: Web applications, REST clients, Swagger documentation

```bash
# Deploy only REST API
docker compose -f docker-compose-rest-api.yml up -d

# Test the service
curl http://localhost:1317/cosmos/base/tendermint/v1beta1/node_info
curl http://localhost:1317/cosmos/bank/v1beta1/supply
```

**Endpoints**:
- Node Info: `http://localhost:1317/cosmos/base/tendermint/v1beta1/node_info`
- Supply: `http://localhost:1317/cosmos/bank/v1beta1/supply`
- Swagger UI: `http://localhost:1317/swagger/`
- Balances: `http://localhost:1317/cosmos/bank/v1beta1/balances/{address}`

---

### 3. gRPC Service
**Purpose**: Provides gRPC interface for high-performance applications
**Port**: 9090
**Use Case**: gRPC clients, high-performance applications, protobuf integration

```bash
# Deploy only gRPC
docker compose -f docker-compose-grpc.yml up -d

# Test the service (health check via REST)
curl http://localhost:8080/cosmos/base/tendermint/v1beta1/node_info

# Test gRPC connection
grpcurl -plaintext localhost:9090 list
```

**Endpoints**:
- gRPC: `localhost:9090`
- Health (REST): `http://localhost:8080/cosmos/base/tendermint/v1beta1/node_info`

---

### 4. Faucet Service  
**Purpose**: Provides token faucet for testing and development
**Port**: 4500
**Use Case**: Testing, development, providing test tokens

```bash
# Deploy only Faucet (requires Tendermint RPC running separately)
docker compose -f docker-compose-faucet.yml up -d

# Test the service
curl http://localhost:4500/health
curl -X POST http://localhost:4500/faucet -d '{"address":"cosmos1..."}'
```

**Endpoints**:
- Health: `http://localhost:4500/health`
- Request tokens: `POST http://localhost:4500/faucet`
- UI: `http://localhost:4500/`

---

## Deployment Strategies

### Single Service Deployment
Deploy one service type for specialized use cases:

```bash
# Option 1: Only Tendermint RPC for direct blockchain access
docker compose -f docker-compose-tendermint.yml up -d

# Option 2: Only REST API for web applications  
docker compose -f docker-compose-rest-api.yml up -d

# Option 3: Only gRPC for high-performance clients
docker compose -f docker-compose-grpc.yml up -d

# Option 4: Only Faucet for token distribution
docker compose -f docker-compose-faucet.yml up -d
```

### Multi-Service Deployment
Deploy multiple services together:

```bash
# Deploy Tendermint + REST API
docker compose -f docker-compose-tendermint.yml -f docker-compose-rest-api.yml up -d

# Deploy all blockchain services (no faucet)
docker compose -f docker-compose-tendermint.yml -f docker-compose-rest-api.yml -f docker-compose-grpc.yml up -d

# Deploy complete stack
docker compose -f docker-compose-tendermint.yml -f docker-compose-rest-api.yml -f docker-compose-grpc.yml -f docker-compose-faucet.yml up -d
```

### Traditional All-in-One Deployment
Use the existing multi-service configuration:

```bash
# Deploy all services in one container
docker compose -f docker-compose-multi.yml up -d
```

---

## Service Configuration

Each service can be configured via environment variables:

### Common Variables
- `CHAIN_ID`: Blockchain chain identifier (default: speculod)
- `MONIKER`: Node moniker name
- `HOME_DIR`: Blockchain data directory
- `KEYRING_BACKEND`: Keyring backend type (default: test)

### Service-Specific Variables
- `SERVICE_TYPE`: Service mode (tendermint, rest-api, grpc, all)
- `PORT`: Internal service port (8080 for REST API)

### Examples

```bash
# Custom chain configuration
export CHAIN_ID=my-custom-chain
export MONIKER=my-node
docker compose -f docker-compose-tendermint.yml up -d

# Different port mapping
docker compose -f docker-compose-rest-api.yml -p 3317:8080 up -d
```

---

## Health Monitoring

Each service provides health endpoints:

```bash
# Tendermint RPC
curl http://localhost:26657/status

# REST API  
curl http://localhost:1317/cosmos/base/tendermint/v1beta1/node_info

# gRPC (via REST health endpoint)
curl http://localhost:8080/cosmos/base/tendermint/v1beta1/node_info

# Faucet
curl http://localhost:4500/health
```

---

## Cloud Deployment

### Google Cloud Run
Each service type can be deployed to Cloud Run:

```bash
# Deploy Tendermint RPC service
gcloud run deploy speculod-tendermint --source . --platform managed --port 26657

# Deploy REST API service  
gcloud run deploy speculod-api --source . --platform managed --port 8080 --set-env-vars SERVICE_TYPE=rest-api

# Deploy gRPC service
gcloud run deploy speculod-grpc --source . --platform managed --port 9090 --set-env-vars SERVICE_TYPE=grpc
```

### Docker Swarm/Kubernetes
Use the individual compose files as templates for orchestration platforms.

---

## Troubleshooting

### Common Issues

1. **Port Conflicts**: Make sure ports are not already in use
2. **Service Dependencies**: Faucet requires Tendermint RPC to be running
3. **Data Persistence**: Each service maintains its own blockchain data volume
4. **Network Connectivity**: Services use bridge networks for internal communication

### Debugging

```bash
# Check service logs
docker compose -f docker-compose-tendermint.yml logs -f

# Check container status
docker compose -f docker-compose-tendermint.yml ps

# Execute into container
docker compose -f docker-compose-tendermint.yml exec tendermint /bin/bash
```
