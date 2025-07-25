# Hybrid Deployment: GCE P2P Node + Cloud Run Nginx Proxy

## Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Local Nodes   │◄──►│  GCE P2P Node   │◄──►│ Cloud Run Proxy │
│                 │    │                 │    │                 │
│ • Development   │    │ • Real P2P      │    │ • HTTP/HTTPS    │
│ • Testing       │    │ • TCP:26656     │    │ • API Gateway   │
│ • Other peers   │    │ • Bootstrap     │    │ • Load Balancer │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Components

### 1. GCE P2P Node (Primary)
- **Purpose**: Real P2P connectivity, blockchain consensus, block production
- **Ports**: 26656 (P2P), 26657 (RPC), 1317 (API), 9090 (gRPC)
- **Function**: Acts as the bootstrap node and persistent peer for the network

### 2. Cloud Run Nginx Proxy (Secondary)
- **Purpose**: API gateway, load balancing, HTTPS termination
- **Ports**: 443 (HTTPS) → routes to multiple backends
- **Function**: Provides clean API access and can proxy to multiple GCE nodes

## Benefits

1. **Real P2P**: GCE node supports proper TCP P2P connections
2. **Scalability**: Cloud Run handles HTTP traffic efficiently  
3. **Reliability**: Multiple deployment targets for redundancy
4. **Cost Effective**: Use GCE for P2P, Cloud Run for API scaling
5. **Domain Mapping**: Clean URLs via Cloud Run domain mapping

## Network Flow

1. **Local nodes** connect to GCE node via P2P (TCP:26656)
2. **Web clients** connect to Cloud Run proxy via HTTPS (443)
3. **GCE node** peers with other blockchain nodes
4. **Cloud Run proxy** forwards API requests to GCE node or other backends
