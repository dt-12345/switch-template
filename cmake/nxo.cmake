set(CMAKE_ASM_CREATE_SHARED_LIBRARY
    "<CMAKE_ASM_COMPILER> <CMAKE_SHARED_LIBRARY_ASM_FLAGS> <LANGUAGE_COMPILE_FLAGS> <LINK_FLAGS> <SONAME_FLAG><TARGET_SONAME> -o <TARGET> <OBJECTS> <LINK_LIBRARIES>"
)

set(NXO_TEMPLATE_ROOT ${CMAKE_CURRENT_LIST_DIR}/../)

set(NXO_TOOLS_DIR ${NXO_TEMPLATE_ROOT}/tools/ CACHE PATH "NXO Tools Path")

if (NOT EXISTS ${NXO_TOOLS_DIR}/elf2nso)
    message(FATAL_ERROR "Could not find elf2nso (${NXO_TOOLS_DIR})")
endif()

if (NOT EXISTS ${NXO_TOOLS_DIR}/elf2nro)
    message(FATAL_ERROR "Could not find elf2nro (${NXO_TOOLS_DIR})")
endif()

add_library(nnSdk SHARED stub/stub.S)
set_target_properties(nnSdk PROPERTIES PREFIX "" SUFFIX ".nss")

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

function(add_nxo target nxo_type)
    set(OPTIONS SHARED_LIBRARY ENABLE_RELRO HEADER_SECTION NO_SDK NO_DEFAULT_INIT)
    set(ONE_VALUE_OPTIONS SDK_VERSION INIT FINI LINKER_SCRIPT HASH_STYLE DYNAMIC_LIST)
    set(MULTI_VALUE_OPTIONS SOURCES)
    cmake_parse_arguments(ARG
        "${OPTIONS}" "${ONE_VALUE_OPTIONS}" "${MULTI_VALUE_OPTIONS}"
        ${ARGN}
    )

    if(NOT DEFINED ARG_SDK_VERSION)
        set(ARG_SDK_VERSION "23.2.2")
    endif()

    parse_version_string(${ARG_SDK_VERSION})

    if(NOT DEFINED ARG_INIT)
        set(ARG_INIT _init)
    endif()

    if(NOT DEFINED ARG_FINI)
        set(ARG_FINI _fini)
    endif()

    if(NOT DEFINED ARG_LINKER_SCRIPT)
        set(ARG_LINKER_SCRIPT ${NXO_TEMPLATE_ROOT}/scripts/aarch64.ld)
    endif()

    if(NOT DEFINED ARG_HASH_STYLE)
        set(ARG_HASH_STYLE sysv)
    endif()

    if(version_major LESS 17)
        if(ARG_ENABLE_RELRO)
            message(WARNING "ENABLE_RELRO is not supported on ${ARG_SDK_VERSION}")
        endif()

        if(ARG_HASH_STYLE STREQUAL "gnu")
            message(WARNING "GNU Hash is not supported on ${ARG_SDK_VERSION}")
        endif()
    endif()

    set(MODULE_NAME ${target})
    string(LENGTH ${MODULE_NAME} MODULE_NAME_LENGTH)

    configure_file(${NXO_TEMPLATE_ROOT}/template/rocrt/rocrt_DebugLink.S.in template/rocrt/rocrt_DebugLink.S @ONLY)

    if(ARG_SHARED_LIBRARY)
        add_library(${target} SHARED)
        set(EXTRA_SOURCES "")
        target_link_options(${target} PRIVATE -shared)
        target_link_options(${target} PRIVATE -Wl,--soname=${MODULE_NAME}${CMAKE_EXECUTABLE_SUFFIX})
    else()
        add_executable(${target})
        set(EXTRA_SOURCES
            ${NXO_TEMPLATE_ROOT}/template/MainRuntime/MainRuntimeObject.cpp
            ${NXO_TEMPLATE_ROOT}/template/MainRuntime/nnApplication.cpp
        )

        if(NOT NO_DEFAULT_INIT)
            list(APPEND EXTRA_SOURCES
                ${NXO_TEMPLATE_ROOT}/template/init/init_Malloc.cpp
                ${NXO_TEMPLATE_ROOT}/template/init/init_Startup.cpp
                ${NXO_TEMPLATE_ROOT}/template/init/detail/init_Startup-os.horizon.cpp
            )

            set_source_files_properties(${NXO_TEMPLATE_ROOT}/template/init/init_Startup.cpp PROPERTIES COMPILE_FLAGS -fno-stack-protector)
        endif()

        # this is to fix any undefined symbols provided by the SDK
        # since this isn't a shared library, we can't just use -shared
        get_target_property(LINKED_LIBRARIES ${target} LINK_LIBRARIES)
        if(NOT ARG_NO_SDK AND NOT "nnSdk" IN_LIST LINKED_LIBRARIES)
            target_link_libraries(${target} PRIVATE nnSdk)
        endif()
    endif()

    set_target_properties(${target} PROPERTIES PREFIX "")
    set_target_properties(${target} PROPERTIES LINK_DEPENDS ${ARG_LINKER_SCRIPT})
    
    target_link_options(${target} PRIVATE -T ${ARG_LINKER_SCRIPT})
    target_link_options(${target} PRIVATE -Wl,--build-id=sha1)
    target_link_options(${target} PRIVATE -Wl,-init=${ARG_INIT},-fini=${ARG_FINI})

    if (NOT DEFINED ARG_DYNAMIC_LIST)
        target_link_options(${target} PRIVATE -Wl,--export-dynamic)
    else()
        target_link_options(${target} PRIVATE -Wl,--dynamic-list=${ARG_DYNAMIC_LIST})
    endif()

    target_link_options(${target} PRIVATE -Wl,--hash-style=${ARG_HASH_STYLE})

    if(ARG_ENABLE_RELRO)
        target_compile_definitions(${target} PRIVATE ENABLE_RELRO)
    endif()

    target_compile_definitions(${target} PRIVATE NN_ROCRT_MODULE_HEADER_SIGNATURE=0x30444f4d)
    if(version_major GREATER_EQUAL 7)
        target_compile_definitions(${target} PRIVATE NN_ROCRT_ROMODULE_SIZE=0xd0)
    elseif(version_major GREATER 5 OR (version_major EQUAL 5 AND version_minor GREATER_EQUAL 1)) # not sure what the actual minor version where this changed is
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
            ${CMAKE_BINARY_DIR}/template/rocrt/rocrt_DebugLink.S
            ${NXO_TEMPLATE_ROOT}/template/rocrt/rocrt_Align.S
            ${NXO_TEMPLATE_ROOT}/template/rocrt/rocrt_Init.aarch64.S
            ${NXO_TEMPLATE_ROOT}/template/rocrt/rocrt.cpp
            ${NXO_TEMPLATE_ROOT}/template/rocrt/rocrt_LinkerSymbolGetter.cpp
            ${EXTRA_SOURCES}
            ${ARG_SOURCES}
        )

        set_target_properties(${target} PROPERTIES SUFFIX ".nss")
        set_source_files_properties(${NXO_TEMPLATE_ROOT}/template/rocrt/rocrt.cpp PROPERTIES COMPILE_FLAGS -fno-exceptions)

        add_custom_command(TARGET ${target} POST_BUILD
            COMMAND ${NXO_TEMPLATE_ROOT}/tools/elf2nso -o ${CMAKE_CURRENT_BINARY_DIR}/${target} ${CMAKE_CURRENT_BINARY_DIR}/${target}.nss
        )
    elseif(nxo_type STREQUAL "nro" OR nro_type STREQUAL "NRO")
        target_sources(${target} PRIVATE
            ${CMAKE_BINARY_DIR}/template/rocrt/rocrt_DebugLink.S
            ${NXO_TEMPLATE_ROOT}/template/rocrt/rocrt_Align.S
            ${NXO_TEMPLATE_ROOT}/template/rocrt/rocrt_Init_nro.aarch64.S
            ${NXO_TEMPLATE_ROOT}/template/rocrt/rocrt_nro.cpp
            ${NXO_TEMPLATE_ROOT}/template/rocrt/rocrt_LinkerSymbolGetter.cpp
            ${EXTRA_SOURCES}
            ${ARG_SOURCES}
        )

        set_target_properties(${target} PROPERTIES SUFFIX ".nrs")
        set_source_files_properties(${NXO_TEMPLATE_ROOT}/template/rocrt/rocrt_nro.cpp PROPERTIES COMPILE_FLAGS -fno-exceptions)

        if(ARG_HEADER_SECTION)
            add_custom_command(TARGET ${target} POST_BUILD
                COMMAND ${NXO_TEMPLATE_ROOT}/tools/elf2nro -o ${CMAKE_CURRENT_BINARY_DIR}/${target}.nso --header ${CMAKE_CURRENT_BINARY_DIR}/${target}.nrs
            )
        else()
            add_custom_command(TARGET ${target} POST_BUILD
                COMMAND ${NXO_TEMPLATE_ROOT}/tools/elf2nro -o ${CMAKE_CURRENT_BINARY_DIR}/${target}.nro ${CMAKE_CURRENT_BINARY_DIR}/${target}.nrs
            )
        endif()
    else()
        message(FATAL_ERROR "Expected either NSO or NRO: ${nxo_type}")
    endif()
endfunction(add_nxo)