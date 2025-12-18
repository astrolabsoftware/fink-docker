#!/bin/bash

# Test script for all Fink Docker builds
# Tests both k8s and sentinel builds for rubin and ztf surveys

set -euo pipefail

DIR=$(cd "$(dirname "$0")"; pwd -P)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results tracking
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
declare -a FAILED_BUILDS=()

usage() {
  cat << EOD

Usage: $(basename "$0") [options]

  Available options:
    -h                  this message
    --k8s-only         test only k8s builds
    --sentinel-only    test only sentinel builds
    --survey SURVEY    test only specific survey (rubin or ztf)
    --verbose          verbose build output
    --no-cleanup       don't remove test images after build
    --dry-run          show what would be tested without running

Test all Fink Docker builds:
  - k8s: science and noscience targets for both surveys
  - sentinel: development images for both surveys

Examples:
  $(basename "$0")                           # Test all builds
  $(basename "$0") --k8s-only               # Test only k8s builds
  $(basename "$0") --sentinel-only          # Test only sentinel builds
  $(basename "$0") --survey ztf             # Test only ZTF builds
  $(basename "$0") --verbose                # Verbose output
  $(basename "$0") --dry-run                # Show what would be tested

EOD
}

# Default values
K8S_ONLY=false
SENTINEL_ONLY=false
SURVEY_FILTER=""
VERBOSE=false
NO_CLEANUP=false
DRY_RUN=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        --k8s-only)
            K8S_ONLY=true
            shift
            ;;
        --sentinel-only)
            SENTINEL_ONLY=true
            shift
            ;;
        --survey)
            SURVEY_FILTER="$2"
            shift 2
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --no-cleanup)
            NO_CLEANUP=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Validate survey filter
if [[ -n "$SURVEY_FILTER" && ! "$SURVEY_FILTER" =~ ^(rubin|ztf)$ ]]; then
    echo "Error: Invalid survey '$SURVEY_FILTER'. Must be: rubin or ztf"
    exit 1
fi

# Validate conflicting options
if [[ "$K8S_ONLY" == true && "$SENTINEL_ONLY" == true ]]; then
    echo "Error: Cannot specify both --k8s-only and --sentinel-only"
    exit 1
fi

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

test_build() {
    local target="$1"
    local survey="$2"
    local suffix="$3"
    local test_name="$4"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    log_info "Testing: $test_name"

    if [[ "$DRY_RUN" == true ]]; then
        echo "  Would run: ./build-images.sh -t $target -i $survey${suffix:+ -s $suffix}${VERBOSE:+ --verbose}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    fi

    # Generate unique tag for test
    local tag_suffix="${target}-${survey}"
    if [[ -n "$suffix" ]]; then
        tag_suffix="${tag_suffix}-${suffix}"
    fi
    local test_tag="fink-test-${tag_suffix}:$(date +%s)"

    # Prepare build command
    local build_cmd="./build-images.sh -t $target -i $survey"
    if [[ -n "$suffix" ]]; then
        build_cmd="$build_cmd -s $suffix"
    fi
    if [[ "$VERBOSE" == true ]]; then
        build_cmd="$build_cmd --verbose"
    fi

    # Capture build output
    local build_log="/tmp/fink-build-test-${tag_suffix}-$(date +%s).log"

    echo "  Running: $build_cmd"
    echo "  Build log: $build_log"

    # Run build
    if $build_cmd > "$build_log" 2>&1; then
        log_success "Build completed: $test_name"
        PASSED_TESTS=$((PASSED_TESTS + 1))

        # Cleanup test image unless --no-cleanup is specified
        if [[ "$NO_CLEANUP" == false ]]; then
            # Extract image name from build log (this is ciux-specific)
            local image_name
            if image_name=$(grep -o "Build successful: .*" "$build_log" | head -1 | cut -d' ' -f3); then
                if [[ -n "$image_name" ]]; then
                    docker rmi "$image_name" 2>/dev/null || log_warning "Could not remove test image: $image_name"
                fi
            fi
        fi

        rm -f "$build_log"
        return 0
    else
        log_error "Build failed: $test_name"
        log_error "Build log saved: $build_log"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        FAILED_BUILDS+=("$test_name")
        return 1
    fi
}

# Main test execution
main() {
    log_info "Starting Fink Docker build tests"
    echo "Configuration:"
    echo "  K8s only: $K8S_ONLY"
    echo "  Sentinel only: $SENTINEL_ONLY"
    echo "  Survey filter: ${SURVEY_FILTER:-all}"
    echo "  Verbose: $VERBOSE"
    echo "  No cleanup: $NO_CLEANUP"
    echo "  Dry run: $DRY_RUN"
    echo ""

    # Define surveys to test
    local surveys=("rubin" "ztf")
    if [[ -n "$SURVEY_FILTER" ]]; then
        surveys=("$SURVEY_FILTER")
    fi

    # Test K8s builds
    if [[ "$SENTINEL_ONLY" != true ]]; then
        log_info "Testing K8s builds..."
        for survey in "${surveys[@]}"; do
            for suffix in "science" "noscience"; do
                test_build "k8s" "$survey" "$suffix" "K8s $survey $suffix"
            done
        done
        echo ""
    fi

    # Test Sentinel builds
    if [[ "$K8S_ONLY" != true ]]; then
        log_info "Testing Sentinel builds..."
        for survey in "${surveys[@]}"; do
            test_build "sentinel" "$survey" "" "Sentinel $survey"
        done
        echo ""
    fi

    # Results summary
    echo "============================================="
    log_info "Test Results Summary"
    echo "Total tests: $TOTAL_TESTS"
    echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
    echo -e "Failed: ${RED}$FAILED_TESTS${NC}"

    if [[ $FAILED_TESTS -gt 0 ]]; then
        echo ""
        log_error "Failed builds:"
        for failed_build in "${FAILED_BUILDS[@]}"; do
            echo "  - $failed_build"
        done
        echo ""
        exit 1
    else
        echo ""
        log_success "All tests passed!"
        exit 0
    fi
}

# Run main function
main "$@"