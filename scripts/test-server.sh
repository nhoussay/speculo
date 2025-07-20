#!/bin/sh

# Simple HTTP server for testing Tendermint deployment
set -e

PORT=${PORT:-8080}
echo "Starting simple HTTP server on port $PORT for testing..."

# Create a simple health endpoint using Python
cat > /tmp/simple_server.py << 'EOF'
import http.server
import socketserver
import json
import os

PORT = int(os.environ.get('PORT', 8080))

class SimpleHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/status':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            response = {
                "jsonrpc": "2.0",
                "id": 1,
                "result": {
                    "node_info": {
                        "id": "test-node",
                        "moniker": "tendermint-test"
                    },
                    "sync_info": {
                        "latest_block_height": "1"
                    }
                }
            }
            self.wfile.write(json.dumps(response).encode())
        elif self.path == '/health':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            response = {"status": "ok", "service": "tendermint-test"}
            self.wfile.write(json.dumps(response).encode())
        else:
            self.send_response(404)
            self.end_headers()

with socketserver.TCPServer(("", PORT), SimpleHandler) as httpd:
    print(f"Serving on port {PORT}")
    httpd.serve_forever()
EOF

# Install python if not present and run the server
if command -v python3 >/dev/null 2>&1; then
    exec python3 /tmp/simple_server.py
else
    # If python not available, use a simple curl-based approach
    echo "Python not available, creating static responses..."
    mkdir -p /tmp/web
    echo '{"status": "ok", "service": "tendermint-test"}' > /tmp/web/health.json
    echo '{"jsonrpc": "2.0", "id": 1, "result": {"node_info": {"id": "test-node", "moniker": "tendermint-test"}, "sync_info": {"latest_block_height": "1"}}}' > /tmp/web/status.json
    
    # Use busybox httpd if available
    if command -v httpd >/dev/null 2>&1; then
        cd /tmp/web
        exec httpd -f -p $PORT
    else
        echo "No suitable HTTP server found. Falling back to netcat..."
        while true; do
            echo -e "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nConnection: close\r\n\r\n{\"status\": \"ok\"}" | nc -l -p $PORT
        done
    fi
fi
