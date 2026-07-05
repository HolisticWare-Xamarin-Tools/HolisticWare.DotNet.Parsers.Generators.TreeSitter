# Windows x86_64 (MinGW)
set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR x86_64)
set(CMAKE_C_COMPILER "${CMAKE_CURRENT_LIST_DIR}/../wrappers/zig-x86_64-windows-cc")

# Use Zig's archiver (macOS ar doesn't support @response-file syntax)
set(CMAKE_AR "${CMAKE_CURRENT_LIST_DIR}/../wrappers/zig-x86_64-windows-ar" CACHE FILEPATH "Path to archiver")
set(CMAKE_RANLIB "${CMAKE_CURRENT_LIST_DIR}/../wrappers/zig-x86_64-windows-ranlib" CACHE FILEPATH "Path to ranlib")

# Disable @response-file syntax (macOS ar doesn't support it)
set(CMAKE_USE_RESPONSE_FILE_FOR_OBJECTS OFF)
set(CMAKE_USE_RESPONSE_FILE_FOR_LIBRARIES OFF)
set(CMAKE_USE_RESPONSE_FILE_FOR_LINKER OFF)
set(CMAKE_USE_RESPONSE_FILE_FOR_INCLUDES OFF)

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
