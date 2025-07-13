#!/bin/bash

# Speculod Order Book Test Runner
# This script provides easy access to run all order book tests

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Function to run tests
run_tests() {
    local test_path="$1"
    local test_name="$2"
    local extra_args="$3"
    
    print_status "Running $test_name tests..."
    
    if go test "$test_path" $extra_args; then
        print_status "$test_name tests passed!"
        return 0
    else
        print_error "$test_name tests failed!"
        return 1
    fi
}

# Function to run benchmarks
run_benchmarks() {
    local test_path="$1"
    local benchmark_name="$2"
    
    print_status "Running $benchmark_name benchmarks..."
    
    if go test "$test_path" -bench=. -benchmem $extra_args; then
        print_status "$benchmark_name benchmarks completed!"
        return 0
    else
        print_error "$benchmark_name benchmarks failed!"
        return 1
    fi
}

# Function to show help
show_help() {
    echo "Speculod Order Book Test Runner"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help              Show this help message"
    echo "  -v, --verbose           Run tests with verbose output"
    echo "  -c, --coverage          Run tests with coverage report"
    echo "  -b, --benchmarks        Run benchmarks"
    echo "  -a, --all               Run all tests and benchmarks"
    echo "  -s, --specific TEST     Run specific test (e.g., TestOrderMatching_BasicMatch)"
    echo "  -r, --race              Run tests with race detection"
    echo "  -j, --jupyter           Open Jupyter notebook for interactive testing"
    echo ""
    echo "Examples:"
    echo "  $0                      Run all tests"
    echo "  $0 -v                   Run all tests with verbose output"
    echo "  $0 -c                   Run tests with coverage"
    echo "  $0 -b                   Run benchmarks"
    echo "  $0 -a                   Run all tests and benchmarks"
    echo "  $0 -s TestOrderMatching_BasicMatch  Run specific test"
    echo "  $0 -r                   Run tests with race detection"
    echo "  $0 -j                   Open Jupyter notebook"
}

# Main script
main() {
    local verbose=""
    local coverage=""
    local benchmarks=""
    local all_tests=""
    local specific_test=""
    local race_detection=""
    local jupyter=""
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--verbose)
                verbose="-v"
                shift
                ;;
            -c|--coverage)
                coverage="-cover"
                shift
                ;;
            -b|--benchmarks)
                benchmarks="true"
                shift
                ;;
            -a|--all)
                all_tests="true"
                shift
                ;;
            -s|--specific)
                specific_test="$2"
                shift 2
                ;;
            -r|--race)
                race_detection="-race"
                shift
                ;;
            -j|--jupyter)
                jupyter="true"
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Check if we're in the right directory
    if [[ ! -f "go.mod" ]]; then
        print_error "Please run this script from the project root directory"
        exit 1
    fi
    
    # Build the test arguments
    local test_args="$verbose $coverage $race_detection"
    
    # Handle specific test
    if [[ -n "$specific_test" ]]; then
        test_args="$test_args -run $specific_test"
    fi
    
    # Handle Jupyter notebook
    if [[ -n "$jupyter" ]]; then
        print_header "Opening Jupyter Notebook"
        if command -v jupyter &> /dev/null; then
            jupyter notebook tests/order_book_testing.ipynb
        else
            print_error "Jupyter is not installed. Please install it first:"
            echo "  pip install jupyter"
            exit 1
        fi
        exit 0
    fi
    
    # Run tests based on options
    if [[ -n "$all_tests" ]]; then
        print_header "Running All Tests and Benchmarks"
        
        # Run all tests
        run_tests "./x/prediction/keeper/" "Order Book" "$test_args"
        
        # Run benchmarks
        run_benchmarks "./x/prediction/keeper/" "Order Book" "$test_args"
        
        # Run simulation tests
        run_tests "./app/" "Simulation" "$test_args"
        
    elif [[ -n "$benchmarks" ]]; then
        print_header "Running Benchmarks"
        run_benchmarks "./x/prediction/keeper/" "Order Book" "$test_args"
        
    else
        print_header "Running Order Book Tests"
        run_tests "./x/prediction/keeper/" "Order Book" "$test_args"
    fi
    
    print_header "Test Summary"
    print_status "All tests completed successfully!"
    print_status "For interactive testing, run: $0 -j"
    print_status "For full documentation, see: docs/testing.md"
}

# Run main function with all arguments
main "$@" 