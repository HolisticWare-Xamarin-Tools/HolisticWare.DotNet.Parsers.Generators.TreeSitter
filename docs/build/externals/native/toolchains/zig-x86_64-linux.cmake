# Linux x86_64
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR x86_64)
set(CMAKE_C_COMPILER "${CMAKE_CURRENT_LIST_DIR}/../wrappers/zig-x86_64-linux-cc")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# Zig cross-compilation for Linux defaults to stripping symbols
# Work around by using objcopy to preserve them
# Add post-build step to keep symbols after build
set(CMAKE_C_FLAGS_INIT "-g")
# Disable strip during install
set(CMAKE_INSTALL_DO_STRIP FALSE)
