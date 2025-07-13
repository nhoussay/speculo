#!/bin/bash

# Test script for settlement module with real keepers using CLI
echo "🧪 Testing Settlement Module with Real Keepers (CLI)"

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

# Create a prediction market first using CLI
echo "📊 Creating a prediction market..."
MARKET_ID=$(./speculodd tx prediction create-market \
  --question "Will it rain tomorrow?" \
  --outcomes "Yes,No" \
  --group-id "weather-group" \
  --deadline $(($(date +%s) + 3600)) \
  --status "ACTIVE" \
  --from alice \
  --chain-id speculod \
  --yes 2>/dev/null | grep -o 'market_id: [0-9]*' | cut -d' ' -f2 || echo "1")

echo "📊 Market created with ID: $MARKET_ID"

# Test commit vote using CLI
echo "🔒 Testing commit vote..."
COMMITMENT=$(echo -n "Yes-secret123" | sha256sum | cut -d' ' -f1)
./speculodd tx settlement commit-vote \
  --market-id $MARKET_ID \
  --commitment $COMMITMENT \
  --from alice \
  --chain-id speculod \
  --yes 2>/dev/null

# Test reveal vote using CLI
echo "🔓 Testing reveal vote..."
./speculodd tx settlement reveal-vote \
  --market-id $MARKET_ID \
  --vote "Yes" \
  --nonce "secret123" \
  --from alice \
  --chain-id speculod \
  --yes 2>/dev/null

# Test finalize outcome using CLI
echo "🏁 Testing finalize outcome..."
./speculodd tx settlement finalize-outcome \
  --market-id $MARKET_ID \
  --from alice \
  --chain-id speculod \
  --yes 2>/dev/null

# Query settlement stats using CLI
echo "📈 Querying settlement stats..."
./speculodd q settlement stats $MARKET_ID 2>/dev/null

# Query reputation scores using CLI
echo "⭐ Querying reputation scores..."
./speculodd q reputation scores $ALICE weather-group 2>/dev/null

# Test query endpoints that should work via HTTP
echo "🌐 Testing HTTP query endpoints..."

# Test params query
echo "📋 Testing params query..."
curl -s "http://localhost:1317/speculod/settlement/v1/params" | jq '.'

# Test commits query
echo "🔒 Testing commits query..."
curl -s "http://localhost:1317/speculod/settlement/v1/commits/$MARKET_ID" | jq '.'

# Test reveals query
echo "🔓 Testing reveals query..."
curl -s "http://localhost:1317/speculod/settlement/v1/reveals/$MARKET_ID" | jq '.'

# Test outcome query
echo "🏁 Testing outcome query..."
curl -s "http://localhost:1317/speculod/settlement/v1/outcome/$MARKET_ID" | jq '.'

echo "✅ Settlement module with real keepers test completed!" 