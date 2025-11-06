#!/usr/bin/env bash
set -euo pipefail

pesde x ewdev/multitarget -- build --yes \
    --build-files src --output dist \
    --global RUNTIME --require-mode luau \
    --lune # Runtimes to build for