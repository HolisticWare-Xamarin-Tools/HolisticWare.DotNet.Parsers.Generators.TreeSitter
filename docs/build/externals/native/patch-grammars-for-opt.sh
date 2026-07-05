#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GRAMMARS_DIR="$SCRIPT_DIR/grammars"

for cmake_file in "$GRAMMARS_DIR"/*/CMakeLists.txt; do
    [ -f "$cmake_file" ] || continue
    
    # Check if already patched
    if grep -q "TREE_SITTER_GRAMMAR_OPTIMIZE_SPEED" "$cmake_file"; then
        echo "Already patched: $(basename $(dirname $cmake_file))"
        continue
    fi
    
    echo "Patching: $(basename $(dirname $cmake_file))"
    
    # Add optimization option after the TREE_SITTER_REUSE_ALLOCATOR option line
    sed -i '' '/^option(TREE_SITTER_REUSE_ALLOCATOR/a\
option(TREE_SITTER_GRAMMAR_OPTIMIZE_SPEED "Use -O2 instead of -Os for better speed" OFF)' "$cmake_file"
    
    # Add compile options before set_target_properties
    # Find the line with target_compile_definitions and add after it
    if ! grep -q "target_compile_options" "$cmake_file"; then
        sed -i '' '/^target_compile_definitions/a\
\
# Optimization flags\
if(TREE_SITTER_GRAMMAR_OPTIMIZE_SPEED)\
    set(GRAMMAR_OPT_FLAGS "-O2")\
else()\
    set(GRAMMAR_OPT_FLAGS "-Os")\
endif()\
\
target_compile_options(${PROJECT_NAME} PRIVATE ${GRAMMAR_OPT_FLAGS})' "$cmake_file"
    fi
done

echo "Done patching $(find $GRAMMARS_DIR -name CMakeLists.txt | wc -l) grammar files"
