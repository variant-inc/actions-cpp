#!/bin/bash
set -euo pipefail

# Install conan && conan package tools
python3 -m pip install --upgrade pip
pip3 install conan
pip3 install conan_package_tools


# Configure remote repo
# shellcheck disable=SC1090
source ~/.profile
conan remote clean
conan remote add conancenter https://center.conan.io
conan remote add cybertron "$ENV_CYBERTRON"
conan user -p "$CONAN_KEY" -r cybertron "$ENV_CONAN_USERNAME"


# Build your program with the given configuration
mkdir build && cd build
# shellcheck disable=SC1090
source ~/.profile
conan remove "energon*" -f
conan install .. --build=missing --profile ../profiles/linux_release
cmake ..
build-wrapper-linux-x86-64 --out-dir ../"$BUILD_WRAPPER_OUT_DIR" cmake --build . --config Release -j5


# Execute tests defined by the CMake configuration.  
# See https://cmake.org/cmake/help/latest/manual/ctest.1.html for more detail
ctest -C BUILD_TYPE