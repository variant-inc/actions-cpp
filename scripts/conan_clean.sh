#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1090
source ~/.profile
conan remove "mirage*" --builds --force
conan remove "mirage*" --packages --force
conan remove "mirage*" --src --force
conan remove "mirage*" --force 