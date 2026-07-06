cmake_minimum_required(VERSION 3.13)

project(tree-sitter-csv
        VERSION "1.2.0"
        DESCRIPTION "CSV, PSV, TSV grammars for tree-sitter"
        HOMEPAGE_URL "https://github.com/tree-sitter-grammars/tree-sitter-csv"
        LANGUAGES C)

option(BUILD_SHARED_LIBS "Build using shared libraries" ON)
option(TREE_SITTER_REUSE_ALLOCATOR "Reuse the library allocator" ON)
option(TREE_SITTER_GRAMMAR_OPTIMIZE_SPEED "Use -O2 instead of -Os for better speed" OFF)

set(TREE_SITTER_ABI_VERSION 15 CACHE STRING "Tree-sitter ABI version")
if(NOT ${TREE_SITTER_ABI_VERSION} MATCHES "^[0-9]+$")
    unset(TREE_SITTER_ABI_VERSION CACHE)
    message(FATAL_ERROR "TREE_SITTER_ABI_VERSION must be an integer")
endif()

find_program(TREE_SITTER_CLI tree-sitter DOC "Tree-sitter CLI")

include(GNUInstallDirs)

macro(add_parser name)
    # Generate parser.c from grammar.json (if tree-sitter CLI available)
    if(TREE_SITTER_CLI)
        add_custom_command(OUTPUT "${CMAKE_CURRENT_SOURCE_DIR}/src/parser.c"
                           DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/src/grammar.json"
                           COMMAND "${TREE_SITTER_CLI}" generate src/grammar.json
                                    --abi=${TREE_SITTER_ABI_VERSION}
                           WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
                           COMMENT "Generating parser.c for ${name}")
    endif()

    # Build library from parser.c (and scanner.c if present)
    set(PARSER_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/src/parser.c")
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/src/scanner.c")
        list(APPEND PARSER_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/src/scanner.c")
    endif()

    add_library(tree-sitter-${name} ${PARSER_SOURCES})
    target_include_directories(tree-sitter-${name} PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/src")

    target_compile_definitions(tree-sitter-${name} PRIVATE
                               $<$<BOOL:${TREE_SITTER_REUSE_ALLOCATOR}>:TREE_SITTER_REUSE_ALLOCATOR>
                               $<$<CONFIG:Debug>:TREE_SITTER_DEBUG>)

    # Optimization flags
    if(TREE_SITTER_GRAMMAR_OPTIMIZE_SPEED)
        set(GRAMMAR_OPT_FLAGS "-O2")
    else()
        set(GRAMMAR_OPT_FLAGS "-Os")
    endif()
    target_compile_options(tree-sitter-${name} PRIVATE ${GRAMMAR_OPT_FLAGS})

    set_target_properties(tree-sitter-${name}
                          PROPERTIES
                          C_STANDARD 11
                          POSITION_INDEPENDENT_CODE ON
                          SOVERSION "${TREE_SITTER_ABI_VERSION}.${PROJECT_VERSION_MAJOR}"
                          DEFINE_SYMBOL "")

    # Install headers from root bindings/c/tree_sitter/ (shared across csv/psv/tsv)
    install(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/bindings/c/tree_sitter"
            DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"
            FILES_MATCHING PATTERN "*.h")
    install(TARGETS tree-sitter-${name}
            LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}")
endmacro()

# Build all three grammar variants
add_subdirectory(csv tree-sitter-csv)
add_subdirectory(psv tree-sitter-psv)
add_subdirectory(tsv tree-sitter-tsv)

add_custom_target(ts-test "${TREE_SITTER_CLI}" test
                  WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
                  COMMENT "tree-sitter test")
