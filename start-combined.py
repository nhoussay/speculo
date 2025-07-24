#!/usr/bin/env python3
import subprocess
import time
import signal
import sys
import os

def signal_handler(sig, frame):
    print("Shutting down processes...")
    sys.exit(0)

signal.signal(signal.SIGINT, signal_handler)
signal.signal(signal.SIGTERM, signal_handler)

print("Starting combined nginx proxy service...")

# Set defaults
os.environ.setdefault('GENESIS_URL', 'https://raw.githubusercontent.com/nhoussay/speculo/main/networks/local-testnet/genesis.json')
os.environ.setdefault('PERSISTENT_PEERS', '9ff2468b686dd79ee94509a99e8a4e9ab2d5f88f@mainnet-tendermint.specu.io:26656')
os.environ.setdefault('MIN_GAS_PRICE', '0.001uspect')
os.environ.setdefault('CHAIN_ID', 'speculo-1')

# Initialize if needed
if not os.path.exists('/root/.speculod/config/genesis.json'):
    print("Initializing speculodd...")
    subprocess.run([
        'speculodd', 'init', 'speculo-persistent-node',
        f'--chain-id={os.environ["CHAIN_ID"]}',
        '--home=/root/.speculod'
    ], check=True)
    
    print("Downloading genesis...")
    subprocess.run([
        'curl', '-s', os.environ['GENESIS_URL'], 
        '-o', '/root/.speculod/config/genesis.json'
    ], check=True)
    
    if os.environ.get('PERSISTENT_PEERS'):
        # Update config with persistent peers
        with open('/root/.speculod/config/config.toml', 'r') as f:
            config = f.read()
        config = config.replace('persistent_peers = ""', f'persistent_peers = "{os.environ["PERSISTENT_PEERS"]}"')
        with open('/root/.speculod/config/config.toml', 'w') as f:
            f.write(config)

# Start speculodd in background
print("Starting speculodd in background...")
speculodd_process = subprocess.Popen([
    'speculodd', 'start',
    '--home=/root/.speculod',
    '--rpc.laddr=tcp://0.0.0.0:26657',
    '--p2p.laddr=tcp://0.0.0.0:26656',
    '--grpc.address=0.0.0.0:9090',
    '--api.address=tcp://0.0.0.0:1317',
    '--api.enable=true',
    '--grpc.enable=true',
    '--api.enabled-unsafe-cors=true',
    f'--minimum-gas-prices={os.environ["MIN_GAS_PRICE"]}'
])

# Wait for speculodd to initialize
print("Waiting for speculodd to initialize...")
time.sleep(30)

# Start nginx in foreground (this keeps the container running)
print("Starting nginx...")
try:
    subprocess.run(['nginx', '-g', 'daemon off;'], check=True)
except KeyboardInterrupt:
    print("Received interrupt signal")
finally:
    print("Terminating speculodd...")
    speculodd_process.terminate()
    speculodd_process.wait()
