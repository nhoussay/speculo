#!/bin/bash

# Reputation Module Test Runner
# This script runs all tests for the reputation module

echo "🌟 Running Reputation Module Tests"
echo "=================================="

# Set the module path
MODULE_PATH="speculod/x/reputation"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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
    echo -e "\n${YELLOW}Running all reputation tests...${NC}"
    echo "----------------------------------------"
    
    if go test -v ./$MODULE_PATH/keeper; then
        echo -e "\n${GREEN}✓ All reputation tests passed!${NC}"
        return 0
    else
        echo -e "\n${RED}✗ Some reputation tests failed${NC}"
        return 1
    fi
}

# Function to run specific test categories
run_integration_tests() {
    echo -e "\n${YELLOW}Running integration tests...${NC}"
    echo "----------------------------------------"
    
    if go test -v ./$MODULE_PATH/keeper -run "^TestReputationIntegration"; then
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
    
    if go test -v ./$MODULE_PATH/keeper -run "^Test(ScoreAdjustment|AuthorityValidation|GroupIsolation|ScoreValidation|ReputationWeighting|ConsensusAlignment|PenaltySystem|MinimumScore|ScoreRetrieval|ScoreStorage)"; then
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

run_query_tests() {
    echo -e "\n${YELLOW}Running query tests...${NC}"
    echo "----------------------------------------"
    
    if go test -v ./$MODULE_PATH/keeper -run "^TestQuery"; then
        echo -e "${GREEN}✓ Query tests passed${NC}"
        return 0
    else
        echo -e "${RED}✗ Query tests failed${NC}"
        return 1
    fi
}

run_genesis_tests() {
    echo -e "\n${YELLOW}Running genesis tests...${NC}"
    echo "----------------------------------------"
    
    if go test -v ./$MODULE_PATH/keeper -run "^TestGenesis"; then
        echo -e "${GREEN}✓ Genesis tests passed${NC}"
        return 0
    else
        echo -e "${RED}✗ Genesis tests failed${NC}"
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

# Function to run cross-module integration tests
run_cross_module_tests() {
    echo -e "\n${YELLOW}Running cross-module integration tests...${NC}"
    echo "----------------------------------------"
    
    # Test reputation with settlement module
    if go test -v ./$MODULE_PATH/keeper -run "^TestReputationSettlementIntegration"; then
        echo -e "${GREEN}✓ Reputation-Settlement integration tests passed${NC}"
    else
        echo -e "${RED}✗ Reputation-Settlement integration tests failed${NC}"
        return 1
    fi
    
    # Test reputation with prediction module
    if go test -v ./$MODULE_PATH/keeper -run "^TestReputationPredictionIntegration"; then
        echo -e "${GREEN}✓ Reputation-Prediction integration tests passed${NC}"
    else
        echo -e "${RED}✗ Reputation-Prediction integration tests failed${NC}"
        return 1
    fi
    
    return 0
}

# Function to run stress tests
run_stress_tests() {
    echo -e "\n${YELLOW}Running stress tests...${NC}"
    echo "----------------------------------------"
    
    if go test -v ./$MODULE_PATH/keeper -run "^TestStress"; then
        echo -e "${GREEN}✓ Stress tests passed${NC}"
        return 0
    else
        echo -e "${RED}✗ Stress tests failed${NC}"
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
    "query")
        run_query_tests
        ;;
    "genesis")
        run_genesis_tests
        ;;
    "cross-module")
        run_cross_module_tests
        ;;
    "stress")
        run_stress_tests
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
        echo "  query       Run query tests only"
        echo "  genesis     Run genesis tests only"
        echo "  cross-module Run cross-module integration tests"
        echo "  stress      Run stress tests only"
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
    echo -e "\n${GREEN}🎉 All reputation tests completed successfully!${NC}"
    exit 0
else
    echo -e "\n${RED}💥 Some reputation tests failed!${NC}"
    exit 1
fi 