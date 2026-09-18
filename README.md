# switch-template

This repository contains a template for building NSOs or NROs for game applications. It uses [Nintendo-OSS](https://support.nintendo.com/jp/oss/index.html) (GPL v2). For the time being, bundling `rtld` is not supported.

See `CMakeLists.txt` for an example.

```
add_nxo(<target> <nxo_type>
        [SDK_VERSION <target_sdk_version>]
        [SHARED_LIBRARY] [ENABLE_RELRO] [HEADER_SECTION] [NO_SDK] [NO_DEFAULT_INIT]
        [INIT <init_function>] [FINI <fini_function>]
        [LINKER_SCRIPT <script_path>] [HASH_STYLE <hash_style>] [DYNAMIC_LIST <dynamic_list>]
        SOURCES <sources>...
)
```
- `<target>`: name of the target to add
- `<nxo_type>`: type of file to build (NSO or NRO)
- `SHARED_LIBRARY <target_sdk_version>`: target SDK version (default = 23.2.2)
- `SHARED_LIBRARY`: create shared library
- `ENABLE_RELRO`: enable read-only relocations (requires SDK versions >= 17)
- `HEADER_SECTION`: create a section-aligned NRO header (only affects NROs)
- `NO_SDK`: do not link against SDK stub library
- `NO_DEFAULT_INIT`: do not use the default `nn::init` initialization code (only affects non-shared libraries)
  - If not using `nn::init` and linking against the SDK, users should provide implementations for the following functions:
    - `nninitStartup`
- `NO_DEFAULT_MALLOC`: do not use the default `nn::init` memory allocation code (only affects non-shared libraries)
  - If not using `nn::init` and linking against the SDK, users should provide implementations for the following functions:
    - `malloc`
    - `free`
    - `calloc`
    - `realloc`
    - `aligned_alloc`
    - `malloc_usable_size` (unsure about this one, most games seem to not use it but it shows up in DWARF)
- `INIT <init_function>`: name of module initialization function (default = _init)
- `FINI <fini_function>`: name of module finalization function (default = _fini)
- `LINKER_SCRIPT <script_path>`: path to linkerscript (default = scripts/aarch64.ld)
- `HASH_STYLE <hash_style>`: hash style - sysv, gnu, or both (default = sysv)
  - GNU-style hash requires SDK >= 17
- `DYNAMIC_LIST <dynamic_list>`: path to exported symbols list
- `SOURCES <sources>...`: list of source files for the target

If building a non-shared library (a.k.a the main application binary), users should provide an implementation of `extern "C" void nnMain()` which will serve as the entry point.

Program execution (assuming you're using the SDK) goes as follows (bold entries are controllable by the application):
- _init_libc0()
- nnosInitialize()
- Enable user exception handler
- _init_libc1()
- nninitInitializeSdkModule()
- **nninitStartup()**
- _init_libc2()
- **DT_INIT for all modules in reverse order** (sdk, subsdk9, subsdk8, ..., subsdk0, main, rtld)
- **nnMain**
- **DT_FINI for all modules in order** (rtld, main, subsdk0, subsdk1, ..., subsdk9, sdk)
- nninitFinalizeSdkModule()
- nnosQuickExit()

## Building

Build the tools from https://github.com/dt-12345/nso-tools and copy elf2nso and elf2nro into `tools/`, then run the following:
```sh
# To build with clang + lld
cmake -B build --toolchain=cmake/toolchain_clang.cmake
cmake --build build

# To build with devkitpro
cmake -B build --toolchain=cmake/toolchain_dkp.cmake
cmake --build build
```