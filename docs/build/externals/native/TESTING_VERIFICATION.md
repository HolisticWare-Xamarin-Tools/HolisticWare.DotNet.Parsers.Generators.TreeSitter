# Testing & Verification Guide

Complete testing procedures for tree-sitter cross-platform builds.

## Quick Verification (5 minutes)

```bash
cd externals/native

# Test macOS build
./build-all.sh --platform macos --grammar-filter c,rust

# Test Linux cross-compile
./build-all.sh --platform linux --grammar-filter c,rust

# Test Windows cross-compile
./build-all.sh --platform windows --grammar-filter c,rust

# Check outputs
ls -la out/*/*/libtree-sitter-*.{dylib,so,dll}
```

## Full Platform Tests

### Test All Platforms (30 minutes)

Run complete build for all platforms with subset of grammars:

```bash
# Clean previous builds
rm -rf build/* out/*

# Test all platforms with limited grammar set
./build-all.sh --grammar-filter c,cpp,rust,python,javascript,typescript
```

**Expected output:**
```
✓ macos/x86_64:       12 binaries
✓ macos/arm64:        12 binaries
✓ linux/x86_64:        6 binaries
✓ linux/arm64:         6 binaries
✓ windows/x64:         6 binaries
✓ ios/arm64:          12 binaries
✓ android/arm64:       6 binaries

Total: 7/7 platforms built successfully
```

### Complete Build Test (3+ hours)

Build all grammars for all platforms:

```bash
./build-all.sh --clean

# Progress can be monitored
tail -f logs/build_*.log
```

**Expected results:**
- macOS: 80+ binaries per architecture
- Linux: 30+ binaries per architecture
- Windows: 30+ binaries for x64
- iOS: 30+ binaries for arm64
- Android: 30+ binaries for arm64

## Binary Verification

### File Type Verification

```bash
# macOS (should be Mach-O)
file out/macos/arm64/libtree-sitter-*.dylib
# Expected: Mach-O 64-bit dynamically linked shared library arm64

# Linux (should be ELF)
file out/linux/arm64/libtree-sitter-*.so
# Expected: ELF 64-bit LSB shared object, ARM aarch64

# Windows (should be PE32)
file out/windows/x64/tree-sitter-*.dll
# Expected: PE32+ executable (DLL) (console) x86-64

# iOS (should be Mach-O for iOS)
file out/ios/arm64/libtree-sitter-*.dylib
# Expected: Mach-O 64-bit dynamically linked shared library arm64

# Android (should be ELF)
file out/android/arm64/libtree-sitter-*.so
# Expected: ELF 64-bit LSB shared object, ARM aarch64
```

### Symbol Verification

```bash
# Check for tree-sitter symbols in macOS binaries
nm out/macos/arm64/libtree-sitter-bash.dylib | grep tree_sitter

# Check for symbols in Linux binaries (if on Linux)
readelf -s out/linux/x86_64/libtree-sitter-bash.so | grep tree_sitter

# On macOS, check cross-compiled Linux binaries (limited info)
nm out/linux/x86_64/libtree-sitter-bash.so | grep tree_sitter || echo "Symbol check skipped for cross-compiled binary"
```

### Size Verification

All libraries should be non-trivial size (> 100KB typical):

```bash
# Check library sizes
ls -lh out/*/*/libtree-sitter-*.{dylib,so,dll} | awk '{print $5, $9}'

# Example output:
# 200K   out/macos/arm64/libtree-sitter-bash.dylib
# 150K   out/linux/x86_64/libtree-sitter-c.so
# 180K   out/windows/x64/tree-sitter-rust.dll
```

## Grammar-Specific Tests

### Test Individual Grammars

```bash
# Test each grammar individually
for grammar in c cpp rust python javascript bash; do
    echo "=== Testing $grammar ==="
    ./build-all.sh --clean --platform macos --grammar-filter $grammar
    [ $? -eq 0 ] && echo "✓ $grammar OK" || echo "✗ $grammar FAILED"
done
```

### Test Previously Missing Grammars

These grammars had no CMakeLists.txt and were fixed:

```bash
# Test each fixed grammar
for grammar in capnp powershell scss swift thrift; do
    echo "=== Testing $grammar (previously missing) ==="
    ./build-all.sh --clean --platform macos --grammar-filter $grammar
    if [ $? -eq 0 ]; then
        echo "✓ $grammar OK"
        ls -la out/macos/*/libtree-sitter-$grammar.dylib
    else
        echo "✗ $grammar FAILED"
    fi
done
```

### Test Complex Grammars

Grammars with scanner.c (lexer) - more complex compilation:

```bash
# Grammars with scanner.c
for grammar in bash cpp javascript python rust typescript; do
    echo "=== Testing $grammar (complex) ==="
    ./build-all.sh --clean --platform macos --grammar-filter $grammar
    [ $? -eq 0 ] && echo "✓ $grammar OK" || echo "✗ $grammar FAILED"
done
```

## Build Log Analysis

### Check for Warnings

```bash
# Find all warnings in most recent build
grep -i "warning" logs/build_*.log | head -20

# Count warnings per platform
for log in logs/build_*.log; do
    echo "$(basename $log): $(grep -i warning $log | wc -l) warnings"
done
```

### Check for Errors

```bash
# Find all errors
grep -i "error\|failed" logs/build_*.log

# Count errors
grep -i "error\|failed" logs/build_*.log | wc -l
```

### Find Skipped Grammars

Some grammars may be skipped if CMakeLists.txt is missing:

```bash
grep "No CMakeLists.txt found" logs/build_*.log
# Should be empty after fixes
```

## Performance Testing

### Measure Build Time

```bash
# Time a complete macOS build
time ./build-all.sh --clean --platform macos

# Time platform-specific builds
time ./build-all.sh --clean --platform linux
time ./build-all.sh --clean --platform windows
time ./build-all.sh --clean --platform ios
time ./build-all.sh --clean --platform android
```

**Expected build times:**
- macOS native: 2-3 minutes
- Linux cross-compile: 3-4 minutes
- Windows cross-compile: 3-4 minutes
- iOS cross-compile: 3-4 minutes
- Android cross-compile: 3-4 minutes

### Parallel Build Stats

```bash
# Monitor CPU usage during build
# macOS
top -o cpu -s 1

# Linux
top -b -s 1

# Check if utilizing multiple cores
cmake --build build/macos_arm64 -j $(nproc)
```

## CI/CD Integration Testing

### GitHub Actions Example

```yaml
name: Build Tree-Sitter

on: [push, pull_request]

jobs:
  build:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install dependencies
        run: |
          brew install cmake zig tree-sitter
      - name: Test macOS build
        run: |
          cd externals/native
          ./build-all.sh --platform macos --grammar-filter c,rust,python
      - name: Test Linux cross-compile
        run: |
          cd externals/native
          ./build-all.sh --platform linux --grammar-filter c,rust
      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        with:
          name: tree-sitter-binaries
          path: externals/native/out/
```

## Regression Testing

### Before & After Comparison

After any CMakeLists.txt changes:

```bash
# Save baseline
./build-all.sh --clean
tar czf baseline-binaries.tar.gz out/

# Make changes to CMakeLists.txt
# ... (edit CMakeLists.txt)

# Test changes
./build-all.sh --clean
tar czf modified-binaries.tar.gz out/

# Compare binary counts
echo "Baseline:"
tar tzf baseline-binaries.tar.gz | wc -l
echo "Modified:"
tar tzf modified-binaries.tar.gz | wc -l
```

## Troubleshooting Test Failures

### If Test Fails at CMake Configuration

```bash
# Check CMakeLists.txt syntax
cmake -S externals/native -B /tmp/test-cmake 2>&1 | head -50

# Check for missing includes
grep "message(FATAL_ERROR" externals/native/CMakeLists.txt
```

### If Test Fails at Compilation

```bash
# Get verbose output
cd build/macos_arm64
cmake --build . --verbose 2>&1 | tail -100

# Check compiler availability
zig version
tree-sitter --version
cmake --version
```

### If Test Fails at Linking

```bash
# Check for missing libraries
ld -lm -lc --verbose 2>&1 | grep -i "error"

# Verify compiler wrapper scripts exist
ls -la cmake/wrappers/zig-*-cc
```

## Automated Testing Script

```bash
#!/bin/bash
set -e

cd externals/native

echo "=== Tree-Sitter Build Test Suite ==="
echo ""

# Test 1: Quick sanity check
echo "[1/5] Quick sanity check (macOS, 3 grammars)"
./build-all.sh --clean --platform macos --grammar-filter c,rust,python
echo "✓ Pass"

# Test 2: All macOS grammars
echo "[2/5] Complete macOS build"
./build-all.sh --clean --platform macos
[ "$(ls out/macos/x86_64/libtree-sitter-*.dylib | wc -l)" -gt 30 ] || exit 1
echo "✓ Pass"

# Test 3: Linux cross-compile
echo "[3/5] Linux cross-compile test"
./build-all.sh --clean --platform linux --grammar-filter c,rust
ls out/linux/x86_64/libtree-sitter-*.so > /dev/null
echo "✓ Pass"

# Test 4: Windows cross-compile
echo "[4/5] Windows cross-compile test"
./build-all.sh --clean --platform windows --grammar-filter c,rust
ls out/windows/x64/tree-sitter-*.dll > /dev/null
echo "✓ Pass"

# Test 5: All fixed grammars
echo "[5/5] Test previously missing grammars"
./build-all.sh --clean --platform macos --grammar-filter capnp,powershell,scss,swift,thrift
[ "$(ls out/macos/x86_64/libtree-sitter-*.dylib | wc -l)" -eq 10 ] || exit 1
echo "✓ Pass"

echo ""
echo "=== All Tests Passed! ==="
```

## Known Issues & Workarounds

### Issue: CMake Cache Conflicts
**Symptom:** "source does not match cache"
**Fix:** 
```bash
rm -rf build/
./build-all.sh --clean
```

### Issue: Zig Compiler Not Found
**Symptom:** "zig: command not found"
**Fix:**
```bash
brew install zig  # or download from ziglang.org
export PATH="$PATH:/path/to/zig"
```

### Issue: Tree-sitter CLI Not Found
**Symptom:** "tree-sitter: command not found"
**Fix:**
```bash
npm install -g tree-sitter-cli
# Or build from source
```

### Issue: Android NDK Not Detected
**Symptom:** "Android NDK setup failed"
**Fix:**
```bash
export ANDROID_NDK_HOME=/path/to/android-ndk-r29.x.x
./build-all.sh --platform android
```

## Success Criteria Checklist

- [ ] All 7 platforms build without errors
- [ ] No skipped grammars (except those marked TODO)
- [ ] Binary file types correct per platform
- [ ] Binary sizes reasonable (>100KB typical)
- [ ] Build times within expected range
- [ ] All previously missing grammars build
- [ ] Binaries verify without errors
- [ ] No unresolved symbols in core library
