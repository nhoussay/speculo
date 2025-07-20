# 🌐 Gandi Domain Setup for Speculod Blockchain

**Setting up custom domain for Google Cloud Run service**  
**Your Domain**: `specu.io`  
**Blockchain Subdomain**: `blockchain.specu.io`  
**Faucet Subdomain**: `faucet.specu.io`

## 📋 Current Service Details

- **Service**: `speculod-blockchain`
- **Region**: `europe-west1` 
- **Current URL**: `https://speculod-blockchain-809714550777.europe-west1.run.app`
- **Project**: `speculo-blockchain`

## 🚀 Quick Setup for specu.io

### Step 1: Domain Verification (IN PROGRESS)

```bash
# Verify domain ownership (browser should have opened)
gcloud domains verify specu.io
```

**Complete this step in Google Search Console**: Verify ownership of `specu.io`

### Step 2: Create Domain Mappings

```bash
# Create mapping for blockchain service
gcloud beta run domain-mappings create \
    --service=speculod-blockchain \
    --domain=blockchain.specu.io \
    --region=europe-west1

# Get DNS records needed
gcloud beta run domain-mappings describe blockchain.specu.io --region=europe-west1
```

## 🔧 Gandi DNS Configuration for specu.io

### In Your Gandi Account:

1. **Login to Gandi**: Go to [admin.gandi.net](https://admin.gandi.net)

2. **Navigate to DNS**: 
   - Go to "Domain" → Select `specu.io` → "DNS Records"

3. **Add DNS Records for blockchain.specu.io**:

   **Required CNAME Record:**
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
