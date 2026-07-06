#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="$SCRIPT_DIR/out"
RESULTS_DIR="$SCRIPT_DIR/benchmarks"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
REPORT_FILE="$RESULTS_DIR/size-report_${TIMESTAMP}.txt"
CSV_FILE="$RESULTS_DIR/size-report_${TIMESTAMP}.csv"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Platform display names
declare -A PLATFORM_NAMES=(
    ["macos"]="macOS"
    ["linux"]="Linux"
    ["windows"]="Windows"
    ["ios"]="iOS"
    ["android"]="Android"
)

declare -A ARCH_NAMES=(
    ["x86_64"]="x86_64"
    ["arm64"]="ARM64"
    ["aarch64"]="ARM64"
    ["amd64"]="AMD64"
)

# Get human-readable platform name
get_platform_name() {
    local platform="$1"
    echo "${PLATFORM_NAMES[$platform]:-$platform}"
}

get_arch_name() {
    local arch="$1"
    echo "${ARCH_NAMES[$arch]:-$arch}"
}

# Format bytes to human readable
format_size() {
    local bytes=$1
    if [ $bytes -ge 1048576 ]; then
        echo "$(echo "scale=2; $bytes / 1024 / 1024" | bc 2>/dev/null || echo "$((bytes / 1024 / 1024))") MB"
    elif [ $bytes -ge 1024 ]; then
        echo "$(echo "scale=2; $bytes / 1024" | bc 2>/dev/null || echo "$((bytes / 1024))") KB"
    else
        echo "${bytes} B"
    fi
}

# Generate markdown table row
format_md_row() {
    local platform="$1"
    local arch="$2"
    local total_bytes="$3"
    local binary_count="$4"
    local largest_bytes="$5"
    local largest_name="$6"
    
    printf "| %s | %s | %d | %s | %s | %s |\n" \
        "$(get_platform_name "$platform")" \
        "$(get_arch_name "$arch")" \
        "$binary_count" \
        "$(format_size "$total_bytes")" \
        "$(format_size "$largest_bytes")" \
        "$largest_name"
}

# Main report generation
main() {
    mkdir -p "$RESULTS_DIR"
    
    echo "=========================================="
    echo "Tree-Sitter Size Comparison Report"
    echo "=========================================="
    echo ""
    echo "Generating report for all platforms..."
    echo ""
    
    # Initialize CSV
    echo "platform,arch,binary_count,total_size_bytes,total_size_human,largest_binary,largest_size_bytes,largest_size_human" > "$CSV_FILE"
    
    # Initialize markdown report
    cat > "$REPORT_FILE" <<EOF
==========================================
Tree-Sitter Library Size Comparison Report
==========================================
Generated: $(date)
Host Platform: $(uname -s) $(uname -m)

== Summary ==

| Platform | Architecture | Binaries | Total Size | Largest Binary | Largest Name |
|----------|-------------|----------|------------|----------------|--------------|
EOF
    
    # Track overall statistics
    local grand_total_size=0
    local grand_total_binaries=0
    local overall_largest=0
    local overall_largest_name=""
    
    # Process each platform
    for platform in macos linux windows ios android; do
        echo "Processing $platform..."
        
        local platform_total=0
        local platform_binaries=0
        
        for arch_dir in "$OUT_DIR/$platform"/*/; do
            [ -d "$arch_dir" ] || continue
            local arch=$(basename "$arch_dir")
            
            local total_size=0
            local binary_count=0
            local largest=0
            local largest_name=""
            
            # Collect all binaries
            while IFS= read -r lib; do
                [ -f "$lib" ] || continue
                
                local size=$(stat -f%z "$lib" 2>/dev/null || stat -c%s "$lib" 2>/dev/null || echo 0)
                local name=$(basename "$lib")
                
                total_size=$((total_size + size))
                binary_count=$((binary_count + 1))
                
                if [ "$size" -gt "$largest" ]; then
                    largest=$size
                    largest_name=$name
                fi
                
                # Add to CSV
                echo "$platform,$arch,$binary_count,$total_size,$(format_size $total_size),$largest_name,$largest,$(format_size $largest)" >> "$CSV_FILE"
            done < <(find "$arch_dir" -type f \( -name "*.dylib" -o -name "*.so" -o -name "*.dll" \) 2>/dev/null | sort)
            
            if [ $binary_count -gt 0 ]; then
                platform_total=$((platform_total + total_size))
                platform_binaries=$((platform_binaries + binary_count))
                
                # Update grand totals
                grand_total_size=$((grand_total_size + total_size))
                grand_total_binaries=$((grand_total_binaries + binary_count))
                
                if [ "$largest" -gt "$overall_largest" ]; then
                    overall_largest=$largest
                    overall_largest_name=$largest_name
                fi
                
                # Add to markdown table
                format_md_row "$platform" "$arch" "$total_size" "$binary_count" "$largest" "$largest_name" >> "$REPORT_FILE"
                
                printf "  %-20s: %d binaries, %s total, largest: %s (%s)\n" \
                    "$(get_arch_name $arch)" \
                    "$binary_count" \
                    "$(format_size $total_size)" \
                    "$largest_name" \
                    "$(format_size $largest)"
            else
                printf "  %-20s: No binaries found\n" "$(get_arch_name $arch)" >> "$REPORT_FILE"
            fi
        done
        
        echo ""
    done
    
    # Add summary to markdown report
    cat >> "$REPORT_FILE" <<EOF

== Summary Statistics ==

| Metric | Value |
|--------|-------|
| Total Platforms | 5 |
| Total Architectures | $grand_total_binaries binaries across all platforms |
| Grand Total Size | $(format_size $grand_total_size) |
| Largest Single Binary | $overall_largest_name ($(format_size $overall_largest)) |

== Top 10 Largest Binaries ==

| Rank | Platform/Arch | Binary | Size |
|------|--------------|--------|------|
EOF
    
    # Find top 10 largest binaries across all platforms
    local rank=0
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        rank=$((rank + 1))
        
        local full_path="$line"
        local platform=$(echo "$full_path" | sed 's|.*/out/||' | cut -d'/' -f1)
        local arch=$(echo "$full_path" | sed 's|.*/out/||' | cut -d'/' -f2)
        local name=$(basename "$full_path")
        local size=$(stat -f%z "$full_path" 2>/dev/null || stat -c%s "$full_path" 2>/dev/null || echo 0)
        
        if [ $rank -le 10 ]; then
            printf "| %d | %s/%s | %s | %s |\n" \
                "$rank" \
                "$(get_platform_name $platform)" \
                "$(get_arch_name $arch)" \
                "$name" \
                "$(format_size $size)" >> "$REPORT_FILE"
        fi
    done < <(find "$OUT_DIR" -type f \( -name "*.dylib" -o -name "*.so" -o -name "*.dll" \) -exec stat -f%z {} \; 2>/dev/null | sort -rn | head -10)
    
    # Add per-grammar comparison if available
    cat >> "$REPORT_FILE" <<EOF

== Per-Grammar Size Comparison ==

| Grammar | macOS/arm64 | Linux/x86_64 | Windows/x64 | iOS/arm64 | Android/arm64 |
|---------|-------------|--------------|-------------|-----------|---------------|
EOF
    
    # Get list of all grammar names
    local grammars=()
    for arch_dir in "$OUT_DIR/macos/arm64"/*/; do
        [ -d "$arch_dir" ] || continue
        for lib in "$arch_dir"/*.dylib; do
            [ -f "$lib" ] || continue
            local name=$(basename "$lib")
            # Extract grammar name (remove libtree-sitter- prefix and .dylib suffix)
            local grammar_name="${name#libtree-sitter-}"
            grammar_name="${grammar_name%.dylib}"
            grammars+=("$grammar_name")
        done
    done
    
    # Remove duplicates
    grammars=($(printf '%s\n' "${grammars[@]}" | sort -u))
    
    for grammar in "${grammars[@]}"; do
        local sizes=()
        local has_data=false
        
        # macOS arm64
        if [ -f "$OUT_DIR/macos/arm64/libtree-sitter-${grammar}.dylib" ]; then
            sizes+=("$(format_size $(stat -f%z "$OUT_DIR/macos/arm64/libtree-sitter-${grammar}.dylib"))")
            has_data=true
        else
            sizes+=("-")
        fi
        
        # Linux x86_64
        if [ -f "$OUT_DIR/linux/x86_64/libtree-sitter-${grammar}.so" ]; then
            sizes+=("$(format_size $(stat -f%z "$OUT_DIR/linux/x86_64/libtree-sitter-${grammar}.so"))")
            has_data=true
        else
            sizes+=("-")
        fi
        
        # Windows x64
        if [ -f "$OUT_DIR/windows/x64/tree-sitter-${grammar}.dll" ]; then
            sizes+=("$(format_size $(stat -f%z "$OUT_DIR/windows/x64/tree-sitter-${grammar}.dll"))")
            has_data=true
        else
            sizes+=("-")
        fi
        
        # iOS arm64
        if [ -f "$OUT_DIR/ios/arm64/libtree-sitter-${grammar}.dylib" ]; then
            sizes+=("$(format_size $(stat -f%z "$OUT_DIR/ios/arm64/libtree-sitter-${grammar}.dylib"))")
            has_data=true
        else
            sizes+=("-")
        fi
        
        # Android arm64
        if [ -f "$OUT_DIR/android/arm64/libtree-sitter-${grammar}.so" ]; then
            sizes+=("$(format_size $(stat -f%z "$OUT_DIR/android/arm64/libtree-sitter-${grammar}.so"))")
            has_data=true
        else
            sizes+=("-")
        fi
        
        if [ "$has_data" = true ]; then
            printf "| %s | %s | %s | %s | %s | %s |\n" \
                "$grammar" \
                "${sizes[0]}" \
                "${sizes[1]}" \
                "${sizes[2]}" \
                "${sizes[3]}" \
                "${sizes[4]}" >> "$REPORT_FILE"
        fi
    done
    
    # Add final summary
    cat >> "$REPORT_FILE" <<EOF

== File Locations ==

- Report: $REPORT_FILE
- CSV Data: $CSV_FILE

== Notes ==

- Sizes are measured on $(uname -s) $(uname -m)
- Binary counts include all .dylib, .so, and .dll files
- Windows binaries may differ in size due to different linking strategies
- LTO and stripping effects are included if enabled during build

==========================================
End of Report
==========================================
EOF
    
    echo ""
    echo "=========================================="
    echo "Report Generation Complete!"
    echo "=========================================="
    echo ""
    echo "Markdown Report: $REPORT_FILE"
    echo "CSV Data:        $CSV_FILE"
    echo ""
    echo "Quick Summary:"
    echo "  Total binaries across all platforms: $grand_total_binaries"
    echo "  Grand total size: $(format_size $grand_total_size)"
    echo "  Largest single binary: $overall_largest_name ($(format_size $overall_largest))"
    echo ""
    
    # Print the markdown report to stdout as well
    cat "$REPORT_FILE"
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi