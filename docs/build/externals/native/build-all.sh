#!/bin/bash
# Tree-Sitter Cross-Platform Build Orchestrator
# Builds tree-sitter language parser binaries for multiple platforms

set -euo pipefail

if [ -n "${ZSH_VERSION:-}" ]; then
    SCRIPT_DIR="$(cd "$(dirname "$(eval 'echo ${(%):-%x}')")" && pwd)"
elif [ -n "${BASH_SOURCE[0]:-}" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
fi

# Determine EXTERNALS_NATIVE_DIR based on script location
# If script is in docs/build/externals/native, sources are in ../../../../externals/native
# If script is in externals/native, sources are in .
if [ -d "$SCRIPT_DIR/../../../../externals/native/core" ]; then
    EXTERNALS_NATIVE_DIR="$SCRIPT_DIR/../../../../externals/native"
elif [ -d "$SCRIPT_DIR/../../../externals/native/core" ]; then
    EXTERNALS_NATIVE_DIR="$SCRIPT_DIR/../../../externals/native"
elif [ -d "$SCRIPT_DIR/../../externals/native/core" ]; then
    EXTERNALS_NATIVE_DIR="$SCRIPT_DIR/../../externals/native"
elif [ -d "$SCRIPT_DIR/core" ]; then
    EXTERNALS_NATIVE_DIR="$SCRIPT_DIR"
else
    # Fallback for other locations
    EXTERNALS_NATIVE_DIR="$SCRIPT_DIR"
fi

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

# Platform configurations: (platform arch output_ext cmake_toolchain)
# Android uses NDK toolchain when available
declare -a PLATFORMS=(
    "macos:x86_64:dylib:zig-x86_64-macos.cmake"
    "macos:arm64:dylib:zig-aarch64-macos.cmake"
    "linux:x86_64:so:zig-x86_64-linux.cmake"
    "linux:arm64:so:zig-aarch64-linux.cmake"
    "windows:x64:dll:zig-x86_64-windows.cmake"
    "android:arm64:so:ndk-aarch64-android.cmake"
    "ios:arm64:dylib:zig-aarch64-ios.cmake"
)

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Build options
GRAMMAR_FILTER=""
MAX_PARALLEL_JOBS=0  # 0 = auto-detect (use all cores)
PARALLEL_BUILD=0
BUILD_PROFILE="balanced"  # size, speed, balanced, debug

# Logging
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$BUILD_LOG"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" | tee -a "$BUILD_LOG" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*" | tee -a "$BUILD_LOG"
}

log_info() {
    echo -e "${YELLOW}[INFO]${NC} $*" | tee -a "$BUILD_LOG"
}

# Initialize
initialize() {
    mkdir -p "$BUILD_DIR" "$LOGS_DIR"
    log "=========================================="
    log "Tree-Sitter Cross-Platform Build"
    log "Started: $(date)"
    log "=========================================="
}

# Setup Android NDK if needed
setup_android_ndk() {
    # Check if Android NDK toolchain already exists
    if [ -f "$SCRIPT_DIR/toolchains/ndk-aarch64-android.cmake" ]; then
        log_success "Android NDK toolchain already configured"
        return 0
    fi
    
    log_info "Setting up Android NDK support..."
    
    # Source the setup script to create the Android toolchain
    if bash "$SCRIPT_DIR/setup-android.sh" 2>&1 | tee -a "$BUILD_LOG"; then
        log_success "Android NDK setup completed"
        return 0
    else
        log_error "Android NDK setup failed"
        return 1
    fi
}

# Validate prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    local missing=0
    
    # Check CMake
    if ! command -v cmake &> /dev/null; then
        log_error "CMake not found. Please install CMake 3.13 or later."
        missing=1
    else
        local cmake_version=$(cmake --version | head -1)
        log "  ✓ $cmake_version"
    fi
    
    # Check Zig (required for most platforms)
    if ! command -v zig &> /dev/null; then
        log_error "Zig not found. Please install Zig."
        missing=1
    else
        local zig_version=$(zig version)
        log "  ✓ Zig version: $zig_version"
    fi
    
    # Check for required tools
    for tool in file nm objdump; do
        if ! command -v $tool &> /dev/null; then
            log_error "Tool '$tool' not found. Required for binary verification."
            missing=1
        fi
    done
    
    if [ $missing -eq 1 ]; then
        log_error "Missing required tools. Cannot proceed."
        exit 1
    fi
    
    # Setup Android NDK
    if ! setup_android_ndk; then
        log_error "Cannot proceed without Android NDK. Please install Android NDK."
        log_error "Common locations:"
        log_error "  - ANDROID_NDK_HOME environment variable"
        log_error "  - \$ANDROID_HOME/ndk/<version> (auto-detected)"
        log_error "  - /opt/android-ndk"
        log_error "  - /usr/local/android-ndk"
        exit 1
    fi
    
    log_success "All prerequisites satisfied"
}

# Check if platform-specific toolchain exists
check_toolchain() {
    local toolchain=$1
    local toolchain_path="$SCRIPT_DIR/toolchains/$toolchain"
    
    if [ ! -f "$toolchain_path" ]; then
        log_error "Toolchain not found: $toolchain_path"
        return 1
    fi
    return 0
}

# Build a single platform
build_platform() {
    local platform=$1
    local arch=$2
    local extension=$3
    local toolchain=$4
    
    log_info "Building $platform/$arch..."
    
    local build_subdir="$BUILD_DIR/${platform}_${arch}"
    local output_subdir="$OUT_DIR/$platform/$arch"
    
    mkdir -p "$build_subdir" "$output_subdir"
    
    # Validate toolchain
    if ! check_toolchain "$toolchain"; then
        log_error "Skipping $platform/$arch: toolchain not available"
        return 1
    fi
    
    # Get profile cmake options (available for both core and grammar builds)
    local profile_opts=$(apply_build_profile "$BUILD_PROFILE")
    
    # --- Phase 1: Build tree-sitter core library (once per platform) ---
    local core_output="$output_subdir/libtree-sitter.${extension}"
    if [ ! -f "$core_output" ]; then
        log "  Building tree-sitter core..."
        
        local core_build_dir="$build_subdir/core"
        mkdir -p "$core_build_dir"
        
        # Check if core source exists
        if [ ! -d "$EXTERNALS_NATIVE_DIR/core/tree-sitter-master" ]; then
            log_error "  Core source not found at $EXTERNALS_NATIVE_DIR/core/tree-sitter-master"
            log_error "  Run download-clone-native.sh to fetch the tree-sitter source"
            return 1
        fi
        
        # Run CMake configure for core library only
        if ! cmake \
            -S "$EXTERNALS_NATIVE_DIR/core/tree-sitter-master" \
            -B "$core_build_dir" \
            -DCMAKE_TOOLCHAIN_FILE="$SCRIPT_DIR/toolchains/$toolchain" \
            $profile_opts \
            2>&1 | tee -a "$BUILD_LOG"; then
            log_error "  CMake configuration failed for core"
            return 1
        fi
        
        # Build only the core library target
        if ! cmake \
            --build "$core_build_dir" \
            --config Release \
            --target tree-sitter \
            2>&1 | tee -a "$BUILD_LOG"; then
            log_error "  Build failed for core"
            return 1
        fi
        
        # Copy core library to output directory
        local core_lib_found=0
        while IFS= read -r lib; do
            if [ -f "$lib" ]; then
                local bname=$(basename "$lib")
                cp -v "$lib" "$output_subdir/$bname" >> "$BUILD_LOG" 2>&1
                log "  ✓ Copied core: $bname"
                core_lib_found=1
            fi
        done < <(find "$core_build_dir" -name "libtree-sitter.*" -o -name "tree-sitter.*.dll" 2>/dev/null || true)
        
        if [ $core_lib_found -eq 0 ]; then
            log_error "  Core library not found after build"
            return 1
        fi
    else
        log "  Core library already exists: $(basename "$core_output")"
    fi
    
    # --- Phase 2: Build each grammar individually (with core linking) ---
    # Get list of grammars to build
    local grammars=()
    if [ -n "$GRAMMAR_FILTER" ]; then
        IFS=',' read -ra grammars <<< "$GRAMMAR_FILTER"
    else
        # Get all grammars from the grammars directory
        GRAMMARS_BASE_DIR="$EXTERNALS_NATIVE_DIR/grammars"
        for grammar_dir in "$GRAMMARS_BASE_DIR"/*/; do
            if [ -f "$grammar_dir/CMakeLists.txt" ]; then
                local grammar_full_name=$(basename "$grammar_dir")
                local grammar_name="${grammar_full_name#tree-sitter-}"
                grammar_name="${grammar_name%-master}"
                grammar_name="${grammar_name%-main}"
                grammars+=("$grammar_name")
            fi
        done
    fi
    
    local success_count=0
    
    # Helper function to find grammar directory by short name
    find_grammar_dir() {
        local short_name=$1
        local base_dir=$2
        for grammar_dir in "$base_dir"/*/; do
            local grammar_full_name=$(basename "$grammar_dir")
            local grammar_name="${grammar_full_name#tree-sitter-}"
            grammar_name="${grammar_name%-master}"
            grammar_name="${grammar_name%-main}"
            if [ "$grammar_name" = "$short_name" ]; then
                echo "$grammar_dir"
                return 0
            fi
        done
        return 1
    }
    
    # Build each grammar individually to avoid duplicate target conflicts
    for grammar in "${grammars[@]}"; do
        log "  Building grammar: $grammar"
        
        local grammar_build_subdir="$build_subdir/${grammar}_grammar"
        mkdir -p "$grammar_build_subdir"
        
        # Find the grammar directory by short name
        local grammar_source_dir=$(find_grammar_dir "$grammar" "$GRAMMARS_BASE_DIR")
        
        # Validate grammar directory exists before configuring CMake
        if [ -z "$grammar_source_dir" ] || [ ! -d "$grammar_source_dir" ]; then
            log_error "  Grammar directory not found for: $grammar"
            continue
        fi
        
        if [ ! -f "$grammar_source_dir/CMakeLists.txt" ]; then
            log_error "  CMakeLists.txt not found for grammar: $grammar at $grammar_source_dir"
            continue
        fi
        
        # Run CMake configure for this single grammar (use grammar source directory, not externals/native)
        if ! cmake \
            -S "$grammar_source_dir" \
            -B "$grammar_build_subdir" \
            -DSINGLE_GRAMMAR="$grammar" \
            -DTREE_SITTER_CORE_DIR="$EXTERNALS_NATIVE_DIR/core/tree-sitter-master" \
            -DCMAKE_TOOLCHAIN_FILE="$SCRIPT_DIR/toolchains/$toolchain" \
            $profile_opts \
            2>&1 | tee -a "$BUILD_LOG"; then
            log_error "  CMake configuration failed for grammar: $grammar"
            continue
        fi
        
        # Run cmake build
        if ! cmake \
            --build "$grammar_build_subdir" \
            --config Release \
            2>&1 | tee -a "$BUILD_LOG"; then
            log_error "  Build failed for grammar: $grammar"
            continue
        fi
        
        # Copy artifacts from this grammar build to the main output directory
        local grammar_output_count=0
        while IFS= read -r lib; do
            if [ -f "$lib" ]; then
                local bname=$(basename "$lib")
                mkdir -p "$output_subdir"
                cp -v "$lib" "$output_subdir/$bname" >> "$BUILD_LOG" 2>&1
                grammar_output_count=$((grammar_output_count + 1))
            fi
        done < <(find "$grammar_build_subdir" -name "*tree-sitter-*.${extension}" 2>/dev/null || true)
        
        if [ $grammar_output_count -gt 0 ]; then
            log "  ✓ Successfully built $grammar ($grammar_output_count libraries)"
            success_count=$((success_count + 1))
        else
            log "  ⚠ Grammar built but no libraries found: $grammar"
        fi
    done
    
    if [ $success_count -eq 0 ]; then
        log_error "No grammars were successfully built for $platform/$arch"
        return 1
    fi
    
    log_success "Built $platform/$arch ($success_count grammars + core)"
    return 0
}

# Copy compiled binaries to output directory
copy_artifacts() {
    local build_dir=$1
    local output_dir=$2
    local extension=$3
    local platform=$4
    local arch=$5
    
    # Find all built libraries (with or without "lib" prefix)
    local found_any=0
    while IFS= read -r lib; do
        if [ -f "$lib" ]; then
            local basename=$(basename "$lib")
            cp -v "$lib" "$output_dir/$basename" >> "$BUILD_LOG" 2>&1
            log "  Copied: $basename"
            found_any=1
        fi
    done < <(find "$build_dir" -name "*tree-sitter-*.${extension}" 2>/dev/null || true)
    
    if [ $found_any -eq 0 ]; then
        log_error "No libraries found for $platform/$arch"
        return 1
    fi
    
    return 0
}

# Verify binary integrity
verify_binary() {
    local binary=$1
    local platform=$2
    local arch=$3
    
    if [ ! -f "$binary" ]; then
        return 1
    fi
    
    # Check file type
    local file_type=$(file "$binary" | grep -o -E 'ELF|Mach-O|PE32' || echo "UNKNOWN")
    
    # Check architecture
    if [ "$platform" = "windows" ]; then
        # PE files - skip symbol check for Windows cross-compiled binaries on non-Windows hosts
        if [ "$file_type" != "PE32" ] && [ "$file_type" != "UNKNOWN" ]; then
            log_error "  Invalid file type for Windows binary: $file_type"
            return 1
        fi
        # For Windows binaries, just verify they exist (can't check symbols on non-Windows)
        return 0
    elif [ "$platform" = "macos" ] || [ "$platform" = "ios" ]; then
        # Mach-O files
        if [ "$file_type" != "Mach-O" ]; then
            log_error "  Invalid file type for macOS/iOS binary: $file_type"
            return 1
        fi
    else
        # ELF files (Linux, Android)
        if [ "$file_type" != "ELF" ]; then
            log_error "  Invalid file type for ELF binary: $file_type"
            return 1
        fi
    fi
    
    # Check for expected symbols (skip for Windows which we can't check on macOS)
    if [ "$platform" != "windows" ]; then
        local nm_symbols
        if nm_symbols=$(nm "$binary" 2>/dev/null); then
            # nm read the binary — core library exports ts_* symbols; grammars export tree_sitter_*
            if ! echo "$nm_symbols" | grep -qE "tree_sitter|ts_parser_new|ts_parser_delete|ts_tree_root|ts_language"; then
                log_error "  Missing expected symbols in $binary"
                return 1
            fi
        else
            # nm cannot read binary (e.g., ELF format on macOS host) — file type verified above
            log "  Symbol check skipped (nm cannot parse this binary format on this host)"
        fi
    fi
    
    return 0
}

# Verify all built binaries
verify_builds() {
    log_info "Verifying built binaries..."
    
    local failed=0
    for platform_spec in "${PLATFORMS[@]}"; do
        IFS=':' read -r platform arch ext toolchain <<< "$platform_spec"
        local output_dir="$OUT_DIR/$platform/$arch"
        
        if [ -d "$output_dir" ]; then
            # Verify core library first
            log "  Verifying tree-sitter core for $platform/$arch:"
            local core_found=0
            while IFS= read -r binary; do
                if [ -f "$binary" ]; then
                    core_found=1
                    if verify_binary "$binary" "$platform" "$arch"; then
                        log "    ✓ $(basename "$binary")"
                    else
                        log_error "    ✗ $(basename "$binary")"
                        failed=1
                    fi
                fi
            done < <(find "$output_dir" -name "libtree-sitter.*" 2>/dev/null || true)
            
            if [ $core_found -eq 0 ]; then
                log_error "    ✗ tree-sitter core library not found"
                failed=1
            fi
            
            # Verify grammar binaries
            log "  Verifying grammar parsers for $platform/$arch:"
            while IFS= read -r binary; do
                if verify_binary "$binary" "$platform" "$arch"; then
                    log "    ✓ $(basename "$binary")"
                else
                    log_error "    ✗ $(basename "$binary")"
                    failed=1
                fi
            done < <(find "$output_dir" -name "*tree-sitter-*" 2>/dev/null || true)
        fi
    done
    
    if [ $failed -eq 1 ]; then
        log_error "Verification failed for some binaries"
        return 1
    fi
    
    log_success "All binaries verified"
    return 0
}

# Print build summary
print_summary() {
    log ""
    log "=========================================="
    log "Build Summary"
    log "=========================================="
    
    local total=0
    local success=0
    
    for platform_spec in "${PLATFORMS[@]}"; do
        IFS=':' read -r platform arch ext toolchain <<< "$platform_spec"
        local output_dir="$OUT_DIR/$platform/$arch"
        
        total=$((total + 1))
        
        local binary_count=0
        if [ -d "$output_dir" ]; then
            binary_count=$(find "$output_dir" -name "*tree-sitter-*" 2>/dev/null | wc -l)
        fi
        
        if [ $binary_count -gt 0 ]; then
            log "  ✓ $platform/$arch: $binary_count binaries"
            success=$((success + 1))
        else
            log "  ✗ $platform/$arch: No binaries found"
        fi
    done
    
    log ""
    log "Total: $success/$total platforms built successfully"
    log "Completed: $(date)"
    log "Log file: $BUILD_LOG"
    log "=========================================="
}

# Get available CPU count for parallel builds
get_cpu_count() {
    if command -v nproc &> /dev/null; then
        nproc
    elif command -v sysctl &> /dev/null && uname | grep -q Darwin; then
        sysctl -n hw.ncpu
    else
        echo 4
    fi
}

# Apply build profile settings to cmake configure arguments
# Returns a string of cmake -D options to pass to cmake configure commands
apply_build_profile() {
    local profile="$1"
    local cmake_opts=""
    
    case "$profile" in
        size)
            # MinSizeRel maps to -Os -DNDEBUG in CMake's standard flag sets
            cmake_opts="-DCMAKE_BUILD_TYPE=MinSizeRel"
            ;;
        speed)
            # Release maps to -O3 -DNDEBUG
            cmake_opts="-DCMAKE_BUILD_TYPE=Release"
            ;;
        debug)
            # Debug maps to -g (no optimization, debug symbols)
            cmake_opts="-DCMAKE_BUILD_TYPE=Debug"
            ;;
        balanced|*)
            # Release maps to -O3 -DNDEBUG
            cmake_opts="-DCMAKE_BUILD_TYPE=Release"
            ;;
    esac
    
    echo "$cmake_opts"
}

# Main build loop
main() {
    initialize
    check_prerequisites
    
    local failed_platforms=()
    
    # Detect parallel build settings
    if [ $PARALLEL_BUILD -eq 1 ] && [ $MAX_PARALLEL_JOBS -eq 0 ]; then
        MAX_PARALLEL_JOBS=$(get_cpu_count)
        log_info "Auto-detected $MAX_PARALLEL_JOBS CPU cores for parallel builds"
    fi
    
    if [ $PARALLEL_BUILD -eq 1 ]; then
        log_info "Parallel build enabled with max $MAX_PARALLEL_JOBS concurrent jobs"
        
        # Build platforms in parallel using background jobs
        local pids=()
        local exit_codes=()
        
        for platform_spec in "${PLATFORMS[@]}"; do
            IFS=':' read -r platform arch ext toolchain <<< "$platform_spec"
            
            # Filter platforms if specified
            if [ -n "$FILTER_PLATFORM" ] && [ "$platform" != "$FILTER_PLATFORM" ]; then
                continue
            fi
            
            # Wait if we've reached the parallelism limit
            while [ ${#pids[@]} -ge $MAX_PARALLEL_JOBS ]; do
                local new_pids=()
                local new_exit_codes=()
                for i in "${!pids[@]}"; do
                    if wait "${pids[$i]}" 2>/dev/null; then
                        new_exit_codes+=(0)
                    else
                        new_exit_codes+=($?)
                    fi
                done
                pids=("${new_pids[@]+"${new_pids[@]}"}")
                exit_codes=("${new_exit_codes[@]+"${new_exit_codes[@]}"}")
            done
            
            # Start build in background
            (
                build_platform "$platform" "$arch" "$ext" "$toolchain"
                exit $?
            ) &
            pids+=($!)
        done
        
        # Wait for all remaining jobs
        local all_success=1
        for pid in "${pids[@]}"; do
            if ! wait "$pid" 2>/dev/null; then
                all_success=0
            fi
        done
        
        if [ $all_success -ne 1 ]; then
            log_error "Some platforms failed to build"
            exit 1
        fi
    else
        # Sequential build (original behavior)
        for platform_spec in "${PLATFORMS[@]}"; do
            IFS=':' read -r platform arch ext toolchain <<< "$platform_spec"
            
            # Filter platforms if specified
            if [ -n "$FILTER_PLATFORM" ] && [ "$platform" != "$FILTER_PLATFORM" ]; then
                continue
            fi
            
            if ! build_platform "$platform" "$arch" "$ext" "$toolchain"; then
                failed_platforms+=("$platform/$arch")
            fi
        done
    fi
    
    if [ ${#failed_platforms[@]} -gt 0 ]; then
        log_error "Failed to build the following platforms:"
        for failed in "${failed_platforms[@]}"; do
            log_error "  - $failed"
        done
    fi
    
    # Verify binaries
    if ! verify_builds; then
        log_error "Binary verification failed"
        exit 1
    fi
    
    print_summary
    
    if [ ${#failed_platforms[@]} -gt 0 ]; then
        exit 1
    fi
    
    log_success "Build completed successfully!"
}

# Show usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    --clean             Clean build directories before building
    --platform PLATFORM Build only specified platform (e.g., macos, linux, windows, android, ios)
    --grammar-filter G  Comma-separated list of grammars to build (default: all)
    --profile PROFILE   Build profile: size, speed, balanced, debug (default: balanced)
    --optimize          Convenience flag: parallel builds + size optimization profile
    --parallel          Enable parallel builds across platforms (uses all CPU cores)
    --jobs N            Max concurrent parallel jobs (default: auto-detect CPU count)
    --verify-only       Only verify existing binaries, don't build
    --measure           Measure sizes of all pre-built binaries and exit
    --help              Show this help message

Examples:
    $0                                                  # Build all platforms, all grammars
    $0 --optimize                                       # Fast optimized build (parallel + size profile)
    $0 --profile size                                   # Build with size optimization
    $0 --profile speed                                  # Build with speed optimization
    $0 --platform macos                                 # Build only macOS (both x86_64 and arm64)
    $0 --grammar-filter c-sharp,typescript,rust        # Build specific grammars for all platforms
    $0 --clean                                          # Clean build directories and build all platforms
    $0 --verify-only                                    # Verify existing binaries without rebuilding

EOF
    exit 0
}

# Parse command-line arguments
CLEAN_BUILD=0
VERIFY_ONLY=0
MEASURE_ONLY=0
FILTER_PLATFORM=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --clean)
            CLEAN_BUILD=1
            shift
            ;;
        --platform)
            FILTER_PLATFORM="$2"
            shift 2
            ;;
        --grammar-filter)
            GRAMMAR_FILTER="$2"
            shift 2
            ;;
        --verify-only)
            VERIFY_ONLY=1
            shift
            ;;
        --measure)
            MEASURE_ONLY=1
            shift
            ;;
        --parallel)
            PARALLEL_BUILD=1
            shift
            ;;
        --jobs)
            MAX_PARALLEL_JOBS="$2"
            shift 2
            ;;
        --profile)
            BUILD_PROFILE="$2"
            shift 2
            ;;
        --optimize)
            PARALLEL_BUILD=1
            BUILD_PROFILE="size"
            shift
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

# Set profile-specific directories now that BUILD_PROFILE is resolved
BUILD_DIR="$SCRIPT_DIR/build-${BUILD_PROFILE}"
OUT_DIR="$SCRIPT_DIR/out-${BUILD_PROFILE}"
LOGS_DIR="$SCRIPT_DIR/logs-${BUILD_PROFILE}"
BUILD_LOG="$LOGS_DIR/build_${TIMESTAMP}.log"

# Clean if requested
if [ $CLEAN_BUILD -eq 1 ]; then
    log_info "Cleaning build directories..."
    rm -rf "$BUILD_DIR"/*
    log_success "Build directories cleaned"
fi

# If verify-only, just verify and exit
if [ $VERIFY_ONLY -eq 1 ]; then
    initialize
    verify_builds
    exit $?
fi

# If measure-only, just measure and exit
if [ $MEASURE_ONLY -eq 1 ]; then
    bash "$SCRIPT_DIR/measure-baseline.sh"
    exit $?
fi

# Main execution
main
