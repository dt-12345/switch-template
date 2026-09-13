# switch-template

This repository contains a template for building NSOs or NROs for game applications. It uses [Nintendo-OSS](https://support.nintendo.com/jp/oss/index.html) (GPL v2). For the time being, bundling `rtld` is not supported.

See `CMakeLists.txt` for an example.

## Building

Build the tools from https://github.com/dt-12345/nso-tools and copy elf2nso and elf2nro into `tools/`, then run the following:
```sh
cmake -B build --toolchain=cmake/toolchain.cmake
cmake --build build
```