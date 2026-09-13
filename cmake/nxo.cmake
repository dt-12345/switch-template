set(CMAKE_EXECUTABLE_SUFFIX ".nss")
set(CMAKE_SHARED_LIBRARY_PREFIX "")
set(CMAKE_SHARED_LIBRARY_SUFFIX ".nss")

add_subdirectory(${PROJECT_SOURCE_DIR}/stub/)

function(build_nxo target nxo_type shared_library enable_relro)
    set(EXTRA_ARGS ${ARGN})
    list(LENGTH EXTRA_ARGS NUM_EXTRA_ARGS)

    if(${NUM_EXTRA_ARGS} GREATER 0)
        list(GET EXTRA_ARGS 0 init)
    else()
        set(init _init)
    endif()

    if(${NUM_EXTRA_ARGS} GREATER 1)
        list(GET EXTRA_ARGS 1 fini)
    else()
        set(fini _fini)
    endif()

    set(MODULE_NAME ${target})
    string(LENGTH ${MODULE_NAME} MODULE_NAME_LENGTH)

    configure_file(${PROJECT_SOURCE_DIR}/template/rocrt_DebugLink.S.in template/rocrt_DebugLink.S @ONLY)

    target_sources(${target} PRIVATE
        ${CMAKE_BINARY_DIR}/template/rocrt_DebugLink.S
        ${PROJECT_SOURCE_DIR}/template/rocrt_Align.S
        ${PROJECT_SOURCE_DIR}/template/rocrt_LinkerSymbolGetter.cpp
    )

    target_include_directories(${target} PRIVATE ${PROJECT_SOURCE_DIR}/template/NX-NXFP2-a64)

    target_link_options(${target} PRIVATE -T${PROJECT_SOURCE_DIR}/scripts/aarch64.ld)
    target_link_options(${target} PRIVATE -Wl,--build-id=sha1)
    target_link_options(${target} PRIVATE -Wl,-init=${init},-fini=${fini})

    set_target_properties(${target} PROPERTIES LINK_DEPENDS ${PROJECT_SOURCE_DIR}/scripts/aarch64.ld)

    if(shared_library)
        target_link_options(${target} PRIVATE -shared)
    else()
        target_sources(${target} PRIVATE ${PROJECT_SOURCE_DIR}/template/MainRuntimeObject.cpp)

        # this is to fix any undefined symbols provided by the SDK
        # since this isn't a shared library, we can't just use -shared
        get_target_property(LINKED_LIBRARIES ${target} LINK_LIBRARIES)
        if(NOT "nnSdk" IN_LIST LINKED_LIBRARIES)
            target_link_libraries(${target} PRIVATE nnSdk)
        endif()
    endif()

    if(enable_relro)
        target_compile_definitions(${target} PRIVATE ENABLE_RELRO)
    endif()

    if(nxo_type STREQUAL "nso" OR nxo_type STREQUAL "NSO")
        target_sources(${target} PRIVATE
            ${PROJECT_SOURCE_DIR}/template/rocrt_Init.aarch64.S
            ${PROJECT_SOURCE_DIR}/template/rocrt.cpp
        )

        set_source_files_properties(${PROJECT_SOURCE_DIR}/template/rocrt.cpp PROPERTIES COMPILE_FLAGS -fno-exceptions)

        add_custom_command(TARGET ${target} POST_BUILD
            COMMAND ${PROJECT_SOURCE_DIR}/tools/elf2nso -o ${CMAKE_CURRENT_BINARY_DIR}/${target} ${CMAKE_CURRENT_BINARY_DIR}/${target}${CMAKE_EXECUTABLE_SUFFIX}
        )
    elseif(nxo_type STREQUAL "nro" OR nro_type STREQUAL "NRO")
        target_sources(${target} PRIVATE
            ${PROJECT_SOURCE_DIR}/template/rocrt_Init_nro.aarch64.S
            ${PROJECT_SOURCE_DIR}/template/rocrt_nro.cpp
        )

        set_source_files_properties(${PROJECT_SOURCE_DIR}/template/rocrt_nro.cpp PROPERTIES COMPILE_FLAGS -fno-exceptions)

        add_custom_command(TARGET ${target} POST_BUILD
            COMMAND ${PROJECT_SOURCE_DIR}/tools/elf2nro -o ${CMAKE_CURRENT_BINARY_DIR}/${target} ${CMAKE_CURRENT_BINARY_DIR}/${target}${CMAKE_EXECUTABLE_SUFFIX}
        )
    else()
        message(FATAL_ERROR "Expected either NSO or NRO: ${nxo_type}")
    endif()
endfunction()