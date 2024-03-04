# ibilcOS
An operational system made for learning purposes at UNESP-Ibilce

### WARN: clone repo with `--recursive` flag

## Build dependencies
```txt
clang
nasm
cmake
xorriso
qemu
```

## How to build?
```sh
mkdir build
cd build
cmake ..
cmake --build . --target setup
cmake --build .
```
to test, run `cmake --build . --target qemu`
