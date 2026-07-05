# Tree-Sitter Build Troubleshooting Guide

Comprehensive troubleshooting guide for common issues during tree-sitter binary compilation.

## Table of Contents

1. [Prerequisites Issues](#prerequisites-issues)
2. [CMake Configuration Errors](#cmake-configuration-errors)
3. [Compilation Errors](#compilation-errors)
4. [Platform-Specific Issues](#platform-specific-issues)
5. [Binary Verification Issues](#binary-verification-issues)
6. [Performance Issues](#performance-issues)

---

## Prerequisites Issues

### Issue: "cmake: command not found"

**Symptoms**:
```
./build-all.sh: line XX: cmake: command not found
```

**Causes**:
- CMake not installed
- CMake not in PATH

**Solutions**:

**macOS**:
```bash
# Install with Homebrew
brew install cmake

# Or install from https://cmake.org/download/

# Verify installation
cmake --version
```

**Linux (Ubuntu/Debian)**:
```bash
# Install from package manager
sudo apt-get update
sudo apt-get install cmake

# Verify installation
cmake --version
```

**Windows**:
```
# Download and install from https://cmake.org/download/
# Ensure "Add CMake to the system PATH" is checked during installation
# Restart terminal/PowerShell after installation

cmake --version
```

---

### Issue: "zig: command not found"

**Symptoms**:
```
./build-all.sh: line XX: zig: command not found
```

**Causes**:
- Zig not installed
- Zig not in PATH
- Old/incompatible Zig version

**Solutions**:

**All Platforms**:
```bash
# Download from https://ziglang.org/download/

# Add to PATH:
export PATH=$PATH:/path/to/zig-directory

# Verify installation
zig version

# For permanent PATH update, add to ~/.bashrc or ~/.zshrc:
export PATH=$PATH:/path/to/zig-directory
source ~/.bashrc  # or ~/.zshrc
```

**macOS (Homebrew)**:
```bash
brew install zig

# Or with latest:
brew reinstall zig
```

---

### Issue: Missing verification tools

**Symptoms**:
```
Tool 'file' not found. Required for binary verification.
Tool 'nm' not found. Required for binary verification.
Tool 'objdump' not found. Required for binary verification.
```

**Solutions**:

**macOS**:
```bash
# Install Xcode Command Line Tools
xcode-select --install

# These tools come with Xcode CLI tools
```

**Linux**:
```bash
# Ubuntu/Debian
sudo apt-get install binutils file

# RHEL/CentOS
sudo yum install binutils file
```

**Windows**:
```
# Install MSYS2 or Git Bash which includes these tools
# Or use WSL (Windows Subsystem for Linux) for native Linux environment
```

---

## CMake Configuration Errors

### Issue: "Toolchain file not found"

**Symptoms**:
```
CMake Error at CMakeLists.txt:1 (cmake_minimum_required):
  Could not find cmake module file:
    .../cmake/toolchains/zig-x86_64-macos.cmake
```

**Causes**:
- Toolchain files missing or in wrong location
- Incorrect toolchain filename

**Solutions**:

```bash
# Verify toolchain files exist
ls -la cmake/toolchains/

# Expected files:
# zig-x86_64-macos.cmake
# zig-aarch64-macos.cmake
# zig-x86_64-linux.cmake
# zig-aarch64-linux.cmake
# zig-x86_64-windows.cmake
# zig-aarch64-android.cmake
# zig-aarch64-ios.cmake

# Ensure they're readable
chmod 644 cmake/toolchains/*.cmake

# Verify from externals/native directory
pwd  # Should be .../externals/native
ls cmake/toolchains/
```

---

### Issue: "CMAKE_TOOLCHAIN_FILE is not set"

**Symptoms**:
```
CMake Error: CMAKE_TOOLCHAIN_FILE not specified.
```

**Causes**:
- build-all.sh not finding toolchain path
- Incorrect working directory

**Solutions**:

```bash
# Ensure you're in the correct directory
cd externals/native

# Verify toolchain path is correct
echo $SCRIPT_DIR
# Should output: .../externals/native

# Run build script from native directory
./build-all.sh
```

---

## Compilation Errors

### Issue: "Compiler error" / Undefined reference

**Symptoms**:
```
error: undefined reference to 'tree_sitter_...'
error: conflicting types for '...'
```

**Causes**:
- Incompatible Zig version
- Corrupted source files
- Cross-compilation configuration issue

**Solutions**:

```bash
# Clean and rebuild
./build-all.sh --clean

# Rebuild with verbose output
rm -rf build/
cmake -S docs/build -B build/macos_x86_64 \
  -DCMAKE_TOOLCHAIN_FILE=cmake/toolchains/zig-x86_64-macos.cmake \
  -DCMAKE_BUILD_TYPE=Release --debug-output
cmake --build build/macos_x86_64 --verbose

# Re-download grammars if corrupted
rm -rf grammars/
../download-clone-native.sh
```

---

### Issue: "Compiler not found"

**Symptoms**:
```
CMake Error at cmake/toolchains/zig-*.cmake:1:
  Compiler 'zig-x86_64-linux-cc' not found.
```

**Causes**:
- Compiler wrapper scripts missing or not executable
- Zig installation incomplete

**Solutions**:

```bash
# Verify wrapper scripts exist and are executable
ls -la cmake/wrappers/
chmod +x cmake/wrappers/zig-*-cc

# Verify they can execute
./cmake/wrappers/zig-x86_64-macos-cc --version

# Reinstall Zig if wrappers fail
brew reinstall zig  # macOS
# or download fresh from https://ziglang.org/download/
```

---

### Issue: "Library not found" / Linking errors

**Symptoms**:
```
ld: library not found for -lSystem
ld: warning: cannot find entry point symbol _main; not setting LC_MAIN
```

**Causes**:
- macOS SDK issues
- Incorrect cross-compilation configuration
- Missing system libraries

**Solutions**:

**macOS**:
```bash
# Update Xcode and SDKs
xcode-select --install
# or
xcode-select --reset
softwareupdate -i -a  # Update macOS and tools

# Verify SDK path
xcrun --show-sdk-path

# Verify Zig can access SDKs
zig version --verbose
```

**Other platforms**:
```bash
# Re-configure and clean rebuild
./build-all.sh --clean --platform linux
```

---

## Platform-Specific Issues

### macOS Issues

#### Issue: "xcrun: not found" or SDK errors

**Symptoms**:
```
xcrun: error: unable to find utility
Code Signing Identity:  (null)
```

**Causes**:
- Xcode Command Line Tools not installed
- Xcode path misconfigured

**Solutions**:
```bash
# Install or reset Xcode CLI tools
xcode-select --install
# or
xcode-select --reset

# Verify SDK location
xcrun --show-sdk-path

# Select correct Xcode version
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

#### Issue: "arm64" build fails on Intel Mac

**Symptoms**:
```
CMake Error: Unsupported architecture: arm64
```

**Causes**:
- Rosetta 2 not enabled
- Zig missing ARM64 support

**Solutions**:
```bash
# Ensure Rosetta 2 is installed
softwareupdate --install-rosetta --agree-to-license

# Verify Zig supports cross-compilation
zig targets | grep aarch64

# Ensure CMake is native (not under Rosetta)
file $(which cmake)
# Should show: Mach-O 64-bit executable arm64 (on Apple Silicon)
# or Mach-O 64-bit executable x86_64 (on Intel)
```

---

### Linux Issues

#### Issue: "glibc" version mismatch

**Symptoms**:
```
./binary: /lib64/libc.so.6: version `GLIBC_2.32' not found
```

**Causes**:
- Binary compiled with newer glibc than target system
- Cross-compilation glibc mismatch

**Solutions**:
```bash
# Check system glibc version
ldd --version | head -1

# Verify binary glibc dependency
objdump -T out/linux/x86_64/tree-sitter-*.so | grep GLIBC

# Rebuild targeting specific glibc version
# (Modify CMakeLists.txt if needed)
```

#### Issue: "arm64" build on x86_64 Linux

**Symptoms**:
```
Cannot execute format file. Exec format error.
```

**Causes**:
- ARM64 binary ran on x86_64 system
- Cross-compilation not configured

**Solutions**:
```bash
# Verify binary architecture
file out/linux/arm64/tree-sitter-*.so
# Should show: "ELF 64-bit LSB shared object, ARM aarch64"

# Install QEMU if you need to test ARM binaries
sudo apt-get install qemu-user-static

# Run with qemu
qemu-aarch64-static out/linux/arm64/tree-sitter-c-sharp.so
```

---

### Android Issues

#### Issue: "Android NDK not found"

**Symptoms**:
```
Android NDK not found. Please set ANDROID_NDK_HOME or install Android NDK r25c or later.
```

**Causes**:
- Android NDK not installed
- ANDROID_NDK_HOME not set
- Wrong NDK version

**Solutions**:

```bash
# Download NDK r25c or later
wget https://developer.android.com/ndk/downloads/ndk-r25c.zip
unzip ndk-r25c.zip

# Set environment variable
export ANDROID_NDK_HOME=/path/to/android-ndk-r25c-or-later

# Add to permanent PATH (~/.bashrc or ~/.zshrc)
export ANDROID_NDK_HOME=/path/to/android-ndk-r25c-or-later

# Verify NDK
ls $ANDROID_NDK_HOME/toolchains/llvm/prebuilt/
```

#### Issue: "API level mismatch"

**Symptoms**:
```
error: target API level is 21 but STL requires minimum 21
```

**Causes**:
- Android API level too low
- Build configuration mismatch

**Solutions**:
```bash
# Verify minimum API level
# Current config: API 21

# If needed, update in toolchain file:
# cmake/toolchains/zig-aarch64-android.cmake

# Or modify build command
./build-all.sh --platform android
```

---

### iOS Issues

#### Issue: "iOS SDK not found"

**Symptoms**:
```
ld: could not find SDK path for 'iphoneos'
```

**Causes**:
- Xcode or iOS SDK not installed
- Incorrect Xcode path

**Solutions**:
```bash
# Install Xcode from App Store
# or command line tools
xcode-select --install

# Verify iOS SDK
xcrun --show-sdk-path --sdk iphoneos

# List available SDKs
xcodebuild -showsdks

# Reset Xcode path if needed
sudo xcode-select --reset
```

#### Issue: "Minimum deployment target mismatch"

**Symptoms**:
```
error: iPhone OS deployment target is 14.0 but SDK is 12.0
```

**Causes**:
- iOS deployment target mismatch
- Xcode version too old

**Solutions**:
```bash
# Update Xcode
softwareupdate -i -a

# Verify iOS SDK version
xcrun -show-sdk-version --sdk iphoneos

# Rebuild with fresh configuration
./build-all.sh --clean --platform ios
```

---

### Windows Issues

#### Issue: "Microsoft Visual C++ Redistributable not found"

**Symptoms**:
```
The program can't start because MSVCP140.dll is missing
```

**Causes**:
- Visual C++ redistributables not installed
- Architecture mismatch (32-bit vs 64-bit)

**Solutions**:
```
# Download Visual C++ Redistributable
# https://support.microsoft.com/en-us/help/2977003

# Or install Visual Studio Community
# https://visualstudio.microsoft.com/

# Install MinGW or MSYS2 as alternative
```

#### Issue: "Long path names fail"

**Symptoms**:
```
cmake: error creating directory "path\to\build\"
filename too long
```

**Causes**:
- Windows path length limitation (260 chars)
- Deep directory nesting

**Solutions**:
```powershell
# Enable long paths in Windows 10/11
reg add HKLM\SYSTEM\CurrentControlSet\Control\FileSystem /v LongPathsEnabled /t REG_DWORD /d 1

# Or use shorter paths
cd C:\build  # Shorter path than nested dirs
```

---

## Binary Verification Issues

### Issue: "File type validation failed"

**Symptoms**:
```
[✗ FAIL] Expected PE32 format, got: ...
[✗ FAIL] Expected Mach-O format, got: ...
```

**Causes**:
- Build produced wrong output format
- Cross-compilation configured incorrectly
- Corrupted binary

**Solutions**:

```bash
# Check binary manually
file out/windows/x64/tree-sitter-*.dll

# Rebuild platform
./build-all.sh --clean --platform windows

# Verify all binaries
./verify-binaries.sh --platform windows
```

---

### Issue: "No tree_sitter symbols found"

**Symptoms**:
```
[✗ FAIL] No tree_sitter symbols found
```

**Causes**:
- Binary is not a tree-sitter library
- Symbols stripped during compilation
- Compilation failed silently

**Solutions**:

```bash
# Verify binary is correct
nm out/macos/x86_64/tree-sitter-c-sharp.dylib | grep tree_sitter

# Check if symbols were stripped
nm out/macos/x86_64/tree-sitter-c-sharp.dylib | wc -l

# Rebuild without stripping
./build-all.sh --clean --platform macos

# Check CMakeLists.txt for strip commands
grep -r "strip" docs/build/
```

---

### Issue: "Cannot read symbols with nm"

**Symptoms**:
```
[✗ FAIL] Cannot read symbols with nm
```

**Causes**:
- Binary format not supported by nm on current platform
- nm not installed

**Solutions**:

```bash
# Verify nm is installed and working
which nm
nm --version

# Try alternative tools
# macOS
nm out/macos/x86_64/tree-sitter-*.dylib
otool -L out/macos/x86_64/tree-sitter-*.dylib

# Linux
nm out/linux/x86_64/tree-sitter-*.so
readelf -s out/linux/x86_64/tree-sitter-*.so

# Windows
dumpbin /EXPORTS out/windows/x64/tree-sitter-*.dll
```

---

## Performance Issues

### Issue: Build takes too long

**Symptoms**:
- Build takes >30 minutes for single platform
- All CPU cores not utilized

**Solutions**:

```bash
# Increase parallel jobs
# Modify build-all.sh, change:
# cmake --build ... 
# to:
# cmake --build ... --parallel 8

# Build only specific grammars
./build-all.sh --grammar-filter c-sharp,typescript

# Build one platform at a time
./build-all.sh --platform macos
```

---

### Issue: Disk space exhaustion during build

**Symptoms**:
```
CMake Error: Disk I/O error
Could not create directory
```

**Causes**:
- Insufficient disk space
- Too many intermediate files

**Solutions**:

```bash
# Check disk space
df -h

# Clean build directories
rm -rf build/
./build-all.sh --clean

# Clean old logs
rm -rf logs/
```

---

## Getting Help

If you encounter issues not listed here:

1. **Check build logs**:
   ```bash
   tail -100 logs/build_*.log
   ```

2. **Enable verbose output**:
   ```bash
   cmake --build build/macos_x86_64 --verbose
   ```

3. **Run verification with details**:
   ```bash
   ./verify-binaries.sh --platform macos
   cat logs/verification_*.txt
   ```

4. **Check system information**:
   ```bash
   uname -a
   cmake --version
   zig version
   file $(which cmake)
   ```

5. **Consult references**:
   - Tree-Sitter: https://tree-sitter.github.io/tree-sitter/
   - CMake: https://cmake.org/cmake/help/latest/
   - Zig: https://ziglang.org/documentation/
