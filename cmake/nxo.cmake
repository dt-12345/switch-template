set(CMAKE_EXECUTABLE_SUFFIX ".nss")
set(CMAKE_SHARED_LIBRARY_PREFIX "")
set(CMAKE_SHARED_LIBRARY_SUFFIX ".nss")

set(NXO_TEMPLATE_ROOT ${CMAKE_CURRENT_LIST_DIR}/../)

add_subdirectory(${NXO_TEMPLATE_ROOT}/stub/)

function(check_integer_string var)
    if(NOT var MATCHES "^[0-9]+$")
        message(FATAL_ERROR "${var} is not an integer")
    endif()
endfunction(check_integer_string)

function(parse_version_string version_string)
    string(REPLACE "." ";" version_list ${version_string})
    
    list(LENGTH version_list version_parts)
    if(NOT version_parts EQUAL 3)
        message(FATAL_ERROR "Failed to parse version string ${version_string}")
    endif()

    list(GET version_list 0 version_major)
    list(GET version_list 1 version_minor)
    list(GET version_list 2 version_micro)

    check_integer_string(${version_major})
    check_integer_string(${version_minor})
    check_integer_string(${version_micro})

    set(version_major ${version_major} PARENT_SCOPE)
    set(version_minor ${version_minor} PARENT_SCOPE)
    set(version_micro ${version_micro} PARENT_SCOPE)
endfunction(parse_version_string)

function(build_nxo target nxo_type)
    set(OPTIONS SHARED_LIBRARY ENABLE_RELRO HEADER_SECTION)
    set(ONE_VALUE_OPTIONS SDK_VERSION INIT FINI LINKER_SCRIPT)
    cmake_parse_arguments(ARG
        "${OPTIONS}" "${ONE_VALUE_OPTIONS}" ""
        ${ARGN}
    )

    if(NOT DEFINED ARG_SDK_VERSION)
        set(ARG_SDK_VERSION "23.2.2")
    endif()

    parse_version_string(${ARG_SDK_VERSION})

    if(version_major LESS 17 AND ARG_ENABLE_RELRO)
        message(WARNING "ENABLE_RELRO is not supported on ${ARG_SDK_VERSION}")
    endif()

    if(NOT DEFINED ARG_INIT)
        set(ARG_INIT _init)
    endif()

    if(NOT DEFINED ARG_FINI)
        set(ARG_FINI _fini)
    endif()

    if(NOT DEFINED ARG_LINKER_SCRIPT)
        set(ARG_LINKER_SCRIPT ${NXO_TEMPLATE_ROOT}/scripts/aarch64.ld)
    endif()

    set(MODULE_NAME ${target})
    string(LENGTH ${MODULE_NAME} MODULE_NAME_LENGTH)

    configure_file(${NXO_TEMPLATE_ROOT}/template/rocrt_DebugLink.S.in template/rocrt_DebugLink.S @ONLY)

    target_sources(${target} PRIVATE
        ${CMAKE_BINARY_DIR}/template/rocrt_DebugLink.S
        ${NXO_TEMPLATE_ROOT}/template/rocrt_Align.S
        ${NXO_TEMPLATE_ROOT}/template/rocrt_LinkerSymbolGetter.cpp
    )

    target_include_directories(${target} PRIVATE ${NXO_TEMPLATE_ROOT}/template/NX-NXFP2-a64-cfi)

    target_link_options(${target} PRIVATE -T${ARG_LINKER_SCRIPT})
    target_link_options(${target} PRIVATE -Wl,--build-id=sha1)
    target_link_options(${target} PRIVATE -Wl,-init=${ARG_INIT},-fini=${ARG_FINI})

    set_target_properties(${target} PROPERTIES LINK_DEPENDS ${ARG_LINKER_SCRIPT})

    if(ARG_SHARED_LIBRARY)
        target_link_options(${target} PRIVATE -shared)
    else()
        target_sources(${target} PRIVATE ${NXO_TEMPLATE_ROOT}/template/MainRuntimeObject.cpp)

        # this is to fix any undefined symbols provided by the SDK
        # since this isn't a shared library, we can't just use -shared
        get_target_property(LINKED_LIBRARIES ${target} LINK_LIBRARIES)
        if(NOT "nnSdk" IN_LIST LINKED_LIBRARIES)
            target_link_libraries(${target} PRIVATE nnSdk)
        endif()
    endif()

    if(ARG_ENABLE_RELRO)
        target_compile_definitions(${target} PRIVATE ENABLE_RELRO)
    endif()

    target_compile_definitions(${target} PRIVATE NN_ROCRT_MODULE_HEADER_SIGNATURE=0x30444f4d)
    if(version_major GREATER_EQUAL 7)
        target_compile_definitions(${target} PRIVATE NN_ROCRT_ROMODULE_SIZE=0xd0)
    elseif(version_major GREATER_EQUAL 5 AND version_minor GREATER_EQUAL 1) # not sure what the actual minor version where this changed is
        target_compile_definitions(${target} PRIVATE NN_ROCRT_ROMODULE_SIZE=0xc8)
    else()
        target_compile_definitions(${target} PRIVATE NN_ROCRT_ROMODULE_SIZE=0xb8)
    endif()
    target_compile_definitions(${target} PRIVATE NN_ROCRT_ROMODULE_ALIGN=0x8)
    if(ARG_HEADER_SECTION)
        target_compile_definitions(${target} PRIVATE NN_ROCRT_NRO_HEADER_ALIGN=0x1000)
    else()
        target_compile_definitions(${target} PRIVATE NN_ROCRT_NRO_HEADER_ALIGN=0x80)
    endif()
    target_compile_definitions(${target} PRIVATE NN_ROCRT_SEGMENT_ALIGN=0x1000)
    target_compile_definitions(${target} PRIVATE NN_SDK_VERSION_MAJOR=${version_major})
    target_compile_definitions(${target} PRIVATE NN_SDK_VERSION_MINOR=${version_minor})
    target_compile_definitions(${target} PRIVATE NN_SDK_VERSION_MICRO=${version_micro})

    if(nxo_type STREQUAL "nso" OR nxo_type STREQUAL "NSO")
        target_sources(${target} PRIVATE
            ${NXO_TEMPLATE_ROOT}/template/rocrt_Init.aarch64.S
            ${NXO_TEMPLATE_ROOT}/template/rocrt.cpp
        )

        set_source_files_properties(${NXO_TEMPLATE_ROOT}/template/rocrt.cpp PROPERTIES COMPILE_FLAGS -fno-exceptions)

        add_custom_command(TARGET ${target} POST_BUILD
            COMMAND ${NXO_TEMPLATE_ROOT}/tools/elf2nso -o ${CMAKE_CURRENT_BINARY_DIR}/${target} ${CMAKE_CURRENT_BINARY_DIR}/${target}${CMAKE_EXECUTABLE_SUFFIX}
        )
    elseif(nxo_type STREQUAL "nro" OR nro_type STREQUAL "NRO")
        target_sources(${target} PRIVATE
            ${NXO_TEMPLATE_ROOT}/template/rocrt_Init_nro.aarch64.S
            ${NXO_TEMPLATE_ROOT}/template/rocrt_nro.cpp
        )

        set_source_files_properties(${NXO_TEMPLATE_ROOT}/template/rocrt_nro.cpp PROPERTIES COMPILE_FLAGS -fno-exceptions)

        if(ARG_HEADER_SECTION)
            add_custom_command(TARGET ${target} POST_BUILD
                COMMAND ${NXO_TEMPLATE_ROOT}/tools/elf2nro -o ${CMAKE_CURRENT_BINARY_DIR}/${target} --header ${CMAKE_CURRENT_BINARY_DIR}/${target}${CMAKE_EXECUTABLE_SUFFIX}
            )
        else()
            add_custom_command(TARGET ${target} POST_BUILD
                COMMAND ${NXO_TEMPLATE_ROOT}/tools/elf2nro -o ${CMAKE_CURRENT_BINARY_DIR}/${target} ${CMAKE_CURRENT_BINARY_DIR}/${target}${CMAKE_EXECUTABLE_SUFFIX}
            )
        endif()
    else()
        message(FATAL_ERROR "Expected either NSO or NRO: ${nxo_type}")
    endif()
endfunction(build_nxo)