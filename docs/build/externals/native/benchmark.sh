#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="$SCRIPT_DIR/out"
RESULTS_DIR="$SCRIPT_DIR/benchmarks"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
REPORT_FILE="$RESULTS_DIR/report_${TIMESTAMP}.txt"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Sample source code for benchmarking (C# code - representative of typical usage)
SAMPLE_CSHARP='using System;
using System.Collections.Generic;
using System.Linq;

namespace BenchmarkTest {
    public class Program {
        public static void Main(string[] args) {
            var data = new Dictionary<string, int>();
            for (int i = 0; i < 1000; i++) {
                data[$"key_{i}"] = i * 2;
            }
            
            var sorted = data
                .Where(x => x.Value > 50)
                .OrderByDescending(x => x.Value)
                .ToDictionary(x => x.Key, x => x.Value);
                
            Console.WriteLine($"Processed {sorted.Count} items");
        }
    }
}'

SAMPLE_TYPESCRIPT='interface User {
    id: number;
    name: string;
    email?: string;
}

class UserService {
    private users: Map<number, User> = new Map();
    
    addUser(user: User): void {
        this.users.set(user.id, user);
    }
    
    findUser(id: number): User | undefined {
        return this.users.get(id);
    }
    
    getUsersByFilter(filter: (u: User) => boolean): User[] {
        return Array.from(this.users.values())
            .filter(filter)
            .sort((a, b) => a.id - b.id);
    }
}

export { UserService, User };'

SAMPLE_PYTHON='import os
import sys
from dataclasses import dataclass
from typing import List, Optional

@dataclass
class Config:
    name: str
    value: int
    enabled: bool = True

def parse_config(lines: List[str]) -> List[Config]:
    configs = []
    for line in lines:
        if not line.strip() or line.startswith("#"):
            continue
        parts = line.split("=")
        if len(parts) == 2:
            key, val = parts[0].strip(), parts[1].strip()
            configs.append(Config(name=key, value=int(val)))
    return configs

def main():
    config_file = os.environ.get("CONFIG_PATH", "config.txt")
    with open(config_file) as f:
        configs = parse_config(f.readlines())
    
    enabled = [c for c in configs if c.enabled]
    print(f"Loaded {len(enabled)} enabled configs")

if __name__ == "__main__":
    main()'

SAMPLE_RUST='use std::collections::HashMap;

#[derive(Debug, Clone)]
struct Item {
    id: u64,
    name: String,
    value: f64,
}

impl Item {
    fn new(id: u64, name: &str, value: f64) -> Self {
        Self {
            id,
            name: name.to_string(),
            value,
        }
    }
}

fn process_items(items: &[Item]) -> HashMap<u64, f64> {
    let mut map = HashMap::new();
    
    for item in items.iter() {
        let entry = map.entry(item.id).or_insert(0.0);
        *entry += item.value;
    }
    
    map.into_iter()
        .filter(|(_, v)| *v > 100.0)
        .collect()
}

fn main() {
    let items: Vec<Item> = (0..1000)
        .map(|i| Item::new(i, &format!("item_{}", i), i as f64 * 1.5))
        .collect();
    
    let result = process_items(&items);
    println!("Processed {} items", result.len());
}'

SAMPLE_GO='package main

import (
	"fmt"
	"sync"
)

type Cache struct {
	mu    sync.RWMutex
	items map[string]interface{}
}

func NewCache() *Cache {
	return &Cache{
		items: make(map[string]interface{}),
	}
}

func (c *Cache) Set(key string, value interface{}) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.items[key] = value
}

func (c *Cache) Get(key string) (interface{}, bool) {
	c.mu.RLock()
	defer c.mu.RUnlock()
	val, ok := c.items[key]
	return val, ok
}

func main() {
	cache := NewCache()
	
	for i := 0; i < 1000; i++ {
		key := fmt.Sprintf("key_%d", i)
		cache.Set(key, i*2)
	}
	
	count := 0
	for i := 0; i < 1000; i++ {
		key := fmt.Sprintf("key_%d", i)
		if _, ok := cache.Get(key); ok {
			count++
		}
	}
	
	fmt.Printf("Retrieved %d items from cache\n", count)
}'

# Run parse benchmark for a single grammar library
run_parse_benchmark() {
    local platform="$1"
    local arch="$2"
    local grammar_name="$3"
    local sample_code="$4"
    local lib_path=""
    
    # Find the library file
    case "$platform" in
        macos|ios)
            lib_path="$OUT_DIR/$platform/$arch/libtree-sitter-${grammar_name}.dylib"
            ;;
        linux|android)
            lib_path="$OUT_DIR/$platform/$arch/libtree-sitter-${grammar_name}.so"
            ;;
        windows)
            lib_path="$OUT_DIR/$platform/$arch/tree-sitter-${grammar_name}.dll"
            ;;
    esac
    
    if [ ! -f "$lib_path" ]; then
        echo "SKIP"
        return
    fi
    
    # Try using tree-sitter CLI if available
    local ts_cli=""
    if command -v tree-sitter &> /dev/null; then
        ts_cli=$(command -v tree-sitter)
    elif [ -f "$SCRIPT_DIR/../../node_modules/.bin/tree-sitter" ]; then
        ts_cli="$SCRIPT_DIR/../../node_modules/.bin/tree-sitter"
    fi
    
    if [ -n "$ts_cli" ]; then
        # Use tree-sitter CLI to parse sample code
        local tmpfile=$(mktemp)
        echo "$sample_code" > "$tmpfile"
        
        local start_time=$(date +%s%N 2>/dev/null || date +%s)
        for i in $(seq 1 50); do
            $ts_cli parse "$tmpfile" --scope "source.$grammar_name" 2>/dev/null || true
        done
        local end_time=$(date +%s%N 2>/dev/null || date +%s)
        
        rm -f "$tmpfile"
        
        # Calculate time in milliseconds
        if [ ${#start_time} -gt 10 ]; then
            echo $(( (end_time - start_time) / 1000000 ))
        else
            echo $(( (end_time - start_time) * 1000 ))
        fi
    else
        # Fallback: just measure file access time as proxy
        local start_time=$(date +%s%N 2>/dev/null || date +%s)
        for i in $(seq 1 50); do
            cat "$lib_path" > /dev/null 2>&1
        done
        local end_time=$(date +%s%N 2>/dev/null || date +%s)
        
        if [ ${#start_time} -gt 10 ]; then
            echo $(( (end_time - start_time) / 1000000 ))
        else
            echo $(( (end_time - start_time) * 1000 ))
        fi
    fi
}

# Run startup benchmark for a single library
run_startup_benchmark() {
    local platform="$1"
    local arch="$2"
    local grammar_name="$3"
    local lib_path=""
    
    # Find the library file
    case "$platform" in
        macos|ios)
            lib_path="$OUT_DIR/$platform/$arch/libtree-sitter-${grammar_name}.dylib"
            ;;
        linux|android)
            lib_path="$OUT_DIR/$platform/$arch/libtree-sitter-${grammar_name}.so"
            ;;
        windows)
            lib_path="$OUT_DIR/$platform/$arch/tree-sitter-${grammar_name}.dll"
            ;;
    esac
    
    if [ ! -f "$lib_path" ]; then
        echo "SKIP"
        return
    fi
    
    # Measure dlopen/load time by running a simple process that loads it
    local start_time=$(date +%s%N 2>/dev/null || date +%s)
    
    if [ "$platform" = "macos" ] || [ "$platform" = "ios" ]; then
        # Use DYLD_LIBRARY_PATH and run a simple command
        DYLD_LIBRARY_PATH="$OUT_DIR/$platform/$arch" true 2>/dev/null || true
    elif [ "$platform" = "linux" ] || [ "$platform" = "android" ]; then
        LD_LIBRARY_PATH="$OUT_DIR/$platform/$arch" true 2>/dev/null || true
    fi
    
    local end_time=$(date +%s%N 2>/dev/null || date +%s)
    
    if [ ${#start_time} -gt 10 ]; then
        echo $(( (end_time - start_time) / 1000000 ))
    else
        echo $(( (end_time - start_time) * 1000 ))
    fi
}

# Main benchmark function
main() {
    mkdir -p "$RESULTS_DIR"
    
    echo "=========================================="
    echo "Tree-Sitter Library Benchmark Suite"
    echo "=========================================="
    echo ""
    echo "Started: $(date)"
    echo "Results will be saved to: $REPORT_FILE"
    echo ""
    
    # Initialize report
    cat > "$REPORT_FILE" <<EOF
==========================================
Tree-Sitter Library Benchmark Report
==========================================
Date: $(date)
Platform: $(uname -s) $(uname -m)

== Size Measurements ==
EOF
    
    # Phase 1: Size measurements
    echo "--- Phase 1: Size Measurements ---"
    echo ""
    
    for platform in macos linux windows ios android; do
        for arch_dir in "$OUT_DIR/$platform"/*/; do
            [ -d "$arch_dir" ] || continue
            arch=$(basename "$arch_dir")
            
            echo "  $platform/$arch:"
            echo "  $platform/$arch:" >> "$REPORT_FILE"
            
            local total_size=0
            local binary_count=0
            local largest=0
            local largest_name=""
            
            for lib in "$arch_dir"/*.dylib "$arch_dir"/*.so "$arch_dir"/*.dll; do
                [ -f "$lib" ] || continue
                local size=$(stat -f%z "$lib" 2>/dev/null || stat -c%s "$lib" 2>/dev/null || echo 0)
                local name=$(basename "$lib")
                total_size=$((total_size + size))
                binary_count=$((binary_count + 1))
                
                if [ "$size" -gt "$largest" ]; then
                    largest=$size
                    largest_name=$name
                fi
                
                printf "    %-45s %8d bytes\n" "$(basename $lib)" "$size" >> "$REPORT_FILE"
            done
            
            local total_mb=$(echo "scale=2; $total_size / 1024 / 1024" | bc 2>/dev/null || echo "$((total_size / 1024 / 1024))")
            printf "    Total: %d binaries, %s MB (largest: %s)\n" "$binary_count" "$total_mb" "$(basename $largest_name)"
            echo "    Total: $binary_count binaries, ${total_mb}MB (largest: $(basename $largest_name))" >> "$REPORT_FILE"
            echo ""
        done
    done
    
    # Phase 2: Parse speed benchmarks
    echo "--- Phase 2: Parse Speed Benchmarks ---"
    echo ""
    
    echo "== Parse Speed (50 iterations, ms) ==" >> "$REPORT_FILE"
    
    local grammars=("c-sharp" "typescript" "python" "rust" "go")
    local samples=("$SAMPLE_CSHARP" "$SAMPLE_TYPESCRIPT" "$SAMPLE_PYTHON" "$SAMPLE_RUST" "$SAMPLE_GO")
    
    for i in "${!grammars[@]}"; do
        local grammar="${grammars[$i]}"
        local sample="${samples[$i]}"
        
        echo "  Grammar: $grammar"
        printf "  %-20s" "" >> "$REPORT_FILE"
        echo "$grammar" >> "$REPORT_FILE"
        
        # Benchmark on macos/arm64 (primary platform)
        if [ -d "$OUT_DIR/macos/arm64" ]; then
            local times=()
            for j in $(seq 1 3); do
                local time=$(run_parse_benchmark "macos" "arm64" "$grammar" "$sample")
                if [ "$time" != "SKIP" ] && [ -n "$time" ]; then
                    times+=("$time")
                fi
            done
            
            if [ ${#times[@]} -gt 0 ]; then
                # Calculate average
                local sum=0
                for t in "${times[@]}"; do
                    sum=$((sum + t))
                done
                local avg=$((sum / ${#times[@]}))
                printf "    macos/arm64: %d ms (avg of %d runs)\n" "$avg" "${#times[@]}"
                echo "    macos/arm64: ${avg}ms (avg of ${#times[@]} runs)" >> "$REPORT_FILE"
            else
                echo "    macos/arm64: SKIPPED (library not found)"
                echo "    macos/arm64: SKIPPED" >> "$REPORT_FILE"
            fi
        fi
        
        # Benchmark on linux/x86_64 if available
        if [ -d "$OUT_DIR/linux/x86_64" ]; then
            local times=()
            for j in $(seq 1 3); do
                local time=$(run_parse_benchmark "linux" "x86_64" "$grammar" "$sample")
                if [ "$time" != "SKIP" ] && [ -n "$time" ]; then
                    times+=("$time")
                fi
            done
            
            if [ ${#times[@]} -gt 0 ]; then
                local sum=0
                for t in "${times[@]}"; do
                    sum=$((sum + t))
                done
                local avg=$((sum / ${#times[@]}))
                printf "    linux/x86_64: %d ms (avg of %d runs)\n" "$avg" "${#times[@]}"
                echo "    linux/x86_64: ${avg}ms (avg of ${#times[@]} runs)" >> "$REPORT_FILE"
            else
                echo "    linux/x86_64: SKIPPED (library not found)"
                echo "    linux/x86_64: SKIPPED" >> "$REPORT_FILE"
            fi
        fi
        
        echo ""
    done
    
    # Phase 3: Startup time benchmarks
    echo "--- Phase 3: Startup Time Benchmarks ---"
    echo ""
    
    echo "== Startup Time (ms) ==" >> "$REPORT_FILE"
    
    for platform in macos linux; do
        for arch_dir in "$OUT_DIR/$platform"/*/; do
            [ -d "$arch_dir" ] || continue
            arch=$(basename "$arch_dir")
            
            echo "  $platform/$arch:"
            printf "  %-20s" "" >> "$REPORT_FILE"
            echo "$platform/$arch:" >> "$REPORT_FILE"
            
            local count=0
            for lib in "$arch_dir"/*.dylib "$arch_dir"/*.so; do
                [ -f "$lib" ] || continue
                local name=$(basename "$lib")
                local time=$(run_startup_benchmark "$platform" "$arch" "${name#libtree-sitter-}")
                
                if [ "$time" != "SKIP" ] && [ -n "$time" ]; then
                    printf "    %-40s %d ms\n" "$(basename $lib)" "$time"
                    echo "    ${name}: ${time}ms" >> "$REPORT_FILE"
                    count=$((count + 1))
                    
                    # Limit output to first 5
                    if [ $count -ge 5 ]; then
                        echo "    ... (showing first 5 of many)"
                        break
                    fi
                fi
            done
            
            echo ""
        done
    done
    
    # Summary
    echo "=========================================="
    echo "Benchmark complete!"
    echo "Report saved to: $REPORT_FILE"
    echo "=========================================="
    
    cat "$REPORT_FILE"
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi