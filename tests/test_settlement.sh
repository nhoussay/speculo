#!/bin/bash
set -e

KEYRING="test"
CHAIN_ID="speculod"
MARKET_ID=1
VOTE="Yes"
NONCE="12345"
HASH=$(echo -n "${VOTE}${NONCE}" | shasum -a 256 | awk '{print $1}')

# 1. Add key 'alice'
echo "=== 1. Add key 'alice' ==="
./speculodd keys add alice --keyring-backend $KEYRING || true

# 2. Show alice's address and balance
echo "=== 2. Show alice's address and balance ==="
ADDR=$(./speculodd keys show alice -a --keyring-backend $KEYRING)
./speculodd query bank balances $ADDR

# 3. Commit vote
echo "=== 3. Commit vote ==="
./speculodd tx settlement commit-vote $MARKET_ID $HASH --from alice --keyring-backend $KEYRING --chain-id $CHAIN_ID --yes

# 4. Reveal vote
echo "=== 4. Reveal vote ==="
./speculodd tx settlement reveal-vote $MARKET_ID $VOTE $NONCE --from alice --keyring-backend $KEYRING --chain-id $CHAIN_ID --yes

# 5. Finalize outcome
echo "=== 5. Finalize outcome ==="
./speculodd tx settlement finalize-outcome $MARKET_ID --from alice --keyring-backend $KEYRING --chain-id $CHAIN_ID --yes

# 6. Query outcome
echo "=== 6. Query outcome ==="
./speculodd query settlement outcome $MARKET_ID

# 7. Query reveals
echo "=== 7. Query reveals ==="
./speculodd query settlement reveals $MARKET_ID 