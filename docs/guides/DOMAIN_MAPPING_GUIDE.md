# Domain Mapping Setup Guide

## Setting up persistent.specu.io → speculo-nginx-proxy

### Current Status
- **Cloud Run Service**: `speculo-nginx-proxy-809714550777.europe-west1.run.app`
- **Target Domain**: `persistent.specu.io`
- **Service Location**: `europe-west1`

### Step 1: Verify Domain Ownership

```bash
# Add domain to Google Search Console or use gcloud
gcloud domains verify persistent.specu.io
```

### Step 2: Create Domain Mapping

```bash
# Map the domain to your Cloud Run service
gcloud run domain-mappings create \
    --service=speculo-nginx-proxy \
    --domain=persistent.specu.io \
    --region=europe-west1 \
    --project=speculo-blockchain

# Check the mapping status
gcloud run domain-mappings describe persistent.specu.io \
    --region=europe-west1 \
    --project=speculo-blockchain
```

### Step 3: Configure DNS Records

After creating the domain mapping, Google Cloud will provide DNS records that you need to add to your domain provider:

1. **A Record**: Points to Google's IP addresses
2. **AAAA Record**: Points to Google's IPv6 addresses  
3. **CNAME Record**: For www subdomain (if needed)

Example DNS records (get actual values from gcloud):
```
# A Records
persistent.specu.io.     300 IN A     216.239.32.21
persistent.specu.io.     300 IN A     216.239.34.21
persistent.specu.io.     300 IN A     216.239.36.21
persistent.specu.io.     300 IN A     216.239.38.21

# AAAA Records  
persistent.specu.io.     300 IN AAAA  2001:4860:4802:32::15
persistent.specu.io.     300 IN AAAA  2001:4860:4802:34::15
persistent.specu.io.     300 IN AAAA  2001:4860:4802:36::15
persistent.specu.io.     300 IN AAAA  2001:4860:4802:38::15
```

### Step 4: Verify SSL Certificate

Google Cloud Run automatically provisions SSL certificates for mapped domains:

```bash
# Check certificate status
gcloud run domain-mappings describe persistent.specu.io \
    --region=europe-west1 \
    --format="value(status.conditions)"
```

### Step 5: Test the Domain

```bash
# Test RPC endpoint
curl https://persistent.specu.io/rpc/status

# Test API endpoint  
curl https://persistent.specu.io/api/cosmos/base/tendermint/v1beta1/node_info

# Test gRPC endpoint (requires grpcurl)
grpcurl persistent.specu.io:443 cosmos.base.tendermint.v1beta1.Service/GetNodeInfo
```

### Troubleshooting

#### DNS Propagation
```bash
# Check DNS propagation
dig persistent.specu.io
nslookup persistent.specu.io
```

#### Certificate Issues
```bash
# Check SSL certificate
openssl s_client -connect persistent.specu.io:443 -servername persistent.specu.io
```

#### Service Health
```bash
# Check Cloud Run service logs
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=speculo-nginx-proxy" \
    --project=speculo-blockchain \
    --format="value(textPayload)" \
    --limit=50
```

### Expected Timeline
- **Domain Mapping Creation**: 1-2 minutes
- **SSL Certificate Provisioning**: 5-15 minutes  
- **DNS Propagation**: 5 minutes - 48 hours (depending on TTL and DNS provider)

### Commands to Get DNS Records

```bash
# Get the exact DNS records you need to configure
gcloud run domain-mappings describe persistent.specu.io \
    --region=europe-west1 \
    --project=speculo-blockchain \
    --format="value(status.resourceRecords[].name,status.resourceRecords[].rrdata)"
```

### Status Check Commands

```bash
# Check overall domain mapping status
gcloud run domain-mappings list --region=europe-west1

# Detailed status of specific mapping
gcloud run domain-mappings describe persistent.specu.io \
    --region=europe-west1 \
    --format="table(
        spec.routeName:label='SERVICE',
        status.conditions[0].type:label='STATUS',
        status.conditions[0].status:label='READY',
        status.url:label='URL'
    )"
```

## Next Steps After Domain is Active

Once `persistent.specu.io` is working, update all configuration files to use the new domain instead of the long Cloud Run URL.
