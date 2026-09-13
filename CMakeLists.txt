cmake_minimum_required(VERSION 3.13)

project(example C CXX ASM)

include(cmake/nxo.cmake)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# build_nxo(target shared_library enable_relro [init_function_name] [fini_function_name])

# this is suitable for the main module of a program
add_executable(example_static_no_relro main.cpp)
build_nxo(example_static_no_relro nso FALSE FALSE)
add_executable(example_static_relro main.cpp)
build_nxo(example_static_relro nso FALSE TRUE)

# this is suitable for any module other than the main module of a program
add_executable(example_shared_no_relro main.cpp)
build_nxo(example_shared_no_relro nso TRUE FALSE)
add_executable(example_shared_relro main.cpp)
build_nxo(example_shared_relro nso TRUE TRUE)

# NRO example
add_executable(example_shared_relro_nro main.cpp)
build_nxo(example_shared_relro_nro nro TRUE TRUE)