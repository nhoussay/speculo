#!/bin/sh

# Speculod RPC Service - Minimal startup for Cloud Run
set -e

echo "Starting Speculod RPC Service..."

# Cloud Run port configuration
PORT=${PORT:-8080}
echo "Using port: $PORT"

# Default environment variables
export MONIKER=${MONIKER:-"rpc-node"}
export CHAIN_ID=${CHAIN_ID:-"speculod-testnet"}
export MINIMUM_GAS_PRICES=${MINIMUM_GAS_PRICES:-"0.001stake"}

# Home directory setup
export HOME=/home/speculod
SPECULOD_HOME="$HOME/.speculod"

echo "Blockchain home: $SPECULOD_HOME"

# Minimal initialization
if [ ! -d "$SPECULOD_HOME/config" ]; then
    echo "Initializing node config..."
    speculodd init $MONIKER --chain-id=$CHAIN_ID --home=$SPECULOD_HOME
    echo "Init completed"
fi

echo "Starting RPC server on port $PORT..."

# Minimal start command for RPC only
exec speculodd start \
    --home=$SPECULOD_HOME \
    --rpc.laddr=tcp://0.0.0.0:$PORT \
    --api.enable=false \
    --grpc.enable=false
