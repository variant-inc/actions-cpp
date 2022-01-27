#!/bin/bash
set -euo pipefail

echo "===Configure remote repo==="
conan remote clean
conan remote add conancenter https://center.conan.io
conan remote add cybertron "$CONAN_UPLOAD"
conan user -p "$CONAN_PASSWORD" -r cybertron "$CONAN_LOGIN_USERNAME"

echo "===Build your program with the given configuration==="
mkdir build && cd build
conan remove "energon*" -f
conan install .. --build=missing --profile ../profiles/linux_release
echo "Cmake"
cmake ..
build-wrapper-linux-x86-64 --out-dir ../build_output cmake --build . --config Release -j5


echo "===Execute tests defined by the CMake configuration.==="
# See https://cmake.org/cmake/help/latest/manual/ctest.1.html for more detail
cd "$GITHUB_WORKSPACE"/build
echo "Current directory: $(pwd)"
ctest -C Release
