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
