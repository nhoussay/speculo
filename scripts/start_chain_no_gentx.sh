#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BINARY="$PROJECT_DIR/speculodd"
CHAIN_ID="speculod"
KEYRING="test"
MONIKER="mynode"
CONFIG_DIR="$PROJECT_DIR/.speculod"
GENESIS_ACCOUNT_NAME="alice"
GENESIS_ACCOUNT_COINS="100000000stake"
GENESIS_INFO_FILE="$PROJECT_DIR/genesis_accounts.txt"

# Get blockchain version
BLOCKCHAIN_VERSION=$($BINARY version 2>/dev/null || echo "unknown")

if [ -d "$CONFIG_DIR" ]; then
  echo "Removing existing chain data in $CONFIG_DIR..."
  rm -rf "$CONFIG_DIR"
fi

# Check if .speculod config exists in project directory
if [ ! -d "$CONFIG_DIR" ]; then
  echo "Initializing chain in $CONFIG_DIR..."
  $BINARY init $MONIKER --chain-id $CHAIN_ID --home $CONFIG_DIR
  echo "Chain initialized."

  echo "Adding genesis account '$GENESIS_ACCOUNT_NAME'..."
  # Capture mnemonic
  GENESIS_MNEMONIC=$($BINARY keys add $GENESIS_ACCOUNT_NAME --keyring-backend $KEYRING --home $CONFIG_DIR 2>&1 | grep -A 12 "important" | tail -n +2 | xargs)

# If account exists, get mnemonic from file (optional: handle as needed)
GENESIS_ACCOUNT_ADDR=$($BINARY keys show $GENESIS_ACCOUNT_NAME -a --keyring-backend $KEYRING --home $CONFIG_DIR)
  
  # Pass all necessary flags to the add-genesis-account command
  echo "Executing: $BINARY add-genesis-account $GENESIS_ACCOUNT_NAME $GENESIS_ACCOUNT_COINS --home $CONFIG_DIR --keyring-backend $KEYRING"
  $BINARY add-genesis-account $GENESIS_ACCOUNT_NAME $GENESIS_ACCOUNT_COINS --home $CONFIG_DIR --keyring-backend $KEYRING

  echo "Skipping genesis transaction generation due to signing issues..."
  echo "Creating a minimal validator configuration for development..."

  # Create a minimal gentx manually for development
  # This is a workaround for the address prefix signing issue
  echo "Attempting to create validator after chain initialization..."
  
  # For now, we'll try to start without a validator and document the limitation
  echo "WARNING: Starting without validators - this blockchain won't produce blocks"
  echo "This is a development-only configuration."

  echo "Validating genesis file..."
  $BINARY validate-genesis --home $CONFIG_DIR

  # Write genesis info to file
  echo "Writing genesis account info to $GENESIS_INFO_FILE"
  {
    echo "Blockchain version: $BLOCKCHAIN_VERSION"
    echo "Genesis account: $GENESIS_ACCOUNT_NAME"
    echo "Address: $GENESIS_ACCOUNT_ADDR"
    echo "Mnemonic: $GENESIS_MNEMONIC"
    echo "Coins: $GENESIS_ACCOUNT_COINS"
    echo "Chain ID: $CHAIN_ID"
    echo "Created: $(date)"
    echo "Note: Started without validators due to gentx signing issues"
    echo "----------------------------------------"
  } >> "$GENESIS_INFO_FILE"
else
  echo "Chain already initialized in $CONFIG_DIR."
fi

echo "Starting $BINARY node..."
$BINARY start --home $CONFIG_DIR --minimum-gas-prices=0.025stake
