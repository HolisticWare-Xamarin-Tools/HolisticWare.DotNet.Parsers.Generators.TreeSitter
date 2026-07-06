#!/bin/bash
# Tree-Sitter Profile Comparison Report Generator
# Generates profiles.md with tables of binary artifacts vs each build profile

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Profile directories (order matters for column display)
PROFILE_DEBUG="out-debug"
PROFILE_BALANCED="out-balanced"
PROFILE_SIZE="out-size"
PROFILE_SPEED="out-speed"

get_profile_name() {
    case "$1" in
        out-debug)     echo "Debug" ;;
        out-balanced)  echo "Balanced" ;;
        out-size)      echo "Size-Optimized" ;;
        out-speed)     echo "Speed-Optimized" ;;
        *)             echo "$1" ;;
    esac
}

get_profile_dir() {
    case "$1" in
        debug)     echo "$PROFILE_DEBUG" ;;
        balanced)  echo "$PROFILE_BALANCED" ;;
        size)      echo "$PROFILE_SIZE" ;;
        speed)     echo "$PROFILE_SPEED" ;;
        *)         echo "$1" ;;
    esac
}

# Platform configurations
PLATFORMS="macos linux windows android ios"

get_platform_name() {
    case "$1" in
        macos)   echo "macOS" ;;
        linux)   echo "Linux" ;;
        windows) echo "Windows" ;;
        android) echo "Android" ;;
        ios)     echo "iOS" ;;
        *)       echo "$1" ;;
    esac
}

# Format bytes to human readable
format_size() {
    local bytes=$1
    if [ "$bytes" -ge 1048576 ] 2>/dev/null; then
        echo "$(echo "scale=2; $bytes / 1024 / 1024" | bc 2>/dev/null || echo "$((bytes / 1024 / 1024))") MB"
    elif [ "$bytes" -ge 1024 ] 2>/dev/null; then
        echo "$(echo "scale=2; $bytes / 1024" | bc 2>/dev/null || echo "$((bytes / 1024))") KB"
    else
        echo "${bytes} B"
    fi
}

# Collect all unique binary names across all profiles for a platform/arch
collect_binaries() {
    local out_dir="$1"
    local platform="$2"
    local arch="$3"
    
    find "$out_dir/$platform/$arch" -type f \( -name "*.dylib" -o -name "*.so*" -o -name "*.dll" \) 2>/dev/null | while read -r f; do
        basename "$f"
    done | sort -u
}

# Get size of a specific binary in a profile
get_binary_size() {
    local out_dir="$1"
    local platform="$2"
    local arch="$3"
    local binary_name="$4"
    
    local full_path="$out_dir/$platform/$arch/$binary_name"
    if [ -f "$full_path" ]; then
        stat -f%z "$full_path" 2>/dev/null || stat -c%s "$full_path" 2>/dev/null || echo "0"
    else
        echo "-"
    fi
}

# Generate report for a single platform
generate_platform_table() {
    local platform="$1"
    local platform_display
    platform_display=$(get_platform_name "$platform")
    
    # Collect all architectures for this platform across all profiles
    local archs_tmpfile
    archs_tmpfile=$(mktemp)
    for profile in "$PROFILE_DEBUG" "$PROFILE_BALANCED" "$PROFILE_SIZE" "$PROFILE_SPEED"; do
        local profile_dir="$SCRIPT_DIR/$profile"
        if [ -d "$profile_dir/$platform" ]; then
            for arch_dir in "$profile_dir/$platform"/*/; do
                [ -d "$arch_dir" ] || continue
                local arch
                arch=$(basename "$arch_dir")
                echo "$arch" >> "$archs_tmpfile"
            done
        fi
    done
    
    # Sort architectures (unique)
    local sorted_archs
    sorted_archs=($(sort -u "$archs_tmpfile"))
    rm -f "$archs_tmpfile"
    
    if [ ${#sorted_archs[@]} -eq 0 ]; then
        return
    fi
    
    echo ""
    echo "## $platform_display"
    echo ""
    
    # Process each architecture
    for arch in "${sorted_archs[@]}"; do
        echo "### $arch"
        echo ""
        
        # Collect all unique binary names across all profiles
        local binaries_tmpfile
        binaries_tmpfile=$(mktemp)
        for profile in "$PROFILE_DEBUG" "$PROFILE_BALANCED" "$PROFILE_SIZE" "$PROFILE_SPEED"; do
            local profile_dir="$SCRIPT_DIR/$profile"
            if [ -d "$profile_dir/$platform/$arch" ]; then
                collect_binaries "$profile_dir" "$platform" "$arch" >> "$binaries_tmpfile"
            fi
        done
        
        local binary_list
        binary_list=($(sort -u "$binaries_tmpfile"))
        rm -f "$binaries_tmpfile"
        
        if [ ${#binary_list[@]} -eq 0 ]; then
            echo "_No binaries found for $platform/$arch_"
            continue
        fi
        
        # Header row
        printf "| Binary | Debug | Balanced | Size-Opt | Speed-Opt |\n"
        
        # Separator row
        printf "|--------|---------|----------|----------|-----------|\n"
        
        # Data rows
        for binary in "${binary_list[@]}"; do
            printf "| \`%s\` |" "$binary"
            for profile in "$PROFILE_DEBUG" "$PROFILE_BALANCED" "$PROFILE_SIZE" "$PROFILE_SPEED"; do
                local profile_dir="$SCRIPT_DIR/$profile"
                if [ -d "$profile_dir/$platform/$arch" ]; then
                    local size
                    size=$(get_binary_size "$profile_dir" "$platform" "$arch" "$binary")
                    if [ "$size" != "-" ] && [ "$size" != "0" ]; then
                        printf " %s |" "$(format_size "$size")"
                    else
                        printf " _missing_ |"
                    fi
                else
                    printf " _N/A_ |"
                fi
            done
            printf "\n"
        done
        
        unset all_binaries
    done
}

# Generate summary statistics per profile
generate_summary() {
    echo ""
    echo "## Summary Statistics"
    echo ""
    
    # Header row
    printf "| Profile | Total Binaries | Total Size | macOS | Linux | Windows | Android | iOS |\n"
    
    # Separator row
    printf "|---------|----------------|------------|-------|-------|---------|---------|-----|\n"
    
    local profiles=("$PROFILE_DEBUG" "$PROFILE_BALANCED" "$PROFILE_SIZE" "$PROFILE_SPEED")
    local profile_keys=("debug" "balanced" "size" "speed")
    
    for i in 0 1 2 3; do
        local profile="${profiles[$i]}"
        local pkey="${profile_keys[$i]}"
        local profile_dir="$SCRIPT_DIR/$profile"
        local total_binaries=0
        local total_size=0
        local platform_counts=""
        
        for platform in $PLATFORMS; do
            local p_count=0
            local p_size=0
            
            if [ -d "$profile_dir/$platform" ]; then
                while IFS= read -r lib; do
                    [ -f "$lib" ] || continue
                    local size
                    size=$(stat -f%z "$lib" 2>/dev/null || stat -c%s "$lib" 2>/dev/null || echo 0)
                    p_count=$((p_count + 1))
                    p_size=$((p_size + size))
                done < <(find "$profile_dir/$platform" -type f \( -name "*.dylib" -o -name "*.so*" -o -name "*.dll" \) 2>/dev/null | sort)
            fi
            
            total_binaries=$((total_binaries + p_count))
            total_size=$((total_size + p_size))
            
            if [ $p_count -gt 0 ]; then
                platform_counts+=" $(format_size "$p_size")"
            else
                platform_counts+=" _-"
            fi
        done
        
        printf "| %s | %d | %s |%s |\n" \
            "$(get_profile_name "$profile")" \
            "$total_binaries" \
            "$(format_size "$total_size")" \
            "$platform_counts"
    done
}

# Generate build status summary
generate_build_status() {
    echo ""
    echo "## Build Status by Profile"
    echo ""
    
    # Header row
    printf "| Grammar | Debug | Balanced | Size-Opt | Speed-Opt |\n"
    printf "|---------|-------|----------|----------|-----------|\n"
    
    local profiles=("$PROFILE_DEBUG" "$PROFILE_BALANCED" "$PROFILE_SIZE" "$PROFILE_SPEED")
    
    # Check each grammar in the grammars directory
    for grammar_dir in "$SCRIPT_DIR/grammars"/*/; do
        [ -d "$grammar_dir" ] || continue
        local grammar_full
        grammar_full=$(basename "$grammar_dir")
        local grammar_name="${grammar_full#tree-sitter-}"
        grammar_name="${grammar_name%-master}"
        grammar_name="${grammar_name%-main}"
        
        # Check if it has CMakeLists.txt
        if [ ! -f "$grammar_dir/CMakeLists.txt" ]; then
            printf "| %s | _no CMake_ | _no CMake_ | _no CMake_ | _no CMake_ |\n" "$grammar_name"
            continue
        fi
        
        local status_debug="_skip_"
        local status_balanced="_skip_"
        local status_size="_skip_"
        local status_speed="_skip_"
        
        for idx in 0 1 2 3; do
            local profile="${profiles[$idx]}"
            local profile_dir="$SCRIPT_DIR/$profile"
            local has_output=0
            
            # Check if any platform has output for this grammar
            for platform in $PLATFORMS; do
                if [ -d "$profile_dir/$platform" ]; then
                    for arch_dir in "$profile_dir/$platform"/*/; do
                        [ -d "$arch_dir" ] || continue
                        # Check for any tree-sitter-${grammar_name}* binary
                        if ls "$arch_dir"/tree-sitter-${grammar_name}.* 2>/dev/null | head -1 > /dev/null 2>&1; then
                            has_output=1
                            break 2
                        fi
                        # Also check libtree-sitter-${grammar_name}*
                        if ls "$arch_dir"/libtree-sitter-${grammar_name}.* 2>/dev/null | head -1 > /dev/null 2>&1; then
                            has_output=1
                            break 2
                        fi
                    done
                fi
            done
            
            case "$profile" in
                out-debug)     [ $has_output -eq 1 ] && status_debug="✓" || status_debug="_fail_" ;;
                out-balanced)  [ $has_output -eq 1 ] && status_balanced="✓" || status_balanced="_fail_" ;;
                out-size)      [ $has_output -eq 1 ] && status_size="✓" || status_size="_fail_" ;;
                out-speed)     [ $has_output -eq 1 ] && status_speed="✓" || status_speed="_fail_" ;;
            esac
        done
        
        printf "| %s | %s | %s | %s | %s |\n" \
            "$grammar_name" "$status_debug" "$status_balanced" "$status_size" "$status_speed"
    done
}

# Main
main() {
    local report_file="$SCRIPT_DIR/profiles.md"
    
    echo "Generating profiles.md report..."
    
    cat > "$report_file" <<EOF
# Tree-Sitter Build Profiles Comparison Report

> **Generated**: $(date)
> **Host Platform**: $(uname -s) $(uname -m)
> **Script**: \`generate-profiles-report.sh\`

## Overview

This report compares binary artifacts across all build profiles:

| Profile | Description | Optimization Flags |
|---------|-------------|-------------------|
| Debug | No optimization, no LTO, no strip | \`-DCMAKE_BUILD_TYPE=Debug\` |
| Balanced | Moderate optimization with LTO and strip | \`-DCMAKE_BUILD_TYPE=Release\`, LTO ON |
| Size-Optimized | Smallest binary size | \`-Os\`, LTO ON, strip |
| Speed-Optimized | Fastest execution | \`-O2\`, LTO ON, strip |

## Platform Comparison

EOF
    
    # Generate platform tables
    for platform in $PLATFORMS; do
        generate_platform_table "$platform" >> "$report_file"
    done
    
    # Add summary
    generate_summary >> "$report_file"
    
    # Add build status
    generate_build_status >> "$report_file"
    
    echo ""
    echo "Report generated: $report_file"
    echo ""
    
    # Print quick stats
    local total_profiles=0
    for profile in "$PROFILE_DEBUG" "$PROFILE_BALANCED" "$PROFILE_SIZE" "$PROFILE_SPEED"; do
        if [ -d "$SCRIPT_DIR/$profile" ]; then
            total_profiles=$((total_profiles + 1))
        fi
    done
    
    local total_grammars
    total_grammars=$(find "$SCRIPT_DIR/grammars" -mindepth 1 -maxdepth 1 -type d | wc -l)
    
    echo "Quick Stats:"
    echo "  Profiles scanned: $total_profiles"
    echo "  Grammars in repo: $total_grammars"
    echo "  Platforms: 5 (macOS, Linux, Windows, Android, iOS)"
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
