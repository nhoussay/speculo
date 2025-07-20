#!/usr/bin/env python3
"""
Speculod Web Faucet - Port 4500
Mimics Starport's token faucet functionality
"""

import json
import subprocess
import threading
import time
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import parse_qs, urlparse
import re

class FaucetHandler(BaseHTTPRequestHandler):
    
    def log_message(self, format, *args):
        """Custom log format"""
        print(f"🚰 {time.strftime('%H:%M:%S')} - {format % args}")
    
    def do_GET(self):
        """Handle GET requests"""
        parsed = urlparse(self.path)
        
        if parsed.path == '/':
            self.serve_faucet_page()
        elif parsed.path == '/status':
            self.serve_status()
        elif parsed.path == '/health':
            self.serve_health()
        else:
            self.send_error(404, "Not Found")
    
    def do_POST(self):
        """Handle POST requests"""
        if self.path == '/':
            self.handle_faucet_request()
        else:
            self.send_error(404, "Not Found")
    
    def serve_faucet_page(self):
        """Serve the main faucet interface"""
        html = """<!DOCTYPE html>
<html>
<head>
    <title>Speculod Token Faucet</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; max-width: 600px; margin: 50px auto; padding: 20px; }
        .header { text-align: center; margin-bottom: 40px; }
        .faucet-box { border: 2px solid #007acc; border-radius: 8px; padding: 30px; background: #f8f9fa; }
        .form-group { margin-bottom: 20px; }
        label { display: block; margin-bottom: 5px; font-weight: bold; }
        input[type="text"], input[type="number"] { width: 100%; padding: 10px; border: 1px solid #ccc; border-radius: 4px; box-sizing: border-box; }
        button { background: #007acc; color: white; padding: 12px 24px; border: none; border-radius: 4px; cursor: pointer; font-size: 16px; }
        button:hover { background: #005a9e; }
        .result { margin-top: 20px; padding: 15px; border-radius: 4px; }
        .success { background: #d4edda; border: 1px solid #c3e6cb; color: #155724; }
        .error { background: #f8d7da; border: 1px solid #f5c6cb; color: #721c24; }
        .info { background: #cce7ff; border: 1px solid #99d6ff; color: #0066cc; margin-bottom: 20px; }
        .code { background: #f1f1f1; padding: 2px 4px; border-radius: 3px; font-family: monospace; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🚰 Speculod Token Faucet</h1>
        <p>Get test tokens for the Speculod blockchain</p>
    </div>
    
    <div class="info">
        <strong>ℹ️ Starport-style Development Faucet</strong><br>
        This faucet provides test tokens for development. Default amount: <span class="code">1,000,000 stake</span>
    </div>
    
    <div class="faucet-box">
        <form onsubmit="requestTokens(event)">
            <div class="form-group">
                <label for="address">Wallet Address:</label>
                <input type="text" id="address" name="address" placeholder="speculo1..." required>
                <small>Enter a valid Speculod address (starts with 'speculo1')</small>
            </div>
            
            <div class="form-group">
                <label for="amount">Amount (stake tokens):</label>
                <input type="number" id="amount" name="amount" value="1000000" min="1" max="10000000">
                <small>Maximum: 10,000,000 stake per request</small>
            </div>
            
            <button type="submit">💰 Request Tokens</button>
        </form>
        
        <div id="result"></div>
    </div>
    
    <div style="margin-top: 40px; text-align: center; color: #666;">
        <h3>Quick Start Commands</h3>
        <p>Create a new account: <span class="code">./scripts/faucet.sh create myaccount</span></p>
        <p>Check balance: <span class="code">./scripts/faucet.sh balance [address]</span></p>
        <p>Send tokens via CLI: <span class="code">./scripts/faucet.sh send [address] [amount]</span></p>
    </div>

    <script>
        async function requestTokens(event) {
            event.preventDefault();
            const address = document.getElementById('address').value;
            const amount = document.getElementById('amount').value;
            const resultDiv = document.getElementById('result');
            
            resultDiv.innerHTML = '<div class="result">⏳ Processing request...</div>';
            
            try {
                const response = await fetch('/', {
                    method: 'POST',
                    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
                    body: `address=${encodeURIComponent(address)}&amount=${encodeURIComponent(amount)}`
                });
                
                const result = await response.json();
                
                if (result.success) {
                    resultDiv.innerHTML = `
                        <div class="result success">
                            <strong>✅ Tokens sent successfully!</strong><br>
                            Address: <code>${result.address}</code><br>
                            Amount: <code>${result.amount} stake</code><br>
                            TX Hash: <code>${result.txhash}</code>
                        </div>`;
                } else {
                    resultDiv.innerHTML = `
                        <div class="result error">
                            <strong>❌ Error:</strong> ${result.error}
                        </div>`;
                }
            } catch (error) {
                resultDiv.innerHTML = `
                    <div class="result error">
                        <strong>❌ Network Error:</strong> ${error.message}
                    </div>`;
            }
        }
    </script>
</body>
</html>"""
        
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.send_header('Content-Length', str(len(html.encode())))
        self.end_headers()
        self.wfile.write(html.encode())
    
    def handle_faucet_request(self):
        """Handle token request"""
        try:
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length).decode('utf-8')
            params = parse_qs(post_data)
            
            address = params.get('address', [''])[0].strip()
            amount = params.get('amount', ['1000000'])[0]
            
            # Validate address
            if not re.match(r'^speculo1[a-z0-9]{38}$', address):
                self.send_json_response({'success': False, 'error': 'Invalid address format'})
                return
            
            # Validate amount
            try:
                amount_int = int(amount)
                if amount_int < 1 or amount_int > 10000000:
                    self.send_json_response({'success': False, 'error': 'Amount must be between 1 and 10,000,000'})
                    return
            except ValueError:
                self.send_json_response({'success': False, 'error': 'Invalid amount'})
                return
            
            # Call the faucet script
            cmd = ['/usr/local/bin/faucet.sh', 'send', address, f'{amount}stake']
            result = subprocess.run(cmd, capture_output=True, text=True)
            
            if result.returncode == 0:
                # Extract transaction hash from output
                txhash = "unknown"
                for line in result.stdout.split('\\n'):
                    if 'TX Hash:' in line:
                        txhash = line.split('TX Hash:')[1].strip()
                        break
                
                self.send_json_response({
                    'success': True,
                    'address': address,
                    'amount': amount,
                    'txhash': txhash
                })
            else:
                error_msg = result.stderr.strip() or result.stdout.strip() or 'Unknown error'
                self.send_json_response({'success': False, 'error': error_msg})
                
        except Exception as e:
            self.send_json_response({'success': False, 'error': str(e)})
    
    def serve_status(self):
        """Serve faucet status"""
        try:
            # Check if blockchain is running
            result = subprocess.run(['docker', 'ps', '--filter', 'name=speculod-local', '--filter', 'status=running'], 
                                  capture_output=True, text=True)
            
            running = 'speculod-local' in result.stdout
            
            status = {
                'faucet_running': True,
                'blockchain_running': running,
                'default_amount': '1000000 stake',
                'max_amount': '10000000 stake'
            }
            
            self.send_json_response(status)
        except Exception as e:
            self.send_json_response({'error': str(e)})
    
    def serve_health(self):
        """Health check endpoint"""
        self.send_json_response({'status': 'healthy', 'service': 'speculod-faucet'})
    
    def send_json_response(self, data):
        """Send JSON response"""
        response = json.dumps(data, indent=2)
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Content-Length', str(len(response.encode())))
        self.end_headers()
        self.wfile.write(response.encode())

def run_faucet_server():
    """Run the faucet web server"""
    server_address = ('localhost', 4500)
    httpd = HTTPServer(server_address, FaucetHandler)
    
    print("🚰 Speculod Web Faucet Server")
    print("=" * 30)
    print(f"🌐 Server running at: http://localhost:4500")
    print(f"📊 Status endpoint: http://localhost:4500/status")
    print(f"💊 Health check: http://localhost:4500/health")
    print("Press Ctrl+C to stop")
    print("")
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\\n🛑 Faucet server stopped")
        httpd.server_close()

if __name__ == '__main__':
    run_faucet_server()
