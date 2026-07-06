#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="$SCRIPT_DIR/out"

echo "=== Tree-Sitter Library Baseline Measurements ==="
echo ""

for platform in macos linux windows ios android; do
    for arch_dir in "$OUT_DIR/$platform"/*/; do
        [ -d "$arch_dir" ] || continue
        arch=$(basename "$arch_dir")
        
        echo "--- $platform/$arch ---"
        
        # Size metrics
        total_size=0
        binary_count=0
        largest=0
        largest_name=""
        
        for lib in "$arch_dir"/*.dylib "$arch_dir"/*.so "$arch_dir"/*.dll; do
            [ -f "$lib" ] || continue
            size=$(stat -f%z "$lib" 2>/dev/null || stat -c%s "$lib" 2>/dev/null || echo 0)
            name=$(basename "$lib")
            total_size=$((total_size + size))
            binary_count=$((binary_count + 1))
            
            if [ "$size" -gt "$largest" ]; then
                largest=$size
                largest_name=$name
            fi
            
            # Symbol count (non-Windows)
            if [[ "$platform" != "windows" ]]; then
                sym_count=$(nm "$lib" 2>/dev/null | wc -l || echo 0)
                echo "  $name: $(du -h "$lib" | cut -f1) ($sym_count symbols)"
            else
                echo "  $name: $(du -h "$lib" | cut -f1)"
            fi
        done
        
        echo "  Total: $binary_count binaries, $(($total_size / 1024 / 1024))MB total, largest: $largest_name ($(($largest / 1024))KB)"
        echo ""
    done
done
