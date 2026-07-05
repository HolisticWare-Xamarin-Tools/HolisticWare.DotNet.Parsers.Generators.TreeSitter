#!/bin/bash
# Generate profiles.md - artifact tables per platform per profile
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILES="balanced debug size speed"
PLATFORMS="macos linux windows android ios"

OUTPUT_FILE="$SCRIPT_DIR/profiles.md"

# Temp file for collecting grammar names
GRAMMAR_LIST=$(mktemp)
trap "rm -f $GRAMMAR_LIST" EXIT

echo "# Tree-Sitter Binary Artifacts by Profile and Platform" > "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Generated:** $(date '+%Y-%m-%d %H:%M:%S')" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Collect all grammar names from any profile's output
for profile in $PROFILES; do
    out_dir="$SCRIPT_DIR/out-$profile"
    if [ -d "$out_dir" ]; then
        for platform in $PLATFORMS; do
            plat_dir="$out_dir/$platform"
            if [ -d "$plat_dir" ]; then
                for arch_dir in "$plat_dir"/*/; do
                    if [ -d "$arch_dir" ]; then
                        for lib in "$arch_dir"/libtree-sitter*; do
                            if [ -f "$lib" ]; then
                                bname=$(basename "$lib")
                                # Skip non-binary artifacts (import libs, debug symbols)
                                case "$bname" in
                                    *.dll.a|*.pdb|*.a|*.lib|*.def) continue ;;
                                esac
                                
                                # Extract grammar name handling versioned symlinks:
                                # libtree-sitter-core -> core, libtree-sitter-bash -> bash
                                # libtree-sitter-bash.14.0.dylib -> bash (strip .{version} before extension)
                                # Core libs: libtree-sitter.dylib / libtree-sitter.so / libtree-sitter.dll
                                #           also versioned: libtree-sitter.0.27.dylib
                                if [[ "$bname" == "libtree-sitter.dylib" || "$bname" == "libtree-sitter.so" || \
                                      "$bname" == "libtree-sitter.dll" || "$bname" == "tree-sitter.dll" ]]; then
                                    echo "core" >> "$GRAMMAR_LIST"
                                elif [[ "$bname" == libtree-sitter.* && "$bname" != libtree-sitter-* ]]; then
                                    # Core versioned symlink: libtree-sitter.0.27.dylib etc.
                                    echo "core" >> "$GRAMMAR_LIST"
                                else
                                    # Remove prefix and extension, then strip version number
                                    tmp=$(echo "$bname" | sed -E 's/^libtree-sitter-//; s/\.[^.]*$//')
                                    # Strip all trailing .{digits} version suffixes (e.g., bash.14.0 -> bash)
                                    gname=$(echo "$tmp" | sed -E 's/(\.[0-9]+)+$//')
                                    echo "$gname" >> "$GRAMMAR_LIST"
                                fi
                            fi
                        done
                    fi
                done
            fi
        done
    fi
done

# Sort and deduplicate grammar names
SORTED_GRAMMARS=$(sort -u "$GRAMMAR_LIST")
GRAMMAR_COUNT=$(echo "$SORTED_GRAMMARS" | wc -l | tr -d ' ')
echo "Found $GRAMMAR_COUNT grammars" >&2

# Function to get artifact info for a given profile/platform/arch/grammar
get_artifact() {
    local profile=$1 platform=$2 arch=$3 grammar=$4
    local out_dir="$SCRIPT_DIR/out-$profile"
    local plat_dir="$out_dir/$platform"
    
    if [ ! -d "$plat_dir" ]; then echo "N/A"; return; fi
    
    for arch_dir in "$plat_dir"/${arch}*; do
        if [ -d "$arch_dir" ]; then
            local pattern
            if [ "$grammar" = "core" ]; then
                # Core library: libtree-sitter.dylib / libtree-sitter.so (no dash after libtree-sitter)
                # Also matches versioned symlinks like libtree-sitter.0.27.dylib
                pattern="libtree-sitter.[^.]*.* libtree-sitter.dylib libtree-sitter.so"
            else
                # Match libtree-sitter-{grammar} exactly, followed by optional version and extension
                pattern="libtree-sitter-${grammar}*"
            fi
            
            for lib in "$arch_dir"/$pattern; do
                if [ -f "$lib" ]; then
                    local bname=$(basename "$lib")
                    # For core: ensure no dash after "libtree-sitter" (excludes grammar libs)
                    if [ "$grammar" = "core" ]; then
                        case "$bname" in
                            libtree-sitter-*) continue ;;  # This is a grammar lib, not core
                        esac
                    else
                        # For non-core grammars, verify exact match (not substring like c-sharp for c)
                        local check_name=$(echo "$bname" | sed -E 's/^libtree-sitter-//; s/\.[^.]*$//')
                        check_name=$(echo "$check_name" | sed -E 's/(\.[0-9]+)+$//')
                        if [ "$check_name" != "$grammar" ]; then
                            continue
                        fi
                    fi
                    local size=$(stat -f%z "$lib" 2>/dev/null || stat -c%s "$lib" 2>/dev/null || echo "?")
                    # Convert bytes to human readable using awk
                    local hr_size
                    if [ "$size" -gt 1048576 ] 2>/dev/null; then
                        hr_size="$(awk "BEGIN {printf \"%.1f\", $size/1048576}")MB"
                    elif [ "$size" -gt 1024 ] 2>/dev/null; then
                        hr_size="$(awk "BEGIN {printf \"%.1f\", $size/1024}")KB"
                    else
                        hr_size="${size}B"
                    fi
                    echo "$(basename "$lib") ($hr_size)"
                    return
                fi
            done
        fi
    done
    echo "N/A"
}

# Generate tables per platform
for platform in $PLATFORMS; do
    echo "## $platform" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    
    # Determine which architectures to show for this platform
    local_archs=""
    case "$platform" in
        macos) local_archs="x86_64 arm64" ;;
        linux) local_archs="x86_64 arm64" ;;
        windows) local_archs="x64" ;;
        android) local_archs="arm64" ;;
        ios) local_archs="arm64" ;;
    esac
    
    for arch in $local_archs; do
        echo "### $platform $arch" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "| Grammar | balanced | debug | size | speed |" >> "$OUTPUT_FILE"
        echo "|---------|----------|-------|------|-------|" >> "$OUTPUT_FILE"
        
        for grammar in $SORTED_GRAMMARS; do
            balanced_artifact=$(get_artifact "balanced" "$platform" "$arch" "$grammar")
            debug_artifact=$(get_artifact "debug" "$platform" "$arch" "$grammar")
            size_artifact=$(get_artifact "size" "$platform" "$arch" "$grammar")
            speed_artifact=$(get_artifact "speed" "$platform" "$arch" "$grammar")
            
            echo "| $grammar | $balanced_artifact | $debug_artifact | $size_artifact | $speed_artifact |" >> "$OUTPUT_FILE"
        done
        
        echo "" >> "$OUTPUT_FILE"
    done
done

echo "Generated: $OUTPUT_FILE"
