#!/bin/bash

# Speculod Token Faucet Service
# Provides tokens for development and testing

set -e

CONTAINER_NAME="${CONTAINER_NAME:-speculod-local}"
FAUCET_AMOUNT="${FAUCET_AMOUNT:-1000000stake}"
KEY_NAME="${KEY_NAME:-alice}"
HOME_DIR="${HOME_DIR:-/home/speculod/.speculod}"

echo "🚰 Speculod Token Faucet"
echo "======================="

# Check if we're running in a container or if blockchain is accessible locally
if [ "$CONTAINER_NAME" = "localhost" ]; then
    # Running locally (cloud mode or direct local execution)
    EXEC_PREFIX=""
else
    # Running with Docker container
    if ! docker ps --filter "name=$CONTAINER_NAME" --filter "status=running" | grep -q $CONTAINER_NAME; then
        echo "❌ Error: Container $CONTAINER_NAME is not running"
        echo "   Start it first with: ./scripts/deploy-local.sh"
        exit 1
    fi
    EXEC_PREFIX="docker exec $CONTAINER_NAME"
fi

# Function to send tokens
send_tokens() {
    local recipient=$1
    local amount=${2:-$FAUCET_AMOUNT}
    
    echo "💰 Sending $amount to $recipient..."
    
    # Execute the transfer
    result=$($EXEC_PREFIX speculodd tx bank send $KEY_NAME $recipient $amount \
        --home $HOME_DIR \
        --keyring-backend test \
        --chain-id ${CHAIN_ID:-speculod} \
        --yes \
        --output json 2>&1)
    
    if echo "$result" | grep -q "txhash"; then
        txhash=$(echo "$result" | jq -r '.txhash' 2>/dev/null || echo "unknown")
        echo "✅ Transaction sent successfully!"
        echo "   Recipient: $recipient"
        echo "   Amount: $amount" 
        echo "   TX Hash: $txhash"
        return 0
    else
        echo "❌ Transaction failed:"
        echo "$result"
        return 1
    fi
}

# Function to get balance
get_balance() {
    local address=$1
    echo "💳 Checking balance for $address..."
    
    balance=$($EXEC_PREFIX speculodd query bank balance $address stake \
        --home $HOME_DIR \
        --output json 2>/dev/null | jq -r '.amount // "0"')
    
    echo "   Balance: $balance stake"
}

# Function to create a new account
create_account() {
    local account_name=$1
    echo "🔑 Creating new account: $account_name..."
    
    result=$($EXEC_PREFIX speculodd keys add $account_name \
        --home $HOME_DIR \
        --keyring-backend test \
        --output json 2>&1)
    
    if echo "$result" | grep -q "address"; then
        address=$(echo "$result" | jq -r '.address')
        echo "✅ Account created successfully!"
        echo "   Name: $account_name"
        echo "   Address: $address"
        echo "$address"
        return 0
    else
        echo "❌ Failed to create account:"
        echo "$result"
        return 1
    fi
}

# Main faucet logic
case "${1:-help}" in
    "send")
        if [ -z "$2" ]; then
            echo "Usage: $0 send <address> [amount]"
            echo "Example: $0 send speculo1abc123... 5000000stake"
            exit 1
        fi
        send_tokens "$2" "$3"
        ;;
    "balance")
        if [ -z "$2" ]; then
            echo "Usage: $0 balance <address>"
            echo "Example: $0 balance speculo1abc123..."
            exit 1
        fi
        get_balance "$2"
        ;;
    "create")
        if [ -z "$2" ]; then
            echo "Usage: $0 create <account_name>"
            echo "Example: $0 create bob"
            exit 1
        fi
        address=$(create_account "$2")
        if [ $? -eq 0 ] && [ -n "$address" ]; then
            echo ""
            echo "🚰 Auto-funding new account with $FAUCET_AMOUNT..."
            send_tokens "$address"
        fi
        ;;
    "list")
        echo "📋 Available accounts:"
        $EXEC_PREFIX speculodd keys list --home $HOME_DIR --keyring-backend test
        ;;
    "help"|*)
        echo "Speculod Token Faucet Commands:"
        echo ""
        echo "  send <address> [amount]    Send tokens to an address"
        echo "  balance <address>          Check balance of an address"  
        echo "  create <name>             Create new account and fund it"
        echo "  list                      List all available accounts"
        echo "  help                      Show this help"
        echo ""
        echo "Examples:"
        echo "  $0 create bob                    # Create account 'bob' and fund it"
        echo "  $0 send speculo1abc... 5000000stake  # Send 5M tokens"
        echo "  $0 balance speculo1abc...        # Check balance"
        echo ""
        echo "Default faucet amount: $FAUCET_AMOUNT"
        ;;
esac
