set(NX64_TRIPLE aarch64-linux-elf)

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_VERSION 1)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

set(CMAKE_SYSROOT ${PROJECT_SOURCE_DIR}/sysroot/musl/)
set(CMAKE_C_COMPILER clang)
set(CMAKE_C_COMPILER_TARGET ${NX64_TRIPLE})
set(CMAKE_CXX_COMPILER clang++)
set(CMAKE_CXX_FLAGS -stdlib=libc++)
set(CMAKE_CXX_COMPILER_TARGET ${NX64_TRIPLE})
set(CMAKE_ASM_COMPILER clang)
set(CMAKE_ASM_COMPILER_TARGET ${NX64_TRIPLE})

add_compile_options(-mcpu=cortex-a57+fp+simd+crypto+crc)
add_compile_options(-fPIC)
add_link_options(-fuse-ld=lld)
add_link_options(-nodefaultlibs)
add_link_options(-nostartfiles)

set(CMAKE_ASM_CREATE_SHARED_LIBRARY
    "<CMAKE_ASM_COMPILER> <CMAKE_SHARED_LIBRARY_ASM_FLAGS> <LANGUAGE_COMPILE_FLAGS> <LINK_FLAGS> <SONAME_FLAG><TARGET_SONAME> -o <TARGET> <OBJECTS> <LINK_LIBRARIES>"
)