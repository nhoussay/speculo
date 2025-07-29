# Configuration Files Organization Summary

This document provides a complete inventory of all configuration files organized by type and purpose.

## 📋 Configuration Organization Overview

All configuration files have been systematically organized into appropriate directories:

- **Nginx Configurations** → `deployments/nginx/` (4 files)
- **Project Configurations** → `config/` (3 files)
- **Active Genesis** → Root directory (1 file)

## 🌐 Nginx Configuration Files (`deployments/nginx/`)

### Load Balancer and Proxy Configurations (4 files)

| Configuration | Purpose | Usage |
|---------------|---------|-------|
| `nginx.conf` | Main nginx proxy configuration | Standard HTTP/HTTPS load balancing |
| `nginx-p2p.conf` | P2P-specific nginx configuration | Tendermint P2P connections |
| `nginx-websocket.conf` | WebSocket proxy configuration | WebSocket-to-TCP bridging |  
| `nginx-single-port.conf` | Single-port nginx setup | Simplified single-port deployment |

### Configuration Details

**Standard Proxy (`nginx.conf`)**:
- HTTP/HTTPS load balancing
- Standard REST API proxying
- Basic upstream configuration

**P2P Configuration (`nginx-p2p.conf`)**:
- Tendermint P2P port handling
- Blockchain node connectivity
- Peer-to-peer networking support

**WebSocket Proxy (`nginx-websocket.conf`)**:
- WebSocket connection handling
- Cloud Run HTTPS compatibility
- WebSocket-to-TCP bridge support

**Single Port (`nginx-single-port.conf`)**:
- Simplified deployment configuration
- Single-port access
- Streamlined proxy setup

## ⚙️ Project Configuration Files (`config/`)

### Dependencies and Build Configuration (3 files)

| File | Purpose | Language/Tool |
|------|---------|---------------|
| `requirements.txt` | Python dependencies | Python/pip |
| `requirements-websocket-bridge.txt` | WebSocket bridge dependencies | Python/pip |
| `package.json` | Node.js dependencies and scripts | Node.js/npm |

### Configuration Details

**Python Dependencies (`requirements.txt`)**:
```python
flask==3.0.0
requests==2.31.0
```

**WebSocket Bridge Dependencies (`requirements-websocket-bridge.txt`)**:
- Specialized dependencies for WebSocket bridging
- Network protocol handling libraries
- Async/await support libraries

**Node.js Configuration (`package.json`)**:
- Project metadata
- npm scripts for automation
- JavaScript dependencies

## 🔗 Active Genesis Configuration (Root Directory)

### Blockchain Genesis (1 file)

| File | Purpose | Status |
|------|---------|--------|
| `local-mainnet-genesis.json` | 3-validator mainnet genesis | ✅ Active - Kept in root |

**Why kept in root**: This file is actively used by the current deployment and referenced by Docker containers and scripts.

## 📁 Updated Project Structure

```
speculod/
├── 📁 deployments/
│   ├── 📁 nginx/                     # Nginx configurations (4 files)
│   │   ├── nginx.conf
│   │   ├── nginx-p2p.conf  
│   │   ├── nginx-websocket.conf
│   │   └── nginx-single-port.conf
│   ├── 📁 docker-compose/
│   ├── 📁 docker/
│   └── 📁 supervisor/
├── 📁 config/                        # Project configurations (3 files)
│   ├── package.json
│   ├── requirements.txt
│   └── requirements-websocket-bridge.txt
├── 📁 scripts/
├── 📁 docs/
└── 📄 local-mainnet-genesis.json     # Active genesis (kept in root)
```

## 🚀 Usage Examples

### Deploy with Nginx Configuration
```bash
# Use specific nginx configuration
docker run -v $(pwd)/deployments/nginx/nginx-websocket.conf:/etc/nginx/nginx.conf nginx

# Deploy with Docker Compose using organized configs
docker-compose -f deployments/docker-compose/docker-compose-nginx-proxy.yml up -d
```

### Install Dependencies
```bash
# Install Python dependencies
pip install -r config/requirements.txt

# Install WebSocket bridge dependencies  
pip install -r config/requirements-websocket-bridge.txt

# Install Node.js dependencies
cd config/ && npm install
```

### Use Genesis Configuration
```bash
# Genesis file remains accessible from root for current deployment
docker-compose -f deployments/docker-compose/docker-compose-all-mainnet-validators.yml up -d
```

## 📊 Configuration Categories Summary

| Category | File Count | Location | Purpose |
|----------|------------|----------|---------|
| **Nginx Configs** | 4 | `deployments/nginx/` | Load balancing and proxy configurations |
| **Project Configs** | 3 | `config/` | Dependencies and build configurations |
| **Genesis Config** | 1 | Root | Active blockchain genesis (in use) |
| **Total Configs** | 8 | Organized | Complete configuration ecosystem |

## 🎯 Benefits of Configuration Organization

### ✅ Before Organization
- 4 nginx configuration files scattered in root directory
- Python and Node.js config files mixed with other files
- No clear separation between active and template configurations
- Difficult to find specific configuration types

### ✅ After Organization
- **Clear Separation**: Infrastructure vs project configurations
- **Purpose-Based Grouping**: Nginx configs grouped together
- **Dependency Management**: All dependency files in config/
- **Active File Preservation**: Genesis file kept accessible for current deployment
- **Easy Navigation**: Know where to find each configuration type

### 🚀 Configuration Management Benefits
- **Infrastructure Configs**: All nginx configurations organized together
- **Dependency Isolation**: Python and Node.js dependencies clearly separated
- **Deployment Ready**: Configurations organized for easy Docker/compose usage
- **Maintainable Structure**: Scalable for additional configuration types

---

**Configuration Organization Status**: ✅ Complete
**Nginx Configurations**: 4 files organized in `deployments/nginx/`
**Project Configurations**: 3 files organized in `config/`
**Active Genesis**: 1 file preserved in root for current deployment
**Last Updated**: Complete configuration file organization
