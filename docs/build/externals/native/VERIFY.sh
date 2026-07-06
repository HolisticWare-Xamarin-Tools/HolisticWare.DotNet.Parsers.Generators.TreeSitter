#!/bin/bash
# Verify the build output

echo "🔍 Tree-Sitter Build Verification"
echo "=================================="
echo ""

echo "📊 Build Output Summary:"
echo ""

for platform in macos linux windows ios android; do
    count=$(find out -path "*/$platform/*" -type f 2>/dev/null | wc -l)
    if [ $count -gt 0 ]; then
        echo "✅ $platform:"
        find out -path "*/$platform/*" -type d | sort | while read dir; do
            arch=$(basename "$dir")
            files=$(find "$dir" -type f | wc -l)
            echo "   └─ $arch: $files binaries"
        done
    fi
done

echo ""
echo "📈 Total Statistics:"
total_files=$(find out -type f 2>/dev/null | wc -l)
total_dirs=$(find out -type d 2>/dev/null | wc -l)
total_size=$(du -sh out 2>/dev/null | awk '{print $1}')

echo "   Files: $total_files"
echo "   Directories: $total_dirs"
echo "   Total Size: $total_size"

echo ""
echo "🔧 Build Command Examples:"
echo ""
echo "  # Build all platforms"
echo "  ./build-all.sh"
echo ""
echo "  # Build specific platform"
echo "  ./build-all.sh --platform macos"
echo ""
echo "  # Build specific grammars"
echo "  ./build-all.sh --grammar-filter c,cpp,python"
echo ""
echo "  # Clean and rebuild"
echo "  ./build-all.sh --clean"
echo ""

echo "📖 Documentation:"
echo "   See BUILD.md for detailed setup and troubleshooting"
