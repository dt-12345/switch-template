# Example toolchain file for building with devkitpro gcc

if (NOT DEFINED ENV{DEVKITPRO})
    message(FATAL_ERROR "devkitpro is not in env")
endif()

file(GLOB DKP_CXX_VERSIONS LIST_DIRECTORIES true $ENV{DEVKITPRO}/devkitA64/aarch64-elf/include/c++/ "*")
list(LENGTH DKP_CXX_VERSIONS DKP_CXX_VERSION_COUNT)

if(DKP_CXX_VERSION_COUNT LESS 1)
    message(FATAL_ERROR "Could not determine devkitpro gcc version")
endif()

list(GET DKP_CXX_VERSIONS 0 DKP_CXX_VERSION)

set(NX64_TRIPLE aarch64-linux-elf)

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_VERSION 1)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

set(CMAKE_C_COMPILER  $ENV{DEVKITPRO}/devkitA64/bin/aarch64-none-elf-gcc)
set(CMAKE_C_COMPILER_TARGET ${NX64_TRIPLE})
set(CMAKE_CXX_COMPILER  $ENV{DEVKITPRO}/devkitA64/bin/aarch64-none-elf-g++)
set(CMAKE_CXX_COMPILER_TARGET ${NX64_TRIPLE})
set(CMAKE_ASM_COMPILER  $ENV{DEVKITPRO}/devkitA64/bin/aarch64-none-elf-gcc)
set(CMAKE_ASM_COMPILER_TARGET ${NX64_TRIPLE})

add_compile_options(-mcpu=cortex-a57+fp+simd+crypto+crc)
add_compile_options(-fPIC)
add_link_options(-nodefaultlibs)
add_link_options(-nostartfiles)

set(CMAKE_ASM_CREATE_SHARED_LIBRARY
    "<CMAKE_ASM_COMPILER> <CMAKE_SHARED_LIBRARY_ASM_FLAGS> <LANGUAGE_COMPILE_FLAGS> <LINK_FLAGS> <SONAME_FLAG><TARGET_SONAME> -o <TARGET> <OBJECTS> <LINK_LIBRARIES>"
)