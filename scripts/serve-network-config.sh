#!/bin/bash

# Simple HTTP server to simulate GitHub for local testing
# This serves the network configuration files locally

echo "🌐 Starting local network configuration server..."
echo "📁 Serving files from: $(pwd)/networks/"
echo "🔗 Access at: http://localhost:8000/local-testnet/"

cd networks && python3 -m http.server 8000
