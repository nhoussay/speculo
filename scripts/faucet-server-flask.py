#!/usr/bin/env python3
"""
Speculod Token Faucet - Cloud Run Compatible Flask Service
Mimics Starport's token faucet functionality with REST API integration
"""

import os
import json
import requests
import time
from flask import Flask, request, jsonify, render_template_string

app = Flask(__name__)

# Configuration from environment variables
BLOCKCHAIN_RPC = os.getenv('BLOCKCHAIN_RPC_URL', 'http://localhost:8080')
FAUCET_PORT = int(os.getenv('FAUCET_PORT', '8080'))
CHAIN_ID = os.getenv('CHAIN_ID', 'speculod')
DENOM = os.getenv('DENOM', 'stake')
AMOUNT = os.getenv('FAUCET_AMOUNT', '1000000')  # 1 token (assuming 6 decimal places)

print(f"🚰 Faucet configuration:")
print(f"- Blockchain RPC: {BLOCKCHAIN_RPC}")
print(f"- Port: {FAUCET_PORT}")
print(f"- Chain ID: {CHAIN_ID}")
print(f"- Denomination: {DENOM}")
print(f"- Amount per request: {AMOUNT}")

# HTML template for the faucet interface
FAUCET_HTML = """<!DOCTYPE html>
<html>
<head>
    <title>Speculod Token Faucet</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; max-width: 600px; margin: 50px auto; padding: 20px; }
        .header { text-align: center; margin-bottom: 40px; }
        .faucet-box { border: 2px solid #007acc; border-radius: 8px; padding: 30px; background: #f8f9fa; }
        .form-group { margin-bottom: 20px; }
        label { display: block; margin-bottom: 5px; font-weight: bold; }
        input[type="text"], input[type="number"] { width: 100%; padding: 10px; border: 1px solid #ccc; border-radius: 4px; box-sizing: border-box; }
        button { background: #007acc; color: white; padding: 12px 24px; border: none; border-radius: 4px; cursor: pointer; font-size: 16px; width: 100%; }
        button:hover { background: #005a9e; }
        .result { margin-top: 20px; padding: 15px; border-radius: 4px; }
        .success { background: #d4edda; border: 1px solid #c3e6cb; color: #155724; }
        .error { background: #f8d7da; border: 1px solid #f5c6cb; color: #721c24; }
        .info { background: #cce7ff; border: 1px solid #99d6ff; color: #0066cc; margin-bottom: 20px; }
        .code { background: #f1f1f1; padding: 2px 4px; border-radius: 3px; font-family: monospace; }
        .loading { display: none; text-align: center; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🚰 Speculod Token Faucet</h1>
        <p>Get test tokens for the Speculod blockchain</p>
    </div>
    
    <div class="info">
        <strong>ℹ️ Development Token Faucet</strong><br>
        This faucet provides test tokens for development. Default amount: <span class="code">{{ amount }} {{ denom }}</span><br>
        Chain ID: <span class="code">{{ chain_id }}</span>
    </div>
    
    <div class="faucet-box">
        <form onsubmit="requestTokens(event)">
            <div class="form-group">
                <label for="address">Wallet Address:</label>
                <input type="text" id="address" name="address" placeholder="speculo1..." required>
                <small>Enter a valid Speculod address (starts with 'speculo1')</small>
            </div>
            
            <div class="form-group">
                <label for="amount">Amount ({{ denom }} tokens):</label>
                <input type="number" id="amount" name="amount" value="{{ amount }}" min="1" max="10000000">
                <small>Maximum: 10,000,000 {{ denom }} per request</small>
            </div>
            
            <button type="submit">💰 Request Tokens</button>
            <div class="loading" id="loading">⏳ Processing request...</div>
        </form>
        
        <div id="result"></div>
    </div>
    
    <div style="margin-top: 40px; text-align: center; color: #666;">
        <h3>API Endpoints</h3>
        <p>POST <span class="code">/request</span> - Request tokens via JSON</p>
        <p>GET <span class="code">/status</span> - Faucet status</p>
        <p>GET <span class="code">/health</span> - Health check</p>
    </div>

    <script>
        async function requestTokens(event) {
            event.preventDefault();
            
            const address = document.getElementById('address').value;
            const amount = document.getElementById('amount').value;
            const resultDiv = document.getElementById('result');
            const button = event.target.querySelector('button');
            const loading = document.getElementById('loading');
            
            // Show loading
            button.style.display = 'none';
            loading.style.display = 'block';
            resultDiv.innerHTML = '';
            
            try {
                const response = await fetch('/request', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({
                        address: address,
                        amount: amount
                    })
                });
                
                const data = await response.json();
                
                if (response.ok && data.success) {
                    resultDiv.innerHTML = `
                        <div class="success">
                            ✅ <strong>Tokens sent successfully!</strong><br>
                            Amount: ${data.amount} ${data.denom}<br>
                            Transaction: <span class="code">${data.txhash || 'N/A'}</span>
                        </div>
                    `;
                } else {
                    resultDiv.innerHTML = `
                        <div class="error">
                            ❌ <strong>Error:</strong> ${data.error || 'Unknown error'}
                        </div>
                    `;
                }
            } catch (error) {
                resultDiv.innerHTML = `
                    <div class="error">
                        ❌ <strong>Request failed:</strong> ${error.message}
                    </div>
                `;
            } finally {
                // Hide loading
                button.style.display = 'block';
                loading.style.display = 'none';
            }
        }
    </script>
</body>
</html>
"""

@app.route('/')
def index():
    """Serve the faucet interface"""
    return render_template_string(FAUCET_HTML, 
                                amount=AMOUNT, 
                                denom=DENOM, 
                                chain_id=CHAIN_ID)

@app.route('/request', methods=['POST'])
def request_tokens():
    """Handle token requests"""
    try:
        data = request.json
        address = data.get('address')
        amount = data.get('amount', AMOUNT)
        
        if not address:
            return jsonify({'success': False, 'error': 'Address is required'}), 400
        
        if not address.startswith('speculo1'):
            return jsonify({'success': False, 'error': 'Invalid address format'}), 400
        
        # Simulate token sending (in a real implementation, this would interact with the blockchain)
        # For now, we'll simulate success
        result = {
            'success': True,
            'address': address,
            'amount': amount,
            'denom': DENOM,
            'txhash': f'mock_tx_{int(time.time())}',
            'message': f'Successfully sent {amount} {DENOM} to {address}'
        }
        
        return jsonify(result)
        
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/status')
def status():
    """Get faucet status"""
    try:
        # Check blockchain connectivity using Tendermint RPC /status endpoint
        blockchain_healthy = False
        try:
            response = requests.get(f'{BLOCKCHAIN_RPC}/status', timeout=5)
            blockchain_healthy = response.status_code == 200 and 'node_info' in response.text
        except:
            pass
        
        return jsonify({
            'faucet_running': True,
            'blockchain_connected': blockchain_healthy,
            'blockchain_rpc': BLOCKCHAIN_RPC,
            'chain_id': CHAIN_ID,
            'default_amount': f'{AMOUNT} {DENOM}',
            'max_amount': f'10000000 {DENOM}'
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/health')
def health():
    """Health check endpoint"""
    return jsonify({'status': 'healthy', 'service': 'speculod-faucet'})

if __name__ == '__main__':
    print("🚰 Starting Speculod Token Faucet Service...")
    print(f"🌐 Server will run on: http://0.0.0.0:{FAUCET_PORT}")
    print(f"📊 Status endpoint: http://0.0.0.0:{FAUCET_PORT}/status")
    print(f"💊 Health check: http://0.0.0.0:{FAUCET_PORT}/health")
    
    app.run(host='0.0.0.0', port=FAUCET_PORT, debug=False)
