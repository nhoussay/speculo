#!/bin/bash

# Test script for settlement module with real keepers
echo "🧪 Testing Settlement Module with Real Keepers"

# Wait for blockchain to be ready
echo "⏳ Waiting for blockchain to be ready..."
sleep 5

# Check if blockchain is running
if ! curl -s http://localhost:1317/cosmos/base/tendermint/v1beta1/node_info > /dev/null; then
    echo "❌ Blockchain is not running. Please start it with 'starport chain serve'"
    exit 1
fi

echo "✅ Blockchain is running"

# Test account addresses
ALICE="cosmos1ujnkqwafr7pf30flp6z7we5a4s6z"
BOB="cosmos12vesvj85vvf6gsgrj0kgldep7efrr9"

echo "👤 Alice: $ALICE"
echo "👤 Bob: $BOB"

# Create a prediction market first
echo "📊 Creating a prediction market..."
MARKET_ID=$(curl -s -X POST http://localhost:1317/speculod/prediction/v1/markets \
  -H "Content-Type: application/json" \
  -d '{
    "market": {
      "question": "Will it rain tomorrow?",
      "outcomes": ["Yes", "No"],
      "groupId": "weather-group",
      "deadline": "'$(($(date +%s) + 3600))'",
      "status": "ACTIVE",
      "creator": "'$ALICE'"
    }
  }' | jq -r '.market.id // "1"')

echo "📊 Market created with ID: $MARKET_ID"

# Test commit vote
echo "🔒 Testing commit vote..."
COMMITMENT=$(echo -n "Yes-secret123" | sha256sum | cut -d' ' -f1)
curl -s -X POST http://localhost:1317/speculod/settlement/v1/commits \
  -H "Content-Type: application/json" \
  -d '{
    "commit": {
      "marketId": "'$MARKET_ID'",
      "creator": "'$ALICE'",
      "commitment": "'$COMMITMENT'"
    }
  }' | jq '.'

# Test reveal vote
echo "🔓 Testing reveal vote..."
curl -s -X POST http://localhost:1317/speculod/settlement/v1/reveals \
  -H "Content-Type: application/json" \
  -d '{
    "reveal": {
      "marketId": "'$MARKET_ID'",
      "creator": "'$ALICE'",
      "vote": "Yes",
      "nonce": "secret123"
    }
  }' | jq '.'

# Test finalize outcome
echo "🏁 Testing finalize outcome..."
curl -s -X POST http://localhost:1317/speculod/settlement/v1/finalize \
  -H "Content-Type: application/json" \
  -d '{
    "finalize": {
      "marketId": "'$MARKET_ID'",
      "creator": "'$ALICE'"
    }
  }' | jq '.'

# Query settlement stats
echo "📈 Querying settlement stats..."
curl -s "http://localhost:1317/speculod/settlement/v1/stats/$MARKET_ID" | jq '.'

# Query reputation scores
echo "⭐ Querying reputation scores..."
curl -s "http://localhost:1317/speculod/reputation/v1/scores/$ALICE/weather-group" | jq '.'

echo "✅ Settlement module with real keepers test completed!" 