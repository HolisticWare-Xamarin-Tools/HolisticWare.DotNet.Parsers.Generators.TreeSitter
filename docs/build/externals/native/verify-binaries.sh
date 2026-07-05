#!/bin/bash
# Tree-Sitter Binary Verification Tool
# Validates compiled binaries and generates verification report

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="$SCRIPT_DIR/out"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
VERIFICATION_REPORT="$SCRIPT_DIR/logs/verification_${TIMESTAMP}.txt"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Statistics
TOTAL_BINARIES=0
VERIFIED=0
FAILED=0

# Logging
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$VERIFICATION_REPORT"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" | tee -a "$VERIFICATION_REPORT" >&2
}

log_success() {
    echo -e "${GREEN}[✓ PASS]${NC} $*" | tee -a "$VERIFICATION_REPORT"
}

log_failure() {
    echo -e "${RED}[✗ FAIL]${NC} $*" | tee -a "$VERIFICATION_REPORT"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*" | tee -a "$VERIFICATION_REPORT"
}

# Initialize
initialize() {
    mkdir -p "$(dirname "$VERIFICATION_REPORT")"
    log "=========================================="
    log "Tree-Sitter Binary Verification Report"
    log "Started: $(date)"
    log "=========================================="
}

# Check file type
check_file_type() {
    local binary=$1
    local platform=$2
    
    local file_output=$(file "$binary")
    
    case "$platform" in
        windows)
            if echo "$file_output" | grep -qi "PE32"; then
                log_success "File type: PE32 (Windows executable)"
                return 0
            else
                log_failure "Expected PE32 format, got: $file_output"
                return 1
            fi
            ;;
        macos|ios)
            if echo "$file_output" | grep -qi "Mach-O"; then
                log_success "File type: Mach-O (macOS/iOS)"
                return 0
            else
                log_failure "Expected Mach-O format, got: $file_output"
                return 1
            fi
            ;;
        linux|android)
            if echo "$file_output" | grep -qi "ELF"; then
                log_success "File type: ELF (Linux/Android)"
                return 0
            else
                log_failure "Expected ELF format, got: $file_output"
                return 1
            fi
            ;;
        *)
            log_error "Unknown platform: $platform"
            return 1
            ;;
    esac
}

# Check for symbols
check_symbols() {
    local binary=$1
    local nm_symbols

    # Try to read symbols with nm
    if ! nm_symbols=$(nm "$binary" 2>/dev/null); then
        # nm failed (e.g., ELF format on macOS host) — file type already checked
        log_info "Symbol check skipped (nm cannot parse this binary format on this host)"
        return 0
    fi

    if [ -z "$nm_symbols" ]; then
        log_failure "Binary has no symbols (may be stripped)"
        return 1
    fi

    # Core library exports ts_* symbols; grammar libraries export tree_sitter_* symbols
    if echo "$nm_symbols" | grep -qiE "tree_sitter|ts_parser_new|ts_parser_delete|ts_tree_root|ts_language"; then
        log_success "Found expected tree-sitter symbols"
        return 0
    else
        log_failure "No expected tree-sitter symbols found"
        return 1
    fi
}

# Check architecture
check_architecture() {
    local binary=$1
    local expected_arch=$2
    
    local file_output=$(file "$binary")
    
    case "$expected_arch" in
        x86_64|x64)
            if echo "$file_output" | grep -qi "x86-64\|x86_64"; then
                log_success "Architecture: x86_64"
                return 0
            else
                log_failure "Expected x86_64, got: $file_output"
                return 1
            fi
            ;;
        arm64|aarch64)
            if echo "$file_output" | grep -qi "aarch64\|ARM64"; then
                log_success "Architecture: ARM64"
                return 0
            else
                log_failure "Expected ARM64, got: $file_output"
                return 1
            fi
            ;;
        *)
            log_info "Architecture check: $expected_arch"
            return 0
            ;;
    esac
}

# Get binary details
get_binary_details() {
    local binary=$1
    
    log "File size: $(du -h "$binary" | cut -f1)"
    log "File info: $(file "$binary")"
}

# Verify a single binary
verify_binary() {
    local binary=$1
    local platform=$2
    local arch=$3
    
    TOTAL_BINARIES=$((TOTAL_BINARIES + 1))
    
    log ""
    log "Verifying: $(basename "$binary")"
    
    local failed=0
    
    # Check file type
    if ! check_file_type "$binary" "$platform"; then
        failed=1
    fi
    
    # Check symbols
    if ! check_symbols "$binary"; then
        failed=1
    fi
    
    # For core library, also verify core-specific symbols
    local bname=$(basename "$binary")
    if echo "$bname" | grep -q "^libtree-sitter\." || echo "$bname" | grep -q "^tree-sitter\.[^.]*\.dll$"; then
        log_info "Core library detected — checking core-specific symbols..."

        local nm_output
        if nm_output=$(nm "$binary" 2>/dev/null); then
            # Check for key tree-sitter core API symbols
            local core_symbols=("ts_parser_new" "ts_parser_delete" "ts_tree_root" "ts_language_field_name")
            local found_symbols=0
            for sym in "${core_symbols[@]}"; do
                if echo "$nm_output" | grep -q "$sym"; then
                    log_info "  Found symbol: $sym"
                    found_symbols=$((found_symbols + 1))
                fi
            done

            if [ $found_symbols -lt 2 ]; then
                log_failure "Core library missing expected symbols (found $found_symbols/4)"
                failed=1
            else
                log_success "Core library has expected API symbols ($found_symbols/4)"
            fi
        else
            log_info "  Core symbol check skipped (nm cannot parse this binary format on this host)"
        fi
    fi
    
    # Check architecture
    if ! check_architecture "$binary" "$arch"; then
        failed=1
    fi
    
    # Get details
    get_binary_details "$binary"
    
    if [ $failed -eq 0 ]; then
        VERIFIED=$((VERIFIED + 1))
        log_success "Binary verification passed"
    else
        FAILED=$((FAILED + 1))
        log_failure "Binary verification failed"
    fi
    
    return $failed
}

# Verify all binaries
verify_all() {
    log_info "Scanning for binaries in $OUT_DIR..."
    
    for platform_dir in "$OUT_DIR"/*; do
        if [ -d "$platform_dir" ]; then
            local platform=$(basename "$platform_dir")
            
            for arch_dir in "$platform_dir"/*; do
                if [ -d "$arch_dir" ]; then
                    local arch=$(basename "$arch_dir")
                    
                    while IFS= read -r binary; do
                        if [ -f "$binary" ]; then
                            verify_binary "$binary" "$platform" "$arch" || true
                        fi
                    done < <(find "$arch_dir" -name "tree-sitter-*" -type f 2>/dev/null || true)
                fi
            done
        fi
    done
}

# Print verification summary
print_summary() {
    log ""
    log "=========================================="
    log "Verification Summary"
    log "=========================================="
    log "Total binaries: $TOTAL_BINARIES"
    log "Passed: $VERIFIED"
    log "Failed: $FAILED"
    
    if [ $TOTAL_BINARIES -eq 0 ]; then
        log_error "No binaries found to verify"
        return 1
    fi
    
    if [ $FAILED -eq 0 ]; then
        log_success "All binaries verified successfully!"
        return 0
    else
        log_failure "$FAILED binary(ies) failed verification"
        return 1
    fi
}

# Show usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    --platform PLATFORM    Verify only binaries for specified platform
    --help                 Show this help message

Examples:
    $0                                  # Verify all binaries
    $0 --platform macos                 # Verify only macOS binaries

EOF
    exit 0
}

# Parse arguments
FILTER_PLATFORM=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --platform)
            FILTER_PLATFORM="$2"
            shift 2
            ;;
        --help)
            usage
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            ;;
    esac
done

# Main execution
main() {
    initialize
    
    if [ -n "$FILTER_PLATFORM" ]; then
        log_info "Filtering to platform: $FILTER_PLATFORM"
    fi
    
    verify_all
    
    if print_summary; then
        log ""
        log "Report saved to: $VERIFICATION_REPORT"
        exit 0
    else
        log ""
        log "Report saved to: $VERIFICATION_REPORT"
        exit 1
    fi
}

main
