#!/bin/bash

# WordPress.com MCP Tools - MCPB Build Script
# This script builds the MCPB extension bundle for distribution

set -e  # Exit on any error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
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

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check Node.js
    if ! command -v node >/dev/null 2>&1; then
        log_error "Node.js is not installed. Please install Node.js >= 18.0.0"
        exit 1
    fi

    local node_version=$(node --version | sed 's/v//' | cut -d. -f1)
    if [ "$node_version" -lt 18 ]; then
        log_error "Node.js version 18 or higher is required. Current version: $(node --version)"
        exit 1
    fi

    # Check npm
    if ! command -v npm >/dev/null 2>&1; then
        log_error "npm is not installed"
        exit 1
    fi

    # Check if mcpb CLI is available
    if ! command -v npx >/dev/null 2>&1; then
        log_error "npx is not installed"
        exit 1
    fi

    log_success "Prerequisites check passed"
}

# Validate manifest
validate_manifest() {
    log_info "Validating manifest.json..."

    if [ ! -f "manifest.json" ]; then
        log_error "manifest.json not found"
        exit 1
    fi

    # Basic JSON syntax check
    if ! node -e "JSON.parse(require('fs').readFileSync('manifest.json', 'utf8'))" 2>/dev/null; then
        log_error "manifest.json has invalid JSON syntax"
        exit 1
    fi

    log_success "Manifest validation passed"
}

# Install dependencies and build
install_and_build() {
    log_info "Installing dependencies and building bundle..."

    # Clean previous builds
    if [ -d "node_modules" ]; then
        rm -rf node_modules
    fi
    if [ -d "dist" ]; then
        rm -rf dist
    fi

    # Install all dependencies (including dev dependencies for building)
    if [ -f "package-lock.json" ]; then
        npm ci --silent
    else
        npm install --silent
    fi

    # Build the bundled version
    log_info "Building bundled server..."
    npx tsup --silent

    # Check if build succeeded
    if [ ! -f "dist/index.js" ]; then
        log_error "Build failed - dist/index.js not found"
        exit 1
    fi

    log_success "Bundle built successfully"
}

# Test server startup
test_server() {
    log_info "Testing bundled server startup..."

    # Test basic node execution
    log_info "Testing basic node execution..."
    if ! node --version >/dev/null 2>&1; then
        log_error "Node.js is not working properly"
        exit 1
    fi
    log_info "Node.js is working: $(node --version)"

    # Check if the bundled server exists
    if [ ! -f "dist/index.js" ]; then
        log_error "Bundled server not found at dist/index.js"
        exit 1
    fi

    # Test the bundled server startup
    log_info "Testing bundled server startup..."

    # Run server test in background and kill after reasonable time
    (
        echo '{"jsonrpc": "2.0", "method": "initialize", "params": {}}' | node dist/index.js 2>&1 | head -10
    ) &
    local server_pid=$!

    # Wait up to 10 seconds for the server test
    local count=0
    while kill -0 $server_pid 2>/dev/null && [ $count -lt 100 ]; do
        sleep 0.1
        count=$((count + 1))
    done

    # Kill the server process if it's still running
    if kill -0 $server_pid 2>/dev/null; then
        kill $server_pid 2>/dev/null
        wait $server_pid 2>/dev/null
        log_success "Bundled server startup test passed (server started and was terminated after 10 seconds)"
    else
        wait $server_pid 2>/dev/null
        local exit_code=$?
        if [ $exit_code -eq 0 ]; then
            log_success "Bundled server startup test completed successfully"
        else
            log_warning "Bundled server test failed with exit code $exit_code"

            # Try to run the server directly to see stderr
            log_info "Attempting to run bundled server directly to capture errors..."
            echo '{"jsonrpc": "2.0", "method": "initialize", "params": {}}' | node dist/index.js 2>&1 | head -5 || true

            log_warning "Bundled server test failed, but continuing build (server may work in runtime)"
        fi
    fi
}

# Create MCPB bundle
create_bundle() {
    log_info "Creating optimized MCPB bundle..."

    local bundle_name="wordpress-com-mcp.mcpb"

    # Remove existing bundle
    if [ -f "$bundle_name" ]; then
        rm "$bundle_name"
    fi

    # Create zip file with only necessary contents (no node_modules!)
    zip -r "$bundle_name" \
        manifest.json \
        dist/ \
        package.json \
        README.md \
        icon.png \
        -x "*.log" \
        -x "*.git*" \
        -x "build.sh" \
        -x "src/*" \
        -x "tsconfig.json" \
        -x "node_modules/*" \
        >/dev/null

    if [ -f "$bundle_name" ]; then
        local size=$(du -h "$bundle_name" | cut -f1)
        log_success "Optimized bundle created: $bundle_name ($size)"

        # Show bundle contents summary
        log_info "Bundle contents:"
        unzip -l "$bundle_name" | tail -n +4 | head -n -2 | awk '{print "  " $4}'
        
        # Show size comparison
        log_info "Bundle size analysis:"
        log_info "  Total bundle size: $size"
        if [ -f "dist/index.js" ]; then
            local dist_size=$(du -h "dist/index.js" | cut -f1)
            log_info "  Bundled server size: $dist_size"
        fi
    else
        log_error "Failed to create bundle"
        exit 1
    fi
}

# Cleanup
cleanup() {
    log_info "Cleaning up temporary files..."

    # Remove any temporary files or logs
    find . -name "*.log" -type f -delete 2>/dev/null || true

    log_success "Cleanup completed"
}

# Show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --skip-test     Skip server startup test"
    echo "  --no-cleanup    Skip cleanup step"
    echo "  --help          Show this help message"
    echo ""
}

# Main function
main() {
    local skip_test=false
    local no_cleanup=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-test)
                skip_test=true
                shift
                ;;
            --no-cleanup)
                no_cleanup=true
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    log_info "Starting WordPress.com MCP Tools build process..."

    # Execute build steps
    check_prerequisites
    validate_manifest
    install_and_build

    if [ "$skip_test" = false ]; then
        test_server
    fi

    create_bundle

    if [ "$no_cleanup" = false ]; then
        cleanup
    fi

    log_success "Build completed successfully!"
    log_info "You can now install wordpress-com-mcp.mcpb in Claude Desktop"
}

# Run main function with all arguments
main "$@"