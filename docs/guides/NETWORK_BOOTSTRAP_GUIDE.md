# Speculod Network Configuration Repository

This repository contains the official network configurations for the Speculod blockchain network.

## 🌐 Mainnet Configuration

### Genesis File
- **URL**: `https://raw.githubusercontent.com/your-org/speculod-network/main/mainnet/genesis.json`
- **SHA256**: `your_actual_genesis_hash_here`
- **Chain ID**: `speculod-mainnet-1`
- **Genesis Time**: `2025-01-01T00:00:00Z`

### Persistent Peers
```json
{
  "persistent_peers": "node1@seed1.speculod.com:26656,node2@seed2.speculod.com:26656",
  "last_updated": "2025-07-22T18:00:00Z",
  "network": "mainnet"
}
```

### Bootstrap Command
```bash
# Automated bootstrap (recommended)
curl -sSL https://bootstrap.speculod.com/install.sh | bash

# Manual bootstrap
wget https://raw.githubusercontent.com/your-org/speculod-network/main/mainnet/genesis.json
wget https://raw.githubusercontent.com/your-org/speculod-network/main/mainnet/genesis.json.sig
gpg --verify genesis.json.sig genesis.json
```

## 🧪 Testnet Configuration

### Genesis File
- **URL**: `https://raw.githubusercontent.com/your-org/speculod-network/main/testnet/genesis.json`
- **Chain ID**: `speculod-testnet-1`

## 🔒 Security Best Practices

### For Node Operators
1. **Always verify genesis hash**: `sha256sum genesis.json`
2. **Use HTTPS only**: Never download over plain HTTP
3. **Multiple peer sources**: Don't rely on single peer lists
4. **Monitor for forks**: Watch for unexpected chain splits

### For Network Maintainers
1. **Immutable genesis**: Never change genesis.json after launch
2. **GPG signatures**: Sign all critical files
3. **Multiple mirrors**: Host on GitHub + independent infrastructure
4. **Transparent updates**: Document all peer list changes

## 📊 Network Endpoints

### Public RPC Nodes
- `https://rpc.speculod.com:443`
- `https://rpc-backup.speculod.com:443`

### Public API Nodes  
- `https://api.speculod.com:443`
- `https://api-backup.speculod.com:443`

### Seed Nodes
- `seed1.speculod.com:26656`
- `seed2.speculod.com:26656`

## 🚀 Quick Start

```bash
# Install speculodd
curl -L https://github.com/your-org/speculod/releases/latest/download/speculodd-linux-amd64 > speculodd
chmod +x speculodd && sudo mv speculodd /usr/local/bin/

# Bootstrap network
mkdir -p ~/.speculod
cd ~/.speculod
curl -sSL https://bootstrap.speculod.com/bootstrap.sh | bash

# Start node
speculodd start --minimum-gas-prices="0.001stake"
```

## 🛡️ Security Considerations

### Genesis File Trust
- The genesis file is the **root of trust** for the entire network
- **NEVER** use genesis from untrusted sources
- Verify signatures and hashes before using

### Peer Discovery Risks
- Malicious peers can slow synchronization
- Use multiple peer sources to avoid eclipse attacks
- Monitor peer diversity and geographic distribution

## 📞 Support

- **Documentation**: https://docs.speculod.com
- **Discord**: https://discord.gg/speculod
- **Issues**: https://github.com/your-org/speculod/issues
