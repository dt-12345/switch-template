cmake_minimum_required(VERSION 3.13)

project(example C CXX ASM)

include(cmake/nxo.cmake)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# build_nxo(<target> <nxo_type>
#           [SDK_VERSION <target_sdk_version>]
#           [SHARED_LIBRARY] [ENABLE_RELRO] [HEADER_SECTION]
#           [INIT <init_function>] [FINI <fini_function>]
#           [LINKER_SCRIPT <script_path>]
# )

# this is suitable for the main module of a program
add_executable(example_static_no_relro main.cpp)
build_nxo(example_static_no_relro nso INIT _init)
add_executable(example_static_relro main.cpp)
build_nxo(example_static_relro nso ENABLE_RELRO)

# this is suitable for any module other than the main module of a program
add_executable(example_shared_no_relro main.cpp)
build_nxo(example_shared_no_relro nso SHARED_LIBRARY)
add_executable(example_shared_relro main.cpp)
build_nxo(example_shared_relro nso SHARED_LIBRARY ENABLE_RELRO)

# NRO example
add_executable(example_shared_relro_nro main.cpp)
build_nxo(example_shared_relro_nro nro SHARED_LIBRARY ENABLE_RELRO HEADER_SECTION)