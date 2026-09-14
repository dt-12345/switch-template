cmake_minimum_required(VERSION 3.13)

project(example C CXX ASM)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

include(cmake/nxo.cmake)

set(NXO_TOOLS_DIR ${PROJECT_SOURCE_DIR}/tools/) # override tools directory if desired

# add_nxo(<target> <nxo_type>
#         [SDK_VERSION <target_sdk_version>]
#         [SHARED_LIBRARY] [ENABLE_RELRO] [HEADER_SECTION] [NO_SDK] [NO_DEFAULT_INIT]
#         [INIT <init_function>] [FINI <fini_function>]
#         [LINKER_SCRIPT <script_path>] [HASH_STYLE <hash_style>] [DYNAMIC_LIST <dynamic_list>]
#         SOURCES <sources>...
# )

# this is suitable for the main module of a program
add_nxo(main_no_relro nso INIT _init SOURCES main.cpp)
add_nxo(main_relro nso ENABLE_RELRO SOURCES main.cpp)

# this is suitable for any module other than the main module of a program
add_nxo(shared_no_relro nso SHARED_LIBRARY SOURCES main_shared.cpp)
add_nxo(shared_relro nso SHARED_LIBRARY ENABLE_RELRO SOURCES main_shared.cpp)

# NRO example
add_nxo(nro_relro nro SHARED_LIBRARY ENABLE_RELRO HEADER_SECTION SOURCES main_shared.cpp)

# Older NRO example
add_nxo(nro_old nro SHARED_LIBRARY SDK_VERSION 1.0.0 SOURCES main_shared.cpp)