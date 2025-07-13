#!/bin/bash

# Settlement Module Test Runner
# This script runs all tests for the settlement module

echo "🧪 Running Settlement Module Tests"
echo "=================================="

# Set the module path
MODULE_PATH="speculod/x/settlement"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to run tests for a specific file
run_test_file() {
    local test_file=$1
    local test_name=$(basename $test_file .go)
    
    echo -e "\n${YELLOW}Running tests in: $test_name${NC}"
    echo "----------------------------------------"
    
    if go test -v ./$MODULE_PATH/keeper -run "^Test.*$test_name" 2>/dev/null; then
        echo -e "${GREEN}✓ $test_name tests passed${NC}"
        return 0
    else
        echo -e "${RED}✗ $test_name tests failed${NC}"
        return 1
    fi
}

# Function to run all tests
run_all_tests() {
    echo -e "\n${YELLOW}Running all settlement tests...${NC}"
    echo "----------------------------------------"
    
    if go test -v ./$MODULE_PATH/keeper; then
        echo -e "\n${GREEN}✓ All settlement tests passed!${NC}"
        return 0
    else
        echo -e "\n${RED}✗ Some settlement tests failed${NC}"
        return 1
    fi
}

# Function to run specific test categories
run_integration_tests() {
    echo -e "\n${YELLOW}Running integration tests...${NC}"
    echo "----------------------------------------"
    
    if go test -v ./$MODULE_PATH/keeper -run "^TestSettlementIntegration"; then
        echo -e "${GREEN}✓ Integration tests passed${NC}"
        return 0
    else
        echo -e "${RED}✗ Integration tests failed${NC}"
        return 1
    fi
}

run_unit_tests() {
    echo -e "\n${YELLOW}Running unit tests...${NC}"
    echo "----------------------------------------"
    
    if go test -v ./$MODULE_PATH/keeper -run "^Test(CommitmentGeneration|VoteValidation|NonceValidation|CommitmentValidation|VoteDistribution|ReputationWeightedVoting|ConsensusDetermination|ReputationAdjustment|RevealRateCalculation|MarketIsolation|CommitmentRevealMatching)"; then
        echo -e "${GREEN}✓ Unit tests passed${NC}"
        return 0
    else
        echo -e "${RED}✗ Unit tests failed${NC}"
        return 1
    fi
}

run_message_tests() {
    echo -e "\n${YELLOW}Running message server tests...${NC}"
    echo "----------------------------------------"
    
    if go test -v ./$MODULE_PATH/keeper -run "^TestMsg"; then
        echo -e "${GREEN}✓ Message server tests passed${NC}"
        return 0
    else
        echo -e "${RED}✗ Message server tests failed${NC}"
        return 1
    fi
}

run_keeper_tests() {
    echo -e "\n${YELLOW}Running keeper operation tests...${NC}"
    echo "----------------------------------------"
    
    if go test -v ./$MODULE_PATH/keeper -run "^TestKeeperOperations"; then
        echo -e "${GREEN}✓ Keeper operation tests passed${NC}"
        return 0
    else
        echo -e "${RED}✗ Keeper operation tests failed${NC}"
        return 1
    fi
}

# Function to run benchmarks
run_benchmarks() {
    echo -e "\n${YELLOW}Running benchmarks...${NC}"
    echo "----------------------------------------"
    
    if go test -v ./$MODULE_PATH/keeper -bench=. -run=^$; then
        echo -e "${GREEN}✓ Benchmarks completed${NC}"
        return 0
    else
        echo -e "${RED}✗ Benchmarks failed${NC}"
        return 1
    fi
}

# Function to show test coverage
run_coverage() {
    echo -e "\n${YELLOW}Running tests with coverage...${NC}"
    echo "----------------------------------------"
    
    if go test -v -cover ./$MODULE_PATH/keeper; then
        echo -e "${GREEN}✓ Coverage report generated${NC}"
        return 0
    else
        echo -e "${RED}✗ Coverage test failed${NC}"
        return 1
    fi
}

# Main script logic
case "${1:-all}" in
    "all")
        run_all_tests
        ;;
    "integration")
        run_integration_tests
        ;;
    "unit")
        run_unit_tests
        ;;
    "message")
        run_message_tests
        ;;
    "keeper")
        run_keeper_tests
        ;;
    "benchmark")
        run_benchmarks
        ;;
    "coverage")
        run_coverage
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [option]"
        echo ""
        echo "Options:"
        echo "  all         Run all tests (default)"
        echo "  integration Run integration tests only"
        echo "  unit        Run unit tests only"
        echo "  message     Run message server tests only"
        echo "  keeper      Run keeper operation tests only"
        echo "  benchmark   Run benchmarks only"
        echo "  coverage    Run tests with coverage report"
        echo "  help        Show this help message"
        ;;
    *)
        echo -e "${RED}Unknown option: $1${NC}"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac

# Exit with appropriate code
if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}🎉 All tests completed successfully!${NC}"
    exit 0
else
    echo -e "\n${RED}💥 Some tests failed!${NC}"
    exit 1
fi 