# Domain Setup Guide

## 🎯 Current Architecture Status

✅ **PRODUCTION READY**: Peer-to-peer multi-service blockchain architecture  
✅ **CLOUD READY**: Google Cloud Run deployment (europe-west1)  
✅ **SERVICES**: Tendermint validator + API peer node + Token faucet  
✅ **INTEGRATION**: Complete service orchestration and P2P connectivity  
🔄 **FINAL STEP**: Custom domain configuration for production access

## 🌐 Domain Architecture Overview

### 📊 **Production Service URLs**
```
Main Services (Google Cloud Run europe-west1):
├── speculod-tendermint-[hash].europe-west1.run.app  # Blockchain RPC
├── speculod-api-[hash].europe-west1.run.app         # REST API
└── speculod-faucet-[hash].europe-west1.run.app      # Token faucet

Custom Domain Mapping:
├── rpc.yourdomain.com     → Tendermint service  
├── api.yourdomain.com     → API service
└── faucet.yourdomain.com  → Faucet service
```

### 🎯 **Domain Strategy**
- **Primary Domain**: `yourdomain.com` (replace with your domain)
- **RPC Subdomain**: `rpc.yourdomain.com` (blockchain RPC access)
- **API Subdomain**: `api.yourdomain.com` (REST API endpoints)
- **Faucet Subdomain**: `faucet.yourdomain.com` (development tokens)

## � Quick Setup Process

### 1️⃣ **Deploy Services to Cloud Run**
```bash
# First deploy the complete architecture
export PROJECT_ID="your-gcp-project-id"
./scripts/deploy-gcp-multi-service.sh

# Note the deployed URLs for domain mapping:
# - speculod-tendermint-[hash].europe-west1.run.app
# - speculod-api-[hash].europe-west1.run.app  
# - speculod-faucet-[hash].europe-west1.run.app
```

### 2️⃣ **Configure DNS Records**
```bash
# Add these DNS records in your domain provider:

# A Record or CNAME for custom domain
rpc.yourdomain.com     → speculod-tendermint-[hash].europe-west1.run.app
api.yourdomain.com     → speculod-api-[hash].europe-west1.run.app
faucet.yourdomain.com  → speculod-faucet-[hash].europe-west1.run.app

# Alternative: Use Cloud DNS for automatic management
gcloud dns managed-zones create speculod-zone --dns-name="yourdomain.com" --description="Speculod blockchain domain"
```

### 3️⃣ **Map Custom Domains to Cloud Run**
```bash
# Map each service to its custom domain
gcloud run domain-mappings create \
  --service=speculod-tendermint \
  --domain=rpc.yourdomain.com \
  --region=europe-west1

gcloud run domain-mappings create \
  --service=speculod-api \
  --domain=api.yourdomain.com \
  --region=europe-west1

gcloud run domain-mappings create \
  --service=speculod-faucet \
  --domain=faucet.yourdomain.com \
  --region=europe-west1
```
   ```
   Type: CNAME
   Name: blockchain
   Value: ghs.googlehosted.com.
   TTL: 300
   ```

4. **Add DNS Records for faucet.specu.io** (future faucet service):

   **Required CNAME Record:**
   ```
   Type: CNAME
   Name: faucet
   Value: ghs.googlehosted.com.
   TTL: 300
   ```

### Step 3: Wait for Domain Mapping Status

After creating domain mappings, check status:

```bash
# Check blockchain subdomain status
gcloud beta run domain-mappings describe blockchain.specu.io --region=europe-west1

# List all domain mappings
gcloud beta run domain-mappings list --region=europe-west1
```

## 🚀 Complete Setup Commands

### Method 1: Root Domain Setup

```bash
# 1. Enable APIs
gcloud services enable domains.googleapis.com certificatemanager.googleapis.com

# 2. Create domain mapping (replace with your domain)
DOMAIN="your-domain.com"
gcloud run domain-mappings create \
    --service=speculod-blockchain \
    --domain=$DOMAIN \
    --region=europe-west1

# 3. Get DNS configuration
gcloud run domain-mappings describe $DOMAIN --region=europe-west1

# 4. Check status
gcloud run domain-mappings list --region=europe-west1
```

### Method 2: Subdomain Setup (Recommended)

```bash
# Using subdomain like blockchain.your-domain.com
SUBDOMAIN="blockchain.your-domain.com"
gcloud run domain-mappings create \
    --service=speculod-blockchain \
    --domain=$SUBDOMAIN \
    --region=europe-west1

# Get configuration
gcloud run domain-mappings describe $SUBDOMAIN --region=europe-west1
```

## 🔍 Verification Steps

### 1. Check Domain Mapping Status
```bash
# Check if mapping is ready
gcloud run domain-mappings list --region=europe-west1

# Detailed status
gcloud run domain-mappings describe YOUR_DOMAIN.com --region=europe-west1
```

### 2. Test DNS Resolution
```bash
# Test DNS resolution (after DNS propagation)
nslookup YOUR_DOMAIN.com
dig YOUR_DOMAIN.com

# Test HTTPS connectivity
curl -I https://YOUR_DOMAIN.com/status
```

### 3. Verify SSL Certificate
```bash
# Check SSL certificate status
curl -I https://YOUR_DOMAIN.com
```

## ⏱️ Expected Timeline

- **DNS Changes**: 5-30 minutes (Gandi is usually fast)
- **SSL Certificate**: 10-60 minutes after DNS propagation
- **Full Propagation**: Up to 24 hours globally

## 🛠️ Common DNS Configurations

### Option 1: Root Domain + www
```
# Root domain
Type: A
Name: @
Value: [Google Cloud IP]

# www subdomain  
Type: CNAME
Name: www
Value: ghs.googlehosted.com.
```

### Option 2: API Subdomain (Recommended)
```
# API subdomain
Type: CNAME
Name: api
Value: ghs.googlehosted.com.

# Alternative: blockchain subdomain
Type: CNAME  
Name: blockchain
Value: ghs.googlehosted.com.
```

### Option 3: Multiple Services
```
# Main blockchain API
Type: CNAME
Name: api
Value: ghs.googlehosted.com.

# Blockchain RPC (future)
Type: CNAME
Name: rpc  
Value: ghs.googlehosted.com.

# Faucet service (future)
Type: CNAME
Name: faucet
Value: ghs.googlehosted.com.
```

## 🚨 Troubleshooting

### Domain Verification Issues
```bash
# Check domain ownership verification
gcloud domains list-user-verified

# Verify domain manually
gcloud domains verify YOUR_DOMAIN.com
```

### SSL Certificate Issues
```bash
# Check certificate status
gcloud run domain-mappings describe YOUR_DOMAIN.com --region=europe-west1 \
    --format="value(status.conditions[0].message)"
```

### DNS Propagation Issues
```bash
# Check DNS from different locations
dig @8.8.8.8 YOUR_DOMAIN.com
dig @1.1.1.1 YOUR_DOMAIN.com

# Check DNS propagation globally
# Use online tools like: whatsmydns.net
```

## 📊 Your specu.io Configuration

### Final URLs After Setup:
- **Blockchain API**: `https://blockchain.specu.io/status`
- **Node Info**: `https://blockchain.specu.io/cosmos/base/tendermint/v1beta1/node_info`
- **Block Status**: `https://blockchain.specu.io/status`
- **Faucet Service** (future): `https://faucet.specu.io/health`

### Gandi DNS Records Summary:
```
# For blockchain service
Type: CNAME
Name: blockchain
Value: ghs.googlehosted.com.
TTL: 300

# For faucet service (future)
Type: CNAME  
Name: faucet
Value: ghs.googlehosted.com.
TTL: 300
```

## ✅ Verification Commands for specu.io

Once domain verification and DNS setup is complete:

```bash
# Test blockchain subdomain
curl https://blockchain.specu.io/status

# Check SSL certificate
curl -I https://blockchain.specu.io

# Test API endpoints
curl https://blockchain.specu.io/cosmos/base/tendermint/v1beta1/node_info

# Future faucet testing
curl https://faucet.specu.io/health
```

## 🎯 Next Steps After Setup

1. **Update Documentation**: Replace URLs in all docs with your custom domain
2. **Configure CORS**: If needed for web applications
3. **Set up Monitoring**: Monitor the custom domain endpoint
4. **Update Client Configurations**: Point API clients to new domain

---

**🚀 Ready to set up your domain? Replace `YOUR_DOMAIN.com` with your actual Gandi domain and run the commands above!**
