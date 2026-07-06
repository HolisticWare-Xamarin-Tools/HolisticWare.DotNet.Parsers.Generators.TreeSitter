#!/usr/bin/env bash
# Android NDK build support script
# Configures Android NDK for cross-compilation

set -euo pipefail

# Try to find Android NDK
find_android_ndk() {
    # Check common locations in order of preference
    local ndk_paths=(
        "$ANDROID_NDK_HOME"
        "$ANDROID_HOME/ndk/29.0.14206865"  # Specific version
        "$ANDROID_HOME/ndk-bundle"
    )
    
    # Also check for latest NDK version in ANDROID_HOME/ndk
    if [ -n "${ANDROID_HOME:-}" ] && [ -d "$ANDROID_HOME/ndk" ]; then
        local latest_ndk=$(ls -1 "$ANDROID_HOME/ndk" 2>/dev/null | sort -V | tail -1)
        if [ -n "$latest_ndk" ]; then
            ndk_paths+=("$ANDROID_HOME/ndk/$latest_ndk")
        fi
    fi
    
    ndk_paths+=(
        "/opt/android-ndk"
        "/usr/local/android-ndk"
    )
    
    for ndk_path in "${ndk_paths[@]}"; do
        if [ -z "$ndk_path" ] || [ ! -d "$ndk_path" ]; then
            continue
        fi
        
        # Check for toolchain in common host platforms
        if [ -d "$ndk_path/toolchains/llvm/prebuilt/linux-x86_64" ]; then
            echo "$ndk_path"
            return 0
        fi
        if [ -d "$ndk_path/toolchains/llvm/prebuilt/darwin-x86_64" ]; then
            echo "$ndk_path"
            return 0
        fi
        if [ -d "$ndk_path/toolchains/llvm/prebuilt/darwin-arm64" ]; then
            echo "$ndk_path"
            return 0
        fi
        if [ -d "$ndk_path/toolchains/llvm/prebuilt/windows-x86_64" ]; then
            echo "$ndk_path"
            return 0
        fi
    done
    
    return 1
}

# Check if Android NDK is available
if ndk_home=$(find_android_ndk); then
    echo "✓ Android NDK found at: $ndk_home"
    
    # Determine the host platform for NDK
    ndk_host=""
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        ndk_host="linux-x86_64"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # Check for both x86_64 and arm64 variants
        if [ -d "$ndk_home/toolchains/llvm/prebuilt/darwin-arm64" ]; then
            ndk_host="darwin-arm64"
        elif [ -d "$ndk_home/toolchains/llvm/prebuilt/darwin-x86_64" ]; then
            ndk_host="darwin-x86_64"
        else
            echo "✗ No suitable Darwin NDK prebuilt found"
            exit 1
        fi
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        ndk_host="windows-x86_64"
    else
        echo "✗ Unsupported host platform for Android NDK"
        exit 1
    fi
    
    # Verify toolchain path exists
    if [ ! -d "$ndk_home/toolchains/llvm/prebuilt/$ndk_host" ]; then
        echo "✗ NDK toolchain not found for host: $ndk_host"
        echo "  Expected: $ndk_home/toolchains/llvm/prebuilt/$ndk_host"
        exit 1
    fi
    
    # Create directories
    mkdir -p toolchains
    
    # Create Android CMake toolchain using NDK
    cat > toolchains/ndk-aarch64-android.cmake << 'TOOLCHAIN_EOF'
# Android NDK Toolchain for CMake
# Auto-configured for tree-sitter cross-compilation

# Detect Android NDK home
if(NOT DEFINED ANDROID_NDK_HOME)
    if(DEFINED ENV{ANDROID_NDK_HOME})
        set(ANDROID_NDK_HOME $ENV{ANDROID_NDK_HOME})
    elseif(DEFINED ENV{ANDROID_HOME})
        # Try to find NDK in ANDROID_HOME
        file(GLOB NDK_VERSIONS "$ENV{ANDROID_HOME}/ndk/*")
        if(NDK_VERSIONS)
            # Use the latest version
            list(SORT NDK_VERSIONS)
            list(GET NDK_VERSIONS -1 ANDROID_NDK_HOME)
        else()
            set(ANDROID_NDK_HOME "$ENV{ANDROID_HOME}/ndk-bundle")
        endif()
    endif()
endif()

if(NOT EXISTS "${ANDROID_NDK_HOME}")
    message(FATAL_ERROR "Android NDK not found at ${ANDROID_NDK_HOME}. Set ANDROID_NDK_HOME or ANDROID_HOME.")
endif()

message(STATUS "Using Android NDK: ${ANDROID_NDK_HOME}")

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

# NDK configuration
set(ANDROID_NDK "${ANDROID_NDK_HOME}")
set(ANDROID_PLATFORM android-21)
set(ANDROID_ABI arm64-v8a)

# Determine host platform for NDK
if(APPLE)
    if(EXISTS "${ANDROID_NDK}/toolchains/llvm/prebuilt/darwin-arm64")
        set(NDK_HOST darwin-arm64)
    elseif(EXISTS "${ANDROID_NDK}/toolchains/llvm/prebuilt/darwin-x86_64")
        set(NDK_HOST darwin-x86_64)
    endif()
elseif(UNIX)
    set(NDK_HOST linux-x86_64)
else()
    set(NDK_HOST windows-x86_64)
endif()

message(STATUS "NDK Host Platform: ${NDK_HOST}")

set(NDK_LLVM ${ANDROID_NDK}/toolchains/llvm/prebuilt/${NDK_HOST})

if(NOT EXISTS "${NDK_LLVM}/bin/aarch64-linux-android21-clang")
    message(FATAL_ERROR "Android NDK toolchain not found at ${NDK_LLVM}")
endif()

set(CMAKE_C_COMPILER ${NDK_LLVM}/bin/aarch64-linux-android21-clang)
set(CMAKE_CXX_COMPILER ${NDK_LLVM}/bin/aarch64-linux-android21-clang++)

# Use NDK sysroot
set(CMAKE_SYSROOT ${ANDROID_NDK}/toolchains/llvm/prebuilt/${NDK_HOST}/sysroot)

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
TOOLCHAIN_EOF
    
    echo "✓ Created Android NDK toolchain: toolchains/ndk-aarch64-android.cmake"
    echo "✓ Android builds will use NDK from: $ndk_home"
else
    echo "✗ Android NDK not found"
    echo ""
    echo "To enable Android builds, install the Android NDK and set one of:"
    echo "  - ANDROID_NDK_HOME environment variable"
    echo "  - ANDROID_HOME environment variable (NDK should be at \$ANDROID_HOME/ndk/VERSION)"
    echo ""
    echo "Common installation locations:"
    echo "  - macOS: ~/Library/Android/sdk/ndk/29.0.14206865"
    echo "  - Linux: ~/Android/Sdk/ndk/29.0.14206865"
    echo "  - Windows: %LOCALAPPDATA%\\Android\\Sdk\\ndk\\29.0.14206865"
    exit 1
fi
