# Speculod Testing System

## 📦 Modules Covered

- **Prediction Module (Order Book)**
- **Settlement Module (Decentralized Market Resolution)**

This document provides a comprehensive overview of the testing systems for both the prediction (order book) and settlement modules in Speculod. It includes architecture, scenarios, test runner usage, and best practices for both modules.

---

# 🧠 Prediction Module (Order Book) Testing

## 🎯 Overview

This comprehensive testing system validates the Speculod prediction market order book functionality. The system includes both build-time tests and interactive Jupyter notebook testing to ensure robust order matching, partial fills, and market isolation.

## 🏗️ Architecture

### Build-Time Tests
- **Location**: `x/prediction/keeper/`
- **Files**: 
  - `order_book_test.go` - Core functionality tests
  - `integration_test.go` - Realistic scenario tests
  - `keeper_test.go` - Existing keeper tests

### Interactive Tests
- **Location**: `tests/`
- **File**: `order_book_testing.ipynb` - Jupyter notebook for interactive testing

### Documentation
- **Location**: `docs/`
- **File**: `testing.md` - Comprehensive testing documentation

### Test Runner
- **Location**: `scripts/`
- **File**: `run_tests.sh` - Easy-to-use test runner script

## 🚀 Quick Start

### Run All Prediction Module Tests
```bash
./scripts/run_tests.sh
```

### Run Tests with Verbose Output
```bash
./scripts/run_tests.sh -v
```

### Run Benchmarks
```bash
./scripts/run_tests.sh -b
```

### Run Specific Test
```bash
./scripts/run_tests.sh -s TestOrderMatching_BasicMatch -v
```

### Open Interactive Jupyter Notebook
```bash
./scripts/run_tests.sh -j
```

## 📋 Test Scenarios

### 1. Basic Order Matching ✅
- **Purpose**: Verify basic buy/sell order matching
- **Scenario**: Alice sells 100 @ 100, Bob buys 100 @ 100
- **Expected**: One trade, both orders filled

### 2. Partial Fill Test ✅
- **Purpose**: Verify large orders can partially fill multiple smaller orders
- **Scenario**: Multiple small sells, one large buy
- **Expected**: Multiple trades, correct amount distribution

### 3. Price-Time Priority Test ✅
- **Purpose**: Verify orders filled by best price first, then earliest time
- **Scenario**: Multiple orders at same price with different timestamps
- **Expected**: Orders filled in priority order

### 4. No Match Test ✅
- **Purpose**: Verify orders don't match when prices don't cross
- **Scenario**: Buy order below best ask
- **Expected**: No trades, orders remain open

### 5. Cross-Market Isolation Test ✅
- **Purpose**: Verify orders in different markets don't interfere
- **Scenario**: Orders in Market 1 and Market 2
- **Expected**: Only Market 1 orders match

### 6. Cross-Outcome Isolation Test ✅
- **Purpose**: Verify orders for different outcomes don't interfere
- **Scenario**: Orders for Outcome 0 and Outcome 1
- **Expected**: Only Outcome 0 orders match

### 7. Edge Cases Test ✅
- **Purpose**: Test various edge cases and error conditions
- **Scenarios**: Zero amounts, invalid prices, filled orders
- **Expected**: Graceful handling of invalid inputs

## 📊 Performance Metrics

### Benchmarks
- **Price Parsing**: ~3.2M operations/second
- **Order Comparison**: ~98M operations/second
- **Memory Usage**: Low (in-memory order book)
- **Scalability**: Good for typical prediction market volumes

### Test Results
```
=== RUN   TestOrderBookIntegration_CompleteScenario
--- PASS: TestOrderBookIntegration_CompleteScenario (0.00s)
=== RUN   TestOrderBookIntegration_PartialFills
--- PASS: TestOrderBookIntegration_PartialFills (0.00s)
=== RUN   TestOrderBookIntegration_NoMatch
--- PASS: TestOrderBookIntegration_NoMatch (0.00s)
=== RUN   TestOrderBookIntegration_CrossMarketIsolation
--- PASS: TestOrderBookIntegration_CrossMarketIsolation (0.00s)
=== RUN   TestOrderBookIntegration_CrossOutcomeIsolation
--- PASS: TestOrderBookIntegration_CrossOutcomeIsolation (0.00s)
=== RUN   TestOrderMatching_BasicMatch
--- PASS: TestOrderMatching_BasicMatch (0.00s)
...
PASS
ok      speculod/x/prediction/keeper    0.471s
```

## 🔧 Order Matching Algorithm

### Core Logic
1. **Order Validation**: Check order validity (price, amount, status)
2. **Candidate Selection**: Find opposite orders in same market/outcome
3. **Price Filtering**: Filter by price compatibility
4. **Sorting**: Sort by price-time priority
5. **Matching**: Execute trades in priority order
6. **Status Updates**: Update order statuses and filled amounts

### Priority Rules
- **Buy Orders**: Lowest sell price first, then earliest timestamp
- **Sell Orders**: Highest buy price first, then earliest timestamp

### Matching Conditions
- **Buy Order Matches Sell Order**: `buyPrice >= sellPrice`
- **Sell Order Matches Buy Order**: `sellPrice <= buyPrice`
- **Additional Requirements**: Same market, same outcome, OPEN/PARTIALLY_FILLED status

## 📁 File Structure

```
speculod/
├── x/prediction/keeper/
│   ├── order_book_test.go      # Core order book tests
│   ├── integration_test.go     # Integration tests
│   └── keeper_test.go         # Existing keeper tests
├── tests/
│   └── order_book_testing.ipynb  # Interactive Jupyter notebook
├── docs/
│   └── testing.md             # Comprehensive documentation
├── scripts/
│   └── run_tests.sh           # Test runner script
└── README_TESTING.md          # This file
```

## 🎮 Interactive Testing

The Jupyter notebook (`tests/order_book_testing.ipynb`) provides:

### Test Scenarios
- Complete order book scenarios with visualizations
- Step-by-step trade execution analysis
- Performance benchmarking
- Edge case exploration

### Features
- Interactive order creation and matching
- Real-time trade visualization
- Performance metrics and charts
- Comprehensive documentation

### Usage
```bash
# Install Jupyter (if not already installed)
pip install jupyter

# Open the notebook
./scripts/run_tests.sh -j
```

## 🛠️ Development

### Adding New Tests
1. Follow existing naming conventions
2. Add comprehensive test cases
3. Include edge cases
4. Document test purpose and expected behavior
5. Update documentation

### Test Guidelines
- **Isolation**: Each test should be independent
- **Clarity**: Test names should be descriptive
- **Coverage**: Test both success and failure cases
- **Performance**: Tests should run quickly
- **Maintainability**: Tests should be easy to understand and modify

## 📈 Monitoring and Metrics

### Key Metrics
1. **Order Volume**: Total orders processed
2. **Trade Volume**: Total trades executed
3. **Fill Rate**: Percentage of orders filled
4. **Latency**: Order processing time
5. **Error Rate**: Failed order percentage

### Health Checks
1. **Order Book Integrity**: Verify order status consistency
2. **Trade Validation**: Verify trade amounts and prices
3. **Market Isolation**: Verify no cross-market trades
4. **Outcome Isolation**: Verify no cross-outcome trades

## 🚨 Error Handling

### Validation Errors
- Invalid price format
- Zero or negative amounts
- Invalid order side
- Invalid market/outcome references

### Business Logic Errors
- Orders already filled
- Orders already cancelled
- Insufficient liquidity
- Price not crossing

## 🔄 CI/CD Integration

### Pre-Deployment Checklist
- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] Performance benchmarks meet requirements
- [ ] Error handling tested
- [ ] Edge cases covered

### Post-Deployment Monitoring
- [ ] Monitor order book performance
- [ ] Track trade execution accuracy
- [ ] Monitor error rates
- [ ] Validate market isolation
- [ ] Check outcome isolation

## 📚 Documentation

### Comprehensive Documentation
- **Location**: `docs/testing.md`
- **Content**: Detailed test scenarios, algorithms, and guidelines
- **Usage**: Reference for developers and testers

---

# 🏛️ Settlement Module (Decentralized Market Resolution) Testing

## Overview

This section describes the comprehensive test suite for the settlement module, which implements a decentralized market resolution engine using commit-reveal voting with reputation-weighted consensus.

## Test Structure

The settlement module tests are organized into several categories, following the same pattern as the prediction module tests:

### 1. Integration Tests (`integration_test.go`)

**Purpose**: Test complete settlement scenarios and workflows

**Key Test Cases**:
- `TestSettlementIntegration_CompleteScenario`: Full commit-reveal-finalize flow
- `TestSettlementIntegration_PartialReveal`: Some voters don't reveal their votes
- `TestSettlementIntegration_NoReveals`: All voters commit but none reveal
- `TestSettlementIntegration_CrossMarketIsolation`: Votes for different markets are isolated

**Coverage**:
- Complete settlement workflow
- Vote distribution calculation
- Reputation-weighted voting
- Consensus determination
- Reputation adjustments
- Market isolation
- Commitment-reveal matching

### 2. Unit Tests (`settlement_test.go`)

**Purpose**: Test individual components and functions in isolation

**Key Test Cases**:
- `TestCommitmentGeneration`: Commitment generation and validation
- `TestVoteValidation`: Vote validation against allowed outcomes
- `TestNonceValidation`: Nonce length and format validation
- `TestCommitmentValidation`: Commitment format validation
- `TestVoteDistribution`: Vote distribution calculation
- `TestReputationWeightedVoting`: Reputation-weighted vote calculation
- `TestConsensusDetermination`: Consensus outcome determination
- `TestReputationAdjustment`: Reputation score adjustments
- `TestRevealRateCalculation`: Reveal rate calculation
- `TestMarketIsolation`: Market isolation logic
- `TestCommitmentRevealMatching`: Commitment-reveal pair validation

**Coverage**:
- Core logic functions
- Data validation
- Mathematical calculations
- State transitions

### 3. Message Server Tests (`msg_server_test.go`)

**Purpose**: Test message handling and validation

**Key Test Cases**:
- `TestMsgCommitVote_ValidCommit`: Valid vote commitment
- `TestMsgCommitVote_InvalidCommitment`: Invalid commitment format
- `TestMsgRevealVote_ValidReveal`: Valid vote reveal
- `TestMsgRevealVote_InvalidVote`: Invalid vote values
- `TestMsgRevealVote_InvalidNonce`: Invalid nonce values
- `TestMsgFinalizeOutcome_ValidFinalize`: Valid outcome finalization
- `TestCommitmentRevealMatching_ValidPair`: Valid commitment-reveal pairs
- `TestCommitmentRevealMatching_InvalidPair`: Invalid commitment-reveal pairs
- `TestMessageValidation_RequiredFields`: Required field validation
- `TestMessageConsistency`: Message consistency across operations
- `TestMessageIsolation`: Message isolation between markets and users

**Coverage**:
- Message structure validation
- Field validation
- Cross-message consistency
- Error handling

### 4. Keeper Operations Tests (`keeper_operations_test.go`)

**Purpose**: Test core keeper storage and retrieval operations

**Key Test Cases**:
- `TestKeeperOperations_CommitStorage`: Commit storage operations
- `TestKeeperOperations_RevealStorage`: Reveal storage operations
- `TestKeeperOperations_OutcomeStorage`: Outcome storage operations
- `TestKeeperOperations_KeyGeneration`: Key generation for different scenarios
- `TestKeeperOperations_DataValidation`: Data validation for keeper operations
- `TestKeeperOperations_CrossMarketIsolation`: Isolation between different markets
- `TestKeeperOperations_DataConsistency`: Data consistency across operations
- `TestKeeperOperations_ErrorHandling`: Error handling scenarios
- `TestKeeperOperations_Performance`: Performance characteristics

**Coverage**:
- Storage operations
- Key generation
- Data validation
- Error handling
- Performance characteristics

## Test Scenarios

### Complete Settlement Scenario

1. **Commit Phase**: Multiple users commit their votes with hashed commitments
2. **Reveal Phase**: Users reveal their actual votes and nonces
3. **Validation**: System validates commitment-reveal pairs
4. **Vote Distribution**: Calculate vote distribution across outcomes
5. **Reputation Weighting**: Apply reputation weights to votes
6. **Consensus Determination**: Determine final outcome based on weighted votes
7. **Reputation Adjustment**: Adjust reputation scores based on voting accuracy

### Partial Reveal Scenario

1. **Commit Phase**: All users commit their votes
2. **Partial Reveal**: Only some users reveal their votes
3. **Reveal Rate Calculation**: Calculate percentage of users who revealed
4. **Weighted Voting**: Apply reputation weights only to revealed votes
5. **Consensus**: Determine outcome based on available reveals

### Market Isolation Scenario

1. **Multiple Markets**: Test votes for different markets
2. **Same User**: Same user voting on different markets
3. **Isolation Verification**: Ensure votes are properly isolated
4. **Key Generation**: Verify unique keys for different markets

## Key Features Tested

### 1. Commit-Reveal Mechanism

- **Commitment Generation**: SHA256 hash of (vote + nonce)
- **Commitment Validation**: 64-character hex string format
- **Reveal Validation**: Vote and nonce must match original commitment
- **Nonce Validation**: 8-64 character length requirement

### 2. Reputation-Weighted Voting

- **Reputation Scores**: User reputation affects vote weight
- **Default Weight**: Users without reputation get weight of 1
- **Minimum Weight**: Minimum weight of 1 for all users
- **Weighted Tally**: Sum of reputation-weighted votes per outcome

### 3. Consensus Determination

- **Highest Weight**: Outcome with highest reputation-weighted votes wins
- **Tie Handling**: First outcome encountered in case of tie
- **No Reveals**: Handle case where no votes are revealed

### 4. Reputation Adjustments

- **Correct Votes**: Users voting with consensus gain reputation (+1)
- **Incorrect Votes**: Users voting against consensus lose reputation (-1)
- **Group Scoping**: Reputation adjustments scoped to market's group

### 5. Market Isolation

- **Cross-Market Isolation**: Votes for different markets are independent
- **Key Generation**: Unique keys for (market_id, voter) pairs
- **Data Separation**: Commits and reveals separated by market

## Running Settlement Module Tests

### Using Go Test Directly

```bash
# Run all settlement tests
go test -v ./x/settlement/keeper

# Run specific test patterns
go test -v ./x/settlement/keeper -run "^TestSettlementIntegration"
go test -v ./x/settlement/keeper -run "^TestMsg"
go test -v ./x/settlement/keeper -run "^TestKeeperOperations"

# Run benchmarks
go test -v ./x/settlement/keeper -bench=.

# Run with coverage
go test -v -cover ./x/settlement/keeper
```

## Best Practices

1. **Test Isolation**: Each test is independent and doesn't rely on other tests
2. **Clear Naming**: Test names clearly describe what is being tested
3. **Comprehensive Assertions**: Multiple assertions per test to verify behavior
4. **Edge Case Coverage**: Tests include boundary conditions and error cases
5. **Performance Testing**: Benchmarks for performance-critical functions
6. **Documentation**: Clear comments explaining test scenarios and expected outcomes

## Future Enhancements

1. **Mock Integration**: Add mock keepers for cross-module testing
2. **Property-Based Testing**: Add property-based tests for complex logic
3. **Fuzz Testing**: Add fuzz tests for input validation
4. **Load Testing**: Add tests for high-volume scenarios
5. **Concurrency Testing**: Add tests for concurrent operations

## Troubleshooting

### Common Issues

1. **Import Errors**: Ensure all required packages are imported
2. **Type Mismatches**: Verify test data matches expected types
3. **Key Generation**: Ensure keys are generated correctly for storage
4. **Commitment Validation**: Verify commitment format and length
5. **Reputation Integration**: Ensure reputation module integration works correctly

### Debug Tips

1. Use `go test -v` for verbose output
2. Use `go test -run "TestName"` to run specific tests
3. Add `t.Log()` statements for debugging
4. Use `require` instead of `assert` for immediate failure
5. Check test data structure matches actual implementation 