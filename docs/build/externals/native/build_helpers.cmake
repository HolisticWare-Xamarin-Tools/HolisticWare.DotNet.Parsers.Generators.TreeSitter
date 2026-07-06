# build_helpers.cmake — shared CMake utilities for the build system.

# Set standard tree-sitter library properties on a target.
function(configure_treesitter_target TARGET_NAME)
    set_target_properties(${TARGET_NAME} PROPERTIES
        C_STANDARD 11
        POSITION_INDEPENDENT_CODE ON
        SOVERSION "${TREE_SITTER_ABI_VERSION}.0"
        DEFINE_SYMBOL ""
    )
endfunction()

# Copy built libraries from the build directory to a designated output folder.
function(copy_libraries BUILD_DIR OUTPUT_DIR EXTENSION)
    file(GLOB built_libs "${BUILD_DIR}/**/tree-sitter-*.${EXTENSION}")
    foreach(lib ${built_libs})
        if(EXISTS "${lib}")
            get_filename_component(basename "${lib}" NAME)
            message(STATUS "Copying ${basename} -> ${OUTPUT_DIR}")
            configure_file("${lib}" "${OUTPUT_DIR}/${basename}" COPYONLY)
        endif()
    endforeach()
endfunction()
