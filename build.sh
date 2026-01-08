#!/bin/bash

# WordPress.com MCP Bundle - MCPB Build Script
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

# Validate manifest
validate_manifest() {
    log_info "Validating manifest.json..."

    if [ ! -f "manifest.json" ]; then
        log_error "manifest.json not found"
        exit 1
    fi

    # Basic JSON syntax check using Python (more portable than Node.js)
    if command -v python3 >/dev/null 2>&1; then
        if ! python3 -m json.tool manifest.json >/dev/null 2>&1; then
            log_error "manifest.json has invalid JSON syntax"
            exit 1
        fi
    elif command -v node >/dev/null 2>&1; then
        if ! node -e "JSON.parse(require('fs').readFileSync('manifest.json', 'utf8'))" 2>/dev/null; then
            log_error "manifest.json has invalid JSON syntax"
            exit 1
        fi
    else
        log_warning "No JSON validator found, skipping syntax check"
    fi

    log_success "Manifest validation passed"
}

# Create MCPB bundle
create_bundle() {
    log_info "Creating MCPB bundle..."

    local bundle_name="wordpress-com-mcp.mcpb"

    # Remove existing bundle
    if [ -f "$bundle_name" ]; then
        rm "$bundle_name"
    fi

    # Verify required files exist
    if [ ! -f "manifest.json" ]; then
        log_error "manifest.json not found"
        exit 1
    fi

    if [ ! -f "icon.png" ]; then
        log_warning "icon.png not found, bundle will be created without icon"
    fi

    if [ ! -f "README.md" ]; then
        log_warning "README.md not found, bundle will be created without README"
    fi

    # Create zip file with only necessary contents
    zip -r "$bundle_name" \
        manifest.json \
        README.md \
        icon.png \
        -x "*.log" \
        -x "*.git*" \
        -x "build.sh" \
        -x "src/*" \
        -x "dist/*" \
        -x "tsconfig.json" \
        -x "package.json" \
        -x "package-lock.json" \
        -x "node_modules/*" \
        >/dev/null 2>&1 || {
        log_error "Failed to create bundle. Is 'zip' command available?"
        exit 1
    }

    if [ -f "$bundle_name" ]; then
        local size=$(du -h "$bundle_name" | cut -f1)
        log_success "Bundle created: $bundle_name ($size)"

        # Show bundle contents summary
        log_info "Bundle contents:"
        unzip -l "$bundle_name" 2>/dev/null | tail -n +4 | head -n -2 | awk '{print "  " $4}' || true
    else
        log_error "Failed to create bundle"
        exit 1
    fi
}

# Show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --help          Show this help message"
    echo ""
}

# Main function
main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
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
        shift
    done

    log_info "Starting WordPress.com MCP Bundle build process..."

    # Execute build steps
    validate_manifest
    create_bundle

    log_success "Build completed successfully!"
    log_info "You can now install wordpress-com-mcp.mcpb in Cursor or other MCP clients"
}

# Run main function with all arguments
main "$@"
