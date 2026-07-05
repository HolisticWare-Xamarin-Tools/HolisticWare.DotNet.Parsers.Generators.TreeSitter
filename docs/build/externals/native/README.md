# Tree-Sitter Native Binaries Build Guide

This directory contains build scripts and configuration for cross-platform compilation of tree-sitter language parser binaries.

## Overview

Tree-Sitter is a parser generator tool and an incremental parsing library. This build system compiles tree-sitter grammar parsers for multiple platforms and architectures using CMake and Zig cross-compilation toolchains.

### Supported Platforms & Architectures

| Platform | Architecture | Output Format | Requirements |
|----------|--------------|---------------|--------------|
| macOS | x86_64 (Intel) | `.dylib` | macOS 10.15+ |
| macOS | arm64 (Apple Silicon) | `.dylib` | macOS 10.15+ |
| Linux | x86_64 | `.so` | glibc 2.29+ |
| Linux | arm64 | `.so` | glibc 2.29+ |
| Windows | x86_64 | `.dll` | Windows 7+ |
| Android | arm64 | `.so` | NDK r25c+, API 21+ |
| iOS | arm64 | `.dylib` | iOS 14+ |

### Core Library

Each build produces a shared `libtree-sitter` core library alongside grammar-specific libraries. Grammars link against the core at runtime, reducing binary size through code sharing.

## Prerequisites

### Required Tools

- **CMake 3.13+** - Build system
- **Zig** - Cross-compilation toolchain
- **Standard utilities** - `file`, `nm`, `objdump` (for verification)

### Platform-Specific Requirements

#### macOS
```bash
# Install CMake
brew install cmake

# Install Zig
brew install zig

# For iOS builds, ensure Xcode Command Line Tools are installed
xcode-select --install
```

#### Linux (Ubuntu/Debian)
```bash
# Install CMake
sudo apt-get install cmake

# Install Zig
wget https://ziglang.org/download/latest/zig-linux-x86_64-latest.tar.xz
tar xf zig-linux-x86_64-latest.tar.xz
sudo mv zig-linux-x86_64-* /opt/zig
export PATH=$PATH:/opt/zig

# Install build tools
sudo apt-get install build-essential file binutils
```

#### Windows
```bash
# Install CMake from https://cmake.org/download/
# Install Zig from https://ziglang.org/download/

# Ensure CMake and Zig are in your PATH
cmake --version
zig version
```

#### Android NDK (for Android builds)
```bash
# Install Android NDK r25c or later
# Option 1: Using Android Studio
# Option 2: Download directly
wget https://developer.android.com/ndk/downloads/ndk-r25c.zip
unzip ndk-r25c.zip
export ANDROID_NDK_HOME=/path/to/android-ndk
```

## Directory Structure

```
externals/native/
├── out/                           # Output directory (git-ignored)
│   ├── macos/
│   │   ├── x86_64/               # macOS Intel binaries
│   │   └── arm64/                # macOS ARM binaries
│   ├── linux/
│   │   ├── x86_64/
│   │   └── arm64/
│   ├── windows/
│   │   └── x64/
│   ├── android/
│   │   └── arm64/
│   └── ios/
│       └── arm64/
├── build/                        # Intermediate build directories (git-ignored)
├── logs/                         # Build logs (git-ignored)
├── core/                         # Tree-sitter core source (tree-sitter-master/)
│   └── CMakeLists.txt            # Core build wrapper
├── grammars/                     # Tree-sitter grammar sources
├── cmake/                        # CMake configuration
│   ├── toolchains/              # Zig cross-compilation toolchains
│   ├── wrappers/                # Zig compiler wrappers
│   └── build_helpers.cmake      # CMake helper functions
├── build-all.sh                 # Master build script
├── build-*.sh                   # Platform-specific helper scripts
├── verify-binaries.sh           # Binary verification script
├── README.md                    # This file
└── .gitignore
```

## Building

### Quick Start

```bash
cd externals/native

# Build all platforms
./build-all.sh

# Build specific platform
./build-all.sh --platform macos

# Build with specific grammars
./build-all.sh --grammar-filter c-sharp,typescript,rust

# Clean build (remove intermediate artifacts)
./build-all.sh --clean

# Verify only (don't build, just check existing binaries)
./build-all.sh --verify-only
```

### Platform-Specific Build Scripts

Convenience scripts for individual platforms:

```bash
# macOS
./build-macos-x86_64.sh
./build-macos-arm64.sh

# Linux
./build-linux-x86_64.sh
./build-linux-arm64.sh

# Windows
./build-windows-x64.sh

# Android
./build-android-arm64.sh

# iOS
./build-ios-arm64.sh
```

### Available Options

```
--clean                             Clean build directories before building
--platform PLATFORM                 Build only specified platform
                                   (macos, linux, windows, android, ios)
--grammar-filter GRAMMARS          Comma-separated list of grammars to build
                                   (e.g., c-sharp,typescript,rust)
--verify-only                       Only verify existing binaries, don't build
--help                             Show help message
```

### Examples

```bash
# Build macOS binaries only
./build-all.sh --platform macos

# Build for Linux with specific grammars
./build-all.sh --platform linux --grammar-filter c-sharp,typescript

# Clean and rebuild everything
./build-all.sh --clean

# Quick verify without building
./build-all.sh --verify-only

# Full build with all grammars (no filter)
./build-all.sh
```

## Output

Compiled binaries are organized by platform and architecture in `out/`. Each directory contains the core library (`libtree-sitter`) plus all grammar-specific libraries:

```
out/
├── macos/x86_64/
│   ├── libtree-sitter.dylib              # Core library (shared across all grammars)
│   ├── libtree-sitter-c-sharp.dylib      # Grammar-specific parser
│   ├── libtree-sitter-typescript.dylib
│   └── ...
├── macos/arm64/
│   ├── libtree-sitter.dylib
│   └── ...
├── linux/x86_64/
│   ├── libtree-sitter.so
│   ├── libtree-sitter-c-sharp.so
│   └── ...
├── windows/x64/
│   ├── tree-sitter.dll                   # Core (Windows uses no prefix)
│   ├── tree-sitter-c-sharp.dll
│   └── ...
├── android/arm64/
│   ├── libtree-sitter.so
│   └── ...
└── ios/arm64/
    ├── libtree-sitter.dylib
    └── ...
```

## Binary Verification

Verify the integrity of compiled binaries:

```bash
# Verify all binaries
./verify-binaries.sh

# Verify specific platform
./verify-binaries.sh --platform macos

# Verify single binary
file out/macos/x86_64/tree-sitter-c-sharp.dylib
nm out/macos/x86_64/tree-sitter-c-sharp.dylib | grep tree_sitter
```

### Verification Checks

- **File type**: Validates correct format (Mach-O, ELF, PE)
- **Architecture**: Verifies target architecture matches expected
- **Symbols**: Checks for expected tree-sitter symbols
- **Details**: Reports file size and metadata

Verification reports are saved in `logs/verification_*.txt`.

## Build Logs

Build logs are automatically generated in `logs/build_*.log` with detailed output including:

- CMake configuration details
- Compiler output and warnings
- Copy operations
- Verification results

To inspect build logs:

```bash
# View latest build log
tail -f logs/build_*.log

# Grep for errors
grep ERROR logs/build_*.log
```

## CI/CD Integration

### GitHub Actions

The project includes automated builds via GitHub Actions (`.github/workflows/build-treesitter.yml`):

- **Triggers**: Push to main/develop, PR, manual dispatch, weekly schedule
- **Matrix**: All 7 platforms built in parallel
- **Artifacts**: 30-day retention for binaries and logs
- **Verification**: Automated binary verification in CI

### Local CI Simulation

Test the build locally to catch issues before pushing:

```bash
# Full clean build (mimics CI)
./build-all.sh --clean

# Verify all binaries
./verify-binaries.sh
```

## Architecture Details

### Cross-Compilation with Zig

Zig provides unified cross-compilation toolchains via:
- **CMake toolchain files**: `cmake/toolchains/zig-*.cmake`
- **Compiler wrappers**: `cmake/wrappers/zig-*-cc`
- **Configuration**: Platform, architecture, and optimization flags

### Build Targets

Configured targets for each platform:
- **Core library**: `libtree-sitter` — shared tree-sitter runtime (built once per platform)
- **Grammar libraries**: `libtree-sitter-{name}` — grammar-specific parsers (one per grammar)
- **ABI version**: Tree-sitter 15
- **C standard**: C11
- **Position independent code**: Enabled for security
- **Optimization**: Release build with optimizations

### Build Order

The build is a two-phase process:
1. **Core** — `libtree-sitter` is built once per platform/architecture
2. **Grammars** — Each grammar is built individually (to avoid target conflicts), linking against the core

This ensures the core library is compiled only once per platform, while grammars can be built independently.

### Linking & Dependencies

- **Core library**: `libtree-sitter.{dylib|so|dll}` — shared tree-sitter runtime, built once per platform
- **Grammar libraries**: Each grammar links against the core (`target_link_libraries(... PRIVATE tree-sitter)`)
- **Runtime dependency**: Consumers must have `libtree-sitter` on their system or bundle it alongside grammar libraries
- **No external runtime dependencies** beyond the core library and platform standard libs

## Troubleshooting

### CMake Configuration Fails

**Error**: `CMake Error: ... : not found`

**Solution**: Ensure Zig and CMake are installed and in PATH
```bash
cmake --version
zig version
echo $PATH
```

### Compiler Wrapper Not Found

**Error**: `zig-x86_64-macos-cc not found`

**Solution**: Verify toolchain wrapper scripts are executable and in correct location
```bash
ls -la cmake/wrappers/
chmod +x cmake/wrappers/zig-*-cc
```

### Binary Verification Fails

**Error**: `Invalid file type` or `Missing expected symbols`

**Solution**: Check build output or rebuild with verification
```bash
./build-all.sh --clean --platform macos
./verify-binaries.sh --platform macos
```

### Android NDK Issues

**Error**: `Android NDK not found`

**Solution**: Set ANDROID_NDK_HOME environment variable
```bash
export ANDROID_NDK_HOME=/path/to/android-ndk
./build-all.sh --platform android
```

### iOS Build Issues

**Error**: `Could not find macOS SDK`

**Solution**: Ensure Xcode Command Line Tools are installed
```bash
xcode-select --install
# or update existing installation
xcode-select --reset
```

## Benchmarking & Size Optimization

### Build Profiles

The build system supports four optimization profiles, selected with `--profile`:

| Profile | Flag | Optimization | LTO | Strip | Use when |
|---------|------|-------------|-----|-------|----------|
| `balanced` | *(default)* | `-Os` | ✓ | ✓ | Normal distribution builds |
| `size` | `--profile size` | `-Os` | ✓ | ✓ | Mobile / embedded targets |
| `speed` | `--profile speed` | `-O2` | ✓ | ✓ | High-throughput server use |
| `debug` | `--profile debug` | none | ✗ | ✗ | Local debugging |

```bash
# Default (balanced)
./build-all.sh

# Smallest binaries
./build-all.sh --profile size

# Fastest parse speed
./build-all.sh --profile speed

# Debug symbols, no optimization
./build-all.sh --profile debug

# Shortcut: parallel build + size profile
./build-all.sh --optimize
```

### Measuring Binary Sizes

**Quick snapshot** — print sizes for all pre-built binaries without rebuilding:

```bash
./build-all.sh --measure
```

**Detailed per-binary breakdown** — lists every binary with size and symbol count:

```bash
./measure-baseline.sh
```

Output example:
```
--- macos/arm64 ---
  libtree-sitter.dylib:          224K  (1423 symbols)
  libtree-sitter-c-sharp.dylib:  5.6M  (312 symbols)
  libtree-sitter-typescript.dylib: 3.1M (289 symbols)
  ...
  Total: 37 binaries, 48MB total, largest: libtree-sitter-c-sharp.dylib (5.7MB)
```

**Cross-platform size report** — generates a markdown table and CSV comparing all platforms:

```bash
./generate-size-report.sh
# → benchmarks/size-report_<timestamp>.txt  (markdown)
# → benchmarks/size-report_<timestamp>.csv  (CSV for spreadsheets)
```

The report includes:
- Total size per platform/architecture
- Top-10 largest binaries across all platforms
- Per-grammar size table comparing macOS / Linux / Windows / iOS / Android

### Benchmarking Parse Speed

Measure parse throughput across key grammars:

```bash
./benchmark.sh
# → benchmarks/report_<timestamp>.txt
```

The benchmark runs three phases:

1. **Size measurements** — all platforms
2. **Parse speed** — 50 parse iterations × 3 runs per grammar (C#, TypeScript, Python, Rust, Go), averaged; requires the `tree-sitter` CLI to be installed
3. **Startup time** — library load latency proxy

### Optimization Workflow

The recommended flow for comparing profiles:

```bash
# 1. Build and record baseline (balanced profile)
./build-all.sh --clean
./measure-baseline.sh > /tmp/baseline.txt

# 2. Rebuild with the target profile
./build-all.sh --clean --profile size    # or --profile speed

# 3. Compare
./measure-baseline.sh > /tmp/optimized.txt
diff /tmp/baseline.txt /tmp/optimized.txt

# 4. Cross-platform report for the chosen profile
./generate-size-report.sh

# 5. Parse speed check
./benchmark.sh
```

### Parallel Builds

Enable multi-core parallel compilation to cut build time:

```bash
# Auto-detect CPU cores
./build-all.sh --parallel

# Explicit job count
./build-all.sh --parallel --jobs 8

# Parallel + size profile (fastest optimized build)
./build-all.sh --optimize
```

### Caching & Incremental Builds

Build caches are stored in `build/`:
- CMake cache: `build/{platform}_{arch}/CMakeCache.txt`
- Object files and intermediate outputs
- Clear with `--clean` for a full rebuild

## Advanced Usage

### Building Specific Grammars Only

```bash
# Only C# and TypeScript
./build-all.sh --grammar-filter c-sharp,typescript

# Only C and C++
./build-all.sh --grammar-filter c,cpp

# Single grammar
./build-all.sh --grammar-filter rust
```

### Custom Build Configurations

Edit build scripts to modify:
- `CMAKE_BUILD_TYPE` (Release, Debug)
- `TREE_SITTER_ABI_VERSION` (currently 15)
- Additional CMake flags

### Debugging Builds

Enable verbose output:
```bash
# Modify build-all.sh to use --verbose flag
cmake --build build/macos_x86_64 --verbose
```

## Contributing

When modifying build scripts:

1. Test locally on target platform
2. Verify binaries with `verify-binaries.sh`
3. Check build logs for warnings
4. Ensure backward compatibility
5. Update documentation if adding features

## References

- **Tree-Sitter**: https://tree-sitter.github.io/tree-sitter/
- **CMake**: https://cmake.org/
- **Zig**: https://ziglang.org/
- **Android NDK**: https://developer.android.com/ndk/

## License

Follow the license of the tree-sitter project and grammar repositories.
