#!/bin/bash

# Validator Service Entrypoint
set -e

echo "🔗 Starting Speculod Validator Service..."

# Default environment variables
export MONIKER=${MONIKER:-"speculod-validator"}
export CHAIN_ID=${CHAIN_ID:-"speculod"}
export DEPLOYMENT_MODE=${DEPLOYMENT_MODE:-"validator"}

echo "Validator Configuration:"
echo "  Moniker: $MONIKER"
echo "  Chain ID: $CHAIN_ID"
echo "  Mode: $DEPLOYMENT_MODE"

# Home directory setup
export HOME=/home/speculod
SPECULOD_HOME="$HOME/.speculod"

# Initialize if needed
if [ ! -d "$SPECULOD_HOME/config" ]; then
    echo "🏗️ Initializing blockchain..."
    speculodd init $MONIKER --chain-id=$CHAIN_ID --home=$SPECULOD_HOME
    
    # Create genesis account
    echo "🔑 Creating genesis account..."
    speculodd keys add genesis-account --keyring-backend=test --home=$SPECULOD_HOME
    GENESIS_ADDRESS=$(speculodd keys show genesis-account -a --keyring-backend=test --home=$SPECULOD_HOME)
    
    # Add genesis account with funds
    speculodd genesis add-genesis-account $GENESIS_ADDRESS 1000000000000stake --home=$SPECULOD_HOME
    
    # Create genesis transaction
    speculodd genesis gentx genesis-account 500000000stake \
        --keyring-backend=test \
        --chain-id=$CHAIN_ID \
        --home=$SPECULOD_HOME
    
    # Collect genesis transactions
    speculodd genesis collect-gentxs --home=$SPECULOD_HOME
    
    echo "✅ Blockchain initialized"
fi

# Configure for cloud deployment
echo "🔧 Configuring for validator mode..."

# Update configuration
sed -i 's|create_empty_blocks = true|create_empty_blocks = false|g' $SPECULOD_HOME/config/config.toml
sed -i 's|rpc.laddr = "tcp://127.0.0.1:26657"|rpc.laddr = "tcp://0.0.0.0:26657"|g' $SPECULOD_HOME/config/config.toml
sed -i 's|laddr = "tcp://127.0.0.1:26656"|laddr = "tcp://0.0.0.0:26656"|g' $SPECULOD_HOME/config/config.toml

# Create health check endpoint script
cat > /home/speculod/health-check.py << 'EOF'
#!/usr/bin/env python3
import http.server
import socketserver
import json
import subprocess
import threading
import time

class HealthHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/health':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            health_data = {
                "status": "healthy",
                "service": "speculod-validator",
                "timestamp": time.time()
            }
            self.wfile.write(json.dumps(health_data).encode())
        elif self.path == '/ready':
            # Check if blockchain is ready
            try:
                result = subprocess.run(['curl', '-s', 'http://localhost:26657/status'], 
                                      capture_output=True, text=True, timeout=5)
                if result.returncode == 0:
                    self.send_response(200)
                    self.send_header('Content-type', 'application/json')
                    self.end_headers()
                    self.wfile.write(b'{"status": "ready"}')
                else:
                    self.send_response(503)
                    self.end_headers()
            except:
                self.send_response(503)
                self.end_headers()
        else:
            self.send_response(404)
            self.end_headers()

def start_health_server():
    with socketserver.TCPServer(("", 8080), HealthHandler) as httpd:
        httpd.serve_forever()

if __name__ == "__main__":
    # Start health server in background
    health_thread = threading.Thread(target=start_health_server, daemon=True)
    health_thread.start()
    
    # Start the blockchain
    subprocess.run(['speculodd', 'start', '--home=/home/speculod/.speculod'])
EOF

chmod +x /home/speculod/health-check.py

echo "🚀 Starting validator with health endpoints..."
echo "   Validator RPC: http://0.0.0.0:26657"
echo "   P2P: tcp://0.0.0.0:26656"
echo "   Health: http://0.0.0.0:8080/health"

# Start the health check server and blockchain
exec python3 /home/speculod/health-check.py
