# 🚀 Cloud Run Deployment Scripts Guide

This guide provides comprehensive documentation for the automated deployment scripts that manage the Speculo blockchain P2P network on Google Cloud Run.

## 📋 Overview

The deployment scripts provide a complete solution for managing blockchain infrastructure on Google Cloud Run:

- **Persistent Node**: Bootstrap node with stable domain mapping
- **Peer Nodes**: Network participants that connect to the persistent node
- **Unified Management**: Single interface for deployment, monitoring, and cleanup

## 🛠️ Script Architecture

### Core Scripts

#### 1. `deploy-persistent-node.sh`
**Purpose**: Deploy and configure the persistent node with domain mapping

**Features**:
- Deploys `speculo-persistent-node-1` service
- Configures domain mapping to `persistent.specu.io`
- Sets up environment for mainnet GitHub configuration
- Validates deployment and blockchain activity
- Handles cleanup of existing services

**Usage**:
```bash
./scripts/deploy-persistent-node.sh
```

#### 2. `deploy-peer-nodes.sh`
**Purpose**: Deploy one or more peer nodes that connect to the persistent node

**Features**:
- Supports deploying multiple peer nodes
- Automatic configuration to connect to persistent node
- Custom naming with suffixes
- Validation of P2P connectivity
- Resource optimization for peer workloads

**Usage**:
```bash
# Deploy 1 peer node (default)
./scripts/deploy-peer-nodes.sh

# Deploy 3 peer nodes
./scripts/deploy-peer-nodes.sh -c 3

# Deploy with custom suffix
./scripts/deploy-peer-nodes.sh -s europe
```

#### 3. `manage-cloud-run-network.sh`
**Purpose**: Unified management interface for the complete network

**Features**:
- One-command network deployment
- Status monitoring and health checks
- Log aggregation and analysis
- Complete cleanup functionality
- Error handling and validation

**Usage**:
```bash
# Deploy complete network
./scripts/manage-cloud-run-network.sh deploy-network

# Check status
./scripts/manage-cloud-run-network.sh status

# View logs
./scripts/manage-cloud-run-network.sh logs -s speculo-persistent-node-1

# Cleanup everything
./scripts/manage-cloud-run-network.sh cleanup
```

## 🎯 Deployment Scenarios

### Scenario 1: First-Time Network Setup

```bash
# Deploy complete network with persistent node + 2 peer nodes
./scripts/manage-cloud-run-network.sh deploy-network

# Verify deployment
./scripts/manage-cloud-run-network.sh status
```

### Scenario 2: Scale Existing Network

```bash
# Add more peer nodes to existing network
./scripts/deploy-peer-nodes.sh -c 3

# Check updated status
./scripts/manage-cloud-run-network.sh status
```

### Scenario 3: Redeploy Persistent Node

```bash
# Deploy fresh persistent node (handles cleanup automatically)
./scripts/deploy-persistent-node.sh

# Verify domain mapping
dig persistent.specu.io
```

### Scenario 4: Development/Testing Cleanup

```bash
# Interactive cleanup with confirmation
./scripts/manage-cloud-run-network.sh cleanup

# Force cleanup for automation
./scripts/manage-cloud-run-network.sh cleanup -f
```

## ⚙️ Configuration Details

### Environment Variables

All deployed services are configured with:

```bash
CHAIN_ID=speculod-mainnet-1
NODE_TYPE=persistent|peer
SERVICE_TYPE=p2p
GITHUB_NETWORK_CONFIG=true
NETWORK_CONFIG_REPO=nhoussay/speculo
NETWORK_CONFIG_BRANCH=main
PERSISTENT_PEERS=838ebde14991541b3bdbe325e4e1009fa3e96cbc@persistent.specu.io:443
```

### Resource Allocation

**Persistent Node**:
- Memory: 2Gi
- CPU: 1
- Min Instances: 1
- Max Instances: 10
- Port: 26656 (P2P)

**Peer Nodes**:
- Memory: 2Gi
- CPU: 1
- Min Instances: 0 (can scale to zero)
- Max Instances: 5
- Port: 26656 (P2P)

### Labels and Metadata

All services are tagged with:
- `type`: persistent-node | peer-node
- `network`: mainnet
- `service`: p2p
- `node-number`: (for peer nodes)

## 🔍 Monitoring and Troubleshooting

### Health Checks

The scripts perform automatic health validation:

1. **Service Status**: Verifies Cloud Run service is ready
2. **Blockchain Activity**: Checks for recent block commits
3. **Domain Resolution**: Validates DNS configuration
4. **P2P Connectivity**: Monitors peer connections

### Log Analysis

```bash
# View recent logs for specific service
./scripts/manage-cloud-run-network.sh logs -s speculo-persistent-node-1

# Check all blockchain activity
gcloud logging read "resource.type=cloud_run_revision AND (resource.labels.service_name:speculo-persistent-node OR resource.labels.service_name:speculo-peer-node) AND textPayload:(\"committed state\" OR \"finalized block\")" --limit=20
```

### Common Issues

#### Issue: Service deployment fails
**Solution**: Check image exists and gcloud authentication
```bash
gcloud container images list --repository=gcr.io/speculo-blockchain
gcloud auth list
```

#### Issue: Domain mapping not working
**Solution**: Verify DNS propagation and Google Cloud DNS setup
```bash
dig persistent.specu.io
gcloud beta run domain-mappings list --region=europe-west1
```

#### Issue: No blockchain activity
**Solution**: Check service logs and network configuration
```bash
./scripts/manage-cloud-run-network.sh logs -s speculo-persistent-node-1
```

## 🚀 Advanced Usage

### Custom Network Topologies

Deploy nodes in different regions:
```bash
# Modify REGION variable in scripts for multi-region deployment
export REGION="us-central1"
./scripts/deploy-peer-nodes.sh -c 2 -s us-central
```

### Production Monitoring

Set up monitoring dashboards:
```bash
# Create monitoring queries
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name:speculo" --format="table(timestamp,resource.labels.service_name,textPayload)"
```

### Integration with CI/CD

Use scripts in automated pipelines:
```yaml
- name: Deploy Network
  run: |
    ./scripts/manage-cloud-run-network.sh deploy-network -c 3
    
- name: Validate Deployment
  run: |
    ./scripts/manage-cloud-run-network.sh status
```

## 📊 Cost Optimization

### Auto-scaling Configuration

Peer nodes scale to zero when unused:
- **Min Instances**: 0 (scales down when no traffic)
- **Max Instances**: 5 (scales up with network activity)
- **Persistent Node**: Always running (min 1 instance)

### Resource Monitoring

Monitor costs:
```bash
# Check current instance counts
gcloud run services list --region=europe-west1 --filter="metadata.labels.network=mainnet"

# View resource usage
gcloud monitoring metrics list --filter="resource.type=cloud_run_revision"
```

## 🔐 Security Considerations

### Network Security

- **P2P Only**: Services only expose port 26656
- **No API Access**: REST/RPC endpoints not available on Cloud Run
- **Domain Verification**: Cryptographic verification of persistent peers

### Access Control

- **IAM Roles**: Requires Cloud Run Admin for deployment
- **Service Accounts**: Uses default Compute Engine service account
- **Network Policies**: Inherits VPC security settings

## 📚 References

- [Google Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Cosmos SDK P2P Networking](https://docs.cosmos.network/main/core/node)
- [Speculo Hybrid Architecture Guide](HYBRID_ARCHITECTURE_GUIDE.md)
